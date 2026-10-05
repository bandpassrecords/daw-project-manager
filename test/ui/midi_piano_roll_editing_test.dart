import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
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
    deleteNote: 'Delete note',
    snap: 'Snap',
    snapOff: 'Off',
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
);

void main() {
  late MidiPreviewPlayer player;
  late List<(MidiClip, String?)> saved;

  setUp(() {
    player = MidiPreviewPlayer();
    saved = [];
  });
  tearDown(() => player.dispose());

  /// The window in a dialog, so closing it has somewhere to go.
  Future<void> open(WidgetTester tester, {bool editable = true}) async {
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
                    clip: _clip,
                    title: 'Riff',
                    subtitle: 'Song',
                    player: player,
                    playerKey: 'k',
                    bpm: 120,
                    labels: _labels,
                    onPlay: () {},
                    musicalKey: 'A minor',
                    onSaveEdited: editable
                        ? (clip, key) async {
                            saved.add((clip, key));
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
    expect(find.byTooltip('Delete note'), findsOneWidget);
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

  testWidgets('with nothing changed, closing just closes', (tester) async {
    await open(tester);
    await startEditing(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard?'), findsNothing);
    expect(find.byType(MidiPianoRollWindow), findsNothing);
  });
}
