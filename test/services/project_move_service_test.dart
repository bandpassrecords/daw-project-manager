import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/project_move_service.dart';
import 'package:daw_project_manager/utils/project_folder_utils.dart';

import '../helpers/test_factories.dart';

void main() {
  // -------------------------------------------------------------------------
  // Pure path rewriting — the half a move gets wrong silently.
  // -------------------------------------------------------------------------
  group('repathProject', () {
    test('rewrites filePath and fileName when the file itself moves', () {
      final project = TestFactories.makeProject(
        filePath: '/old/Songs/Midnight.als',
        fileName: 'Midnight.als',
      );

      final moved = repathProject(
        project,
        from: '/old/Songs/Midnight.als',
        to: '/archive/Midnight.als',
      );

      expect(moved.filePath, '/archive/Midnight.als');
      expect(moved.fileName, 'Midnight.als');
    });

    test('rewrites paths nested under a moved folder', () {
      final project = TestFactories.makeProject(
        filePath: '/old/Midnight/Midnight.als',
        previewSongPath: '/old/Midnight/Bounces/rough.wav',
        previewSongAutoPath: '/old/Midnight/Bounces/auto.wav',
      );

      final moved = repathProject(
        project,
        from: '/old/Midnight',
        to: '/archive/Midnight',
      );

      expect(moved.filePath, '/archive/Midnight/Midnight.als');
      expect(moved.previewSongPath, '/archive/Midnight/Bounces/rough.wav');
      expect(moved.previewSongAutoPath, '/archive/Midnight/Bounces/auto.wav');
    });

    test('leaves a preview song outside the moved prefix alone', () {
      final project = TestFactories.makeProject(
        filePath: '/old/Midnight/Midnight.als',
        // A bounce the user keeps in a shared renders folder, not in the
        // project folder — moving the project must not claim it moved too.
        previewSongPath: '/Users/me/Renders/midnight_master.wav',
      );

      final moved = repathProject(
        project,
        from: '/old/Midnight',
        to: '/archive/Midnight',
      );

      expect(moved.filePath, '/archive/Midnight/Midnight.als');
      expect(moved.previewSongPath, '/Users/me/Renders/midnight_master.wav');
    });

    test('leaves a drive:// preview reference untouched', () {
      final project = TestFactories.makeProject(
        filePath: '/old/Midnight/Midnight.als',
        previewSongPath: 'drive://1a2b3c',
      );

      final moved = repathProject(
        project,
        from: '/old/Midnight',
        to: '/archive/Midnight',
      );

      // Normalizing this as a path would turn it into "drive:/1a2b3c" and the
      // Drive fallback would stop resolving.
      expect(moved.previewSongPath, 'drive://1a2b3c');
    });

    test('does not rewrite a sibling folder sharing a name prefix', () {
      // "/old/Midnight Drive" starts with "/old/Midnight" as a *string* but is
      // not inside it — only a separator-aware prefix test gets this right.
      final project = TestFactories.makeProject(
        filePath: '/old/Midnight Drive/Song.als',
      );

      final moved = repathProject(
        project,
        from: '/old/Midnight',
        to: '/archive/Midnight',
      );

      expect(moved.filePath, '/old/Midnight Drive/Song.als');
    });
  });

  // -------------------------------------------------------------------------
  // Folder-dedication test, shared with the archive scope resolver.
  // -------------------------------------------------------------------------
  group('folderIsDedicatedTo', () {
    test('is true when no other project shares the folder', () {
      expect(
        folderIsDedicatedTo('/lib/Midnight/Midnight.als', [
          '/lib/Midnight/Midnight.als',
          '/lib/Sunrise/Sunrise.als',
        ]),
        isTrue,
      );
    });

    test('is false when another project sits in the same folder', () {
      expect(
        folderIsDedicatedTo('/lib/Flat/one.flp', [
          '/lib/Flat/one.flp',
          '/lib/Flat/two.flp',
        ]),
        isFalse,
      );
    });

    test('ignores the project\'s own entry regardless of path spelling', () {
      expect(
        folderIsDedicatedTo('/lib/Midnight/Midnight.als', [
          '/lib/./Midnight/Midnight.als',
        ]),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Real filesystem moves.
  // -------------------------------------------------------------------------
  group('moveProject', () {
    late Directory tempDir;
    late Directory library;
    late Directory destination;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('project_move_test_');
      library = Directory(p.join(tempDir.path, 'Library'));
      destination = Directory(p.join(tempDir.path, 'Archive'));
      await library.create(recursive: true);
      await destination.create(recursive: true);
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('moves a single project file and repaths the project', () async {
      final src = File(p.join(library.path, 'Midnight.als'));
      await src.writeAsString('als');
      final project = TestFactories.makeProject(filePath: src.path);

      final result = await moveProject(
        project,
        destination.path,
        moveContainingFolder: false,
      );

      expect(src.existsSync(), isFalse);
      final moved = File(p.join(destination.path, 'Midnight.als'));
      expect(moved.existsSync(), isTrue);
      expect(await moved.readAsString(), 'als');
      expect(result.project.filePath, moved.path);
      expect(result.movedTo, moved.path);
    });

    test('moves a bundle directory as one unit', () async {
      final bundle = Directory(p.join(library.path, 'Midnight.logicx'));
      await bundle.create(recursive: true);
      await File(p.join(bundle.path, 'ProjectData')).writeAsString('logic');
      final project = TestFactories.makeProject(filePath: bundle.path);

      final result = await moveProject(
        project,
        destination.path,
        moveContainingFolder: false,
      );

      expect(bundle.existsSync(), isFalse);
      final movedBundle = Directory(p.join(destination.path, 'Midnight.logicx'));
      expect(movedBundle.existsSync(), isTrue);
      expect(
        File(p.join(movedBundle.path, 'ProjectData')).existsSync(),
        isTrue,
      );
      expect(result.project.filePath, movedBundle.path);
    });

    test('moves the whole containing folder and repaths nested files', () async {
      final folder = Directory(p.join(library.path, 'Midnight'));
      final bounces = Directory(p.join(folder.path, 'Bounces'));
      await bounces.create(recursive: true);
      final projectFile = File(p.join(folder.path, 'Midnight.als'));
      await projectFile.writeAsString('als');
      final bounce = File(p.join(bounces.path, 'rough.wav'));
      await bounce.writeAsString('wav');

      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        previewSongPath: bounce.path,
      );

      final result = await moveProject(
        project,
        destination.path,
        moveContainingFolder: true,
      );

      expect(folder.existsSync(), isFalse);
      final movedFolder = Directory(p.join(destination.path, 'Midnight'));
      expect(movedFolder.existsSync(), isTrue);
      expect(
        result.project.filePath,
        p.join(movedFolder.path, 'Midnight.als'),
      );
      expect(
        result.project.previewSongPath,
        p.join(movedFolder.path, 'Bounces', 'rough.wav'),
      );
      expect(File(result.project.previewSongPath!).existsSync(), isTrue);
    });

    test('refuses when the destination already holds that name', () async {
      final src = File(p.join(library.path, 'Midnight.als'));
      await src.writeAsString('als');
      await File(p.join(destination.path, 'Midnight.als')).writeAsString('old');
      final project = TestFactories.makeProject(filePath: src.path);

      await expectLater(
        moveProject(project, destination.path, moveContainingFolder: false),
        throwsA(
          isA<ProjectMoveException>().having(
            (e) => e.reason,
            'reason',
            ProjectMoveError.destinationOccupied,
          ),
        ),
      );

      // Refused before anything moved: both files are still where they were.
      expect(src.existsSync(), isTrue);
      expect(
        await File(p.join(destination.path, 'Midnight.als')).readAsString(),
        'old',
      );
    });

    test('refuses to move a folder into its own subtree', () async {
      final folder = Directory(p.join(library.path, 'Midnight'));
      final inner = Directory(p.join(folder.path, 'Inner'));
      await inner.create(recursive: true);
      final projectFile = File(p.join(folder.path, 'Midnight.als'));
      await projectFile.writeAsString('als');
      final project = TestFactories.makeProject(filePath: projectFile.path);

      await expectLater(
        moveProject(project, inner.path, moveContainingFolder: true),
        throwsA(
          isA<ProjectMoveException>().having(
            (e) => e.reason,
            'reason',
            ProjectMoveError.destinationInsideSource,
          ),
        ),
      );

      expect(projectFile.existsSync(), isTrue);
    });

    test('refuses when the project file is not on this machine', () async {
      final project = TestFactories.makeProject(
        filePath: p.join(library.path, 'Gone.als'),
      );

      await expectLater(
        moveProject(project, destination.path, moveContainingFolder: false),
        throwsA(
          isA<ProjectMoveException>().having(
            (e) => e.reason,
            'reason',
            ProjectMoveError.sourceMissing,
          ),
        ),
      );
    });

    test('refuses a move to where the project already is', () async {
      final src = File(p.join(library.path, 'Midnight.als'));
      await src.writeAsString('als');
      final project = TestFactories.makeProject(filePath: src.path);

      await expectLater(
        moveProject(project, library.path, moveContainingFolder: false),
        throwsA(
          isA<ProjectMoveException>().having(
            (e) => e.reason,
            'reason',
            ProjectMoveError.sameLocation,
          ),
        ),
      );

      expect(src.existsSync(), isTrue);
    });

    test('creates the destination folder when it does not exist', () async {
      final src = File(p.join(library.path, 'Midnight.als'));
      await src.writeAsString('als');
      final project = TestFactories.makeProject(filePath: src.path);
      final fresh = p.join(tempDir.path, 'Fresh', 'Nested');

      final result = await moveProject(
        project,
        fresh,
        moveContainingFolder: false,
      );

      expect(File(result.project.filePath).existsSync(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // The cross-device fallback, exercised directly — a real cross-volume
  // rename failure isn't reproducible in CI.
  // -------------------------------------------------------------------------
  group('copyEntityThenDelete', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('project_move_copy_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('copies a directory tree intact, then removes the original', () async {
      final source = Directory(p.join(tempDir.path, 'Midnight'));
      final nested = Directory(p.join(source.path, 'Samples', 'Drums'));
      await nested.create(recursive: true);
      await File(p.join(source.path, 'Midnight.als')).writeAsString('als');
      await File(p.join(nested.path, 'kick.wav')).writeAsString('kick');

      final destPath = p.join(tempDir.path, 'Archive', 'Midnight');
      await Directory(p.dirname(destPath)).create(recursive: true);

      await copyEntityThenDelete(source.path, destPath, isDirectory: true);

      expect(source.existsSync(), isFalse);
      expect(File(p.join(destPath, 'Midnight.als')).existsSync(), isTrue);
      expect(
        await File(
          p.join(destPath, 'Samples', 'Drums', 'kick.wav'),
        ).readAsString(),
        'kick',
      );
    });

    test('copies a single file, then removes the original', () async {
      final source = File(p.join(tempDir.path, 'Midnight.als'));
      await source.writeAsString('als');
      final destPath = p.join(tempDir.path, 'moved.als');

      await copyEntityThenDelete(source.path, destPath, isDirectory: false);

      expect(source.existsSync(), isFalse);
      expect(await File(destPath).readAsString(), 'als');
    });
  });
}
