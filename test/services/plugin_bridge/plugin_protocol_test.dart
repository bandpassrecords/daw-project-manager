import 'dart:convert';

import 'package:daw_project_manager/models/plugin_capture.dart';
import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/services/plugin_bridge/plugin_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../helpers/test_factories.dart';

void main() {
  final solo = Profile(id: 'solo', name: 'Audio Crawler', createdAt: DateTime(2025));
  final duo = Profile(id: 'duo', name: 'Crawler & Friends', createdAt: DateTime(2025));
  final now = DateTime.utc(2026, 10, 18, 12);

  group('buildDpmPluginIndex', () {
    test('lists every profile\'s projects with their to-dos', () {
      final index = buildDpmPluginIndex([
        DpmPluginProfileProjects(solo, [
          TestFactories.makeProject(
            id: 'p1',
            filePath: p.join('music', 'Teardrop.cpr'),
            fileName: 'Teardrop.cpr',
            dawType: 'Cubase',
            todos: [TestFactories.makeTodo(id: 't1', text: 'Fix kick')],
          ),
        ]),
        DpmPluginProfileProjects(duo, [
          TestFactories.makeProject(id: 'p2', fileName: 'Bounce.flp', dawType: null),
        ]),
      ], generatedAt: now, appVersion: '2.10.0');

      expect(index['schema'], 1);
      expect(index['generatedAt'], '2026-10-18T12:00:00.000Z');
      expect(index['app'], {'version': '2.10.0'});

      final projects = index['projects'] as List;
      expect(projects, hasLength(2));
      expect(projects[0]['id'], 'p1');
      expect(projects[0]['profileId'], 'solo');
      expect(projects[0]['profileName'], 'Audio Crawler');
      expect(projects[0]['name'], 'Teardrop');
      expect(projects[0]['filePath'], p.join('music', 'Teardrop.cpr'));
      expect(projects[0]['dawType'], 'Cubase');
      expect(projects[0]['todos'], [
        {'id': 't1', 'text': 'Fix kick', 'completed': false, 'createdAt': DateTime(2025, 1, 10).toUtc().toIso8601String()},
      ]);
      expect(projects[1]['profileId'], 'duo');
      expect(projects[1]['dawType'], '');
    });

    test('leaves out stacks and archived projects; members carry the stack\'s to-dos', () {
      final stack = TestFactories.makeProject(
        id: 'stack',
        isVirtual: true,
        memberProjectIds: ['v1', 'v2'],
        todos: [TestFactories.makeTodo(id: 'shared', text: 'Shared to-do')],
      );
      final v1 = TestFactories.makeProject(id: 'v1', fileName: 'Song v1.als', stackId: 'stack',
          todos: [TestFactories.makeTodo(id: 'dormant', text: 'Dormant own to-do')]);
      final v2 = TestFactories.makeProject(id: 'v2', fileName: 'Song v2.als', stackId: 'stack');
      final archived = TestFactories.makeProject(id: 'old', archivePath: p.join('archive', 'old.zip'));

      final projects = buildDpmPluginIndex([
        DpmPluginProfileProjects(solo, [stack, v1, v2, archived]),
      ], generatedAt: now, appVersion: '1')['projects'] as List;

      expect(projects.map((e) => e['id']), ['v1', 'v2']);
      for (final member in projects) {
        expect((member['todos'] as List).map((t) => t['id']), ['shared']);
      }
    });

    test('the fingerprint ignores the time, so an unchanged library is not rewritten', () {
      final library = [DpmPluginProfileProjects(solo, [TestFactories.makeProject(id: 'p1')])];
      final a = buildDpmPluginIndex(library, generatedAt: now, appVersion: '1');
      final b = buildDpmPluginIndex(library, generatedAt: now.add(const Duration(minutes: 5)), appVersion: '1');
      expect(dpmPluginIndexFingerprint(a), dpmPluginIndexFingerprint(b));

      final c = buildDpmPluginIndex([
        DpmPluginProfileProjects(solo, [TestFactories.makeProject(id: 'p1', todos: [TestFactories.makeTodo()])]),
      ], generatedAt: now, appVersion: '1');
      expect(dpmPluginIndexFingerprint(c), isNot(dpmPluginIndexFingerprint(a)));
    });
  });

  group('plugin releases', () {
    test('the index names the newest release when one is known', () {
      final library = [DpmPluginProfileProjects(solo, [])];
      final withRelease = buildDpmPluginIndex(library,
          generatedAt: now,
          appVersion: '1',
          latestRelease: const DpmPluginRelease('0.2.0', 'https://github.com/bandpassrecords/daw-project-manager-plugin/releases/tag/v0.2.0'));
      expect(withRelease['plugin'], {
        'latestVersion': '0.2.0',
        'releaseUrl': 'https://github.com/bandpassrecords/daw-project-manager-plugin/releases/tag/v0.2.0',
      });
      expect(buildDpmPluginIndex(library, generatedAt: now, appVersion: '1').containsKey('plugin'), isFalse);
    });

    test('a new release changes the fingerprint, so the index is rewritten', () {
      final library = [DpmPluginProfileProjects(solo, [])];
      final before = buildDpmPluginIndex(library, generatedAt: now, appVersion: '1');
      final after = buildDpmPluginIndex(library,
          generatedAt: now, appVersion: '1', latestRelease: const DpmPluginRelease('0.2.0', 'u'));
      expect(dpmPluginIndexFingerprint(after), isNot(dpmPluginIndexFingerprint(before)));
    });

    test('GitHub\'s latest-release answer is read', () {
      final release = parseDpmPluginRelease({
        'tag_name': 'v0.2.0',
        'html_url': 'https://github.com/bandpassrecords/daw-project-manager-plugin/releases/tag/v0.2.0',
      })!;
      expect(release.version, '0.2.0');
      expect(release.url, 'https://github.com/bandpassrecords/daw-project-manager-plugin/releases/tag/v0.2.0');

      expect(parseDpmPluginRelease({'tag_name': 'nightly', 'html_url': 'u'}), isNull);
      expect(parseDpmPluginRelease({'tag_name': 'v1.2', 'html_url': 'u'}), isNull);
      expect(parseDpmPluginRelease({'html_url': 'u'}), isNull);
    });
  });

  test('the launch hint names the project, its profile and when it opened', () {
    final hint = buildDpmPluginLaunchHint(
      profileId: 'solo',
      project: TestFactories.makeProject(id: 'p1', filePath: p.join('music', 'a.cpr')),
      launchedAt: now,
    );
    expect(hint, {
      'projectId': 'p1',
      'profileId': 'solo',
      'filePath': p.join('music', 'a.cpr'),
      'launchedAt': '2026-10-18T12:00:00.000Z',
    });
  });

  group('parseDpmPluginMessage', () {
    String message(String type, Map<String, dynamic> payload, {Object? project = const {'id': 'p1', 'profileId': 'solo'}}) =>
        jsonEncode({
          'schema': 1,
          'id': 'm1',
          'type': type,
          'createdAt': '2026-10-18T12:00:05.000Z',
          'plugin': {'version': '0.1.0', 'instanceId': 'i'},
          'host': {'name': 'Cubase', 'windowTitle': 'x'},
          'project': project,
          'payload': payload,
        });

    test('reads a new to-do, as one trimmed line', () {
      final m = parseDpmPluginMessage(message('todo.add', {
        'todoId': 't9',
        'text': '  [01:23]  Vocal\ttoo loud \n',
        'createdAt': '2026-10-18T12:00:04.000Z',
      }));
      expect(m, isA<DpmPluginTodoAdd>());
      final add = m as DpmPluginTodoAdd;
      expect(add.project!.profileId, 'solo');
      expect(add.project!.projectId, 'p1');
      expect(add.todoId, 't9');
      expect(add.text, '[01:23] Vocal too loud');
      expect(add.todoCreatedAt, DateTime.utc(2026, 10, 18, 12, 0, 4).toLocal());
    });

    test('reads a tick, a capture and a hello', () {
      final tick = parseDpmPluginMessage(message('todo.setCompleted', {'todoId': 't1', 'completed': true}));
      expect((tick as DpmPluginTodoSetCompleted).completed, isTrue);

      final capture = parseDpmPluginMessage(message('capture.ready', {
        'file': 'captures/Song_1.flac',
        'durationSeconds': 60,
        'capturedAt': '2026-10-18T12:00:00.000Z',
      }));
      expect((capture as DpmPluginCaptureReady).file, 'captures/Song_1.flac');
      expect(capture.durationSeconds, 60.0);

      expect(parseDpmPluginMessage(message('session.hello', {'linkedByUser': true})), isA<DpmPluginHello>());
    });

    test('an unlinked message has no project', () {
      final m = parseDpmPluginMessage(message('capture.ready', {'file': 'captures/x.flac'}, project: null));
      expect(m!.project, isNull);
    });

    test('an unknown type is kept as unknown, to be dropped', () {
      final m = parseDpmPluginMessage(message('marker.add', {}));
      expect((m as DpmPluginUnknownMessage).type, 'marker.add');
    });

    test('garbage and incomplete messages are not messages', () {
      expect(parseDpmPluginMessage('not json'), isNull);
      expect(parseDpmPluginMessage('[1,2]'), isNull);
      expect(parseDpmPluginMessage(jsonEncode({'type': 'todo.add'})), isNull);
      expect(parseDpmPluginMessage(message('todo.add', {'todoId': 't1', 'text': '   '})), isNull);
      expect(parseDpmPluginMessage(message('todo.add', {'text': 'no id'})), isNull);
      expect(parseDpmPluginMessage(message('todo.setCompleted', {'todoId': 't1', 'completed': 'yes'})), isNull);
    });

    test('an over-long to-do is cut', () {
      final m = parseDpmPluginMessage(message('todo.add', {'todoId': 't1', 'text': 'a' * 900})) as DpmPluginTodoAdd;
      expect(m.text.length, dpmPluginMaxTodoLength);
    });
  });

  group('presence', () {
    test('every time from the plugin is local, as the app keeps times', () {
      // The plugin writes UTC with a Z. Kept as UTC, a session once showed as
      // 12:51-10:52 two hours east of UTC.
      expect(dpmPluginTime('2026-10-18T10:52:00.000Z')!.isUtc, isFalse);
      expect(dpmPluginTime('2026-10-18T10:52:00.000Z'), DateTime.utc(2026, 10, 18, 10, 52).toLocal());
      final m = parseDpmPluginMessage(jsonEncode({
        'id': 'm1',
        'type': 'todo.add',
        'createdAt': '2026-10-18T10:52:00.000Z',
        'project': {'id': 'p1', 'profileId': 'solo'},
        'payload': {'todoId': 't1', 'text': 'x', 'createdAt': '2026-10-18T10:51:00.000Z'},
      })) as DpmPluginTodoAdd;
      expect(m.createdAt.isUtc, isFalse);
      expect(m.todoCreatedAt.isUtc, isFalse);
      expect(
        parseDpmPluginHeartbeat(jsonEncode({
          'runId': 'r',
          'lastSeen': '2026-10-18T10:52:00.000Z',
          'project': {'id': 'p1', 'profileId': 'solo'},
        }))!.lastSeen.isUtc,
        isFalse,
      );
    });

    test('hello and goodbye carry the running instance\'s id', () {
      String msg(String type) => jsonEncode({
            'id': 'm1',
            'type': type,
            'createdAt': '2026-10-18T12:42:00.000Z',
            'plugin': {'version': '0.1.0', 'instanceId': 'saved', 'runId': 'run-1'},
            'host': {'name': 'Steinberg Cubase 13', 'windowTitle': 'x'},
            'project': {'id': 'p1', 'profileId': 'solo'},
            'payload': {},
          });
      final hello = parseDpmPluginMessage(msg('session.hello'))!;
      final goodbye = parseDpmPluginMessage(msg('session.goodbye'))!;
      expect(hello, isA<DpmPluginHello>());
      expect(hello.runId, 'run-1');
      expect(goodbye, isA<DpmPluginGoodbye>());
      expect(goodbye.runId, 'run-1');
      expect(goodbye.createdAt, DateTime.utc(2026, 10, 18, 12, 42).toLocal());
      expect(goodbye.hostName, 'Steinberg Cubase 13');
    });

    test('a heartbeat names the instance, its project and when it was last seen', () {
      final beat = parseDpmPluginHeartbeat(jsonEncode({
        'schema': 1,
        'runId': 'run-1',
        'lastSeen': '2026-10-18T12:41:50.000Z',
        'project': {'id': 'p1', 'profileId': 'solo'},
      }))!;
      expect(beat.runId, 'run-1');
      expect(beat.project.projectId, 'p1');
      expect(beat.lastSeen, DateTime.utc(2026, 10, 18, 12, 41, 50).toLocal());

      expect(parseDpmPluginHeartbeat('{'), isNull);
      expect(parseDpmPluginHeartbeat(jsonEncode({'runId': 'r', 'lastSeen': 'x', 'project': null})), isNull);
    });
  });

  group('decideDpmPluginSession', () {
    final left = DateTime.utc(2026, 10, 18, 12, 42);
    DpmPluginDeparture closedAt(DateTime at) => DpmPluginDeparture(at, DpmPluginDepartureReason.closed);
    DpmPluginSessionAction? decide({
      Set<String> active = const {'solo/p1'},
      Set<String> before = const {'solo/p1'},
      Set<String> after = const {},
      Map<String, DpmPluginDeparture>? departed,
      List<DpmPluginProjectRef> hellos = const [],
      bool end = true,
      bool start = false,
    }) =>
        decideDpmPluginSession(
          activeSessionKeys: active,
          presentBefore: before,
          presentAfter: after,
          departures: departed ?? {'solo/p1': closedAt(left)},
          hellos: hellos,
          endWhenDawCloses: end,
          startWhenDawOpens: start,
        );

    test('the DAW letting go of the session\'s project ends it, when it left', () {
      final action = decide();
      expect(action, isA<EndDpmPluginSession>());
      expect((action as EndDpmPluginSession).at, left);
    });

    test('nothing ends while another instance is still in the project', () {
      expect(decide(after: {'solo/p1'}), isNull);
    });

    test('a session for a project no plugin was ever in is never ended', () {
      expect(decide(before: {}), isNull);
    });

    test('another project closing doesn\'t end this session', () {
      expect(decide(before: {'solo/p1', 'solo/p2'}, after: {'solo/p1'}, departed: {'solo/p2': closedAt(left)}), isNull);
    });

    test('with the setting off, nothing ends', () {
      expect(decide(end: false), isNull);
    });

    test('a stack\'s session ends when the last of its versions closes, at the latest departure', () {
      final later = left.add(const Duration(minutes: 3));
      final action = decide(
        active: {'solo/stack', 'solo/v1', 'solo/v2'},
        before: {'solo/v1', 'solo/v2'},
        departed: {'solo/v1': closedAt(left), 'solo/v2': closedAt(later)},
      );
      expect((action as EndDpmPluginSession).at, later);

      expect(decide(active: {'solo/stack', 'solo/v1', 'solo/v2'}, before: {'solo/v1', 'solo/v2'}, after: {'solo/v2'},
          departed: {'solo/v1': closedAt(left)}), isNull);
    });

    test('a hello starts a session only when asked to, and never over a running one', () {
      const opened = DpmPluginProjectRef('solo', 'p9');
      expect(decide(active: {}, before: {}, hellos: [opened]), isNull);
      final start = decide(active: {}, before: {}, hellos: [opened], start: true);
      expect((start as StartDpmPluginSession).project.projectId, 'p9');
      expect(decide(after: {'solo/p1'}, hellos: [opened], start: true), isNull);
    });
  });

  group('applying to-do messages', () {
    final add = DpmPluginTodoAdd('m1', now, const DpmPluginProjectRef('solo', 'p1'),
        todoId: 't9', text: 'Automate the filter', todoCreatedAt: now);

    test('a new to-do keeps the plugin\'s id, so the plugin can see it arrived', () {
      final project = TestFactories.makeProject(todos: [TestFactories.makeTodo(id: 't1')]);
      final updated = applyDpmPluginTodoAdd(project, add)!;
      expect(updated.todos.map((t) => t.id), ['t1', 't9']);
      expect(updated.todos.last.text, 'Automate the filter');
      expect(updated.todos.last.completed, isFalse);
      expect(updated.todos.last.createdAt, now);
    });

    test('applying the same add twice changes nothing', () {
      final once = applyDpmPluginTodoAdd(TestFactories.makeProject(todos: []), add)!;
      expect(applyDpmPluginTodoAdd(once, add), isNull);
    });

    test('a tick sets completed; a repeat or a deleted to-do changes nothing', () {
      final project = TestFactories.makeProject(todos: [TestFactories.makeTodo(id: 't1')]);
      final tick = DpmPluginTodoSetCompleted('m2', now, null, todoId: 't1', completed: true);

      final ticked = applyDpmPluginTodoSetCompleted(project, tick)!;
      expect(ticked.todos.single.completed, isTrue);
      expect(applyDpmPluginTodoSetCompleted(ticked, tick), isNull);

      final gone = DpmPluginTodoSetCompleted('m3', now, null, todoId: 'deleted', completed: true);
      expect(applyDpmPluginTodoSetCompleted(project, gone), isNull);
    });

    test('a stack member\'s to-dos are its stack\'s', () {
      final stack = TestFactories.makeProject(id: 'stack', isVirtual: true);
      final member = TestFactories.makeProject(id: 'v1', stackId: 'stack');
      final loose = TestFactories.makeProject(id: 'p1');
      final orphan = TestFactories.makeProject(id: 'v9', stackId: 'gone');

      expect(dpmPluginOwnerOf(member, [stack, member, loose]).id, 'stack');
      expect(dpmPluginOwnerOf(loose, [stack, member, loose]).id, 'p1');
      expect(dpmPluginOwnerOf(orphan, [stack, orphan]).id, 'v9');
    });
  });

  group('dpmPluginKeepsCapture', () {
    final dir = p.join('data', 'preview_songs', 'plugin');
    final captured = DateTime(2026, 10, 18, 12);
    PluginCapture at(DateTime when) =>
        PluginCapture(path: p.join(dir, 'p1', 'take.flac'), capturedAt: when, durationSeconds: 60);

    test('keeps the first capture of a project', () {
      expect(dpmPluginKeepsCapture(TestFactories.makeProject(), captured), isTrue);
    });

    test('keeps a newer capture, never an older one arriving late', () {
      final project = TestFactories.makeProject(latestCapture: at(captured));
      expect(dpmPluginKeepsCapture(project, captured.add(const Duration(minutes: 1))), isTrue);
      expect(dpmPluginKeepsCapture(project, captured.subtract(const Duration(minutes: 1))), isFalse);
      expect(dpmPluginKeepsCapture(project, captured), isFalse);
    });

    test('ignores the preview song: a picked or auto-detected one never decides', () {
      // Both gaps of the old rule: a capture replaced a newer auto-detected
      // bounce, and a newer bounce could never take over from a capture.
      final bounce = p.join('music', 'Song Mixdown.wav');
      final project = TestFactories.makeProject(previewSongAutoPath: bounce, previewSongPath: p.join('music', 'Master.wav'));
      expect(dpmPluginKeepsCapture(project, captured), isTrue);
    });
  });

  group('dpmPluginDetected', () {
    test('a copy installed, or one seen running, counts on a desktop', () {
      expect(dpmPluginDetected(isDesktop: true, anyInstalled: true, seen: false), isTrue);
      // The Flatpak can't search the plug-in folders: a sighting is its only sign.
      expect(dpmPluginDetected(isDesktop: true, anyInstalled: false, seen: true), isTrue);
      expect(dpmPluginDetected(isDesktop: true, anyInstalled: false, seen: false), isFalse);
    });

    test('never on a phone, whatever a synced sighting says', () {
      expect(dpmPluginDetected(isDesktop: false, anyInstalled: true, seen: true), isFalse);
      expect(dpmPluginDetected(isDesktop: false, anyInstalled: false, seen: false, developerTools: true), isFalse);
      expect(dpmPluginDetected(isDesktop: true, anyInstalled: false, seen: false, developerTools: true), isTrue);
    });
  });

  group('dpmPluginCaptureFileInUse', () {
    final take = p.join('data', 'preview_songs', 'plugin', 'p1', 'take.flac');

    test('a file is in use while a project keeps it as its latest capture', () {
      final project = TestFactories.makeProject(
          latestCapture: PluginCapture(path: take, capturedAt: DateTime(2026, 10), durationSeconds: 30));
      expect(dpmPluginCaptureFileInUse(take, [project]), isTrue);
    });

    test('or as its preview song: promoted, or adopted before captures had a slot', () {
      expect(dpmPluginCaptureFileInUse(take, [TestFactories.makeProject(previewSongPath: take)]), isTrue);
    });

    test('and not otherwise', () {
      expect(dpmPluginCaptureFileInUse(take, [TestFactories.makeProject()]), isFalse);
    });
  });
}
