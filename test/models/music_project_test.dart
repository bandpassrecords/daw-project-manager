import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:daw_project_manager/models/music_project.dart';
import '../helpers/test_factories.dart';
import '../helpers/hive_test_helper.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDownAll(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  group('MusicProject.displayName', () {
    test('returns customDisplayName when set', () {
      final p = TestFactories.makeProject(customDisplayName: 'My Custom Name');
      expect(p.displayName, 'My Custom Name');
    });

    test('returns fileName without extension when customDisplayName is null', () {
      final p = TestFactories.makeProject(customDisplayName: null);
      expect(p.displayName, 'MyProject');
    });

    test('returns fileName without extension when customDisplayName is whitespace only', () {
      final p = TestFactories.makeProject(customDisplayName: '   ');
      expect(p.displayName, 'MyProject');
    });
  });

  group('MusicProject.displayName — date stripping', () {
    // The flag is process-global static state (see the doc comment on it);
    // every test here must leave it back at the default.
    tearDown(() => MusicProject.stripDatesFromNames = false);

    test('keeps the date in the file name while the flag is off', () {
      final p = TestFactories.makeProject(
        fileName: '2026-08-02 - Teardrop.cpr',
        customDisplayName: null,
      );
      expect(p.displayName, '2026-08-02 - Teardrop');
    });

    test('strips the date from the file name while the flag is on', () {
      MusicProject.stripDatesFromNames = true;
      final p = TestFactories.makeProject(
        fileName: '2026-08-02 - Teardrop.cpr',
        customDisplayName: null,
      );
      expect(p.displayName, 'Teardrop');
    });

    test('never strips a date the user typed into customDisplayName', () {
      MusicProject.stripDatesFromNames = true;
      final p = TestFactories.makeProject(
        fileName: '2026-08-02 - Teardrop.cpr',
        customDisplayName: '2026-08-02 - My Chosen Name',
      );
      expect(p.displayName, '2026-08-02 - My Chosen Name');
    });

    test('leaves a dateless file name alone with the flag on', () {
      MusicProject.stripDatesFromNames = true;
      final p = TestFactories.makeProject(customDisplayName: null);
      expect(p.displayName, 'MyProject');
    });
  });

  group('MusicProject.projectAge', () {
    test('uses fileCreatedAt when set', () {
      final created = DateTime.now().subtract(const Duration(days: 30));
      final modified = DateTime.now().subtract(const Duration(days: 5));
      final p = TestFactories.makeProject(
        fileCreatedAt: created,
        lastModifiedAt: modified,
      );
      expect(p.projectAge.inDays, closeTo(30, 1));
    });

    test('falls back to lastModifiedAt when fileCreatedAt is null', () {
      final modified = DateTime.now().subtract(const Duration(days: 10));
      final p = TestFactories.makeProject(
        fileCreatedAt: null,
        lastModifiedAt: modified,
      );
      expect(p.projectAge.inDays, closeTo(10, 1));
    });
  });

  group('MusicProject.daysUntilDeadline', () {
    test('returns null when no deadline set', () {
      final p = TestFactories.makeProject(deadline: null);
      expect(p.daysUntilDeadline, isNull);
    });

    test('returns positive value for future deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day + 7),
      );
      // Allow ±1 day for DST boundary crossings.
      expect(p.daysUntilDeadline, inInclusiveRange(6, 7));
    });

    test('returns negative value for past deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day - 3),
      );
      expect(p.daysUntilDeadline, inInclusiveRange(-3, -2));
    });

    test('returns 0 for deadline today', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day),
      );
      expect(p.daysUntilDeadline, 0);
    });
  });

  group('MusicProject.deadlineStatus', () {
    test('returns null when no deadline', () {
      expect(TestFactories.makeProject().deadlineStatus, isNull);
    });

    test('returns "Due today" for today', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day),
        status: 'Mixing',
      );
      expect(p.deadlineStatus, 'Due today');
    });

    test('returns "X days left" format for near-future deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day + 5),
        status: 'Mixing',
      );
      // Exact count may vary by ±1 around DST boundaries; verify the format.
      expect(p.deadlineStatus, matches(RegExp(r'^\d+ days? left$')));
    });

    test('returns "X weeks left" format for multi-week deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day + 21),
        status: 'Mixing',
      );
      expect(p.deadlineStatus, matches(RegExp(r'^\d+ weeks? left$')));
    });

    test('returns overdue format for past deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day - 2),
        status: 'Mixing',
      );
      expect(p.deadlineStatus, matches(RegExp(r'^\d+ days? overdue$')));
    });
  });

  group('MusicProject.projectAgeFormatted', () {
    test('returns "Just now" when project created seconds ago', () {
      final p = TestFactories.makeProject(fileCreatedAt: DateTime.now());
      expect(p.projectAgeFormatted, 'Just now');
    });

    test('returns singular "1 hour" for a one-hour-old project', () {
      final p = TestFactories.makeProject(
        fileCreatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(p.projectAgeFormatted, '1 hour');
    });

    test('returns plural hours for a multi-hour-old project', () {
      final p = TestFactories.makeProject(
        fileCreatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(p.projectAgeFormatted, '5 hours');
    });

    test('returns days when project is several days old', () {
      final p = TestFactories.makeProject(
        fileCreatedAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(p.projectAgeFormatted, '5 days');
    });

    test('returns months only when day remainder is zero', () {
      // 30 days → 1 month exactly (30 % 30 == 0)
      final p = TestFactories.makeProject(
        fileCreatedAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(p.projectAgeFormatted, '1 month');
    });

    test('returns months and days for a partial month', () {
      // 45 days → 1 month, 15 days
      final p = TestFactories.makeProject(
        fileCreatedAt: DateTime.now().subtract(const Duration(days: 45)),
      );
      expect(p.projectAgeFormatted, '1 month, 15 days');
    });

    test('returns years only when month remainder is zero', () {
      // 365 days → 1 year, 0 months
      final p = TestFactories.makeProject(
        fileCreatedAt: DateTime.now().subtract(const Duration(days: 365)),
      );
      expect(p.projectAgeFormatted, '1 year');
    });

    test('returns years and months for multi-year project', () {
      // 400 days → 1 year, 1 month (35 days / 30 = 1 month)
      final p = TestFactories.makeProject(
        fileCreatedAt: DateTime.now().subtract(const Duration(days: 400)),
      );
      expect(p.projectAgeFormatted, '1 year, 1 month');
    });
  });

  group('MusicProject.timeToCompletion', () {
    test('returns null when project is not in a finished phase', () {
      final p = TestFactories.makeProject(
        status: 'Mixing',
        statusChangedAt: DateTime(2025, 1, 1),
      );
      expect(p.timeToCompletion(), isNull);
    });

    test('returns null when statusChangedAt is not set', () {
      final p = TestFactories.makeProject(
        status: 'Finished',
        statusChangedAt: null,
      );
      expect(p.timeToCompletion(), isNull);
    });

    test('uses fileCreatedAt as start date when available', () {
      final p = TestFactories.makeProject(
        status: 'Finished',
        fileCreatedAt: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 6, 1), // later — should be ignored
        statusChangedAt: DateTime(2025, 1, 1),
      );
      // 2024 is a leap year: Jan 1 → Jan 1 next year = 366 days
      expect(p.timeToCompletion()!.inDays, 366);
    });

    test('falls back to createdAt when fileCreatedAt is null', () {
      final p = TestFactories.makeProject(
        status: 'Finished',
        fileCreatedAt: null,
        createdAt: DateTime(2024, 6, 1),
        statusChangedAt: DateTime(2025, 6, 1),
      );
      // Jun 1 2024 → Jun 1 2025 = 365 days (leap day was before June)
      expect(p.timeToCompletion()!.inDays, 365);
    });

    test('accepts custom finishedPhases set', () {
      final p = TestFactories.makeProject(
        status: 'Mastering',
        statusChangedAt: DateTime(2025, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      );
      expect(p.timeToCompletion({'Mastering'}), isNotNull);
      expect(p.timeToCompletion({'Finished'}), isNull);
    });
  });

  group('MusicProject.timeToCompletionFormatted', () {
    test('returns null when project is not finished', () {
      final p = TestFactories.makeProject(status: 'Mixing');
      expect(p.timeToCompletionFormatted(), isNull);
    });

    test('returns "Less than an hour" for very quick completion', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        status: 'Finished',
        createdAt: now.subtract(const Duration(minutes: 30)),
        statusChangedAt: now,
      );
      expect(p.timeToCompletionFormatted(), 'Less than an hour');
    });

    test('returns days for a week-long project', () {
      final p = TestFactories.makeProject(
        status: 'Finished',
        createdAt: DateTime(2025, 1, 1),
        statusChangedAt: DateTime(2025, 1, 8),
      );
      expect(p.timeToCompletionFormatted(), '7 days');
    });

    test('returns months and days for a multi-month project', () {
      // Jan 1 → Feb 15 = 45 days → 1 month, 15 days
      final p = TestFactories.makeProject(
        status: 'Finished',
        createdAt: DateTime(2025, 1, 1),
        statusChangedAt: DateTime(2025, 2, 15),
      );
      expect(p.timeToCompletionFormatted(), '1 month, 15 days');
    });
  });

  group('MusicProject.compatibleCamelotCodes', () {
    test('returns null when musicalKey is null', () {
      final p = TestFactories.makeProject(musicalKey: null);
      expect(p.compatibleCamelotCodes, isNull);
    });

    test('includes the relative key (same number, opposite letter)', () {
      // A minor = 8A → relative major = C major = 8B
      final p = TestFactories.makeProject(musicalKey: 'A minor');
      expect(p.compatibleCamelotCodes, contains('8B'));
    });

    test('includes adjacent keys on the wheel (+1 and -1)', () {
      // A minor = 8A → 9A and 7A
      final codes = TestFactories.makeProject(musicalKey: 'A minor').compatibleCamelotCodes!;
      expect(codes, contains('9A'));
      expect(codes, contains('7A'));
    });

    test('includes energy-shift keys (+7 and -7) with wrap-around', () {
      // A minor = 8A → +7 = 15 → wraps to 3A; -7 = 1A
      final codes = TestFactories.makeProject(musicalKey: 'A minor').compatibleCamelotCodes!;
      expect(codes, contains('3A'));
      expect(codes, contains('1A'));
    });

    test('+1 wraps correctly from 12 to 1', () {
      // E major = 12B → +1 wraps to 1B
      expect(
        TestFactories.makeProject(musicalKey: 'E major').compatibleCamelotCodes,
        contains('1B'),
      );
    });

    test('-1 wraps correctly from 1 to 12', () {
      // B major = 1B → -1 wraps to 12B
      expect(
        TestFactories.makeProject(musicalKey: 'B major').compatibleCamelotCodes,
        contains('12B'),
      );
    });
  });

  group('MusicProject.camelotCode', () {
    test('returns correct code for C minor', () {
      final p = TestFactories.makeProject(musicalKey: 'c minor');
      expect(p.camelotCode, '5A');
    });

    test('returns correct code for A major', () {
      final p = TestFactories.makeProject(musicalKey: 'a major');
      expect(p.camelotCode, '11B');
    });

    test('returns correct code for G# minor (enharmonic)', () {
      final p = TestFactories.makeProject(musicalKey: 'g# minor');
      expect(p.camelotCode, '1A');
    });

    test('returns null for unrecognised key', () {
      final p = TestFactories.makeProject(musicalKey: 'X# ultra');
      expect(p.camelotCode, isNull);
    });

    test('returns null when musicalKey is null', () {
      final p = TestFactories.makeProject(musicalKey: null);
      expect(p.camelotCode, isNull);
    });

    test('resolves enharmonic G#/Ab Major notation', () {
      final p = TestFactories.makeProject(musicalKey: 'G#/Ab Major');
      expect(p.camelotCode, '4B');
    });

    test('resolves enharmonic C#/Db Minor notation', () {
      final p = TestFactories.makeProject(musicalKey: 'C#/Db Minor');
      expect(p.camelotCode, '12A');
    });
  });

  group('camelotCodeForKey (top-level)', () {
    // MusicProject.camelotCode delegates to this function so templates (and
    // anything else without a MusicProject instance) can reuse the same
    // lookup table without duplicating it.
    test('matches MusicProject.camelotCode for the same key', () {
      final p = TestFactories.makeProject(musicalKey: 'c minor');
      expect(camelotCodeForKey('c minor'), p.camelotCode);
    });

    test('returns null for null or empty input', () {
      expect(camelotCodeForKey(null), isNull);
      expect(camelotCodeForKey(''), isNull);
    });
  });

  group('MusicProject.copyWith', () {
    test('preserves unchanged fields', () {
      final original = TestFactories.makeProject(bpm: 128.0, notes: 'cool track');
      final copy = original.copyWith(status: 'Finished');
      expect(copy.bpm, 128.0);
      expect(copy.notes, 'cool track');
      expect(copy.status, 'Finished');
    });

    test('clearNotes sets notes to null', () {
      final p = TestFactories.makeProject(notes: 'some notes');
      expect(p.copyWith(clearNotes: true).notes, isNull);
    });

    test('clearDeadline sets deadline to null', () {
      final p = TestFactories.makeProject(
        deadline: DateTime(2026, 6, 1),
      );
      expect(p.copyWith(clearDeadline: true).deadline, isNull);
    });

    test('does not change lastModifiedAt unless explicitly provided', () {
      final original = TestFactories.makeProject();
      final copy = original.copyWith(status: 'Finished');
      expect(copy.lastModifiedAt, original.lastModifiedAt);
    });

    // Regression: clearing nullable fields via copyWith was broken — passing null
    // for bpm/musicalKey/customDisplayName had no effect because of the
    // `field ?? this.field` pattern. Fix added explicit clearField bool flags.

    test('clearBpm sets bpm to null', () {
      final p = TestFactories.makeProject(bpm: 128.0);
      expect(p.copyWith(clearBpm: true).bpm, isNull);
    });

    test('passing null bpm without clearBpm preserves existing value', () {
      final p = TestFactories.makeProject(bpm: 128.0);
      expect(p.copyWith(bpm: null).bpm, 128.0);
    });

    test('clearMusicalKey sets musicalKey to null', () {
      final p = TestFactories.makeProject(musicalKey: 'C minor');
      expect(p.copyWith(clearMusicalKey: true).musicalKey, isNull);
    });

    test('passing null musicalKey without clearMusicalKey preserves existing value', () {
      final p = TestFactories.makeProject(musicalKey: 'C minor');
      expect(p.copyWith(musicalKey: null).musicalKey, 'C minor');
    });

    test('clearDawType and clearDawVersion set both to null', () {
      final p = TestFactories.makeProject(dawType: 'FL Studio', dawVersion: '21');
      final cleared = p.copyWith(clearDawType: true, clearDawVersion: true);
      expect(cleared.dawType, isNull);
      expect(cleared.dawVersion, isNull);
    });

    test('passing null dawType without clearDawType preserves existing value', () {
      final p = TestFactories.makeProject(dawType: 'FL Studio');
      expect(p.copyWith(dawType: null).dawType, 'FL Studio');
    });

    test('copyWith updates projectNotes when provided', () {
      final p = TestFactories.makeProject(projectNotes: null);
      expect(p.copyWith(projectNotes: 'Title\nby Author\n\nSome notes').projectNotes,
          'Title\nby Author\n\nSome notes');
    });

    test('passing null projectNotes to copyWith preserves existing value', () {
      final p = TestFactories.makeProject(projectNotes: 'existing notes');
      expect(p.copyWith(projectNotes: null).projectNotes, 'existing notes');
    });

    test('clearCustomDisplayName sets customDisplayName to null', () {
      final p = TestFactories.makeProject(customDisplayName: 'My Track');
      expect(p.copyWith(clearCustomDisplayName: true).customDisplayName, isNull);
    });

    test('passing null customDisplayName without flag preserves existing value', () {
      final p = TestFactories.makeProject(customDisplayName: 'My Track');
      expect(p.copyWith(customDisplayName: null).customDisplayName, 'My Track');
    });

    test('copyWith sets sourceTemplateId when provided', () {
      final p = TestFactories.makeProject(sourceTemplateId: null);
      expect(p.copyWith(sourceTemplateId: 'template-1').sourceTemplateId, 'template-1');
    });

    test('clearSourceTemplateId sets sourceTemplateId to null', () {
      final p = TestFactories.makeProject(sourceTemplateId: 'template-1');
      expect(p.copyWith(clearSourceTemplateId: true).sourceTemplateId, isNull);
    });
  });

  group('MusicProjectAdapter (Hive round-trip)', () {
    test('preserves all fields after write and read', () async {
      final todo = TestFactories.makeTodo();
      final original = TestFactories.makeProject(
        id: 'hive-round-trip',
        bpm: 140.0,
        musicalKey: 'F# minor',
        notes: 'test notes',
        fileCreatedAt: DateTime(2023, 5, 20),
        deadline: DateTime(2026, 12, 31),
        todos: [todo],
        dawType: 'FL Studio',
        dawVersion: '21',
        projectNotes: 'Notes 1\nby Audio Crawler\n\nSome project notes',
        sourceTemplateId: 'template-42',
      );

      final box = await Hive.openBox<MusicProject>('round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.id, original.id);
      expect(restored.filePath, original.filePath);
      expect(restored.lastModifiedAt, original.lastModifiedAt);
      expect(restored.fileCreatedAt, original.fileCreatedAt);
      expect(restored.createdAt, original.createdAt);
      expect(restored.bpm, original.bpm);
      expect(restored.musicalKey, original.musicalKey);
      expect(restored.notes, original.notes);
      expect(restored.deadline, original.deadline);
      expect(restored.dawType, original.dawType);
      expect(restored.projectNotes, original.projectNotes);
      expect(restored.sourceTemplateId, original.sourceTemplateId);
      expect(restored.todos.length, 1);
      expect(restored.todos.first.text, todo.text);
    });

    test('reads back null optional fields correctly', () async {
      final original = TestFactories.makeMinimalProject(id: 'minimal-hive');
      final box = await Hive.openBox<MusicProject>('minimal_round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.fileCreatedAt, isNull);
      expect(restored.deadline, isNull);
      expect(restored.bpm, isNull);
      expect(restored.notes, isNull);
      expect(restored.todos, isEmpty);
      expect(restored.sourceTemplateId, isNull);
    });

    test('preserves the archive fields (#116)', () async {
      // The adapter is hand-written, so a new field is only persisted if
      // read/write were both updated and writeByte's field count bumped.
      final original = TestFactories.makeProject(
        id: 'archive-hive-round-trip',
        archivePath: '/Volumes/Archive/Midnight.zip',
        archivedAt: DateTime(2026, 3, 4, 15, 30),
        archiveEntryPath: 'Midnight/Midnight.als',
      );

      final box = await Hive.openBox<MusicProject>('archive_round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.archivePath, '/Volumes/Archive/Midnight.zip');
      expect(restored.archivedAt, DateTime(2026, 3, 4, 15, 30));
      expect(restored.archiveEntryPath, 'Midnight/Midnight.als');
      expect(restored.isArchived, isTrue);
    });
  });

  group('MusicProject.previewShareFileName', () {
    const localPath = '/previews/abc123_preview.wav';

    test('returns null when previewSongPath is null', () {
      final p = TestFactories.makeProject(previewSongPath: null);
      expect(p.previewShareFileName, isNull);
    });

    test('returns null when previewSongPath is empty', () {
      final p = TestFactories.makeProject(previewSongPath: '');
      expect(p.previewShareFileName, isNull);
    });

    test('returns null when previewSongPath is a Drive reference', () {
      final p = TestFactories.makeProject(
        previewSongPath: 'drive://1AbCdEfGhIjKlMnOpQrS',
      );
      expect(p.previewShareFileName, isNull);
    });

    test('returns stored previewSongFileName when it is a real name', () {
      final p = TestFactories.makeProject(
        previewSongPath: localPath,
        previewSongFileName: 'My Demo Mix.wav',
      );
      expect(p.previewShareFileName, 'My Demo Mix.wav');
    });

    test('falls back to project displayName when previewSongFileName is null', () {
      final p = TestFactories.makeProject(
        customDisplayName: 'Chill Beats',
        previewSongPath: localPath,
        previewSongFileName: null,
      );
      expect(p.previewShareFileName, 'Chill Beats.wav');
    });

    test('falls back to project displayName when previewSongFileName is UUID-based', () {
      final p = TestFactories.makeProject(
        customDisplayName: 'Summer Track',
        previewSongPath: localPath,
        previewSongFileName:
            '550e8400-e29b-41d4-a716-446655440000_preview.wav',
      );
      expect(p.previewShareFileName, 'Summer Track.wav');
    });

    test('sanitizes invalid filename characters from displayName', () {
      final p = TestFactories.makeProject(
        customDisplayName: 'Track: "Final?" <Mix>',
        previewSongPath: localPath,
        previewSongFileName: null,
      );
      expect(p.previewShareFileName, 'Track_ _Final__ _Mix_.wav');
    });

    test('uses fileName stem when customDisplayName is not set', () {
      final p = TestFactories.makeProject(
        customDisplayName: null,
        fileName: 'MyProject.als',
        previewSongPath: '/previews/xyz_preview.mp3',
        previewSongFileName: null,
      );
      expect(p.previewShareFileName, 'MyProject.mp3');
    });

    test('preserves stored name that starts with uuid-like text but is not a backup name', () {
      final p = TestFactories.makeProject(
        previewSongPath: localPath,
        previewSongFileName: '550e8400-e29b-41d4-a716-446655440000_finalmaster.wav',
      );
      // Does NOT match the strict "_preview." pattern, so it is kept as-is.
      expect(
        p.previewShareFileName,
        '550e8400-e29b-41d4-a716-446655440000_finalmaster.wav',
      );
    });

    // The share filename is what the recipient sees in WhatsApp, so it drops
    // the date regardless of the display-only stripDatesFromNames preference.
    group('date stripping is unconditional', () {
      tearDown(() => MusicProject.stripDatesFromNames = false);

      test('strips the date from a stored previewSongFileName', () {
        final p = TestFactories.makeProject(
          previewSongPath: localPath,
          previewSongFileName: '2026-08-02 - My Demo Mix.wav',
        );
        expect(p.previewShareFileName, 'My Demo Mix.wav');
      });

      test('strips a trailing date while keeping the extension', () {
        final p = TestFactories.makeProject(
          previewSongPath: localPath,
          previewSongFileName: 'My Demo Mix_20260802_1430.wav',
        );
        expect(p.previewShareFileName, 'My Demo Mix.wav');
      });

      test('strips the date from the displayName fallback with the flag off', () {
        final p = TestFactories.makeProject(
          customDisplayName: null,
          fileName: '2026-08-02 - Teardrop.cpr',
          previewSongPath: localPath,
          previewSongFileName: null,
        );
        expect(MusicProject.stripDatesFromNames, isFalse);
        expect(p.displayName, '2026-08-02 - Teardrop');
        expect(p.previewShareFileName, 'Teardrop.wav');
      });

      test('gives the same result with the flag on', () {
        MusicProject.stripDatesFromNames = true;
        final p = TestFactories.makeProject(
          customDisplayName: null,
          fileName: '2026-08-02 - Teardrop.cpr',
          previewSongPath: localPath,
          previewSongFileName: null,
        );
        expect(p.previewShareFileName, 'Teardrop.wav');
      });
    });
  });

  group('TestFactories.makeProject field coverage', () {
    // Regression: thumbnailPath, uploadedPreviewSongHash, sessions and
    // metadataScanned were added to MusicProject but never exposed as
    // makeProject() params, so tests couldn't construct a project with
    // them set without bypassing the factory — against the CLAUDE.md
    // checklist for adding a MusicProject field.
    test('exposes thumbnailPath, uploadedPreviewSongHash, sessions and metadataScanned', () {
      final session = SessionRecord(
        id: 's1',
        startedAt: DateTime(2025, 1, 1, 10, 0),
        endedAt: DateTime(2025, 1, 1, 11, 0),
        durationSeconds: 3600,
      );

      final p = TestFactories.makeProject(
        thumbnailPath: '/thumbs/p1.png',
        uploadedPreviewSongHash: 'abc123',
        sessions: [session],
        metadataScanned: true,
      );

      expect(p.thumbnailPath, '/thumbs/p1.png');
      expect(p.uploadedPreviewSongHash, 'abc123');
      expect(p.sessions, [session]);
      expect(p.metadataScanned, isTrue);
    });

    test('defaults thumbnailPath/uploadedPreviewSongHash to null, sessions to empty, metadataScanned to false', () {
      final p = TestFactories.makeProject();

      expect(p.thumbnailPath, isNull);
      expect(p.uploadedPreviewSongHash, isNull);
      expect(p.sessions, isEmpty);
      expect(p.metadataScanned, isFalse);
    });
  });

  group('MusicProject archiving (#116)', () {
    test('isArchived follows archivePath', () {
      expect(TestFactories.makeProject().isArchived, isFalse);
      expect(
        TestFactories.makeProject(
          archivePath: '/Volumes/Archive/Midnight.zip',
        ).isArchived,
        isTrue,
      );
    });

    test('an archived project is never a missing-file candidate', () {
      // The regression this guards: an archived project's filePath still names
      // the emptied original location, so without this gate "Delete Missing"
      // would offer to throw away the one row pointing at the archive.
      final archived = TestFactories.makeProject(
        archivePath: '/Volumes/Archive/Midnight.zip',
        archiveEntryPath: 'Midnight/Midnight.als',
      );

      expect(archived.isMissingFileCandidate, isFalse);
    });

    test('an ordinary project is still a missing-file candidate', () {
      expect(TestFactories.makeProject().isMissingFileCandidate, isTrue);
    });

    test('a stack stays excluded regardless of archive state', () {
      expect(
        TestFactories.makeProject(isVirtual: true).isMissingFileCandidate,
        isFalse,
      );
    });

    test('clearing the archive fields un-archives via copyWith', () {
      final archived = TestFactories.makeProject(
        archivePath: '/Volumes/Archive/Midnight.zip',
        archivedAt: DateTime(2026, 3, 4),
        archiveEntryPath: 'Midnight/Midnight.als',
      );

      final restored = archived.copyWith(
        clearArchivePath: true,
        clearArchivedAt: true,
        clearArchiveEntryPath: true,
      );

      expect(restored.isArchived, isFalse);
      expect(restored.archivedAt, isNull);
      expect(restored.archiveEntryPath, isNull);
      expect(restored.isMissingFileCandidate, isTrue);
    });
  });
}
