import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/custom_field.dart';
import 'package:daw_project_manager/ui/widgets/custom_fields_editor.dart';

void main() {
  const lufs = CustomFieldDefinition(
      id: 'lufs', name: 'LUFS', type: CustomFieldType.number);
  const engineer = CustomFieldDefinition(id: 'eng', name: 'Engineer');

  late List<String> saved;

  setUp(() => saved = []);

  Widget app(Map<String, String> values) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              CustomFieldsEditor(
                fields: const [lufs, engineer],
                values: values,
                onChanged: (id, value) => saved.add('$id=$value'),
              ),
              // Somewhere else to put the focus.
              const TextField(key: ValueKey('elsewhere')),
            ],
          ),
        ),
      );

  Finder field(String id) => find.byKey(ValueKey('custom-field-$id'));

  testWidgets('shows each field labelled, with its stored value',
      (tester) async {
    await tester.pumpWidget(app({'lufs': '-14.2'}));

    expect(find.text('LUFS'), findsOneWidget);
    expect(find.text('Engineer'), findsOneWidget);
    expect(find.text('-14.2'), findsOneWidget);
  });

  testWidgets('saves once typing pauses', (tester) async {
    await tester.pumpWidget(app(const {}));

    await tester.enterText(field('eng'), 'Ana');
    expect(saved, isEmpty);
    await tester.pump(const Duration(milliseconds: 450));

    expect(saved, ['eng=Ana']);
  });

  testWidgets('a number field refuses and flags something that is not one',
      (tester) async {
    await tester.pumpWidget(app(const {}));

    await tester.enterText(field('lufs'), '-14 dB');
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Enter a number'), findsOneWidget);
    expect(saved, isEmpty);
  });

  testWidgets('clearing a field saves an empty value', (tester) async {
    await tester.pumpWidget(app({'eng': 'Ana'}));

    await tester.enterText(field('eng'), '');
    await tester.pump(const Duration(milliseconds: 450));

    expect(saved, ['eng=']);
  });

  testWidgets('leaving a field saves at once', (tester) async {
    await tester.pumpWidget(app(const {}));

    await tester.tap(field('lufs'));
    await tester.enterText(field('lufs'), '-9,8');
    await tester.tap(find.byKey(const ValueKey('elsewhere')));
    await tester.pump();

    expect(saved, ['lufs=-9,8']);
    await tester.pump(const Duration(milliseconds: 450));
    expect(saved, ['lufs=-9,8'], reason: 'the debounce does not save it twice');
  });

  testWidgets('follows a value changed elsewhere while not being edited',
      (tester) async {
    await tester.pumpWidget(app({'eng': 'Ana'}));

    await tester.pumpWidget(app({'eng': 'Bia'}));

    expect(find.text('Bia'), findsOneWidget);
  });
}
