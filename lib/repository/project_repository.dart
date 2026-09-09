import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'dart:convert';

import '../models/music_project.dart';
import '../models/pending_folder.dart';
import '../models/scan_mode.dart';
import '../models/scan_root.dart';
import '../models/ignored_path.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../models/part_template.dart';
import '../models/project_part.dart';
import '../models/todo_item.dart';
import '../models/todo_template.dart';
import '../models/project_template.dart';
import '../models/template_root.dart';
import '../models/playlist.dart';
import '../models/project_event.dart';
import '../services/metadata_extractor.dart';
import '../services/notification_background_service.dart';
import '../utils/app_paths.dart';
import 'profile_repository.dart';
import '../models/profile.dart';

class ProjectRepository {
  final String profileId;
  final Box<MusicProject> projectsBox;
  final Box<ScanRoot> rootsBox;
  final Box<IgnoredPath> ignoredPathsBox;
  final Box<Release> releasesBox;
  final Box<Playlist> playlistsBox;
  final Box<ProjectEvent> eventsBox;
  // Global (profile-agnostic) key-value settings box
  final Box<String> appSettingsBox;
  final _uuid = const Uuid();

  static const _keyCustomMixdownFolder = 'customMixdownFolder';
  static const _keyCustomMixdownFolders = 'customMixdownFolders';
  static const _keyCustomMixdownFoldersByDaw = 'customMixdownFoldersByDaw';
  static const _keyDawLaunchCommandsByDaw = 'dawLaunchCommandsByDaw';

  ProjectRepository({
    required this.profileId,
    required this.projectsBox,
    required this.rootsBox,
    required this.ignoredPathsBox,
    required this.releasesBox,
    required this.playlistsBox,
    required this.eventsBox,
    required this.appSettingsBox,
  });

  // Closes every per-profile box this repository opened, so switching to a
  // different profile doesn't leave the outgoing profile's projects (and
  // everything else) resident in memory for the rest of the app session.
  // appSettingsBox is intentionally NOT closed — it's global, shared across
  // profiles, and other repositories/providers may still be reading it.
  Future<void> closeBoxes() async {
    await projectsBox.close();
    await rootsBox.close();
    await ignoredPathsBox.close();
    await releasesBox.close();
    await playlistsBox.close();
    await eventsBox.close();
  }

  // Subfolder names (relative to each project's own folder) checked, in
  // order, before falling back to DAW-specific and generic defaults.
  List<String> getCustomMixdownFolders() {
    final raw = appSettingsBox.get(_keyCustomMixdownFolders);
    if (raw != null) {
      try {
        return List.unmodifiable((jsonDecode(raw) as List).cast<String>());
      } catch (_) {}
    }
    // Migrate the legacy single-folder key.
    final legacy = appSettingsBox.get(_keyCustomMixdownFolder);
    if (legacy != null && legacy.isNotEmpty) return [legacy];
    return const [];
  }

  Future<void> setCustomMixdownFolders(List<String> folders) async {
    final cleaned = folders
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      await appSettingsBox.delete(_keyCustomMixdownFolders);
    } else {
      await appSettingsBox.put(_keyCustomMixdownFolders, jsonEncode(cleaned));
    }
  }

  // Subfolder names checked per-DAW (keyed by the same strings as
  // MixdownDetectorService.dawFolders, or MixdownDetectorService.otherDawKey
  // for unrecognized DAWs) — additive to, and checked after, the fully-global
  // list above, but before that DAW's hardcoded defaults.
  Map<String, List<String>> getCustomMixdownFoldersByDaw() {
    final raw = appSettingsBox.get(_keyCustomMixdownFoldersByDaw);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw) as Map;
      return Map.unmodifiable(
        decoded.map(
          (key, value) => MapEntry(
            key as String,
            List<String>.unmodifiable((value as List).cast<String>()),
          ),
        ),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> setCustomMixdownFoldersByDaw(
    Map<String, List<String>> foldersByDaw,
  ) async {
    final cleaned = <String, List<String>>{};
    for (final entry in foldersByDaw.entries) {
      final names = entry.value
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();
      if (names.isNotEmpty) cleaned[entry.key] = names;
    }
    if (cleaned.isEmpty) {
      await appSettingsBox.delete(_keyCustomMixdownFoldersByDaw);
    } else {
      await appSettingsBox.put(
        _keyCustomMixdownFoldersByDaw,
        jsonEncode(cleaned),
      );
    }
  }

  // "Launch in DAW" executable overrides, keyed by the same DAW display-name
  // strings MetadataExtractor produces (project.dawType) — global
  // (device-local), not per-profile: they describe what's physically
  // installed on this machine, not anything about a music profile's
  // identity. Used on every desktop platform: always on Linux (no
  // dependable OS file association for most DAWs), and on Windows/macOS as a
  // fallback the user can configure when the standard launch fails.
  //
  // A DAW maps to a *list* of paths (e.g. two Ableton versions): one → use
  // it directly, several → the launcher asks which to run. The persisted
  // JSON is `{"<daw>": ["<path>", ...]}`; the reader also accepts the legacy
  // `{"<daw>": "<path>"}` single-string shape written before this.

  /// Configured override paths for [dawType], in the order they were added.
  /// Empty when none are configured.
  List<String> getDawLaunchCommandPaths(String dawType) =>
      getDawLaunchCommands()[dawType] ?? const [];

  /// Every configured DAW mapped to its ordered list of override paths.
  Map<String, List<String>> getDawLaunchCommands() {
    final raw = appSettingsBox.get(_keyDawLaunchCommandsByDaw);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw) as Map;
      final out = <String, List<String>>{};
      decoded.forEach((key, value) {
        final paths = <String>[
          if (value is String)
            value
          else if (value is List)
            for (final v in value) v.toString(),
        ].map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        if (paths.isNotEmpty) out[key as String] = paths;
      });
      return Map.unmodifiable(out);
    } catch (_) {
      return const {};
    }
  }

  /// Appends [binaryPath] to [dawType]'s override list. No-op if blank or
  /// already present.
  Future<void> addDawLaunchCommand(String dawType, String binaryPath) async {
    final cleaned = binaryPath.trim();
    if (cleaned.isEmpty) return;
    final current = _mutableDawLaunchCommands();
    final list = current.putIfAbsent(dawType, () => <String>[]);
    if (list.contains(cleaned)) return;
    list.add(cleaned);
    await _persistDawLaunchCommands(current);
  }

  /// Removes [binaryPath] from [dawType]'s override list, dropping the DAW
  /// key entirely once its list is empty.
  Future<void> removeDawLaunchCommand(String dawType, String binaryPath) async {
    final current = _mutableDawLaunchCommands();
    final list = current[dawType];
    if (list == null || !list.remove(binaryPath.trim())) return;
    if (list.isEmpty) current.remove(dawType);
    await _persistDawLaunchCommands(current);
  }

  /// Removes every override configured for [dawType].
  Future<void> clearDawLaunchCommands(String dawType) async {
    final current = _mutableDawLaunchCommands();
    if (current.remove(dawType) == null) return;
    await _persistDawLaunchCommands(current);
  }

  Map<String, List<String>> _mutableDawLaunchCommands() => {
        for (final entry in getDawLaunchCommands().entries)
          entry.key: List<String>.from(entry.value),
      };

  Future<void> _persistDawLaunchCommands(
    Map<String, List<String>> commands,
  ) async {
    commands.removeWhere((_, paths) => paths.isEmpty);
    if (commands.isEmpty) {
      await appSettingsBox.delete(_keyDawLaunchCommandsByDaw);
    } else {
      await appSettingsBox.put(
        _keyDawLaunchCommandsByDaw,
        jsonEncode(commands),
      );
    }
  }

  // Custom Phases — ordered list of phase names, per-profile
  static const _defaultPhases = [
    'Idea',
    'Arranging',
    'Mixing',
    'Mastering',
    'Finished',
  ];
  String get _customPhasesKey => '${profileId}_phases';

  List<String> getCustomPhases() {
    final raw = appSettingsBox.get(_customPhasesKey);
    if (raw == null) return List.unmodifiable(_defaultPhases);
    try {
      return List.unmodifiable((jsonDecode(raw) as List).cast<String>());
    } catch (_) {
      return List.unmodifiable(_defaultPhases);
    }
  }

  Future<void> setCustomPhases(List<String> phases) async =>
      appSettingsBox.put(_customPhasesKey, jsonEncode(phases));

  // Phase Colors — per-profile map of phase name → '#RRGGBB' hex string
  String get _phaseColorsKey => '${profileId}_phase_colors';

  Map<String, String> getPhaseColors() {
    final raw = appSettingsBox.get(_phaseColorsKey);
    if (raw == null) return const {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  Future<void> setPhaseColors(Map<String, String> colors) async =>
      appSettingsBox.put(_phaseColorsKey, jsonEncode(colors));

  // Finished Phases — which phase names are treated as "done" for filters/stats
  String get _finishedPhasesKey => '${profileId}_finished_phases';

  Set<String> getFinishedPhases() {
    final raw = appSettingsBox.get(_finishedPhasesKey);
    if (raw != null) {
      try {
        return (jsonDecode(raw) as List).cast<String>().toSet();
      } catch (_) {}
    }
    // Migrate legacy single-phase key
    final legacy = appSettingsBox.get('${profileId}_finished_phase');
    if (legacy != null) return {legacy};
    return {'Finished'};
  }

  Future<void> setFinishedPhases(Set<String> phases) async =>
      appSettingsBox.put(_finishedPhasesKey, jsonEncode(phases.toList()));

  Future<void> setFinishedPhase(String phase) async =>
      setFinishedPhases({phase});

  // Pending Folders — stored as JSON list in the per-profile app_settings slot
  String get _pendingFoldersKey => '${profileId}_pending_folders';

  List<PendingFolder> getPendingFolders() {
    final raw = appSettingsBox.get(_pendingFoldersKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PendingFolder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addPendingFolder(PendingFolder folder) async {
    final current = getPendingFolders()
      ..removeWhere((f) => f.path == folder.path);
    current.add(folder);
    await appSettingsBox.put(
      _pendingFoldersKey,
      jsonEncode(current.map((f) => f.toJson()).toList()),
    );
  }

  Future<void> removePendingFolder(String id) async {
    final current = getPendingFolders()..removeWhere((f) => f.id == id);
    await appSettingsBox.put(
      _pendingFoldersKey,
      jsonEncode(current.map((f) => f.toJson()).toList()),
    );
  }

  Future<void> updatePendingFolder(PendingFolder folder) async {
    final current = getPendingFolders()..removeWhere((f) => f.id == folder.id);
    current.add(folder);
    await appSettingsBox.put(
      _pendingFoldersKey,
      jsonEncode(current.map((f) => f.toJson()).toList()),
    );
  }

  /// Removes pending folders that now contain a real DAW project file, or whose
  /// folder no longer exists on disk. Returns the removed IDs.
  Future<List<String>> resolveCompletedPendingFolders() async {
    final current = getPendingFolders();
    final toRemove = current
        .where((pf) => !pf.folderExists || pf.hasProjectFile())
        .map((pf) => pf.id)
        .toList();
    if (toRemove.isNotEmpty) {
      final remaining = current.where((f) => !toRemove.contains(f.id)).toList();
      await appSettingsBox.put(
        _pendingFoldersKey,
        jsonEncode(remaining.map((f) => f.toJson()).toList()),
      );
    }
    return toRemove;
  }

  static Future<ProjectRepository> init(ProfileRepository profileRepo) async {
    // Initialize Hive with LocalAppData directory (only once)
    await ensureHiveInitialized();

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MusicProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScanRootAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(IgnoredPathAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ReleaseAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ReleaseFileAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TodoItemAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(PlaylistAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(TodoTemplateAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ProjectEventAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(ProjectTemplateAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(TemplateRootAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(ProjectPartAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(PartTemplateAdapter());
    }

    // Get current profile
    final currentProfile = profileRepo.getCurrentProfile();
    if (currentProfile == null) {
      throw Exception('No active profile found');
    }

    final profileId = currentProfile.id;

    // Use profile-specific box names
    final projects = await Hive.openBox<MusicProject>('${profileId}_projects');
    final roots = await Hive.openBox<ScanRoot>('${profileId}_roots');
    final ignoredPaths = await Hive.openBox<IgnoredPath>(
      '${profileId}_ignored_paths',
    );
    final releases = await Hive.openBox<Release>('${profileId}_releases');
    final playlists = await Hive.openBox<Playlist>('${profileId}_playlists');
    final events = await Hive.openBox<ProjectEvent>('${profileId}_events');
    final appSettings = await Hive.openBox<String>('app_settings');

    if (kDebugMode) {
      print('ProjectRepository.init: Opened boxes for profile $profileId');
      print('  Projects box: ${projects.length} projects');
    }

    return ProjectRepository(
      profileId: profileId,
      projectsBox: projects,
      rootsBox: roots,
      ignoredPathsBox: ignoredPaths,
      releasesBox: releases,
      playlistsBox: playlists,
      eventsBox: events,
      appSettingsBox: appSettings,
    );
  }

  /// Reinitialize with a different profile
  static Future<ProjectRepository> initWithProfile(
    ProfileRepository profileRepo,
    String profileId,
  ) async {
    // Ensure Hive is initialized (only once)
    await ensureHiveInitialized();

    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ProjectEventAdapter());
    }

    // Use profile-specific box names
    final projects = await Hive.openBox<MusicProject>('${profileId}_projects');
    final roots = await Hive.openBox<ScanRoot>('${profileId}_roots');
    final ignoredPaths = await Hive.openBox<IgnoredPath>(
      '${profileId}_ignored_paths',
    );
    final releases = await Hive.openBox<Release>('${profileId}_releases');
    final playlists = await Hive.openBox<Playlist>('${profileId}_playlists');
    final events = await Hive.openBox<ProjectEvent>('${profileId}_events');
    final appSettings = await Hive.openBox<String>('app_settings');

    return ProjectRepository(
      profileId: profileId,
      projectsBox: projects,
      rootsBox: roots,
      ignoredPathsBox: ignoredPaths,
      releasesBox: releases,
      playlistsBox: playlists,
      eventsBox: events,
      appSettingsBox: appSettings,
    );
  }

  // Roots
  /// Registers [path] as a scan root and returns the created [ScanRoot] so
  /// callers can immediately scan just that folder (see
  /// [importProjectsFromRoot]) without re-looking it up by path.
  Future<ScanRoot> addRoot(String path) async {
    final id = _uuid.v4();
    final root = ScanRoot(
      id: id,
      path: path,
      addedAt: DateTime.now(),
      // Auto-derived friendly label — see ScanRoot.displayName's doc for
      // why this is needed on Linux/Flatpak (the stored path itself may
      // be a sandboxed document-portal path, not the real location).
      // User-editable afterward via setRootDisplayName.
      displayName: p.basename(path),
    );
    await rootsBox.put(id, root);
    return root;
  }

  /// Sets (or, if [displayName] is null/blank, clears back to the
  /// auto-derived folder-name default) the user-facing label for root
  /// [id]. No-op if the root doesn't exist.
  Future<void> setRootDisplayName(String id, String? displayName) async {
    final root = rootsBox.get(id);
    if (root == null) return;
    final trimmed = displayName?.trim();
    await rootsBox.put(
      id,
      root.copyWith(
        displayName: (trimmed == null || trimmed.isEmpty)
            ? p.basename(root.path)
            : trimmed,
      ),
    );
  }

  Future<void> removeRoot(String id) async {
    final root = rootsBox.get(id);
    if (root == null) return;

    // Get the root path and normalize it for comparison
    final rootPath = p.normalize(root.path);
    // Ensure root path ends with separator for proper matching
    final rootPathNormalized = rootPath.endsWith(p.separator)
        ? rootPath
        : rootPath + p.separator;

    // Get all project IDs that are referenced in releases (to preserve them)
    final releases = getAllReleases();
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }

    // Remove all projects that belong to this root folder
    // Note: projectsBox is already profile-specific, so we only operate on current profile's projects
    final projectsToDelete = <String>[];

    for (final project in projectsBox.values) {
      try {
        // Normalize project file path for comparison
        final projectPath = p.normalize(project.filePath);

        // Check if project's file path is within the root folder
        // This is safe because projectsBox is profile-specific (${profileId}_projects)
        if (projectPath.startsWith(rootPathNormalized) ||
            projectPath.startsWith(rootPath + p.separator)) {
          // Preserve projects that are referenced in releases
          if (!protectedProjectIds.contains(project.id)) {
            projectsToDelete.add(project.id);
          }
        }
      } catch (_) {
        // If path normalization fails, skip this project
        // Better to be safe and not delete than to delete incorrectly
      }
    }

    // Delete all projects from this root (except those in releases)
    if (projectsToDelete.isNotEmpty) {
      await projectsBox.deleteAll(projectsToDelete);
    }

    // Remove the root after deleting projects
    await rootsBox.delete(id);
  }

  Future<void> updateRootLastScanAt(String rootId, DateTime scanTime) async {
    final root = rootsBox.get(rootId);
    if (root != null) {
      await rootsBox.put(rootId, root.copyWith(lastScanAt: scanTime));
    }
  }

  Future<void> updateRootScanDepth(String rootId, int depth) async {
    final root = rootsBox.get(rootId);
    if (root != null) {
      await rootsBox.put(rootId, root.copyWith(scanDepth: depth));
    }
  }

  /// Sets a root's [ScanMode], writing both fields [ScanRoot.scanMode] is
  /// derived from so the two can never disagree.
  ///
  /// Turning [ScanMode.versionStack] *off* deliberately leaves existing stacks
  /// alone: they hold metadata and work time the user has accumulated, and
  /// dissolving them because a display setting flipped would throw that away.
  /// Unstacking stays an explicit, per-stack action.
  Future<void> updateRootScanMode(String rootId, ScanMode mode) async {
    final root = rootsBox.get(rootId);
    if (root == null) return;
    await rootsBox.put(
      rootId,
      root.copyWith(
        autoStackVersions: mode == ScanMode.versionStack,
        // Version stacking groups by immediate parent folder, so it wants the
        // recursive walk that depth 0 gives, same as flat.
        scanDepth: mode == ScanMode.smartFolder ? 1 : 0,
      ),
    );
  }

  /// Permanently deletes [projectIds] and all their data (notes, deadlines,
  /// session/timer history, etc.) — irreversible. Scans never call this on
  /// their own (see `upsertFromFileSystemEntity`): a project whose file goes
  /// missing just stays in the list flagged missing (a live filesystem
  /// check, done in the UI) until the user explicitly deletes it, e.g. via
  /// the "Delete Missing" bulk action.
  Future<void> deleteProjectsPermanently(Iterable<String> projectIds) async {
    await projectsBox.deleteAll(projectIds);
    await cleanUpDanglingStackLinks();
  }

  List<ScanRoot> getRoots() => rootsBox.values.toList(growable: false);

  /// Updates the stored path for a scan root and rewrites the `filePath`,
  /// `previewSongPath`, and `previewSongAutoPath` of every project whose path
  /// starts with the old root path. No files are moved on disk.
  /// Returns the number of projects whose paths were updated.
  Future<int> relocateRoot(String rootId, String newPath) async {
    final root = rootsBox.get(rootId);
    if (root == null) return 0;

    final oldPath = p.normalize(root.path);
    final newNorm = p.normalize(newPath);
    final oldPrefix = oldPath.endsWith(p.separator)
        ? oldPath
        : oldPath + p.separator;
    final newPrefix = newNorm.endsWith(p.separator)
        ? newNorm
        : newNorm + p.separator;

    String repath(String src) {
      final norm = p.normalize(src);
      if (norm.startsWith(oldPrefix)) {
        return newPrefix + norm.substring(oldPrefix.length);
      }
      if (norm == oldPath) {
        return newNorm;
      }
      return src;
    }

    // Update the root itself
    await rootsBox.put(rootId, root.copyWith(path: newNorm));

    int count = 0;
    for (final project in projectsBox.values.toList()) {
      if (!p.normalize(project.filePath).startsWith(oldPrefix) &&
          p.normalize(project.filePath) != oldPath) {
        continue;
      }

      final updated = project.copyWith(
        filePath: repath(project.filePath),
        fileName: p.basename(repath(project.filePath)),
        previewSongPath: project.previewSongPath != null
            ? repath(project.previewSongPath!)
            : null,
        previewSongAutoPath: project.previewSongAutoPath != null
            ? repath(project.previewSongAutoPath!)
            : null,
      );
      await projectsBox.put(updated.id, updated);
      count++;
    }
    return count;
  }

  // Ignored paths (directories under roots that should not be scanned)
  Future<void> addIgnoredPath(String path) async {
    final id = _uuid.v4();
    final ignored = IgnoredPath(id: id, path: path, addedAt: DateTime.now());
    await ignoredPathsBox.put(id, ignored);

    // Also delete any already-indexed projects within this path (unless in releases).
    await _deleteProjectsUnderPathPrefix(path);
  }

  Future<void> removeIgnoredPath(String id) async {
    await ignoredPathsBox.delete(id);
  }

  List<IgnoredPath> getIgnoredPaths() =>
      ignoredPathsBox.values.toList(growable: false);

  Stream<BoxEvent> watchIgnoredPaths() => ignoredPathsBox.watch();

  Future<void> _deleteProjectsUnderPathPrefix(String basePath) async {
    // Get all project IDs that are referenced in releases (to preserve them)
    final releases = getAllReleases();
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }

    final rootPath = p.normalize(basePath);
    final rootPathNormalized = rootPath.endsWith(p.separator)
        ? rootPath
        : rootPath + p.separator;

    final projectsToDelete = <String>[];
    for (final project in projectsBox.values) {
      try {
        final projectPath = p.normalize(project.filePath);
        if (projectPath.startsWith(rootPathNormalized) ||
            projectPath.startsWith(rootPath + p.separator)) {
          if (!protectedProjectIds.contains(project.id)) {
            projectsToDelete.add(project.id);
          }
        }
      } catch (_) {
        // Skip on path errors (safer to not delete).
      }
    }

    if (projectsToDelete.isNotEmpty) {
      await projectsBox.deleteAll(projectsToDelete);
      await cleanUpDanglingStackLinks();
    }
  }

  /// Repairs stack links after projects have been deleted out from under them.
  ///
  /// Deletion here happens by id or by path prefix, neither of which knows
  /// about stacks, so either side of the link can be left pointing at nothing:
  /// a member whose stack is gone would keep deferring its metadata to a row
  /// that no longer exists, and a stack listing deleted members would report
  /// the wrong version count and work total. A stack left with fewer than two
  /// versions is dissolved, for the same reason [removeFromStack] does it.
  Future<void> cleanUpDanglingStackLinks() async {
    for (final project in projectsBox.values.toList(growable: false)) {
      if (project.isVirtual) {
        // A member counts as live only if it still exists *and* is not
        // claimed by some other stack. Anything else is dropped from the
        // list; a member that simply lost its backlink is re-linked below.
        final live = <String>[];
        final relink = <MusicProject>[];
        for (final id in project.memberProjectIds) {
          final member = projectsBox.get(id);
          if (member == null) continue;
          if (member.stackId != null && member.stackId != project.id) continue;
          live.add(id);
          if (member.stackId == null) relink.add(member);
        }

        if (live.length < 2) {
          await unstack(project.id);
          continue;
        }

        // Repairs stacks broken by scans that used to rebuild each project
        // from scratch and drop its stackId (see _buildProjectAndEvent).
        // That left the stack row listing members which no longer pointed
        // back, so nothing collapsed: the versions showed as loose projects
        // beside a stack row claiming to hold them.
        for (final member in relink) {
          await projectsBox.put(
            member.id,
            member.copyWith(stackId: project.id),
          );
        }

        if (live.length == project.memberProjectIds.length &&
            live.contains(project.defaultLaunchMemberId)) {
          continue;
        }
        await projectsBox.put(
          project.id,
          project.copyWith(
            memberProjectIds: live,
            defaultLaunchMemberId:
                live.contains(project.defaultLaunchMemberId)
                ? project.defaultLaunchMemberId
                : live.first,
          ),
        );
      } else if (project.stackId case final stackId?) {
        final stack = projectsBox.get(stackId);
        if (stack == null || !stack.isVirtual) {
          await projectsBox.put(
            project.id,
            project.copyWith(clearStackId: true),
          );
        }
      }
    }
  }

  // Projects
  MusicProject? getById(String id) => projectsBox.get(id);

  MusicProject? getByPath(String path) {
    try {
      return projectsBox.values.firstWhere((p) => p.filePath == path);
    } catch (_) {
      return null;
    }
  }

  // LÓGICA CORRIGIDA para preservar campos customizados
  /// Upserts a project from a file system entity
  /// [fullMetadata] if true, extracts full metadata (BPM, key, DAW version) - slower
  /// if false, only extracts DAW type from extension - faster
  Future<void> upsertFromFileSystemEntity(
    FileSystemEntity entity, {
    bool fullMetadata = false,
    String? parentProjectId,
  }) async {
    final built = await _buildProjectAndEvent(
      entity,
      fullMetadata: fullMetadata,
      parentProjectId: parentProjectId,
    );
    await projectsBox.put(built.project.id, built.project);
    if (built.event != null) {
      await eventsBox.put(built.event!.id, built.event!);
    }
  }

  /// Batched counterpart of [upsertFromFileSystemEntity] for scan loops,
  /// which otherwise call it once per discovered file — each call does its
  /// own `Box.put()`, and Hive fires a change event per put. On a library
  /// with thousands of projects that turns one rescan into thousands of
  /// events, each of which re-materializes and re-filters the whole project
  /// list downstream (see `watchAllProjects`'s debounce, which only softens
  /// the effect — this removes the write-side cause). Metadata extraction
  /// still happens per file (it's genuinely per-file I/O), but persistence
  /// is batched into `putAll` calls, flushed every [flushEvery] entities so
  /// memory stays bounded on very large scans.
  ///
  /// A single unreadable/vanished file (e.g. deleted or locked mid-scan)
  /// must not abort the whole batch — each entity is processed in its own
  /// try/catch, and failures are collected and returned by path instead of
  /// thrown, so callers can keep going and report them afterward rather
  /// than losing every project after the one that failed.
  ///
  /// [onProgress] is invoked after each entity (whether it succeeded or
  /// failed) with the running count and the batch's total, for callers that
  /// want to show scan progress.
  Future<List<String>> upsertManyFromFileSystemEntities(
    List<FileSystemEntity> entities, {
    bool fullMetadata = false,
    // Overrides [fullMetadata] per entity, for callers like the dashboard's
    // "unscanned only" rescan mode where the decision depends on each
    // project's current metadataScanned state.
    bool Function(FileSystemEntity entity)? fullMetadataFor,
    String? parentProjectId,
    int flushEvery = 200,
    void Function(int processed, int total)? onProgress,
  }) async {
    var pendingProjects = <String, MusicProject>{};
    var pendingEvents = <String, ProjectEvent>{};
    final failedPaths = <String>[];

    Future<void> flush() async {
      if (pendingProjects.isNotEmpty) {
        await projectsBox.putAll(pendingProjects);
        pendingProjects = {};
      }
      if (pendingEvents.isNotEmpty) {
        await eventsBox.putAll(pendingEvents);
        pendingEvents = {};
      }
    }

    final total = entities.length;
    for (var i = 0; i < entities.length; i++) {
      final entity = entities[i];
      try {
        final built = await _buildProjectAndEvent(
          entity,
          fullMetadata: fullMetadataFor?.call(entity) ?? fullMetadata,
          parentProjectId: parentProjectId,
        );
        pendingProjects[built.project.id] = built.project;
        if (built.event != null) {
          pendingEvents[built.event!.id] = built.event!;
        }
      } catch (e) {
        failedPaths.add(entity.path);
        if (kDebugMode) {
          print('[upsertManyFromFileSystemEntities] failed ${entity.path}: $e');
        }
      }
      onProgress?.call(i + 1, total);
      if (pendingProjects.length >= flushEvery) {
        await flush();
      }
    }
    await flush();
    return failedPaths;
  }

  Future<({MusicProject project, ProjectEvent? event})> _buildProjectAndEvent(
    FileSystemEntity entity, {
    bool fullMetadata = false,
    String? parentProjectId,
  }) async {
    final filePath = entity.path;
    final stat = await entity.stat();
    final fileName = p.basename(filePath);
    // Works for directory bundles too (Logic Pro .logicx, LUNA .luna,
    // GarageBand .band) — extension parsing is purely string-based and
    // doesn't care whether the path is a file or a directory.
    final ext = p.extension(filePath).toLowerCase();
    final size = stat.size;
    final lastModified = stat.modified;

    final existing = getByPath(filePath);

    // Extract metadata from project file
    ProjectMetadata? extractedMetadata;
    try {
      if (fullMetadata) {
        extractedMetadata = await MetadataExtractor.extractMetadata(filePath);
      } else {
        extractedMetadata = await MetadataExtractor.extractLightweightMetadata(
          filePath,
        );
      }
    } catch (_) {
      // If extraction fails, continue without metadata
    }

    // Always update BPM and key from file if available (these can change in the project)
    // Fall back to existing values only if extraction didn't find anything
    final bpm = extractedMetadata?.bpm ?? existing?.bpm;
    final key = extractedMetadata?.key ?? existing?.musicalKey;

    // Determine DAW type: always update from file (based on extension)
    final dawType = extractedMetadata?.dawType;
    // Preserve existing DAW version if extraction didn't find anything (e.g., during lightweight scan)
    final dawVersion = extractedMetadata?.dawVersion ?? existing?.dawVersion;
    // Same fallback as dawVersion: only a full-metadata scan of a supported
    // DAW (currently Reaper and Cubase/Nuendo) populates this, so preserve
    // it otherwise.
    final projectNotes =
        extractedMetadata?.projectNotes ?? existing?.projectNotes;
    // Markers use null vs empty to tell "didn't look" from "looked, found
    // none": a lightweight scan leaves them null and must not wipe what a
    // previous deep scan found, while a deep scan of a file whose markers
    // were deleted in the DAW returns an empty list, which must win.
    final markers =
        extractedMetadata?.markers ?? existing?.markers ?? const [];

    // Detect file creation date from filesystem
    // On Windows, stat.changed is the creation time
    // On other platforms, we fall back to lastModified as an approximation
    // IMPORTANT: Once fileCreatedAt is set, it should NEVER be overridden
    DateTime? fileCreatedAt = existing?.fileCreatedAt;
    if (fileCreatedAt == null) {
      // Try to get file creation time
      // On Windows, stat.changed returns file creation time
      // On Unix-like systems, it returns inode change time (not creation)
      // We use stat.changed on Windows, otherwise fall back to lastModified
      if (Platform.isWindows) {
        fileCreatedAt = stat.changed;
      } else {
        // On macOS/Linux, use the earlier of modified and changed times
        // as a best approximation of creation time
        fileCreatedAt = stat.changed.isBefore(stat.modified)
            ? stat.changed
            : stat.modified;
      }
    }

    // Preserve-by-default. An earlier version of this built a fresh
    // MusicProject and re-listed every field worth keeping, which meant any
    // field added to the model later was silently wiped by the next scan
    // unless someone remembered to add it here — and several were: song
    // parts, thumbnails, the source template link, the ignored-newer-song
    // path, and every version-stacking link. Copying the existing row and
    // overwriting only what the filesystem and extraction actually know
    // inverts that: a new field is kept unless it is deliberately updated.
    //
    // Only fields listed below are touched; everything else survives a scan.
    final projectToSave = existing != null
        ? existing.copyWith(
            filePath: filePath,
            fileName: fileName,
            fileSizeBytes: size,
            lastModifiedAt: lastModified,
            fileExtension: ext,
            updatedAt: DateTime.now(),
            // Null from extraction means "didn't find it", so the stored
            // value stands — copyWith already treats null as "leave alone".
            bpm: extractedMetadata?.bpm,
            musicalKey: extractedMetadata?.key,
            dawVersion: extractedMetadata?.dawVersion,
            projectNotes: extractedMetadata?.projectNotes,
            markers: extractedMetadata?.markers,
            // DAW type is derived from the extension, so it always comes from
            // the file; a failed extraction clears it rather than leaving a
            // stale one behind.
            dawType: dawType,
            clearDawType: dawType == null,
            fileCreatedAt: fileCreatedAt,
            parentProjectId: parentProjectId,
            metadataScanned: fullMetadata ? true : existing.metadataScanned,
          )
        : MusicProject(
            id: _uuid.v4(),
            filePath: filePath,
            fileName: fileName,
            fileSizeBytes: size,
            lastModifiedAt: lastModified,
            fileExtension: ext,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            status: 'Idea',
            bpm: bpm,
            musicalKey: key,
            dawType: dawType,
            dawVersion: dawVersion,
            projectNotes: projectNotes,
            markers: markers,
            fileCreatedAt: fileCreatedAt,
            parentProjectId: parentProjectId,
            metadataScanned: fullMetadata,
          );

    // Record a file_changed event if an existing project had its file mutated
    ProjectEvent? event;
    if (existing != null &&
        (existing.fileSizeBytes != size ||
            existing.lastModifiedAt != lastModified)) {
      event = ProjectEvent(
        id: _uuid.v4(),
        projectId: projectToSave.id,
        eventType: ProjectEvent.fileChanged,
        occurredAt: DateTime.now(),
        payload: jsonEncode({
          'sizeChanged': existing.fileSizeBytes != size,
          'lastModifiedChanged': existing.lastModifiedAt != lastModified,
          'newSizeBytes': size,
        }),
      );
    }

    return (project: projectToSave, event: event);
  }

  List<MusicProject> getAllProjects() =>
      projectsBox.values.toList(growable: false);

  // ---------------------------------------------------------------------------
  // Version stacking (#94)
  //
  // A "stack" is a virtual project: a row that owns the shared metadata for
  // several version files of the same song and has no file of its own. Members
  // keep their own metadata untouched but dormant, so unstacking can hand it
  // back rather than losing it.
  // ---------------------------------------------------------------------------

  /// The members of [stack], in the order they are listed on it.
  ///
  /// Ids that no longer resolve are skipped rather than returned as nulls —
  /// a member can be deleted from under a stack, and every caller here wants
  /// "the versions that still exist".
  List<MusicProject> stackMembers(MusicProject stack) => [
    for (final id in stack.memberProjectIds)
      if (projectsBox.get(id) case final m?) m,
  ];

  /// Total seconds worked across every version in [stack].
  ///
  /// Derived on read rather than stored. A rolled-up copy would need
  /// invalidating on every timer tick, stack, unstack, member deletion and
  /// Drive restore, and would drift silently the first time one was missed.
  int stackTotalWorkSeconds(MusicProject stack) => stackMembers(
    stack,
  ).fold(0, (sum, m) => sum + m.totalWorkSeconds);

  /// Every work session across [stack]'s versions, newest last.
  List<SessionRecord> stackSessions(MusicProject stack) =>
      stackMembers(stack).expand((m) => m.sessions).toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  /// Groups [projects] by the directory their file sits in directly.
  ///
  /// Deliberately *not* [smartFolderGroupKey], which buckets by the top-level
  /// folder under a scan root: for `Root/1-Active/SongA/SongA v3.cpr` that key
  /// is `1-Active`, so reusing it would stack every song in `1-Active` into a
  /// single entry. Version stacking wants the immediate parent — `SongA`.
  ///
  /// Virtual projects and projects already in a stack are excluded.
  static Map<String, List<MusicProject>> groupByImmediateFolder(
    Iterable<MusicProject> projects,
  ) {
    final byFolder = <String, List<MusicProject>>{};
    for (final project in projects) {
      if (project.isVirtual || project.isStackMember) continue;
      final folder = p.dirname(p.normalize(project.filePath));
      byFolder.putIfAbsent(folder, () => []).add(project);
    }
    return byFolder;
  }

  /// Makes a stack out of [members], promoting [metadataSourceId]'s metadata
  /// onto it, and returns the new virtual project.
  ///
  /// The members keep every field they had — nothing is cleared — so
  /// [unstack] can restore them exactly. What changes is that they now carry a
  /// [MusicProject.stackId], and the UI reads the stack's metadata instead of
  /// theirs.
  ///
  /// Throws [ArgumentError] for fewer than two members, or when a member is
  /// already stacked: silently re-parenting would strand the previous stack's
  /// metadata.
  Future<MusicProject> stackProjects({
    required List<String> memberIds,
    String? metadataSourceId,
  }) async {
    if (memberIds.length < 2) {
      throw ArgumentError('A stack needs at least two versions');
    }
    final members = [
      for (final id in memberIds)
        if (projectsBox.get(id) case final m?) m,
    ];
    if (members.length != memberIds.length) {
      throw ArgumentError('One or more projects to stack no longer exist');
    }
    if (members.any((m) => m.isVirtual || m.isStackMember)) {
      throw ArgumentError('A project can only belong to one stack');
    }

    // Default to the oldest member: when someone saves v1 → v2 → v3, the
    // metadata they have been maintaining is on the one they started from.
    final source = metadataSourceId != null
        ? members.firstWhere(
            (m) => m.id == metadataSourceId,
            orElse: () => members.first,
          )
        : (members.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
              .first;

    final now = DateTime.now();
    final folder = p.dirname(p.normalize(source.filePath));
    final stack = source.copyWith(
      id: _uuid.v4(),
      isVirtual: true,
      memberProjectIds: members.map((m) => m.id).toList(),
      defaultLaunchMemberId: source.id,
      clearStackId: true,
      // Synthesized: a stack has no file. The folder keeps the path
      // meaningful for display and for anything that groups by directory.
      filePath: folder,
      // The stack is named after the project promoted onto it, not after the
      // folder. Naming it for the folder meant the main project appeared
      // under a name the user never chose — and often one shared with a
      // sibling stack, since "Bounces" or "Project" are common folder names.
      //
      // Carried as fileName rather than baked into customDisplayName so that
      // displayName derives exactly the way the source's does, honouring the
      // live date-stripping preference instead of freezing today's setting
      // into stored text. (copyWith already carries any customDisplayName the
      // source had, which still wins over this.)
      fileName: source.fileName,
      fileSizeBytes: 0,
      createdAt: now,
      updatedAt: now,
      // Work time is summed from members on read, never stored here.
      totalWorkSeconds: 0,
      sessions: const [],
    );

    await projectsBox.put(stack.id, stack);
    for (final member in members) {
      await projectsBox.put(member.id, member.copyWith(stackId: stack.id));
    }
    return stack;
  }

  /// Releases whose track list contains [projectId].
  List<Release> releasesContaining(String projectId) => [
    for (final release in releasesBox.values)
      if (release.trackIds.contains(projectId)) release,
  ];

  /// Swaps [oldId] for [newId] in every release track list that holds it,
  /// keeping the track's position. Returns the number of releases changed.
  ///
  /// If a release already lists [newId], [oldId] is simply dropped rather than
  /// creating a duplicate entry.
  Future<int> replaceProjectInReleases(String oldId, String newId) async {
    var changed = 0;
    for (final release in releasesContaining(oldId)) {
      final updated = <String>[];
      for (final id in release.trackIds) {
        if (id != oldId) {
          updated.add(id);
        } else if (!release.trackIds.contains(newId)) {
          updated.add(newId);
        }
      }
      await releasesBox.put(release.id, release.copyWith(trackIds: updated));
      changed++;
    }
    return changed;
  }

  /// Dissolves [stackId], returning its members to independent projects.
  ///
  /// Members get their own metadata back untouched, because stacking never
  /// cleared it. The stack row itself is deleted along with any edits made to
  /// it — that is the lossy part, and the UI should say so before calling.
  ///
  /// A stack can be a track on a release. Deleting the row without touching
  /// the release would strand its id in `trackIds`, and the release page skips
  /// ids it cannot resolve — so the track would vanish from the release with
  /// no warning and the dead id would sit there forever. Its slot is handed to
  /// [releaseSuccessorId], or, when the caller doesn't say (the automatic path
  /// in [removeFromStack]), to whichever version was nominated to open by
  /// default, falling back to the first. The UI should ask rather than rely on
  /// that default.
  Future<void> unstack(String stackId, {String? releaseSuccessorId}) async {
    final stack = projectsBox.get(stackId);
    if (stack == null || !stack.isVirtual) return;
    final members = stackMembers(stack);

    if (members.isNotEmpty) {
      final successor = releaseSuccessorId ?? stack.defaultLaunchMemberId;
      final resolved = members.any((m) => m.id == successor)
          ? successor!
          : members.first.id;
      await replaceProjectInReleases(stackId, resolved);
    }

    for (final member in members) {
      // Only release a version that actually points back here. A stale stack
      // can still list a version that has since joined another one, and
      // clearing that member's link would quietly steal it from the stack it
      // now belongs to.
      if (member.stackId != null && member.stackId != stackId) continue;
      await projectsBox.put(member.id, member.copyWith(clearStackId: true));
    }
    await projectsBox.delete(stackId);
  }

  /// Attaches [projectId] to [stackId] — used when a scan finds a new version
  /// file in a folder that is already stacked, so it inherits the main
  /// project's metadata instead of arriving blank.
  Future<void> addToStack({
    required String stackId,
    required String projectId,
  }) async {
    final stack = projectsBox.get(stackId);
    final project = projectsBox.get(projectId);
    if (stack == null || !stack.isVirtual || project == null) return;
    if (project.isVirtual || stack.memberProjectIds.contains(projectId)) return;
    // A project can only belong to one stack. Re-parenting silently would
    // flip its stackId while leaving it listed on the old stack, so its work
    // time would be counted by both and cleanUpDanglingStackLinks — which
    // only repairs links pointing at nothing — would never notice.
    if (project.isStackMember) return;

    await projectsBox.put(
      stackId,
      stack.copyWith(
        memberProjectIds: [...stack.memberProjectIds, projectId],
      ),
    );
    await projectsBox.put(projectId, project.copyWith(stackId: stackId));
  }

  /// What [autoStackFolders] would do to one folder: the loose projects it
  /// would pull in, and the stack they would join if that folder already has
  /// one.
  ///
  /// Exists so the Version Stack setting can *show* its effect before applying
  /// it. Auto-stacking rewrites rows rather than redrawing them, so flipping a
  /// segmented button should not silently restructure someone's library.
  List<AutoStackPlanEntry> planAutoStack(Iterable<String> rootPaths) {
    final roots = [for (final path in rootPaths) p.normalize(path)];
    if (roots.isEmpty) return const [];

    bool underRoot(String filePath) {
      final norm = p.normalize(filePath);
      return roots.any(
        (root) => p.isWithin(root, norm) || p.equals(root, p.dirname(norm)),
      );
    }

    final stackByFolder = <String, MusicProject>{
      for (final project in projectsBox.values)
        if (project.isVirtual) p.normalize(project.filePath): project,
    };
    final rootFolders = roots.toSet();

    final plan = <AutoStackPlanEntry>[];
    final grouped = groupByImmediateFolder(
      projectsBox.values.where(
        (project) => !project.hidden && underRoot(project.filePath),
      ),
    );
    for (final entry in grouped.entries) {
      if (rootFolders.contains(entry.key)) continue;
      final existing = stackByFolder[entry.key];
      if (existing == null && entry.value.length < 2) continue;
      plan.add(
        AutoStackPlanEntry(
          folder: entry.key,
          projects: entry.value,
          existingStack: existing,
        ),
      );
    }
    plan.sort((a, b) => a.folder.toLowerCase().compareTo(b.folder.toLowerCase()));
    return plan;
  }

  /// Creates and grows stacks for every root in [ScanMode.versionStack],
  /// treating each immediate parent folder holding two or more project files
  /// as one main project. Returns the number of stacks created.
  ///
  /// Called after a scan. Two rules keep it from destroying anything the user
  /// arranged by hand:
  /// - It only ever *adds*. A folder that is already stacked absorbs its new
  ///   files (so a freshly saved `v4` inherits the main project's notes,
  ///   tasks and deadline instead of arriving blank); nothing is ever
  ///   unstacked here.
  /// - A project the user already stacked elsewhere is left alone —
  ///   [groupByImmediateFolder] skips anything carrying a `stackId`, so a
  ///   hand-made stack spanning two folders survives a rescan intact.
  Future<int> autoStackFolders() async {
    final stackRoots = [
      for (final root in rootsBox.values)
        if (root.scanMode == ScanMode.versionStack) root.path,
    ];
    if (stackRoots.isEmpty) return 0;
    return applyAutoStackPlan(planAutoStack(stackRoots));
  }

  /// Applies what [planAutoStack] described. Returns the number of new stacks
  /// created (folders joining an existing stack are not counted).
  Future<int> applyAutoStackPlan(List<AutoStackPlanEntry> plan) async {
    var created = 0;
    for (final entry in plan) {
      if (entry.existingStack case final stack?) {
        for (final project in entry.projects) {
          await addToStack(stackId: stack.id, projectId: project.id);
        }
        continue;
      }
      if (entry.projects.length < 2) continue;
      await stackProjects(
        memberIds: entry.projects.map((m) => m.id).toList(),
      );
      created++;
    }
    return created;
  }

  /// Detaches [projectId] from whatever stack holds it.
  ///
  /// If that leaves the stack with a single version, the stack is dissolved
  /// too: a "stack of one" is just a project wearing a badge, and leaving it
  /// around means its metadata quietly outranks the file's own.
  Future<void> removeFromStack(String projectId) async {
    final project = projectsBox.get(projectId);
    final stackId = project?.stackId;
    if (project == null || stackId == null) return;
    final stack = projectsBox.get(stackId);

    await projectsBox.put(projectId, project.copyWith(clearStackId: true));
    if (stack == null) return;

    final remaining = stack.memberProjectIds
        .where((id) => id != projectId)
        .toList();
    if (remaining.length < 2) {
      await unstack(stackId);
      return;
    }
    await projectsBox.put(
      stackId,
      stack.copyWith(
        memberProjectIds: remaining,
        defaultLaunchMemberId: stack.defaultLaunchMemberId == projectId
            ? remaining.first
            : stack.defaultLaunchMemberId,
      ),
    );
  }

  Future<void> updateProject(MusicProject project) async {
    final updatedProject = project.copyWith(updatedAt: DateTime.now());
    await projectsBox.put(updatedProject.id, updatedProject);

    // Reschedule notifications if on Android and deadline changed
    if (Platform.isAndroid) {
      try {
        await NotificationBackgroundService.triggerCheck();
      } catch (e) {
        if (kDebugMode) print('Error rescheduling notifications: $e');
      }
    }
  }

  /// Saves a project exactly as-is, preserving all dates.
  /// Use this for backup/sync restore, NOT for user-initiated edits.
  Future<void> restoreProject(MusicProject project) async {
    await projectsBox.put(project.id, project);
  }

  /// Extracts full metadata for a single project and updates it
  Future<void> extractFullMetadataForProject(String projectId) async {
    final project = projectsBox.get(projectId);
    if (project == null) return;

    try {
      final extractedMetadata = await MetadataExtractor.extractMetadata(
        project.filePath,
      );

      // Update project with extracted metadata, preserving existing values if extraction didn't find anything
      final updated = project.copyWith(
        bpm: extractedMetadata.bpm ?? project.bpm,
        musicalKey: extractedMetadata.key ?? project.musicalKey,
        dawType: extractedMetadata.dawType ?? project.dawType,
        dawVersion: extractedMetadata.dawVersion ?? project.dawVersion,
        projectNotes: extractedMetadata.projectNotes ?? project.projectNotes,
        markers: extractedMetadata.markers ?? project.markers,
        updatedAt: DateTime.now(),
      );

      await projectsBox.put(projectId, updated);
    } catch (_) {
      // If extraction fails, silently continue
    }
  }

  // --- Event methods ---

  Future<void> addEvent(ProjectEvent event) async {
    await eventsBox.put(event.id, event);
  }

  List<ProjectEvent> getEventsForProject(String projectId) {
    return eventsBox.values
        .where((e) => e.projectId == projectId)
        .toList(growable: false)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  List<ProjectEvent> getAllEvents() => eventsBox.values.toList(growable: false);

  Stream<BoxEvent> watchEvents() => eventsBox.watch();

  Future<void> clearEventsForProject(String projectId) async {
    final keys = eventsBox.values
        .where((e) => e.projectId == projectId)
        .map((e) => e.id)
        .toList(growable: false);
    await eventsBox.deleteAll(keys);
  }

  // Reactive listeners
  ValueListenable<Box<MusicProject>> projectsListenable() =>
      projectsBox.listenable();
  ValueListenable<Box<ScanRoot>> rootsListenable() => rootsBox.listenable();

  // Stream watch for Riverpod StreamProvider usage
  Stream<BoxEvent> watchProjects() => projectsBox.watch();

  // Emits the full project list on every Hive box change. Scans can fire
  // hundreds/thousands of individual put()s in quick succession (one per
  // discovered file), each of which would otherwise re-materialize and
  // re-filter the whole list — an O(N^2) cost that dominates scan time on
  // large libraries. Debouncing collapses a burst of box events into a
  // single emission after they go quiet.
  Stream<List<MusicProject>> watchAllProjects() {
    late StreamController<List<MusicProject>> controller;
    StreamSubscription<BoxEvent>? boxSub;
    Timer? debounceTimer;

    void emitCurrent() {
      // The debounce timer below can fire after this profile's boxes were
      // closed out from under it — e.g. a fast profile switch, where
      // repositoryProvider's onDispose closes projectsBox before this
      // stream's own subscription (on the outgoing allProjectsStreamProvider)
      // gets cancelled. Touching a closed box throws HiveError, and since
      // this runs inside a bare Timer callback with no surrounding
      // try/catch, that becomes an uncaught async exception. Guard instead
      // of relying on cross-provider disposal ordering.
      if (!projectsBox.isOpen) return;
      List<MusicProject> projects;
      try {
        projects = projectsBox.values.toList();
      } catch (_) {
        return;
      }
      if (kDebugMode) {
        print(
          'watchAllProjects: emitting ${projects.length} projects for profile $profileId',
        );
      }
      if (!controller.isClosed) controller.add(projects);
    }

    controller = StreamController<List<MusicProject>>(
      onListen: () {
        emitCurrent();
        boxSub = projectsBox.watch().listen((_) {
          debounceTimer?.cancel();
          debounceTimer = Timer(const Duration(milliseconds: 200), emitCurrent);
        });
      },
      onCancel: () {
        debounceTimer?.cancel();
        boxSub?.cancel();
      },
    );

    return controller.stream;
  }

  Stream<BoxEvent> watchRoots() => rootsBox.watch();

  Future<void> clearAllData() async {
    // Get all project IDs that are referenced in releases (to preserve them)
    final releases = getAllReleases();
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }

    // Delete all projects except those referenced in releases
    if (protectedProjectIds.isNotEmpty) {
      final allProjectIds = projectsBox.keys.cast<String>().toSet();
      final projectsToDelete = allProjectIds.difference(protectedProjectIds);
      if (projectsToDelete.isNotEmpty) {
        await projectsBox.deleteAll(projectsToDelete);
      }
    } else {
      // No protected projects, safe to clear all
      await projectsBox.clear();
    }

    // Always clear roots
    await rootsBox.clear();

    // Clear ignored paths
    await ignoredPathsBox.clear();

    // Clear event log
    await eventsBox.clear();
  }

  /// Wipes every Hive box across all profiles and all global settings,
  /// leaving the app in a clean first-launch state with a fresh default profile.
  static Future<void> deleteAllAppData() async {
    // Collect profile IDs while boxes are still open (avoids type-mismatch
    // errors from trying to reopen a typed box as Box<dynamic>).
    final List<String> profileIds;
    if (Hive.isBoxOpen(ProfileRepository.profilesBoxName)) {
      profileIds = Hive.box<Profile>(
        ProfileRepository.profilesBoxName,
      ).keys.cast<String>().toList();
    } else {
      final box = await Hive.openBox<Profile>(
        ProfileRepository.profilesBoxName,
      );
      profileIds = box.keys.cast<String>().toList();
    }

    // Close every open box so we can re-open them without type conflicts.
    await Hive.close();

    // Clear per-profile boxes.
    const perProfileBoxes = [
      'projects',
      'roots',
      'ignored_paths',
      'releases',
      'playlists',
      'events',
    ];
    for (final profileId in profileIds) {
      for (final suffix in perProfileBoxes) {
        try {
          final box = await Hive.openBox<dynamic>('${profileId}_$suffix');
          await box.clear();
          await box.close();
        } catch (_) {}
      }
    }

    // Clear global boxes.
    const globalBoxNames = [
      'settings', 'app_settings', 'notification_preferences',
      'todoTemplates',
      'partTemplates',
      'projectTemplates',
      'templateRoots',
      'profiles',
      'backup_timestamps',
      // Legacy / misc boxes.
      'music_projects', 'projects', 'releases', 'roots',
    ];
    for (final name in globalBoxNames) {
      try {
        final box = await Hive.openBox<dynamic>(name);
        await box.clear();
        await box.close();
      } catch (_) {}
    }

    // Delete locally downloaded preview song files.
    try {
      final previewSongsPath = await getPreviewSongsPath();
      final dir = Directory(previewSongsPath);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}

    // Re-initialize with a fresh default profile so the app starts cleanly.
    await ProfileRepository.init();
  }

  // Releases
  Future<void> addRelease(Release release) async {
    await releasesBox.put(release.id, release);
  }

  Future<void> updateRelease(Release release) async {
    await releasesBox.put(release.id, release);
  }

  Future<void> deleteRelease(String releaseId) async {
    await releasesBox.delete(releaseId);
  }

  List<Release> getAllReleases() => releasesBox.values.toList(growable: false);

  Release? getReleaseById(String id) {
    try {
      return releasesBox.get(id);
    } catch (_) {
      return null;
    }
  }

  Stream<List<Release>> watchAllReleases() async* {
    // Emit initial value immediately
    yield releasesBox.values.toList();
    // Then watch for changes
    yield* releasesBox.watch().map((_) => releasesBox.values.toList());
  }

  Stream<BoxEvent> watchReleases() => releasesBox.watch();

  // Playlists
  Future<Playlist> createPlaylist(
    String name, {
    List<String>? projectIds,
    List<String>? audioFilePaths,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final playlist = Playlist(
      id: id,
      name: name,
      projectIds: projectIds ?? [],
      audioFilePaths: audioFilePaths ?? [],
      createdAt: now,
      updatedAt: now,
    );
    await playlistsBox.put(id, playlist);
    return playlist;
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final updated = playlist.copyWith(updatedAt: DateTime.now());
    await playlistsBox.put(playlist.id, updated);
  }

  Future<void> deletePlaylist(String id) async {
    await playlistsBox.delete(id);
  }

  List<Playlist> getAllPlaylists() =>
      playlistsBox.values.toList(growable: false);

  Playlist? getPlaylistById(String id) {
    try {
      return playlistsBox.get(id);
    } catch (_) {
      return null;
    }
  }

  Stream<List<Playlist>> watchAllPlaylists() async* {
    // Emit initial value immediately
    yield playlistsBox.values.toList();
    // Then watch for changes
    yield* playlistsBox.watch().map((_) => playlistsBox.values.toList());
  }

  ValueListenable<Box<Playlist>> playlistsListenable() =>
      playlistsBox.listenable();
}

/// One folder's worth of automatic stacking, as [ProjectRepository.planAutoStack]
/// describes it before anything is written.
class AutoStackPlanEntry {
  const AutoStackPlanEntry({
    required this.folder,
    required this.projects,
    this.existingStack,
  });

  /// The immediate parent folder whose files become one main project.
  final String folder;

  /// The loose projects that would be stacked — the whole group for a new
  /// stack, or just the newcomers when [existingStack] is set.
  final List<MusicProject> projects;

  /// The stack this folder already has, if any. Non-null means these projects
  /// would *join* it rather than form a new one.
  final MusicProject? existingStack;

  bool get createsNewStack => existingStack == null;

  /// How many versions the main project ends up holding.
  int get resultingVersionCount =>
      (existingStack?.memberProjectIds.length ?? 0) + projects.length;
}
