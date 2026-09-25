import 'package:path/path.dart' as p;

import '../models/scan_root.dart';

/// Path-prefix helpers for [ScanRoot.enabled] — see that field's doc for why
/// disabling a root has to hide its projects without deleting anything.
///
/// Kept as free functions over plain paths (rather than methods on the
/// provider) so the rule can be unit-tested without Hive or a widget tree.

/// [path] normalized and terminated with a separator, so a prefix test can
/// never match a sibling folder that merely starts with the same characters
/// (`/music/albums` must not swallow `/music/albums-old`).
String normalizedRootPrefix(String path) {
  final normalized = p.normalize(path);
  return normalized.endsWith(p.separator)
      ? normalized
      : normalized + p.separator;
}

/// Whether [filePath] sits inside the folder [rootPath].
///
/// The root folder itself counts as inside it: a version stack's `filePath`
/// is the folder its versions live in, which can be the scan root itself.
bool isUnderRootPath(String filePath, String rootPath) {
  final prefix = normalizedRootPrefix(rootPath);
  final normalized = p.normalize(filePath);
  if (normalized.startsWith(prefix)) return true;
  // `p.normalize` strips the trailing separator, so the root itself compares
  // equal to the prefix minus that one character.
  return normalized == prefix.substring(0, prefix.length - 1);
}

/// Whether a project at [filePath] should be hidden because the only root it
/// belongs to is switched off.
///
/// Enabled roots win: roots can nest, and a project inside an enabled subtree
/// stays visible even when some ancestor root is disabled. A project under no
/// root at all is never hidden — those are the metadata-only entries restored
/// from a backup or another machine, and they have no folder to be silenced
/// by.
bool isHiddenByDisabledRoot(
  String filePath,
  Iterable<ScanRoot> roots,
) {
  var matchedDisabled = false;
  for (final root in roots) {
    if (!isUnderRootPath(filePath, root.path)) continue;
    if (root.enabled) return false;
    matchedDisabled = true;
  }
  return matchedDisabled;
}
