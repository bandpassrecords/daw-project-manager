import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_collection.dart';
import 'package:daw_project_manager/models/midi_collection_drag.dart';

MidiClip _clip(int pitch) => MidiClip(
  name: 'c$pitch',
  ppq: 480,
  lengthTicks: 1920,
  notes: [
    MidiNote(startTick: 0, lengthTicks: 240, pitch: pitch, velocity: 100),
  ],
);

MidiCollectionItem _item(String id, int pitch, {String? folder}) =>
    MidiCollectionItem(
      id: id,
      clip: _clip(pitch),
      addedAt: DateTime.utc(2026),
      folderId: folder,
    );

final _c = MidiCollection(
  id: 'c',
  name: 'Pack',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  folders: const [
    MidiCollectionFolder(id: 'a', name: 'A'),
    MidiCollectionFolder(id: 'b', name: 'B', parentId: 'a'),
    MidiCollectionFolder(id: 'z', name: 'Z'),
  ],
  items: [
    _item('i1', 40),
    _item('i2', 41, folder: 'a'),
  ],
);

void main() {
  const clipDrag = MidiItemDragData(
    collectionId: 'c',
    itemIds: ['i1'],
    label: 'i1',
  );
  MidiFolderDragData folder(String id) =>
      MidiFolderDragData(collectionId: 'c', folderId: id, label: id);

  test(
    'a clip goes into any folder, before another clip, not before itself',
    () {
      expect(
        canDropMidi(clipDrag, const MidiDropTarget('c', folderId: 'b'), _c),
        isTrue,
      );
      expect(
        canDropMidi(
          clipDrag,
          const MidiDropTarget('c', beforeItemId: 'i2'),
          _c,
        ),
        isTrue,
      );
      expect(
        canDropMidi(
          clipDrag,
          const MidiDropTarget('c', beforeItemId: 'i1'),
          _c,
        ),
        isFalse,
      );
      expect(
        canDropMidi(clipDrag, const MidiDropTarget('c', folderId: 'gone'), _c),
        isFalse,
      );
    },
  );

  test(
    'into another collection: into it or a folder, not between its clips',
    () {
      const other = MidiItemDragData(
        collectionId: 'x',
        itemIds: ['k'],
        label: 'k',
      );
      expect(canDropMidi(other, const MidiDropTarget('c'), _c), isTrue);
      expect(
        canDropMidi(other, const MidiDropTarget('c', beforeItemId: 'i1'), _c),
        isFalse,
      );
    },
  );

  test('a folder never goes into itself, inside itself or where it is', () {
    expect(
      canDropMidi(folder('a'), const MidiDropTarget('c', folderId: 'z'), _c),
      isTrue,
    );
    expect(
      canDropMidi(folder('a'), const MidiDropTarget('c', folderId: 'a'), _c),
      isFalse,
    );
    expect(
      canDropMidi(folder('a'), const MidiDropTarget('c', folderId: 'b'), _c),
      isFalse,
    );
    expect(
      canDropMidi(folder('a'), const MidiDropTarget('c'), _c),
      isFalse,
      reason: 'already at the top level',
    );
    expect(canDropMidi(folder('b'), const MidiDropTarget('c'), _c), isTrue);
    expect(
      canDropMidi(
        folder('b'),
        const MidiDropTarget('c', beforeItemId: 'i1'),
        _c,
      ),
      isFalse,
      reason: 'folders are not placed between clips',
    );
    expect(
      canDropMidi(
        const MidiFolderDragData(collectionId: 'x', folderId: 'a', label: 'a'),
        const MidiDropTarget('c'),
        _c,
      ),
      isFalse,
      reason: 'folders stay in their collection',
    );
  });

  test('a library clip goes in unless the collection already plays it', () {
    expect(
      canDropMidi(
        MidiLibraryClipDragData(item: _item('new', 60), label: 'n'),
        const MidiDropTarget('c'),
        _c,
      ),
      isTrue,
    );
    expect(
      canDropMidi(
        MidiLibraryClipDragData(item: _item('new', 40), label: 'n'),
        const MidiDropTarget('c'),
        _c,
      ),
      isFalse,
    );
  });

  test('nothing lands in a collection that is gone or deleted', () {
    expect(canDropMidi(clipDrag, const MidiDropTarget('c'), null), isFalse);
    expect(
      canDropMidi(
        clipDrag,
        const MidiDropTarget('c'),
        _c.copyWith(deleted: true, updatedAt: DateTime.utc(2026)),
      ),
      isFalse,
    );
  });
}
