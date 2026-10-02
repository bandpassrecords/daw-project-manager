import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/custom_field.dart';

void main() {
  group('CustomFieldDefinition JSON', () {
    test('round-trips every field', () {
      final field = CustomFieldDefinition(
        id: 'lufs',
        name: 'LUFS',
        type: CustomFieldType.number,
        showInProjectsTable: false,
        showInReleaseTracks: true,
        order: 3,
        updatedAt: DateTime(2026, 9, 1, 10),
        deletedAt: DateTime(2026, 9, 2),
      );

      expect(CustomFieldDefinition.fromJson(field.toJson()), field);
    });

    test('fills defaults for what an older or hand-written entry lacks', () {
      final field =
          CustomFieldDefinition.fromJson({'id': 'x', 'name': 'Mastered by'});

      expect(field.type, CustomFieldType.text);
      expect(field.showInProjectsTable, isTrue);
      expect(field.showInReleaseTracks, isFalse);
      expect(field.order, 0);
      expect(field.updatedAt, isNull);
      expect(field.isDeleted, isFalse);
    });

    test('reads an unknown type as text rather than failing', () {
      final field = CustomFieldDefinition.fromJson(
          {'id': 'x', 'name': 'Y', 'type': 'colour'});

      expect(field.type, CustomFieldType.text);
    });

    test('throws without an id or a name, for the list parser to skip', () {
      expect(() => CustomFieldDefinition.fromJson({'name': 'n'}),
          throwsFormatException);
      expect(() => CustomFieldDefinition.fromJson({'id': '', 'name': 'n'}),
          throwsFormatException);
      expect(() => CustomFieldDefinition.fromJson({'id': 'x'}),
          throwsFormatException);
    });
  });

  test('copyWith keeps the id, so renaming keeps the values attached', () {
    const field = CustomFieldDefinition(id: 'lufs', name: 'Loudness');

    final renamed = field.copyWith(name: 'LUFS');

    expect(renamed.id, 'lufs');
    expect(renamed.name, 'LUFS');
  });

  test('a tombstone reads as deleted', () {
    final field = CustomFieldDefinition(
        id: 'x', name: 'Y', deletedAt: DateTime(2026, 1, 1));

    expect(field.isDeleted, isTrue);
  });
}
