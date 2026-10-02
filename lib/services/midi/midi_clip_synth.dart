import 'dart:math' as math;
import 'dart:typed_data';

import '../../models/midi_clip.dart';

/// A deliberately tiny synthesizer that renders a [MidiClip] to a WAV file,
/// so a clip can be auditioned with the app's ordinary audio player — no
/// soundfont, no native MIDI output, nothing to install.
///
/// It is a preview, not a mix: one soft, slightly bright tone (a few additive
/// harmonics from a wavetable) with a short attack and release, every note
/// the same timbre. Enough to hear the rhythm and the line.
class MidiClipSynth {
  const MidiClipSynth({this.sampleRate = 44100, this.maxSeconds = 180});

  final int sampleRate;

  /// Longer clips are rendered only up to here: a preview of a 20-minute
  /// part would mean a 100 MB buffer for something nobody listens through.
  final int maxSeconds;

  static const _tableSize = 2048;
  static final Float64List _table = _buildTable();

  static Float64List _buildTable() {
    // Harmonic amplitudes: a mellow saw-ish tone that still reads on laptop
    // speakers, where a pure sine below ~150 Hz all but disappears.
    const harmonics = [1.0, 0.45, 0.25, 0.12, 0.06];
    final table = Float64List(_tableSize + 1);
    var peak = 0.0;
    for (var i = 0; i < _tableSize; i++) {
      final phase = 2 * math.pi * i / _tableSize;
      var v = 0.0;
      for (var h = 0; h < harmonics.length; h++) {
        v += harmonics[h] * math.sin(phase * (h + 1));
      }
      table[i] = v;
      peak = math.max(peak, v.abs());
    }
    for (var i = 0; i < _tableSize; i++) {
      table[i] /= peak;
    }
    table[_tableSize] = table[0]; // guard sample for interpolation
    return table;
  }

  /// Seconds the clip lasts at [bpm], capped at [maxSeconds].
  double durationSeconds(MidiClip clip, double bpm) {
    final secondsPerTick = 60 / bpm / clip.ppq;
    var end = clip.lengthTicks;
    for (final n in clip.notes) {
      if (n.endTick > end) end = n.endTick;
    }
    final seconds = end * secondsPerTick + _release;
    return math.min(seconds, maxSeconds.toDouble());
  }

  static const _attack = 0.005;
  static const _decay = 0.12;
  static const _sustain = 0.6;
  static const _release = 0.15;

  /// Renders [clip] at [bpm] (120 when unknown) to 16-bit mono PCM WAV bytes.
  Uint8List renderWav(MidiClip clip, {double? bpm}) {
    final tempo = (bpm == null || bpm <= 0) ? 120.0 : bpm;
    final secondsPerTick = 60 / tempo / clip.ppq;
    final totalSeconds = durationSeconds(clip, tempo);
    final frames = math.max(1, (totalSeconds * sampleRate).ceil());
    final mix = Float64List(frames);

    final attackFrames = math.max(1, (_attack * sampleRate).round());
    final decayFrames = math.max(1, (_decay * sampleRate).round());
    final releaseFrames = math.max(1, (_release * sampleRate).round());

    for (final note in clip.notes) {
      final start = (note.startTick * secondsPerTick * sampleRate).round();
      if (start >= frames || start < 0) continue;
      final held = math.max(1, (note.lengthTicks * secondsPerTick * sampleRate).round());
      final end = math.min(frames, start + held + releaseFrames);
      final freq = 440.0 * math.pow(2, (note.pitch - 69) / 12);
      final step = freq * _tableSize / sampleRate;
      // Gentle velocity curve; 0.25 headroom per voice before normalising.
      final gain = 0.25 * math.pow(note.velocity / 127, 1.5);

      var phase = 0.0;
      var levelAtRelease = 0.0;
      for (var f = start; f < end; f++) {
        final t = f - start;
        double env;
        if (t < held) {
          if (t < attackFrames) {
            env = t / attackFrames;
          } else if (t < attackFrames + decayFrames) {
            env = 1 - (1 - _sustain) * (t - attackFrames) / decayFrames;
          } else {
            env = _sustain;
          }
          levelAtRelease = env;
        } else {
          env = levelAtRelease * (1 - (t - held) / releaseFrames);
        }
        final i = phase.floor();
        final frac = phase - i;
        final sample = _table[i] + (_table[i + 1] - _table[i]) * frac;
        mix[f] += sample * env * gain;
        phase += step;
        if (phase >= _tableSize) phase -= _tableSize;
      }
    }

    // Normalise only downwards: a sparse clip stays at its natural level
    // instead of being blown up, a dense one is pulled back from clipping.
    var peak = 0.0;
    for (final v in mix) {
      final a = v.abs();
      if (a > peak) peak = a;
    }
    final scale = peak > 0.9 ? 0.9 / peak : 1.0;

    final pcm = ByteData(frames * 2);
    for (var i = 0; i < frames; i++) {
      final v = (mix[i] * scale * 32767).round().clamp(-32768, 32767);
      pcm.setInt16(i * 2, v, Endian.little);
    }
    return _wav(pcm.buffer.asUint8List(), sampleRate);
  }
}

Uint8List _wav(Uint8List pcm, int sampleRate) {
  final header = ByteData(44);
  void str(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  str(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(pcm))
      .toBytes();
}
