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
  StreamSubscription<Duration>? _positionSub;

  /// The last position the player reported, and when. Players report a few
  /// times a second; [positionOf] extrapolates between reports so a playhead
  /// moves smoothly.
  Duration _lastPosition = Duration.zero;
  DateTime _lastPositionAt = DateTime.now();
  int _generation = 0;
  bool _disposed = false;

  /// The clip playing now, if any.
  String? playingKey;

  /// The clip being rendered, if any.
  String? preparingKey;

  /// Playback volume, 0…1, applied to every preview this player plays.
  double volume = 1.0;

  /// Sets [volume], live on whatever is playing now.
  Future<void> setVolume(double value) async {
    volume = value.clamp(0.0, 1.0);
    await _player?.setVolume(volume);
  }

  /// Whether the playing clip ([playingKey]) is paused. Only the piano roll
  /// pauses; list rows play and stop.
  bool paused = false;

  /// Where the next [play] of a clip should start, set by [startAt].
  (String, Duration)? _startAt;

  @visibleForTesting
  Duration? pendingStartFor(String key) =>
      _startAt?.$1 == key ? _startAt!.$2 : null;

  /// Makes the next [play] of clip [key] start [position] in instead of at
  /// the beginning — clicking the piano roll's ruler while it is stopped.
  /// A [play] of any other clip forgets it.
  void startAt(String key, Duration position) {
    _startAt = (key, position.isNegative ? Duration.zero : position);
  }

  /// Jumps clip [key]'s playback to [position], playing or paused. Does
  /// nothing when [key] isn't the clip playing.
  Future<void> seek(String key, Duration position) async {
    if (playingKey != key) return;
    final to = position.isNegative ? Duration.zero : position;
    // Set before the player answers, so the playhead is there on the next
    // frame rather than gliding on from the old position first.
    _lastPosition = to;
    _lastPositionAt = DateTime.now();
    _notify();
    await _player?.seek(to);
  }

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
    final startAt = pendingStartFor(key);
    _startAt = null;
    preparingKey = key;
    paused = false;
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
        paused = false;
        _notify();
      });
      _positionSub ??= player.onPositionChanged.listen((p) {
        _lastPosition = p;
        _lastPositionAt = DateTime.now();
      });
      await player.stop();
      await player.setVolume(volume);
      _lastPosition = Duration.zero;
      _lastPositionAt = DateTime.now();
      await player.play(DeviceFileSource(path));
      if (generation != _generation || _disposed) return;
      if (startAt != null && startAt > Duration.zero) {
        await player.seek(startAt);
        if (generation != _generation || _disposed) return;
      }
      _lastPosition = startAt ?? Duration.zero;
      _lastPositionAt = DateTime.now();
      playingKey = key;
    } finally {
      if (generation == _generation && preparingKey == key) preparingKey = null;
      _notify();
    }
  }

  /// How far into clip [key]'s preview playback is, or null when that clip
  /// isn't the one playing. Extrapolated from the player's last report;
  /// frozen while paused.
  Duration? positionOf(String key) {
    if (playingKey != key) return null;
    if (paused) return _lastPosition;
    return extrapolatePosition(_lastPosition, _lastPositionAt, DateTime.now());
  }

  /// Pauses the playing clip where it is.
  Future<void> pause() async {
    final key = playingKey;
    if (key == null || paused) return;
    _lastPosition = positionOf(key) ?? _lastPosition;
    paused = true;
    _notify();
    await _player?.pause();
  }

  /// Carries on from where [pause] left off.
  Future<void> resume() async {
    if (playingKey == null || !paused) return;
    paused = false;
    _lastPositionAt = DateTime.now();
    _notify();
    await _player?.resume();
  }

  Future<void> stop() async {
    _generation++;
    preparingKey = null;
    playingKey = null;
    paused = false;
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
    _positionSub?.cancel();
    _player?.dispose();
    super.dispose();
  }
}

/// The playback position at [now], given the player last reported
/// [reported] at [reportedAt]. Players report a few times a second; moving
/// on by the wall-clock time since gives a playhead that glides instead of
/// jumping. Capped at a second past the report, so a stalled player can't
/// send the playhead running off.
@visibleForTesting
Duration extrapolatePosition(Duration reported, DateTime reportedAt, DateTime now) {
  var elapsed = now.difference(reportedAt);
  if (elapsed.isNegative) elapsed = Duration.zero;
  if (elapsed > const Duration(seconds: 1)) elapsed = const Duration(seconds: 1);
  return reported + elapsed;
}
