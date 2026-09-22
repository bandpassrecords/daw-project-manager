import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/project_attachment.dart';
import 'package:daw_project_manager/services/attachment_export_service.dart';

/// #112 — exporting a song's attachments. The shape of the output is chosen
/// before anything is read, so the "one file vs. one text file vs. a ZIP"
/// rule is tested without a file system; the writing half then gets a real
/// temp directory.
void main() {
  ProjectAttachment file(String path, {String id = 'f', String label = ''}) =>
      ProjectAttachment(
        id: id,
        kind: ProjectAttachmentKind.file,
        target: path,
        label: label,
        addedAt: DateTime(2025, 1, 1),
      );

  ProjectAttachment link(
    String url, {
    String id = 'l',
    String label = '',
    String? note,
  }) =>
      ProjectAttachment(
        id: id,
        kind: ProjectAttachmentKind.link,
        target: url,
        label: label,
        addedAt: DateTime(2025, 1, 1),
        note: note,
      );

  // Every file path "exists" unless it is named as gone.
  bool Function(String) existsExcept(Set<String> gone) =>
      (path) => !gone.contains(path);

  group('planAttachmentExport', () {
    test('nothing attached means nothing to export', () {
      final plan = planAttachmentExport(
        attachments: const [],
        fileExists: existsExcept(const {}),
      );

      expect(plan.kind, AttachmentExportKind.nothing);
      expect(plan.isEmpty, isTrue);
    });

    test('a single file is exported as itself, not as a one-entry ZIP', () {
      final plan = planAttachmentExport(
        attachments: [file('/refs/ref.wav')],
        fileExists: existsExcept(const {}),
      );

      expect(plan.kind, AttachmentExportKind.singleFile);
      expect(plan.suggestedFileName('My Song'), 'ref.wav');
    });

    test('a single link becomes one text file', () {
      final plan = planAttachmentExport(
        attachments: [link('https://example.com/stems')],
        fileExists: existsExcept(const {}),
      );

      expect(plan.kind, AttachmentExportKind.linksOnly);
      expect(plan.suggestedFileName('My Song'), 'My Song_links.txt');
    });

    test('several links still travel as one text file, not a ZIP', () {
      final plan = planAttachmentExport(
        attachments: [
          link('https://example.com/a', id: 'l1'),
          link('https://example.com/b', id: 'l2'),
          link('https://example.com/c', id: 'l3'),
        ],
        fileExists: existsExcept(const {}),
      );

      expect(plan.kind, AttachmentExportKind.linksOnly);
      expect(plan.links, hasLength(3));
    });

    test('two files become a ZIP', () {
      final plan = planAttachmentExport(
        attachments: [
          file('/refs/a.wav', id: 'f1'),
          file('/refs/b.wav', id: 'f2'),
        ],
        fileExists: existsExcept(const {}),
      );

      expect(plan.kind, AttachmentExportKind.zip);
      expect(plan.suggestedFileName('My Song'), 'My Song_attachments.zip');
    });

    test('one file plus one link becomes a ZIP carrying both', () {
      final plan = planAttachmentExport(
        attachments: [file('/refs/a.wav'), link('https://example.com/x')],
        fileExists: existsExcept(const {}),
      );

      expect(plan.kind, AttachmentExportKind.zip);
      expect(plan.files, hasLength(1));
      expect(plan.links, hasLength(1));
    });

    test('a moved file is set aside, not exported', () {
      final plan = planAttachmentExport(
        attachments: [
          file('/refs/here.wav', id: 'f1'),
          file('/refs/gone.wav', id: 'f2'),
        ],
        fileExists: existsExcept({'/refs/gone.wav'}),
      );

      expect(plan.missingFiles.map((a) => a.id), ['f2']);
      expect(
        plan.kind,
        AttachmentExportKind.singleFile,
        reason: 'one file left means one file out, not a ZIP of one',
      );
    });

    test('only missing files means there is nothing left to export', () {
      final plan = planAttachmentExport(
        attachments: [file('/refs/gone.wav')],
        fileExists: existsExcept({'/refs/gone.wav'}),
      );

      expect(plan.kind, AttachmentExportKind.nothing);
      expect(plan.missingFiles, hasLength(1));
    });

    test('a blank target is skipped entirely', () {
      final plan = planAttachmentExport(
        attachments: [file('   ')],
        fileExists: existsExcept(const {}),
      );

      expect(plan.kind, AttachmentExportKind.nothing);
      expect(plan.missingFiles, isEmpty);
    });

    test('a song name with path characters cannot escape the file name', () {
      final plan = planAttachmentExport(
        attachments: [
          file('/refs/a.wav', id: 'f1'),
          file('/refs/b.wav', id: 'f2'),
        ],
        fileExists: existsExcept(const {}),
      );

      expect(
        plan.suggestedFileName('AC/DC: "Live"'),
        'AC_DC_ _Live__attachments.zip',
      );
    });
  });

  group('buildAttachmentLinksFile', () {
    test('carries label, URL and note for each link', () {
      final text = buildAttachmentLinksFile(
        header: 'My Song',
        links: [
          link(
            'https://example.com/stems',
            id: 'l1',
            label: 'Stem delivery',
            note: 'expires in 7 days',
          ),
          link('https://example.com/lyrics', id: 'l2', label: 'Lyric sheet'),
        ],
      );

      expect(text, startsWith('My Song\n'));
      expect(text, contains('Stem delivery'));
      expect(text, contains('https://example.com/stems'));
      expect(text, contains('expires in 7 days'));
      expect(text, contains('Lyric sheet'));
      expect(text, contains('https://example.com/lyrics'));
    });

    test('an unlabelled link still gets a readable line', () {
      final text = buildAttachmentLinksFile(
        header: 'My Song',
        links: [link('https://drive.google.com/folders/abc')],
      );

      expect(text, contains('drive.google.com/folders/abc'));
    });
  });

  group('zipEntryNames', () {
    test('two attachments with the same base name do not collide', () {
      final names = zipEntryNames([
        file('/refs/a/ref.wav', id: 'f1'),
        file('/refs/b/ref.wav', id: 'f2'),
        file('/refs/c/ref.wav', id: 'f3'),
      ]);

      expect(names, ['ref.wav', 'ref (2).wav', 'ref (3).wav']);
    });

    test('a file named like the links file yields to it', () {
      final names = zipEntryNames(
        [file('/refs/links.txt')],
        reserved: {attachmentLinksFileName},
      );

      expect(names, ['links (2).txt']);
    });
  });

  group('AttachmentExportService.write', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('attachment_export_');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    Future<String> makeSource(String name, String contents) async {
      final f = File(p.join(tempDir.path, name));
      await f.writeAsString(contents);
      return f.path;
    }

    test('a single file is copied, and the original is left alone', () async {
      final source = await makeSource('ref.wav', 'audio-bytes');
      final plan = planAttachmentExport(attachments: [file(source)]);
      final destination = p.join(tempDir.path, 'out', 'ref.wav');

      final written = await AttachmentExportService.write(
        plan: plan,
        destinationPath: destination,
        linksHeader: 'My Song',
      );

      expect(await written.readAsString(), 'audio-bytes');
      expect(
        await File(source).exists(),
        isTrue,
        reason: 'exporting must never move or consume the original',
      );
    });

    test('links alone are written as plain text', () async {
      final plan = planAttachmentExport(
        attachments: [link('https://example.com/stems', label: 'Stems')],
      );
      final destination = p.join(tempDir.path, 'links.txt');

      final written = await AttachmentExportService.write(
        plan: plan,
        destinationPath: destination,
        linksHeader: 'My Song',
      );

      final text = await written.readAsString();
      expect(text, contains('My Song'));
      expect(text, contains('https://example.com/stems'));
    });

    test('files and links go into one ZIP, links as links.txt', () async {
      final a = await makeSource('a.wav', 'aaa');
      final b = await makeSource('b.wav', 'bbb');
      final plan = planAttachmentExport(
        attachments: [
          file(a, id: 'f1'),
          file(b, id: 'f2'),
          link('https://example.com/stems', id: 'l1', label: 'Stems'),
        ],
      );
      final destination = p.join(tempDir.path, 'out.zip');

      final written = await AttachmentExportService.write(
        plan: plan,
        destinationPath: destination,
        linksHeader: 'My Song',
      );

      final archive = ZipDecoder().decodeBytes(await written.readAsBytes());
      expect(
        archive.files.map((f) => f.name).toSet(),
        {'a.wav', 'b.wav', attachmentLinksFileName},
      );

      final links = archive.files
          .firstWhere((f) => f.name == attachmentLinksFileName);
      expect(
        String.fromCharCodes(links.content as List<int>),
        contains('https://example.com/stems'),
      );
    });

    test('a file that vanishes after planning is skipped, not fatal', () async {
      final a = await makeSource('a.wav', 'aaa');
      final b = await makeSource('b.wav', 'bbb');
      final plan = planAttachmentExport(
        attachments: [file(a, id: 'f1'), file(b, id: 'f2')],
      );
      await File(b).delete();

      final written = await AttachmentExportService.write(
        plan: plan,
        destinationPath: p.join(tempDir.path, 'out.zip'),
        linksHeader: 'My Song',
      );

      final archive = ZipDecoder().decodeBytes(await written.readAsBytes());
      expect(archive.files.map((f) => f.name), ['a.wav']);
    });

    test('an existing ZIP at the destination is replaced, not appended to',
        () async {
      final a = await makeSource('a.wav', 'aaa');
      final destination = p.join(tempDir.path, 'out.zip');
      await File(destination).writeAsString('stale contents');

      final plan = planAttachmentExport(
        attachments: [file(a, id: 'f1'), link('https://example.com/x')],
      );
      final written = await AttachmentExportService.write(
        plan: plan,
        destinationPath: destination,
        linksHeader: 'My Song',
      );

      final archive = ZipDecoder().decodeBytes(await written.readAsBytes());
      expect(archive.files, hasLength(2));
    });

    test('an empty plan refuses rather than writing a stub file', () async {
      final plan = planAttachmentExport(attachments: const []);

      expect(
        () => AttachmentExportService.write(
          plan: plan,
          destinationPath: p.join(tempDir.path, 'out.zip'),
          linksHeader: 'My Song',
        ),
        throwsStateError,
      );
    });
  });
}
