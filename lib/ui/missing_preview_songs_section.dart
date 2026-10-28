import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../services/google_drive_sync_service.dart';
import '../services/mixdown_detector_service.dart';
import '../services/preview_song_sync.dart';
import '../utils/missing_preview_songs.dart';
import 'app_snack_bar.dart';
import 'dialogs/drive_sync_dialogs.dart' show showDriveConfirmDialog;
import 'dialogs/preview_song_not_found_dialog.dart' show previewAudioExtensions;
import 'widgets/missing_preview_songs_card.dart';

/// Settings > Mixdown folders > Missing preview songs, for the current
/// profile: [MissingPreviewSongsCard] with what its buttons do. Checks only
/// when asked — Drive is read then, and only when signed in.
class MissingPreviewSongsSection extends ConsumerStatefulWidget {
  const MissingPreviewSongsSection({super.key});

  @override
  ConsumerState<MissingPreviewSongsSection> createState() => _MissingPreviewSongsSectionState();
}

class _MissingPreviewSongsSectionState extends ConsumerState<MissingPreviewSongsSection> {
  List<MissingPreviewSong>? _items;
  bool _checking = false;
  bool _busy = false;
  bool _signedOut = false;

  /// What Drive had at the last check, by project id. Kept, so sorting the
  /// list again after an action doesn't ask Drive again.
  Map<String, PreviewSongEntry> _onDrive = const {};

  GoogleDriveSyncService get _drive => ref.read(googleDriveSyncServiceProvider);

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final driveOffered = GoogleDriveSyncService.isSupported;
      _signedOut = driveOffered && !_drive.isSignedIn;
      _onDrive = const {};
      if (driveOffered && _drive.isSignedIn) {
        try {
          _onDrive = await _drive.exclusive(_drive.previewSongsOnDrive);
        } catch (e) {
          // Drive unreachable: the rest of the list still stands.
          debugPrint('[MissingPreviewSongs] could not read Drive: $e');
        }
      }
      await _sort();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// Sorts the profile's projects again against [_onDrive].
  Future<void> _sort() async {
    final repo = await ref.read(repositoryProvider.future);
    final items = await findMissingPreviewSongs(
      repo.getAllProjects(),
      onDrive: _onDrive.keys.toSet(),
      windows: Platform.isWindows,
      fileExists: (path) => File(path).exists(),
      folderExists: (path) => Directory(path).exists(),
    );
    if (mounted) setState(() => _items = items);
  }

  /// Runs [action] on each of [songs], against the project as it is now
  /// stored, then sorts the list again.
  Future<void> _each(
    List<MissingPreviewSong> songs,
    Future<MusicProject?> Function(MissingPreviewSong song, MusicProject current) action,
  ) async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      for (final song in songs) {
        final current = repo.getById(song.project.id);
        if (current == null) continue;
        final updated = await action(song, current);
        if (updated != null) await repo.updateProject(updated);
      }
      ref.invalidate(allProjectsStreamProvider);
      await _sort();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(List<MissingPreviewSong> songs) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    var done = 0;
    String? failed;
    await _each(songs, (song, current) async {
      final referenced = driveReferenceFileId(song.path);
      final entry = _onDrive[song.project.id] ??
          (referenced == null
              ? null
              : PreviewSongEntry(
                  fileId: referenced,
                  hash: current.uploadedPreviewSongHash,
                  fileName: current.previewSongFileName,
                ));
      final downloaded = entry == null
          ? null
          : await _drive.exclusive(() => _drive.downloadPreviewSong(song.project.id, entry));
      if (downloaded == null) {
        failed ??= song.project.displayName;
        return null;
      }
      done++;
      final name = entry!.fileName;
      return withDownloadedPreview(
        current,
        downloaded,
        fileName: name == null || isAppPreviewCopyName(name) ? null : name,
        hash: entry.hash,
      );
    });
    messenger.showAppSnackBar(SnackBar(
      content: Text(songs.length == 1 && failed != null
          ? l10n.missingPreviewDownloadFailed(failed!)
          : l10n.missingPreviewDownloadedResult(done, songs.length)),
    ));
  }

  Future<void> _find(List<MissingPreviewSong> songs) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final customFolders = ref.read(customMixdownFoldersProvider).value;
    final customFoldersByDaw = ref.read(customMixdownFoldersByDawProvider).value;
    var found = 0;
    await _each(songs, (song, current) async {
      // Looked for as if it had no song, so the missing one isn't what is
      // compared against; a miss leaves the project as it was.
      final detected = MixdownDetectorService.findLatestMixdown(
        current.copyWith(
          clearPreviewSongPath: true,
          clearPreviewSongFileName: true,
          clearPreviewSongAutoPath: true,
          clearIgnoredNewerSongPath: true,
        ),
        customFolders: customFolders,
        customFoldersByDaw: customFoldersByDaw,
      );
      if (detected == null) return null;
      found++;
      return withFoundPreview(current, detected.path);
    });
    messenger.showAppSnackBar(SnackBar(
      content: Text(songs.length == 1 && found == 0
          ? l10n.noPreviewSongFoundAutomatically
          : l10n.missingPreviewFoundResult(found, songs.length)),
    ));
  }

  Future<void> _choose(MissingPreviewSong song) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: previewAudioExtensions,
      dialogTitle: l10n.selectPreviewSong,
    );
    final picked = result?.path;
    if (picked == null || !mounted) return;
    await _each([song], (song, current) async => song.manual
        ? current.copyWith(
            previewSongPath: picked,
            previewSongFileName: p.basename(picked),
            clearIgnoredNewerSongPath: true,
          )
        : current.copyWith(previewSongAutoPath: picked, clearIgnoredNewerSongPath: true));
  }

  Future<void> _remove(List<MissingPreviewSong> songs, {required bool all}) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDriveConfirmDialog(
      context,
      title: all ? l10n.missingPreviewRemoveAllTitle(songs.length) : l10n.removePreviewSong,
      body: l10n.missingPreviewRemoveBody,
      confirmLabel: all ? l10n.missingPreviewRemoveAll : l10n.removePreviewSong,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _each(songs, (song, current) async => withoutMissingPreview(current, song));
  }

  @override
  Widget build(BuildContext context) {
    // A check made for another profile says nothing about this one.
    ref.listen(currentProfileProvider, (prev, next) {
      if (prev?.value?.id != next.value?.id) setState(() => _items = null);
    });
    return MissingPreviewSongsCard(
      items: _items,
      checking: _checking,
      busy: _busy,
      showSignInHint: _signedOut,
      onCheck: _check,
      onDownload: _download,
      onFind: _find,
      onChoose: _choose,
      onRemove: _remove,
    );
  }
}
