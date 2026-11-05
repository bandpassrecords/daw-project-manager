import 'package:material_ui/material_ui.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/backup_progress.dart';
import '../../services/google_drive_sync_service.dart';

/// Asks before merging a backup in, saying what it will change (counted
/// by [GoogleDriveSyncService.previewMerge]). A merge only ever adds and
/// updates — and removes what was deleted on purpose somewhere — so this
/// is not the red "replace your data" warning it used to be.
///
/// Returns null when cancelled, else whether to fetch preview songs.
Future<bool?> showMergeConfirmDialog(
  BuildContext context, {
  required String title,
  required List<String> previewLines,
  required String confirmLabel,
  bool offerPreviewSongs = true,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _MergeConfirmDialog(
      title: title,
      previewLines: previewLines,
      confirmLabel: confirmLabel,
      offerPreviewSongs: offerPreviewSongs,
    ),
  );
}

class _MergeConfirmDialog extends StatefulWidget {
  const _MergeConfirmDialog({
    required this.title,
    required this.previewLines,
    required this.confirmLabel,
    required this.offerPreviewSongs,
  });

  final String title;
  final List<String> previewLines;
  final String confirmLabel;
  final bool offerPreviewSongs;

  @override
  State<_MergeConfirmDialog> createState() => _MergeConfirmDialogState();
}

class _MergeConfirmDialogState extends State<_MergeConfirmDialog> {
  bool _previewSongs = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.previewLines.isEmpty)
              Text(l10n.driveMergeNothing)
            else
              for (final line in widget.previewLines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(line)),
                    ],
                  ),
                ),
            const SizedBox(height: 12),
            Text(
              l10n.driveMergeKeepsLocal,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.offerPreviewSongs) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _previewSongs,
                onChanged: (v) => setState(() => _previewSongs = v ?? true),
                title: Text(l10n.downloadPreviewSongs),
                subtitle: Text(l10n.downloadPreviewSongsExplanation),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _previewSongs),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// What the user chose after signing in.
class FirstSyncChoice {
  const FirstSyncChoice({required this.syncNow, required this.keepInSync});
  final bool syncNow;
  final bool keepInSync;
}

/// Shown right after signing in, so it doesn't end at a snackbar: either
/// "found a backup — bring it here?" (with what that would change) or
/// "nothing on Drive yet — upload?" (with roughly how much goes up), and,
/// when automatic sync is off, an offer to turn it on.
///
/// With a backup, [previewLines] is what Drive would bring here and
/// [uploadLines] what this device would send; both empty means they already
/// match, and the dialog says so instead of asking to sync.
Future<FirstSyncChoice?> showFirstSyncDialog(
  BuildContext context, {
  required bool hasBackup,
  String? backupLine,
  List<String> previewLines = const [],
  List<String> uploadLines = const [],
  String? estimateLine,
  required bool offerKeepInSync,
}) {
  return showDialog<FirstSyncChoice>(
    context: context,
    builder: (context) => _FirstSyncDialog(
      hasBackup: hasBackup,
      backupLine: backupLine,
      previewLines: previewLines,
      uploadLines: uploadLines,
      estimateLine: estimateLine,
      offerKeepInSync: offerKeepInSync,
    ),
  );
}

class _FirstSyncDialog extends StatefulWidget {
  const _FirstSyncDialog({
    required this.hasBackup,
    required this.backupLine,
    required this.previewLines,
    required this.uploadLines,
    required this.estimateLine,
    required this.offerKeepInSync,
  });

  final bool hasBackup;
  final String? backupLine;
  final List<String> previewLines;
  final List<String> uploadLines;
  final String? estimateLine;
  final bool offerKeepInSync;

  @override
  State<_FirstSyncDialog> createState() => _FirstSyncDialogState();
}

class _FirstSyncDialogState extends State<_FirstSyncDialog> {
  // Off: connecting is manual. Automatic sync is something to ask for, not a
  // default that starts uploading before the first sync has been looked at.
  bool _keepInSync = false;

  bool get _inSync =>
      widget.hasBackup &&
      widget.previewLines.isEmpty &&
      widget.uploadLines.isEmpty;

  Widget _section(BuildContext context, String heading, List<String> lines) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: const TextStyle(fontWeight: FontWeight.w600)),
            for (final line in lines) Text('•  $line'),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(
        widget.hasBackup
            ? l10n.driveFoundBackupTitle
            : l10n.driveFirstUploadTitle,
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.hasBackup) ...[
              if (widget.backupLine != null) Text(widget.backupLine!),
              const SizedBox(height: 8),
              if (_inSync)
                Text(
                  l10n.driveAlreadyInSync,
                  key: const ValueKey('drive-in-sync'),
                )
              else ...[
                Text(l10n.driveFoundBackupBody),
                if (widget.previewLines.isNotEmpty)
                  _section(context, l10n.driveFromDrive, widget.previewLines),
                if (widget.uploadLines.isNotEmpty)
                  _section(
                    context,
                    l10n.driveFromThisDevice,
                    widget.uploadLines,
                  ),
              ],
            ] else ...[
              Text(l10n.driveFirstUploadBody),
              if (widget.estimateLine != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.estimateLine!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
            if (widget.offerKeepInSync) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _keepInSync,
                onChanged: (v) => setState(() => _keepInSync = v ?? false),
                title: Text(l10n.driveKeepInSyncAutomatically),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_inSync)
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              FirstSyncChoice(
                syncNow: false,
                keepInSync: widget.offerKeepInSync && _keepInSync,
              ),
            ),
            child: Text(l10n.done),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              FirstSyncChoice(
                syncNow: false,
                keepInSync: widget.offerKeepInSync && _keepInSync,
              ),
            ),
            child: Text(l10n.driveLater),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              FirstSyncChoice(
                syncNow: true,
                keepInSync: widget.offerKeepInSync && _keepInSync,
              ),
            ),
            child: Text(l10n.driveSyncNow),
          ),
        ],
      ],
    );
  }
}

/// Picks one of the earlier backups Drive keeps, newest first.
Future<BackupSnapshot?> showSnapshotPicker(
  BuildContext context, {
  required List<BackupSnapshot> snapshots,
  required String Function(BackupSnapshot) describe,
  required int snapshotsKept,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<BackupSnapshot>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(l10n.driveRecoverTitle),
      content: SizedBox(
        width: 420,
        child: snapshots.isEmpty
            ? Text(l10n.driveNoSnapshots)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.driveRecoverEarlierHint(snapshotsKept),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final s in snapshots)
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(describe(s)),
                            onTap: () => Navigator.pop(context, s),
                          ),
                      ],
                    ),
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
    ),
  );
}

/// A yes/no confirmation; [destructive] paints the confirm button red (with
/// white text — Flutter derives no contrast from a custom background).
Future<bool> showDriveConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(title),
      content: SizedBox(width: 420, child: Text(body)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Progress for a sync, upload or restore. It never closes itself — the
/// caller pops it exactly once when the operation ends — because the merge
/// reports "completed" halfway through a sync, and the old dialogs closed
/// on that and left the caller popping whatever was underneath.
class DriveSyncProgressDialog extends StatefulWidget {
  const DriveSyncProgressDialog({
    super.key,
    required this.title,
    required this.progress,
    required this.onCancel,
  });

  final String title;
  final Stream<BackupProgress> progress;
  final VoidCallback onCancel;

  @override
  State<DriveSyncProgressDialog> createState() =>
      _DriveSyncProgressDialogState();
}

class _DriveSyncProgressDialogState extends State<DriveSyncProgressDialog> {
  bool _cancelling = false;

  static String _stageText(AppLocalizations l10n, BackupProgressStage stage) {
    switch (stage) {
      case BackupProgressStage.collectingData:
        return l10n.collectingData;
      case BackupProgressStage.uploadingPreviewSongs:
        return l10n.uploadingPreviewSongs;
      case BackupProgressStage.uploadingProfilePhotos:
        return l10n.uploadingProfilePhotos;
      case BackupProgressStage.uploadingReleaseArtwork:
        return l10n.uploadingReleaseArtwork;
      case BackupProgressStage.uploadingProjectCoverArt:
        return l10n.uploadingProjectCoverArt;
      case BackupProgressStage.uploadingDatabase:
        return l10n.uploadingDatabase;
      case BackupProgressStage.downloadingDatabase:
        return l10n.downloadingDatabase;
      case BackupProgressStage.downloadingPreviewSongs:
        return l10n.downloadingPreviewSongs;
      case BackupProgressStage.downloadingProfilePhotos:
        return l10n.downloadingProfilePhotos;
      case BackupProgressStage.downloadingReleaseArtwork:
        return l10n.downloadingReleaseArtwork;
      case BackupProgressStage.downloadingProjectCoverArt:
        return l10n.downloadingProjectCoverArt;
      case BackupProgressStage.mergingData:
        return l10n.mergingData;
      case BackupProgressStage.completed:
        return l10n.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(_cancelling ? l10n.cancelling : widget.title),
        content: SizedBox(
          width: 400,
          child: StreamBuilder<BackupProgress>(
            stream: widget.progress,
            builder: (context, snapshot) {
              final p = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p == null ? l10n.driveSyncing : _stageText(l10n, p.stage),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: p == null || p.stage == BackupProgressStage.completed
                        ? null
                        : p.progress,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  if (p != null && p.totalItems > 1)
                    Text(
                      '${p.currentIndex} / ${p.totalItems}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cancelling
                ? null
                : () {
                    setState(() => _cancelling = true);
                    widget.onCancel();
                  },
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
