import 'dart:io';

import 'package:daw_project_manager/services/file_hash_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

import '../helpers/hive_test_helper.dart';

void main() {
  group('cachedHash', () {
    final entry = encodeHashEntry('abc', size: 10, modified: 1000);

    test('the hash of a file of the same size and time', () {
      expect(cachedHash(entry, size: 10, modified: 1000), 'abc');
    });

    test('nothing for a file changed since', () {
      expect(cachedHash(entry, size: 11, modified: 1000), isNull, reason: 'new contents, old time');
      expect(cachedHash(entry, size: 10, modified: 1001), isNull);
    });

    test('nothing for no entry or one that can\'t be read', () {
      expect(cachedHash(null, size: 10, modified: 1000), isNull);
      expect(cachedHash('not json', size: 10, modified: 1000), isNull);
      expect(cachedHash('{"size":10,"modified":1000}', size: 10, modified: 1000), isNull);
    });
  });

  group('FileHashCache', () {
    late Directory tempDir;
    late FileHashCache cache;
    late File file;
    var reads = 0;

    Future<String> hash() => cache.hashOf(file.path, () async {
          reads++;
          return 'hash ${file.readAsBytesSync().length}';
        });

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      cache = FileHashCache(await Hive.openBox<String>(FileHashCache.boxName));
      file = File(p.join(tempDir.path, 'song.wav'))..writeAsBytesSync([1, 2, 3]);
      reads = 0;
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('an unchanged file is read once, however often it is asked for', () async {
      // Every sync read every preview song whole.
      expect(await hash(), 'hash 3');
      expect(await hash(), 'hash 3');
      expect(reads, 1);
    });

    test('a file that changed is read again', () async {
      await hash();
      file.writeAsBytesSync([1, 2, 3, 4]);

      expect(await hash(), 'hash 4');
      expect(reads, 2);
    });

    test('a file touched without changing size is read again', () async {
      await hash();
      file.setLastModifiedSync(DateTime.now().add(const Duration(minutes: 1)));

      await hash();
      expect(reads, 2);
    });

    test('remembered across opens of the cache', () async {
      await hash();
      cache = FileHashCache(await Hive.openBox<String>(FileHashCache.boxName));

      await hash();
      expect(reads, 1);
    });

    test('a missing file is left to the reader, which says so', () async {
      file.deleteSync();

      await expectLater(
        cache.hashOf(file.path, () async => throw const FileSystemException('File not found')),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
