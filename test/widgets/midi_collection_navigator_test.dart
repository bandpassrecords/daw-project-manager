import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/midi_library_page.dart';

void main() {
  late List<String?> selected;
  late int created;

  setUp(() {
    selected = [];
    created = 0;
  });

  Widget wrap({String? selectedId, bool horizontal = false}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: horizontal ? 400 : 240,
            height: horizontal ? 80 : 600,
            child: MidiCollectionNavigator(
              allClipsLabel: 'All clips',
              allClipsCount: 74,
              collectionsLabel: 'Collections',
              newCollectionLabel: 'New collection',
              collections: const [
                (id: 'c1', name: 'Basslines', count: 5),
                (id: 'c2', name: 'Pads', count: 0),
              ],
              selectedId: selectedId,
              onSelect: selected.add,
              onNew: () => created++,
              horizontal: horizontal,
            ),
          ),
        ),
      );

  testWidgets('lists all clips and each collection with counts', (tester) async {
    await tester.pumpWidget(wrap());
    expect(find.text('All clips'), findsOneWidget);
    expect(find.text('74'), findsOneWidget);
    expect(find.text('Basslines'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('selecting reports the collection, or null for all clips',
      (tester) async {
    await tester.pumpWidget(wrap(selectedId: 'c1'));
    await tester.tap(find.text('Pads'));
    await tester.tap(find.text('All clips'));
    expect(selected, ['c2', null]);
  });

  testWidgets('offers a new collection', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.byTooltip('New collection'));
    expect(created, 1);
  });

  testWidgets('on a phone it is a row of chips', (tester) async {
    await tester.pumpWidget(wrap(horizontal: true));
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    // A row of chips scrolls sideways; bring each into view like a thumb would.
    await tester.ensureVisible(find.text('Basslines (5)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basslines (5)'));
    await tester.ensureVisible(find.text('New collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New collection'));
    expect(selected, ['c1']);
    expect(created, 1);
  });
}
