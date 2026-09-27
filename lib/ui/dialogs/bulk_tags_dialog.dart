import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../widgets/project_tags_editor.dart';

/// What the bulk tag dialog asked for: put [tag] on every selected project,
/// or take it off every one that has it.
typedef BulkTagChange = ({String tag, bool add});

/// Adds a tag to, or removes one from, every selected project at once (#109).
///
/// One change per visit, and it applies as soon as it is chosen: typing a tag
/// and pressing Enter adds it, clicking × on a tag removes it. Returns null
/// when the user cancels. The caller canonicalizes and writes — the dialog
/// only reports what was picked.
///
/// [suggestions] is every tag in the library, for autocomplete; [removable]
/// is the tags present on at least one selected project, the only ones worth
/// offering to remove.
Future<BulkTagChange?> showBulkTagsDialog(
  BuildContext context, {
  required int projectCount,
  required List<String> suggestions,
  required List<String> removable,
}) {
  return showDialog<BulkTagChange>(
    context: context,
    builder: (_) => BulkTagsDialog(
      projectCount: projectCount,
      suggestions: suggestions,
      removable: removable,
    ),
  );
}

class BulkTagsDialog extends StatelessWidget {
  const BulkTagsDialog({
    super.key,
    required this.projectCount,
    required this.suggestions,
    required this.removable,
  });

  final int projectCount;
  final List<String> suggestions;
  final List<String> removable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return AlertDialog(
      title: Text(l10n.bulkTagsTitle(projectCount)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.bulkTagsAddLabel, style: labelStyle),
            const SizedBox(height: 8),
            // The editor with no chips of its own is exactly "a field that
            // adds a tag, with autocomplete". Nothing is excluded from the
            // suggestions: a tag some selected projects already have is
            // still a valid one to give the rest.
            ProjectTagsEditor(
              tags: const [],
              suggestions: suggestions,
              hintText: l10n.addTagHint,
              removeTooltip: l10n.removeTagTooltip,
              onAdd: (tag) =>
                  Navigator.of(context).pop<BulkTagChange>((tag: tag, add: true)),
              onRemove: (_) {},
            ),
            const SizedBox(height: 20),
            Text(l10n.bulkTagsRemoveLabel, style: labelStyle),
            const SizedBox(height: 8),
            if (removable.isEmpty)
              Text(
                l10n.bulkTagsNoneToRemove,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in removable)
                    InputChip(
                      key: ValueKey('bulk-remove-$tag'),
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      deleteButtonTooltipMessage: l10n.removeTagTooltip(tag),
                      onDeleted: () => Navigator.of(context)
                          .pop<BulkTagChange>((tag: tag, add: false)),
                    ),
                ],
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
