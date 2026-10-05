import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/custom_field.dart';
import '../../utils/custom_fields.dart';

/// Settings > Columns & fields: which columns the projects table and release
/// tracklists show — every field, built-in or custom, can be switched on in
/// either, independently — in what order, and the user's custom fields.
///
/// Both lists are a grid: a row per field with a checkbox per table, under
/// a header naming the tables, and every other row shaded so a checkbox is
/// easy to tie to its field across a wide page.
///
/// Plain values and callbacks — no `Ref`, no Hive — so it can be
/// widget-tested; the settings page wires it to the providers.
class ColumnsAndFieldsSettings extends StatelessWidget {
  const ColumnsAndFieldsSettings({
    super.key,
    required this.columns,
    required this.columnLabel,
    required this.onColumnVisibleChanged,
    required this.onColumnInReleaseTracksChanged,
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

  /// Shown in the projects table.
  final void Function(String columnId, bool visible) onColumnVisibleChanged;

  /// Shown in release tracklists.
  final void Function(String columnId, bool shown)
      onColumnInReleaseTracksChanged;
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

  /// Width of each table's checkbox column, header included.
  static const double tableColumnWidth = 84;

  /// Width of the edit and delete buttons at the end of a custom field's row.
  static const double _actionsWidth = 96;

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

  /// The labels over the checkbox columns: "Projects", "Release tracks".
  Widget _tablesHeader(BuildContext context, {double trailing = 0}) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        );
    Widget label(String text) => SizedBox(
          width: tableColumnWidth,
          child: Text(text,
              textAlign: TextAlign.center, style: style, maxLines: 2),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          const Spacer(),
          label(l10n.columnsInProjectsTable),
          label(l10n.columnsInReleaseTracks),
          SizedBox(width: trailing),
        ],
      ),
    );
  }

  /// One table's checkbox, centred under its header.
  Widget _tableCheckbox({
    required Key key,
    required bool value,
    required String tooltip,
    required ValueChanged<bool> onChanged,
  }) =>
      SizedBox(
        width: tableColumnWidth,
        child: Center(
          child: Tooltip(
            message: tooltip,
            child: Checkbox(
              key: key,
              value: value,
              onChanged: (v) => onChanged(v ?? false),
            ),
          ),
        ),
      );

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tablesHeader(context),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: columns.length,
                    onReorder: onColumnsReordered,
                    itemBuilder: (context, index) {
                      final column = columns[index];
                      return StripedRow(
                        key: ValueKey('column-${column.id}'),
                        index: index,
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(Icons.drag_indicator,
                                    color: dragColor),
                              ),
                            ),
                            Expanded(child: Text(columnLabel(column.id))),
                            _tableCheckbox(
                              key: ValueKey('column-${column.id}-projects'),
                              value: column.visible,
                              tooltip: l10n.customFieldShowInProjectsTable,
                              onChanged: (v) =>
                                  onColumnVisibleChanged(column.id, v),
                            ),
                            _tableCheckbox(
                              key: ValueKey('column-${column.id}-tracks'),
                              value: column.inReleaseTracks,
                              tooltip: l10n.customFieldShowInReleaseTracks,
                              onChanged: (v) =>
                                  onColumnInReleaseTracksChanged(column.id, v),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      );
                    },
                  ),
                ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _tablesHeader(context, trailing: _actionsWidth),
                    ReorderableListView.builder(
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
                        final nowhere = !field.showInProjectsTable &&
                            !field.showInReleaseTracks;
                        return StripedRow(
                          key: ValueKey('field-${field.id}'),
                          index: index,
                          onTap: () => onEditField(field),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(Icons.drag_indicator,
                                      color: dragColor),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(field.name),
                                    Text(
                                      nowhere
                                          ? '$typeLabel · ${l10n.customFieldProjectPageOnly}'
                                          : typeLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              _tableCheckbox(
                                key: ValueKey('field-${field.id}-projects'),
                                value: field.showInProjectsTable,
                                tooltip: l10n.customFieldShowInProjectsTable,
                                onChanged: (v) => onFieldChanged(
                                    field.copyWith(showInProjectsTable: v)),
                              ),
                              _tableCheckbox(
                                key: ValueKey('field-${field.id}-tracks'),
                                value: field.showInReleaseTracks,
                                tooltip: l10n.customFieldShowInReleaseTracks,
                                onChanged: (v) => onFieldChanged(
                                    field.copyWith(showInReleaseTracks: v)),
                              ),
                              SizedBox(
                                width: _actionsWidth,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
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
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A list row shaded on every other line ([index] odd), so a control at the
/// far end of a wide row is easy to tie to the label it belongs to.
class StripedRow extends StatelessWidget {
  const StripedRow({
    super.key,
    required this.index,
    required this.child,
    this.onTap,
  });

  final int index;
  final Widget child;
  final VoidCallback? onTap;

  /// The shade of the striped rows, from the theme so it works on any of
  /// them.
  static Color stripeColor(ThemeData theme) =>
      theme.colorScheme.onSurface.withValues(alpha: 0.06);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: index.isOdd ? stripeColor(theme) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: child,
        ),
      ),
    );
  }
}
