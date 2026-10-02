import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// Project stats are read from the file, but they still have to survive a
/// Hive round-trip, a Drive restore and a local backup: a phone, or a
/// Flatpak restore without the project folders, can't re-read the file.
void main() {
  const stats = ProjectStats(
    audioTracks: 41,
    midiTracks: 6,
    instrumentTracks: 9,
    samplerTracks: 2,
    busTracks: 3,
    folderTracks: 4,
    plugins: ['Diva', 'Pro-Q 3', 'Serum'],
    midiClipCount: 25,
  );

  group('ProjectStats', () {
    test('totals split content tracks from buses and folders', () {
      expect(stats.contentTracks, 58);
      expect(stats.totalTracks, 65);
      expect(stats.isEmpty, isFalse);
      expect(const ProjectStats().isEmpty, isTrue);
    });

    test('map round-trip preserves every field', () {
      expect(ProjectStats.fromMap(stats.toMap()), stats);
    });

    test('an unknown clip count stays unknown rather than becoming 0', () {
      const noClips = ProjectStats(audioTracks: 1);
      final restored = ProjectStats.fromMap(noClips.toMap());
      expect(restored.midiClipCount, isNull);
    });

    test('a malformed map costs the bad fields, never the whole value', () {
      final restored = ProjectStats.fromMap({
        'audio': 'lots',
        'midi': -3,
        'instrument': 2.0,
        'plugins': ['Serum', 7, null, 'Diva'],
        'midiClips': 'x',
      });
      expect(restored.audioTracks, 0);
      expect(restored.midiTracks, 0);
      expect(restored.instrumentTracks, 2);
      expect(restored.plugins, ['Serum', 'Diva']);
      expect(restored.midiClipCount, isNull);
    });

    test('tryFromMap reads anything that is not a map as absent', () {
      expect(ProjectStats.tryFromMap(null), isNull);
      expect(ProjectStats.tryFromMap('stats'), isNull);
      expect(ProjectStats.tryFromMap(const {'audio': 1})?.audioTracks, 1);
    });

    test('equality is by value, plugin order included', () {
      expect(ProjectStats.fromMap(stats.toMap()).hashCode, stats.hashCode);
      expect(
        const ProjectStats(plugins: ['A', 'B']) ==
            const ProjectStats(plugins: ['B', 'A']),
        isFalse,
      );
    });
  });

  group('normalizePluginNames', () {
    test('strips architecture suffixes and dedupes case-insensitively', () {
      expect(
        normalizePluginNames([
          'Serum_x64',
          'serum',
          'OTT (x64)',
          'LFOTool_x64',
          '  Pro-Q 3 ',
          '',
          'Kick 3',
        ]),
        ['Kick 3', 'LFOTool', 'OTT', 'Pro-Q 3', 'Serum'],
      );
    });

    test('sorts case-insensitively', () {
      expect(normalizePluginNames(['soothe2', 'Decapitator', 'bx_cleansweep']),
          ['bx_cleansweep', 'Decapitator', 'soothe2']);
    });

    test('does not merge a vendor-prefixed name into a shorter one', () {
      // A rule general enough for "FabFilter Pro-Q 3" → "Pro-Q 3" would also
      // turn "Tube Compressor" into "Compressor".
      expect(normalizePluginNames(['Compressor', 'Tube Compressor']),
          ['Compressor', 'Tube Compressor']);
    });
  });

  group('MusicProject.stats', () {
    test('defaults to null — never extracted', () {
      expect(TestFactories.makeProject().stats, isNull);
    });

    test('copyWith carries stats through an unrelated edit', () {
      final p = TestFactories.makeProject().copyWith(stats: stats);
      expect(p.stats, stats);
      expect(p.copyWith(notes: 'unrelated').stats, stats);
    });
  });

  group('MusicProjectAdapter', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await HiveTestHelper.setUp();
    });

    tearDownAll(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('stats survive a Hive round-trip', () async {
      final original =
          TestFactories.makeProject(id: 'stats-round-trip', stats: stats);
      final box = await Hive.openBox<MusicProject>('stats_round_trip_test');
      await box.put(original.id, original);

      expect(box.get(original.id)!.stats, stats);
    });

    test('a project without stats round-trips as null, not as empty',
        () async {
      final original = TestFactories.makeProject(id: 'no-stats');
      final box = await Hive.openBox<MusicProject>('stats_null_test');
      await box.put(original.id, original);

      expect(box.get(original.id)!.stats, isNull);
    });

    test('a record written before stats existed reads as null', () {
      final restored = MusicProjectAdapter().read(_LegacyRecordReader({
        0: 'legacy-id',
        1: '/Users/artist/Sessions/Old.cpr',
        2: 'Old.cpr',
        3: 1024,
        4: DateTime(2024, 1, 1),
        7: 'Idea',
        8: '.cpr',
        9: DateTime(2024, 1, 1),
        10: DateTime(2024, 1, 2),
      }));

      expect(restored.stats, isNull);
    });
  });

  group('serialization', () {
    test('Drive sync round-trip preserves stats', () {
      final service = GoogleDriveSyncService();
      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(TestFactories.makeProject(stats: stats)),
      );
      expect(restored.stats, stats);
    });

    test('a Drive record from before stats existed restores as null', () {
      final service = GoogleDriveSyncService();
      final data = service
          .serializeProjectForTest(TestFactories.makeProject(stats: stats))
        ..remove('stats');
      expect(service.deserializeProjectForTest(data).stats, isNull);
    });

    test('local backup round-trip preserves stats', () {
      final restored = BackupService.projectFromJson(
        BackupService.projectToJson(TestFactories.makeProject(stats: stats)),
      );
      expect(restored.stats, stats);
    });

    test('a backup file from before stats existed restores as null', () {
      final json =
          BackupService.projectToJson(TestFactories.makeProject(stats: stats))
            ..remove('stats');
      expect(BackupService.projectFromJson(json).stats, isNull);
    });
  });
}

/// Replays one Hive record's field map into `MusicProjectAdapter.read` — see
/// the same helper in `project_marker_test.dart`.
class _LegacyRecordReader implements BinaryReader {
  _LegacyRecordReader(Map<int, dynamic> fields)
      : _script = [
          fields.length,
          for (final entry in fields.entries) ...[entry.key, entry.value],
        ];

  final List<dynamic> _script;
  int _cursor = 0;

  @override
  int readByte() => _script[_cursor++] as int;

  @override
  dynamic read([int? typeId]) => _script[_cursor++];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not needed here');
}
