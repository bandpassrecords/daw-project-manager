/// Model for tracking backup upload progress
class BackupProgress {
  final BackupProgressStage stage;
  final String currentItem;
  final int currentIndex;
  final int totalItems;
  final double progress; // 0.0 to 1.0
  /// Non-fatal warnings collected during this operation (e.g. files that failed to upload).
  final List<String> warnings;

  BackupProgress({
    required this.stage,
    required this.currentItem,
    required this.currentIndex,
    required this.totalItems,
    required this.progress,
    this.warnings = const [],
  });

  BackupProgress copyWith({
    BackupProgressStage? stage,
    String? currentItem,
    int? currentIndex,
    int? totalItems,
    double? progress,
    List<String>? warnings,
  }) {
    return BackupProgress(
      stage: stage ?? this.stage,
      currentItem: currentItem ?? this.currentItem,
      currentIndex: currentIndex ?? this.currentIndex,
      totalItems: totalItems ?? this.totalItems,
      progress: progress ?? this.progress,
      warnings: warnings ?? this.warnings,
    );
  }
}

enum BackupProgressStage {
  collectingData,
  uploadingPreviewSongs,
  uploadingProfilePhotos,
  uploadingReleaseArtwork,
  uploadingProjectCoverArt,
  uploadingDatabase,
  downloadingDatabase,
  downloadingPreviewSongs,
  downloadingProfilePhotos,
  downloadingReleaseArtwork,
  downloadingProjectCoverArt,
  mergingData,
  completed,
}
