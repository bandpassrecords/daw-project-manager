import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../models/music_project.dart';
import '../../models/plugin_capture.dart';
import '../../utils/app_paths.dart';
import '../../utils/safe_file_name.dart';
import 'plugin_protocol.dart';

/// Where the app reads projects from and saves them to, for the bridge. An
/// interface so the bridge is tested against plain lists, never Hive.
abstract class DpmPluginLibrary {
  /// Every profile with its projects.
  Future<List<DpmPluginProfileProjects>> load();

  /// Saves an edit made on the plugin's behalf, as a user edit (bumped
  /// `updatedAt`, so it syncs like one).
  Future<void> saveProject(String profileId, MusicProject project);
}

/// How the bridge reaches the app's work sessions, for ending a session when
/// the DAW closes the project and starting one when it opens. An interface
/// so the decisions are tested without Riverpod or a timer.
abstract class DpmPluginSessionHooks {
  /// The running session's project (in the active profile), or null.
  DpmPluginProjectRef? activeSession();

  /// Settings > Work Sessions, device-local.
  bool get endWhenDawCloses;
  bool get startWhenDawOpens;

  /// Ends the running session as if it had been ended when the DAW let go
  /// of its project ([DpmPluginDeparture.at]), and tells the user why.
  Future<void> endSession(DpmPluginDeparture departure);

  /// Starts a session for [project] — when it is in the active profile.
  Future<void> startSession(DpmPluginProjectRef project);
}

/// The bridge folder the DAW Project Manager plugin shares with this app:
/// `plugin_bridge` inside the library folder. A pinned or dev library gets
/// its own, so a test build never talks to plugins working for the stable app.
Future<String> dpmPluginBridgePath() async => p.join(await getLocalAppDataPath(), 'plugin_bridge');

/// Writes `launch.json` just before [project] opens in its DAW, so the plugin
/// can link to it without asking. Best effort: a failure costs the plugin a
/// hint, never the launch.
Future<void> writeDpmPluginLaunchHint(String profileId, MusicProject project, {String? bridgeDir}) async {
  try {
    final dir = bridgeDir ?? await dpmPluginBridgePath();
    final hint = buildDpmPluginLaunchHint(profileId: profileId, project: project, launchedAt: DateTime.now());
    await writeFileAtomically(File(p.join(dir, 'launch.json')), jsonEncode(hint));
  } catch (e) {
    if (kDebugMode) debugPrint('Plugin launch hint not written: $e');
  }
}

/// The plugin's newest release on GitHub, or null when it can't be found out.
Future<DpmPluginRelease?> fetchLatestDpmPluginRelease({http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final response = await c
        .get(Uri.parse('https://api.github.com/repos/bandpassrecords/daw-project-manager-plugin/releases/latest'),
            headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body);
    return json is Map<String, dynamic> ? parseDpmPluginRelease(json) : null;
  } catch (e) {
    if (kDebugMode) debugPrint('Plugin release check failed: $e');
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// Writes [contents] to a temporary name and renames it over [target], so a
/// reader (the plugin) never sees half a file.
Future<void> writeFileAtomically(File target, String contents) async {
  await target.parent.create(recursive: true);
  final temp = File('${target.path}.tmp');
  await temp.writeAsString(contents, flush: true);
  await temp.rename(target.path);
}

/// The app's half of the DAW Project Manager plugin's protocol (docs/PROTOCOL.md
/// in bandpassrecords/daw-project-manager-plugin): keeps `index.json` current and applies the
/// plugin's outbox — new to-dos, ticks and pre-listen captures.
///
/// Desktop only. Runs on a timer rather than a file watcher: the folder is
/// tiny, a tick costs a directory listing, and watchers are unreliable on
/// network and cloud-synced home folders.
class DpmPluginBridgeService {
  DpmPluginBridgeService({
    required this.library,
    required this.bridgeDir,
    required this.previewSongsDir,
    required this.appVersion,
    DateTime Function()? clock,
    this.checkLatestRelease,
    this.releaseChecksAllowed,
    this.sessions,
    this.onPluginSeen,
    this.onLatestRelease,
  }) : _now = clock ?? DateTime.now;

  /// Every hello and heartbeat from a running plugin, for the DAW plugin
  /// settings' "last seen" line. Called often: the receiver throttles.
  final void Function(DpmPluginSighting sighting)? onPluginSeen;

  /// The newest plugin release whenever it is looked up, or null when
  /// looking isn't allowed — for the settings' download button.
  final void Function(DpmPluginRelease? release)? onLatestRelease;

  /// Null: presence is tracked but never touches a session.
  final DpmPluginSessionHooks? sessions;

  final DpmPluginLibrary library;
  final String bridgeDir;
  final String previewSongsDir;
  final String appVersion;
  final DateTime Function() _now;

  /// Looks up the plugin's newest release ([fetchLatestDpmPluginRelease]).
  /// Null: never look.
  final Future<DpmPluginRelease?> Function()? checkLatestRelease;

  /// Whether looking is allowed right now — the user's "check for updates"
  /// setting, in a build that checks its own updates. Null: always.
  final Future<bool> Function()? releaseChecksAllowed;

  /// How often the release is looked up again, and how soon after a failure.
  static const releaseCheckInterval = Duration(hours: 24);
  static const releaseRetryInterval = Duration(hours: 1);

  Timer? _timer;
  bool _ticking = false;
  String? _lastFingerprint;
  DpmPluginRelease? _latestRelease;
  DateTime? _nextReleaseCheck;

  // Message ids handled lately, listed in the index as "applied".
  final List<({String id, DateTime at})> _applied = [];
  static const appliedKeptFor = Duration(minutes: 30);
  static const appliedKeptMax = 500;

  // Presence: running plugin instances by runId, and what changed this tick.
  final Map<String, DpmPluginInstance> _instances = {};
  final List<DpmPluginProjectRef> _hellos = [];
  final Map<String, DpmPluginDeparture> _departures = {};
  DateTime? _lastTick;

  String get outboxDir => p.join(bridgeDir, 'outbox');
  String get instancesDir => p.join(bridgeDir, 'instances');

  /// Projects (by [dpmPluginKey]) a DAW has open right now.
  Set<String> get presentProjects =>
      {for (final i in _instances.values) dpmPluginKey(i.project.profileId, i.project.projectId)};
  String get capturesDir => p.join(bridgeDir, 'captures');
  String get dpmPluginPreviewDir => p.join(previewSongsDir, dpmPluginPreviewFolderName);
  File get indexFile => File(p.join(bridgeDir, 'index.json'));

  void start({Duration interval = const Duration(seconds: 3)}) {
    _timer?.cancel();
    unawaited(tick());
    _timer = Timer.periodic(interval, (_) => unawaited(tick()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Applies the outbox, then rewrites the index if anything in it changed —
  /// always after applying a message, since a fresh `generatedAt` is how the
  /// plugin learns its changes arrived. Never runs twice at once.
  Future<void> tick() async {
    if (_ticking) return;
    _ticking = true;
    try {
      final now = _now();
      final before = presentProjects;
      _hellos.clear();
      _departures.clear();

      // Woken from sleep: the plugins slept too, and their heartbeats are as
      // old as the nap. A fresh grace period, or waking would end the session
      // at the moment the lid closed.
      final last = _lastTick;
      if (last != null && now.difference(last) > dpmPluginSleepGap) {
        _instances.updateAll((_, i) => i.seenAt(now));
      }
      _lastTick = now;

      await _readHeartbeats();
      final handledBefore = _applied.length;
      final changed = await processOutbox();
      await _expireStale(now);
      await _decideSession(before);
      // Rewritten after anything was handled, changed or not: the fresh
      // "applied" list and generatedAt are the plugin's confirmation.
      await writeIndex(force: changed > 0 || _applied.length != handledBefore);
    } catch (e) {
      if (kDebugMode) debugPrint('Plugin bridge tick failed: $e');
    } finally {
      _ticking = false;
    }
  }

  /// Writes `index.json` when its content changed since the last write (or
  /// when [force]d). Returns whether it wrote.
  Future<bool> writeIndex({bool force = false}) async {
    await _refreshLatestRelease();
    final now = _now();
    _applied.removeWhere((a) => now.difference(a.at) > appliedKeptFor);
    if (_applied.length > appliedKeptMax) _applied.removeRange(0, _applied.length - appliedKeptMax);
    final index = buildDpmPluginIndex(await library.load(),
        generatedAt: now,
        appVersion: appVersion,
        latestRelease: _latestRelease,
        appliedMessageIds: [for (final a in _applied) a.id]);
    final fingerprint = dpmPluginIndexFingerprint(index);
    if (!force && fingerprint == _lastFingerprint && await indexFile.exists()) return false;

    await writeFileAtomically(indexFile, jsonEncode(index));
    _lastFingerprint = fingerprint;
    return true;
  }

  /// Looks the plugin's newest release up again when it is due: once a day,
  /// an hour after a failure. When checks aren't allowed (any more), the
  /// index stops naming a release, so the plugin stops offering it.
  Future<void> _refreshLatestRelease() async {
    final check = checkLatestRelease;
    if (check == null) return;

    final allowed = releaseChecksAllowed == null || await releaseChecksAllowed!();
    if (!allowed) {
      if (_latestRelease != null) onLatestRelease?.call(null);
      _latestRelease = null;
      _nextReleaseCheck = null;
      return;
    }

    final now = _now();
    if (_nextReleaseCheck != null && now.isBefore(_nextReleaseCheck!)) return;

    final release = await check();
    if (release != null) {
      _latestRelease = release;
      onLatestRelease?.call(release);
    }
    _nextReleaseCheck = now.add(release != null ? releaseCheckInterval : releaseRetryInterval);
  }

  /// Applies every message in the outbox, oldest first, deleting each once
  /// handled. Returns how many changed a project.
  Future<int> processOutbox() async {
    final dir = Directory(outboxDir);
    if (!await dir.exists()) return 0;

    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    if (files.isEmpty) return 0;
    // Names start with the UTC time and a sequence number: name order is the
    // order the plugin wrote them in.
    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    var library = await this.library.load();
    var changed = 0;

    for (final file in files) {
      final String text;
      try {
        text = await file.readAsString();
      } catch (_) {
        continue; // still being written by another tool; next tick
      }

      final message = parseDpmPluginMessage(text);
      try {
        if (message != null && await _apply(message, library)) {
          changed++;
          library = await this.library.load();
        }
        // Handled, whatever came of it: the plugin stops waiting.
        if (message != null) _applied.add((id: message.id, at: _now()));
      } catch (e) {
        if (kDebugMode) debugPrint('Plugin message ${p.basename(file.path)} failed: $e');
      }

      try {
        await file.delete();
      } catch (_) {}
    }

    return changed;
  }

  Future<bool> _apply(DpmPluginMessage message, List<DpmPluginProfileProjects> library) async {
    switch (message) {
      case DpmPluginHello(:final runId, :final project, :final hostName, :final pluginVersion):
        if (runId != null && project != null) {
          _see(DpmPluginInstance(runId, project, message.createdAt, hostName: hostName, pluginVersion: pluginVersion));
          _hellos.add(project);
        }
        return false;

      case DpmPluginGoodbye(:final runId):
        if (runId != null) await _leave(runId, message.createdAt, DpmPluginDepartureReason.closed);
        return false;

      case DpmPluginUnknownMessage(:final type):
        if (kDebugMode) debugPrint('Plugin message of unknown type "$type" dropped');
        return false;

      case DpmPluginTodoAdd():
        final found = _find(library, message.project);
        if (found == null) return false;
        final updated = applyDpmPluginTodoAdd(found.owner, message);
        if (updated == null) return false;
        await this.library.saveProject(found.profileId, updated);
        return true;

      case DpmPluginNotesSet():
        final found = _find(library, message.project);
        if (found == null) return false;
        final updated = applyDpmPluginNotesSet(found.owner, message);
        if (updated == null) return false;
        await this.library.saveProject(found.profileId, updated);
        return true;

      case DpmPluginTodoSetCompleted():
        final found = _find(library, message.project);
        if (found == null) return false;
        final updated = applyDpmPluginTodoSetCompleted(found.owner, message);
        if (updated == null) return false;
        await this.library.saveProject(found.profileId, updated);
        return true;

      case DpmPluginCaptureReady():
        return _adoptCapture(message, library);
    }
  }

  /// Records an instance as present, keeping whichever sighting is newer.
  void _see(DpmPluginInstance instance) {
    if (instance.pluginVersion.isNotEmpty) {
      onPluginSeen?.call(DpmPluginSighting(instance.pluginVersion, instance.hostName, instance.lastSeen));
    }
    final known = _instances[instance.runId];
    if (known != null && !instance.lastSeen.isAfter(known.lastSeen)) return;
    _instances[instance.runId] = instance.hostName.isEmpty && known != null
        ? DpmPluginInstance(instance.runId, instance.project, instance.lastSeen, hostName: known.hostName)
        : instance;
  }

  /// An instance left at [at]: gone from presence, its heartbeat file too.
  Future<void> _leave(String runId, DateTime at, DpmPluginDepartureReason reason) async {
    final instance = _instances.remove(runId);
    if (instance != null) {
      final key = dpmPluginKey(instance.project.profileId, instance.project.projectId);
      final previous = _departures[key];
      if (previous == null || at.isAfter(previous.at)) {
        _departures[key] = DpmPluginDeparture(at, reason, hostName: instance.hostName);
      }
    }
    try {
      // The run id came from a message: it names a file in instances/ only.
      final path = safeFileIn(instancesDir, '$runId.json');
      if (path != null && await File(path).exists()) await File(path).delete();
    } catch (_) {}
  }

  Future<void> _readHeartbeats() async {
    final dir = Directory(instancesDir);
    if (!await dir.exists()) return;
    await for (final entry in dir.list()) {
      if (entry is! File || !entry.path.endsWith('.json')) continue;
      try {
        final instance = parseDpmPluginHeartbeat(await entry.readAsString());
        if (instance != null) _see(instance);
      } catch (_) {} // being rewritten; next tick
    }
  }

  /// Instances whose heartbeat went stale died without a goodbye (a crashed
  /// DAW): they leave at their last heartbeat.
  Future<void> _expireStale(DateTime now) async {
    final stale = _instances.values.where((i) => now.difference(i.lastSeen) > dpmPluginHeartbeatStale).toList();
    for (final instance in stale) {
      await _leave(instance.runId, instance.lastSeen, DpmPluginDepartureReason.stoppedResponding);
    }
  }

  Future<void> _decideSession(Set<String> presentBefore) async {
    final hooks = sessions;
    if (hooks == null) return;

    final presentAfter = presentProjects;
    final active = hooks.activeSession();
    final activeKeys = active == null ? <String>{} : await _sessionKeys(active);

    final action = decideDpmPluginSession(
      activeSessionKeys: activeKeys,
      presentBefore: presentBefore,
      presentAfter: presentAfter,
      departures: _departures,
      // A hello only counts while its instance is still there: an old one
      // read after the app was closed for a day starts nothing.
      hellos: _hellos.where((h) => presentAfter.contains(dpmPluginKey(h.profileId, h.projectId))).toList(),
      endWhenDawCloses: hooks.endWhenDawCloses,
      startWhenDawOpens: hooks.startWhenDawOpens,
    );

    switch (action) {
      case EndDpmPluginSession(:final departure):
        await hooks.endSession(departure);
      case StartDpmPluginSession(:final project):
        await hooks.startSession(project);
      case null:
        break;
    }
  }

  /// The keys a session answers to: its project's, and for a version stack
  /// every member's — the DAW opens a version, the session is the stack's.
  Future<Set<String>> _sessionKeys(DpmPluginProjectRef active) async {
    final keys = {dpmPluginKey(active.profileId, active.projectId)};
    for (final entry in await library.load()) {
      if (entry.profile.id != active.profileId) continue;
      for (final project in entry.projects) {
        if (project.id == active.projectId && project.isVirtual) {
          keys.addAll(project.memberProjectIds.map((id) => dpmPluginKey(active.profileId, id)));
        }
      }
    }
    return keys;
  }

  ({String profileId, MusicProject owner})? _find(
    List<DpmPluginProfileProjects> library,
    DpmPluginProjectRef? ref,
  ) {
    if (ref == null) return null;
    for (final entry in library) {
      if (entry.profile.id != ref.profileId) continue;
      for (final project in entry.projects) {
        if (project.id == ref.projectId) {
          return (profileId: entry.profile.id, owner: dpmPluginOwnerOf(project, entry.projects));
        }
      }
    }
    return null;
  }

  /// Copies a capture into the app's own folder and makes it the project's
  /// latest capture ([MusicProject.latestCapture]) — never its preview song.
  /// The bridge's copy is removed either way: the plugin records a new one
  /// on the next pass.
  Future<bool> _adoptCapture(DpmPluginCaptureReady message, List<DpmPluginProfileProjects> library) async {
    final source = File(p.normalize(p.join(bridgeDir, message.file)));
    // Only files in captures/: a message must not point the app elsewhere.
    if (!p.isWithin(capturesDir, source.path)) return false;
    // Gone: superseded by a later capture before the app got to it.
    if (!await source.exists()) return false;

    try {
      final found = _find(library, message.project);
      if (found == null) return false;

      final owner = found.owner;
      if (!dpmPluginKeepsCapture(owner, message.capturedAt)) return false;

      final destination = File(p.join(dpmPluginPreviewDir, owner.id, p.basename(source.path)));
      await destination.parent.create(recursive: true);
      await source.copy(destination.path);

      final previous = owner.latestCapture?.path;
      await this.library.saveProject(
        found.profileId,
        owner.copyWith(
          latestCapture: PluginCapture(
            path: destination.path,
            capturedAt: message.capturedAt,
            durationSeconds: message.durationSeconds,
          ),
        ),
      );

      // The capture it replaces, unless something still plays it: a stack
      // and its promoted member share one row's look, and a capture adopted
      // as a preview song before captures had a slot stays there.
      if (previous != null && previous != destination.path && p.isWithin(dpmPluginPreviewDir, previous)) {
        final reloaded = await this.library.load();
        if (!dpmPluginCaptureFileInUse(previous, reloaded.expand((e) => e.projects))) {
          try {
            await File(previous).delete();
          } catch (_) {}
        }
      }
      return true;
    } finally {
      try {
        await source.delete();
      } catch (_) {}
    }
  }
}
