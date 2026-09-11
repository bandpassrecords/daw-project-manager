import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/scan_root.dart';
import 'package:daw_project_manager/services/project_archive_service.dart';

import '../helpers/test_factories.dart';

ScanRoot _root(String path) => ScanRoot(
      id: 'root-${path.hashCode}',
      path: path,
      addedAt: DateTime(2025, 1, 1),
      scanDepth: 0,
    );

void main() {
  // -------------------------------------------------------------------------
  // Scope resolution — the part #116 said was undefined.
  // -------------------------------------------------------------------------
  group('defaultScopeFor', () {
    test('a bundle archives alone, never its parent', () {
      // Taking the parent of a .logicx would sweep up every sibling project.
      expect(
        defaultScopeFor(
          '/lib/Midnight.logicx',
          allProjectPaths: ['/lib/Midnight.logicx'],
        ),
        ArchiveScope.projectFileOnly,
      );
    });

    test('a bundle archives alone even in a folder of its own', () {
      expect(
        defaultScopeFor(
          '/lib/Midnight/Midnight.band',
          allProjectPaths: ['/lib/Midnight/Midnight.band'],
        ),
        ArchiveScope.projectFileOnly,
      );
    });

    test('a lone file in its own folder archives with the folder', () {
      expect(
        defaultScopeFor(
          '/lib/Midnight/Midnight.als',
          allProjectPaths: [
            '/lib/Midnight/Midnight.als',
            '/lib/Sunrise/Sunrise.als',
          ],
        ),
        ArchiveScope.containingFolder,
      );
    });

    test('a file sharing its folder archives alone', () {
      // A flat scan root: one archive must not swallow the other projects.
      expect(
        defaultScopeFor(
          '/lib/Flat/one.flp',
          allProjectPaths: ['/lib/Flat/one.flp', '/lib/Flat/two.flp'],
        ),
        ArchiveScope.projectFileOnly,
      );
    });
  });

  group('archiveSourceFor', () {
    test('folder scope resolves to the containing folder', () {
      expect(
        archiveSourceFor('/lib/Midnight/Midnight.als', ArchiveScope.containingFolder),
        '/lib/Midnight',
      );
    });

    test('file scope resolves to the project entity itself', () {
      expect(
        archiveSourceFor('/lib/Midnight/Midnight.als', ArchiveScope.projectFileOnly),
        '/lib/Midnight/Midnight.als',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Destination guard.
  // -------------------------------------------------------------------------
  group('conflictingScanRoot', () {
    final roots = [_root('/Users/me/Music/Projects')];

    test('rejects a scan root itself', () {
      expect(
        conflictingScanRoot('/Users/me/Music/Projects', roots)?.path,
        '/Users/me/Music/Projects',
      );
    });

    test('rejects a folder inside a scan root', () {
      expect(
        conflictingScanRoot('/Users/me/Music/Projects/Archive', roots),
        isNotNull,
      );
    });

    test('rejects an ancestor of a scan root', () {
      // A root is scanned wherever it sits, so archiving above it still means
      // the archives land inside scanned territory.
      expect(conflictingScanRoot('/Users/me/Music', roots), isNotNull);
    });

    test('accepts a sibling path', () {
      expect(conflictingScanRoot('/Users/me/Archive', roots), isNull);
    });

    test('is not fooled by a shared name prefix', () {
      // "/Users/me/Music/Projects Archive" is not inside "…/Projects".
      expect(
        conflictingScanRoot('/Users/me/Music/Projects Archive', roots),
        isNull,
      );
    });
  });

  group('archiveFileNameFor', () {
    test('uses the display name', () {
      expect(
        archiveFileNameFor(TestFactories.makeProject(customDisplayName: 'Midnight Drive')),
        'Midnight Drive.zip',
      );
    });

    test('strips characters a filesystem would reject', () {
      expect(
        archiveFileNameFor(TestFactories.makeProject(customDisplayName: 'A/B: C?')),
        'A_B_ C_.zip',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Archiving against a real filesystem.
  // -------------------------------------------------------------------------
  group('archiveProject', () {
    late Directory tempDir;
    late Directory library;
    late Directory archiveDir;
    late Directory projectFolder;
    late File projectFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('project_archive_test_');
      library = Directory(p.join(tempDir.path, 'Library'));
      archiveDir = Directory(p.join(tempDir.path, 'Archive'));
      projectFolder = Directory(p.join(library.path, 'Midnight'));
      await Directory(p.join(projectFolder.path, 'Samples')).create(recursive: true);
      await archiveDir.create(recursive: true);

      projectFile = File(p.join(projectFolder.path, 'Midnight.als'));
      await projectFile.writeAsString('project data');
      await File(p.join(projectFolder.path, 'Samples', 'kick.wav'))
          .writeAsString('kick audio');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    Future<Set<String>> entriesOf(String archivePath) async {
      final input = InputFileStream(archivePath);
      try {
        final archive = ZipDecoder().decodeStream(input);
        return {
          for (final f in archive.files)
            if (f.isFile) f.name,
        };
      } finally {
        await input.close();
      }
    }

    test('zips the whole folder and records where the project file sits',
        () async {
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        customDisplayName: 'Midnight',
      );

      final result = await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: false,
      );

      expect(File(result.archivePath).existsSync(), isTrue);
      expect(
        await entriesOf(result.archivePath),
        containsAll(<String>['Midnight/Midnight.als', 'Midnight/Samples/kick.wav']),
      );
      expect(result.project.isArchived, isTrue);
      expect(result.project.archiveEntryPath, 'Midnight/Midnight.als');
      expect(result.project.archivedAt, isNotNull);
      expect(result.originalsDeleted, isFalse);
    });

    test('zips only the project file under file scope', () async {
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        customDisplayName: 'Midnight',
      );

      final result = await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.projectFileOnly,
        deleteOriginals: false,
      );

      expect(await entriesOf(result.archivePath), <String>{'Midnight.als'});
      expect(result.project.archiveEntryPath, 'Midnight.als');
    });

    test('leaves filePath naming the original location', () async {
      // Repointing filePath at the zip would break fileExtension, DAW
      // launching, and "restore to where it came from".
      final project = TestFactories.makeProject(filePath: projectFile.path);

      final result = await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: false,
      );

      expect(result.project.filePath, projectFile.path);
    });

    test('an archived project is not a missing-file candidate', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);

      final result = await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: true,
      );

      // The originals are gone on purpose — "Delete Missing" must not offer to
      // throw away the row that points at the archive.
      expect(File(result.project.filePath).existsSync(), isFalse);
      expect(result.project.isMissingFileCandidate, isFalse);
    });

    test('deletes the originals only when asked', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);

      final kept = await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: false,
      );
      expect(projectFolder.existsSync(), isTrue, reason: 'unticked box keeps originals');
      await File(kept.archivePath).delete();

      final removed = await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: true,
      );
      expect(projectFolder.existsSync(), isFalse);
      expect(removed.originalsDeleted, isTrue);
    });

    test('refuses a destination inside a scan root, before writing anything',
        () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);
      final inside = Directory(p.join(library.path, 'Archive'));

      await expectLater(
        archiveProject(
          project,
          inside.path,
          scope: ArchiveScope.containingFolder,
          deleteOriginals: true,
          scanRoots: [_root(library.path)],
        ),
        throwsA(
          isA<ProjectArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveError.destinationInScanRoot,
          ),
        ),
      );

      expect(inside.existsSync(), isFalse);
      expect(projectFolder.existsSync(), isTrue);
    });

    test('refuses when an archive of that name is already there', () async {
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        customDisplayName: 'Midnight',
      );
      await File(p.join(archiveDir.path, 'Midnight.zip')).writeAsString('old');

      await expectLater(
        archiveProject(
          project,
          archiveDir.path,
          scope: ArchiveScope.containingFolder,
          deleteOriginals: true,
        ),
        throwsA(
          isA<ProjectArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveError.destinationOccupied,
          ),
        ),
      );

      expect(
        await File(p.join(archiveDir.path, 'Midnight.zip')).readAsString(),
        'old',
        reason: 'the existing archive must not be overwritten',
      );
      expect(projectFolder.existsSync(), isTrue);
    });

    test('refuses when the project file is not on this machine', () async {
      final project = TestFactories.makeProject(
        filePath: p.join(library.path, 'Gone', 'Gone.als'),
      );

      await expectLater(
        archiveProject(
          project,
          archiveDir.path,
          scope: ArchiveScope.projectFileOnly,
          deleteOriginals: false,
        ),
        throwsA(
          isA<ProjectArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveError.sourceMissing,
          ),
        ),
      );
    });

    test('cancelling leaves neither a .zip nor a .zip.part behind', () async {
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        customDisplayName: 'Midnight',
      );
      final token = ArchiveCancelToken()..cancel();

      await expectLater(
        archiveProject(
          project,
          archiveDir.path,
          scope: ArchiveScope.containingFolder,
          deleteOriginals: true,
          cancelToken: token,
        ),
        throwsA(isA<ArchiveCancelledException>()),
      );

      final leftovers = archiveDir.listSync().map((e) => p.basename(e.path));
      expect(leftovers, isEmpty);
      expect(projectFolder.existsSync(), isTrue,
          reason: 'a cancelled archive must never delete originals');
    });

    test('reports progress through to done', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);
      final stages = <ArchiveStage>[];

      await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: true,
        onProgress: (pr) => stages.add(pr.stage),
      );

      expect(stages.first, ArchiveStage.scanning);
      expect(stages, contains(ArchiveStage.compressing));
      expect(stages, contains(ArchiveStage.verifying));
      expect(stages, contains(ArchiveStage.deleting));
      expect(stages.last, ArchiveStage.done);
    });
  });

  // -------------------------------------------------------------------------
  // Verification — what stands between "written" and "delete 4 GB".
  // -------------------------------------------------------------------------
  group('verifyArchive', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('archive_verify_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('reports nothing missing for a complete archive', () async {
      final source = Directory(p.join(tempDir.path, 'Song'));
      await source.create(recursive: true);
      await File(p.join(source.path, 'a.als')).writeAsString('a');

      final zipPath = p.join(tempDir.path, 'Song.zip');
      final encoder = ZipFileEncoder()..create(zipPath);
      await encoder.addDirectory(source);
      await encoder.close();

      expect(await verifyArchive(zipPath, ['Song/a.als']), isEmpty);
    });

    test('names the entries an archive does not contain', () async {
      final source = Directory(p.join(tempDir.path, 'Song'));
      await source.create(recursive: true);
      await File(p.join(source.path, 'a.als')).writeAsString('a');

      final zipPath = p.join(tempDir.path, 'Song.zip');
      final encoder = ZipFileEncoder()..create(zipPath);
      await encoder.addDirectory(source);
      await encoder.close();

      expect(
        await verifyArchive(zipPath, ['Song/a.als', 'Song/missing.wav']),
        ['Song/missing.wav'],
      );
    });

    test('a corrupt archive verifies as nothing having arrived', () async {
      // The case that must never lead to deleting the originals.
      final zipPath = p.join(tempDir.path, 'Corrupt.zip');
      await File(zipPath).writeAsString('this is not a zip file at all');

      expect(
        await verifyArchive(zipPath, ['Song/a.als']),
        ['Song/a.als'],
      );
    });
  });

  // -------------------------------------------------------------------------
  // Restore.
  // -------------------------------------------------------------------------
  group('restoreProject', () {
    late Directory tempDir;
    late Directory archiveDir;
    late Directory restoreDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('archive_restore_test_');
      archiveDir = Directory(p.join(tempDir.path, 'Archive'));
      restoreDir = Directory(p.join(tempDir.path, 'Restored'));
      await archiveDir.create(recursive: true);
      await restoreDir.create(recursive: true);
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('extracts and repoints filePath at the recorded entry', () async {
      final source = Directory(p.join(tempDir.path, 'Midnight'));
      await Directory(p.join(source.path, 'Samples')).create(recursive: true);
      await File(p.join(source.path, 'Midnight.als')).writeAsString('als');
      await File(p.join(source.path, 'Samples', 'kick.wav')).writeAsString('kick');

      final original = TestFactories.makeProject(
        filePath: p.join(source.path, 'Midnight.als'),
        customDisplayName: 'Midnight',
      );
      final archived = (await archiveProject(
        original,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: true,
      ))
          .project;

      final restored = await restoreProject(archived, restoreDir.path);

      expect(restored.isArchived, isFalse);
      expect(restored.archiveEntryPath, isNull);
      expect(restored.archivedAt, isNull);
      expect(
        restored.filePath,
        p.join(restoreDir.path, 'Midnight', 'Midnight.als'),
      );
      expect(File(restored.filePath).existsSync(), isTrue);
      expect(await File(restored.filePath).readAsString(), 'als');
      expect(
        File(p.join(restoreDir.path, 'Midnight', 'Samples', 'kick.wav'))
            .existsSync(),
        isTrue,
      );
      // fileName follows filePath, or the row would show the archive's name.
      expect(restored.fileName, 'Midnight.als');
    });

    test('refuses a project that was never archived', () async {
      await expectLater(
        restoreProject(TestFactories.makeProject(), restoreDir.path),
        throwsA(
          isA<ProjectArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveError.notArchived,
          ),
        ),
      );
    });

    test('refuses when the archive file is gone', () async {
      final project = TestFactories.makeProject(
        archivePath: p.join(archiveDir.path, 'Nope.zip'),
        archiveEntryPath: 'Nope/Nope.als',
      );

      await expectLater(
        restoreProject(project, restoreDir.path),
        throwsA(
          isA<ProjectArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveError.sourceMissing,
          ),
        ),
      );
    });

    test('refuses to overwrite something already at the restore path', () async {
      final source = Directory(p.join(tempDir.path, 'Midnight'));
      await source.create(recursive: true);
      await File(p.join(source.path, 'Midnight.als')).writeAsString('als');

      final archived = (await archiveProject(
        TestFactories.makeProject(
          filePath: p.join(source.path, 'Midnight.als'),
          customDisplayName: 'Midnight',
        ),
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: true,
      ))
          .project;

      final clash = File(p.join(restoreDir.path, 'Midnight', 'Midnight.als'));
      await clash.parent.create(recursive: true);
      await clash.writeAsString('someone else');

      await expectLater(
        restoreProject(archived, restoreDir.path),
        throwsA(
          isA<ProjectArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveError.destinationOccupied,
          ),
        ),
      );
      expect(await clash.readAsString(), 'someone else');
    });
  });

  // -------------------------------------------------------------------------
  // Putting an archive back where it came from.
  // -------------------------------------------------------------------------
  group('originalRestoreFolderFor', () {
    test('folder-scoped archive resolves to the folder\'s parent', () {
      // Extracting a zip rooted at "Midnight/" into "/lib" recreates
      // "/lib/Midnight/Midnight.als" — the original filePath.
      final project = TestFactories.makeProject(
        filePath: '/lib/Midnight/Midnight.als',
        archivePath: '/archive/Midnight.zip',
        archiveEntryPath: 'Midnight/Midnight.als',
      );

      expect(originalRestoreFolderFor(project), '/lib');
    });

    test('file-scoped archive resolves to the containing folder', () {
      final project = TestFactories.makeProject(
        filePath: '/lib/Flat/one.flp',
        archivePath: '/archive/one.zip',
        archiveEntryPath: 'one.flp',
      );

      expect(originalRestoreFolderFor(project), '/lib/Flat');
    });

    test('a deeply nested project file resolves correctly', () {
      final project = TestFactories.makeProject(
        filePath: '/lib/Midnight/Sessions/Take 3/Midnight.als',
        archivePath: '/archive/Midnight.zip',
        archiveEntryPath: 'Midnight/Sessions/Take 3/Midnight.als',
      );

      expect(originalRestoreFolderFor(project), '/lib');
    });

    test('is null for a project that was never archived', () {
      expect(originalRestoreFolderFor(TestFactories.makeProject()), isNull);
    });
  });

  group('undoArchive', () {
    late Directory tempDir;
    late Directory library;
    late Directory archiveDir;
    late Directory projectFolder;
    late File projectFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('archive_undo_test_');
      library = Directory(p.join(tempDir.path, 'Library'));
      archiveDir = Directory(p.join(tempDir.path, 'Archive'));
      projectFolder = Directory(p.join(library.path, 'Midnight'));
      await Directory(p.join(projectFolder.path, 'Samples')).create(recursive: true);
      await archiveDir.create(recursive: true);

      projectFile = File(p.join(projectFolder.path, 'Midnight.als'));
      await projectFile.writeAsString('project data');
      await File(p.join(projectFolder.path, 'Samples', 'kick.wav'))
          .writeAsString('kick audio');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('puts the files back when the originals were deleted', () async {
      final archived = (await archiveProject(
        TestFactories.makeProject(
          filePath: projectFile.path,
          customDisplayName: 'Midnight',
        ),
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: true,
      ))
          .project;
      expect(projectFolder.existsSync(), isFalse);

      final reverted = await undoArchive(archived);

      expect(reverted.isArchived, isFalse);
      expect(reverted.archivedAt, isNull);
      expect(reverted.archiveEntryPath, isNull);
      // Back at exactly the path it started from, contents intact.
      expect(reverted.filePath, projectFile.path);
      expect(await File(projectFile.path).readAsString(), 'project data');
      expect(
        await File(p.join(projectFolder.path, 'Samples', 'kick.wav'))
            .readAsString(),
        'kick audio',
      );
      expect(File(archived.archivePath!).existsSync(), isFalse);
    });

    test('just drops the zip when the originals were kept', () async {
      final archived = (await archiveProject(
        TestFactories.makeProject(
          filePath: projectFile.path,
          customDisplayName: 'Midnight',
        ),
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: false,
      ))
          .project;

      final reverted = await undoArchive(archived);

      expect(reverted.isArchived, isFalse);
      expect(File(archived.archivePath!).existsSync(), isFalse);
      // The untouched originals must not have been extracted over.
      expect(await File(projectFile.path).readAsString(), 'project data');
    });

    test('keeps the archive when deleteArchiveFile is false', () async {
      final archived = (await archiveProject(
        TestFactories.makeProject(
          filePath: projectFile.path,
          customDisplayName: 'Midnight',
        ),
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: false,
      ))
          .project;

      final reverted = await undoArchive(archived, deleteArchiveFile: false);

      expect(reverted.isArchived, isFalse);
      expect(File(archived.archivePath!).existsSync(), isTrue);
    });

    test('refuses a project that was never archived', () async {
      await expectLater(
        undoArchive(TestFactories.makeProject()),
        throwsA(
          isA<ProjectArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveError.notArchived,
          ),
        ),
      );
    });

    test('leaves the project archived when the zip is gone', () async {
      // Files deleted and archive missing: there is nothing to bring back, so
      // undo must fail loudly rather than quietly clearing the flag and
      // stranding the project.
      final archived = (await archiveProject(
        TestFactories.makeProject(
          filePath: projectFile.path,
          customDisplayName: 'Midnight',
        ),
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: true,
      ))
          .project;
      await File(archived.archivePath!).delete();

      await expectLater(
        undoArchive(archived),
        throwsA(
          isA<ProjectArchiveException>().having(
            (e) => e.reason,
            'reason',
            ArchiveError.sourceMissing,
          ),
        ),
      );
      expect(archived.isArchived, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Size preview.
  // -------------------------------------------------------------------------
  group('archiveSizeOf', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('archive_size_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('folder scope totals every file beneath', () async {
      final folder = Directory(p.join(tempDir.path, 'Song'));
      await Directory(p.join(folder.path, 'Samples')).create(recursive: true);
      await File(p.join(folder.path, 'Song.als')).writeAsString('12345');
      await File(p.join(folder.path, 'Samples', 'kick.wav')).writeAsString('123');

      final size = await archiveSizeOf(
        p.join(folder.path, 'Song.als'),
        ArchiveScope.containingFolder,
      );

      expect(size.files, 2);
      expect(size.bytes, 8);
    });

    test('file scope totals just the project file', () async {
      final folder = Directory(p.join(tempDir.path, 'Song'));
      await folder.create(recursive: true);
      final file = File(p.join(folder.path, 'Song.als'));
      await file.writeAsString('12345');
      await File(p.join(folder.path, 'other.wav')).writeAsString('9999999');

      final size = await archiveSizeOf(file.path, ArchiveScope.projectFileOnly);

      expect(size.files, 1);
      expect(size.bytes, 5);
    });

    test('a missing source reports zero rather than throwing', () async {
      final size = await archiveSizeOf(
        p.join(tempDir.path, 'nothing.als'),
        ArchiveScope.projectFileOnly,
      );
      expect(size, (bytes: 0, files: 0));
    });
  });
}
