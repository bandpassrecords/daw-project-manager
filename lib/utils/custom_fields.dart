import 'dart:convert';

import '../models/custom_field.dart';
import '../models/music_project.dart';

// ── Custom field definitions ──────────────────────────────────────────────

/// The fields the user can see and fill in: tombstones dropped, in the order
/// they arranged them in Settings (name breaks a tie, so two devices that
/// both made a field at position 0 still agree).
List<CustomFieldDefinition> activeCustomFields(
    Iterable<CustomFieldDefinition> all) {
  final active = all.where((f) => !f.isDeleted).toList()
    ..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0
          ? byOrder
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return active;
}

/// [active] with `order` rewritten to its list position — what the provider
/// stores after a reorder, so positions stay dense.
List<CustomFieldDefinition> renumberCustomFields(
  List<CustomFieldDefinition> active,
  DateTime now,
) =>
    [
      for (var i = 0; i < active.length; i++)
        active[i].order == i ? active[i] : active[i].copyWith(order: i, updatedAt: now),
    ];

/// Why a typed field name can't be saved, or null when it can.
enum CustomFieldNameProblem { empty, duplicate }

/// Checks [name] against the other active fields. Case-insensitive, like
/// tags: "LUFS" and "lufs" as two columns would only ever be a mistake.
/// [ownId] is the field being edited, which may keep its own name.
CustomFieldNameProblem? validateCustomFieldName(
  String name,
  Iterable<CustomFieldDefinition> active, {
  String? ownId,
}) {
  final trimmed = name.trim().toLowerCase();
  if (trimmed.isEmpty) return CustomFieldNameProblem.empty;
  final taken = active.any(
      (f) => f.id != ownId && f.name.trim().toLowerCase() == trimmed);
  return taken ? CustomFieldNameProblem.duplicate : null;
}

/// The TrinaGrid field name of a custom field's column. Prefixed so it can
/// never collide with a built-in column's field.
String customFieldColumnField(String fieldId) => 'cf_$fieldId';

/// A stable fingerprint of [fields] as columns: grids put it in their key so
/// adding, renaming or retyping a column remounts them.
String customFieldColumnsSignature(Iterable<CustomFieldDefinition> fields) =>
    fields.map((f) => '${f.id}:${f.type.name}:${f.name}').join('|');

/// What a project shows for [field]: the stored value, or '' when unset.
String customFieldValue(MusicProject project, CustomFieldDefinition field) =>
    project.customFields[field.id] ?? '';

// ── Numbers ───────────────────────────────────────────────────────────────

final _numberRe = RegExp(r'^[+\-−]?(\d+([.,]\d*)?|[.,]\d+)$');

/// Parses what someone types into a number field: "-14.2", "-14,2" (comma
/// decimal, as most of the app's locales write it), "−9" (a typographic
/// minus pasted from a meter plug-in). Null for anything else, blank included.
double? parseCustomNumber(String? text) {
  final trimmed = text?.trim() ?? '';
  if (!_numberRe.hasMatch(trimmed)) return null;
  return double.tryParse(
      trimmed.replaceAll('−', '-').replaceAll(',', '.'));
}

/// Whether [text] is acceptable for a field of [type]. Blank always is — it
/// means "no value".
bool isValidCustomFieldValue(CustomFieldType type, String text) {
  if (text.trim().isEmpty) return true;
  return type != CustomFieldType.number || parseCustomNumber(text) != null;
}

/// Orders two stored values of a field of [type].
///
/// Blank sorts lowest. Number fields compare by value, with anything
/// unparseable (typed before the field became a number, say) after every
/// number; text compares case-insensitively.
int compareCustomFieldValues(CustomFieldType type, Object? a, Object? b) {
  final as = (a ?? '').toString().trim();
  final bs = (b ?? '').toString().trim();
  if (as.isEmpty || bs.isEmpty) {
    return as.isEmpty == bs.isEmpty ? 0 : (as.isEmpty ? -1 : 1);
  }
  if (type == CustomFieldType.number) {
    final an = parseCustomNumber(as);
    final bn = parseCustomNumber(bs);
    if (an != null && bn != null) return an.compareTo(bn);
    if (an != null) return -1;
    if (bn != null) return 1;
  }
  return as.toLowerCase().compareTo(bs.toLowerCase());
}

// ── Built-in table columns ────────────────────────────────────────────────

/// The built-in columns the user may show, hide and reorder, in their
/// default order — in the projects table and in a release's tracklist alike:
/// every field can be switched on in either, independently
/// ([TableColumnSetting.visible] / [TableColumnSetting.inReleaseTracks]), in
/// one shared order. The checkbox and Name columns (frozen at the start, the
/// tracklist's # and Title) and the actions column (at the end) are not in
/// it: a table without names or actions is not a table anyone wants.
const List<String> kProjectsTableBuiltInColumns = [
  'status',
  'dawType',
  'bpm',
  'key',
  'tags',
  'lastModified',
  'deadline',
  // The columns a release's tracklist has, offered here too.
  'notes',
  'length',
  'parts',
];

/// Built-ins that start hidden: added after users had arranged their table,
/// they shouldn't appear in it uninvited. Switched on in Settings > Columns
/// & fields like any other.
const Set<String> kProjectsTableHiddenByDefault = {'notes', 'length', 'parts'};

/// Built-ins a release's tracklist starts without: the ones it never had
/// before every field could be shown in either table.
const Set<String> kReleaseTracksHiddenByDefault = {'tags', 'deadline'};

/// One built-in column's place and where it shows. Device-local, in the
/// `settings` box: which columns fit is a question about this screen.
class TableColumnSetting {
  const TableColumnSetting(
    this.id, {
    this.visible = true,
    this.inReleaseTracks = true,
  });

  final String id;

  /// Shown in the projects table.
  final bool visible;

  /// Shown in a release's tracklist.
  final bool inReleaseTracks;

  TableColumnSetting withVisible(bool value) =>
      TableColumnSetting(id, visible: value, inReleaseTracks: inReleaseTracks);

  TableColumnSetting withInReleaseTracks(bool value) =>
      TableColumnSetting(id, visible: visible, inReleaseTracks: value);

  @override
  bool operator ==(Object other) =>
      other is TableColumnSetting &&
      other.id == id &&
      other.visible == visible &&
      other.inReleaseTracks == inReleaseTracks;

  @override
  int get hashCode => Object.hash(id, visible, inReleaseTracks);

  @override
  String toString() =>
      '$id${visible ? '' : ' (hidden)'}${inReleaseTracks ? '' : ' (not in tracks)'}';
}

/// [stored] made complete and safe: unknown or repeated ids dropped, and every
/// built-in it lacks (one added by a newer version) appended at the end —
/// shown in each table unless it is one of that table's hidden-by-default
/// ([hiddenByDefault], [tracksHiddenByDefault]).
List<TableColumnSetting> normalizeColumnLayout(
  Iterable<TableColumnSetting> stored, {
  List<String> builtIns = kProjectsTableBuiltInColumns,
  Set<String> hiddenByDefault = kProjectsTableHiddenByDefault,
  Set<String> tracksHiddenByDefault = kReleaseTracksHiddenByDefault,
}) {
  final seen = <String>{};
  final result = <TableColumnSetting>[];
  for (final setting in stored) {
    if (!builtIns.contains(setting.id) || !seen.add(setting.id)) continue;
    result.add(setting);
  }
  for (final id in builtIns) {
    if (seen.add(id)) {
      result.add(TableColumnSetting(
        id,
        visible: !hiddenByDefault.contains(id),
        inReleaseTracks: !tracksHiddenByDefault.contains(id),
      ));
    }
  }
  return result;
}

/// Reads the stored layout. Never throws; anything unreadable is the default.
List<TableColumnSetting> decodeColumnLayout(String? raw) {
  final stored = <TableColumnSetting>[];
  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final entry in decoded) {
          if (entry is Map && entry['id'] is String) {
            final id = entry['id'] as String;
            stored.add(TableColumnSetting(
              id,
              visible: entry['visible'] as bool? ?? true,
              // Saved before the tracklist could be arranged: what it used
              // to show.
              inReleaseTracks: entry['tracks'] as bool? ??
                  !kReleaseTracksHiddenByDefault.contains(id),
            ));
          }
        }
      }
    } catch (_) {
      // Fall through to the default layout.
    }
  }
  return normalizeColumnLayout(stored);
}

String encodeColumnLayout(List<TableColumnSetting> layout) => jsonEncode([
      for (final s in layout)
        {'id': s.id, 'visible': s.visible, 'tracks': s.inReleaseTracks},
    ]);

/// [layout] with the entry at [oldIndex] moved to [newIndex], using
/// `ReorderableListView`'s convention (newIndex counted before removal).
List<TableColumnSetting> reorderColumnLayout(
  List<TableColumnSetting> layout,
  int oldIndex,
  int newIndex,
) {
  if (newIndex > oldIndex) newIndex--;
  final next = [...layout];
  next.insert(newIndex, next.removeAt(oldIndex));
  return next;
}

/// Rearranges a table's [columns] (anything with a field name, via
/// [fieldOf]): the configurable built-ins — those in [order] — move into that
/// order, [extra] (the custom field columns) follow them, and every other
/// column keeps its place before or after that block. Columns of [order]
/// missing from [columns] are skipped.
///
/// Hidden built-ins stay in the list (the grid hides them), so rows and
/// columns always agree on which cells exist.
List<T> arrangeTableColumns<T>(
  List<T> columns,
  String Function(T column) fieldOf,
  List<String> order,
  List<T> extra,
) {
  final byField = {for (final c in columns) fieldOf(c): c};
  final firstConfigurable =
      columns.indexWhere((c) => order.contains(fieldOf(c)));
  final cut = firstConfigurable < 0 ? columns.length : firstConfigurable;
  return [
    ...columns.take(cut),
    for (final id in order)
      if (byField[id] != null) byField[id] as T,
    ...extra,
    ...columns.skip(cut).where((c) => !order.contains(fieldOf(c))),
  ];
}

/// The built-in column fields to draw, in order. `tags` additionally needs
/// the tags feature switched on — hiding it in Settings > Appearance hides
/// every tag surface, the column included, whatever the layout says.
List<String> visibleBuiltInColumns(
  List<TableColumnSetting> layout, {
  required bool tagsEnabled,
}) =>
    [
      for (final s in layout)
        if (s.visible && (s.id != 'tags' || tagsEnabled)) s.id,
    ];

/// [visibleBuiltInColumns] for a release's tracklist: the built-ins switched
/// on for it, in the shared order.
List<String> releaseTracksBuiltInColumns(
  List<TableColumnSetting> layout, {
  required bool tagsEnabled,
}) =>
    [
      for (final s in layout)
        if (s.inReleaseTracks && (s.id != 'tags' || tagsEnabled)) s.id,
    ];
