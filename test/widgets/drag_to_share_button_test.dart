import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/ui/widgets/drag_to_share_button.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('drag_share_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('resolveDragSharePath', () {
    test(
      'passes an already-compatible file through untouched, no callback',
      () async {
        final events = <bool>[];

        final path = await resolveDragSharePath(
          '/x/song.mp3',
          cache: {},
          onConverting: events.add,
          getTempDir: () async => tempDir,
          convert: (_, _) async => fail('must not convert .mp3'),
        );

        expect(path, '/x/song.mp3');
        expect(events, isEmpty);
      },
    );

    test(
      'cache miss converts, fires true then false, populates the cache',
      () async {
        final events = <bool>[];
        final cache = <String, String>{};
        final converted = File('${tempDir.path}/song.mp3')
          ..writeAsStringSync('x');

        final path = await resolveDragSharePath(
          '/x/song.wav',
          cache: cache,
          onConverting: events.add,
          getTempDir: () async => tempDir,
          convert: (_, _) async => converted,
        );

        expect(path, converted.path);
        expect(events, [true, false]);
        expect(cache['/x/song.wav'], converted.path);
      },
    );

    test('cache hit skips conversion and never fires the callback', () async {
      final events = <bool>[];
      final cachedFile = File('${tempDir.path}/cached.mp3')
        ..writeAsStringSync('x');
      final cache = {'/x/song.wav': cachedFile.path};

      final path = await resolveDragSharePath(
        '/x/song.wav',
        cache: cache,
        onConverting: events.add,
        getTempDir: () async => tempDir,
        convert: (_, _) async => fail('must not convert on cache hit'),
      );

      expect(path, cachedFile.path);
      expect(events, isEmpty);
    });

    test('a stale cache entry (file deleted) reconverts', () async {
      final events = <bool>[];
      final cache = {'/x/song.wav': '${tempDir.path}/gone.mp3'};
      final reconverted = File('${tempDir.path}/fresh.mp3')
        ..writeAsStringSync('x');

      final path = await resolveDragSharePath(
        '/x/song.wav',
        cache: cache,
        onConverting: events.add,
        getTempDir: () async => tempDir,
        convert: (_, _) async => reconverted,
      );

      expect(path, reconverted.path);
      expect(events, [true, false]);
      expect(cache['/x/song.wav'], reconverted.path);
    });

    test('returns null and still fires false when conversion fails', () async {
      final events = <bool>[];
      final cache = <String, String>{};

      final path = await resolveDragSharePath(
        '/x/song.wav',
        cache: cache,
        onConverting: events.add,
        getTempDir: () async => tempDir,
        convert: (_, _) async => null,
      );

      expect(path, isNull);
      expect(events, [true, false]);
      expect(cache, isEmpty);
    });

    test("with the song's name, drags a copy under that name", () async {
      final source = File('${tempDir.path}/2fa08b9a_preview.wav')
        ..writeAsStringSync('wav');
      final converted = File('${tempDir.path}/2fa08b9a_preview.mp3')
        ..writeAsStringSync('mp3');
      final cache = <String, String>{};

      final path = await resolveDragSharePath(
        source.path,
        cache: cache,
        getTempDir: () async => tempDir,
        convert: (_, _) async => converted,
        shareName: 'Leave the lights on.wav',
      );

      expect(p.basename(path!), 'Leave the lights on.mp3');
      expect(File(path).readAsStringSync(), 'mp3');
      // The next drag takes the named copy straight from the cache.
      final again = await resolveDragSharePath(
        source.path,
        cache: cache,
        getTempDir: () async => tempDir,
        convert: (_, _) async => fail('must not convert twice'),
        shareName: 'Leave the lights on.wav',
      );
      expect(again, path);
    });

    test(
      "with the song's name, a compatible file is copied under it too",
      () async {
        final source = File('${tempDir.path}/2fa08b9a_preview.mp3')
          ..writeAsStringSync('mp3');
        final path = await resolveDragSharePath(
          source.path,
          cache: {},
          getTempDir: () async => tempDir,
          shareName: 'Teardrop.mp3',
        );
        expect(p.basename(path!), 'Teardrop.mp3');
        expect(source.existsSync(), isTrue);
      },
    );
  });
}
