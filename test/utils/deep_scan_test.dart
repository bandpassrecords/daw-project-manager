import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/services/metadata_extractor.dart';
import 'package:daw_project_manager/utils/deep_scan.dart';

import '../helpers/test_factories.dart';

/// The rule reads the file path, so it has to match the name.
MusicProject _project(String fileName) => TestFactories.makeProject(
      filePath: '/Music/Projects/$fileName',
      fileName: fileName,
    );

void main() {
  group('needsDeepScan', () {
    test('a file the library does not know yet needs one', () {
      expect(needsDeepScan(null), isTrue);
    });

    test('a project never deep-scanned needs one', () {
      final p = _project('Song.als');
      expect(needsDeepScan(p), isTrue);
    });

    test('deep-scanned before contents were read: needs one, for its MIDI', () {
      // The regression: these projects carried metadataScanned, so "only
      // projects without metadata" skipped them and their tracks, plug-ins
      // and MIDI clips were never read.
      for (final name in [
        'Song.als',
        'Song.cpr',
        'Song.rpp',
        'Song.flp',
        'Song.npr',
        'Song.song',
        'SONG.ALS',
      ]) {
        final p = _project(name)
            .copyWith(metadataScanned: true);
        expect(needsDeepScan(p), isTrue, reason: name);
      }
    });

    test('deep-scanned with its contents read: done', () {
      final p = _project('Song.als').copyWith(
        metadataScanned: true,
        stats: const ProjectStats(midiTracks: 2, midiClipCount: 3),
      );
      expect(needsDeepScan(p), isFalse);
    });

    test('a format with no contents reader is done once deep-scanned', () {
      for (final name in ['Song.bwproject', 'Song.logicx', 'Song.ptx']) {
        final p = _project(name)
            .copyWith(metadataScanned: true);
        expect(needsDeepScan(p), isFalse, reason: name);
      }
    });
  });

  test('readsProjectContents: the formats with track/plug-in/MIDI readers', () {
    for (final yes in ['a.als', 'a.alp', 'a.cpr', 'a.npr', 'a.rpp', 'a.flp', 'a.song']) {
      expect(MetadataExtractor.readsProjectContents(yes), isTrue, reason: yes);
    }
    for (final no in ['a.bwproject', 'a.mgd', 'a.logicx', 'a.ptx', 'a.wav']) {
      expect(MetadataExtractor.readsProjectContents(no), isFalse, reason: no);
    }
  });
}
