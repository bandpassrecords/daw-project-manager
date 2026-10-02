import 'dart:math' as math;
import 'dart:typed_data';

import '../../models/midi_clip.dart';
import 'synth_voice.dart';

/// A deliberately small synthesizer that renders a [MidiClip] to a WAV file,
/// so a clip can be auditioned with the app's ordinary audio player — no
/// soundfont, no native MIDI output, nothing to install.
///
/// Each [SynthVoice] is a sketch of its family — a harmonic recipe, an
/// envelope, a little detune or vibrato — and the drum voices are classic
/// analogue-style recipes (pitched-down sine kick, noise snare and hats).
/// Enough to hear what a part is and how it moves, not to mix with.
class MidiClipSynth {
  const MidiClipSynth({this.sampleRate = 44100, this.maxSeconds = 180});

  final int sampleRate;

  /// Longer clips are rendered only up to here: a preview of a 20-minute
  /// part would mean a 100 MB buffer for something nobody listens through.
  final int maxSeconds;

  /// Seconds the clip lasts at [bpm] with [voice]'s release tail, capped at
  /// [maxSeconds].
  double durationSeconds(MidiClip clip, double bpm,
      {SynthVoice voice = SynthVoice.synth}) {
    final secondsPerTick = 60 / bpm / clip.ppq;
    var end = clip.lengthTicks;
    for (final n in clip.notes) {
      if (n.endTick > end) end = n.endTick;
    }
    final seconds = end * secondsPerTick + _tailSeconds(voice);
    return math.min(seconds, maxSeconds.toDouble());
  }

  /// Renders [clip] at [bpm] (120 when unknown) with [voice] to 16-bit mono
  /// PCM WAV bytes.
  Uint8List renderWav(MidiClip clip,
      {double? bpm, SynthVoice voice = SynthVoice.synth}) {
    final tempo = (bpm == null || bpm <= 0) ? 120.0 : bpm;
    final secondsPerTick = 60 / tempo / clip.ppq;
    final totalSeconds = durationSeconds(clip, tempo, voice: voice);
    final frames = math.max(1, (totalSeconds * sampleRate).ceil());
    final mix = Float64List(frames);

    for (final note in clip.notes) {
      final start = (note.startTick * secondsPerTick * sampleRate).round();
      if (start >= frames || start < 0) continue;
      final held = math.max(
          1, (note.lengthTicks * secondsPerTick * sampleRate).round());
      // Gentle velocity curve; headroom per voice before normalising.
      final gain = 0.25 * math.pow(note.velocity / 127, 1.5).toDouble();
      if (voice.isDrum) {
        _renderDrum(mix, start, _drumFor(voice, note.pitch), gain, note.pitch);
      } else {
        _renderTone(mix, start, held, note.pitch, gain, _patches[voice]!);
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

  // --- tonal voices --------------------------------------------------------

  void _renderTone(Float64List mix, int start, int held, int pitch,
      double gain, _Patch patch) {
    final sr = sampleRate.toDouble();
    final release = math.max(1, (patch.release * sr).round());
    final end = math.min(mix.length, start + held + release);
    final baseFreq = 440.0 * math.pow(2, (pitch - 69) / 12);
    final table = patch.table;
    final size = table.length - 1;
    final voices = patch.detuneCents.length;
    final phases = List<double>.filled(voices, 0);
    final steps = [
      for (final cents in patch.detuneCents)
        baseFreq * math.pow(2, cents / 1200) * size / sr,
    ];
    final attack = math.max(1.0, patch.attack * sr);
    final decay = math.max(1.0, patch.decay * sr);
    final perVoice = gain / voices;
    var levelAtRelease = 0.0;

    for (var f = start; f < end; f++) {
      final t = f - start;
      double env;
      if (t < held) {
        if (t < attack) {
          env = t / attack;
        } else if (patch.exponentialDecay) {
          env = patch.sustain +
              (1 - patch.sustain) * math.exp(-(t - attack) / decay);
        } else if (t < attack + decay) {
          env = 1 - (1 - patch.sustain) * (t - attack) / decay;
        } else {
          env = patch.sustain;
        }
        levelAtRelease = env;
      } else {
        env = levelAtRelease * (1 - (t - held) / release);
      }
      if (env <= 0) continue;

      // Vibrato eases in after its delay so short notes stay steady.
      var pitchMod = 1.0;
      if (patch.vibratoCents > 0 && t > patch.vibratoDelay * sr) {
        final depth = math.min(1.0, (t - patch.vibratoDelay * sr) / (0.3 * sr));
        pitchMod = math.pow(2,
                patch.vibratoCents * depth *
                    math.sin(2 * math.pi * patch.vibratoHz * t / sr) /
                    1200)
            .toDouble();
      }

      var sample = 0.0;
      for (var v = 0; v < voices; v++) {
        final ph = phases[v];
        final i = ph.floor();
        sample += table[i] + (table[i + 1] - table[i]) * (ph - i);
        var next = ph + steps[v] * pitchMod;
        if (next >= size) next -= size;
        phases[v] = next;
      }
      mix[f] += sample * env * perVoice;
    }
  }

  // --- drums ---------------------------------------------------------------

  void _renderDrum(
      Float64List mix, int start, _Drum drum, double gain, int pitch) {
    final sr = sampleRate.toDouble();
    // Seeded by position only: the same hit renders the same bytes, and a
    // kick voice sounds identical whatever pitch the note was written at.
    final noise = _Noise(start * 7919 + 17);
    double tau(double seconds) => seconds * sr;

    switch (drum) {
      case _Drum.kick:
        final len = math.min(mix.length - start, (0.45 * sr).round());
        var phase = 0.0;
        for (var t = 0; t < len; t++) {
          // Pitch sweeps 150 Hz → 45 Hz: the "thump" of an analogue kick.
          final freq = 45 + 105 * math.exp(-t / tau(0.035));
          phase += 2 * math.pi * freq / sr;
          final amp = math.exp(-t / tau(0.18));
          final click = t < 0.002 * sr ? noise.next() * 0.3 : 0.0;
          mix[start + t] += (math.sin(phase) + click) * amp * gain * 2.2;
        }
      case _Drum.snare:
        final len = math.min(mix.length - start, (0.3 * sr).round());
        var phase = 0.0;
        final hp = _HighPass(0.7);
        for (var t = 0; t < len; t++) {
          phase += 2 * math.pi * 185 / sr;
          final tone = math.sin(phase) * math.exp(-t / tau(0.04));
          final body = hp.filter(noise.next()) * math.exp(-t / tau(0.09));
          mix[start + t] += (tone * 0.6 + body) * gain * 1.6;
        }
      case _Drum.clap:
        final len = math.min(mix.length - start, (0.35 * sr).round());
        final hp = _HighPass(0.8);
        for (var t = 0; t < len; t++) {
          final s = t / sr;
          // Three quick bursts, then the room tail.
          final burst = (s % 0.011) < 0.004 && s < 0.033 ? 1.0 : 0.0;
          final tail = s >= 0.022 ? math.exp(-(s - 0.022) / 0.11) : 0.0;
          mix[start + t] +=
              hp.filter(noise.next()) * math.max(burst, tail) * gain * 1.5;
        }
      case _Drum.closedHat:
      case _Drum.openHat:
      case _Drum.cymbal:
        final decay = switch (drum) {
          _Drum.closedHat => 0.035,
          _Drum.openHat => 0.22,
          _ => 0.8,
        };
        final len = math.min(mix.length - start, (decay * 5 * sr).round());
        final hp = _HighPass(0.45);
        final hp2 = _HighPass(0.45);
        for (var t = 0; t < len; t++) {
          final v = hp2.filter(hp.filter(noise.next()));
          mix[start + t] += v * math.exp(-t / tau(decay)) * gain * 0.9;
        }
      case _Drum.tom:
        // Low toms low, high toms high: map the GM tom range onto 80–220 Hz.
        final base = 80 + (pitch.clamp(41, 50) - 41) * 15.0;
        final len = math.min(mix.length - start, (0.5 * sr).round());
        var phase = 0.0;
        for (var t = 0; t < len; t++) {
          final freq = base * (1 + 0.5 * math.exp(-t / tau(0.05)));
          phase += 2 * math.pi * freq / sr;
          mix[start + t] += math.sin(phase) * math.exp(-t / tau(0.2)) * gain * 1.8;
        }
      case _Drum.perc:
        // A short pitched knock that follows the note, for congas, bongos
        // and anything else unnamed.
        final freq = 200 * math.pow(2, (pitch - 60) / 24);
        final len = math.min(mix.length - start, (0.25 * sr).round());
        var phase = 0.0;
        for (var t = 0; t < len; t++) {
          phase += 2 * math.pi * freq / sr;
          final amp = math.exp(-t / tau(0.06));
          mix[start + t] +=
              (math.sin(phase) + noise.next() * 0.15) * amp * gain * 1.5;
        }
    }
  }

  /// Which drum a note plays: the voice's own drum, or — for a full kit —
  /// the General MIDI drum map, with sensible fallbacks for pitches outside it.
  static _Drum _drumFor(SynthVoice voice, int pitch) {
    switch (voice) {
      case SynthVoice.kick:
        return _Drum.kick;
      case SynthVoice.snare:
        return _Drum.snare;
      case SynthVoice.clap:
        return _Drum.clap;
      case SynthVoice.hiHat:
        return pitch == 46 ? _Drum.openHat : _Drum.closedHat;
      case SynthVoice.percussion:
        return (pitch >= 41 && pitch <= 50) ? _Drum.tom : _Drum.perc;
      default:
        return switch (pitch) {
          35 || 36 => _Drum.kick,
          37 || 38 || 40 => _Drum.snare,
          39 => _Drum.clap,
          42 || 44 => _Drum.closedHat,
          46 => _Drum.openHat,
          41 || 43 || 45 || 47 || 48 || 50 => _Drum.tom,
          49 || 51 || 52 || 53 || 55 || 57 || 59 => _Drum.cymbal,
          < 35 => _Drum.kick,
          _ => _Drum.perc,
        };
    }
  }

  double _tailSeconds(SynthVoice voice) =>
      voice.isDrum ? 0.8 : _patches[voice]!.release;
}

enum _Drum { kick, snare, clap, closedHat, openHat, cymbal, tom, perc }

/// One tonal voice: a single-cycle wavetable built from harmonic
/// amplitudes, an ADSR envelope, optional unison detune and vibrato.
class _Patch {
  _Patch({
    required List<double> harmonics,
    this.attack = 0.005,
    this.decay = 0.12,
    this.sustain = 0.6,
    this.release = 0.15,
    this.exponentialDecay = false,
    this.detuneCents = const [0],
    this.vibratoCents = 0,
    this.vibratoHz = 5,
    this.vibratoDelay = 0.25,
    List<double>? partialRatios,
  }) : table = _buildTable(harmonics, partialRatios);

  final double attack, decay, sustain, release;
  final bool exponentialDecay;
  final List<double> detuneCents;
  final double vibratoCents, vibratoHz, vibratoDelay;
  final Float64List table;

  static const _tableSize = 2048;

  /// [ratios] lets a partial sit off the harmonic series (bells). Off-series
  /// ratios are rounded to the nearest whole number of cycles per table, so
  /// the table still loops cleanly — the slight inharmonicity survives.
  static Float64List _buildTable(List<double> amps, List<double>? ratios) {
    final table = Float64List(_tableSize + 1);
    var peak = 0.0;
    for (var i = 0; i < _tableSize; i++) {
      final phase = 2 * math.pi * i / _tableSize;
      var v = 0.0;
      for (var h = 0; h < amps.length; h++) {
        final ratio = ratios != null ? ratios[h].roundToDouble() : (h + 1).toDouble();
        v += amps[h] * math.sin(phase * ratio);
      }
      table[i] = v;
      peak = math.max(peak, v.abs());
    }
    if (peak > 0) {
      for (var i = 0; i < _tableSize; i++) {
        table[i] /= peak;
      }
    }
    table[_tableSize] = table[0];
    return table;
  }
}

List<double> _saw(int n, [double rolloff = 1]) =>
    [for (var h = 1; h <= n; h++) 1 / math.pow(h, rolloff).toDouble()];

final Map<SynthVoice, _Patch> _patches = {
  SynthVoice.synth: _Patch(harmonics: const [1.0, 0.45, 0.25, 0.12, 0.06]),
  SynthVoice.lead: _Patch(
    harmonics: _saw(14),
    attack: 0.004,
    decay: 0.08,
    sustain: 0.8,
    release: 0.12,
    detuneCents: const [-7, 7],
    vibratoCents: 12,
    vibratoHz: 5.5,
  ),
  SynthVoice.bass: _Patch(
    harmonics: const [1.0, 0.55, 0.25, 0.12, 0.05],
    attack: 0.003,
    decay: 0.15,
    sustain: 0.75,
    release: 0.06,
  ),
  SynthVoice.pad: _Patch(
    harmonics: _saw(8, 1.6),
    attack: 0.35,
    decay: 0.4,
    sustain: 0.8,
    release: 0.7,
    detuneCents: const [-11, 0, 11],
  ),
  SynthVoice.pluck: _Patch(
    harmonics: _saw(10, 1.2),
    attack: 0.002,
    decay: 0.18,
    sustain: 0,
    release: 0.1,
    exponentialDecay: true,
  ),
  SynthVoice.keys: _Patch(
    harmonics: const [1.0, 0.5, 0.28, 0.16, 0.08, 0.04],
    attack: 0.003,
    decay: 0.7,
    sustain: 0.12,
    release: 0.25,
    exponentialDecay: true,
  ),
  SynthVoice.organ: _Patch(
    // Drawbar-ish: fundamental, octave, twelfth, two octaves, …
    harmonics: const [1.0, 0.8, 0.6, 0.45, 0, 0.3, 0, 0.2],
    attack: 0.008,
    decay: 0.05,
    sustain: 1,
    release: 0.06,
  ),
  SynthVoice.strings: _Patch(
    harmonics: _saw(10, 1.3),
    attack: 0.2,
    decay: 0.3,
    sustain: 0.85,
    release: 0.4,
    detuneCents: const [-6, 6],
    vibratoCents: 14,
    vibratoHz: 5.2,
    vibratoDelay: 0.3,
  ),
  SynthVoice.brass: _Patch(
    harmonics: _saw(10, 0.9),
    attack: 0.06,
    decay: 0.15,
    sustain: 0.75,
    release: 0.12,
    vibratoCents: 8,
    vibratoDelay: 0.4,
  ),
  SynthVoice.bell: _Patch(
    harmonics: const [1.0, 0.5, 0.3, 0.15],
    partialRatios: const [1, 2.76, 5.4, 8.93],
    attack: 0.002,
    decay: 0.9,
    sustain: 0,
    release: 0.8,
    exponentialDecay: true,
  ),
};

/// Deterministic white noise (xorshift), so the same clip renders the same
/// bytes every time — the preview cache depends on it.
class _Noise {
  _Noise(int seed) : _state = (seed & 0x7FFFFFFF) | 1;
  int _state;

  double next() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return (_state / 0xFFFFFFFF) * 2 - 1;
  }
}

/// One-pole high-pass: what turns white noise into hats and snare rattle.
class _HighPass {
  _HighPass(this.a);
  final double a;
  double _x = 0, _y = 0;

  double filter(double x) {
    final y = a * (_y + x - _x);
    _x = x;
    _y = y;
    return y;
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
