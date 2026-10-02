import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

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
    final list = [
      for (final raw in box.values) ?MidiCollection.tryParse(raw),
    ].where((c) => includeDeleted || !c.deleted).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// A live collection by id; null for a missing or deleted one.
  Future<MidiCollection?> get(String id) async {
    final c = MidiCollection.tryParse((await _box()).get(id));
    return (c == null || c.deleted) ? null : c;
  }

  Future<void> put(MidiCollection c) async => (await _box()).put(c.id, c.toJson());

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

  Future<void> removeItem(String id, String itemId) async {
    final c = await get(id);
    if (c == null) return;
    await put(c.copyWith(
      items: [for (final i in c.items) if (i.id != itemId) i],
      updatedAt: _now(),
    ));
  }

  /// Remembers the preview instrument picked for one item (null = infer).
  Future<void> setItemVoice(String id, String itemId, String? voice) async {
    final c = await get(id);
    if (c == null) return;
    await put(c.copyWith(
      items: [
        for (final i in c.items)
          i.id == itemId ? i.copyWith(voice: voice, clearVoice: voice == null) : i,
      ],
      updatedAt: _now(),
    ));
  }

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
