import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../models/music_project.dart';
import '../models/scan_root.dart';
import 'scanner_service.dart';
import '../utils/project_folder_utils.dart';

/// What an archive covers on disk.
enum ArchiveScope {
  /// Just the project's own file, or its `.logicx`/`.luna`/`.band` bundle.
  projectFileOnly,

  /// The whole folder the project sits in — samples, bounces, freeze files.
  containingFolder,
}

/// Why an archive was refused before anything was written.
enum ArchiveError {
  /// The project's file or bundle is not on this machine.
  sourceMissing,

  /// The destination is a scan root, inside one, or an ancestor of one — the
  /// next scan would index the archive straight back into the library.
  destinationInScanRoot,

  /// An archive of that name is already there.
  destinationOccupied,

  /// The finished zip did not contain everything it should.
  verificationFailed,

  /// The project has no archive to restore from.
  notArchived,
}

class ProjectArchiveException implements Exception {
  final ArchiveError reason;

  /// The path or scan-root name the failure is about, for the UI's message.
  final String detail;

  const ProjectArchiveException(this.reason, this.detail);

  @override
  String toString() => 'ProjectArchiveException($reason, $detail)';
}

/// Where an archive run has got to, for the progress dialog.
enum ArchiveStage { scanning, compressing, verifying, deleting, done }

class ArchiveProgress {
  final ArchiveStage stage;

  /// The file currently being added, for the "…/Samples/kick.wav" line.
  final String currentItem;

  /// 0..1, or null while the stage has no measurable total (walking the tree).
  final double? progress;

  /// Files that could not be read and were left out. Collected rather than
  /// thrown: one unreadable file should not cost the user the other 213.
  final List<String> warnings;

  const ArchiveProgress({
    required this.stage,
    this.currentItem = '',
    this.progress,
    this.warnings = const [],
  });
}

/// Cancels an in-flight archive. Mirrors `UpdateCancelToken` in
/// `appimage_update_service.dart`.
class ArchiveCancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class ArchiveCancelledException implements Exception {
  const ArchiveCancelledException();
  @override
  String toString() => 'Archive cancelled';
}

class ArchiveResult {
  /// The project, flagged archived and pointing at the zip.
  final MusicProject project;

  /// Absolute path of the written archive.
  final String archivePath;

  /// Files skipped because they could not be read.
  final List<String> warnings;

  /// Whether the originals were removed.
  final bool originalsDeleted;

  const ArchiveResult({
    required this.project,
    required this.archivePath,
    required this.warnings,
    required this.originalsDeleted,
  });
}

// ---------------------------------------------------------------------------
// Pure decisions — the parts #116 flagged as undefined.
// ---------------------------------------------------------------------------

/// The scope to offer by default for the project at [projectPath].
///
/// [allProjectPaths] is every indexed project's `filePath`; the project's own
/// entry is ignored.
///
/// - A **bundle** (`.logicx` / `.luna` / `.band`) is itself the project, so it
///   archives alone. Taking its parent would sweep up every sibling project.
/// - A **single file in a folder of its own** archives with the folder: its
///   samples and bounces live there, and a `.cpr` without its Audio Files
///   folder is not a usable archive.
/// - A **single file sharing its folder** with another indexed project
///   archives alone. A flat scan root is often twenty `.flp`s in one
///   directory, and one archive must not swallow the other nineteen.
ArchiveScope defaultScopeFor(
  String projectPath, {
  required Iterable<String> allProjectPaths,
}) {
  if (ScannerService.isBundlePath(projectPath)) {
    return ArchiveScope.projectFileOnly;
  }
  return folderIsDedicatedTo(projectPath, allProjectPaths)
      ? ArchiveScope.containingFolder
      : ArchiveScope.projectFileOnly;
}

/// What [scope] actually covers on disk for the project at [projectPath].
String archiveSourceFor(String projectPath, ArchiveScope scope) =>
    scope == ArchiveScope.containingFolder
        ? containingFolderOf(projectPath)
        : projectPath;

/// The scan root that makes [destFolder] an unusable archive destination, or
/// null when it is fine.
///
/// Archiving into a scanned folder would have the next scan re-index every
/// zip'd project straight back into the library — and, once the originals are
/// deleted, leave a row pointing at a file inside its own archive. An ancestor
/// of a root counts too, since a root is scanned wherever it sits.
ScanRoot? conflictingScanRoot(String destFolder, Iterable<ScanRoot> roots) {
  final dest = p.normalize(destFolder);
  for (final root in roots) {
    final rootPath = p.normalize(root.path);
    if (dest == rootPath ||
        p.isWithin(rootPath, dest) ||
        p.isWithin(dest, rootPath)) {
      return root;
    }
  }
  return null;
}

/// The archive file name for [project] — its display name, made safe for a
/// filesystem.
String archiveFileNameFor(MusicProject project) {
  final safe = project.displayName
      .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
      .trim();
  return '${safe.isEmpty ? 'project' : safe}.zip';
}

// ---------------------------------------------------------------------------
// Archiving.
// ---------------------------------------------------------------------------

/// Zips [project] into [destFolder], verifies the result, and returns the
/// project flagged archived.
///
/// Originals are deleted only when [deleteOriginals] is set *and* verification
/// passed — the delete is the one irreversible step, so it never runs on an
/// archive we haven't proved readable.
///
/// The caller persists the result and invalidates `allProjectsStreamProvider`;
/// keeping Hive and Riverpod out of here lets this run against a temp dir in a
/// test.
Future<ArchiveResult> archiveProject(
  MusicProject project,
  String destFolder, {
  required ArchiveScope scope,
  required bool deleteOriginals,
  Iterable<ScanRoot> scanRoots = const [],
  ArchiveCancelToken? cancelToken,
  void Function(ArchiveProgress)? onProgress,
}) async {
  final conflict = conflictingScanRoot(destFolder, scanRoots);
  if (conflict != null) {
    throw ProjectArchiveException(
      ArchiveError.destinationInScanRoot,
      conflict.effectiveDisplayName,
    );
  }

  final sourcePath = archiveSourceFor(project.filePath, scope);
  final sourceIsDirectory = Directory(sourcePath).existsSync();
  if (!sourceIsDirectory && !File(sourcePath).existsSync()) {
    throw ProjectArchiveException(ArchiveError.sourceMissing, sourcePath);
  }

  await Directory(destFolder).create(recursive: true);
  final archivePath = p.join(destFolder, archiveFileNameFor(project));
  if (File(archivePath).existsSync()) {
    throw ProjectArchiveException(ArchiveError.destinationOccupied, archivePath);
  }

  // Written under a temp name and renamed on success, so a cancelled or
  // crashed run never leaves something that looks like a finished archive.
  final partPath = '$archivePath.part';
  await File(partPath).parent.create(recursive: true);

  onProgress?.call(const ArchiveProgress(stage: ArchiveStage.scanning));

  final warnings = <String>[];
  // Zip-relative paths of everything we believe we wrote, for verification.
  final expectedEntries = <String>[];
  final encoder = ZipFileEncoder();

  try {
    encoder.create(partPath);

    if (sourceIsDirectory) {
      final rootName = p.basename(sourcePath);
      await encoder.addDirectory(
        Directory(sourcePath),
        // ZipFileProgress does double duty: progress reporting and, via
        // ZipFileOperation.cancel, the cancel hook — checked per entry rather
        // than only between whole items.
        filter: (entity, progress) {
          if (cancelToken?.isCancelled ?? false) {
            return ZipFileOperation.cancel;
          }
          if (entity is File) {
            final rel = p.relative(entity.path, from: sourcePath);
            // A file we cannot read would abort the whole run inside the
            // encoder; skipping it costs one file instead of the archive.
            if (!_isReadable(entity)) {
              warnings.add(rel);
              return ZipFileOperation.skip;
            }
            expectedEntries.add(p.url.join(rootName, p.split(rel).join('/')));
            onProgress?.call(
              ArchiveProgress(
                stage: ArchiveStage.compressing,
                currentItem: rel,
                progress: progress,
              ),
            );
          }
          return ZipFileOperation.include;
        },
      );
    } else {
      final name = p.basename(sourcePath);
      onProgress?.call(
        ArchiveProgress(
          stage: ArchiveStage.compressing,
          currentItem: name,
          progress: 0,
        ),
      );
      if (cancelToken?.isCancelled ?? false) {
        throw const ArchiveCancelledException();
      }
      await encoder.addFile(File(sourcePath), name);
      expectedEntries.add(name);
    }

    await encoder.close();

    if (cancelToken?.isCancelled ?? false) {
      throw const ArchiveCancelledException();
    }
  } catch (_) {
    // close() is safe to call twice; the part file must not survive either way.
    try {
      await encoder.close();
    } catch (_) {
      // Already closed, or never opened.
    }
    await _deleteIfExists(partPath);
    rethrow;
  }

  await File(partPath).rename(archivePath);

  onProgress?.call(
    ArchiveProgress(stage: ArchiveStage.verifying, warnings: warnings),
  );

  final missing = await verifyArchive(archivePath, expectedEntries);
  if (missing.isNotEmpty) {
    // The zip stays on disk so the user can inspect it, but the originals are
    // untouched and the project is not flagged archived.
    throw ProjectArchiveException(
      ArchiveError.verificationFailed,
      missing.take(5).join(', '),
    );
  }

  var deleted = false;
  if (deleteOriginals) {
    onProgress?.call(
      ArchiveProgress(stage: ArchiveStage.deleting, warnings: warnings),
    );
    if (sourceIsDirectory) {
      await Directory(sourcePath).delete(recursive: true);
    } else {
      await File(sourcePath).delete();
    }
    deleted = true;
  }

  onProgress?.call(
    ArchiveProgress(
      stage: ArchiveStage.done,
      progress: 1,
      warnings: warnings,
    ),
  );

  // Where the project's own file sits inside the zip, so restore can find it
  // exactly instead of guessing by basename.
  final entryPath = sourceIsDirectory
      ? p.url.join(
          p.basename(sourcePath),
          p.split(p.relative(project.filePath, from: sourcePath)).join('/'),
        )
      : p.basename(sourcePath);

  return ArchiveResult(
    project: project.copyWith(
      archivePath: archivePath,
      archivedAt: DateTime.now(),
      archiveEntryPath: entryPath,
    ),
    archivePath: archivePath,
    warnings: warnings,
    originalsDeleted: deleted,
  );
}

/// The entries of [expectedEntries] that the finished zip at [archivePath]
/// does not actually contain.
///
/// Re-opens and reads the archive rather than trusting the encoder's return —
/// this is what stands between "the zip was written" and deleting 4 GB of
/// originals.
Future<List<String>> verifyArchive(
  String archivePath,
  List<String> expectedEntries,
) async {
  final InputFileStream input = InputFileStream(archivePath);
  try {
    final archive = ZipDecoder().decodeStream(input);
    final present = <String>{
      for (final f in archive.files)
        if (f.isFile) f.name,
    };
    return expectedEntries.where((e) => !present.contains(e)).toList();
  } catch (_) {
    // An unreadable archive verifies as "nothing arrived".
    return List<String>.from(expectedEntries);
  } finally {
    await input.close();
  }
}

/// The folder an archive must be extracted into to put its files back exactly
/// where they came from, or null when the project isn't archived.
///
/// Derived rather than stored: [MusicProject.archiveEntryPath] is the project
/// file's path *inside* the zip, and [MusicProject.filePath] still names where
/// it came from, so the extraction root is simply `filePath` with as many
/// trailing segments removed as `archiveEntryPath` has. That works out to the
/// containing folder's parent for a folder-scoped archive and the containing
/// folder itself for a file-scoped one, with no extra field to keep in sync.
String? originalRestoreFolderFor(MusicProject project) {
  final entryPath = project.archiveEntryPath;
  if (entryPath == null) return null;

  final depth = p.url.split(entryPath).where((s) => s.isNotEmpty).length;
  if (depth == 0) return null;

  var folder = p.normalize(project.filePath);
  for (var i = 0; i < depth; i++) {
    final parent = p.dirname(folder);
    // dirname bottoms out at the filesystem root; stop rather than claim it.
    if (parent == folder) return null;
    folder = parent;
  }
  return folder;
}

/// Reverses an archive: puts the files back if they were deleted, removes the
/// zip, and clears the archived state.
///
/// The two cases the UI's Undo covers are the same code path here. Archiving
/// without deleting the originals leaves them in place, so undo is just "throw
/// the zip away"; archiving *with* the delete needs the extraction first. The
/// zip is only removed once the project file is confirmed back on disk, so a
/// failed undo leaves the archive intact and the project still archived.
Future<MusicProject> undoArchive(
  MusicProject project, {
  bool deleteArchiveFile = true,
}) async {
  final archivePath = project.archivePath;
  if (archivePath == null) {
    throw ProjectArchiveException(ArchiveError.notArchived, project.displayName);
  }

  if (!_entityExists(project.filePath)) {
    final folder = originalRestoreFolderFor(project);
    if (folder == null) {
      throw ProjectArchiveException(ArchiveError.notArchived, project.displayName);
    }
    if (!File(archivePath).existsSync()) {
      throw ProjectArchiveException(ArchiveError.sourceMissing, archivePath);
    }

    await extractFileToDisk(archivePath, folder);

    if (!_entityExists(project.filePath)) {
      throw ProjectArchiveException(
        ArchiveError.verificationFailed,
        project.filePath,
      );
    }
  }

  if (deleteArchiveFile) {
    await _deleteIfExists(archivePath);
  }

  return project.copyWith(
    clearArchivePath: true,
    clearArchivedAt: true,
    clearArchiveEntryPath: true,
  );
}

/// Extracts [project]'s archive into [destFolder] and returns the project
/// pointing back at real files.
Future<MusicProject> restoreProject(
  MusicProject project,
  String destFolder,
) async {
  final archivePath = project.archivePath;
  final entryPath = project.archiveEntryPath;
  if (archivePath == null || entryPath == null) {
    throw ProjectArchiveException(ArchiveError.notArchived, project.displayName);
  }
  if (!File(archivePath).existsSync()) {
    throw ProjectArchiveException(ArchiveError.sourceMissing, archivePath);
  }

  final restoredPath = p.join(destFolder, p.joinAll(p.url.split(entryPath)));
  if (File(restoredPath).existsSync() || Directory(restoredPath).existsSync()) {
    throw ProjectArchiveException(
      ArchiveError.destinationOccupied,
      restoredPath,
    );
  }

  await extractFileToDisk(archivePath, destFolder);

  return project.copyWith(
    filePath: restoredPath,
    fileName: p.basename(restoredPath),
    clearArchivePath: true,
    clearArchivedAt: true,
    clearArchiveEntryPath: true,
  );
}

/// Total size on disk of what [scope] would archive, for the dialog's
/// "3.9 GB / 214 files" line.
Future<({int bytes, int files})> archiveSizeOf(
  String projectPath,
  ArchiveScope scope,
) async {
  final source = archiveSourceFor(projectPath, scope);
  if (Directory(source).existsSync()) {
    var bytes = 0;
    var files = 0;
    await for (final entity in Directory(source).list(recursive: true)) {
      if (entity is File) {
        try {
          bytes += await entity.length();
          files++;
        } catch (_) {
          // Unreadable now is unreadable at archive time too; it'll show up
          // as a warning there rather than being counted here.
        }
      }
    }
    return (bytes: bytes, files: files);
  }
  final file = File(source);
  if (!file.existsSync()) return (bytes: 0, files: 0);
  return (bytes: await file.length(), files: 1);
}

bool _entityExists(String path) =>
    File(path).existsSync() || Directory(path).existsSync();

bool _isReadable(File file) {
  RandomAccessFile? handle;
  try {
    handle = file.openSync();
    return true;
  } catch (_) {
    return false;
  } finally {
    try {
      handle?.closeSync();
    } catch (_) {
      // Nothing to close.
    }
  }
}

Future<void> _deleteIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (_) {
      // Best effort — a leftover .part is inert, it just wastes space.
    }
  }
}
