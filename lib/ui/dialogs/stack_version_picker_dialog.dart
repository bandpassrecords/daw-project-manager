import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../utils/search_utils.dart';

/// Filters [candidates] down to those matching [query], across the name and
/// the file path.
///
/// The path is searched too because versions of a project are usually named
/// almost identically ("Track v1", "Track v2"), so the folder is often the
/// only thing that tells two candidates apart — and typing the folder name is
/// the natural way to find every version of one project at once.
///
/// An empty or whitespace-only query returns everything rather than nothing.
@visibleForTesting
List<MusicProject> filterStackCandidates(
  List<MusicProject> candidates,
  String query,
) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return candidates;
  return [
    for (final project in candidates)
      if (fuzzyMatchAny([project.displayName, project.filePath], trimmed))
        project,
  ];
}

/// Picks one project out of [candidates]. Returns the chosen project, or null
/// on Cancel / barrier dismiss.
///
/// Used when exactly one answer makes sense — choosing which version of a
/// stack to open in the DAW. For adding versions, see
/// [showStackVersionMultiPickerDialog].
Future<MusicProject?> showStackVersionPickerDialog(
  BuildContext context, {
  required String title,
  required List<MusicProject> candidates,
  required String emptyLabel,
  String Function(MusicProject project)? subtitleBuilder,
  bool searchable = false,
}) async {
  final chosen = await showDialog<List<MusicProject>>(
    context: context,
    builder: (_) => _StackVersionPickerDialog(
      title: title,
      candidates: candidates,
      emptyLabel: emptyLabel,
      subtitleBuilder: subtitleBuilder,
      searchable: searchable,
      multiSelect: false,
    ),
  );
  return (chosen == null || chosen.isEmpty) ? null : chosen.first;
}

/// Picks any number of projects out of [candidates]. Returns the chosen
/// projects, or an empty list on Cancel / barrier dismiss.
///
/// Adding versions is naturally a bulk action — a project that has five
/// revision files needs all four siblings attached, and doing that one dialog
/// at a time is four times the work for no benefit.
Future<List<MusicProject>> showStackVersionMultiPickerDialog(
  BuildContext context, {
  required String title,
  required List<MusicProject> candidates,
  required String emptyLabel,
  String Function(MusicProject project)? subtitleBuilder,
}) async {
  final chosen = await showDialog<List<MusicProject>>(
    context: context,
    builder: (_) => _StackVersionPickerDialog(
      title: title,
      candidates: candidates,
      emptyLabel: emptyLabel,
      subtitleBuilder: subtitleBuilder,
      searchable: true,
      multiSelect: true,
    ),
  );
  return chosen ?? const [];
}

class _StackVersionPickerDialog extends StatefulWidget {
  const _StackVersionPickerDialog({
    required this.title,
    required this.candidates,
    required this.emptyLabel,
    required this.searchable,
    required this.multiSelect,
    this.subtitleBuilder,
  });

  final String title;
  final List<MusicProject> candidates;
  final String emptyLabel;

  /// Whether to show the search field. On where the list can be the whole
  /// library (adding versions); off for a stack's own handful of versions.
  final bool searchable;

  /// Tick-boxes and a confirm button rather than tap-to-choose.
  final bool multiSelect;

  final String Function(MusicProject project)? subtitleBuilder;

  @override
  State<_StackVersionPickerDialog> createState() =>
      _StackVersionPickerDialogState();
}

class _StackVersionPickerDialogState extends State<_StackVersionPickerDialog> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _selectedIds = <String>{};
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggle(MusicProject project) => setState(() {
    if (!_selectedIds.remove(project.id)) _selectedIds.add(project.id);
  });

  /// The chosen projects, in the order [widget.candidates] lists them rather
  /// than the order they were ticked — the caller sorted that list, and the
  /// versions should land on the stack in the same order they were shown.
  List<MusicProject> get _selected => [
    for (final project in widget.candidates)
      if (_selectedIds.contains(project.id)) project,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final visible = filterStackCandidates(widget.candidates, _query);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: widget.candidates.isEmpty
            ? Text(widget.emptyLabel, style: theme.textTheme.bodySmall)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.searchable) ...[
                    TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      autofocus: true,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        hintText: l10n.stackSearchProjects,
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                  _searchFocus.requestFocus();
                                },
                              ),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // "Select all" applies to what the search is currently
                  // showing, not the whole library — searching then selecting
                  // everything found is the point of pairing the two.
                  if (widget.multiSelect && visible.isNotEmpty)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setState(
                            () => _selectedIds.addAll(visible.map((p) => p.id)),
                          ),
                          child: Text(l10n.stackSelectAll),
                        ),
                        if (_selectedIds.isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                setState(_selectedIds.clear),
                            child: Text(l10n.stackClearSelection),
                          ),
                      ],
                    ),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l10n.stackSearchNoMatches,
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final project = visible[i];
                          final subtitle = widget.subtitleBuilder?.call(
                            project,
                          );
                          final subtitleWidget = subtitle == null
                              ? null
                              : Text(
                                  subtitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                );
                          final title = Text(
                            project.displayName,
                            overflow: TextOverflow.ellipsis,
                          );

                          if (widget.multiSelect) {
                            return CheckboxListTile(
                              value: _selectedIds.contains(project.id),
                              onChanged: (_) => _toggle(project),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              title: title,
                              subtitle: subtitleWidget,
                            );
                          }
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const Icon(Icons.music_note, size: 20),
                            title: title,
                            subtitle: subtitleWidget,
                            onTap: () =>
                                Navigator.of(context).pop([project]),
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
        if (widget.multiSelect)
          ElevatedButton(
            // Nothing ticked means nothing to add, so the button stays
            // disabled rather than closing on a no-op.
            onPressed: _selectedIds.isEmpty
                ? null
                : () => Navigator.of(context).pop(_selected),
            child: Text(l10n.stackAddVersionsConfirm(_selectedIds.length)),
          ),
      ],
    );
  }
}
