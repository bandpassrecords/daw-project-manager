import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/midi_clip.dart';
import '../services/app_audio_focus.dart';
import '../services/midi/midi_clip_service.dart';
import '../services/midi/midi_clip_synth.dart';
import '../services/midi/synth_voice.dart';

/// Where a [MidiPreviewPlayer.play] starts: where the clip it takes over
/// had got to ([held]), when it takes one over, else where it was asked to
/// ([requested]) — inside one pass of a loop of [loopLength].
Duration? takeOverStart({
  required Duration? held,
  required Duration? requested,
  Duration? loopLength,
}) {
  final at = held ?? requested;
  return at == null ? null : wrapLoopPosition(at, loopLength);
}

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
  /// Joins the app-wide one-sound-at-a-time rule ([AppAudioFocus]): a song
  /// or another preview starting stops this one, and this one starting
  /// pauses them.
  MidiPreviewPlayer() {
    AppAudioFocus.register(this, () {
      if (playingKey != null || preparingKey != null) stop();
    });
  }

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

  /// Whether previews play on repeat until stopped. Set with [setLoop].
  bool loop = false;

  /// What [play] was last asked to play, so [setLoop] can carry on with it.
  (String, MidiClip, double?, SynthVoice)? _current;

  /// One pass of the playing preview, when it is looping; null otherwise.
  Duration? _loopLength;

  /// [setLoop] was changed while paused: the audio is switched on resume.
  bool _loopChangedWhilePaused = false;

  /// Turns looping on or off — live: a clip that is playing carries on from
  /// where it is, re-rendered as a seamless loop or as a single pass.
  Future<void> setLoop(bool value) async {
    if (loop == value) return;
    loop = value;
    _notify();
    final current = _current;
    // A clip still rendering is restarted too, or it would start in the
    // mode that was just switched away from.
    final key = playingKey ?? preparingKey;
    if (key == null || current == null || current.$1 != key) return;
    if (paused) {
      _loopChangedWhilePaused = true;
      return;
    }
    await _restartFrom(positionOf(key) ?? Duration.zero);
  }

  Future<void> _restartFrom(Duration position) async {
    final current = _current;
    if (current == null) return;
    final (key, clip, bpm, voice) = current;
    startAt(key, position);
    await play(key, clip, bpm: bpm, voice: voice);
  }

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
    final to = wrapLoopPosition(
        position.isNegative ? Duration.zero : position, _loopLength);
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
  ///
  /// With [takeOver], and something playing, [clip] replaces it the way an
  /// edit should: what plays carries on while [clip] renders — no stop, no
  /// "preparing" — and [clip] then starts from wherever playback has got to
  /// by then. Without it, deleting a note mid-playback cut the sound out
  /// and flickered the transport.
  Future<void> play(String key, MidiClip clip,
      {double? bpm, required SynthVoice voice, bool takeOver = false}) async {
    final generation = ++_generation;
    final takingOver = takeOver && playingKey != null && !paused;
    final heldKey = playingKey;
    final looping = loop;
    final loopLength = looping
        ? Duration(
            microseconds:
                (const MidiClipSynth().loopSeconds(clip, bpm ?? 120) * 1e6)
                    .round())
        : null;
    final requested = pendingStartFor(key);
    final startAt =
        requested == null ? null : wrapLoopPosition(requested, loopLength);
    _startAt = null;
    _current = (key, clip, bpm, voice);
    _loopChangedWhilePaused = false;
    if (!takingOver) {
      preparingKey = key;
      paused = false;
      _notify();
    }
    try {
      final path = await MidiClipService.renderPreview(
        clip,
        bpm: bpm,
        voice: voice,
        loop: looping,
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
      // Taking over: carry on from where the held clip is by now (the render
      // took a moment), not from where it was when it began. Read before
      // anything below stops it or resets the position — read after, it
      // was always 0, and every edit, undo or redo restarted the clip.
      final from = takeOverStart(
        held: takingOver && heldKey != null && playingKey == heldKey
            ? positionOf(heldKey)
            : null,
        requested: startAt,
        loopLength: loopLength,
      );
      await player.stop();
      await player.setVolume(volume);
      await player
          .setReleaseMode(looping ? ReleaseMode.loop : ReleaseMode.stop);
      _loopLength = loopLength;
      _lastPosition = Duration.zero;
      _lastPositionAt = DateTime.now();
      if (from != null && from > Duration.zero) {
        // Loaded, moved, then started: playing first and seeking after
        // sounded the clip's first moments — a restart — before the jump.
        await player.setSource(DeviceFileSource(path));
        if (generation != _generation || _disposed) return;
        await player.seek(from);
        if (generation != _generation || _disposed) return;
        await player.resume();
      } else {
        await player.play(DeviceFileSource(path));
      }
      if (generation != _generation || _disposed) return;
      _lastPosition = from ?? Duration.zero;
      _lastPositionAt = DateTime.now();
      playingKey = key;
      AppAudioFocus.claim(this);
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
    if (paused) return wrapLoopPosition(_lastPosition, _loopLength);
    return wrapLoopPosition(
      extrapolatePosition(_lastPosition, _lastPositionAt, DateTime.now()),
      _loopLength,
    );
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
    if (_loopChangedWhilePaused) {
      // Looping was switched while paused: carry on in the new mode.
      _loopChangedWhilePaused = false;
      await _restartFrom(_lastPosition);
      return;
    }
    paused = false;
    _lastPositionAt = DateTime.now();
    _notify();
    AppAudioFocus.claim(this);
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
    AppAudioFocus.unregister(this);
    _disposed = true;
    _generation++;
    _completeSub?.cancel();
    _positionSub?.cancel();
    _player?.dispose();
    super.dispose();
  }
}

/// [position] within one pass of a loop [length] long — where a looping
/// preview really is. Unchanged when not looping ([length] null or zero).
@visibleForTesting
Duration wrapLoopPosition(Duration position, Duration? length) {
  if (length == null || length <= Duration.zero) return position;
  return Duration(
      microseconds: position.inMicroseconds % length.inMicroseconds);
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
