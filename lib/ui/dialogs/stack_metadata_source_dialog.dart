import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../utils/version_stacks.dart';
import '../widgets/project_cover_avatar.dart';

/// The projects whose metadata a new stack could inherit, if the user has to
/// be asked at all (#94).
///
/// Stacking promotes exactly one member's metadata onto the stack and leaves
/// every other member's untouched — nothing is merged, so there is no way for
/// two versions' details to be mangled together. What *can* go unnoticed is
/// the promotion picking a version the user did not expect, so the choice is
/// only worth surfacing when more than one version actually has something to
/// promote — details or a look of its own (cover art, colour, icon). With zero
/// or one, the answer is forced and the dialog would be pure friction.
List<MusicProject> stackMetadataSourceCandidates(
  List<MusicProject> members,
) {
  final withSomething =
      members.where((m) => m.hasSomethingToPromote).toList();
  return withSomething.length >= 2 ? withSomething : const [];
}

/// The member promoted to *main project* when the user isn't asked — see
/// [preferredStackMetadataSource], which automatic folder stacking uses too.
MusicProject defaultStackMetadataSource(List<MusicProject> members) =>
    preferredStackMetadataSource(members);

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
                        // Its cover, colour or icon, so choosing between two
                        // versions' looks is a choice the user can see.
                        // Renders nothing for a version without one.
                        secondary: ProjectCoverAvatar(
                          project: project,
                          size: 36,
                        ),
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
