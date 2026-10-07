import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/midi_tree_state_store.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  group('MidiTreeState', () {
    test('toggles and sets what is open, each tree on its own', () {
      var t = const MidiTreeState();
      t = t.toggleNav('c1').toggleFolder('f1').toggleFolder('f2');
      expect(t.nav, {'c1'});
      expect(t.folders, {'f1', 'f2'});
      t = t.toggleFolder('f1');
      expect(t.folders, {'f2'});
      t = t.setNav(['c1', 'c2', 'f9'], true);
      expect(t.nav, {'c1', 'c2', 'f9'});
      t = t.setNav(['c1', 'c2', 'f9'], false);
      expect(t.nav, isEmpty);
      t = t.setGroups(['p:Song', 'p:Other'], false).setGroups(['p:Song'], true);
      expect(t.groups, {'p:Song': true, 'p:Other': false});
    });

    test('round-trips through JSON; anything unreadable is all defaults', () {
      final t = const MidiTreeState()
          .toggleNav('c1')
          .toggleFolder('f1')
          .setGroups(['t:140 BPM'], false);
      final back = MidiTreeState.fromJson(jsonDecode(jsonEncode(t.toJson())));
      expect(back.nav, {'c1'});
      expect(back.folders, {'f1'});
      expect(back.groups, {'t:140 BPM': false});

      final odd = MidiTreeState.fromJson({
        'nav': ['ok', 3],
        'folders': 'nope',
        'groups': {'a': true, 'b': 'yes'},
      });
      expect(odd.nav, {'ok'});
      expect(odd.folders, isEmpty);
      expect(odd.groups, {'a': true});
      expect(MidiTreeState.fromJson(null).nav, isEmpty);
    });
  });

  group('MidiTreeStateStore', () {
    late Directory dir;
    setUp(() async => dir = await HiveTestHelper.setUp());
    tearDown(() => HiveTestHelper.tearDown(dir));

    test('keeps the tree as it was left, between runs', () async {
      await MidiTreeStateStore.save(
        const MidiTreeState().toggleNav('c1').toggleFolder('f1'),
      );
      MidiTreeStateStore.cachedForTest = const MidiTreeState();
      final loaded = await MidiTreeStateStore.load();
      expect(loaded.nav, {'c1'});
      expect(loaded.folders, {'f1'});
      expect(MidiTreeStateStore.current.folders, {'f1'});
    });
  });
}
