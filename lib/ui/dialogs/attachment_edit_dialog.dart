import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/project_attachment.dart';

/// Adds a link, or edits any existing attachment (#112).
///
/// Returns the new/updated [ProjectAttachment], or null when the user cancels.
/// One dialog for both jobs because the fields are the same either way — only
/// the title and whether the target starts empty differ; a file added through
/// the picker skips it entirely and lands in the list straight away.
Future<ProjectAttachment?> showAttachmentEditDialog(
  BuildContext context, {
  ProjectAttachment? existing,
  ProjectAttachmentKind kind = ProjectAttachmentKind.link,
}) {
  return showDialog<ProjectAttachment>(
    context: context,
    builder: (_) => _AttachmentEditDialog(
      existing: existing,
      kind: existing?.kind ?? kind,
    ),
  );
}

class _AttachmentEditDialog extends StatefulWidget {
  const _AttachmentEditDialog({required this.existing, required this.kind});

  final ProjectAttachment? existing;
  final ProjectAttachmentKind kind;

  @override
  State<_AttachmentEditDialog> createState() => _AttachmentEditDialogState();
}

class _AttachmentEditDialogState extends State<_AttachmentEditDialog> {
  static const _uuid = Uuid();

  late final _targetCtrl =
      TextEditingController(text: widget.existing?.target ?? '');
  late final _labelCtrl =
      TextEditingController(text: widget.existing?.label ?? '');
  late final _noteCtrl =
      TextEditingController(text: widget.existing?.note ?? '');

  String? _targetError;

  bool get _isLink => widget.kind == ProjectAttachmentKind.link;

  @override
  void dispose() {
    _targetCtrl.dispose();
    _labelCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final rawTarget = _targetCtrl.text.trim();

    if (rawTarget.isEmpty) {
      setState(() => _targetError =
          _isLink ? l10n.attachmentUrlInvalid : l10n.attachmentPathRequired);
      return;
    }
    if (_isLink && !ProjectAttachment.looksLikeUrl(rawTarget)) {
      setState(() => _targetError = l10n.attachmentUrlInvalid);
      return;
    }

    final target =
        _isLink ? ProjectAttachment.normalizeUrl(rawTarget) : rawTarget;
    final note = _noteCtrl.text.trim();
    final existing = widget.existing;

    Navigator.of(context).pop(
      existing == null
          ? ProjectAttachment(
              id: _uuid.v4(),
              kind: widget.kind,
              target: target,
              label: _labelCtrl.text.trim(),
              addedAt: DateTime.now(),
              note: note.isEmpty ? null : note,
            )
          : existing.copyWith(
              target: target,
              label: _labelCtrl.text.trim(),
              note: note.isEmpty ? null : note,
              clearNote: note.isEmpty,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? l10n.attachmentEditDialogTitle
            : (_isLink ? l10n.attachmentAddLink : l10n.attachmentAddFile),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _targetCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText:
                    _isLink ? l10n.attachmentUrlLabel : l10n.attachmentPathLabel,
                errorText: _targetError,
                prefixIcon: Icon(_isLink ? Icons.link : Icons.folder_outlined),
              ),
              onChanged: (_) {
                if (_targetError != null) setState(() => _targetError = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              decoration:
                  InputDecoration(labelText: l10n.attachmentLabelLabel),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.attachmentNoteLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
