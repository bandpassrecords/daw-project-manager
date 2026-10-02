import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../services/midi/midi_clip_service.dart';
import '../utils/file_launcher.dart';

/// Whether to try the OS share sheet for files on this platform. Mobile,
/// macOS and Windows have one that takes files; Linux's share_plus can only
/// send text.
@visibleForTesting
bool shareSheetWorthTrying({required bool isLinux}) => !isLinux;

/// What to do after a share attempt.
enum ShareFollowUp {
  /// The share sheet answered (shared or dismissed): nothing more.
  none,

  /// We can't tell whether a share sheet appeared — Windows reports
  /// `unavailable` both when its share window opens and when it can't (an
  /// unpackaged build). Opening the folder then put a second window up next
  /// to the share sheet, so the folder is only *offered*.
  offerFolder,

  /// There was certainly no share sheet (Linux, or the call failed): open
  /// the folder so the files can be dragged into a chat.
  openFolder,
}

/// [tried] is whether the share sheet was attempted; [status] its result, or
/// null when the call threw.
@visibleForTesting
ShareFollowUp shareFollowUp({required bool tried, ShareResultStatus? status}) {
  if (!tried || status == null) return ShareFollowUp.openFolder;
  if (status == ShareResultStatus.unavailable) return ShareFollowUp.offerFolder;
  return ShareFollowUp.none;
}

/// Shares [clips] as `.mid` files — one clip, or all of a project's.
///
/// Files are written to a fresh temp folder per share (named after the
/// clips, carrying [bpm]), then handed to the OS share sheet. Where there is
/// certainly no share sheet the folder is opened with a hint to drag the
/// files into a chat; where we can't tell, a snackbar offers it instead (see
/// [shareFollowUp]).
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

    final tried = shareSheetWorthTrying(isLinux: Platform.isLinux);
    ShareResultStatus? status;
    if (tried) {
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
    switch (shareFollowUp(tried: tried, status: status)) {
      case ShareFollowUp.none:
        break;
      case ShareFollowUp.offerFolder:
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.midiClipsShareOfferFolder),
          action: SnackBarAction(
            label: l10n.midiClipsShowInFolder,
            onPressed: () => FileLauncher.openFolder(dir.path),
          ),
        ));
      case ShareFollowUp.openFolder:
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
