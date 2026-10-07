import 'package:flutter/foundation.dart';

/// One sound at a time, across the whole app.
///
/// The app has several players that can be on screen together — the bottom
/// player bar, a project's preview song, a release's tracks, a playlist, the
/// phone's player, and MIDI clip previews. Each registers how to silence
/// itself, and claims the focus when it starts making sound; every other
/// registered player is then asked to stop. So starting a MIDI preview
/// pauses the song that was playing, and starting a song stops the preview.
///
/// Players are keyed by identity (usually their `State` or service object),
/// so registering again replaces the earlier callback, and a player
/// claiming never silences itself.
class AppAudioFocus {
  AppAudioFocus._();

  static final Map<Object, VoidCallback> _silencers = {};
  static Object? _owner;

  /// The player that last claimed the focus, if it is still registered.
  static Object? get owner =>
      _owner != null && _silencers.containsKey(_owner) ? _owner : null;

  /// Registers [player], with [silence] to pause or stop it when another
  /// player claims the focus. [silence] is called whether or not [player]
  /// is playing; it should do nothing when it isn't.
  static void register(Object player, VoidCallback silence) {
    _silencers[player] = silence;
  }

  /// Forgets [player] — call from its `dispose`.
  static void unregister(Object player) {
    _silencers.remove(player);
    if (identical(_owner, player)) _owner = null;
  }

  /// [player] has started making sound: silences every other registered
  /// player. A silencer that throws doesn't stop the rest from being
  /// silenced.
  static void claim(Object player) {
    _owner = player;
    for (final entry in [..._silencers.entries]) {
      if (identical(entry.key, player)) continue;
      try {
        entry.value();
      } catch (e) {
        debugPrint('[AppAudioFocus] silencing ${entry.key} failed: $e');
      }
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _silencers.clear();
    _owner = null;
  }
}
