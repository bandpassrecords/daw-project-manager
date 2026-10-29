import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/zip_export_service.dart';

/// The release and profile pages' "download as zip": every file once, under
/// a name of its own, streamed to disk rather than held in memory.
void main() {
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('zip_export_'));
  tearDown(() async => tmp.delete(recursive: true));

  Future<String> file(String name, String content) async {
    final f = File(p.join(tmp.path, 'src', name));
    await f.create(recursive: true);
    await f.writeAsString(content);
    return f.path;
  }

  Map<String, String> readZip(String zipPath) {
    final archive = ZipDecoder().decodeBytes(File(zipPath).readAsBytesSync());
    return {
      for (final f in archive.files)
        if (f.isFile) f.name: utf8.decode(f.content as List<int>),
    };
  }

  group('profileZipEntries', () {
    test('puts each file in once, and the biography as its text', () async {
      // "Download all" added every file twice: one loop for the files, and a
      // second, meant for the biography, that added the files again.
      final art = await file('front.png', 'png');
      final kit = await file('press.pdf', 'pdf');
      final zip = p.join(tmp.path, 'out', 'profile.zip');

      final count = await writeZipExport(
        zip,
        profileZipEntries([
          const MapEntry(kBiographyMarker, kBiographyMarker),
          MapEntry('artwork_1.png', art),
          MapEntry('press.pdf', kit),
        ], bio: 'Producer from Porto Alegre'),
      );

      final archive = ZipDecoder().decodeBytes(File(zip).readAsBytesSync());
      expect(archive.files.map((f) => f.name).toList(), ['biography.txt', 'artwork_1.png', 'press.pdf']);
      expect(count, 3);
      expect(readZip(zip), {
        'biography.txt': 'Producer from Porto Alegre',
        'artwork_1.png': 'png',
        'press.pdf': 'pdf',
      });
    });
  });

  test('two files of one name both arrive', () async {
    final a = await file('a/Master.wav', 'first');
    final b = await file('b/Master.wav', 'second');
    final zip = p.join(tmp.path, 'release.zip');

    await writeZipExport(zip, [
      ZipExportEntry.file('Master.wav', a),
      ZipExportEntry.file('Master.wav', b),
    ]);

    expect(readZip(zip), {'Master.wav': 'first', 'Master (2).wav': 'second'});
  });

  test('a file that is gone is left out, the rest still go in', () async {
    final here = await file('here.wav', 'here');
    final zip = p.join(tmp.path, 'release.zip');

    final count = await writeZipExport(zip, [
      ZipExportEntry.file('gone.wav', p.join(tmp.path, 'src', 'gone.wav')),
      ZipExportEntry.file('here.wav', here),
    ]);

    expect(count, 1);
    expect(readZip(zip), {'here.wav': 'here'});
  });

  test('replaces an earlier zip, and leaves no partial file', () async {
    final zip = p.join(tmp.path, 'release.zip');
    await File(zip).writeAsString('an older export');

    await writeZipExport(zip, [ZipExportEntry.file('x.wav', await file('x.wav', 'x'))]);

    expect(readZip(zip), {'x.wav': 'x'});
    expect(File('$zip.part').existsSync(), isFalse);
  });

  test('a failure leaves the earlier zip as it was', () async {
    final zip = p.join(tmp.path, 'release.zip');
    await File(zip).writeAsString('an older export');
    // A folder where the partial zip must go: writing it fails.
    await Directory('$zip.part').create();

    await expectLater(
      writeZipExport(zip, [ZipExportEntry.file('ok.wav', await file('ok.wav', 'ok'))]),
      throwsA(anything),
    );

    expect(await File(zip).readAsString(), 'an older export');
  });

  test('runs on an isolate of its own, as the pages call it', () async {
    final zip = p.join(tmp.path, 'release.zip');
    final entries = [ZipExportEntry.file('x.wav', await file('x.wav', 'x'))];

    final count = await Isolate.run(() => writeZipExport(zip, entries));

    expect(count, 1);
    expect(readZip(zip), {'x.wav': 'x'});
  });

  group('uniqueZipNames', () {
    test('numbers repeats, ignoring case, and keeps the extension', () {
      expect(
        uniqueZipNames(['a.wav', 'A.wav', 'a.wav', 'b.wav', 'notes']),
        ['a.wav', 'A (2).wav', 'a (3).wav', 'b.wav', 'notes'],
      );
    });
  });
}
