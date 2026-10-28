/// Formats a playback [duration] as `mm:ss`, or `hh:mm:ss` once it reaches an
/// hour — or always, with [withHours]. Every player's clock goes through it:
/// copies that left the hours out showed 1:12:00 as 12:00.
String formatPlaybackTimestamp(Duration duration, {bool withHours = false}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = duration.inHours;
  final m = two(duration.inMinutes.remainder(60));
  final s = two(duration.inSeconds.remainder(60));
  return h > 0 || withHours ? '${two(h)}:$m:$s' : '$m:$s';
}

/// A player's `position / total` readout. Once [total] reaches an hour the
/// position carries hours too (`00:12:00 / 01:30:00`), so the readout is one
/// width for the whole file rather than growing at the hour mark.
String formatPlaybackProgress(Duration position, Duration total) {
  final hours = total.inHours > 0;
  return '${formatPlaybackTimestamp(position, withHours: hours)} / '
      '${formatPlaybackTimestamp(total)}';
}

/// Builds the todo text for a note captured at a given playback [position],
/// prefixing the trimmed [note] with its formatted timestamp, e.g. `[1:23] Fix the kick drum`.
String buildTimestampedTodoText(Duration position, String note) {
  return '[${formatPlaybackTimestamp(position)}] ${note.trim()}';
}

/// Builds the text for a new task on a project's task list. Only stamps a
/// timestamp when [isCurrentlyPlaying] is true — i.e. the task's project is
/// the one actually loaded in the player right now — since [position]
/// otherwise refers to a different (or no) track.
String buildTaskTextForProject({
  required bool isCurrentlyPlaying,
  required Duration position,
  required String text,
}) {
  final trimmed = text.trim();
  return isCurrentlyPlaying
      ? buildTimestampedTodoText(position, trimmed)
      : trimmed;
}
