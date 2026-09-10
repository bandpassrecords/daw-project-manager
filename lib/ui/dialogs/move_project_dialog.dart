import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../providers/providers.dart';
import '../../services/project_move_service.dart';
import '../../utils/project_folder_utils.dart';

/// The user-facing message for a refused move.
///
/// Kept as a plain switch rather than a field on the exception so the service
/// stays free of `AppLocalizations` and can be tested without a widget tree.
String moveErrorMessage(AppLocalizations l10n, ProjectMoveException e) {
  switch (e.reason) {
    case ProjectMoveError.sourceMissing:
      return l10n.moveProjectErrorSourceMissing;
    case ProjectMoveError.destinationOccupied:
      return l10n.moveProjectErrorDestinationOccupied(p.basename(e.path));
    case ProjectMoveError.destinationInsideSource:
      return l10n.moveProjectErrorDestinationInsideSource;
    case ProjectMoveError.sameLocation:
      return l10n.moveProjectErrorSameLocation;
  }
}

/// Moves one project's file (and optionally its whole containing folder) to a
/// folder the user picks, rewriting its stored paths so the metadata follows
/// (#88).
///
/// Returns true when the project actually moved.
Future<bool> showMoveProjectDialog(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  // A stack is a virtual row whose filePath is a folder it only synthesized —
  // there is nothing on disk to move, and moving its members would silently
  // re-parent the stack. Versions are moved individually instead.
  if (project.isVirtual) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.moveProjectStackUnsupported),
      ),
    );
    return false;
  }

  final allPaths = ref
      .read(allProjectsStreamProvider)
      .value
      ?.where((e) => !e.isVirtual)
      .map((e) => e.filePath)
      .toList(growable: false);

  final moved = await showDialog<MusicProject>(
    context: context,
    builder: (_) => _MoveProjectDialog(
      project: project,
      // Offering "move the whole folder" when the folder holds other projects
      // would move those too, without ever naming them.
      canMoveFolder: folderIsDedicatedTo(
        project.filePath,
        allPaths ?? [project.filePath],
      ),
    ),
  );
  if (moved == null) return false;

  final repo = await ref.read(repositoryProvider.future);
  await repo.updateProject(moved);
  ref.invalidate(allProjectsStreamProvider);

  if (context.mounted) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.moveProjectSuccess(moved.displayName, p.dirname(moved.filePath)),
        ),
      ),
    );
  }
  return true;
}

class _MoveProjectDialog extends StatefulWidget {
  final MusicProject project;
  final bool canMoveFolder;

  const _MoveProjectDialog({required this.project, required this.canMoveFolder});

  @override
  State<_MoveProjectDialog> createState() => _MoveProjectDialogState();
}

class _MoveProjectDialogState extends State<_MoveProjectDialog> {
  String? _destination;
  late bool _moveFolder = widget.canMoveFolder;
  bool _busy = false;
  String? _error;

  String get _folderName => p.basename(containingFolderOf(widget.project.filePath));

  Future<void> _pickDestination() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.selectMoveDestinationTitle,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _destination = picked;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final destination = _destination;
    if (destination == null || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await moveProject(
        widget.project,
        destination,
        moveContainingFolder: _moveFolder,
      );
      if (mounted) Navigator.pop(context, result.project);
    } on ProjectMoveException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = moveErrorMessage(l10n, e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.moveProjectFailed(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(l10n.moveProjectDialogTitle),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.displayName,
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Text(l10n.moveProjectDestinationLabel, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            // CrossAxisAlignment.center, not the Row default: the button would
            // otherwise top-align against the text's full height.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _destination ?? l10n.moveProjectNoDestinationChosen,
                    style: _destination == null
                        ? theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          )
                        : theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _pickDestination,
                  child: Text(l10n.moveProjectChooseDestination),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.canMoveFolder)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _moveFolder,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _moveFolder = v ?? false),
                title: Text(l10n.moveProjectIncludeFolder(_folderName)),
                subtitle: Text(
                  _moveFolder
                      ? l10n.moveProjectIncludeFolderDescription
                      : l10n.moveProjectFileOnlyDescription,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              )
            else
              Text(
                l10n.moveProjectFileOnlyDescription,
                style: theme.textTheme.bodySmall,
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _destination == null || _busy ? null : _submit,
          child: _busy
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.moveProjectInProgress),
                  ],
                )
              : Text(l10n.moveProjectConfirm),
        ),
      ],
    );
  }
}
