import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../services/midi/midi_clip_service.dart';
import '../services/midi/midi_file_writer.dart';
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

/// Packs [files] into `<zipName>.zip` inside [dir] — one attachment for a
/// whole collection, which chat apps and mail take far better than a pile
/// of loose files. Entry names are the files' own (already unique).
@visibleForTesting
Future<File> zipMidiFiles(List<File> files, Directory dir, String zipName) async {
  final archive = Archive();
  for (final f in files) {
    final bytes = await f.readAsBytes();
    archive.addFile(ArchiveFile(p.basename(f.path), bytes.length, bytes));
  }
  final safe = zipName
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .replaceFirst(RegExp(r'[. ]+$'), '')
      .trim();
  final zip = File(p.join(dir.path, '${safe.isEmpty ? 'MIDI' : safe}.zip'));
  await zip.writeAsBytes(ZipEncoder().encode(archive), flush: true);
  return zip;
}

/// Shares [clips] as `.mid` files — one clip, or all of a project's — or,
/// with [zipName], as a single `.zip` of them.
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
  String? zipName,
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
    var files = await MidiClipService.exportAll(clips, dir, bpm: bpm);
    if (zipName != null) {
      final zipDir = Directory(p.join(dir.path, 'zip'));
      await zipDir.create();
      files = [await zipMidiFiles(files, zipDir, zipName)];
    }

    final tried = shareSheetWorthTrying(isLinux: Platform.isLinux);
    ShareResultStatus? status;
    if (tried) {
      try {
        final result = await SharePlus.instance.share(ShareParams(
          files: [
            for (final f in files)
              XFile(
                f.path,
                name: p.basename(f.path),
                mimeType: zipName != null ? 'application/zip' : 'audio/midi',
              ),
          ],
          text: text,
          sharePositionOrigin: origin,
        ));
        status = result.status;
      } catch (_) {
        status = null;
      }
    }
    // The folder to show is the one holding what was shared.
    final shown = files.first.parent;
    switch (shareFollowUp(tried: tried, status: status)) {
      case ShareFollowUp.none:
        break;
      case ShareFollowUp.offerFolder:
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.midiClipsShareOfferFolder),
          action: SnackBarAction(
            label: l10n.midiClipsShowInFolder,
            onPressed: () => FileLauncher.openFolder(shown.path),
          ),
        ));
      case ShareFollowUp.openFolder:
        await FileLauncher.openFolder(shown.path);
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

/// Puts [clip] on the system clipboard as a `.mid` *file*, the way Ctrl+C on
/// a file in Explorer or Finder does.
///
/// There is no clipboard format DAWs share for MIDI notes — each keeps its
/// own private one — so a file is the most a clipboard can carry. It pastes
/// into folders, chat apps and DAWs that accept pasted files; dragging the
/// clip remains the dependable way into the rest. Returns false where there
/// is no system clipboard to write to.
Future<bool> copyMidiClipToClipboard(MidiClip clip, {double? bpm}) async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) return false;
  final base = await getTemporaryDirectory();
  // A folder per copy: whatever pasted the last one may still read it.
  final dir = Directory(p.join(base.path, 'daw_project_manager', 'midi_copy',
      DateTime.now().microsecondsSinceEpoch.toString()));
  await dir.create(recursive: true);
  final path = p.join(dir.path, midiClipFileName(clip));
  await MidiClipService.writeMidiFile(clip, path, bpm: bpm);
  final item = DataWriterItem(suggestedName: p.basename(path))
    ..add(Formats.fileUri(Uri.file(path)));
  await clipboard.write([item]);
  return true;
}

