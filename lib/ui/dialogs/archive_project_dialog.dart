import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../models/scan_root.dart';
import '../../providers/providers.dart';
import '../../services/project_archive_service.dart';
import '../../utils/project_folder_utils.dart';

/// The user-facing message for a refused archive.
///
/// A plain switch rather than a field on the exception, so the service stays
/// free of `AppLocalizations` and testable without a widget tree.
String archiveErrorMessage(AppLocalizations l10n, ProjectArchiveException e) {
  switch (e.reason) {
    case ArchiveError.sourceMissing:
      return l10n.archiveErrorSourceMissing;
    case ArchiveError.destinationInScanRoot:
      return l10n.archiveErrorDestinationInScanRoot(e.detail);
    case ArchiveError.destinationOccupied:
      return l10n.archiveErrorDestinationOccupied(p.basename(e.detail));
    case ArchiveError.verificationFailed:
      return l10n.archiveErrorVerificationFailed(e.detail);
    case ArchiveError.notArchived:
      return l10n.archiveErrorNotArchived;
  }
}

String formatByteSize(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / gb).toStringAsFixed(2)} GB';
}

/// Zips a project out of the working library and flags it archived (#116).
///
/// Returns true when the project was archived.
Future<bool> showArchiveProjectDialog(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  // A stack owns no files — its versions do. Archiving one would have to
  // archive every member and re-point the stack, which is not what this does.
  if (project.isVirtual) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.archiveProjectStackUnsupported,
        ),
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

  final result = await showDialog<ArchiveResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ArchiveProjectDialog(
      project: project,
      defaultScope: defaultScopeFor(
        project.filePath,
        allProjectPaths: allPaths ?? [project.filePath],
      ),
      initialDestination: ref.read(archiveFolderProvider),
      scanRoots: ref.read(scanRootsProvider),
    ),
  );
  if (result == null) return false;

  final repo = await ref.read(repositoryProvider.future);
  await repo.updateProject(result.project);
  ref.invalidate(allProjectsStreamProvider);

  // Remember where they put it, so the next archive doesn't ask again.
  await ref
      .read(archiveFolderProvider.notifier)
      .set(p.dirname(result.archivePath));

  if (context.mounted) {
    final l10n = AppLocalizations.of(context)!;
    final message = StringBuffer(
      l10n.archiveProjectSuccess(result.project.displayName),
    );
    if (result.warnings.isNotEmpty) {
      message.write(' — ${l10n.archiveWarningsSkipped(result.warnings.length)}');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.toString()),
        // Archiving is the kind of thing people do to the wrong row. Undo puts
        // the files back where they were (extracting them first if the delete
        // was ticked), removes the zip and clears the flag.
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => _undoArchive(context, ref, result.project),
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }
  return true;
}

/// Reverses a just-finished archive. Shown as the snackbar's Undo, and safe to
/// invoke long after the fact — [undoArchive] only extracts when the files are
/// actually gone.
Future<void> _undoArchive(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final reverted = await undoArchive(project);
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(reverted);
    ref.invalidate(allProjectsStreamProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.archiveUndone)));
  } on ProjectArchiveException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(archiveErrorMessage(l10n, e))),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.archiveUndoFailed(e.toString()))),
    );
  }
}

/// Throws away a project's archive without touching the project's own files.
///
/// The counterpart to Restore for a project archived *with* its originals
/// left in place: there is nothing to bring back, so "restoring" is
/// meaningless and what the user wants is to stop calling it archived.
Future<bool> showDiscardArchiveDialog(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  final l10n = AppLocalizations.of(context)!;
  if (!project.isArchived) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).cardColor,
      title: Text(l10n.discardArchiveConfirmTitle),
      content: Text(l10n.discardArchiveConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade300,
            foregroundColor: Colors.black,
          ),
          child: Text(l10n.discardArchiveButtonLabel),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    final reverted = await undoArchive(project);
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(reverted);
    ref.invalidate(allProjectsStreamProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.discardArchiveDone)));
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.archiveUndoFailed(e.toString()))),
    );
    return false;
  }
}

/// Extracts an archived project back onto disk and clears its archived state.
Future<bool> showRestoreProjectDialog(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  final l10n = AppLocalizations.of(context)!;
  if (!project.isArchived) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.archiveErrorNotArchived)),
    );
    return false;
  }

  // Restoring almost always means "put it back where it was", and making the
  // user re-find that folder in a picker is both tedious and a chance to get
  // it wrong. Offered only when the original location is actually free.
  final original = originalRestoreFolderFor(project);
  final originalIsFree = original != null && !_entityExistsAt(project.filePath);

  String? destination;
  if (originalIsFree) {
    final choice = await showDialog<_RestoreTarget>(
      context: context,
      builder: (ctx) => _RestoreTargetDialog(originalFolder: original),
    );
    if (choice == null || !context.mounted) return false;
    destination = choice == _RestoreTarget.original
        ? original
        : await FilePicker.getDirectoryPath(
            dialogTitle: l10n.selectRestoreDestinationTitle,
          );
  } else {
    destination = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.selectRestoreDestinationTitle,
    );
  }
  if (destination == null || !context.mounted) return false;

  final nav = Navigator.of(context, rootNavigator: true);
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).cardColor,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Flexible(
            child: Text(AppLocalizations.of(ctx)!.restoreProjectInProgress),
          ),
        ],
      ),
    ),
  );

  MusicProject? restored;
  String? error;
  try {
    restored = await restoreProject(project, destination);
  } on ProjectArchiveException catch (e) {
    error = archiveErrorMessage(l10n, e);
  } catch (e) {
    error = l10n.restoreProjectFailed(e.toString());
  } finally {
    nav.pop();
  }

  if (restored != null) {
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(restored);
    ref.invalidate(allProjectsStreamProvider);
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? l10n.restoreProjectSuccess(restored!.displayName),
        ),
      ),
    );
  }
  return error == null;
}

bool _entityExistsAt(String path) =>
    File(path).existsSync() || Directory(path).existsSync();

enum _RestoreTarget { original, chooseFolder }

/// Asks whether to put an archive back where it came from or somewhere new.
class _RestoreTargetDialog extends StatelessWidget {
  final String originalFolder;

  const _RestoreTargetDialog({required this.originalFolder});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(l10n.restoreProjectDialogTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restoreProjectDescription),
            const SizedBox(height: 16),
            Text(l10n.restoreWhereTo, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_backup_restore),
              title: Text(l10n.restoreToOriginalLocation),
              subtitle: Text(
                originalFolder,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.pop(context, _RestoreTarget.original),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_open),
              title: Text(l10n.restoreToChosenFolder),
              onTap: () => Navigator.pop(context, _RestoreTarget.chooseFolder),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

/// Archives several projects in one pass (#116).
///
/// Deliberately offers no per-project scope choice — that is what the single
/// dialog is for. Each project gets [defaultScopeFor]'s answer, so a project
/// with a folder of its own takes the folder and one sharing a folder takes
/// only its own file, which is the safe reading in both cases.
///
/// Returns the number of projects archived.
Future<int> showArchiveProjectsBulkDialog(
  BuildContext context,
  WidgetRef ref,
  List<MusicProject> projects,
) async {
  final archivable = projects
      .where((e) => !e.isVirtual && !e.isArchived)
      .toList(growable: false);
  if (archivable.isEmpty) return 0;

  final allPaths = ref
      .read(allProjectsStreamProvider)
      .value
      ?.where((e) => !e.isVirtual)
      .map((e) => e.filePath)
      .toList(growable: false);

  final results = await showDialog<List<ArchiveResult>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ArchiveBulkDialog(
      projects: archivable,
      allProjectPaths: allPaths ?? const [],
      initialDestination: ref.read(archiveFolderProvider),
      scanRoots: ref.read(scanRootsProvider),
    ),
  );
  if (results == null || results.isEmpty) return 0;

  final repo = await ref.read(repositoryProvider.future);
  for (final result in results) {
    await repo.updateProject(result.project);
  }
  ref.invalidate(allProjectsStreamProvider);
  await ref
      .read(archiveFolderProvider.notifier)
      .set(p.dirname(results.first.archivePath));

  if (context.mounted) {
    final l10n = AppLocalizations.of(context)!;
    final failed = archivable.length - results.length;
    final message = StringBuffer(l10n.archiveBulkSuccess(results.length));
    if (failed > 0) {
      message.write(' — ${l10n.archiveBulkFailures(failed)}');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.toString())),
    );
  }
  return results.length;
}

class _ArchiveBulkDialog extends StatefulWidget {
  final List<MusicProject> projects;
  final List<String> allProjectPaths;
  final String? initialDestination;
  final List<ScanRoot> scanRoots;

  const _ArchiveBulkDialog({
    required this.projects,
    required this.allProjectPaths,
    required this.initialDestination,
    required this.scanRoots,
  });

  @override
  State<_ArchiveBulkDialog> createState() => _ArchiveBulkDialogState();
}

class _ArchiveBulkDialogState extends State<_ArchiveBulkDialog> {
  late String? _destination = widget.initialDestination;
  bool _deleteOriginals = false;
  String? _error;

  ArchiveCancelToken? _cancelToken;
  bool get _running => _cancelToken != null;
  int _done = 0;
  String _currentName = '';

  Future<void> _pickDestination() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.selectArchiveLocationTitle,
    );
    if (picked == null || !mounted) return;

    final conflict = conflictingScanRoot(picked, widget.scanRoots);
    setState(() {
      if (conflict != null) {
        _error = l10n.archiveErrorDestinationInScanRoot(
          conflict.effectiveDisplayName,
        );
      } else {
        _destination = picked;
        _error = null;
      }
    });
  }

  Future<void> _submit() async {
    final destination = _destination;
    if (destination == null || _running) return;

    final token = ArchiveCancelToken();
    setState(() {
      _cancelToken = token;
      _error = null;
      _done = 0;
    });

    final results = <ArchiveResult>[];
    for (final project in widget.projects) {
      if (token.isCancelled) break;
      if (mounted) {
        setState(() => _currentName = project.displayName);
      }
      try {
        results.add(
          await archiveProject(
            project,
            destination,
            scope: defaultScopeFor(
              project.filePath,
              allProjectPaths: widget.allProjectPaths,
            ),
            deleteOriginals: _deleteOriginals,
            scanRoots: widget.scanRoots,
            cancelToken: token,
          ),
        );
      } on ArchiveCancelledException {
        break;
      } catch (_) {
        // One project failing (missing files, a name clash in the destination)
        // must not abandon the rest of the batch; the count of failures is
        // reported at the end.
      }
      if (mounted) setState(() => _done++);
    }

    if (mounted) Navigator.pop(context, results);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final total = widget.projects.length;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(l10n.archiveProjectDialogTitle),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.archiveBulkConfirmMessage(total)),
            const SizedBox(height: 12),
            if (_running) ...[
              Text(l10n.archiveBulkProgress(_done, total)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: total == 0 ? null : _done / total,
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Text(
                _currentName,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              Text(
                l10n.archiveBulkScopeNote,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(l10n.archiveLocationTitle, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _destination ?? l10n.archiveLocationNotSet,
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
                    onPressed: _pickDestination,
                    child: Text(l10n.moveProjectChooseDestination),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _deleteOriginals,
                onChanged: (v) => setState(() => _deleteOriginals = v ?? false),
                title: Text(l10n.archiveProjectDeleteOriginals),
                subtitle: Text(l10n.archiveProjectDeleteOriginalsDescription),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],
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
          onPressed: () {
            if (_running) {
              _cancelToken?.cancel();
            } else {
              Navigator.pop(context);
            }
          },
          child: Text(l10n.cancel),
        ),
        if (!_running)
          FilledButton(
            onPressed: _destination == null ? null : _submit,
            child: Text(l10n.archiveProjectConfirm),
          ),
      ],
    );
  }
}

class _ArchiveProjectDialog extends StatefulWidget {
  final MusicProject project;
  final ArchiveScope defaultScope;
  final String? initialDestination;
  final List<ScanRoot> scanRoots;

  const _ArchiveProjectDialog({
    required this.project,
    required this.defaultScope,
    required this.initialDestination,
    required this.scanRoots,
  });

  @override
  State<_ArchiveProjectDialog> createState() => _ArchiveProjectDialogState();
}

class _ArchiveProjectDialogState extends State<_ArchiveProjectDialog> {
  late ArchiveScope _scope = widget.defaultScope;
  late String? _destination = widget.initialDestination;
  bool _deleteOriginals = false;
  String? _error;

  /// Sizes per scope, filled in as the counts come back so the radio labels
  /// can say what each choice actually costs.
  final Map<ArchiveScope, ({int bytes, int files})> _sizes = {};

  ArchiveCancelToken? _cancelToken;
  ArchiveProgress? _progress;
  bool get _running => _cancelToken != null;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    for (final scope in ArchiveScope.values) {
      final size = await archiveSizeOf(widget.project.filePath, scope);
      if (!mounted) return;
      setState(() => _sizes[scope] = size);
    }
  }

  String get _folderName =>
      p.basename(containingFolderOf(widget.project.filePath));

  Future<void> _pickDestination() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.selectArchiveLocationTitle,
    );
    if (picked == null || !mounted) return;

    // Checked at pick time so a bad location is rejected before the user has
    // committed to the whole operation.
    final conflict = conflictingScanRoot(picked, widget.scanRoots);
    setState(() {
      if (conflict != null) {
        _error = l10n.archiveErrorDestinationInScanRoot(
          conflict.effectiveDisplayName,
        );
      } else {
        _destination = picked;
        _error = null;
      }
    });
  }

  Future<void> _submit() async {
    final destination = _destination;
    if (destination == null || _running) return;

    final l10n = AppLocalizations.of(context)!;
    final token = ArchiveCancelToken();
    setState(() {
      _cancelToken = token;
      _error = null;
      _progress = const ArchiveProgress(stage: ArchiveStage.scanning);
    });

    try {
      final result = await archiveProject(
        widget.project,
        destination,
        scope: _scope,
        deleteOriginals: _deleteOriginals,
        scanRoots: widget.scanRoots,
        cancelToken: token,
        onProgress: (pr) {
          if (mounted) setState(() => _progress = pr);
        },
      );
      if (mounted) Navigator.pop(context, result);
    } on ArchiveCancelledException {
      if (mounted) Navigator.pop(context);
    } on ProjectArchiveException catch (e) {
      if (mounted) {
        setState(() {
          _cancelToken = null;
          _progress = null;
          _error = archiveErrorMessage(l10n, e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cancelToken = null;
          _progress = null;
          _error = l10n.archiveProjectFailed(e.toString());
        });
      }
    }
  }

  String _stageLabel(AppLocalizations l10n, ArchiveStage stage) {
    switch (stage) {
      case ArchiveStage.scanning:
        return l10n.archiveStageScanning;
      case ArchiveStage.compressing:
        return l10n.archiveStageCompressing;
      case ArchiveStage.verifying:
        return l10n.archiveStageVerifying;
      case ArchiveStage.deleting:
        return l10n.archiveStageDeleting;
      case ArchiveStage.done:
        return l10n.archiveStageVerifying;
    }
  }

  String? _summaryFor(AppLocalizations l10n, ArchiveScope scope) {
    final size = _sizes[scope];
    if (size == null) return null;
    return l10n.archiveScopeSummary(formatByteSize(size.bytes), size.files);
  }

  Widget _scopeOption(AppLocalizations l10n, ArchiveScope scope, String label) {
    final summary = _summaryFor(l10n, scope);
    return RadioListTile<ArchiveScope>(
      contentPadding: EdgeInsets.zero,
      value: scope,
      // ignore: deprecated_member_use
      groupValue: _scope,
      // ignore: deprecated_member_use
      onChanged: _running ? null : (v) => setState(() => _scope = v ?? _scope),
      title: Text(label),
      subtitle: summary == null
          ? null
          : Text(summary, style: Theme.of(context).textTheme.bodySmall),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = _progress;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(l10n.archiveProjectDialogTitle),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.displayName,
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (progress != null) ...[
              Text(_stageLabel(l10n, progress.stage)),
              const SizedBox(height: 8),
              // A null value renders indeterminate, which is right while the
              // tree is being walked and nothing measurable has started.
              LinearProgressIndicator(value: progress.progress, minHeight: 6),
              if (progress.currentItem.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  progress.currentItem,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ] else ...[
              Text(
                l10n.archiveProjectWhatToArchive,
                style: theme.textTheme.bodySmall,
              ),
              _scopeOption(
                l10n,
                ArchiveScope.projectFileOnly,
                l10n.archiveProjectScopeFileOnly,
              ),
              _scopeOption(
                l10n,
                ArchiveScope.containingFolder,
                l10n.archiveProjectScopeFolder(_folderName),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.archiveLocationTitle,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              // CrossAxisAlignment.center, not the Row default, so the button
              // doesn't top-align against the path text.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _destination ?? l10n.archiveLocationNotSet,
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
                    onPressed: _pickDestination,
                    child: Text(l10n.moveProjectChooseDestination),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _deleteOriginals,
                onChanged: (v) => setState(() => _deleteOriginals = v ?? false),
                title: Text(l10n.archiveProjectDeleteOriginals),
                subtitle: Text(l10n.archiveProjectDeleteOriginalsDescription),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],
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
          onPressed: () {
            if (_running) {
              _cancelToken?.cancel();
            } else {
              Navigator.pop(context);
            }
          },
          child: Text(l10n.cancel),
        ),
        if (!_running)
          FilledButton(
            onPressed: _destination == null ? null : _submit,
            child: Text(l10n.archiveProjectConfirm),
          ),
      ],
    );
  }
}
