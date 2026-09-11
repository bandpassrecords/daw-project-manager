import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// #110 — a project's cover art, accent colour and icon are user data. They
/// have to survive a Hive round-trip, a Drive restore and a local backup
/// restore; any one of those skipped is silent data loss rather than a missing
/// feature. `thumbnailPath` was already in both serializers but had no UI, so
/// nothing ever exercised it.
void main() {
  group('MusicProjectAdapter', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await HiveTestHelper.setUp();
    });

    tearDownAll(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('cover art, accent colour and icon survive a Hive round-trip',
        () async {
      final original = TestFactories.makeProject(
        id: 'appearance-round-trip',
        thumbnailPath: '/covers/appearance-round-trip_cover.png',
        accentColor: 0xFF4FC3F7,
        iconKey: 'mic',
      );

      final box = await Hive.openBox<MusicProject>('appearance_round_trip');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.thumbnailPath, '/covers/appearance-round-trip_cover.png');
      expect(restored.accentColor, 0xFF4FC3F7);
      expect(restored.iconKey, 'mic');
    });

    test('a record written before #110 reads as automatic', () async {
      // The real backwards-compatibility case: every project already in a
      // user's box was written without indexes 38/39 at all. Null there is
      // exactly the "derive it from the id" default, so no migration is owed.
      final reader = _LegacyRecordReader({
        0: 'legacy-id',
        1: '/Users/artist/Sessions/Old.rpp',
        2: 'Old.rpp',
        3: 1024,
        4: DateTime(2024, 1, 1),
        7: 'Idea',
        8: '.rpp',
        9: DateTime(2024, 1, 1),
        10: DateTime(2024, 1, 2),
      });

      final restored = MusicProjectAdapter().read(reader);

      expect(restored.accentColor, isNull);
      expect(restored.iconKey, isNull);
      expect(restored.thumbnailPath, isNull);
    });
  });

  group('copyWith', () {
    test('clearAccentColor / clearIconKey reset to automatic', () {
      final p = TestFactories.makeProject(accentColor: 0xFF112233, iconKey: 'mic');
      final reset = p.copyWith(clearAccentColor: true, clearIconKey: true);
      expect(reset.accentColor, isNull);
      expect(reset.iconKey, isNull);
    });

    test('clearThumbnailPath drops the cover', () {
      final p = TestFactories.makeProject(thumbnailPath: '/covers/x.png');
      expect(p.copyWith(clearThumbnailPath: true).thumbnailPath, isNull);
    });

    test('an unrelated edit keeps the appearance', () {
      final p = TestFactories.makeProject(
        thumbnailPath: '/covers/x.png',
        accentColor: 0xFF112233,
        iconKey: 'mic',
      );
      final edited = p.copyWith(notes: 'unrelated');
      expect(edited.thumbnailPath, '/covers/x.png');
      expect(edited.accentColor, 0xFF112233);
      expect(edited.iconKey, 'mic');
    });
  });

  group('Drive sync serialization', () {
    test('round-trip preserves the appearance fields', () {
      final service = GoogleDriveSyncService();
      final original = TestFactories.makeProject(
        thumbnailPath: '/covers/song_cover.jpg',
        accentColor: 0xFFEF5350,
        iconKey: 'piano',
      );

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.thumbnailPath, '/covers/song_cover.jpg');
      expect(restored.accentColor, 0xFFEF5350);
      expect(restored.iconKey, 'piano');
    });

    test('a payload from before #110 restores as automatic', () {
      final service = GoogleDriveSyncService();
      final data = service.serializeProjectForTest(
        TestFactories.makeProject(accentColor: 0xFFEF5350, iconKey: 'piano'),
      )
        ..remove('accentColor')
        ..remove('iconKey');

      final restored = service.deserializeProjectForTest(data);
      expect(restored.accentColor, isNull);
      expect(restored.iconKey, isNull);
    });

    test('survives the JSON encode/decode the real upload does', () {
      // jsonDecode hands back num, not int — a plain `as int?` cast on
      // accentColor would throw on every restore.
      final service = GoogleDriveSyncService();
      final encoded = jsonEncode(
        service.serializeProjectForTest(
          TestFactories.makeProject(accentColor: 0xFF4FC3F7, iconKey: 'mic'),
        ),
      );

      final restored = service.deserializeProjectForTest(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(restored.accentColor, 0xFF4FC3F7);
      expect(restored.iconKey, 'mic');
    });
  });

  group('local backup serialization', () {
    test('round-trip preserves the appearance fields', () {
      // Flatpak's only backup path — a field skipped here can never be backed
      // up at all by those users.
      final original = TestFactories.makeProject(
        thumbnailPath: '/covers/song_cover.jpg',
        accentColor: 0xFFBA68C8,
        iconKey: 'album',
      );

      final restored = BackupService.projectFromJson(
        BackupService.projectToJson(original),
      );

      expect(restored.thumbnailPath, '/covers/song_cover.jpg');
      expect(restored.accentColor, 0xFFBA68C8);
      expect(restored.iconKey, 'album');
    });

    test('a backup file from before #110 restores as automatic', () {
      final json = BackupService.projectToJson(
        TestFactories.makeProject(accentColor: 0xFFBA68C8, iconKey: 'album'),
      )
        ..remove('accentColor')
        ..remove('iconKey');

      final restored = BackupService.projectFromJson(json);
      expect(restored.accentColor, isNull);
      expect(restored.iconKey, isNull);
    });

    test('survives the JSON encode/decode the real export does', () {
      final encoded = jsonEncode(
        BackupService.projectToJson(
          TestFactories.makeProject(accentColor: 0xFF81C784, iconKey: 'waves'),
        ),
      );

      final restored = BackupService.projectFromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(restored.accentColor, 0xFF81C784);
      expect(restored.iconKey, 'waves');
    });
  });
}

/// A [BinaryReader] that replays one Hive record's field map — enough to drive
/// `MusicProjectAdapter.read`, which only ever calls [readByte] and [read].
///
/// Lets a record written by an older version of the adapter (no indexes 38/39)
/// be fed to the current one, which is the case no round-trip through a live
/// box can reproduce: writing always uses today's field list.
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
