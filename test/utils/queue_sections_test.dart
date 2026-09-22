import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/models/todo_item.dart';
import 'package:daw_project_manager/utils/queue_sections.dart';
import 'package:daw_project_manager/utils/todo_due_utils.dart';

import '../helpers/test_factories.dart';

/// #113 — what the Task Queue shows and in what order. Extracted from
/// QueuePage.build precisely so the ordering rules can be asserted without
/// standing up Hive and the provider tree.
void main() {
  final now = DateTime(2025, 6, 10, 15, 30);

  TodoItem todo(String text, {DateTime? dueAt, bool completed = false}) =>
      TestFactories.makeTodo(
        id: text,
        text: text,
        dueAt: dueAt,
        completed: completed,
      );

  Release release(String title, List<TodoItem> todos) =>
      Release(id: title, title: title, trackIds: const [], todos: todos);

  List<QueueSection> build({
    List<dynamic> projects = const [],
    List<Release> releases = const [],
    String searchText = '',
    QueueDueFilter dueFilter = QueueDueFilter.all,
  }) =>
      buildQueueSections(
        projects: projects.cast(),
        releases: releases,
        searchText: searchText,
        dueFilter: dueFilter,
        now: now,
      );

  group('what appears', () {
    test('a project with no pending todos gets no section', () {
      final sections = build(projects: [
        TestFactories.makeProject(id: 'p1', todos: [todo('done', completed: true)]),
        TestFactories.makeProject(id: 'p2', todos: const []),
      ]);

      expect(sections, isEmpty);
    });

    test('projects and releases both get sections, interleaved by name', () {
      // Nothing dated and one todo each, so the final tiebreak decides:
      // alphabetical, which puts the release above the project.
      final sections = build(
        projects: [
          TestFactories.makeProject(
              id: 'p1', customDisplayName: 'Song', todos: [todo('mix')]),
        ],
        releases: [release('EP', [todo('art')])],
      );

      expect(sections.map((s) => s.kind),
          [QueueOwnerKind.release, QueueOwnerKind.project]);
      expect(sections.map((s) => s.name), ['EP', 'Song']);
      expect(sections.last.project.id, 'p1');
      expect(sections.first.release.id, 'EP');
    });
  });

  group('due-date ordering', () {
    test('the section holding the soonest task leads, whatever its backlog', () {
      // Before #113 this list was ordered by pending count alone, so the
      // project due tomorrow sat below a project with a longer backlog.
      final sections = build(projects: [
        TestFactories.makeProject(id: 'big', customDisplayName: 'Big backlog', todos: [
          todo('a', dueAt: DateTime(2025, 7, 1)),
          todo('b', dueAt: DateTime(2025, 7, 2)),
          todo('c', dueAt: DateTime(2025, 7, 3)),
        ]),
        TestFactories.makeProject(
          id: 'urgent',
          customDisplayName: 'Due tomorrow',
          todos: [todo('d', dueAt: DateTime(2025, 6, 11))],
        ),
      ]);

      expect(sections.map((s) => s.name), ['Due tomorrow', 'Big backlog']);
    });

    test('a release can outrank a project and vice versa', () {
      final sections = build(
        projects: [
          TestFactories.makeProject(
            id: 'p1',
            customDisplayName: 'Later song',
            todos: [todo('mix', dueAt: DateTime(2025, 6, 20))],
          ),
        ],
        releases: [
          release('Urgent EP', [todo('art', dueAt: DateTime(2025, 6, 11))]),
        ],
      );

      expect(sections.map((s) => s.name), ['Urgent EP', 'Later song']);
    });

    test('undated sections sink below every dated one', () {
      final sections = build(
        projects: [
          TestFactories.makeProject(
            id: 'p1',
            customDisplayName: 'Undated',
            todos: [todo('a'), todo('b'), todo('c')],
          ),
        ],
        releases: [
          release('Dated EP', [todo('art', dueAt: DateTime(2025, 12, 31))]),
        ],
      );

      expect(sections.map((s) => s.name), ['Dated EP', 'Undated']);
    });

    test('todos inside a section are ordered by what is due next', () {
      final sections = build(projects: [
        TestFactories.makeProject(id: 'p1', todos: [
          todo('undated'),
          todo('later', dueAt: DateTime(2025, 7, 1)),
          todo('overdue', dueAt: DateTime(2025, 6, 1)),
        ]),
      ]);

      expect(sections.single.todos.map((t) => t.text),
          ['overdue', 'later', 'undated']);
    });
  });

  group('due filter', () {
    final projects = [
      TestFactories.makeProject(id: 'p1', customDisplayName: 'A', todos: [
        todo('overdue', dueAt: DateTime(2025, 6, 1)),
        todo('undated'),
      ]),
      TestFactories.makeProject(id: 'p2', customDisplayName: 'B', todos: [
        todo('today', dueAt: DateTime(2025, 6, 10)),
        todo('far', dueAt: DateTime(2025, 9, 1)),
      ]),
    ];

    test('overdue narrows to the overdue task, and drops empty sections', () {
      final sections = build(projects: projects, dueFilter: QueueDueFilter.overdue);

      expect(sections.length, 1);
      expect(sections.single.name, 'A');
      expect(sections.single.todos.map((t) => t.text), ['overdue']);
    });

    test('dueToday narrows to today', () {
      final sections = build(projects: projects, dueFilter: QueueDueFilter.dueToday);

      expect(sections.single.todos.map((t) => t.text), ['today']);
    });

    test('dueThisWeek keeps overdue and today but not months out', () {
      final sections =
          build(projects: projects, dueFilter: QueueDueFilter.dueThisWeek);

      expect(sections.map((s) => s.name), ['A', 'B']);
      expect(sections[0].todos.map((t) => t.text), ['overdue']);
      expect(sections[1].todos.map((t) => t.text), ['today']);
    });

    test('noDueDate surfaces exactly the tasks nobody has scheduled', () {
      final sections =
          build(projects: projects, dueFilter: QueueDueFilter.noDueDate);

      expect(sections.single.todos.map((t) => t.text), ['undated']);
    });

    test('a filter that matches nothing yields an empty queue', () {
      final sections = build(
        projects: [
          TestFactories.makeProject(id: 'p1', todos: [todo('undated')]),
        ],
        dueFilter: QueueDueFilter.overdue,
      );

      expect(sections, isEmpty);
    });
  });

  group('search still works alongside the filter', () {
    final projects = [
      TestFactories.makeProject(id: 'p1', customDisplayName: 'Midnight Drive', todos: [
        todo('master', dueAt: DateTime(2025, 6, 12)),
        todo('artwork'),
      ]),
      TestFactories.makeProject(id: 'p2', customDisplayName: 'Other Song', todos: [
        todo('master vocals', dueAt: DateTime(2025, 6, 11)),
      ]),
    ];

    test('matching the owner name keeps all of its todos', () {
      final sections = build(projects: projects, searchText: 'midnight');

      expect(sections.single.name, 'Midnight Drive');
      expect(sections.single.todos.length, 2);
    });

    test('matching todo text keeps only the matching todos', () {
      final sections = build(projects: projects, searchText: 'artwork');

      expect(sections.single.todos.map((t) => t.text), ['artwork']);
    });

    test('search and due filter both apply', () {
      final sections = build(
        projects: projects,
        searchText: 'master',
        dueFilter: QueueDueFilter.dueThisWeek,
      );

      // Both projects match "master", but ordering is still due-first.
      expect(sections.map((s) => s.name), ['Other Song', 'Midnight Drive']);

      final narrowed = build(
        projects: projects,
        searchText: 'midnight',
        dueFilter: QueueDueFilter.noDueDate,
      );
      expect(narrowed.single.todos.map((t) => t.text), ['artwork']);
    });
  });

  test('queuePendingCount totals every visible todo', () {
    final sections = build(
      projects: [
        TestFactories.makeProject(id: 'p1', todos: [todo('a'), todo('b')]),
      ],
      releases: [release('EP', [todo('c')])],
    );

    expect(queuePendingCount(sections), 3);
  });
}
