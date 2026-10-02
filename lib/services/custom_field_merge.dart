import 'dart:convert';

import '../models/custom_field.dart';

/// The `app_settings` box key the definitions are stored under, as a JSON
/// array. Shared by the provider, local backup and Drive sync.
const String customFieldDefinitionsStorageKey = 'customFieldDefinitions';

/// Parses a JSON array of field definitions, skipping any entry that can't be
/// read. Never throws, never returns null — one malformed field must not cost
/// the user the rest.
List<CustomFieldDefinition> customFieldDefinitionsFromJson(List? entries) {
  if (entries == null) return const [];
  final fields = <CustomFieldDefinition>[];
  for (final entry in entries) {
    if (entry is! Map) continue;
    try {
      fields.add(
          CustomFieldDefinition.fromJson(Map<String, dynamic>.from(entry)));
    } catch (_) {
      continue;
    }
  }
  return fields;
}

/// Reads the stored JSON string. Never throws.
List<CustomFieldDefinition> decodeCustomFieldDefinitions(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    return decoded is List ? customFieldDefinitionsFromJson(decoded) : const [];
  } catch (_) {
    return const [];
  }
}

String encodeCustomFieldDefinitions(List<CustomFieldDefinition> fields) =>
    jsonEncode(fields.map((f) => f.toJson()).toList());

/// Merges [incoming] definitions into [local], keyed by id — shared by local
/// backup restore and Drive sync so the two can't disagree. Same rules as
/// `mergeCustomThemes`:
///
/// * union — absence is never a deletion; a field made since the backup
///   survives restoring it.
/// * on a same-id collision the newer `updatedAt` wins, and a copy with no
///   timestamp never displaces one that has one.
///
/// Deletion travels as a tombstone (`deletedAt` set, `updatedAt` bumped), so
/// it wins against an older live copy exactly like any other edit would.
List<CustomFieldDefinition> mergeCustomFieldDefinitions(
  List<CustomFieldDefinition> local,
  List<CustomFieldDefinition> incoming,
) {
  final merged = <String, CustomFieldDefinition>{
    for (final f in local) f.id: f,
  };
  for (final field in incoming) {
    final existing = merged[field.id];
    if (existing == null || isNewerCustomField(field, existing)) {
      merged[field.id] = field;
    }
  }
  return merged.values.toList();
}

/// Whether [incoming] should replace [existing].
bool isNewerCustomField(
    CustomFieldDefinition incoming, CustomFieldDefinition existing) {
  final incomingAt = incoming.updatedAt;
  if (incomingAt == null) return false;
  final existingAt = existing.updatedAt;
  if (existingAt == null) return true;
  return incomingAt.isAfter(existingAt);
}
