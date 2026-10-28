import 'package:daw_project_manager/services/preview_song_sync.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_factories.dart';

void main() {
  group('previewSongEntriesFrom', () {
    test('reads the three maps into one entry per project', () {
      final entries = previewSongEntriesFrom({
        'previewSongFiles': {'a': 'file-a', 'b': 'file-b'},
        'previewSongHashes': {'a': 'hash-a'},
        'previewSongFileNames': {'a': 'Song.wav'},
      });

      expect(entries.keys, {'a', 'b'});
      expect(entries['a']!.fileId, 'file-a');
      expect(entries['a']!.hash, 'hash-a');
      expect(entries['a']!.fileName, 'Song.wav');
      expect(entries['b']!.hash, isNull);
      expect(entries['b']!.fileName, isNull);
    });

    test('a backup without the maps, or a malformed one, lists nothing', () {
      expect(previewSongEntriesFrom({}), isEmpty);
      expect(previewSongEntriesFrom({'previewSongFiles': 'nope'}), isEmpty);
      expect(previewSongEntriesFrom({'previewSongFiles': {'a': 7}}), isEmpty);
    });
  });

  group('previewSongProjectId', () {
    test('reads the project from the upload\'s file name', () {
      expect(previewSongProjectId('013021c9-6661-4fc5-93a3-f36e042de644_preview.wav'),
          '013021c9-6661-4fc5-93a3-f36e042de644');
      expect(previewSongProjectId('a_preview.mp3'), 'a');
      expect(previewSongProjectId('a_preview'), 'a');
    });

    test('anything else in the folder belongs to no project', () {
      expect(previewSongProjectId('notes.txt'), isNull);
      expect(previewSongProjectId('_preview.wav'), isNull);
      expect(previewSongProjectId('a_preview.wav.part'), isNull);
      expect(previewSongProjectId('a_previewer.wav'), isNull);
    });
  });

  group('previewSongsByProject', () {
    test('a project with two files is its newest one', () {
      // Changing format uploads under a new extension and leaves the old.
      final byProject = previewSongsByProject([
        PreviewSongOnDrive(fileId: 'old', name: 'a_preview.wav', modifiedTime: DateTime(2026, 1)),
        PreviewSongOnDrive(fileId: 'new', name: 'a_preview.mp3', modifiedTime: DateTime(2026, 3)),
        PreviewSongOnDrive(fileId: 'b', name: 'b_preview.wav', modifiedTime: DateTime(2026, 2)),
        const PreviewSongOnDrive(fileId: 'x', name: 'readme.txt'),
      ]);

      expect(byProject.keys, {'a', 'b'});
      expect(byProject['a']!.fileId, 'new');
    });
  });

  group('previewSongWanted', () {
    test('a manual preview is always wanted', () {
      final project = TestFactories.makeProject(previewSongPath: '/gone.wav');
      expect(previewSongWanted(project, includeAutoDetected: false), isTrue);
    });

    test('an auto-detected one only when auto-detected songs are uploaded', () {
      final project = TestFactories.makeProject(previewSongAutoPath: '/mix.wav');
      expect(previewSongWanted(project, includeAutoDetected: true), isTrue);
      expect(previewSongWanted(project, includeAutoDetected: false), isFalse);
    });

    test('a project with no preview is not', () {
      expect(previewSongWanted(TestFactories.makeProject(), includeAutoDetected: true), isFalse);
    });
  });

  group('driveReferenceFileId', () {
    test('reads drive:// references only', () {
      expect(driveReferenceFileId('drive://abc'), 'abc');
      expect(driveReferenceFileId('drive://'), isNull);
      expect(driveReferenceFileId('/music/song.wav'), isNull);
      expect(driveReferenceFileId(null), isNull);
    });
  });

  group('carriedPreviewSongEntry', () {
    const previous = PreviewSongEntry(fileId: 'file-a', hash: 'hash-a', fileName: 'Song.wav');

    test('a song whose file is gone here keeps the previous backup\'s entry', () {
      // The bug: the backup was rebuilt from this device's files alone, and
      // a missing copy took the song from every device.
      final project = TestFactories.makeProject(
        id: 'a',
        previewSongPath: r'C:\Users\me\AppData\Local\daw_project_manager\preview_songs\a_preview.wav',
      );

      final kept = carriedPreviewSongEntry(project: project, includeAutoDetected: false, previous: previous);

      expect(kept, same(previous));
    });

    test('a removed preview lets go', () {
      final project = TestFactories.makeProject(id: 'a');

      expect(carriedPreviewSongEntry(project: project, includeAutoDetected: true, previous: previous), isNull);
    });

    test('an entry whose file is no longer on Drive is not kept', () {
      final project = TestFactories.makeProject(id: 'a', previewSongPath: '/gone.wav');

      expect(
        carriedPreviewSongEntry(
          project: project,
          includeAutoDetected: false,
          previous: previous,
          onDrive: const {},
        ),
        isNull,
      );
    });

    test('a drive:// reference names its own file', () {
      final project = TestFactories.makeProject(
        id: 'a',
        previewSongPath: 'drive://file-r',
        previewSongFileName: 'Mix.flac',
        uploadedPreviewSongHash: 'hash-r',
      );

      final kept = carriedPreviewSongEntry(project: project, includeAutoDetected: false)!;

      expect(kept.fileId, 'file-r');
      expect(kept.hash, 'hash-r');
      expect(kept.fileName, 'Mix.flac');
    });

    test('a file on Drive no backup lists any more is found by its name', () {
      // What earlier uploads left behind: the song is still on Drive.
      final project = TestFactories.makeProject(
        id: 'a',
        previewSongPath: r'H:\My Drive\Song\Mixdown\Song (final).wav',
      );

      final found = carriedPreviewSongEntry(
        project: project,
        includeAutoDetected: false,
        onDrive: {
          'a': const PreviewSongOnDrive(fileId: 'orphan', name: 'a_preview.wav'),
        },
      )!;

      expect(found.fileId, 'orphan');
      expect(found.hash, isNull, reason: 'which take it is is not known');
      expect(found.fileName, 'Song (final).wav');
    });

    test('a found file the app named itself keeps its extension', () {
      final project = TestFactories.makeProject(
        id: '013021c9-6661-4fc5-93a3-f36e042de644',
        previewSongPath: '/data/preview_songs/013021c9-6661-4fc5-93a3-f36e042de644_preview.wav',
      );

      final found = carriedPreviewSongEntry(
        project: project,
        includeAutoDetected: false,
        onDrive: {
          project.id: const PreviewSongOnDrive(
            fileId: 'orphan',
            name: '013021c9-6661-4fc5-93a3-f36e042de644_preview.wav',
          ),
        },
      )!;

      expect(found.fileName, '013021c9-6661-4fc5-93a3-f36e042de644_preview.wav');
    });

    test('nothing listed and nothing on Drive: nothing', () {
      final project = TestFactories.makeProject(id: 'a', previewSongPath: '/gone.wav');

      expect(carriedPreviewSongEntry(project: project, includeAutoDetected: false, onDrive: const {}), isNull);
    });
  });
}
