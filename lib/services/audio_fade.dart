import 'package:audioplayers/audioplayers.dart';

/// The volumes a fade from [volume] to silence steps through: [steps] of
/// them, each a little quieter than the last on a squared curve, the last
/// exactly 0. Small steps, so no single drop is heard as a click; true
/// silence at the end, so the stop after it isn't either.
List<double> fadeOutVolumes(double volume, {int steps = 16}) => [
      for (var k = 1; k <= steps; k++)
        volume * (1 - k / steps) * (1 - k / steps),
    ];

/// Fades [player] from [volume] to silence over about [over], then stops
/// (or pauses, with [pause]) it. Cut off mid-wave — or faded in a few big
/// jumps, as before — a sound ends in a click. Never throws: a player that
/// can't fade still stops.
///
/// [abandoned] is asked before every step: once the player has been handed
/// something new to play, the fade lets it be — carrying on would turn the
/// new sound down and then stop it.
Future<void> fadeOutAndStop(
  AudioPlayer player,
  double volume, {
  bool pause = false,
  Duration over = const Duration(milliseconds: 80),
  bool Function()? abandoned,
}) =>
    runFadeOut(
      setVolume: player.setVolume,
      stop: pause ? player.pause : player.stop,
      volume: volume,
      over: over,
      abandoned: abandoned,
    );

/// What [fadeOutAndStop] does, with the player's volume and stop as plain
/// functions — so it can be checked without an audio device.
Future<void> runFadeOut({
  required Future<void> Function(double volume) setVolume,
  required Future<void> Function() stop,
  required double volume,
  Duration over = const Duration(milliseconds: 80),
  bool Function()? abandoned,
}) async {
  const steps = 16;
  bool gone() => abandoned?.call() ?? false;
  try {
    for (final v in fadeOutVolumes(volume, steps: steps)) {
      if (gone()) return;
      await setVolume(v);
      await Future<void>.delayed(over ~/ steps);
    }
  } catch (_) {
    // A player that can't fade still stops.
  }
  if (gone()) return;
  await stop();
}
