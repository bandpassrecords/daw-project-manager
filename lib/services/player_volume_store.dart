import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// Remembers the playback volume across players and across launches.
///
/// Every player in the app builds its own `AudioPlayer` and starts at full
/// volume, so turning a track down and opening the next one — or the same one
/// in a different surface — blasted it again at 1.0. The level is a property
/// of how loud the user wants this app to be, not of any one widget.
///
/// Device-local by design: it describes this machine's speakers and this
/// person's ears, not their library, so it is in neither Drive sync nor local
/// backup — restoring a backup should not change how loud the app is.
class PlayerVolumeStore {
  const PlayerVolumeStore._();

  static const String boxName = 'app_settings';
  static const String key = 'player_volume';

  /// What a player starts at before anything is loaded, and the fallback for
  /// a missing or unreadable stored value.
  static const double defaultVolume = 1.0;

  /// Cached so a player can start at the right level on its first build
  /// rather than at full volume for a frame — the box read is async, and a
  /// momentary blast is exactly what this is meant to prevent.
  static double _cached = defaultVolume;

  /// The last known volume, available synchronously. Correct from the first
  /// [load] of the session onwards.
  static double get current => _cached;

  @visibleForTesting
  static set cachedForTest(double value) => _cached = value;

  /// Reads the stored volume, clamped to a usable range.
  ///
  /// Never throws: a corrupt or missing value falls back to [defaultVolume],
  /// because failing to read a preference must not stop playback.
  static Future<double> load() async {
    try {
      final box = await Hive.openBox<String>(boxName);
      final stored = box.get(key);
      _cached = parseVolume(stored);
      return _cached;
    } catch (e) {
      debugPrint('[PlayerVolume] failed to load: $e');
      return _cached;
    }
  }

  /// Stores [volume]. Best-effort — a failed write costs the user the setting
  /// next launch, which must not surface as an error mid-playback.
  static Future<void> save(double volume) async {
    final clamped = clampVolume(volume);
    _cached = clamped;
    try {
      final box = await Hive.openBox<String>(boxName);
      await box.put(key, clamped.toString());
    } catch (e) {
      debugPrint('[PlayerVolume] failed to save: $e');
    }
  }
}

/// [volume] held inside 0…1.
double clampVolume(double volume) => volume.clamp(0.0, 1.0);

/// Reads a stored volume string.
///
/// Anything unparseable, out of range, or absent reads as
/// [PlayerVolumeStore.defaultVolume] rather than as silence — a stored value
/// gone bad should leave the app audible, not mysteriously mute.
double parseVolume(String? stored) {
  if (stored == null || stored.isEmpty) return PlayerVolumeStore.defaultVolume;
  final parsed = double.tryParse(stored);
  if (parsed == null || parsed.isNaN) return PlayerVolumeStore.defaultVolume;
  return clampVolume(parsed);
}
