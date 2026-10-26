import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:daw_project_manager/services/backup_service.dart';
import 'package:daw_project_manager/utils/app_paths.dart';

import '../helpers/test_factories.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.supportPath);
  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

/// #110 — a local backup that stored only the cover's *path* would restore a
/// broken image on any other machine, and this is Flatpak's only backup path.
/// The bytes have to travel inside the JSON the way release artwork and
/// profile photos already do.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory sourceDir;

  // A 1x1 PNG — small, but real bytes rather than a string, so base64
  // round-tripping is actually exercised.
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cover_art_backup_');
    sourceDir = await Directory.systemTemp.createTemp('cover_art_source_');
    // Two levels down, so even an escape of two levels the code under test
    // fails to stop still lands in the temp folder, never on the machine.
    final appData = Directory(p.join(tempDir.path, 'a', 'b'));
    await appData.create(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(appData.path);
    // Windows reads %LOCALAPPDATA%, not the path provider: without this the
    // test wrote into the developer's real app data folder.
    debugLocalAppDataOverride = appData.path;
  });

  tearDown(() async {
    debugLocalAppDataOverride = null;
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
  });

  test('the cover image travels inside the backup and is written back out',
      () async {
    final cover = File(p.join(sourceDir.path, 'my-cover.png'));
    await cover.writeAsBytes(pngBytes);

    final original = TestFactories.makeProject(
      id: 'cover-1',
      thumbnailPath: cover.path,
      accentColor: 0xFF4FC3F7,
      iconKey: 'mic',
    );

    final json = await BackupService.projectToJsonWithCoverArt(original);
    expect(json['coverArtData'], isNotNull);
    expect(json['coverArtFileName'], 'my-cover.png');

    // Simulate restoring onto a different machine: the exporting machine's
    // folder is gone, so only the embedded bytes can save the cover.
    await sourceDir.delete(recursive: true);

    final restored = await BackupService.projectFromJsonWithCoverArt(
      jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
    );

    expect(restored.thumbnailPath, isNotNull);
    expect(restored.thumbnailPath, isNot(cover.path));
    expect(
      p.basename(p.dirname(restored.thumbnailPath!)),
      'project_cover_art',
      reason: 'the restored cover must land in the managed folder',
    );
    expect(await File(restored.thumbnailPath!).readAsBytes(), pngBytes);
    expect(restored.accentColor, 0xFF4FC3F7);
    expect(restored.iconKey, 'mic');
  });

  test('the restored cover is named after the project, not the source file',
      () async {
    // Two projects exported from libraries that both happened to use
    // "cover.png" must not overwrite each other on the way back in.
    final coverA = File(p.join(sourceDir.path, 'cover.png'));
    await coverA.writeAsBytes(pngBytes);

    final a = await BackupService.projectFromJsonWithCoverArt(
      await BackupService.projectToJsonWithCoverArt(
        TestFactories.makeProject(id: 'aaa', thumbnailPath: coverA.path),
      ),
    );
    final b = await BackupService.projectFromJsonWithCoverArt(
      await BackupService.projectToJsonWithCoverArt(
        TestFactories.makeProject(id: 'bbb', thumbnailPath: coverA.path),
      ),
    );

    expect(p.basename(a.thumbnailPath!), 'aaa_cover.png');
    expect(p.basename(b.thumbnailPath!), 'bbb_cover.png');
  });

  test('a project with no cover carries no image payload', () async {
    final json = await BackupService.projectToJsonWithCoverArt(
      TestFactories.makeProject(id: 'no-cover'),
    );

    expect(json.containsKey('coverArtData'), isFalse);
    final restored = await BackupService.projectFromJsonWithCoverArt(json);
    expect(restored.thumbnailPath, isNull);
  });

  test('an unreadable cover exports the metadata anyway', () async {
    // Backing up must not fail because one image went missing between the
    // scan and the export.
    final json = await BackupService.projectToJsonWithCoverArt(
      TestFactories.makeProject(
        id: 'gone',
        thumbnailPath: p.join(sourceDir.path, 'not-there.png'),
        accentColor: 0xFFEF5350,
      ),
    );

    expect(json.containsKey('coverArtData'), isFalse);
    expect(json['accentColor'], 0xFFEF5350);

    // And the path is kept: on the machine that made the backup it may still
    // resolve, and the avatar falls back to the accent colour if it does not.
    final restored = await BackupService.projectFromJsonWithCoverArt(json);
    expect(restored.thumbnailPath, p.join(sourceDir.path, 'not-there.png'));
  });

  // A backup is a file anyone could have written. Its ids and file names go
  // into the names of the images it carries, so a crafted one once wrote its
  // own bytes wherever `..\..\Startup\x_cover.bat` led.
  group('a crafted backup cannot write outside the managed folders', () {
    for (final id in [r'..\..\x', '../../x']) {
      test('a project id "$id" writes no cover anywhere', () async {
        final coverDir = await getProjectCoverArtPath();
        final restored = await BackupService.projectFromJsonWithCoverArt({
          ...BackupService.projectToJson(TestFactories.makeProject(id: id)),
          'coverArtData': base64Encode(pngBytes),
          'coverArtFileName': 'evil.bat',
        });

        expect(restored.thumbnailPath, isNull);
        for (final ext in ['.bat', '.jpg']) {
          expect(File(p.normalize(p.join(coverDir, '../../x_cover$ext'))).existsSync(), isFalse);
        }
      });

      test('a release id "$id" writes no artwork anywhere', () async {
        final artworkDir = await getReleaseArtworkPath();
        final release = await BackupService.releaseFromJsonForTest({
          'id': id,
          'title': 'EP',
          'artworkData': base64Encode(pngBytes),
          'artworkFileName': 'evil.bat',
        });

        expect(release.artworkImagePath, isNull);
        for (final ext in ['.bat', '.jpg']) {
          expect(File(p.normalize(p.join(artworkDir, '../../x_artwork$ext'))).existsSync(), isFalse);
        }
      });
    }

    test('a file name that is more than a name keeps only a safe extension', () async {
      final restored = await BackupService.projectFromJsonWithCoverArt({
        ...BackupService.projectToJson(TestFactories.makeProject(id: 'p1')),
        'coverArtData': base64Encode(pngBytes),
        'coverArtFileName': 'x.png:stream',
      });

      expect(p.basename(restored.thumbnailPath!), 'p1_cover.jpg');
      expect(await File(restored.thumbnailPath!).readAsBytes(), pngBytes);
    });

    test('a safe release id still restores its artwork', () async {
      final release = await BackupService.releaseFromJsonForTest({
        'id': 'r1',
        'title': 'EP',
        'artworkData': base64Encode(pngBytes),
        'artworkFileName': 'front.png',
      });

      expect(p.basename(release.artworkImagePath!), 'r1_artwork.png');
      expect(await File(release.artworkImagePath!).readAsBytes(), pngBytes);
    });
  });
}
