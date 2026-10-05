import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/midi_clip.dart';
import '../services/midi/midi_clip_service.dart';
import '../services/midi/synth_voice.dart';

/// Sounds single notes in the piano roll: a key pressed on its keyboard, a
/// note drawn or dragged with acoustic feedback on.
///
/// Each note is rendered through the preview synth like a one-note clip
/// ([clipFor]) and cached on disk by the preview renderer, so a key sounds
/// straight away the second time. A few players take turns, so quick notes
/// ring over each other instead of cutting each other off.
///
/// Deliberately outside `AppAudioFocus`: these are short blips over
/// whatever plays, as in a DAW — a key clicked must not stop the clip being
/// edited.
class MidiNoteAuditioner {
  MidiNoteAuditioner({this.voice = SynthVoice.synth, this.volume = 1.0});

  /// The instrument notes sound with: the clip's.
  SynthVoice voice;

  /// 0…1: the preview volume.
  double volume;

  static const _players = 4;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _disposed = false;

  /// The one-note clip [pitch] is sounded as: a dotted eighth at 120 BPM,
  /// enough to hear the note and short enough to get out of the way.
  static MidiClip clipFor(int pitch, int velocity) => MidiClip(
        name: 'audition',
        ppq: 480,
        lengthTicks: 480,
        notes: [
          MidiNote(
            startTick: 0,
            lengthTicks: 360,
            pitch: pitch.clamp(0, 127),
            velocity: auditionVelocity(velocity),
          ),
        ],
      );

  /// Sounds [pitch] at about [velocity]. Never throws: feedback that fails
  /// to play must not interrupt editing.
  Future<void> play(int pitch, {int velocity = 100}) async {
    if (_disposed) return;
    try {
      final path = await MidiClipService.renderPreview(
        clipFor(pitch, velocity),
        bpm: 120,
        voice: voice,
        directory: await _directory(),
      );
      if (_disposed) return;
      final AudioPlayer player;
      if (_pool.length < _players) {
        player = AudioPlayer();
        _pool.add(player);
      } else {
        player = _pool[_next++ % _players];
      }
      await player.stop();
      await player.setVolume(volume);
      await player.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint('[MidiNoteAuditioner] failed to play $pitch: $e');
    }
  }

  void dispose() {
    _disposed = true;
    for (final player in _pool) {
      player.dispose();
    }
    _pool.clear();
  }

  static Future<Directory> _directory() async {
    final base = await getTemporaryDirectory();
    return Directory(p.join(base.path, 'daw_project_manager', 'midi_audition'));
  }
}

/// [velocity] rounded to one of eight loudness steps, so a handful of
/// renders per key cover every velocity.
int auditionVelocity(int velocity) =>
    ((velocity.clamp(1, 127) / 16).round() * 16).clamp(16, 127);
