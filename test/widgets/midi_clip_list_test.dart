import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';
import 'package:daw_project_manager/ui/widgets/midi_clip_list.dart';

/// The list is a plain view: it owns no player and writes no files, so every
/// state here runs without audio or a file system. The OS drag (which needs a
/// native plugin) is injected by the page through `dragHandleBuilder`.
void main() {
  final labels = MidiClipListLabels(
    play: 'Play',
    stop: 'Stop',
    save: 'Save',
    share: 'Share',
    instrument: (name) => 'Instrument: $name',
    voiceName: (v) => v.name,
    dragTooltip: 'Drag',
    bars: (n) => n == 1 ? '1 bar' : '$n bars',
    notes: (n) => n == 1 ? '1 note' : '$n notes',
    usedTimes: (n) => 'Used $n×',
    alsoAs: (names) => 'Also: $names',
    noTrack: 'Other clips',
    expandTrack: 'Show track',
    collapseTrack: 'Hide track',
    addToCollection: 'Add to collection',
    removeFromCollection: 'Remove',
    more: 'More',
  );

  MidiClip clip(String name, {String? track, int occurrences = 1, int beats = 16}) =>
      MidiClip(
        name: name,
        trackName: track,
        ppq: 480,
        lengthTicks: beats * 480,
        occurrences: occurrences,
        notes: const [
          MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100),
          MidiNote(startTick: 480, lengthTicks: 240, pitch: 64, velocity: 100),
        ],
      );

  late List<int> played;
  late List<int> saved;
  late List<int> shared;
  late List<(int, SynthVoice)> voiceChanges;
  late List<int> added;
  late List<int> removed;

  setUp(() {
    added = [];
    removed = [];
    played = [];
    saved = [];
    shared = [];
    voiceChanges = [];
  });

  Widget wrap(
    List<MidiClip> clips, {
    int? playing,
    int? preparing,
    bool draggable = false,
    bool canSave = true,
    int expandAllUpTo = 12,
    bool compact = false,
    bool grouped = true,
    bool collectionActions = false,
    String? Function(int)? groupLabelOf,
    String? Function(int)? detailPrefixOf,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MidiClipList(
              clips: clips,
              labels: labels,
              playingIndex: playing,
              preparingIndex: preparing,
              onPlay: played.add,
              onSave: canSave ? saved.add : null,
              onShare: (i, _) => shared.add(i),
              voiceOf: (i) => i.isEven ? SynthVoice.bass : SynthVoice.pad,
              onVoiceChanged: (i, v) => voiceChanges.add((i, v)),
              compact: compact,
              grouped: grouped,
              groupLabelOf: groupLabelOf,
              detailPrefixOf: detailPrefixOf,
              onAddToCollection:
                  collectionActions ? (i, _) => added.add(i) : null,
              onRemove: collectionActions ? removed.add : null,
              expandAllUpTo: expandAllUpTo,
              dragHandleBuilder: draggable
                  ? (context, index, handle) =>
                      KeyedSubtree(key: ValueKey('drag-$index'), child: handle)
                  : null,
            ),
          ),
        ),
      );

  testWidgets('lists clips under a header per track, with a count',
      (tester) async {
    await tester.pumpWidget(wrap([
      clip('MIDI 01', track: 'Bassline'),
      clip('MIDI 02', track: 'Lead'),
      clip('MIDI 03', track: 'Bassline'),
      clip('Loose'),
    ]));

    expect(find.text('Bassline'), findsOneWidget);
    expect(find.text('Lead'), findsOneWidget);
    expect(find.text('Other clips'), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: 'Bassline has two clips');

    // Headers come before their own clips, in first-seen track order.
    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(y('Bassline') < y('MIDI 01'), isTrue);
    expect(y('MIDI 03') < y('Lead'), isTrue);
    expect(y('MIDI 02') < y('Other clips'), isTrue);
  });

  testWidgets('a row shows length, notes and reuse; the track is the header',
      (tester) async {
    await tester.pumpWidget(wrap([
      clip('Bassline', track: 'Serum 01', occurrences: 3, beats: 15),
    ]));

    expect(find.text('Bassline'), findsOneWidget);
    expect(find.text('4 bars · 2 notes · Used 3×'), findsOneWidget,
        reason: '15 beats rounds up to 4 bars; no track in the subtitle');
  });

  testWidgets('names the clips that were merged into an entry', (tester) async {
    await tester.pumpWidget(wrap([
      clip('Riff', track: 'Synth A').copyWith(
        otherNames: ['Synth B – Riff copy', 'Synth C'],
      ),
      clip('Solo', track: 'Synth A'),
    ]));

    expect(find.byTooltip('Also: Synth B – Riff copy, Synth C'), findsOneWidget);
    expect(
      find.byType(Tooltip).evaluate().where(
          (e) => (e.widget as Tooltip).message?.startsWith('Also:') ?? false),
      hasLength(1),
      reason: 'an unmerged clip gets no tooltip',
    );
  });

  testWidgets('a long list starts collapsed to its track headers',
      (tester) async {
    await tester.pumpWidget(wrap([
      clip('A1', track: 'Drums'),
      clip('A2', track: 'Drums'),
      clip('B1', track: 'Keys'),
    ], expandAllUpTo: 2));

    expect(find.text('Drums'), findsOneWidget);
    expect(find.text('Keys'), findsOneWidget);
    expect(find.text('A1'), findsNothing);

    await tester.tap(find.text('Drums'));
    await tester.pump();
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('B1'), findsNothing, reason: 'only the tapped track opens');
  });

  testWidgets('a short list starts open, and a header tap folds its track',
      (tester) async {
    await tester.pumpWidget(wrap([
      clip('A1', track: 'Drums'),
      clip('B1', track: 'Keys'),
    ]));

    expect(find.text('A1'), findsOneWidget);
    await tester.tap(find.text('Drums'));
    await tester.pump();
    expect(find.text('A1'), findsNothing);
    expect(find.text('B1'), findsOneWidget);
  });

  testWidgets('play and save report the clip index across groups',
      (tester) async {
    // Grouping reorders rows on screen; callbacks must still name the clip's
    // index in the list the page passed in.
    await tester.pumpWidget(wrap([
      clip('A', track: 'One'),
      clip('B', track: 'Two'),
      clip('C', track: 'One'),
    ]));

    await tester.tap(find.byTooltip('Play').at(1)); // 'C', shown second
    await tester.tap(find.byTooltip('Save').last); // 'B', shown last
    expect(played, [2]);
    expect(saved, [1]);
  });

  testWidgets('the playing clip offers stop instead of play', (tester) async {
    await tester.pumpWidget(wrap([clip('A'), clip('B')], playing: 0));

    expect(find.byTooltip('Stop'), findsOneWidget);
    expect(find.byTooltip('Play'), findsOneWidget);
    await tester.tap(find.byTooltip('Stop'));
    expect(played, [0], reason: 'the page decides that a second tap stops');
  });

  testWidgets('a clip being rendered shows a spinner instead of play',
      (tester) async {
    await tester.pumpWidget(wrap([clip('A')], preparing: 0));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Play'), findsNothing);
  });

  testWidgets('drag handles appear only when the page provides drag',
      (tester) async {
    await tester.pumpWidget(wrap([clip('A')]));
    expect(find.byTooltip('Drag'), findsNothing);

    await tester.pumpWidget(wrap([clip('A'), clip('B')], draggable: true));
    expect(find.byKey(const ValueKey('drag-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('drag-1')), findsOneWidget);
  });

  testWidgets('share reports the clip; save can be left out', (tester) async {
    await tester.pumpWidget(wrap([clip('A'), clip('B')], canSave: false));

    expect(find.byTooltip('Save'), findsNothing);
    await tester.tap(find.byTooltip('Share').last);
    expect(shared, [1]);
  });

  testWidgets('each clip shows its instrument and can switch it',
      (tester) async {
    await tester.pumpWidget(wrap([clip('A'), clip('B')]));

    expect(find.byTooltip('Instrument: bass'), findsOneWidget);
    expect(find.byTooltip('Instrument: pad'), findsOneWidget);

    await tester.tap(find.byTooltip('Instrument: pad'));
    await tester.pumpAndSettle();
    // The menu opens aligned on the current voice, so pick one just below it.
    await tester.tap(find.text('keys').last);
    await tester.pumpAndSettle();
    expect(voiceChanges, [(1, SynthVoice.keys)]);
  });

  testWidgets('groups by any label, with a details prefix per row',
      (tester) async {
    final clips = [clip('Riff', track: 'Bass'), clip('Pad', track: 'Keys')];
    await tester.pumpWidget(wrap(
      clips,
      groupLabelOf: (i) => i == 0 ? 'Song A' : 'Song B',
      detailPrefixOf: (i) => clips[i].trackName,
    ));

    expect(find.text('Song A'), findsOneWidget);
    expect(find.text('Song B'), findsOneWidget);
    expect(find.text('Bass · 4 bars · 2 notes'), findsOneWidget);
  });

  testWidgets('ungrouped lists rows only, in order', (tester) async {
    await tester.pumpWidget(wrap(
      [clip('One', track: 'X'), clip('Two', track: 'Y')],
      grouped: false,
    ));
    expect(find.text('X'), findsNothing, reason: 'no headers');
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('collection actions report the clip', (tester) async {
    await tester.pumpWidget(wrap([clip('A'), clip('B')], collectionActions: true));
    await tester.tap(find.byTooltip('Add to collection').last);
    await tester.tap(find.byTooltip('Remove').first);
    expect(added, [1]);
    expect(removed, [0]);
  });

  testWidgets('compact rows keep play and fold the rest into More',
      (tester) async {
    await tester.pumpWidget(wrap([clip('A')], compact: true, collectionActions: true));

    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.byTooltip('Share'), findsNothing);
    expect(find.byTooltip('Add to collection'), findsNothing);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to collection'));
    await tester.pumpAndSettle();
    expect(added, [0]);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(shared, [0]);
  });

  testWidgets('compact instrument choice goes through a dialog', (tester) async {
    await tester.pumpWidget(wrap([clip('A')], compact: true));
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instrument: bass'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('organ'));
    await tester.pumpAndSettle();
    expect(voiceChanges, [(0, SynthVoice.organ)]);
  });
}
