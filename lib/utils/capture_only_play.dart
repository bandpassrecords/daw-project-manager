import 'package:material_ui/material_ui.dart';

import '../models/music_project.dart';

/// Whether the DAW plugin's capture is all [project] has to play: no preview
/// song set or auto-detected, only a latest capture. Then the play button
/// plays it directly, in [kCaptureOnlyPlayColor] — neither the green of a
/// chosen preview nor the amber of a detected one, and with no dot or menu,
/// since there is no second thing to choose. Not gated on the plugin being
/// installed: a capture synced from another computer is still the only audio.
bool playsCaptureOnly(MusicProject project) =>
    project.previewSongPath?.isNotEmpty != true &&
    project.previewSongAutoPath == null &&
    project.latestCapture != null;

/// The play button's colour when [playsCaptureOnly].
const Color kCaptureOnlyPlayColor = Colors.cyan;

/// The same, softer, for the dark scrim of a dashboard card's cover.
final Color kCaptureOnlyPlayColorOnCard = Colors.cyanAccent.shade100;
