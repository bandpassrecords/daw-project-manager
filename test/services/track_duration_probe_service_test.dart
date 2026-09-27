import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/services/track_duration_probe_service.dart';

import '../helpers/test_factories.dart';

void main() {
  // The probe itself drives a real audio decoder, which a unit test has no
  // way to stand up — what is testable, and what actually decides behaviour,
  // is which tracks are worth probing at all.
  group('projectsNeedingDurationProbe', () {
    MusicProject project({
      String id = 'p1',
      int? manual,
      int? auto,
    }) =>
        TestFactories.makeProject(
          id: id,
          durationMs: manual,
          autoDurationMs: auto,
        );

    bool always(MusicProject _) => true;
    bool never(MusicProject _) => false;

    test('probes a track with a preview and no length', () {
      final pending = projectsNeedingDurationProbe(
        [project()],
        hasPlayablePreview: always,
      );
      expect(pending.map((p) => p.id), ['p1']);
    });

    test('skips a track that already has a measured length', () {
      final pending = projectsNeedingDurationProbe(
        [project(auto: 225000)],
        hasPlayablePreview: always,
      );
      expect(pending, isEmpty);
    });

    test('skips a track whose length the user typed', () {
      // Probing it would be wasted work: the typed value wins anyway.
      final pending = projectsNeedingDurationProbe(
        [project(manual: 225000)],
        hasPlayablePreview: always,
      );
      expect(pending, isEmpty);
    });

    test('skips a track with no playable preview', () {
      final pending = projectsNeedingDurationProbe(
        [project()],
        hasPlayablePreview: never,
      );
      expect(pending, isEmpty);
    });

    test('treats a zero stored length as still unknown', () {
      final pending = projectsNeedingDurationProbe(
        [project(auto: 0)],
        hasPlayablePreview: always,
      );
      expect(pending.map((p) => p.id), ['p1']);
    });

    test('picks out only the tracks that need it', () {
      final pending = projectsNeedingDurationProbe(
        [
          project(id: 'has-length', auto: 1000),
          project(id: 'needs-probe'),
          project(id: 'typed', manual: 1000),
          project(id: 'also-needs'),
        ],
        hasPlayablePreview: always,
      );
      expect(pending.map((p) => p.id), ['needs-probe', 'also-needs']);
    });

    test('returns empty for an empty release', () {
      expect(
        projectsNeedingDurationProbe(const [], hasPlayablePreview: always),
        isEmpty,
      );
    });

    test('respects the preview check per project, not wholesale', () {
      final pending = projectsNeedingDurationProbe(
        [project(id: 'playable'), project(id: 'not-playable')],
        hasPlayablePreview: (p) => p.id == 'playable',
      );
      expect(pending.map((p) => p.id), ['playable']);
    });
  });

  group('TrackDurationProbeService.probe', () {
    test('returns null for an empty path without touching a decoder', () async {
      expect(await TrackDurationProbeService.probe(''), isNull);
    });

    test('returns null for a file that is not there', () async {
      expect(
        await TrackDurationProbeService.probe('/nope/missing-file.wav'),
        isNull,
      );
    });
  });
}
