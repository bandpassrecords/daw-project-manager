import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/midi_clip.dart';
import '../services/midi/midi_clip_service.dart';
import '../services/midi/synth_voice.dart';

/// Plays MIDI clip previews — renders through the built-in synth, then plays
/// the WAV — for any list of clips. Shared by a project's clip section and
/// the MIDI library so both behave the same.
///
/// Clips are identified by a caller-chosen [String] key (a clip's
/// `contentKey`, a collection item's id), not by list position, so a list
/// that reorders or refreshes under a playing preview doesn't confuse it.
///
/// Every [play] starts a new generation; a render that finishes after a newer
/// [play] or [stop] is dropped. That is what makes "change the tempo while it
/// renders" and "tap another clip while one renders" both come out right.
class MidiPreviewPlayer extends ChangeNotifier {
  AudioPlayer? _player;
  StreamSubscription<void>? _completeSub;
  int _generation = 0;
  bool _disposed = false;

  /// The clip playing now, if any.
  String? playingKey;

  /// The clip being rendered, if any.
  String? preparingKey;

  /// Plays [clip] — or stops it, when [key] is already the one playing.
  Future<void> toggle(String key, MidiClip clip,
      {double? bpm, required SynthVoice voice}) async {
    if (playingKey == key) return stop();
    return play(key, clip, bpm: bpm, voice: voice);
  }

  /// Renders and plays [clip]. Throws what rendering or playback threw, so
  /// the caller can tell the user.
  Future<void> play(String key, MidiClip clip,
      {double? bpm, required SynthVoice voice}) async {
    final generation = ++_generation;
    preparingKey = key;
    _notify();
    try {
      final path = await MidiClipService.renderPreview(
        clip,
        bpm: bpm,
        voice: voice,
        directory: await _previewDir(),
      );
      if (generation != _generation || _disposed) return;
      final player = _player ??= AudioPlayer();
      _completeSub ??= player.onPlayerComplete.listen((_) {
        playingKey = null;
        _notify();
      });
      await player.stop();
      await player.play(DeviceFileSource(path));
      if (generation != _generation || _disposed) return;
      playingKey = key;
    } finally {
      if (generation == _generation && preparingKey == key) preparingKey = null;
      _notify();
    }
  }

  Future<void> stop() async {
    _generation++;
    preparingKey = null;
    playingKey = null;
    _notify();
    await _player?.stop();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static Future<Directory> _previewDir() async {
    final base = await getTemporaryDirectory();
    return Directory(p.join(base.path, 'daw_project_manager', 'midi_previews'));
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _completeSub?.cancel();
    _player?.dispose();
    super.dispose();
  }
}
