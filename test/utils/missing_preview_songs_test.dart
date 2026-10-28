import 'package:daw_project_manager/utils/missing_preview_songs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_factories.dart';

void main() {
  group('previewSongOf', () {
    test('the picked song wins over the auto-detected one', () {
      final song = previewSongOf(TestFactories.makeProject(
        previewSongPath: '/picked.wav',
        previewSongAutoPath: '/auto.wav',
      ))!;
      expect(song.path, '/picked.wav');
      expect(song.manual, isTrue);
    });

    test('the auto-detected one when nothing is picked', () {
      final song = previewSongOf(TestFactories.makeProject(previewSongAutoPath: '/auto.wav'))!;
      expect(song.path, '/auto.wav');
      expect(song.manual, isFalse);
    });

    test('none', () {
      expect(previewSongOf(TestFactories.makeProject()), isNull);
    });
  });

  group('isOtherComputersPath', () {
    test('a drive letter or a share is another computer\'s on a Mac or Linux', () {
      expect(isOtherComputersPath(r'C:\Users\me\song.wav', windows: false), isTrue);
      expect(isOtherComputersPath(r'\\nas\music\song.wav', windows: false), isTrue);
      expect(isOtherComputersPath('/Users/me/song.wav', windows: false), isFalse);
    });

    test('a /… path is another computer\'s on Windows', () {
      expect(isOtherComputersPath('/Users/me/song.wav', windows: true), isTrue);
      expect(isOtherComputersPath('/data/user/0/app/files/x.jpg', windows: true), isTrue);
      expect(isOtherComputersPath(r'H:\My Drive\song.wav', windows: true), isFalse);
      expect(isOtherComputersPath('//nas/music/song.wav', windows: true), isFalse);
    });
  });

  group('findMissingPreviewSongs', () {
    Future<List<MissingPreviewSong>> find(
      List projects, {
      Set<String> onDrive = const {},
      bool windows = true,
      Set<String> files = const {},
      Set<String> folders = const {},
    }) =>
        findMissingPreviewSongs(
          projects.cast(),
          onDrive: onDrive,
          windows: windows,
          fileExists: (p) async => files.contains(p),
          folderExists: (p) async => folders.contains(p),
        );

    test('a song that is there is not listed, nor a project without one', () async {
      final found = await find([
        TestFactories.makeProject(id: 'a', previewSongPath: r'C:\mix\a.wav'),
        TestFactories.makeProject(id: 'b'),
      ], files: {r'C:\mix\a.wav'});
      expect(found, isEmpty);
    });

    test('sorts each missing song by why', () async {
      final found = await find(
        [
          TestFactories.makeProject(id: 'gone', customDisplayName: 'Gone', previewSongPath: r'C:\mix\gone.wav'),
          TestFactories.makeProject(id: 'unplugged', customDisplayName: 'Unplugged', previewSongPath: r'H:\My Drive\x.wav'),
          TestFactories.makeProject(id: 'mac', customDisplayName: 'Mac', previewSongPath: '/Users/me/x.wav'),
          TestFactories.makeProject(id: 'drive', customDisplayName: 'Drive', previewSongPath: r'C:\app\preview_songs\drive_preview.wav'),
          TestFactories.makeProject(id: 'ref', customDisplayName: 'Ref', previewSongPath: 'drive://file-1'),
        ],
        onDrive: {'drive'},
        folders: {r'C:\mix'},
      );

      expect({for (final s in found) s.project.id: s.kind}, {
        'drive': MissingPreviewKind.onDrive,
        'ref': MissingPreviewKind.onDrive,
        'mac': MissingPreviewKind.otherComputer,
        'unplugged': MissingPreviewKind.folderMissing,
        'gone': MissingPreviewKind.fileMissing,
      });
      expect(found.map((s) => s.project.id), ['drive', 'ref', 'mac', 'unplugged', 'gone'],
          reason: 'grouped in the order the review lists them, then by name');
    });

    test('Drive having it wins over every other reason', () async {
      // Downloading is the one fix that doesn't need the old path at all.
      final found = await find(
        [TestFactories.makeProject(id: 'a', previewSongPath: '/Users/me/x.wav')],
        onDrive: {'a'},
      );
      expect(found.single.kind, MissingPreviewKind.onDrive);
    });

    test('an auto-detected song is listed as one', () async {
      final found = await find(
        [TestFactories.makeProject(id: 'a', previewSongAutoPath: r'C:\mix\a.wav')],
        folders: {r'C:\mix'},
      );
      expect(found.single.manual, isFalse);
      expect(found.single.fileName, 'a.wav');
    });

    test('only asks whether things exist', () async {
      // A cloud drive's placeholder is downloaded by a read, never by this.
      final asked = <String>[];
      await findMissingPreviewSongs(
        [TestFactories.makeProject(id: 'a', previewSongPath: r'C:\mix\a.wav')],
        onDrive: const {},
        windows: true,
        fileExists: (p) async {
          asked.add('file $p');
          return false;
        },
        folderExists: (p) async {
          asked.add('folder $p');
          return true;
        },
      );
      expect(asked, hasLength(2));
    });
  });

  group('what an action makes of the project', () {
    final missing = MissingPreviewSong(
      project: TestFactories.makeProject(id: 'a'),
      path: '/gone.wav',
      manual: true,
      kind: MissingPreviewKind.fileMissing,
    );

    test('removing clears only the slot the missing song was in', () {
      final project = TestFactories.makeProject(
        id: 'a',
        previewSongPath: '/gone.wav',
        previewSongFileName: 'gone.wav',
        previewSongAutoPath: '/mix.wav',
      );

      final removed = withoutMissingPreview(project, missing);

      expect(removed.previewSongPath, isNull);
      expect(removed.previewSongFileName, isNull);
      expect(removed.previewSongAutoPath, '/mix.wav', reason: 'it plays next');
    });

    test('removing a missing auto-detected song leaves the picked slot', () {
      final project = TestFactories.makeProject(id: 'a', previewSongAutoPath: '/gone.wav');
      final auto = MissingPreviewSong(
        project: project,
        path: '/gone.wav',
        manual: false,
        kind: MissingPreviewKind.fileMissing,
      );

      expect(withoutMissingPreview(project, auto).previewSongAutoPath, isNull);
    });

    test('a found mixdown goes in the auto-detected slot', () {
      final project = TestFactories.makeProject(id: 'a', previewSongPath: '/gone.wav');

      final found = withFoundPreview(project, '/mix/new.wav');

      expect(found.previewSongPath, isNull);
      expect(found.previewSongAutoPath, '/mix/new.wav');
    });

    test('a download goes in the picked slot, with Drive\'s name and hash', () {
      final project = TestFactories.makeProject(id: 'a', previewSongPath: '/gone.wav');

      final downloaded = withDownloadedPreview(
        project,
        '/app/preview_songs/a_preview.wav',
        fileName: 'Song.wav',
        hash: 'h',
      );

      expect(downloaded.previewSongPath, '/app/preview_songs/a_preview.wav');
      expect(downloaded.previewSongFileName, 'Song.wav');
      expect(downloaded.uploadedPreviewSongHash, 'h');
    });
  });
}
