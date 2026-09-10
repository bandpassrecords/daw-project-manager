import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/music_project.dart';
import '../utils/folder_copy_utils.dart';
import '../utils/project_folder_utils.dart';

/// Why a move was refused before anything on disk was touched.
enum ProjectMoveError {
  /// The project's file or bundle is not on this machine.
  sourceMissing,

  /// The destination already holds an entry with that name.
  destinationOccupied,

  /// The destination folder is the source folder itself, or lives inside it —
  /// moving a directory into its own subtree.
  destinationInsideSource,

  /// The destination is where the project already lives.
  sameLocation,
}

class ProjectMoveException implements Exception {
  final ProjectMoveError reason;

  /// The path the failure is about, for the message the UI shows.
  final String path;

  const ProjectMoveException(this.reason, this.path);

  @override
  String toString() => 'ProjectMoveException($reason, $path)';
}

class ProjectMoveResult {
  /// The project with every stored path rewritten to the new location.
  final MusicProject project;

  /// Where the moved file, bundle or folder now lives.
  final String movedTo;

  const ProjectMoveResult({required this.project, required this.movedTo});
}

/// Rewrites every stored path on [project] that lives under [from] so that it
/// lives under [to] instead. Pure — no filesystem access — so the interesting
/// half of a move is testable without a disk.
///
/// Same prefix rule as `ProjectRepository.relocateRoot`, which does this for a
/// whole scan root: an exact match is replaced outright, a path under the
/// prefix keeps its tail, and anything else is left alone. Kept consistent with
/// it deliberately so per-project and per-root moves cannot drift apart.
MusicProject repathProject(
  MusicProject project, {
  required String from,
  required String to,
}) {
  final fromNorm = p.normalize(from);
  final toNorm = p.normalize(to);
  final fromPrefix =
      fromNorm.endsWith(p.separator) ? fromNorm : fromNorm + p.separator;
  final toPrefix = toNorm.endsWith(p.separator) ? toNorm : toNorm + p.separator;

  String? repath(String? src) {
    if (src == null || src.isEmpty) return src;
    // A Drive fallback reference is not a filesystem path — normalizing it
    // would mangle the "drive://" scheme into "drive:/".
    if (src.startsWith('drive://')) return src;

    final norm = p.normalize(src);
    if (norm == fromNorm) return toNorm;
    if (norm.startsWith(fromPrefix)) {
      return toPrefix + norm.substring(fromPrefix.length);
    }
    return src;
  }

  final newFilePath = repath(project.filePath)!;
  return project.copyWith(
    filePath: newFilePath,
    fileName: p.basename(newFilePath),
    previewSongPath: repath(project.previewSongPath),
    previewSongAutoPath: repath(project.previewSongAutoPath),
  );
}

/// Moves one project — its file or bundle, or the whole folder containing it —
/// into [destinationFolder], and returns the project with its stored paths
/// rewritten to match.
///
/// This is the per-project counterpart to `ProjectRepository.relocateRoot()`:
/// that one rewrites metadata for an entire scan root and expects you to have
/// moved the files yourself, this one actually moves them, for one project.
///
/// The caller persists the result (`repo.updateProject`) and invalidates
/// `allProjectsStreamProvider`; keeping that out of here leaves the service
/// free of Riverpod and Hive so it can be tested against a temp directory.
Future<ProjectMoveResult> moveProject(
  MusicProject project,
  String destinationFolder, {
  required bool moveContainingFolder,
}) async {
  // What actually moves. `containingFolderOf` (p.dirname) rather than
  // `ScannerService.projectContainingFolder`: for a bundle the latter answers
  // "what should Finder reveal?" and returns the bundle's *parent*, which
  // would silently widen "move this project" into "move everything beside it".
  final sourcePath = moveContainingFolder
      ? containingFolderOf(project.filePath)
      : project.filePath;

  final sourceIsDirectory = Directory(sourcePath).existsSync();
  if (!sourceIsDirectory && !File(sourcePath).existsSync()) {
    throw ProjectMoveException(ProjectMoveError.sourceMissing, sourcePath);
  }

  final destFolderNorm = p.normalize(destinationFolder);
  final sourceNorm = p.normalize(sourcePath);
  final destPath = p.join(destFolderNorm, p.basename(sourceNorm));

  if (p.normalize(destPath) == sourceNorm) {
    throw ProjectMoveException(ProjectMoveError.sameLocation, destinationFolder);
  }

  // Moving a directory into its own subtree would copy it into itself.
  if (sourceIsDirectory && p.isWithin(sourceNorm, destFolderNorm)) {
    throw ProjectMoveException(
      ProjectMoveError.destinationInsideSource,
      destinationFolder,
    );
  }

  if (File(destPath).existsSync() || Directory(destPath).existsSync()) {
    throw ProjectMoveException(ProjectMoveError.destinationOccupied, destPath);
  }

  await Directory(destFolderNorm).create(recursive: true);
  await moveEntity(sourcePath, destPath);

  return ProjectMoveResult(
    project: repathProject(project, from: sourcePath, to: destPath),
    movedTo: destPath,
  );
}

/// Moves the file or directory at [sourcePath] to [destPath], falling back to
/// copy-then-delete when a plain rename can't do it.
///
/// `rename()` is a single filesystem call and cannot cross devices — moving a
/// project from the internal SSD to an external archive drive, which is much of
/// the point of this feature, always lands in the fallback. The copy finishes
/// before anything is deleted, so an interrupted cross-drive move leaves the
/// original where it was rather than losing the project.
Future<void> moveEntity(String sourcePath, String destPath) async {
  final isDirectory = Directory(sourcePath).existsSync();

  try {
    if (isDirectory) {
      await Directory(sourcePath).rename(destPath);
    } else {
      await File(sourcePath).rename(destPath);
    }
    return;
  } on FileSystemException {
    // Cross-device, or a filesystem that refuses the rename. Fall through.
  }

  await copyEntityThenDelete(sourcePath, destPath, isDirectory: isDirectory);
}

/// The cross-device half of [moveEntity], separated so it can be tested
/// directly — a genuine cross-volume rename failure isn't reproducible in CI.
Future<void> copyEntityThenDelete(
  String sourcePath,
  String destPath, {
  required bool isDirectory,
}) async {
  if (isDirectory) {
    await copyDirectoryRecursive(Directory(sourcePath), Directory(destPath));
    await Directory(sourcePath).delete(recursive: true);
  } else {
    await File(sourcePath).copy(destPath);
    await File(sourcePath).delete();
  }
}
