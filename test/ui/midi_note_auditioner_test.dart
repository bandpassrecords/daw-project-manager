import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/midi_note_auditioner.dart';

void main() {
  test('velocities fall into a few loudness steps, never silent', () {
    expect(auditionVelocity(1), 16);
    expect(auditionVelocity(100), 96);
    expect(auditionVelocity(103), 96);
    expect(auditionVelocity(127), 127);
    expect(auditionVelocity(300), 127);
    final steps = {for (var v = 1; v <= 127; v++) auditionVelocity(v)};
    expect(steps.length, lessThanOrEqualTo(8));
  });

  test('a note is sounded as a short one-note clip', () {
    final clip = MidiNoteAuditioner.clipFor(64, 100);
    final note = clip.notes.single;
    expect((note.pitch, note.velocity, note.startTick), (64, 96, 0));
    expect(note.lengthTicks, lessThan(clip.lengthTicks));
    expect(note.lengthTicks, lessThanOrEqualTo(120),
        reason: 'a short blip: at 120 BPM a 16th, an eighth of a second');
    expect(MidiNoteAuditioner.clipFor(200, 100).notes.single.pitch, 127);
  });

  test('a held note is long enough to outlast a press, and renders apart',
      () {
    final held = MidiNoteAuditioner.clipFor(60, 100, held: true);
    expect(held.notes.single.lengthTicks, greaterThanOrEqualTo(8 * 480));
    expect(held.contentKey,
        isNot(MidiNoteAuditioner.clipFor(60, 100).contentKey));
    expect(heldNoteForTest().released, isFalse);
  });

  test('the same note and loudness renders once', () {
    expect(MidiNoteAuditioner.clipFor(60, 100).contentKey,
        MidiNoteAuditioner.clipFor(60, 98).contentKey);
    expect(MidiNoteAuditioner.clipFor(60, 100).contentKey,
        isNot(MidiNoteAuditioner.clipFor(61, 100).contentKey));
  });
}
