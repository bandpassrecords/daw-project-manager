import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../services/midi/midi_clip_service.dart';
import '../utils/file_launcher.dart';

/// Whether to try the OS share sheet for files on this platform. Mobile and
/// macOS have one that takes files. Windows only does when the app is
/// MSIX-packaged, which can't be told apart up front, so it is tried and
/// falls back on `unavailable`. Linux's share_plus can only send text.
@visibleForTesting
bool shareSheetWorthTrying({required bool isLinux}) => !isLinux;

/// Whether a share attempt needs the reveal-in-folder fallback.
@visibleForTesting
bool shareFellThrough(ShareResultStatus? status) =>
    status == null || status == ShareResultStatus.unavailable;

/// Shares [clips] as `.mid` files — one clip, or all of a project's.
///
/// Files are written to a fresh temp folder per share (named after the
/// clips, carrying [bpm]), then handed to the OS share sheet. Where there is
/// no share sheet for files, that folder is opened instead with a hint to
/// drag the files into a chat — the same fallback the diagnostic log uses.
Future<void> shareMidiClips(
  BuildContext context,
  List<MidiClip> clips, {
  required String text,
  double? bpm,
  Rect? origin,
}) async {
  if (clips.isEmpty) return;
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(
      base.path,
      'daw_project_manager',
      'midi_share',
      DateTime.now().microsecondsSinceEpoch.toString(),
    ));
    final files = await MidiClipService.exportAll(clips, dir, bpm: bpm);

    ShareResultStatus? status;
    if (shareSheetWorthTrying(isLinux: Platform.isLinux)) {
      try {
        final result = await SharePlus.instance.share(ShareParams(
          files: [
            for (final f in files)
              XFile(f.path, name: p.basename(f.path), mimeType: 'audio/midi'),
          ],
          text: text,
          sharePositionOrigin: origin,
        ));
        status = result.status;
      } catch (_) {
        status = null;
      }
    }
    if (shareFellThrough(status)) {
      await FileLauncher.openFolder(dir.path);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.midiClipsShareFallback)),
      );
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.midiClipShareFailed(e.toString()))),
    );
  }
}

/// The on-screen rectangle of [context]'s widget, for anchoring the share
/// popover on macOS and iPad (where share_plus requires one).
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
