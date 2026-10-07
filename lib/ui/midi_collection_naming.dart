import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip_naming.dart';
import '../models/midi_collection.dart';
import 'widgets/midi_clips_section.dart' show synthVoiceName;

/// What [role] is called in the UI and in file names.
String midiRoleName(AppLocalizations l10n, MidiClipRole role) => switch (role) {
  MidiClipRole.melody => l10n.midiRoleMelody,
  MidiClipRole.bass => l10n.midiRoleBass,
  MidiClipRole.chords => l10n.midiRoleChords,
  MidiClipRole.arp => l10n.midiRoleArp,
  MidiClipRole.lead => l10n.midiRoleLead,
  MidiClipRole.pad => l10n.midiRolePad,
  MidiClipRole.drums => l10n.midiRoleDrums,
  MidiClipRole.fx => l10n.midiRoleFx,
  MidiClipRole.other => l10n.midiRoleOther,
};

/// What a file name piece is called in the naming dialog.
String midiNameFieldLabel(AppLocalizations l10n, MidiNameField field) =>
    switch (field) {
      MidiNameField.name => l10n.midiNameFieldName,
      MidiNameField.role => l10n.midiRoleLabel,
      MidiNameField.bpm => l10n.midiNameFieldBpm,
      MidiNameField.key => l10n.midiNameFieldKey,
      MidiNameField.bars => l10n.midiNameFieldBars,
      MidiNameField.timeSignature => l10n.midiNameFieldTimeSignature,
      MidiNameField.grid => l10n.midiNameFieldGrid,
      MidiNameField.instrument => l10n.midiNameFieldInstrument,
    };

MidiNamingLabels midiNamingLabelsOf(AppLocalizations l10n) => MidiNamingLabels(
  roleName: (r) => midiRoleName(l10n, r),
  instrumentName: (v) => synthVoiceName(l10n, v),
  bars: l10n.midiClipBars,
  free: l10n.midiNameFree,
);

/// The separators the naming dialog offers.
const kMidiNameSeparators = [' - ', '_', ' '];

/// Edits a collection's [MidiNamingTemplate]: whether files are numbered,
/// which pieces their names carry and in what order, and the separator —
/// with an example name ([preview]) that follows every change.
class MidiNamingDialog extends StatefulWidget {
  const MidiNamingDialog({
    super.key,
    required this.initial,
    required this.preview,
  });

  final MidiNamingTemplate initial;

  /// A file name made with the template being edited, or null when there
  /// is no clip to show one for.
  final String? Function(MidiNamingTemplate template) preview;

  @override
  State<MidiNamingDialog> createState() => _MidiNamingDialogState();
}

class _MidiNamingDialogState extends State<MidiNamingDialog> {
  late bool _numbered;
  late String _separator;

  /// Every field: the template's, in its order, then the rest.
  late List<MidiNameField> _order;
  late Set<MidiNameField> _on;

  @override
  void initState() {
    super.initState();
    _load(widget.initial);
  }

  void _load(MidiNamingTemplate t) {
    _numbered = t.numbered;
    _separator = t.separator;
    _order = [
      ...t.fields,
      for (final f in MidiNameField.values)
        if (!t.fields.contains(f)) f,
    ];
    _on = t.fields.toSet();
  }

  MidiNamingTemplate get _template => MidiNamingTemplate(
    numbered: _numbered,
    separator: _separator,
    fields: [
      for (final f in _order)
        if (_on.contains(f)) f,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final example = widget.preview(_template);
    return AlertDialog(
      title: Text(l10n.midiNamingTitle),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (example != null) ...[
                Text(
                  l10n.midiNamingPreview,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    example,
                    key: const ValueKey('midi-naming-preview'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SwitchListTile(
                key: const ValueKey('midi-naming-numbered'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.midiNamingNumbered),
                subtitle: Text(l10n.midiNamingNumberedHint),
                value: _numbered,
                onChanged: (v) => setState(() => _numbered = v),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text(l10n.midiNamingSeparator)),
                  DropdownButton<String>(
                    key: const ValueKey('midi-naming-separator'),
                    value: kMidiNameSeparators.contains(_separator)
                        ? _separator
                        : kMidiNameSeparators.first,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final s in kMidiNameSeparators)
                        DropdownMenuItem(
                          value: s,
                          child: Text(
                            '${l10n.midiNameFieldName}$s${l10n.midiRoleBass}',
                          ),
                        ),
                    ],
                    onChanged: (s) {
                      if (s != null) setState(() => _separator = s);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(l10n.midiNamingFields, style: theme.textTheme.labelMedium),
              Text(l10n.midiNamingFieldsHint, style: theme.textTheme.bodySmall),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (from, to) => setState(() {
                  if (to > from) to--;
                  _order.insert(to, _order.removeAt(from));
                }),
                children: [
                  for (final (i, f) in _order.indexed)
                    CheckboxListTile(
                      key: ValueKey('midi-naming-field-${f.name}'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _on.contains(f),
                      title: Text(midiNameFieldLabel(l10n, f)),
                      secondary: ReorderableDragStartListener(
                        index: i,
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _on.add(f);
                        } else {
                          _on.remove(f);
                        }
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _load(MidiNamingTemplate.standard)),
          child: Text(l10n.midiNamingReset),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('midi-naming-save'),
          onPressed: () => Navigator.of(context).pop(_template),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// A folder as a picker lists it: indented by [depth].
typedef MidiFolderChoice = ({String id, String name, int depth});

List<MidiFolderChoice> midiFolderChoices(
  MidiCollection collection, {
  Set<String> exclude = const {},
}) => [
  for (final (:folder, :depth) in collection.folderTree())
    if (!exclude.contains(folder.id))
      (id: folder.id, name: folder.name, depth: depth),
];

/// What the user chose when saving a new clip.
class MidiSaveClipChoice {
  const MidiSaveClipChoice({required this.name, this.role, this.folderId});

  final String name;

  /// Null: suggested from the clip.
  final MidiClipRole? role;

  /// Null: the collection's top level.
  final String? folderId;
}

/// Saving a clip drawn from nothing into a collection: its name, its role
/// and its folder, with the file name it will export as ([fileNameOf])
/// following every change.
class MidiSaveClipDialog extends StatefulWidget {
  const MidiSaveClipDialog({
    super.key,
    required this.initialName,
    required this.suggestedRole,
    required this.folders,
    required this.fileNameOf,
    this.initialFolderId,
  });

  final String initialName;

  /// What "Automatic" means for this clip.
  final MidiClipRole suggestedRole;
  final List<MidiFolderChoice> folders;
  final String? initialFolderId;
  final String Function(MidiSaveClipChoice choice) fileNameOf;

  @override
  State<MidiSaveClipDialog> createState() => _MidiSaveClipDialogState();
}

class _MidiSaveClipDialogState extends State<MidiSaveClipDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  MidiClipRole? _role;
  late String? _folderId =
      widget.folders.any((f) => f.id == widget.initialFolderId)
      ? widget.initialFolderId
      : null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  MidiSaveClipChoice get _choice => MidiSaveClipChoice(
    name: _name.text.trim(),
    role: _role,
    folderId: _folderId,
  );

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(_choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.midiSaveClipTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('midi-save-clip-name'),
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.midiNameFieldName),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MidiClipRole?>(
              key: const ValueKey('midi-save-clip-role'),
              initialValue: _role,
              decoration: InputDecoration(labelText: l10n.midiRoleLabel),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    l10n.midiRoleAutomatic(
                      midiRoleName(l10n, widget.suggestedRole),
                    ),
                  ),
                ),
                for (final r in MidiClipRole.values)
                  DropdownMenuItem(
                    value: r,
                    child: Text(midiRoleName(l10n, r)),
                  ),
              ],
              onChanged: (r) => setState(() => _role = r),
            ),
            if (widget.folders.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const ValueKey('midi-save-clip-folder'),
                initialValue: _folderId,
                decoration: InputDecoration(labelText: l10n.midiFolderLabel),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.midiFolderTopLevel),
                  ),
                  for (final f in widget.folders)
                    DropdownMenuItem(
                      value: f.id,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.0 * f.depth),
                        child: Text(f.name),
                      ),
                    ),
                ],
                onChanged: (id) => setState(() => _folderId = id),
              ),
            ],
            const SizedBox(height: 16),
            Text(l10n.midiSaveFileName, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              widget.fileNameOf(_choice),
              key: const ValueKey('midi-save-clip-file-name'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
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
          key: const ValueKey('midi-save-clip-save'),
          onPressed: _name.text.trim().isEmpty ? null : _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Picks a role for a clip: one of [MidiClipRole], or automatic (the
/// record's role null) — which shows what it would suggest. Null when
/// dismissed.
Future<({MidiClipRole? role})?> pickMidiClipRole(
  BuildContext context, {
  required MidiClipRole? current,
  required MidiClipRole suggested,
}) {
  final l10n = AppLocalizations.of(context)!;
  Widget option(MidiClipRole? role, String label) => SimpleDialogOption(
    key: ValueKey('midi-role-${role?.name ?? 'auto'}'),
    onPressed: () => Navigator.of(context).pop((role: role)),
    child: Row(
      children: [
        Icon(
          current == role ? Icons.radio_button_checked : Icons.radio_button_off,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    ),
  );
  return showDialog<({MidiClipRole? role})>(
    context: context,
    builder: (_) => SimpleDialog(
      title: Text(l10n.midiRoleLabel),
      children: [
        option(null, l10n.midiRoleAutomatic(midiRoleName(l10n, suggested))),
        for (final r in MidiClipRole.values) option(r, midiRoleName(l10n, r)),
      ],
    ),
  );
}

/// Picks where to move something in [collection]: the top level or one of
/// its folders (minus [exclude] — a folder can't go inside itself). The
/// record's id is null for the top level; the result is null when
/// dismissed.
Future<({String? id})?> pickMidiFolder(
  BuildContext context,
  MidiCollection collection, {
  String? current,
  Set<String> exclude = const {},
}) {
  final l10n = AppLocalizations.of(context)!;
  Widget option(String? id, String name, int depth) => SimpleDialogOption(
    key: ValueKey('midi-folder-option-${id ?? 'top'}'),
    onPressed: () => Navigator.of(context).pop((id: id)),
    child: Padding(
      padding: EdgeInsets.only(left: 16.0 * depth),
      child: Row(
        children: [
          Icon(
            id == null ? Icons.library_music_outlined : Icons.folder_outlined,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: id == current
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
        ],
      ),
    ),
  );
  return showDialog<({String? id})>(
    context: context,
    builder: (_) => SimpleDialog(
      title: Text(l10n.midiMoveTo),
      children: [
        option(null, l10n.midiFolderTopLevel, 0),
        for (final f in midiFolderChoices(collection, exclude: exclude))
          option(f.id, f.name, f.depth + 1),
      ],
    ),
  );
}

/// One clip in [MidiBulkRenameDialog]: its name now and the one proposed.
class MidiRenameRow {
  const MidiRenameRow({
    required this.itemId,
    required this.current,
    required this.proposed,
    this.where = '',
  });

  final String itemId;
  final String current;
  final String proposed;

  /// Which folder it is in, to tell same-named clips apart ('' at the top).
  final String where;
}

/// Renames many clips at once from the naming scheme: each row shows the
/// clip's name now and a field holding the proposed one, to correct before
/// anything is renamed, and a tick to leave it out. Pops item id → new
/// name for the ticked rows that change, or null when cancelled.
class MidiBulkRenameDialog extends StatefulWidget {
  const MidiBulkRenameDialog({super.key, required this.rows});

  final List<MidiRenameRow> rows;

  @override
  State<MidiBulkRenameDialog> createState() => _MidiBulkRenameDialogState();
}

class _MidiBulkRenameDialogState extends State<MidiBulkRenameDialog> {
  late final List<TextEditingController> _names = [
    for (final r in widget.rows) TextEditingController(text: r.proposed),
  ];

  /// Ticked to start with: every clip the scheme would rename.
  late final List<bool> _on = [
    for (final r in widget.rows) r.proposed.trim() != r.current.trim(),
  ];

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _renames => {
    for (var i = 0; i < widget.rows.length; i++)
      if (_on[i] &&
          _names[i].text.trim().isNotEmpty &&
          _names[i].text.trim() != widget.rows[i].current.trim())
        widget.rows[i].itemId: _names[i].text.trim(),
  };

  bool? get _allState {
    if (_on.every((on) => on)) return true;
    if (_on.every((on) => !on)) return false;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final renames = _renames;
    return AlertDialog(
      title: Text(l10n.midiBulkRenameTitle),
      content: SizedBox(
        width: 640,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.midiBulkRenameHint, style: theme.textTheme.bodySmall),
            CheckboxListTile(
              key: const ValueKey('midi-bulk-rename-all'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              tristate: true,
              value: _allState,
              title: Text(l10n.midiBulkRenameSelectAll),
              onChanged: (_) => setState(() {
                final to = _allState != true;
                for (var i = 0; i < _on.length; i++) {
                  _on[i] = to;
                }
              }),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: widget.rows.length,
                itemBuilder: (context, i) {
                  final row = widget.rows[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          key: ValueKey('midi-bulk-rename-on-${row.itemId}'),
                          value: _on[i],
                          onChanged: (v) => setState(() => _on[i] = v ?? false),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                [
                                  row.where,
                                  row.current,
                                ].where((s) => s.isNotEmpty).join(' / '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                              TextField(
                                key: ValueKey(
                                  'midi-bulk-rename-name-${row.itemId}',
                                ),
                                controller: _names[i],
                                enabled: _on[i],
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('midi-bulk-rename-apply'),
          onPressed: renames.isEmpty
              ? null
              : () => Navigator.of(context).pop(renames),
          child: Text(l10n.midiBulkRenameApply(renames.length)),
        ),
      ],
    );
  }
}

/// Confirms deleting [folder]; what is inside it moves up, so nothing but
/// the folder goes.
Future<bool> confirmDeleteMidiFolder(
  BuildContext context,
  MidiCollectionFolder folder,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.midiFolderDelete),
      content: Text(l10n.midiFolderDeleteConfirm(folder.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}
