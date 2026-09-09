import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/playback_seek.dart';

void main() {
  group('seekTarget', () {
    const total = Duration(minutes: 3); // 180s

    test('jumps forward and backward by the given seconds', () {
      expect(seekTarget(const Duration(seconds: 40), 5, total),
          const Duration(seconds: 45));
      expect(seekTarget(const Duration(seconds: 40), -5, total),
          const Duration(seconds: 35));
    });

    test('clamps to zero at the start', () {
      expect(seekTarget(const Duration(seconds: 3), -5, total), Duration.zero);
      expect(seekTarget(Duration.zero, -30, total), Duration.zero);
    });

    test('clamps to the track length at the end', () {
      expect(seekTarget(const Duration(seconds: 178), 5, total), total);
    });

    test('only enforces the lower bound when the length is unknown', () {
      // duration 0 = not loaded yet; a +5s tap must still advance, not clamp.
      expect(seekTarget(const Duration(seconds: 10), 5, Duration.zero),
          const Duration(seconds: 15));
      expect(seekTarget(const Duration(seconds: 2), -5, Duration.zero),
          Duration.zero);
    });
  });

  // Regression cover for: seeking in the project-detail player did nothing on
  // Android while the track was playing through the global mobile player. The
  // page delegated play/pause to that player but still sent every seek, volume
  // change and mono swap to its own idle AudioPlayer.
  group('playbackTargetFor', () {
    test('routes to the mobile player when it holds this project', () {
      expect(
        playbackTargetFor(
          isMobile: true,
          projectId: 'p1',
          mobilePlayerProjectId: 'p1',
        ),
        PlaybackTarget.mobilePlayer,
      );
    });

    test('stays local on mobile when the global player holds another track',
        () {
      expect(
        playbackTargetFor(
          isMobile: true,
          projectId: 'p1',
          mobilePlayerProjectId: 'p2',
        ),
        PlaybackTarget.local,
      );
    });

    test('stays local on mobile when nothing is playing globally', () {
      expect(
        playbackTargetFor(isMobile: true, projectId: 'p1'),
        PlaybackTarget.local,
      );
    });

    test('routes to the desktop bar when it holds this project', () {
      expect(
        playbackTargetFor(
          isMobile: false,
          projectId: 'p1',
          desktopPlayerProjectId: 'p1',
        ),
        PlaybackTarget.desktopPlayerBar,
      );
    });

    test('stays local on desktop when the bar holds another track or none', () {
      expect(
        playbackTargetFor(
          isMobile: false,
          projectId: 'p1',
          desktopPlayerProjectId: 'p2',
        ),
        PlaybackTarget.local,
      );
      expect(
        playbackTargetFor(isMobile: false, projectId: 'p1'),
        PlaybackTarget.local,
      );
    });

    test('ignores the player belonging to the other platform', () {
      // A stale desktop request must not capture a mobile seek, and vice versa.
      expect(
        playbackTargetFor(
          isMobile: true,
          projectId: 'p1',
          desktopPlayerProjectId: 'p1',
        ),
        PlaybackTarget.local,
      );
      expect(
        playbackTargetFor(
          isMobile: false,
          projectId: 'p1',
          mobilePlayerProjectId: 'p1',
        ),
        PlaybackTarget.local,
      );
    });
  });
}
