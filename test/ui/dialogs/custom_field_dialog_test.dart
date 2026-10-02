import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/custom_field.dart';
import 'package:daw_project_manager/ui/dialogs/custom_field_dialog.dart';

void main() {
  late List<CustomFieldDefinition?> results;

  setUp(() => results = []);

  Future<void> pump(
    WidgetTester tester, {
    CustomFieldDefinition? existing,
    List<CustomFieldDefinition> active = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                results.add(await showCustomFieldDialog(
                  context,
                  existing: existing,
                  active: active,
                ));
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('creates a number field with the chosen placement',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), ' LUFS ');
    await tester.tap(find.text('Number'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Column in release tracklists'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final field = results.single!;
    expect(field.name, 'LUFS');
    expect(field.type, CustomFieldType.number);
    expect(field.showInProjectsTable, isTrue);
    expect(field.showInReleaseTracks, isTrue);
    expect(field.id, isNotEmpty);
  });

  testWidgets('explains what the number type does', (tester) async {
    await pump(tester);
    expect(find.textContaining('sort by value'), findsNothing);

    await tester.tap(find.text('Number'));
    await tester.pumpAndSettle();

    expect(find.textContaining('sort by value'), findsOneWidget);
  });

  testWidgets('refuses an empty name', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name'), findsOneWidget);
    expect(results, isEmpty, reason: 'the dialog stays open');
  });

  testWidgets('refuses a name another field already has', (tester) async {
    await pump(tester,
        active: const [CustomFieldDefinition(id: 'a', name: 'LUFS')]);

    await tester.enterText(find.byType(TextField), 'lufs');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('A field with this name already exists'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('editing keeps the id, so the values stay attached',
      (tester) async {
    const existing = CustomFieldDefinition(id: 'keep-me', name: 'Loudness');
    await pump(tester, existing: existing, active: const [existing]);

    await tester.enterText(find.byType(TextField), 'LUFS');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(results.single!.id, 'keep-me');
    expect(results.single!.name, 'LUFS');
  });

  testWidgets('cancel returns nothing', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });
}
