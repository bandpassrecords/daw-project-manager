import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../providers/providers.dart';
import '../../utils/app_paths.dart';
import '../../utils/mobile_utils.dart';
import '../../utils/project_visuals.dart';
import '../widgets/project_cover_avatar.dart';
import 'color_picker_dialog.dart';

/// Extensions the cover picker accepts on a drop. Same set the release
/// artwork picker takes — `.gif` included.
const Set<String> kCoverArtExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.webp',
  '.bmp',
  '.tiff',
  '.heic',
  '.heif',
};

/// Opens the per-project appearance editor (#110): cover art, accent color and
/// icon in one place.
///
/// Every edit is written through the repository as it is made rather than on a
/// Save button — the dialog previews the live project, so an unsaved draft
/// would show the user something the rest of the app disagrees with.
Future<void> showProjectAppearanceDialog(
  BuildContext context, {
  required String projectId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ProjectAppearanceDialog(projectId: projectId),
  );
}

class ProjectAppearanceDialog extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectAppearanceDialog({super.key, required this.projectId});

  @override
  ConsumerState<ProjectAppearanceDialog> createState() =>
      _ProjectAppearanceDialogState();
}

class _ProjectAppearanceDialogState
    extends ConsumerState<ProjectAppearanceDialog> {
  bool _dragging = false;

  MusicProject? _project(WidgetRef ref) {
    final projects = ref.watch(allProjectsStreamProvider).value;
    if (projects == null) return null;
    for (final project in projects) {
      if (project.id == widget.projectId) return project;
    }
    return null;
  }

  /// True when [coverPath] points inside our managed cover-art folder, i.e.
  /// this app made the copy and may delete it. A path the user pointed us at
  /// directly (from an older build, or a Drive payload) is never deleted.
  bool _isManagedCover(String coverPath) =>
      path.basename(path.dirname(coverPath)) == 'project_cover_art';

  Future<void> _saveCoverFrom(String sourcePath, MusicProject project) async {
    final l10n = AppLocalizations.of(context)!;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectedFileDoesNotExist)),
      );
      return;
    }

    try {
      final coverDirPath = await getProjectCoverArtPath();
      final coverDir = Directory(coverDirPath);
      if (!await coverDir.exists()) await coverDir.create(recursive: true);

      // A fresh uuid per pick rather than a fixed `<projectId>_cover` name:
      // Flutter's image cache keys on the path, so reusing the name would keep
      // showing the previous cover until the app restarted.
      final fileName = '${const Uuid().v4()}${path.extension(sourcePath)}';
      final destFile =
          await sourceFile.copy(path.join(coverDir.path, fileName));

      final previous = project.thumbnailPath;
      final repo = await ref.read(repositoryProvider.future);
      await repo.updateProject(
        project.copyWith(thumbnailPath: destFile.path),
      );
      await _deleteManagedCover(previous);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.imageSavedSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToSaveImage(e.toString()))),
      );
    }
  }

  Future<void> _deleteManagedCover(String? coverPath) async {
    if (coverPath == null || coverPath.isEmpty) return;
    if (!_isManagedCover(coverPath)) return;
    try {
      final file = File(coverPath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A cover we failed to delete is a stray file, not a failed edit — the
      // project already points somewhere else.
    }
  }

  Future<void> _pickCover(MusicProject project) async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    final picked = result?.files.single.path;
    if (picked == null) return;
    await _saveCoverFrom(picked, project);
  }

  Future<void> _handleDrop(List<String> filePaths, MusicProject project) async {
    for (final filePath in filePaths) {
      if (kCoverArtExtensions.contains(path.extension(filePath).toLowerCase())) {
        if (await File(filePath).exists()) {
          await _saveCoverFrom(filePath, project);
          return;
        }
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.selectedFileDoesNotExist),
      ),
    );
  }

  Future<void> _removeCover(MusicProject project) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeCoverArt),
        content: Text(l10n.removeCoverArtConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.updateProject(project.copyWith(clearThumbnailPath: true));
      await _deleteManagedCover(project.thumbnailPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.coverArtRemoved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToRemoveCoverArt(e.toString()))),
      );
    }
  }

  Future<void> _pickAccentColor(MusicProject project) async {
    final l10n = AppLocalizations.of(context)!;
    final chosen = await showAppColorPicker(
      context,
      title: l10n.projectAccentColor,
      // Nothing chosen yet: open on the first swatch rather than on a
      // fabricated "current" colour the project does not actually have.
      current: projectAccentColor(project) ?? kProjectAccentPalette.first,
      palette: kProjectAccentPalette,
    );
    if (chosen == null || !mounted) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(
      project.copyWith(accentColor: chosen.toARGB32()),
    );
  }

  /// Tapping the selected icon again clears it — the only way back to "no
  /// icon" short of clearing the colour too.
  Future<void> _toggleIconKey(MusicProject project, String key) async {
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(
      project.iconKey == key
          ? project.copyWith(clearIconKey: true)
          : project.copyWith(iconKey: key),
    );
  }

  Future<void> _clearAccentColor(MusicProject project) async {
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(project.copyWith(clearAccentColor: true));
  }

  Future<void> _clearColorAndIcon(MusicProject project) async {
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(
      project.copyWith(clearAccentColor: true, clearIconKey: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final project = _project(ref);

    if (project == null) {
      return AlertDialog(
        title: Text(l10n.projectAppearance),
        content: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      );
    }

    final hasCover = projectHasCoverArt(project);
    final accent = projectAccentColor(project);
    final hasColorOrIcon = accent != null || project.iconKey != null;
    // What the swatch and the icon grid tint themselves with while the project
    // has no colour of its own. Never written anywhere — picking a colour is
    // what stores one.
    final tint = accent ?? theme.colorScheme.primary;

    Widget preview = ProjectCoverAvatar(
      project: project,
      size: 120,
      showEmptyPlaceholder: true,
    );
    if (!MobileUtils.isMobile()) {
      preview = DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (details) {
          setState(() => _dragging = false);
          _handleDrop(details.files.map((f) => f.path).toList(), project);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _dragging
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: preview,
        ),
      );
    }

    return AlertDialog(
      title: Text(l10n.projectAppearance),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: preview),
              if (!MobileUtils.isMobile())
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.dropCoverArtHere,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _SectionLabel(l10n.projectCoverArt),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickCover(project),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(
                      hasCover ? l10n.replaceCoverArt : l10n.chooseCoverArt,
                    ),
                  ),
                  if (hasCover)
                    OutlinedButton.icon(
                      onPressed: () => _removeCover(project),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l10n.removeCoverArt),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(l10n.projectAccentColor),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _pickAccentColor(project),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: accent != null
                          ? null
                          : Icon(
                              Icons.add,
                              size: 18,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      accent == null
                          ? l10n.appearanceNone
                          : '#${accent.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (accent != null)
                    IconButton(
                      onPressed: () => _clearAccentColor(project),
                      icon: const Icon(Icons.close, size: 18),
                      // Just the colour — the dialog's footer action is the
                      // one that clears both.
                      tooltip: l10n.remove,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(l10n.projectIcon),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in kProjectIconChoices.entries)
                    _IconChoice(
                      icon: entry.value,
                      color: tint,
                      selected: project.iconKey == entry.key,
                      onTap: () => _toggleIconKey(project, entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.appearanceNoneHint, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
      actions: [
        if (hasColorOrIcon)
          TextButton(
            onPressed: () => _clearColorAndIcon(project),
            child: Text(l10n.clearColorAndIcon),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoice({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).dividerColor.withValues(alpha: 0.6),
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(icon, size: 20, color: selected ? color : null),
      ),
    );
  }
}
