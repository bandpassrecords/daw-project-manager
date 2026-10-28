import 'dart:convert';
import 'dart:io';

import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';
import 'package:daw_project_manager/utils/app_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/fake_drive.dart';
import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.supportPath);
  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

/// Preview songs whose file is missing on the uploading device, through Drive
/// sync end to end: the real sync service against an in-memory Drive
/// ([FakeDrive]), the app's data folder a temp folder.
///
/// A phone takes the same path — it reads no preview files for the upload,
/// so every song is one "with no file here" — but `MobileUtils.isMobile()`
/// can't be faked, so that is covered by these desktop runs and the rules'
/// own tests (preview_song_sync_test.dart), not run as a phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory appData;
  late ProjectRepository projectRepo;
  late ProfileRepository profileRepo;
  late Profile profile;
  late FakeDrive fakeDrive;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    appData = await Directory.systemTemp.createTemp('dpm_preview_sync_');
    debugLocalAppDataOverride = appData.path;
    PathProviderPlatform.instance = _FakePathProvider(appData.path);
    final profilesBox = await Hive.openBox<Profile>('profiles');
    final settingsBox = await Hive.openBox<String>('settings');
    profileRepo = ProfileRepository(profilesBox: profilesBox, settingsBox: settingsBox);
    profile = await profileRepo.createProfile('Studio');
    projectRepo = await HiveTestHelper.createRepository(profileId: profile.id);
    await Hive.openBox<String>('app_settings');
    fakeDrive = FakeDrive();
  });

  tearDown(() async {
    debugLocalAppDataOverride = null;
    await HiveTestHelper.tearDown(tempDir);
    if (await appData.exists()) await appData.delete(recursive: true);
  });

  Future<GoogleDriveSyncService> signedIn() async {
    final service = GoogleDriveSyncService()..driveApi = fakeDrive.api;
    await service.ensureAppDataFolder();
    return service;
  }

  String backupFolderId() =>
      fakeDrive.files.values.firstWhere((f) => f.isFolder && f.parents.contains('root')).id;

  /// A preview song an earlier upload put on Drive.
  FakeDriveFile songOnDrive(String name, List<int> bytes) {
    final folder = fakeDrive.named('preview_songs') ??
        fakeDrive.seed(
          name: 'preview_songs',
          parent: backupFolderId(),
          mimeType: FakeDrive.folderMimeType,
        );
    return fakeDrive.seed(name: name, parent: folder.id, content: bytes, mimeType: 'audio/wav');
  }

  /// The backup an earlier upload left, listing [previewSongFiles].
  void backupListing(GoogleDriveSyncService service, Map<String, String> previewSongFiles) {
    fakeDrive.seed(
      name: 'database_backup.json',
      parent: backupFolderId(),
      description: 'Laptop',
      content: utf8.encode(jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'device': 'Laptop',
        'projects': [
          for (final id in previewSongFiles.keys)
            {
              ...service.serializeProjectForTest(projectRepo.projectsBox.get(id)!),
              'profileId': profile.id,
            },
        ],
        'previewSongFiles': previewSongFiles,
        'previewSongHashes': {for (final id in previewSongFiles.keys) id: 'hash-$id'},
        'previewSongFileNames': {for (final id in previewSongFiles.keys) id: 'Song $id.wav'},
      })),
    );
  }

  Map<String, dynamic> backupOnDrive() =>
      jsonDecode(fakeDrive.named('database_backup.json')!.text) as Map<String, dynamic>;

  Map<String, dynamic> listedSongs() =>
      (backupOnDrive()['previewSongFiles'] as Map?)?.cast<String, dynamic>() ?? {};

  /// Where this app keeps its own copy of a song it downloaded.
  Future<String> managedCopy(String projectId) async =>
      p.join(await getPreviewSongsPath(), '${projectId}_preview.wav');

  test('a song whose copy is gone here stays in the backup', () async {
    // The bug: the backup was rebuilt from this device's files alone, so a
    // copy missing here took the song from every device.
    final service = await signedIn();
    final song = songOnDrive('a_preview.wav', [1, 2, 3]);
    await projectRepo.projectsBox.put(
      'a',
      TestFactories.makeProject(id: 'a', previewSongPath: await managedCopy('a')),
    );
    backupListing(service, {'a': song.id});

    await service.uploadDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

    expect(listedSongs(), {'a': song.id});
    expect(backupOnDrive()['previewSongHashes'], {'a': 'hash-a'});
    expect(backupOnDrive()['previewSongFileNames'], {'a': 'Song a.wav'});
  });

  test('a song an earlier backup let go is listed again, then comes back', () async {
    // What earlier uploads left: the file on Drive, named after its
    // project, and a backup that no longer lists it.
    final service = await signedIn();
    final song = songOnDrive('a_preview.wav', [4, 5, 6]);
    await projectRepo.projectsBox.put(
      'a',
      TestFactories.makeProject(id: 'a', previewSongPath: await managedCopy('a')),
    );
    backupListing(service, {});

    await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);
    expect(listedSongs(), {'a': song.id});

    // Listed again, the next merge downloads it like any song missing here.
    await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);
    final path = projectRepo.projectsBox.get('a')!.previewSongPath!;
    expect(await File(path).readAsBytes(), [4, 5, 6]);
  });

  test('a song removed from its project is let go', () async {
    final service = await signedIn();
    final song = songOnDrive('a_preview.wav', [1]);
    await projectRepo.projectsBox.put('a', TestFactories.makeProject(id: 'a'));
    backupListing(service, {'a': song.id});

    await service.uploadDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

    expect(listedSongs(), isEmpty);
  });

  test('a listed song no longer on Drive is not kept', () async {
    final service = await signedIn();
    songOnDrive('other_preview.wav', [1]);
    await projectRepo.projectsBox.put(
      'a',
      TestFactories.makeProject(id: 'a', previewSongPath: await managedCopy('a')),
    );
    backupListing(service, {'a': 'deleted-file'});

    await service.uploadDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

    expect(listedSongs(), isEmpty);
  });

  test('a song with its file here is uploaded as before', () async {
    final service = await signedIn();
    final file = File(p.join(tempDir.path, 'Mix.wav'))..writeAsBytesSync([9, 9]);
    await projectRepo.projectsBox.put(
      'a',
      TestFactories.makeProject(id: 'a', previewSongPath: file.path),
    );

    await service.uploadDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

    final uploaded = fakeDrive.named('a_preview.wav')!;
    expect(uploaded.content, [9, 9]);
    expect(listedSongs(), {'a': uploaded.id});
  });
}
