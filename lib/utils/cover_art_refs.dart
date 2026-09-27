import 'package:path/path.dart' as p;

import '../models/music_project.dart';
import '../models/release.dart';

/// Whether any project's cover art or any release's artwork still points at
/// [imagePath].
///
/// Several rows can share one image file: a version stack is a copy of the
/// member promoted onto it, `thumbnailPath` included, so the stack and that
/// member point at the same cover. Deleting the file because *one* of them
/// changed its cover silently broke the other — a member got its cover back on
/// unstack only as a dead path. Anything that deletes a managed image asks
/// this first, after the row that let go of it has been saved.
bool isImageInUse(
  String imagePath, {
  required Iterable<MusicProject> projects,
  required Iterable<Release> releases,
}) {
  final target = p.normalize(imagePath);
  bool same(String? other) =>
      other != null &&
      other.trim().isNotEmpty &&
      p.equals(p.normalize(other), target);
  return projects.any((project) => same(project.thumbnailPath)) ||
      releases.any((release) => same(release.artworkImagePath));
}
