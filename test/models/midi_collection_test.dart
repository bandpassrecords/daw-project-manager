import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_collection.dart';
import 'package:daw_project_manager/repository/midi_collection_store.dart';

import '../helpers/hive_test_helper.dart';

MidiClip _clip(String name, int pitch) => MidiClip(
      name: name,
      trackName: 'Bass',
      ppq: 480,
      lengthTicks: 1920,
      notes: [MidiNote(startTick: 0, lengthTicks: 240, pitch: pitch, velocity: 100)],
    );

MidiCollectionItem _item(String id, MidiClip clip) => MidiCollectionItem(
      id: id,
      clip: clip,
      addedAt: DateTime.utc(2026, 10, 1),
      sourceProjectId: 'p1',
      sourceProjectName: 'Song',
      bpm: 145,
      voice: 'bass',
    );

void main() {
  group('MidiCollection JSON', () {
    test('round-trips through real JSON text, clips and all', () {
      final c = MidiCollection(
        id: 'c1',
        name: 'Basslines',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 2, 1),
        items: [_item('i1', _clip('Line', 36))],
      );
      final back = MidiCollection.tryParse(jsonDecode(jsonEncode(c.toJson())))!;
      expect(back.name, 'Basslines');
      expect(back.updatedAt, c.updatedAt);
      expect(back.deleted, isFalse);
      final item = back.items.single;
      expect(item.clip.contentKey, c.items.single.clip.contentKey);
      expect(item.sourceProjectName, 'Song');
      expect(item.bpm, 145);
      expect(item.voice, 'bass');
    });

    test('a tombstone round-trips as deleted', () {
      final c = MidiCollection(
        id: 'c1',
        name: 'x',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        deleted: true,
      );
      expect(MidiCollection.tryParse(c.toJson())!.deleted, isTrue);
    });

    test('unreadable items are skipped, unreadable collections dropped', () {
      final json = MidiCollection(
        id: 'c1',
        name: 'x',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        items: [_item('i1', _clip('a', 40))],
      ).toJson();
      (json['items'] as List).add({'id': 'broken'});
      expect(MidiCollection.tryParse(json)!.items, hasLength(1));
      expect(midiCollectionsFromJson([json, 'nope', {'id': 1}]), hasLength(1));
      expect(midiCollectionsFromJson(null), isEmpty);
    });

    test('containsClip compares notes, not names', () {
      final c = MidiCollection(
        id: 'c1',
        name: 'x',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        items: [_item('i1', _clip('a', 40))],
      );
      expect(c.containsClip(_clip('renamed', 40)), isTrue);
      expect(c.containsClip(_clip('a', 41)), isFalse);
    });
  });

  group('MidiCollectionStore', () {
    late Directory tempDir;
    late DateTime now;
    late MidiCollectionStore store;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      now = DateTime.utc(2026, 10, 1, 12);
      store = MidiCollectionStore('profile-a', clock: () => now);
    });

    tearDown(() => HiveTestHelper.tearDown(tempDir));

    test('creates, renames and lists by name', () async {
      final b = await store.create('  Basslines ');
      await store.create('ambient pads');
      now = now.add(const Duration(minutes: 1));
      await store.rename(b.id, 'Acid basslines');

      final all = await store.all();
      expect(all.map((c) => c.name), ['Acid basslines', 'ambient pads']);
      expect(all.first.updatedAt, now, reason: 'a rename is a change that syncs');
    });

    test('adds copies, skipping clips it already has', () async {
      final c = await store.create('Riffs');
      expect(await store.addItems(c.id, [_item('i1', _clip('a', 40))]), 1);
      expect(
        await store.addItems(c.id, [
          _item('i2', _clip('a copy', 40)), // same notes
          _item('i3', _clip('b', 43)),
        ]),
        1,
      );
      expect((await store.get(c.id))!.items.map((i) => i.id), ['i1', 'i3']);
    });

    test('removes an item and remembers an item\'s instrument', () async {
      final c = await store.create('Riffs');
      await store.addItems(c.id, [_item('i1', _clip('a', 40)), _item('i2', _clip('b', 43))]);
      await store.removeItem(c.id, 'i1');
      await store.setItemVoice(c.id, 'i2', 'pluck');
      final items = (await store.get(c.id))!.items;
      expect(items.single.id, 'i2');
      expect(items.single.voice, 'pluck');

      await store.setItemVoice(c.id, 'i2', null);
      expect((await store.get(c.id))!.items.single.voice, isNull);
    });

    test('deleting leaves a tombstone: gone from view, still there to sync', () async {
      final c = await store.create('Riffs');
      await store.addItems(c.id, [_item('i1', _clip('a', 40))]);
      now = now.add(const Duration(minutes: 1));
      await store.delete(c.id);

      expect(await store.all(), isEmpty);
      expect(await store.get(c.id), isNull);
      final tombstone = (await store.all(includeDeleted: true)).single;
      expect(tombstone.deleted, isTrue);
      expect(tombstone.items, isEmpty, reason: 'no clip data kept for a deleted collection');
      expect(tombstone.updatedAt, now);
    });

    group('mergeIncoming', () {
      MidiCollection remote(String id, String name, DateTime at, {bool deleted = false}) =>
          MidiCollection(
            id: id,
            name: name,
            createdAt: DateTime.utc(2026),
            updatedAt: at,
            deleted: deleted,
          );

      test('adds new, takes newer, ignores older, never deletes', () async {
        final mine = await store.create('Mine'); // updated at `now`
        final local = await store.create('Local only');

        final written = await store.mergeIncoming([
          remote(mine.id, 'Older rename', now.subtract(const Duration(days: 1))),
          remote('new', 'From the laptop', now),
        ]);

        expect(written, 1);
        final names = (await store.all()).map((c) => c.name).toList();
        expect(names, containsAll(['Mine', 'Local only', 'From the laptop']));
        expect(await store.get(local.id), isNotNull);
      });

      test('a newer tombstone deletes here too', () async {
        final c = await store.create('Riffs');
        await store.mergeIncoming([
          remote(c.id, 'Riffs', now.add(const Duration(minutes: 5)), deleted: true),
        ]);
        expect(await store.get(c.id), isNull);
      });

      test('an older copy cannot bring a deleted collection back', () async {
        final c = await store.create('Riffs');
        now = now.add(const Duration(minutes: 5));
        await store.delete(c.id);

        await store.mergeIncoming([
          remote(c.id, 'Riffs', now.subtract(const Duration(minutes: 1))),
        ]);
        expect(await store.get(c.id), isNull);
      });
    });
  });
}
