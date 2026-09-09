import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:daw_project_manager/services/scanner_service.dart';

void main() {
  group('bundle directory detection', () {
    // Regression coverage: LUNA (.luna) and GarageBand (.band) save projects
    // as a directory bundle, same as Logic Pro's .logicx — but scanDirectory
    // used to only special-case .logicx, so a .luna/.band bundle would get
    // pushed onto the traversal stack and recursed into instead of yielded
    // as a single project, silently finding nothing (no supported extension
    // lives inside the bundle's own contents).
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('scanner_bundle_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('.luna bundle directory is yielded as a single project', () async {
      final lunaDir = Directory(p.join(tempDir.path, 'My Song.luna'));
      await lunaDir.create(recursive: true);
      await File(p.join(lunaDir.path, 'session.dat')).writeAsString('fake');

      final results = await ScannerService().scanDirectory(tempDir.path).toList();

      expect(results, hasLength(1));
      expect(results.first.path, lunaDir.path);
      expect(results.first, isA<Directory>());
    });

    test('.band bundle directory (GarageBand) is yielded as a single project', () async {
      final bandDir = Directory(p.join(tempDir.path, 'My Song.band'));
      await bandDir.create(recursive: true);
      await File(p.join(bandDir.path, 'projectData')).writeAsString('fake');

      final results = await ScannerService().scanDirectory(tempDir.path).toList();

      expect(results, hasLength(1));
      expect(results.first.path, bandDir.path);
    });
  });

  group('projectContainingFolder', () {
    // Regression coverage for GitHub issue #142: "Open Folder" on a Logic Pro
    // / LUNA project opened the project in the DAW instead of revealing its
    // folder. Cause: the project's stored path IS the `.logicx`/`.luna`
    // directory (a package bundle), and the old logic did "if it's a
    // directory, open it as-is" — but `open`ing a bundle on macOS launches
    // the DAW. A bundle must resolve to its *parent*, same as a single file.
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('containing_folder_test_');
    });
    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('a .logicx bundle resolves to its parent folder, not itself', () async {
      final logicx = Directory(p.join(tempDir.path, 'Song.logicx'));
      await logicx.create();
      expect(
        ScannerService.projectContainingFolder(logicx.path),
        tempDir.path,
      );
    });

    test('a .luna bundle resolves to its parent folder', () async {
      final luna = Directory(p.join(tempDir.path, 'Song.luna'));
      await luna.create();
      expect(ScannerService.projectContainingFolder(luna.path), tempDir.path);
    });

    test('a single-file project resolves to its parent folder', () async {
      final flp = File(p.join(tempDir.path, 'Song.flp'));
      await flp.writeAsString('x');
      expect(ScannerService.projectContainingFolder(flp.path), tempDir.path);
    });

    test('a genuine loose-files project folder resolves to itself', () async {
      final projectDir = Directory(p.join(tempDir.path, 'My Project'));
      await projectDir.create();
      expect(
        ScannerService.projectContainingFolder(projectDir.path),
        projectDir.path,
      );
    });

    test(
      'release-detail "Open Folder" reveals the containing folder of a bundle '
      'track, not the bundle (release_detail_page had its own un-fixed copy of '
      'the #142 inline logic)',
      () async {
        // The releases tab track tile used to compute its folder as
        // `isDirectorySync(path) ? path : dirname(path)` — the exact naive
        // expression #142 removed from the dashboard. For a Logic Pro track
        // that meant opening the `.logicx` bundle, launching Logic instead of
        // showing the folder. It must now route through this helper like every
        // other "Open Folder" entry point.
        final songFolder = Directory(p.join(tempDir.path, 'Release', 'Track 01'));
        await songFolder.create(recursive: true);
        final logicx = Directory(p.join(songFolder.path, 'Track 01.logicx'));
        await logicx.create();

        expect(
          ScannerService.projectContainingFolder(logicx.path),
          songFolder.path,
        );
      },
    );

    test('isBundlePath is case-insensitive and extension-anchored', () {
      expect(ScannerService.isBundlePath('/x/Song.logicx'), isTrue);
      expect(ScannerService.isBundlePath('/x/Song.LOGICX'), isTrue);
      expect(ScannerService.isBundlePath('/x/Song.luna'), isTrue);
      expect(ScannerService.isBundlePath('/x/Song.band'), isTrue);
      expect(ScannerService.isBundlePath('/x/Song.als'), isFalse);
      expect(ScannerService.isBundlePath('/x/logicx-notes.txt'), isFalse);
    });
  });

  group('newlyFoundPaths', () {
    // Regression coverage for the "New" badge (recentlyDiscoveredProjectsProvider)
    // now that both the initial scan and a manual rescan run without blocking
    // the UI: a project that appears mid-scan needs to be distinguishable
    // from one that was already known, purely by comparing scan output
    // against a pre-scan snapshot of known paths.

    test('returns paths not present in knownPaths', () {
      final found = {'/a/one.als', '/a/two.als', '/a/three.als'};
      final known = {'/a/one.als'};

      expect(newlyFoundPaths(found, known), {'/a/two.als', '/a/three.als'});
    });

    test('returns empty when every found path was already known', () {
      final found = {'/a/one.als', '/a/two.als'};
      final known = {'/a/one.als', '/a/two.als', '/a/other.als'};

      expect(newlyFoundPaths(found, known), isEmpty);
    });

    test('returns everything found when nothing was previously known', () {
      final found = {'/a/one.als', '/a/two.als'};

      expect(newlyFoundPaths(found, {}), found);
    });

    test('is empty when the scan found nothing', () {
      expect(newlyFoundPaths({}, {'/a/one.als'}), isEmpty);
    });
  });
}
