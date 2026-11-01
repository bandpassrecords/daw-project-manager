import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/template_export/reference_service.dart';

import '../../helpers/test_factories.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('dpm_ref_'));
  tearDown(() => dir.delete(recursive: true));

  final song = TestFactories.makeProject(
    id: 'song',
    filePath: '/x/Song.cpr',
    fileName: 'Song.cpr',
    fileSizeBytes: 100,
    lastModifiedAt: DateTime(2026, 1, 1),
  );

  test('tracks, with their instrument, survive a save and a load', () async {
    final file = File(p.join(dir.path, 'cache.json'));
    final cache = ReferenceCache(file)
      ..put(song, const [
        CubaseTrack(
          index: 0,
          name: 'Lead',
          type: CubaseTrackType.instrument,
          instrument: 'Serum',
          inserts: [CubaseInsert(slot: 0, plugin: 'OTT_x64', bypassed: true)],
        ),
      ]);
    await cache.save();

    final loaded = await ReferenceCache.load(file);
    final track = loaded.freshTracksOf(song)!.single;
    expect((track.name, track.instrument), ('Lead', 'Serum'));
    expect((track.inserts.single.plugin, track.inserts.single.bypassed),
        ('OTT_x64', true));
  });

  test('a file changed since it was read has no fresh tracks', () {
    final cache = ReferenceCache(File(p.join(dir.path, 'c.json')))
      ..put(song, const [
        CubaseTrack(index: 0, name: 'A', type: CubaseTrackType.audio),
      ]);
    expect(cache.freshTracksOf(song), isNotNull);
    final saved = song.copyWith(lastModifiedAt: DateTime(2026, 2, 1));
    expect(cache.freshTracksOf(saved), isNull);
    expect(cache.tracksOf(saved.id), isNotNull, reason: 'kept, just stale');
  });

  test('a cache from before instruments were kept is read again', () async {
    final file = File(p.join(dir.path, 'old.json'));
    await file.writeAsString(jsonEncode({
      'version': 2,
      'projects': {
        'song': {'s': 100, 'm': 0, 't': []},
      },
    }));
    expect((await ReferenceCache.load(file)).length, 0);
  });
}
