import 'package:flutter/material.dart';

import '../models/music_project.dart';

/// Per-project visual identity (#110): the cover art, accent color and icon
/// that let a project be picked out of a list without reading its name.
///
/// All three are opt-in. A project the user has not decorated shows *nothing* —
/// no placeholder image, no auto-assigned color, no stand-in icon — so the list
/// stays as quiet as it is today until someone chooses to mark a song. Cover
/// art, when set, wins over the color and icon.

/// Accent colors offered in the appearance editor.
///
/// A starting point, not a constraint: the picker also opens a full wheel and a
/// hex field, so any color is reachable. Tuned for dark backgrounds — user
/// themes are dark-only in v1.
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

/// Icons offered in the appearance editor, keyed by a stable identifier.
///
/// The *key* is what gets stored, synced and backed up, so a key must never
/// change meaning. Retiring one is safe — [projectIcon] returns null for a key
/// it no longer knows, which reads as "no icon chosen" rather than as a crash.
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

/// The accent color the user chose for [project], or null if they chose none.
Color? projectAccentColor(MusicProject project) =>
    project.accentColor == null ? null : Color(project.accentColor!);

/// The icon the user chose for [project], or null if they chose none.
///
/// A stored key this build no longer ships also reads as null: better an
/// undecorated row than a crash on a retired icon.
IconData? projectIcon(MusicProject project) =>
    project.iconKey == null ? null : kProjectIconChoices[project.iconKey!];

/// Whether [project] should be drawn as cover art rather than as its accent
/// badge — the "cover art wins" rule, in one place so the row, the header and
/// the appearance editor cannot disagree about it.
///
/// A question about stored state only. Whether the file behind the path still
/// loads is the cover widget's `errorBuilder` to answer, since stat-ing it on
/// every row rebuild would cost more than the fallback does.
bool projectHasCoverArt(MusicProject project) =>
    project.thumbnailPath != null && project.thumbnailPath!.isNotEmpty;

/// Whether [project] has anything to draw at all.
///
/// False for every project nobody has decorated, which is what keeps the list
/// free of generic placeholders.
bool projectHasVisualIdentity(MusicProject project) =>
    projectHasCoverArt(project) ||
    projectAccentColor(project) != null ||
    projectIcon(project) != null;
