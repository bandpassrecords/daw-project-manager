import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/custom_field.dart';
import 'package:daw_project_manager/models/custom_theme.dart';
import 'package:daw_project_manager/models/midi_collection.dart';
import 'package:daw_project_manager/models/part_template.dart';
import 'package:daw_project_manager/models/stored_midi_clips.dart';
import 'package:daw_project_manager/models/todo_template.dart';
import 'package:daw_project_manager/providers/theme_provider.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import 'package:daw_project_manager/utils/sync_time.dart';

import '../helpers/test_factories.dart';

/// Synced instants once went into the JSON as local times with no offset.
/// Read on a device in another time zone, or twice in the hour the clocks go
/// back, they named a different moment: a restore made at 02:30 on the night
/// of 25 October came out an hour before its own deletion and lost to it.
void main() {
  // Any instant: the property is that the text names it, wherever it's read.
  final instant = DateTime(2026, 10, 25, 2, 30, 15, 123);

  bool namesItsZone(Object? json) => json is String && json.endsWith('Z');

  group('syncInstant / parseSyncInstant', () {
    test('writes UTC, with its Z', () {
      expect(namesItsZone(syncInstant(instant)), isTrue);
      expect(DateTime.parse(syncInstant(instant)).isAtSameMomentAs(instant), isTrue);
    });

    test('writes to the millisecond, as Hive keeps it', () {
      // In memory a row changed this session has microseconds; read back
      // from Hive it doesn't. Written as they are, the same row made two
      // different backups, and an unchanged library was uploaded every launch.
      final fresh = DateTime.utc(2026, 10, 25, 2, 30, 15, 123, 456);
      final fromHive = DateTime.fromMillisecondsSinceEpoch(fresh.millisecondsSinceEpoch, isUtc: true);

      expect(syncInstant(fresh), syncInstant(fromHive));
      expect(syncInstant(fresh), '2026-10-25T02:30:15.123Z');
    });

    test('reads back the same moment, in local time', () {
      final read = parseSyncInstant(syncInstant(instant));
      expect(read, instant);
      expect(read.isUtc, isFalse);
    });

    test('reads an older file, written without an offset, as local time', () {
      expect(parseSyncInstant('2026-06-01T10:00:00.000'), DateTime(2026, 6, 1, 10));
      expect(tryParseSyncInstant('2026-06-01T10:00:00.000'), DateTime(2026, 6, 1, 10));
    });

    test('tryParseSyncInstant: nothing for nothing', () {
      expect(tryParseSyncInstant(null), isNull);
      expect(tryParseSyncInstant(''), isNull);
      expect(tryParseSyncInstant(42), isNull);
    });
  });

  group('local backup', () {
    test("a project's instants name their zone and come back as they were", () {
      final project = TestFactories.makeProject(
        createdAt: instant,
        updatedAt: instant,
        lastModifiedAt: instant,
      );
      final json = BackupService.projectToJson(project);

      for (final field in ['createdAt', 'updatedAt', 'lastModifiedAt']) {
        expect(namesItsZone(json[field]), isTrue, reason: field);
      }
      final restored = BackupService.projectFromJson(json);
      expect(restored.createdAt, instant);
      expect(restored.updatedAt, instant);
      expect(restored.lastModifiedAt, instant);
    });

    test('a deadline stays a date on the calendar', () {
      final deadline = DateTime(2026, 11, 30);
      final json = BackupService.projectToJson(TestFactories.makeProject(deadline: deadline));

      expect(namesItsZone(json['deadline']), isFalse);
      expect(BackupService.projectFromJson(json).deadline, deadline);
    });
  });

  group('what decides the newer copy, for every merged kind', () {
    test('custom field definitions', () {
      final field = CustomFieldDefinition(
        id: 'f',
        name: 'Mood',
        type: CustomFieldType.text,
        updatedAt: instant,
        deletedAt: instant,
      );
      final json = field.toJson();
      expect(namesItsZone(json['updatedAt']), isTrue);
      expect(namesItsZone(json['deletedAt']), isTrue);
      final back = CustomFieldDefinition.fromJson(json);
      expect(back.updatedAt, instant);
      expect(back.deletedAt, instant);
    });

    test('custom themes', () {
      final theme = AppThemes.classicDarkSpec.copyWith(id: 't', updatedAt: instant);
      final json = theme.toJson();
      expect(namesItsZone(json['updatedAt']), isTrue);
      expect(CustomTheme.fromJson(json).updatedAt, instant);
    });

    test('MIDI collections', () {
      final collection = MidiCollection(id: 'c', name: 'Basses', createdAt: instant, updatedAt: instant);
      final json = collection.toJson();
      expect(namesItsZone(json['updatedAt']), isTrue);
      expect(MidiCollection.tryParse(json)!.updatedAt, instant);
    });

    test('stored MIDI clips', () {
      final stored = StoredMidiClips(clips: const [], extractedAt: instant, sourceModifiedAt: instant);
      final json = stored.toJson();
      expect(namesItsZone(json['extractedAt']), isTrue);
      expect(namesItsZone(json['sourceModifiedAt']), isTrue);
      final back = StoredMidiClips.tryParse(json)!;
      expect(back.extractedAt, instant);
      expect(back.sourceModifiedAt, instant);
    });

    test('to-do and part templates', () {
      final todo = TodoTemplate(id: 't', name: 'Mix', items: const [], createdAt: instant, updatedAt: instant);
      expect(namesItsZone(todo.toJson()['updatedAt']), isTrue);
      expect(TodoTemplate.fromJson(todo.toJson()).updatedAt, instant);

      final part = PartTemplate(id: 'p', name: 'Band', items: const [], createdAt: instant, updatedAt: instant);
      expect(namesItsZone(part.toJson()['updatedAt']), isTrue);
      expect(PartTemplate.fromJson(part.toJson()).updatedAt, instant);
    });
  });
}
