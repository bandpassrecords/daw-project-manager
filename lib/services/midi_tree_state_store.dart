import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import 'player_volume_store.dart';

/// Which parts of the MIDI tab's trees are open: collections and folders
/// in the side list ([nav]), folders in a collection's tree ([folders]),
/// and the groups of "All clips" — a project, or a tempo — the user opened
/// or closed ([groups]; a group not in it opens by the list's default).
class MidiTreeState {
  const MidiTreeState({
    this.nav = const {},
    this.folders = const {},
    this.groups = const {},
  });

  final Set<String> nav;
  final Set<String> folders;
  final Map<String, bool> groups;

  static Set<String> _toggled(Set<String> set, String id) =>
      set.contains(id) ? ({...set}..remove(id)) : {...set, id};

  static Set<String> _set(Set<String> set, Iterable<String> ids, bool open) =>
      open ? {...set, ...ids} : ({...set}..removeAll(ids));

  MidiTreeState toggleNav(String id) => _with(nav: _toggled(nav, id));
  MidiTreeState setNav(Iterable<String> ids, bool open) =>
      _with(nav: _set(nav, ids, open));
  MidiTreeState toggleFolder(String id) =>
      _with(folders: _toggled(folders, id));
  MidiTreeState setFolders(Iterable<String> ids, bool open) =>
      _with(folders: _set(folders, ids, open));
  MidiTreeState setGroups(Iterable<String> keys, bool open) =>
      _with(groups: {...groups, for (final k in keys) k: open});

  MidiTreeState _with({
    Set<String>? nav,
    Set<String>? folders,
    Map<String, bool>? groups,
  }) => MidiTreeState(
    nav: nav ?? this.nav,
    folders: folders ?? this.folders,
    groups: groups ?? this.groups,
  );

  Map<String, dynamic> toJson() => {
    'nav': nav.toList(),
    'folders': folders.toList(),
    'groups': groups,
  };

  /// Anything unreadable is a tree with everything at its default.
  static MidiTreeState fromJson(Object? json) {
    if (json is! Map) return const MidiTreeState();
    Set<String> ids(Object? list) => list is List
        ? {
            for (final v in list)
              if (v is String) v,
          }
        : const {};
    final groups = json['groups'];
    return MidiTreeState(
      nav: ids(json['nav']),
      folders: ids(json['folders']),
      groups: groups is Map
          ? {
              for (final e in groups.entries)
                if (e.key is String && e.value is bool)
                  e.key as String: e.value as bool,
            }
          : const {},
    );
  }
}

/// Keeps [MidiTreeState] between runs. Device-local, like the preview
/// volume: how this person left the lists on this machine — neither synced
/// nor backed up.
class MidiTreeStateStore {
  const MidiTreeStateStore._();

  static const String key = 'midi_tree_state';
  static MidiTreeState _cached = const MidiTreeState();

  static MidiTreeState get current => _cached;

  @visibleForTesting
  static set cachedForTest(MidiTreeState value) => _cached = value;

  static Future<MidiTreeState> load() async {
    try {
      final box = await Hive.openBox<String>(PlayerVolumeStore.boxName);
      final raw = box.get(key);
      if (raw != null) _cached = MidiTreeState.fromJson(jsonDecode(raw));
    } catch (e) {
      debugPrint('[MidiTreeState] failed to load: $e');
    }
    return _cached;
  }

  static Future<void> save(MidiTreeState state) async {
    _cached = state;
    try {
      final box = await Hive.openBox<String>(PlayerVolumeStore.boxName);
      await box.put(key, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[MidiTreeState] failed to save: $e');
    }
  }
}
