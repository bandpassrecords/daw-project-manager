import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../services/metadata_extractor.dart';
import '../services/mixdown_detector_service.dart';
import '../services/scanner_service.dart';
import '../utils/file_launcher.dart';
import 'dialogs/card_initials_dialog.dart';
import 'preview_share.dart';
import 'project_detail_page.dart';
import 'session_actions.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)),
      );
    }
    return;
  }

  final success = await FileLauncher.openFolder(folderPath);

  if (success) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.openingFolder(project.displayName),
          ),
        ),
      );
    }
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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

  final result = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: [
      PopupMenuItem<String>(
        value: sessionMode
            ? (isSubscribed ? 'endSession' : 'startSession')
            : 'launch',
        child: Row(
          children: [
            Icon(
              sessionMode
                  ? (isSubscribed
                        ? Icons.bookmark
                        : Icons.bookmark_add_outlined)
                  : Icons.open_in_new,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              sessionMode
                  ? (isSubscribed ? l10n.endSession : l10n.startSession)
                  : l10n.tooltipLaunchInDaw,
            ),
          ],
        ),
      ),
      // Card-only: the label is drawn on the card's generated cover, so
      // offering it on a grid row would point at something not on screen.
      if (includeCardOptions)
        PopupMenuItem<String>(
          value: 'cardInitials',
          child: Row(
            children: [
              const Icon(Icons.text_fields, size: 20),
              const SizedBox(width: 8),
              Text(l10n.cardInitialsTitle),
            ],
          ),
        ),
      PopupMenuItem<String>(
        value: 'view',
        child: Row(
          children: [
            const Icon(Icons.assignment, size: 20),
            const SizedBox(width: 8),
            Text(l10n.tooltipViewDetails),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'openFolder',
        child: Row(
          children: [
            const Icon(Icons.folder_open, size: 20),
            const SizedBox(width: 8),
            Text(l10n.openFolder),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: project.hidden ? 'unhide' : 'hide',
        child: Row(
          children: [
            Icon(
              project.hidden ? Icons.visibility : Icons.visibility_off,
              size: 20,
              color: project.hidden
                  ? Colors.green.shade300
                  : Colors.red.shade300,
            ),
            const SizedBox(width: 8),
            Text(project.hidden ? l10n.unhide : l10n.hide),
          ],
        ),
      ),
      if (File(project.filePath).existsSync() ||
          Directory(project.filePath).existsSync())
        PopupMenuItem<String>(
          value: 'refresh',
          child: Row(
            children: [
              const Icon(Icons.refresh, size: 20),
              const SizedBox(width: 8),
              Text(l10n.refreshProject),
            ],
          ),
        ),
      if (File(project.filePath).existsSync() ||
          Directory(project.filePath).existsSync())
        PopupMenuItem<String>(
          value: 'extractMetadata',
          enabled: extractionSupported,
          child: Tooltip(
            message: extractionSupported
                ? ''
                : l10n.metadataExtractionNotSupportedForDaw,
            child: Row(
              children: [
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 8),
                Text(l10n.extractMetadata),
              ],
            ),
          ),
        ),
      PopupMenuItem<String>(
        value: 'restoreFromDrive',
        child: Row(
          children: [
            const Icon(Icons.cloud_download, size: 20),
            const SizedBox(width: 8),
            Text(l10n.restoreProjectFromDrive),
          ],
        ),
      ),
      if (effectivePreviewPathFor(project) != null &&
          !effectivePreviewPathFor(project)!.startsWith('drive://'))
        PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              const Icon(Icons.share, size: 20),
              const SizedBox(width: 8),
              Text(l10n.sharePreviewSong),
            ],
          ),
        ),
    ],
    color: Theme.of(context).cardColor,
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
            ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
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
            final msg = l10n.metadataExtractedForProjects(1, '', '');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
          }
        } catch (e) {
          if (context.mounted) {
            final msg = '${l10n.error}: $e';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
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
            ScaffoldMessenger.of(context).showSnackBar(
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
            ).showSnackBar(SnackBar(content: Text(msg)));
          }
        }
        break;
      case 'share':
        if (context.mounted) await shareProjectPreview(context, project);
        break;
    }
  }
}
