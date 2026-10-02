import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/midi_clip_synth.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';

MidiClip _clip(List<MidiNote> notes, {int length = 1920}) =>
    MidiClip(name: 'x', ppq: 480, lengthTicks: length, notes: notes);

Int16List _samples(Uint8List wav) {
  final d = ByteData.sublistView(wav);
  final n = d.getUint32(40, Endian.little) ~/ 2;
  return Int16List.fromList(
      [for (var i = 0; i < n; i++) d.getInt16(44 + i * 2, Endian.little)]);
}

void main() {
  const synth = MidiClipSynth(sampleRate: 8000);

  test('writes a valid 16-bit mono PCM WAV header', () {
    final wav = synth.renderWav(_clip(const [
      MidiNote(startTick: 0, lengthTicks: 480, pitch: 69, velocity: 100),
    ]));
    final d = ByteData.sublistView(wav);
    expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
    expect(d.getUint32(4, Endian.little), wav.length - 8);
    expect(ascii.decode(wav.sublist(8, 16)), 'WAVEfmt ');
    expect(d.getUint16(20, Endian.little), 1, reason: 'PCM');
    expect(d.getUint16(22, Endian.little), 1, reason: 'mono');
    expect(d.getUint32(24, Endian.little), 8000);
    expect(d.getUint16(34, Endian.little), 16);
    expect(ascii.decode(wav.sublist(36, 40)), 'data');
    expect(d.getUint32(40, Endian.little), wav.length - 44);
  });

  test('lasts the clip length at the given tempo, plus the release tail', () {
    // 4 beats at 120 BPM = 2 s, + 0.15 s release.
    final seconds = synth.durationSeconds(_clip(const [], length: 1920), 120);
    expect(seconds, closeTo(2.15, 1e-9));
    final wav = synth.renderWav(_clip(const [], length: 1920), bpm: 120);
    expect(_samples(wav).length, (2.15 * 8000).ceil());
  });

  test('defaults to 120 BPM when the project tempo is unknown', () {
    final a = synth.renderWav(_clip(const [], length: 960));
    final b = synth.renderWav(_clip(const [], length: 960), bpm: 120);
    expect(a.length, b.length);
  });

  test('sound where the note is, silence where it is not', () {
    final s = _samples(synth.renderWav(
      _clip(const [MidiNote(startTick: 960, lengthTicks: 480, pitch: 60, velocity: 127)]),
      bpm: 120,
    ));
    int peak(int fromSec10, int toSec10) {
      var p = 0;
      for (var i = fromSec10 * 800; i < toSec10 * 800; i++) {
        if (s[i].abs() > p) p = s[i].abs();
      }
      return p;
    }

    expect(peak(0, 9), 0, reason: 'before the note at 1 s');
    expect(peak(10, 14), greaterThan(1000), reason: 'during the note');
  });

  test('a dense chord is pulled back from clipping', () {
    final chord = [
      for (var p = 40; p < 80; p++)
        MidiNote(startTick: 0, lengthTicks: 960, pitch: p, velocity: 127),
    ];
    final s = _samples(synth.renderWav(_clip(chord), bpm: 120));
    final peak = s.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    expect(peak, lessThanOrEqualTo((0.9 * 32767).round() + 1));
    expect(peak, greaterThan(20000));
  });

  test('louder velocity, louder note', () {
    int peakFor(int velocity) {
      final s = _samples(synth.renderWav(_clip([
        MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: velocity),
      ]), bpm: 120));
      return s.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    }

    expect(peakFor(127), greaterThan(peakFor(40)));
  });

  group('events', () {
    const note = MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: 100);
    MidiClip withEvents(List<MidiEvent> events) => MidiClip(
        name: 'x', ppq: 480, lengthTicks: 1920, notes: const [note], events: events);
    MidiEvent cc(int tick, int number, int value) => MidiEvent(
        tick: tick, kind: MidiEventKind.controller, number: number, value: value);

    int peak(Int16List s, [int from = 0, int? to]) {
      var p = 0;
      for (var i = from; i < (to ?? s.length); i++) {
        if (s[i].abs() > p) p = s[i].abs();
      }
      return p;
    }

    test('ClipControls: loudness follows volume × expression, squared', () {
      final c = ClipControls(withEvents([cc(0, 7, 127), cc(480, 11, 64)]));
      expect(c.loudnessAt(0, 0), 1.0);
      expect(c.loudnessAt(0, 480), closeTo(math.pow(64 / 127, 2), 1e-9));
      expect(c.loudnessAt(1, 480), 1.0, reason: 'another channel is untouched');
    });

    test('ClipControls: a note let go under the pedal rings to pedal-up', () {
      final c = ClipControls(withEvents([cc(0, 64, 127), cc(1440, 64, 0)]));
      expect(c.sustainedUntil(0, 480), 1440);
      expect(c.sustainedUntil(0, 1500), 1500, reason: 'pedal is up by then');
      final held = ClipControls(withEvents([cc(0, 64, 127)]));
      expect(held.sustainedUntil(0, 480), 1920,
          reason: 'a pedal never lifted holds to the end of the clip');
    });

    test('ClipControls: bends are ratios over ±2 semitones', () {
      final c = ClipControls(withEvents(const [
        MidiEvent(tick: 0, kind: MidiEventKind.pitchBend, value: 8192),
        MidiEvent(tick: 240, kind: MidiEventKind.pitchBend, value: 16383),
        MidiEvent(tick: 480, kind: MidiEventKind.pitchBend, value: 0),
      ]));
      final ratios = c.bendRatios(0);
      expect(ratios[0], (0, 1.0));
      expect(ratios[1].$2, closeTo(math.pow(2, 2 / 12), 1e-3));
      expect(ratios[2].$2, closeTo(math.pow(2, -2 / 12), 1e-9));
    });

    test('a bend changes what is heard; a clip without events is unchanged', () {
      final plain = synth.renderWav(_clip(const [note]), bpm: 120);
      expect(synth.renderWav(withEvents(const []), bpm: 120), plain);
      final bent = synth.renderWav(withEvents(const [
        MidiEvent(tick: 240, kind: MidiEventKind.pitchBend, value: 16383),
      ]), bpm: 120);
      expect(listEquals(bent, plain), isFalse);
    });

    test('the sustain pedal keeps a released note sounding', () {
      // 480 ticks at 120 BPM = 0.5 s = 4000 frames; look well after release.
      final dry = _samples(synth.renderWav(withEvents(const []), bpm: 120));
      final pedalled = _samples(synth.renderWav(
          withEvents([cc(0, 64, 127), cc(1440, 64, 0)]),
          bpm: 120));
      expect(peak(pedalled, 9000, 11000), greaterThan(peak(dry, 9000, 11000)));
    });

    test('volume turned down plays quieter', () {
      final full = _samples(synth.renderWav(withEvents(const []), bpm: 120));
      final quiet =
          _samples(synth.renderWav(withEvents([cc(0, 7, 40)]), bpm: 120));
      expect(peak(quiet), lessThan(peak(full)));
    });
  });

  test('a very long clip is capped instead of allocating minutes of audio', () {
    const capped = MidiClipSynth(sampleRate: 8000, maxSeconds: 3);
    final clip = _clip(const [
      MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: 100),
    ], length: 480 * 1000);
    expect(_samples(capped.renderWav(clip, bpm: 120)).length, 3 * 8000);
  });

  group('voices', () {
    final melody = _clip(const [
      MidiNote(startTick: 0, lengthTicks: 480, pitch: 48, velocity: 110),
      MidiNote(startTick: 480, lengthTicks: 480, pitch: 55, velocity: 110),
    ]);
    final kit = _clip(const [
      MidiNote(startTick: 0, lengthTicks: 120, pitch: 36, velocity: 120),
      MidiNote(startTick: 480, lengthTicks: 120, pitch: 38, velocity: 120),
      MidiNote(startTick: 960, lengthTicks: 120, pitch: 42, velocity: 120),
      MidiNote(startTick: 1440, lengthTicks: 120, pitch: 49, velocity: 120),
    ]);

    int peak(Int16List s) => s.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);

    for (final voice in SynthVoice.values) {
      test('${voice.name} makes sound and stays in range', () {
        final s = _samples(synth.renderWav(voice.isDrum ? kit : melody,
            bpm: 120, voice: voice));
        expect(peak(s), greaterThan(1000));
        expect(peak(s), lessThanOrEqualTo(32767));
      });
    }

    test('different voices sound different', () {
      final voices = [SynthVoice.lead, SynthVoice.pad, SynthVoice.organ, SynthVoice.bell];
      final rendered = [
        for (final v in voices) synth.renderWav(melody, bpm: 120, voice: v),
      ];
      for (var i = 0; i < rendered.length; i++) {
        for (var j = i + 1; j < rendered.length; j++) {
          expect(listEquals(rendered[i], rendered[j]), isFalse,
              reason: '${voices[i].name} vs ${voices[j].name}');
        }
      }
    });

    test('a pad swells in; a pluck is loudest right away', () {
      final early = (0.02 * 8000).round();
      double level(SynthVoice v) {
        final s = _samples(synth.renderWav(melody, bpm: 120, voice: v));
        var p = 0;
        for (var i = 0; i < early; i++) {
          if (s[i].abs() > p) p = s[i].abs();
        }
        return p / peak(s);
      }

      expect(level(SynthVoice.pad), lessThan(0.3));
      expect(level(SynthVoice.pluck), greaterThan(0.5));
    });

    test('drums render the same bytes every time', () {
      // The preview cache keys on clip, tempo and voice; noise must be
      // seeded, not random, or a cached file would differ from a fresh one.
      expect(synth.renderWav(kit, bpm: 120, voice: SynthVoice.drumKit),
          synth.renderWav(kit, bpm: 120, voice: SynthVoice.drumKit));
    });

    test('a kick voice turns every note into a kick, whatever the pitch', () {
      final high = _clip(const [
        MidiNote(startTick: 0, lengthTicks: 120, pitch: 84, velocity: 120),
      ]);
      final low = _clip(const [
        MidiNote(startTick: 0, lengthTicks: 120, pitch: 36, velocity: 120),
      ]);
      expect(synth.renderWav(high, bpm: 120, voice: SynthVoice.kick),
          synth.renderWav(low, bpm: 120, voice: SynthVoice.kick));
    });
  });
}
