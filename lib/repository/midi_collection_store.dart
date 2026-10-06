import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/midi_clip_naming.dart';
import '../models/midi_collection.dart';

/// One profile's MIDI collections, in their own Hive box
/// (`<profileId>_midi_collections`), stored as JSON maps — the clips inside
/// are copies (see [MidiCollectionItem]).
///
/// Opened on first use, like `MidiClipStore`, so Drive sync and backup can
/// reach it by profile id.
class MidiCollectionStore {
  MidiCollectionStore(this.profileId, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final String profileId;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  static String boxNameFor(String profileId) => '${profileId}_midi_collections';

  Future<Box<Map>> _box() async {
    final name = boxNameFor(profileId);
    if (Hive.isBoxOpen(name)) return Hive.box<Map>(name);
    return Hive.openBox<Map>(name);
  }

  /// Every live collection, sorted by name. [includeDeleted] adds the
  /// tombstones, which only sync and backup need.
  Future<List<MidiCollection>> all({bool includeDeleted = false}) async {
    final box = await _box();
    final list =
        [
          for (final raw in box.values) ?MidiCollection.tryParse(raw),
        ].where((c) => includeDeleted || !c.deleted).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return list;
  }

  /// A live collection by id; null for a missing or deleted one.
  Future<MidiCollection?> get(String id) async {
    final c = MidiCollection.tryParse((await _box()).get(id));
    return (c == null || c.deleted) ? null : c;
  }

  Future<void> put(MidiCollection c) async =>
      (await _box()).put(c.id, c.toJson());

  /// Deletes a collection by leaving a tombstone (see
  /// [MidiCollection.deleted]), so the deletion reaches other devices.
  Future<void> delete(String id) async {
    final c = await get(id);
    if (c == null) return;
    await put(c.copyWith(items: const [], deleted: true, updatedAt: _now()));
  }

  Future<void> clear() async => (await _box()).clear();

  /// Fires whenever any collection is written or removed.
  Stream<void> watch() async* {
    final box = await _box();
    yield* box.watch().map((_) {});
  }

  Future<MidiCollection> create(String name) async {
    final now = _now();
    final c = MidiCollection(
      id: _uuid.v4(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await put(c);
    return c;
  }

  Future<void> rename(String id, String name) async {
    final c = await get(id);
    if (c == null || name.trim().isEmpty) return;
    await put(c.copyWith(name: name.trim(), updatedAt: _now()));
  }

  /// Copies [items] into collection [id], skipping clips it already holds
  /// (same notes). Returns how many were added.
  Future<int> addItems(String id, List<MidiCollectionItem> items) async {
    final c = await get(id);
    if (c == null) return 0;
    final next = [...c.items];
    var added = 0;
    for (final item in items) {
      final key = item.clip.contentKey;
      if (next.any((i) => i.clip.contentKey == key)) continue;
      next.add(item);
      added++;
    }
    if (added > 0) await put(c.copyWith(items: next, updatedAt: _now()));
    return added;
  }

  /// Puts [item] in collection [id]: in place of the item with its id, or
  /// at the end. A new idea saved again replaces what it saved before,
  /// rather than piling up a copy per save.
  Future<void> putItem(String id, MidiCollectionItem item) async {
    final c = await get(id);
    if (c == null) return;
    final exists = c.items.any((i) => i.id == item.id);
    await put(
      c.copyWith(
        items: exists
            ? [for (final i in c.items) i.id == item.id ? item : i]
            : [...c.items, item],
        updatedAt: _now(),
      ),
    );
  }

  Future<void> removeItem(String id, String itemId) async {
    final c = await get(id);
    if (c == null) return;
    await put(
      c.copyWith(
        items: [
          for (final i in c.items)
            if (i.id != itemId) i,
        ],
        updatedAt: _now(),
      ),
    );
  }

  /// Remembers the preview instrument picked for one item (null = infer).
  Future<void> setItemVoice(String id, String itemId, String? voice) async {
    final c = await get(id);
    if (c == null) return;
    await put(
      c.copyWith(
        items: [
          for (final i in c.items)
            i.id == itemId
                ? i.copyWith(voice: voice, clearVoice: voice == null)
                : i,
        ],
        updatedAt: _now(),
      ),
    );
  }

  /// Applies [change] to live collection [id] and saves it with a fresh
  /// `updatedAt`; [change] returning null leaves it as it was.
  Future<MidiCollection?> _update(
    String id,
    MidiCollection? Function(MidiCollection c, DateTime now) change,
  ) async {
    final c = await get(id);
    if (c == null) return null;
    final next = change(c, _now());
    if (next == null) return null;
    await put(next);
    return next;
  }

  /// The name the user gives one clip in this collection (blank: back to
  /// the clip's own).
  Future<void> renameItem(String id, String itemId, String? title) =>
      _update(id, (c, now) {
        final t = title?.trim() ?? '';
        return c.copyWith(
          items: [
            for (final i in c.items)
              i.id == itemId ? i.copyWith(title: t, clearTitle: t.isEmpty) : i,
          ],
          updatedAt: now,
        );
      });

  /// What one clip plays (null: suggest it again).
  Future<void> setItemRole(String id, String itemId, MidiClipRole? role) =>
      _update(
        id,
        (c, now) => c.copyWith(
          items: [
            for (final i in c.items)
              i.id == itemId
                  ? i.copyWith(role: role?.name, clearRole: role == null)
                  : i,
          ],
          updatedAt: now,
        ),
      );

  /// How the collection's exported files are named.
  Future<void> setNaming(String id, MidiNamingTemplate naming) => _update(
    id,
    (c, now) =>
        c.naming == naming ? null : c.copyWith(naming: naming, updatedAt: now),
  );

  /// A new folder [name] inside [parentId] (null: the top level). Returns
  /// its id, or null when the name is blank or the collection is gone.
  Future<String?> addFolder(String id, String name, {String? parentId}) async {
    if (name.trim().isEmpty) return null;
    final folderId = _uuid.v4();
    final done = await _update(
      id,
      (c, now) => c.copyWith(
        folders: [
          ...c.folders,
          MidiCollectionFolder(
            id: folderId,
            name: name.trim(),
            parentId: c.folderById(parentId)?.id,
          ),
        ],
        updatedAt: now,
      ),
    );
    return done == null ? null : folderId;
  }

  Future<void> renameFolder(String id, String folderId, String name) =>
      _update(id, (c, now) {
        if (name.trim().isEmpty || c.folderById(folderId) == null) return null;
        return c.copyWith(
          folders: [
            for (final f in c.folders)
              f.id == folderId ? f.copyWith(name: name.trim()) : f,
          ],
          updatedAt: now,
        );
      });

  /// Removes a folder; what was in it — clips and folders — moves up into
  /// its parent. Nothing but the folder itself is lost.
  Future<void> deleteFolder(String id, String folderId) =>
      _update(id, (c, now) {
        final gone = c.folderById(folderId);
        if (gone == null) return null;
        final parent = c.folderById(gone.parentId)?.id;
        return c.copyWith(
          folders: [
            for (final f in c.folders)
              if (f.id != folderId)
                f.parentId == folderId
                    ? f.copyWith(parentId: parent, clearParent: parent == null)
                    : f,
          ],
          items: [
            for (final i in c.items)
              i.folderId == folderId
                  ? i.copyWith(folderId: parent, clearFolder: parent == null)
                  : i,
          ],
          updatedAt: now,
        );
      });

  /// Moves a folder into [parentId] (null: the top level). Refused into
  /// itself or anything inside it.
  Future<void> moveFolder(String id, String folderId, String? parentId) =>
      _update(id, (c, now) {
        if (c.folderById(folderId) == null) return null;
        final target = c.folderById(parentId)?.id;
        if (target != null &&
            c.folderAndDescendants(folderId).contains(target)) {
          return null;
        }
        return c.copyWith(
          folders: [
            for (final f in c.folders)
              f.id == folderId
                  ? f.copyWith(parentId: target, clearParent: target == null)
                  : f,
          ],
          updatedAt: now,
        );
      });

  /// Moves clips into [folderId] (null: the top level), after what is
  /// already there, keeping their order.
  Future<void> moveItemsToFolder(
    String id,
    Iterable<String> itemIds,
    String? folderId,
  ) => _update(id, (c, now) {
    final target = c.folderById(folderId)?.id;
    final ids = itemIds.toSet();
    final moving = [
      for (final i in c.items)
        if (ids.contains(i.id))
          i.copyWith(folderId: target, clearFolder: target == null),
    ];
    if (moving.isEmpty) return null;
    return c.copyWith(
      items: [
        for (final i in c.items)
          if (!ids.contains(i.id)) i,
        ...moving,
      ],
      updatedAt: now,
    );
  });

  /// Moves the clip at [from] in folder [folderId] to [to] (both positions
  /// among that folder's clips, as `ReorderableListView` reports them:
  /// [to] counts the clip still in its old place). A folder's order is its
  /// files' numbers.
  Future<void> reorderInFolder(String id, String? folderId, int from, int to) =>
      _update(id, (c, now) {
        final inFolder = c.itemsIn(c.folderById(folderId)?.id);
        if (from < 0 || from >= inFolder.length) return null;
        var target = to > from ? to - 1 : to;
        target = target.clamp(0, inFolder.length - 1);
        if (target == from) return null;
        final reordered = [...inFolder];
        reordered.insert(target, reordered.removeAt(from));
        // The folder's slots in the whole list stay where they were; only
        // which of its clips sits in each changes.
        final ids = {for (final i in inFolder) i.id};
        var next = 0;
        return c.copyWith(
          items: [
            for (final i in c.items) ids.contains(i.id) ? reordered[next++] : i,
          ],
          updatedAt: now,
        );
      });

  /// Merges collections from Drive or a backup: union by id, the newer
  /// [MidiCollection.updatedAt] winning a same-id collision. Never deletes —
  /// a collection here that [incoming] lacks was made on this device since,
  /// not removed (the same rule as `mergeCustomThemes`). Returns how many
  /// were written.
  Future<int> mergeIncoming(List<MidiCollection> incoming) async {
    if (incoming.isEmpty) return 0;
    final box = await _box();
    var written = 0;
    for (final c in incoming) {
      final mine = MidiCollection.tryParse(box.get(c.id));
      if (mine != null && !c.updatedAt.isAfter(mine.updatedAt)) continue;
      await box.put(c.id, c.toJson());
      written++;
    }
    return written;
  }

  static String newItemId() => _uuid.v4();
}
