import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/services/player_volume_store.dart';
import 'package:daw_project_manager/utils/playback_seek.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    PlayerVolumeStore.cachedForTest = 0.7;
    container = ProviderContainer();
  });
  tearDown(() {
    container.dispose();
    PlayerVolumeStore.cachedForTest = PlayerVolumeStore.defaultVolume;
  });

  double volume() => container.read(desktopPlayerVolumeProvider);
  DesktopPlayerVolumeNotifier notifier() =>
      container.read(desktopPlayerVolumeProvider.notifier);

  test('starts at the remembered level, not full volume', () {
    expect(volume(), 0.7);
  });

  test('a page can set the bar\'s level', () {
    // The bug: the project page's slider and ctrl+wheel set the page's own
    // idle player while the bar played the track, so nothing audible moved.
    notifier().set(0.3);
    expect(volume(), 0.3);
  });

  test('clamps out-of-range levels', () {
    notifier().set(1.4);
    expect(volume(), 1.0);
    notifier().set(-0.5);
    expect(volume(), 0.0);
  });

  test('setting the level already held does not notify', () {
    // The bar and the page each echo a change back through this provider;
    // the equality check is what stops them bouncing it forever.
    var notifications = 0;
    container.listen(desktopPlayerVolumeProvider, (_, _) => notifications++);

    notifier().set(0.7);
    expect(notifications, 0);

    notifier().set(0.4);
    notifier().set(0.4);
    expect(notifications, 1);
  });

  test('a track playing in the bar routes to the bar', () {
    // The routing decision the project page's volume now follows, alongside
    // seek — there is a distinct case for the bar rather than falling
    // through to the page's own player.
    expect(
      playbackTargetFor(
        isMobile: false,
        projectId: 'p1',
        desktopPlayerProjectId: 'p1',
      ),
      PlaybackTarget.desktopPlayerBar,
    );
  });
}
