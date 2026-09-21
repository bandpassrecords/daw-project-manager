import 'dart:io';

import '../models/music_project.dart';

/// Whether an image path is usable. Injected so callers can be tested without
/// touching the filesystem.
typedef ImageExistsCheck = bool Function(String path);

bool defaultImageExists(String path) => File(path).existsSync();

/// A project's thumbnail if it has one that is actually on disk, else null.
///
/// One place for the "set, non-blank, and the file is still there" test, so
/// the player, the media notification and the release-artwork picker can't
/// disagree about whether a project has a picture. A stored path whose file
/// has since been deleted counts as no thumbnail — every caller would
/// otherwise have to render its own broken-image state.
String? resolveProjectThumbnail(
  MusicProject project, {
  ImageExistsCheck imageExists = defaultImageExists,
}) {
  final path = project.thumbnailPath;
  if (path == null || path.trim().isEmpty) return null;
  if (!imageExists(path)) return null;
  return path;
}
