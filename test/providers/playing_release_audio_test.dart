import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

void main() {
  group('shouldYieldReleaseAudio', () {
    test('yields when someone else holds the floor', () {
      expect(
        shouldYieldReleaseAudio(fileId: 'a', owner: 'b'),
        isTrue,
      );
    });

    test('does not yield to itself', () {
      // The item that just claimed the floor must not pause itself in
      // response to its own claim.
      expect(shouldYieldReleaseAudio(fileId: 'a', owner: 'a'), isFalse);
    });

    test('does not yield when nothing holds the floor', () {
      expect(shouldYieldReleaseAudio(fileId: 'a', owner: null), isFalse);
    });
  });

  group('PlayingReleaseAudioNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    String? owner() => container.read(playingReleaseAudioProvider);
    PlayingReleaseAudioNotifier notifier() =>
        container.read(playingReleaseAudioProvider.notifier);

    test('starts with nothing playing', () {
      expect(owner(), isNull);
    });

    test('claiming takes the floor', () {
      notifier().claim('track-1');
      expect(owner(), 'track-1');
    });

    test('a second claim replaces the first', () {
      notifier().claim('track-1');
      notifier().claim('track-2');
      expect(owner(), 'track-2');
    });

    test('releasing the floor clears it', () {
      notifier().claim('track-1');
      notifier().releaseFloor('track-1');
      expect(owner(), isNull);
    });

    test('a stale release does not silence whoever holds the floor now', () {
      // The race this guards: item 1 is paused as item 2 starts, and item 1's
      // pause handler fires afterwards. An unguarded clear would stop item 2.
      notifier().claim('track-1');
      notifier().claim('track-2');
      notifier().releaseFloor('track-1');
      expect(owner(), 'track-2');
    });

    test('releasing when nothing is playing is harmless', () {
      notifier().releaseFloor('track-1');
      expect(owner(), isNull);
    });

    test('clear drops the floor whoever held it', () {
      notifier().claim('track-1');
      notifier().clear();
      expect(owner(), isNull);
    });

    test('after a claim, only the claimant keeps playing', () {
      // The end-to-end rule the audio items implement between them.
      notifier().claim('track-2');
      final current = owner();

      expect(shouldYieldReleaseAudio(fileId: 'track-1', owner: current), isTrue);
      expect(shouldYieldReleaseAudio(fileId: 'track-2', owner: current), isFalse);
      expect(shouldYieldReleaseAudio(fileId: 'track-3', owner: current), isTrue);
    });
  });
}
