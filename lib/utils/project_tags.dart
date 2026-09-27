import '../models/music_project.dart';

/// User-defined project tags (#109): the rules every screen shares.
///
/// A tag is free text — a genre, a client, a mood, a row of emoji. The only
/// rules are the ones that keep one idea from splitting into two filters:
/// surrounding whitespace is dropped, inner runs of whitespace collapse to one
/// space, and two tags that differ only by case are the same tag. The first
/// spelling the library used wins (see [canonicalTag]), so typing "trap" on a
/// song when "Trap" already exists files it under "Trap".
///
/// Pure functions over lists, so the rules are testable without Hive or a
/// widget. [MusicProject.tags] is written only through [addTag] / [removeTag].

/// Longest tag accepted, in characters. Long enough for "for the Luna EP
/// pitch", short enough that a chip in a table cell still reads as a label.
const int kMaxTagLength = 40;

final _whitespaceRun = RegExp(r'\s+');

/// [raw] cleaned up for storage, or null when nothing usable is left.
///
/// Trims, collapses inner whitespace and clips to [kMaxTagLength]. Clipping
/// counts runes rather than UTF-16 units so an emoji is never cut in half.
String? normalizeTag(String raw) {
  final collapsed = raw.trim().replaceAll(_whitespaceRun, ' ');
  if (collapsed.isEmpty) return null;
  final runes = collapsed.runes;
  if (runes.length <= kMaxTagLength) return collapsed;
  return String.fromCharCodes(runes.take(kMaxTagLength)).trimRight();
}

/// The key two tags are compared by. Case-insensitive, nothing else.
String tagKey(String tag) => tag.toLowerCase();

/// Whether [tags] holds [tag], ignoring case.
bool containsTag(Iterable<String> tags, String tag) {
  final key = tagKey(tag);
  return tags.any((t) => tagKey(t) == key);
}

/// [raw], normalized, spelled the way [existing] already spells it if it is
/// already in use — otherwise as typed. Null when [raw] is blank.
String? canonicalTag(String raw, Iterable<String> existing) {
  final tag = normalizeTag(raw);
  if (tag == null) return null;
  final key = tagKey(tag);
  for (final known in existing) {
    if (tagKey(known) == key) return known;
  }
  return tag;
}

/// [tags] with [tag] appended, or [tags] itself (same instance) when [tag] is
/// blank or already there.
///
/// Returning the same instance for a no-op lets a caller skip the write:
/// `identical(addTag(t, x), t)` means nothing changed.
List<String> addTag(List<String> tags, String tag) {
  final normalized = normalizeTag(tag);
  if (normalized == null || containsTag(tags, normalized)) return tags;
  return List.unmodifiable([...tags, normalized]);
}

/// [tags] without [tag] (ignoring case), or [tags] itself when it wasn't
/// there — same no-op contract as [addTag].
List<String> removeTag(List<String> tags, String tag) {
  if (!containsTag(tags, tag)) return tags;
  final key = tagKey(tag);
  return List.unmodifiable(tags.where((t) => tagKey(t) != key));
}

/// Every distinct tag used across [projects], sorted case-insensitively, each
/// spelled the way it first appears.
///
/// This is what the tag filter offers and what the editors autocomplete
/// from, so it must be computed over the whole library — never over an
/// already-filtered list, or picking a tag would make every other tag vanish
/// from the dropdown.
List<String> collectTags(Iterable<MusicProject> projects) {
  final byKey = <String, String>{};
  for (final project in projects) {
    for (final tag in project.tags) {
      byKey.putIfAbsent(tagKey(tag), () => tag);
    }
  }
  final tags = byKey.values.toList()
    ..sort((a, b) => tagKey(a).compareTo(tagKey(b)));
  return tags;
}

/// Whether [project] carries [tag], ignoring case.
bool projectHasTag(MusicProject project, String tag) =>
    containsTag(project.tags, tag);

/// The tag filter that should actually apply: [selected] if some project in
/// [available] still has it, otherwise none.
///
/// A filter on a tag nobody uses any more — its last project was untagged, or
/// deleted, or a Drive restore renamed it — would silently empty the list
/// while the dropdown, which only offers tags in use, showed no filter at
/// all. Treating it as "no filter" keeps the list and the control agreeing.
String? effectiveTagFilter(String? selected, List<String> available) {
  if (selected == null) return null;
  final key = tagKey(selected);
  for (final tag in available) {
    if (tagKey(tag) == key) return tag;
  }
  return null;
}

/// Orders two projects by their tags for "sort by tags": alphabetically by
/// the sorted tag list, compared tag by tag.
///
/// Untagged projects return null here so the caller can keep them last in
/// both directions — no tags is an absence, like no deadline, not a value
/// that belongs at one end of the alphabet.
int? compareByTags(MusicProject a, MusicProject b) {
  if (a.tags.isEmpty || b.tags.isEmpty) return null;
  final aKeys = a.tags.map(tagKey).toList()..sort();
  final bKeys = b.tags.map(tagKey).toList()..sort();
  for (var i = 0; i < aKeys.length && i < bKeys.length; i++) {
    final result = aKeys[i].compareTo(bKeys[i]);
    if (result != 0) return result;
  }
  return aKeys.length.compareTo(bKeys.length);
}

/// What a bulk tag change would do to [projects]: each one whose tags
/// actually change, paired with its new list.
///
/// Projects that already have the tag (when adding) or lack it (when
/// removing) are left out, so the caller writes only real changes and can
/// report an honest count.
List<(MusicProject, List<String>)> planBulkTagChange(
  Iterable<MusicProject> projects,
  String tag, {
  required bool add,
}) {
  final changes = <(MusicProject, List<String>)>[];
  for (final project in projects) {
    final updated = add
        ? addTag(project.tags, tag)
        : removeTag(project.tags, tag);
    if (!identical(updated, project.tags)) changes.add((project, updated));
  }
  return changes;
}
