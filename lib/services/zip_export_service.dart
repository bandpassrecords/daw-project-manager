import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

/// One file in a zip the user exports (a release's files, a profile's
/// assets): its name inside the zip, and where its bytes come from — a file
/// on disk, or text made on the spot (a biography).
class ZipExportEntry {
  final String name;
  final String? sourcePath;
  final List<int>? bytes;

  const ZipExportEntry.file(this.name, String path)
      : sourcePath = path,
        bytes = null;

  const ZipExportEntry.bytes(this.name, List<int> this.bytes) : sourcePath = null;
}

/// The marker the profile page's file lists use for the biography, which is
/// text on the profile rather than a file.
const kBiographyMarker = 'biography.txt';

/// A profile's files for a zip, as the profile page lists them — name in the
/// zip to path — with the biography marker turned into the biography's text.
/// Each listed file goes in once.
List<ZipExportEntry> profileZipEntries(
  Iterable<MapEntry<String, String>> files, {
  required String? bio,
}) =>
    [
      for (final MapEntry(key: name, value: path) in files)
        if (path == kBiographyMarker)
          ZipExportEntry.bytes(kBiographyMarker, utf8.encode(bio ?? ''))
        else
          ZipExportEntry.file(name, path),
    ];

/// Formats that are compressed already: stored as they are, since deflating
/// them again costs time and saves nothing.
const _storedExtensions = {
  '.mp3', '.m4a', '.aac', '.ogg', '.opus', '.flac',
  '.jpg', '.jpeg', '.png', '.webp', '.gif',
  '.zip', '.mp4', '.mov', '.pdf',
};

/// [names] made unique, in order: a repeat becomes "name (2).ext". Two
/// release files may well both be called "Master.wav", and a zip with two
/// entries of one name extracts as one file.
List<String> uniqueZipNames(List<String> names) {
  final taken = <String>{};
  return [
    for (final name in names)
      () {
        var candidate = name;
        final stem = p.url.withoutExtension(name);
        final ext = p.url.extension(name);
        for (var n = 2; !taken.add(candidate.toLowerCase()); n++) {
          candidate = '$stem ($n)$ext';
        }
        return candidate;
      }(),
  ];
}

/// Writes [entries] to a zip at [zipPath] and returns how many went in.
///
/// Each file is streamed from disk as it is added: reading every file into
/// memory and encoding the whole zip at once, as the export pages did, froze
/// the app — or ran it out of memory — on a release of WAVs. The zip is
/// written to `.part` and renamed when done, so a failure never leaves
/// something that looks finished, and an earlier zip at [zipPath] stays until
/// then. A file that is no longer there is left out.
///
/// Plain values in and out, so the pages run it on an isolate of its own.
Future<int> writeZipExport(String zipPath, List<ZipExportEntry> entries) async {
  final present = [
    for (final entry in entries)
      if (entry.bytes != null || File(entry.sourcePath!).existsSync()) entry,
  ];
  final names = uniqueZipNames([for (final e in present) e.name]);

  final partPath = '$zipPath.part';
  await File(zipPath).parent.create(recursive: true);
  final encoder = ZipFileEncoder();
  try {
    encoder.create(partPath);
    for (var i = 0; i < present.length; i++) {
      final entry = present[i];
      if (entry.bytes != null) {
        encoder.addArchiveFile(ArchiveFile(names[i], entry.bytes!.length, entry.bytes!));
      } else {
        final stored = _storedExtensions.contains(p.extension(entry.sourcePath!).toLowerCase());
        await encoder.addFile(File(entry.sourcePath!), names[i], stored ? 0 : null);
      }
    }
    await encoder.close();
  } catch (_) {
    try {
      await encoder.close();
    } catch (_) {}
    final part = File(partPath);
    if (await part.exists()) await part.delete();
    rethrow;
  }

  final target = File(zipPath);
  if (await target.exists()) await target.delete();
  await File(partPath).rename(zipPath);
  return present.length;
}
