import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/app_audio_focus.dart';
import 'package:daw_project_manager/ui/midi_preview_player.dart';

void main() {
  setUp(AppAudioFocus.resetForTest);
  tearDown(AppAudioFocus.resetForTest);

  group('AppAudioFocus', () {
    test('a player claiming silences every other player, never itself', () {
      final silenced = <String>[];
      final song = Object(), preview = Object(), playlist = Object();
      AppAudioFocus.register(song, () => silenced.add('song'));
      AppAudioFocus.register(preview, () => silenced.add('preview'));
      AppAudioFocus.register(playlist, () => silenced.add('playlist'));

      AppAudioFocus.claim(preview);
      expect(silenced, ['song', 'playlist']);
      expect(AppAudioFocus.owner, same(preview));
    });

    test('an unregistered player is left alone and stops owning', () {
      final silenced = <String>[];
      final song = Object(), preview = Object();
      AppAudioFocus.register(song, () => silenced.add('song'));
      AppAudioFocus.register(preview, () => silenced.add('preview'));
      AppAudioFocus.claim(song);
      expect(silenced, ['preview']);
      AppAudioFocus.unregister(song);
      expect(AppAudioFocus.owner, isNull);
      silenced.clear();

      AppAudioFocus.claim(preview);
      expect(silenced, isEmpty, reason: 'the song is gone; nothing to silence');
    });

    test('registering again replaces the earlier callback', () {
      final calls = <int>[];
      final song = Object();
      AppAudioFocus.register(song, () => calls.add(1));
      AppAudioFocus.register(song, () => calls.add(2));
      AppAudioFocus.claim(Object());
      expect(calls, [2]);
    });

    test('one silencer failing does not spare the rest', () {
      final silenced = <String>[];
      AppAudioFocus.register(Object(), () => throw StateError('gone'));
      AppAudioFocus.register(Object(), () => silenced.add('second'));
      AppAudioFocus.claim(Object());
      expect(silenced, ['second']);
    });
  });

  group('MidiPreviewPlayer and the rest of the app', () {
    test('a song starting stops the playing MIDI preview', () async {
      final player = MidiPreviewPlayer()..playingKey = 'k';
      addTearDown(player.dispose);
      await player.pause(); // no audio needed to be the playing clip

      AppAudioFocus.claim(Object()); // e.g. the bottom player bar starts
      await Future<void>.delayed(Duration.zero);
      expect(player.playingKey, isNull);
    });

    test('a MIDI preview resuming pauses whatever else is playing', () async {
      var songPaused = false;
      final song = Object();
      AppAudioFocus.register(song, () => songPaused = true);
      final player = MidiPreviewPlayer()..playingKey = 'k';
      addTearDown(player.dispose);
      await player.pause();

      await player.resume();
      expect(songPaused, isTrue);
      expect(player.playingKey, 'k', reason: 'it does not silence itself');
    });

    test('two previews: one starting stops the other', () async {
      final a = MidiPreviewPlayer()..playingKey = 'a';
      final b = MidiPreviewPlayer()..playingKey = 'b';
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await a.pause();
      await b.pause();

      await b.resume();
      await Future<void>.delayed(Duration.zero);
      expect(a.playingKey, isNull);
      expect(b.playingKey, 'b');
    });

    test('a disposed preview drops out', () async {
      final player = MidiPreviewPlayer();
      player.dispose();
      expect(() => AppAudioFocus.claim(Object()), returnsNormally);
    });
  });
}
