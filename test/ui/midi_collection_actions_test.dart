import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/midi_collection_actions.dart';

void main() {
  late List<String?> results;

  setUp(() => results = []);

  Widget app({String initial = ''}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(await promptCollectionName(
                context,
                title: 'New collection',
                action: 'Create',
                initial: initial,
              )),
              child: const Text('open'),
            ),
          ),
        ),
      );

  // Regression: the controller was disposed as soon as the dialog returned,
  // while the dialog was still animating out — "A TextEditingController was
  // used after being disposed" on every Create, Enter or Cancel.
  testWidgets('creating closes the dialog cleanly and returns the trimmed name',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Basslines ');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(results, ['Basslines']);
  });

  testWidgets('Enter submits, also without leaving a disposed controller behind',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Pads');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(results, ['Pads']);
  });

  testWidgets('cancelling returns null and closes cleanly', (tester) async {
    await tester.pumpWidget(app(initial: 'Old name'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(results, [null]);
  });

  testWidgets('a blank name cannot be confirmed', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    final create = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Create'));
    expect(create.onPressed, isNull);
  });

  testWidgets('a rename starts from the current name', (tester) async {
    await tester.pumpWidget(app(initial: 'Old name'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Old name'), findsOneWidget);
  });
}
