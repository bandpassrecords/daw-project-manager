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
    final c = _editing();
    // Pointer moves in three steps; each preview starts from the original.
    c.moveNote(0, 100, 1);
    c.moveNote(0, 250, 2);
    c.moveNote(0, 470, 2);
    expect(c.clip.notes.single.startTick, 480);
    expect(c.clip.notes.single.pitch, 62);
    expect(c.canUndo, isFalse, reason: 'nothing committed mid-drag');
    c.endGesture();
    expect(c.canUndo, isTrue);
    c.undo();
    expect(c.clip.notes.single.startTick, 0);
  });

  test('a note cannot be moved before the start or off the keyboard', () {
    final c = _editing();
    c.moveNote(0, -1000, 100);
    expect(c.clip.notes.single.startTick, 0);
    expect(c.clip.notes.single.pitch, 127);
  });

  test('resizing snaps the end and keeps at least one step', () {
    final c = _editing();
    c.resizeNote(0, 950);
    expect(c.clip.notes.single.lengthTicks, 960);
    c.resizeNote(0, 10);
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
    final c = _editing();
    c.moveNote(0, 960, 0);
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
    c.addNoteAt(1800, 72); // runs past the bar end
    c.resizeNote(1, 2400);
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
}
