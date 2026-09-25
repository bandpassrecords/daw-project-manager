import '../models/music_project.dart';

/// Song length: how it is stored, parsed, formatted, and totalled for a
/// release.
///
/// A project carries two lengths, mirroring how preview songs already work
/// (`previewSongPath` vs `previewSongAutoPath`): [MusicProject.autoDurationMs]
/// is what a player measured off the preview song, and
/// [MusicProject.durationMs] is what the user typed. The typed one wins, and
/// clearing it falls back to the measured one rather than to nothing — so
/// correcting a length is never destructive, and re-measuring never silently
/// overwrites a deliberate value.

/// The length to show for [project]: what the user typed, else what was
/// measured, else null when neither exists.
Duration? effectiveTrackDuration(MusicProject project) {
  final ms = project.durationMs ?? project.autoDurationMs;
  if (ms == null || ms <= 0) return null;
  return Duration(milliseconds: ms);
}

/// Whether [project] shows a length the user typed rather than one measured
/// off its preview song. Lets the UI say which it is, and offer to revert.
bool hasManualTrackDuration(MusicProject project) =>
    project.durationMs != null && project.durationMs! > 0;

/// `m:ss`, or `h:mm:ss` once an hour is reached.
///
/// Minutes are not zero-padded at the front (`3:07`, not `03:07`) — that is
/// how track times are written on a sleeve. Seconds always are.
String formatTrackDuration(Duration duration) {
  final total = duration.inSeconds.abs();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  final ss = seconds.toString().padLeft(2, '0');
  if (hours == 0) return '$minutes:$ss';
  return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
}

/// Parses what someone might type into a length field, or null if it makes no
/// sense as a duration.
///
/// Accepts `m:ss`, `h:mm:ss`, and a bare number of seconds. Deliberately
/// strict about the parts being numeric and the seconds/minutes being under
/// 60 in the colon forms: silently reading `3:75` as 4:15 would be a worse
/// outcome than refusing it and letting the user see their typo.
Duration? parseTrackDuration(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;

  if (!text.contains(':')) {
    final seconds = int.tryParse(text);
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }

  final parts = text.split(':');
  if (parts.length > 3) return null;
  final numbers = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part.trim());
    if (value == null || value < 0) return null;
    numbers.add(value);
  }

  if (numbers.length == 2) {
    final [minutes, seconds] = numbers;
    if (seconds > 59) return null;
    return Duration(minutes: minutes, seconds: seconds);
  }
  final [hours, minutes, seconds] = numbers;
  if (minutes > 59 || seconds > 59) return null;
  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}

/// Smallest change in a measured length worth writing back to Hive.
///
/// A player reports a duration that can wobble by a few milliseconds between
/// loads, and every project row is watched — rewriting the box over a 3 ms
/// difference would churn storage and wake every listener for nothing.
const Duration kAutoDurationTolerance = Duration(seconds: 1);

/// Whether a duration a player just reported should replace the stored
/// [storedMs].
///
/// False for a zero or negative reading (a player that has not resolved the
/// file yet reports `Duration.zero`, which must never be stored as a real
/// length), and false when it agrees with what is already stored to within
/// [kAutoDurationTolerance].
bool shouldUpdateAutoDuration({
  required int? storedMs,
  required Duration measured,
}) {
  if (measured <= Duration.zero) return false;
  if (storedMs == null || storedMs <= 0) return true;
  final difference = (measured.inMilliseconds - storedMs).abs();
  return difference >= kAutoDurationTolerance.inMilliseconds;
}

/// Combined length of every track in [projects] that has one.
///
/// Tracks with no length contribute nothing rather than blocking the total:
/// a release half-filled in should still show what it has. [tracksMissingDuration]
/// is how the UI knows to present the figure as a floor rather than a fact.
Duration releaseTotalDuration(Iterable<MusicProject> projects) {
  var total = Duration.zero;
  for (final project in projects) {
    final duration = effectiveTrackDuration(project);
    if (duration != null) total += duration;
  }
  return total;
}

/// How many of [projects] have no length yet — the count behind a
/// "3 tracks not counted" note next to a release total.
int tracksMissingDuration(Iterable<MusicProject> projects) =>
    projects.where((p) => effectiveTrackDuration(p) == null).length;

/// Writes [measured] onto [project] as its measured length, if it is worth
/// writing (see [shouldUpdateAutoDuration]). Returns the updated project, or
/// null when nothing needed saving.
///
/// Takes a `save` callback rather than a repository so the decision stays
/// testable without Hive; every player passes `repo.updateProject`.
Future<MusicProject?> recordMeasuredDuration(
  MusicProject project,
  Duration measured,
  Future<void> Function(MusicProject project) save,
) async {
  if (!shouldUpdateAutoDuration(
    storedMs: project.autoDurationMs,
    measured: measured,
  )) {
    return null;
  }
  final updated = project.copyWith(autoDurationMs: measured.inMilliseconds);
  await save(updated);
  return updated;
}

/// Which explanation the Length field's info icon shows, given where the
/// project's length comes from. Takes the localized strings as arguments so
/// the choice can be tested without a widget tree.
///
/// A typed length is reported even when a measured one also exists, because
/// the typed one is what the field is showing.
String songLengthSourceMessage({
  required bool manual,
  required bool measured,
  required String typedByHand,
  required String fromPreview,
  required String howItWorks,
}) {
  if (manual) return typedByHand;
  if (measured) return fromPreview;
  return howItWorks;
}
