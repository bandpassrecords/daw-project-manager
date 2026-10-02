import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/custom_field.dart';
import '../../utils/custom_fields.dart';

/// Adds a custom field ([existing] null) or edits one. Returns the field to
/// save, or null when cancelled. [active] is every live field, for the
/// duplicate-name check.
///
/// The caller stores the result through `customFieldDefinitionsProvider`,
/// which stamps `updatedAt` and, for a new field, its position.
Future<CustomFieldDefinition?> showCustomFieldDialog(
  BuildContext context, {
  CustomFieldDefinition? existing,
  required List<CustomFieldDefinition> active,
}) {
  return showDialog<CustomFieldDefinition>(
    context: context,
    builder: (_) => CustomFieldDialog(existing: existing, active: active),
  );
}

class CustomFieldDialog extends StatefulWidget {
  const CustomFieldDialog({super.key, this.existing, required this.active});

  final CustomFieldDefinition? existing;
  final List<CustomFieldDefinition> active;

  @override
  State<CustomFieldDialog> createState() => _CustomFieldDialogState();
}

class _CustomFieldDialogState extends State<CustomFieldDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late CustomFieldType _type = widget.existing?.type ?? CustomFieldType.text;
  late bool _inTable = widget.existing?.showInProjectsTable ?? true;
  late bool _inRelease = widget.existing?.showInReleaseTracks ?? false;

  /// Only shown once the user has tried to save, so an empty field doesn't
  /// open with an error under it.
  bool _showErrors = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  CustomFieldNameProblem? get _problem => validateCustomFieldName(
        _name.text,
        widget.active,
        ownId: widget.existing?.id,
      );

  void _submit() {
    if (_problem != null) {
      setState(() => _showErrors = true);
      return;
    }
    final name = _name.text.trim();
    final existing = widget.existing;
    Navigator.of(context).pop(
      existing == null
          ? CustomFieldDefinition(
              id: const Uuid().v4(),
              name: name,
              type: _type,
              showInProjectsTable: _inTable,
              showInReleaseTracks: _inRelease,
            )
          : existing.copyWith(
              name: name,
              type: _type,
              showInProjectsTable: _inTable,
              showInReleaseTracks: _inRelease,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final problem = _showErrors ? _problem : null;
    return AlertDialog(
      title: Text(
          widget.existing == null ? l10n.addCustomField : l10n.editCustomField),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.customFieldName,
                hintText: l10n.customFieldNameHint,
                errorText: switch (problem) {
                  CustomFieldNameProblem.empty => l10n.customFieldNameRequired,
                  CustomFieldNameProblem.duplicate =>
                    l10n.customFieldNameDuplicate,
                  null => null,
                },
              ),
              onChanged: (_) {
                if (_showErrors) setState(() {});
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(l10n.customFieldType,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<CustomFieldType>(
              segments: [
                ButtonSegment(
                  value: CustomFieldType.text,
                  icon: const Icon(Icons.short_text),
                  label: Text(l10n.customFieldTypeText),
                ),
                ButtonSegment(
                  value: CustomFieldType.number,
                  icon: const Icon(Icons.numbers),
                  label: Text(l10n.customFieldTypeNumber),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            if (_type == CustomFieldType.number) ...[
              const SizedBox(height: 6),
              Text(l10n.customFieldTypeNumberHelp,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _inTable,
              title: Text(l10n.customFieldShowInProjectsTable),
              onChanged: (v) => setState(() => _inTable = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _inRelease,
              title: Text(l10n.customFieldShowInReleaseTracks),
              onChanged: (v) => setState(() => _inRelease = v ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
