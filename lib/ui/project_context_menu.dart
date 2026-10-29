import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../services/google_drive_sync_service.dart';
import '../services/metadata_extractor.dart';
import '../services/mixdown_detector_service.dart';
import '../services/scanner_service.dart';
import '../utils/file_launcher.dart';
import '../utils/project_file_status.dart';
import 'dialogs/archive_project_dialog.dart';
import 'dialogs/card_initials_dialog.dart';
import 'dialogs/move_project_dialog.dart';
import 'preview_share.dart';
import 'project_detail_page.dart';
import 'project_playback.dart';
import 'profile_move_actions.dart';
import 'recently_deleted_actions.dart';
import 'session_actions.dart';
import 'app_snack_bar.dart';
import 'widgets/anchored_menu.dart';
import 'widgets/semantics_safe.dart';

/// The right-click menu on a project, and the three navigation actions it
/// shares with the rest of the dashboard.
///
/// Lifted out of `_PlutoProjectsTableState` when the card view landed (#111):
/// the cards need the *same* menu as a grid row, and a second copy of a
/// fifteen-branch menu is a guarantee the two drift. The grid's method now
/// delegates here, so there is one definition of what a project's context
/// menu does and one place to add the next entry.

/// Opens the project in its DAW — unless a work session is being tracked, in
/// which case launching a row means starting/ending that session instead and
/// the caller's session branch has already handled it.
Future<void> launchProjectFromMenu(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  if (ref.read(sessionModeProvider)) return;
  // Never call FileLauncher directly — launchProjectInDaw is what knows about
  // the DAW executable overrides and the configure prompt. See CLAUDE.md.
  await launchProjectInDaw(context, ref, project);
}

Future<void> openProjectDetail(
  BuildContext context,
  MusicProject project,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
  );
}

/// Reveals the folder the project lives in.
Future<void> openProjectFolder(
  BuildContext context,
  MusicProject project,
) async {
  // A package-bundle project (.logicx/.luna/.band) is a directory, but
  // revealing it would just launch the DAW — resolve to its parent. See
  // ScannerService.projectContainingFolder.
  final String folderPath = ScannerService.projectContainingFolder(
    project.filePath,
  );

  final exists = Directory(folderPath).existsSync();
  if (!exists) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)),
      );
    }
    return;
  }

  final success = await FileLauncher.openFolder(folderPath);

  if (success) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.openingFolder(project.displayName),
          ),
        ),
      );
    }
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.couldNotOpenFolder('Unable to open folder'),
          ),
        ),
      );
    }
  }
}

Future<void> showProjectContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required MusicProject project,
  required Offset position,
  required void Function(List<String> ids) onHideProjects,
  required void Function(List<String> ids) onUnhideProjects,
  required void Function(bool) onExtractingMetadataChanged,
  bool includeCardOptions = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final driveService = ref.read(googleDriveSyncServiceProvider);
  final sessionMode = ref.read(sessionModeProvider);
  final isSubscribed =
      sessionMode && ref.read(activeProjectProvider)?.id == project.id;
  final extractionSupported = MetadataExtractor.supportsFullExtraction(
    project.filePath,
  );

  final preview = effectivePreviewPathFor(project);
  final result = await showAnchoredMenu<String>(
    context: context,
    position: position,
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(Theme.of(context).cardColor),
    ),
    builder: (choose) => projectMenuChildren(
      l10n: l10n,
      project: project,
      choose: choose,
      sessionMode: sessionMode,
      isSubscribed: isSubscribed,
      includeCardOptions: includeCardOptions,
      filesPresent: File(project.filePath).existsSync() ||
          Directory(project.filePath).existsSync(),
      extractionSupported: extractionSupported,
      archivedFilesPresent: project.isArchived && projectFileExists(project),
      driveRestoreOffered: GoogleDriveSyncService.isSupported,
      previewShareable: preview != null && !preview.startsWith('drive://'),
      captureOffered: offersLatestCapture(
        project,
        pluginDetected: ref.read(dpmPluginDetectedProvider),
      ),
      inspectOffered: !project.isVirtual &&
          ref.read(visibleTabsProvider).contains(AppTab.inspector) &&
          File(project.filePath).existsSync(),
    ),
  );

  if (result != null && context.mounted) {
    switch (result) {
      case 'launch':
        await launchProjectFromMenu(context, ref, project);
        break;
      case 'startSession':
        await confirmStartSession(context, ref, project);
        break;
      case 'endSession':
        await confirmEndSession(context, ref);
        break;
      case 'cardInitials':
        await showCardInitialsDialog(context, ref, project);
        break;
      case 'view':
        await openProjectDetail(context, project);
        break;
      case 'openFolder':
        await openProjectFolder(context, project);
        break;
      case 'inspect':
        // Read it fresh: the file may have changed since it was last open.
        ref.invalidate(projectAnatomyProvider(project.filePath));
        ref.read(inspectorFileProvider.notifier).open(project.filePath);
        ref.read(inspectorShowRequestProvider.notifier).request();
        break;
      case 'playCapture':
        await playProjectCapture(context, ref, project);
        break;
      case 'move':
        await showMoveProjectDialog(context, ref, project);
        break;
      case 'archive':
        await showArchiveProjectDialog(context, ref, project);
        break;
      case 'restore':
        await showRestoreProjectDialog(context, ref, project);
        break;
      case 'discardArchive':
        await showDiscardArchiveDialog(context, ref, project);
        break;
      case 'moveToProfile':
        await moveToProfileFromMenu(context, ref, project);
        break;
      case 'delete':
        await deleteProjectFromLibrary(context, ref, project);
        break;
      case 'hide':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(l10n.hide),
            content: Text(l10n.hideProjectMessage(project.displayName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade300,
                  foregroundColor: Colors.black,
                ),
                child: Text(l10n.hide),
              ),
            ],
          ),
        );
        if (confirm == true) {
          onHideProjects([project.id]);
        }
        break;
      case 'unhide':
        onUnhideProjects([project.id]);
        break;
      case 'refresh':
        try {
          final repo = await ref.read(repositoryProvider.future);
          final entity = Directory(project.filePath).existsSync()
              ? Directory(project.filePath) as FileSystemEntity
              : File(project.filePath);
          await repo.upsertFromFileSystemEntity(entity, fullMetadata: true);
          if (project.previewSongPath?.isNotEmpty != true &&
              project.previewSongAutoPath == null) {
            final customFolders = ref.read(customMixdownFoldersProvider).value;
            final customFoldersByDaw = ref
                .read(customMixdownFoldersByDawProvider)
                .value;
            final detected = MixdownDetectorService.findLatestMixdown(
              project,
              customFolders: customFolders,
              customFoldersByDaw: customFoldersByDaw,
            );
            if (detected != null) {
              final fresh = repo.getById(project.id) ?? project;
              await repo.updateProject(
                fresh.copyWith(previewSongAutoPath: detected.path),
              );
            }
          }
          ref.invalidate(allProjectsStreamProvider);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showAppSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
          }
        }
        break;
      case 'extractMetadata':
        onExtractingMetadataChanged(true);
        try {
          final repo = await ref.read(repositoryProvider.future);
          await repo.extractFullMetadataForProject(project.id);
          ref.invalidate(allProjectsStreamProvider);
          if (context.mounted) {
            final msg = l10n.metadataExtractedForProjects(1, '');
            ScaffoldMessenger.of(
              context,
            ).showAppSnackBar(SnackBar(content: Text(msg)));
          }
        } catch (e) {
          if (context.mounted) {
            final msg = '${l10n.error}: $e';
            ScaffoldMessenger.of(
              context,
            ).showAppSnackBar(SnackBar(content: Text(msg)));
          }
        } finally {
          onExtractingMetadataChanged(false);
        }
        break;
      case 'restoreFromDrive':
        if (!context.mounted) break;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(l10n.restoringProjectFromDrive),
              ],
            ),
          ),
        );
        try {
          // Restore session if not already authenticated (e.g. Drive page was never opened)
          if (!driveService.isSignedIn) {
            await driveService.restoreSession();
          }
          if (!driveService.isSignedIn) {
            throw Exception('not_signed_in');
          }
          final profileRepo = await ref.read(profileRepositoryProvider.future);
          await driveService.restoreSingleProject(
            projectId: project.id,
            profileRepo: profileRepo,
          );
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ref.invalidate(allProjectsStreamProvider);
            ScaffoldMessenger.of(context).showAppSnackBar(
              SnackBar(content: Text(l10n.projectRestoredFromDrive)),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            final errStr = e.toString();
            final String msg;
            if (errStr.contains('not_signed_in') ||
                errStr.contains('Not signed in')) {
              msg = l10n.signInToGoogleDriveFirst;
            } else if (errStr.contains('not found in backup')) {
              msg = l10n.projectNotFoundInBackup;
            } else {
              msg = '${l10n.error}: $e';
            }
            ScaffoldMessenger.of(
              context,
            ).showAppSnackBar(SnackBar(content: Text(msg)));
          }
        }
        break;
      case 'share':
        if (context.mounted) await shareProjectPreview(context, project);
        break;
    }
  }
}

/// The project menu's entries, from plain values so it can be tested without
/// Riverpod or the file system. Every entry calls [choose] with the value
/// [showProjectContextMenu] acts on.
///
/// The everyday actions sit at the top, the rest in two submenus that open
/// on hover (Files: move, archive; Update details: re-reading the project),
/// and Delete last, on its own.
List<Widget> projectMenuChildren({
  required AppLocalizations l10n,
  required MusicProject project,
  required void Function(String value) choose,
  required bool sessionMode,
  required bool isSubscribed,
  required bool includeCardOptions,
  required bool filesPresent,
  required bool extractionSupported,
  required bool archivedFilesPresent,
  required bool driveRestoreOffered,
  required bool previewShareable,
  bool captureOffered = false,
  bool inspectOffered = false,
}) {
  Widget item(
    String value,
    IconData icon,
    String label, {
    Color? iconColor,
    bool enabled = true,
    String? whyNot,
  }) =>
      MenuItemButton(
        key: ValueKey('project-menu-$value'),
        leadingIcon: Icon(icon, size: 20, color: iconColor),
        onPressed: enabled ? () => choose(value) : null,
        child: whyNot == null || enabled
            ? Text(label)
            : StandaloneTooltip(message: whyNot, child: Text(label)),
      );

  Widget submenu(String key, IconData icon, String label, List<Widget> items) =>
      SubmenuButton(
        key: ValueKey('project-menu-$key'),
        leadingIcon: Icon(icon, size: 20),
        // Long enough that crossing it on the way to an item below doesn't
        // open it; short enough that resting on it does.
        hoverOpenDelay: const Duration(milliseconds: 150),
        animated: true,
        menuChildren: items,
        child: Text(label),
      );

  // Moving and archiving (#88, #116). A stack has no files of its own — its
  // versions do — so both are offered only on a real project, and its
  // versions are moved or archived from their own rows.
  final files = [
    if (!project.isVirtual) ...[
      item('move', Icons.drive_file_move_outline, l10n.moveProjectButtonLabel),
      project.isArchived
          ? item('restore', Icons.unarchive_outlined,
              l10n.restoreProjectButtonLabel)
          : item('archive', Icons.archive_outlined,
              l10n.archiveProjectButtonLabel),
      // Only worth offering while the files are still here: with nothing to
      // bring back, throwing the zip away would strand the project.
      if (archivedFilesPresent)
        item('discardArchive', Icons.delete_sweep_outlined,
            l10n.discardArchiveButtonLabel,
            iconColor: Colors.red.shade300),
    ],
  ];
  final update = [
    if (filesPresent) ...[
      item('refresh', Icons.refresh, l10n.refreshProject),
      item('extractMetadata', Icons.search, l10n.extractMetadata,
          enabled: extractionSupported,
          whyNot: l10n.metadataExtractionNotSupportedForDaw),
    ],
    // Drive isn't offered inside Flatpak (GoogleDriveSyncService.isSupported).
    if (driveRestoreOffered)
      item('restoreFromDrive', Icons.cloud_download,
          l10n.restoreProjectFromDrive),
  ];

  return [
    sessionMode
        ? item(
            isSubscribed ? 'endSession' : 'startSession',
            isSubscribed ? Icons.bookmark : Icons.bookmark_add_outlined,
            isSubscribed ? l10n.endSession : l10n.startSession)
        : item('launch', Icons.open_in_new, l10n.tooltipLaunchInDaw),
    item('view', Icons.assignment, l10n.tooltipViewDetails),
    item('openFolder', Icons.folder_open, l10n.openFolder),
    // The Inspector tab (#196): desktop-only, and a stack has no file.
    if (inspectOffered)
      item('inspect', Icons.manage_search, l10n.projectMenuInspect),
    // The DAW plugin's latest capture (offersLatestCapture): the same rule as
    // the dot on the play button.
    if (captureOffered)
      item('playCapture', Icons.graphic_eq, l10n.latestCapturePlay),
    if (previewShareable) item('share', Icons.share, l10n.sharePreviewSong),
    const Divider(height: 1),
    if (files.isNotEmpty)
      submenu('files', Icons.folder_copy_outlined, l10n.projectMenuFiles, files),
    if (update.isNotEmpty)
      submenu('update', Icons.sync, l10n.projectMenuUpdate, update),
    // Card-only: the label is drawn on the card's generated cover, so
    // offering it on a grid row would point at something not on screen.
    if (includeCardOptions)
      item('cardInitials', Icons.text_fields, l10n.cardInitialsTitle),
    project.hidden
        ? item('unhide', Icons.visibility, l10n.unhide,
            iconColor: Colors.green.shade300)
        : item('hide', Icons.visibility_off, l10n.hide,
            iconColor: Colors.red.shade300),
    // To another artist's profile: a song moves whole, a version with its
    // stack (see planProfileMove).
    if (!project.isArchived)
      item('moveToProfile', Icons.switch_account_outlined,
          l10n.moveToProfileMenu),
    // Delete into Recently deleted (Settings > Project folders). Not on a
    // stack — its shared details live on its row, and unstacking is the way
    // out — nor on an archived project, the one row pointing at its zip.
    if (!project.isVirtual && !project.isArchived) ...[
      const Divider(height: 1),
      item('delete', Icons.delete_outline, l10n.deleteProjectMenu,
          iconColor: Colors.red.shade300),
    ],
  ];
}
