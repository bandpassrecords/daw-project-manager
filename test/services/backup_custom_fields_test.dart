import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/custom_field.dart';
import 'package:daw_project_manager/services/backup_service.dart';

import '../helpers/hive_test_helper.dart';

/// Local backup coverage for custom field definitions — global user data,
/// and this is the only backup path Flatpak has.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  CustomFieldDefinition field(String id,
          {String? name, DateTime? updatedAt, DateTime? deletedAt}) =>
      CustomFieldDefinition(
        id: id,
        name: name ?? 'Field $id',
        type: CustomFieldType.number,
        showInReleaseTracks: true,
        updatedAt: updatedAt ?? DateTime(2026, 1, 1),
        deletedAt: deletedAt,
      );

  test('fields written by a restore are read back intact', () async {
    await BackupService.writeCustomFieldDefinitionsForTest(
        [field('lufs', name: 'LUFS')]);

    final restored = await BackupService.readCustomFieldDefinitionsForTest();

    expect(restored, hasLength(1));
    expect(restored.single.name, 'LUFS');
    expect(restored.single.type, CustomFieldType.number);
    expect(restored.single.showInReleaseTracks, isTrue);
  });

  test('an empty store reads as an empty list, not an error', () async {
    expect(await BackupService.readCustomFieldDefinitionsForTest(), isEmpty);
  });

  test('restoring a backup does not drop fields made since it', () async {
    await BackupService.writeCustomFieldDefinitionsForTest([field('made-here')]);

    await BackupService.writeCustomFieldDefinitionsForTest(
        [field('from-backup')]);

    final restored = await BackupService.readCustomFieldDefinitionsForTest();
    expect(restored.map((f) => f.id),
        containsAll(['made-here', 'from-backup']));
  });

  test('restoring an old backup does not revive a field deleted since',
      () async {
    await BackupService.writeCustomFieldDefinitionsForTest([
      field('lufs',
          updatedAt: DateTime(2026, 5, 1), deletedAt: DateTime(2026, 5, 1)),
    ]);

    await BackupService.writeCustomFieldDefinitionsForTest(
        [field('lufs', updatedAt: DateTime(2026, 1, 1))]);

    final restored = await BackupService.readCustomFieldDefinitionsForTest();
    expect(restored.single.isDeleted, isTrue);
  });
}
