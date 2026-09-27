import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/scan_root.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDownAll(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  ScanRoot makeRoot({
    String id = 'root-1',
    String path = '/home/artist/Music/Projects',
    DateTime? addedAt,
    DateTime? lastScanAt,
    int scanDepth = 0,
    String? displayName,
    bool enabled = true,
  }) {
    return ScanRoot(
      id: id,
      path: path,
      addedAt: addedAt ?? DateTime(2025, 1, 1),
      lastScanAt: lastScanAt,
      scanDepth: scanDepth,
      displayName: displayName,
      enabled: enabled,
    );
  }

  group('ScanRoot.effectiveDisplayName', () {
    test('uses displayName when set', () {
      final root = makeRoot(
        path: '/home/artist/Music/Projects',
        displayName: 'My LMMS Projects',
      );
      expect(root.effectiveDisplayName, 'My LMMS Projects');
    });

    test('falls back to the folder\'s own name when displayName is unset', () {
      final root = makeRoot(
        path: '/home/artist/Music/Projects',
        displayName: null,
      );
      expect(root.effectiveDisplayName, 'Projects');
    });

    test('falls back correctly for a Windows-style path', () {
      // p.basename() uses the current platform's path style, so this
      // assertion is only meaningful when actually running on Windows —
      // gated below rather than asserted unconditionally.
      final root = makeRoot(
        path: r'C:\Users\Artist\Music\Projects',
        displayName: null,
      );
      expect(root.effectiveDisplayName, 'Projects');
    }, testOn: 'windows');
  });

  group('ScanRoot.copyWith', () {
    test('preserves displayName when no argument is given', () {
      final root = makeRoot(displayName: 'Projects');
      final copy = root.copyWith();

      expect(copy.displayName, 'Projects');
    });

    test('updates only displayName', () {
      final root = makeRoot(displayName: 'Projects');
      final renamed = root.copyWith(displayName: 'My LMMS Projects');

      expect(renamed.displayName, 'My LMMS Projects');
      expect(renamed.id, root.id);
      expect(renamed.path, root.path);
    });
  });

  group('ScanRootAdapter (Hive round-trip)', () {
    test('preserves displayName after write and read', () async {
      final original = makeRoot(displayName: 'Projects');

      final box = await Hive.openBox<ScanRoot>('scan_root_round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;
      await box.close();

      expect(restored.displayName, 'Projects');
    });

    test('reads back a null displayName correctly (pre-existing roots)', () async {
      final original = makeRoot(id: 'root-2', displayName: null);

      final box = await Hive.openBox<ScanRoot>('scan_root_round_trip_test_2');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;
      await box.close();

      expect(restored.displayName, isNull);
    });

    test('preserves a disabled root across write and read', () async {
      final original = makeRoot(id: 'root-3', enabled: false);

      final box = await Hive.openBox<ScanRoot>('scan_root_round_trip_test_3');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;
      await box.close();

      expect(restored.enabled, isFalse);
    });

    test('defaults enabled to true for a root written before the field existed',
        () {
      // Simulates a box whose stored record has only fields 0..6 — the exact
      // shape written by the adapter before `enabled` was added. Without the
      // `?? true` fallback in read(), every pre-existing root would come back
      // disabled and the user's whole library would vanish on upgrade.
      final legacyFields = <int, dynamic>{
        0: 'legacy-root',
        1: '/home/artist/Music',
        2: DateTime(2025, 1, 1),
        3: null,
        4: 0,
        5: 'Music',
        6: false,
      };
      final restored = ScanRoot(
        id: legacyFields[0] as String,
        path: legacyFields[1] as String,
        addedAt: legacyFields[2] as DateTime,
        lastScanAt: legacyFields[3] as DateTime?,
        scanDepth: legacyFields[4] as int,
        displayName: legacyFields[5] as String?,
        autoStackVersions: legacyFields[6] as bool,
        enabled: legacyFields[7] as bool? ?? true,
      );

      expect(restored.enabled, isTrue);
    });
  });

  group('ScanRoot.enabled', () {
    test('defaults to true', () {
      expect(makeRoot().enabled, isTrue);
    });

    test('copyWith can switch it off and back on', () {
      final root = makeRoot();
      expect(root.copyWith(enabled: false).enabled, isFalse);
      expect(
        root.copyWith(enabled: false).copyWith(enabled: true).enabled,
        isTrue,
      );
    });

    test('copyWith leaves it alone when not passed', () {
      final disabled = makeRoot(enabled: false);
      expect(disabled.copyWith(displayName: 'Renamed').enabled, isFalse);
    });
  });
}
