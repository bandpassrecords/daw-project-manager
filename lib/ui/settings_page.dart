import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/scan_mode.dart';
import '../models/project_detail_layout.dart';
import '../models/waveform_style.dart';
import '../models/scan_root.dart';
import 'dialogs/auto_stack_confirm_dialog.dart';
import '../providers/providers.dart';
import '../providers/theme_provider.dart';
import '../repository/project_repository.dart';
import '../services/auto_start_service.dart';
import '../services/backup_service.dart';
import '../utils/app_paths.dart' show canPickAppDataDir;
import 'dev_library_picker.dart' show DevLibraryCard;
import '../services/crash_logger.dart';
import '../services/google_drive_sync_service.dart' show GoogleDriveSyncService;
import '../services/mixdown_detector_service.dart';
import '../services/project_parts_csv_export_service.dart';
import '../services/project_parts_xlsx_export_service.dart';
import '../services/project_text_export_service.dart';
import '../services/scan_import_service.dart';
import '../services/update_check_service.dart';
import '../utils/daw_logo.dart';
import '../utils/file_launcher.dart';
import '../utils/mobile_utils.dart';
import '../utils/phase_colors.dart';
import 'dashboard_page.dart' show appVersion;
import 'dialogs/daw_launch_command_dialog.dart';
import 'google_drive_sync_page.dart' show GoogleDriveSyncSection;
import 'metadata_extraction_info_page.dart';
import 'notification_settings_page.dart' show WorkTimerSection;
import 'onboarding_wizard_page.dart';
import 'widgets/parts_export_card.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/section_nav_rail.dart';
import 'widgets/language_switcher.dart' show LanguageSwitcher;
import 'widgets/license_dialog.dart';
import 'widgets/shortcuts_help_dialog.dart';
import 'widgets/update_available_dialog.dart';

/// A Flatpak document-portal path, e.g.
/// `/run/user/1000/doc/98127/projects` — the portal never exposes the real
/// filesystem location to a sandboxed app without broader permissions this
/// app deliberately doesn't request, so [ScanRoot.path] itself is one of
/// these rather than something meaningful to show.
@visibleForTesting
bool looksLikeFlatpakPortalPath(String path) =>
    Platform.isLinux && RegExp(r'^/run/user/\d+/doc/').hasMatch(path);

/// Identifies a SettingsPage tab for deep-linking (e.g. the dashboard's
/// Google Drive quick-access shortcut opening straight to [backup]). Member
/// declaration order here is purely cosmetic — actual nav/rendering order
/// comes from _SettingsPageState._sectionOrder(), which resolves an
/// [initialSection] to a live position by identity, so it stays correct
/// even when a platform-conditional section (like [dawLaunchCommands]) is
/// absent from the list or reordered within it.
enum SettingsSection {
  general,
  appearance,
  projectFolders,
  // Desktop-only — see the MobileUtils.isDesktop() gate in _sectionOrder().
  dawLaunchCommands,
  mixdownFolders,
  phases,
  workSessions,
  backup,
  dangerZone,
  shortcuts,
  about,
}

/// Single desktop settings hub, Chrome-settings-style: the left nav rail
/// picks one section (data management, general, project folders, phases,
/// notifications, danger zone) and only that section renders on the right —
/// switching sections is always a visible page change, not a scroll. A
/// search box atop the nav rail flips the content pane into a flattened,
/// cross-section results list with matching text highlighted; picking a
/// result clears the search and jumps straight to that section's tab.
/// Only ever pushed from desktop-gated entry points (dashboard's Settings
/// button/rail action), so there's no mobile layout to maintain here.
class SettingsPage extends ConsumerStatefulWidget {
  final SettingsSection initialSection;

  const SettingsPage({super.key, this.initialSection = SettingsSection.general});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _searchController = TextEditingController();

  // Resolved by identity, not by widget.initialSection.index directly — see
  // _sectionOrder() for why the enum's declaration order can't be trusted
  // as a position.
  late int _activeSection = () {
    final idx = _sectionOrder().indexOf(widget.initialSection);
    return idx < 0 ? 0 : idx;
  }();

  bool _busy = false;
  bool _checkingUpdate = false;
  late final TextEditingController _newMixdownFolderCtrl;
  final Map<String, TextEditingController> _mixdownFolderByDawCtrls = {};
  final _addPhaseController = TextEditingController();
  String? _addPhaseError;

  @override
  void initState() {
    super.initState();
    _newMixdownFolderCtrl = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _newMixdownFolderCtrl.dispose();
    for (final c in _mixdownFolderByDawCtrls.values) {
      c.dispose();
    }
    _addPhaseController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _selectSection(int index) {
    setState(() {
      _activeSection = index;
      _searchController.clear();
    });
  }

  // ---------------------------------------------------------------------
  // Data management — backup / restore
  // ---------------------------------------------------------------------

  Future<void> _exportBackup() async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfileId = profileRepo.getCurrentProfileId();
      if (currentProfileId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.noProfileSelected)),
          );
        }
        return;
      }

      final projectRepo = await ref.read(repositoryProvider.future);
      if (!mounted) return;

      final file = await BackupService.exportBackup(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        profileId: currentProfileId,
        exportDialogTitle: AppLocalizations.of(context)!.exportBackupDialogTitle,
      );

      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.backupExportedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToExportBackup(e.toString()))),
        );
      }
    }
  }

  String _getImportButtonText(ImportMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ImportMode.merge:
        return l10n.mergeWithCurrentProfile;
      case ImportMode.replace:
        return l10n.replaceCurrentProfile;
      case ImportMode.createNewProfile:
        return l10n.create;
    }
  }

  Future<void> _showImportDialog() async {
    ImportMode? selectedMode = ImportMode.merge; // Default to merge mode
    final profileNameController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocalizations.of(context)!.importBackup),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.importBackupMessage),
                const SizedBox(height: 16),
                RadioListTile<ImportMode>(
                  title: Text(AppLocalizations.of(context)!.mergeWithCurrentProfile),
                  value: ImportMode.merge,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value;
                    });
                  },
                ),
                RadioListTile<ImportMode>(
                  title: Text(AppLocalizations.of(context)!.replaceCurrentProfile),
                  value: ImportMode.replace,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value;
                    });
                  },
                ),
                RadioListTile<ImportMode>(
                  title: Text(AppLocalizations.of(context)!.createNewProfileForImport),
                  value: ImportMode.createNewProfile,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value;
                    });
                  },
                ),
                if (selectedMode == ImportMode.createNewProfile) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: profileNameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.profileName,
                      hintText: AppLocalizations.of(context)!.profileName,
                    ),
                    autofocus: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMode == ImportMode.createNewProfile) {
                  final name = profileNameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(ctx)!.pleaseEnterProfileName)),
                    );
                    return;
                  }
                  Navigator.pop(ctx, {
                    'mode': selectedMode,
                    'profileName': name,
                  });
                } else {
                  Navigator.pop(ctx, {
                    'mode': selectedMode,
                  });
                }
              },
              style: selectedMode == ImportMode.replace
                  ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
                  : null,
              child: Text(_getImportButtonText(selectedMode!)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final mode = result['mode'] as ImportMode;
      final profileName = result['profileName'] as String?;
      await _importBackup(importMode: mode, newProfileName: profileName);
    }
  }

  Future<void> _importBackup({
    required ImportMode importMode,
    String? newProfileName,
  }) async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      if (!mounted) return;
      final currentProfileId = profileRepo.getCurrentProfileId();

      // For createNewProfile mode, we don't need currentProfileId or projectRepo yet
      ProjectRepository? projectRepo;
      if (importMode != ImportMode.createNewProfile) {
        if (currentProfileId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.noProfileSelected)),
            );
          }
          return;
        }
        projectRepo = await ref.read(repositoryProvider.future);
        if (!mounted) return;
      }

      final importResult = await BackupService.importBackup(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        currentProfileId: currentProfileId,
        importMode: importMode,
        newProfileName: newProfileName,
        importDialogTitle: AppLocalizations.of(context)!.importBackupDialogTitle,
        invalidBackupFormatMessage: AppLocalizations.of(context)!.invalidBackupFileFormat,
        profileNameRequiredMessage: AppLocalizations.of(context)!.profileNameRequiredForNewProfile,
        currentProfileRequiredMessage: AppLocalizations.of(context)!.currentProfileRequired,
      );

      if (importResult.cancelled) {
        return;
      }

      if (mounted) {
        String message;
        if (importMode == ImportMode.createNewProfile && importResult.newProfileId != null) {
          message = AppLocalizations.of(context)!.backupImportedToNewProfile(
            newProfileName ?? '',
            importResult.projectsCount,
            importResult.rootsCount,
            importResult.releasesCount,
          );
        } else {
          message = AppLocalizations.of(context)!.backupImportedSuccessfully(
            importResult.projectsCount,
            importResult.rootsCount,
            importResult.releasesCount,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToImportBackup(e.toString()))),
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Project folders — mixdown folders, export, scan roots, excluded folders
  // ---------------------------------------------------------------------

  Future<void> _addMixdownFolder(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final current = ref.read(customMixdownFoldersProvider).value ?? const <String>[];
    if (current.any((f) => f.toLowerCase() == trimmed.toLowerCase())) {
      _newMixdownFolderCtrl.clear();
      return;
    }
    final repo = await ref.read(repositoryProvider.future);
    await repo.setCustomMixdownFolders([...current, trimmed]);
    ref.invalidate(customMixdownFoldersProvider);
    _newMixdownFolderCtrl.clear();
  }

  Future<void> _removeMixdownFolder(String folder) async {
    final current = ref.read(customMixdownFoldersProvider).value ?? const <String>[];
    final repo = await ref.read(repositoryProvider.future);
    await repo.setCustomMixdownFolders(current.where((f) => f != folder).toList());
    ref.invalidate(customMixdownFoldersProvider);
  }

  TextEditingController _mixdownFolderCtrlFor(String dawKey) =>
      _mixdownFolderByDawCtrls.putIfAbsent(dawKey, () => TextEditingController());

  Future<void> _addMixdownFolderForDaw(String dawKey, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final current = ref.read(customMixdownFoldersByDawProvider).value ?? const <String, List<String>>{};
    final existing = current[dawKey] ?? const <String>[];
    if (existing.any((f) => f.toLowerCase() == trimmed.toLowerCase())) {
      _mixdownFolderCtrlFor(dawKey).clear();
      return;
    }
    final repo = await ref.read(repositoryProvider.future);
    await repo.setCustomMixdownFoldersByDaw({
      ...current,
      dawKey: [...existing, trimmed],
    });
    ref.invalidate(customMixdownFoldersByDawProvider);
    _mixdownFolderCtrlFor(dawKey).clear();
  }

  Future<void> _removeMixdownFolderForDaw(String dawKey, String folder) async {
    final current = ref.read(customMixdownFoldersByDawProvider).value ?? const <String, List<String>>{};
    final existing = current[dawKey] ?? const <String>[];
    final repo = await ref.read(repositoryProvider.future);
    await repo.setCustomMixdownFoldersByDaw({
      ...current,
      dawKey: existing.where((f) => f != folder).toList(),
    });
    ref.invalidate(customMixdownFoldersByDawProvider);
  }

  /// Every project's parts as one flat sheet — the shape people actually want
  /// when handing recording progress to a bandmate or a studio. [asXlsx]
  /// picks the formatted workbook over plain CSV.
  Future<void> _exportAllParts({required bool asXlsx}) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = await ref.read(repositoryProvider.future);
    final projects = repo.getAllProjects();
    final partCount = ProjectPartsCsvExportService.partCount(projects);

    if (partCount == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noPartsToExport)),
        );
      }
      return;
    }

    try {
      final destPath = await FilePicker.saveFile(
        dialogTitle: asXlsx ? l10n.exportAllPartsXlsx : l10n.exportAllPartsCsv,
        fileName: asXlsx
            ? ProjectPartsXlsxExportService.suggestedBulkFileName()
            : ProjectPartsCsvExportService.suggestedBulkFileName(),
        type: FileType.custom,
        allowedExtensions: [asXlsx ? 'xlsx' : 'csv'],
      );
      if (destPath == null) return; // user cancelled

      if (asXlsx) {
        final workbook =
            ProjectPartsXlsxExportService.buildWorkbook(projects, l10n);
        if (workbook == null) return;
        await File(destPath).writeAsBytes(workbook);
      } else {
        await File(destPath).writeAsString(
          ProjectPartsCsvExportService.formatProjects(projects, l10n),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.partsCsvExported(partCount))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToExportProjectInfo(e.toString()))),
        );
      }
    }
  }

  Future<void> _exportAllProjectsInfo() async {
    final l10n = AppLocalizations.of(context)!;
    final repo = await ref.read(repositoryProvider.future);
    final projects = repo.getAllProjects();

    if (projects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noProjectsToExport)),
        );
      }
      return;
    }

    try {
      final text = ProjectTextExportService.formatProjects(projects, l10n);
      final destPath = await FilePicker.saveFile(
        dialogTitle: l10n.exportAllProjectsInfo,
        fileName: ProjectTextExportService.suggestedBulkFileName(),
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      if (destPath == null) return; // user cancelled

      await File(destPath).writeAsString(text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.allProjectsInfoExported(projects.length))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToExportProjectInfo(e.toString()))),
        );
      }
    }
  }

  Future<void> _scanOnlyFolder(ProjectRepository repo, String folderId, String folderPath) async {
    final found = await importProjectsFromRoot(repo, folderId, folderPath);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final msg = found == 0
        ? l10n.noProjectsFoundInRoots
        : l10n.scanComplete(l10n.rescan, found, found == 1 ? '' : 's');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addProjectFolder() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;

    final picked = await FilePicker.getDirectoryPath(dialogTitle: l10n.selectProjectsFolder);
    if (picked == null) return;

    // Reject if this exact folder is already a scan root.
    final existingRoots = ref.read(scanRootsProvider);
    final pickedNorm = p.normalize(picked);
    if (existingRoots.any((r) => p.normalize(r.path) == pickedNorm)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.folderAlreadyAdded)),
        );
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      final root = await repo.addRoot(picked);

      ref.invalidate(rootsWatchProvider);
      ref.invalidate(scanRootsProvider);

      // Scan only the newly-added folder
      await _scanOnlyFolder(repo, root.id, root.path);

      ref.invalidate(allProjectsStreamProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorAddingFolder(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _relocateProjectFolder(String folderId, String oldPath) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;

    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.relocateFolderDialogTitle,
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      final count = await repo.relocateRoot(folderId, picked);
      ref.invalidate(rootsWatchProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(allProjectsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.relocateFolderSuccess(count))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorAddingFolder(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _renameProjectFolder(String folderId, String currentName) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.renameProjectFolderTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.renameButton),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || !mounted) return;

    final repo = await ref.read(repositoryProvider.future);
    await repo.setRootDisplayName(folderId, newName);
    ref.invalidate(scanRootsProvider);
  }

  Future<void> _removeProjectFolder(String folderId) async {
    if (_busy) return;

    final l10n = AppLocalizations.of(context)!;
    final folders = ref.read(scanRootsProvider);
    final folder = folders.where((r) => r.id == folderId).toList();
    final folderPath = folder.isNotEmpty ? folder.first.path : '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.removeProjectFolderTitle),
        content: Text(l10n.removeProjectFolderMessage(folderPath)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.removeRoot(folderId);
      ref.invalidate(rootsWatchProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(allProjectsStreamProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateScanMode(ScanRoot root, ScanMode newMode) async {
    if (newMode == root.scanMode) return;
    final repo = await ref.read(repositoryProvider.future);

    // Version Stack restructures rows rather than redrawing them, so the user
    // sees what it would do before it happens. Only worth asking when it would
    // actually stack something — with nothing to group, the switch is inert
    // and a dialog would be pure friction.
    var plan = const <AutoStackPlanEntry>[];
    if (newMode == ScanMode.versionStack) {
      plan = repo.planAutoStack([root.path]);
      if (plan.isNotEmpty) {
        if (!mounted) return;
        final confirmed = await showAutoStackConfirmDialog(context, plan: plan);
        if (confirmed != true) return;
      }
    }

    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await repo.updateRootScanMode(root.id, newMode);
      // Applied straight away rather than at the next scan — the setting reads
      // as a statement about the library, so leaving the list unchanged looks
      // like it failed. The plan is the one the user just approved, so what
      // happens is exactly what they were shown.
      if (plan.isNotEmpty) await repo.applyAutoStackPlan(plan);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(allProjectsStreamProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showScanModeInfo(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.scanModeSectionTitle),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.scanModeSectionDescription),
                const SizedBox(height: 16),
                Text(l10n.scanModeFlat, style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(l10n.scanModeFlatDescription, style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 6),
                const _FlatModePreview(),
                const SizedBox(height: 16),
                Text(l10n.scanModeSmartFolder, style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(l10n.scanModeSmartFolderDescription, style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 6),
                const _SmartFolderModePreview(),
                const SizedBox(height: 16),
                Text(l10n.scanModeVersionStack, style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(l10n.scanModeVersionStackDescription, style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 6),
                const _VersionStackModePreview(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _addExcludedFolder() async {
    if (_busy) return;

    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.getDirectoryPath(dialogTitle: l10n.selectExcludedFolder);
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.addIgnoredPath(picked);
      ref.invalidate(ignoredPathsWatchProvider);
      ref.invalidate(ignoredPathsProvider);
      ref.invalidate(allProjectsStreamProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeExcludedFolder(String excludedId) async {
    if (_busy) return;

    final l10n = AppLocalizations.of(context)!;
    final excludedFolders = ref.read(ignoredPathsProvider);
    final excluded = excludedFolders.where((p) => p.id == excludedId).toList();
    final excludedPath = excluded.isNotEmpty ? excluded.first.path : '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.removeExcludedFolderTitle),
        content: Text(
          excludedPath.isEmpty ? l10n.removeExcludedFolderMessageNoPath : l10n.removeExcludedFolderMessage(excludedPath),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.removeIgnoredPath(excludedId);
      ref.invalidate(ignoredPathsWatchProvider);
      ref.invalidate(ignoredPathsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------
  // Phases
  // ---------------------------------------------------------------------

  Future<void> _savePhases(List<String> phases) async {
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    await repo.setCustomPhases(phases);
    ref.invalidate(customPhasesProvider);
  }

  Future<void> _saveColor(String phase, Color color) async {
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    final current = Map<String, String>.from(repo.getPhaseColors());
    current[phase] = colorToHex(color);
    await repo.setPhaseColors(current);
    ref.invalidate(phaseColorsProvider);
  }

  Future<void> _resetPhasesToDefaults() async {
    const defaults = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];
    final defaultSet = defaults.toSet();

    // Find projects using phases that won't exist after the reset
    final projects = ref.read(projectsProvider);
    final customPhases = ref.read(customPhasesProvider);
    final orphanedPhases = customPhases
        .where((p) => !defaultSet.contains(p))
        .where((p) => projects.any((proj) => proj.status == p))
        .toList();

    if (!mounted) return;
    final affected = projects.where((proj) => orphanedPhases.contains(proj.status)).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.resetToDefaults),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orphanedPhases.isNotEmpty ? l10n.resetPhasesWarning(affected) : l10n.resetPhasesConfirm),
              if (orphanedPhases.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: orphanedPhases
                      .map((p) => Chip(
                            label: Text(p, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: theme.dividerColor),
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.resetPhasesWarningNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.resetToDefaults),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    await repo.setCustomPhases(defaults);
    await repo.setPhaseColors({});
    await repo.setFinishedPhases({'Finished'});
    ref.invalidate(customPhasesProvider);
    ref.invalidate(phaseColorsProvider);
    ref.invalidate(finishedPhaseProvider);
  }

  Future<void> _toggleFinishedPhase(String phase, Set<String> current) async {
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    final updated = Set<String>.from(current);
    if (updated.contains(phase)) {
      if (updated.length > 1) updated.remove(phase);
    } else {
      updated.add(phase);
    }
    await repo.setFinishedPhases(updated);
    ref.invalidate(finishedPhaseProvider);
  }

  Future<void> _deletePhase(String phase, List<String> current) async {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.read(projectsProvider);
    final count = projects.where((p) => p.status == phase).length;
    if (count > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deletePhaseWarning(count))),
      );
    }
    final updated = List<String>.from(current)..remove(phase);
    await _savePhases(updated);
  }

  Future<void> _addPhase(List<String> current) async {
    final l10n = AppLocalizations.of(context)!;
    final name = _addPhaseController.text.trim();
    if (name.isEmpty) return;
    if (current.any((p) => p.toLowerCase() == name.toLowerCase())) {
      setState(() => _addPhaseError = l10n.phaseDuplicateError);
      return;
    }
    setState(() => _addPhaseError = null);
    _addPhaseController.clear();
    await _savePhases([...current, name]);
  }

  Future<void> _pickColor(
    String phase,
    Color currentColor,
    List<String> phases,
  ) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        phaseName: phase,
        currentColor: currentColor,
      ),
    );
    if (picked != null) await _saveColor(phase, picked);
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  // Single source of truth for nav/rendering order. Doesn't need
  // AppLocalizations — just identifiers — so it's also safe to call from
  // _activeSection's initializer, before the widget tree (and l10n) exists.
  // Everyday workspace settings first, then data/danger-zone, then
  // reference material (shortcuts/about) last; DAW Locations sits with the
  // other "where things live on disk" settings right after Project Folders.
  // newGroup (below, in _navItemFor) draws a divider in the nav rail
  // immediately above an item, visually separating loose categories without
  // needing text headers.
  List<SettingsSection> _sectionOrder() => [
        SettingsSection.general,
        SettingsSection.appearance,
        SettingsSection.projectFolders,
        // Desktop only. On Linux this is usually required (no dependable OS
        // file association for most DAWs); on Windows/macOS it's a fallback
        // for when the standard "Launch in DAW" fails. Mobile has no DAW to
        // point at.
        if (MobileUtils.isDesktop()) SettingsSection.dawLaunchCommands,
        SettingsSection.mixdownFolders,
        SettingsSection.phases,
        SettingsSection.workSessions,
        SettingsSection.backup,
        SettingsSection.dangerZone,
        SettingsSection.shortcuts,
        SettingsSection.about,
      ];

  SectionNavItem _navItemFor(SettingsSection id, AppLocalizations l10n) {
    switch (id) {
      case SettingsSection.general:
        return SectionNavItem(icon: Icons.tune_outlined, label: l10n.general);
      case SettingsSection.appearance:
        return SectionNavItem(icon: Icons.palette_outlined, label: l10n.appearanceTabLabel);
      case SettingsSection.projectFolders:
        return SectionNavItem(icon: Icons.folder_outlined, label: l10n.roots);
      case SettingsSection.dawLaunchCommands:
        return SectionNavItem(icon: Icons.terminal_outlined, label: l10n.dawLaunchCommandsTabLabel);
      case SettingsSection.mixdownFolders:
        return SectionNavItem(icon: Icons.audio_file_outlined, label: l10n.mixdownFoldersTabLabel);
      case SettingsSection.phases:
        return SectionNavItem(icon: Icons.timeline_outlined, label: l10n.phases);
      case SettingsSection.workSessions:
        return SectionNavItem(icon: Icons.bookmark_outlined, label: l10n.workSessionsTabLabel);
      case SettingsSection.backup:
        return SectionNavItem(icon: Icons.backup_outlined, label: l10n.backupTabLabel, newGroup: true);
      case SettingsSection.dangerZone:
        return SectionNavItem(icon: Icons.warning_amber_rounded, label: l10n.pathsSettingsDangerZoneTitle);
      case SettingsSection.shortcuts:
        return SectionNavItem(icon: Icons.keyboard_outlined, label: l10n.keyboardShortcuts, newGroup: true);
      case SettingsSection.about:
        return SectionNavItem(icon: Icons.info_outline, label: l10n.aboutTabLabel);
    }
  }

  List<SectionNavItem> _navItems(AppLocalizations l10n) =>
      _sectionOrder().map((id) => _navItemFor(id, l10n)).toList();

  Widget Function(AppLocalizations) _builderFor(SettingsSection id) {
    switch (id) {
      case SettingsSection.general:
        return _buildGeneralSection;
      case SettingsSection.appearance:
        return _buildAppearanceSection;
      case SettingsSection.projectFolders:
        return _buildProjectFoldersSection;
      case SettingsSection.dawLaunchCommands:
        return _buildDawLaunchCommandsSection;
      case SettingsSection.mixdownFolders:
        return _buildMixdownFoldersSection;
      case SettingsSection.phases:
        return _buildPhasesSection;
      case SettingsSection.workSessions:
        return _buildWorkSessionsSection;
      case SettingsSection.backup:
        return _buildBackupSection;
      case SettingsSection.dangerZone:
        return _buildDangerZoneSection;
      case SettingsSection.shortcuts:
        return _buildShortcutsSection;
      case SettingsSection.about:
        return _buildAboutSection;
    }
  }

  List<Widget Function(AppLocalizations)> get _sectionBuilders =>
      _sectionOrder().map(_builderFor).toList();

  /// Flat index of searchable setting labels, used only to power the search
  /// box's cross-section results — not tied to the live widgets themselves.
  List<_SearchEntry> _searchIndex(AppLocalizations l10n) => [
        _SearchEntry(SettingsSection.general, Icons.tune_outlined, l10n.general, null),
        _SearchEntry(SettingsSection.general, Icons.lightbulb_outline, l10n.showSuggestions, l10n.showSuggestionsDescription),
        _SearchEntry(SettingsSection.general, Icons.palette_outlined, l10n.lastModifiedColors, l10n.lastModifiedColorsDescription),
        _SearchEntry(SettingsSection.general, Icons.dock_outlined, l10n.closeToTray, l10n.closeToTrayDescription),
        _SearchEntry(SettingsSection.general, Icons.power_settings_new, l10n.autoStart, l10n.autoStartDescription),
        _SearchEntry(SettingsSection.general, Icons.minimize, l10n.startMinimized, l10n.startMinimizedDescription),
        _SearchEntry(SettingsSection.general, Icons.language, l10n.language, l10n.languageSettingDescription),
        _SearchEntry(SettingsSection.general, Icons.table_chart_outlined, l10n.metadataExtractionTitle, l10n.metadataExtractionSubtitle),
        _SearchEntry(SettingsSection.general, Icons.restart_alt, l10n.resetOnboarding, null),
        _SearchEntry(SettingsSection.appearance, Icons.palette_outlined, l10n.theme, l10n.themeSettingDescription),
        _SearchEntry(SettingsSection.appearance, Icons.view_sidebar_outlined, l10n.projectDetailLayout, l10n.projectDetailLayoutSettingDescription),
        _SearchEntry(SettingsSection.appearance, Icons.graphic_eq, l10n.waveformStyle, l10n.waveformStyleSettingDescription),
        _SearchEntry(SettingsSection.appearance, Icons.equalizer, l10n.waveformChannels, l10n.waveformChannelsSettingDescription),
        _SearchEntry(SettingsSection.appearance, Icons.tab_outlined, l10n.customizeTabs, l10n.customizeTabsDescription),
        _SearchEntry(SettingsSection.appearance, Icons.view_sidebar_outlined, l10n.tabPosition, null),
        _SearchEntry(SettingsSection.appearance, Icons.event_busy_outlined, l10n.hideDatesInNames, l10n.hideDatesInNamesDescription),
        _SearchEntry(SettingsSection.projectFolders, Icons.folder_outlined, l10n.projectFoldersSectionTitle, l10n.projectFoldersSectionSubtitle),
        _SearchEntry(SettingsSection.projectFolders, Icons.view_agenda_outlined, l10n.scanModeSectionTitle, l10n.scanModeSectionDescription),
        _SearchEntry(SettingsSection.projectFolders, Icons.sort, l10n.excludeSmartFoldersFromSort, l10n.excludeSmartFoldersFromSortDescription),
        _SearchEntry(SettingsSection.projectFolders, Icons.merge, l10n.mergeSmartFoldersByName, l10n.mergeSmartFoldersByNameDescription),
        _SearchEntry(SettingsSection.projectFolders, Icons.visibility_outlined, l10n.alwaysShowSmartFolders, l10n.alwaysShowSmartFoldersDescription),
        _SearchEntry(SettingsSection.projectFolders, Icons.block, l10n.excludedFoldersSectionTitle, l10n.excludedFoldersSectionSubtitle),
        _SearchEntry(SettingsSection.projectFolders, Icons.description_outlined, l10n.exportAllProjectsInfo, l10n.exportAllProjectsInfoSubtitle),
        _SearchEntry(SettingsSection.projectFolders, Icons.table_view_outlined, l10n.exportAllPartsCsv, l10n.exportAllPartsCsvSubtitle),
        _SearchEntry(SettingsSection.projectFolders, Icons.grid_on, l10n.exportAllPartsXlsx, l10n.exportAllPartsXlsxSubtitle),
        if (MobileUtils.isDesktop()) ...[
          _SearchEntry(SettingsSection.dawLaunchCommands, Icons.terminal_outlined, l10n.dawLaunchCommandsTabLabel, l10n.dawLaunchCommandsSectionDescription),
        ],
        _SearchEntry(SettingsSection.mixdownFolders, Icons.audio_file_outlined, l10n.mixdownFoldersTabLabel, l10n.mixdownFoldersSectionDescription),
        _SearchEntry(SettingsSection.mixdownFolders, Icons.folder_open, l10n.previewMixdownFolderTitle, l10n.previewMixdownFolderSubtitle),
        for (final dawKey in MixdownDetectorService.dawFolders.keys)
          _SearchEntry(SettingsSection.mixdownFolders, Icons.piano_outlined, dawKey, MixdownDetectorService.dawFolders[dawKey]!.join(', ')),
        _SearchEntry(SettingsSection.phases, Icons.timeline_outlined, l10n.phases, l10n.phasesDescription),
        _SearchEntry(SettingsSection.phases, Icons.add, l10n.addPhase, null),
        _SearchEntry(SettingsSection.phases, Icons.restart_alt, l10n.resetToDefaults, null),
        _SearchEntry(SettingsSection.workSessions, Icons.bookmark_outlined, l10n.sessionMode, l10n.sessionModeDescription),
        _SearchEntry(SettingsSection.workSessions, Icons.timer_outlined, l10n.workTimerSection, l10n.workTimerSectionDesc),
        _SearchEntry(SettingsSection.backup, Icons.backup_outlined, l10n.localBackup, null),
        _SearchEntry(SettingsSection.backup, Icons.upload_file, l10n.exportBackup, null),
        _SearchEntry(SettingsSection.backup, Icons.download, l10n.importBackup, null),
        if (GoogleDriveSyncService.isSupported)
          _SearchEntry(SettingsSection.backup, Icons.cloud_outlined, l10n.googleDriveSync, null),
        _SearchEntry(SettingsSection.dangerZone, Icons.warning_amber_rounded, l10n.pathsSettingsDangerZoneTitle, l10n.pathsSettingsDangerZoneSubtitle),
        _SearchEntry(SettingsSection.dangerZone, Icons.delete_forever, l10n.clearLibrary, l10n.clearLibraryMessage),
        _SearchEntry(SettingsSection.dangerZone, Icons.delete_sweep_rounded, l10n.deleteAllData, l10n.deleteAllDataSubtitle),
        _SearchEntry(SettingsSection.shortcuts, Icons.keyboard_outlined, l10n.keyboardShortcuts, null),
        _SearchEntry(SettingsSection.about, Icons.info_outline, l10n.aboutTabLabel, l10n.appDescription),
        if (UpdateCheckService.isSupported)
          _SearchEntry(SettingsSection.about, Icons.system_update_alt_outlined, l10n.checkForUpdates, l10n.checkForUpdatesDescription),
        _SearchEntry(SettingsSection.about, Icons.favorite, l10n.donate, null),
        _SearchEntry(SettingsSection.about, Icons.web, l10n.website, null),
        _SearchEntry(SettingsSection.about, Icons.menu_book_outlined, l10n.menuDocumentation, null),
        _SearchEntry(SettingsSection.about, Icons.gavel_outlined, l10n.license, null),
        _SearchEntry(SettingsSection.about, Icons.bug_report_outlined, l10n.reportIssue, null),
        _SearchEntry(SettingsSection.about, Icons.bug_report_outlined, l10n.shareDiagnosticLog, null),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navItems = _navItems(l10n);
    final query = _searchController.text.trim();

    return Scaffold(
      body: Column(
        children: [
          DesktopTitleBar(title: l10n.settings, showBack: true),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 240,
                  child: SectionNavRail(
                    items: navItems,
                    activeIndex: _activeSection,
                    searchController: _searchController,
                    searchHint: l10n.searchSettings,
                    onTap: _selectSection,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Padding(
                    padding: MobileUtils.getResponsivePadding(context),
                    child: query.isEmpty
                        ? SingleChildScrollView(child: _sectionBuilders[_activeSection](l10n))
                        : _buildSearchResults(l10n, query),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n, String query) {
    final navItems = _navItems(l10n);
    final lowerQuery = query.toLowerCase();
    final matches = _searchIndex(l10n).where((e) {
      return e.title.toLowerCase().contains(lowerQuery) ||
          (e.subtitle?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    if (matches.isEmpty) {
      return Center(
        child: Text(
          l10n.noSettingsFoundFor(query),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final order = _sectionOrder();
    final bySection = <SettingsSection, List<_SearchEntry>>{};
    for (final entry in matches) {
      bySection.putIfAbsent(entry.section, () => []).add(entry);
    }

    final highlightStyle = TextStyle(
      fontWeight: FontWeight.w700,
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
    );

    return ListView(
      children: [
        for (final section in bySection.keys) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(navItems[order.indexOf(section)].icon, size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  navItems[order.indexOf(section)].label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final entry in bySection[section]!) ...[
                  ListTile(
                    leading: Icon(entry.icon),
                    title: Text.rich(TextSpan(
                      children: _highlightSpans(
                        entry.title,
                        query,
                        Theme.of(context).textTheme.bodyLarge,
                        highlightStyle,
                      ),
                    )),
                    subtitle: entry.subtitle == null
                        ? null
                        : Text.rich(TextSpan(
                            children: _highlightSpans(
                              entry.subtitle!,
                              query,
                              Theme.of(context).textTheme.bodySmall,
                              highlightStyle,
                            ),
                          )),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _selectSection(order.indexOf(section)),
                  ),
                  if (entry != bySection[section]!.last) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  List<InlineSpan> _highlightSpans(
    String text,
    String query,
    TextStyle? baseStyle,
    TextStyle highlightStyle,
  ) {
    if (query.isEmpty) return [TextSpan(text: text, style: baseStyle)];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <InlineSpan>[];
    var start = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: (baseStyle ?? const TextStyle()).merge(highlightStyle),
      ));
      start = idx + query.length;
    }
    return spans;
  }

  Widget _buildBackupSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Theme.of(context).cardColor,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.localBackup,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: Text(l10n.exportBackup),
                      onPressed: () => _exportBackup(),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: Text(l10n.importBackup),
                      onPressed: () => _showImportDialog(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Google Drive Sync — not offered inside Flatpak (see
        // GoogleDriveSyncService.isSupported for why: the desktop OAuth flow
        // needs a client secret that can't be shipped in the open Flatpak
        // build). A separate quick-access shortcut to the same content
        // still exists in the main window's toolbar.
        if (GoogleDriveSyncService.isSupported) ...[
          const SizedBox(height: 12),
          const GoogleDriveSyncSection(),
        ],
      ],
    );
  }

  Widget _buildGeneralSection(AppLocalizations l10n) {
    final suggestionsEnabled = ref.watch(suggestionsEnabledProvider);
    final lastModifiedColors = ref.watch(lastModifiedColorProvider);
    final closeToTray = ref.watch(closeToTrayProvider);
    final autoStart = ref.watch(autoStartProvider);
    final startMinimized = ref.watch(startMinimizedProvider);
    final currentLocale = ref.watch(localeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Only ever built in a build that may choose its library, i.e. run
        // from source. Release builds — including the pull-request builds
        // handed to testers, which are pinned to their own directory — never
        // show the picker, so they have nothing to reset here either.
        if (canPickAppDataDir) ...[
          const DevLibraryCard(),
          const SizedBox(height: 12),
        ],
        Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_outlined),
                const SizedBox(width: 10),
                Text(l10n.general, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: suggestionsEnabled,
              onChanged: (v) =>
                  ref.read(suggestionsEnabledProvider.notifier).set(v),
              title: Text(l10n.showSuggestions),
              subtitle: Text(
                l10n.showSuggestionsDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            SwitchListTile(
              value: lastModifiedColors,
              onChanged: (_) => ref.read(lastModifiedColorProvider.notifier).toggle(),
              title: Text(l10n.lastModifiedColors),
              subtitle: Text(l10n.lastModifiedColorsDescription,
                  style: Theme.of(context).textTheme.bodySmall),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            SwitchListTile(
              value: closeToTray,
              onChanged: (v) => ref.read(closeToTrayProvider.notifier).set(v),
              title: Text(l10n.closeToTray),
              subtitle: Text(l10n.closeToTrayDescription,
                  style: Theme.of(context).textTheme.bodySmall),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (AutoStartService.isSupported)
              SwitchListTile(
                value: autoStart,
                onChanged: (v) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok =
                      await ref.read(autoStartProvider.notifier).set(v);
                  if (!ok && mounted) {
                    // The switch has already snapped back to the OS's
                    // actual state — say why, so it doesn't look inert.
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.autoStartFailed)),
                    );
                  }
                },
                title: Text(l10n.autoStart),
                subtitle: Text(l10n.autoStartDescription,
                    style: Theme.of(context).textTheme.bodySmall),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            if (AutoStartService.isSupported)
              Padding(
                // Indented to read as a sub-option of the switch above,
                // which is the only thing that makes it do anything.
                padding: const EdgeInsets.only(left: 24),
                child: SwitchListTile(
                  value: startMinimized,
                  onChanged: autoStart
                      ? (v) async {
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await ref
                              .read(startMinimizedProvider.notifier)
                              .set(v);
                          if (!ok && mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.autoStartFailed)),
                            );
                          }
                        }
                      : null,
                  title: Text(l10n.startMinimized),
                  subtitle: Text(l10n.startMinimizedDescription,
                      style: Theme.of(context).textTheme.bodySmall),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.language),
              subtitle: Text(l10n.languageSettingDescription,
                  style: Theme.of(context).textTheme.bodySmall),
              trailing: DropdownButton<Locale>(
                value: currentLocale,
                underline: const SizedBox.shrink(),
                items: LanguageSwitcher.languageNames.entries.map((entry) {
                  return DropdownMenuItem<Locale>(
                    value: Locale(entry.key),
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (locale) {
                  if (locale != null) {
                    ref.read(localeProvider.notifier).setLocale(locale);
                  }
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(l10n.metadataExtractionTitle),
              subtitle: Text(l10n.metadataExtractionSubtitle,
                  style: Theme.of(context).textTheme.bodySmall),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MetadataExtractionInfoPage(),
                ),
              ),
            ),
            const Divider(height: 20),
            TextButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.resetOnboarding),
                    content: Text(l10n.resetOnboardingConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                        ),
                        child: Text(l10n.resetOnboarding),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                ref.read(onboardingCompleteProvider.notifier).reset();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingWizardPage()),
                  (route) => false,
                );
              },
              icon: Icon(Icons.restart_alt, size: 16,
                  color: Theme.of(context).colorScheme.error),
              label: Text(l10n.resetOnboarding,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
        ),
      ],
    );
  }

  Widget _buildProjectFoldersSection(AppLocalizations l10n) {
    final projectFolders = ref.watch(scanRootsProvider);
    final excludedFolders = ref.watch(ignoredPathsProvider);
    final dateFormat = ref.watch(dateFormatProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project folders section
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(l10n.projectFoldersSectionTitle, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 2),
                              IconButton(
                                tooltip: l10n.scanModeSectionTitle,
                                icon: const Icon(Icons.info_outline, size: 18),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showScanModeInfo(context, l10n),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.projectFoldersSectionSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _addProjectFolder,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addFolder),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (projectFolders.isEmpty)
                  _EmptyState(
                    icon: Icons.folder_open,
                    title: l10n.projectFoldersEmptyTitle,
                    subtitle: l10n.projectFoldersEmptySubtitle,
                    actionLabel: l10n.addFolder,
                    onAction: _busy ? null : _addProjectFolder,
                  )
                else
                  ...projectFolders.map((f) {
                    final isPortalPath = looksLikeFlatpakPortalPath(f.path);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder),
                      title: Text(f.effectiveDisplayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.path,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            f.lastScanAt == null
                                ? l10n.notScannedYet
                                : l10n.lastScan(dateFormat.format(f.lastScanAt!)),
                          ),
                          if (isPortalPath)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.flatpakPortalPathExplanation,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.scanModeLabel,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                SegmentedButton<ScanMode>(
                                  segments: [
                                    ButtonSegment(
                                      value: ScanMode.flat,
                                      label: Text(l10n.scanModeFlat),
                                    ),
                                    ButtonSegment(
                                      value: ScanMode.smartFolder,
                                      label: Text(l10n.scanModeSmartFolder),
                                    ),
                                    ButtonSegment(
                                      value: ScanMode.versionStack,
                                      label: Text(l10n.scanModeVersionStack),
                                    ),
                                  ],
                                  selected: {f.scanMode},
                                  showSelectedIcon: false,
                                  style: const ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onSelectionChanged: _busy
                                      ? null
                                      : (selection) => _updateScanMode(f, selection.first),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.renameButton,
                            onPressed: _busy ? null : () => _renameProjectFolder(f.id, f.effectiveDisplayName),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: l10n.openFolder,
                            onPressed: () => FileLauncher.openFolder(f.path),
                            icon: const Icon(Icons.folder_open_outlined),
                          ),
                          IconButton(
                            tooltip: l10n.relocateFolderDialogTitle,
                            onPressed: _busy ? null : () => _relocateProjectFolder(f.id, f.path),
                            icon: const Icon(Icons.drive_file_move_outline),
                          ),
                          IconButton(
                            tooltip: l10n.remove,
                            onPressed: _busy ? null : () => _removeProjectFolder(f.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Smart Folder behavior card — global toggles only; per-folder scan
        // mode itself is now set inline on each folder row above.
        if (projectFolders.isNotEmpty)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.view_agenda_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.smartFolderOptionsSectionTitle,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              l10n.smartFolderOptionsSectionDescription,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: ref.watch(excludeSmartFoldersFromSortProvider),
                    onChanged: (v) => ref.read(excludeSmartFoldersFromSortProvider.notifier).set(v),
                    title: Text(l10n.excludeSmartFoldersFromSort),
                    subtitle: Text(
                      l10n.excludeSmartFoldersFromSortDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  SwitchListTile(
                    value: ref.watch(mergeSmartFoldersByNameProvider),
                    onChanged: (v) => ref.read(mergeSmartFoldersByNameProvider.notifier).set(v),
                    title: Text(l10n.mergeSmartFoldersByName),
                    subtitle: Text(
                      l10n.mergeSmartFoldersByNameDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  SwitchListTile(
                    value: ref.watch(alwaysShowSmartFoldersProvider),
                    onChanged: (v) => ref.read(alwaysShowSmartFoldersProvider.notifier).set(v),
                    title: Text(l10n.alwaysShowSmartFolders),
                    subtitle: Text(
                      l10n.alwaysShowSmartFoldersDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Excluded folders section
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.block),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.excludedFoldersSectionTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            l10n.excludedFoldersSectionSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _addExcludedFolder,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addExcludedFolder),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (excludedFolders.isEmpty)
                  _EmptyState(
                    icon: Icons.block,
                    title: l10n.excludedFoldersEmptyTitle,
                    subtitle: l10n.excludedFoldersEmptySubtitle,
                  )
                else
                  ...excludedFolders.map((p) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.block),
                      title: Text(p.path),
                      trailing: IconButton(
                        tooltip: l10n.remove,
                        onPressed: _busy ? null : () => _removeExcludedFolder(p.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Data / export section
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.description_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.exportAllProjectsInfo, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        l10n.exportAllProjectsInfoSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _exportAllProjectsInfo,
                  icon: const Icon(Icons.description_outlined),
                  label: Text(l10n.exportAllProjectsInfo),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        PartsExportCard(
          busy: _busy,
          onExport: ({required bool asXlsx}) =>
              _exportAllParts(asXlsx: asXlsx),
        ),
      ],
    );
  }

  Widget _buildMixdownFoldersSection(AppLocalizations l10n) {
    final customMixdownFolders = ref.watch(customMixdownFoldersProvider).value ?? const <String>[];
    final customMixdownFoldersByDaw =
        ref.watch(customMixdownFoldersByDawProvider).value ?? const <String, List<String>>{};
    final dawKeys = [
      ...MixdownDetectorService.dawFolders.keys,
      MixdownDetectorService.otherDawKey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mixdownFoldersSectionDescription, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),

        // Global custom mixdown folders — checked first, for every DAW.
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_open),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.previewMixdownFolderTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            l10n.previewMixdownFolderSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (customMixdownFolders.isEmpty)
                  Text(
                    l10n.noCustomMixdownFolders,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  ...customMixdownFolders.map((folder) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.folder_open),
                      title: Text(folder),
                      trailing: IconButton(
                        tooltip: l10n.remove,
                        onPressed: () => _removeMixdownFolder(folder),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newMixdownFolderCtrl,
                        decoration: InputDecoration(
                          hintText: l10n.previewMixdownFolderHint,
                          prefixIcon: const Icon(Icons.folder_open),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: _addMixdownFolder,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () => _addMixdownFolder(_newMixdownFolderCtrl.text),
                      child: Text(l10n.addMixdownFolder),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(l10n.mixdownFoldersDawDefaultsHeading, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(l10n.mixdownFoldersInfoDialogBody, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),

        // Per-DAW defaults + user-added folder names.
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final dawKey in dawKeys) ...[
                if (dawKey != dawKeys.first) const Divider(height: 1),
                _MixdownDawTile(
                  dawKey: dawKey,
                  displayName: dawKey == MixdownDetectorService.otherDawKey
                      ? l10n.mixdownFoldersOtherDawLabel
                      : dawKey,
                  defaultFolders: dawKey == MixdownDetectorService.otherDawKey
                      ? MixdownDetectorService.fallbackFolders
                      : MixdownDetectorService.dawFolders[dawKey]!,
                  customFolders: customMixdownFoldersByDaw[dawKey] ?? const <String>[],
                  controller: _mixdownFolderCtrlFor(dawKey),
                  defaultsLabel: l10n.mixdownFoldersDefaultsLabel,
                  customLabel: l10n.mixdownFoldersCustomLabel,
                  emptyCustomLabel: l10n.noCustomMixdownFolders,
                  addHint: l10n.previewMixdownFolderHint,
                  addLabel: l10n.addMixdownFolder,
                  removeTooltip: l10n.remove,
                  onAdd: (value) => _addMixdownFolderForDaw(dawKey, value),
                  onRemove: (folder) => _removeMixdownFolderForDaw(dawKey, folder),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDawLaunchCommandsSection(AppLocalizations l10n) {
    final launchCommands = ref.watch(dawLaunchCommandsProvider).value ??
        const <String, List<String>>{};
    final projects = ref.watch(allProjectsStreamProvider).value ?? const [];
    final dawTypes =
        <String>{
            for (final project in projects)
              if (project.dawType != null) project.dawType!,
            ...launchCommands.keys,
          }.toList()
          ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titled intro card. Kept separate from the DAW list below so more
        // DAW Locations subsections can be added as their own cards later.
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal_outlined),
                    const SizedBox(width: 10),
                    Text(
                      l10n.dawLaunchCommandsTabLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dawLaunchCommandsSectionDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (dawTypes.isEmpty)
          Text(
            l10n.dawLaunchCommandsEmptyState,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final dawType in dawTypes) ...[
                  if (dawType != dawTypes.first) const Divider(height: 1),
                  _DawLaunchCommandGroup(
                    dawType: dawType,
                    configuredPaths:
                        launchCommands[dawType] ?? const <String>[],
                    notConfiguredLabel: l10n.dawLaunchCommandNotConfigured,
                    missingTooltip: l10n.dawLaunchCommandMissingTooltip,
                    addLabel: l10n.dawLaunchCommandAddButton,
                    removeTooltip: l10n.remove,
                    onAdd: () => showDawLaunchCommandDialog(
                      context,
                      dawType: dawType,
                    ),
                    onRemovePath: (path) async {
                      final repo = await ref.read(repositoryProvider.future);
                      await repo.removeDawLaunchCommand(dawType, path);
                      ref.invalidate(dawLaunchCommandsProvider);
                    },
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhasesSection(AppLocalizations l10n) {
    final phases = ref.watch(customPhasesProvider);
    final storedColors = ref.watch(phaseColorsProvider);
    final finishedPhase = ref.watch(finishedPhaseProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline_outlined),
                    const SizedBox(width: 10),
                    Text(l10n.phases, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                TextButton(
                  onPressed: _resetPhasesToDefaults,
                  child: Text(l10n.resetToDefaults),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(l10n.phasesDescription, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: phases.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final updated = List<String>.from(phases);
                  updated.insert(newIndex, updated.removeAt(oldIndex));
                  _savePhases(updated);
                },
                itemBuilder: (context, index) {
                  final phase = phases[index];
                  final color = resolvePhaseColor(phase, storedColors, phases);
                  return ListTile(
                    key: ValueKey(phase),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_indicator,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: l10n.selectPhaseColor,
                          child: GestureDetector(
                            onTap: () => _pickColor(phase, color, phases),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(phase),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: l10n.markAsFinished,
                          child: IconButton(
                            icon: Icon(
                              finishedPhase.contains(phase)
                                  ? Icons.flag
                                  : Icons.flag_outlined,
                              color: finishedPhase.contains(phase)
                                  ? Colors.green
                                  : null,
                            ),
                            onPressed: () => _toggleFinishedPhase(phase, finishedPhase),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Theme.of(context).colorScheme.error,
                          tooltip: l10n.delete,
                          onPressed: phases.length > 1
                              ? () => _deletePhase(phase, phases)
                              : null,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Add phase row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _addPhaseController,
                    decoration: InputDecoration(
                      labelText: l10n.phaseNameHint,
                      errorText: _addPhaseError,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addPhase(phases),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _addPhase(phases),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addPhase),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkSessionsSection(AppLocalizations l10n) {
    final sessionMode = ref.watch(sessionModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_outlined),
                    const SizedBox(width: 10),
                    Text(l10n.sessionMode, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.sessionModeDescription, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                _SessionModeOption(
                  icon: Icons.open_in_new,
                  label: l10n.normalMode,
                  description: l10n.normalModeDescription,
                  selected: !sessionMode,
                  onTap: () => ref.read(sessionModeProvider.notifier).set(false),
                ),
                const SizedBox(height: 8),
                _SessionModeOption(
                  icon: Icons.bookmark_add_outlined,
                  label: l10n.sessionMode,
                  description: l10n.sessionModeCardDescription,
                  selected: sessionMode,
                  onTap: () => ref.read(sessionModeProvider.notifier).set(true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: WorkTimerSection(l10n: l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection(AppLocalizations l10n) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.pathsSettingsDangerZoneTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        l10n.pathsSettingsDangerZoneSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Theme.of(context).cardColor,
                              title: Text(l10n.clearLibrary),
                              content: Text(l10n.clearLibraryMessage),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    foregroundColor: Theme.of(context).colorScheme.onError,
                                  ),
                                  child: Text(l10n.clear),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          if (!mounted) return;

                          setState(() => _busy = true);
                          try {
                            final repo = await ref.read(repositoryProvider.future);
                            await repo.clearAllData();
                            ref.invalidate(repositoryProvider);
                            ref.invalidate(rootsWatchProvider);
                            ref.invalidate(scanRootsProvider);
                            ref.invalidate(ignoredPathsWatchProvider);
                            ref.invalidate(ignoredPathsProvider);
                            ref.invalidate(allProjectsStreamProvider);
                            await ref.read(repositoryProvider.future);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.libraryCleared)),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  icon: const Icon(Icons.delete_forever),
                  label: Text(l10n.clearLibrary),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.delete_sweep_rounded, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.deleteAllData, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        l10n.deleteAllDataSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          // First confirmation
                          final confirm1 = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Theme.of(context).cardColor,
                              title: Text(l10n.deleteAllDataConfirm1Title),
                              content: Text(l10n.deleteAllDataConfirm1Message),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    foregroundColor: Theme.of(context).colorScheme.onError,
                                  ),
                                  child: Text(l10n.deleteAllData),
                                ),
                              ],
                            ),
                          );
                          if (confirm1 != true || !mounted) return;

                          // Second confirmation
                          final confirm2 = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Theme.of(context).cardColor,
                              title: Text(l10n.deleteAllDataConfirm2Title),
                              content: Text(l10n.deleteAllDataConfirm2Message),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    foregroundColor: Theme.of(context).colorScheme.onError,
                                  ),
                                  child: Text(l10n.deleteEverything),
                                ),
                              ],
                            ),
                          );
                          if (confirm2 != true || !mounted) return;

                          setState(() => _busy = true);
                          try {
                            await ProjectRepository.deleteAllAppData();
                            // Invalidate root provider first so all dependents
                            // (currentProfileProvider, repositoryProvider, etc.)
                            // rebuild against fresh Hive boxes.
                            ref.invalidate(profileRepositoryProvider);
                            ref.invalidate(currentProfileProvider);
                            ref.invalidate(allProfilesProvider);
                            ref.invalidate(repositoryProvider);
                            ref.invalidate(rootsWatchProvider);
                            ref.invalidate(scanRootsProvider);
                            ref.invalidate(ignoredPathsWatchProvider);
                            ref.invalidate(ignoredPathsProvider);
                            ref.invalidate(allProjectsStreamProvider);
                            await ref.read(profileRepositoryProvider.future);
                            await ref.read(repositoryProvider.future);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.allDataDeleted)),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: Text(l10n.deleteAllData),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareDiagnosticLog() async {
    final files = await CrashLogger.existingLogFiles();
    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.shareDiagnosticLogEmpty)),
        );
      }
      return;
    }
    final shared = await CrashLogger.shareOrRevealLogFiles(files);
    if (!shared && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.shareDiagnosticLogFolderOpened)),
      );
    }
  }

  Future<void> _clearDiagnosticLog() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.clearDiagnosticLogConfirmTitle),
        content: Text(l10n.clearDiagnosticLogConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await CrashLogger.clearLogs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.diagnosticLogCleared)),
      );
    }
  }

  Widget _buildAboutSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('app_icon.png', width: 64, height: 64),
                const SizedBox(height: 12),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (appVersion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(l10n.versionLabel(appVersion), style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 12),
                Text(
                  l10n.appDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '© ${DateTime.now().year} Bandpass Records',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.favorite, size: 16),
                      label: Text(l10n.donate),
                    ),
                    FilledButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://dpm.bandpassrecords.com'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.web, size: 16),
                      label: Text(l10n.website),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://dpm.bandpassrecords.com/docs.html'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.menu_book_outlined, size: 16),
                      label: Text(l10n.menuDocumentation),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showLicenseDialog(context),
                      icon: const Icon(Icons.gavel_outlined, size: 16),
                      label: Text(l10n.license),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://github.com/bandpassrecords/daw-project-manager/issues/new?template=issue.yml'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.bug_report_outlined, size: 16),
                      label: Text(l10n.reportIssue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Hidden on Linux, except when running as the AppImage build (which
        // gets a real self-update instead of a GitHub-release-page link) —
        // see UpdateCheckService.isSupported.
        if (UpdateCheckService.isSupported) ...[
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.system_update_alt_outlined),
                      const SizedBox(width: 10),
                      Text(l10n.checkForUpdates, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: ref.watch(checkForUpdatesProvider),
                    onChanged: (v) => ref.read(checkForUpdatesProvider.notifier).toggle(),
                    title: Text(l10n.checkForUpdates),
                    subtitle: Text(l10n.checkForUpdatesDescription,
                        style: Theme.of(context).textTheme.bodySmall),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _checkingUpdate
                          ? null
                          : () async {
                              setState(() => _checkingUpdate = true);
                              final result = await UpdateCheckService.checkForUpdate(appVersion);
                              if (!mounted) return;
                              setState(() => _checkingUpdate = false);
                              if (result != null) {
                                ref.read(availableUpdateProvider.notifier).set(result);
                                UpdateAvailableDialog.show(context, result);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.upToDate)),
                                );
                              }
                            },
                      icon: _checkingUpdate
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(l10n.checkNow),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bug_report_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.shareDiagnosticLog, style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: ref.watch(diagnosticLoggingEnabledProvider),
                  onChanged: (v) => ref.read(diagnosticLoggingEnabledProvider.notifier).toggle(),
                  title: Text(l10n.enableDiagnosticLogging),
                  subtitle: Text(
                    l10n.enableDiagnosticLoggingDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.ios_share, size: 16),
                      label: Text(l10n.shareDiagnosticLog),
                      onPressed: _shareDiagnosticLog,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(l10n.clearDiagnosticLog),
                      onPressed: _clearDiagnosticLog,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(AppLocalizations l10n) {
    final visibleSet = ref.watch(visibleTabsProvider);
    final tabPos = ref.watch(tabPositionProvider);
    final themeType = ref.watch(themeTypeProvider);
    final hideDatesInNames = ref.watch(nameDateStrippingProvider);
    final allTabs = VisibleTabsNotifier.canonicalOrder
        .where((t) => t != AppTab.playlists) // playlists is mobile-only
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme selector. AppThemeType.studioLight is deliberately excluded —
        // it's hidden from every menu/switcher until it's ready (see CLAUDE.md).
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_outlined),
                    const SizedBox(width: 10),
                    Text(l10n.theme, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.themeSettingDescription, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                SegmentedButton<AppThemeType>(
                  segments: [
                    ButtonSegment(
                      value: AppThemeType.classicDark,
                      icon: const Icon(Icons.dark_mode_outlined, size: 16),
                      label: Text(l10n.classicDarkThemeName),
                    ),
                    ButtonSegment(
                      value: AppThemeType.neonDark,
                      icon: const Icon(Icons.bolt_outlined, size: 16),
                      label: Text(l10n.neonDarkThemeName),
                    ),
                  ],
                  selected: {themeType},
                  onSelectionChanged: (s) =>
                      ref.read(themeTypeProvider.notifier).setThemeType(s.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // How the project detail page arranges itself. Desktop only — a phone
        // has no room for a nav rail, so mobile ignores this.
        if (!MobileUtils.isMobile())
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.view_sidebar_outlined),
                      const SizedBox(width: 10),
                      Text(l10n.projectDetailLayout,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.projectDetailLayoutSettingDescription,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  SegmentedButton<ProjectDetailLayout>(
                    segments: [
                      ButtonSegment(
                        value: ProjectDetailLayout.classic,
                        icon: const Icon(Icons.view_stream_outlined, size: 16),
                        label: Text(l10n.projectDetailLayoutClassic),
                      ),
                      ButtonSegment(
                        value: ProjectDetailLayout.sectioned,
                        icon: const Icon(Icons.view_sidebar_outlined, size: 16),
                        label: Text(l10n.projectDetailLayoutSectioned),
                      ),
                    ],
                    selected: {ref.watch(projectDetailLayoutProvider)},
                    onSelectionChanged: (s) => ref
                        .read(projectDetailLayoutProvider.notifier)
                        .set(s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ref.watch(projectDetailLayoutProvider) ==
                            ProjectDetailLayout.classic
                        ? l10n.projectDetailLayoutClassicDescription
                        : l10n.projectDetailLayoutSectionedDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        if (!MobileUtils.isMobile()) const SizedBox(height: 12),
        // Waveform rendering used by every audio preview player.
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.graphic_eq),
                    const SizedBox(width: 10),
                    Text(l10n.waveformStyle,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.waveformStyleSettingDescription,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                SegmentedButton<WaveformStyle>(
                  segments: [
                    ButtonSegment(
                      value: WaveformStyle.detailed,
                      icon: const Icon(Icons.graphic_eq, size: 16),
                      label: Text(l10n.waveformStyleDetailed),
                    ),
                    ButtonSegment(
                      value: WaveformStyle.classic,
                      icon: const Icon(Icons.show_chart, size: 16),
                      label: Text(l10n.waveformStyleClassic),
                    ),
                  ],
                  selected: {ref.watch(waveformStyleProvider)},
                  onSelectionChanged: (s) =>
                      ref.read(waveformStyleProvider.notifier).set(s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  ref.watch(waveformStyleProvider) == WaveformStyle.detailed
                      ? l10n.waveformStyleDetailedDescription
                      : l10n.waveformStyleClassicDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                // Applies to both renderings — each simply draws its own
                // shape twice, in two bands.
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.equalizer, size: 20),
                    const SizedBox(width: 10),
                    Text(l10n.waveformChannels,
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.waveformChannelsSettingDescription,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.remove, size: 16),
                      label: Text(l10n.waveformChannelsSingle),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.drag_handle, size: 16),
                      label: Text(l10n.waveformChannelsDual),
                    ),
                  ],
                  selected: {ref.watch(waveformStereoProvider)},
                  onSelectionChanged: (s) =>
                      ref.read(waveformStereoProvider.notifier).set(s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  ref.watch(waveformStereoProvider)
                      ? l10n.waveformChannelsDualDescription
                      : l10n.waveformChannelsSingleDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tab_outlined),
                    const SizedBox(width: 10),
                    Text(l10n.customizeTabs, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.customizeTabsDescription, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                Text(
                  l10n.tabPosition,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TabPosition>(
                  segments: [
                    ButtonSegment(
                      value: TabPosition.left,
                      icon: const Icon(Icons.view_sidebar_outlined, size: 16),
                      label: Text(l10n.tabPositionLeft),
                    ),
                    ButtonSegment(
                      value: TabPosition.top,
                      icon: const Icon(Icons.tab, size: 16),
                      label: Text(l10n.tabPositionTop),
                    ),
                  ],
                  selected: {tabPos},
                  onSelectionChanged: (s) => ref.read(tabPositionProvider.notifier).set(s.first),
                ),
                const Divider(height: 24),
                for (final tab in allTabs)
                  CheckboxListTile(
                    value: visibleSet.contains(tab),
                    onChanged: tab == AppTab.projects
                        ? null
                        : (v) => ref.read(visibleTabsProvider.notifier).setTabVisible(tab, v ?? false),
                    secondary: Icon(_tabIcon(tab)),
                    title: Text(_tabLabel(tab, l10n)),
                    subtitle: tab == AppTab.projects
                        ? Text(
                            l10n.alwaysVisible,
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : null,
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_busy_outlined),
                    const SizedBox(width: 10),
                    Text(l10n.hideDatesInNames,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.hideDatesInNamesDescription,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: hideDatesInNames,
                  onChanged: (v) =>
                      ref.read(nameDateStrippingProvider.notifier).set(v),
                  title: Text(l10n.hideDatesInNames),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _tabIcons = {
    AppTab.projects: Icons.library_music,
    AppTab.releases: Icons.album,
    AppTab.playlists: Icons.playlist_play,
    AppTab.queue: Icons.checklist,
    AppTab.statistics: Icons.bar_chart_rounded,
    AppTab.player: Icons.headphones,
  };

  IconData _tabIcon(AppTab tab) => _tabIcons[tab]!;

  String _tabLabel(AppTab tab, AppLocalizations l10n) => switch (tab) {
        AppTab.projects => l10n.projectsTab,
        AppTab.releases => l10n.releasesTab,
        AppTab.playlists => l10n.playlists,
        AppTab.queue => l10n.queueTab,
        AppTab.statistics => l10n.statisticsTab,
        AppTab.player => l10n.musicPlayerTab,
      };

  Widget _buildShortcutsSection(AppLocalizations l10n) {
    final isMac = Platform.isMacOS;
    final mod = isMac ? '⌘' : 'Ctrl';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.keyboard_outlined),
                const SizedBox(width: 10),
                Text(l10n.keyboardShortcuts, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ShortcutGroup(
              label: l10n.shortcutGroupGlobal,
              entries: [
                ShortcutEntry(keys: [mod, 'F'], description: l10n.shortcutFocusSearch),
                ShortcutEntry(keys: [mod, 'R'], description: l10n.shortcutRescan),
                ShortcutEntry(keys: [mod, 'T'], description: l10n.shortcutFocusTable),
              ],
            ),
            ShortcutGroup(
              label: l10n.shortcutGroupProjectsTable,
              entries: [
                ShortcutEntry(keys: ['P'], description: l10n.shortcutPlayPause),
                ShortcutEntry(keys: ['D'], description: l10n.shortcutViewDetails),
                ShortcutEntry(keys: ['F'], description: l10n.shortcutOpenFolder),
                ShortcutEntry(keys: ['↑ / ↓'], description: l10n.shortcutNavigateRows),
                ShortcutEntry(keys: ['Enter'], description: l10n.shortcutEditCell),
              ],
            ),
            ShortcutGroup(
              label: '↳ ${l10n.shortcutGroupProjectsTableStandardMode}',
              entries: [
                ShortcutEntry(keys: ['O'], description: l10n.shortcutOpenInDaw),
              ],
            ),
            ShortcutGroup(
              label: '↳ ${l10n.shortcutGroupProjectsTableSessionMode}',
              entries: [
                ShortcutEntry(keys: ['S'], description: l10n.shortcutToggleSession),
              ],
            ),
            ShortcutGroup(
              label: l10n.shortcutGroupReleasesTable,
              entries: [
                ShortcutEntry(keys: ['D'], description: l10n.shortcutViewRelease),
                ShortcutEntry(keys: ['Enter'], description: l10n.shortcutViewRelease),
              ],
            ),
            ShortcutGroup(
              label: l10n.shortcutGroupPreviewPlayer,
              entries: [
                ShortcutEntry(keys: ['Space'], description: l10n.shortcutPlayerPlayPause),
                ShortcutEntry(keys: ['←  /  →'], description: l10n.shortcutPlayerSeek5),
                ShortcutEntry(keys: [isMac ? '⌃' : 'Ctrl', '←  /  →'], description: l10n.shortcutPlayerSeek30),
              ],
            ),
            ShortcutGroup(
              label: l10n.shortcutGroupNavigation,
              entries: [
                if (isMac) ShortcutEntry(keys: ['⌘', '←'], description: l10n.shortcutGoBack),
                ShortcutEntry(
                  keys: [isMac ? '⌥' : 'Alt', '←'],
                  description: l10n.shortcutGoBack,
                ),
              ],
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Left nav rail — a search box pinned on top, then one tab per section.
// Picking a tab swaps which section renders on the right; it never scrolls.
// ---------------------------------------------------------------------------

/// One searchable setting, indexed only for the search box's flattened
/// cross-section results — not connected to the live widget tree.
class _SearchEntry {
  final SettingsSection section;
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SearchEntry(this.section, this.icon, this.title, this.subtitle);
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                if (actionLabel != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mixdown Folders — one expandable row per DAW showing its built-in default
// folder names plus an editor for user-added ones.
// ---------------------------------------------------------------------------

class _MixdownDawTile extends StatelessWidget {
  final String dawKey;
  final String displayName;
  final List<String> defaultFolders;
  final List<String> customFolders;
  final TextEditingController controller;
  final String defaultsLabel;
  final String customLabel;
  final String emptyCustomLabel;
  final String addHint;
  final String addLabel;
  final String removeTooltip;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _MixdownDawTile({
    required this.dawKey,
    required this.displayName,
    required this.defaultFolders,
    required this.customFolders,
    required this.controller,
    required this.defaultsLabel,
    required this.customLabel,
    required this.emptyCustomLabel,
    required this.addHint,
    required this.addLabel,
    required this.removeTooltip,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final logoPath = getDawLogoPath(dawKey);
    return ExpansionTile(
      leading: logoPath != null
          ? Image.asset(logoPath, width: 24, height: 24)
          : const Icon(Icons.piano_outlined),
      title: Text(displayName),
      subtitle: Text(
        defaultFolders.join(', '),
        style: Theme.of(context).textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(defaultsLabel, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: defaultFolders.map((f) => Chip(label: Text(f))).toList(),
        ),
        const SizedBox(height: 16),
        Text(customLabel, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        if (customFolders.isEmpty)
          Text(emptyCustomLabel, style: Theme.of(context).textTheme.bodySmall)
        else
          ...customFolders.map((folder) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.folder_open),
              title: Text(folder),
              trailing: IconButton(
                tooltip: removeTooltip,
                onPressed: () => onRemove(folder),
                icon: const Icon(Icons.delete_outline),
              ),
            );
          }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: addHint,
                  prefixIcon: const Icon(Icons.folder_open),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: onAdd,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => onAdd(controller.text),
              child: Text(addLabel),
            ),
          ],
        ),
      ],
    );
  }
}

/// One DAW's block in the DAW Locations list: its name, every configured
/// override path (each with a "no longer exists" warning and a remove
/// button), and an "Add location" action. A DAW with several paths makes the
/// launcher ask which to use.
class _DawLaunchCommandGroup extends StatelessWidget {
  final String dawType;
  final List<String> configuredPaths;
  final String notConfiguredLabel;
  final String missingTooltip;
  final String addLabel;
  final String removeTooltip;
  final VoidCallback onAdd;
  final Future<void> Function(String path) onRemovePath;

  const _DawLaunchCommandGroup({
    required this.dawType,
    required this.configuredPaths,
    required this.notConfiguredLabel,
    required this.missingTooltip,
    required this.addLabel,
    required this.removeTooltip,
    required this.onAdd,
    required this.onRemovePath,
  });

  @override
  Widget build(BuildContext context) {
    final logoPath = getDawLogoPath(dawType);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              logoPath != null
                  ? Image.asset(
                      logoPath,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stack) =>
                          const Icon(Icons.piano_outlined),
                    )
                  : const Icon(Icons.piano_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dawType,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(addLabel),
              ),
            ],
          ),
          if (configuredPaths.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: Text(
                notConfiguredLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final path in configuredPaths)
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Row(
                  children: [
                    if (!FileLauncher.targetExists(path)) ...[
                      Tooltip(
                        message: missingTooltip,
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade400,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        path,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: removeTooltip,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onRemovePath(path),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Scan mode preview mockups — shown once in the shared "Scan Mode" info
// dialog (see _showScanModeInfo) rather than duplicated per folder.
// ---------------------------------------------------------------------------

// Flat mode preview — simple rows, no grouping
class _FlatModePreview extends StatelessWidget {
  const _FlatModePreview();

  @override
  Widget build(BuildContext context) {
    const rows = ['Song Alpha', 'Song Beta', 'Remix Final', 'Dark Ambient'];
    return _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .map((name) => _PreviewRow(icon: Icons.music_note, label: name))
            .toList(),
      ),
    );
  }
}

// Smart Folder mode preview — groups when >1, flat otherwise
class _SmartFolderModePreview extends StatelessWidget {
  const _SmartFolderModePreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewRow(icon: Icons.folder_open, label: 'EP Project', bold: true),
          _PreviewRow(icon: Icons.music_note, label: 'Track 01', indent: true),
          _PreviewRow(icon: Icons.music_note, label: 'Track 02', indent: true, last: true),
          _PreviewRow(icon: Icons.music_note, label: 'Song Alpha'),
          _PreviewRow(icon: Icons.folder_open, label: 'Album', bold: true),
          _PreviewRow(icon: Icons.music_note, label: 'Intro', indent: true),
          _PreviewRow(icon: Icons.music_note, label: 'Chorus', indent: true, last: true),
        ],
      ),
    );
  }
}

/// Version Stack: the *folder* becomes the main-project row, and the files
/// inside it become versions of it — the same tree as Smart Folder, but the
/// group row is a real project that owns the metadata rather than a display
/// grouping.
class _VersionStackModePreview extends StatelessWidget {
  const _VersionStackModePreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewRow(icon: Icons.layers, label: 'Song Alpha  ·  3', bold: true),
          _PreviewRow(icon: Icons.music_note, label: 'Alpha v1', indent: true),
          _PreviewRow(icon: Icons.music_note, label: 'Alpha v2', indent: true),
          _PreviewRow(icon: Icons.music_note, label: 'Alpha v3', indent: true, last: true),
          _PreviewRow(icon: Icons.layers, label: 'Song Beta  ·  2', bold: true),
          _PreviewRow(icon: Icons.music_note, label: 'Beta rough', indent: true),
          _PreviewRow(icon: Icons.music_note, label: 'Beta final', indent: true, last: true),
        ],
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  final Widget child;
  const _PreviewFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: child,
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool indent;
  final bool bold;
  final bool last;

  const _PreviewRow({
    required this.icon,
    required this.label,
    this.indent = false,
    this.bold = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.only(left: indent ? 14.0 : 0, bottom: 2),
      child: Row(
        children: [
          if (indent) ...[
            Text(
              last ? '└ ' : '├ ',
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.4), fontFamily: 'monospace'),
            ),
          ],
          Icon(icon, size: 12, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: bold ? 0.9 : 0.7),
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session mode selector — Normal vs Session mode, stacked as plain
// icon + label + description rows (no mockup preview — see history for why).
// ---------------------------------------------------------------------------

class _SessionModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _SessionModeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected ? colorScheme.primary : colorScheme.outlineVariant;
    final bgColor = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.25)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: 10),
              Icon(
                icon,
                size: 18,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected ? colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase color picker dialog
// ---------------------------------------------------------------------------

class _ColorPickerDialog extends StatelessWidget {
  final String phaseName;
  final Color currentColor;

  const _ColorPickerDialog({
    required this.phaseName,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(phaseName),
      content: SizedBox(
        width: 220,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kPhaseColorPalette.map((color) {
            final isSelected = color.toARGB32() == currentColor.toARGB32();
            return GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: ThemeData.estimateBrightnessForColor(color) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
