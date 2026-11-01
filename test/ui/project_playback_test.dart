import 'package:daw_project_manager/models/plugin_capture.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/project_playback.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_factories.dart';

void main() {
  const take = '/data/preview_songs/plugin/p1/take.flac';
  final capture = PluginCapture(path: take, capturedAt: DateTime(2026, 10, 21, 18), durationSeconds: 60);

  DesktopPlayerRequest playing(String projectId, String file) => DesktopPlayerRequest(
        project: TestFactories.makeProject(id: projectId),
        resolvedPath: file,
        generation: 1,
      );

  group('playButtonIsCurrent', () {
    test('a capture promoted to preview song lights the play button that plays it', () {
      // The bug: preview and capture were told apart by file, so with both
      // one file the play button stayed still and the capture's lit up.
      final project = TestFactories.makeProject(id: 'p1', previewSongPath: take, latestCapture: capture);
      expect(playButtonIsCurrent(playing('p1', take), project), isTrue);
    });

    test("the project's capture playing lights its one play button too", () {
      final project = TestFactories.makeProject(
          id: 'p1', previewSongPath: '/music/Master.wav', latestCapture: capture);
      expect(playButtonIsCurrent(playing('p1', take), project), isTrue);
      expect(playButtonIsCurrent(playing('p1', '/music/Master.wav'), project), isTrue);
    });

    test("another project's playback, or none, does not", () {
      final project = TestFactories.makeProject(id: 'p1');
      expect(playButtonIsCurrent(playing('p2', take), project), isFalse);
      expect(playButtonIsCurrent(null, project), isFalse);
    });
  });

  group('offersLatestCapture', () {
    test('only for a project with a capture, where the plugin is detected', () {
      final withCapture = TestFactories.makeProject(latestCapture: capture, previewSongPath: '/music/Master.wav');
      expect(offersLatestCapture(withCapture, pluginDetected: true), isTrue);
      expect(offersLatestCapture(withCapture, pluginDetected: false), isFalse);
      expect(offersLatestCapture(TestFactories.makeProject(), pluginDetected: true), isFalse);
    });
  });
}
