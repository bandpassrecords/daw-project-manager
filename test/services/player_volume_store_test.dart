import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/services/player_volume_store.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  group('parseVolume', () {
    test('reads a stored level', () {
      expect(parseVolume('0.35'), 0.35);
    });

    test('an absent value is full volume, not silence', () {
      // A fresh install has nothing stored; defaulting to 0 would make the
      // app look broken the first time anything is played.
      expect(parseVolume(null), PlayerVolumeStore.defaultVolume);
      expect(parseVolume(''), PlayerVolumeStore.defaultVolume);
    });

    test('garbage reads as full volume rather than mute', () {
      expect(parseVolume('loud'), PlayerVolumeStore.defaultVolume);
      expect(parseVolume('NaN'), PlayerVolumeStore.defaultVolume);
    });

    test('out-of-range values are clamped', () {
      expect(parseVolume('1.7'), 1.0);
      expect(parseVolume('-0.2'), 0.0);
    });

    test('a deliberate mute is kept', () {
      // 0 is a real choice — only an unreadable value falls back to 1.0.
      expect(parseVolume('0.0'), 0.0);
    });
  });

  group('clampVolume', () {
    test('keeps values inside 0…1', () {
      expect(clampVolume(0.5), 0.5);
      expect(clampVolume(2), 1.0);
      expect(clampVolume(-1), 0.0);
    });
  });

  group('PlayerVolumeStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      PlayerVolumeStore.cachedForTest = PlayerVolumeStore.defaultVolume;
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('a saved level survives a reload', () async {
      // The bug this fixes: turn a track down, open the next one, and it
      // blasts at full volume again.
      await PlayerVolumeStore.save(0.4);
      PlayerVolumeStore.cachedForTest = PlayerVolumeStore.defaultVolume;

      expect(await PlayerVolumeStore.load(), 0.4);
      expect(PlayerVolumeStore.current, 0.4);
    });

    test('saving updates the synchronous value immediately', () async {
      // Players seed their slider from `current` on their first build, before
      // any async read could finish.
      await PlayerVolumeStore.save(0.25);

      expect(PlayerVolumeStore.current, 0.25);
    });

    test('saving an out-of-range value stores it clamped', () async {
      await PlayerVolumeStore.save(3);

      expect(await PlayerVolumeStore.load(), 1.0);
    });

    test('loading with nothing stored gives full volume', () async {
      expect(await PlayerVolumeStore.load(), PlayerVolumeStore.defaultVolume);
    });

    test('lives in the device-local settings box', () async {
      // Deliberately not synced or backed up — it describes this machine's
      // speakers, not the user's library.
      await PlayerVolumeStore.save(0.6);
      final box = await Hive.openBox<String>(PlayerVolumeStore.boxName);

      expect(box.get(PlayerVolumeStore.key), '0.6');
    });
  });
}
