import '../models/music_project.dart';

/// Sorting for the project views that have no column headers to click — the
/// mobile list and the dashboard card grid (#111).
///
/// The table gets its sorting from `TrinaGrid`'s own headers; everything else
/// needs an explicit control, and both of those controls should agree on what
/// "sort by phase" means. Pure functions over a list, so the rules are
/// testable without a widget.

enum ProjectSortField { lastModified, name, phase, createdAt, bpm, deadline }

/// The direction each field is most useful in when it is first picked.
///
/// Dates and BPM read newest/highest first — "what did I touch last" is the
/// question being asked. Names and phases read forwards.
bool defaultDescendingFor(ProjectSortField field) => switch (field) {
  ProjectSortField.lastModified => true,
  ProjectSortField.createdAt => true,
  ProjectSortField.bpm => true,
  ProjectSortField.name => false,
  ProjectSortField.phase => false,
  ProjectSortField.deadline => false,
};

/// [projects] sorted by [field], ascending unless [descending].
///
/// Returns a new list; the input is never mutated — callers hand it output
/// straight from `projectsProvider`, which is shared with the table.
///
/// A project with no deadline sorts last in **both** directions: "no deadline"
/// is the absence of a date rather than a very early or very late one, and
/// flipping the arrow should not march the undated half of the library up to
/// the top. Missing BPM is different — 0 is a sensible floor for a number.
List<MusicProject> sortProjects(
  List<MusicProject> projects,
  ProjectSortField field, {
  bool descending = false,
}) {
  final list = List<MusicProject>.from(projects);
  int compare(MusicProject a, MusicProject b) => switch (field) {
    ProjectSortField.lastModified => a.lastModifiedAt.compareTo(
      b.lastModifiedAt,
    ),
    ProjectSortField.createdAt => a.createdAt.compareTo(b.createdAt),
    ProjectSortField.name => a.displayName.toLowerCase().compareTo(
      b.displayName.toLowerCase(),
    ),
    ProjectSortField.phase => a.status.toLowerCase().compareTo(
      b.status.toLowerCase(),
    ),
    ProjectSortField.bpm => (a.bpm ?? 0).compareTo(b.bpm ?? 0),
    ProjectSortField.deadline => _compareDeadlines(a, b, descending),
  };

  list.sort((a, b) {
    final result = compare(a, b);
    // The deadline comparator has already resolved its own direction so that
    // undated projects stay at the bottom either way.
    if (field == ProjectSortField.deadline) return result;
    return descending ? -result : result;
  });
  return list;
}

int _compareDeadlines(MusicProject a, MusicProject b, bool descending) {
  final aDeadline = a.deadline;
  final bDeadline = b.deadline;
  if (aDeadline == null && bDeadline == null) return 0;
  if (aDeadline == null) return 1;
  if (bDeadline == null) return -1;
  final result = aDeadline.compareTo(bDeadline);
  return descending ? -result : result;
}
