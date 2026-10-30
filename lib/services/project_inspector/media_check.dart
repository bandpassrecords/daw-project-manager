import 'package:path/path.dart' as p;

import '../../models/sample_reference.dart';
import '../sample_pack/sample_locator.dart';

/// Whether an audio file a project uses is on this computer.
enum MediaStatus {
  /// Where the project says it is.
  found,

  /// Not there, but a file of that name sits in the project's own folder —
  /// what the DAW would find too when asked to look.
  foundElsewhere,

  missing,
}

class MediaCheck {
  const MediaCheck(this.reference, this.status, {this.path});
  final SampleReference reference;
  final MediaStatus status;

  /// Where the file was found; null when missing.
  final String? path;
}

/// Looks for every file [references] names, without opening any: a file on
/// a cloud drive downloads when read, so only existence and size are asked
/// (the sample pack's rule). A file referenced several times is checked once.
///
/// The search is [SampleLocator]'s: the stored places first, then the
/// project's own folder tree by name. Library folders aren't searched here —
/// a same-named file elsewhere is a guess, and relinking is for #214.
Future<List<MediaCheck>> checkMedia(
  List<SampleReference> references, {
  required String projectDir,
  SampleLocator? locator,
}) async {
  final finder = locator ?? SampleLocator();
  final seen = <String>{};
  final checks = <MediaCheck>[];
  for (final ref in references) {
    final identity =
        '${ref.fileName.toLowerCase()}\u0000${ref.candidates.firstOrNull ?? ''}';
    if (!seen.add(identity)) continue;
    final found = await finder.locate(ref, projectDir: projectDir);
    if (found == null) {
      checks.add(MediaCheck(ref, MediaStatus.missing));
      continue;
    }
    final stored = {
      for (final c in ref.candidates)
        p.normalize(p.isAbsolute(c) ? c : p.join(projectDir, c)),
    };
    checks.add(MediaCheck(
      ref,
      stored.contains(p.normalize(found))
          ? MediaStatus.found
          : MediaStatus.foundElsewhere,
      path: found,
    ));
  }
  return checks;
}

/// How many of [checks] are in each status.
Map<MediaStatus, int> mediaCounts(List<MediaCheck> checks) {
  final counts = <MediaStatus, int>{};
  for (final c in checks) {
    counts[c.status] = (counts[c.status] ?? 0) + 1;
  }
  return counts;
}
