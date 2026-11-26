import 'dart:convert';

import 'package:hive_ce/hive.dart';

/// A scan folder moved from [from] to [to] with "Relocate folder"
/// (`ProjectRepository.relocateRoot`).
///
/// Kept so a row that arrives later still naming the old place — from a
/// Drive merge, a local backup import — lands at the new one. Without it a
/// merge brought back a copy of every project from before the move, still
/// pointing at the empty folder, beside the one relocating had moved.
class RootRelocation {
  const RootRelocation({
    required this.from,
    required this.to,
    required this.at,
  });

  final String from;
  final String to;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'from': from,
    'to': to,
    'at': at.toUtc().toIso8601String(),
  };

  static RootRelocation? fromJson(Object? json) {
    if (json is! Map) return null;
    final from = json['from'], to = json['to'];
    final at = json['at'] is String
        ? DateTime.tryParse(json['at'] as String)
        : null;
    if (from is! String || to is! String || at == null) return null;
    return RootRelocation(from: from, to: to, at: at.toLocal());
  }
}

/// Every relocation made on this device, per profile, oldest first.
///
/// **Device-local**: a path names a place on this computer's disks, so it is
/// neither synced nor in local backup, like the file hash cache.
class RootRelocationStore {
  static const boxName = 'root_relocations';

  static Future<Box<String>> _box() async => Hive.isBoxOpen(boxName)
      ? Hive.box<String>(boxName)
      : await Hive.openBox<String>(boxName);

  static Future<void> record(
    String profileId, {
    required String from,
    required String to,
    DateTime? at,
  }) async {
    final box = await _box();
    final list = [
      ...await of(profileId),
      RootRelocation(from: from, to: to, at: at ?? DateTime.now()),
    ];
    await box.put(profileId, jsonEncode([for (final r in list) r.toJson()]));
  }

  static Future<List<RootRelocation>> of(String profileId) async {
    final box = await _box();
    final raw = box.get(profileId);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded)
          if (RootRelocation.fromJson(e) case final r?) r,
      ]..sort((a, b) => a.at.compareTo(b.at));
    } catch (_) {
      return const [];
    }
  }
}
