import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';

MidiNote n(int start, int length, [int pitch = 60, int velocity = 100]) =>
    MidiNote(
      startTick: start,
      lengthTicks: length,
      pitch: pitch,
      velocity: velocity,
    );

MidiClip clip(String name, List<MidiNote> notes,
        {String? track, int length = 1920}) =>
    MidiClip(
      name: name,
      trackName: track,
      ppq: 480,
      lengthTicks: length,
      notes: notes,
    );

void main() {
  group('windowMidiNotes', () {
    test('keeps notes inside the window and re-bases them to 0', () {
      final out = windowMidiNotes(
        [n(0, 100), n(500, 100), n(1000, 100)],
        windowStart: 400,
        windowLength: 1000,
      );
      expect(out, [n(100, 100), n(600, 100)]);
    });

    test('drops notes that start before the window (trimmed-away material)',
        () {
      // Cubase keeps notes before a trimmed part's start; they must not play.
      final out = windowMidiNotes(
        [n(-92160, 120), n(0, 120)],
        windowStart: 0,
        windowLength: 480,
      );
      expect(out, [n(0, 120)]);
    });

    test('shortens a note that runs past the window end', () {
      final out =
          windowMidiNotes([n(400, 480)], windowStart: 0, windowLength: 480);
      expect(out, [n(400, 80)]);
    });

    test('unrolls a loop until the window is full', () {
      // A 1-beat loop of one note, played for 3 beats.
      final out = windowMidiNotes(
        [n(0, 240), n(600, 100)], // the second note is outside the loop
        windowStart: 0,
        windowLength: 1440,
        loop: true,
        loopStart: 0,
        loopEnd: 480,
      );
      expect(out.map((x) => x.startTick), [0, 480, 960]);
    });

    test('a window starting mid-loop plays to the loop end, then wraps', () {
      final out = windowMidiNotes(
        [n(0, 100), n(240, 100)],
        windowStart: 240,
        windowLength: 720,
        loop: true,
        loopStart: 0,
        loopEnd: 480,
      );
      // 240 → 0 (first pass), then wrap: 0 → 240, 240 → 480.
      expect(out.map((x) => x.startTick), [0, 240, 480]);
    });

    test('an empty or negative window yields nothing', () {
      expect(windowMidiNotes([n(0, 1)], windowStart: 0, windowLength: 0),
          isEmpty);
    });

    test('result is sorted by time, then pitch', () {
      final out = windowMidiNotes(
        [n(10, 5, 64), n(0, 5, 60), n(10, 5, 62)],
        windowStart: 0,
        windowLength: 100,
      );
      expect(out.map((x) => x.pitch), [60, 62, 64]);
    });
  });

  group('dedupeMidiClips', () {
    test('collapses clips that play the same notes, whatever their names',
        () {
      final a = clip('Riff', [n(0, 240)], track: 'Synth A');
      final b = clip('Riff copy', [n(0, 240)], track: 'Synth B');
      final c = clip('Riff', [n(0, 240, 62)]);
      final out = dedupeMidiClips([a, b, c, a]);
      expect(out, hasLength(2));
      expect(out.first.occurrences, 3);
      expect(out.first.label, 'Synth A – Riff', reason: 'first seen wins');
      expect(out.first.otherNames, ['Synth B – Riff copy'],
          reason: 'a repeat of the first clip adds no name');
      expect(out.last.occurrences, 1);
      expect(out.last.otherNames, isEmpty);
    });

    test('the same notes at another resolution are the same clip', () {
      final at480 = clip('A', [n(0, 240), n(480, 240, 64)], length: 1920);
      final at960 = MidiClip(
        name: 'B',
        ppq: 960,
        lengthTicks: 3840,
        notes: [n(0, 480), n(960, 480, 64)],
      );
      expect(dedupeMidiClips([at480, at960]).single.occurrences, 2);
    });

    test('the MIDI channel does not make a clip different', () {
      final ch0 = clip('A', [n(0, 240)]);
      final ch9 = clip('A', const [
        MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100, channel: 9),
      ]);
      expect(dedupeMidiClips([ch0, ch9]), hasLength(1));
    });

    test('velocity and transposition do make a clip different', () {
      final out = dedupeMidiClips([
        clip('A', [n(0, 240, 60, 100)]),
        clip('A', [n(0, 240, 60, 90)]),
        clip('A', [n(0, 240, 62, 100)]),
      ]);
      expect(out, hasLength(3));
    });

    test('a longer clip that only repeats a shorter one merges into it', () {
      final bar = [n(0, 240, 36), n(960, 240, 38)];
      final oneBar = clip('Beat', bar, length: 1920);
      final fourBars = clip('Beat long', [
        for (var b = 0; b < 4; b++)
          for (final x in bar) n(x.startTick + b * 1920, 240, x.pitch),
      ], length: 4 * 1920);
      final out = dedupeMidiClips([fourBars, oneBar]);
      expect(out.single.occurrences, 2);
      expect(out.single.lengthTicks, 1920);
      expect(out.single.name, 'Beat long');
    });

    test('drops clips with no notes', () {
      expect(dedupeMidiClips([clip('Empty', const [])]), isEmpty);
    });

    test('same notes but a different length are different clips', () {
      final out = dedupeMidiClips([
        clip('A', [n(0, 10)], length: 480),
        clip('A', [n(0, 10)], length: 960),
      ]);
      expect(out, hasLength(2));
    });
  });

  group('reduceToRepeatingPattern', () {
    List<MidiNote> repeat(List<MidiNote> bar, int bars, {int barTicks = 1920}) => [
          for (var b = 0; b < bars; b++)
            for (final x in bar)
              n(x.startTick + b * barTicks, x.lengthTicks, x.pitch, x.velocity),
        ];

    test('shrinks an exact repetition to the fewest whole bars', () {
      final twoBar = [n(0, 240, 36), n(1920, 240, 43)];
      final c = clip('x', repeat(twoBar, 3, barTicks: 3840), length: 6 * 1920);
      final r = reduceToRepeatingPattern(c);
      expect(r.lengthTicks, 3840);
      expect(r.notes, twoBar);
    });

    test('accepts a final repeat that was cut short', () {
      final bar = [n(0, 240), n(960, 240)];
      final notes = repeat(bar, 3)..removeLast(); // 2.5 bars
      final r = reduceToRepeatingPattern(clip('x', notes, length: 1920 * 2 + 960));
      expect(r.lengthTicks, 1920);
      expect(r.notes, bar);
    });

    test('leaves a clip that never repeats exactly alone', () {
      final notes = [...repeat([n(0, 240)], 3), n(3 * 1920, 240, 61)];
      final c = clip('x', notes, length: 4 * 1920);
      expect(identical(reduceToRepeatingPattern(c), c), isTrue);
    });

    test('one changed velocity breaks the repetition', () {
      final notes = repeat([n(0, 240)], 4);
      notes[3] = n(3 * 1920, 240, 60, 90);
      final c = clip('x', notes, length: 4 * 1920);
      expect(reduceToRepeatingPattern(c).lengthTicks, 4 * 1920);
    });

    test('a clip of one bar or less is already as short as it gets', () {
      final c = clip('x', [n(0, 240), n(480, 240)], length: 960);
      expect(identical(reduceToRepeatingPattern(c), c), isTrue);
    });
  });

  test('label combines track and clip without repeating either', () {
    expect(clip('Riff', const [], track: 'Bass').label, 'Bass – Riff');
    expect(clip('Bass', const [], track: 'Bass').label, 'Bass');
    expect(clip('', const [], track: 'Bass').label, 'Bass');
    expect(clip('Riff', const []).label, 'Riff');
  });

  test('lengthBeats converts ticks with the clip PPQ', () {
    expect(clip('x', const [], length: 960).lengthBeats, 2);
  });

  group('groupMidiClipsByTrack', () {
    test('groups by track in first-seen order, trackless clips last', () {
      final clips = [
        clip('a', const [], track: 'Bass'),
        clip('b', const []),
        clip('c', const [], track: 'Lead'),
        clip('d', const [], track: 'Bass'),
        clip('e', const [], track: '  '),
      ];
      final groups = groupMidiClipsByTrack(clips);
      expect(groups.map((g) => g.trackName), ['Bass', 'Lead', null]);
      expect(groups.map((g) => g.clipIndices), [
        [0, 3],
        [2],
        [1, 4],
      ]);
    });

    test('a track name with stray spaces is still the same track', () {
      final groups = groupMidiClipsByTrack([
        clip('a', const [], track: 'Bass'),
        clip('b', const [], track: 'Bass '),
      ]);
      expect(groups.single.clipIndices, [0, 1]);
    });

    test('no clips, no groups', () {
      expect(groupMidiClipsByTrack(const []), isEmpty);
    });
  });
}
