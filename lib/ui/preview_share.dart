import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../services/audio_analysis_service.dart';
import 'widgets/conversion_progress_dialog.dart';
import 'app_snack_bar.dart';

/// The preview-song file a project would actually play: a manually chosen one
/// wins over an auto-detected mixdown.
String? effectivePreviewPathFor(MusicProject project) =>
    project.previewSongPath?.isNotEmpty == true
    ? project.previewSongPath
    : project.previewSongAutoPath;

/// MIME type to declare for a shared audio file.
///
/// Android's share sheet passes this straight to the receiving app, and some
/// apps route on the declared type rather than sniffing the bytes — an
/// attachment typed `application/octet-stream` can be rejected as "unsupported"
/// even when its contents are perfectly playable. share_plus only guesses from
/// the extension when this is omitted, so state it.
String shareMimeTypeForFileName(String fileName) {
  switch (p.extension(fileName).toLowerCase()) {
    case '.mp3':
      return 'audio/mpeg';
    // AAC in an MP4 container — what afconvert produces on macOS and what
    // Android's MediaMuxer produces via AudioShareConverter.
    case '.m4a':
    case '.mp4':
      return 'audio/mp4';
    case '.aac':
      return 'audio/aac';
    case '.wav':
      return 'audio/wav';
    case '.flac':
      return 'audio/flac';
    case '.ogg':
      return 'audio/ogg';
    case '.aif':
    case '.aiff':
      return 'audio/aiff';
    default:
      return 'audio/*';
  }
}

const _audioExtensions = {
  '.wav',
  '.wave',
  '.aif',
  '.aiff',
  '.flac',
  '.mp3',
  '.m4a',
  '.aac',
  '.ogg',
  '.oga',
  '.opus',
  '.wma',
  '.alac',
};

/// The name a shared preview song goes out under: [friendlyName] (the song's
/// own, `MusicProject.previewShareFileName`) with the extension of the file
/// actually shared, [sharedPath] — `Leave the lights on.wav` converted is
/// `Leave the lights on.mp3`.
///
/// Never [sharedPath]'s own name: a preview song kept by the app is
/// `<project id>_preview.wav`, and its converted copy is named after it, so
/// every song shared as MP3 arrived as `2fa08b9a-…_preview.mp3`.
String sharedPreviewName(String friendlyName, String sharedPath) {
  final ext = p.extension(friendlyName);
  final stem = _audioExtensions.contains(ext.toLowerCase())
      ? friendlyName.substring(0, friendlyName.length - ext.length)
      : friendlyName;
  return '$stem${p.extension(sharedPath)}';
}

/// Copies [file] into the app's cache directory under [shareFileName], ready
/// to hand to the share sheet, and returns it. Returns null when the result
/// would be an empty file.
///
/// Android's share sheet can only hand out files the app exposes through its
/// FileProvider, which is scoped to the cache directory — hence the copy
/// rather than sharing in place. On a desktop the receiving app takes the
/// name from the file itself, so the copy is what gives it the song's name.
///
/// Two traps this exists to avoid, both of which look identical to the user
/// ("it only sent the text", because the receiving app silently drops a
/// zero-byte attachment):
///  - the audio converter writes into this same cache directory, so [file]
///    can already *be* the destination, and `File.copy` onto itself truncates
///    it to nothing;
///  - a conversion that failed halfway can leave a real but empty file.
Future<File?> stageFileForShare(File file, String shareFileName) async {
  final cacheDir = await getTemporaryDirectory();
  final staged = File(p.join(cacheDir.path, shareFileName));
  if (!p.equals(file.path, staged.path)) {
    await file.copy(staged.path);
  }
  if (!await staged.exists() || await staged.length() == 0) return null;
  return staged;
}

/// Shares a project's preview song through the OS share sheet, converting it
/// to MP3 first when the source format is one messaging apps reject.
///
/// One implementation for the dashboard's right-click menu, the mobile list's
/// long-press sheet, the preview dialog, the project page, the phone player
/// and anywhere else that grows a Share button — copies of it had drifted
/// apart, and all four named a converted song after its uuid.
///
/// [previewPath] is the song to share when the caller knows better than the
/// stored project (one just detected or replaced on screen).
Future<void> shareProjectPreview(
  BuildContext context,
  MusicProject project, {
  String? previewPath,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  final effectivePath = previewPath ?? effectivePreviewPathFor(project);
  if (effectivePath == null || effectivePath.isEmpty) return;
  if (effectivePath.startsWith('drive://')) {
    messenger.showAppSnackBar(
      SnackBar(content: Text(l10n.previewSongNotAvailableDownloadFirst)),
    );
    return;
  }

  try {
    final sourceFile = File(effectivePath);
    if (!await sourceFile.exists()) {
      messenger.showAppSnackBar(
        SnackBar(content: Text(l10n.previewSongFileNotFound)),
      );
      return;
    }

    final friendlyName =
        project.previewShareFileName ?? p.basename(effectivePath);

    // WhatsApp (confirmed via manual testing) rejects WAV/AIFF/FLAC as a
    // direct audio attachment with no error shown to us — convert to a
    // compatible format first so the shared file is actually accepted.
    var fileToShare = sourceFile;
    if (AudioAnalysisService.needsConversionForSharing(effectivePath) &&
        context.mounted) {
      final converted = await convertForSharingWithProgress(
        context,
        effectivePath,
      );
      if (converted != null) {
        fileToShare = converted;
      } else {
        messenger.showAppSnackBar(
          SnackBar(content: Text(l10n.mp3ConversionFailed)),
        );
      }
    }

    final shareText = l10n.sharePreviewSongText(project.displayName);
    final shareFileName = sharedPreviewName(friendlyName, fileToShare.path);
    final shareFile = await stageFileForShare(fileToShare, shareFileName);
    if (shareFile == null) {
      messenger.showAppSnackBar(
        SnackBar(content: Text(l10n.failedToSharePreviewSong(shareFileName))),
      );
      return;
    }
    // No "share menu unavailable" warning on `unavailable`: share_plus
    // returns that status on Windows every time, right after the share menu
    // has opened — Windows does not report what the user picked. A share
    // that really fails throws, and the catch below reports it.
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            shareFile.path,
            name: shareFileName,
            mimeType: shareMimeTypeForFileName(shareFileName),
          ),
        ],
        text: shareText,
      ),
    );
  } catch (e) {
    messenger.showAppSnackBar(
      SnackBar(content: Text(l10n.failedToSharePreviewSong(e.toString()))),
    );
  }
}
