import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/custom_field.dart';
import '../../utils/custom_fields.dart';

/// Settings > Columns & fields: which built-in columns the projects table
/// shows (and their order), and the user's custom fields.
///
/// Plain values and callbacks — no `Ref`, no Hive — so it can be
/// widget-tested; the settings page wires it to the providers.
class ColumnsAndFieldsSettings extends StatelessWidget {
  const ColumnsAndFieldsSettings({
    super.key,
    required this.columns,
    required this.columnLabel,
    required this.onColumnVisibleChanged,
    required this.onColumnsReordered,
    required this.onResetColumns,
    required this.fields,
    required this.onAddField,
    required this.onEditField,
    required this.onDeleteField,
    required this.onFieldChanged,
    required this.onFieldsReordered,
  });

  final List<TableColumnSetting> columns;
  final String Function(String columnId) columnLabel;
  final void Function(String columnId, bool visible) onColumnVisibleChanged;
  final void Function(int oldIndex, int newIndex) onColumnsReordered;
  final VoidCallback onResetColumns;

  /// Active fields only, in order.
  final List<CustomFieldDefinition> fields;
  final VoidCallback onAddField;
  final ValueChanged<CustomFieldDefinition> onEditField;
  final ValueChanged<CustomFieldDefinition> onDeleteField;

  /// A quick toggle straight from the list (where the field shows).
  final ValueChanged<CustomFieldDefinition> onFieldChanged;
  final void Function(int oldIndex, int newIndex) onFieldsReordered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnsCard(context),
        const SizedBox(height: 12),
        _buildFieldsCard(context),
      ],
    );
  }

  Widget _header(BuildContext context, IconData icon, String title,
      {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildColumnsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dragColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(
              context,
              Icons.view_column_outlined,
              l10n.projectsTableColumnsTitle,
              trailing: TextButton(
                onPressed: onResetColumns,
                child: Text(l10n.resetToDefaults),
              ),
            ),
            const SizedBox(height: 2),
            Text(l10n.projectsTableColumnsDescription,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: columns.length,
                onReorder: onColumnsReordered,
                itemBuilder: (context, index) {
                  final column = columns[index];
                  return ListTile(
                    key: ValueKey('column-${column.id}'),
                    dense: true,
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_indicator, color: dragColor),
                    ),
                    title: Text(columnLabel(column.id)),
                    trailing: Switch(
                      value: column.visible,
                      onChanged: (v) => onColumnVisibleChanged(column.id, v),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dim = Theme.of(context).textTheme.bodySmall?.color;
    final dragColor = Theme.of(context).textTheme.bodyMedium?.color;
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(
              context,
              Icons.dashboard_customize_outlined,
              l10n.customFieldsTitle,
              trailing: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.addCustomField),
                onPressed: onAddField,
              ),
            ),
            const SizedBox(height: 2),
            Text(l10n.customFieldsDescription,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (fields.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.noCustomFieldsYet,
                    style: TextStyle(color: dim)),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: fields.length,
                  onReorder: onFieldsReordered,
                  itemBuilder: (context, index) {
                    final field = fields[index];
                    final typeLabel = field.type == CustomFieldType.number
                        ? l10n.customFieldTypeNumber
                        : l10n.customFieldTypeText;
                    final placement = [
                      if (field.showInProjectsTable)
                        l10n.customFieldShowInProjectsTable,
                      if (field.showInReleaseTracks)
                        l10n.customFieldShowInReleaseTracks,
                    ];
                    return ListTile(
                      key: ValueKey('field-${field.id}'),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: Icon(Icons.drag_indicator, color: dragColor),
                      ),
                      title: Text(field.name),
                      subtitle: Text(
                        '$typeLabel · ${placement.isEmpty ? l10n.customFieldProjectPageOnly : placement.join(' · ')}',
                      ),
                      onTap: () => onEditField(field),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.table_rows_outlined,
                                color:
                                    field.showInProjectsTable ? primary : dim),
                            tooltip: l10n.customFieldShowInProjectsTable,
                            isSelected: field.showInProjectsTable,
                            onPressed: () => onFieldChanged(field.copyWith(
                                showInProjectsTable:
                                    !field.showInProjectsTable)),
                          ),
                          IconButton(
                            icon: Icon(Icons.album_outlined,
                                color:
                                    field.showInReleaseTracks ? primary : dim),
                            tooltip: l10n.customFieldShowInReleaseTracks,
                            isSelected: field.showInReleaseTracks,
                            onPressed: () => onFieldChanged(field.copyWith(
                                showInReleaseTracks:
                                    !field.showInReleaseTracks)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: l10n.editCustomField,
                            onPressed: () => onEditField(field),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade300,
                            tooltip: l10n.delete,
                            onPressed: () => onDeleteField(field),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
