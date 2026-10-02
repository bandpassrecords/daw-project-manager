import '../models/music_project.dart';
import '../models/project_part.dart';

/// The texts the projects search matches a project against, for
/// `fuzzyMatchAny`.
///
/// Multi-valued fields (markers, tags, plug-ins) go in one entry each rather
/// than joined: `fuzzyMatchAny` requires every query word to hit the *same*
/// entry, so a joined string would match words picked out of two unrelated
/// markers.
///
/// [includeTags] is false while tags are switched off: a hidden tag must not
/// make a project match, or the user sees a result with nothing on screen
/// explaining why.
Iterable<String?> projectSearchFields(
  MusicProject p, {
  required bool includeTags,
}) sync* {
  yield p.displayName;
  yield p.notes;
  // projectNotes are the read-only notes extracted from the DAW file itself —
  // real user content, so searchable too.
  yield p.projectNotes;
  // Instrumentation is searchable too, so "who played bass on which song" is
  // answerable from the projects list. Guarded because this runs per project
  // per keystroke and searchableText builds a string.
  if (p.parts.isNotEmpty) yield ProjectPart.searchableText(p.parts);
  yield* p.markers.map((m) => m.name);
  if (includeTags) yield* p.tags;
  // So "serum" finds every song that loads it.
  final plugins = p.stats?.plugins;
  if (plugins != null) yield* plugins;
}
