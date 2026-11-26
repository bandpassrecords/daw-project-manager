import 'dart:convert';
import 'dart:io';

import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_drive.dart';
import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// One file, one row, through a real sync against an in-memory Drive.
///
/// A library had 68 songs twice after its Proton Drive folder moved from C:
/// to F:: Relocate folder moved every row it had, then a merge brought back
/// older copies of rows that had been deleted (before deletions were
/// recorded) and rescanned under new ids — still naming the C: folder.
void main() {
  late Directory tempDir;
  late ProjectRepository projectRepo;
  late ProfileRepository profileRepo;
  late Profile profile;
  late FakeDrive fakeDrive;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    final profilesBox = await Hive.openBox<Profile>('profiles');
    final settingsBox = await Hive.openBox<String>('settings');
    profileRepo = ProfileRepository(
      profilesBox: profilesBox,
      settingsBox: settingsBox,
    );
    profile = await profileRepo.createProfile('Audio Crawler');
    projectRepo = await HiveTestHelper.createRepository(profileId: profile.id);
    await Hive.openBox<String>('app_settings');
    fakeDrive = FakeDrive();
  });

  tearDown(() async => HiveTestHelper.tearDown(tempDir));

  Future<GoogleDriveSyncService> signedIn() async {
    final service = GoogleDriveSyncService()..driveApi = fakeDrive.api;
    await service.ensureAppDataFolder();
    return service;
  }

  void seedFromAnotherDevice(
    GoogleDriveSyncService service, {
    required List<Map<String, dynamic>> projects,
    List<Map<String, dynamic>> releases = const [],
  }) {
    final folder = fakeDrive.files.values
        .firstWhere((f) => f.isFolder && f.parents.contains('root'))
        .id;
    fakeDrive.seed(
      name: 'database_backup.json',
      parent: folder,
      description: 'Laptop',
      content: utf8.encode(
        jsonEncode({
          'timestamp': DateTime.now().toIso8601String(),
          'device': 'Laptop',
          'projects': projects,
          'releases': releases,
          'projectToProfile': {for (final x in projects) x['id']: profile.id},
          'releaseToProfile': {for (final r in releases) r['id']: profile.id},
        }),
      ),
    );
  }

  Set<String> idsOnDrive() => {
    for (final x
        in (jsonDecode(fakeDrive.named('database_backup.json')!.text)
                as Map)['projects']
            as List)
      x['id'] as String,
  };

  String song(String drive, String name) =>
      p.join(tempDir.path, drive, 'Audio Crawler', name, '$name.cpr');

  test(
    'a row from another device for a file already here is folded in',
    () async {
      final service = await signedIn();
      await projectRepo.projectsBox.put(
        'here',
        TestFactories.makeProject(
          id: 'here',
          filePath: song('F', 'Relax'),
          status: 'Idea',
        ),
      );
      seedFromAnotherDevice(
        service,
        projects: [
          service.serializeProjectForTest(
            TestFactories.makeProject(
              id: 'laptop',
              filePath: song('F', 'Relax'),
              status: 'Finished',
              notes: 'mastered on the laptop',
            ),
          ),
        ],
        releases: [
          service.serializeReleaseForTest(
            Release(id: 'ep', title: 'EP', trackIds: ['laptop']),
          ),
        ],
      );

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(projectRepo.getAllProjects().map((r) => r.id), ['here']);
      final kept = projectRepo.projectsBox.get('here')!;
      expect(kept.status, 'Finished');
      expect(kept.notes, 'mastered on the laptop');
      expect(projectRepo.releasesBox.get('ep')!.trackIds, ['here']);
      // Nothing deleted: the laptop keeps its own row; Drive gets this one.
      expect(idsOnDrive(), {'here'});
    },
  );

  test(
    'a row naming the place a folder was relocated from lands at the new one',
    () async {
      final service = await signedIn();
      final root = await projectRepo.addRoot(
        p.join(tempDir.path, 'C', 'Audio Crawler'),
      );
      await projectRepo.projectsBox.put(
        'may',
        TestFactories.makeProject(
          id: 'may',
          filePath: song('C', 'Meiko'),
          status: 'Idea',
        ),
      );
      await projectRepo.relocateRoot(
        root.id,
        p.join(tempDir.path, 'F', 'Audio Crawler'),
      );
      expect(projectRepo.projectsBox.get('may')!.filePath, song('F', 'Meiko'));

      seedFromAnotherDevice(
        service,
        projects: [
          service.serializeProjectForTest(
            TestFactories.makeProject(
              id: 'december',
              filePath: song('C', 'Meiko'),
              status: 'Finished',
              updatedAt: DateTime(2026, 5, 13),
            ),
          ),
        ],
      );

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(projectRepo.getAllProjects().map((r) => r.id), ['may']);
      expect(projectRepo.projectsBox.get('may')!.status, 'Finished');
      expect(projectRepo.projectsBox.get('may')!.filePath, song('F', 'Meiko'));
    },
  );

  test('the same row brought back again changes nothing', () async {
    final service = await signedIn();
    await projectRepo.projectsBox.put(
      'here',
      TestFactories.makeProject(id: 'here', filePath: song('F', 'A')),
    );
    final laptop = service.serializeProjectForTest(
      TestFactories.makeProject(
        id: 'laptop',
        filePath: song('F', 'A'),
        notes: 'n',
      ),
    );
    seedFromAnotherDevice(service, projects: [laptop]);
    await service.syncDatabase(
      projectRepo: projectRepo,
      profileRepo: profileRepo,
    );
    final once = projectRepo.projectsBox.get('here')!.updatedAt;

    // The laptop uploads its row again.
    fakeDrive.files.removeWhere((_, f) => f.name == 'database_backup.json');
    seedFromAnotherDevice(service, projects: [laptop]);
    await service.syncDatabase(
      projectRepo: projectRepo,
      profileRepo: profileRepo,
    );

    expect(projectRepo.getAllProjects().map((r) => r.id), ['here']);
    expect(projectRepo.projectsBox.get('here')!.updatedAt, once);
  });
}
