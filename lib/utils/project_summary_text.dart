import '../models/music_project.dart';

/// One-line summaries of a project's free text, for places that have a row
/// rather than a page to work with — currently the release tracklist.

/// Default width of an excerpt, in characters. Roughly what fits a table cell
/// before the renderer's own ellipsis takes over; the cap here is about not
/// carrying a whole paragraph around, not about pixels.
const int kNoteExcerptMaxChars = 120;

/// The notes the user wrote on [project], flattened to a single line, or null
/// when they wrote none.
///
/// Only the user's own [MusicProject.notes] — never the DAW-extracted
/// `projectNotes`. On a release tracklist the note is the user's word on the
/// song; the project file's embedded text is session scratch (plug-in notes,
/// comments left in the DAW) that reads as noise there. It used to be the
/// fallback when no note was typed, and was taken out for that reason.
///
/// Newlines and runs of whitespace collapse to single spaces — a two-paragraph
/// note must not blow up a table row's height, and the full text is still
/// available as a tooltip.
String? projectNoteExcerpt(
  MusicProject project, {
  int maxChars = kNoteExcerptMaxChars,
}) {
  final flattened = _flatten(project.notes);
  if (flattened == null) return null;
  return _truncate(flattened, maxChars);
}

/// The full note text behind [projectNoteExcerpt], flattened but uncut — what
/// a tooltip shows when the excerpt was shortened.
String? projectNoteFullText(MusicProject project) => _flatten(project.notes);

/// [text] with every run of whitespace collapsed to one space, or null when
/// nothing but whitespace is left.
String? _flatten(String? text) {
  if (text == null) return null;
  final flattened = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flattened.isEmpty ? null : flattened;
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
