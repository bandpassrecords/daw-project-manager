// The app and the DAW plugin, each running its own bridge code, on one
// bridge folder. The app side is the real DpmPluginBridgeService over a real
// Hive library in a temp folder; the plugin side is the plugin repo's headless
// driver (plugin_driver.dart), one plugin instance with no DAW. Nothing here
// writes a message by hand: what one side writes, the other side's own code
// reads.
//
// Skips when no driver is built: the plugin repo, checked out next to this
// one and built (`cmake --build build --target DAWProjectManagerBridgeDriver`),
// or DPM_PLUGIN_DRIVER naming the binary. CI builds the plugin release in
// plugin_ref.

import 'dart:io';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/models/todo_item.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/services/plugin_bridge/plugin_bridge_service.dart';
import 'package:daw_project_manager/services/plugin_bridge/plugin_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_plugin_session_hooks.dart';
import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';
import 'plugin_driver.dart';

/// The bridge's view of a real repository: one profile, read and saved
/// through the same calls the app's own library makes.
class _RepositoryLibrary implements DpmPluginLibrary {
  _RepositoryLibrary(this.profile, this.repo);

  final Profile profile;
  final ProjectRepository repo;

  @override
  Future<List<DpmPluginProfileProjects>> load() async =>
      [DpmPluginProfileProjects(profile, repo.getAllProjects())];

  @override
  Future<void> saveProject(String profileId, MusicProject project) => repo.updateProject(project);
}

const _cubase = 'Steinberg Cubase 13';

void main() {
  final driverPath = PluginDriver.locate();

  late Directory hiveDir;
  late Directory scratch;
  late ProjectRepository repo;
  late FakeHooks hooks;
  late DpmPluginBridgeService app;
  late PluginDriver plugin;
  late DateTime now;
  late List<DpmPluginSighting> sightings;

  final solo = Profile(id: 'solo', name: 'Solo', createdAt: DateTime(2025));

  String bridgeDir() => p.join(scratch.path, 'bridge');
  String previewSongsDir() => p.join(scratch.path, 'preview_songs');

  /// A Cubase project in the library, its file in the scratch folder.
  Future<void> addSong(String id, String name, {List<TodoItem>? todos, String? notes, String? previewSongPath}) async {
    final file = File(p.join(scratch.path, 'Projects', name, '$name.cpr'));
    await file.create(recursive: true);
    await repo.updateProject(TestFactories.makeProject(
      id: id,
      filePath: file.path,
      fileName: '$name.cpr',
      dawType: 'Cubase',
      dawVersion: '13',
      todos: todos,
      notes: notes,
      previewSongPath: previewSongPath,
    ));
  }

  MusicProject song(String id) => repo.getAllProjects().firstWhere((x) => x.id == id);

  /// One exchange: the plugin writes what it has, the app applies it and
  /// rewrites the index, the plugin reads that back.
  Future<void> exchange() async {
    await plugin.send('deliver');
    await app.tick();
    await plugin.send('refresh');
  }

  /// The plugin loaded into Cubase with [name] open, linked to its project.
  Future<Map<String, dynamic>> openInCubase(String name) async {
    await app.tick(); // the index the plugin matches against
    await plugin.host(_cubase, 'Cubase Pro Project - $name');
    await plugin.send('refresh');
    final linked = (await plugin.send('autoLink'))['linked'] as Map<String, dynamic>?;
    expect(linked, isNotNull, reason: 'the plugin should recognise "$name" in the window title');
    return linked!;
  }

  setUp(() async {
    hiveDir = await HiveTestHelper.setUp();
    scratch = await Directory.systemTemp.createTemp('dpm_plugin_it_');
    repo = await HiveTestHelper.createRepository(profileId: solo.id);
    hooks = FakeHooks();
    sightings = [];
    now = DateTime.utc(2026, 10, 21, 10);
    app = DpmPluginBridgeService(
      library: _RepositoryLibrary(solo, repo),
      bridgeDir: bridgeDir(),
      previewSongsDir: previewSongsDir(),
      appVersion: '3.0.0',
      clock: () => now,
      sessions: hooks,
      onPluginSeen: sightings.add,
    );
    plugin = await PluginDriver.start(driverPath!, bridgeDir: bridgeDir());
    await plugin.setClock(now);
  });

  tearDown(() async {
    await plugin.quit();
    await HiveTestHelper.tearDown(hiveDir);
    if (await scratch.exists()) await scratch.delete(recursive: true);
  });

  group('the plugin and the app on one bridge folder', skip: driverPath == null ? _noDriver : null, () {
    test('the plugin recognises the open project from the DAW window, not a similar one', () async {
      await addSong('song-a', 'Night Drive');
      await addSong('song-b', 'Night Drive Remix');

      final linked = await openInCubase('Night Drive');

      expect(linked['projectId'], 'song-a');
      expect(linked['profileId'], 'solo');
    });

    test('a to-do added in the plugin lands on the project with the id the plugin gave it', () async {
      await addSong('song-a', 'Night Drive');
      await openInCubase('Night Drive');

      expect((await plugin.send('addTodo', {'text': 'Fix the snare'}))['added'], isTrue);
      final pluginTodo = ((await plugin.state())['todos'] as List).cast<Map<String, dynamic>>()
          .singleWhere((t) => t['text'] == 'Fix the snare');
      await exchange();

      final todo = song('song-a').todos.singleWhere((t) => t.text == 'Fix the snare');
      expect(todo.id, pluginTodo['id']);
      expect(todo.completed, isFalse);
      // The app's rewrite of the index is the plugin's acknowledgement.
      expect((await plugin.state())['undelivered'], 0);
    });

    test('a to-do ticked on either side shows as ticked on the other', () async {
      await addSong('song-a', 'Night Drive', todos: [
        TodoItem(id: 't1', text: 'Mix vocals', createdAt: DateTime(2026, 10)),
        TodoItem(id: 't2', text: 'Bounce stems', createdAt: DateTime(2026, 10)),
      ]);
      await openInCubase('Night Drive');

      // App → plugin.
      final p1 = song('song-a');
      await repo.updateProject(p1.copyWith(todos: [
        for (final t in p1.todos) t.id == 't1' ? t.copyWith(completed: true) : t,
      ]));
      await app.tick();
      await plugin.send('refresh');
      final pluginTodos = {
        for (final t in ((await plugin.state())['todos'] as List).cast<Map<String, dynamic>>()) t['id']: t,
      };
      expect(pluginTodos['t1']!['completed'], isTrue);
      expect(pluginTodos['t2']!['completed'], isFalse);

      // Plugin → app.
      await plugin.send('setTodoCompleted', {'todoId': 't2', 'completed': true});
      await exchange();
      expect(song('song-a').todos.firstWhere((t) => t.id == 't2').completed, isTrue);
    });

    test('notes edited in the plugin replace the app\'s when the app\'s are as the plugin saw them', () async {
      await addSong('song-a', 'Night Drive', notes: 'Verse in D minor');
      await openInCubase('Night Drive');
      expect((await plugin.state())['notes'], 'Verse in D minor');

      await plugin.send('setNotes', {'text': 'Verse in D minor\nChorus lifts to F'});
      await exchange();

      expect(song('song-a').notes, 'Verse in D minor\nChorus lifts to F');
      expect((await plugin.state())['notesPending'], isFalse);
    });

    test('notes edited on both sides at once keep both texts', () async {
      await addSong('song-a', 'Night Drive', notes: 'Verse in D minor');
      await openInCubase('Night Drive');

      await plugin.send('setNotes', {'text': 'Plugin: try a half-time bridge'});
      await repo.updateProject(song('song-a').copyWith(notes: 'App: drums too loud'));
      await exchange();

      final notes = song('song-a').notes!;
      expect(notes, contains('App: drums too loud'));
      expect(notes, contains('Plugin: try a half-time bridge'));
      expect(notes, contains(dpmPluginNotesSeparator.trim()));
    });

    test('the app sees the plugin arrive, and ends the session when the DAW closes the project', () async {
      await addSong('song-a', 'Night Drive');
      await openInCubase('Night Drive');
      await exchange(); // hello
      await plugin.send('heartbeat');
      await app.tick();

      expect(sightings, isNotEmpty);
      expect(sightings.last.hostName, contains('Cubase'));
      expect(app.presentProjects, contains(dpmPluginKey('solo', 'song-a')));

      hooks.active = const DpmPluginProjectRef('solo', 'song-a');
      await plugin.send('goodbye');
      await exchange();

      expect(app.presentProjects, isEmpty);
      expect(hooks.departures.single.reason, DpmPluginDepartureReason.closed);
    });

    test('a DAW that crashes ends the session once its heartbeat goes stale', () async {
      await addSong('song-a', 'Night Drive');
      await openInCubase('Night Drive');
      await exchange();
      await plugin.send('heartbeat');
      await app.tick();
      hooks.active = const DpmPluginProjectRef('solo', 'song-a');

      // No goodbye, no more heartbeats. The app ticks on in steps short
      // enough not to read as the computer having slept.
      await plugin.kill();
      for (var i = 0; i < 12 && hooks.departures.isEmpty; i++) {
        now = now.add(const Duration(seconds: 10));
        await app.tick();
      }

      expect(hooks.departures.single.reason, DpmPluginDepartureReason.stoppedResponding);
      expect(app.presentProjects, isEmpty);
      // quit() in tearDown copes with the process being gone.
    });

    test("a capture becomes the project's latest capture, beside an empty preview", () async {
      await addSong('song-a', 'Night Drive');
      await openInCubase('Night Drive');

      await plugin.send('settings', {'captureMode': 'automatic'});
      // An automatic take is kept from 10 s.
      final captured = await plugin.send('capture', {'seconds': 12.0, 'sampleRate': 48000});
      expect(captured['verdict'], 'keep');
      await exchange();

      final kept = song('song-a').latestCapture;
      expect(kept, isNotNull);
      expect(p.isWithin(p.join(previewSongsDir(), dpmPluginPreviewFolderName, 'song-a'), kept!.path), isTrue);
      expect(File(kept.path).existsSync(), isTrue);
      expect(kept.durationSeconds, closeTo(12, 0.5));
      expect(song('song-a').previewSongPath, isNull, reason: 'a capture never becomes the preview song');
    });

    test('a capture leaves a preview song the user picked alone', () async {
      final picked = File(p.join(Directory.systemTemp.path, 'dpm_it_picked_mix.wav'));
      await picked.writeAsBytes(const [0, 1, 2, 3]);
      addTearDown(() => picked.existsSync() ? picked.deleteSync() : null);
      await addSong('song-a', 'Night Drive', previewSongPath: picked.path);
      await openInCubase('Night Drive');

      await plugin.send('settings', {'captureMode': 'automatic'});
      await plugin.send('capture', {'seconds': 12.0, 'sampleRate': 48000});
      await exchange();

      expect(song('song-a').previewSongPath, picked.path);
      expect(song('song-a').latestCapture, isNotNull);
    });

    test("a longer pass replaces the latest capture, and the earlier take's file goes", () async {
      await addSong('song-a', 'Night Drive');
      await openInCubase('Night Drive');
      await plugin.send('settings', {'captureMode': 'automatic'});

      await plugin.send('capture', {'seconds': 12.0, 'sampleRate': 48000});
      await exchange();
      final first = song('song-a').latestCapture!;

      // Later on the plugin's clock, and at least as long: the plugin keeps it.
      now = now.add(const Duration(minutes: 3));
      await plugin.setClock(now);
      final second = await plugin.send('capture', {'seconds': 20.0, 'sampleRate': 48000});
      expect(second['verdict'], 'keep');
      await exchange();

      final kept = song('song-a').latestCapture!;
      expect(kept.path, isNot(first.path));
      expect(kept.durationSeconds, closeTo(20, 0.5));
      expect(File(kept.path).existsSync(), isTrue);
      expect(File(first.path).existsSync(), isFalse);
    });
  });
}

const _noDriver = 'No plugin bridge driver. Build DAWProjectManagerBridgeDriver in the plugin '
    'repo checked out next to this one, or set DPM_PLUGIN_DRIVER to the binary.';
