import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/todo_item.dart';
import 'package:daw_project_manager/utils/todo_due_utils.dart';

import '../helpers/test_factories.dart';

void main() {
  // Mid-afternoon on purpose: due dates are stored at midnight, so a
  // date-only comparison is the only thing that keeps a todo due "today"
  // reading as due today rather than already overdue.
  final now = DateTime(2025, 6, 10, 15, 30);

  TodoItem todo(String id, {DateTime? dueAt, bool completed = false, DateTime? createdAt}) =>
      TestFactories.makeTodo(
        id: id,
        text: id,
        dueAt: dueAt,
        completed: completed,
        createdAt: createdAt,
      );

  group('daysUntilDue', () {
    test('is 0 for a date-only due date that lands on today', () {
      expect(daysUntilDue(DateTime(2025, 6, 10), now), 0);
    });

    test('counts whole days regardless of time of day', () {
      expect(daysUntilDue(DateTime(2025, 6, 11, 1), now), 1);
      expect(daysUntilDue(DateTime(2025, 6, 9, 23, 59), now), -1);
    });

    test('is null with no due date', () {
      expect(daysUntilDue(null, now), isNull);
    });
  });

  group('todoDueStatus', () {
    test('classifies each band', () {
      expect(todoDueStatus(null, now), TodoDueStatus.none);
      expect(todoDueStatus(DateTime(2025, 6, 9), now), TodoDueStatus.overdue);
      expect(todoDueStatus(DateTime(2025, 6, 10), now), TodoDueStatus.dueToday);
      expect(todoDueStatus(DateTime(2025, 6, 11), now), TodoDueStatus.dueSoon);
      expect(todoDueStatus(DateTime(2025, 6, 17), now), TodoDueStatus.dueSoon);
      expect(todoDueStatus(DateTime(2025, 6, 18), now), TodoDueStatus.upcoming);
    });
  });

  group('matchesDueFilter', () {
    final overdue = todo('overdue', dueAt: DateTime(2025, 6, 1));
    final today = todo('today', dueAt: DateTime(2025, 6, 10));
    final soon = todo('soon', dueAt: DateTime(2025, 6, 14));
    final later = todo('later', dueAt: DateTime(2025, 8, 1));
    final undated = todo('undated');

    test('all keeps everything', () {
      for (final t in [overdue, today, soon, later, undated]) {
        expect(matchesDueFilter(t, QueueDueFilter.all, now), isTrue);
      }
    });

    test('overdue keeps only past due dates', () {
      expect(matchesDueFilter(overdue, QueueDueFilter.overdue, now), isTrue);
      expect(matchesDueFilter(today, QueueDueFilter.overdue, now), isFalse);
      expect(matchesDueFilter(undated, QueueDueFilter.overdue, now), isFalse);
    });

    test('dueToday keeps only today', () {
      expect(matchesDueFilter(today, QueueDueFilter.dueToday, now), isTrue);
      expect(matchesDueFilter(overdue, QueueDueFilter.dueToday, now), isFalse);
      expect(matchesDueFilter(soon, QueueDueFilter.dueToday, now), isFalse);
    });

    test('dueThisWeek sweeps up overdue, today and the next seven days', () {
      expect(matchesDueFilter(overdue, QueueDueFilter.dueThisWeek, now), isTrue);
      expect(matchesDueFilter(today, QueueDueFilter.dueThisWeek, now), isTrue);
      expect(matchesDueFilter(soon, QueueDueFilter.dueThisWeek, now), isTrue);
      expect(matchesDueFilter(later, QueueDueFilter.dueThisWeek, now), isFalse);
      expect(matchesDueFilter(undated, QueueDueFilter.dueThisWeek, now), isFalse);
    });

    test('noDueDate keeps only undated todos', () {
      expect(matchesDueFilter(undated, QueueDueFilter.noDueDate, now), isTrue);
      expect(matchesDueFilter(overdue, QueueDueFilter.noDueDate, now), isFalse);
    });
  });

  group('sortTodosByDue', () {
    test('orders by due date, undated last', () {
      final sorted = sortTodosByDue([
        todo('undated'),
        todo('late', dueAt: DateTime(2025, 7, 1)),
        todo('overdue', dueAt: DateTime(2025, 6, 1)),
        todo('today', dueAt: DateTime(2025, 6, 10)),
      ]);

      expect(sorted.map((t) => t.id), ['overdue', 'today', 'late', 'undated']);
    });

    test('orders undated todos oldest first', () {
      final sorted = sortTodosByDue([
        todo('newer', createdAt: DateTime(2025, 5, 2)),
        todo('older', createdAt: DateTime(2025, 5, 1)),
      ]);

      expect(sorted.map((t) => t.id), ['older', 'newer']);
    });

    test('breaks exact ties by text so the order is stable', () {
      final due = DateTime(2025, 6, 12);
      final sorted = sortTodosByDue([
        todo('b', dueAt: due),
        todo('a', dueAt: due),
      ]);

      expect(sorted.map((t) => t.id), ['a', 'b']);
    });
  });

  group('earliestDueDate', () {
    test('finds the soonest date', () {
      expect(
        earliestDueDate([
          todo('a', dueAt: DateTime(2025, 7, 1)),
          todo('b', dueAt: DateTime(2025, 6, 2)),
          todo('c'),
        ]),
        DateTime(2025, 6, 2),
      );
    });

    test('is null when nothing is dated', () {
      expect(earliestDueDate([todo('a'), todo('b')]), isNull);
    });
  });

  group('compareSectionsByDue', () {
    int cmp(List<TodoItem> a, List<TodoItem> b, {String aName = 'a', String bName = 'b'}) =>
        compareSectionsByDue(a, b, aName: aName, bName: bName);

    test('the section holding the soonest task comes first', () {
      final soonest = [todo('x', dueAt: DateTime(2025, 6, 11))];
      final later = [
        todo('y', dueAt: DateTime(2025, 6, 20)),
        todo('z', dueAt: DateTime(2025, 6, 21)),
      ];

      // Even though the later section has more pending tasks.
      expect(cmp(soonest, later), lessThan(0));
      expect(cmp(later, soonest), greaterThan(0));
    });

    test('sections with no dated task sink below every dated one', () {
      final dated = [todo('x', dueAt: DateTime(2025, 12, 31))];
      final undated = [todo('y'), todo('z'), todo('w')];

      expect(cmp(dated, undated), lessThan(0));
      expect(cmp(undated, dated), greaterThan(0));
    });

    test('falls back to the old pending-count order when nothing is dated', () {
      final many = [todo('a'), todo('b')];
      final few = [todo('c')];

      expect(cmp(many, few), lessThan(0));
    });

    test('breaks a full tie by name', () {
      expect(cmp([todo('a')], [todo('b')], aName: 'Beta', bName: 'Alpha'),
          greaterThan(0));
    });
  });
}
