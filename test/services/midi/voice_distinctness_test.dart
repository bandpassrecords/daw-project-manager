import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/midi_clip_synth.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';

/// What a voice sounds like, measured from what it renders: the share of
/// each of its first twelve harmonics (its tone), and how loud it is in a
/// few windows across a one-second C3 (its envelope).
class _Voice {
  _Voice(this.tone, this.envelope);
  final List<double> tone;
  final List<double> envelope;
}

double _distance(List<double> a, List<double> b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    s += (a[i] - b[i]) * (a[i] - b[i]);
  }
  return math.sqrt(s);
}

_Voice _measure(SynthVoice voice) {
  const synth = MidiClipSynth();
  const clip = MidiClip(name: 'probe', ppq: 480, lengthTicks: 1920, notes: [
    MidiNote(startTick: 0, lengthTicks: 960, pitch: 60, velocity: 100),
  ]);
  final wav = synth.renderWav(clip, bpm: 120, voice: voice);
  final data = ByteData.sublistView(wav);
  final rate = data.getUint32(24, Endian.little);
  final x = [
    for (var i = 44; i + 1 < wav.length; i += 2)
      data.getInt16(i, Endian.little) / 32768,
  ];
  int at(double s) => (s * rate).round().clamp(0, x.length);

  double harmonic(int k) {
    final w = 2 * math.pi * 261.63 * k / rate;
    final c = 2 * math.cos(w);
    var s1 = 0.0, s2 = 0.0;
    for (var i = at(0.15); i < at(0.45); i++) {
      final s0 = x[i] + c * s1 - s2;
      s2 = s1;
      s1 = s0;
    }
    return math.sqrt(math.max(0, s1 * s1 + s2 * s2 - c * s1 * s2));
  }

  final h = [for (var k = 1; k <= 12; k++) harmonic(k)];
  final total = h.reduce((a, b) => a + b);

  double rms(double a, double b) {
    var sum = 0.0;
    for (var i = at(a); i < at(b); i++) {
      sum += x[i] * x[i];
    }
    return math.sqrt(sum / math.max(1, at(b) - at(a)));
  }

  final env = [
    rms(0, 0.02),
    rms(0.05, 0.1),
    rms(0.2, 0.3),
    rms(0.4, 0.5),
    rms(0.9, 1.0),
    rms(1.0, 1.2),
  ];
  final peak = env.reduce(math.max);
  return _Voice(
    [for (final a in h) total == 0 ? 0.0 : a / total],
    [for (final e in env) peak == 0 ? 0.0 : e / peak],
  );
}

void main() {
  // Keys was once a bass with a decay — the same tone (0.05 apart) and the
  // same first 300 ms — and the bell an organ tone fading like the keys
  // (envelopes 0.09 apart): picking one over the other changed nothing
  // anyone could hear. A pair with the same tone *and* the same start, or
  // too alike overall, fails here. (A pluck and a brass share a sawtooth
  // tone, but one snaps and dies while the other swells: no one confuses
  // them.)
  test('every instrument sounds like itself, not like another', () {
    final voices = SynthVoice.values.where((v) => !v.isDrum).toList();
    final measured = {for (final v in voices) v: _measure(v)};
    for (var i = 0; i < voices.length; i++) {
      for (var j = i + 1; j < voices.length; j++) {
        final a = measured[voices[i]]!, b = measured[voices[j]]!;
        final tone = _distance(a.tone, b.tone);
        final envelope = _distance(a.envelope, b.envelope);
        final start =
            _distance(a.envelope.sublist(0, 3), b.envelope.sublist(0, 3));
        final pair = '${voices[i].name} and ${voices[j].name}';
        expect(tone >= 0.15 || start >= 0.25, isTrue,
            reason: '$pair have the same tone ($tone) and start ($start)');
        expect(tone + envelope, greaterThanOrEqualTo(0.55),
            reason: '$pair sound alike (tone $tone, envelope $envelope)');
      }
    }
  });
}
