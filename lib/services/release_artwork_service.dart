import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/music_project.dart';
import '../utils/app_paths.dart';
import '../utils/project_visuals.dart';

/// One project's thumbnail, offered as artwork for a release being created.
class ReleaseArtworkCandidate {
  const ReleaseArtworkCandidate({
    required this.projectId,
    required this.projectName,
    required this.imagePath,
  });

  final String projectId;

  /// Shown under the thumbnail so it's clear which track the image came from
  /// when several tracks have one.
  final String projectName;

  final String imagePath;

  @override
  bool operator ==(Object other) =>
      other is ReleaseArtworkCandidate &&
      other.projectId == projectId &&
      other.projectName == projectName &&
      other.imagePath == imagePath;

  @override
  int get hashCode => Object.hash(projectId, projectName, imagePath);
}

/// The thumbnails worth offering as artwork for a release made from
/// [projects], in the order the projects were given.
///
/// Skips projects with no thumbnail and thumbnails whose file is gone — a
/// broken-image tile is worse than one fewer choice. Duplicate paths collapse
/// to a single entry: several versions of one song commonly share a cover, and
/// offering the same picture three times is just noise.
List<ReleaseArtworkCandidate> releaseArtworkCandidates(
  Iterable<MusicProject> projects, {
  ImageExistsCheck imageExists = defaultImageExists,
}) {
  final seenPaths = <String>{};
  final candidates = <ReleaseArtworkCandidate>[];
  for (final project in projects) {
    final path = existingCoverArtPath(project, imageExists: imageExists);
    if (path == null) continue;
    if (!seenPaths.add(path)) continue;
    candidates.add(
      ReleaseArtworkCandidate(
        projectId: project.id,
        projectName: project.displayName,
        imagePath: path,
      ),
    );
  }
  return candidates;
}

/// Whether to interrupt release creation to ask about artwork.
///
/// Only when there is something to carry over. One candidate still asks
/// rather than silently adopting it: a track's thumbnail is not automatically
/// the release's cover, and a release created with artwork the user never
/// chose is harder to notice than one created without any.
bool shouldOfferArtworkCarryOver(List<ReleaseArtworkCandidate> candidates) =>
    candidates.isNotEmpty;

/// Gives a release its own copy of the carried-over cover at [sourcePath],
/// in the release artwork folder, and returns the copy's path.
///
/// The release must not point at the project's cover file itself: that file
/// belongs to the project, and changing or removing the project's cover
/// deletes it, which took the release's artwork with it. Returns null when
/// there is nothing to copy or the copy fails, so the release is simply
/// created without artwork rather than pointing at somebody else's file.
///
/// [artworkDir] is injectable for tests; it defaults to the app's managed
/// release artwork folder.
Future<String?> copyArtworkForRelease(
  String? sourcePath, {
  Future<String> Function() artworkDir = getReleaseArtworkPath,
}) async {
  if (sourcePath == null || sourcePath.trim().isEmpty) return null;
  try {
    final source = File(sourcePath);
    if (!await source.exists()) return null;
    final dir = Directory(await artworkDir());
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = p.join(
      dir.path,
      '${const Uuid().v4()}${p.extension(sourcePath)}',
    );
    return (await source.copy(dest)).path;
  } catch (_) {
    return null;
  }
}
