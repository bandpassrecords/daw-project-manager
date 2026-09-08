import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../utils/search_utils.dart';

/// Filters [candidates] down to those matching [query], across the name and
/// the file path.
///
/// The path is searched too because versions of a song are usually named
/// almost identically ("Track v1", "Track v2"), so the folder is often the
/// only thing that tells two candidates apart — and typing the folder name is
/// the natural way to find every version of one song at once.
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
/// Used for both sides of stack membership: choosing a standalone project to
/// pull into a stack, and choosing which version of a stack to open in the DAW
/// when no default has been nominated. Both are "same list, same rows, one
/// answer", so they share a dialog rather than duplicating one.
Future<MusicProject?> showStackVersionPickerDialog(
  BuildContext context, {
  required String title,
  required List<MusicProject> candidates,
  required String emptyLabel,
  String Function(MusicProject project)? subtitleBuilder,
  bool searchable = false,
}) {
  return showDialog<MusicProject>(
    context: context,
    builder: (_) => _StackVersionPickerDialog(
      title: title,
      candidates: candidates,
      emptyLabel: emptyLabel,
      subtitleBuilder: subtitleBuilder,
      searchable: searchable,
    ),
  );
}

class _StackVersionPickerDialog extends StatefulWidget {
  const _StackVersionPickerDialog({
    required this.title,
    required this.candidates,
    required this.emptyLabel,
    required this.searchable,
    this.subtitleBuilder,
  });

  final String title;
  final List<MusicProject> candidates;
  final String emptyLabel;

  /// Whether to show the search field. On by default only where the list can
  /// be the whole library (adding a version); a stack's own handful of
  /// versions doesn't need one.
  final bool searchable;

  final String Function(MusicProject project)? subtitleBuilder;

  @override
  State<_StackVersionPickerDialog> createState() =>
      _StackVersionPickerDialogState();
}

class _StackVersionPickerDialogState extends State<_StackVersionPickerDialog> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

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
                    const SizedBox(height: 12),
                  ],
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
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const Icon(Icons.music_note, size: 20),
                            title: Text(
                              project.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: subtitle == null
                                ? null
                                : Text(
                                    subtitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                            onTap: () => Navigator.of(context).pop(project),
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
      ],
    );
  }
}
