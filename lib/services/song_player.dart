import 'package:audioplayers/audioplayers.dart';

/// How often a song player reports where it is.
///
/// audioplayers reports on every frame by default, which keeps the whole
/// app rendering at the display's rate for as long as a song plays — and on
/// Windows asks the native side for the position on the thread that handles
/// the window's input, every frame. The main page felt sluggish while a song
/// played. Twenty a second still moves a full-width waveform by about a
/// pixel at a time, and the time shown only changes once a second.
const Duration kSongPositionInterval = Duration(milliseconds: 50);

/// The position updater every song player uses: [kSongPositionInterval]
/// apart, never once a frame.
PositionUpdater songPositionUpdater(Future<Duration?> Function() getPosition) =>
    TimerPositionUpdater(
      getPosition: getPosition,
      interval: kSongPositionInterval,
    );

/// A player for songs — preview songs, a release's tracks, playlists, the
/// plugin's captures — reporting its position at [kSongPositionInterval].
///
/// Every song player is made here (a test fails on a bare `AudioPlayer()`
/// in `lib/`). The MIDI preview player and the note auditioner are not song
/// players: the piano roll's playhead follows the clip frame by frame.
AudioPlayer newSongPlayer() {
  final player = AudioPlayer();
  player.positionUpdater = songPositionUpdater(player.getCurrentPosition);
  return player;
}
