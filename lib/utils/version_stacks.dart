import '../models/music_project.dart';

/// Collapses version stacks (#94) into one row per song for anything that
/// counts, totals or buckets projects.
///
/// A stacked library holds N+1 rows for one piece of work: the stack, which
/// owns the shared metadata, and each version file underneath it. Counting
/// that list raw reports a stacked song several times over and buckets its
/// promoted BPM and key once per version.
///
/// Two things happen here:
/// - Members are dropped; the stack stands in for them.
/// - Each stack's [MusicProject.totalWorkSeconds] and [MusicProject.sessions]
///   are rolled up from its members. Work time is stored on the *members* and
///   derived on read (see `ProjectRepository.stackTotalWorkSeconds`), so a
///   stack row taken at face value reports zero hours — dropping the members
///   without this would erase the library's work history from every total.
///
/// Rows keep their input order, and non-stacked projects pass through
/// untouched. Pure so the aggregation is testable without Hive; the
/// repository's `stackMembers` walks the box instead, which is the right tool
/// when only one stack is in question.
List<MusicProject> collapseVersionStacks(List<MusicProject> projects) {
  final workByStack = <String, int>{};
  final sessionsByStack = <String, List<SessionRecord>>{};

  for (final project in projects) {
    final stackId = project.stackId;
    if (stackId == null) continue;
    workByStack[stackId] =
        (workByStack[stackId] ?? 0) + project.totalWorkSeconds;
    if (project.sessions.isNotEmpty) {
      (sessionsByStack[stackId] ??= []).addAll(project.sessions);
    }
  }

  final collapsed = <MusicProject>[];
  for (final project in projects) {
    if (project.isStackMember) continue;
    if (!project.isVirtual) {
      collapsed.add(project);
      continue;
    }
    final sessions = sessionsByStack[project.id] ?? const <SessionRecord>[];
    collapsed.add(
      project.copyWith(
        totalWorkSeconds: workByStack[project.id] ?? 0,
        sessions: sessions.isEmpty
            ? const []
            : (sessions.toList()
              ..sort((a, b) => a.startedAt.compareTo(b.startedAt))),
      ),
    );
  }
  return collapsed;
}

/// [collapseVersionStacks] for a nullable list, preserving null so callers
/// that treat "not loaded yet" differently from "loaded and empty" keep that
/// distinction.
List<MusicProject>? collapseVersionStacksOrNull(List<MusicProject>? projects) =>
    projects == null ? null : collapseVersionStacks(projects);
