import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/ui/widgets/midi_clip_edit_controller.dart';

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
    c.setVelocity(0, 200);
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

  test('drawing a lane writes one value per grid step', () {
    final c = _editing();
    c.drawLane(MidiEventKind.controller, 1, 10, 20);
    c.drawLane(MidiEventKind.controller, 1, 130, 40);
    c.drawLane(MidiEventKind.controller, 1, 100, 30); // same step as the first
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
}
