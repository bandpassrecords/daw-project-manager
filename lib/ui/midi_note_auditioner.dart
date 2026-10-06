import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/midi_clip.dart';
import '../services/audio_fade.dart';
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
  MidiNoteAuditioner({this.voice = SynthVoice.keys, this.volume = 1.0});

  /// The instrument notes sound with: the clip's.
  SynthVoice voice;

  /// 0…1: the preview volume.
  double volume;

  // Enough that a note still ringing out isn't cut off (a click) by a
  // quick run of new ones taking its player.
  static const _players = 8;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _disposed = false;

  /// The one-note clip [pitch] is sounded as: a 16th at 120 BPM — a blip,
  /// enough to hear which note it is and gone before the next click (a
  /// longer one hung on and felt wrong).
  ///
  /// [held]: a note sounded for as long as a key is held — eight beats,
  /// more than a press lasts, cut short (faded) when it is let go.
  static MidiClip clipFor(int pitch, int velocity, {bool held = false}) =>
      MidiClip(
        name: held ? 'audition-held' : 'audition',
        ppq: 480,
        lengthTicks: held ? 8 * 480 : 240,
        notes: [
          MidiNote(
            startTick: 0,
            lengthTicks: held ? 8 * 480 : 120,
            pitch: pitch.clamp(0, 127),
            velocity: auditionVelocity(velocity),
          ),
        ],
      );

  /// Sounds [pitch] at about [velocity], briefly. Never throws: feedback
  /// that fails to play must not interrupt editing.
  Future<void> play(int pitch, {int velocity = 100}) async {
    if (_disposed) return;
    try {
      final path = await _render(clipFor(pitch, velocity));
      if (_disposed) return;
      final player = _nextPlayer(Object());
      await player.stop();
      await player.setVolume(volume);
      await player.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint('[MidiNoteAuditioner] failed to play $pitch: $e');
    }
  }

  /// Starts [pitch] sounding for as long as it's held — a key pressed on
  /// the keyboard, a note pressed or drawn — until [release]. Let go before
  /// it could even start, it sounds as a short [play], as a click should.
  MidiHeldNote hold(int pitch, {int velocity = 100}) {
    final note = MidiHeldNote._();
    _hold(note, pitch, velocity);
    return note;
  }

  Future<void> _hold(MidiHeldNote note, int pitch, int velocity) async {
    if (_disposed) return;
    try {
      final path = await _render(clipFor(pitch, velocity, held: true));
      if (_disposed) return;
      if (note._released) {
        await play(pitch, velocity: velocity);
        return;
      }
      final player = _nextPlayer(note);
      note._player = player;
      await player.stop();
      await player.setVolume(volume);
      await player.play(DeviceFileSource(path));
      if (note._released) await _fadeOut(player, note);
    } catch (e) {
      debugPrint('[MidiNoteAuditioner] failed to hold $pitch: $e');
    }
  }

  /// Lets a [hold] go: it fades out quickly rather than stopping dead.
  Future<void> release(MidiHeldNote note) async {
    if (note._released) return;
    note._released = true;
    final player = note._player;
    if (player != null && !_disposed) await _fadeOut(player, note);
  }

  /// Which sound each player is playing now: a fade lets go of a player
  /// handed on to a newer one.
  final Map<AudioPlayer, Object> _playing = {};

  Future<void> _fadeOut(AudioPlayer player, MidiHeldNote note) =>
      fadeOutAndStop(player, volume,
          over: const Duration(milliseconds: 60),
          abandoned: () => _disposed || !identical(_playing[player], note));

  Future<String> _render(MidiClip clip) async => MidiClipService.renderPreview(
        clip,
        bpm: 120,
        voice: voice,
        directory: await _directory(),
      );

  /// A player for [sound], taken from whatever it was playing.
  AudioPlayer _nextPlayer(Object sound) {
    final AudioPlayer player;
    if (_pool.length < _players) {
      player = AudioPlayer();
      _pool.add(player);
    } else {
      player = _pool[_next++ % _players];
    }
    _playing[player] = sound;
    return player;
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

/// A note [MidiNoteAuditioner.hold] is sounding, to give back to
/// [MidiNoteAuditioner.release].
class MidiHeldNote {
  MidiHeldNote._();

  bool _released = false;
  AudioPlayer? _player;

  /// Whether it has been let go.
  bool get released => _released;
}

/// A held note for a stand-in auditioner in tests, which sounds nothing.
@visibleForTesting
MidiHeldNote heldNoteForTest() => MidiHeldNote._();
