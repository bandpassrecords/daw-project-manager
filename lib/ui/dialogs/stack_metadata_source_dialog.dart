import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';

/// The projects whose metadata a new stack could inherit, if the user has to
/// be asked at all (#94).
///
/// Stacking promotes exactly one member's metadata onto the stack and leaves
/// every other member's untouched — nothing is merged, so there is no way for
/// two versions' details to be mangled together. What *can* go unnoticed is
/// the promotion picking a version the user did not expect, so the choice is
/// only worth surfacing when more than one version actually has details to
/// promote. With zero or one, the answer is forced and the dialog would be
/// pure friction.
List<MusicProject> stackMetadataSourceCandidates(
  List<MusicProject> members,
) {
  final withMetadata = members.where((m) => m.hasUserMetadata).toList();
  return withMetadata.length >= 2 ? withMetadata : const [];
}

/// The member promoted to *main project* when the user isn't asked: the
/// oldest, because with `v1 → v2 → v3` the details someone has been
/// maintaining sit on the one they started from.
MusicProject defaultStackMetadataSource(List<MusicProject> members) =>
    (members.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
        .first;

/// Asks which member's metadata the new stack should inherit. Returns the
/// chosen project, or null if the user cancelled.
Future<MusicProject?> showStackMetadataSourceDialog(
  BuildContext context, {
  required List<MusicProject> candidates,
  required MusicProject suggested,
  required String Function(MusicProject project) summaryBuilder,
}) {
  return showDialog<MusicProject>(
    context: context,
    builder: (_) => _StackMetadataSourceDialog(
      candidates: candidates,
      suggested: suggested,
      summaryBuilder: summaryBuilder,
    ),
  );
}

class _StackMetadataSourceDialog extends StatefulWidget {
  const _StackMetadataSourceDialog({
    required this.candidates,
    required this.suggested,
    required this.summaryBuilder,
  });

  final List<MusicProject> candidates;
  final MusicProject suggested;
  final String Function(MusicProject project) summaryBuilder;

  @override
  State<_StackMetadataSourceDialog> createState() =>
      _StackMetadataSourceDialogState();
}

class _StackMetadataSourceDialogState
    extends State<_StackMetadataSourceDialog> {
  late String _selectedId = widget.suggested.id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(l10n.stackMetadataSourceTitle),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.stackMetadataSourceBody,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final project in widget.candidates)
                      RadioListTile<String>(
                        value: project.id,
                        // ignore: deprecated_member_use
                        groupValue: _selectedId,
                        // ignore: deprecated_member_use
                        onChanged: (id) =>
                            setState(() => _selectedId = id ?? _selectedId),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          project.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.summaryBuilder(project),
                              style: theme.textTheme.bodySmall,
                            ),
                            if (project.id == widget.suggested.id)
                              Text(
                                l10n.stackMetadataSourceOldestHint,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
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
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(
            widget.candidates.firstWhere((p) => p.id == _selectedId),
          ),
          child: Text(l10n.stackAsVersions),
        ),
      ],
    );
  }
}
