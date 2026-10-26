import 'dart:convert';
import 'dart:io';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/services/plugin_bridge/plugin_bridge_service.dart';
import 'package:daw_project_manager/services/plugin_bridge/plugin_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../helpers/fake_plugin_session_hooks.dart';
import '../../helpers/test_factories.dart';

/// An in-memory library: the bridge's whole conversation with the plugin is
/// tested against a temp folder and plain lists, no Hive.
class FakeLibrary implements DpmPluginLibrary {
  FakeLibrary(this.profiles);

  final Map<Profile, List<MusicProject>> profiles;
  final saves = <(String, MusicProject)>[];

  @override
  Future<List<DpmPluginProfileProjects>> load() async =>
      [for (final e in profiles.entries) DpmPluginProfileProjects(e.key, List.of(e.value))];

  @override
  Future<void> saveProject(String profileId, MusicProject project) async {
    saves.add((profileId, project));
    final list = profiles.entries.firstWhere((e) => e.key.id == profileId).value;
    final i = list.indexWhere((x) => x.id == project.id);
    list[i] = project;
  }

  MusicProject project(String profileId, String id) =>
      profiles.entries.firstWhere((e) => e.key.id == profileId).value.firstWhere((x) => x.id == id);
}

void main() {
  late Directory tmp;
  late String bridgeDir;
  late String previewDir;
  late FakeLibrary library;
  late DpmPluginBridgeService bridge;
  var clock = DateTime.utc(2026, 10, 18, 12);

  final solo = Profile(id: 'solo', name: 'Solo', createdAt: DateTime(2025));
  final duo = Profile(id: 'duo', name: 'Duo', createdAt: DateTime(2025));

  var sequence = 0;
  Future<File> drop(String type, Map<String, dynamic> payload,
      {String profileId = 'solo', String projectId = 'p1', String? runId, DateTime? at}) async {
    final file = File(p.join(bridgeDir, 'outbox',
        '20261018T120000000Z-${(sequence++).toString().padLeft(6, '0')}-abcd1234.json'));
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({
      'schema': 1,
      'id': 'm$sequence',
      'type': type,
      'createdAt': (at ?? DateTime.utc(2026, 10, 18, 12)).toUtc().toIso8601String(),
      if (runId != null) 'plugin': {'version': '0.1.0', 'instanceId': 'saved', 'runId': runId},
      'host': {'name': 'Steinberg Cubase 13', 'windowTitle': ''},
      'project': {'id': projectId, 'profileId': profileId},
      'payload': payload,
    }));
    return file;
  }

  Future<File> capture(String name, {String content = 'flac'}) async {
    final file = File(p.join(bridgeDir, 'captures', name));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return file;
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('plugin_bridge_test');
    bridgeDir = p.join(tmp.path, 'plugin_bridge');
    previewDir = p.join(tmp.path, 'preview_songs');
    sequence = 0;
    clock = DateTime.utc(2026, 10, 18, 12);
    library = FakeLibrary({
      solo: [
        TestFactories.makeProject(id: 'p1', fileName: 'Teardrop.cpr', todos: [TestFactories.makeTodo(id: 't1')]),
        TestFactories.makeProject(id: 'stack', isVirtual: true, memberProjectIds: ['v1']),
        TestFactories.makeProject(id: 'v1', fileName: 'Song v1.als', stackId: 'stack'),
      ],
      // The same id in another profile: must never be touched by solo's messages.
      duo: [TestFactories.makeProject(id: 'p1', fileName: 'Duo copy.cpr')],
    });
    bridge = DpmPluginBridgeService(
      library: library,
      bridgeDir: bridgeDir,
      previewSongsDir: previewDir,
      appVersion: '2.10.0',
      clock: () => clock,
    );
  });

  tearDown(() async {
    bridge.stop();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('index.json', () {
    test('is written whole, and rewritten only when the library changes', () async {
      expect(await bridge.writeIndex(), isTrue);
      final index = jsonDecode(await bridge.indexFile.readAsString()) as Map<String, dynamic>;
      expect(index['schema'], 1);
      expect((index['projects'] as List).map((e) => '${e['profileId']}/${e['id']}'), ['solo/p1', 'solo/v1', 'duo/p1']);
      expect(File('${bridge.indexFile.path}.tmp').existsSync(), isFalse);

      clock = clock.add(const Duration(seconds: 3));
      expect(await bridge.writeIndex(), isFalse);

      await library.saveProject('solo', library.project('solo', 'p1').copyWith(todos: []));
      expect(await bridge.writeIndex(), isTrue);
    });

    test('is rewritten if someone deleted it', () async {
      await bridge.writeIndex();
      await bridge.indexFile.delete();
      expect(await bridge.writeIndex(), isTrue);
    });
  });

  group('outbox', () {
    // A run id names the instance's heartbeat file, and a goodbye deletes
    // it: "../../x" once deleted x.json wherever that led.
    for (final runId in ['../../victim', r'..\..\victim']) {
      test('a goodbye with the run id "$runId" deletes nothing outside instances/', () async {
        final victim = File(p.join(tmp.path, 'victim.json'));
        await victim.writeAsString('{}');

        await drop('session.goodbye', {}, runId: runId);
        await bridge.tick();

        expect(victim.existsSync(), isTrue);
      });

      test('a heartbeat with the run id "$runId" is no instance', () async {
        final victim = File(p.join(tmp.path, 'victim.json'));
        await victim.writeAsString('{}');
        final heartbeat = File(p.join(bridgeDir, 'instances', 'hb.json'));
        await heartbeat.parent.create(recursive: true);
        await heartbeat.writeAsString(jsonEncode({
          'schema': 1,
          'runId': runId,
          'lastSeen': clock.toIso8601String(),
          'project': {'id': 'p1', 'profileId': 'solo'},
        }));

        await bridge.tick();
        expect(bridge.presentProjects, isEmpty);
        // Long enough to go stale, which used to delete "its" file.
        clock = clock.add(const Duration(hours: 1));
        await bridge.tick();

        expect(victim.existsSync(), isTrue);
      });
    }

    test('a new to-do lands on the right profile\'s project, and the message is deleted', () async {
      final file = await drop('todo.add', {'todoId': 't9', 'text': 'Automate the filter'});
      expect(await bridge.processOutbox(), 1);

      expect(library.project('solo', 'p1').todos.map((t) => t.id), ['t1', 't9']);
      expect(library.project('duo', 'p1').todos, isEmpty);
      expect(await file.exists(), isFalse);
    });

    test('messages are applied in file-name order', () async {
      await drop('todo.add', {'todoId': 't9', 'text': 'New'});
      await drop('todo.setCompleted', {'todoId': 't9', 'completed': true});
      await drop('todo.setCompleted', {'todoId': 't9', 'completed': false});
      await drop('todo.setCompleted', {'todoId': 't9', 'completed': true});

      await bridge.processOutbox();
      expect(library.project('solo', 'p1').todos.last.completed, isTrue);
    });

    test('a stack member\'s to-do goes to its stack', () async {
      await drop('todo.add', {'todoId': 't5', 'text': 'Shared'}, projectId: 'v1');
      await bridge.processOutbox();
      expect(library.project('solo', 'stack').todos.single.id, 't5');
      expect(library.project('solo', 'v1').todos, isEmpty);
    });

    test('replays, unknown projects, unknown types and garbage change nothing but are cleared', () async {
      await drop('todo.add', {'todoId': 't1', 'text': 'Already there'});
      await drop('todo.add', {'todoId': 'x', 'text': 'Nowhere'}, projectId: 'gone');
      await drop('marker.add', {});
      final garbage = File(p.join(bridgeDir, 'outbox', '20261018T130000000Z-000000-ffffffff.json'));
      await garbage.writeAsString('{ not json');
      final partial = File(p.join(bridgeDir, 'outbox', 'still-writing.tmp'));
      await partial.writeAsString('{');

      expect(await bridge.processOutbox(), 0);
      expect(library.saves, isEmpty);
      final left = Directory(p.join(bridgeDir, 'outbox')).listSync().map((e) => p.basename(e.path));
      expect(left, ['still-writing.tmp']);
    });

    test('a tick forces a fresh index so the plugin sees it arrived', () async {
      await bridge.writeIndex();
      final before = jsonDecode(await bridge.indexFile.readAsString())['generatedAt'];

      clock = clock.add(const Duration(seconds: 5));
      await drop('todo.setCompleted', {'todoId': 't1', 'completed': true});
      await bridge.tick();

      final index = jsonDecode(await bridge.indexFile.readAsString()) as Map<String, dynamic>;
      expect(index['generatedAt'], isNot(before));
      final p1 = (index['projects'] as List).firstWhere((e) => e['profileId'] == 'solo' && e['id'] == 'p1');
      expect(p1['todos'].single['completed'], isTrue);
    });
  });

  group('captures', () {
    String capturedAt(int minute) => DateTime.utc(2026, 10, 18, 12, minute).toIso8601String();

    test('a capture becomes the latest capture, and the preview song is left alone', () async {
      final source = await capture('Teardrop_20261018-120000.flac');
      await drop('capture.ready', {
        'file': 'captures/Teardrop_20261018-120000.flac',
        'durationSeconds': 60,
        'capturedAt': capturedAt(0),
      });

      expect(await bridge.processOutbox(), 1);
      final project = library.project('solo', 'p1');
      final kept = project.latestCapture!;
      expect(p.isWithin(p.join(bridge.dpmPluginPreviewDir, 'p1'), kept.path), isTrue);
      expect(await File(kept.path).readAsString(), 'flac');
      expect(kept.durationSeconds, 60);
      expect(kept.capturedAt.toUtc(), DateTime.utc(2026, 10, 18, 12));
      expect(project.previewSongPath, isNull);
      expect(await source.exists(), isFalse);
    });

    test('a capture never touches a preview song, picked or auto-detected', () async {
      // The gaps the old rule had: a capture took over from a newer
      // auto-detected bounce, and no newer bounce could ever take over back.
      final picked = p.join(tmp.path, 'Final Master.wav');
      final bounce = p.join(tmp.path, 'Song Mixdown.wav');
      await library.saveProject('solo',
          library.project('solo', 'p1').copyWith(previewSongPath: picked, previewSongAutoPath: bounce));

      await capture('c.flac');
      await drop('capture.ready', {'file': 'captures/c.flac', 'capturedAt': capturedAt(0)});
      expect(await bridge.processOutbox(), 1);

      final project = library.project('solo', 'p1');
      expect(project.previewSongPath, picked);
      expect(project.previewSongAutoPath, bounce);
      expect(project.latestCapture, isNotNull);
    });

    test('a newer capture replaces the earlier one and its file', () async {
      await capture('a.flac');
      await drop('capture.ready', {'file': 'captures/a.flac', 'capturedAt': capturedAt(0)});
      await bridge.processOutbox();
      final first = library.project('solo', 'p1').latestCapture!.path;

      await capture('b.flac', content: 'newer');
      await drop('capture.ready',
          {'file': 'captures/b.flac', 'supersedes': 'captures/a.flac', 'capturedAt': capturedAt(5)});
      await bridge.processOutbox();

      final second = library.project('solo', 'p1').latestCapture!.path;
      expect(second, isNot(first));
      expect(await File(second).readAsString(), 'newer');
      expect(await File(first).exists(), isFalse);
    });

    test('an older capture arriving late does not replace a newer one', () async {
      await capture('new.flac', content: 'new');
      await drop('capture.ready', {'file': 'captures/new.flac', 'capturedAt': capturedAt(5)});
      await bridge.processOutbox();
      library.saves.clear();

      final late = await capture('old.flac', content: 'old');
      await drop('capture.ready', {'file': 'captures/old.flac', 'capturedAt': capturedAt(0)});
      expect(await bridge.processOutbox(), 0);

      expect(await File(library.project('solo', 'p1').latestCapture!.path).readAsString(), 'new');
      expect(library.saves, isEmpty);
      expect(await late.exists(), isFalse, reason: "the bridge's copy is cleared either way");
    });

    test('a capture promoted to preview song keeps its file when a newer capture arrives', () async {
      await capture('a.flac');
      await drop('capture.ready', {'file': 'captures/a.flac', 'capturedAt': capturedAt(0)});
      await bridge.processOutbox();
      final promoted = library.project('solo', 'p1').latestCapture!.path;
      await library.saveProject('solo', library.project('solo', 'p1').copyWith(previewSongPath: promoted));

      await capture('b.flac', content: 'newer');
      await drop('capture.ready', {'file': 'captures/b.flac', 'capturedAt': capturedAt(5)});
      await bridge.processOutbox();

      expect(library.project('solo', 'p1').previewSongPath, promoted);
      expect(await File(promoted).exists(), isTrue);
    });

    test('a superseded capture whose file is gone is skipped', () async {
      await drop('capture.ready', {'file': 'captures/gone.flac'});
      expect(await bridge.processOutbox(), 0);
      expect(library.project('solo', 'p1').latestCapture, isNull);
    });

    test('a message can\'t point the app outside the captures folder', () async {
      final outside = File(p.join(tmp.path, 'secret.txt'));
      await outside.writeAsString('keep me');
      await drop('capture.ready', {'file': '../secret.txt'});
      await drop('capture.ready', {'file': 'captures/../../secret.txt'});

      expect(await bridge.processOutbox(), 0);
      expect(await outside.exists(), isTrue);
      expect(library.project('solo', 'p1').latestCapture, isNull);
    });
  });

  group('plugin updates', () {
    const release = DpmPluginRelease('0.2.0', 'https://github.com/bandpassrecords/daw-project-manager-plugin/releases/tag/v0.2.0');

    DpmPluginBridgeService withChecker(Future<DpmPluginRelease?> Function() check, {Future<bool> Function()? allowed}) =>
        DpmPluginBridgeService(
          library: library,
          bridgeDir: bridgeDir,
          previewSongsDir: previewDir,
          appVersion: '2.10.0',
          clock: () => clock,
          checkLatestRelease: check,
          releaseChecksAllowed: allowed,
        );

    Future<Map<String, dynamic>> index(DpmPluginBridgeService b) async =>
        jsonDecode(await b.indexFile.readAsString()) as Map<String, dynamic>;

    test('the release is looked up once a day and written into the index', () async {
      var calls = 0;
      final b = withChecker(() async {
        calls++;
        return release;
      });

      await b.writeIndex();
      expect((await index(b))['plugin']['latestVersion'], '0.2.0');

      clock = clock.add(const Duration(hours: 23));
      await b.writeIndex(force: true);
      expect(calls, 1);

      clock = clock.add(const Duration(hours: 2));
      await b.writeIndex(force: true);
      expect(calls, 2);
    });

    test('a failed lookup is retried an hour later and keeps the last known release', () async {
      final answers = <DpmPluginRelease?>[release, null, null];
      var calls = 0;
      final b = withChecker(() async => answers[calls++]);

      await b.writeIndex();
      clock = clock.add(const Duration(hours: 25));
      await b.writeIndex(force: true);
      expect(calls, 2);
      expect((await index(b))['plugin']['latestVersion'], '0.2.0');

      clock = clock.add(const Duration(minutes: 30));
      await b.writeIndex(force: true);
      expect(calls, 2);
      clock = clock.add(const Duration(minutes: 31));
      await b.writeIndex(force: true);
      expect(calls, 3);
    });

    test('with update checks off, nothing is looked up and no release is named', () async {
      var allowed = true;
      var calls = 0;
      final b = withChecker(() async {
        calls++;
        return release;
      }, allowed: () async => allowed);

      await b.writeIndex();
      expect((await index(b)).containsKey('plugin'), isTrue);

      allowed = false;
      clock = clock.add(const Duration(days: 2));
      expect(await b.writeIndex(), isTrue);   // the release left the index
      expect((await index(b)).containsKey('plugin'), isFalse);
      expect(calls, 1);
    });
  });

  group('work sessions follow the DAW', () {
    late FakeHooks hooks;
    late DpmPluginBridgeService b;

    setUp(() {
      hooks = FakeHooks();
      b = DpmPluginBridgeService(
        library: library,
        bridgeDir: bridgeDir,
        previewSongsDir: previewDir,
        appVersion: '2.10.0',
        clock: () => clock,
        sessions: hooks,
      );
    });

    Future<void> heartbeat(String runId, DateTime lastSeen, {String projectId = 'p1'}) async {
      final file = File(p.join(bridgeDir, 'instances', '$runId.json'));
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({
        'schema': 1,
        'runId': runId,
        'lastSeen': lastSeen.toIso8601String(),
        'project': {'id': projectId, 'profileId': 'solo'},
      }));
    }

    Future<void> after(Duration d) async {
      clock = clock.add(d);
      await b.tick();
    }

    test('closing the project in the DAW ends the session at the goodbye\'s time', () async {
      hooks.active = const DpmPluginProjectRef('solo', 'p1');
      await drop('session.hello', {}, runId: 'r1', at: clock);
      await b.tick();
      expect(b.presentProjects, {'solo/p1'});
      expect(hooks.ended, isEmpty);

      final closedAt = clock.add(const Duration(minutes: 40));
      await drop('session.goodbye', {}, runId: 'r1', at: closedAt);
      await after(const Duration(minutes: 41));

      expect(hooks.ended, [closedAt]);
      expect(hooks.departures.single.reason, DpmPluginDepartureReason.closed);
      expect(hooks.departures.single.hostName, 'Steinberg Cubase 13');
      expect(hooks.departures.single.at.isUtc, isFalse);
      expect(b.presentProjects, isEmpty);
    });

    test('a crashed DAW ends the session at its last heartbeat, once it is stale', () async {
      hooks.active = const DpmPluginProjectRef('solo', 'p1');
      await heartbeat('r1', clock);
      await b.tick();
      final lastBeat = clock.add(const Duration(minutes: 5));
      await heartbeat('r1', lastBeat);
      await after(const Duration(minutes: 5));
      expect(hooks.ended, isEmpty);

      // No more heartbeats: still present for 90 s, then gone at the last one.
      await after(const Duration(seconds: 3));
      await after(const Duration(seconds: 3));
      expect(hooks.ended, isEmpty);
      for (var i = 0; i < 30; i++) {
        await after(const Duration(seconds: 3));
      }
      expect(hooks.ended, [lastBeat]);
      expect(hooks.departures.single.reason, DpmPluginDepartureReason.stoppedResponding);
      expect(File(p.join(bridgeDir, 'instances', 'r1.json')).existsSync(), isFalse);
    });

    test('waking from sleep is not a crash', () async {
      hooks.active = const DpmPluginProjectRef('solo', 'p1');
      await heartbeat('r1', clock);
      await b.tick();

      // The computer slept for two hours; the plugin wakes and beats again.
      clock = clock.add(const Duration(hours: 2));
      await b.tick();
      expect(hooks.ended, isEmpty);
      await heartbeat('r1', clock.add(const Duration(seconds: 5)));
      await after(const Duration(seconds: 6));
      expect(hooks.ended, isEmpty);
      expect(b.presentProjects, {'solo/p1'});
    });

    test('the session ends only when the last instance in the project leaves', () async {
      hooks.active = const DpmPluginProjectRef('solo', 'p1');
      await drop('session.hello', {}, runId: 'master-bus', at: clock);
      await drop('session.hello', {}, runId: 'vocal-bus', at: clock);
      await b.tick();

      await drop('session.goodbye', {}, runId: 'vocal-bus', at: clock.add(const Duration(minutes: 1)));
      await after(const Duration(minutes: 2));
      expect(hooks.ended, isEmpty);

      await drop('session.goodbye', {}, runId: 'master-bus', at: clock);
      await after(const Duration(seconds: 3));
      expect(hooks.ended, hasLength(1));
    });

    test('a session the DAW never had the project open for is left alone', () async {
      hooks.active = const DpmPluginProjectRef('solo', 'p1');
      await drop('session.hello', {}, runId: 'r1', projectId: 'v1', at: clock);
      await b.tick();
      await drop('session.goodbye', {}, runId: 'r1', projectId: 'v1', at: clock);
      await after(const Duration(seconds: 3));
      expect(hooks.ended, isEmpty);
    });

    test('a stack\'s session ends when the version the DAW had open closes', () async {
      hooks.active = const DpmPluginProjectRef('solo', 'stack');
      await drop('session.hello', {}, runId: 'r1', projectId: 'v1', at: clock);
      await b.tick();
      await drop('session.goodbye', {}, runId: 'r1', projectId: 'v1', at: clock);
      await after(const Duration(seconds: 3));
      expect(hooks.ended, hasLength(1));
    });

    test('with the setting off, closing the DAW changes nothing', () async {
      hooks.active = const DpmPluginProjectRef('solo', 'p1');
      hooks.endWhenDawCloses = false;
      await drop('session.hello', {}, runId: 'r1', at: clock);
      await b.tick();
      await drop('session.goodbye', {}, runId: 'r1', at: clock);
      await after(const Duration(seconds: 3));
      expect(hooks.ended, isEmpty);
    });

    test('opening a project in the DAW starts its session when asked to', () async {
      hooks.startWhenDawOpens = true;
      await drop('session.hello', {}, runId: 'r1', at: clock);
      await b.tick();
      expect(hooks.started.single.projectId, 'p1');
    });

    test('an old hello, read after the app was closed, starts nothing', () async {
      hooks.startWhenDawOpens = true;
      await drop('session.hello', {}, runId: 'r1', at: clock.subtract(const Duration(hours: 20)));
      await b.tick();
      expect(hooks.started, isEmpty);
      expect(b.presentProjects, isEmpty);
    });

    test('without any sign of the plugin, no session is ever ended', () async {
      // Someone who does not use the plugin at all: hours of ticks, a sleep,
      // nothing in the bridge folder. The session must run untouched.
      hooks.active = const DpmPluginProjectRef('solo', 'p1');
      for (var i = 0; i < 200; i++) {
        await after(const Duration(seconds: 3));
      }
      await after(const Duration(hours: 3));
      await after(const Duration(seconds: 3));
      expect(hooks.ended, isEmpty);
      expect(hooks.active, isNotNull);
    });

    test('a leftover heartbeat from a crash long ago ends nothing and is cleared', () async {
      hooks.active = const DpmPluginProjectRef('solo', 'p1');
      await heartbeat('old', clock.subtract(const Duration(days: 3)));
      await b.tick();
      expect(hooks.ended, isEmpty);
      expect(File(p.join(bridgeDir, 'instances', 'old.json')).existsSync(), isFalse);
    });
  });

  group('what Settings > DAW plugin shows', () {
    test('hellos and heartbeats report which plugin version runs in which DAW', () async {
      final seen = <DpmPluginSighting>[];
      final b = DpmPluginBridgeService(
        library: library,
        bridgeDir: bridgeDir,
        previewSongsDir: previewDir,
        appVersion: '2.10.0',
        clock: () => clock,
        onPluginSeen: seen.add,
      );

      await drop('session.hello', {}, runId: 'r1', at: clock);
      await b.tick();
      expect(seen.single.version, '0.1.0');
      expect(seen.single.hostName, 'Steinberg Cubase 13');

      final beat = File(p.join(bridgeDir, 'instances', 'r1.json'));
      await beat.parent.create(recursive: true);
      await beat.writeAsString(jsonEncode({
        'runId': 'r1',
        'pluginVersion': '0.1.0',
        'lastSeen': clock.add(const Duration(seconds: 10)).toIso8601String(),
        'project': {'id': 'p1', 'profileId': 'solo'},
      }));
      clock = clock.add(const Duration(seconds: 10));
      await b.tick();
      expect(seen, hasLength(2));
    });

    test('the newest release is reported when looked up, and withdrawn when checks go off', () async {
      final reported = <DpmPluginRelease?>[];
      var allowed = true;
      final b = DpmPluginBridgeService(
        library: library,
        bridgeDir: bridgeDir,
        previewSongsDir: previewDir,
        appVersion: '2.10.0',
        clock: () => clock,
        checkLatestRelease: () async => const DpmPluginRelease('0.2.0', 'u'),
        releaseChecksAllowed: () async => allowed,
        onLatestRelease: reported.add,
      );

      await b.writeIndex();
      expect(reported.single?.version, '0.2.0');

      allowed = false;
      await b.writeIndex(force: true);
      expect(reported, hasLength(2));
      expect(reported.last, isNull);
    });
  });

  test('the launch hint is written whole', () async {
    await writeDpmPluginLaunchHint('solo', library.project('solo', 'p1'), bridgeDir: bridgeDir);
    final hint = jsonDecode(await File(p.join(bridgeDir, 'launch.json')).readAsString());
    expect(hint['projectId'], 'p1');
    expect(hint['profileId'], 'solo');
    expect(DateTime.tryParse(hint['launchedAt']), isNotNull);
  });
}
