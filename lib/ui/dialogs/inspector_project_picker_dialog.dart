import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../services/project_inspector/library/project_choices.dart';

/// What [InspectorProjectPickerDialog] chose: a project's file, or a file
/// dialog for one outside the library.
class InspectorPick {
  const InspectorPick(String this.path);
  const InspectorPick.browse() : path = null;

  final String? path;
  bool get browse => path == null;
}

/// The Inspector's Open project… and Compare with…: the library's projects
/// to pick from, searchable — the open project's versions first when
/// comparing — and "Browse files…" for anything else.
class InspectorProjectPickerDialog extends StatefulWidget {
  const InspectorProjectPickerDialog({
    super.key,
    required this.title,
    required this.choices,
  });

  final String title;
  final InspectorProjectChoices choices;

  @override
  State<InspectorProjectPickerDialog> createState() =>
      _InspectorProjectPickerDialogState();
}

class _InspectorProjectPickerDialogState
    extends State<InspectorProjectPickerDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final versions = widget.choices.versions
        .where((pr) => matchesInspectorSearch(pr, _search))
        .toList();
    final others = widget.choices.others
        .where((pr) => matchesInspectorSearch(pr, _search))
        .toList();
    // Headings only when there are two lists to tell apart.
    final headed = widget.choices.versions.isNotEmpty;
    final rows = <Object>[
      if (headed && versions.isNotEmpty) l10n.inspectorPickVersions,
      ...versions,
      if (headed && others.isNotEmpty) l10n.inspectorPickLibrary,
      ...others,
    ];
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 560,
        height: 480,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.inspectorPickSearch,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: rows.isEmpty
                  ? Center(child: Text(l10n.inspectorPickNone))
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        if (row is String) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                            child: Text(
                              row,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }
                        final pr = row as MusicProject;
                        return ListTile(
                          dense: true,
                          title: Text(
                            pr.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              if (pr.dawType != null) pr.dawType!,
                              p.dirname(pr.filePath),
                            ].join(' · '),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            date.format(pr.lastModifiedAt),
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () => Navigator.pop(
                            context,
                            InspectorPick(pr.filePath),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, const InspectorPick.browse()),
          icon: const Icon(Icons.folder_open),
          label: Text(l10n.inspectorPickBrowse),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
