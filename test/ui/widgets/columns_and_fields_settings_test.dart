import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/custom_field.dart';
import 'package:daw_project_manager/ui/widgets/columns_and_fields_settings.dart';
import 'package:daw_project_manager/utils/custom_fields.dart';

void main() {
  final visibilityChanges = <String>[];
  final tracksChanges = <String>[];
  final changedFields = <CustomFieldDefinition>[];
  final edited = <CustomFieldDefinition>[];
  final deleted = <CustomFieldDefinition>[];
  var added = 0;

  setUp(() {
    visibilityChanges.clear();
    tracksChanges.clear();
    changedFields.clear();
    edited.clear();
    deleted.clear();
    added = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    List<CustomFieldDefinition> fields = const [],
    double width = 1200,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
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
              onColumnInReleaseTracksChanged: (id, v) =>
                  tracksChanges.add('$id=$v'),
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

  testWidgets('each table has its own checkbox per column', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('column-bpm-projects')));
    await tester.tap(find.byKey(const ValueKey('column-bpm-tracks')));
    // Tags start off in release tracklists: ticking turns it on there.
    await tester.tap(find.byKey(const ValueKey('column-tags-tracks')));
    await tester.pump();

    expect(visibilityChanges, ['bpm=false']);
    expect(tracksChanges, ['bpm=false', 'tags=true']);
  });

  testWidgets('the checkbox columns are headed by the table they stand for',
      (tester) async {
    await pump(tester, fields: const [
      CustomFieldDefinition(id: 'lufs', name: 'LUFS'),
    ]);
    // Over the built-in columns and over the custom fields.
    expect(find.text('Projects'), findsNWidgets(2));
    expect(find.text('Release tracks'), findsNWidgets(2));
  });

  testWidgets('every other row is shaded', (tester) async {
    await pump(tester);
    final rows = tester.widgetList<StripedRow>(find.byType(StripedRow)).toList();
    expect(rows, hasLength(kProjectsTableBuiltInColumns.length));
    Color? colorOf(int i) => tester
        .widget<Material>(find
            .descendant(of: find.byWidget(rows[i]), matching: find.byType(Material))
            .first)
        .color;
    expect(colorOf(0), Colors.transparent);
    expect(colorOf(1), isNot(Colors.transparent));
    expect(colorOf(2), Colors.transparent);
    expect(colorOf(3), colorOf(1));
  });

  testWidgets('fits a phone without overflowing', (tester) async {
    await pump(tester, width: 360, fields: const [
      CustomFieldDefinition(id: 'lufs', name: 'Loudness (integrated LUFS)'),
    ]);
    expect(tester.takeException(), isNull);
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

    // Where it shows is the checkboxes' job; the subtitle says the type, and
    // that a field nowhere in a table lives on the project page only.
    expect(find.text('Number'), findsOneWidget);
    expect(find.text('Text · Project page only'), findsOneWidget);
  });

  testWidgets('the placement buttons toggle straight from the list',
      (tester) async {
    const field = CustomFieldDefinition(id: 'lufs', name: 'LUFS');
    await pump(tester, fields: const [field]);

    await tester.tap(find.byKey(const ValueKey('field-lufs-tracks')));
    await tester.tap(find.byKey(const ValueKey('field-lufs-projects')));

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
