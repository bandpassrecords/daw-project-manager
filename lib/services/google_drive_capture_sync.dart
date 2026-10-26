part of 'google_drive_sync_service.dart';

/// The DAW plugin's latest captures on Drive: uploaded with the backup and
/// downloaded by a merge, as the rules in plugin_capture_sync.dart decide.
/// A track of their own beside the preview songs' — one file per project,
/// `<profile>_<project>_capture.<ext>` in `plugin_captures`, overwritten in
/// place by each newer take — so the preview songs' code is untouched.
extension _CaptureSync on GoogleDriveSyncService {
  static const _folderName = 'plugin_captures';

  /// The backup's `pluginCaptures`, uploading whatever changed. A phone
  /// never uploads one (it never records any); it keeps the entries for
  /// the captures it has, so its upload doesn't take them from everyone
  /// else. A failed upload keeps the entry it would have replaced.
  Future<Map<String, dynamic>> _captureEntriesForUpload(
    List<Profile> profiles,
    Map<String, CaptureEntry> onDrive,
  ) async {
    final result = <String, dynamic>{};
    String? folderId;
    for (final profile in profiles) {
      final box = await Hive.openBox<MusicProject>('${profile.id}_projects');
      for (final project in box.values) {
        final capture = project.latestCapture;
        if (capture == null) continue;
        final key = captureEntryKey(profile.id, project.id);
        final existing = onDrive[key];
        String? hash;
        if (!MobileUtils.isMobile() && await File(capture.path).exists()) {
          hash = await _cachedFileHash(capture.path);
        }
        switch (decideCaptureUpload(local: capture, localHash: hash, onDrive: existing)) {
          case NoCaptureUpload():
            break;
          case KeepCaptureEntry(:final entry):
            result[key] = entry.toJson();
          case UploadCapture(:final replacing):
            try {
              folderId ??= await _ensureSubfolder(_folderName);
              final fileId = await _uploadCaptureFile(
                capture.path,
                folderId: folderId,
                driveName: '${profile.id}_${project.id}_capture${path.extension(capture.path)}',
                replacingFileId: replacing?.fileId,
              );
              result[key] = CaptureEntry(
                fileId: fileId,
                hash: hash!,
                name: path.basename(capture.path),
                capturedAt: capture.capturedAt,
                durationSeconds: capture.durationSeconds,
              ).toJson();
            } catch (e) {
              if (kDebugMode) debugPrint('Capture upload failed for $key: $e');
              if (replacing != null) result[key] = replacing.toJson();
            }
        }
      }
    }
    return result;
  }

  /// Overwrites [replacingFileId] in place when it still exists, else
  /// creates the file. Returns the Drive file id.
  Future<String> _uploadCaptureFile(
    String localPath, {
    required String folderId,
    required String driveName,
    String? replacingFileId,
  }) async {
    final bytes = await File(localPath).readAsBytes();
    drive.Media media() => drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: _getContentTypeForFile(path.extension(localPath)),
        );
    if (replacingFileId != null) {
      try {
        final updated = await _withRetry(() => _driveApi!.files.update(
              drive.File()..name = driveName,
              replacingFileId,
              uploadMedia: media(),
            ));
        return updated.id ?? replacingFileId;
      } on drive.DetailedApiRequestError catch (e) {
        if (e.status != 404) rethrow;
        // Gone from Drive (emptied by hand): made again below.
      }
    }
    final created = await _withRetry(() => _driveApi!.files.create(
          drive.File()
            ..name = driveName
            ..parents = [folderId],
          uploadMedia: media(),
        ));
    return created.id!;
  }

  /// Brings down every capture [raw] (a backup's `pluginCaptures`) has that
  /// this device lacks: none yet, an older one, or this very one without
  /// its file. Saved as a mirror of Drive, so `updatedAt` stays as it is.
  /// A download that fails, or arrives unlike its hash, is skipped: the
  /// project keeps what it had, and the next sync tries again.
  Future<void> _mergeCaptures(Object? raw, List<Profile> profiles) async {
    final entries = captureEntriesFrom(raw);
    if (entries.isEmpty) return;
    final known = {for (final p in profiles) p.id};
    final pluginDir = path.join(await getPreviewSongsPath(), dpmPluginPreviewFolderName);

    for (final MapEntry(key: key, value: entry) in entries.entries) {
      final slash = key.indexOf('/');
      if (slash <= 0) continue;
      final profileId = key.substring(0, slash);
      final projectId = key.substring(slash + 1);
      if (!known.contains(profileId)) continue;

      final box = await Hive.openBox<MusicProject>('${profileId}_projects');
      final project = box.get(projectId);
      if (project == null) continue;
      final local = project.latestCapture;
      final localExists = local != null && await File(local.path).exists();
      if (!captureNeedsDownload(local: local, localFileExists: localExists, remote: entry)) continue;

      // The name alone, never a path a backup could steer elsewhere.
      final projectDir = safeFileIn(pluginDir, projectId);
      final target = projectDir == null ? null : safeFileIn(projectDir, path.basename(entry.name));
      if (target == null) continue;
      try {
        await _downloadCaptureFile(entry, target);
      } catch (e) {
        if (kDebugMode) debugPrint('Capture download failed for $key: $e');
        continue;
      }

      final previous = local?.path;
      await box.put(
        projectId,
        project.copyWith(
          latestCapture: PluginCapture(
            path: target,
            capturedAt: entry.capturedAt,
            durationSeconds: entry.durationSeconds,
          ),
        ),
      );
      if (previous != null &&
          previous != target &&
          path.isWithin(pluginDir, previous) &&
          !dpmPluginCaptureFileInUse(previous, box.values)) {
        try {
          await File(previous).delete();
        } catch (_) {}
      }
    }
  }

  /// Downloads [entry]'s file to [target], whole or not at all, and checks
  /// it against the hash the uploader recorded.
  Future<void> _downloadCaptureFile(CaptureEntry entry, String target) async {
    final file = File(target);
    await file.parent.create(recursive: true);
    final partial = File('$target.part');
    await _withRetry(() async {
      final media = (await _driveApi!.files.get(
        entry.fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      )) as drive.Media;
      final sink = partial.openWrite();
      try {
        await for (final chunk in media.stream) {
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
    });
    if (await _calculateFileHash(partial.path) != entry.hash) {
      await partial.delete();
      throw StateError('downloaded capture does not match its hash');
    }
    if (await file.exists()) await file.delete();
    await partial.rename(target);
  }
}
