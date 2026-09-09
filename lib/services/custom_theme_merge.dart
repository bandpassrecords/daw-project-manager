import '../models/custom_theme.dart';

/// Parses a JSON array of themes, skipping any entry that can't be read.
///
/// One malformed theme must not cost the user the rest of their set, so this
/// never throws and never returns null.
List<CustomTheme> customThemesFromJson(List? entries) {
  if (entries == null) return const [];
  final themes = <CustomTheme>[];
  for (final entry in entries) {
    if (entry is! Map) continue;
    try {
      themes.add(CustomTheme.fromJson(Map<String, dynamic>.from(entry)));
    } catch (_) {
      continue;
    }
  }
  return themes;
}

/// Merges [incoming] themes into [local], keyed by id.
///
/// Shared by local backup restore and Google Drive sync so both resolve the
/// same way:
///
/// * union — a theme only one side has survives, in particular a local theme
///   the other side has never seen. Absence is never treated as a deletion:
///   restoring last month's backup must not remove a theme made since.
/// * on a same-id collision the newer `updatedAt` wins, so a stale copy can't
///   roll back an edit.
/// * a theme carrying no timestamp never displaces one that has a timestamp.
///
/// Local themes keep their relative order, with genuinely new incoming ones
/// appended.
List<CustomTheme> mergeCustomThemes(
  List<CustomTheme> local,
  List<CustomTheme> incoming,
) {
  final merged = <String, CustomTheme>{for (final t in local) t.id: t};
  for (final theme in incoming) {
    final existing = merged[theme.id];
    if (existing == null || isNewerTheme(theme, existing)) {
      merged[theme.id] = theme;
    }
  }
  return merged.values.toList();
}

/// Whether [incoming] should replace [existing].
bool isNewerTheme(CustomTheme incoming, CustomTheme existing) {
  final incomingAt = incoming.updatedAt;
  if (incomingAt == null) return false;
  final existingAt = existing.updatedAt;
  if (existingAt == null) return true;
  return incomingAt.isAfter(existingAt);
}
