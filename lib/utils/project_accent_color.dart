import 'package:flutter/material.dart';

/// Visual identity for a project that has no cover art of its own.
///
/// Everything here is derived from the project id, so the same song gets the
/// same colour on every machine and after every restore without storing a
/// single byte. #110 added the stored, user-overridable accent colour this
/// anticipated; this is now the fallback under it, for the (many) projects
/// nobody ever sets one on — a freshly scanned library of 300 folders has to
/// look distinguishable with zero user effort, or the card view is just a
/// bigger table.
///
/// [resolvedAccentColor] in `project_visuals.dart` is what UI should call: it
/// layers the stored override over [derivedAccentColor]. The two used to share
/// the name `projectAccentColor` on separate branches, with opposite meanings
/// — one nullable and user-set, one always-derived — which is exactly the
/// confusion the rename is here to prevent.

/// FNV-1a over the UTF-16 code units.
///
/// Deliberately not `String.hashCode`: that is only promised to be stable
/// within a single run of a single Dart version, and a project quietly
/// changing colour after an app update is exactly what this prevents.
int stableStringHash(String value) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < value.length; i++) {
    final unit = value.codeUnitAt(i);
    hash ^= unit & 0xff;
    hash = (hash * 0x01000193) & 0xffffffff;
    hash ^= (unit >> 8) & 0xff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// A stable accent colour derived from [projectId], for a project whose owner
/// has chosen none.
///
/// The hue comes off the hash; saturation and lightness are pinned so every
/// generated colour sits in the same band — white text stays readable on all
/// of them, and no project draws the eye just because it rolled a brighter
/// number than its neighbours.
Color derivedAccentColor(String projectId) {
  final hue = (stableStringHash(projectId) % 360).toDouble();
  return HSLColor.fromAHSL(1.0, hue, 0.45, 0.42).toColor();
}

/// The short label drawn on a project's generated cover: what the user typed,
/// or the initials derived from the name when they have typed nothing.
///
/// Whitespace-only counts as nothing — clearing the field in the editor is how
/// a user goes back to the derived label, and a card must never be blank.
String projectCardInitials(String? custom, String displayName) {
  final trimmed = custom?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return projectInitials(displayName);
}

/// One or two letters standing in for a project with no cover art.
///
/// Two initials when the name has two or more words ("Night Drive" → "ND"),
/// otherwise the first two characters of the single word ("bassline" → "BA"),
/// so a card is never blank.
String projectInitials(String displayName) {
  final words = displayName
      .split(RegExp(r'[\s_\-.]+'))
      .where((w) => w.trim().isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final word = words.first;
    return (word.length == 1 ? word : word.substring(0, 2)).toUpperCase();
  }
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}
