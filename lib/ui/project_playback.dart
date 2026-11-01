import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as path;

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../utils/capture_only_play.dart';
import '../utils/track_duration.dart';
import 'app_snack_bar.dart';
import 'widgets/anchored_menu.dart';

/// Whether [project]'s play button shows itself playing: anything of that
/// project in the desktop player, its preview song or its latest capture.
/// One button plays both, so it is the project that counts, never the
/// file: once a capture is promoted to preview song both are one file, and
/// telling them apart by path lit the wrong button.
bool playButtonIsCurrent(DesktopPlayerRequest? request, MusicProject project) =>
    request?.project.id == project.id;

/// Whether [project]'s play button offers its latest capture (a dot on the
/// button, and a right-click menu): it has one, and this device has the
/// DAW plugin ([dpmPluginDetectedProvider]).
bool offersLatestCapture(MusicProject project, {required bool pluginDetected}) =>
    pluginDetected && project.latestCapture != null && !playsCaptureOnly(project);

/// Plays [project]'s latest capture (the DAW plugin's last pass) in the
/// desktop player. A capture synced from another device whose file hasn't
/// come down yet is said, not failed.
Future<void> playProjectCapture(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  final capture = project.latestCapture;
  if (capture == null) return;
  if (!await File(capture.path).exists()) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.latestCaptureNotOnThisDevice)),
    );
    return;
  }
  ref.read(desktopPlayerProvider.notifier).play(
        project.copyWith(
          previewSongPath: capture.path,
          previewSongFileName: path.basename(capture.path),
        ),
        capture.path,
      );
}

/// The play button's own menu (its right-click), offered only where
/// [offersLatestCapture]: the preview song, or the latest capture with when
/// it was taken and how long it is.
Future<void> showPlayChoiceMenu({
  required BuildContext context,
  required WidgetRef ref,
  required MusicProject project,
  required Offset position,
  required VoidCallback onPlayPreview,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final capture = project.latestCapture!;
  final when = DateFormat.yMMMd(Localizations.localeOf(context).toString())
      .add_Hm()
      .format(capture.capturedAt.toLocal());
  final length = formatTrackDuration(Duration(milliseconds: (capture.durationSeconds * 1000).round()));
  final choice = await showAnchoredMenu<String>(
    context: context,
    position: position,
    style: MenuStyle(backgroundColor: WidgetStatePropertyAll(Theme.of(context).cardColor)),
    builder: (choose) => [
      MenuItemButton(
        key: const ValueKey('play-menu-preview'),
        leadingIcon: const Icon(Icons.play_arrow, size: 20),
        onPressed: () => choose('preview'),
        child: Text(l10n.playPreview),
      ),
      MenuItemButton(
        key: const ValueKey('play-menu-capture'),
        leadingIcon: const Icon(Icons.graphic_eq, size: 20),
        onPressed: () => choose('capture'),
        child: Text('${l10n.latestCapturePlay}  ·  ${l10n.latestCaptureDetails(when, length)}'),
      ),
    ],
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'preview':
      onPlayPreview();
    case 'capture':
      await playProjectCapture(context, ref, project);
  }
}
