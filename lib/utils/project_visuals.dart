import 'package:flutter/material.dart';

import '../models/music_project.dart';

/// Per-project visual identity (#110): the accent color and icon that let a
/// project be picked out of a list without reading its name.
///
/// Every project has both from the moment it is scanned, at zero user effort:
/// when [MusicProject.accentColor] / [MusicProject.iconKey] are null the value
/// is *derived* from a stable hash of the project id rather than stored. That
/// choice matters in three places:
///
///  * every project already in a user's library gets a look immediately, with
///    no migration pass over the box;
///  * the same song looks identical on every machine and after every Drive
///    restore, because the id — not a stored color — is what travels;
///  * "Automatic" stays a real, restorable state (null), so a user who
///    overrides a color can always get the original one back.
///
/// Cover art, when set, wins over both — see [ProjectCoverAvatar].

/// Accent colors offered to the user, and the pool the automatic assignment
/// draws from.
///
/// **The order is part of the derivation.** Reordering or removing an entry
/// re-rolls the automatic color of every project that has not been overridden,
/// so append rather than edit. Tuned for dark backgrounds — user themes are
/// dark-only in v1.
const List<Color> kProjectAccentPalette = [
  Color(0xFF4FC3F7), // light blue
  Color(0xFF7986CB), // indigo
  Color(0xFF9575CD), // deep purple
  Color(0xFFBA68C8), // purple
  Color(0xFFF06292), // pink
  Color(0xFFEF5350), // red
  Color(0xFFFF8A65), // salmon
  Color(0xFFFFB74D), // orange
  Color(0xFFFFD54F), // amber
  Color(0xFFDCE775), // lime
  Color(0xFF81C784), // green
  Color(0xFF4DB6AC), // teal
  Color(0xFF4DD0E1), // cyan
  Color(0xFF90A4AE), // blue grey
];

/// Icons offered to the user, keyed by a stable identifier.
///
/// The *key* is what is stored, so a key must never change meaning. The
/// iteration order is part of the derivation, exactly as with the palette:
/// append, don't reorder. Removing a key is safe for stored data —
/// [resolveProjectIconKey] falls back to the derived icon for a key it no
/// longer knows — but it does re-roll automatic assignments.
const Map<String, IconData> kProjectIconChoices = {
  'note': Icons.music_note,
  'audiotrack': Icons.audiotrack,
  'album': Icons.album,
  'headphones': Icons.headphones,
  'mic': Icons.mic,
  'piano': Icons.piano,
  'guitar': Icons.music_video,
  'drums': Icons.album_outlined,
  'equalizer': Icons.equalizer,
  'graphic_eq': Icons.graphic_eq,
  'radio': Icons.radio,
  'speaker': Icons.speaker,
  'tune': Icons.tune,
  'waves': Icons.waves,
  'star': Icons.star,
  'bolt': Icons.bolt,
};

/// FNV-1a over the UTF-16 code units.
///
/// Deliberately not `String.hashCode`: that is only guaranteed stable within a
/// single run of a single Dart implementation, and a project's automatic color
/// changing between app launches — or differing between desktop and mobile for
/// the same synced project — is exactly what this must not do.
int stableProjectHash(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit & 0xFF;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
    hash ^= (unit >> 8) & 0xFF;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// The accent color a project gets when the user has not chosen one.
Color deterministicAccentColor(String projectId) =>
    kProjectAccentPalette[stableProjectHash('accent:$projectId') %
        kProjectAccentPalette.length];

/// The icon key a project gets when the user has not chosen one.
///
/// Seeded differently from [deterministicAccentColor] so that two projects
/// sharing a color are unlikely to also share an icon.
String deterministicIconKey(String projectId) => kProjectIconChoices.keys
    .elementAt(stableProjectHash('icon:$projectId') % kProjectIconChoices.length);

/// The accent color to paint for [project] — the user's override if there is
/// one, otherwise the derived color.
Color resolveProjectAccentColor(MusicProject project) =>
    project.accentColor != null
        ? Color(project.accentColor!)
        : deterministicAccentColor(project.id);

/// The icon key to show for [project]. An override naming an icon this build
/// no longer ships falls back to the derived key rather than to nothing.
String resolveProjectIconKey(MusicProject project) {
  final key = project.iconKey;
  if (key != null && kProjectIconChoices.containsKey(key)) return key;
  return deterministicIconKey(project.id);
}

/// The icon to show for [project].
IconData resolveProjectIcon(MusicProject project) =>
    kProjectIconChoices[resolveProjectIconKey(project)]!;

/// Whether [project] should be drawn as cover art rather than as its accent
/// badge — the "cover art wins" rule, in one place so the avatar and the
/// appearance editor cannot disagree about it.
///
/// A question about stored state only. Whether the file behind the path still
/// loads is [ProjectCoverAvatar]'s `errorBuilder` to answer, since stat-ing it
/// on every row rebuild would cost more than the fallback does.
bool projectHasCoverArt(MusicProject project) =>
    project.thumbnailPath != null && project.thumbnailPath!.isNotEmpty;
