import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_collection.dart';
import 'package:daw_project_manager/models/midi_collection_drag.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';
import 'package:daw_project_manager/ui/widgets/midi_clip_list.dart';
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

final _pack = MidiCollection(
  id: 'c',
  name: 'Pack',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  folders: const [
    MidiCollectionFolder(id: 'bass', name: 'Bass'),
    MidiCollectionFolder(id: 'acid', name: 'Acid', parentId: 'bass'),
    MidiCollectionFolder(id: 'pads', name: 'Pads'),
  ],
  items: [
    _item('top', 60),
    _item('line', 36, folder: 'bass'),
    _item('squelch', 37, folder: 'acid'),
  ],
);

void main() {
  late Set<String> expanded;
  late List<(MidiDragData, MidiDropTarget)> drops;
  late List<String> picked;

  setUp(() {
    expanded = {};
    drops = [];
    picked = [];
  });

  Widget tree({String? root}) => MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: MidiCollectionTree(
            collection: _pack,
            rootFolderId: root,
            expanded: expanded,
            onToggle: (id) => setState(() {
              if (!expanded.remove(id)) expanded.add(id);
            }),
            clipsIn: (context, folderId) {
              final here = _pack.itemsIn(folderId);
              if (here.isEmpty) return null;
              return Column(
                children: [
                  for (final i in here)
                    MidiDropZone(
                      target: MidiDropTarget(
                        'c',
                        folderId: folderId,
                        beforeItemId: i.id,
                      ),
                      canDrop: (d, t) => canDropMidi(d, t, _pack),
                      onDrop: (d, t) => drops.add((d, t)),
                      lineAbove: true,
                      child: SizedBox(height: 40, child: Text('clip ${i.id}')),
                    ),
                ],
              );
            },
            folderActions: (f) => [
              MidiClipRowAction(
                id: 'rename',
                label: 'Rename',
                icon: Icons.edit,
                onSelected: () => picked.add('rename ${f.id}'),
              ),
            ],
            canDrop: (d, t) => canDropMidi(d, t, _pack),
            onDrop: (d, t) => drops.add((d, t)),
            expandLabel: 'Expand',
            collapseLabel: 'Collapse',
            moreLabel: 'More',
          ),
        ),
      ),
    ),
  );

  testWidgets('folders open and close on their folders and clips', (
    tester,
  ) async {
    await tester.pumpWidget(tree());
    expect(find.text('Bass'), findsOneWidget);
    expect(find.text('Pads'), findsOneWidget);
    expect(
      find.text('clip top'),
      findsOneWidget,
      reason: 'top-level clips show',
    );
    expect(find.text('clip line'), findsNothing);
    expect(
      find.byKey(const ValueKey('midi-toggle-pads')),
      findsNothing,
      reason: 'an empty folder has nothing to open',
    );

    await tester.tap(find.text('Bass'));
    await tester.pump();
    expect(find.text('Acid'), findsOneWidget);
    expect(find.text('clip line'), findsOneWidget);
    expect(find.text('clip squelch'), findsNothing);
    expect(
      tester.getTopLeft(find.text('clip line')).dx,
      greaterThan(tester.getTopLeft(find.text('clip top')).dx),
      reason: 'indented under its folder',
    );

    await tester.tap(find.byKey(const ValueKey('midi-toggle-acid')));
    await tester.pump();
    expect(find.text('clip squelch'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('midi-toggle-bass')));
    await tester.pump();
    expect(find.text('Acid'), findsNothing);
    expect(find.text('clip squelch'), findsNothing);
  });

  testWidgets('starting inside a folder shows what is in it', (tester) async {
    await tester.pumpWidget(tree(root: 'bass'));
    expect(find.text('Bass'), findsNothing);
    expect(find.text('Acid'), findsOneWidget);
    expect(find.text('clip line'), findsOneWidget);
    expect(find.text('clip top'), findsNothing);
  });

  Future<void> drag(WidgetTester tester, Finder from, Finder to) async {
    final gesture = await tester.startGesture(tester.getCenter(from));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(to));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a folder dragged onto another moves into it, never into itself',
    (tester) async {
      await tester.pumpWidget(tree());
      await drag(tester, find.text('Pads'), find.text('Bass'));
      expect(drops.single.$1, isA<MidiFolderDragData>());
      expect(drops.single.$2, const MidiDropTarget('c', folderId: 'bass'));

      expanded.add('bass');
      await tester.pumpWidget(tree());
      await drag(tester, find.text('Bass'), find.text('Acid'));
      expect(drops, hasLength(1), reason: 'Acid is inside Bass');
    },
  );

  testWidgets('a drag resting on a closed folder opens it', (tester) async {
    await tester.pumpWidget(tree());
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Pads')),
    );
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('Bass')));
    await tester.pump();
    expect(find.text('Acid'), findsNothing);
    await tester.pump(
      MidiDropZone.holdDelay + const Duration(milliseconds: 50),
    );
    await tester.pump();
    expect(find.text('Acid'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets("a folder's menu lists the caller's actions", (tester) async {
    await tester.pumpWidget(tree());
    await tester.tap(find.byKey(const ValueKey('midi-folder-menu-pads')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('midi-folder-action-rename')));
    await tester.pumpAndSettle();
    expect(picked, ['rename pads']);
  });

  group('MidiClipList drag hooks', () {
    testWidgets('groups the caller keeps open or closed stay that way', (
      tester,
    ) async {
      final kept = <String?, bool>{'Song B': true};
      final clips = [
        for (final (i, song) in ['Song A', 'Song B'].indexed)
          MidiClip(
            name: 'clip $i',
            trackName: song,
            ppq: 480,
            lengthTicks: 1920,
            notes: [
              MidiNote(
                startTick: 0,
                lengthTicks: 240,
                pitch: 60 + i,
                velocity: 100,
              ),
            ],
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MidiClipList(
                clips: clips,
                compact: true,
                expandAllUpTo: 0, // closed by default
                labels: MidiClipListLabels(
                  play: 'Play',
                  stop: 'Stop',
                  save: 'Save',
                  share: 'Share',
                  instrument: (n) => n,
                  voiceName: (v) => v.name,
                  dragTooltip: 'Drag',
                  bars: (n) => '$n bars',
                  notes: (n) => '$n notes',
                  usedTimes: (n) => '$n',
                  alsoAs: (n) => n,
                  noTrack: '',
                  expandTrack: '',
                  collapseTrack: '',
                ),
                onPlay: (_) {},
                onShare: (_, _) {},
                voiceOf: (_) => SynthVoice.bass,
                onVoiceChanged: (_, _) {},
                groupOpen: (label) => kept[label],
                onGroupToggled: (label, open) =>
                    setState(() => kept[label] = open),
              ),
            ),
          ),
        ),
      );
      expect(find.text('clip 0'), findsNothing, reason: 'the default: closed');
      expect(find.text('clip 1'), findsOneWidget, reason: 'kept open');
      await tester.tap(find.text('Song A'));
      await tester.pump();
      expect(kept['Song A'], isTrue);
      expect(find.text('clip 0'), findsOneWidget);
    });

    testWidgets('a row dragged onto another drops just before it', (
      tester,
    ) async {
      final dropped = <(MidiDragData, MidiDropTarget)>[];
      final clips = [_pack.items[0].clip, _pack.items[1].clip];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MidiClipList(
              clips: clips,
              grouped: false,
              compact: true,
              labels: MidiClipListLabels(
                play: 'Play',
                stop: 'Stop',
                save: 'Save',
                share: 'Share',
                instrument: (n) => n,
                voiceName: (v) => v.name,
                dragTooltip: 'Drag',
                bars: (n) => '$n bars',
                notes: (n) => '$n notes',
                usedTimes: (n) => '$n',
                alsoAs: (n) => n,
                noTrack: '',
                expandTrack: '',
                collapseTrack: '',
              ),
              onPlay: (_) {},
              onShare: (_, _) {},
              voiceOf: (_) => SynthVoice.bass,
              onVoiceChanged: (_, _) {},
              grabWrapper: (context, i, child) => midiDragSource(
                data: MidiItemDragData(
                  collectionId: 'c',
                  itemIds: [_pack.items[i].id],
                  label: clips[i].name,
                ),
                child: child,
              ),
              rowWrapper: (context, i, row) => MidiDropZone(
                target: MidiDropTarget('c', beforeItemId: _pack.items[i].id),
                canDrop: (d, t) => canDropMidi(d, t, _pack),
                onDrop: (d, t) => dropped.add((d, t)),
                lineAbove: true,
                child: row,
              ),
            ),
          ),
        ),
      );
      await drag(tester, find.text('line'), find.text('top'));
      expect(dropped.single.$2, const MidiDropTarget('c', beforeItemId: 'top'));
      expect((dropped.single.$1 as MidiItemDragData).itemIds, ['line']);

      await drag(tester, find.text('top'), find.text('top').first);
      expect(dropped, hasLength(1), reason: 'not before itself');
    });
  });
}
