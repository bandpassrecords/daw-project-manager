import 'dart:convert';

import '../../models/music_project.dart';
import '../../models/profile.dart';
import '../../models/todo_item.dart';

/// The app's side of the DAW Project Manager plugin's protocol — the pure part:
/// what goes into `index.json`, how the plugin's messages are read, and what
/// they do to a project. File I/O lives in `plugin_bridge_service.dart`.
///
/// The contract is `docs/PROTOCOL.md` in bandpassrecords/daw-project-manager-plugin; this
/// file and that one change together.

/// `index.json`'s schema. A breaking change gets a new file name, not a new
/// number here: older plugins read any schema >= 1 and ignore unknown fields.
const int dpmPluginIndexSchema = 1;

/// One profile and its projects, as the bridge sees them.
class DpmPluginProfileProjects {
  final Profile profile;
  final List<MusicProject> projects;

  const DpmPluginProfileProjects(this.profile, this.projects);
}

/// The row a project's to-dos live on: a version-stack member's are its
/// stack's (the stack owns the shared metadata), everything else's its own.
MusicProject dpmPluginOwnerOf(MusicProject project, List<MusicProject> profileProjects) {
  final stackId = project.stackId;
  if (stackId == null) return project;
  for (final candidate in profileProjects) {
    if (candidate.id == stackId && candidate.isVirtual) return candidate;
  }
  return project;
}

/// Whether a project belongs in the plugin's list: it has a file a DAW can
/// open. Stacks (no file of their own) and archived projects (zipped away)
/// don't; a stack's members do, carrying the stack's to-dos.
bool dpmPluginListsProject(MusicProject project) => !project.isVirtual && !project.isArchived;

/// The newest plugin release on GitHub, for the plugin's "Update available".
class DpmPluginRelease {
  final String version;

  /// The release page.
  final String url;

  /// The installer for each platform, when the release has one.
  final Map<DpmPluginPlatform, String> downloads;

  const DpmPluginRelease(this.version, this.url, {this.downloads = const {}});
}

/// The desktop platforms the plugin ships installers for.
enum DpmPluginPlatform { windows, macOS, linux }

/// Where the plugin's releases live: the fallback when the newest release
/// isn't known (update checks off, offline, the Flatpak).
const dpmPluginReleasesPage = 'https://github.com/bandpassrecords/daw-project-manager-plugin/releases/latest';

/// The plugin installer's file name on a release, per platform — the names
/// the plugin's CI gives them (`packaging/`), version in the middle.
final Map<DpmPluginPlatform, RegExp> _installerNames = {
  DpmPluginPlatform.windows: RegExp(r'^DAW_Project_Manager_Plugin_Installer_v[\d.]+\.exe$'),
  DpmPluginPlatform.macOS: RegExp(r'^DAW_Project_Manager_Plugin_macOS_Installer_v[\d.]+\.pkg$'),
  DpmPluginPlatform.linux: RegExp(r'^DAW_Project_Manager_Plugin_Linux_x86_64_v[\d.]+\.tar\.gz$'),
};

/// What "Download the DAW plugin" opens: this platform's installer from the
/// newest release, else that release's page, else the releases page.
String dpmPluginDownloadUrl(DpmPluginRelease? release, DpmPluginPlatform platform) =>
    release?.downloads[platform] ?? release?.url ?? dpmPluginReleasesPage;

/// Whether [remote] is a strictly newer x.y.z version than [local]. A
/// version that isn't x.y.z is never newer.
bool isNewerDpmPluginVersion(String remote, String local) {
  List<int>? parse(String v) {
    final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)').firstMatch(v.trim());
    return m == null ? null : [for (var i = 1; i <= 3; i++) int.parse(m.group(i)!)];
  }

  final r = parse(remote), l = parse(local);
  if (r == null || l == null) return false;
  for (var i = 0; i < 3; i++) {
    if (r[i] != l[i]) return r[i] > l[i];
  }
  return false;
}

/// The last time this computer saw the plugin running, and which: for the
/// DAW plugin settings ("last seen in … version …") and its update offer.
/// Device-local.
class DpmPluginSighting {
  final String version;
  final String hostName;
  final DateTime at;

  const DpmPluginSighting(this.version, this.hostName, this.at);

  Map<String, dynamic> toJson() => {'version': version, 'host': hostName, 'at': at.toUtc().toIso8601String()};

  static DpmPluginSighting? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final version = json['version'], host = json['host'], at = dpmPluginTime(json['at']);
    if (version is! String || version.isEmpty || at == null) return null;
    return DpmPluginSighting(version, host is String ? host : '', at);
  }

  /// Whether this sighting says something [previous] didn't: a version or
  /// host change, or simply a minute later — so the record stays current
  /// without being rewritten on every heartbeat.
  bool isNewsAfter(DpmPluginSighting? previous) =>
      previous == null ||
      version != previous.version ||
      hostName != previous.hostName ||
      at.difference(previous.at) >= const Duration(minutes: 1);
}

/// `index.json`: every profile's projects with the to-dos the app shows for
/// them. Every profile, not just the active one — a DAW session belongs to
/// whichever artist it belongs to. [latestRelease], when known, lets the
/// plugin offer its own update without going on the network itself.
Map<String, dynamic> buildDpmPluginIndex(
  List<DpmPluginProfileProjects> library, {
  required DateTime generatedAt,
  required String appVersion,
  DpmPluginRelease? latestRelease,
  List<String> appliedMessageIds = const [],
}) {
  final projects = <Map<String, dynamic>>[];

  for (final entry in library) {
    for (final project in entry.projects) {
      if (!dpmPluginListsProject(project)) continue;
      final owner = dpmPluginOwnerOf(project, entry.projects);
      projects.add({
        'id': project.id,
        'profileId': entry.profile.id,
        'profileName': entry.profile.name,
        'name': project.displayName,
        'filePath': project.filePath,
        'dawType': project.dawType ?? '',
        'notes': owner.notes ?? '',
        'todos': [
          for (final todo in owner.todos)
            {
              'id': todo.id,
              'text': todo.text,
              'completed': todo.completed,
              'createdAt': todo.createdAt.toUtc().toIso8601String(),
            },
        ],
      });
    }
  }

  return {
    'schema': dpmPluginIndexSchema,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'app': {'version': appVersion},
    if (latestRelease != null)
      'plugin': {'latestVersion': latestRelease.version, 'releaseUrl': latestRelease.url},
    // The plugin messages handled lately: how a notes edit learns it arrived.
    'applied': appliedMessageIds,
    'projects': projects,
  };
}

/// Reads GitHub's "latest release" answer for the plugin's repo. Null when it
/// isn't one (no tag, no page, a version that isn't x.y.z).
DpmPluginRelease? parseDpmPluginRelease(Map<String, dynamic> json) {
  final tag = json['tag_name'];
  final url = json['html_url'];
  if (tag is! String || url is! String) return null;
  final version = tag.replaceFirst(RegExp(r'^v'), '');
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) return null;

  final downloads = <DpmPluginPlatform, String>{};
  final assets = json['assets'];
  if (assets is List) {
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = asset['name'], link = asset['browser_download_url'];
      if (name is! String || link is! String) continue;
      for (final entry in _installerNames.entries) {
        if (entry.value.hasMatch(name)) downloads[entry.key] = link;
      }
    }
  }
  return DpmPluginRelease(version, url, downloads: downloads);
}

/// The index without its timestamp, for "did anything change?" — rewriting
/// an identical index every few seconds would be pointless disk churn.
String dpmPluginIndexFingerprint(Map<String, dynamic> index) =>
    jsonEncode({...index}..remove('generatedAt'));

/// `launch.json`, written just before a project is opened in its DAW.
Map<String, dynamic> buildDpmPluginLaunchHint({
  required String profileId,
  required MusicProject project,
  required DateTime launchedAt,
}) => {
  'projectId': project.id,
  'profileId': profileId,
  'filePath': project.filePath,
  'launchedAt': launchedAt.toUtc().toIso8601String(),
};

// --- Messages from the plugin ------------------------------------------------

/// Which project a message is about. Matched by profile *and* id, never id
/// alone: one id can sit in two profiles.
class DpmPluginProjectRef {
  final String profileId;
  final String projectId;

  const DpmPluginProjectRef(this.profileId, this.projectId);
}

sealed class DpmPluginMessage {
  final String id;
  final DateTime createdAt;
  final DpmPluginProjectRef? project;

  /// The running plugin instance that sent it — never saved, so two open
  /// copies of one project are two instances. Null from older plugins.
  final String? runId;

  /// The DAW it runs in, as the host describes itself ("Steinberg Cubase 13").
  final String hostName;

  /// The plugin's own version.
  final String pluginVersion;

  const DpmPluginMessage(this.id, this.createdAt, this.project,
      {this.runId, this.hostName = '', this.pluginVersion = ''});
}

/// A plugin instance is running inside a project.
class DpmPluginHello extends DpmPluginMessage {
  const DpmPluginHello(super.id, super.createdAt, super.project, {super.runId, super.hostName, super.pluginVersion});
}

/// A plugin instance has left a project: the DAW closed it or quit, the
/// plugin was removed, or it was linked elsewhere. [createdAt] is when.
class DpmPluginGoodbye extends DpmPluginMessage {
  const DpmPluginGoodbye(super.id, super.createdAt, super.project, {super.runId, super.hostName});
}

class DpmPluginTodoAdd extends DpmPluginMessage {
  final String todoId;
  final String text;
  final DateTime todoCreatedAt;

  const DpmPluginTodoAdd(super.id, super.createdAt, super.project,
      {required this.todoId, required this.text, required this.todoCreatedAt});
}

class DpmPluginTodoSetCompleted extends DpmPluginMessage {
  final String todoId;
  final bool completed;

  const DpmPluginTodoSetCompleted(super.id, super.createdAt, super.project,
      {required this.todoId, required this.completed});
}

/// The project's notes, edited in the plugin: the whole new text and the
/// text it was edited from.
class DpmPluginNotesSet extends DpmPluginMessage {
  final String text;
  final String baseText;

  const DpmPluginNotesSet(super.id, super.createdAt, super.project, {required this.text, required this.baseText});
}

class DpmPluginCaptureReady extends DpmPluginMessage {
  /// Relative to the bridge folder, forward slashes.
  final String file;
  final double durationSeconds;
  final DateTime capturedAt;

  const DpmPluginCaptureReady(super.id, super.createdAt, super.project,
      {required this.file, required this.durationSeconds, required this.capturedAt});
}

/// A type this build doesn't know: logged and deleted, so a newer plugin
/// can't fill the folder.
class DpmPluginUnknownMessage extends DpmPluginMessage {
  final String type;

  const DpmPluginUnknownMessage(super.id, super.createdAt, super.project, this.type);
}

/// Longest to-do text accepted from the plugin (it sends at most 500).
const int dpmPluginMaxTodoLength = 500;

/// Longest notes text accepted from the plugin (it sends at most 20 000).
const int dpmPluginMaxNotesLength = 20000;

/// Put between the app's notes and the plugin's when both changed at once.
const dpmPluginNotesSeparator = '\n\n----------\n';

/// Reads one outbox file. Null when it isn't a message at all.
/// A time written by the plugin (UTC, "Z"), as the app keeps times: local.
/// Dart parses "…Z" as a UTC DateTime, and DateFormat prints it as such —
/// which is how a session once showed as 12:51–10:52 two hours east of UTC.
DateTime? dpmPluginTime(Object? value) => DateTime.tryParse('$value')?.toLocal();

DpmPluginMessage? parseDpmPluginMessage(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;

  final id = decoded['id'];
  final type = decoded['type'];
  if (id is! String || id.isEmpty || type is! String) return null;

  final createdAt = dpmPluginTime(decoded['createdAt']) ?? DateTime.now();
  final project = _parseRef(decoded['project']);
  final payload = decoded['payload'] is Map<String, dynamic>
      ? decoded['payload'] as Map<String, dynamic>
      : const <String, dynamic>{};

  final plugin = decoded['plugin'];
  final runId = plugin is Map<String, dynamic> ? dpmPluginRunIdOf(plugin['runId']) : null;
  final pluginVersion = plugin is Map<String, dynamic> && plugin['version'] is String ? plugin['version'] as String : '';

  final host = decoded['host'];
  final hostName = host is Map<String, dynamic> && host['name'] is String ? host['name'] as String : '';

  switch (type) {
    case 'session.hello':
      return DpmPluginHello(id, createdAt, project, runId: runId, hostName: hostName, pluginVersion: pluginVersion);

    case 'session.goodbye':
      return DpmPluginGoodbye(id, createdAt, project, runId: runId, hostName: hostName);

    case 'todo.add':
      final todoId = payload['todoId'];
      final rawText = payload['text'];
      if (todoId is! String || todoId.isEmpty || rawText is! String) return null;
      final text = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) return null;
      return DpmPluginTodoAdd(id, createdAt, project,
          todoId: todoId,
          text: text.length > dpmPluginMaxTodoLength ? text.substring(0, dpmPluginMaxTodoLength) : text,
          todoCreatedAt: dpmPluginTime(payload['createdAt']) ?? createdAt);

    case 'todo.setCompleted':
      final todoId = payload['todoId'];
      final completed = payload['completed'];
      if (todoId is! String || completed is! bool) return null;
      return DpmPluginTodoSetCompleted(id, createdAt, project, todoId: todoId, completed: completed);

    case 'notes.set':
      final text = payload['text'];
      final baseText = payload['baseText'];
      if (text is! String || baseText is! String) return null;
      return DpmPluginNotesSet(id, createdAt, project,
          text: text.length > dpmPluginMaxNotesLength ? text.substring(0, dpmPluginMaxNotesLength) : text,
          baseText: baseText);

    case 'capture.ready':
      final file = payload['file'];
      if (file is! String || file.isEmpty) return null;
      return DpmPluginCaptureReady(id, createdAt, project,
          file: file,
          durationSeconds: (payload['durationSeconds'] as num?)?.toDouble() ?? 0,
          capturedAt: dpmPluginTime(payload['capturedAt']) ?? createdAt);

    default:
      return DpmPluginUnknownMessage(id, createdAt, project, type);
  }
}

DpmPluginProjectRef? _parseRef(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final id = value['id'];
  final profileId = value['profileId'];
  if (id is! String || id.isEmpty || profileId is! String) return null;
  return DpmPluginProjectRef(profileId, id);
}

/// [owner] with the plugin's to-do added, or null when it is already there —
/// which is what makes applying the same message twice harmless.
MusicProject? applyDpmPluginTodoAdd(MusicProject owner, DpmPluginTodoAdd message) {
  if (owner.todos.any((t) => t.id == message.todoId)) return null;
  return owner.copyWith(todos: [
    ...owner.todos,
    TodoItem(id: message.todoId, text: message.text, createdAt: message.todoCreatedAt),
  ]);
}

/// [owner] with the to-do ticked or unticked, or null when there is nothing
/// to change — including a to-do deleted in the app: a deletion beats a tick.
MusicProject? applyDpmPluginTodoSetCompleted(MusicProject owner, DpmPluginTodoSetCompleted message) {
  final index = owner.todos.indexWhere((t) => t.id == message.todoId);
  if (index < 0 || owner.todos[index].completed == message.completed) return null;
  final todos = [...owner.todos];
  todos[index] = todos[index].copyWith(completed: message.completed);
  return owner.copyWith(todos: todos);
}

// --- Presence: which projects a DAW has open --------------------------------

/// A plugin instance's heartbeat goes stale after this long without a
/// refresh (it refreshes every 10 s): the DAW died without a goodbye.
const dpmPluginHeartbeatStale = Duration(seconds: 90);

/// A gap this long between two of the app's own ticks means the computer
/// slept: every instance then gets a fresh [dpmPluginHeartbeatStale].
const dpmPluginSleepGap = Duration(seconds: 30);

/// One running plugin instance, present in a project.
class DpmPluginInstance {
  final String runId;
  final DpmPluginProjectRef project;
  final DateTime lastSeen;
  final String hostName;
  final String pluginVersion;

  const DpmPluginInstance(this.runId, this.project, this.lastSeen, {this.hostName = '', this.pluginVersion = ''});

  DpmPluginInstance seenAt(DateTime time) =>
      DpmPluginInstance(runId, project, time, hostName: hostName, pluginVersion: pluginVersion);
}

/// How an instance left its project.
enum DpmPluginDepartureReason {
  /// It said goodbye: the DAW closed the project or quit, or the plugin was
  /// removed.
  closed,

  /// It went quiet: no goodbye, and its heartbeat went stale — a crashed or
  /// killed DAW, most likely.
  stoppedResponding,
}

/// When and how the last instance in a project left it.
class DpmPluginDeparture {
  final DateTime at;
  final DpmPluginDepartureReason reason;
  final String hostName;

  const DpmPluginDeparture(this.at, this.reason, {this.hostName = ''});
}

/// [value] when it is a run id the app can name a file after, else null. The
/// plugin sends a dashed UUID; anything else — `../../x` above all, which
/// made a goodbye delete `x.json` wherever that led — is no instance at all.
String? dpmPluginRunIdOf(Object? value) =>
    value is String && RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(value) ? value : null;

/// Reads `instances/<runId>.json`. Null when it isn't a linked heartbeat.
DpmPluginInstance? parseDpmPluginHeartbeat(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final runId = dpmPluginRunIdOf(decoded['runId']);
  final project = _parseRef(decoded['project']);
  final lastSeen = dpmPluginTime(decoded['lastSeen']);
  if (runId == null || project == null || lastSeen == null) return null;
  final host = decoded['host'];
  final hostName = host is Map<String, dynamic> && host['name'] is String ? host['name'] as String : '';
  final pluginVersion = decoded['pluginVersion'] is String ? decoded['pluginVersion'] as String : '';
  return DpmPluginInstance(runId, project, lastSeen, hostName: hostName, pluginVersion: pluginVersion);
}

/// The key a session is tracked under: profile and id, never id alone.
String dpmPluginKey(String profileId, String projectId) => '$profileId/$projectId';

/// What the plugin's comings and goings mean for the work session.
sealed class DpmPluginSessionAction {
  const DpmPluginSessionAction();
}

/// End the running session, at the moment the DAW let go of its project.
class EndDpmPluginSession extends DpmPluginSessionAction {
  final DpmPluginDeparture departure;
  const EndDpmPluginSession(this.departure);

  DateTime get at => departure.at;
}

/// Start a session for a project that just opened in the DAW.
class StartDpmPluginSession extends DpmPluginSessionAction {
  final DpmPluginProjectRef project;
  const StartDpmPluginSession(this.project);
}

/// Decides one tick of presence changes.
///
/// [activeSessionKeys] are the keys the running session answers to: its
/// project's, plus — for a session on a version stack — every member's, so
/// closing the version the DAW had open ends the stack's session.
/// [presentBefore]/[presentAfter] are the keys with at least one instance at
/// the start and end of the tick; [departures], when and how each key's
/// last instance left; [hellos], projects that said hello this tick, in order.
///
/// A session ends only on a transition from present to absent — a session
/// for a project no plugin was ever present in is never ended — and only
/// once *every* key it answers to is absent. A session starts only when none
/// is running: it never switches away from one.
DpmPluginSessionAction? decideDpmPluginSession({
  required Set<String> activeSessionKeys,
  required Set<String> presentBefore,
  required Set<String> presentAfter,
  required Map<String, DpmPluginDeparture> departures,
  required List<DpmPluginProjectRef> hellos,
  required bool endWhenDawCloses,
  required bool startWhenDawOpens,
}) {
  if (activeSessionKeys.isNotEmpty) {
    if (!endWhenDawCloses) return null;
    final wasPresent = activeSessionKeys.any(presentBefore.contains);
    final isPresent = activeSessionKeys.any(presentAfter.contains);
    if (!wasPresent || isPresent) return null;

    DpmPluginDeparture? last;
    for (final key in activeSessionKeys) {
      final left = departures[key];
      if (left != null && (last == null || left.at.isAfter(last.at))) last = left;
    }
    return last == null ? null : EndDpmPluginSession(last);
  }

  if (startWhenDawOpens && hellos.isNotEmpty) return StartDpmPluginSession(hellos.last);
  return null;
}

/// [owner] with the plugin's notes edit applied, or null when there is
/// nothing to change. Notes are never silently lost:
/// - the app's notes still read as the edit began ([DpmPluginNotesSet.baseText])
///   → the plugin's text replaces them;
/// - they changed in the app meanwhile → both are kept: the app's, a
///   separator line, then the plugin's.
MusicProject? applyDpmPluginNotesSet(MusicProject owner, DpmPluginNotesSet message) {
  final current = owner.notes ?? '';
  if (current == message.text) return null;

  final merged = current == message.baseText || current.trim().isEmpty
      ? message.text
      : '$current$dpmPluginNotesSeparator${message.text}';
  return merged.isEmpty ? owner.copyWith(clearNotes: true) : owner.copyWith(notes: merged);
}

/// The plugin's captures are copied here, under the preview-songs folder
/// (`<folder>/<project id>/`), so they ride along wherever preview songs do.
const String dpmPluginPreviewFolderName = 'plugin';

/// Whether a capture taken at [capturedAt] becomes [owner]'s latest capture.
///
/// A capture never touches the preview song: it has a slot of its own
/// ([MusicProject.latestCapture]). It only has to be newer than the one
/// kept, or a late message would put an older take back.
bool dpmPluginKeepsCapture(MusicProject owner, DateTime capturedAt) {
  final current = owner.latestCapture;
  return current == null || capturedAt.isAfter(current.capturedAt);
}

/// Whether this device has the DAW plugin: a copy found installed, or one
/// seen running (where the plug-in folders can't be searched, the Flatpak,
/// a sighting is the only sign). Never on a phone. The dashboard shows its
/// capture buttons only then: on every project otherwise, they'd be noise.
bool dpmPluginDetected({required bool isDesktop, required bool anyInstalled, required bool seen}) =>
    isDesktop && (anyInstalled || seen);

/// Whether any project in [projects] still plays the file at [path], as its
/// latest capture or its preview song (a capture adopted as the preview
/// before captures had a slot of their own stays there).
bool dpmPluginCaptureFileInUse(String path, Iterable<MusicProject> projects) =>
    projects.any((x) => x.latestCapture?.path == path || x.previewSongPath == path);
