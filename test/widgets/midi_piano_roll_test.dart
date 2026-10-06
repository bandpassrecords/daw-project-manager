import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/ui/midi_piano_roll_dialog.dart';
import 'package:daw_project_manager/ui/midi_preview_player.dart';
import 'package:daw_project_manager/ui/widgets/midi_clip_edit_controller.dart';
import 'package:daw_project_manager/ui/widgets/midi_piano_roll.dart';
import 'package:daw_project_manager/utils/musical_scale.dart';

String _laneName(MidiLane lane) => lane.isVelocity
    ? 'Velocity'
    : lane.kind == MidiEventKind.controller
        ? 'CC ${lane.number}'
        : lane.kind!.name;

String _scaleTypeName(ScaleType type) => type.name;

const _labels = MidiPianoRollLabels(
  zoomIn: 'Zoom in',
  zoomOut: 'Zoom out',
  fit: 'Fit',
  follow: 'Follow',
  lane: 'Lane',
  laneNone: 'None',
  laneName: _laneName,
  scale: 'Scale',
  scaleNone: 'No scale',
  scaleRoot: 'Root',
  scaleType: 'Type',
  scaleTypeName: _scaleTypeName,
);

const _expressive = MidiClip(
  name: 'Lead',
  ppq: 480,
  lengthTicks: 1920,
  notes: [
    MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: 100),
    MidiNote(startTick: 960, lengthTicks: 480, pitch: 64, velocity: 70),
  ],
  events: [
    MidiEvent(tick: 0, kind: MidiEventKind.program, value: 4),
    MidiEvent(tick: 0, kind: MidiEventKind.controller, number: 74, value: 20),
    MidiEvent(tick: 0, kind: MidiEventKind.controller, number: 1, value: 0),
    MidiEvent(tick: 240, kind: MidiEventKind.pitchBend, value: 12000),
    MidiEvent(tick: 480, kind: MidiEventKind.controller, number: 1, value: 90),
    MidiEvent(tick: 500, kind: MidiEventKind.channelPressure, value: 30),
    MidiEvent(
        tick: 960, kind: MidiEventKind.polyPressure, number: 64, value: 50),
  ],
);

MidiClip _clip({int bars = 4}) => MidiClip(
      name: 'Riff',
      trackName: 'Bass',
      ppq: 480,
      lengthTicks: bars * 1920,
      notes: [
        for (var i = 0; i < bars * 4; i++)
          MidiNote(startTick: i * 480, lengthTicks: 240, pitch: 36 + i % 7, velocity: 40 + i * 5),
      ],
    );

void main() {
  group('helpers', () {
    test('note names put middle C at C3', () {
      expect(midiNoteName(60), 'C3');
      expect(midiNoteName(61), 'C#3');
      expect(midiNoteName(0), 'C-2');
      expect(midiNoteName(127), 'G8');
    });

    test("the keyboard names only the C's, however far it is zoomed", () {
      for (final rowHeight in [14.0, 28.0]) {
        expect([for (var p = 60; p < 72; p++) showsKeyName(p, rowHeight)],
            [true, ...List.filled(11, false)],
            reason: 'rows $rowHeight px tall');
      }
      // Squeezed: not even the C's fit.
      expect(showsKeyName(60, 6), isFalse);
    });

    test('a note shows its name once there is room, across and down', () {
      // "C#3" at the labels' size is about 20 px wide.
      expect(noteLabelFits(noteWidth: 60, rowHeight: 18, labelWidth: 20), isTrue);
      expect(noteLabelFits(noteWidth: 60, rowHeight: 12, labelWidth: 20), isFalse,
          reason: 'too short a row: zoom in vertically');
      expect(noteLabelFits(noteWidth: 24, rowHeight: 18, labelWidth: 20), isFalse,
          reason: 'too short a note: zoom in horizontally');
      expect(noteLabelFits(noteWidth: 26, rowHeight: 13, labelWidth: 20), isTrue,
          reason: 'just fits: the label plus its padding on both sides');
    });

    test('the name is dark on a loud note, light on a quiet one', () {
      expect(noteLabelColor(1.0), noteLabelColor(0.8));
      expect(noteLabelColor(0.4), isNot(noteLabelColor(1.0)));
      expect(noteLabelColor(0.4).computeLuminance(),
          greaterThan(noteLabelColor(1.0).computeLuminance()));
    });

    test("a note's edges: its outer quarter, at most 8 px, the end first", () {
      expect(noteEdgeAt(x: 103, left: 100, right: 200), NoteEdge.start);
      expect(noteEdgeAt(x: 150, left: 100, right: 200), isNull);
      expect(noteEdgeAt(x: 195, left: 100, right: 200), NoteEdge.end);
      expect(noteEdgeAt(x: 203, left: 100, right: 200), NoteEdge.end,
          reason: 'just past the end still catches it');
      expect(noteEdgeAt(x: 109, left: 100, right: 200), isNull,
          reason: 'never more than 8 px in');
      // A 12 px note: a 3 px edge each side, the middle still a move.
      expect(noteEdgeAt(x: 106, left: 100, right: 112), isNull);
      expect(noteEdgeAt(x: 110, left: 100, right: 112), NoteEdge.end);
      // A 2 px note still has an end to catch.
      expect(noteEdgeAt(x: 102, left: 100, right: 102), NoteEdge.end);
    });

    test('a double-click: soon enough after, close enough to the first', () {
      const at = Offset(50, 50);
      const t = Duration(seconds: 3);
      bool second(Duration time, Offset where) => isDoubleTap(
          previousTime: t, previousAt: at, time: time, at: where);
      expect(second(t + const Duration(milliseconds: 200), at), isTrue);
      expect(second(t + const Duration(milliseconds: 400), at), isFalse);
      expect(second(t + const Duration(milliseconds: 200), at + const Offset(20, 0)),
          isFalse);
      expect(
          isDoubleTap(previousTime: null, previousAt: null, time: t, at: at),
          isFalse,
          reason: 'the first click');
    });

    test('zoom keeps the pointer still, or the middle without one', () {
      expect(zoomAnchorX(pointerX: 640, viewWidth: 800), 640);
      expect(zoomAnchorX(pointerX: null, viewWidth: 800), 400);
      expect(zoomAnchorX(pointerX: 900, viewWidth: 800), 400,
          reason: 'off the grid');
    });

    test('a bend drawn near the middle snaps to no bend; nothing else snaps',
        () {
      const bend = MidiLane.of(MidiEventKind.pitchBend);
      expect(snapLaneValue(bend, 8500), 8192);
      expect(snapLaneValue(bend, 7800), 8192);
      expect(snapLaneValue(bend, 9500), 9500);
      expect(snapLaneValue(const MidiLane.of(MidiEventKind.controller, 1), 64),
          64);
    });

    test('out of scale: only with a scale, by pitch class', () {
      const aMinor = MusicalScale(9, ScaleType.minor);
      expect(noteOutOfScale(aMinor, 69), isFalse); // A
      expect(noteOutOfScale(aMinor, 70), isTrue); // A#
      expect(noteOutOfScale(null, 70), isFalse);
      const notes = [
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 60, velocity: 1),
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 61, velocity: 1),
      ];
      expect(outOfScaleFlags(notes, aMinor), [false, true]);
      expect(outOfScaleFlags(notes, null), isNull);
    });

    test('vertical zoom keeps the row being looked at still', () {
      // Row 20 (of 14 px) sits 80 px down the view at a scroll of 200.
      const anchor = 20 * 14.0 - 200;
      final scroll = verticalZoomScroll(
          scrollY: 200, oldRow: 14, newRow: 28, anchorY: anchor);
      expect(20 * 28 - scroll, anchor);
      expect(
          verticalZoomScroll(scrollY: 0, oldRow: 28, newRow: 6, anchorY: 10),
          0,
          reason: 'never above the top');
    });

    test('the keyboard parts white keys where a piano does', () {
      // Under C and F: the two places white keys meet with no black key.
      expect([for (var p = 60; p < 72; p++) if (!isBlackKey(p) && whiteKeySeamBelow(p)) p],
          [60, 65]);
      expect(kBlackKeyWidthFraction, inInclusiveRange(0.5, 0.7));
    });

    test('the snap grid draws its divisions between the beats', () {
      expect(gridDivisionTicks(stepTicks: 120, ppq: 480, pxPerTick: 0.1), 120);
      expect(gridDivisionTicks(stepTicks: 480, ppq: 480, pxPerTick: 1), isNull,
          reason: 'a quarter-note grid is the beat lines');
      expect(gridDivisionTicks(stepTicks: 60, ppq: 480, pxPerTick: 0.05), isNull,
          reason: 'too close together to see');
    });

    test('black keys', () {
      expect([for (var p = 60; p < 72; p++) isBlackKey(p)],
          [false, true, false, true, false, false, true, false, true, false, true, false]);
    });

    test('range pads the notes and shows at least two octaves', () {
      final one = pianoRollRange(const [
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 60, velocity: 1),
      ]);
      expect(one.high - one.low + 1, 24);
      expect(one.low <= 57 && one.high >= 63, isTrue);

      final wide = pianoRollRange(const [
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 30, velocity: 1),
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 90, velocity: 1),
      ]);
      expect((wide.low, wide.high), (27, 93));
    });

    test('range never leaves the MIDI note range', () {
      final edge = pianoRollRange(const [
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 0, velocity: 1),
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 127, velocity: 1),
      ]);
      expect((edge.low, edge.high), (0, 127));
      expect(pianoRollRange(const []).high - pianoRollRange(const []).low + 1, 24);
    });

    test('time from ticks reverses ticksAt', () {
      expect(durationAtTick(960, 120, 480), const Duration(seconds: 1));
      expect(ticksAt(durationAtTick(1234, 97, 960), 97, 960), closeTo(1234, 0.01));
      expect(durationAtTick(960, 0, 480), Duration.zero);
    });

    test('ticks from playback time at a tempo', () {
      // 1 s at 120 BPM is 2 beats.
      expect(ticksAt(const Duration(seconds: 1), 120, 480), 960);
      expect(ticksAt(const Duration(milliseconds: 500), 60, 960), 480);
    });

    group('followScroll keeps the playhead centred', () {
      double follow(double x) =>
          followScroll(playheadX: x, viewWidth: 1000, maxScroll: 5000);

      test('the line walks right until it reaches the middle', () {
        expect(follow(0), 0);
        expect(follow(300), 0);
        expect(follow(500), 0);
      });

      test('then the notes scroll smoothly with the line held centred', () {
        expect(follow(501), 1);
        expect(follow(2500), 2000);
        expect(follow(2500.5), 2000.5, reason: 'continuous, not paged');
      });

      test('at the end the scroll stops and the line walks to the edge', () {
        expect(follow(5500), 5000);
        expect(follow(5990), 5000);
      });

      test('a clip narrower than the view never scrolls', () {
        expect(followScroll(playheadX: 700, viewWidth: 1000, maxScroll: 0), 0);
      });
    });
  });

  group('lanes', () {
    test('velocity first, then what the clip holds, controllers by number', () {
      expect(availableMidiLanes(_expressive), const [
        MidiLane.velocity(),
        MidiLane.of(MidiEventKind.pitchBend),
        MidiLane.of(MidiEventKind.controller, 1),
        MidiLane.of(MidiEventKind.controller, 74),
        MidiLane.of(MidiEventKind.channelPressure),
        MidiLane.of(MidiEventKind.polyPressure),
        MidiLane.of(MidiEventKind.program),
      ]);
    });

    test('a clip of notes alone still offers pitch bend and the mod wheel', () {
      // Empty, but there to look at — and to draw in while editing.
      expect(availableMidiLanes(_clip()), const [
        MidiLane.velocity(),
        MidiLane.of(MidiEventKind.pitchBend),
        MidiLane.of(MidiEventKind.controller, 1),
      ]);
    });

    test('points are note velocities or the lane\'s own events', () {
      expect(midiLanePoints(_expressive, const MidiLane.velocity()),
          [(0, 100), (960, 70)]);
      expect(
          midiLanePoints(
              _expressive, const MidiLane.of(MidiEventKind.controller, 1)),
          [(0, 0), (480, 90)]);
      expect(
          midiLanePoints(_expressive, const MidiLane.of(MidiEventKind.pitchBend)),
          [(240, 12000)]);
    });

    test('poly aftertouch is one lane for every key', () {
      expect(const MidiLane.of(MidiEventKind.polyPressure, 64),
          const MidiLane.of(MidiEventKind.polyPressure));
      expect(const MidiLane.of(MidiEventKind.pitchBend).maxValue, 16383);
      expect(const MidiLane.velocity().maxValue, 127);
    });
  });

  group('extrapolatePosition', () {
    final at = DateTime(2026, 1, 1, 12);

    test('moves on by the time since the last report', () {
      expect(
        extrapolatePosition(const Duration(seconds: 2), at,
            at.add(const Duration(milliseconds: 150))),
        const Duration(milliseconds: 2150),
      );
    });

    test('a stalled player cannot send the playhead running off', () {
      expect(
        extrapolatePosition(Duration.zero, at, at.add(const Duration(seconds: 30))),
        const Duration(seconds: 1),
      );
    });

    test('a clock that went backwards does not move it back', () {
      expect(
        extrapolatePosition(const Duration(seconds: 1), at,
            at.subtract(const Duration(seconds: 1))),
        const Duration(seconds: 1),
      );
    });
  });

  group('MidiPianoRoll', () {
    Widget wrap(MidiClip clip,
            {Duration? Function()? positionOf,
            Listenable? playback,
            ValueChanged<Duration>? onSeek}) =>
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: MidiPianoRoll(
                clip: clip,
                labels: _labels,
                bpm: 120,
                positionOf: positionOf,
                playback: playback,
                onSeek: onSeek,
              ),
            ),
          ),
        );

    testWidgets('draws a clip and handles zoom, fit and wheel input', (tester) async {
      await tester.pumpWidget(wrap(_clip()));
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      await tester.tap(find.byTooltip('Fit'));
      await tester.pump();

      final center = tester.getCenter(find.byType(MidiPianoRoll));
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(center));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows velocity by default; the picker switches or hides the lane',
        (tester) async {
      await tester.pumpWidget(wrap(_expressive));
      final lane = find.byKey(const ValueKey('midi-piano-roll-lane'));
      expect(lane, findsOneWidget);
      expect(find.text('Velocity'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('midi-piano-roll-lane-picker')));
      await tester.pumpAndSettle();
      for (final name in ['pitchBend', 'CC 1', 'CC 74', 'channelPressure',
          'polyPressure', 'program', 'None']) {
        expect(find.text(name), findsWidgets, reason: name);
      }
      await tester.tap(find.text('CC 74').last);
      await tester.pumpAndSettle();
      expect(lane, findsOneWidget);
      expect(find.text('CC 74'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('midi-piano-roll-lane-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('None').last);
      await tester.pumpAndSettle();
      expect(lane, findsNothing, reason: 'the notes get the room back');
      expect(tester.takeException(), isNull);
    });

    testWidgets('every lane paints without error', (tester) async {
      await tester.pumpWidget(wrap(_expressive));
      for (final lane in availableMidiLanes(_expressive).skip(1)) {
        await tester
            .tap(find.byKey(const ValueKey('midi-piano-roll-lane-picker')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_laneName(lane)).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$lane');
      }
    });

    group('the ruler', () {
      final ruler = find.byKey(const ValueKey('midi-piano-roll-ruler'));

      testWidgets('a click seeks to the time under it', (tester) async {
        final seeks = <Duration>[];
        // Four bars at 120 BPM: 8 seconds across the fitted ruler.
        await tester.pumpWidget(wrap(_clip(), onSeek: seeks.add));
        final box = tester.getRect(ruler);
        await tester.tapAt(box.centerLeft + Offset(box.width / 4, 0));
        expect(seeks.single.inMilliseconds, closeTo(2000, 5));
      });

      testWidgets('a drag seeks once, where it is let go', (tester) async {
        final seeks = <Duration>[];
        await tester.pumpWidget(wrap(_clip(), onSeek: seeks.add));
        final box = tester.getRect(ruler);
        final drag = await tester.startGesture(box.centerLeft + const Offset(5, 0));
        await drag.moveBy(Offset(box.width / 4, 0));
        await tester.pump();
        await drag.moveBy(Offset(box.width / 4, 0));
        await tester.pump();
        expect(seeks, isEmpty, reason: 'nothing jumps while still dragging');
        await drag.up();
        expect(seeks.single.inMilliseconds, closeTo(4000 + 8000 * 5 / box.width, 5));
      });

      testWidgets('past the clip end it seeks to the end', (tester) async {
        final seeks = <Duration>[];
        await tester.pumpWidget(wrap(_clip(), onSeek: seeks.add));
        await tester.tap(find.byTooltip('Zoom out'));
        await tester.pump();
        final box = tester.getRect(ruler);
        await tester.tapAt(box.centerRight - const Offset(2, 0));
        expect(seeks.single, const Duration(seconds: 8));
      });

      testWidgets('without onSeek the ruler is just a ruler', (tester) async {
        await tester.pumpWidget(wrap(_clip()));
        expect(ruler, findsNothing);
      });
    });

    group('scale', () {
      Widget withScale(MusicalScale? scale, List<MusicalScale?> changes) =>
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 500,
                child: MidiPianoRoll(
                  clip: _clip(),
                  labels: _labels,
                  initialScale: scale,
                  onScaleChanged: changes.add,
                ),
              ),
            ),
          );
      final button = find.byKey(const ValueKey('midi-piano-roll-scale'));

      testWidgets('opens on the given scale and says which', (tester) async {
        await tester.pumpWidget(
            withScale(const MusicalScale(9, ScaleType.minor), []));
        expect(find.descendant(of: button, matching: find.text('A minor')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('without one the button just says Scale', (tester) async {
        await tester.pumpWidget(withScale(null, []));
        expect(find.descendant(of: button, matching: find.text('Scale')),
            findsOneWidget);
      });

      testWidgets('the chooser changes it, and No scale turns it off',
          (tester) async {
        final changes = <MusicalScale?>[];
        await tester.pumpWidget(
            withScale(const MusicalScale(9, ScaleType.minor), changes));

        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('midi-scale-type')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('dorian').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(changes, [const MusicalScale(9, ScaleType.dorian)]);
        expect(find.descendant(of: button, matching: find.text('A dorian')),
            findsOneWidget);

        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.tap(find.text('No scale'));
        await tester.pumpAndSettle();
        expect(changes.last, isNull);
        expect(find.descendant(of: button, matching: find.text('Scale')),
            findsOneWidget);
      });

      testWidgets('cancelling the chooser changes nothing', (tester) async {
        final changes = <MusicalScale?>[];
        await tester.pumpWidget(
            withScale(const MusicalScale(0, ScaleType.major), changes));
        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(changes, isEmpty);
      });
    });

    testWidgets('zoomed right in, notes are drawn with their names',
        (tester) async {
      await tester.pumpWidget(wrap(_clip()));
      // Tallest rows, and wide notes.
      tester.widget<Slider>(find.byType(Slider)).onChanged!(28);
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('Zoom in'));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('selected and out-of-scale notes, stems and the snap grid '
        'paint', (tester) async {
      final editor = MidiClipEditController(_clip())
        ..editing = true
        ..selectAll()
        ..snap = MidiSnap.thirtySecond;
      addTearDown(editor.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 500,
            child: MidiPianoRoll(
              clip: _clip(),
              labels: _labels,
              editor: editor,
              initialScale: const MusicalScale(0, ScaleType.majorPentatonic),
            ),
          ),
        ),
      ));
      tester.widget<Slider>(find.byType(Slider)).onChanged!(28);
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Zoom in'));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty clip still lays out', (tester) async {
      await tester.pumpWidget(wrap(const MidiClip(name: 'x', ppq: 480, lengthTicks: 0, notes: [])));
      expect(tester.takeException(), isNull);
    });

    testWidgets('follow is on by default and can be switched off', (tester) async {
      await tester.pumpWidget(wrap(_clip()));
      IconButton followButton() => tester.widget<IconButton>(
          find.ancestor(of: find.byIcon(Icons.my_location), matching: find.byType(IconButton)));
      expect(followButton().isSelected, isTrue);
      await tester.tap(find.byTooltip('Follow'));
      await tester.pump();
      expect(tester.widgetList(find.byIcon(Icons.my_location)), isEmpty);
    });

    testWidgets('zooming switches follow off, so it does not snap back',
        (tester) async {
      await tester.pumpWidget(wrap(_clip()));
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(find.byIcon(Icons.my_location), findsNothing);
    });

    testWidgets('ticks only while playing', (tester) async {
      final playback = ValueNotifier(false);
      var polls = 0;
      await tester.pumpWidget(wrap(
        _clip(bars: 64),
        playback: playback,
        positionOf: () {
          polls++;
          return playback.value ? Duration(milliseconds: 100 * polls) : null;
        },
      ));
      // Silent: nothing scheduled, so the frame pump settles.
      await tester.pumpAndSettle();
      final idlePolls = polls;
      await tester.pump(const Duration(milliseconds: 100));
      expect(polls, idlePolls, reason: 'no per-frame polling while silent');

      playback.value = true;
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(polls, greaterThan(idlePolls + 2), reason: 'polled every frame while playing');

      playback.value = false;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('showMidiPianoRoll', () {
    testWidgets('closing the window stops the clip it was playing',
        (tester) async {
      final player = MidiPreviewPlayer();
      addTearDown(player.dispose);
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMidiPianoRoll(
                context,
                clip: _clip(),
                title: 'Riff',
                player: player,
                playerKey: 'k',
                bpm: 120,
                onPlay: (_) {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      player.playingKey = 'k';
      await player.pause();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(MidiPianoRoll), findsNothing);
      expect(player.playingKey, isNull);
    });

    testWidgets('shows the clip, plays through the caller, and closes', (tester) async {
      final player = MidiPreviewPlayer();
      addTearDown(player.dispose);
      var toggles = 0;
      // The window reads the shared preview volume, so it needs a scope.
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMidiPianoRoll(
                context,
                clip: _clip(),
                title: 'Bass – Riff',
                subtitle: 'Night Drive',
                player: player,
                playerKey: 'k',
                bpm: 128,
                onPlay: (_) => toggles++,
                musicalKey: 'A minor',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      )));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Bass – Riff'), findsOneWidget);
      expect(find.byType(Slider), findsWidgets, reason: 'the volume control');
      expect(find.byTooltip('Loop playback'), findsOneWidget,
          reason: 'the loop toggle, beside the volume');
      expect(find.text('Night Drive'), findsOneWidget);
      expect(find.text('Velocity'), findsOneWidget,
          reason: 'the lane picker, named through the app\'s strings');
      expect(find.text('A Minor'), findsOneWidget,
          reason: 'opens on the project key, named in the app strings');

      await tester.tap(find.byIcon(Icons.play_circle_outline));
      expect(toggles, 1);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(MidiPianoRoll), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
