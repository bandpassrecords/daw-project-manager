import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_collection.dart';
import 'package:daw_project_manager/models/midi_collection_drag.dart';
import 'package:daw_project_manager/ui/widgets/midi_collection_tree.dart';

MidiCollectionItem _item(String id, int pitch, {String? folder}) =>
    MidiCollectionItem(
      id: id,
      clip: MidiClip(
        name: id,
        ppq: 480,
        lengthTicks: 1920,
        notes: [
          MidiNote(startTick: 0, lengthTicks: 240, pitch: pitch, velocity: 100),
        ],
      ),
      addedAt: DateTime.utc(2026),
      folderId: folder,
    );

final _basslines = MidiCollection(
  id: 'c1',
  name: 'Basslines',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  folders: const [
    MidiCollectionFolder(id: 'f1', name: 'Acid'),
    MidiCollectionFolder(id: 'f2', name: 'Deep acid', parentId: 'f1'),
  ],
  items: [
    _item('a', 36),
    _item('b', 37),
    _item('c', 38, folder: 'f1'),
    _item('d', 39),
    _item('e', 40),
  ],
);

final _pads = MidiCollection(
  id: 'c2',
  name: 'Pads',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late List<String?> selected;
  late List<(String, String)> selectedFolders;
  late Set<String> expanded;
  late List<(MidiDragData, MidiDropTarget)> drops;
  late int created;

  setUp(() {
    selected = [];
    selectedFolders = [];
    expanded = {};
    drops = [];
    created = 0;
  });

  Widget wrap({String? selectedId, bool horizontal = false, Widget? extra}) =>
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Row(
              children: [
                SizedBox(
                  width: horizontal ? 400 : 240,
                  height: horizontal ? 80 : 600,
                  child: MidiCollectionNavigator(
                    allClipsLabel: 'All clips',
                    allClipsCount: 74,
                    collectionsLabel: 'Collections',
                    newCollectionLabel: 'New collection',
                    collections: [_basslines, _pads],
                    selectedId: selectedId,
                    onSelect: selected.add,
                    onSelectFolder: (c, f) => selectedFolders.add((c, f)),
                    onNew: () => created++,
                    expanded: expanded,
                    onToggle: (id) => setState(() {
                      if (!expanded.remove(id)) expanded.add(id);
                    }),
                    canDrop: (data, target) => canDropMidi(
                      data,
                      target,
                      [
                        _basslines,
                        _pads,
                      ].where((c) => c.id == target.collectionId).firstOrNull,
                    ),
                    onDrop: (data, target) => drops.add((data, target)),
                    expandLabel: 'Expand',
                    collapseLabel: 'Collapse',
                    onExpandAll: () =>
                        setState(() => expanded.addAll(['c1', 'f1', 'f2'])),
                    onCollapseAll: () => setState(expanded.clear),
                    expandAllLabel: 'Expand all',
                    collapseAllLabel: 'Collapse all',
                    horizontal: horizontal,
                  ),
                ),
                ?extra,
              ],
            ),
          ),
        ),
      );

  testWidgets('lists all clips and each collection with counts', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    expect(find.text('All clips'), findsOneWidget);
    expect(find.text('74'), findsOneWidget);
    expect(find.text('Basslines'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('selecting reports the collection, or null for all clips', (
    tester,
  ) async {
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

  testWidgets('a collection opens on its folders, as deep as they go', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    expect(find.text('Acid'), findsNothing);
    expect(
      find.byKey(const ValueKey('midi-toggle-c2')),
      findsNothing,
      reason: 'nothing to open in a collection with no folders',
    );

    await tester.tap(find.byKey(const ValueKey('midi-toggle-c1')));
    await tester.pump();
    expect(find.text('Acid'), findsOneWidget);
    expect(find.text('Deep acid'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('midi-toggle-f1')));
    await tester.pump();
    expect(find.text('Deep acid'), findsOneWidget);

    await tester.tap(find.text('Deep acid'));
    expect(selectedFolders, [('c1', 'f2')]);

    await tester.tap(find.byKey(const ValueKey('midi-toggle-c1')));
    await tester.pump();
    expect(find.text('Acid'), findsNothing, reason: 'closed again');
  });

  testWidgets('rows line up whether or not they have something to open', (
    tester,
  ) async {
    // The toggle is an IconButton, which Material 3 pads to a 40px tap
    // target; the placeholder for a row with nothing to open was 28px, so
    // a collection or folder without children sat 12px left of its peers.
    expanded.addAll(['c1', 'f1']);
    await tester.pumpWidget(wrap());
    double left(String text) => tester.getTopLeft(find.text(text)).dx;

    expect(left('Pads'), left('Basslines'), reason: 'same level, same inset');
    expect(
      left('Deep acid') - left('Acid'),
      left('Acid') - left('Basslines'),
      reason: 'each level is indented by the same step',
    );
    expect(left('Acid'), greaterThan(left('Basslines')));
  });

  testWidgets(
    'a clip dragged onto a folder or another collection drops there',
    (tester) async {
      expanded.add('c1');
      const data = MidiItemDragData(
        collectionId: 'c1',
        itemIds: ['a'],
        label: 'a',
      );
      await tester.pumpWidget(
        wrap(
          extra: Draggable<MidiDragData>(
            data: data,
            feedback: const Text('dragging'),
            child: const SizedBox(width: 60, height: 60, child: Text('clip')),
          ),
        ),
      );

      Future<void> dragTo(Finder target) async {
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('clip')),
        );
        await gesture.moveBy(const Offset(-20, 0));
        await tester.pump();
        await gesture.moveTo(tester.getCenter(target));
        await tester.pump();
        await gesture.up();
        await tester.pump();
      }

      await dragTo(find.text('Acid'));
      await dragTo(find.text('Pads'));
      expect(drops.map((d) => d.$2), [
        const MidiDropTarget('c1', folderId: 'f1'),
        const MidiDropTarget('c2'),
      ]);
    },
  );

  testWidgets('a drag resting on a closed collection opens it', (tester) async {
    await tester.pumpWidget(
      wrap(
        extra: Draggable<MidiDragData>(
          data: const MidiItemDragData(
            collectionId: 'c2',
            itemIds: ['x'],
            label: 'x',
          ),
          feedback: const Text('dragging'),
          child: const SizedBox(width: 60, height: 60, child: Text('clip')),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('clip')),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('Basslines')));
    await tester.pump();
    expect(find.text('Acid'), findsNothing);
    await tester.pump(
      MidiDropZone.holdDelay + const Duration(milliseconds: 50),
    );
    await tester.pump();
    expect(find.text('Acid'), findsOneWidget);
    await gesture.up();
    await tester.pump();
  });

  testWidgets('expand all and collapse all', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.byTooltip('Expand all'));
    await tester.pump();
    expect(find.text('Deep acid'), findsOneWidget);
    await tester.tap(find.byTooltip('Collapse all'));
    await tester.pump();
    expect(find.text('Acid'), findsNothing);
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
