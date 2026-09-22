import '../models/music_project.dart';
import '../models/release.dart';
import '../models/todo_item.dart';
import 'search_utils.dart';
import 'todo_due_utils.dart';

/// What a Task Queue section hangs off.
enum QueueOwnerKind { project, release }

/// One Task Queue card: an owner (a project or a release) and the pending
/// todos of it that survive the current search and due filter.
class QueueSection {
  final QueueOwnerKind kind;

  /// The [MusicProject] or [Release] the todos belong to.
  final Object owner;

  /// Owner name, used for the final alphabetical tiebreak.
  final String name;

  /// Pending, matching todos, ordered by what is due next.
  final List<TodoItem> todos;

  const QueueSection({
    required this.kind,
    required this.owner,
    required this.name,
    required this.todos,
  });

  MusicProject get project => owner as MusicProject;
  Release get release => owner as Release;
}

/// The Task Queue's list, in display order.
///
/// Pure so the ordering rules the queue actually shows can be tested without
/// standing up Hive and the whole provider tree.
///
/// Ordering is due-first — the section holding the soonest task leads, so the
/// queue reads as "what is actually due next" rather than "who has the longest
/// backlog". Sections with nothing dated fall back to the old pending-count
/// order, which is what the queue looked like before due dates existed.
List<QueueSection> buildQueueSections({
  required List<MusicProject> projects,
  required List<Release> releases,
  required String searchText,
  required QueueDueFilter dueFilter,
  required DateTime now,
}) {
  final search = searchText.toLowerCase().trim();

  List<TodoItem> visibleTodos(Iterable<TodoItem> todos, String ownerName) {
    // A search hit on the owner's name keeps all of its todos; otherwise each
    // todo has to match on its own text.
    final ownerMatches = search.isNotEmpty && fuzzyMatchAll(ownerName, search);
    return sortTodosByDue(todos.where((t) =>
        !t.completed &&
        matchesDueFilter(t, dueFilter, now) &&
        (search.isEmpty || ownerMatches || fuzzyMatchAll(t.text, search))));
  }

  final sections = <QueueSection>[];

  for (final project in projects) {
    final todos = visibleTodos(project.todos, project.displayName);
    if (todos.isEmpty) continue;
    sections.add(QueueSection(
      kind: QueueOwnerKind.project,
      owner: project,
      name: project.displayName,
      todos: todos,
    ));
  }

  for (final release in releases) {
    final todos = visibleTodos(release.todos, release.title);
    if (todos.isEmpty) continue;
    sections.add(QueueSection(
      kind: QueueOwnerKind.release,
      owner: release,
      name: release.title,
      todos: todos,
    ));
  }

  sections.sort((a, b) => compareSectionsByDue(
        a.todos,
        b.todos,
        aName: a.name,
        bName: b.name,
      ));
  return sections;
}

/// Total pending todos across [sections] — the number in the summary line.
int queuePendingCount(Iterable<QueueSection> sections) =>
    sections.fold<int>(0, (sum, s) => sum + s.todos.length);
