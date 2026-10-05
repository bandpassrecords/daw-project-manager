import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../utils/midi_edit_hints.dart';
import 'player_volume_store.dart';

/// The piano roll editor's hints this person has already learned (see
/// [MidiEditHints]), so a hint retired once stays retired across launches.
///
/// Device-local, like the preview volume and loop setting: it describes
/// what this person has seen on this machine, not their library — neither
/// synced nor backed up.
class MidiEditHintsStore {
  const MidiEditHintsStore._();

  static const String key = 'midi_edit_hints_learned';
  static Set<MidiEditHint> _cached = {};

  static Set<MidiEditHint> get current => Set.unmodifiable(_cached);

  @visibleForTesting
  static set cachedForTest(Set<MidiEditHint> value) => _cached = {...value};

  static Future<Set<MidiEditHint>> load() async {
    try {
      final box = await Hive.openBox<String>(PlayerVolumeStore.boxName);
      _cached = decodeMidiEditHints(box.get(key));
    } catch (e) {
      debugPrint('[MidiEditHints] failed to load: $e');
    }
    return current;
  }

  static Future<void> save(Set<MidiEditHint> learned) async {
    _cached = {...learned};
    try {
      final box = await Hive.openBox<String>(PlayerVolumeStore.boxName);
      await box.put(key, encodeMidiEditHints(learned));
    } catch (e) {
      debugPrint('[MidiEditHints] failed to save: $e');
    }
  }
}

/// Whether the piano roll sounds notes as they are edited (its "acoustic
/// feedback" toggle). Device-local, like the hints beside it.
class MidiAcousticFeedbackStore {
  const MidiAcousticFeedbackStore._();

  static const String key = 'midi_acoustic_feedback';
  static bool _cached = false;

  static bool get current => _cached;

  @visibleForTesting
  static set cachedForTest(bool value) => _cached = value;

  static Future<bool> load() async {
    try {
      final box = await Hive.openBox<String>(PlayerVolumeStore.boxName);
      _cached = box.get(key) == 'true';
    } catch (e) {
      debugPrint('[MidiAcousticFeedback] failed to load: $e');
    }
    return _cached;
  }

  static Future<void> save(bool on) async {
    _cached = on;
    try {
      final box = await Hive.openBox<String>(PlayerVolumeStore.boxName);
      await box.put(key, on.toString());
    } catch (e) {
      debugPrint('[MidiAcousticFeedback] failed to save: $e');
    }
  }
}
