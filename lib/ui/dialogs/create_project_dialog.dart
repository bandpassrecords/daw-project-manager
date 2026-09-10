import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../models/pending_folder.dart';
import '../../models/project_template.dart';
import '../../models/scan_root.dart';
import '../../providers/providers.dart';
import '../../services/daw_detector.dart';
import '../../services/metadata_extractor.dart';
import '../../services/project_template_service.dart';
import '../../utils/daw_logo.dart';
import '../../utils/file_launcher.dart';
import '../project_templates_page.dart';
import '../session_actions.dart';

enum _NamingScheme { artistTrack, collab, dateTrack, custom, remix }

enum _StartMode { emptyFolder, template }

/// Builds the "remix" naming scheme's folder/file name: the original
/// artist and track, followed by a "(Remixer[, Remixer2, ...] Remix)"
/// suffix — e.g. "Massive Attack - Teardrop (Audio Crawler Remix)" or,
/// with more than one remixer, "... (Audio Crawler vs M4rs Remix)".
/// Extracted as a standalone function (rather than left inline in the
/// dialog's private `_folderName` getter) so this naming logic can be unit
/// tested without pumping the whole wizard widget.
@visibleForTesting
String buildRemixFolderName({
  required String originalArtist,
  required String track,
  required List<String> remixerNames,
  String datePrefix = '',
}) {
  final artist = originalArtist.trim();
  final trackName = track.trim();
  final remixers = remixerNames
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final suffix = remixers.isEmpty ? '' : ' (${remixers.join(' vs ')} Remix)';

  if (artist.isEmpty && trackName.isEmpty) return '';
  if (artist.isEmpty) return '$datePrefix$trackName$suffix';
  if (trackName.isEmpty) return '$datePrefix$artist$suffix';
  return '$datePrefix$artist - $trackName$suffix';
}

class CreateProjectDialog extends ConsumerStatefulWidget {
  /// Pre-selects a template and jumps straight to the template flow — used
  /// by "Use as new project" on [ProjectTemplatesPage] so the user doesn't
  /// have to find the same template again inside this wizard.
  final ProjectTemplate? initialTemplate;

  const CreateProjectDialog({super.key, this.initialTemplate});

  @override
  ConsumerState<CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Location
  ScanRoot? _selectedRoot;

  // Step 2: Naming
  _NamingScheme _scheme = _NamingScheme.artistTrack;
  // The profile's own artist name (auto-filled from the profile), used by the
  // artist/collab schemes.
  final _primaryArtistController = TextEditingController();
  // The *original* track's artist — remix scheme only. Kept separate from
  // _primaryArtistController so switching schemes never bleeds the profile
  // name into "original artist", or the original artist back into the
  // profile-artist field.
  final _originalArtistController = TextEditingController();
  final _trackNameController = TextEditingController();
  final _customNameController = TextEditingController();
  final List<TextEditingController> _collabControllers = [];
  // Remix scheme: one or more remixer names, distinct from
  // _collabControllers — those are additional *primary* artists, these are
  // the people remixing someone else's track, joined with " vs " rather
  // than " & " (e.g. "Massive Attack - Teardrop (Audio Crawler Remix)" or
  // "... (Audio Crawler vs M4rs Remix)").
  final List<TextEditingController> _remixArtistControllers = [];
  bool _isFolderValid = true;
  String? _folderError;

  // Step 3: Start (empty folder vs. template)
  _StartMode _startMode = _StartMode.emptyFolder;
  ProjectTemplate? _selectedTemplate;
  final _templateSearchController = TextEditingController();
  String _templateQuery = '';

  // Step 4: DAW (only reachable when _startMode is emptyFolder)
  List<DetectedDaw>? _detectedDaws;
  bool _detectingDaws = false;
  DetectedDaw? _selectedDaw;

  // Options
  bool _includeTimestamp = false;

  // Success state
  bool _folderCreated = false;
  String _createdPath = '';
  String _createdFolderName = '';
  bool _openedInDaw = false;
  bool _trackSessionFromNow = false;
  PendingFolder? _createdPendingFolder;
  // Set only by the template flow, which never auto-launches the DAW (see
  // _finishFromTemplate) — lets the success screen offer a manual "Open in
  // DAW" button without needing to look the project back up.
  MusicProject? _createdProjectForLaunch;

  @override
  void initState() {
    super.initState();
    _collabControllers.add(TextEditingController());
    _remixArtistControllers.add(TextEditingController());
    _trackNameController.addListener(_onNameChanged);
    _primaryArtistController.addListener(_onNameChanged);
    _originalArtistController.addListener(_onNameChanged);
    _customNameController.addListener(_onNameChanged);
    _templateSearchController.addListener(() {
      setState(
        () => _templateQuery = _templateSearchController.text
            .trim()
            .toLowerCase(),
      );
    });
    _includeTimestamp =
        Hive.box<String>('settings').get('createProjectIncludeDate') == 'true';
    if (widget.initialTemplate != null) {
      _startMode = _StartMode.template;
      _selectedTemplate = widget.initialTemplate;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _primaryArtistController.dispose();
    _originalArtistController.dispose();
    _trackNameController.dispose();
    _customNameController.dispose();
    _templateSearchController.dispose();
    for (final c in _collabControllers) {
      c.dispose();
    }
    for (final c in _remixArtistControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onNameChanged() => setState(() {
    _validateFolderName();
  });

  void _toggleIncludeTimestamp(bool value) {
    setState(() => _includeTimestamp = value);
    Hive.box<String>(
      'settings',
    ).put('createProjectIncludeDate', value.toString());
    _validateFolderName();
  }

  String get _folderName {
    final track = _trackNameController.text.trim();
    final datePrefix = _includeTimestamp && _scheme != _NamingScheme.dateTrack
        ? '${DateFormat('yyyy-MM-dd').format(DateTime.now())} - '
        : '';

    switch (_scheme) {
      case _NamingScheme.artistTrack:
        final artist = _primaryArtistController.text.trim();
        if (artist.isEmpty && track.isEmpty) return '';
        if (artist.isEmpty) return '$datePrefix$track';
        if (track.isEmpty) return '$datePrefix$artist';
        return '$datePrefix$artist - $track';

      case _NamingScheme.collab:
        final artists = [
          _primaryArtistController.text.trim(),
          ..._collabControllers.map((c) => c.text.trim()),
        ].where((s) => s.isNotEmpty).toList();
        final artistStr = artists.join(' & ');
        if (artistStr.isEmpty && track.isEmpty) return '';
        if (artistStr.isEmpty) return '$datePrefix$track';
        if (track.isEmpty) return '$datePrefix$artistStr';
        return '$datePrefix$artistStr - $track';

      case _NamingScheme.dateTrack:
        final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (track.isEmpty) return date;
        return '$date - $track';

      case _NamingScheme.custom:
        final custom = _customNameController.text.trim();
        if (custom.isEmpty) return '';
        return '$datePrefix$custom';

      case _NamingScheme.remix:
        return buildRemixFolderName(
          originalArtist: _originalArtistController.text,
          track: track,
          remixerNames: _remixArtistControllers.map((c) => c.text).toList(),
          datePrefix: datePrefix,
        );
    }
  }

  void _validateFolderName() {
    final name = _folderName;
    if (name.isEmpty) {
      _isFolderValid = false;
      _folderError = null;
      return;
    }
    // Check invalid characters (Windows + macOS)
    final invalid = RegExp(r'[<>:"/\\|?*\x00-\x1f]');
    if (invalid.hasMatch(name)) {
      _isFolderValid = false;
      _folderError = AppLocalizations.of(context)!.createProjectInvalidChars;
      return;
    }
    // Check if folder already exists in selected root
    if (_selectedRoot != null) {
      final targetPath = p.join(_selectedRoot!.path, name);
      if (Directory(targetPath).existsSync()) {
        _isFolderValid = false;
        _folderError = AppLocalizations.of(context)!.createProjectFolderExists;
        return;
      }
    }
    _isFolderValid = true;
    _folderError = null;
  }

  Future<void> _startDawDetection() async {
    setState(() => _detectingDaws = true);
    final daws = await DawDetector.detectInstalledDaws();
    if (mounted) {
      setState(() {
        _detectedDaws = daws;
        _detectingDaws = false;
      });
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish({bool openInDaw = false}) async {
    if (_selectedRoot == null || _folderName.isEmpty || !_isFolderValid) return;

    final targetPath = p.join(_selectedRoot!.path, _folderName);
    final folderName = _folderName;

    // Create the folder
    try {
      await PendingFolder.createEmptyFolder(targetPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.createProjectError}: $e',
            ),
          ),
        );
      }
      return;
    }

    // Register as a pending folder so a row appears in the project list
    final pf = PendingFolder.create(
      path: targetPath,
      intendedDawName: openInDaw ? _selectedDaw?.name : null,
    );
    final repo = await ref.read(repositoryProvider.future);
    await repo.addPendingFolder(pf);
    ref.read(pendingFoldersDirtyProvider.notifier).bump();

    // Launch the DAW
    if (openInDaw && _selectedDaw != null) {
      final exePath = _selectedDaw!.executablePath;
      try {
        if (Platform.isMacOS && exePath.endsWith('.app')) {
          await Process.start('open', [
            exePath,
          ], mode: ProcessStartMode.detached);
        } else {
          await Process.start(
            exePath,
            [],
            workingDirectory: File(exePath).parent.path,
            mode: ProcessStartMode.detached,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.couldNotLaunchDaw(_selectedDaw!.name, e.toString()),
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _folderCreated = true;
        _createdPath = targetPath;
        _createdFolderName = folderName;
        _openedInDaw = openInDaw;
        _trackSessionFromNow = openInDaw;
        _createdPendingFolder = pf;
      });
    }
  }

  /// Copies the selected template into a new project folder, renames its
  /// main file to match, and registers the result as a real project (there's
  /// no PendingFolder placeholder step here — the DAW file already exists
  /// the moment the copy finishes). The DAW is never launched automatically
  /// here — the success view's Open Folder / Copy Name options are enough
  /// for the "just get the folder ready" case a template is usually for. In
  /// session mode we additionally ask whether to start the session now,
  /// rather than assuming that from "session mode is on" alone.
  Future<void> _finishFromTemplate() async {
    if (_selectedRoot == null ||
        _folderName.isEmpty ||
        !_isFolderValid ||
        _selectedTemplate == null) {
      return;
    }

    final targetPath = p.join(_selectedRoot!.path, _folderName);
    final folderName = _folderName;
    final template = _selectedTemplate!;

    // Other templates registered from the same "shared" folder (see
    // ProjectTemplateService.discoverTemplateCandidates) — instantiate()
    // needs these to know which parts of the folder belong to a *different*
    // song and should be left out of the copy.
    final templatesBox = await Hive.openBox<ProjectTemplate>(
      'projectTemplates',
    );
    final siblingTemplates = templatesBox.values
        .where(
          (t) =>
              t.id != template.id &&
              t.sourceFolderPath == template.sourceFolderPath,
        )
        .toList();

    final String newMainFilePath;
    try {
      newMainFilePath = await ProjectTemplateService.instantiate(
        template: template,
        destinationFolderPath: targetPath,
        newProjectName: folderName,
        siblingTemplates: siblingTemplates,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.createProjectError}: $e',
            ),
          ),
        );
      }
      return;
    }

    final repo = await ref.read(repositoryProvider.future);
    await repo.upsertFromFileSystemEntity(
      File(newMainFilePath),
      fullMetadata: true,
    );

    // The template's main file format may not support auto-extraction (e.g.
    // FL Studio, Logic) — fall back to whatever bpm/key the user filled in
    // manually on the template itself, same as a project's own manual fields.
    var createdProject = repo.getByPath(newMainFilePath);
    if (createdProject != null) {
      final needsBpm = createdProject.bpm == null && template.bpm != null;
      final needsKey =
          createdProject.musicalKey == null && template.musicalKey != null;
      createdProject = createdProject.copyWith(
        bpm: needsBpm ? template.bpm : null,
        musicalKey: needsKey ? template.musicalKey : null,
        sourceTemplateId: template.id,
      );
      await repo.updateProject(createdProject);
    }

    // Flags the row with the same "New" badge a background-discovered
    // project gets on the main dashboard, and feeds the idle-suggestions
    // panel — otherwise a project created from the templates page (which
    // isn't the dashboard) has no visible sign it just appeared.
    if (createdProject != null) {
      ref.read(recentlyDiscoveredProjectsProvider.notifier).addAll([
        createdProject.id,
      ]);
    }

    // Unlike the empty-folder flow, a template-created project never opens
    // the DAW automatically — the whole point of a template is the folder
    // being ready, not necessarily wanting to jump into it immediately. In
    // session mode we still ask, since starting a session is a deliberate
    // choice (and may need to prompt about switching an active one) rather
    // than something to assume from "session mode is on".
    if (ref.read(sessionModeProvider) && createdProject != null && mounted) {
      await confirmStartSession(context, ref, createdProject);
    }

    if (mounted) {
      setState(() {
        _folderCreated = true;
        _createdPath = targetPath;
        _createdFolderName = folderName;
        _openedInDaw = false;
        _trackSessionFromNow = false;
        _createdPendingFolder = null;
        _createdProjectForLaunch = createdProject;
      });
    }
  }

  /// Applies session stamping (if opted in) then closes the dialog.
  Future<void> _closeSuccess({bool openFolder = false}) async {
    if (_trackSessionFromNow && _createdPendingFolder != null) {
      final repo = await ref.read(repositoryProvider.future);
      await repo.updatePendingFolder(
        _createdPendingFolder!.copyWith(
          sessionStartedAt: _createdPendingFolder!.createdAt,
        ),
      );
      // Bump so _PendingFoldersSection rebuilds with the fresh pf that has
      // sessionStartedAt set — without this the row widget keeps the stale
      // object and the Refresh handler would read sessionStartedAt == null.
      ref.read(pendingFoldersDirtyProvider.notifier).bump();
    }
    if (mounted) {
      if (openFolder) FileLauncher.openFolder(_createdPath);
      Navigator.of(context).pop(_createdPath);
    }
  }

  Widget _buildSuccessView(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeSuccess,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.createProjectCreatedTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createProjectCreatedMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: SelectableText(
              _createdPath,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          // Session tracking opt-in — only shown when the DAW was launched
          // and session mode is active.
          if (_openedInDaw && ref.watch(sessionModeProvider)) ...[
            const SizedBox(height: 12),
            CheckboxListTile.adaptive(
              title: Text(l10n.createProjectTrackSession),
              value: _trackSessionFromNow,
              onChanged: (v) =>
                  setState(() => _trackSessionFromNow = v ?? false),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: Text(l10n.createProjectCopyName),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _createdFolderName),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.createProjectNameCopied),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: Text(l10n.openFolder),
                onPressed: () => _closeSuccess(openFolder: true),
              ),
              if (_createdProjectForLaunch != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l10n.openInDaw),
                  onPressed: () =>
                      launchProjectInDaw(context, ref, _createdProjectForLaunch!),
                ),
              FilledButton(onPressed: _closeSuccess, child: Text(l10n.close)),
            ],
          ),
        ],
      ),
    );
  }

  bool get _hasMultipleRoots {
    final roots = ref.read(scanRootsProvider);
    return roots.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    final roots = ref.watch(scanRootsProvider);
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(currentProfileProvider).value;

    // Auto-select if only one root
    if (_selectedRoot == null && roots.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedRoot = roots.first);
      });
    }

    // Pre-fill the profile-artist field from the profile name. It has its own
    // controller (the remix "original artist" field is _originalArtist
    // controller), so this is safe to do regardless of the current scheme —
    // switching back to artist/collab always shows the profile name again,
    // while anything the user typed over it is left alone.
    if (_primaryArtistController.text.isEmpty && profile?.name != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _primaryArtistController.text.isEmpty) {
          _primaryArtistController.text = profile!.name;
        }
      });
    }

    // Remix scheme: the profile is doing the remixing, so it pre-fills the
    // first remixer slot instead of the (original) artist field above.
    if (_scheme == _NamingScheme.remix &&
        _remixArtistControllers.isNotEmpty &&
        _remixArtistControllers.first.text.isEmpty &&
        profile?.name != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _remixArtistControllers.first.text.isEmpty) {
          _remixArtistControllers.first.text = profile!.name;
        }
      });
    }

    if (_folderCreated) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
          child: _buildSuccessView(l10n),
        ),
      );
    }

    final steps = [
      if (_hasMultipleRoots) _buildLocationStep(roots, l10n),
      _buildNamingStep(l10n),
      _buildStartStep(l10n),
      if (_startMode == _StartMode.emptyFolder) _buildDawStep(l10n),
    ];
    final totalSteps = steps.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  const Icon(Icons.create_new_folder_outlined),
                  const SizedBox(width: 12),
                  Text(
                    l10n.createProject,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Step indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _StepIndicator(
                currentStep: _currentStep,
                totalSteps: totalSteps,
              ),
            ),
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: steps,
              ),
            ),
            // Footer buttons
            _buildFooter(l10n, totalSteps),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep(List<ScanRoot> roots, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createProjectSelectFolder,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createProjectSelectFolderHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: roots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final root = roots[i];
                final isSelected = _selectedRoot?.id == root.id;
                final dirName = p.basename(root.path);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() {
                    _selectedRoot = root;
                    _validateFolderName();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.08)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dirName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : null,
                                    ),
                              ),
                              Tooltip(
                                message: root.path,
                                child: Text(
                                  root.path,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNamingStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createProjectNameTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createProjectNameHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          // Scheme selector
          Wrap(
            spacing: 8,
            runSpacing: 8, // vertical gap when a chip wraps to a new line
            children: [
              _SchemeChip(
                label: l10n.createProjectSchemeArtistTrack,
                selected: _scheme == _NamingScheme.artistTrack,
                onTap: () => setState(() {
                  _scheme = _NamingScheme.artistTrack;
                  _validateFolderName();
                }),
              ),
              _SchemeChip(
                label: l10n.createProjectSchemeCollab,
                selected: _scheme == _NamingScheme.collab,
                onTap: () => setState(() {
                  _scheme = _NamingScheme.collab;
                  _validateFolderName();
                }),
              ),
              _SchemeChip(
                label: l10n.createProjectSchemeDate,
                selected: _scheme == _NamingScheme.dateTrack,
                onTap: () => setState(() {
                  _scheme = _NamingScheme.dateTrack;
                  _validateFolderName();
                }),
              ),
              _SchemeChip(
                label: l10n.createProjectSchemeCustom,
                selected: _scheme == _NamingScheme.custom,
                onTap: () => setState(() {
                  _scheme = _NamingScheme.custom;
                  _validateFolderName();
                }),
              ),
              _SchemeChip(
                label: l10n.createProjectSchemeRemix,
                selected: _scheme == _NamingScheme.remix,
                onTap: () => setState(() {
                  _scheme = _NamingScheme.remix;
                  _validateFolderName();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date prefix toggle (hidden for dateTrack since it always includes the date)
          if (_scheme != _NamingScheme.dateTrack)
            CheckboxListTile.adaptive(
              title: Text(l10n.createProjectIncludeDate),
              value: _includeTimestamp,
              onChanged: (v) => _toggleIncludeTimestamp(v ?? false),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 12),
          // Fields based on scheme
          if (_scheme == _NamingScheme.artistTrack) ...[
            TextField(
              controller: _primaryArtistController,
              decoration: InputDecoration(
                labelText: l10n.createProjectArtistName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trackNameController,
              decoration: InputDecoration(
                labelText: l10n.createProjectTrackName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
            ),
          ] else if (_scheme == _NamingScheme.collab) ...[
            TextField(
              controller: _primaryArtistController,
              decoration: InputDecoration(
                labelText: '${l10n.createProjectArtistName} 1',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < _collabControllers.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _collabControllers[i],
                      decoration: InputDecoration(
                        labelText: '${l10n.createProjectArtistName} ${i + 2}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() => _validateFolderName()),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  if (_collabControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => setState(() {
                        _collabControllers[i].dispose();
                        _collabControllers.removeAt(i);
                        _validateFolderName();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.createProjectAddArtist),
              onPressed: _collabControllers.length < 5
                  ? () => setState(() {
                      _collabControllers.add(
                        TextEditingController()..addListener(
                          () => setState(() => _validateFolderName()),
                        ),
                      );
                    })
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trackNameController,
              decoration: InputDecoration(
                labelText: l10n.createProjectTrackName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.done,
            ),
          ] else if (_scheme == _NamingScheme.dateTrack) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trackNameController,
              decoration: InputDecoration(
                labelText: l10n.createProjectTrackName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
            ),
          ] else if (_scheme == _NamingScheme.custom) ...[
            TextField(
              controller: _customNameController,
              decoration: InputDecoration(
                labelText: l10n.createProjectCustomName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
            ),
          ] else if (_scheme == _NamingScheme.remix) ...[
            TextField(
              controller: _originalArtistController,
              decoration: InputDecoration(
                labelText: l10n.createProjectOriginalArtist,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trackNameController,
              decoration: InputDecoration(
                labelText: l10n.createProjectTrackName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < _remixArtistControllers.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _remixArtistControllers[i],
                      decoration: InputDecoration(
                        labelText: '${l10n.createProjectRemixerName} ${i + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() => _validateFolderName()),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  if (_remixArtistControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => setState(() {
                        _remixArtistControllers[i].dispose();
                        _remixArtistControllers.removeAt(i);
                        _validateFolderName();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.createProjectAddRemixer),
              onPressed: _remixArtistControllers.length < 5
                  ? () => setState(() {
                      _remixArtistControllers.add(
                        TextEditingController()..addListener(
                          () => setState(() => _validateFolderName()),
                        ),
                      );
                    })
                  : null,
            ),
          ],
          const SizedBox(height: 20),
          // Preview
          _FolderPreview(
            folderName: _folderName,
            rootPath: _selectedRoot?.path,
            error: _folderError,
            isValid: _isFolderValid,
          ),
        ],
      ),
    );
  }

  Widget _buildStartStep(AppLocalizations l10n) {
    final templatesAsync = ref.watch(projectTemplatesProvider);
    // Hidden templates are put away, not deleted — they stay registered so a
    // template-folder refresh won't re-import them, but they are not offered
    // here any more.
    final visibleTemplates = ref.watch(visibleProjectTemplatesProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createProjectStartFrom,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createProjectStartFromHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SchemeChip(
                  label: l10n.createProjectEmptyFolder,
                  selected: _startMode == _StartMode.emptyFolder,
                  onTap: () =>
                      setState(() => _startMode = _StartMode.emptyFolder),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SchemeChip(
                  label: l10n.createProjectFromTemplate,
                  selected: _startMode == _StartMode.template,
                  onTap: () => setState(() => _startMode = _StartMode.template),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_startMode == _StartMode.template)
            Expanded(
              child: templatesAsync.when(
                data: (_) {
                  final templates = visibleTemplates;
                  if (templates.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.noTemplatesYet,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProjectTemplatesPage(),
                              ),
                            ),
                            child: Text(l10n.manageTemplates),
                          ),
                        ],
                      ),
                    );
                  }
                  final filteredTemplates = _templateQuery.isEmpty
                      ? templates
                      : templates
                            .where(
                              (t) =>
                                  t.name.toLowerCase().contains(_templateQuery),
                            )
                            .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _templateSearchController,
                        decoration: InputDecoration(
                          hintText: l10n.searchTemplates,
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredTemplates.isEmpty
                            ? Center(child: Text(l10n.noMatchingTemplates))
                            : ListView.separated(
                                itemCount: filteredTemplates.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (ctx, i) {
                                  final template = filteredTemplates[i];
                                  final isSelected =
                                      _selectedTemplate?.id == template.id;
                                  final ext = p.extension(
                                    template.mainFileRelativePath,
                                  );
                                  final dawType =
                                      MetadataExtractor.getDawTypeFromExtension(
                                        ext,
                                      );
                                  final logoPath = getDawLogoPath(dawType);
                                  final details = [
                                    if (template.bpm != null)
                                      '${template.bpm!.toStringAsFixed(template.bpm! % 1 == 0 ? 0 : 2)} BPM',
                                    if (template.musicalKey != null)
                                      template.musicalKey!,
                                    if (template.dawVersion != null)
                                      '${dawType ?? ''} ${template.dawVersion}'
                                          .trim(),
                                  ].join(' • ');
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => setState(
                                      () => _selectedTemplate = template,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(context).dividerColor,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        color: isSelected
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.08)
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          logoPath != null
                                              ? Image.asset(
                                                  logoPath,
                                                  width: 24,
                                                  height: 24,
                                                )
                                              : const Icon(
                                                  Icons.piano_outlined,
                                                ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  template.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : null,
                                                      ),
                                                ),
                                                if (details.isNotEmpty)
                                                  Text(
                                                    details,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProjectTemplatesPage(),
                          ),
                        ),
                        child: Text(l10n.manageTemplates),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text(l10n.errorLoadingTemplates)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDawStep(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createProjectSelectDaw,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createProjectSelectDawHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (_detectingDaws)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_detectedDaws == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search, size: 48),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(l10n.createProjectDetectDaws),
                      onPressed: _startDawDetection,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _finish(openInDaw: false),
                      child: Text(l10n.createProjectSkipDaw),
                    ),
                  ],
                ),
              ),
            )
          else if (_detectedDaws!.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.music_off, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      l10n.createProjectNoDawsFound,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _finish(openInDaw: false),
                      child: Text(l10n.createProjectSkipDaw),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _detectedDaws!.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final daw = _detectedDaws![i];
                  final isSelected = _selectedDaw?.name == daw.name;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedDaw = daw),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.08)
                            : null,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.piano_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  daw.name,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                ),
                                Tooltip(
                                  message: daw.executablePath,
                                  child: Text(
                                    daw.executablePath,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n, int totalSteps) {
    final namingStepIndex = _hasMultipleRoots ? 1 : 0;
    final startStepIndex = namingStepIndex + 1;
    final dawStepIndex = startStepIndex + 1;

    final isNamingStep = _currentStep == namingStepIndex;
    final isStartStep = _currentStep == startStepIndex;
    final isDawStep =
        _startMode == _StartMode.emptyFolder && _currentStep == dawStepIndex;
    final isLocationStep = _hasMultipleRoots && _currentStep == 0;

    final canAdvanceFromLocation = _selectedRoot != null;
    final canAdvanceFromNaming = _isFolderValid && _folderName.isNotEmpty;
    final canFinishFromTemplate =
        _startMode == _StartMode.template && _selectedTemplate != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => _goToStep(_currentStep - 1),
              child: Text(l10n.back),
            ),
          const Spacer(),
          if (isLocationStep)
            FilledButton(
              onPressed: canAdvanceFromLocation ? () => _goToStep(1) : null,
              child: Text(l10n.next),
            )
          else if (isNamingStep)
            FilledButton(
              onPressed: canAdvanceFromNaming
                  ? () => _goToStep(startStepIndex)
                  : null,
              child: Text(l10n.next),
            )
          else if (isStartStep) ...[
            if (_startMode == _StartMode.template)
              FilledButton(
                onPressed: canFinishFromTemplate ? _finishFromTemplate : null,
                child: Text(l10n.createProjectCreateOnly),
              )
            else
              FilledButton(
                onPressed: () {
                  _goToStep(dawStepIndex);
                  if (_detectedDaws == null) _startDawDetection();
                },
                child: Text(l10n.next),
              ),
          ] else if (isDawStep) ...[
            if (_detectedDaws != null && _detectedDaws!.isNotEmpty) ...[
              OutlinedButton(
                onPressed: () => _finish(openInDaw: false),
                child: Text(l10n.createProjectCreateOnly),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.createProjectCreateAndOpen),
                onPressed: _selectedDaw != null
                    ? () => _finish(openInDaw: true)
                    : null,
              ),
            ] else ...[
              FilledButton(
                onPressed: _detectedDaws != null
                    ? () => _finish(openInDaw: false)
                    : null,
                child: Text(l10n.createProjectCreateOnly),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isDone || isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
              ),
              if (i < totalSteps - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}

class _SchemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SchemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.2),
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).dividerColor,
      ),
    );
  }
}

class _FolderPreview extends StatelessWidget {
  final String folderName;
  final String? rootPath;
  final String? error;
  final bool isValid;

  const _FolderPreview({
    required this.folderName,
    required this.rootPath,
    required this.error,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final displayPath = rootPath != null && folderName.isNotEmpty
        ? p.join(rootPath!, folderName)
        : folderName.isEmpty
        ? '…'
        : folderName;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: error != null
            ? Border.all(color: Theme.of(context).colorScheme.error)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid && folderName.isNotEmpty
                    ? Icons.create_new_folder_outlined
                    : Icons.folder_outlined,
                size: 16,
                color: error != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: displayPath,
                  child: Text(
                    displayPath,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: error != null
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
