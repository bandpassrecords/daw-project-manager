import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../models/project_attachment.dart';
import '../utils/file_launcher.dart';

/// What exporting a project's attachments should produce (#112).
enum AttachmentExportKind {
  /// Nothing worth writing — no links, and no file that still resolves.
  nothing,

  /// Exactly one file and no links: hand back a copy of that file rather than
  /// a one-entry ZIP the user has to unpack.
  singleFile,

  /// Links only: one plain text file. A shared Drive folder is a line of
  /// text, and zipping a line of text helps nobody.
  linksOnly,

  /// Several files, or files plus links: a ZIP, with the links carried inside
  /// it as the same text file [linksOnly] would have produced.
  zip,
}

/// The decision [AttachmentExportService] acts on, worked out before anything
/// is read or written.
///
/// Pure data so the "one file vs. one text file vs. a ZIP" rule can be tested
/// without a file system — the same split as `resolveDawLaunchAction`.
class AttachmentExportPlan {
  const AttachmentExportPlan({
    required this.kind,
    required this.files,
    required this.links,
    required this.missingFiles,
  });

  final AttachmentExportKind kind;

  /// File attachments whose target still resolves, in list order.
  final List<ProjectAttachment> files;

  /// Link attachments, in list order.
  final List<ProjectAttachment> links;

  /// File attachments whose target has moved or been deleted. Never written;
  /// reported to the user instead, so an export is never quietly short.
  final List<ProjectAttachment> missingFiles;

  bool get isEmpty => kind == AttachmentExportKind.nothing;

  /// Default name to offer in the save dialog, derived from the song's
  /// display name.
  String suggestedFileName(String projectName) {
    final safe = sanitizeFileName(projectName);
    switch (kind) {
      case AttachmentExportKind.nothing:
        return '';
      case AttachmentExportKind.singleFile:
        return p.basename(files.single.target);
      case AttachmentExportKind.linksOnly:
        return '${safe}_links.txt';
      case AttachmentExportKind.zip:
        return '${safe}_attachments.zip';
    }
  }

  static String sanitizeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return cleaned.isEmpty ? 'attachments' : cleaned;
  }
}

/// Name of the text file the links are written to, inside a ZIP or on its own.
const attachmentLinksFileName = 'links.txt';

/// Works out what an export of [attachments] would produce.
///
/// [fileExists] is injected so the rule is testable without touching disk; the
/// UI passes `FileLauncher.targetExists`.
AttachmentExportPlan planAttachmentExport({
  required List<ProjectAttachment> attachments,
  bool Function(String path)? fileExists,
}) {
  final exists = fileExists ?? FileLauncher.targetExists;

  final files = <ProjectAttachment>[];
  final links = <ProjectAttachment>[];
  final missing = <ProjectAttachment>[];

  for (final attachment in attachments) {
    final target = attachment.target.trim();
    if (target.isEmpty) continue;
    if (attachment.isLink) {
      links.add(attachment);
    } else if (exists(target)) {
      files.add(attachment);
    } else {
      missing.add(attachment);
    }
  }

  // The links all travel together in one text file, so they count as a single
  // entry however many there are: three links and no files is still one file
  // to save, not a ZIP.
  final entries = files.length + (links.isEmpty ? 0 : 1);
  final kind = switch (entries) {
    0 => AttachmentExportKind.nothing,
    1 => links.isEmpty
        ? AttachmentExportKind.singleFile
        : AttachmentExportKind.linksOnly,
    _ => AttachmentExportKind.zip,
  };

  return AttachmentExportPlan(
    kind: kind,
    files: files,
    links: links,
    missingFiles: missing,
  );
}

/// Renders [links] as the plain text file that ships with an export.
///
/// Deliberately free of prose: [header] (the song's name) and the user's own
/// labels, URLs and notes are all that goes in, so nothing here needs
/// translating and the file reads the same in every locale.
String buildAttachmentLinksFile({
  required String header,
  required List<ProjectAttachment> links,
}) {
  final buffer = StringBuffer()
    ..writeln(header)
    ..writeln();
  for (final link in links) {
    buffer.writeln(link.displayLabel);
    buffer.writeln(link.target);
    final note = link.note?.trim();
    if (note != null && note.isNotEmpty) buffer.writeln(note);
    buffer.writeln();
  }
  return buffer.toString();
}

/// Entry names for the files inside a ZIP, de-duplicated.
///
/// Two attachments can perfectly well be `ref.wav` from different folders; a
/// ZIP with the same name twice loses one of them on extraction, so the later
/// ones get a ` (2)` suffix before the extension. [reserved] holds names the
/// archive already spends (the links file).
List<String> zipEntryNames(
  List<ProjectAttachment> files, {
  Set<String> reserved = const {},
}) {
  final taken = {...reserved.map((n) => n.toLowerCase())};
  final names = <String>[];
  for (final file in files) {
    final base = p.basename(file.target.trim());
    final stem = p.basenameWithoutExtension(base);
    final ext = p.extension(base);
    var candidate = base;
    var counter = 2;
    while (taken.contains(candidate.toLowerCase())) {
      candidate = '$stem ($counter)$ext';
      counter++;
    }
    taken.add(candidate.toLowerCase());
    names.add(candidate);
  }
  return names;
}

/// Writes the export described by a [AttachmentExportPlan] to [destinationPath].
///
/// Never touches the originals: a file attachment is copied, a link is text.
class AttachmentExportService {
  const AttachmentExportService._();

  /// Writes [plan] to [destinationPath], which the caller has already chosen
  /// (and which should match [AttachmentExportPlan.suggestedFileName]'s
  /// extension). [linksHeader] titles the text file — pass the song's name.
  ///
  /// Returns the file that was written.
  static Future<File> write({
    required AttachmentExportPlan plan,
    required String destinationPath,
    required String linksHeader,
  }) async {
    final destination = File(destinationPath);
    if (!await destination.parent.exists()) {
      await destination.parent.create(recursive: true);
    }

    switch (plan.kind) {
      case AttachmentExportKind.nothing:
        throw StateError('Nothing to export');

      case AttachmentExportKind.singleFile:
        // copy() replaces an existing destination, which is what the save
        // dialog's own "overwrite?" prompt already promised the user.
        return File(plan.files.single.target.trim()).copy(destinationPath);

      case AttachmentExportKind.linksOnly:
        return destination.writeAsString(
          buildAttachmentLinksFile(header: linksHeader, links: plan.links),
        );

      case AttachmentExportKind.zip:
        final archive = Archive();
        if (plan.links.isNotEmpty) {
          final bytes = const Utf8Encoder().convert(
            buildAttachmentLinksFile(header: linksHeader, links: plan.links),
          );
          archive.addFile(
            ArchiveFile(attachmentLinksFileName, bytes.length, bytes),
          );
        }
        final names = zipEntryNames(
          plan.files,
          reserved: plan.links.isEmpty ? const {} : {attachmentLinksFileName},
        );
        for (var i = 0; i < plan.files.length; i++) {
          final source = File(plan.files[i].target.trim());
          // A file can vanish between planning and writing; skipping beats
          // aborting an export the user is already waiting on.
          if (!await source.exists()) continue;
          final data = await source.readAsBytes();
          archive.addFile(ArchiveFile(names[i], data.length, data));
        }
        if (await destination.exists()) await destination.delete();
        return destination.writeAsBytes(ZipEncoder().encode(archive));
    }
  }
}
