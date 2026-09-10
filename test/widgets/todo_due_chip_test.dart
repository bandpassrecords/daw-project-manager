import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/todo_due_chip.dart';
import 'package:daw_project_manager/utils/todo_due_utils.dart';

import '../helpers/test_factories.dart';

/// #113 — the due-date chip and button a todo row carries, in the project/
/// release todo list and in the Task Queue alike. Both take an injectable
/// clock so these don't drift with the wall calendar.
void main() {
  final now = DateTime(2025, 6, 10, 15, 30);

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  group('TodoDueChip', () {
    testWidgets('an overdue date reads as overdue, by how many days',
        (tester) async {
      await tester.pumpWidget(
        wrap(TodoDueChip(dueAt: DateTime(2025, 6, 7), now: now)),
      );

      expect(find.text('3 days overdue'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('one day over is singular', (tester) async {
      await tester.pumpWidget(
        wrap(TodoDueChip(dueAt: DateTime(2025, 6, 9), now: now)),
      );

      expect(find.text('1 day overdue'), findsOneWidget);
    });

    testWidgets('today and tomorrow are named, not dated', (tester) async {
      await tester.pumpWidget(
        wrap(TodoDueChip(dueAt: DateTime(2025, 6, 10), now: now)),
      );
      expect(find.text('Due today'), findsOneWidget);
      expect(find.byIcon(Icons.today), findsOneWidget);

      await tester.pumpWidget(
        wrap(TodoDueChip(dueAt: DateTime(2025, 6, 11), now: now)),
      );
      expect(find.text('Due tomorrow'), findsOneWidget);
    });

    testWidgets('anything further out shows the date', (tester) async {
      await tester.pumpWidget(
        wrap(TodoDueChip(dueAt: DateTime(2025, 7, 4), now: now)),
      );

      expect(find.text('Due Jul 4'), findsOneWidget);
    });

    testWidgets('overdue and due-today are visually distinct from each other',
        (tester) async {
      // The whole point of the chip: at a glance, "late" must not look like
      // "due now", and neither must look like a date weeks out.
      Color colorOf(WidgetTester tester) =>
          tester.widget<Text>(find.byType(Text).first).style!.color!;

      await tester.pumpWidget(
        wrap(TodoDueChip(dueAt: DateTime(2025, 6, 1), now: now)),
      );
      final overdue = colorOf(tester);

      await tester.pumpWidget(
        wrap(TodoDueChip(dueAt: DateTime(2025, 6, 10), now: now)),
      );
      final today = colorOf(tester);

      await tester.pumpWidget(
        wrap(TodoDueChip(dueAt: DateTime(2025, 12, 1), now: now)),
      );
      final upcoming = colorOf(tester);

      expect(overdue, isNot(today));
      expect(today, isNot(upcoming));
      expect(overdue, isNot(upcoming));
    });

    testWidgets('a completed todo is not shouted at for being late',
        (tester) async {
      await tester.pumpWidget(
        wrap(TodoDueChip(dueAt: DateTime(2025, 6, 1), now: now, muted: true)),
      );

      final style = tester.widget<Text>(find.byType(Text).first).style!;
      expect(style.color, isNot(todoDueColor(
        tester.element(find.byType(TodoDueChip)),
        TodoDueStatus.overdue,
      )));
    });
  });

  group('TodoDueButton', () {
    testWidgets('offers to set a date when the todo has none', (tester) async {
      await tester.pumpWidget(wrap(TodoDueButton(
        todo: TestFactories.makeTodo(),
        onDueDateChanged: (_) {},
      )));

      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
      expect(find.byType(PopupMenuButton<dynamic>), findsNothing);
    });

    testWidgets('offers change and clear once a date is set', (tester) async {
      await tester.pumpWidget(wrap(TodoDueButton(
        todo: TestFactories.makeTodo(dueAt: DateTime(2025, 6, 20)),
        onDueDateChanged: (_) {},
        now: now,
      )));

      await tester.tap(find.byIcon(Icons.event_available));
      await tester.pumpAndSettle();

      expect(find.text('Set due date'), findsOneWidget);
      expect(find.text('Clear due date'), findsOneWidget);
    });

    testWidgets('clearing reports null', (tester) async {
      DateTime? reported = DateTime(2025, 6, 20);
      var called = false;

      await tester.pumpWidget(wrap(TodoDueButton(
        todo: TestFactories.makeTodo(dueAt: DateTime(2025, 6, 20)),
        onDueDateChanged: (dueAt) {
          reported = dueAt;
          called = true;
        },
        now: now,
      )));

      await tester.tap(find.byIcon(Icons.event_available));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear due date'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(reported, isNull);
    });

    testWidgets('picking a date reports it at midnight', (tester) async {
      // A stray time component would make "due today" depend on the hour the
      // date was picked.
      DateTime? reported;

      await tester.pumpWidget(wrap(TodoDueButton(
        todo: TestFactories.makeTodo(),
        onDueDateChanged: (dueAt) => reported = dueAt,
      )));

      await tester.tap(find.byIcon(Icons.event_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(reported!.hour, 0);
      expect(reported!.minute, 0);
      expect(reported!.second, 0);
    });

    testWidgets('reopens without asserting on an already-overdue todo',
        (tester) async {
      // showDatePicker asserts initialDate >= firstDate; anchoring firstDate
      // at today would throw the moment someone reopened an overdue todo.
      await tester.pumpWidget(wrap(TodoDueButton(
        todo: TestFactories.makeTodo(
          dueAt: DateTime.now().subtract(const Duration(days: 90)),
        ),
        onDueDateChanged: (_) {},
      )));

      await tester.tap(find.byIcon(Icons.event_available));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set due date'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('OK'), findsOneWidget);
    });
  });
}
