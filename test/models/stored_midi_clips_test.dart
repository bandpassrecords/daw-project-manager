import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/stored_midi_clips.dart';
import 'package:daw_project_manager/repository/midi_clip_store.dart';

import '../helpers/hive_test_helper.dart';

const _notes = [
  MidiNote(startTick: 0, lengthTicks: 240, pitch: 36, velocity: 100),
  MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: 90, channel: 9),
  MidiNote(startTick: 200000, lengthTicks: 1, pitch: 127, velocity: 1),
];

StoredMidiClips _stored(DateTime at, {String name = 'Riff'}) => StoredMidiClips(
      extractedAt: at,
      sourceModifiedAt: DateTime.utc(2026, 9, 1),
      clips: [
        MidiClip(
          name: name,
          trackName: 'Bass',
          ppq: 480,
          lengthTicks: 3840,
          notes: _notes,
          occurrences: 3,
          otherNames: const ['Synth – Riff copy'],
        ),
      ],
    );

void main() {
  group('note packing', () {
    test('round-trips every field, large positions included', () {
      expect(unpackMidiNotes(packMidiNotes(_notes)), _notes);
    });

    test('is compact: a handful of bytes per note', () {
      final notes = [
        for (var i = 0; i < 1000; i++)
          MidiNote(startTick: i * 120, lengthTicks: 110, pitch: 60, velocity: 100),
      ];
      expect(packMidiNotes(notes).length, lessThan(1000 * 8));
    });

    test('a truncated or foreign blob yields what it can, never throws', () {
      final packed = packMidiNotes(_notes);
      expect(unpackMidiNotes(Uint8List.sublistView(packed, 0, packed.length - 2)),
          _notes.take(2).toList());
      expect(unpackMidiNotes(Uint8List.fromList([99, 1, 2, 3])), isEmpty);
      expect(unpackMidiNotes(Uint8List(0)), isEmpty);
    });
  });

  group('StoredMidiClips', () {
    final value = _stored(DateTime.utc(2026, 10, 1, 12));

    void expectSame(StoredMidiClips? got) {
      expect(got, isNotNull);
      expect(got!.extractedAt, value.extractedAt);
      expect(got.sourceModifiedAt, value.sourceModifiedAt);
      final c = got.clips.single;
      expect(c.label, 'Bass – Riff');
      expect(c.ppq, 480);
      expect(c.lengthTicks, 3840);
      expect(c.occurrences, 3);
      expect(c.otherNames, ['Synth – Riff copy']);
      expect(c.notes, _notes);
    }

    test('the Hive form round-trips', () {
      expectSame(StoredMidiClips.tryParse(value.toMap()));
    });

    test('the JSON form round-trips through real JSON text', () {
      expectSame(StoredMidiClips.tryParse(jsonDecode(jsonEncode(value.toJson()))));
    });

    test('a bad clip is skipped, the rest kept; garbage reads as absent', () {
      final json = value.toJson();
      (json['clips'] as List).add({'name': 'broken', 'ppq': 'x'});
      expect(StoredMidiClips.tryParse(json)!.clips, hasLength(1));
      expect(StoredMidiClips.tryParse('nope'), isNull);
      expect(StoredMidiClips.tryParse({'clips': []}), isNull,
          reason: 'no extraction time, no record');
    });

    test('is stale only when the file changed after the read', () {
      expect(value.isStaleFor(DateTime.utc(2026, 9, 2)), isTrue);
      expect(value.isStaleFor(DateTime.utc(2026, 9, 1)), isFalse);
      expect(value.isStaleFor(null), isFalse);
    });

    test('sub-second and FAT-rounding differences are not a change', () {
      // Regression: on Linux the scan's stat() time is whole seconds and the
      // page's lastModified() keeps milliseconds, so every freshly read
      // project showed "the project file has changed".
      final at = DateTime.utc(2026, 9, 1);
      expect(value.isStaleFor(at.add(const Duration(milliseconds: 50))), isFalse);
      expect(value.isStaleFor(at.add(const Duration(milliseconds: 1999))), isFalse);
      expect(value.isStaleFor(at.add(const Duration(seconds: 2))), isTrue);
    });
  });

  group('MidiClipStore', () {
    late Directory tempDir;
    late MidiClipStore store;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      store = MidiClipStore('profile-a');
    });

    tearDown(() => HiveTestHelper.tearDown(tempDir));

    test('stores, reads and deletes per project', () async {
      await store.put('p1', _stored(DateTime.utc(2026, 1, 1)));
      await store.put('p2', _stored(DateTime.utc(2026, 1, 1)));
      expect((await store.get('p1'))!.clips.single.notes, _notes);

      await store.deleteAll(['p1']);
      expect(await store.get('p1'), isNull);
      expect(await store.get('p2'), isNotNull);
      expect((await store.getAll()).keys, ['p2']);
    });

    test('profiles do not see each other\'s clips', () async {
      await store.put('p1', _stored(DateTime.utc(2026, 1, 1)));
      expect(await MidiClipStore('profile-b').get('p1'), isNull);
    });

    test('getAll can be limited to some projects', () async {
      await store.put('p1', _stored(DateTime.utc(2026, 1, 1)));
      await store.put('p2', _stored(DateTime.utc(2026, 1, 1)));
      expect((await store.getAll(onlyProjects: {'p2'})).keys, ['p2']);
    });

    test('mergeNewer takes newer and new records, never older ones, never deletes',
        () async {
      await store.put('kept', _stored(DateTime.utc(2026, 5, 1), name: 'mine'));
      await store.put('updated', _stored(DateTime.utc(2026, 5, 1), name: 'old'));
      await store.put('local-only', _stored(DateTime.utc(2026, 5, 1)));

      final written = await store.mergeNewer({
        'kept': _stored(DateTime.utc(2026, 4, 1), name: 'older'),
        'updated': _stored(DateTime.utc(2026, 6, 1), name: 'new'),
        'arrived': _stored(DateTime.utc(2026, 6, 1)),
      });

      expect(written, 2);
      expect((await store.get('kept'))!.clips.single.name, 'mine');
      expect((await store.get('updated'))!.clips.single.name, 'new');
      expect(await store.get('arrived'), isNotNull);
      expect(await store.get('local-only'), isNotNull);
    });

    test('watch reports which project changed', () async {
      final events = <String>[];
      final sub = store.watch().listen(events.add);
      await Future<void>.delayed(Duration.zero);
      await store.put('p9', _stored(DateTime.utc(2026, 1, 1)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(events, contains('p9'));
    });
  });

  test('payload helpers round-trip and skip unreadable entries', () {
    final all = {'p1': _stored(DateTime.utc(2026, 1, 1))};
    final json = jsonDecode(jsonEncode(storedMidiClipsToJson(all)));
    (json as Map)['bad'] = 'x';
    final back = storedMidiClipsFromJson(json);
    expect(back.keys, ['p1']);
    expect(back['p1']!.clips.single.notes, _notes);
    expect(storedMidiClipsFromJson(null), isEmpty);
  });
}
