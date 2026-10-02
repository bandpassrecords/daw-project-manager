import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/custom_field.dart';
import 'package:daw_project_manager/ui/widgets/columns_and_fields_settings.dart';
import 'package:daw_project_manager/utils/custom_fields.dart';

void main() {
  final visibilityChanges = <String>[];
  final changedFields = <CustomFieldDefinition>[];
  final edited = <CustomFieldDefinition>[];
  final deleted = <CustomFieldDefinition>[];
  var added = 0;

  setUp(() {
    visibilityChanges.clear();
    changedFields.clear();
    edited.clear();
    deleted.clear();
    added = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    List<CustomFieldDefinition> fields = const [],
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ColumnsAndFieldsSettings(
              columns: normalizeColumnLayout(const []),
              columnLabel: (id) => 'col:$id',
              onColumnVisibleChanged: (id, v) =>
                  visibilityChanges.add('$id=$v'),
              onColumnsReordered: (_, _) {},
              onResetColumns: () {},
              fields: fields,
              onAddField: () => added++,
              onEditField: edited.add,
              onDeleteField: deleted.add,
              onFieldChanged: changedFields.add,
              onFieldsReordered: (_, _) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('lists every configurable built-in column', (tester) async {
    await pump(tester);

    for (final id in kProjectsTableBuiltInColumns) {
      expect(find.text('col:$id'), findsOneWidget);
    }
  });

  testWidgets('switching a column off reports it', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(Switch).at(2)); // bpm
    await tester.pump();

    expect(visibilityChanges, ['bpm=false']);
  });

  testWidgets('says so when there are no custom fields', (tester) async {
    await pump(tester);

    expect(find.text('No custom fields yet.'), findsOneWidget);
    await tester.tap(find.text('Add field'));
    expect(added, 1);
  });

  testWidgets('a field shows its type and where it appears', (tester) async {
    await pump(tester, fields: const [
      CustomFieldDefinition(
        id: 'lufs',
        name: 'LUFS',
        type: CustomFieldType.number,
        showInProjectsTable: false,
        showInReleaseTracks: true,
      ),
      CustomFieldDefinition(
        id: 'notes',
        name: 'Engineer',
        showInProjectsTable: false,
      ),
    ]);

    expect(find.text('Number · Column in release tracklists'), findsOneWidget);
    expect(find.text('Text · Project page only'), findsOneWidget);
  });

  testWidgets('the placement buttons toggle straight from the list',
      (tester) async {
    const field = CustomFieldDefinition(id: 'lufs', name: 'LUFS');
    await pump(tester, fields: const [field]);

    await tester.tap(find.byTooltip('Column in release tracklists'));
    await tester.tap(find.byTooltip('Column in the projects table'));

    expect(changedFields[0].showInReleaseTracks, isTrue);
    expect(changedFields[1].showInProjectsTable, isFalse);
  });

  testWidgets('edit and delete report the field', (tester) async {
    const field = CustomFieldDefinition(id: 'lufs', name: 'LUFS');
    await pump(tester, fields: const [field]);

    await tester.tap(find.byTooltip('Edit field'));
    await tester.tap(find.byTooltip('Delete'));

    expect(edited.single.id, 'lufs');
    expect(deleted.single.id, 'lufs');
  });
}
