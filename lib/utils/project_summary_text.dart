import '../models/music_project.dart';

/// One-line summaries of a project's free text, for places that have a row
/// rather than a page to work with — currently the release tracklist.

/// Default width of an excerpt, in characters. Roughly what fits a table cell
/// before the renderer's own ellipsis takes over; the cap here is about not
/// carrying a whole paragraph around, not about pixels.
const int kNoteExcerptMaxChars = 120;

/// [project]'s notes flattened to a single line, or null when it has none.
///
/// Prefers the user's own notes over the DAW-extracted ones: someone who typed
/// a line about a song said something deliberate, whereas `projectNotes` is
/// whatever the project file happened to carry. Falls back to the DAW text so a
/// row is not blank when that is all there is.
///
/// Newlines and runs of whitespace collapse to single spaces — a two-paragraph
/// note must not blow up a table row's height, and the full text is still
/// available as a tooltip.
String? projectNoteExcerpt(
  MusicProject project, {
  int maxChars = kNoteExcerptMaxChars,
}) {
  final source = _firstNonBlank([project.notes, project.projectNotes]);
  if (source == null) return null;
  final flattened = source.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flattened.isEmpty) return null;
  return _truncate(flattened, maxChars);
}

/// The full note text behind [projectNoteExcerpt], flattened but uncut — what
/// a tooltip shows when the excerpt was shortened.
String? projectNoteFullText(MusicProject project) {
  final source = _firstNonBlank([project.notes, project.projectNotes]);
  if (source == null) return null;
  final flattened = source.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flattened.isEmpty ? null : flattened;
}

String? _firstNonBlank(List<String?> candidates) {
  for (final candidate in candidates) {
    if (candidate != null && candidate.trim().isNotEmpty) return candidate;
  }
  return null;
}

/// [text] cut to [maxChars], ending with an ellipsis.
///
/// Backs up to the last word boundary when there is one reasonably close, so
/// the excerpt ends on a word rather than mid-syllable. "Reasonably close" is
/// deliberately lenient about scripts that don't space their words (Japanese,
/// Chinese): with no boundary to find, it just cuts at the limit.
String _truncate(String text, int maxChars) {
  if (maxChars <= 0) return '';
  if (text.length <= maxChars) return text;
  final hardCut = text.substring(0, maxChars);
  final lastSpace = hardCut.lastIndexOf(' ');
  final cut = lastSpace >= maxChars ~/ 2
      ? hardCut.substring(0, lastSpace)
      : hardCut;
  return '${cut.trimRight()}…';
}
