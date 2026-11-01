import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/plugin_capture.dart';
import 'package:daw_project_manager/ui/project_playback.dart';
import 'package:daw_project_manager/utils/capture_only_play.dart';

import '../helpers/test_factories.dart';

void main() {
  final capture = PluginCapture(
    path: '/captures/take.wav',
    capturedAt: DateTime(2026, 5, 1),
    durationSeconds: 30,
  );

  group('playsCaptureOnly', () {
    test('a capture and nothing else', () {
      expect(playsCaptureOnly(TestFactories.makeProject(latestCapture: capture)), isTrue);
    });

    test('not when a preview song is set', () {
      expect(
        playsCaptureOnly(TestFactories.makeProject(
          latestCapture: capture,
          previewSongPath: '/music/Master.wav',
        )),
        isFalse,
      );
    });

    test('not when a mixdown was detected', () {
      expect(
        playsCaptureOnly(TestFactories.makeProject(
          latestCapture: capture,
          previewSongAutoPath: '/Bounces/mix.wav',
        )),
        isFalse,
      );
    });

    test('not without a capture', () {
      expect(playsCaptureOnly(TestFactories.makeProject()), isFalse);
    });
  });

  group('offersLatestCapture', () {
    test('a choice is offered only where there is a preview to choose against', () {
      final both = TestFactories.makeProject(
        latestCapture: capture,
        previewSongPath: '/music/Master.wav',
      );
      final only = TestFactories.makeProject(latestCapture: capture);

      expect(offersLatestCapture(both, pluginDetected: true), isTrue);
      expect(offersLatestCapture(both, pluginDetected: false), isFalse);
      expect(offersLatestCapture(only, pluginDetected: true), isFalse,
          reason: 'the play button plays it directly');
    });
  });
}
