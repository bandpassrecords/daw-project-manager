// Settings > Mixdown folders > Missing preview songs: which projects' preview
// songs this computer can't find, and why — the rules only, no Drive and no
// widgets.
//
// "Not found here" is not "gone": the path may be another computer's (paths
// sync), on a drive that isn't connected, or a copy Drive still has. So the
// review sorts them, and nothing is cleared without the user asking.

import 'package:path/path.dart' as p;

import '../models/music_project.dart';
import '../services/preview_song_sync.dart' show driveReferenceFileId;

/// Why a preview song is missing, in the order the review lists them.
enum MissingPreviewKind {
  /// Drive has the song: it can be downloaded.
  onDrive,

  /// A path in another operating system's form — another computer's song,
  /// which may play fine there.
  otherComputer,

  /// Its folder isn't there either: a drive that isn't connected, or a
  /// folder moved or deleted.
  folderMissing,

  /// The folder is there and the file is not.
  fileMissing,
}

/// One project whose preview song can't be found on this computer.
class MissingPreviewSong {
  const MissingPreviewSong({
    required this.project,
    required this.path,
    required this.manual,
    required this.kind,
  });

  final MusicProject project;

  /// The path that doesn't resolve (or a `drive://` reference).
  final String path;

  /// Whether it is the song the user picked (`previewSongPath`) rather than
  /// an auto-detected mixdown (`previewSongAutoPath`).
  final bool manual;

  final MissingPreviewKind kind;

  /// The file's name, read in either operating system's form.
  String get fileName =>
      driveReferenceFileId(path) != null ? (project.previewSongFileName ?? path) : p.windows.basename(path);
}

/// The song [project] plays as its preview: the picked one, else the
/// auto-detected one. Null when it has neither.
({String path, bool manual})? previewSongOf(MusicProject project) {
  final picked = project.previewSongPath;
  if (picked != null && picked.isNotEmpty) return (path: picked, manual: true);
  final auto = project.previewSongAutoPath;
  if (auto != null && auto.isNotEmpty) return (path: auto, manual: false);
  return null;
}

/// Whether [path] is written the other operating system's way: a drive
/// letter or network share on a Mac or Linux, a `/…` path on Windows.
bool isOtherComputersPath(String path, {required bool windows}) {
  if (windows) return path.startsWith('/') && !path.startsWith('//');
  return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path) || path.startsWith(r'\\');
}

/// Every project of [projects] whose preview song isn't on this computer,
/// sorted into [MissingPreviewKind]s, then by name.
///
/// Only asks the filesystem whether a file or folder exists — a type check,
/// which never reads a file, so a cloud drive's placeholder isn't downloaded.
/// [onDrive] is the projects Drive has a song for (empty when not signed in).
Future<List<MissingPreviewSong>> findMissingPreviewSongs(
  Iterable<MusicProject> projects, {
  required Set<String> onDrive,
  required bool windows,
  required Future<bool> Function(String path) fileExists,
  required Future<bool> Function(String path) folderExists,
}) async {
  final missing = <MissingPreviewSong>[];
  // This computer's path rules, as [windows] says (and tests on any OS can).
  final paths = windows ? p.windows : p.posix;
  for (final project in projects) {
    final song = previewSongOf(project);
    if (song == null) continue;
    MissingPreviewKind kind;
    if (driveReferenceFileId(song.path) != null) {
      kind = MissingPreviewKind.onDrive;
    } else if (await fileExists(song.path)) {
      continue;
    } else if (onDrive.contains(project.id)) {
      kind = MissingPreviewKind.onDrive;
    } else if (isOtherComputersPath(song.path, windows: windows)) {
      kind = MissingPreviewKind.otherComputer;
    } else if (!await folderExists(paths.dirname(song.path))) {
      kind = MissingPreviewKind.folderMissing;
    } else {
      kind = MissingPreviewKind.fileMissing;
    }
    missing.add(MissingPreviewSong(project: project, path: song.path, manual: song.manual, kind: kind));
  }
  missing.sort((a, b) {
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    return a.project.displayName.toLowerCase().compareTo(b.project.displayName.toLowerCase());
  });
  return missing;
}

/// Of [songs], how many are not lost even though this computer can't find
/// them — Drive can still download them, or they belong to another computer
/// where they may play — for the confirmation before removing them.
({int onDrive, int otherComputer}) stillPlayableElsewhere(Iterable<MissingPreviewSong> songs) => (
      onDrive: songs.where((s) => s.kind == MissingPreviewKind.onDrive).length,
      otherComputer: songs.where((s) => s.kind == MissingPreviewKind.otherComputer).length,
    );

/// [project] with the missing song of [song] taken off: the slot it was in
/// is cleared, nothing else. The other slot, if it has a song, plays next.
MusicProject withoutMissingPreview(MusicProject project, MissingPreviewSong song) => song.manual
    ? project.copyWith(clearPreviewSongPath: true, clearPreviewSongFileName: true)
    : project.copyWith(clearPreviewSongAutoPath: true);

/// [project] playing [found], a mixdown found in its folders, in place of
/// its missing song — in the auto-detected slot, the one detection uses, so
/// a later pick still wins over it.
MusicProject withFoundPreview(MusicProject project, String found) => project.copyWith(
      clearPreviewSongPath: true,
      clearPreviewSongFileName: true,
      clearIgnoredNewerSongPath: true,
      previewSongAutoPath: found,
    );

/// [project] playing [downloaded], the copy of its song just fetched from
/// Drive, in the picked slot as a restore puts it.
MusicProject withDownloadedPreview(
  MusicProject project,
  String downloaded, {
  String? fileName,
  String? hash,
}) =>
    project.copyWith(
      previewSongPath: downloaded,
      previewSongFileName: fileName ?? project.previewSongFileName,
      uploadedPreviewSongHash: hash ?? project.uploadedPreviewSongHash,
    );
