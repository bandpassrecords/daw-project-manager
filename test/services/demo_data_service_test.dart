import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_event.dart';
import 'package:daw_project_manager/models/project_template.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/models/todo_template.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/services/demo_data_service.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

void main() {
  late Directory tempDir;
  late ProfileRepository profileRepo;

  Future<String> fakePreviewSongsPath() async {
    final dir = Directory(p.join(tempDir.path, 'previews'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> fakeDemoFilesPath() async {
    final dir = Directory(p.join(tempDir.path, 'demo_projects'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    profileRepo = await HiveTestHelper.createProfileRepository();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  group('DemoDataService.generate', () {
    test('gives some projects a plugin capture, some of them beside a preview song', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');

      final captured = projects.values.where((x) => x.latestCapture != null).toList();
      expect(captured, isNotEmpty);
      for (final project in captured) {
        final capture = project.latestCapture!;
        expect(File(capture.path).existsSync(), isTrue);
        expect(
          p.isWithin(p.join(tempDir.path, 'previews', 'plugin', project.id), capture.path),
          isTrue,
        );
        expect(capture.path, isNot(project.previewSongPath));
      }
      expect(
        captured.where((x) => x.previewSongPath != null),
        isNotEmpty,
        reason: 'a project needs both, or there is nothing to choose between',
      );
    });

    test('creates a profile named "Demo — Screenshots"', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      expect(profile.name, DemoDataService.demoProfileName);
      // Plus the two lighter-weight secondary demo profiles (see
      // DemoDataService._secondaryDemoProfileNames), used to give the
      // Profile Manager more than one profile to show in screenshots.
      expect(profileRepo.getAllProfiles().length, 3);
    });

    test('running twice reuses the same profile and does not duplicate data', () async {
      final first = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final firstProjects = await Hive.openBox<MusicProject>('${first.id}_projects');
      final firstCount = firstProjects.length;
      await firstProjects.close();

      final second = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      expect(second.id, first.id);
      expect(profileRepo.getAllProfiles().length, 3);

      final secondProjects = await Hive.openBox<MusicProject>('${second.id}_projects');
      expect(secondProjects.length, firstCount);
    });

    test('spans every supported DAW type and every canonical status', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');

      final dawTypes = projects.values.map((p) => p.dawType).toSet();
      final statuses = projects.values.map((p) => p.status).toSet();

      expect(
        dawTypes,
        {
          'Ableton Live', 'Bitwig Studio', 'Cubase', 'FL Studio', 'Logic Pro',
          'Maschine', 'MAGDA', 'Nuendo', 'Pro Tools', 'Reaper', 'Sonar',
          'Studio One', 'Waveform', 'LUNA',
          'Ardour', 'GarageBand', 'Renoise', 'LMMS', 'Audacity', 'Qtractor',
          'Rosegarden', 'Reason', 'Digital Performer', 'Adobe Audition',
          'Samplitude / Sequoia', 'ACID Pro', 'Mixcraft',
        },
      );
      expect(statuses, {'Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'});
    });

    test('every project has a real placeholder on disk at its filePath', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');

      for (final project in projects.values) {
        final existsAsFile = File(project.filePath).existsSync();
        final existsAsDirectory = Directory(project.filePath).existsSync();
        expect(existsAsFile || existsAsDirectory, isTrue,
            reason: '${project.filePath} should exist on disk');
      }
    });

    test('package-bundle DAWs (Logic Pro, LUNA, GarageBand) get a real directory, not a file', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');

      final bundleProjects = projects.values
          .where((p) => p.fileExtension == '.logicx' || p.fileExtension == '.luna' || p.fileExtension == '.band');
      expect(bundleProjects, isNotEmpty);
      for (final project in bundleProjects) {
        expect(Directory(project.filePath).existsSync(), isTrue,
            reason: '${project.filePath} (${project.fileExtension}) should be a directory');
        expect(File(project.filePath).existsSync(), isFalse);
      }

      final fileProjects = projects.values.where((p) => p.fileExtension == '.als');
      expect(fileProjects, isNotEmpty);
      for (final project in fileProjects) {
        expect(File(project.filePath).existsSync(), isTrue,
            reason: '${project.filePath} (${project.fileExtension}) should be a file');
      }
    });

    test('every release trackId resolves to a generated project', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');
      final releases = await Hive.openBox<Release>('${profile.id}_releases');

      final projectIds = projects.keys.toSet();
      expect(releases.values, isNotEmpty);
      for (final release in releases.values) {
        for (final trackId in release.trackIds) {
          expect(projectIds.contains(trackId), isTrue,
              reason: 'Release "${release.title}" references missing project $trackId');
        }
      }
    });

    test('status-change events are within the last 12 months with valid payloads', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final events = await Hive.openBox<ProjectEvent>('${profile.id}_events');
      expect(events.values, isNotEmpty);

      final cutoff = DateTime.now().subtract(const Duration(days: 366));
      const validStatuses = {'Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'};

      for (final event in events.values) {
        expect(event.occurredAt.isAfter(cutoff), isTrue,
            reason: 'Event ${event.id} occurred outside the last 12 months');

        if (event.eventType == ProjectEvent.statusChange) {
          final payload = jsonDecode(event.payload as String) as Map;
          expect(validStatuses.contains(payload['from']), isTrue);
          expect(validStatuses.contains(payload['to']), isTrue);
        }
      }
    });

    test('a project\'s work sessions add up to the time it says was worked', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');
      const order = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];

      for (final project in projects.values) {
        final sessions = project.sessions;
        expect(sessions, isNotEmpty, reason: '${project.displayName} has no session history');
        expect(sessions.fold<int>(0, (a, s) => a + s.durationSeconds), project.totalWorkSeconds,
            reason: project.displayName);
        for (final (k, s) in sessions.indexed) {
          expect(s.endedAt.difference(s.startedAt).inSeconds, s.durationSeconds);
          expect(order.indexOf(s.phase!), lessThanOrEqualTo(order.indexOf(project.status)),
              reason: 'a session in a phase the song had not reached');
          if (k > 0) {
            expect(s.startedAt.isAfter(sessions[k - 1].endedAt), isTrue, reason: 'sessions overlap');
          }
        }
        expect(sessions.map((s) => s.id).toSet().length, sessions.length);
      }
    });

    test('does not touch a separate profile\'s real project data', () async {
      final realRepo = await HiveTestHelper.createRepository(profileId: 'real-user-profile');
      final realProject = TestFactories.makeProject(id: 'real-project-1');
      await realRepo.projectsBox.put(realProject.id, realProject);

      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      expect(realRepo.projectsBox.length, 1);
      expect(realRepo.getById('real-project-1'), isNotNull);
    });

    test('adds demo-tagged entries to the global todoTemplates box without touching a real one', () async {
      final templatesBox = await Hive.openBox<TodoTemplate>('todoTemplates');
      final template = TodoTemplate(
        id: 'real-template-1',
        name: 'My Real Template',
        items: const ['Step 1', 'Step 2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await templatesBox.put(template.id, template);

      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      expect(templatesBox.get('real-template-1')?.name, 'My Real Template');
      final demoEntries = templatesBox.values.where((t) => t.name.startsWith('Demo — '));
      expect(demoEntries, isNotEmpty);
    });

    test('adds demo-tagged Project Templates with a real placeholder source folder', () async {
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      final templatesBox = await Hive.openBox<ProjectTemplate>('projectTemplates');
      final demoTemplates = templatesBox.values.where((t) => t.name.startsWith('Demo — ')).toList();
      expect(demoTemplates, isNotEmpty);

      for (final template in demoTemplates) {
        expect(Directory(template.sourceFolderPath).existsSync(), isTrue);
        final mainFilePath = p.join(template.sourceFolderPath, template.mainFileRelativePath);
        final existsAsFile = File(mainFilePath).existsSync();
        final existsAsDirectory = Directory(mainFilePath).existsSync();
        expect(existsAsFile || existsAsDirectory, isTrue);
      }
    });

    test('main profile releases have artwork and attached files pointing to real placeholders', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final releases = await Hive.openBox<Release>('${profile.id}_releases');

      expect(releases.values, isNotEmpty);
      for (final release in releases.values) {
        expect(release.artworkImagePath, isNotNull);
        expect(File(release.artworkImagePath!).existsSync(), isTrue);
        expect(release.files, isNotEmpty);
        for (final file in release.files) {
          expect(File(file.filePath).existsSync(), isTrue);
        }
      }
    });

    test('release artwork is a real decodable 512x512 PNG, not just a file that exists', () async {
      // Regression coverage for the hand-rolled PNG encoder in
      // DemoDataService — a malformed chunk/CRC would make the file exist
      // on disk but fail to decode, showing a broken-image icon in
      // screenshots instead of real cover art.
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final releases = await Hive.openBox<Release>('${profile.id}_releases');
      final artworkPath = releases.values.first.artworkImagePath!;
      final bytes = await File(artworkPath).readAsBytes();

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      expect(frame.image.width, 512);
      expect(frame.image.height, 512);
    });

    test('creates the secondary demo profiles alongside the main one', () async {
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      final names = profileRepo.getAllProfiles().map((p) => p.name).toSet();
      expect(names, {
        DemoDataService.demoProfileName,
        'Demo — Solo Artist',
        'Demo — Studio B',
      });
    });
  });

  group('DemoDataService.demoSessions', () {
    final created = DateTime(2026, 1, 1);

    test('adds up exactly, in quarter hours, one a day, the phases in order', () {
      for (final total in [7200, 10800, 36000, 90000]) {
        final sessions = DemoDataService.demoSessions(
          totalSeconds: total,
          createdAt: created,
          updatedAt: created.add(const Duration(days: 60)),
          phases: const ['Idea', 'Arranging', 'Mixing'],
          seed: total,
        );
        expect(sessions.fold<int>(0, (a, s) => a + s.durationSeconds), total);
        expect(sessions.every((s) => s.durationSeconds > 0 && s.durationSeconds % 900 == 0), isTrue);
        final days = sessions.map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day));
        expect(days.toSet().length, sessions.length, reason: 'two sessions on one day');
        expect(sessions.first.phase, 'Idea');
        expect(sessions.last.phase, 'Mixing');
      }
    });

    test('never more sessions than days to hold them', () {
      final sessions = DemoDataService.demoSessions(
        totalSeconds: 90000,
        createdAt: created,
        updatedAt: created.add(const Duration(days: 3)),
        phases: const ['Idea'],
        seed: 1,
      );
      expect(sessions.length, 3);
      expect(sessions.fold<int>(0, (a, s) => a + s.durationSeconds), 90000);
    });

    test('nothing worked, or no time to work in: no sessions', () {
      expect(
        DemoDataService.demoSessions(
            totalSeconds: 0, createdAt: created, updatedAt: created.add(const Duration(days: 9)), phases: const ['Idea'], seed: 0),
        isEmpty,
      );
      expect(
        DemoDataService.demoSessions(totalSeconds: 3600, createdAt: created, updatedAt: created, phases: const ['Idea'], seed: 0),
        isEmpty,
      );
    });
  });

  group('DemoDataService.remove', () {
    test('returns false when no demo profile exists', () async {
      final removed = await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);
      expect(removed, isFalse);
    });

    test('deletes the demo profile entirely when another profile exists', () async {
      await profileRepo.createProfile('Real Profile');
      final demoProfile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      final removed = await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(removed, isTrue);
      expect(profileRepo.getAllProfiles().any((p) => p.id == demoProfile.id), isFalse);
      expect(profileRepo.getAllProfiles().length, 1);
    });

    test('empties but keeps the demo profile when it is the only profile', () async {
      final demoProfile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      final removed = await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(removed, isTrue);
      expect(profileRepo.getAllProfiles().length, 1);
      final projects = await Hive.openBox<MusicProject>('${demoProfile.id}_projects');
      expect(projects, isEmpty);
    });

    test('removes the plugin captures it generated, folder and all', () async {
      await profileRepo.createProfile('Real Profile');
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final captureDir = Directory(p.join(tempDir.path, 'previews', 'plugin'));
      expect(captureDir.existsSync(), isTrue);

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(
        captureDir.existsSync() ? captureDir.listSync(recursive: true).whereType<File>() : <File>[],
        isEmpty,
      );
    });

    test('deletes generated preview audio files from disk', () async {
      await profileRepo.createProfile('Real Profile');
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final previewDir = Directory(p.join(tempDir.path, 'previews'));
      final filesBefore = previewDir.listSync().whereType<File>().toList();
      expect(filesBefore, isNotEmpty);

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      final filesAfter = previewDir.listSync().whereType<File>().toList();
      expect(filesAfter, isEmpty);
    });

    test('does not touch a separate profile\'s real project data', () async {
      final realRepo = await HiveTestHelper.createRepository(profileId: 'real-user-profile');
      final realProject = TestFactories.makeProject(id: 'real-project-1');
      await realRepo.projectsBox.put(realProject.id, realProject);
      await profileRepo.createProfile('Real Profile');

      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(realRepo.projectsBox.length, 1);
      expect(realRepo.getById('real-project-1'), isNotNull);
    });

    test('deletes the placeholder project files/folders directory from disk', () async {
      await profileRepo.createProfile('Real Profile');
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final demoFilesDir = Directory(p.join(tempDir.path, 'demo_projects'));
      expect(demoFilesDir.existsSync(), isTrue);
      expect(demoFilesDir.listSync(), isNotEmpty);

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(demoFilesDir.existsSync(), isFalse);
    });

    test('deletes the secondary demo profiles too when another profile exists', () async {
      await profileRepo.createProfile('Real Profile');
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      final names = profileRepo.getAllProfiles().map((p) => p.name).toSet();
      expect(names, {'Real Profile'});
    });

    test('keeps exactly one demo profile (emptied) when demo profiles are the only ones', () async {
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(profileRepo.getAllProfiles().length, 1);
      expect(profileRepo.getAllProfiles().first.name, DemoDataService.demoProfileName);
    });

    test('removes demo-tagged template entries without touching a real one', () async {
      final todoBox = await Hive.openBox<TodoTemplate>('todoTemplates');
      final realTemplate = TodoTemplate(
        id: 'real-template-1',
        name: 'My Real Template',
        items: const ['Step 1'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await todoBox.put(realTemplate.id, realTemplate);

      await profileRepo.createProfile('Real Profile');
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      expect(todoBox.values.any((t) => t.name.startsWith('Demo — ')), isTrue);

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(todoBox.values.any((t) => t.name.startsWith('Demo — ')), isFalse);
      expect(todoBox.get('real-template-1')?.name, 'My Real Template');
    });
  });
}
