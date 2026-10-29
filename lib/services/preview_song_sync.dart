// What a Drive backup says about a project's preview song when this device
// has no file to read for it — the rules only, no Drive.
//
// A backup lists each preview song in three maps keyed by project id:
// `previewSongFiles` (the file on Drive), `previewSongHashes` and
// `previewSongFileNames`. A project missing from them is one no device can
// download any more. Each upload used to rebuild the maps from the files on
// the uploading device alone, so a desktop whose copy had gone — and a phone,
// which never reads its files for this — wrote a backup without that preview,
// and every device after it lost the song while its file sat on Drive,
// pointed at by nothing.

import 'package:path/path.dart' as p;

import '../models/music_project.dart';

/// One project's preview song as a backup lists it.
class PreviewSongEntry {
  const PreviewSongEntry({required this.fileId, this.hash, this.fileName});

  /// The file on Drive.
  final String fileId;

  /// Its content hash, when known: an unchanged file is never uploaded or
  /// downloaded again.
  final String? hash;

  /// The name the song had where it was picked, which also gives a download
  /// its extension.
  final String? fileName;
}

/// Every preview song a backup lists, by project id.
Map<String, PreviewSongEntry> previewSongEntriesFrom(Map<String, dynamic> backup) {
  final files = backup['previewSongFiles'];
  if (files is! Map) return const {};
  final hashes = backup['previewSongHashes'];
  final names = backup['previewSongFileNames'];
  final entries = <String, PreviewSongEntry>{};
  for (final e in files.entries) {
    if (e.key is! String || e.value is! String) continue;
    final hash = hashes is Map ? hashes[e.key] : null;
    final name = names is Map ? names[e.key] : null;
    entries[e.key as String] = PreviewSongEntry(
      fileId: e.value as String,
      hash: hash is String ? hash : null,
      fileName: name is String ? name : null,
    );
  }
  return entries;
}

/// A file in Drive's preview songs folder.
class PreviewSongOnDrive {
  const PreviewSongOnDrive({required this.fileId, required this.name, this.modifiedTime});

  final String fileId;
  final String name;
  final DateTime? modifiedTime;
}

/// The project a preview song on Drive belongs to: the upload names each one
/// `<projectId>_preview<ext>`. Null for anything else in the folder.
String? previewSongProjectId(String driveName) {
  final at = driveName.lastIndexOf('_preview');
  if (at <= 0) return null;
  final rest = driveName.substring(at + '_preview'.length);
  if (rest.isNotEmpty && (!rest.startsWith('.') || rest.substring(1).contains('.'))) {
    return null;
  }
  return driveName.substring(0, at);
}

/// The newest preview song on Drive per project. Changing a song's format
/// uploads it under a new extension and leaves the old file there, so a
/// project can have more than one; the last one written is its song.
Map<String, PreviewSongOnDrive> previewSongsByProject(Iterable<PreviewSongOnDrive> files) {
  final byProject = <String, PreviewSongOnDrive>{};
  for (final f in files) {
    final id = previewSongProjectId(f.name);
    if (id == null) continue;
    final held = byProject[id];
    final newer = held == null ||
        (f.modifiedTime != null &&
            (held.modifiedTime == null || f.modifiedTime!.isAfter(held.modifiedTime!)));
    if (newer) byProject[id] = f;
  }
  return byProject;
}

/// Whether [project] still has a preview song a backup should keep listing.
/// An auto-detected one counts only when auto-detected songs are uploaded:
/// otherwise the backup never listed it, and a manual song the user removed
/// must not come back on other devices through it.
bool previewSongWanted(MusicProject project, {required bool includeAutoDetected}) {
  if (project.previewSongPath?.isNotEmpty == true) return true;
  return includeAutoDetected && project.previewSongAutoPath?.isNotEmpty == true;
}

const _driveReferencePrefix = 'drive://';

/// The Drive file a `drive://<fileId>` preview path names, or null.
String? driveReferenceFileId(String? previewPath) {
  if (previewPath == null || !previewPath.startsWith(_driveReferencePrefix)) return null;
  final id = previewPath.substring(_driveReferencePrefix.length);
  return id.isEmpty ? null : id;
}

/// What the new backup lists for [project] when this device did not find,
/// or upload, a file for it — its file is missing here, it is a `drive://`
/// reference, or this is a phone. Null: nothing, and the backup lets go.
///
/// In order: the entry the previous backup had, the file a `drive://`
/// reference names, then a file on Drive named after the project — one an
/// earlier upload left listed by nothing. [onDrive] is Drive's preview songs
/// folder by project ([previewSongsByProject]); when it was read, an entry
/// whose file isn't in it is not kept, and when it wasn't (null), entries are
/// kept as they are.
PreviewSongEntry? carriedPreviewSongEntry({
  required MusicProject project,
  required bool includeAutoDetected,
  PreviewSongEntry? previous,
  Map<String, PreviewSongOnDrive>? onDrive,
}) {
  if (!previewSongWanted(project, includeAutoDetected: includeAutoDetected)) return null;
  final idsOnDrive = onDrive?.values.map((f) => f.fileId).toSet();
  bool stillThere(String fileId) => idsOnDrive == null || idsOnDrive.contains(fileId);

  if (previous != null && stillThere(previous.fileId)) return previous;

  final referenced = driveReferenceFileId(project.previewSongPath);
  if (referenced != null && stillThere(referenced)) {
    return PreviewSongEntry(
      fileId: referenced,
      hash: project.uploadedPreviewSongHash,
      fileName: project.previewSongFileName,
    );
  }

  final orphan = onDrive?[project.id];
  if (orphan == null) return null;
  return PreviewSongEntry(
    fileId: orphan.fileId,
    // Which take it is isn't known: a download checks nothing rather than
    // refusing a file for a hash it never had.
    fileName: project.previewSongFileName ?? _realName(project) ?? orphan.name,
  );
}

final _uuidPreviewName = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_preview\.',
  caseSensitive: false,
);

/// Whether [fileName] is one of this app's own `<id>_preview.<ext>` copies,
/// which says nothing about what the song was called.
bool isAppPreviewCopyName(String fileName) => _uuidPreviewName.hasMatch(fileName);

/// The song's own file name from its stored path, unless that is one of this
/// app's `<id>_preview.<ext>` copies.
String? _realName(MusicProject project) {
  for (final path in [project.previewSongPath, project.previewSongAutoPath]) {
    if (path == null || path.isEmpty || driveReferenceFileId(path) != null) continue;
    // Windows rules split on both separators: a path synced from a Windows
    // desktop is read on a phone or a Mac too.
    final name = p.windows.basename(path);
    if (!isAppPreviewCopyName(name)) return name;
  }
  return null;
}

/// Every preview song Drive has, by project: the backup's entries whose file
/// is still there, then — for projects it no longer lists — the newest file
/// named after the project.
Map<String, PreviewSongEntry> previewSongsAvailable({
  required Map<String, PreviewSongEntry> listed,
  required Map<String, PreviewSongOnDrive> onDrive,
}) {
  final ids = onDrive.values.map((f) => f.fileId).toSet();
  return {
    for (final e in listed.entries)
      if (ids.contains(e.value.fileId)) e.key: e.value,
    for (final e in onDrive.entries)
      if (!listed.containsKey(e.key) || !ids.contains(listed[e.key]!.fileId))
        e.key: PreviewSongEntry(fileId: e.value.fileId, fileName: e.value.name),
  };
}
