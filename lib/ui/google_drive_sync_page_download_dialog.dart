import 'package:flutter/material.dart';
import '../models/backup_progress.dart';
import '../generated/l10n/app_localizations.dart';

/// Dialog for showing backup upload progress (Mobile)
class UploadProgressDialog extends StatefulWidget {
  final Stream<BackupProgress> progressStream;

  const UploadProgressDialog({
    super.key,
    required this.progressStream,
  });

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  bool _hasCompleted = false;

  String _getStageText(BackupProgressStage stage, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (stage) {
      case BackupProgressStage.collectingData:
        return l.collectingData;
      case BackupProgressStage.uploadingPreviewSongs:
        return l.uploadingPreviewSongs;
      case BackupProgressStage.uploadingProfilePhotos:
        return l.uploadingProfilePhotos;
      case BackupProgressStage.uploadingReleaseArtwork:
        return l.uploadingReleaseArtwork;
      case BackupProgressStage.uploadingProjectCoverArt:
        return l.uploadingProjectCoverArt;
      case BackupProgressStage.uploadingDatabase:
        return l.uploadingDatabase;
      case BackupProgressStage.completed:
        return l.completed;
      default:
        return l.uploadingDatabase;
    }
  }

  void _handleCompletion() {
    if (!_hasCompleted && mounted) {
      _hasCompleted = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Row(
        children: [
          const Icon(Icons.cloud_upload, size: 24),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.uploadingBackupTitle),
        ],
      ),
      content: StreamBuilder<BackupProgress>(
        stream: widget.progressStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final progress = snapshot.data!;
          final percentage = (progress.progress * 100).toStringAsFixed(0);
          if (progress.stage == BackupProgressStage.completed && progress.progress >= 1.0) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleCompletion());
          }
          return SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStageText(progress.stage, context),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (progress.totalItems > 0)
                  Text(
                    '${progress.currentIndex} / ${progress.totalItems}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                if (progress.totalItems > 0) const SizedBox(height: 8),
                LinearProgressIndicator(value: progress.progress, minHeight: 8),
                const SizedBox(height: 8),
                Text('$percentage%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dialog for showing backup download progress (Mobile)
class DownloadProgressDialog extends StatefulWidget {
  final Stream<BackupProgress> progressStream;

  const DownloadProgressDialog({
    super.key,
    required this.progressStream,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  bool _hasCompleted = false;

  String _getStageText(BackupProgressStage stage, BuildContext context) {
    switch (stage) {
      case BackupProgressStage.downloadingDatabase:
        return AppLocalizations.of(context)!.downloadingDatabase;
      case BackupProgressStage.downloadingPreviewSongs:
        return AppLocalizations.of(context)!.downloadingPreviewSongs;
      case BackupProgressStage.downloadingProfilePhotos:
        return AppLocalizations.of(context)!.downloadingProfilePhotos;
      case BackupProgressStage.downloadingProjectCoverArt:
        return AppLocalizations.of(context)!.downloadingProjectCoverArt;
      case BackupProgressStage.mergingData:
        return AppLocalizations.of(context)!.mergingData;
      case BackupProgressStage.completed:
        return AppLocalizations.of(context)!.completed;
      default:
        return AppLocalizations.of(context)!.mergingData;
    }
  }

  void _handleCompletion() {
    if (!_hasCompleted && mounted) {
      _hasCompleted = true;
      // Close dialog after a short delay to show completion
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Row(
        children: [
          const Icon(Icons.cloud_download, size: 24),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.downloadingBackupTitle),
        ],
      ),
      content: StreamBuilder<BackupProgress>(
        stream: widget.progressStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final progress = snapshot.data!;
          final percentage = (progress.progress * 100).toStringAsFixed(0);
          
          // Auto-close when completed
          if (progress.stage == BackupProgressStage.completed && progress.progress >= 1.0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleCompletion();
            });
          }

          return SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stage indicator
                Text(
                  _getStageText(progress.stage, context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progress indicator with counter
                if (progress.totalItems > 0)
                  Text(
                    '${progress.currentIndex} / ${progress.totalItems}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                if (progress.totalItems > 0) const SizedBox(height: 8),
                
                // Progress bar
                LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                
                // Percentage
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
