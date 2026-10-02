import 'package:trina_grid/trina_grid.dart';

import '../../models/custom_field.dart';
import '../../utils/custom_fields.dart';

/// A custom field's column, shared by the projects table and the release
/// tracklist table. Cell values are the stored text (see
/// `customFieldValue`); a number field sorts by value, so -14.2 comes before
/// -9.8 instead of after it.
TrinaColumn customFieldTrinaColumn(CustomFieldDefinition field) {
  final isNumber = field.type == CustomFieldType.number;
  return TrinaColumn(
    title: field.name,
    field: customFieldColumnField(field.id),
    type: TrinaColumnType.custom(
      compare: (a, b) => compareCustomFieldValues(field.type, a, b),
    ),
    width: isNumber ? 100 : 160,
    minWidth: 70,
    textAlign: isNumber ? TrinaColumnTextAlign.end : TrinaColumnTextAlign.start,
    enableEditingMode: false,
  );
}
