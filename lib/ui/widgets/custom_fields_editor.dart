import 'dart:async';

import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/custom_field.dart';
import '../../utils/custom_fields.dart';

/// One input per custom field, on the project detail page — the place a
/// field can always be filled in, whether or not it also has a column.
///
/// Plain values and a callback, no `Ref`: the page stores what
/// [onChanged] reports. Saves a moment after typing stops and again when a
/// field loses focus. A number field holding something that isn't a number
/// shows an error and is not saved, so a half-typed "-1" on its way to "-14"
/// is never stored as garbage.
///
/// An incoming [values] change (a sync, another window) replaces a field's
/// text only while that field is not being edited.
class CustomFieldsEditor extends StatefulWidget {
  const CustomFieldsEditor({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 400),
  });

  /// Active fields, in order.
  final List<CustomFieldDefinition> fields;

  /// The project's stored values, keyed by field id.
  final Map<String, String> values;

  /// Called with the field id and the text to store ('' clears it).
  final void Function(String fieldId, String value) onChanged;

  final Duration debounce;

  @override
  State<CustomFieldsEditor> createState() => _CustomFieldsEditorState();
}

class _CustomFieldsEditorState extends State<CustomFieldsEditor> {
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};
  final _timers = <String, Timer>{};

  /// What was last stored (or last seen stored) per field — a controller
  /// still showing this has no unsaved typing and may follow [values].
  final _lastStored = <String, String>{};

  @override
  void initState() {
    super.initState();
    _syncFields();
  }

  @override
  void didUpdateWidget(CustomFieldsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFields();
  }

  void _syncFields() {
    for (final field in widget.fields) {
      final stored = widget.values[field.id] ?? '';
      final controller = _controllers[field.id];
      if (controller == null) {
        _controllers[field.id] = TextEditingController(text: stored);
        _lastStored[field.id] = stored;
        final node = FocusNode();
        node.addListener(() {
          if (!node.hasFocus) _commit(field.id);
        });
        _focusNodes[field.id] = node;
        continue;
      }
      final editing = _focusNodes[field.id]!.hasFocus ||
          controller.text != _lastStored[field.id];
      if (!editing && controller.text != stored) {
        controller.text = stored;
      }
      if (!editing) _lastStored[field.id] = stored;
    }
  }

  CustomFieldDefinition? _field(String id) {
    for (final f in widget.fields) {
      if (f.id == id) return f;
    }
    return null;
  }

  void _commit(String fieldId) {
    _timers.remove(fieldId)?.cancel();
    final field = _field(fieldId);
    final controller = _controllers[fieldId];
    if (field == null || controller == null) return;
    final text = controller.text.trim();
    if (!isValidCustomFieldValue(field.type, text)) return;
    if (text == (_lastStored[fieldId] ?? '').trim()) return;
    _lastStored[fieldId] = controller.text;
    widget.onChanged(fieldId, text);
  }

  void _scheduleCommit(String fieldId) {
    _timers.remove(fieldId)?.cancel();
    _timers[fieldId] = Timer(widget.debounce, () => _commit(fieldId));
  }

  @override
  void dispose() {
    // Flush anything still waiting on its debounce rather than dropping it.
    for (final id in _timers.keys.toList()) {
      _commit(id);
    }
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final n in _focusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(builder: (context, constraints) {
      // Side by side on a wide page, one per row on a phone.
      final width = constraints.maxWidth < 520 ? constraints.maxWidth : 240.0;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final field in widget.fields)
            SizedBox(
              width: width,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controllers[field.id]!,
                builder: (context, value, _) {
                  final valid =
                      isValidCustomFieldValue(field.type, value.text);
                  return TextField(
                    key: ValueKey('custom-field-${field.id}'),
                    controller: _controllers[field.id],
                    focusNode: _focusNodes[field.id],
                    keyboardType: field.type == CustomFieldType.number
                        ? const TextInputType.numberWithOptions(
                            signed: true, decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: field.name,
                      errorText: valid ? null : l10n.customFieldInvalidNumber,
                    ),
                    onChanged: (_) => _scheduleCommit(field.id),
                    onSubmitted: (_) => _commit(field.id),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}
