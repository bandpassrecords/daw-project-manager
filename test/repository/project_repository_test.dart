import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/pending_folder.dart';
import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/models/project_event.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/models/todo_item.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/models/notification_preferences.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import 'package:daw_project_manager/services/deadline_notification_plan.dart';
import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// A [FileSystemEntity] whose [stat] always throws — used to simulate a file
/// that vanishes or becomes unreadable mid-scan (deleted, locked by another
/// program, etc.) without relying on flaky, platform-specific ways to
/// actually break a real file on disk. Only [path] and [stat] are ever
/// touched by the code under test; every other member routes through
/// [noSuchMethod] since it's never called on this path.
class _ThrowingFileSystemEntity implements FileSystemEntity {
  @override
  final String path;

  _ThrowingFileSystemEntity(this.path);

  @override
  Future<FileStat> stat() =>
      throw const FileSystemException('simulated stat failure');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  // #113: todo due dates only reach the notification scheduler if every save
  // hands it this profile's projects *and* releases. It used to read a legacy
  // global box with no releases, wiping every reminder on each edit.
  group('ProjectRepository deadline rescheduling', () {
    late List<({List<MusicProject> projects, List<Release> releases})> calls;

    Future<ProjectRepository> recordingRepository({
      String profileId = 'test-profile',
    }) {
      return HiveTestHelper.createRepository(
        profileId: profileId,
        rescheduleDeadlineNotifications: ({
          required List<MusicProject> projects,
          required List<Release> releases,
        }) async {
          calls.add((projects: projects, releases: releases));
        },
      );
    }

    Release makeRelease({List<TodoItem> todos = const []}) => Release(
          id: 'r1',
          title: 'Summer EP',
          trackIds: const [],
          todos: todos,
        );

    setUp(() => calls = []);

    test("updateProject hands over this profile's projects and releases",
        () async {
      final repo = await recordingRepository();
      await repo.releasesBox.put(
        'r1',
        makeRelease(todos: [
          TestFactories.makeTodo(id: 'art', dueAt: DateTime(2030, 6, 20)),
        ]),
      );

      await repo.updateProject(TestFactories.makeProject(
        id: 'p1',
        todos: [
          TestFactories.makeTodo(id: 'vox', dueAt: DateTime(2030, 6, 18)),
        ],
      ));

      expect(calls, hasLength(1));
      expect(calls.single.projects.map((p) => p.id), ['p1']);
      expect(calls.single.releases.map((r) => r.id), ['r1']);

      // What was handed over is enough to plan both todo reminders.
      final todoIds = planDeadlineNotifications(
        preferences: NotificationPreferences(reminderDays: const []),
        now: DateTime(2030, 6, 1),
        projects: calls.single.projects,
        releases: calls.single.releases,
      ).map((o) => o.todo?.id);
      expect(todoIds, containsAll(['vox', 'art']));
    });

    test("does not read another profile's projects", () async {
      final other = await HiveTestHelper.createRepository(profileId: 'other');
      await other.projectsBox.put(
          'elsewhere', TestFactories.makeProject(id: 'elsewhere'));

      final repo = await recordingRepository();
      await repo.updateProject(TestFactories.makeProject(id: 'p1'));

      expect(calls.single.projects.map((p) => p.id), ['p1']);
    });

    test('updateRelease reschedules with the new todo due date', () async {
      final repo = await recordingRepository();
      final due = DateTime(2030, 6, 20);

      await repo.updateRelease(makeRelease(todos: [
        TestFactories.makeTodo(id: 'art', dueAt: due),
      ]));

      expect(calls, hasLength(1));
      expect(calls.single.releases.single.todos.single.dueAt, due);
    });

    test('addRelease reschedules', () async {
      final repo = await recordingRepository();
      await repo.addRelease(makeRelease());
      expect(calls.single.releases.map((r) => r.id), ['r1']);
    });

    test('deleteRelease reschedules without the deleted release', () async {
      final repo = await recordingRepository();
      await repo.releasesBox.put('r1', makeRelease());

      await repo.deleteRelease('r1');

      expect(calls.single.releases, isEmpty);
    });

    test('deleteProjectsPermanently reschedules without the deleted project',
        () async {
      final repo = await recordingRepository();
      await repo.projectsBox.put('p1', TestFactories.makeProject(id: 'p1'));

      await repo.deleteProjectsPermanently(['p1']);

      expect(calls.single.projects, isEmpty);
    });

    test('a failing scheduler does not fail the save', () async {
      final repo = await HiveTestHelper.createRepository(
        rescheduleDeadlineNotifications: ({
          required List<MusicProject> projects,
          required List<Release> releases,
        }) async =>
            throw StateError('plugin unavailable'),
      );

      await repo.updateProject(TestFactories.makeProject(id: 'p1'));

      expect(repo.getById('p1'), isNotNull);
    });
  });

  group('ProjectRepository.updateProject', () {
    test('bumps updatedAt to approximately now', () async {
      final repo = await HiveTestHelper.createRepository();
      final project = TestFactories.makeProject(
        updatedAt: DateTime(2020, 1, 1),
      );
      await repo.updateProject(project);

      final saved = repo.getById(project.id)!;
      final diff = DateTime.now().difference(saved.updatedAt).abs();
      expect(diff.inSeconds, lessThan(5));
    });

    test('does NOT change lastModifiedAt', () async {
      final repo = await HiveTestHelper.createRepository();
      final modifiedAt = DateTime(2024, 6, 15, 10, 0, 0);
      final project = TestFactories.makeProject(lastModifiedAt: modifiedAt);

      await repo.updateProject(project);

      final saved = repo.getById(project.id)!;
      expect(saved.lastModifiedAt, modifiedAt);
    });

    test('preserves all other fields', () async {
      final repo = await HiveTestHelper.createRepository();
      final original = TestFactories.makeProject(
        bpm: 140.0,
        notes: 'great track',
        status: 'Mastering',
        musicalKey: 'D minor',
      );

      await repo.updateProject(original);
      final saved = repo.getById(original.id)!;

      expect(saved.bpm, 140.0);
      expect(saved.notes, 'great track');
      expect(saved.status, 'Mastering');
      expect(saved.musicalKey, 'D minor');
    });

    test('creates project if it does not exist yet', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getAllProjects(), isEmpty);

      final project = TestFactories.makeProject(id: 'new-id');
      await repo.updateProject(project);

      expect(repo.getAllProjects().length, 1);
      expect(repo.getById('new-id'), isNotNull);
    });
  });

  group('ProjectRepository.restoreProject', () {
    test('preserves lastModifiedAt exactly (does not bump)', () async {
      final repo = await HiveTestHelper.createRepository();
      final modifiedAt = DateTime(2019, 3, 22, 15, 30, 0);
      final project = TestFactories.makeProject(lastModifiedAt: modifiedAt);

      await repo.restoreProject(project);

      final saved = repo.getById(project.id)!;
      expect(saved.lastModifiedAt, modifiedAt);
    });

    test('preserves updatedAt exactly (does not bump)', () async {
      final repo = await HiveTestHelper.createRepository();
      final updatedAt = DateTime(2019, 3, 22, 16, 0, 0);
      final project = TestFactories.makeProject(updatedAt: updatedAt);

      await repo.restoreProject(project);

      final saved = repo.getById(project.id)!;
      expect(saved.updatedAt, updatedAt);
    });

    test('preserves fileCreatedAt', () async {
      final repo = await HiveTestHelper.createRepository();
      final fileCreatedAt = DateTime(2018, 1, 1);
      final project = TestFactories.makeProject(fileCreatedAt: fileCreatedAt);

      await repo.restoreProject(project);

      final saved = repo.getById(project.id)!;
      expect(saved.fileCreatedAt, fileCreatedAt);
    });

    test('overwrites existing project completely', () async {
      final repo = await HiveTestHelper.createRepository();
      final original = TestFactories.makeProject(status: 'Idea');
      await repo.updateProject(original);

      final fromBackup = TestFactories.makeProject(
        id: original.id,
        status: 'Finished',
        lastModifiedAt: DateTime(2021, 5, 5),
        updatedAt: DateTime(2021, 5, 5),
      );
      await repo.restoreProject(fromBackup);

      final saved = repo.getById(original.id)!;
      expect(saved.status, 'Finished');
      expect(saved.lastModifiedAt, DateTime(2021, 5, 5));
    });
  });

  group('ProjectRepository.getById', () {
    test('returns project for matching id', () async {
      final repo = await HiveTestHelper.createRepository();
      final project = TestFactories.makeProject(id: 'find-me');
      await repo.restoreProject(project);

      expect(repo.getById('find-me'), isNotNull);
      expect(repo.getById('find-me')!.id, 'find-me');
    });

    test('returns null for unknown id', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getById('does-not-exist'), isNull);
    });
  });

  group('ProjectRepository.getByPath', () {
    test('returns project for matching path', () async {
      final repo = await HiveTestHelper.createRepository();
      final project = TestFactories.makeProject(filePath: '/music/project.als');
      await repo.restoreProject(project);

      expect(repo.getByPath('/music/project.als'), isNotNull);
    });

    test('returns null for non-matching path', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getByPath('/does/not/exist.als'), isNull);
    });
  });

  group('ProjectRepository.getAllProjects', () {
    test('returns empty list when no projects stored', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getAllProjects(), isEmpty);
    });

    test('returns all stored projects', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.restoreProject(TestFactories.makeProject(id: 'p1'));
      await repo.restoreProject(TestFactories.makeProject(id: 'p2'));
      await repo.restoreProject(TestFactories.makeProject(id: 'p3'));

      expect(repo.getAllProjects().length, 3);
    });
  });

  group('ProjectRepository.custom phases', () {
    test(
      'getCustomPhases returns the 5 default phases when not configured',
      () async {
        final repo = await HiveTestHelper.createRepository();
        expect(repo.getCustomPhases(), [
          'Idea',
          'Arranging',
          'Mixing',
          'Mastering',
          'Finished',
        ]);
      },
    );

    test('setCustomPhases / getCustomPhases round-trip', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setCustomPhases(['Draft', 'WIP', 'Done']);
      expect(repo.getCustomPhases(), ['Draft', 'WIP', 'Done']);
    });

    test('getCustomPhases falls back to defaults on malformed JSON', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.appSettingsBox.put('test-profile_phases', 'not valid json{{');
      expect(repo.getCustomPhases(), [
        'Idea',
        'Arranging',
        'Mixing',
        'Mastering',
        'Finished',
      ]);
    });

    test('getCustomPhases returns an unmodifiable list', () async {
      final repo = await HiveTestHelper.createRepository();
      final phases = repo.getCustomPhases();
      expect(() => (phases as dynamic).add('Extra'), throwsUnsupportedError);
    });
  });

  group('ProjectRepository.phase colors', () {
    test('getPhaseColors returns empty map when not configured', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getPhaseColors(), isEmpty);
    });

    test('setPhaseColors / getPhaseColors round-trip', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setPhaseColors({'Mixing': '#FF5733', 'Finished': '#2ECC71'});
      final colors = repo.getPhaseColors();
      expect(colors['Mixing'], '#FF5733');
      expect(colors['Finished'], '#2ECC71');
    });

    test('getPhaseColors returns empty map on malformed JSON', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.appSettingsBox.put('test-profile_phase_colors', '{bad}');
      expect(repo.getPhaseColors(), isEmpty);
    });
  });

  group('ProjectRepository.finished phases', () {
    test(
      'getFinishedPhases defaults to {"Finished"} when not configured',
      () async {
        final repo = await HiveTestHelper.createRepository();
        expect(repo.getFinishedPhases(), {'Finished'});
      },
    );

    test('setFinishedPhases / getFinishedPhases round-trip', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setFinishedPhases({'Released', 'Archived'});
      expect(repo.getFinishedPhases(), {'Released', 'Archived'});
    });

    test('setFinishedPhase wraps a single phase into a set', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setFinishedPhase('Mastering');
      expect(repo.getFinishedPhases(), {'Mastering'});
    });

    test('migrates legacy single-phase key when new key is absent', () async {
      final repo = await HiveTestHelper.createRepository();
      // Simulate a DB written before the multi-phase feature was added
      await repo.appSettingsBox.put('test-profile_finished_phase', 'Released');
      expect(repo.getFinishedPhases(), {'Released'});
    });
  });

  group('ProjectRepository.custom mixdown folders', () {
    test(
      'getCustomMixdownFolders returns empty list when not configured',
      () async {
        final repo = await HiveTestHelper.createRepository();
        expect(repo.getCustomMixdownFolders(), isEmpty);
      },
    );

    test(
      'setCustomMixdownFolders saves trimmed, non-empty values in order',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.setCustomMixdownFolders(['  Exports  ', 'Mixdowns', '']);
        expect(repo.getCustomMixdownFolders(), ['Exports', 'Mixdowns']);
      },
    );

    test(
      'setCustomMixdownFolders with empty list deletes the setting',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.setCustomMixdownFolders(['Exports']);
        await repo.setCustomMixdownFolders([]);
        expect(repo.getCustomMixdownFolders(), isEmpty);
      },
    );

    test(
      'setCustomMixdownFolders with only blank entries deletes the setting',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.setCustomMixdownFolders(['Exports']);
        await repo.setCustomMixdownFolders(['  ', '']);
        expect(repo.getCustomMixdownFolders(), isEmpty);
      },
    );

    test(
      'migrates the legacy single-folder key when the new key is absent',
      () async {
        final repo = await HiveTestHelper.createRepository();
        // Simulate a DB written before the multi-folder feature was added.
        await repo.appSettingsBox.put('customMixdownFolder', 'LegacyMixdowns');
        expect(repo.getCustomMixdownFolders(), ['LegacyMixdowns']);
      },
    );

    test('new multi-folder key takes precedence over the legacy key', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.appSettingsBox.put('customMixdownFolder', 'LegacyMixdowns');
      await repo.setCustomMixdownFolders(['NewMixdowns']);
      expect(repo.getCustomMixdownFolders(), ['NewMixdowns']);
    });
  });

  group('ProjectRepository.custom mixdown folders by DAW', () {
    test(
      'getCustomMixdownFoldersByDaw returns empty map when not configured',
      () async {
        final repo = await HiveTestHelper.createRepository();
        expect(repo.getCustomMixdownFoldersByDaw(), isEmpty);
      },
    );

    test(
      'setCustomMixdownFoldersByDaw saves trimmed, non-empty values per DAW',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.setCustomMixdownFoldersByDaw({
          'Ableton Live': ['  Exports  ', 'Mixdowns', ''],
          'FL Studio': ['Renders'],
        });
        expect(repo.getCustomMixdownFoldersByDaw(), {
          'Ableton Live': ['Exports', 'Mixdowns'],
          'FL Studio': ['Renders'],
        });
      },
    );

    test(
      'setCustomMixdownFoldersByDaw drops DAW keys left with no folders after trimming',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.setCustomMixdownFoldersByDaw({
          'Ableton Live': ['Exports'],
          'FL Studio': ['  ', ''],
        });
        expect(repo.getCustomMixdownFoldersByDaw(), {
          'Ableton Live': ['Exports'],
        });
      },
    );

    test(
      'setCustomMixdownFoldersByDaw with an empty map deletes the setting',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.setCustomMixdownFoldersByDaw({
          'Ableton Live': ['Exports'],
        });
        await repo.setCustomMixdownFoldersByDaw({});
        expect(repo.getCustomMixdownFoldersByDaw(), isEmpty);
      },
    );

    test(
      'setCustomMixdownFoldersByDaw overwrites the previously stored map',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.setCustomMixdownFoldersByDaw({
          'Ableton Live': ['Exports'],
        });
        await repo.setCustomMixdownFoldersByDaw({
          'FL Studio': ['Renders'],
        });
        expect(repo.getCustomMixdownFoldersByDaw(), {
          'FL Studio': ['Renders'],
        });
      },
    );
  });

  group('ProjectRepository.scan root display names', () {
    test('addRoot auto-fills displayName from the folder\'s own name', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/home/artist/Music/Projects');

      final root = repo.getRoots().single;
      expect(root.displayName, 'Projects');
    });

    test('setRootDisplayName sets a custom label', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/home/artist/Music/Projects');
      final root = repo.getRoots().single;

      await repo.setRootDisplayName(root.id, 'My LMMS Projects');

      expect(repo.getRoots().single.displayName, 'My LMMS Projects');
    });

    test('setRootDisplayName trims whitespace', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/home/artist/Music/Projects');
      final root = repo.getRoots().single;

      await repo.setRootDisplayName(root.id, '  My Projects  ');

      expect(repo.getRoots().single.displayName, 'My Projects');
    });

    test('setRootDisplayName with null reverts to the auto-derived folder name', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/home/artist/Music/Projects');
      final root = repo.getRoots().single;
      await repo.setRootDisplayName(root.id, 'Custom name');

      await repo.setRootDisplayName(root.id, null);

      expect(repo.getRoots().single.displayName, 'Projects');
    });

    test('setRootDisplayName with a blank string reverts to the auto-derived folder name', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/home/artist/Music/Projects');
      final root = repo.getRoots().single;
      await repo.setRootDisplayName(root.id, 'Custom name');

      await repo.setRootDisplayName(root.id, '   ');

      expect(repo.getRoots().single.displayName, 'Projects');
    });

    test('setRootDisplayName is a no-op for an unknown root id', () async {
      final repo = await HiveTestHelper.createRepository();
      // Should not throw.
      await repo.setRootDisplayName('does-not-exist', 'Whatever');
    });
  });

  group('ProjectRepository.DAW launch commands', () {
    test('getDawLaunchCommandPaths is empty when not configured', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getDawLaunchCommandPaths('Zrythm'), isEmpty);
    });

    test('addDawLaunchCommand saves a trimmed path per DAW', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addDawLaunchCommand('Zrythm', '  /opt/zrythm/zrythm  ');
      expect(repo.getDawLaunchCommandPaths('Zrythm'), ['/opt/zrythm/zrythm']);
      expect(repo.getDawLaunchCommands(), {
        'Zrythm': ['/opt/zrythm/zrythm'],
      });
    });

    test('addDawLaunchCommand keeps several ordered paths for one DAW', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addDawLaunchCommand('Ableton Live', '/Applications/Live 11.app');
      await repo.addDawLaunchCommand('Ableton Live', '/Applications/Live 12.app');
      expect(repo.getDawLaunchCommandPaths('Ableton Live'), [
        '/Applications/Live 11.app',
        '/Applications/Live 12.app',
      ]);
    });

    test('addDawLaunchCommand ignores a duplicate and a blank path', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addDawLaunchCommand('Zrythm', '/opt/zrythm/zrythm');
      await repo.addDawLaunchCommand('Zrythm', '/opt/zrythm/zrythm');
      await repo.addDawLaunchCommand('Zrythm', '   ');
      expect(repo.getDawLaunchCommandPaths('Zrythm'), ['/opt/zrythm/zrythm']);
    });

    test('addDawLaunchCommand keeps entries for other DAWs independent', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addDawLaunchCommand('Zrythm', '/opt/zrythm/zrythm');
      await repo.addDawLaunchCommand('Ardour', '/opt/Ardour/Ardour.AppImage');
      expect(repo.getDawLaunchCommands(), {
        'Zrythm': ['/opt/zrythm/zrythm'],
        'Ardour': ['/opt/Ardour/Ardour.AppImage'],
      });
    });

    test('removeDawLaunchCommand drops one path, keeping the rest', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addDawLaunchCommand('Ableton Live', '/a.app');
      await repo.addDawLaunchCommand('Ableton Live', '/b.app');
      await repo.removeDawLaunchCommand('Ableton Live', '/a.app');
      expect(repo.getDawLaunchCommandPaths('Ableton Live'), ['/b.app']);
    });

    test('removing the last path drops the DAW and clears the setting', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addDawLaunchCommand('Zrythm', '/opt/zrythm/zrythm');
      await repo.removeDawLaunchCommand('Zrythm', '/opt/zrythm/zrythm');
      expect(repo.getDawLaunchCommands(), isEmpty);
      expect(repo.appSettingsBox.get('dawLaunchCommandsByDaw'), isNull);
    });

    test('clearDawLaunchCommands removes only that DAW', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addDawLaunchCommand('Zrythm', '/z1');
      await repo.addDawLaunchCommand('Zrythm', '/z2');
      await repo.addDawLaunchCommand('Ardour', '/a1');
      await repo.clearDawLaunchCommands('Zrythm');
      expect(repo.getDawLaunchCommands(), {
        'Ardour': ['/a1'],
      });
    });

    test('reads the legacy single-string-per-DAW JSON shape', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.appSettingsBox.put(
        'dawLaunchCommandsByDaw',
        '{"Zrythm":"/opt/zrythm/zrythm","Ardour":["/a1","/a2"]}',
      );
      expect(repo.getDawLaunchCommands(), {
        'Zrythm': ['/opt/zrythm/zrythm'],
        'Ardour': ['/a1', '/a2'],
      });
    });
  });

  group('ProjectRepository.pending folders', () {
    test('getPendingFolders returns empty list when not configured', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getPendingFolders(), isEmpty);
    });

    test('addPendingFolder / getPendingFolders round-trip', () async {
      final repo = await HiveTestHelper.createRepository();
      final folder = PendingFolder(
        id: 'pf-1',
        path: '/music/project',
        createdAt: DateTime(2025, 1, 1),
      );
      await repo.addPendingFolder(folder);
      final saved = repo.getPendingFolders();
      expect(saved.length, 1);
      expect(saved.first.id, 'pf-1');
      expect(saved.first.path, '/music/project');
    });

    test(
      'addPendingFolder deduplicates by path — new entry replaces old',
      () async {
        final repo = await HiveTestHelper.createRepository();
        final old = PendingFolder(
          id: 'pf-old',
          path: '/same',
          createdAt: DateTime(2025, 1, 1),
        );
        final newer = PendingFolder(
          id: 'pf-new',
          path: '/same',
          createdAt: DateTime(2025, 6, 1),
        );
        await repo.addPendingFolder(old);
        await repo.addPendingFolder(newer);
        final folders = repo.getPendingFolders();
        expect(folders.length, 1);
        expect(folders.first.id, 'pf-new');
      },
    );

    test('removePendingFolder removes by id, keeps others', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addPendingFolder(
        PendingFolder(id: 'pf-1', path: '/a', createdAt: DateTime(2025, 1, 1)),
      );
      await repo.addPendingFolder(
        PendingFolder(id: 'pf-2', path: '/b', createdAt: DateTime(2025, 1, 1)),
      );
      await repo.removePendingFolder('pf-1');
      final folders = repo.getPendingFolders();
      expect(folders.length, 1);
      expect(folders.first.id, 'pf-2');
    });

    test('updatePendingFolder replaces the existing entry', () async {
      final repo = await HiveTestHelper.createRepository();
      final original = PendingFolder(
        id: 'pf-1',
        path: '/a',
        createdAt: DateTime(2025, 1, 1),
      );
      await repo.addPendingFolder(original);
      final updated = original.copyWith(sessionStartedAt: DateTime(2025, 3, 1));
      await repo.updatePendingFolder(updated);
      final folders = repo.getPendingFolders();
      expect(folders.length, 1);
      expect(folders.first.sessionStartedAt, DateTime(2025, 3, 1));
    });

    test(
      'resolveCompletedPendingFolders removes non-existent folders',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.addPendingFolder(
          PendingFolder(
            id: 'pf-gone',
            path: '/definitely/does/not/exist/on/disk',
            createdAt: DateTime(2025, 1, 1),
          ),
        );
        final removed = await repo.resolveCompletedPendingFolders();
        expect(removed, contains('pf-gone'));
        expect(repo.getPendingFolders(), isEmpty);
      },
    );

    test(
      'resolveCompletedPendingFolders removes folders that contain a DAW project file',
      () async {
        final dir = await Directory.systemTemp.createTemp('resolve_done_');
        try {
          await File('${dir.path}/project.als').create();
          final repo = await HiveTestHelper.createRepository();
          await repo.addPendingFolder(
            PendingFolder(
              id: 'pf-done',
              path: dir.path,
              createdAt: DateTime(2025, 1, 1),
            ),
          );
          final removed = await repo.resolveCompletedPendingFolders();
          expect(removed, contains('pf-done'));
          expect(repo.getPendingFolders(), isEmpty);
        } finally {
          await dir.delete(recursive: true);
        }
      },
    );

    test(
      'resolveCompletedPendingFolders keeps folders that exist and have no project file',
      () async {
        final dir = await Directory.systemTemp.createTemp('resolve_keep_');
        try {
          final repo = await HiveTestHelper.createRepository();
          await repo.addPendingFolder(
            PendingFolder(
              id: 'pf-empty',
              path: dir.path,
              createdAt: DateTime(2025, 1, 1),
            ),
          );
          final removed = await repo.resolveCompletedPendingFolders();
          expect(removed, isEmpty);
          expect(repo.getPendingFolders().length, 1);
        } finally {
          await dir.delete(recursive: true);
        }
      },
    );
  });

  group('ProjectRepository.watchAllProjects', () {
    // Regression: _scanAll in dashboard_page.dart was missing
    // ref.invalidate(allProjectsStreamProvider) after completing a scan,
    // so the table would not refresh until the user navigated away and back.
    // The fix relies on watchAllProjects() emitting after every Box.put(),
    // which these tests verify at the repository level.

    test('emits initial snapshot immediately on subscribe', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(TestFactories.makeProject(id: 'p1'));
      await repo.updateProject(TestFactories.makeProject(id: 'p2'));

      final first = await repo.watchAllProjects().first;
      expect(first.map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test('emits updated list after a project is saved', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(TestFactories.makeProject(id: 'existing'));

      // Collect all emissions via listen so no events are missed. Writes are
      // debounced (200ms) so the dashboard doesn't re-filter/re-sort on
      // every single Box.put() during a scan — wait past that window before
      // asserting on the post-write emission.
      final emissions = <List<MusicProject>>[];
      final sub = repo.watchAllProjects().listen(emissions.add);
      await Future.delayed(Duration.zero);

      await repo.updateProject(TestFactories.makeProject(id: 'newly-added'));
      await Future.delayed(const Duration(milliseconds: 250));
      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.any((p) => p.id == 'newly-added'), isTrue);
    });

    test('emits updated lastModifiedAt after rescan upsert', () async {
      // Simulates the rescan path: upsertFromFileSystemEntity calls
      // projectsBox.put() unconditionally, which must trigger a Box.watch()
      // event so the dashboard table reflects the new date.
      final repo = await HiveTestHelper.createRepository();
      final original = TestFactories.makeProject(
        id: 'scanned',
        lastModifiedAt: DateTime(2024, 1, 1),
      );
      await repo.updateProject(original);

      final emissions = <List<MusicProject>>[];
      final sub = repo.watchAllProjects().listen(emissions.add);
      await Future.delayed(Duration.zero);

      final rescanned = original.copyWith(
        lastModifiedAt: DateTime(2025, 6, 10),
      );
      await repo.restoreProject(rescanned);
      await Future.delayed(const Duration(milliseconds: 250));
      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      final saved = emissions.last.firstWhere((p) => p.id == 'scanned');
      expect(saved.lastModifiedAt, DateTime(2025, 6, 10));
    });

    test(
      'a pending debounced emit does not throw if the box closes first',
      () async {
        // Regression: repositoryProvider's onDispose closes a profile's boxes
        // on every profile switch (to avoid keeping every visited profile
        // resident in memory). If that close races ahead of the outgoing
        // allProjectsStreamProvider subscription being cancelled, the 200ms
        // debounce Timer here fires afterward and used to call
        // projectsBox.values on an already-closed box — a HiveError thrown
        // from inside a bare Timer callback, i.e. an uncaught async exception
        // (reported in the field as "Box has already been closed" on every
        // profile switch).
        final repo = await HiveTestHelper.createRepository();
        await repo.updateProject(TestFactories.makeProject(id: 'p1'));

        final sub = repo.watchAllProjects().listen((_) {});
        await Future.delayed(Duration.zero);

        // Schedules the debounce timer, then closes the box before it fires —
        // simulating the profile-switch race without needing two profiles.
        await repo.updateProject(TestFactories.makeProject(id: 'p2'));
        await repo.projectsBox.close();

        // If unguarded, the pending Timer fires during this wait and throws
        // with nothing to catch it, failing this test via an uncaught error.
        await Future.delayed(const Duration(milliseconds: 300));
        await sub.cancel();
      },
    );
  });

  group('ProjectRepository.removeRoot', () {
    test('removes projects whose filePath is under the root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
        TestFactories.makeProject(id: 'p1', filePath: '/rootA/track1.als'),
      );
      await repo.updateProject(
        TestFactories.makeProject(id: 'p2', filePath: '/rootA/sub/track2.als'),
      );

      await repo.removeRoot(rootId);

      expect(repo.getById('p1'), isNull);
      expect(repo.getById('p2'), isNull);
    });

    test('preserves projects under a different root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
        TestFactories.makeProject(id: 'inA', filePath: '/rootA/track.als'),
      );
      await repo.updateProject(
        TestFactories.makeProject(id: 'inB', filePath: '/rootB/other.als'),
      );

      await repo.removeRoot(rootId);

      expect(repo.getById('inA'), isNull);
      expect(repo.getById('inB'), isNotNull);
    });

    test('preserves projects referenced in a release', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
        TestFactories.makeProject(id: 'normal', filePath: '/rootA/normal.als'),
      );
      await repo.updateProject(
        TestFactories.makeProject(
          id: 'protected',
          filePath: '/rootA/protected.als',
        ),
      );
      await repo.addRelease(
        Release(id: 'r1', title: 'EP', trackIds: ['protected']),
      );

      await repo.removeRoot(rootId);

      expect(repo.getById('normal'), isNull);
      expect(repo.getById('protected'), isNotNull);
    });

    test('removes the root entry from the roots box', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.removeRoot(rootId);

      expect(repo.getRoots(), isEmpty);
    });

    test('does nothing when root id is not found', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(
        TestFactories.makeProject(id: 'p1', filePath: '/rootA/track.als'),
      );

      await repo.removeRoot('no-such-root-id');

      expect(repo.getById('p1'), isNotNull);
    });
  });

  group('ProjectRepository.relocateRoot', () {
    test('updates the root path', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.relocateRoot(rootId, '/rootB');

      expect(p.normalize(repo.getRoots().first.path), p.normalize('/rootB'));
    });

    test('rewrites filePath for every project under the old root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
        TestFactories.makeProject(id: 'p1', filePath: '/rootA/track1.als'),
      );
      await repo.updateProject(
        TestFactories.makeProject(id: 'p2', filePath: '/rootA/sub/track2.als'),
      );

      await repo.relocateRoot(rootId, '/rootB');

      expect(
        p.normalize(repo.getById('p1')!.filePath),
        p.normalize('/rootB/track1.als'),
      );
      expect(
        p.normalize(repo.getById('p2')!.filePath),
        p.normalize('/rootB/sub/track2.als'),
      );
    });

    test('returns the count of rewritten projects', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
        TestFactories.makeProject(id: 'p1', filePath: '/rootA/a.als'),
      );
      await repo.updateProject(
        TestFactories.makeProject(id: 'p2', filePath: '/rootA/b.als'),
      );

      final count = await repo.relocateRoot(rootId, '/rootB');

      expect(count, 2);
    });

    test('does not touch projects under a different root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
        TestFactories.makeProject(id: 'inA', filePath: '/rootA/track.als'),
      );
      await repo.updateProject(
        TestFactories.makeProject(id: 'inB', filePath: '/rootB/other.als'),
      );

      await repo.relocateRoot(rootId, '/rootC');

      expect(
        p.normalize(repo.getById('inB')!.filePath),
        p.normalize('/rootB/other.als'),
        reason: 'Project outside the relocated root must be unchanged',
      );
    });

    test(
      'also rewrites previewSongPath when it starts with the old root',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.addRoot('/rootA');
        final rootId = repo.getRoots().first.id;

        await repo.updateProject(
          TestFactories.makeProject(
            id: 'p1',
            filePath: '/rootA/track.als',
            previewSongPath: '/rootA/Exports/mix.mp3',
          ),
        );

        await repo.relocateRoot(rootId, '/rootB');

        expect(
          p.normalize(repo.getById('p1')!.previewSongPath!),
          p.normalize('/rootB/Exports/mix.mp3'),
        );
      },
    );

    test('returns 0 when root id is not found', () async {
      final repo = await HiveTestHelper.createRepository();
      final count = await repo.relocateRoot('no-such-id', '/rootB');
      expect(count, 0);
    });
  });

  group('ProjectRepository.deleteProjectsPermanently', () {
    // Scans used to auto-prune a project the moment its file went missing
    // (removeOrphanedProjectsFromRoot / clearMissingFiles) — including, in
    // clearMissingFiles's case, projects still referenced by a Release, with
    // no confirmation and no way back. That's gone: a missing file now just
    // leaves the project flagged missing (a live filesystem check done in
    // the UI) until the user explicitly deletes it via this method, e.g.
    // from the "Delete Missing" bulk action.

    test('removes the given projects', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(TestFactories.makeProject(id: 'a'));
      await repo.updateProject(TestFactories.makeProject(id: 'b'));

      await repo.deleteProjectsPermanently(['a']);

      expect(repo.getById('a'), isNull);
      expect(repo.getById('b'), isNotNull);
    });

    test(
      'deletes every id given, including ones referenced by a release',
      () async {
        // Unlike the old auto-prune, an explicit user-triggered delete is not
        // expected to protect release-tracked projects — the user asked for
        // exactly this deletion, deliberately, via the selection UI.
        final repo = await HiveTestHelper.createRepository();
        await repo.updateProject(TestFactories.makeProject(id: 'tracked'));
        await repo.addRelease(
          Release(id: 'r1', title: 'EP', trackIds: ['tracked']),
        );

        await repo.deleteProjectsPermanently(['tracked']);

        expect(repo.getById('tracked'), isNull);
      },
    );

    test('is a no-op for an empty id list', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(TestFactories.makeProject(id: 'a'));

      await repo.deleteProjectsPermanently([]);

      expect(repo.getById('a'), isNotNull);
    });

    test('silently ignores ids that do not exist', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(TestFactories.makeProject(id: 'a'));

      await repo.deleteProjectsPermanently(['a', 'does-not-exist']);

      expect(repo.getById('a'), isNull);
    });
  });

  group('Backup restore contract', () {
    test('restoreProject after updateProject keeps backup dates', () async {
      // Simulates: user changes status on mobile (updateProject),
      // then re-imports backup (restoreProject). Backup dates must win.
      final repo = await HiveTestHelper.createRepository();
      final desktopDate = DateTime(2023, 8, 10, 12, 0, 0);

      // First: project exists on device with a recent updatedAt
      final onDevice = TestFactories.makeProject(
        id: 'sync-test',
        lastModifiedAt: DateTime.now(),
      );
      await repo.updateProject(onDevice);

      // Then: backup import restores the correct desktop date
      final fromBackup = TestFactories.makeProject(
        id: 'sync-test',
        lastModifiedAt: desktopDate,
        updatedAt: desktopDate,
      );
      await repo.restoreProject(fromBackup);

      final saved = repo.getById('sync-test')!;
      expect(saved.lastModifiedAt, desktopDate);
    });

    // -----------------------------------------------------------------------
    // Full end-to-end scenario
    // -----------------------------------------------------------------------
    // Scenario:
    //   1. Android already has the project but with an OLD lastModifiedAt
    //      (e.g. from when the file was first synced to the device months ago).
    //   2. On desktop the user has been working on the project — lastModifiedAt
    //      is now a NEWER date reflecting the latest DAW save.
    //   3. User generates a backup on desktop and imports it on Android.
    //   4. After the import, Android must show the NEW desktop date.
    test(
      'desktop backup with newer date overwrites old Android date',
      () async {
        final repo = await HiveTestHelper.createRepository();

        // --- Step 1: Android already has the project with an OLD date ---
        // The file was first synced to Android back in January; that is what
        // stat.modified returned when the app scanned it.
        final androidOldDate = DateTime(2024, 1, 10, 8, 0, 0);

        final androidExistingProject = TestFactories.makeProject(
          id: 'daw-project-001',
          filePath: '/storage/emulated/0/Drive/MyBanger.als',
          fileName: 'MyBanger.als',
          lastModifiedAt: androidOldDate,
          fileCreatedAt: androidOldDate,
          status: 'Idea',
          bpm: 120.0,
        );
        await repo.restoreProject(androidExistingProject);

        // Confirm the old date is in the DB before the import.
        expect(repo.getById('daw-project-001')!.lastModifiedAt, androidOldDate);

        // --- Step 2: desktop has a newer backup ---
        // The project was worked on heavily; last DAW save was Nov 12 2024.
        final desktopNewDate = DateTime(2024, 11, 12, 9, 45, 0);

        final desktopBackupProject = TestFactories.makeProject(
          id: 'daw-project-001',
          filePath: '/Users/artist/Live/MyBanger.als',
          fileName: 'MyBanger.als',
          lastModifiedAt: desktopNewDate,
          fileCreatedAt: DateTime(2023, 3, 1),
          status: 'Mixing',
          bpm: 128.0,
          musicalKey: 'C minor',
          notes: 'Needs vocal chop on drop',
        );

        final backupJson = BackupService.projectToJson(desktopBackupProject);

        // --- Step 3: user imports the desktop backup on Android ---
        final projectFromBackup = BackupService.projectFromJson(backupJson);
        await repo.restoreProject(projectFromBackup);

        // --- Step 4: verify the NEW desktop date is now stored ---
        final saved = repo.getById('daw-project-001')!;

        expect(
          saved.lastModifiedAt,
          desktopNewDate,
          reason:
              'lastModifiedAt must be updated to the newer desktop DAW date.',
        );
        expect(
          saved.lastModifiedAt,
          isNot(androidOldDate),
          reason: 'The old Android date must have been replaced by the backup.',
        );
        expect(
          saved.lastModifiedAt.isAfter(androidOldDate),
          isTrue,
          reason: 'Stored date must be newer than the previous Android date.',
        );

        // Other metadata from the backup must also be intact.
        expect(saved.bpm, 128.0);
        expect(saved.musicalKey, 'C minor');
        expect(saved.notes, 'Needs vocal chop on drop');
        expect(saved.status, 'Mixing');
      },
    );
  });

  // These exercise the "diff against known paths, upsert only new ones"
  // contract the background folder watcher (FolderWatcherService, wired up
  // in main.dart) relies on: it calls upsertFromFileSystemEntity only for
  // paths not already in getAllProjects(), so a single new file must produce
  // exactly one project, and re-running it for an already-known path must
  // update in place rather than duplicate.
  group('ProjectRepository.upsertFromFileSystemEntity (watcher-style diff)', () {
    test('creates exactly one project for a newly seen file', () async {
      final repo = await HiveTestHelper.createRepository();
      final fileDir = await Directory.systemTemp.createTemp(
        'upsert_diff_test_',
      );
      addTearDown(() => fileDir.delete(recursive: true));
      final file = File(p.join(fileDir.path, 'song.als'))
        ..writeAsStringSync('data');

      expect(repo.getByPath(file.path), isNull);

      await repo.upsertFromFileSystemEntity(file, fullMetadata: false);

      expect(repo.getAllProjects().length, 1);
      expect(repo.getByPath(file.path), isNotNull);
    });

    test(
      're-upserting an already-known path updates in place instead of duplicating',
      () async {
        final repo = await HiveTestHelper.createRepository();
        final fileDir = await Directory.systemTemp.createTemp(
          'upsert_diff_test_',
        );
        addTearDown(() => fileDir.delete(recursive: true));
        final file = File(p.join(fileDir.path, 'song.als'))
          ..writeAsStringSync('data');

        await repo.upsertFromFileSystemEntity(file, fullMetadata: false);
        final firstId = repo.getByPath(file.path)!.id;

        file.writeAsStringSync('more data than before');
        await repo.upsertFromFileSystemEntity(file, fullMetadata: false);

        expect(repo.getAllProjects().length, 1);
        expect(repo.getByPath(file.path)!.id, firstId);
      },
    );
  });

  group('ProjectRepository.upsertManyFromFileSystemEntities', () {
    test('creates one project per newly seen file', () async {
      final repo = await HiveTestHelper.createRepository();
      final fileDir = await Directory.systemTemp.createTemp(
        'upsert_many_test_',
      );
      addTearDown(() => fileDir.delete(recursive: true));
      final files = [
        File(p.join(fileDir.path, 'a.als'))..writeAsStringSync('a'),
        File(p.join(fileDir.path, 'b.als'))..writeAsStringSync('b'),
        File(p.join(fileDir.path, 'c.als'))..writeAsStringSync('c'),
      ];

      await repo.upsertManyFromFileSystemEntities(files, fullMetadata: false);

      expect(repo.getAllProjects().length, 3);
      for (final f in files) {
        expect(repo.getByPath(f.path), isNotNull);
      }
    });

    test(
      're-upserting already-known paths updates in place instead of duplicating',
      () async {
        final repo = await HiveTestHelper.createRepository();
        final fileDir = await Directory.systemTemp.createTemp(
          'upsert_many_test_',
        );
        addTearDown(() => fileDir.delete(recursive: true));
        final file = File(p.join(fileDir.path, 'song.als'))
          ..writeAsStringSync('data');

        await repo.upsertManyFromFileSystemEntities([
          file,
        ], fullMetadata: false);
        final firstId = repo.getByPath(file.path)!.id;

        file.writeAsStringSync('more data than before');
        await repo.upsertManyFromFileSystemEntities([
          file,
        ], fullMetadata: false);

        expect(repo.getAllProjects().length, 1);
        expect(repo.getByPath(file.path)!.id, firstId);
      },
    );

    test('flushes in chunks so a large batch does not lose entries', () async {
      final repo = await HiveTestHelper.createRepository();
      final fileDir = await Directory.systemTemp.createTemp(
        'upsert_many_flush_test_',
      );
      addTearDown(() => fileDir.delete(recursive: true));
      final files = List.generate(
        5,
        (i) =>
            File(p.join(fileDir.path, 'song$i.als'))..writeAsStringSync('$i'),
      );

      // flushEvery smaller than the batch forces multiple putAll flushes.
      await repo.upsertManyFromFileSystemEntities(
        files,
        fullMetadata: false,
        flushEvery: 2,
      );

      expect(repo.getAllProjects().length, 5);
    });

    test(
      'resolves fullMetadataFor per entity instead of a single flag for the whole batch',
      () async {
        final repo = await HiveTestHelper.createRepository();
        final fileDir = await Directory.systemTemp.createTemp(
          'upsert_many_perfile_test_',
        );
        addTearDown(() => fileDir.delete(recursive: true));
        final full = File(p.join(fileDir.path, 'full.rpp'))
          ..writeAsStringSync('BPM 120');
        final light = File(p.join(fileDir.path, 'light.rpp'))
          ..writeAsStringSync('BPM 120');

        await repo.upsertManyFromFileSystemEntities([
          full,
          light,
        ], fullMetadataFor: (e) => e.path == full.path);

        expect(repo.getByPath(full.path)!.metadataScanned, isTrue);
        expect(repo.getByPath(light.path)!.metadataScanned, isFalse);
      },
    );

    test('is a no-op for an empty entity list', () async {
      final repo = await HiveTestHelper.createRepository();

      await repo.upsertManyFromFileSystemEntities([], fullMetadata: false);

      expect(repo.getAllProjects(), isEmpty);
    });

    test(
      'a single failing entity does not abort the rest of the batch, and its path is reported',
      () async {
        // Regression coverage: a scan used to abort entirely (losing every
        // remaining project in the batch) the moment one file threw while
        // being processed — e.g. deleted or locked mid-scan. Failures are
        // now caught per entity and returned by path instead.
        final repo = await HiveTestHelper.createRepository();
        final fileDir = await Directory.systemTemp.createTemp(
          'upsert_many_failure_test_',
        );
        addTearDown(() => fileDir.delete(recursive: true));
        final good1 = File(p.join(fileDir.path, 'good1.als'))
          ..writeAsStringSync('a');
        final good2 = File(p.join(fileDir.path, 'good2.als'))
          ..writeAsStringSync('b');
        final broken = _ThrowingFileSystemEntity(
          p.join(fileDir.path, 'broken.als'),
        );

        final failures = await repo.upsertManyFromFileSystemEntities([
          good1,
          broken,
          good2,
        ], fullMetadata: false);

        expect(failures, [broken.path]);
        expect(repo.getAllProjects().length, 2);
        expect(repo.getByPath(good1.path), isNotNull);
        expect(repo.getByPath(good2.path), isNotNull);
      },
    );

    test(
      'onProgress reports a running count and the batch total for every entity, success or failure',
      () async {
        final repo = await HiveTestHelper.createRepository();
        final fileDir = await Directory.systemTemp.createTemp(
          'upsert_many_progress_test_',
        );
        addTearDown(() => fileDir.delete(recursive: true));
        final good = File(p.join(fileDir.path, 'good.als'))
          ..writeAsStringSync('a');
        final broken = _ThrowingFileSystemEntity(
          p.join(fileDir.path, 'broken.als'),
        );

        final progressCalls = <(int, int)>[];
        await repo.upsertManyFromFileSystemEntities(
          [good, broken],
          fullMetadata: false,
          onProgress: (processed, total) =>
              progressCalls.add((processed, total)),
        );

        expect(progressCalls, [(1, 2), (2, 2)]);
      },
    );
  });

  group('ProjectRepository.watchAllProjects', () {
    test('emits the initial project list immediately on listen', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(TestFactories.makeProject(id: 'p1'));

      final first = await repo.watchAllProjects().first;

      expect(first.map((p) => p.id), ['p1']);
    });

    test(
      'collapses a burst of rapid box writes into a single emission',
      () async {
        final repo = await HiveTestHelper.createRepository();
        final emissions = <List<MusicProject>>[];
        final sub = repo.watchAllProjects().listen(emissions.add);
        addTearDown(sub.cancel);

        // Let the initial emission land, then fire many writes back-to-back —
        // this mirrors what a scan does (one put() per discovered file).
        await Future<void>.delayed(const Duration(milliseconds: 10));
        emissions.clear();
        for (var i = 0; i < 20; i++) {
          await repo.updateProject(TestFactories.makeProject(id: 'burst-$i'));
        }

        // Debounce window is 200ms — nothing should have emitted yet.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emissions, isEmpty);

        // After the debounce window closes, exactly one emission with every write folded in.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(emissions.length, 1);
        expect(emissions.single.length, 20);
      },
    );
  });

  group('ProjectRepository.closeBoxes', () {
    test(
      'closes the per-profile boxes so they can be reopened cleanly',
      () async {
        final repo = await HiveTestHelper.createRepository();
        await repo.updateProject(TestFactories.makeProject(id: 'p1'));
        expect(repo.projectsBox.isOpen, isTrue);

        await repo.closeBoxes();

        expect(repo.projectsBox.isOpen, isFalse);

        // Reopening should see the previously-written data, proving nothing
        // was lost or corrupted by the close.
        final reopened = await HiveTestHelper.createRepository();
        expect(reopened.getById('p1'), isNotNull);
      },
    );
  });

  group('ProjectRepository.clearAllData', () {
    // "Clear Library" in settings_page.dart — clears the current profile's
    // data without closing any Hive box (unlike deleteAllAppData below).

    test('clears projects, roots, ignored paths and events', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.restoreProject(TestFactories.makeProject(id: 'p1'));
      await repo.addRoot('/music/root');
      await repo.addIgnoredPath('/music/root/ignored');
      await repo.addEvent(
        ProjectEvent(
          id: 'e1',
          projectId: 'p1',
          eventType: ProjectEvent.statusChange,
          occurredAt: DateTime(2026, 1, 1),
        ),
      );

      await repo.clearAllData();

      expect(repo.getAllProjects(), isEmpty);
      expect(repo.getRoots(), isEmpty);
      expect(repo.getIgnoredPaths(), isEmpty);
      expect(repo.getAllEvents(), isEmpty);
    });

    test('preserves projects referenced by a release', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.restoreProject(TestFactories.makeProject(id: 'keep'));
      await repo.restoreProject(TestFactories.makeProject(id: 'discard'));
      await repo.addRelease(
        Release(id: 'r1', title: 'Release', trackIds: const ['keep']),
      );

      await repo.clearAllData();

      expect(repo.getAllProjects().map((p) => p.id), ['keep']);
    });
  });

  group('ProjectRepository.deleteAllAppData', () {
    // "Delete All Data" in settings_page.dart — the two-confirmation
    // "nuclear" reset. Unlike clearAllData, this closes every Hive box
    // across every profile before clearing them (see the crash this caused
    // in dashboard_page.dart, fixed via safeGetAllProjects). Verifying the
    // wipe itself actually completes end-to-end here.

    test(
      "wipes every profile's data and leaves a single fresh default profile",
      () async {
        final profileRepo = await HiveTestHelper.createProfileRepository();
        final profileA = await profileRepo.createProfile('A');
        final profileB = await profileRepo.createProfile('B');

        final repoA = await HiveTestHelper.createRepository(
          profileId: profileA.id,
        );
        await repoA.restoreProject(TestFactories.makeProject(id: 'a1'));
        await repoA.addRoot('/music/a');

        final repoB = await HiveTestHelper.createRepository(
          profileId: profileB.id,
        );
        await repoB.restoreProject(TestFactories.makeProject(id: 'b1'));
        await repoB.addRoot('/music/b');

        await ProjectRepository.deleteAllAppData();

        final profiles = Hive.box<Profile>(
          ProfileRepository.profilesBoxName,
        ).values.toList();
        expect(profiles, hasLength(1));
        expect(profiles.single.name, 'Default');
        expect(profiles.single.id, isNot(profileA.id));
        expect(profiles.single.id, isNot(profileB.id));

        final aProjects = await Hive.openBox<dynamic>(
          '${profileA.id}_projects',
        );
        final bProjects = await Hive.openBox<dynamic>(
          '${profileB.id}_projects',
        );
        expect(aProjects.isEmpty, isTrue);
        expect(bProjects.isEmpty, isTrue);

        final aRoots = await Hive.openBox<dynamic>('${profileA.id}_roots');
        final bRoots = await Hive.openBox<dynamic>('${profileB.id}_roots');
        expect(aRoots.isEmpty, isTrue);
        expect(bRoots.isEmpty, isTrue);
      },
    );
  });
}
