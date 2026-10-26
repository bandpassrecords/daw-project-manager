import 'dart:io';

import 'package:daw_project_manager/services/google_drive_sync_service.dart';
import 'package:daw_project_manager/utils/app_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/fake_drive.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getApplicationDocumentsPath() async => p.join(root, 'documents');
}

/// Media downloaded from a Drive backup is named after the backup's own ids:
/// an id that climbs out of the folder (`../../escape`) must not steer the
/// write elsewhere. The downloads refuse it instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory appData;
  late FakeDrive fakeDrive;
  late GoogleDriveSyncService service;
  late String driveFileId;

  setUp(() async {
    // Nested, so an escape of two levels still lands inside the temp root,
    // where the test can look for it.
    final root = await Directory.systemTemp.createTemp('dpm_drive_paths_');
    appData = Directory(p.join(root.path, 'a', 'b'));
    await appData.create(recursive: true);
    debugLocalAppDataOverride = appData.path;
    PathProviderPlatform.instance = _FakePathProvider(appData.path);
    fakeDrive = FakeDrive();
    service = GoogleDriveSyncService()..driveApi = fakeDrive.api;
    driveFileId = fakeDrive.seed(name: 'media', parent: 'root', content: [1, 2, 3]).id;
  });

  tearDown(() async {
    debugLocalAppDataOverride = null;
    final root = appData.parent.parent;
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// Every file under the temp root that isn't under the app's data folder.
  List<String> writtenOutside() => appData.parent.parent
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path)
      .where((path) => !p.isWithin(appData.path, path))
      .toList();

  const escapes = ['../../escape', r'..\..\escape'];

  test('a safe id still downloads into the managed folder', () async {
    final cover = await service.downloadProjectCoverArtFile(
      driveFileId: driveFileId,
      projectId: '3f2a9c1e-0b7d-4c8e-9a51-2d6f0e8b4c11',
      fileExtension: '.png',
    );
    expect(cover, isNotNull);
    expect(p.isWithin(await getProjectCoverArtPath(), cover!), isTrue);
    expect(await File(cover).readAsBytes(), [1, 2, 3]);
  });

  for (final id in escapes) {
    test('cover art refuses the project id "$id"', () async {
      final result = await service.downloadProjectCoverArtFile(
        driveFileId: driveFileId,
        projectId: id,
        fileExtension: '.bat',
      );
      expect(result, isNull);
      expect(writtenOutside(), isEmpty);
    });

    test('a preview song refuses the project id "$id"', () async {
      final result = await service.downloadPreviewSongFile(
        driveFileId: driveFileId,
        projectId: id,
        fileExtension: '.wav',
      );
      expect(result, isNull);
      expect(writtenOutside(), isEmpty);
    });

    test('release artwork refuses the release id "$id"', () async {
      final result = await service.downloadReleaseArtworkFile(
        driveFileId: driveFileId,
        releaseId: id,
        fileExtension: '.jpg',
      );
      expect(result, isNull);
      expect(writtenOutside(), isEmpty);
    });

    test('a profile photo refuses the profile id "$id"', () async {
      final result = await service.downloadProfilePhotoFile(
        driveFileId: driveFileId,
        profileId: id,
        fileExtension: '.jpg',
      );
      expect(result, isNull);
      expect(writtenOutside(), isEmpty);
    });
  }

  test('an extension that is more than an extension falls back', () async {
    final cover = await service.downloadProjectCoverArtFile(
      driveFileId: driveFileId,
      projectId: 'p1',
      fileExtension: r'.jpg\..\..\x',
    );
    expect(cover, isNotNull);
    expect(p.basename(cover!), 'p1_cover.jpg');
  });
}
