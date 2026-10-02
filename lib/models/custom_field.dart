import 'package:flutter/foundation.dart';

/// What a custom field holds. Values are always stored as text (see
/// `MusicProject.customFields`); the type only decides how a value is entered,
/// validated and sorted.
enum CustomFieldType {
  /// Free text — "Mastered by", "ISRC", "Mix notes".
  text,

  /// A decimal number, negative allowed — "LUFS", "True peak". Sorts by
  /// value rather than alphabetically, so -9.8 lands above -14.2.
  number;

  static CustomFieldType fromName(String? name) => CustomFieldType.values
      .firstWhere((t) => t.name == name, orElse: () => CustomFieldType.text);
}

/// One field the user added in Settings > Columns & fields: a name, a type and
/// where it shows up besides the project detail page (which always shows it).
///
/// The whole definition is **user data** — it syncs to Drive and goes into
/// local backup, so the "LUFS" column built on one machine appears on the
/// next. Which *built-in* columns are visible is a device-local preference
/// instead (`projectsTableColumnsProvider`).
///
/// Deleting a field leaves a tombstone ([deletedAt]) rather than removing the
/// entry: sync and restore merge by union, so a field that simply vanished
/// would be brought straight back by the next copy that still had it.
@immutable
class CustomFieldDefinition {
  const CustomFieldDefinition({
    required this.id,
    required this.name,
    this.type = CustomFieldType.text,
    this.showInProjectsTable = true,
    this.showInReleaseTracks = false,
    this.order = 0,
    this.updatedAt,
    this.deletedAt,
  });

  /// Stable identity (a uuid) — the key into `MusicProject.customFields`.
  /// Renaming a field keeps its id, so its values follow the new name.
  final String id;

  final String name;
  final CustomFieldType type;

  /// Whether the dashboard's projects table gets a column for this field.
  final bool showInProjectsTable;

  /// Whether a release's tracklist table gets a column for this field — the
  /// per-album view, where loudness and the like get compared track by track.
  final bool showInReleaseTracks;

  /// Position among the user's fields; columns and editors follow it.
  final int order;

  /// Last edit, for merge: on a same-id collision the newer one wins. Null
  /// never displaces a timestamped copy.
  final DateTime? updatedAt;

  /// Set when the user deleted the field. A tombstone is hidden everywhere
  /// but kept so the deletion survives a merge with an older copy.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  CustomFieldDefinition copyWith({
    String? name,
    CustomFieldType? type,
    bool? showInProjectsTable,
    bool? showInReleaseTracks,
    int? order,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CustomFieldDefinition(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      showInProjectsTable: showInProjectsTable ?? this.showInProjectsTable,
      showInReleaseTracks: showInReleaseTracks ?? this.showInReleaseTracks,
      order: order ?? this.order,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'showInProjectsTable': showInProjectsTable,
        'showInReleaseTracks': showInReleaseTracks,
        'order': order,
        'updatedAt': updatedAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  /// Throws on a missing id or name — callers parse lists through
  /// `customFieldDefinitionsFromJson`, which skips the bad entry.
  factory CustomFieldDefinition.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) {
      throw const FormatException('custom field needs an id and a name');
    }
    return CustomFieldDefinition(
      id: id,
      name: name,
      type: CustomFieldType.fromName(json['type'] as String?),
      showInProjectsTable: json['showInProjectsTable'] as bool? ?? true,
      showInReleaseTracks: json['showInReleaseTracks'] as bool? ?? false,
      order: (json['order'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CustomFieldDefinition &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.showInProjectsTable == showInProjectsTable &&
      other.showInReleaseTracks == showInReleaseTracks &&
      other.order == order &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(id, name, type, showInProjectsTable,
      showInReleaseTracks, order, updatedAt, deletedAt);
}
