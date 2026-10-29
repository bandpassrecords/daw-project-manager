import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:path/path.dart' as p;

import '../models/project_template.dart';
import '../utils/folder_copy_utils.dart';
import 'scanner_service.dart';

/// Called once [ProjectTemplateService.instantiate] has copied the template;
/// a test throws from it to stand in for a copy that fails partway.
@visibleForTesting
void Function(String destinationFolderPath)? debugAfterTemplateCopy;

/// A single recognized DAW project file found by
/// [ProjectTemplateService.discoverTemplateCandidates], ready to be turned
/// into a [ProjectTemplate] once given an id and timestamps. A folder with
/// several project files yields one candidate per file, all sharing the same
/// [sourceFolderPath].
class TemplateFolderCandidate {
  final String name;
  final String sourceFolderPath;
  final String mainFileRelativePath;

  const TemplateFolderCandidate({
    required this.name,
    required this.sourceFolderPath,
    required this.mainFileRelativePath,
  });
}

/// Instantiates a [ProjectTemplate] into a new project folder: copies the
/// template's whole source folder to a new location and renames only the
/// main project file to match the new project's name — every other copied
/// file or subfolder keeps its original name.
class ProjectTemplateService {
  /// Scans the immediate subfolders of [parentFolderPath] (non-recursive at
  /// this level) for recognized DAW project files (searched recursively
  /// within that subfolder). Used for bulk-importing a folder that contains
  /// several template folders at once.
  ///
  /// A subfolder with exactly one project file produces one "self-contained"
  /// candidate for the whole folder. A subfolder with *multiple* project
  /// files — several independent songs sharing one sample pool/resource
  /// folder, for example — produces one candidate *per file* instead of
  /// being skipped as ambiguous; [instantiate] knows to leave sibling
  /// project files behind when copying that kind of candidate (see its doc
  /// comment). Subfolders with zero matches are omitted entirely.
  static List<TemplateFolderCandidate> discoverTemplateCandidates(
    String parentFolderPath,
  ) {
    final candidates = <TemplateFolderCandidate>[];
    List<FileSystemEntity> topLevel;
    try {
      topLevel = Directory(parentFolderPath).listSync(recursive: false);
    } catch (e) {
      // Root folder missing/inaccessible — return no candidates rather than
      // throwing, so one bad root doesn't abort scanning of the others.
      if (kDebugMode) {
        print(
          '[ProjectTemplateService] Could not list "$parentFolderPath": $e',
        );
      }
      return candidates;
    }

    if (kDebugMode) {
      print(
        '[ProjectTemplateService] Scanning "$parentFolderPath": '
        '${topLevel.length} top-level entries',
      );
    }

    for (final entity in topLevel) {
      if (entity is! Directory) {
        if (kDebugMode) {
          print(
            '[ProjectTemplateService]   skip "${p.basename(entity.path)}": not a folder',
          );
        }
        continue;
      }

      final matches = <File>[];
      try {
        for (final e in entity.listSync(recursive: true)) {
          if (e is File &&
              ScannerService.supportedExtensions.contains(
                p.extension(e.path).toLowerCase(),
              )) {
            matches.add(e);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[ProjectTemplateService]   skip "${entity.path}": could not list contents ($e)',
          );
        }
        continue;
      }

      if (matches.isEmpty) {
        if (kDebugMode) {
          print(
            '[ProjectTemplateService]   skip "${entity.path}": no recognized DAW project file found',
          );
        }
        continue;
      }

      final folderName = p.basename(entity.path);
      if (matches.length == 1) {
        if (kDebugMode) {
          print(
            '[ProjectTemplateService]   found candidate "${entity.path}" -> ${matches.single.path}',
          );
        }
        candidates.add(
          TemplateFolderCandidate(
            name: folderName,
            sourceFolderPath: entity.path,
            mainFileRelativePath: p.relative(
              matches.single.path,
              from: entity.path,
            ),
          ),
        );
        continue;
      }

      // Several project files share this folder (and its resources) —
      // register each as its own template rather than skipping the whole
      // folder. `instantiate` leaves the *other* project files behind when
      // copying one of these, so they don't bleed into an unrelated project.
      if (kDebugMode) {
        print(
          '[ProjectTemplateService]   "${entity.path}": ${matches.length} DAW project files found '
          '(${matches.map((f) => p.basename(f.path)).join(', ')}) — registering each as its own template',
        );
      }
      for (final match in matches) {
        candidates.add(
          TemplateFolderCandidate(
            name: '$folderName — ${p.basenameWithoutExtension(match.path)}',
            sourceFolderPath: entity.path,
            mainFileRelativePath: p.relative(match.path, from: entity.path),
          ),
        );
      }
    }

    if (kDebugMode) {
      print(
        '[ProjectTemplateService] "$parentFolderPath": ${candidates.length} candidate(s) found',
      );
    }

    return candidates;
  }

  /// Filters [candidates] down to the ones not already registered — compared
  /// by full main-file path (`sourceFolderPath` + `mainFileRelativePath`)
  /// against [existingMainFilePaths] — so refreshing a set of template roots
  /// only adds newly-appeared template files instead of re-adding everything
  /// found on every refresh. Keying on the full file path (rather than just
  /// the folder) matters now that one folder can yield multiple candidates —
  /// registering one project file in a shared folder must not shadow its
  /// siblings on the next refresh.
  static List<TemplateFolderCandidate> filterNewCandidates(
    List<TemplateFolderCandidate> candidates,
    Set<String> existingMainFilePaths,
  ) {
    return candidates
        .where(
          (c) => !existingMainFilePaths.contains(
            p.join(c.sourceFolderPath, c.mainFileRelativePath),
          ),
        )
        .toList();
  }

  /// Copies [template]'s source folder into [destinationFolderPath] (which
  /// must not already exist — callers should validate that first, the same
  /// way the empty-folder project creation flow does) and renames the copied
  /// main file to `<newProjectName><original extension>`, preserving
  /// whatever subfolder it originally lived in relative to the template
  /// root. Returns the new absolute path of the renamed main file.
  ///
  /// [siblingTemplates] should be every *other* registered [ProjectTemplate]
  /// that shares [template]'s `sourceFolderPath` — i.e. the rest of a
  /// "shared" folder's templates (see [discoverTemplateCandidates]). Each
  /// sibling's top-level path segment relative to that shared folder (its
  /// own file if it sits directly in the folder, or its containing
  /// subfolder if it lives nested in one) is left out of the copy, so
  /// instantiating one song out of a shared folder doesn't drag the other
  /// registered songs along with it. Everything else — resource subfolders
  /// (samples, renders, ...) and any project file that *isn't* itself a
  /// registered sibling template — is copied as-is, even if it happens to
  /// share a folder with the one being instantiated.
  ///
  /// The renamed main file's on-disk modified time is stamped to "now" —
  /// file copies (at least on Windows) preserve the original mtime, so
  /// without this a freshly-created project would inherit the template's
  /// (often much older) timestamp and sort as if it hadn't been touched in
  /// a long time on the main dashboard's Last Modified column.
  static Future<String> instantiate({
    required ProjectTemplate template,
    required String destinationFolderPath,
    required String newProjectName,
    List<ProjectTemplate> siblingTemplates = const [],
  }) async {
    final sourceDir = Directory(template.sourceFolderPath);
    if (!await sourceDir.exists()) {
      throw StateError(
        'Template source folder no longer exists: ${template.sourceFolderPath}',
      );
    }
    final sourceMainFile = File(
      p.join(template.sourceFolderPath, template.mainFileRelativePath),
    );
    if (!await sourceMainFile.exists()) {
      throw StateError(
        'Template main file no longer exists: ${sourceMainFile.path}',
      );
    }

    final ownFirstSegment = p.split(template.mainFileRelativePath).first;
    final excludedPaths = <String>{};
    for (final sibling in siblingTemplates) {
      if (sibling.sourceFolderPath != template.sourceFolderPath) continue;
      if (sibling.mainFileRelativePath == template.mainFileRelativePath) {
        continue;
      }
      final siblingFirstSegment = p.split(sibling.mainFileRelativePath).first;
      // If the sibling shares the exact same top-level subfolder as the
      // template being instantiated, excluding it would also exclude the
      // main file itself — leave it in rather than corrupt the copy.
      if (siblingFirstSegment == ownFirstSegment) continue;
      excludedPaths.add(p.join(template.sourceFolderPath, siblingFirstSegment));
    }

    // Checked here as well as by the dialog: the cleanup below deletes the
    // folder recursively, so it must only ever be one this call made. The
    // dialog checks when the name is typed, and a folder can appear by the
    // time the copy starts (a cloud sync, a second click on Finish).
    if (await FileSystemEntity.type(destinationFolderPath) != FileSystemEntityType.notFound) {
      throw StateError('Destination already exists: $destinationFolderPath');
    }

    // The destination folder did not exist a moment ago, so anything found
    // under it on failure is ours to clean up: a half-copied folder
    // left behind would otherwise collide with a same-named retry ("folder
    // already exists") with no way for the user to tell it apart from a
    // real project.
    try {
      await copyDirectoryRecursive(
        sourceDir,
        Directory(destinationFolderPath),
        excludedPaths: excludedPaths,
      );
      debugAfterTemplateCopy?.call(destinationFolderPath);

      final copiedMainFile = File(
        p.join(destinationFolderPath, template.mainFileRelativePath),
      );
      final newFileName =
          '$newProjectName${p.extension(template.mainFileRelativePath)}';
      final newMainFilePath = p.join(p.dirname(copiedMainFile.path), newFileName);
      final renamedMainFile = await copiedMainFile.rename(newMainFilePath);
      await renamedMainFile.setLastModified(DateTime.now());

      return newMainFilePath;
    } catch (_) {
      final destinationDir = Directory(destinationFolderPath);
      if (await destinationDir.exists()) {
        try {
          await destinationDir.delete(recursive: true);
        } catch (_) {
          // Best-effort cleanup — surface the original copy failure either way.
        }
      }
      rethrow;
    }
  }
}
