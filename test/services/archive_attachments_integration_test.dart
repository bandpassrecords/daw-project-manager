import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/project_attachment.dart';
import 'package:daw_project_manager/services/project_archive_service.dart';
import 'package:daw_project_manager/services/project_move_service.dart';

import '../helpers/test_factories.dart';

/// Where #112 (attachments) meets #116 (archive) and #88 (move).
///
/// Each feature was built on its own branch and is individually correct; these
/// are the behaviours that only exist once they are in the same tree.
void main() {
  late Directory tempDir;
  late Directory library;
  late Directory archiveDir;
  late Directory projectFolder;
  late File projectFile;

  ProjectAttachment fileAttachment(String id, String target) =>
      ProjectAttachment(
        id: id,
        kind: ProjectAttachmentKind.file,
        target: target,
        addedAt: DateTime(2026, 1, 1),
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('archive_attach_test_');
    library = Directory(p.join(tempDir.path, 'Library'));
    archiveDir = Directory(p.join(tempDir.path, 'Archive'));
    projectFolder = Directory(p.join(library.path, 'Midnight'));
    await projectFolder.create(recursive: true);
    await archiveDir.create(recursive: true);
    projectFile = File(p.join(projectFolder.path, 'Midnight.als'));
    await projectFile.writeAsString('als');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<Set<String>> entriesOf(String archivePath) async {
    final input = InputFileStream(archivePath);
    try {
      return {
        for (final f in ZipDecoder().decodeStream(input).files)
          if (f.isFile) f.name,
      };
    } finally {
      await input.close();
    }
  }

  group('attachmentsToGather', () {
    test('picks up a file attachment living outside the archived folder',
        () async {
      final outside = File(p.join(tempDir.path, 'reference.wav'));
      await outside.writeAsString('ref');
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        attachments: [fileAttachment('a1', outside.path)],
      );

      final gathered = attachmentsToGather(project, projectFolder.path);

      expect(gathered.map((a) => a.id), ['a1']);
    });

    test('skips one already inside the folder, which the walk covers',
        () async {
      final inside = File(p.join(projectFolder.path, 'lyrics.txt'));
      await inside.writeAsString('words');
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        attachments: [fileAttachment('a1', inside.path)],
      );

      expect(attachmentsToGather(project, projectFolder.path), isEmpty);
    });

    test('skips links, which have no bytes to archive', () {
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        attachments: [
          ProjectAttachment(
            id: 'a1',
            kind: ProjectAttachmentKind.link,
            target: 'https://example.com/stems',
            addedAt: DateTime(2026, 1, 1),
          ),
        ],
      );

      expect(attachmentsToGather(project, projectFolder.path), isEmpty);
    });

    test('skips a target that no longer resolves', () {
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        attachments: [
          fileAttachment('a1', p.join(tempDir.path, 'deleted-long-ago.pdf')),
        ],
      );

      expect(attachmentsToGather(project, projectFolder.path), isEmpty);
    });
  });

  group('attachmentEntryPathFor', () {
    test('keys on the attachment id so same-named files cannot collide', () {
      final a = fileAttachment('a1', '/downloads/notes.pdf');
      final b = fileAttachment('a2', '/desktop/notes.pdf');

      expect(attachmentEntryPathFor(a), '_attachments/a1/notes.pdf');
      expect(attachmentEntryPathFor(b), '_attachments/a2/notes.pdf');
    });
  });

  group('archiveProject with attachments', () {
    test('gathers an outside attachment into the zip', () async {
      final outside = File(p.join(tempDir.path, 'reference.wav'));
      await outside.writeAsString('reference audio');
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        customDisplayName: 'Midnight',
        attachments: [fileAttachment('a1', outside.path)],
      );

      final result = await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: false,
      );

      expect(
        await entriesOf(result.archivePath),
        containsAll(<String>[
          'Midnight/Midnight.als',
          '_attachments/a1/reference.wav',
        ]),
      );
    });

    test('does not store an inside attachment twice', () async {
      final inside = File(p.join(projectFolder.path, 'lyrics.txt'));
      await inside.writeAsString('words');
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        customDisplayName: 'Midnight',
        attachments: [fileAttachment('a1', inside.path)],
      );

      final result = await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: false,
      );

      final entries = await entriesOf(result.archivePath);
      expect(entries, contains('Midnight/lyrics.txt'));
      expect(entries.where((e) => e.startsWith('_attachments/')), isEmpty);
    });

    test('gathered attachments are covered by verification', () async {
      // The delete-originals gate is only as good as the entry list it checks,
      // so a gathered attachment has to be in it.
      final outside = File(p.join(tempDir.path, 'reference.wav'));
      await outside.writeAsString('reference audio');
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        customDisplayName: 'Midnight',
        attachments: [fileAttachment('a1', outside.path)],
      );

      final result = await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: false,
      );

      expect(
        await verifyArchive(result.archivePath, ['_attachments/a1/reference.wav']),
        isEmpty,
      );
    });

    test('archiving never deletes an attachment outside the folder', () async {
      // deleteOriginals means "the project's own files", not "everything this
      // project points at" — the reference track in Downloads is not ours.
      final outside = File(p.join(tempDir.path, 'reference.wav'));
      await outside.writeAsString('reference audio');
      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        customDisplayName: 'Midnight',
        attachments: [fileAttachment('a1', outside.path)],
      );

      await archiveProject(
        project,
        archiveDir.path,
        scope: ArchiveScope.containingFolder,
        deleteOriginals: true,
      );

      expect(projectFolder.existsSync(), isFalse);
      expect(outside.existsSync(), isTrue);
    });
  });

  group('repathRestoredAttachments', () {
    test('leaves an attachment whose original still resolves alone', () async {
      // Archiving never deleted it, so it is still the right target; pointing
      // it into a restore folder would drag a live file out from under the
      // user.
      final outside = File(p.join(tempDir.path, 'reference.wav'));
      await outside.writeAsString('ref');
      final restoreDir = Directory(p.join(tempDir.path, 'Restored'));
      await Directory(p.join(restoreDir.path, '_attachments', 'a1'))
          .create(recursive: true);
      await File(p.join(restoreDir.path, '_attachments', 'a1', 'reference.wav'))
          .writeAsString('ref');

      final project = TestFactories.makeProject(
        attachments: [fileAttachment('a1', outside.path)],
      );

      final result = repathRestoredAttachments(project, restoreDir.path);

      expect(result.attachments.single.target, outside.path);
    });

    test('repoints one whose original is gone at the extracted copy', () async {
      final restoreDir = Directory(p.join(tempDir.path, 'Restored'));
      await Directory(p.join(restoreDir.path, '_attachments', 'a1'))
          .create(recursive: true);
      final extracted =
          File(p.join(restoreDir.path, '_attachments', 'a1', 'reference.wav'));
      await extracted.writeAsString('ref');

      final project = TestFactories.makeProject(
        attachments: [
          fileAttachment('a1', p.join(tempDir.path, 'gone', 'reference.wav')),
        ],
      );

      final result = repathRestoredAttachments(project, restoreDir.path);

      expect(result.attachments.single.target, extracted.path);
    });

    test('leaves a broken attachment the archive never carried', () {
      final project = TestFactories.makeProject(
        attachments: [fileAttachment('a1', '/nowhere/at/all.pdf')],
      );

      final result = repathRestoredAttachments(project, tempDir.path);

      expect(result.attachments.single.target, '/nowhere/at/all.pdf');
    });

    test('never touches a link', () {
      final project = TestFactories.makeProject(
        attachments: [
          ProjectAttachment(
            id: 'a1',
            kind: ProjectAttachmentKind.link,
            target: 'https://example.com/stems',
            addedAt: DateTime(2026, 1, 1),
          ),
        ],
      );

      final result = repathRestoredAttachments(project, tempDir.path);

      expect(result.attachments.single.target, 'https://example.com/stems');
    });
  });

  group('moveProject with attachments', () {
    test('repaths an attachment that lived inside the moved folder', () async {
      // The lyric sheet a user drops next to the project file is the common
      // case, and a move that left it pointing at the old path would break
      // every one of them.
      final inside = File(p.join(projectFolder.path, 'lyrics.txt'));
      await inside.writeAsString('words');
      final outside = File(p.join(tempDir.path, 'contract.pdf'));
      await outside.writeAsString('sign here');
      final destination = Directory(p.join(tempDir.path, 'Moved'));
      await destination.create(recursive: true);

      final project = TestFactories.makeProject(
        filePath: projectFile.path,
        attachments: [
          fileAttachment('inside', inside.path),
          fileAttachment('outside', outside.path),
          ProjectAttachment(
            id: 'link',
            kind: ProjectAttachmentKind.link,
            target: 'https://example.com/stems',
            addedAt: DateTime(2026, 1, 1),
          ),
        ],
      );

      final result = await moveProject(
        project,
        destination.path,
        moveContainingFolder: true,
      );

      final byId = {for (final a in result.project.attachments) a.id: a.target};
      expect(byId['inside'], p.join(destination.path, 'Midnight', 'lyrics.txt'));
      expect(File(byId['inside']!).existsSync(), isTrue);
      // Outside the moved folder, so untouched — and a link is not a path.
      expect(byId['outside'], outside.path);
      expect(byId['link'], 'https://example.com/stems');
    });
  });
}
