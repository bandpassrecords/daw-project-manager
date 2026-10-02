import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/midi_clip_synth.dart';

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

  test('a very long clip is capped instead of allocating minutes of audio', () {
    const capped = MidiClipSynth(sampleRate: 8000, maxSeconds: 3);
    final clip = _clip(const [
      MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: 100),
    ], length: 480 * 1000);
    expect(_samples(capped.renderWav(clip, bpm: 120)).length, 3 * 8000);
  });
}
