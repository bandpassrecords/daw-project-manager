import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/custom_field.dart';
import 'package:daw_project_manager/services/custom_field_merge.dart';

/// The rules local backup restore and Drive sync share for custom field
/// definitions — the same as for custom themes, plus tombstones so a deleted
/// field stays deleted.
void main() {
  CustomFieldDefinition field(
    String id, {
    String? name,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      CustomFieldDefinition(
        id: id,
        name: name ?? 'Field $id',
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );

  group('mergeCustomFieldDefinitions', () {
    test('keeps a field only one side has — absence is not a deletion', () {
      final merged = mergeCustomFieldDefinitions(
        [field('local', updatedAt: DateTime(2026, 1, 1))],
        [field('incoming', updatedAt: DateTime(2026, 1, 1))],
      );

      expect(merged.map((f) => f.id), ['local', 'incoming']);
    });

    test('the newer edit wins a same-id collision', () {
      final merged = mergeCustomFieldDefinitions(
        [field('a', name: 'Loudness', updatedAt: DateTime(2026, 1, 1))],
        [field('a', name: 'LUFS', updatedAt: DateTime(2026, 2, 1))],
      );

      expect(merged.single.name, 'LUFS');
    });

    test('a stale copy cannot roll back a newer local edit', () {
      final merged = mergeCustomFieldDefinitions(
        [field('a', name: 'LUFS', updatedAt: DateTime(2026, 2, 1))],
        [field('a', name: 'Loudness', updatedAt: DateTime(2026, 1, 1))],
      );

      expect(merged.single.name, 'LUFS');
    });

    test('a copy without a timestamp never displaces one that has one', () {
      final merged = mergeCustomFieldDefinitions(
        [field('a', name: 'Kept', updatedAt: DateTime(2026, 1, 1))],
        [field('a', name: 'Undated')],
      );

      expect(merged.single.name, 'Kept');
    });

    test('a newer deletion beats an older live copy', () {
      // Deleted on this device; an older backup still has the field. Without
      // the tombstone, the union would bring it straight back.
      final merged = mergeCustomFieldDefinitions(
        [
          field('a',
              updatedAt: DateTime(2026, 3, 1), deletedAt: DateTime(2026, 3, 1)),
        ],
        [field('a', updatedAt: DateTime(2026, 1, 1))],
      );

      expect(merged.single.isDeleted, isTrue);
    });

    test('a deletion made on another device reaches this one', () {
      final merged = mergeCustomFieldDefinitions(
        [field('a', updatedAt: DateTime(2026, 1, 1))],
        [
          field('a',
              updatedAt: DateTime(2026, 3, 1), deletedAt: DateTime(2026, 3, 1)),
        ],
      );

      expect(merged.single.isDeleted, isTrue);
    });
  });

  group('decoding', () {
    test('skips a malformed entry and keeps the rest', () {
      final fields = customFieldDefinitionsFromJson([
        {'id': 'ok', 'name': 'LUFS'},
        {'name': 'no id'},
        'not a map',
        {'id': 'ok2', 'name': 'ISRC'},
      ]);

      expect(fields.map((f) => f.id), ['ok', 'ok2']);
    });

    test('reads null, empty and garbage as no fields', () {
      expect(customFieldDefinitionsFromJson(null), isEmpty);
      expect(decodeCustomFieldDefinitions(null), isEmpty);
      expect(decodeCustomFieldDefinitions(''), isEmpty);
      expect(decodeCustomFieldDefinitions('{not json'), isEmpty);
      expect(decodeCustomFieldDefinitions('{"a": 1}'), isEmpty);
    });

    test('encode and decode round-trip', () {
      final fields = [
        field('a', name: 'LUFS', updatedAt: DateTime(2026, 1, 1)),
        field('b', deletedAt: DateTime(2026, 2, 1)),
      ];

      expect(
        decodeCustomFieldDefinitions(encodeCustomFieldDefinitions(fields)),
        fields,
      );
    });
  });
}
