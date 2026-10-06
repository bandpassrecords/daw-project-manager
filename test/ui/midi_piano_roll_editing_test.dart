import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';
import 'package:daw_project_manager/ui/midi_note_auditioner.dart';
import 'package:daw_project_manager/ui/midi_collection_actions.dart';
import 'package:daw_project_manager/ui/widgets/midi_tool_icons.dart';
import 'package:daw_project_manager/ui/midi_piano_roll_dialog.dart';
import 'package:daw_project_manager/ui/midi_preview_player.dart';
import 'package:daw_project_manager/ui/widgets/midi_piano_roll.dart';
import 'package:daw_project_manager/utils/musical_scale.dart';

/// One bar at 480 PPQ with one note: C3 (60) on beat 1.
const _clip = MidiClip(
  name: 'Riff',
  ppq: 480,
  lengthTicks: 1920,
  notes: [MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100)],
);

String _laneName(MidiLane lane) => lane.toString();
String _scaleTypeName(ScaleType type) => type.name;
String _edited(String name) => '$name (edited)';
String _voiceName(SynthVoice voice) => voice.name;
String _instrument(String name) => 'Instrument: $name';

/// Four quarter notes on C3, all at velocity 100.
const _fourNotes = MidiClip(
  name: 'Four',
  ppq: 480,
  lengthTicks: 1920,
  notes: [
    MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100),
    MidiNote(startTick: 480, lengthTicks: 240, pitch: 60, velocity: 100),
    MidiNote(startTick: 960, lengthTicks: 240, pitch: 60, velocity: 100),
    MidiNote(startTick: 1440, lengthTicks: 240, pitch: 60, velocity: 100),
  ],
);

/// Hears what the window sounds, instead of playing it.
class _Ear extends MidiNoteAuditioner {
  final heard = <int>[];

  @override
  Future<void> play(int pitch, {int velocity = 100}) async => heard.add(pitch);
}

const _labels = MidiPianoRollWindowLabels(
  roll: MidiPianoRollLabels(
    zoomIn: 'In',
    zoomOut: 'Out',
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
    edit: 'Edit',
    undo: 'Undo',
    redo: 'Redo',
    snap: 'Snap',
    snapOff: 'Off',
    toolSelect: 'Select',
    toolRange: 'Range',
    toolEraser: 'Eraser',
    toolPencil: 'Pencil',
    duplicate: 'Duplicate',
    transpose: 'Transpose',
    transposeUpSemitone: 'Semitone up',
    transposeDownSemitone: 'Semitone down',
    transposeUpOctave: 'Octave up',
    transposeDownOctave: 'Octave down',
    acousticFeedback: 'Feedback',
  ),
  close: 'Close',
  play: 'Play',
  pause: 'Pause',
  stop: 'Stop',
  openProject: 'Open project',
  saveAsNew: 'Save as new clip',
  editedName: _edited,
  discardTitle: 'Discard?',
  discardBody: 'Not saved.',
  keepEditing: 'Keep editing',
  discard: 'Discard',
  voiceName: _voiceName,
  instrument: _instrument,
);

void main() {
  late MidiPreviewPlayer player;
  late List<(MidiClip, String?)> saved;
  late List<SynthVoice> savedVoices, voiceChanges;
  late int shortcutSheets;
  late List<bool> fullScreenChanges;
  late List<bool> feedbackChanges;
  late _Ear ear;

  setUp(() {
    player = MidiPreviewPlayer();
    saved = [];
    savedVoices = [];
    voiceChanges = [];
    shortcutSheets = 0;
    fullScreenChanges = [];
    feedbackChanges = [];
    ear = _Ear();
  });
  tearDown(() => player.dispose());

  /// The window in a dialog, so closing it has somewhere to go.
  Future<void> open(
    WidgetTester tester, {
    bool editable = true,
    MidiClip clip = _clip,
    MidiPianoRollWindowLabels labels = _labels,
    bool feedback = false,
    bool startEditing = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                insetPadding: EdgeInsets.zero,
                child: SizedBox(
                  width: 900,
                  height: 600,
                  child: MidiPianoRollWindow(
                    clip: clip,
                    title: 'Riff',
                    subtitle: 'Song',
                    player: player,
                    playerKey: 'k',
                    bpm: 120,
                    labels: labels,
                    onPlay: (_) {},
                    musicalKey: 'A minor',
                    voice: SynthVoice.keys,
                    onVoiceChanged: voiceChanges.add,
                    onShowShortcuts: () => shortcutSheets++,
                    fullScreen: false,
                    onFullScreenChanged: fullScreenChanges.add,
                    acousticFeedback: feedback,
                    onAcousticFeedbackChanged: feedbackChanges.add,
                    auditioner: ear,
                    startEditing: startEditing,
                    onSaveEdited: editable
                        ? (clip, key, voice) async {
                            saved.add((clip, key));
                            savedVoices.add(voice);
                            return true;
                          }
                        : null,
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The note grid: between the ruler and the lane, right of the keyboard.
  Rect grid(WidgetTester tester) {
    final ruler = tester.getRect(find.byKey(const ValueKey('midi-piano-roll-ruler')));
    final lane = tester.getRect(find.byKey(const ValueKey('midi-piano-roll-lane')));
    return Rect.fromLTRB(ruler.left, ruler.bottom, ruler.right, lane.top);
  }

  Future<void> startEditing(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('midi-piano-roll-edit')));
    await tester.pumpAndSettle();
  }

  // Taps carry their own times, so two separate clicks are never taken for
  // a double-click by accident, and a double-click is one on purpose.
  var clock = Duration.zero;

  Future<void> click(WidgetTester tester, Offset at,
      {Duration after = const Duration(seconds: 1)}) async {
    clock += after;
    final g = await tester.createGesture();
    await g.down(at, timeStamp: clock);
    await g.up(timeStamp: clock);
    await tester.pumpAndSettle();
  }

  Future<void> doubleClick(WidgetTester tester, Offset at) async {
    await click(tester, at);
    await click(tester, at, after: const Duration(milliseconds: 120));
  }

  Future<void> dragFrom(WidgetTester tester, Offset from, Offset by) async {
    final drag = await tester.startGesture(from);
    for (var i = 1; i <= 4; i++) {
      await drag.moveTo(from + by * (i / 4));
      await tester.pump();
    }
    await drag.up();
    await tester.pumpAndSettle();
  }

  /// The middle of the clip's one note (ticks 0–240 of 1920, on C3).
  Offset noteMiddle(Rect g) => Offset(g.left + g.width / 16, g.center.dy);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('midi-piano-roll-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('without somewhere to save, the roll is a viewer', (tester) async {
    await open(tester, editable: false);
    expect(find.byKey(const ValueKey('midi-piano-roll-edit')), findsNothing);
  });

  testWidgets('edit mode brings the tools; there is nothing to save yet',
      (tester) async {
    await open(tester);
    await startEditing(tester);
    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(find.byTooltip('Redo'), findsOneWidget);
    for (final tool in ['select', 'range', 'eraser', 'pencil']) {
      expect(find.byKey(ValueKey('midi-piano-roll-tool-$tool')), findsOneWidget,
          reason: tool);
    }
    expect(find.byTooltip('Delete note'), findsNothing,
        reason: 'the eraser took its place');
    expect(find.byKey(const ValueKey('midi-piano-roll-duplicate')), findsOneWidget);
    expect(find.byKey(const ValueKey('midi-piano-roll-transpose')), findsOneWidget);
    expect(find.byKey(const ValueKey('midi-piano-roll-snap')), findsOneWidget);
    expect(find.byKey(const ValueKey('midi-piano-roll-save')), findsNothing);
  });

  testWidgets(
      'a click only selects; a double-click adds a note; saving makes a new '
      'clip in the project key', (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    // Three quarters into the clip (tick 1440), on the middle row (C3).
    final spot = Offset(g.left + g.width * 0.76, g.center.dy);
    await click(tester, spot);
    expect(find.byKey(const ValueKey('midi-piano-roll-save')), findsNothing,
        reason: 'as in Cubase, a single click adds nothing');
    await doubleClick(tester, spot);

    await save(tester);
    final (clip, key) = saved.single;
    expect(clip.name, 'Riff (edited)');
    expect(clip.notes.map((n) => (n.startTick, n.pitch)), [(0, 60), (1440, 60)]);
    expect(key, 'A minor', reason: 'the scale it was edited in');
    expect(find.byKey(const ValueKey('midi-piano-roll-save')), findsNothing,
        reason: 'saved: nothing left to save');
  });

  testWidgets('a double-click on a note deletes it', (tester) async {
    await open(tester);
    await startEditing(tester);
    await doubleClick(tester, noteMiddle(grid(tester)));
    await save(tester);
    expect(saved.single.$1.notes, isEmpty);
  });

  testWidgets('dragging a note moves it along the grid', (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    final note = noteMiddle(g);
    final drag = await tester.startGesture(note);
    await drag.moveBy(Offset(g.width * 0.125, 0));
    await tester.pump();
    await drag.moveBy(Offset(g.width * 0.125, 0));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    await save(tester);
    expect(saved.single.$1.notes.single.startTick, 480,
        reason: 'a quarter of the bar, snapped to 1/16');
  });

  testWidgets('Delete removes the selected note; Ctrl+Z puts it back',
      (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    await click(tester, noteMiddle(g)); // select it
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('midi-piano-roll-save')), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('midi-piano-roll-save')), findsNothing,
        reason: 'undone back to the clip as opened');
  });

  testWidgets('closing with unsaved edits asks first', (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    await doubleClick(tester, Offset(g.left + g.width * 0.5, g.center.dy));

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(MidiPianoRollWindow), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(MidiPianoRollWindow), findsNothing);
    expect(saved, isEmpty);
  });

  testWidgets('dragging across the mod wheel lane draws it', (tester) async {
    await open(tester);
    await startEditing(tester);
    await tester.tap(find.byKey(const ValueKey('midi-piano-roll-lane-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MidiLane(controller 1)').last);
    await tester.pumpAndSettle();

    final lane = tester.getRect(find.byKey(const ValueKey('midi-piano-roll-lane')));
    final g = grid(tester);
    // From the top of the lane at the start, down to the bottom halfway in.
    final drag = await tester.startGesture(Offset(g.left + 2, lane.top + 4));
    for (var i = 1; i <= 8; i++) {
      await drag.moveTo(Offset(g.left + 2 + g.width * 0.5 * i / 8,
          lane.top + 4 + (lane.height - 8) * i / 8));
      await tester.pump();
    }
    await drag.up();
    await tester.pumpAndSettle();

    await save(tester);
    final mod = saved.single.$1.events
        .where((e) => e.kind == MidiEventKind.controller && e.number == 1)
        .toList();
    expect(mod.length, greaterThan(3), reason: 'a curve, not a single point');
    expect(mod.first.value, greaterThan(100), reason: 'starts near the top');
    expect(mod.last.value, lessThan(30), reason: 'ends near the bottom');
  });

  testWidgets('a box selects; up moves a semitone, Shift+up an octave',
      (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    // From empty space above and right of the note, to below its start.
    await dragFrom(tester, Offset(g.left + g.width * 0.3, g.center.dy - 40),
        Offset(-g.width * 0.3 + 2, 80));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    await save(tester);
    expect(saved.single.$1.notes.single.pitch, 73);
  });

  testWidgets("dragging a note's end changes its length", (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    // The note's right edge is an eighth of the way across.
    await dragFrom(tester, Offset(g.left + g.width / 8 - 3, g.center.dy),
        Offset(g.width / 8, 0));
    await save(tester);
    final note = saved.single.$1.notes.single;
    expect((note.startTick, note.lengthTicks), (0, 480));
  });

  testWidgets('an Alt-drag copies the note', (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await dragFrom(tester, noteMiddle(g), Offset(g.width / 4, 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await save(tester);
    expect(saved.single.$1.notes.map((n) => (n.startTick, n.pitch)),
        [(0, 60), (480, 60)]);
  });

  testWidgets('holding Ctrl, a drag ignores the grid', (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    // 250 ticks: between the 1/16 steps at 240 and 360.
    await dragFrom(tester, noteMiddle(g), Offset(g.width * 250 / 1920, 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await save(tester);
    expect(saved.single.$1.notes.single.startTick, closeTo(250, 2));
  });

  testWidgets('zooming keeps the time under the mouse where it was',
      (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    final spot = Offset(g.left + g.width * 0.76, g.center.dy); // tick ~1459
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(spot));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -120)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    // Zoomed around the middle or the start, the same spot would be a
    // different 1/16 step (1320 or 1200).
    await doubleClick(tester, spot);
    await save(tester);
    expect(saved.single.$1.notes.last.startTick, 1440);
  });

  group('the pencil', () {
    Future<void> pickPencil(WidgetTester tester) async {
      // Cubase's key for the draw tool.
      await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<IconButton>(
                  find.byKey(const ValueKey('midi-piano-roll-tool-pencil')))
              .isSelected,
          isTrue);
    }

    testWidgets('one click adds a note', (tester) async {
      await open(tester);
      await startEditing(tester);
      await pickPencil(tester);
      final g = grid(tester);
      await click(tester, Offset(g.left + g.width * 0.76, g.center.dy));
      await save(tester);
      expect(saved.single.$1.notes.map((n) => (n.startTick, n.lengthTicks)),
          [(0, 240), (1440, 120)]);
    });

    testWidgets('dragging as it adds makes the note longer, one undo step',
        (tester) async {
      await open(tester);
      await startEditing(tester);
      await pickPencil(tester);
      final g = grid(tester);
      await dragFrom(tester, Offset(g.left + g.width * 0.5 + 2, g.center.dy),
          Offset(g.width / 8, 0));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('midi-piano-roll-save')), findsNothing,
          reason: 'one undo took the whole note away');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      await save(tester);
      final drawn = saved.single.$1.notes.last;
      expect((drawn.startTick, drawn.lengthTicks), (960, 360));
    });

    testWidgets('a click on a note erases it', (tester) async {
      await open(tester);
      await startEditing(tester);
      await pickPencil(tester);
      await click(tester, noteMiddle(grid(tester)));
      await save(tester);
      expect(saved.single.$1.notes, isEmpty);
    });

    testWidgets('1 goes back to selecting: a click adds nothing',
        (tester) async {
      await open(tester);
      await startEditing(tester);
      await pickPencil(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      final g = grid(tester);
      await click(tester, Offset(g.left + g.width * 0.76, g.center.dy));
      expect(find.byKey(const ValueKey('midi-piano-roll-save')), findsNothing);
    });
  });

  testWidgets('a drag across the velocity lane sets every note it passes',
      (tester) async {
    await open(tester, clip: _fourNotes);
    await startEditing(tester);
    final lane =
        tester.getRect(find.byKey(const ValueKey('midi-piano-roll-lane')));
    final g = grid(tester);
    // From the top at the first stem, down to the bottom past the last.
    await dragFrom(tester, Offset(g.left + 2, lane.top + 4),
        Offset(g.width * 0.8, lane.height - 8));
    await save(tester);
    final velocities = saved.single.$1.notes.map((n) => n.velocity).toList();
    expect(velocities.first, greaterThan(110));
    expect(velocities.last, lessThan(40));
    for (var i = 1; i < velocities.length; i++) {
      expect(velocities[i], lessThan(velocities[i - 1]),
          reason: 'a sloped line across the stems: $velocities');
    }
  });

  testWidgets('a bend is drawn finely, and snaps back to no bend mid-lane',
      (tester) async {
    await open(tester);
    await startEditing(tester);
    await tester.tap(find.byKey(const ValueKey('midi-piano-roll-lane-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MidiLane(pitchBend 0)').last);
    await tester.pumpAndSettle();
    final lane =
        tester.getRect(find.byKey(const ValueKey('midi-piano-roll-lane')));
    final g = grid(tester);
    await dragFrom(tester, Offset(g.left + 2, lane.top + 4),
        Offset(g.width * 0.25, lane.center.dy + 1 - (lane.top + 4)));
    await save(tester);
    final bend = saved.single.$1.events
        .where((e) => e.kind == MidiEventKind.pitchBend)
        .toList();
    expect(bend.length, greaterThan(10),
        reason: 'a 128th-note resolution, not one value per 1/16');
    expect(bend.every((e) => e.tick % 15 == 0), isTrue);
    expect(bend.first.value, greaterThan(15000));
    expect(bend.last.value, 8192, reason: 'snapped to no bend');
  });

  testWidgets('the shortcut sheet opens from its button, ? and F1',
      (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('midi-piano-roll-shortcuts')));
    await tester.pump();
    expect(shortcutSheets, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pump();
    expect(shortcutSheets, 2);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash, character: '?');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(shortcutSheets, 3);
  });

  testWidgets('no hint pops up while editing', (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    await doubleClick(tester, Offset(g.left + g.width * 0.5, g.center.dy));
    expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
  });

  testWidgets('the full screen toggle asks for the other state',
      (tester) async {
    await open(tester);
    final toggle = find.byKey(const ValueKey('midi-piano-roll-fullscreen'));
    expect(find.descendant(of: toggle, matching: find.byIcon(Icons.fullscreen)),
        findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(fullScreenChanges, [true]);
  });

  testWidgets('a middle-button drag moves the canvas, and edits nothing',
      (tester) async {
    await open(tester);
    await startEditing(tester);
    final g = grid(tester);
    final middle = await tester.startGesture(
        Offset(g.left + g.width * 0.5, g.center.dy),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton);
    for (var i = 1; i <= 4; i++) {
      await middle.moveBy(Offset(-g.width * 0.25 / 4, 0));
      await tester.pump();
    }
    await middle.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('midi-piano-roll-save')), findsNothing);

    // Scrolled a quarter of the view: the middle is now tick 1440, not 960.
    await doubleClick(tester, Offset(g.left + g.width * 0.5 + 2, g.center.dy));
    await save(tester);
    expect(saved.single.$1.notes.last.startTick, 1440);
  });

  group('range, duplicate and eraser', () {
    testWidgets('2, drag a range, Ctrl+D twice: the bar repeats',
        (tester) async {
      await open(tester);
      await startEditing(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      final g = grid(tester);
      // The first quarter of the bar: ticks 0–480.
      await dragFrom(tester, Offset(g.left + 2, g.center.dy - 50),
          Offset(g.width * 0.24, 0));
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
      }
      await save(tester);
      expect(saved.single.$1.notes.map((n) => n.startTick), [0, 480, 960]);
    });

    testWidgets('the duplicate button copies the selection, for a phone',
        (tester) async {
      await open(tester);
      await startEditing(tester);
      await click(tester, noteMiddle(grid(tester)));
      await tester.tap(find.byKey(const ValueKey('midi-piano-roll-duplicate')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(saved.single.$1.notes.map((n) => n.startTick), [0, 240]);
    });

    testWidgets('the transpose menu moves the selection, for a phone',
        (tester) async {
      await open(tester);
      await startEditing(tester);
      await click(tester, noteMiddle(grid(tester)));
      await tester.tap(find.byKey(const ValueKey('midi-piano-roll-transpose')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Octave up'));
      await tester.pumpAndSettle();
      await save(tester);
      expect(saved.single.$1.notes.single.pitch, 72);
    });

    testWidgets('5, then one swipe erases every note it passes, one undo',
        (tester) async {
      await open(tester, clip: _fourNotes);
      await startEditing(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pumpAndSettle();
      final g = grid(tester);
      await dragFrom(tester, Offset(g.left + 4, g.center.dy),
          Offset(g.width * 0.85, 0));
      await save(tester);
      expect(saved.single.$1.notes, isEmpty);
    });

    testWidgets('the eraser deletes a note it clicks', (tester) async {
      await open(tester, clip: _fourNotes);
      await startEditing(tester);
      await tester.tap(find.byKey(const ValueKey('midi-piano-roll-tool-eraser')));
      await tester.pumpAndSettle();
      final g = grid(tester);
      await click(tester, Offset(g.left + g.width * 0.25 + 20, g.center.dy));
      await save(tester);
      expect(saved.single.$1.notes.map((n) => n.startTick), [0, 960, 1440]);
    });

    testWidgets('the pencil and the eraser are drawn under the mouse',
        (tester) async {
      await open(tester);
      await startEditing(tester);
      final g = grid(tester);
      final mouse = TestPointer(1, PointerDeviceKind.mouse);
      final cursor = find.byKey(const ValueKey('midi-piano-roll-tool-cursor'));
      await tester.sendEventToBinding(mouse.hover(g.center + const Offset(0, -40)));
      await tester.pump();
      expect(cursor, findsNothing, reason: 'the select tool keeps the pointer');

      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.sendEventToBinding(mouse.hover(g.center + const Offset(4, -40)));
      await tester.pump();
      expect(cursor, findsOneWidget);
      expect(find.descendant(of: cursor, matching: find.byType(MidiToolIcon)),
          findsWidgets);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
      await tester.sendEventToBinding(mouse.hover(g.center + const Offset(8, -40)));
      await tester.pump();
      expect(find.descendant(of: cursor, matching: find.byIcon(Icons.edit)),
          findsWidgets);
    });
  });

  testWidgets('Q quantizes the notes to the grid', (tester) async {
    await open(
      tester,
      clip: const MidiClip(
        name: 'Loose',
        ppq: 480,
        lengthTicks: 1920,
        notes: [MidiNote(startTick: 470, lengthTicks: 240, pitch: 60, velocity: 100)],
      ),
    );
    await startEditing(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pumpAndSettle();
    await save(tester);
    expect(saved.single.$1.notes.single.startTick, 480);
  });

  group('a new idea', () {
    testWidgets('opens editing with the pencil: one click draws',
        (tester) async {
      await open(tester, startEditing: true);
      expect(
          tester
              .widget<IconButton>(
                  find.byKey(const ValueKey('midi-piano-roll-tool-pencil')))
              .isSelected,
          isTrue);
      final g = grid(tester);
      await click(tester, Offset(g.left + g.width * 0.76, g.center.dy));
      await save(tester);
      expect(saved.single.$1.notes, hasLength(2));
    });

    testWidgets('a note dragged past the end grows the clip', (tester) async {
      await open(tester, startEditing: true);
      final g = grid(tester);
      await dragFrom(tester, Offset(g.left + g.width * 0.9, g.center.dy),
          Offset(g.width * 0.3, 0));
      await save(tester);
      expect(saved.single.$1.lengthTicks, 3840);
    });

    testWidgets('the canvas never ends: scroll on and keep drawing',
        (tester) async {
      await open(tester, startEditing: true);
      final g = grid(tester);
      for (var pass = 0; pass < 6; pass++) {
        final middle = await tester.startGesture(
            Offset(g.right - 4, g.center.dy),
            kind: PointerDeviceKind.mouse,
            buttons: kMiddleMouseButton);
        for (var i = 0; i < 4; i++) {
          await middle.moveBy(Offset(-(g.width - 8) / 4, 0));
          await tester.pump();
        }
        await middle.up();
        await tester.pumpAndSettle();
      }
      await click(tester, Offset(g.left + g.width * 0.5, g.center.dy));
      await save(tester);
      final drawn = saved.single.$1.notes.last;
      expect(drawn.startTick, greaterThan(9600),
          reason: 'well past the clip and its four spare bars');
      expect(saved.single.$1.lengthTicks % 1920, 0);
      expect(saved.single.$1.lengthTicks, greaterThanOrEqualTo(drawn.endTick));
    });

    test('a blank idea is four empty bars', () {
      final idea = newMidiIdea('Idea 1');
      expect(idea.notes, isEmpty);
      expect(idea.lengthTicks, 4 * 4 * idea.ppq);
      expect(idea.name, 'Idea 1');
    });
  });


  group('sound', () {
    testWidgets('dragging along the keyboard plays each key it passes',
        (tester) async {
      await open(tester);
      final g = grid(tester);
      final drag = await tester.startGesture(Offset(g.left - 10, g.center.dy));
      for (var i = 1; i <= 3; i++) {
        await drag.moveBy(const Offset(0, 14)); // one row down each time
        await tester.pump();
      }
      await drag.up();
      await tester.pumpAndSettle();
      expect(ear.heard, [60, 59, 58, 57]);
    });

    testWidgets('the window names the instrument it plays', (tester) async {
      await open(tester);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('midi-piano-roll-voice')),
              matching: find.text('keys')),
          findsOneWidget);
    });

    testWidgets('a key on the keyboard plays, editing or not',
        (tester) async {
      await open(tester);
      final g = grid(tester);
      await click(tester, Offset(g.left - 10, g.center.dy));
      expect(ear.heard, [60]);
    });

    testWidgets('acoustic feedback: drawn, clicked and moved notes sound',
        (tester) async {
      await open(tester);
      await startEditing(tester);
      final g = grid(tester);
      await click(tester, noteMiddle(g));
      expect(ear.heard, isEmpty, reason: 'feedback is off');

      await tester.tap(find.byKey(const ValueKey('midi-piano-roll-feedback')));
      await tester.pumpAndSettle();
      expect(feedbackChanges, [true]);

      await click(tester, noteMiddle(g));
      expect(ear.heard, [60], reason: 'a clicked note');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(ear.heard.last, 61, reason: 'a transposed note');

      await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
      await tester.pumpAndSettle();
      await click(tester, Offset(g.left + g.width * 0.76, g.center.dy));
      expect(ear.heard.last, 60, reason: 'a drawn note');
    });

    testWidgets('the instrument can be changed, and a saved edit keeps it',
        (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('midi-piano-roll-voice')));
      await tester.pumpAndSettle();
      // The menu opens on the current instrument; bring the one wanted in.
      await tester.ensureVisible(find.text('bass').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('bass').last);
      await tester.pumpAndSettle();
      expect(voiceChanges, [SynthVoice.bass]);

      await startEditing(tester);
      await doubleClick(tester, Offset(grid(tester).left + 300, grid(tester).center.dy));
      await save(tester);
      expect(savedVoices, [SynthVoice.bass]);
    });
  });

  testWidgets('the vertical zoom stands upright at the top of the right side',
      (tester) async {
    await open(tester);
    final zoom = find.byKey(const ValueKey('midi-piano-roll-vertical-zoom'));
    final box = tester.getRect(zoom);
    final g = grid(tester);
    expect(box.height, greaterThan(box.width * 4));
    expect(box.bottom, lessThan(g.bottom - 100),
        reason: 'its old length, not stretched down the whole side');
    expect(box.top, lessThan(g.top + 4));
    expect(box.left, greaterThan(g.right - 1));
    expect(find.descendant(of: zoom, matching: find.byType(RotatedBox)),
        findsOneWidget);
  });


  testWidgets('with nothing changed, closing just closes', (tester) async {
    await open(tester);
    await startEditing(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard?'), findsNothing);
    expect(find.byType(MidiPianoRollWindow), findsNothing);
  });
}
