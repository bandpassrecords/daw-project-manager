import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/music_project.dart';
import '../utils/track_duration.dart';

/// Reads a song's length off its preview file **without playing it**.
///
/// Song length is otherwise only learned when a player loads a track, which
/// means a release opened on a fresh library shows no lengths at all and no
/// total — the figures look unimplemented until every track has been played
/// once. This fills them in quietly instead.
///
/// Uses an [AudioPlayer] that is never started rather than parsing headers:
/// the app already depends on this decoder for every format it can play, so
/// the probe supports exactly the same set of files by construction, with no
/// second implementation of WAV/FLAC/MP3/OGG/AIFF parsing to keep correct.
class TrackDurationProbeService {
  const TrackDurationProbeService._();

  /// How long to wait for a decoder to report a duration before giving up.
  ///
  /// A probe that hangs must not hold up the ones behind it; a file that takes
  /// longer than this simply keeps its blank length until it is played.
  static const Duration probeTimeout = Duration(seconds: 5);

  /// The length of the audio at [path], or null when it cannot be determined.
  ///
  /// Never throws: a missing file, an unsupported codec or a decoder that
  /// refuses the file all return null, because the only consequence is a row
  /// that keeps showing no length.
  static Future<Duration?> probe(String path) async {
    if (path.isEmpty) return null;
    if (!File(path).existsSync()) return null;

    final player = AudioPlayer();
    try {
      // The duration can arrive either as the answer to getDuration() or on
      // the stream, depending on platform and format, so race both rather
      // than betting on one.
      final fromStream = player.onDurationChanged
          .firstWhere((d) => d > Duration.zero)
          .then<Duration?>((d) => d);

      await player.setSourceDeviceFile(path);

      final direct = player.getDuration();
      final resolved = await Future.any([direct, fromStream])
          .timeout(probeTimeout, onTimeout: () => null);

      if (resolved != null && resolved > Duration.zero) return resolved;

      // getDuration() can legitimately answer null before the decoder is
      // ready; give the stream the rest of the window on its own.
      return await fromStream
          .timeout(probeTimeout, onTimeout: () => null);
    } catch (e) {
      debugPrint('[DurationProbe] $path: $e');
      return null;
    } finally {
      // Releases the native decoder whatever happened above. Disposing can
      // itself throw for a source that never loaded, which must not escape.
      try {
        await player.dispose();
      } catch (_) {}
    }
  }
}

/// The projects in [projects] whose length is still unknown but knowable —
/// they have a playable preview song and no length from either source.
///
/// Pure, so the "what is worth probing" rule can be tested without touching a
/// decoder. [hasPlayablePreview] is injected for the same reason.
List<MusicProject> projectsNeedingDurationProbe(
  Iterable<MusicProject> projects, {
  required bool Function(MusicProject project) hasPlayablePreview,
}) {
  return [
    for (final project in projects)
      if (effectiveTrackDuration(project) == null && hasPlayablePreview(project))
        project,
  ];
}
