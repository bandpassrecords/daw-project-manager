import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/todo_item.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/utils/todo_completion.dart';

import '../helpers/test_factories.dart';

void main() {
  TodoItem todo(String id, {bool completed = false, String? text}) =>
      TestFactories.makeTodo(
        id: id,
        text: text ?? id,
        completed: completed,
      );

  group('setTodoCompleted', () {
    test('completes exactly the todo asked for', () {
      // The bug this guards: ticking one task off and finding the rest gone
      // too. Completion rewrites the owner's whole list, so "only this one"
      // has to be true of the list, not just of the row that was tapped.
      final before = [todo('a'), todo('b'), todo('c')];

      final after = setTodoCompleted(before, 'b', completed: true);

      expect(completedTodoCount(after), 1);
      expect(after.firstWhere((t) => t.id == 'b').completed, isTrue);
      expect(after.firstWhere((t) => t.id == 'a').completed, isFalse);
      expect(after.firstWhere((t) => t.id == 'c').completed, isFalse);
    });

    test('leaves todos that merely share text alone', () {
      final before = [
        todo('a', text: 'Mix vocals'),
        todo('b', text: 'Mix vocals'),
      ];

      final after = setTodoCompleted(before, 'a', completed: true);

      expect(after.firstWhere((t) => t.id == 'b').completed, isFalse);
    });

    test('un-completes exactly the todo asked for', () {
      final before = [
        todo('a', completed: true),
        todo('b', completed: true),
      ];

      final after = setTodoCompleted(before, 'a', completed: false);

      expect(after.firstWhere((t) => t.id == 'a').completed, isFalse);
      expect(after.firstWhere((t) => t.id == 'b').completed, isTrue);
    });

    test('preserves order', () {
      final before = [todo('a'), todo('b'), todo('c')];

      final after = setTodoCompleted(before, 'b', completed: true);

      expect(after.map((t) => t.id), ['a', 'b', 'c']);
    });

    test('preserves the rest of the completed todo', () {
      final due = DateTime(2026, 1, 2);
      final before = [TestFactories.makeTodo(id: 'a', text: 'Mix', dueAt: due)];

      final after = setTodoCompleted(before, 'a', completed: true);

      expect(after.single.text, 'Mix');
      expect(after.single.dueAt, due);
      expect(after.single.createdAt, before.single.createdAt);
    });

    test('returns the same list when the todo is already in that state', () {
      // Callers skip the write on identity, so a no-op tick cannot churn Hive
      // or wake every listener watching the project.
      final before = [todo('a', completed: true)];

      expect(
        identical(setTodoCompleted(before, 'a', completed: true), before),
        isTrue,
      );
    });

    test('returns the same list when no todo matches', () {
      final before = [todo('a')];

      expect(
        identical(setTodoCompleted(before, 'nope', completed: true), before),
        isTrue,
      );
    });

    test('an empty list stays empty', () {
      expect(setTodoCompleted(const [], 'a', completed: true), isEmpty);
    });
  });

  group('RecentlyCompletedTodosNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    Set<String> held() => container.read(recentlyCompletedTodosProvider);
    RecentlyCompletedTodosNotifier notifier() =>
        container.read(recentlyCompletedTodosProvider.notifier);

    test('starts empty', () {
      expect(held(), isEmpty);
    });

    test('holds each completed todo', () {
      notifier().add('a');
      notifier().add('b');

      expect(held(), {'a', 'b'});
    });

    test('adding the same id twice holds it once', () {
      notifier().add('a');
      notifier().add('a');

      expect(held(), {'a'});
    });

    test('undo stops holding it', () {
      notifier().add('a');
      notifier().add('b');
      notifier().remove('a');

      expect(held(), {'b'});
    });

    test('removing something never held is harmless', () {
      notifier().remove('a');

      expect(held(), isEmpty);
    });

    test('clear drops everything, as leaving the tab does', () {
      notifier().add('a');
      notifier().add('b');
      notifier().clear();

      expect(held(), isEmpty);
    });

    test('clearing an empty set does not churn state', () {
      final before = held();
      notifier().clear();

      expect(identical(held(), before), isTrue);
    });
  });
}
