import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/custom_theme.dart';
import 'package:daw_project_manager/services/backup_service.dart';

import '../helpers/hive_test_helper.dart';

/// Local backup coverage for user themes (#148).
///
/// This is the only backup path Flatpak has — Google Drive sync is not
/// offered there — so a theme skipped here is one those users could never
/// back up at all, not merely one that wouldn't survive a Drive restore.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  CustomTheme theme(String id, {String? name, DateTime? updatedAt}) =>
      CustomTheme(
        id: id,
        name: name ?? 'Theme $id',
        brightness: Brightness.dark,
        primary: const Color(0xFFEC407A),
        background: const Color(0xFF14161A),
        card: const Color(0xFF232529),
        cardRadius: 10,
        controlRadius: 6,
        updatedAt: updatedAt ?? DateTime(2026, 1, 1),
      );

  test('themes written by a restore are read back intact', () async {
    await BackupService.writeCustomThemesForTest([theme('a', name: 'Amber')]);

    final restored = await BackupService.readCustomThemesForTest();

    expect(restored, hasLength(1));
    expect(restored.single.id, 'a');
    expect(restored.single.name, 'Amber');
    expect(restored.single.primary, const Color(0xFFEC407A));
    expect(restored.single.cardRadius, 10);
    expect(restored.single.controlRadius, 6);
  });

  test('an empty store reads as an empty list, not an error', () async {
    expect(await BackupService.readCustomThemesForTest(), isEmpty);
  });

  test('restoring a backup does not drop themes made since it', () async {
    await BackupService.writeCustomThemesForTest([theme('made-here')]);

    await BackupService.writeCustomThemesForTest([theme('from-backup')]);

    final restored = await BackupService.readCustomThemesForTest();
    expect(restored.map((t) => t.id), containsAll(['made-here', 'from-backup']));
  });

  test('a stale backup cannot roll back a newer local edit', () async {
    await BackupService.writeCustomThemesForTest(
      [theme('a', name: 'Edited here', updatedAt: DateTime(2026, 6, 1))],
    );

    await BackupService.writeCustomThemesForTest(
      [theme('a', name: 'Stale backup', updatedAt: DateTime(2026, 1, 1))],
    );

    final restored = await BackupService.readCustomThemesForTest();
    expect(restored.single.name, 'Edited here');
  });

  test('a pre-1.3 backup with no customThemes key imports cleanly', () async {
    // The key simply isn't there in an older file; that must read as "no
    // themes", not as an error that aborts the whole import.
    expect(BackupService.customThemesFromJsonForTest(null), isEmpty);
  });

  test('one unreadable theme in a backup does not lose the others', () async {
    final parsed = BackupService.customThemesFromJsonForTest([
      theme('good-1').toJson(),
      {'missing': 'an id'},
      theme('good-2').toJson(),
    ]);

    expect(parsed.map((t) => t.id), ['good-1', 'good-2']);
  });
}
