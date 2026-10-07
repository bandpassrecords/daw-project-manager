import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_clip_naming.dart';
import 'package:daw_project_manager/models/midi_collection.dart';
import 'package:daw_project_manager/repository/midi_collection_store.dart';

import '../helpers/hive_test_helper.dart';

MidiClip _clip(String name, int pitch) => MidiClip(
  name: name,
  trackName: 'Bass',
  ppq: 480,
  lengthTicks: 1920,
  notes: [
    MidiNote(startTick: 0, lengthTicks: 240, pitch: pitch, velocity: 100),
  ],
);

MidiCollectionItem _item(String id, MidiClip clip) => MidiCollectionItem(
  id: id,
  clip: clip,
  addedAt: DateTime.utc(2026, 10, 1),
  sourceProjectId: 'p1',
  sourceProjectName: 'Song',
  bpm: 145,
  musicalKey: 'F# minor',
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
      expect(item.musicalKey, 'F# minor');
      expect(item.voice, 'bass');
      expect(item.copyWith(voice: 'pad').musicalKey, 'F# minor');
    });

    test('an imported item keeps the file it came from', () {
      final item = MidiCollectionItem(
        id: 'i9',
        clip: _clip('Hook', 60),
        addedAt: DateTime.utc(2026, 10, 2),
        sourceFileName: 'Hook.mid',
      );
      final back = MidiCollectionItem.tryParse(
        jsonDecode(jsonEncode(item.toJson())),
      )!;
      expect(back.sourceFileName, 'Hook.mid');
      expect(back.sourceProjectId, isNull);
      expect(back.copyWith(voice: 'pad').sourceFileName, 'Hook.mid');
      expect(
        _item('i1', _clip('Line', 36)).toJson().containsKey('sourceFile'),
        isFalse,
      );
    });

    test('an item from before keys were kept reads with no key', () {
      final json = _item('i1', _clip('Line', 36)).toJson()..remove('key');
      expect(MidiCollectionItem.tryParse(json)!.musicalKey, isNull);
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
      expect(
        midiCollectionsFromJson([
          json,
          'nope',
          {'id': 1},
        ]),
        hasLength(1),
      );
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

  group('folders, names and roles', () {
    MidiCollection pack({
      List<MidiCollectionFolder> folders = const [],
      List<MidiCollectionItem> items = const [],
    }) => MidiCollection(
      id: 'c1',
      name: 'Pack',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      folders: folders,
      items: items,
    );

    test(
      'round-trip through JSON with the folders, naming, names and roles',
      () {
        final item = MidiCollectionItem(
          id: 'i1',
          clip: _clip('Line', 36),
          addedAt: DateTime.utc(2026, 10, 6),
          title: 'Acid',
          role: 'bass',
          folderId: 'f2',
        );
        final c =
            pack(
              folders: const [
                MidiCollectionFolder(id: 'f1', name: 'Bass'),
                MidiCollectionFolder(id: 'f2', name: 'Acid', parentId: 'f1'),
              ],
              items: [item],
            ).copyWith(
              naming: const MidiNamingTemplate(numbered: false, separator: '_'),
              updatedAt: DateTime.utc(2026),
            );
        final back = MidiCollection.tryParse(
          jsonDecode(jsonEncode(c.toJson())),
        )!;
        expect(back.folders.map((f) => (f.id, f.name, f.parentId)), [
          ('f1', 'Bass', null),
          ('f2', 'Acid', 'f1'),
        ]);
        expect(back.naming, c.naming);
        final i = back.items.single;
        expect((i.title, i.role, i.folderId), ('Acid', 'bass', 'f2'));
        expect(i.displayName, 'Acid');
        expect(i.chosenRole, MidiClipRole.bass);
      },
    );

    test(
      'a collection from before folders reads flat, with the standard naming',
      () {
        final json = pack(items: [_item('i1', _clip('Line', 36))]).toJson();
        expect(json.containsKey('folders'), isFalse);
        expect(
          json.containsKey('naming'),
          isFalse,
          reason: 'the default goes unsaid',
        );
        final back = MidiCollection.tryParse(json)!;
        expect(back.folders, isEmpty);
        expect(back.naming, MidiNamingTemplate.standard);
        final i = back.items.single;
        expect(i.folderId, isNull);
        expect(i.displayName, 'Bass – Line');
        expect(i.chosenRole, isNull);
        expect(
          i.copyWith(role: 'mystery').chosenRole,
          isNull,
          reason: 'a role this build lacks is suggested again',
        );
      },
    );

    test('folder paths, contents and the tree', () {
      final c = pack(
        folders: const [
          MidiCollectionFolder(id: 'a', name: 'A'),
          MidiCollectionFolder(id: 'b', name: 'B', parentId: 'a'),
          MidiCollectionFolder(id: 'c', name: 'C', parentId: 'b'),
          MidiCollectionFolder(id: 'd', name: 'D'),
          MidiCollectionFolder(id: 'orphan', name: 'O', parentId: 'gone'),
        ],
        items: [
          MidiCollectionItem(
            id: 'x',
            clip: _clip('x', 40),
            addedAt: DateTime.utc(2026),
            folderId: 'b',
          ),
          MidiCollectionItem(
            id: 'y',
            clip: _clip('y', 41),
            addedAt: DateTime.utc(2026),
            folderId: 'gone',
          ),
        ],
      );
      expect(c.folderPath('c').map((f) => f.name), ['A', 'B', 'C']);
      expect(c.folderPath(null), isEmpty);
      expect(c.foldersIn(null).map((f) => f.id), ['a', 'd', 'orphan']);
      expect(c.itemsIn('b').map((i) => i.id), ['x']);
      expect(c.itemsIn(null).map((i) => i.id), [
        'y',
      ], reason: 'its folder is gone');
      expect(c.folderAndDescendants('a'), {'a', 'b', 'c'});
      expect(c.folderTree().map((e) => '${e.folder.id}${e.depth}'), [
        'a0',
        'b1',
        'c2',
        'd0',
        'orphan0',
      ]);
    });

    test(
      'a parent loop (two devices moving folders) neither hangs nor hides',
      () {
        final c = pack(
          folders: const [
            MidiCollectionFolder(id: 'a', name: 'A', parentId: 'b'),
            MidiCollectionFolder(id: 'b', name: 'B', parentId: 'a'),
          ],
        );
        expect(c.folderPath('a').map((f) => f.id), ['b', 'a']);
        expect(
          c.foldersIn(null).map((f) => f.id),
          ['a', 'b'],
          reason: 'shown at the top level rather than nowhere',
        );
      },
    );
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
      expect(
        all.first.updatedAt,
        now,
        reason: 'a rename is a change that syncs',
      );
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
      await store.addItems(c.id, [
        _item('i1', _clip('a', 40)),
        _item('i2', _clip('b', 43)),
      ]);
      await store.removeItem(c.id, 'i1');
      await store.setItemVoice(c.id, 'i2', 'pluck');
      final items = (await store.get(c.id))!.items;
      expect(items.single.id, 'i2');
      expect(items.single.voice, 'pluck');

      await store.setItemVoice(c.id, 'i2', null);
      expect((await store.get(c.id))!.items.single.voice, isNull);
    });

    test('putItem replaces the item with its id, or adds it', () async {
      final c = await store.create('Ideas');
      await store.putItem(c.id, _item('idea', _clip('Idea 1', 60)));
      now = now.add(const Duration(minutes: 1));
      await store.putItem(c.id, _item('idea', _clip('Idea 1', 64)));
      await store.putItem(c.id, _item('other', _clip('Idea 2', 67)));
      final saved = (await store.get(c.id))!;
      expect(
        saved.items.map((i) => i.id),
        ['idea', 'other'],
        reason: 'saving the same idea again replaces it, in its place',
      );
      expect(saved.items.first.clip.notes.single.pitch, 64);
      expect(saved.updatedAt, now, reason: 'a change that syncs');
    });

    test(
      'deleting leaves a tombstone: gone from view, still there to sync',
      () async {
        final c = await store.create('Riffs');
        await store.addItems(c.id, [_item('i1', _clip('a', 40))]);
        now = now.add(const Duration(minutes: 1));
        await store.delete(c.id);

        expect(await store.all(), isEmpty);
        expect(await store.get(c.id), isNull);
        final tombstone = (await store.all(includeDeleted: true)).single;
        expect(tombstone.deleted, isTrue);
        expect(
          tombstone.items,
          isEmpty,
          reason: 'no clip data kept for a deleted collection',
        );
        expect(tombstone.updatedAt, now);
      },
    );

    group('folders, names, roles and order', () {
      late String id;

      setUp(() async {
        id = (await store.create('Pack')).id;
        await store.addItems(id, [
          _item('i1', _clip('a', 40)),
          _item('i2', _clip('b', 41)),
          _item('i3', _clip('c', 42)),
          _item('i4', _clip('d', 43)),
        ]);
      });

      Future<MidiCollection> pack() async => (await store.get(id))!;

      test('folders nest, rename and move — never into themselves', () async {
        final bass = (await store.addFolder(id, ' Bass '))!;
        final acid = (await store.addFolder(id, 'Acid', parentId: bass))!;
        expect(await store.addFolder(id, '  '), isNull);
        await store.renameFolder(id, acid, 'Acid lines');
        var c = await pack();
        expect(c.folderPath(acid).map((f) => f.name), ['Bass', 'Acid lines']);

        await store.moveFolder(id, bass, acid);
        expect(
          (await pack()).folderById(bass)!.parentId,
          isNull,
          reason: 'into its own child: refused',
        );
        await store.moveFolder(id, acid, null);
        c = await pack();
        expect(c.folderById(acid)!.parentId, isNull);
      });

      test(
        'moving clips puts them at the end of the folder, in order',
        () async {
          final f = (await store.addFolder(id, 'Keep'))!;
          await store.moveItemsToFolder(id, ['i3'], f);
          now = now.add(const Duration(minutes: 1));
          await store.moveItemsToFolder(id, ['i4', 'i1'], f);
          final c = await pack();
          expect(c.itemsIn(f).map((i) => i.id), ['i3', 'i1', 'i4']);
          expect(c.itemsIn(null).map((i) => i.id), ['i2']);
          expect(c.updatedAt, now, reason: 'a move syncs');
        },
      );

      test('deleting a folder moves what it held up a level', () async {
        final outer = (await store.addFolder(id, 'Outer'))!;
        final inner = (await store.addFolder(id, 'Inner', parentId: outer))!;
        final deep = (await store.addFolder(id, 'Deep', parentId: inner))!;
        await store.moveItemsToFolder(id, ['i1'], inner);
        await store.deleteFolder(id, inner);
        final c = await pack();
        expect(c.folderById(inner), isNull);
        expect(c.folderById(deep)!.parentId, outer);
        expect(c.items.firstWhere((i) => i.id == 'i1').folderId, outer);
        expect(c.items, hasLength(4), reason: 'no clip is lost');
      });

      test(
        'reordering within a folder leaves the others where they were',
        () async {
          final f = (await store.addFolder(id, 'F'))!;
          await store.moveItemsToFolder(id, ['i2', 'i4'], f);
          // Top level: i1, i3. F: i2, i4.
          await store.reorderInFolder(id, null, 1, 0);
          var c = await pack();
          expect(c.itemsIn(null).map((i) => i.id), ['i3', 'i1']);
          expect(c.itemsIn(f).map((i) => i.id), ['i2', 'i4']);

          // ReorderableListView's "down one": to counts the moved row.
          await store.reorderInFolder(id, f, 0, 2);
          c = await pack();
          expect(c.itemsIn(f).map((i) => i.id), ['i4', 'i2']);
        },
      );

      test('a drop between clips puts them just before that clip', () async {
        final f = (await store.addFolder(id, 'F'))!;
        await store.moveItemsToFolder(id, ['i2', 'i3'], f);
        // Top: i1, i4. F: i2, i3. i4 goes into F before i3; i1 before i2.
        await store.moveItemsToFolder(id, ['i4'], f, beforeItemId: 'i3');
        await store.moveItemsToFolder(id, ['i1'], f, beforeItemId: 'i2');
        final c = await pack();
        expect(c.itemsIn(f).map((i) => i.id), ['i1', 'i2', 'i4', 'i3']);
        expect(c.itemsIn(null), isEmpty);
      });

      test(
        'clips move to another collection, unless it already plays them',
        () async {
          final other = await store.create('Other');
          await store.addItems(other.id, [
            _item('dup', _clip('same as i2', 41)),
          ]);
          final f = (await store.addFolder(other.id, 'In here'))!;
          now = now.add(const Duration(minutes: 1));
          final moved = await store.moveItemsToCollection(id, other.id, [
            'i1',
            'i2',
          ], f);
          expect(moved, 1);
          final from = await pack();
          final to = (await store.get(other.id))!;
          expect(
            from.items.map((i) => i.id),
            ['i2', 'i3', 'i4'],
            reason: 'i2 stays: the other collection has its notes already',
          );
          expect(to.itemsIn(f).map((i) => i.id), ['i1']);
          expect(from.updatedAt, now);
          expect(to.updatedAt, now);
        },
      );

      test('many clips renamed at once, and back', () async {
        await store.renameItem(id, 'i2', 'Kept');
        final before = await store.renameItems(id, {
          'i1': 'Bass - 140BPM',
          'i2': 'Bass - 140BPM 2',
          'i3': 'c', // its clip's own name, but now a title of its own
        });
        var c = await pack();
        expect(c.items.map((i) => i.title), [
          'Bass - 140BPM',
          'Bass - 140BPM 2',
          'c',
          null,
        ]);
        expect(before, {'i1': null, 'i2': 'Kept', 'i3': null});

        await store.renameItems(id, before);
        c = await pack();
        expect(c.items.map((i) => i.title), [null, 'Kept', null, null]);
      });

      test('names, roles and the naming template', () async {
        await store.renameItem(id, 'i1', '  Big riff ');
        await store.setItemRole(id, 'i1', MidiClipRole.lead);
        var item = (await pack()).items.first;
        expect(item.title, 'Big riff');
        expect(item.chosenRole, MidiClipRole.lead);

        await store.renameItem(id, 'i1', ' ');
        await store.setItemRole(id, 'i1', null);
        item = (await pack()).items.first;
        expect(item.title, isNull, reason: 'blank: back to its own name');
        expect(item.role, isNull, reason: 'back to suggesting');

        const naming = MidiNamingTemplate(numbered: false);
        now = now.add(const Duration(minutes: 1));
        await store.setNaming(id, naming);
        final c = await pack();
        expect(c.naming, naming);
        expect(c.updatedAt, now);
      });
    });

    group('mergeIncoming', () {
      MidiCollection remote(
        String id,
        String name,
        DateTime at, {
        bool deleted = false,
      }) => MidiCollection(
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
          remote(
            mine.id,
            'Older rename',
            now.subtract(const Duration(days: 1)),
          ),
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
          remote(
            c.id,
            'Riffs',
            now.add(const Duration(minutes: 5)),
            deleted: true,
          ),
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
