import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/ui/widgets/midi_clip_edit_controller.dart';
import 'package:daw_project_manager/utils/time_signature.dart';

/// One 4/4 bar at 480 PPQ with one note: C3 on beat 1.
const _clip = MidiClip(
  name: 'Riff',
  ppq: 480,
  lengthTicks: 1920,
  notes: [MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: 90)],
);

MidiClipEditController _editing() =>
    MidiClipEditController(_clip)..editing = true;

void main() {
  test('starts unedited, on a 1/16 grid', () {
    final c = _editing();
    expect(c.clip, same(_clip));
    expect(c.edited, isFalse);
    expect(c.canUndo, isFalse);
    expect(c.snap, MidiSnap.sixteenth);
    expect(c.stepTicks, 120);
  });

  test('snapping: a click lands in its grid step, a drag rounds', () {
    final c = _editing();
    expect(c.snapDown(359), 240);
    expect(c.snapDown(-10), 0);
    expect(c.snapDelta(170), 120);
    expect(c.snapDelta(-61), -120);
    c.snap = MidiSnap.off;
    expect(c.stepTicks, 1);
    expect(c.snapDown(359.7), 359);
  });

  test('a click adds a one-step note, selected, as one undo step', () {
    final c = _editing()..velocity = 70;
    c.addNoteAt(500, 64);
    expect(c.clip.notes.last,
        const MidiNote(startTick: 480, lengthTicks: 120, pitch: 64, velocity: 70));
    expect(c.selected, 1);
    expect(c.edited, isTrue);
    c.undo();
    expect(c.clip.notes, _clip.notes);
    expect(c.edited, isFalse, reason: 'back to the original');
    c.redo();
    expect(c.clip.notes, hasLength(2));
  });

  test('a drag moves from where the note started, and commits once', () {
    final c = _editing()..select(0);
    c.beginGesture();
    // Pointer moves in three steps; each preview starts from the original.
    c.moveSelection(100, 1);
    c.moveSelection(250, 2);
    c.moveSelection(470, 2);
    expect(c.clip.notes.single.startTick, 480);
    expect(c.clip.notes.single.pitch, 62);
    expect(c.canUndo, isFalse, reason: 'nothing committed mid-drag');
    c.endGesture();
    expect(c.canUndo, isTrue);
    c.undo();
    expect(c.clip.notes.single.startTick, 0);
  });

  test('a note cannot be moved before the start or off the keyboard', () {
    final c = _editing()..select(0);
    c.beginGesture();
    c.moveSelection(-1000, 100);
    expect(c.clip.notes.single.startTick, 0);
    expect(c.clip.notes.single.pitch, 127);
  });

  test('resizing snaps the end and keeps at least one step', () {
    final c = _editing()..select(0);
    c.beginGesture();
    c.resizeSelection(NoteEdge.end, 470);
    expect(c.clip.notes.single.lengthTicks, 960);
    c.resizeSelection(NoteEdge.end, -470);
    expect(c.clip.notes.single.lengthTicks, 120);
  });

  test('velocity is set and remembered for the next note', () {
    final c = _editing();
    c.beginGesture();
    c.drawVelocities(0, 200, 0, 200);
    expect(c.clip.notes.single.velocity, 127);
    c.endGesture();
    c.addNoteAt(960, 60);
    expect(c.clip.notes.last.velocity, 127);
  });

  test('deleting the selection is a step of its own', () {
    final c = _editing()..select(0);
    c.deleteSelected();
    expect(c.clip.notes, isEmpty);
    expect(c.selected, isNull);
    c.undo();
    expect(c.clip.notes, hasLength(1));
  });

  test('nothing is deleted outside edit mode', () {
    final c = MidiClipEditController(_clip)..select(0);
    c.deleteSelected();
    expect(c.clip.notes, hasLength(1));
  });

  test('drawing a lane writes one value per 128th, whatever the grid', () {
    final c = _editing();
    expect(c.laneStepTicks, 15, reason: '480 PPQ / 32');
    c.drawLane(MidiEventKind.controller, 1, 10, 20);
    c.drawLane(MidiEventKind.controller, 1, 130, 40);
    c.drawLane(MidiEventKind.controller, 1, 5, 30); // same step as the first
    c.endGesture();
    expect(c.clip.events.map((e) => (e.tick, e.number, e.value)),
        [(0, 1, 30), (120, 1, 40)]);
    c.drawLane(MidiEventKind.pitchBend, 0, 0, 99999);
    expect(c.clip.events.firstWhere((e) => e.kind == MidiEventKind.pitchBend).value,
        16383);
  });

  test('a cancelled gesture leaves nothing behind', () {
    final c = _editing()..select(0);
    c.beginGesture();
    c.moveSelection(960, 0);
    c.cancelGesture();
    expect(c.clip, same(_clip));
    expect(c.edited, isFalse);
  });

  test('a new edit clears redo', () {
    final c = _editing();
    c.addNoteAt(0, 62);
    c.undo();
    expect(c.canRedo, isTrue);
    c.addNoteAt(0, 64);
    expect(c.canRedo, isFalse);
  });

  test('finished: notes in order, length grown to a whole bar', () {
    final c = _editing();
    c.addNoteAt(1800, 72); // runs past the bar end, selected
    c.beginGesture();
    c.resizeSelection(NoteEdge.end, 480);
    c.endGesture();
    c.addNoteAt(0, 48);
    final out = c.finished;
    expect(out.notes.map((n) => n.pitch), [48, 60, 72]);
    expect(out.lengthTicks, 3840);
  });

  test('after saving, the saved clip is the new original', () {
    final c = _editing();
    c.addNoteAt(960, 67);
    expect(c.edited, isTrue);
    c.markSaved();
    expect(c.edited, isFalse);
    expect(c.canUndo, isTrue, reason: 'history survives a save');
  });

  test('leaving edit mode drops the selection', () {
    final c = _editing()..select(0);
    c.editing = false;
    expect(c.selected, isNull);
  });

  /// C3 on beat 1, E3 on beat 2, G3 on beat 3: a broken chord.
  const chord = MidiClip(
    name: 'Chord',
    ppq: 480,
    lengthTicks: 1920,
    notes: [
      MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: 90),
      MidiNote(startTick: 480, lengthTicks: 480, pitch: 64, velocity: 90),
      MidiNote(startTick: 960, lengthTicks: 480, pitch: 67, velocity: 90),
    ],
  );
  MidiClipEditController editingChord() =>
      MidiClipEditController(chord)..editing = true;

  group('selection', () {
    test('a box selects what sounds inside it, on its keys', () {
      final c = editingChord();
      // Beats 1–2, C3–F3.
      c.selectInBox(fromTick: 100, toTick: 900, lowPitch: 60, highPitch: 65);
      expect(c.selection, {0, 1});
      expect(c.selected, isNull, reason: 'more than one note is selected');
      c.selectInBox(fromTick: 480, toTick: 900, lowPitch: 0, highPitch: 127);
      expect(c.selection, {1}, reason: 'the note ending at 480 is outside');
    });

    test('a Shift box adds to what was selected', () {
      final c = editingChord()..select(2);
      c.selectInBox(
          fromTick: 0, toTick: 100, lowPitch: 0, highPitch: 127, keep: {2});
      expect(c.selection, {0, 2});
    });

    test('Shift-click toggles one note in and out', () {
      final c = editingChord()..select(0);
      c.toggleSelected(2);
      expect(c.selection, {0, 2});
      c.toggleSelected(0);
      expect(c.selection, {2});
    });

    test('select all, and nothing past the notes', () {
      final c = editingChord()..selectAll();
      expect(c.selection, {0, 1, 2});
      c.select(7);
      expect(c.selection, isEmpty);
    });
  });

  group('transposing', () {
    test('up/down moves every selected note, as one undo step', () {
      final c = editingChord()..selectAll();
      c.transposeSelection(1);
      expect(c.clip.notes.map((n) => n.pitch), [61, 65, 68]);
      c.transposeSelection(-12);
      expect(c.clip.notes.map((n) => n.pitch), [49, 53, 56]);
      c.undo();
      expect(c.clip.notes.map((n) => n.pitch), [61, 65, 68]);
    });

    test('only the selection moves', () {
      final c = editingChord()..select(1);
      c.transposeSelection(12);
      expect(c.clip.notes.map((n) => n.pitch), [60, 76, 67]);
    });

    test('stops at the keyboard edge without bending the chord', () {
      final c = MidiClipEditController(const MidiClip(
        name: 'High',
        ppq: 480,
        lengthTicks: 1920,
        notes: [
          MidiNote(startTick: 0, lengthTicks: 480, pitch: 120, velocity: 90),
          MidiNote(startTick: 0, lengthTicks: 480, pitch: 124, velocity: 90),
        ],
      ))
        ..editing = true
        ..selectAll();
      c.transposeSelection(12);
      expect(c.clip.notes.map((n) => n.pitch), [123, 127]);
      final before = c.clip;
      c.transposeSelection(1);
      expect(c.clip, same(before), reason: 'already at the top');
    });

    test('nothing moves outside edit mode or with nothing selected', () {
      final c = editingChord();
      c.transposeSelection(1);
      expect(c.edited, isFalse);
      final viewing = MidiClipEditController(chord)..selectAll();
      viewing.transposeSelection(1);
      expect(viewing.edited, isFalse);
    });
  });

  group('dragging a selection', () {
    test('moves every selected note by the same amount', () {
      final c = editingChord()..selectAll();
      c.beginGesture();
      c.moveSelection(250, -2);
      c.endGesture();
      expect(c.clip.notes.map((n) => (n.startTick, n.pitch)),
          [(240, 58), (720, 62), (1200, 65)]);
    });

    test('stops at the clip start without squashing the selection', () {
      final c = editingChord()
        ..select(1)
        ..toggleSelected(2);
      c.beginGesture();
      c.moveSelection(-2000, 0);
      expect(c.clip.notes.map((n) => n.startTick), [0, 0, 480]);
    });

    test('Ctrl ignores the grid', () {
      final c = editingChord()..select(0);
      c.beginGesture();
      c.moveSelection(37, 0, free: true);
      expect(c.clip.notes.first.startTick, 37);
      c.moveSelection(37, 0);
      expect(c.clip.notes.first.startTick, 0, reason: 'snapped to 1/16');
    });

    test('an Alt-drag moves copies and leaves the originals', () {
      final c = editingChord()..select(0);
      c.beginGesture(duplicate: true);
      expect(c.selection, {3}, reason: 'the copy is what is selected');
      c.moveSelection(1440, 0);
      c.endGesture();
      expect(c.clip.notes.map((n) => (n.startTick, n.pitch)),
          [(0, 60), (480, 64), (960, 67), (1440, 60)]);
      c.undo();
      expect(c.clip.notes, chord.notes, reason: 'one undo step');
    });

    test('a copy that never moved is dropped', () {
      final c = editingChord()..select(0);
      c.beginGesture(duplicate: true);
      c.moveSelection(10, 0); // under one step: snaps back onto the original
      c.endGesture();
      expect(c.clip.notes, chord.notes);
      expect(c.canUndo, isFalse);
      expect(c.selection, isEmpty);
    });
  });

  group('resizing from either edge', () {
    test("the end edge changes every selected note's length", () {
      final c = editingChord()
        ..select(0)
        ..toggleSelected(1);
      c.beginGesture();
      c.resizeSelection(NoteEdge.end, 240);
      c.endGesture();
      expect(c.clip.notes.map((n) => n.lengthTicks), [720, 720, 480]);
    });

    test('the start edge moves where a note begins, not where it ends', () {
      final c = editingChord()..select(1);
      c.beginGesture();
      c.resizeSelection(NoteEdge.start, -240);
      expect(c.clip.notes[1].startTick, 240);
      expect(c.clip.notes[1].endTick, 960);
      c.resizeSelection(NoteEdge.start, 1000);
      expect(c.clip.notes[1].lengthTicks, 120, reason: 'one step at least');
      expect(c.clip.notes[1].endTick, 960);
      c.resizeSelection(NoteEdge.start, -2000);
      expect(c.clip.notes[1].startTick, 0, reason: 'not before the clip');
    });

    test('Ctrl resizes to the tick, down to one tick long', () {
      final c = editingChord()..select(0);
      c.beginGesture();
      c.resizeSelection(NoteEdge.end, 13, free: true);
      expect(c.clip.notes.first.lengthTicks, 493);
      c.resizeSelection(NoteEdge.end, -1000, free: true);
      expect(c.clip.notes.first.lengthTicks, 1);
    });
  });

  group('double-click actions', () {
    test('deleting one note is an undo step and clears the selection', () {
      final c = editingChord()..select(1);
      c.deleteNote(1);
      expect(c.clip.notes.map((n) => n.pitch), [60, 67]);
      expect(c.selection, isEmpty);
      c.undo();
      expect(c.clip.notes, chord.notes);
    });

    test('nothing is deleted outside edit mode', () {
      final c = MidiClipEditController(chord)..deleteNote(0);
      expect(c.clip.notes, hasLength(3));
    });

    test('deleting the selection removes every selected note', () {
      final c = editingChord()
        ..select(0)
        ..toggleSelected(2);
      c.deleteSelected();
      expect(c.clip.notes.map((n) => n.pitch), [64]);
    });
  });

  group('the pencil', () {
    test('a drawn note is selected, stretched, and one undo step', () {
      final c = editingChord();
      c.beginNote(1450, 72);
      expect(c.selection, {3});
      expect(c.clip.notes.last,
          const MidiNote(startTick: 1440, lengthTicks: 120, pitch: 72, velocity: 100));
      c.resizeSelection(NoteEdge.end, 240);
      c.endGesture();
      expect(c.clip.notes.last.lengthTicks, 360);
      expect(c.canUndo, isTrue);
      c.undo();
      expect(c.clip.notes, chord.notes, reason: 'drawing and stretching undo together');
    });

    test('a click without a drag keeps a one-step note', () {
      final c = editingChord()..beginNote(0, 50);
      c.endGesture();
      expect(c.clip.notes, hasLength(4));
    });

    test('a cancelled drawing leaves nothing, not even a selection', () {
      final c = editingChord()..beginNote(0, 50);
      c.cancelGesture();
      expect(c.clip.notes, chord.notes);
      expect(c.selection, isEmpty);
      expect(c.canUndo, isFalse);
    });

    test('the tool is select until changed, and says when it is', () {
      final c = editingChord();
      expect(c.tool, MidiEditTool.select);
      var told = 0;
      c.addListener(() => told++);
      c.tool = MidiEditTool.pencil;
      c.tool = MidiEditTool.pencil;
      expect(told, 1);
    });
  });

  group('drawing velocities', () {
    test('a line across the stems sets every note it passes', () {
      final c = editingChord();
      c.beginGesture();
      c.drawVelocities(0, 120, 960, 20);
      c.endGesture();
      expect(c.clip.notes.map((n) => n.velocity), [120, 70, 20]);
      expect(c.velocity, 20, reason: 'the next note gets the last value');
      c.undo();
      expect(c.clip.notes, chord.notes, reason: 'one undo step');
    });

    test('drawn right to left all the same', () {
      final c = editingChord();
      c.drawVelocities(960, 20, 0, 120);
      expect(c.clip.notes.map((n) => n.velocity), [120, 70, 20]);
    });

    test('a chord on one stem all takes the value', () {
      final c = MidiClipEditController(const MidiClip(
        name: 'Chord',
        ppq: 480,
        lengthTicks: 1920,
        notes: [
          MidiNote(startTick: 480, lengthTicks: 480, pitch: 60, velocity: 90),
          MidiNote(startTick: 480, lengthTicks: 480, pitch: 64, velocity: 80),
          MidiNote(startTick: 960, lengthTicks: 480, pitch: 67, velocity: 70),
        ],
      ))
        ..editing = true;
      c.drawVelocities(480, 30, 480, 30);
      expect(c.clip.notes.map((n) => n.velocity), [30, 30, 70]);
    });

    test('with several notes selected, only they change', () {
      final c = editingChord()
        ..select(0)
        ..toggleSelected(2);
      c.drawVelocities(0, 120, 960, 20);
      expect(c.clip.notes.map((n) => n.velocity), [120, 90, 20]);
      c.select(1); // one selected: a sweep is a sweep again
      c.drawVelocities(0, 10, 960, 10);
      expect(c.clip.notes.map((n) => n.velocity), [10, 10, 10]);
    });

    test('only notes starting inside the stretch change', () {
      final c = editingChord();
      c.drawVelocities(400, 50, 900, 50);
      expect(c.clip.notes.map((n) => n.velocity), [90, 50, 90]);
    });
  });

  group('drawing a lane along a line', () {
    test('a fast drag leaves no gaps: every step between is drawn', () {
      final c = editingChord();
      c.drawLane(MidiEventKind.controller, 1, 0, 0);
      c.drawLane(MidiEventKind.controller, 1, 60, 100, fromTick: 0, fromValue: 0);
      expect(c.clip.events.map((e) => (e.tick, e.value)),
          [(0, 0), (15, 25), (30, 50), (45, 75), (60, 100)]);
    });

    test('drawing back over a stretch replaces it', () {
      final c = editingChord();
      c.drawLane(MidiEventKind.pitchBend, 0, 60, 16383, fromTick: 0, fromValue: 16383);
      c.drawLane(MidiEventKind.pitchBend, 0, 0, 8192, fromTick: 60, fromValue: 8192);
      expect(c.clip.events.map((e) => (e.tick, e.value)), [(0, 8192)]);
    });

    test('other lanes are left alone', () {
      final c = editingChord();
      c.drawLane(MidiEventKind.controller, 1, 0, 64);
      c.drawLane(MidiEventKind.controller, 74, 30, 10, fromTick: 0, fromValue: 10);
      expect(
          c.clip.events
              .where((e) => e.number == 1)
              .map((e) => (e.tick, e.value)),
          [(0, 64)]);
    });
  });

  group('the range tool', () {
    test('a range snaps each end to the nearest grid line, and selects '
        'what starts in it', () {
      final c = editingChord();
      c.selectRange(560, 130); // either way round
      expect(c.range, (start: 120, end: 600));
      expect(c.selection, {1}, reason: 'only E3 starts inside');
      c.selectRange(10, 10);
      expect(c.range, (start: 0, end: 120), reason: 'at least one step');
    });

    test('anything else that selects lets the range go', () {
      final c = editingChord()..selectRange(0, 960);
      c.select(2);
      expect(c.range, isNull);
      c.selectRange(0, 960);
      c.tool = MidiEditTool.pencil;
      expect(c.range, isNull, reason: 'another tool');
    });
  });

  group('duplicate', () {
    test('a range is copied straight after itself, cut at its end, events '
        'and all, and moves onto the copy', () {
      final c = MidiClipEditController(const MidiClip(
        name: 'Riff',
        ppq: 480,
        lengthTicks: 1920,
        notes: [
          MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 90),
          MidiNote(startTick: 240, lengthTicks: 720, pitch: 62, velocity: 90),
        ],
        events: [
          MidiEvent(tick: 120, kind: MidiEventKind.controller, number: 1, value: 64),
          MidiEvent(tick: 360, kind: MidiEventKind.controller, number: 1, value: 0),
        ],
      ))
        ..editing = true;
      c.selectRange(0, 480);
      c.duplicate();
      expect(c.clip.notes.map((n) => (n.startTick, n.lengthTicks, n.pitch)), [
        (0, 240, 60),
        (240, 720, 62),
        (480, 240, 60),
        (720, 240, 62), // cut off at the range's end
      ]);
      expect(c.clip.events.map((e) => (e.tick, e.value)),
          [(120, 64), (360, 0), (600, 64), (840, 0)]);
      expect(c.range, (start: 480, end: 960));
      expect(c.selection, {2, 3});

      c.duplicate(); // and again: the pattern carries on
      expect(c.clip.notes.map((n) => n.startTick), [0, 240, 480, 720, 960, 1200]);
      c.undo();
      c.undo();
      expect(c.clip.notes, hasLength(2), reason: 'one undo step each');
    });

    test('selected notes are copied to start where the last one ends', () {
      final c = editingChord()
        ..select(0)
        ..toggleSelected(1);
      // C3 at 0 and E3 at 480, each 480 long: the pair ends at 960.
      c.duplicate();
      expect(c.clip.notes.map((n) => (n.startTick, n.pitch)).skip(3),
          [(960, 60), (1440, 64)]);
      expect(c.selection, {3, 4}, reason: 'the copies, ready to go again');
      c.duplicate();
      expect(c.clip.notes.map((n) => n.startTick).skip(5), [1920, 2400]);
    });

    test('exactly where the last note ends, on the grid or not', () {
      final c = MidiClipEditController(const MidiClip(
        name: 'Short',
        ppq: 480,
        lengthTicks: 1920,
        notes: [MidiNote(startTick: 0, lengthTicks: 100, pitch: 60, velocity: 90)],
      ))
        ..editing = true
        ..select(0);
      c.duplicate();
      expect(c.clip.notes.last.startTick, 100,
          reason: 'not the next 1/16: right after the note, on purpose');
    });

    test('nothing selected, or not editing: nothing happens', () {
      final c = editingChord()..duplicate();
      expect(c.edited, isFalse);
      final viewing = MidiClipEditController(chord)..select(0);
      viewing.duplicate();
      expect(viewing.edited, isFalse);
    });
  });

  group('the eraser', () {
    test('notes erased in one drag are one undo step', () {
      final c = editingChord()..beginGesture();
      c.eraseNote(0);
      c.eraseNote(0); // what was E3, now first
      c.endGesture();
      expect(c.clip.notes.map((n) => n.pitch), [67]);
      c.undo();
      expect(c.clip.notes, chord.notes);
    });

    test('over a lane it takes the points it passes', () {
      final c = editingChord();
      c.drawLane(MidiEventKind.controller, 1, 90, 100, fromTick: 0, fromValue: 10);
      c.endGesture();
      c.beginGesture();
      c.eraseLane(MidiEventKind.controller, 1, 50, 30);
      c.endGesture();
      expect(c.clip.events.map((e) => e.tick), [0, 15, 60, 75, 90]);
    });
  });

  group('quantize', () {
    const loose = MidiClip(
      name: 'Loose',
      ppq: 480,
      lengthTicks: 1920,
      notes: [
        MidiNote(startTick: 10, lengthTicks: 200, pitch: 60, velocity: 90),
        MidiNote(startTick: 470, lengthTicks: 300, pitch: 64, velocity: 90),
        MidiNote(startTick: 905, lengthTicks: 100, pitch: 67, velocity: 90),
      ],
    );

    test('with nothing selected, every start goes to the nearest step; '
        'lengths stay', () {
      final c = MidiClipEditController(loose)..editing = true;
      c.quantize();
      expect(c.clip.notes.map((n) => (n.startTick, n.lengthTicks)),
          [(0, 200), (480, 300), (960, 100)]);
      c.undo();
      expect(c.clip.notes, loose.notes, reason: 'one undo step');
    });

    test('only the selection, when there is one, on the grid set', () {
      final c = MidiClipEditController(loose)
        ..editing = true
        ..snap = MidiSnap.quarter
        ..select(2);
      c.quantize();
      expect(c.clip.notes.map((n) => n.startTick), [10, 470, 960]);
      expect(c.selection, {2}, reason: 'still selected, to go again');
    });

    test('snapping off quantizes to 1/16; already on the grid is no step',
        () {
      final c = MidiClipEditController(loose)
        ..editing = true
        ..snap = MidiSnap.off;
      c.quantize();
      expect(c.clip.notes.map((n) => n.startTick), [0, 480, 960]);
      c.quantize();
      expect(c.canUndo, isTrue);
      c.undo();
      expect(c.canUndo, isFalse, reason: 'the second did nothing');
    });
  });

  group('a clip grows with its notes', () {
    test('a note past the end grows it to that bar; undo shrinks it', () {
      final c = editingChord();
      c.addNoteAt(1900, 72); // a 1/16 from 1800, ending past the bar
      expect(c.clip.lengthTicks, 1920, reason: 'ends at 1920 exactly');
      c.beginGesture();
      c.resizeSelection(NoteEdge.end, 480);
      c.endGesture();
      expect(c.clip.lengthTicks, 3840);
      c.addNoteAt(9000, 60);
      expect(c.clip.lengthTicks, 9600);
      c.undo();
      expect(c.clip.lengthTicks, 3840);
    });

    test('nothing past the end: the very same clip', () {
      expect(grownToNotes(chord), same(chord));
    });
  });

  group('range snapping', () {
    test('each end goes to the nearest line, not the next one', () {
      final c = editingChord();
      c.selectRange(50, 170); // under half a step past 0 and past 120
      expect(c.range, (start: 0, end: 120));
      c.selectRange(70, 290);
      expect(c.range, (start: 120, end: 240));
    });

    test('an end dragged moves to the nearest line, never past the other',
        () {
      final c = editingChord()..selectRange(0, 960);
      c.adjustRange(NoteEdge.end, 1470);
      expect(c.range, (start: 0, end: 1440));
      expect(c.selection, {0, 1, 2}, reason: 'G3 at 960 is now inside');
      c.adjustRange(NoteEdge.start, 2000);
      expect(c.range, (start: 1320, end: 1440), reason: 'a step short of the end');
      c.adjustRange(NoteEdge.end, 0);
      expect(c.range, (start: 1320, end: 1440), reason: 'a step past the start');
    });
  });

  group('time signature', () {
    test('a clip grows by its own bars', () {
      final c = editingChord()..timeSignature = const TimeSignature(3, 4);
      c.addNoteAt(1900, 72);
      c.beginGesture();
      c.resizeSelection(NoteEdge.end, 240);
      c.endGesture();
      // Ends at 2160: past 1920, into the second 3/4 bar (1440–2880).
      expect(c.clip.lengthTicks, 2880);
      expect(grownToNotes(c.clip, barTicks: 1440), same(c.clip));
    });
  });

  group('the pencil sets how hard', () {
    test('up and down while drawing: that note only, the next starts fresh',
        () {
      final c = editingChord()..beginNote(0, 50);
      c.setDrawnVelocity(127);
      c.resizeSelection(NoteEdge.end, 240);
      c.endGesture();
      expect(c.clip.notes.last.velocity, 127);
      expect(c.clip.notes.last.lengthTicks, 360, reason: 'length kept too');
      expect(c.velocity, 100, reason: 'not carried over');
      c.beginNote(960, 52);
      c.endGesture();
      expect(c.clip.notes.last.velocity, 100);
    });

    test('only while drawing', () {
      final c = editingChord()..select(0);
      c.setDrawnVelocity(10);
      expect(c.clip.notes.first.velocity, 90);
    });
  });

  group('a drafted clip is as long as its notes', () {
    test('it grows and shrinks bar by bar, a bar at least', () {
      final c = MidiClipEditController(
          const MidiClip(name: 'Idea', ppq: 480, lengthTicks: 1920, notes: []))
        ..editing = true
        ..lengthFollowsNotes = true;
      c.addNoteAt(5000, 60); // in the third bar
      expect(c.clip.lengthTicks, 5760);
      c.deleteNote(0);
      expect(c.clip.lengthTicks, 1920, reason: 'nothing left: one bar');
      c.addNoteAt(100, 60);
      expect(c.finished.lengthTicks, 1920);
    });

    test('a clip from a project keeps its length when notes go', () {
      final c = editingChord()..deleteNote(2);
      expect(c.clip.lengthTicks, 1920);
    });

    test('fittedToNotes: the bar the last note ends in', () {
      const clip = MidiClip(
        name: 'x',
        ppq: 480,
        lengthTicks: 9600,
        notes: [MidiNote(startTick: 1400, lengthTicks: 100, pitch: 60, velocity: 90)],
      );
      expect(fittedToNotes(clip, barTicks: 1440).lengthTicks, 2880,
          reason: 'ends at 1500: into the second 3/4 bar');
      expect(fittedToNotes(clip, barTicks: 1920).lengthTicks, 1920);
    });
  });
}
