import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';

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
}) {
  return showDialog<MusicProject>(
    context: context,
    builder: (_) => _StackVersionPickerDialog(
      title: title,
      candidates: candidates,
      emptyLabel: emptyLabel,
      subtitleBuilder: subtitleBuilder,
    ),
  );
}

class _StackVersionPickerDialog extends StatelessWidget {
  const _StackVersionPickerDialog({
    required this.title,
    required this.candidates,
    required this.emptyLabel,
    this.subtitleBuilder,
  });

  final String title;
  final List<MusicProject> candidates;
  final String emptyLabel;
  final String Function(MusicProject project)? subtitleBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: candidates.isEmpty
            ? Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      itemBuilder: (context, i) {
                        final project = candidates[i];
                        final subtitle = subtitleBuilder?.call(project);
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
                                  style: Theme.of(context).textTheme.bodySmall,
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
