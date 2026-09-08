import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// NOVO IMPORT
import 'package:path/path.dart' as p; // NOVO IMPORT
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

import 'package:uuid/uuid.dart';

import '../models/music_project.dart';
import '../models/project_detail_layout.dart';
import '../models/project_event.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../utils/daw_logo.dart';
import '../utils/mobile_utils.dart';
import '../utils/file_launcher.dart';
import '../utils/playback_seek.dart';
import '../utils/route_observer.dart';
import '../generated/l10n/app_localizations.dart';
import 'marker_navigation.dart';
import 'session_actions.dart';
import 'settings_page.dart' show SettingsPage, SettingsSection;
import 'preview_share.dart';
import 'dialogs/preview_song_not_found_dialog.dart';
import '../services/audio_analysis_service.dart';
import '../services/metadata_extractor.dart';
import '../services/metadata_sidecar_service.dart';
import '../services/mixdown_detector_service.dart';
import '../services/project_text_export_service.dart';
import '../services/scanner_service.dart';
import 'dialogs/save_as_template_dialog.dart';
import 'dialogs/stack_version_picker_dialog.dart';
import 'widgets/conversion_progress_dialog.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/project_detail_header.dart';
import 'widgets/project_markers_section.dart';
import 'widgets/project_versions_section.dart';
import 'widgets/section_nav_rail.dart';
import 'widgets/resizable_text_field.dart';
import 'widgets/parts_summary_card.dart';
import 'widgets/todo_list_widget.dart';
import 'widgets/waveform_widget.dart';
import 'project_statistics_page.dart';

/// The project with [projectId], or null when it is not in [projects].
///
/// Null is a normal outcome, not an error: the row this page shows can be
/// deleted underneath it — unstacking removes the stack, and "Delete Missing"
/// or a Drive restore can remove any project. The stream rebuilds the page
/// before the pop that follows has run, so a `firstWhere` without an `orElse`
/// here throws "Bad state: No element" mid-frame.
@visibleForTesting
MusicProject? findProjectById(List<MusicProject> projects, String projectId) {
  for (final project in projects) {
    if (project.id == projectId) return project;
  }
  return null;
}

class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();

  /// Which section the nav rail has selected, in the sectioned layout.
  /// Ignored entirely by the classic one-scroll layout.
  int _activeSection = 0;
  late TextEditingController _nameCtrl;
  late TextEditingController _bpmCtrl;
  late TextEditingController _keyCtrl;
  late TextEditingController _notesCtrl; // NOVO CONTROLLER
  late TextEditingController _projectNotesCtrl;
  late FocusNode _nameFocusNode;
  late FocusNode _bpmFocusNode;
  late FocusNode _keyFocusNode;
  late FocusNode _notesFocusNode;
  String? _lastSavedName;
  String? _lastSavedBpm;
  String? _lastSavedKey;
  String? _lastSavedNotes;
  String? _selectedPhase;

  bool _hasInitializedPhase = false;
  bool _extractingMetadata = false;
  Timer? _autoSaveTimer;

  /// Records status-change and/or metadata-edit events after saving a project.
  Future<void> _recordSaveEvents(
    ProjectRepository repo,
    MusicProject oldProject,
    MusicProject newProject,
    String newStatus,
    bool statusChanged,
  ) async {
    final now = DateTime.now();
    if (statusChanged) {
      await repo.addEvent(ProjectEvent(
        id: _uuid.v4(),
        projectId: newProject.id,
        eventType: ProjectEvent.statusChange,
        occurredAt: now,
        payload: jsonEncode({'from': oldProject.status, 'to': newStatus}),
      ));
    }
    final changedFields = <String>[];
    if (oldProject.customDisplayName != newProject.customDisplayName) {
      changedFields.add('name');
    }
    if (oldProject.bpm != newProject.bpm) changedFields.add('bpm');
    if (oldProject.musicalKey != newProject.musicalKey) changedFields.add('key');
    if (oldProject.notes != newProject.notes) changedFields.add('notes');
    if (oldProject.deadline != newProject.deadline) changedFields.add('deadline');
    if (changedFields.isNotEmpty) {
      await repo.addEvent(ProjectEvent(
        id: _uuid.v4(),
        projectId: newProject.id,
        eventType: ProjectEvent.metadataEdit,
        occurredAt: now,
        payload: jsonEncode({'fields': changedFields}),
      ));
    }
  }


  // --- Version stacking (#94) ---------------------------------------------
  //
  // A stack is a virtual project owning the shared metadata for several real
  // files. All four actions below write through the repository and then
  // invalidate the projects stream, because membership changes rewrite rows
  // other than the one this page is showing.

  /// Adds a version to [project].
  ///
  /// Handles both directions this can be reached from: [project] is already a
  /// stack, in which case the chosen file joins it — or [project] is an
  /// ordinary project, in which case picking a second file *starts* a stack
  /// from the two. The second case is why the Versions section is offered on
  /// unstacked projects at all: a song is often recognised as having versions
  /// while looking at one of them, not while multi-selecting in the grid.
  Future<void> _addVersionToStack(
    ProjectRepository repo,
    MusicProject project,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Anything real and not already spoken for, minus this project itself.
    // A project can only belong to one stack, so offering a stacked one would
    // just throw in the repository.
    final candidates =
        repo.projectsBox.values
            .where(
              (p) =>
                  !p.isVirtual && !p.isStackMember && p.id != project.id,
            )
            .toList()
          ..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );

    // Multi-select: a project with five revision files needs all four
    // siblings attached, and one dialog per sibling is four times the work.
    final chosen = await showStackVersionMultiPickerDialog(
      context,
      title: l10n.stackAddVersionMultiTitle,
      candidates: candidates,
      emptyLabel: l10n.stackAddVersionEmpty,
      subtitleBuilder: (p) => p.filePath,
    );
    if (chosen.isEmpty) return;

    if (project.isVirtual) {
      for (final version in chosen) {
        await repo.addToStack(stackId: project.id, projectId: version.id);
      }
      if (mounted) ref.invalidate(allProjectsStreamProvider);
      return;
    }

    // Starting a stack from this project. It becomes the main project without
    // asking: it is the one the user is looking at, so promoting anything else
    // would be a surprise.
    final stack = await repo.stackProjects(
      memberIds: [project.id, ...chosen.map((p) => p.id)],
      metadataSourceId: project.id,
    );
    if (!mounted) return;
    ref.invalidate(allProjectsStreamProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.stackStartedMessage)),
    );
    // This page was showing a project that is now a version inside the new
    // song, so follow it there rather than leaving a member page open.
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProjectDetailPage(projectId: stack.id),
      ),
    );
  }

  Future<void> _removeVersionFromStack(
    ProjectRepository repo,
    MusicProject member,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.stackRemoveVersion),
        content: Text(l10n.stackRemoveVersionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.stackRemoveVersion),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await repo.removeFromStack(member.id);
    if (mounted) ref.invalidate(allProjectsStreamProvider);
  }

  /// Dissolves the stack and leaves the page: the project this page was
  /// showing no longer exists once [ProjectRepository.unstack] returns.
  Future<void> _unstackSong(ProjectRepository repo, MusicProject stack) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.stackUnstackTitle),
        content: Text(l10n.stackUnstackMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.stackUnstack),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await repo.unstack(stack.id);
    if (!mounted) return;
    // Leave first, then refresh. Invalidating while this page is still
    // mounted rebuilds it against a stack that no longer exists.
    navigator.pop();
    ref.invalidate(allProjectsStreamProvider);
  }

  /// Compact work total for a version row, e.g. `2h 15m` / `45m`.
  static String _formatWorkTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  Future<void> _setDefaultLaunchVersion(
    ProjectRepository repo,
    MusicProject stack,
    MusicProject member,
  ) async {
    await repo.updateProject(
      stack.copyWith(defaultLaunchMemberId: member.id),
    );
    if (mounted) ref.invalidate(allProjectsStreamProvider);
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bpmCtrl = TextEditingController();
    _keyCtrl = TextEditingController();
    _notesCtrl = TextEditingController(); // INICIALIZA
    _projectNotesCtrl = TextEditingController();
    _nameFocusNode = FocusNode();
    _bpmFocusNode = FocusNode();
    _keyFocusNode = FocusNode();
    _notesFocusNode = FocusNode();

    // Defer the badge dismissal until after the first frame has finished building.
    // Mutating a provider during initState can trip Riverpod's widget-build guard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recentlyDiscoveredProjectsProvider.notifier).dismiss(widget.projectId);
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameCtrl.dispose();
    _bpmCtrl.dispose();
    _keyCtrl.dispose();
    _notesCtrl.dispose();
    _projectNotesCtrl.dispose();
    _nameFocusNode.dispose();
    _bpmFocusNode.dispose();
    _keyFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 300), _doAutoSave);
  }

  Future<void> _doAutoSave() async {
    final allProjects = ref.read(allProjectsStreamProvider).value;
    if (allProjects == null) return;
    final MusicProject project;
    try {
      project = allProjects.firstWhere((p) => p.id == widget.projectId);
    } catch (_) {
      return;
    }
    final repo = await ref.read(repositoryProvider.future);

    final nameText = _nameCtrl.text.trim();
    final newCustomDisplayName =
        (nameText.isEmpty || nameText == project.fileName) ? null : nameText;
    final notesText = _notesCtrl.text.trim();
    final newNotes = notesText.isEmpty ? null : notesText;
    final newStatus = _selectedPhase ?? project.status;
    final statusChanged = project.status != newStatus;
    final bpmText = _bpmCtrl.text.trim();
    final keyText = _keyCtrl.text.trim();

    final updated = project.copyWith(
      customDisplayName: newCustomDisplayName,
      clearCustomDisplayName: newCustomDisplayName == null,
      bpm: bpmText.isEmpty ? null : double.tryParse(bpmText),
      clearBpm: bpmText.isEmpty,
      musicalKey: keyText.isEmpty ? null : keyText,
      clearMusicalKey: keyText.isEmpty,
      notes: newNotes,
      clearNotes: newNotes == null,
      status: newStatus,
      statusChangedAt: statusChanged ? DateTime.now() : null,
    );

    await repo.updateProject(updated);
    await _recordSaveEvents(repo, project, updated, newStatus, statusChanged);
    await _writeMetadataSidecars(
      updated,
      bpmChanged: _lastSavedBpm != bpmText,
      keyChanged: _lastSavedKey != keyText,
    );

    _lastSavedName = newCustomDisplayName ?? project.fileName;
    _lastSavedBpm = bpmText;
    _lastSavedKey = keyText;
    _lastSavedNotes = newNotes ?? '';
  }

  /// Mirrors BPM and key into the `bpm.txt` / `key.txt` files next to the
  /// project, which [MetadataExtractor] reads back on scan. This used to hang
  /// off the dashboard grid's inline cell editor; that editor is gone, and
  /// this page is now the only place either value can be changed.
  ///
  /// Only writes on an actual change: [_doAutoSave] runs on a debounce after
  /// every keystroke in any field, and rewriting two files each time would
  /// churn the project folder (and any folder watcher pointed at it).
  Future<void> _writeMetadataSidecars(
    MusicProject project, {
    required bool bpmChanged,
    required bool keyChanged,
  }) async {
    // _lastSavedBpm/_lastSavedKey are null until the first save, at which
    // point "changed" is true but the value is whatever was loaded from the
    // project — writing it back out is harmless and self-healing.
    try {
      if (bpmChanged) await MetadataSidecarService.writeBpm(project, project.bpm);
      if (keyChanged) {
        await MetadataSidecarService.writeKey(project, project.musicalKey);
      }
    } catch (e) {
      // A read-only or missing project folder must not break autosave — the
      // Hive write above already succeeded, and the sidecar is a convenience.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToWriteBpmFile(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _clearDawInfo() async {
    final allProjects = ref.read(allProjectsStreamProvider).value;
    if (allProjects == null) return;
    final MusicProject project;
    try {
      project = allProjects.firstWhere((p) => p.id == widget.projectId);
    } catch (_) {
      return;
    }
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(project.copyWith(clearDawType: true, clearDawVersion: true));
  }

  // NOVO: Função para abrir o diretório pai
  Future<void> _openProjectFolder(String filePath) async {
    // A single file resolves to its parent; a package-bundle project
    // (.logicx/.luna/.band) also resolves to its parent — revealing the
    // bundle itself just launches the DAW. See
    // ScannerService.projectContainingFolder.
    final folderPath = ScannerService.projectContainingFolder(filePath);

    final success = await FileLauncher.openFolder(folderPath);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.couldNotOpenFolder('Unable to open folder'),
          ),
        ),
      );
    }
  }

  Future<void> _renameProjectFile(MusicProject project) async {
    final ext = p.extension(project.filePath);
    final currentBaseName = p.basenameWithoutExtension(project.filePath);
    final projectDir = p.dirname(project.filePath);
    final folderName = p.basename(projectDir);
    final folderMatchesProject = folderName == currentBaseName;

    final result = await showDialog<({String newName, bool renameFolder})>(
      context: context,
      builder: (ctx) => _RenameProjectDialog(
        currentName: currentBaseName,
        canRenameFolder: folderMatchesProject,
      ),
    );
    if (result == null || result.newName.trim() == currentBaseName) return;

    final newBaseName = result.newName.trim();
    final newFilePath = p.join(projectDir, '$newBaseName$ext');

    if (File(newFilePath).existsSync() || Directory(newFilePath).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.renameAlreadyExists('$newBaseName$ext'))),
        );
      }
      return;
    }

    try {
      // Rename the project file or bundle directory
      if (Directory(project.filePath).existsSync()) {
        await Directory(project.filePath).rename(newFilePath);
      } else {
        await File(project.filePath).rename(newFilePath);
      }

      String finalFilePath = newFilePath;
      String? newPreviewSongPath = project.previewSongPath;
      String? newAutoPath = project.previewSongAutoPath;

      // Rename containing folder if requested
      if (result.renameFolder && folderMatchesProject) {
        final newFolderPath = p.join(p.dirname(projectDir), newBaseName);
        if (!Directory(newFolderPath).existsSync()) {
          await Directory(projectDir).rename(newFolderPath);
          finalFilePath = p.join(newFolderPath, '$newBaseName$ext');
          // Fix any stored paths that were inside the old folder
          if (newPreviewSongPath != null && newPreviewSongPath.startsWith(projectDir)) {
            newPreviewSongPath = newFolderPath + newPreviewSongPath.substring(projectDir.length);
          }
          if (newAutoPath != null && newAutoPath.startsWith(projectDir)) {
            newAutoPath = newFolderPath + newAutoPath.substring(projectDir.length);
          }
        }
      }

      final repo = await ref.read(repositoryProvider.future);
      await repo.updateProject(project.copyWith(
        filePath: finalFilePath,
        fileName: '$newBaseName$ext',
        previewSongPath: newPreviewSongPath,
        previewSongAutoPath: newAutoPath,
      ));
      ref.invalidate(allProjectsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.renameSuccess('$newBaseName$ext'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.renameFailed(e.toString()))),
        );
      }
    }
  }

  /// Saves this project's info to a plain text file, so a readable record of it
  /// survives even after the DAW file (and eventually the library entry) is gone.
  Future<void> _exportProjectInfo(MusicProject project) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final text = ProjectTextExportService.formatProject(project, l10n);
      final destPath = await FilePicker.saveFile(
        dialogTitle: l10n.exportProjectInfo,
        fileName: ProjectTextExportService.suggestedFileNameFor(project),
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      if (destPath == null) return; // user cancelled

      await File(destPath).writeAsString(text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.savedCopyTo(destPath))),
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

  /// The DAW's logo when one is known for [dawType], falling back to a
  /// generic piano icon tinted with [color] (the theme's primary color).
  /// Sized to match the original icon's footprint (same 16x16 the dashboard
  /// table uses for its DAW badges) so the logo doesn't blow out the field.
  Widget _buildDawPrefixIcon(String? dawType, Color color) {
    final logoPath = getDawLogoPath(dawType);
    if (logoPath == null) {
      return Icon(Icons.piano, color: color);
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        logoPath,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.piano, color: color),
      ),
    );
  }

  /// Read-only display of notes extracted straight from the DAW project
  /// file itself (e.g. Reaper's Title/Author/Notes tab) — distinct from the
  /// user-editable [MusicProject.notes] description field it sits beside.
  /// Shares the same expand/collapse and drag-resize affordances as that
  /// field via [ResizableTextField]'s readOnly mode.
  Widget _buildProjectNotesField() {
    return ResizableTextField(
      controller: _projectNotesCtrl,
      readOnly: true,
      labelText: AppLocalizations.of(context)!.projectNotesFromDaw,
      expandTooltip: AppLocalizations.of(context)!.expandNotes,
      collapseTooltip: AppLocalizations.of(context)!.collapseNotes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(repositoryProvider);
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);
    final isMobile = MobileUtils.isMobile();

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.projectDetails),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(
            title: AppLocalizations.of(context)!.projectDetails,
            showBack: true,
          ),
          Expanded(
            child: repoAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(AppLocalizations.of(context)!.failedToLoad),
              ),
              data: (repo) {
                // Use projects from stream to get latest data, fallback to repo if stream not ready
                // The stream should automatically update when Hive emits changes
                // The row this page is showing can disappear underneath it —
                // unstacking deletes the stack, and "Delete Missing" or a
                // Drive restore can remove any project. The stream rebuilds
                // this widget before the pop that follows has run, so every
                // lookup has to tolerate the project being gone rather than
                // throwing "Bad state: No element" mid-frame.
                final project = allProjectsAsync.when(
                  data: (allProjects) =>
                      _findProject(allProjects) ??
                      _findProject(repo.getAllProjects()),
                  loading: () => _findProject(repo.getAllProjects()),
                  error: (_, _) => _findProject(repo.getAllProjects()),
                );
                if (project == null) return _buildProjectGone();
                return _buildProjectContent(repo, project, allProjectsAsync);
              },
            ),
          ),
        ],
      ),
    );
  }

  MusicProject? _findProject(List<MusicProject> projects) =>
      findProjectById(projects, widget.projectId);

  /// Placeholder for the frame(s) between the project being deleted and this
  /// page being popped. Pops itself in case nothing else does — a page left
  /// showing a project that no longer exists has nothing to offer.
  Widget _buildProjectGone() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    });
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildProjectContent(
    ProjectRepository repo,
    MusicProject project,
    AsyncValue<List<MusicProject>> allProjectsAsync,
  ) {
    // Watch the stream to ensure we get updates when the project changes
    return Consumer(
      builder: (context, ref, child) {
        // Re-read the project from the stream to get the latest value
        final currentProjectsAsync = ref.watch(allProjectsStreamProvider);
        final dateFormat = ref.watch(dateFormatProvider);
        final currentProjects = currentProjectsAsync.value ?? [project];
        final currentProject = currentProjects.firstWhere(
          (p) => p.id == widget.projectId,
          orElse: () => project,
        );
        
        // Use the current project instead of the passed one
        final updatedProject = currentProject;

        // Sincroniza controllers com os dados do projeto
        // Só atualiza se o campo não estiver com foco E se o texto não foi modificado pelo usuário
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentName =
              updatedProject.customDisplayName ?? updatedProject.fileName;
          final currentBpm = updatedProject.bpm?.toString() ?? '';
          final currentKey = updatedProject.musicalKey ?? '';
          final currentNotes = updatedProject.notes ?? '';
          
          // Só atualiza se o campo não estiver com foco E se o texto atual for igual ao último valor salvo
          // Isso preserva o texto digitado pelo usuário mesmo quando o foco muda
          if (!_nameFocusNode.hasFocus) {
            if (_lastSavedName == null || _nameCtrl.text == _lastSavedName) {
              if (_nameCtrl.text != currentName) {
                _nameCtrl.text = currentName;
                _lastSavedName = currentName;
              }
            } else {
              // Se o texto foi modificado pelo usuário, atualiza o valor salvo apenas se ainda não foi inicializado
              _lastSavedName ??= currentName;
            }
          }
          
          if (!_bpmFocusNode.hasFocus) {
            if (_lastSavedBpm == null || _bpmCtrl.text == _lastSavedBpm) {
              if (_bpmCtrl.text != currentBpm) {
                _bpmCtrl.text = currentBpm;
                _lastSavedBpm = currentBpm;
              }
            } else {
              _lastSavedBpm ??= currentBpm;
            }
          }
          
          if (!_keyFocusNode.hasFocus) {
            if (_lastSavedKey == null || _keyCtrl.text == _lastSavedKey) {
              if (_keyCtrl.text != currentKey) {
                _keyCtrl.text = currentKey;
                _lastSavedKey = currentKey;
              }
            } else {
              _lastSavedKey ??= currentKey;
            }
          }
          
          // NOVO: Sincroniza Notas - só atualiza se não estiver com foco E se o texto não foi modificado
          if (!_notesFocusNode.hasFocus) {
            if (_lastSavedNotes == null || _notesCtrl.text == _lastSavedNotes) {
              if (_notesCtrl.text != currentNotes) {
                _notesCtrl.text = currentNotes;
                _lastSavedNotes = currentNotes;
              }
            } else {
              _lastSavedNotes ??= currentNotes;
            }
          }
          // Read-only field extracted from the DAW file — no user edits to
          // preserve, so it can just always mirror the current value.
          final currentProjectNotes = updatedProject.projectNotes ?? '';
          if (_projectNotesCtrl.text != currentProjectNotes) {
            _projectNotesCtrl.text = currentProjectNotes;
          }
          // Sincroniza fase do projeto (only on first load)
          if (!_hasInitializedPhase) {
            if (mounted) {
              setState(() {
                _selectedPhase = updatedProject.status;
                _hasInitializedPhase = true;
              });
            }
          }
                });

        final isMobile = MobileUtils.isMobile();
        final sourceFileExists = File(updatedProject.filePath).existsSync() ||
            Directory(updatedProject.filePath).existsSync();
        final extractionSupported =
            MetadataExtractor.supportsFullExtraction(updatedProject.filePath);
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProjectDetailHeader(
                  project: updatedProject,
                  dateFormat: dateFormat,
                  isSessionActive: ref.watch(activeProjectProvider)?.id == widget.projectId,
                  liveSessionSeconds: ref.watch(workTimerProvider),
                  finishedPhase: ref.watch(finishedPhaseProvider),
                ),
                _ProjectDetailActionBar(
                  project: updatedProject,
                  isMobile: isMobile,
                  sourceFileExists: sourceFileExists,
                  onOpenFolder: () => _openProjectFolder(updatedProject.filePath),
                  onRename: () => _renameProjectFile(updatedProject),
                  onOpenInDaw: () => launchProjectInDaw(context, ref, updatedProject),
                  onStats: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProjectStatisticsPage(projectId: updatedProject.id)),
                  ),
                  onExport: () => _exportProjectInfo(updatedProject),
                  onSaveAsTemplate: () => showDialog(
                    context: context,
                    builder: (_) => SaveAsTemplateDialog(project: updatedProject),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Builder(builder: (context) {
                      final l10n = AppLocalizations.of(context)!;

                      // Page-level, so it stays above whichever section is
                      // showing rather than belonging to one of them.
                      final banner = <Widget>[
                    if (!sourceFileExists && !MobileUtils.isMobile())
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade400),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.sourceFileNotFoundMetadataOnly,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                        const SizedBox(height: 16),
                      ];

                      // The page's content, cut into the sections the nav
                      // rail offers. The classic layout renders every group
                      // in this order in one scroll — the order the page has
                      // always had, apart from the deadline field, which
                      // moved up beside the phase dropdown so that each group
                      // is one contiguous run.
                      final sections = <_DetailSection>[
                        _DetailSection(
                          icon: Icons.tune_outlined,
                          label: l10n.projectDetails,
                          children: [
                            // A version's own page is reachable from its
                            // song's Versions list. Say so, and offer the way
                            // back — otherwise the page looks like an ordinary
                            // project whose edits mysteriously don't show up
                            // in the list.
                            if (updatedProject.stackId case final stackId?)
                              Builder(
                                builder: (context) {
                                  final stack = repo.projectsBox.get(stackId);
                                  if (stack == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.layers),
                                      title: Text(
                                        '${l10n.stackMemberOf}: '
                                        '${stack.displayName}',
                                      ),
                                      subtitle: Text(
                                        l10n.stackMemberNotice,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      trailing: TextButton(
                                        onPressed: () => Navigator.of(context)
                                            .pushReplacement(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ProjectDetailPage(
                                                      projectId: stack.id,
                                                    ),
                                              ),
                                            ),
                                        child: Text(l10n.stackOpenMainProject),
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Campo para editar o nome de exibição customizado
                            TextFormField(
                              controller: _nameCtrl,
                              focusNode: _nameFocusNode,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.projectName,
                              ),
                              onChanged: (_) => _scheduleAutoSave(),
                            ),
                            const SizedBox(height: 12),
                            // Use Column on mobile, Row on desktop
                            isMobile
                                ? Column(
                                    children: [
                                      TextFormField(
                                        controller: _bpmCtrl,
                                        focusNode: _bpmFocusNode,
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(
                                            context,
                                          )!.bpm,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => _scheduleAutoSave(),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _keyCtrl,
                                        focusNode: _keyFocusNode,
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(
                                            context,
                                          )!.key,
                                        ),
                                        onChanged: (_) {
                                          setState(() {});
                                          _scheduleAutoSave();
                                        },
                                      ),
                                      // Camelot code field (only shown when key is set)
                                      if (updatedProject.camelotCode != null) ...[
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          key: ValueKey(updatedProject.camelotCode),
                                          enabled: false,
                                          initialValue: updatedProject.camelotCode,
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(context)!.camelotCode,
                                            filled: true,
                                            fillColor: Colors.blue.withValues(alpha: 0.05),
                                            border: const OutlineInputBorder(),
                                            disabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.blue.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.music_note,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                      // DAW field (mobile)
                                      if (updatedProject.dawType != null) ...[
                                        const SizedBox(height: 12),
                                        Builder(builder: (context) {
                                          final dawColor = Theme.of(context).colorScheme.primary;
                                          return TextFormField(
                                            key: ValueKey('${updatedProject.dawType}-${updatedProject.dawVersion}'),
                                            enabled: false,
                                            initialValue: updatedProject.dawVersion?.isNotEmpty == true
                                                ? '${updatedProject.dawType} ${updatedProject.dawVersion}'
                                                : updatedProject.dawType,
                                            decoration: InputDecoration(
                                              labelText: AppLocalizations.of(context)!.daw,
                                              filled: true,
                                              fillColor: dawColor.withValues(alpha: 0.05),
                                              border: const OutlineInputBorder(),
                                              disabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: dawColor.withValues(alpha: 0.3),
                                                ),
                                              ),
                                              prefixIcon: _buildDawPrefixIcon(updatedProject.dawType, dawColor),
                                              suffixIcon: IconButton(
                                                icon: const Icon(Icons.close, size: 18),
                                                tooltip: AppLocalizations.of(context)!.clearDaw,
                                                onPressed: _clearDawInfo,
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: dawColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _bpmCtrl,
                                          focusNode: _bpmFocusNode,
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(
                                              context,
                                            )!.bpm,
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => _scheduleAutoSave(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _keyCtrl,
                                          focusNode: _keyFocusNode,
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(
                                              context,
                                            )!.key,
                                          ),
                                          onChanged: (value) {
                                            // Force rebuild to update Camelot code display
                                            setState(() {});
                                            _scheduleAutoSave();
                                          },
                                        ),
                                      ),
                                      // Camelot code field on desktop (next to key field)
                                      if (updatedProject.camelotCode != null) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            enabled: false,
                                            initialValue: updatedProject.camelotCode,
                                            decoration: InputDecoration(
                                              labelText: AppLocalizations.of(context)!.camelotCode,
                                              filled: true,
                                              fillColor: Colors.blue.withValues(alpha: 0.05),
                                              border: const OutlineInputBorder(),
                                              disabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.blue.withValues(alpha: 0.3),
                                                ),
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.music_note,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                      // DAW field on desktop (next to key/Camelot fields)
                                      if (updatedProject.dawType != null) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Builder(builder: (context) {
                                            final dawColor = Theme.of(context).colorScheme.primary;
                                            return TextFormField(
                                              key: ValueKey('${updatedProject.dawType}-${updatedProject.dawVersion}'),
                                              enabled: false,
                                              initialValue: updatedProject.dawVersion?.isNotEmpty == true
                                                  ? '${updatedProject.dawType} ${updatedProject.dawVersion}'
                                                  : updatedProject.dawType,
                                              decoration: InputDecoration(
                                                labelText: AppLocalizations.of(context)!.daw,
                                                filled: true,
                                                fillColor: dawColor.withValues(alpha: 0.05),
                                                border: const OutlineInputBorder(),
                                                disabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: dawColor.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                prefixIcon: _buildDawPrefixIcon(updatedProject.dawType, dawColor),
                                                suffixIcon: IconButton(
                                                  icon: const Icon(Icons.close, size: 18),
                                                  tooltip: AppLocalizations.of(context)!.clearDaw,
                                                  onPressed: _clearDawInfo,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: dawColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: !sourceFileExists
                                            ? AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine
                                            : !extractionSupported
                                                ? AppLocalizations.of(context)!.metadataExtractionNotSupportedForDaw
                                                : '',
                                        child: ElevatedButton.icon(
                                        onPressed: _extractingMetadata || !sourceFileExists || !extractionSupported
                                            ? null
                                            : () async {
                                                setState(
                                                  () => _extractingMetadata = true,
                                                );
                                                try {
                                                  await repo
                                                      .extractFullMetadataForProject(
                                                        updatedProject.id,
                                                      );
                                                  // Refresh the project data
                                                  ref.invalidate(
                                                    allProjectsStreamProvider,
                                                  );
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.metadataExtractedSuccessfully,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.failedToExtractMetadata(
                                                            e.toString(),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) {
                                                    setState(
                                                      () =>
                                                          _extractingMetadata = false,
                                                    );
                                                  }
                                                }
                                              },
                                        icon: _extractingMetadata
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.search, size: 18),
                                        label: Text(
                                          _extractingMetadata
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.extracting
                                              : AppLocalizations.of(context)!.extract,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 12),

                            // Project Phase Dropdown
                            DropdownButtonFormField<String>(
                              initialValue:
                                  _selectedPhase ??
                                  ref.watch(customPhasesProvider).first,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.projectPhase,
                              ),
                              items: ref.watch(customPhasesProvider).map((phase) {
                                return DropdownMenuItem<String>(
                                  value: phase,
                                  child: Text(phase),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPhase = value;
                                });
                                _scheduleAutoSave();
                              },
                            ),
                            const SizedBox(height: 12),
                            // Deadline field
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: updatedProject.deadline ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                );
                                if (picked != null) {
                                  final updated = updatedProject.copyWith(deadline: picked);
                                  await repo.updateProject(updated);
                                  if (mounted) {
                                    ref.invalidate(allProjectsStreamProvider);
                                  }
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.projectDeadline,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: updatedProject.deadline != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () async {
                                            final updated = updatedProject.copyWith(clearDeadline: true);
                                            await repo.updateProject(updated);
                                            if (mounted) {
                                              ref.invalidate(allProjectsStreamProvider);
                                            }
                                          },
                                        )
                                      : const Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  updatedProject.deadline != null
                                      ? DateFormat('MMM dd, yyyy').format(updatedProject.deadline!)
                                      : AppLocalizations.of(context)!.noDeadlineSet,
                                  style: TextStyle(
                                    color: updatedProject.deadline != null
                                        ? (updatedProject.daysUntilDeadline! < 0
                                            ? Colors.red
                                            : updatedProject.daysUntilDeadline! == 0
                                                ? Colors.red
                                                : updatedProject.daysUntilDeadline! <= 7
                                                    ? Colors.orange
                                                    : Theme.of(context).textTheme.bodyLarge?.color)
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                        _DetailSection(
                          icon: Icons.notes_outlined,
                          label: l10n.notes,
                          children: [
                            // NOVO: CAMPO DE NOTAS
                            Builder(builder: (context) {
                              final projectNotes = updatedProject.projectNotes;
                              if (projectNotes == null || projectNotes.trim().isEmpty) {
                                return ResizableTextField(
                                  controller: _notesCtrl,
                                  focusNode: _notesFocusNode,
                                  labelText: AppLocalizations.of(context)!.notes,
                                  expandTooltip: AppLocalizations.of(context)!.expandNotes,
                                  collapseTooltip: AppLocalizations.of(context)!.collapseNotes,
                                  onChanged: (_) => _scheduleAutoSave(),
                                );
                              }
                              if (isMobile) {
                                return Column(
                                  children: [
                                    ResizableTextField(
                                      controller: _notesCtrl,
                                      focusNode: _notesFocusNode,
                                      labelText: AppLocalizations.of(context)!.notes,
                                      expandTooltip: AppLocalizations.of(context)!.expandNotes,
                                      collapseTooltip: AppLocalizations.of(context)!.collapseNotes,
                                      onChanged: (_) => _scheduleAutoSave(),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildProjectNotesField(),
                                  ],
                                );
                              }
                              return SyncedResizableTextFieldPair(
                                leftController: _notesCtrl,
                                leftFocusNode: _notesFocusNode,
                                leftLabelText: AppLocalizations.of(context)!.notes,
                                leftOnChanged: (_) => _scheduleAutoSave(),
                                rightController: _projectNotesCtrl,
                                rightLabelText: AppLocalizations.of(context)!.projectNotesFromDaw,
                                rightReadOnly: true,
                                expandTooltip: AppLocalizations.of(context)!.expandNotes,
                                collapseTooltip: AppLocalizations.of(context)!.collapseNotes,
                              );
                            }),

                            // Markers and regions read out of the DAW project
                            // file. Renders nothing at all when there are
                            // none, which is every project from a DAW whose
                            // format we don't parse markers out of yet.
                            Builder(builder: (context) {
                              final l10n = AppLocalizations.of(context)!;
                              final canJump =
                                  canJumpToProjectMarkers(updatedProject);
                              return ProjectMarkersSection(
                                markers: updatedProject.markers,
                                title: l10n.projectMarkers,
                                unnamedMarkerLabel: l10n.projectMarkerUnnamed,
                                unnamedRegionLabel: l10n.projectRegionUnnamed,
                                showAllLabel: l10n.showAll,
                                collapseLabel: l10n.collapse,
                                jumpTooltip: l10n.projectMarkerJumpTooltip,
                                disabledTooltip:
                                    l10n.projectMarkerNoPreviewSong,
                                padding: EdgeInsets.zero,
                                onTap: canJump
                                    ? (marker) => jumpToProjectMarker(
                                          ref,
                                          updatedProject,
                                          marker,
                                        )
                                    : null,
                              );
                            }),

                            const SizedBox(height: 12),
                          ],
                        ),
                        _DetailSection(
                          icon: Icons.music_note_outlined,
                          label: l10n.previewSong,
                          children: [
                            // Preview Song Section
                            _PreviewSongPlayer(
                              key: ValueKey('${updatedProject.id}_${updatedProject.previewSongPath}'),
                              project: updatedProject,
                              onSongRemoved: () async {
                                try {
                                  if (kDebugMode) {
                                    print('Removing preview song from project: ${updatedProject.id}');
                                    print('Current previewSongPath: ${updatedProject.previewSongPath}');
                                  }
                                  
                                  // Clear only the path type that's currently active.
                                  // Removing a manual preview falls back to auto; removing
                                  // an auto preview clears it without immediately re-detecting.
                                  final updated = updatedProject.previewSongPath?.isNotEmpty == true
                                      ? updatedProject.copyWith(clearPreviewSongPath: true, updatedAt: DateTime.now())
                                      : updatedProject.copyWith(clearPreviewSongAutoPath: true, updatedAt: DateTime.now());
                                  
                                  if (kDebugMode) {
                                    print('Updated project previewSongPath: ${updated.previewSongPath}');
                                    print('Updated project updatedAt: ${updated.updatedAt}');
                                  }
                                  
                                  // Update directly in the box to ensure Hive emits the event
                                  await repo.updateProject(updated);
                                  
                                  if (kDebugMode) {
                                    // Verify immediately after update
                                    final verifyProjects = repo.getAllProjects();
                                    final verifyProject = verifyProjects.firstWhere(
                                      (p) => p.id == updatedProject.id,
                                      orElse: () => updatedProject,
                                    );
                                    print('Immediately after update - previewSongPath: ${verifyProject.previewSongPath}');
                                  }
                                  
                                  if (kDebugMode) {
                                    // Verify the update was saved
                                    final verifyProject = repo.getAllProjects().firstWhere(
                                      (p) => p.id == updatedProject.id,
                                      orElse: () => updatedProject,
                                    );
                                    print('After update - previewSongPath in repo: ${verifyProject.previewSongPath}');
                                  }
                                  
                                  if (mounted) {
                                    // The Hive watch should automatically trigger the stream to emit
                                    // The Consumer in _buildProjectContent watches allProjectsStreamProvider
                                    // and will automatically rebuild when the stream emits a new value
                                    // We don't need to invalidate - the stream will update via Hive watch
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.previewSongRemoved,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('Error removing preview song: $e');
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${AppLocalizations.of(context)!.error}: ${e.toString()}',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              onSongChanged: (filePath) async {
                                // When changing the preview song, we should NOT update the uploadedPreviewSongHash here.
                                // The uploadedPreviewSongHash should only be updated after a successful upload to Drive.
                                // By keeping the old hash intact, the upload process will calculate
                                // the new file's hash and compare it with the old uploadedPreviewSongHash in the database.
                                // If they differ, it will upload the new file and update the uploadedPreviewSongHash.
                                // The uploadedPreviewSongHash will be updated in uploadDatabase() after successful upload.
                                
                                final updated = project.copyWith(
                                  previewSongPath: filePath,
                                  // Keep old uploadedPreviewSongHash - don't update it here
                                  // It will be updated after successful upload to Drive
                                  previewSongFileName: p.basename(filePath),
                                );
                                await repo.updateProject(updated);
                                if (mounted) {
                                  // Invalidate to refresh the stream
                                  ref.invalidate(allProjectsStreamProvider);
                                  // Wait a bit for the stream to update
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.previewSongAdded,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                        // Offered on ordinary projects too, not just stacks:
                        // a song is usually recognised as having versions
                        // while looking at one of them, so the section shows
                        // an empty state with "Add Version" that starts a
                        // stack from here. Suppressed only on a version that
                        // already belongs to a stack — its song owns the list,
                        // and the banner at the top of this page links there.
                        if (!updatedProject.isStackMember)
                          _DetailSection(
                            icon: Icons.layers_outlined,
                            label: l10n.stackVersionsTitle,
                            children: [
                              Builder(
                                builder: (context) {
                                  final members = updatedProject.isVirtual
                                      ? repo.stackMembers(updatedProject)
                                      : const <MusicProject>[];
                                  return ProjectVersionsSection(
                                    members: members,
                                    defaultLaunchMemberId:
                                        updatedProject.defaultLaunchMemberId,
                                    title: l10n.stackVersionsTitle,
                                    countLabel: l10n.stackVersionCount(
                                      members.length,
                                    ),
                                    addLabel: l10n.stackAddVersion,
                                    unstackLabel: l10n.stackUnstack,
                                    defaultBadgeLabel: l10n.stackDefaultVersion,
                                    setDefaultTooltip:
                                        l10n.stackSetDefaultVersion,
                                    defaultTooltip:
                                        l10n.stackDefaultVersionTooltip,
                                    removeTooltip: l10n.stackRemoveVersion,
                                    emptyTitle: l10n.stackNotStackedYet,
                                    emptyDescription: l10n.stackStartFromHere,
                                    padding: EdgeInsets.zero,
                                    subtitleBuilder: (member) {
                                      final modified = dateFormat.format(
                                        member.lastModifiedAt,
                                      );
                                      if (member.totalWorkSeconds <= 0) {
                                        return modified;
                                      }
                                      return '$modified  ·  '
                                          '${_formatWorkTime(member.totalWorkSeconds)}';
                                    },
                                    onAdd: () => _addVersionToStack(
                                      repo,
                                      updatedProject,
                                    ),
                                    // Everything below acts on members, so it
                                    // has no meaning until there is a stack.
                                    onRemove: updatedProject.isVirtual
                                        ? (member) => _removeVersionFromStack(
                                            repo,
                                            member,
                                          )
                                        : null,
                                    onSetDefault: updatedProject.isVirtual
                                        ? (member) =>
                                              _setDefaultLaunchVersion(
                                                repo,
                                                updatedProject,
                                                member,
                                              )
                                        : null,
                                    onOpen: (member) => Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => ProjectDetailPage(
                                              projectId: member.id,
                                            ),
                                          ),
                                        ),
                                    onUnstack: updatedProject.isVirtual
                                        ? () =>
                                              _unstackSong(repo, updatedProject)
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        _DetailSection(
                          icon: Icons.piano_outlined,
                          label: l10n.songParts,
                          children: [
                            // Instruments & Parts — progress at a glance; the
                            // editing workspace is a page of its own.
                            PartsSummaryCard(project: updatedProject),

                            const SizedBox(height: 24),
                          ],
                        ),
                        _DetailSection(
                          icon: Icons.checklist_outlined,
                          label: l10n.todoList,
                          children: [
                            // TODO List
                            // Use key to force widget rebuild when todos change
                            TodoListWidget(
                              key: ValueKey('${updatedProject.id}_${updatedProject.todos.length}_${updatedProject.todos.map((t) => t.id).join(",")}'),
                              todos: updatedProject.todos,
                              onTodosChanged: (updatedTodos) async {
                                final updated = updatedProject.copyWith(
                                  todos: updatedTodos,
                                );
                                await repo.updateProject(updated);
                                // Invalidate the projects stream to refresh the UI
                                if (mounted) {
                                  ref.invalidate(allProjectsStreamProvider);
                                }
                              },
                              onTodoCompleted: (completedTodo) async {
                                await repo.addEvent(ProjectEvent(
                                  id: _uuid.v4(),
                                  projectId: updatedProject.id,
                                  eventType: ProjectEvent.todoCompleted,
                                  occurredAt: DateTime.now(),
                                  payload: jsonEncode({
                                    'todoId': completedTodo.id,
                                    'todoText': completedTodo.text,
                                  }),
                                ));
                              },
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                        _DetailSection(
                          icon: Icons.history_outlined,
                          label: l10n.sessionHistory,
                          children: [
                            if (updatedProject.isVirtual)
                              // Work time on a stack is the sum of its
                              // versions', derived on read (see
                              // ProjectRepository.stackSessions) — the stack
                              // row itself never stores sessions.
                              _SessionHistorySection(
                                sessions: repo.stackSessions(updatedProject),
                              )
                            else
                            _SessionHistorySection(
                              sessions: updatedProject.sessions,
                              onRemove: (session) async {
                                final updatedSessions = updatedProject.sessions
                                    .where((s) => s.id != session.id)
                                    .toList();
                                final updatedTotal = updatedSessions.fold<int>(
                                    0, (a, b) => a + b.durationSeconds);
                                await repo.updateProject(updatedProject.copyWith(
                                  sessions: updatedSessions,
                                  totalWorkSeconds: updatedTotal,
                                ));
                              },
                              onEdit: (updated) async {
                                final updatedSessions = updatedProject.sessions
                                    .map((s) =>
                                        s.id == updated.id ? updated : s)
                                    .toList();
                                final updatedTotal = updatedSessions.fold<int>(
                                    0, (a, b) => a + b.durationSeconds);
                                await repo.updateProject(updatedProject.copyWith(
                                  sessions: updatedSessions,
                                  totalWorkSeconds: updatedTotal,
                                ));
                              },
                            ),
                            const SizedBox(height: 24),
                            _ProjectStatsButton(projectId: updatedProject.id),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ];

                      // A phone has no room for a rail, so mobile always gets
                      // the single scroll whatever the setting says.
                      final sectioned = !isMobile &&
                          ref.watch(projectDetailLayoutProvider) ==
                              ProjectDetailLayout.sectioned;

                      if (!sectioned) {
                        return ListView(
                          padding: MobileUtils.getResponsivePadding(context),
                          children: [
                            ...banner,
                            for (final section in sections) ...section.children,
                          ],
                        );
                      }

                      final active =
                          _activeSection.clamp(0, sections.length - 1);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 200,
                            child: SectionNavRail(
                              items: [
                                for (final section in sections)
                                  SectionNavItem(
                                    icon: section.icon,
                                    label: section.label,
                                  ),
                              ],
                              activeIndex: active,
                              onTap: (index) =>
                                  setState(() => _activeSection = index),
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: ListView(
                              // Keyed by section so switching starts the new
                              // one at the top instead of inheriting the
                              // previous section's scroll offset.
                              key: ValueKey(active),
                              padding:
                                  MobileUtils.getResponsivePadding(context),
                              children: [
                                ...banner,
                                ...sections[active].children,
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
            // Loading overlay
            if (_extractingMetadata)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Extracting metadata...',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
    },
    );
  }
}

// ─── Action Toolbar ───────────────────────────────────────────────────────────

class _ProjectDetailActionBar extends ConsumerWidget {
  final MusicProject project;
  final bool isMobile;
  final bool sourceFileExists;
  final VoidCallback onOpenFolder;
  final VoidCallback onRename;
  final VoidCallback onOpenInDaw;
  final VoidCallback onStats;
  final VoidCallback onExport;
  final VoidCallback onSaveAsTemplate;

  const _ProjectDetailActionBar({
    required this.project,
    required this.isMobile,
    required this.sourceFileExists,
    required this.onOpenFolder,
    required this.onRename,
    required this.onOpenInDaw,
    required this.onStats,
    required this.onExport,
    required this.onSaveAsTemplate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notFoundMsg = l10n.sourceFileNotFoundOnThisMachine;
    final sessionMode = ref.watch(sessionModeProvider);
    final isSubscribed =
        sessionMode && ref.watch(activeProjectProvider)?.id == project.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isMobile) ...[
            const SizedBox(width: 8),
            if (sessionMode) ...[
              OutlinedButton.icon(
                onPressed: () => isSubscribed
                    ? confirmEndSession(context, ref)
                    : confirmStartSession(context, ref, project),
                icon: Icon(
                  isSubscribed ? Icons.bookmark : Icons.bookmark_add_outlined,
                  size: 16,
                  color: isSubscribed ? Colors.green.shade400 : null,
                ),
                label: Text(isSubscribed ? l10n.endSession : l10n.startSession),
              ),
              // Once this project's session is active, still let the user
              // launch the DAW from here instead of needing the dashboard.
              if (isSubscribed) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: sourceFileExists ? '' : notFoundMsg,
                  child: OutlinedButton.icon(
                    onPressed: sourceFileExists ? onOpenInDaw : null,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l10n.openInDaw),
                  ),
                ),
              ],
            ] else
              Tooltip(
                message: sourceFileExists ? '' : notFoundMsg,
                child: OutlinedButton.icon(
                  onPressed: sourceFileExists ? onOpenInDaw : null,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l10n.openInDaw),
                ),
              ),
          ],
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: sourceFileExists ? '' : notFoundMsg,
              child: OutlinedButton.icon(
                onPressed: sourceFileExists ? onOpenFolder : null,
                icon: const Icon(Icons.folder_open, size: 16),
                label: Text(l10n.openFolder),
              ),
            ),
          ],
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: sourceFileExists ? '' : notFoundMsg,
              child: OutlinedButton.icon(
                onPressed: sourceFileExists ? onRename : null,
                icon: const Icon(Icons.drive_file_rename_outline, size: 16),
                label: Text(l10n.renameFileButtonLabel),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onStats,
              icon: const Icon(Icons.bar_chart, size: 16),
              label: Text(l10n.statsSingleProjectActivity),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.description_outlined, size: 16),
              label: Text(l10n.exportProjectInfo),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onSaveAsTemplate,
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: Text(l10n.saveAsTemplate),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PreviewSongPlayer extends ConsumerStatefulWidget {
  final MusicProject project;
  final Future<void> Function() onSongRemoved;
  final Future<void> Function(String) onSongChanged;

  const _PreviewSongPlayer({
    super.key,
    required this.project,
    required this.onSongRemoved,
    required this.onSongChanged,
  });

  @override
  ConsumerState<_PreviewSongPlayer> createState() => _PreviewSongPlayerState();
}

class _TogglePlayPauseIntent extends Intent {
  const _TogglePlayPauseIntent();
}

class _PreviewSongPlayerState extends ConsumerState<_PreviewSongPlayer>
    with RouteAwareDropTargetState<_PreviewSongPlayer> {
  AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer? _warmPlayer; // pre-loaded with the alternate source (mono↔stereo)
  int _playerGen = 0;       // incremented on each swap; stale listeners self-cancel
  final FocusNode _focusNode = FocusNode();
  bool _isPlaying = false;
  bool _playbackEnded = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDraggingOver = false;
  double _volume = 1.0;
  double _preMuteVolume = 1.0;

  // Mono
  bool _isMono = false;
  bool _isGeneratingMono = false;
  String? _monoFilePath;

  // File metadata (populated for any format)
  AudioFileInfo? _fileInfo;

  // Waveform peaks for display
  WaveformPeaks? _peaks;

  // Auto-detected mixdown path (used when no preview song is set manually)
  String? _autoDetectedPath;

  // Set when the user accepts a "Replace & Play" suggestion; overrides everything
  // until the widget rebuilds with updated project data from the stream.
  String? _replacedPreviewPath;

  String? get _effectivePreviewPath =>
      _replacedPreviewPath ??
      (widget.project.previewSongPath?.isNotEmpty == true
          ? widget.project.previewSongPath
          : (_autoDetectedPath ?? widget.project.previewSongAutoPath));

  @override
  void initState() {
    super.initState();
    _attachListeners(_audioPlayer, _playerGen);
    _adoptStoredAutoPath();
    _startBackgroundPrep();
  }

  /// Adopts an already-detected mixdown path if one is on record. Deliberately
  /// does NOT scan: opening a project (or switching to another) shouldn't
  /// silently walk its mixdown folders and persist a preview the user never
  /// asked for. A fresh scan only happens when the user presses "Find
  /// automatically" ([_findMixdownNow]).
  void _adoptStoredAutoPath() {
    if (widget.project.previewSongPath?.isNotEmpty == true) return;
    if (widget.project.previewSongAutoPath != null) {
      _autoDetectedPath = widget.project.previewSongAutoPath;
    }
  }

  /// Snackbar shown when a mixdown scan turns up nothing: the message plus a
  /// shortcut into Settings › Mixdown Folders so the user can check or add
  /// the folder names being searched.
  SnackBar _noMixdownFoundSnackBar(AppLocalizations l10n) => SnackBar(
        content: Text(l10n.noPreviewSongFoundAutomatically),
        action: SnackBarAction(
          label: l10n.mixdownFoldersTabLabel,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SettingsPage(
                initialSection: SettingsSection.mixdownFolders,
              ),
            ),
          ),
        ),
      );

  /// User-initiated mixdown search (the "Auto-Find" button) — the only place
  /// that scans the mixdown folders. Runs a fresh scan, persists the hit as
  /// the auto preview, and reports the outcome.
  Future<void> _findMixdownNow() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final customFolders = ref.read(customMixdownFoldersProvider).value;
    final customFoldersByDaw = ref.read(customMixdownFoldersByDawProvider).value;
    final file = MixdownDetectorService.findLatestMixdown(
      widget.project,
      customFolders: customFolders,
      customFoldersByDaw: customFoldersByDaw,
    );
    if (!mounted) return;
    if (file == null) {
      messenger.showSnackBar(_noMixdownFoundSnackBar(l10n));
      return;
    }
    setState(() => _autoDetectedPath = file.path);
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(
      widget.project.copyWith(previewSongAutoPath: file.path),
    );
    if (!mounted) return;
    ref.invalidate(allProjectsStreamProvider);
    _startBackgroundPrep();
    messenger.showSnackBar(SnackBar(content: Text(l10n.previewSongAdded)));
  }

  void _attachListeners(AudioPlayer player, int gen) {
    player.onPlayerStateChanged.listen((state) {
      if (gen != _playerGen || !mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    player.onDurationChanged.listen((d) {
      if (gen != _playerGen || !mounted) return;
      setState(() => _duration = d);
    });
    player.onPositionChanged.listen((p) {
      if (gen != _playerGen || !mounted) return;
      setState(() => _position = p);
    });
    player.onPlayerComplete.listen((_) {
      if (gen != _playerGen || !mounted) return;
      setState(() { _isPlaying = false; _position = Duration.zero; _playbackEnded = true; });
    });
  }

  @override
  void dispose() {
    _warmPlayer?.dispose();
    _audioPlayer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PreviewSongPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idChanged = oldWidget.project.id != widget.project.id;
    final pathChanged = oldWidget.project.previewSongPath != widget.project.previewSongPath;
    final autoPathChanged = oldWidget.project.previewSongAutoPath != widget.project.previewSongAutoPath;
    if (idChanged || pathChanged || autoPathChanged) {
      // If the stream delivered the path we replaced to, clear the local override.
      if (_replacedPreviewPath != null &&
          (widget.project.previewSongPath == _replacedPreviewPath ||
           widget.project.previewSongAutoPath == _replacedPreviewPath)) {
        _replacedPreviewPath = null;
      }
      _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _playbackEnded = false;
        _position = Duration.zero;
        _duration = Duration.zero;
        _isMono = false;
        _isGeneratingMono = false;
        _monoFilePath = null;
        _fileInfo = null;
        _peaks = null;
        _autoDetectedPath = null;
      });
      // Adopt an already-detected path if there is one, but never scan here —
      // not on a project switch, and not after a removal (which would just
      // undo what the user did). A fresh scan is only ever the "Find
      // automatically" button ([_findMixdownNow]).
      _adoptStoredAutoPath();
      _startBackgroundPrep();
    }
  }

  // ── Background preparation ──────────────────────────────────────────────────

  void _startBackgroundPrep() {
    if (!_hasAudioFile()) return;
    final path = _effectivePreviewPath!;

    // File metadata — works for any format
    AudioAnalysisService.getFileInfo(path).then((info) {
      if (mounted && info != null) setState(() => _fileInfo = info);
    });

    // Waveform peaks — memory → disk → extraction
    ref.read(waveformCacheProvider.notifier).getOrExtract(
      path,
      onStale: () {
        if (!mounted) return;
        setState(() => _peaks = null);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.previewAudioChangedRefreshing),
          duration: const Duration(seconds: 3),
        ));
      },
    ).then((peaks) {
      if (!mounted || peaks == null) return;
      setState(() => _peaks = peaks);
    });

    // Pre-generate mono file for any supported format
    if (_supportsMonoMix()) _prepareMonoFile(path);
  }

  Future<void> _prepareMonoFile(String path) async {
    final tmpDir = await getTemporaryDirectory();
    final outPath = '${tmpDir.path}/mono_${widget.project.id}.wav';
    final ok = await AudioAnalysisService.writeMonoWavFile(path, outPath);
    if (!mounted) return;
    if (ok) {
      setState(() => _monoFilePath = outPath);
      _preWarmAlt(DeviceFileSource(outPath));
    } else {
      // File may already be mono — level data may not be ready yet, so we
      // resolve the channel count here directly from the service.
      final channels = await AudioAnalysisService.getChannelCount(path);
      if (mounted && channels == 1) {
        setState(() => _monoFilePath = path);
        _preWarmAlt(DeviceFileSource(path));
      }
    }
  }

  /// Pre-loads [source] into [_warmPlayer] so the next toggle is source-load-free.
  void _preWarmAlt(Source source) {
    _warmPlayer?.dispose();
    _warmPlayer = AudioPlayer();
    _warmPlayer!.setVolume(_volume);
    _warmPlayer!.setSource(source); // fire-and-forget; loads into native buffer
  }

  /// Fades [player] from 0 → [_volume] over ~120 ms.
  /// Cancels automatically if the player is swapped out before the fade ends.
  void _fadeIn(AudioPlayer player) {
    const steps = 12;
    const stepMs = 10; // 12 × 10 ms = 120 ms total
    int step = 0;
    Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      step++;
      if (!mounted || player != _audioPlayer) {
        timer.cancel();
        return;
      }
      player.setVolume((_volume * step / steps).clamp(0.0, _volume));
      if (step >= steps) {
        timer.cancel();
        player.setVolume(_volume); // land on exact target
      }
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _hasAudioFile() {
    final path = _effectivePreviewPath;
    return path != null && path.isNotEmpty;
  }

  bool _supportsMonoMix() {
    final path = _effectivePreviewPath;
    if (path == null || path.isEmpty) return false;
    final ext = path.toLowerCase().split('.').last;
    if (ext == 'wav') return true;
    if (Platform.isMacOS || Platform.isIOS) {
      return const {'mp3', 'flac', 'aif', 'aiff', 'aac', 'm4a'}.contains(ext);
    }
    return const {'mp3', 'flac', 'aif', 'aiff', 'ogg', 'aac', 'm4a'}.contains(ext);
  }

  Source _currentSource() {
    if (_isMono && _monoFilePath != null) return DeviceFileSource(_monoFilePath!);
    return DeviceFileSource(_effectivePreviewPath!);
  }

  Future<void> _toggleMono() async {
    debugPrint('[Mono] _toggleMono called. supportsMonoMix=${_supportsMonoMix()} isMono=$_isMono monoFilePath=$_monoFilePath');
    if (!_supportsMonoMix()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.monoRequiresWav)),
      );
      return;
    }
    final newMono = !_isMono;

    // If we're toggling ON and the mono file isn't ready yet, generate it now.
    if (newMono && _monoFilePath == null) {
      setState(() => _isGeneratingMono = true);
      final tmpDir = await getTemporaryDirectory();
      final outPath = '${tmpDir.path}/mono_${widget.project.id}.wav';
      debugPrint('[Mono] Generating mono file → $outPath');
      final ok = await AudioAnalysisService.writeMonoWavFile(
          _effectivePreviewPath!, outPath);
      debugPrint('[Mono] writeMonoWavFile result: $ok channels=${_fileInfo?.channels}');
      if (!mounted) return;
      if (!ok) {
        // If the file is already mono, use the original as the mono source.
        final alreadyMono = _fileInfo?.channels == 1;
        if (alreadyMono) {
          debugPrint('[Mono] File is already mono — using original path.');
          setState(() { _monoFilePath = _effectivePreviewPath!; _isGeneratingMono = false; });
        } else {
          setState(() => _isGeneratingMono = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.monoUnsupportedFormat)),
          );
          return;
        }
      } else {
        setState(() { _monoFilePath = outPath; _isGeneratingMono = false; });
      }
    }

    final wasPlaying = _isPlaying;
    final savedPosition = _position;
    setState(() => _isMono = newMono);

    // Grab (or create) the new active player.
    final newActive = _warmPlayer ?? AudioPlayer();
    _warmPlayer = null;

    // Advance generation: listeners on the old player will now self-cancel.
    final gen = ++_playerGen;
    final oldActive = _audioPlayer;
    _audioPlayer = newActive;
    _attachListeners(newActive, gen);

    try {
      if (wasPlaying) {
        await newActive.setVolume(0);
        await newActive.play(_currentSource(), position: savedPosition);
        _fadeIn(newActive);
      } else {
        await newActive.setVolume(_volume);
        await newActive.setSource(_currentSource());
        if (savedPosition > Duration.zero) await newActive.seek(savedPosition);
      }
    } catch (e) {
      debugPrint('[Mono] switch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.monoSwitchFailed(e.toString()))),
        );
      }
    }

    // Recycle the old player as the warm player for the next toggle.
    await oldActive.stop();
    final altSource = _isMono
        ? DeviceFileSource(_effectivePreviewPath!)
        : (_monoFilePath != null ? DeviceFileSource(_monoFilePath!) : null);
    if (altSource != null) {
      _warmPlayer = oldActive;
      _warmPlayer!.setVolume(_volume);
      _warmPlayer!.setSource(altSource); // fire-and-forget
    } else {
      oldActive.dispose();
    }
  }

  Future<void> _togglePlayPause() async {
    if (!_hasAudioFile()) return;

    // On mobile: pause/resume via global MobilePlayerNotifier so the mini
    // player and Android notification stay in sync. Validation still happens
    // below; only the final play/pause calls are delegated.
    if (MobileUtils.isMobile()) {
      final mobileNotifier = ref.read(mobilePlayerProvider.notifier);
      final mobileState = ref.read(mobilePlayerProvider);
      final isThisTrack = mobileState.currentProject?.id == widget.project.id;

      if (_isPlaying || (isThisTrack && mobileState.isPlaying)) {
        await mobileNotifier.pause();
        return;
      }
    } else {
      if (!_isPlaying) ref.read(desktopPlayerProvider.notifier).close();
    }

    try {
      if (_isPlaying && !MobileUtils.isMobile()) {
        await _audioPlayer.pause();
      } else {
        if (_effectivePreviewPath!.startsWith('drive://')) {
          // If we still have a Drive reference, the file wasn't downloaded
          // This shouldn't happen if backup was downloaded correctly, but handle gracefully
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Preview song not available. Please download backup again.',
                ),
              ),
            );
          }
          return;
        } else {
          // Local file - check if it exists
          final file = File(_effectivePreviewPath!);
          if (!await file.exists()) {
            if (!mounted) return;
            final l10n = AppLocalizations.of(context)!;
            final messenger = ScaffoldMessenger.of(context);
            // Shares the dialog with the dashboard's copies, but applies the
            // outcome through this page's own callbacks — they carry
            // detail-page-only concerns (leaving the Drive upload hash intact,
            // the "preview song added" snackbar) that a shared writer would
            // have to reimplement.
            final action = await showPreviewSongNotFoundDialog(context);
            if (!mounted || action == null) return;
            switch (action) {
              case PreviewNotFoundAction.remove:
                await widget.onSongRemoved();
              case PreviewNotFoundAction.autoFind:
                final found =
                    await clearAndAutoFindPreview(ref, widget.project);
                if (!mounted) return;
                if (found == null) {
                  messenger.showSnackBar(_noMixdownFoundSnackBar(l10n));
                  return;
                }
                setState(() => _replacedPreviewPath = found);
                await _playOnCurrentPlatform(found);
              case PreviewNotFoundAction.selectNew:
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: previewAudioExtensions,
                  dialogTitle: l10n.selectPreviewSong,
                );
                if (!mounted) return;
                final newPath = result?.files.single.path;
                if (newPath == null) return;
                setState(() => _replacedPreviewPath = newPath);
                await widget.onSongChanged(newPath);
                if (!mounted) return;
                await _playOnCurrentPlatform(newPath);
            }
            return;
          }
          
          // Check for a newer audio file in the same folder as the current preview,
          // regardless of whether the path was manually set or auto-detected.
          // Skip the prompt if the user previously rejected this specific file.
          final newer = MixdownDetectorService.findNewerFileInSameFolder(
            _effectivePreviewPath!,
            ignoredPath: widget.project.ignoredNewerSongPath,
          );
          if (newer != null && mounted) {
            final l10n = AppLocalizations.of(context)!;
            final replace = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.newerExportFound),
                content: Text(l10n.newerExportFoundMessage(p.basename(newer.path))),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                  OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.keepCurrent)),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.replaceAndPlay)),
                ],
              ),
            );
            if (!mounted) return;
            if (replace == null) return;
            if (replace) {
              // Override _effectivePreviewPath immediately so the filename display
              // updates before the stream rebuild arrives (covers both manual and auto).
              setState(() => _replacedPreviewPath = newer.path);
              widget.onSongChanged(newer.path);
              await _playOnCurrentPlatform(newer.path);
              return;
            } else {
              // "Keep Current" — remember the user rejected this specific file so
              // we don't ask again unless an even newer file appears.
              final repo = await ref.read(repositoryProvider.future);
              await repo.updateProject(
                widget.project.copyWith(ignoredNewerSongPath: newer.path),
              );
            }
          }

          if (MobileUtils.isMobile()) {
            await _playOnCurrentPlatform(_effectivePreviewPath!);
          } else {
            // Play from current source (stereo or pre-mixed mono).
            if (_playbackEnded) {
              setState(() => _playbackEnded = false);
              await _audioPlayer.stop();
              await _audioPlayer.play(_currentSource(),
                  position: _position > Duration.zero ? _position : null);
            } else if (_position == Duration.zero || _position >= _duration) {
              await _audioPlayer.play(_currentSource());
            } else {
              await _audioPlayer.resume();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToPlayPreview(e.toString()),
            ),
          ),
        );
      }
    }
  }

  /// Inicia playback no player correto para a plataforma.
  /// Mobile → MobilePlayerNotifier (mini player + notificação Android).
  /// Desktop → AudioPlayer local.
  Future<void> _playOnCurrentPlatform(String path) async {
    if (MobileUtils.isMobile()) {
      final queue = ref.read(mobilePlayerQueueProvider);
      final idx = queue.indexWhere((p) => p.id == widget.project.id);
      await ref.read(mobilePlayerProvider.notifier).playProject(
        widget.project,
        path,
        queue: queue,
        queueIndex: idx >= 0 ? idx : null,
      );
    } else {
      await _audioPlayer.play(DeviceFileSource(path));
    }
  }

  Future<void> _seek(int seconds) async {
    await _audioPlayer.seek(seekTarget(_position, seconds, _duration));
  }

  Future<void> _sharePreviewSong() async {
    // Covers a manually-selected preview song AND an auto-detected mixdown —
    // both are equally shareable, only the source of the path differs.
    final effectivePath = _effectivePreviewPath;
    if (effectivePath == null || effectivePath.isEmpty) {
      if (kDebugMode) {
        debugPrint('[preview_share] No effective preview path for project=${widget.project.id}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
        );
      }
      return;
    }

    // Skip if it's a Drive file reference (not downloaded)
    if (effectivePath.startsWith('drive://')) {
      if (kDebugMode) {
        debugPrint('[preview_share] Path is Drive reference (not downloaded): $effectivePath');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongNotAvailableDownloadFirst)),
        );
      }
      return;
    }

    try {
      final sourceFile = File(effectivePath);
      if (kDebugMode) {
        debugPrint('[preview_share] sourceFile=${sourceFile.path}');
      }
      if (!await sourceFile.exists()) {
        if (kDebugMode) {
          debugPrint('[preview_share] sourceFile does not exist');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
          );
        }
        return;
      }

      // WhatsApp enforces a ~64MB limit for audio messages, but typically allows larger files as "documents".
      // Keep default share here (audio). A separate "Share ZIP" button is also available.
      final fileSizeBytes = await sourceFile.length();
      if (kDebugMode) {
        debugPrint('[preview_share] sizeBytes=$fileSizeBytes');
      }

      // Get the original filename — prefer stored name, fall back to project name
      String originalFileName = widget.project.previewShareFileName ??
          p.basename(effectivePath);

      // Ensure the filename has an extension
      if (!originalFileName.contains('.')) {
        final ext = p.extension(effectivePath);
        originalFileName = '$originalFileName$ext';
      }

      // WhatsApp (confirmed via manual testing, including plain OS
      // drag-and-drop of the raw file) rejects WAV/AIFF/FLAC as a direct
      // audio attachment with no error shown to us — convert to a
      // compatible format first so the shared file is actually accepted.
      var fileToShare = sourceFile;
      var shareFileName = originalFileName;
      if (AudioAnalysisService.needsConversionForSharing(effectivePath) && mounted) {
        if (kDebugMode) {
          debugPrint('[preview_share] converting for messaging-app compatibility...');
        }
        final converted = await convertForSharingWithProgress(context, effectivePath);
        if (converted != null) {
          fileToShare = converted;
          shareFileName = p.basename(converted.path);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mp3ConversionFailed)),
          );
        }
      }

      if (!mounted) return;
      final shareText = AppLocalizations.of(
        context,
      )!.sharePreviewSongText(widget.project.displayName);

      // On mobile, copy to cache directory with original name for sharing
      if (MobileUtils.isMobile()) {
        final shareFile = await stageFileForMobileShare(fileToShare, shareFileName);
        if (shareFile == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToSharePreviewSong(shareFileName),
                ),
              ),
            );
          }
          return;
        }
        if (kDebugMode) {
          debugPrint('[preview_share] staged at ${shareFile.path}, invoking share sheet...');
        }

        // Share the file (default behavior)
        final result = await Share.shareXFiles(
          [
            XFile(
              shareFile.path,
              name: shareFileName,
              mimeType: shareMimeTypeForFileName(shareFileName),
            ),
          ],
          text: shareText,
        );
        if (kDebugMode) {
          debugPrint('[preview_share] Share.shareXFiles returned (user completed/dismissed share sheet)');
          debugPrint('[preview_share] ShareResult: status=${result.status} raw=${result.raw}');
        }
      } else {
        // On other platforms, share the file directly
        if (kDebugMode) {
          debugPrint('[preview_share] non-Android direct share, invoking share sheet...');
        }
        final result = await Share.shareXFiles(
          [XFile(fileToShare.path)],
          text: shareText,
        );
        if (kDebugMode) {
          debugPrint('[preview_share] ShareResult: status=${result.status} raw=${result.raw}');
        }
        // Unpackaged Windows builds have no working share sheet
        // (DataTransferManager needs MSIX) — without this the click does
        // nothing visible at all.
        if (result.status == ShareResultStatus.unavailable && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.shareSheetUnavailable)),
          );
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[preview_share] ERROR: $e');
        debugPrint('$st');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSharePreviewSong(e.toString()))),
        );
      }
    }
  }

  Future<void> _sharePreviewSongAsZip() async {
    if (!MobileUtils.isMobile()) return;

    final effectivePath = _effectivePreviewPath;
    if (effectivePath == null || effectivePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
        );
      }
      return;
    }

    // Skip if it's a Drive file reference (not downloaded)
    if (effectivePath.startsWith('drive://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongNotAvailableDownloadFirst)),
        );
      }
      return;
    }

    try {
      final sourceFile = File(effectivePath);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
          );
        }
        return;
      }

      // Get the original filename — prefer stored name, fall back to project name
      String originalFileName = widget.project.previewShareFileName ??
          p.basename(effectivePath);
      if (!originalFileName.contains('.')) {
        final ext = p.extension(effectivePath);
        originalFileName = '$originalFileName$ext';
      }

      // Copy to cache and zip it
      final cacheDir = await getTemporaryDirectory();
      final shareFile = File(p.join(cacheDir.path, originalFileName));
      await sourceFile.copy(shareFile.path);

      final zipBase = p.basenameWithoutExtension(originalFileName);
      var zipPath = p.join(cacheDir.path, '$zipBase.zip');
      var zipFile = File(zipPath);
      if (await zipFile.exists()) {
        zipPath = p.join(cacheDir.path, '${zipBase}_${DateTime.now().millisecondsSinceEpoch}.zip');
        zipFile = File(zipPath);
      }

      if (kDebugMode) {
        debugPrint('[preview_share_zip] sourceFile=${sourceFile.path}');
        debugPrint('[preview_share_zip] copiedTo=${shareFile.path}');
        debugPrint('[preview_share_zip] creating zip: ${zipFile.path}');
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);
      await encoder.addFile(shareFile);
      encoder.close();

      final zipSizeBytes = await zipFile.length();
      if (kDebugMode) {
        debugPrint('[preview_share_zip] zipSizeBytes=$zipSizeBytes');
        debugPrint('[preview_share_zip] invoking share sheet...');
      }

      if (!mounted) return;
      final result = await Share.shareXFiles(
        [XFile(zipFile.path, name: p.basename(zipFile.path), mimeType: 'application/zip')],
        text: AppLocalizations.of(
          context,
        )!.sharePreviewSongZipText(widget.project.displayName),
      );
      if (kDebugMode) {
        debugPrint('[preview_share_zip] Share.shareXFiles returned (user completed/dismissed share sheet)');
        debugPrint('[preview_share_zip] ShareResult: status=${result.status} raw=${result.raw}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[preview_share_zip] ERROR: $e');
        debugPrint('$st');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSharePreviewSongAsZip(e.toString()))),
        );
      }
    }
  }

  /// Desktop (macOS/Windows): opens a save dialog and copies the preview song to the chosen location.
  Future<void> _exportPreviewSongDesktop() async {
    final l10n = AppLocalizations.of(context)!;
    final songPath = _effectivePreviewPath;

    if (songPath == null || songPath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.previewSongFileNotFound)),
        );
      }
      return;
    }

    if (songPath.startsWith('drive://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.previewSongNotAvailableDownloadFirst)),
        );
      }
      return;
    }

    try {
      final sourceFile = File(songPath);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.previewSongFileNotFound)),
          );
        }
        return;
      }

      final originalName = widget.project.previewShareFileName ?? p.basename(songPath);
      final ext = p.extension(songPath).replaceFirst('.', '');

      final destPath = await FilePicker.saveFile(
        dialogTitle: l10n.saveCopy,
        fileName: originalName,
        type: FileType.custom,
        allowedExtensions: [ext.isNotEmpty ? ext : 'mp3'],
      );

      if (destPath == null) return; // user cancelled

      await sourceFile.copy(destPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.savedCopyTo(destPath))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToSharePreviewSong(e.toString()))),
        );
      }
    }
  }

  /// Picks a local audio file on Android/iOS and stores it in the app's preview_songs folder.
  /// This does NOT upload anything to Drive.
  Future<void> _pickPreviewSongMobile() async {
    if (!MobileUtils.isMobile()) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: previewAudioExtensions,
        dialogTitle: l10n.selectPreviewSong,
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return;
      }

      final source = File(result.files.single.path!);
      if (!await source.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.previewSongFileNotFound)),
          );
        }
        return;
      }

      // Copy into app's persistent documents directory for reliable access
      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(appDir.path, 'preview_songs', widget.project.id));
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      final originalName =
          result.files.single.name.isNotEmpty ? result.files.single.name : p.basename(source.path);
      final destPath = p.join(destDir.path, originalName);
      await source.copy(destPath);

      final repo = await ref.read(repositoryProvider.future);
      final updated = widget.project.copyWith(
        previewSongPath: destPath,
        previewSongFileName: originalName,
        clearUploadedPreviewSongHash: true,
        updatedAt: DateTime.now(),
      );
      await repo.updateProject(updated);

      // Refresh UI
      ref.invalidate(allProjectsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.previewSongAdded)),
        );
      }
    } on PlatformException catch (e) {
      // Common error in Android emulators: file picker can't access storage
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to select file: ${e.message ?? "Unknown error"}\n\n'
              'Note: This often happens in Android emulators. '
              'Try using a real device or adding audio files to the emulator storage.',
            ),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? '${twoDigits(hours)}:$minutes:$seconds' : '$minutes:$seconds';
  }

  bool _isValidAudioFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return MixdownDetectorService.audioExtensions.contains(ext);
  }

  Future<void> _handleDroppedFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      if (kDebugMode) {
        print('No file paths provided');
      }
      return;
    }

    if (kDebugMode) {
      print('Dropped files: $filePaths');
    }

    // Use the first valid audio file
    for (final filePath in filePaths) {
      if (kDebugMode) {
        print('Checking file: $filePath');
        print('Is valid audio: ${_isValidAudioFile(filePath)}');
      }

      if (_isValidAudioFile(filePath)) {
        final file = File(filePath);
        final exists = await file.exists();
        if (kDebugMode) {
          print('File exists: $exists');
        }

        if (exists) {
          if (kDebugMode) {
            print('Calling onSongChanged with: $filePath');
          }
          await widget.onSongChanged(filePath);
          return;
        }
      }
    }

    // If no valid audio file was found, show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.previewSongFileNotFound),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(desktopPlayerProvider, (prev, next) {
      if (next != null && _isPlaying) _audioPlayer.pause();
    });

    // Sync local display state from the global player when on mobile.
    if (MobileUtils.isMobile()) {
      ref.listen<MobilePlayerState>(mobilePlayerProvider, (prev, next) {
        final isThisTrack = next.currentProject?.id == widget.project.id;
        if (isThisTrack) {
          setState(() {
            _isPlaying = next.isPlaying;
            _position = next.position;
            _duration = next.duration;
          });
        } else if (prev?.currentProject?.id == widget.project.id && !isThisTrack) {
          setState(() => _isPlaying = false);
        }
      });
    }
    return DropTarget(
      enable: dropTargetEnabled,
      onDragDone: (detail) async {
        setState(() {
          _isDraggingOver = false;
        });
        try {
          if (detail.files.isNotEmpty) {
            if (kDebugMode) {
              print('Files dropped: ${detail.files.length}');
              for (final file in detail.files) {
                print('File: ${file.name}, path: ${file.path}');
              }
            }

            // Extract file paths from dropped files
            final filePaths = <String>[];
            for (final file in detail.files) {
              if (file.path.isNotEmpty) {
                filePaths.add(file.path);
              }
            }

            if (filePaths.isNotEmpty) {
              await _handleDroppedFiles(filePaths);
            } else if (kDebugMode) {
              print('No valid file paths found');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error handling dropped files: $e');
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.errorHandlingDroppedFiles(e.toString())),
              ),
            );
          }
        }
      },
      onDragEntered: (detail) {
        setState(() {
          _isDraggingOver = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _isDraggingOver = false;
        });
      },
      child: Card(
        color: _isDraggingOver
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        child: Container(
          decoration: _isDraggingOver
              ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.previewSong,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 12),
                if (_hasAudioFile())
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.project.previewSongFileName ??
                              p.basename(_effectivePreviewPath!),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red.shade300,
                            onPressed: () async {
                              // Show confirmation dialog
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    AppLocalizations.of(context)!.removePreviewSong,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(context)!.removePreviewSongConfirm,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: Text(AppLocalizations.of(context)!.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: Text(AppLocalizations.of(context)!.remove),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                // Stop audio if playing
                                await _audioPlayer.stop();
                                setState(() {
                                  _isPlaying = false;
                                  _position = Duration.zero;
                                  _duration = Duration.zero;
                                });
                                await widget.onSongRemoved();
                              }
                            },
                            tooltip: AppLocalizations.of(
                              context,
                            )!.removePreviewSong,
                          ),
                        ],
                      ),
                      if (_autoDetectedPath != null &&
                          widget.project.previewSongPath?.isNotEmpty != true)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.folder_open,
                                  size: 12, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                'Auto-detected from mixdown folder',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.amber),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 2),
                      _FileInfoRow(
                        path: _effectivePreviewPath!,
                        fileInfo: _fileInfo,
                      ),
                      const SizedBox(height: 10),
                      // Audio player controls with keyboard shortcuts
                      Focus(
                        focusNode: _focusNode,
                        onKeyEvent: (node, event) {
                          if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
                          final isModified = HardwareKeyboard.instance.isControlPressed ||
                              HardwareKeyboard.instance.isMetaPressed;
                          if (event.logicalKey == LogicalKeyboardKey.space) {
                            _togglePlayPause();
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            _seek(isModified ? -30 : -5);
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                            _seek(isModified ? 30 : 5);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Transport + volume row. The volume slider is
                            // Flexible and the time moved to its own line
                            // below, so this never overflows the card on a
                            // narrow (sectioned) detail layout — the elapsed /
                            // total used to be pushed off the right edge.
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.replay_5),
                                  tooltip: Platform.isMacOS ? '← −5s  •  ⌘+← −30s' : '← −5s  •  Ctrl+← −30s',
                                  onPressed: () => _seek(-5),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                                  ),
                                  onPressed: () {
                                    _focusNode.requestFocus();
                                    _togglePlayPause();
                                  },
                                  iconSize: 34,
                                  color: _autoDetectedPath != null &&
                                          widget.project.previewSongPath
                                                  ?.isNotEmpty !=
                                              true
                                      ? Colors.amber
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.forward_5),
                                  tooltip: Platform.isMacOS ? '→ +5s  •  ⌘+→ +30s' : '→ +5s  •  Ctrl+→ +30s',
                                  onPressed: () => _seek(5),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(
                                    _volume == 0 ? Icons.volume_off : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    if (_volume > 0) {
                                      setState(() { _preMuteVolume = _volume; _volume = 0; });
                                      await _audioPlayer.setVolume(0);
                                    } else {
                                      final restore = _preMuteVolume > 0 ? _preMuteVolume : 1.0;
                                      setState(() { _volume = restore; });
                                      await _audioPlayer.setVolume(restore);
                                    }
                                  },
                                  tooltip: _volume == 0 ? AppLocalizations.of(context)!.volumeUnmute : AppLocalizations.of(context)!.volumeMute,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                Flexible(
                                  child: SizedBox(
                                    width: 120,
                                    child: Slider(
                                      value: _volume,
                                      min: 0.0,
                                      max: 1.0,
                                      onChanged: (value) async {
                                        setState(() { _volume = value; });
                                        await _audioPlayer.setVolume(value);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Elapsed / total — its own line, spread to the
                            // edges so both ends stay inside the card.
                            Padding(
                              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_duration),
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Waveform
                            WaveformWidget(
                              peaks: _peaks,
                              progress: _duration.inMilliseconds > 0
                                  ? _position.inMilliseconds / _duration.inMilliseconds
                                  : 0.0,
                              height: 80,
                              onSeek: (p) {
                                final target = Duration(milliseconds: (p * _duration.inMilliseconds).round());
                                setState(() => _position = target);
                                _audioPlayer.seek(target);
                              },
                            ),
                          ],
                        ),
                      ),
                      // Mono toggle + Analyze (any audio file)
                      if (_hasAudioFile()) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Tooltip(
                              message: AppLocalizations.of(context)!.monoToggleTooltip,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18, height: 18,
                                    child: _isGeneratingMono
                                        ? const CircularProgressIndicator(strokeWidth: 2)
                                        : Checkbox(
                                            value: _isMono,
                                            onChanged: (_) => _toggleMono(),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                            activeColor: Colors.red,
                                          ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _isGeneratingMono ? null : _toggleMono,
                                    child: Text(
                                      AppLocalizations.of(context)!.monoLabel,
                                      style: TextStyle(color: _isMono ? Colors.red : null),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.noPreviewSongSelected,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (_isDraggingOver)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            AppLocalizations.of(context)!.dropAudioFileHere,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                // On mobile, show Share button instead of Change Preview Song
                // On desktop, show Change Preview Song button
                MobileUtils.isMobile()
                    ? Builder(
                        builder: (context) {
                          final buttons = <Widget>[];

                          // Mobile: allow selecting/changing preview song locally
                          buttons.add(
                            ElevatedButton.icon(
                              onPressed: _pickPreviewSongMobile,
                              icon: const Icon(Icons.audio_file),
                              label: Text(
                                widget.project.previewSongPath != null &&
                                        widget.project.previewSongPath!.isNotEmpty
                                    ? AppLocalizations.of(context)!.changePreviewSong
                                    : AppLocalizations.of(context)!.selectPreviewSong,
                              ),
                            ),
                          );

                          // Share (manual or auto-detected preview song, as long
                          // as it's a local file and not a pending Drive reference)
                          if (_effectivePreviewPath != null &&
                              _effectivePreviewPath!.isNotEmpty &&
                              !_effectivePreviewPath!.startsWith('drive://')) {
                            buttons.add(
                              ElevatedButton.icon(
                                onPressed: _sharePreviewSong,
                                icon: const Icon(Icons.share),
                                label: Text(AppLocalizations.of(context)!.share),
                              ),
                            );

                            if (MobileUtils.isMobile()) {
                              buttons.add(
                                ElevatedButton.icon(
                                  onPressed: _sharePreviewSongAsZip,
                                  icon: const Icon(Icons.folder_zip),
                                  label: Text(AppLocalizations.of(context)!.shareZip),
                                ),
                              );
                            }
                          }

                          if (buttons.isEmpty) return const SizedBox.shrink();
                          return Wrap(spacing: 8, runSpacing: 8, children: buttons);
                        },
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: previewAudioExtensions,
                                dialogTitle: AppLocalizations.of(context)!.selectPreviewSong,
                              );
                              if (result != null && result.files.single.path != null) {
                                widget.onSongChanged(result.files.single.path!);
                              }
                            },
                            icon: const Icon(Icons.audio_file),
                            label: Text(
                              widget.project.previewSongPath != null &&
                                      widget.project.previewSongPath!.isNotEmpty
                                  ? AppLocalizations.of(context)!.changePreviewSong
                                  : AppLocalizations.of(context)!.selectPreviewSong,
                            ),
                          ),
                          // Deliberate re-scan of the mixdown folders. Removal
                          // no longer auto-detects, so this is how the user
                          // opts back into an auto preview. Only meaningful
                          // when they haven't set a manual pick.
                          if (widget.project.previewSongPath?.isNotEmpty != true)
                            OutlinedButton.icon(
                              onPressed: _findMixdownNow,
                              icon: const Icon(Icons.travel_explore),
                              label: Text(
                                AppLocalizations.of(context)!
                                    .findPreviewAutomatically,
                              ),
                            ),
                          if (_effectivePreviewPath != null &&
                              _effectivePreviewPath!.isNotEmpty &&
                              !_effectivePreviewPath!.startsWith('drive://')) ...[
                            ElevatedButton.icon(
                              onPressed: _exportPreviewSongDesktop,
                              icon: const Icon(Icons.save_alt),
                              label: Text(AppLocalizations.of(context)!.saveCopy),
                            ),
                            ElevatedButton.icon(
                              onPressed: _sharePreviewSong,
                              icon: const Icon(Icons.share),
                              label: Text(AppLocalizations.of(context)!.share),
                            ),
                          ],
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
// Project Stats Button — navigates to the dedicated statistics page
// ---------------------------------------------------------------------------

// ─── File info row ────────────────────────────────────────────────────────────

class _FileInfoRow extends StatelessWidget {
  final String path;
  final AudioFileInfo? fileInfo;

  const _FileInfoRow({required this.path, required this.fileInfo});

  String get _formatLabel {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'wav': return 'WAV';
      case 'mp3': return 'MP3';
      case 'flac': return 'FLAC';
      case 'aif': case 'aiff': return 'AIFF';
      case 'aac': return 'AAC';
      case 'm4a': return 'M4A';
      case 'ogg': return 'OGG';
      default: return ext.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).textTheme.bodySmall?.color;

    final parts = <String>[];
    if (fileInfo != null) {
      final sr = fileInfo!.sampleRate;
      parts.add(sr % 1000 == 0 ? '${sr ~/ 1000} kHz' : '${(sr / 1000).toStringAsFixed(1)} kHz');
      if (fileInfo!.bitDepth != null) {
        parts.add('${fileInfo!.bitDepth}-bit');
      } else if (fileInfo!.bitrateKbps != null) {
        parts.add('${fileInfo!.bitrateKbps} kbps');
      }
      final ch = fileInfo!.channels;
      parts.add(ch == 1 ? 'Mono' : ch == 2 ? 'Stereo' : '${ch}ch');
    }
    parts.add(_formatLabel);

    return Text(
      parts.join(' · '),
      style: TextStyle(fontSize: 11, color: dim),
    );
  }
}

class _ProjectStatsButton extends ConsumerWidget {
  final String projectId;
  const _ProjectStatsButton({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final events = ref.watch(eventsForProjectProvider(projectId));

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bar_chart_rounded, size: 20),
      title: Text(
        l10n.statsSingleProjectActivity,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        events.isEmpty
            ? l10n.statsNoEvents
            : l10n.statsEventCount(events.length),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectStatisticsPage(projectId: projectId),
        ),
      ),
    );
  }
}

class _RenameProjectDialog extends StatefulWidget {
  final String currentName;
  final bool canRenameFolder;

  const _RenameProjectDialog({
    required this.currentName,
    required this.canRenameFolder,
  });

  @override
  State<_RenameProjectDialog> createState() => _RenameProjectDialogState();
}

class _RenameProjectDialogState extends State<_RenameProjectDialog> {
  late final TextEditingController _ctrl;
  bool _renameFolder = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
    _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: widget.currentName.length);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.renameProjectFileTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.newFileNameLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final l10n = AppLocalizations.of(context)!;
                if (v == null || v.trim().isEmpty) return l10n.nameCannotBeEmpty;
                if (v.contains('/') || v.contains('\\') || v.contains(':')) {
                  return l10n.nameInvalidCharacters;
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (widget.canRenameFolder) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _renameFolder,
                onChanged: (v) => setState(() => _renameFolder = v ?? true),
                title: Text(AppLocalizations.of(context)!.alsoRenameContainingFolder),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(AppLocalizations.of(context)!.renameButton),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      newName: _ctrl.text.trim(),
      renameFolder: widget.canRenameFolder && _renameFolder,
    ));
  }
}

// ─── Session History Section ──────────────────────────────────────────────────

class _SessionHistorySection extends StatefulWidget {
  final List<SessionRecord> sessions;

  /// Null makes the list read-only. Used for a stack, whose sessions are
  /// aggregated from its versions: the records belong to the member projects,
  /// so editing one from here would have to guess which member to write back
  /// to. Editing stays on the version's own page, which owns the record.
  final void Function(SessionRecord)? onRemove;
  final void Function(SessionRecord updated)? onEdit;
  const _SessionHistorySection({
    required this.sessions,
    this.onRemove,
    this.onEdit,
  });

  bool get isReadOnly => onRemove == null || onEdit == null;

  @override
  State<_SessionHistorySection> createState() => _SessionHistorySectionState();
}

class _SessionHistorySectionState extends State<_SessionHistorySection> {
  bool _expanded = true;

  void _editSessionDuration(BuildContext context, SessionRecord session) async {
    final updated = await showDialog<SessionRecord>(
      context: context,
      builder: (ctx) => _EditSessionDialog(session: session),
    );
    if (updated != null) widget.onEdit?.call(updated);
  }

  void _confirmRemove(BuildContext context, SessionRecord session) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, yyyy');
    final timeFmt = DateFormat('HH:mm');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeSessionTitle),
        content: Text(
          '${dateFmt.format(session.startedAt)}  '
          '${timeFmt.format(session.startedAt)}–${timeFmt.format(session.endedAt)}  '
          '(${_fmtDuration(session.durationSeconds)})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onRemove?.call(session);
            },
            child: Text(l10n.delete,
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  static String _fmtDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sorted = [...widget.sessions]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final totalSeconds =
        widget.sessions.fold<int>(0, (a, b) => a + b.durationSeconds);
    final dateFmt = DateFormat('MMM d, yyyy');
    final timeFmt = DateFormat('HH:mm');
    final bodySmall = theme.textTheme.bodySmall;
    final divider = theme.dividerColor.withValues(alpha: 0.4);

    Widget cell(String text, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Text(
            text,
            style: bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
        );

    final canToggle = widget.sessions.isNotEmpty;

    final Map<String, List<SessionRecord>> byPhase = {};
    for (final s in widget.sessions) {
      (byPhase[s.phase ?? '—'] ??= []).add(s);
    }
    final phaseEntries = byPhase.entries.toList()
      ..sort((a, b) {
        final durA = a.value.fold<int>(0, (acc, r) => acc + r.durationSeconds);
        final durB = b.value.fold<int>(0, (acc, r) => acc + r.durationSeconds);
        return durB.compareTo(durA);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: canToggle ? () => setState(() => _expanded = !_expanded) : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.work_history_outlined,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n.sessionHistory,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (canToggle && !_expanded) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.sessionCount(widget.sessions.length)} · ${_fmtDuration(totalSeconds)}',
                    style: bodySmall?.copyWith(color: theme.disabledColor),
                  ),
                ],
                const Spacer(),
                if (canToggle)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: theme.disabledColor,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.sessions.isEmpty)
          Text(
            l10n.noSessionsYet,
            style: bodySmall?.copyWith(color: theme.disabledColor),
          )
        else if (_expanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(color: divider, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    // Header
                    TableRow(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      ),
                      children: [
                        cell(l10n.sessionTableDate, bold: true),
                        cell(l10n.sessionTableTime, bold: true),
                        cell(l10n.phase, bold: true),
                        cell(l10n.sessionTableDuration, bold: true),
                      ],
                    ),
                    // One row per individual session
                    for (final s in sorted)
                      TableRow(
                        children: [
                          cell(dateFmt.format(s.startedAt)),
                          cell(
                              '${timeFmt.format(s.startedAt)}–${timeFmt.format(s.endedAt)}'),
                          cell(s.phase ?? '—'),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            child: Row(
                              children: [
                                Text(_fmtDuration(s.durationSeconds),
                                    style: bodySmall),
                                const Spacer(),
                                if (!widget.isReadOnly) ...[
                                  GestureDetector(
                                    onTap: () =>
                                        _editSessionDuration(context, s),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _confirmRemove(context, s),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 14,
                                      color: theme.colorScheme.error
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    // Total row
                    TableRow(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      ),
                      children: [
                        cell(l10n.sessionTableTotal,
                            bold: true, color: theme.colorScheme.primary),
                        cell(l10n.sessionCount(widget.sessions.length),
                            color: theme.colorScheme.primary),
                        cell(''),
                        cell(_fmtDuration(totalSeconds),
                            bold: true, color: theme.colorScheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
              if (phaseEntries.length > 1) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.bar_chart_outlined,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      l10n.sessionByPhase,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                    },
                    border: TableBorder(
                      horizontalInside: BorderSide(color: divider, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.08),
                        ),
                        children: [
                          cell(l10n.phase, bold: true),
                          cell(l10n.sessionTableDuration, bold: true),
                        ],
                      ),
                      for (final entry in phaseEntries)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    l10n.sessionCount(entry.value.length),
                                    style: bodySmall?.copyWith(
                                        color: theme.disabledColor),
                                  ),
                                ],
                              ),
                            ),
                            cell(
                              _fmtDuration(entry.value.fold<int>(
                                  0, (acc, r) => acc + r.durationSeconds)),
                              bold: true,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

// ─── Edit Session Duration Dialog ────────────────────────────────────────────

class _EditSessionDialog extends StatefulWidget {
  final SessionRecord session;
  const _EditSessionDialog({required this.session});

  @override
  State<_EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<_EditSessionDialog> {
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _minutesCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final h = widget.session.durationSeconds ~/ 3600;
    final m = (widget.session.durationSeconds % 3600) ~/ 60;
    _hoursCtrl = TextEditingController(text: h.toString());
    _minutesCtrl = TextEditingController(text: m.toString());
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final h = int.tryParse(_hoursCtrl.text.trim()) ?? 0;
    final m = int.tryParse(_minutesCtrl.text.trim()) ?? 0;
    final newSeconds = h * 3600 + m * 60;
    final updated = SessionRecord(
      id: widget.session.id,
      startedAt: widget.session.startedAt,
      endedAt: widget.session.endedAt,
      durationSeconds: newSeconds,
      phase: widget.session.phase,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('MMM d, yyyy');
    final timeFmt = DateFormat('HH:mm');

    return AlertDialog(
      title: Text(l10n.editSessionTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dateFmt.format(widget.session.startedAt)}  '
              '${timeFmt.format(widget.session.startedAt)}–'
              '${timeFmt.format(widget.session.endedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hoursCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.editSessionHours,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final val = int.tryParse(v?.trim() ?? '');
                      if (val == null || val < 0) return '0+';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minutesCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.minutes,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final h = int.tryParse(_hoursCtrl.text.trim()) ?? 0;
                      final m = int.tryParse(v?.trim() ?? '');
                      if (m == null || m < 0 || m > 59) return '0–59';
                      if (h == 0 && m == 0) {
                        return l10n.editSessionInvalid;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// One group of the project detail page's content.
///
/// The classic layout concatenates every group into a single scroll; the
/// sectioned layout renders one at a time with the nav rail choosing. Keeping
/// them as data rather than as separate widgets means both layouts are fed by
/// exactly the same children, so the two cannot drift apart.
class _DetailSection {
  const _DetailSection({
    required this.icon,
    required this.label,
    required this.children,
  });

  final IconData icon;
  final String label;
  final List<Widget> children;
}
