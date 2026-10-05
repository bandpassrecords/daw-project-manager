import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/custom_field.dart';
import 'package:daw_project_manager/utils/custom_fields.dart';

import '../helpers/test_factories.dart';

void main() {
  group('parseCustomNumber', () {
    test('reads plain, negative and decimal numbers', () {
      expect(parseCustomNumber('-14.2'), -14.2);
      expect(parseCustomNumber('9'), 9);
      expect(parseCustomNumber('+3.5'), 3.5);
      expect(parseCustomNumber('.5'), 0.5);
      expect(parseCustomNumber('  -8  '), -8);
    });

    test('reads a comma decimal, as most of the app locales write one', () {
      expect(parseCustomNumber('-14,2'), -14.2);
    });

    test('reads a typographic minus pasted from a meter', () {
      expect(parseCustomNumber('−14.2'), -14.2);
    });

    test('rejects anything that is not just a number', () {
      expect(parseCustomNumber(null), isNull);
      expect(parseCustomNumber(''), isNull);
      expect(parseCustomNumber('-'), isNull);
      expect(parseCustomNumber('-14 LUFS'), isNull);
      expect(parseCustomNumber('1.2.3'), isNull);
      expect(parseCustomNumber('abc'), isNull);
    });
  });

  test('isValidCustomFieldValue: blank is always fine, text anything', () {
    expect(isValidCustomFieldValue(CustomFieldType.number, ''), isTrue);
    expect(isValidCustomFieldValue(CustomFieldType.number, '-14'), isTrue);
    expect(isValidCustomFieldValue(CustomFieldType.number, '-1x'), isFalse);
    expect(isValidCustomFieldValue(CustomFieldType.text, '-1x'), isTrue);
  });

  group('compareCustomFieldValues', () {
    List<String> sorted(CustomFieldType type, List<String> values) =>
        [...values]..sort((a, b) => compareCustomFieldValues(type, a, b));

    test('numbers sort by value, not alphabetically', () {
      // The exact case from the request: equalising an album's loudness.
      expect(
        sorted(CustomFieldType.number, ['-9.8', '-14.2', '-11', '-14,0']),
        ['-14.2', '-14,0', '-11', '-9.8'],
      );
    });

    test('blank sorts lowest, and unparseable after every number', () {
      expect(
        sorted(CustomFieldType.number, ['oops', '-9', '', '-14']),
        ['', '-14', '-9', 'oops'],
      );
    });

    test('text sorts case-insensitively', () {
      expect(
        sorted(CustomFieldType.text, ['bob', 'Ana', 'carla']),
        ['Ana', 'bob', 'carla'],
      );
    });

    test('null counts as blank', () {
      expect(compareCustomFieldValues(CustomFieldType.number, null, ''), 0);
      expect(compareCustomFieldValues(CustomFieldType.number, null, '1'), -1);
    });
  });

  group('activeCustomFields', () {
    test('drops tombstones and follows the user order, name breaking ties', () {
      final fields = activeCustomFields([
        const CustomFieldDefinition(id: 'c', name: 'Zed', order: 1),
        CustomFieldDefinition(
            id: 'gone', name: 'Gone', deletedAt: DateTime(2026, 1, 1)),
        const CustomFieldDefinition(id: 'b', name: 'beta', order: 0),
        const CustomFieldDefinition(id: 'a', name: 'Alpha', order: 0),
      ]);

      expect(fields.map((f) => f.id), ['a', 'b', 'c']);
    });

    test('renumber rewrites positions densely and stamps only what moved', () {
      final now = DateTime(2026, 9, 1);
      final renumbered = renumberCustomFields([
        const CustomFieldDefinition(id: 'a', name: 'A', order: 0),
        const CustomFieldDefinition(id: 'b', name: 'B', order: 5),
      ], now);

      expect(renumbered.map((f) => f.order), [0, 1]);
      expect(renumbered.first.updatedAt, isNull);
      expect(renumbered.last.updatedAt, now);
    });
  });

  group('validateCustomFieldName', () {
    const lufs = CustomFieldDefinition(id: 'lufs', name: 'LUFS');

    test('a blank name is refused', () {
      expect(validateCustomFieldName('  ', const []),
          CustomFieldNameProblem.empty);
    });

    test('a name another field has is refused, ignoring case', () {
      expect(validateCustomFieldName(' lufs ', const [lufs]),
          CustomFieldNameProblem.duplicate);
    });

    test('a field may keep its own name when edited', () {
      expect(validateCustomFieldName('LUFS', const [lufs], ownId: 'lufs'),
          isNull);
    });

    test('a new name is fine', () {
      expect(validateCustomFieldName('ISRC', const [lufs]), isNull);
    });
  });

  test('customFieldValue reads the stored value or blank', () {
    const field = CustomFieldDefinition(id: 'lufs', name: 'LUFS');

    expect(
      customFieldValue(
          TestFactories.makeProject(customFields: {'lufs': '-14'}), field),
      '-14',
    );
    expect(customFieldValue(TestFactories.makeProject(), field), '');
  });

  test('column field names are prefixed so they cannot hit a built-in', () {
    expect(customFieldColumnField('bpm'), 'cf_bpm');
  });

  test('the column signature changes with name, type and membership', () {
    const a = CustomFieldDefinition(id: 'a', name: 'LUFS');
    final base = customFieldColumnsSignature([a]);

    expect(customFieldColumnsSignature([a.copyWith(name: 'Loudness')]),
        isNot(base));
    expect(
        customFieldColumnsSignature([a.copyWith(type: CustomFieldType.number)]),
        isNot(base));
    expect(customFieldColumnsSignature(const []), isNot(base));
    expect(customFieldColumnsSignature([a]), base);
  });

  group('projects table column layout', () {
    test('an empty store is every built-in in default order, the opt-in ones hidden',
        () {
      expect(decodeColumnLayout(null).map((s) => s.id),
          kProjectsTableBuiltInColumns);
      expect(
        {for (final s in decodeColumnLayout(null)) if (!s.visible) s.id},
        kProjectsTableHiddenByDefault,
      );
      expect(decodeColumnLayout('garbage').map((s) => s.id),
          kProjectsTableBuiltInColumns);
    });

    test('notes, length and parts (the tracklist columns) are on offer',
        () {
      expect(kProjectsTableBuiltInColumns,
          containsAll(['notes', 'length', 'parts']));
      expect(kProjectsTableHiddenByDefault, {'notes', 'length', 'parts'});
    });

    test('a layout saved before them gets them appended, hidden', () {
      // Arranged and stored by an older version: bpm hidden, deadline first.
      final older = normalizeColumnLayout(const [
        TableColumnSetting('deadline'),
        TableColumnSetting('bpm', visible: false),
      ]);
      expect(older.take(2).map((s) => s.toString()), ['deadline', 'bpm (hidden)']);
      expect(older.sublist(older.length - 3).map((s) => s.toString()),
          ['notes (hidden)', 'length (hidden)', 'parts (hidden)']);
      expect(older.firstWhere((s) => s.id == 'status').visible, isTrue,
          reason: 'older built-ins it lacked still come in visible');
    });

    test('a layout saved before tracklists could be arranged keeps what they showed',
        () {
      // An older build wrote only id + visible.
      final layout = decodeColumnLayout(
          '[{"id":"status","visible":true},{"id":"tags","visible":true},'
          '{"id":"deadline","visible":false},{"id":"bpm","visible":true}]');
      final tracks = {for (final s in layout) s.id: s.inReleaseTracks};
      expect(tracks['status'], isTrue);
      expect(tracks['bpm'], isTrue);
      expect(tracks['tags'], isFalse, reason: 'tracklists never had tags');
      expect(tracks['deadline'], isFalse);
      expect(layout.firstWhere((s) => s.id == 'deadline').visible, isFalse,
          reason: 'the projects table setting is untouched');
    });

    test('the release tracklist setting round-trips, independently', () {
      final layout = normalizeColumnLayout(const [
        TableColumnSetting('bpm', visible: false, inReleaseTracks: true),
        TableColumnSetting('key', visible: true, inReleaseTracks: false),
      ]);
      final back = decodeColumnLayout(encodeColumnLayout(layout));
      expect(back, layout);
      expect(back.first.toString(), 'bpm (hidden)');
      expect(back[1].toString(), 'key (not in tracks)');
    });

    test('releaseTracksBuiltInColumns: what the tracklist draws, in order', () {
      final layout = normalizeColumnLayout(const [
        TableColumnSetting('tags', inReleaseTracks: true),
        TableColumnSetting('bpm', inReleaseTracks: false),
      ]);
      final shown = releaseTracksBuiltInColumns(layout, tagsEnabled: true);
      expect(shown.first, 'tags');
      expect(shown, isNot(contains('bpm')));
      expect(shown, isNot(contains('deadline')), reason: 'off by default there');
      expect(shown, containsAll(['notes', 'length', 'parts']),
          reason: 'the tracklist had these before');
      expect(releaseTracksBuiltInColumns(layout, tagsEnabled: false),
          isNot(contains('tags')),
          reason: 'tags switched off app-wide hide everywhere');
    });

    test('once switched on, an opt-in column stays on', () {
      final layout = normalizeColumnLayout(const [
        TableColumnSetting('notes'),
      ]);
      expect(layout.first, const TableColumnSetting('notes'));
    });

    test('round-trips order and visibility', () {
      final layout = [
        const TableColumnSetting('bpm', visible: false),
        ...normalizeColumnLayout(const [])
            .where((s) => s.id != 'bpm'),
      ];

      expect(decodeColumnLayout(encodeColumnLayout(layout)), layout);
    });

    test('drops unknown and repeated ids, appends built-ins it lacks', () {
      final layout = normalizeColumnLayout(const [
        TableColumnSetting('deadline'),
        TableColumnSetting('retired-column'),
        TableColumnSetting('deadline', visible: false),
      ]);

      expect(layout.first, const TableColumnSetting('deadline'));
      expect(layout.map((s) => s.id).toSet(),
          kProjectsTableBuiltInColumns.toSet());
      expect(layout, hasLength(kProjectsTableBuiltInColumns.length));
    });

    test('reorder follows ReorderableListView indices', () {
      final layout = normalizeColumnLayout(const []);

      final moved = reorderColumnLayout(layout, 0, 3);

      expect(moved.map((s) => s.id).take(3), ['dawType', 'bpm', 'status']);
    });

    test('the tags column also needs the tags feature switched on', () {
      final layout = normalizeColumnLayout(const []);

      expect(visibleBuiltInColumns(layout, tagsEnabled: false),
          isNot(contains('tags')));
      expect(visibleBuiltInColumns(layout, tagsEnabled: true),
          contains('tags'));
    });

    test('a hidden column is not drawn', () {
      final layout = [
        for (final s in normalizeColumnLayout(const []))
          s.id == 'bpm' ? s.withVisible(false) : s,
      ];

      expect(visibleBuiltInColumns(layout, tagsEnabled: true),
          isNot(contains('bpm')));
    });
  });

  group('arrangeTableColumns', () {
    String id(String s) => s;

    test('built-ins follow the layout, custom columns follow them, '
        'fixed columns keep their ends', () {
      final arranged = arrangeTableColumns<String>(
        ['checkbox', 'name', 'status', 'bpm', 'key', 'launch', 'data'],
        id,
        ['key', 'status', 'bpm'],
        ['cf_lufs'],
      );

      expect(arranged, [
        'checkbox',
        'name',
        'key',
        'status',
        'bpm',
        'cf_lufs',
        'launch',
        'data',
      ]);
    });

    test('skips layout ids the table does not have', () {
      final arranged = arrangeTableColumns<String>(
        ['name', 'bpm', 'launch'],
        id,
        ['tags', 'bpm'],
        const [],
      );

      expect(arranged, ['name', 'bpm', 'launch']);
    });
  });
}
