import 'package:hive_ce/hive.dart';

import '../models/stored_midi_clips.dart';

/// Every project's stored MIDI clips for one profile, in a lazy Hive box of
/// its own (`<profileId>_midi_clips`) so note data is only read when a
/// project page asks for it.
///
/// Opened on first use rather than with the repository: most sessions never
/// look at a clip, and Drive sync and backup reach it by profile id without a
/// repository at hand.
class MidiClipStore {
  MidiClipStore(this.profileId);

  final String profileId;

  static String boxNameFor(String profileId) => '${profileId}_midi_clips';

  Future<LazyBox<Map>> _box() async {
    final name = boxNameFor(profileId);
    if (Hive.isBoxOpen(name)) return Hive.lazyBox<Map>(name);
    return Hive.openLazyBox<Map>(name);
  }

  Future<StoredMidiClips?> get(String projectId) async =>
      StoredMidiClips.tryParse(await (await _box()).get(projectId));

  Future<void> put(String projectId, StoredMidiClips clips) async =>
      (await _box()).put(projectId, clips.toMap());

  Future<void> deleteAll(Iterable<String> projectIds) async {
    final ids = projectIds.toList();
    if (ids.isEmpty) return;
    await (await _box()).deleteAll(ids);
  }

  Future<void> clear() async => (await _box()).clear();

  /// Every stored record, for Drive sync and backup.
  Future<Map<String, StoredMidiClips>> getAll({Set<String>? onlyProjects}) async {
    final box = await _box();
    final out = <String, StoredMidiClips>{};
    for (final key in box.keys) {
      if (key is! String) continue;
      if (onlyProjects != null && !onlyProjects.contains(key)) continue;
      final value = StoredMidiClips.tryParse(await box.get(key));
      if (value != null) out[key] = value;
    }
    return out;
  }

  /// Fires with the project id whenever that project's clips are written or
  /// removed.
  Stream<String> watch() async* {
    final box = await _box();
    yield* box.watch().map((e) => e.key.toString());
  }

  /// Takes [incoming] where it is newer than what is stored, and adds what
  /// isn't stored at all. Never deletes: a record here that [incoming] lacks
  /// was read on this device and not yet synced, not removed. Returns how many
  /// projects were written.
  Future<int> mergeNewer(Map<String, StoredMidiClips> incoming) async {
    final box = await _box();
    var written = 0;
    for (final entry in incoming.entries) {
      final existing = StoredMidiClips.tryParse(await box.get(entry.key));
      if (existing != null &&
          !entry.value.extractedAt.isAfter(existing.extractedAt)) {
        continue;
      }
      await box.put(entry.key, entry.value.toMap());
      written++;
    }
    return written;
  }
}

/// Reads the `midiClips` section of a Drive or backup payload: project id →
/// [StoredMidiClips.toJson]. Unreadable entries are skipped.
Map<String, StoredMidiClips> storedMidiClipsFromJson(Object? json) {
  if (json is! Map) return const {};
  return {
    for (final e in json.entries)
      if (e.key is String && StoredMidiClips.tryParse(e.value) != null)
        e.key as String: StoredMidiClips.tryParse(e.value)!,
  };
}

Map<String, dynamic> storedMidiClipsToJson(Map<String, StoredMidiClips> all) =>
    {for (final e in all.entries) e.key: e.value.toJson()};
