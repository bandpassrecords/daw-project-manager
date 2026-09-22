import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_attachment.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// #112 — a project's attachments (the reference track, the stem-delivery
/// link, the lyric sheet, the contract) are user data, so they have to survive
/// a Hive round-trip, a Drive restore and a local backup restore. Any one of
/// those skipped is silent data loss rather than a missing feature.
void main() {
  final reference = ProjectAttachment(
    id: 'a1',
    kind: ProjectAttachmentKind.file,
    target: '/Users/artist/Refs/reference.wav',
    label: 'Reference track',
    addedAt: DateTime(2025, 2, 3, 14, 5),
  );
  final stems = ProjectAttachment(
    id: 'a2',
    kind: ProjectAttachmentKind.link,
    target: 'https://drive.google.com/drive/folders/abc123',
    label: 'Stem delivery',
    addedAt: DateTime(2025, 2, 4, 9, 30),
    note: 'expires in 7 days',
  );

  group('ProjectAttachment.displayLabel', () {
    test('uses the label the user typed', () {
      expect(reference.displayLabel, 'Reference track');
    });

    test('falls back to the file name for an unlabelled file', () {
      expect(
        reference.copyWith(label: '  ').displayLabel,
        'reference.wav',
      );
    });

    test('falls back to host and path for an unlabelled link', () {
      expect(
        stems.copyWith(label: '').displayLabel,
        'drive.google.com/drive/folders/abc123',
      );
    });

    test('a bare host link drops the lone slash', () {
      final bare = stems.copyWith(label: '', target: 'https://example.com/');
      expect(bare.displayLabel, 'example.com');
    });

    test('an unparseable link falls back to the raw target', () {
      final odd = stems.copyWith(label: '', target: 'notaurl');
      expect(odd.displayLabel, 'notaurl');
    });
  });

  group('ProjectAttachment.looksLikeUrl', () {
    test('accepts the schemes a link is actually pasted with', () {
      expect(ProjectAttachment.looksLikeUrl('https://example.com'), isTrue);
      expect(ProjectAttachment.looksLikeUrl('http://example.com'), isTrue);
      expect(
        ProjectAttachment.looksLikeUrl('  https://example.com  '),
        isTrue,
        reason: 'a pasted URL usually brings whitespace with it',
      );
      expect(ProjectAttachment.looksLikeUrl('www.example.com'), isTrue);
      expect(ProjectAttachment.looksLikeUrl('mailto:a@b.com'), isTrue);
    });

    test('a Windows path is not a URL despite the colon', () {
      expect(
        ProjectAttachment.looksLikeUrl(r'C:\Stems\ref.wav'),
        isFalse,
        reason: 'mistaking this for a link would open a browser tab',
      );
      expect(ProjectAttachment.looksLikeUrl(r'\\nas\stems\ref.wav'), isFalse);
    });

    test('a posix path is not a URL', () {
      expect(
        ProjectAttachment.looksLikeUrl('/Users/artist/Refs/reference.wav'),
        isFalse,
      );
      expect(ProjectAttachment.looksLikeUrl(''), isFalse);
    });

    test('file:// describes something on disk, not a page to browse', () {
      expect(ProjectAttachment.looksLikeUrl('file:///Users/a/ref.wav'), isFalse);
    });
  });

  group('ProjectAttachment.normalizeUrl', () {
    test('gives a bare www host the scheme it is missing', () {
      expect(
        ProjectAttachment.normalizeUrl('www.example.com/song'),
        'https://www.example.com/song',
      );
    });

    test('leaves a URL that already has a scheme alone', () {
      expect(
        ProjectAttachment.normalizeUrl('  http://example.com  '),
        'http://example.com',
      );
    });
  });

  group('ProjectAttachment map round-trip', () {
    test('preserves every field', () {
      expect(ProjectAttachment.fromMap(reference.toMap()), reference);
      expect(ProjectAttachment.fromMap(stems.toMap()), stems);
    });

    test('an absent note stays absent rather than becoming empty text', () {
      expect(reference.toMap().containsKey('note'), isFalse);
      expect(ProjectAttachment.fromMap(reference.toMap()).note, isNull);
    });

    test('an unrecognized kind is inferred from the target', () {
      final asLink = ProjectAttachment.fromMap({
        'id': 'x',
        'kind': 'something-newer',
        'target': 'https://example.com',
        'addedAt': DateTime(2025, 1, 1).toIso8601String(),
      });
      final asFile = ProjectAttachment.fromMap({
        'id': 'y',
        'target': '/Users/artist/ref.wav',
        'addedAt': DateTime(2025, 1, 1).toIso8601String(),
      });

      expect(asLink.kind, ProjectAttachmentKind.link);
      expect(asFile.kind, ProjectAttachmentKind.file);
    });

    test('a map missing keys reads as a usable attachment rather than throwing',
        () {
      final a = ProjectAttachment.fromMap(const {});

      expect(a.target, isEmpty);
      expect(a.label, isEmpty);
      expect(a.kind, ProjectAttachmentKind.file);
      expect(a.addedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('equality is by value, so an unchanged sync is recognisable', () {
      expect(reference.copyWith(), reference);
      expect(reference.copyWith(label: 'Other'), isNot(reference));
    });

    test('copyWith can clear a note that was set', () {
      expect(stems.copyWith(clearNote: true).note, isNull);
      expect(stems.copyWith(label: 'Renamed').note, 'expires in 7 days');
    });
  });

  group('MusicProject.attachments', () {
    test('defaults to empty', () {
      expect(TestFactories.makeProject().attachments, isEmpty);
    });

    test('copyWith carries attachments through', () {
      final p = TestFactories.makeProject()
          .copyWith(attachments: [reference, stems]);

      expect(p.attachments, [reference, stems]);
      expect(p.copyWith(notes: 'unrelated').attachments, [reference, stems],
          reason: 'an unrelated edit must not drop them');
    });

    test('attachments count as user metadata for stacking (#94)', () {
      // Otherwise stacking would silently promote another version's (empty)
      // details over the one holding the contract and the stem link.
      expect(TestFactories.makeProject().hasUserMetadata, isFalse);
      expect(
        TestFactories.makeProject(attachments: [reference]).hasUserMetadata,
        isTrue,
      );
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

    test('attachments survive a Hive round-trip', () async {
      final original = TestFactories.makeProject(
        id: 'attachments-round-trip',
        attachments: [reference, stems],
      );

      final box =
          await Hive.openBox<MusicProject>('attachment_round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.attachments, [reference, stems]);
      expect(restored.attachments[1].note, 'expires in 7 days');
    });

    test('a record written before attachments existed reads as an empty list',
        () async {
      // The real backwards-compatibility case: every project already in a
      // user's box was written without index 38 at all.
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

      expect(restored.attachments, isEmpty);
      expect(restored.id, 'legacy-id');
    });
  });

  group('serialization', () {
    test('Drive sync round-trip preserves attachments', () {
      final service = GoogleDriveSyncService();
      final original =
          TestFactories.makeProject(attachments: [reference, stems]);

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.attachments, [reference, stems]);
    });

    test('a Drive record from before attachments existed restores as empty',
        () {
      final service = GoogleDriveSyncService();
      final data = service.serializeProjectForTest(
        TestFactories.makeProject(attachments: [reference]),
      )..remove('attachments');

      expect(service.deserializeProjectForTest(data).attachments, isEmpty);
    });

    test('local backup round-trip preserves attachments', () {
      // Flatpak's only backup path — a field skipped here can never be backed
      // up at all by those users.
      final original =
          TestFactories.makeProject(attachments: [reference, stems]);

      final restored = BackupService.projectFromJson(
        BackupService.projectToJson(original),
      );

      expect(restored.attachments, [reference, stems]);
    });

    test('a backup file from before attachments existed restores as empty', () {
      final json = BackupService.projectToJson(
        TestFactories.makeProject(attachments: [reference]),
      )..remove('attachments');

      expect(BackupService.projectFromJson(json).attachments, isEmpty);
    });
  });
}

/// A [BinaryReader] that replays one Hive record's field map — enough to drive
/// `MusicProjectAdapter.read`, which only ever calls [readByte] and [read].
///
/// Lets a record written by an older version of the adapter (no index 38) be
/// fed to the current one, which is the case no round-trip through a live box
/// can reproduce: writing always uses today's field list.
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
