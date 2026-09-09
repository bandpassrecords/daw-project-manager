import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:audio_service/audio_service.dart' show MediaItem;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/app_paths.dart';
import '../utils/mobile_utils.dart';
import '../utils/version_stacks.dart';
import '../utils/phase_colors.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../services/audio_analysis_service.dart';
import '../services/thumbnail_toolbar_service.dart';
import '../services/waveform_disk_cache.dart';
import '../models/project_detail_layout.dart';
import '../models/waveform_style.dart';
import '../models/scan_root.dart';
import '../models/ignored_path.dart';
import '../models/release.dart';
import '../models/profile.dart';
import '../models/playlist.dart';
import '../models/todo_template.dart';
import '../models/part_template.dart';
import '../models/project_part.dart';
import '../models/project_template.dart';
import '../models/template_root.dart';
import '../models/project_event.dart';
import '../repository/project_repository.dart';
import '../utils/search_utils.dart';
import '../repository/profile_repository.dart';
import '../services/google_drive_sync_service.dart';
import '../services/deadline_notification_service.dart';
import '../models/auto_backup_interval.dart';
import '../models/pending_folder.dart';
import '../services/metadata_extractor.dart';
import '../services/auto_start_service.dart';
import '../services/crash_logger.dart';

// Profile Repository Provider
final profileRepositoryProvider = FutureProvider<ProfileRepository>((
  ref,
) async {
  return ProfileRepository.init();
});

// Current Profile Provider
final currentProfileProvider = StreamProvider<Profile?>((ref) async* {
  final profileRepo = await ref.watch(profileRepositoryProvider.future);
  final currentId = profileRepo.getCurrentProfileId();
  if (currentId != null) {
    yield profileRepo.getProfileById(currentId);
  } else {
    yield null;
  }

  // Watch for profile changes
  yield* profileRepo.watchProfiles().asyncMap((_) async {
    final currentId = profileRepo.getCurrentProfileId();
    return currentId != null ? profileRepo.getProfileById(currentId) : null;
  });
});

// All Profiles Provider
final allProfilesProvider = StreamProvider<List<Profile>>((ref) async* {
  final profileRepo = await ref.watch(profileRepositoryProvider.future);
  yield* profileRepo.watchAllProfiles();
});

// Project Repository Provider - depends on ProfileRepository and current profile
final repositoryProvider = FutureProvider<ProjectRepository>((ref) async {
  final profileRepo = await ref.watch(profileRepositoryProvider.future);
  // Watch current profile to invalidate when profile changes
  final currentProfile = await ref.watch(currentProfileProvider.future);
  if (currentProfile == null) {
    throw Exception('No active profile found');
  }
  final repo = await ProjectRepository.init(profileRepo);
  // Deliberately NOT closing this profile's boxes via ref.onDispose on
  // profile switch (as a memory optimization once was) — Riverpod keeps
  // exposing the outgoing FutureProvider's previous value as .value while
  // the new one loads (AsyncValue's "keep previous data during reload"
  // behavior), so any build-time code that reads repositoryProvider's
  // .value synchronously (e.g. dashboard_page.dart's startup-dialog check)
  // can still be holding this exact repo object after onDispose already
  // closed its boxes underneath it — a HiveError "Box has already been
  // closed" thrown mid-build, not from any one call site we can just guard,
  // but from the dispose timing itself. Every profile visited this session
  // stays resident in memory as a result; that's the accepted tradeoff.
  return repo;
});

final customMixdownFoldersProvider = FutureProvider<List<String>>((ref) async {
  final repo = await ref.watch(repositoryProvider.future);
  return repo.getCustomMixdownFolders();
});

final customMixdownFoldersByDawProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
      final repo = await ref.watch(repositoryProvider.future);
      return repo.getCustomMixdownFoldersByDaw();
    });

// "Launch in DAW" executable overrides (desktop), keyed by DAW display name,
// each mapped to an ordered list of paths.
final dawLaunchCommandsProvider = FutureProvider<Map<String, List<String>>>((
  ref,
) async {
  final repo = await ref.watch(repositoryProvider.future);
  return repo.getDawLaunchCommands();
});

final rootsWatchProvider = StreamProvider<void>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchRoots().map((_) {});
});

final scanRootsProvider = Provider<List<ScanRoot>>((ref) {
  // Rebuild when roots box changes
  ref.watch(rootsWatchProvider);
  final repoAsync = ref.watch(repositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) => repo.getRoots(),
    orElse: () => const <ScanRoot>[],
  );
});

final ignoredPathsWatchProvider = StreamProvider<void>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchIgnoredPaths().map((_) {});
});

final ignoredPathsProvider = Provider<List<IgnoredPath>>((ref) {
  // Rebuild when ignored paths box changes
  ref.watch(ignoredPathsWatchProvider);
  final repoAsync = ref.watch(repositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) => repo.getIgnoredPaths(),
    orElse: () => const <IgnoredPath>[],
  );
});

// scanning state is managed in UI now

class QueryParams {
  final String searchText;
  final bool sortDesc;
  const QueryParams({this.searchText = '', this.sortDesc = true});

  // Adiciona o método copyWith para facilitar a atualização
  QueryParams copyWith({String? searchText, bool? sortDesc}) {
    return QueryParams(
      searchText: searchText ?? this.searchText,
      sortDesc: sortDesc ?? this.sortDesc,
    );
  }
}

// CORREÇÃO ESSENCIAL PARA RIVERPOD V3: Usa Notifier<T> (em vez de StateNotifier<T>)
class QueryParamsNotifier extends Notifier<QueryParams> {
  // CORREÇÃO ESSENCIAL PARA RIVERPOD V3: O construtor v3 é o método build()
  @override
  QueryParams build() {
    return const QueryParams();
  }

  void setSearchText(String text) {
    state = state.copyWith(searchText: text);
  }

  void toggleSortDesc() {
    state = state.copyWith(sortDesc: !state.sortDesc);
  }
}

// CORREÇÃO ESSENCIAL PARA RIVERPOD V3: Usa NotifierProvider (em vez de StateNotifierProvider)
final queryParamsNotifierProvider =
    NotifierProvider<QueryParamsNotifier, QueryParams>(() {
      return QueryParamsNotifier();
    });

// Separate search providers for Projects and Releases tabs
class ProjectsSearchNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setSearchText(String text) {
    state = text;
  }

  void clear() {
    state = '';
  }
}

final projectsSearchProvider = NotifierProvider<ProjectsSearchNotifier, String>(
  () {
    return ProjectsSearchNotifier();
  },
);

class ReleasesSearchNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setSearchText(String text) {
    state = text;
  }

  void clear() {
    state = '';
  }
}

final releasesSearchProvider = NotifierProvider<ReleasesSearchNotifier, String>(
  () {
    return ReleasesSearchNotifier();
  },
);

// Template Search Provider — same session-only shape as projectsSearchProvider.
// Kept in a global provider (rather than local widget state) so the search
// text survives navigating away from and back to the Project Templates page,
// not just widget rebuilds.
class TemplateSearchNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setSearchText(String text) {
    state = text;
  }

  void clear() {
    state = '';
  }
}

final templateSearchProvider = NotifierProvider<TemplateSearchNotifier, String>(
  () {
    return TemplateSearchNotifier();
  },
);

enum ReleasesSort { dateDesc, dateAsc, titleAsc, titleDesc }

class ReleasesSortNotifier extends Notifier<ReleasesSort> {
  @override
  ReleasesSort build() => ReleasesSort.dateDesc;

  void setSort(ReleasesSort sort) => state = sort;
}

final releasesSortProvider =
    NotifierProvider<ReleasesSortNotifier, ReleasesSort>(() {
      return ReleasesSortNotifier();
    });

class PlaylistsSearchNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setSearchText(String text) {
    state = text;
  }

  void clear() {
    state = '';
  }
}

final playlistsSearchProvider =
    NotifierProvider<PlaylistsSearchNotifier, String>(() {
      return PlaylistsSearchNotifier();
    });

// Show hidden projects state provider
// 0 = show only visible (default)
// 1 = show all (visible + hidden)
// 2 = show only hidden
//
// Intentionally session-only (not persisted to Hive). This used to be saved
// across restarts, but "show only hidden" filters out every normal project —
// leaving it on from a forgotten earlier session (or, since the underlying
// key wasn't profile-scoped, a *different* profile) made the whole project
// list silently disappear on next launch with no obvious cause.
class ShowHiddenProjectsNotifier extends Notifier<int> {
  @override
  int build() => 0; // Always starts showing only visible projects.

  void setShowAll(bool show) {
    state = show ? 1 : 0;
  }

  void setShowOnlyHidden(bool show) {
    state = show ? 2 : 0;
  }

  bool get isShowingAll => state == 1;
  bool get isShowingOnlyHidden => state == 2;
  bool get isShowingVisible => state == 0;
}

final showHiddenProjectsProvider =
    NotifierProvider<ShowHiddenProjectsNotifier, int>(() {
      return ShowHiddenProjectsNotifier();
    });

// REMOVEMOS: projectsWatchProvider (substituído pela reatividade do stream abaixo)

// Caches File(...).existsSync() / Directory(...).existsSync() results by
// path. Existence checks were previously re-run per project on every
// projectsProvider rebuild AND per visible grid row on every frame — real
// syscalls on the UI thread, repeated far more often than the filesystem
// actually changes. The cache is invalidated wholesale whenever the project
// list changes (scan, rescan, manual edit) via fileExistenceCacheProvider
// below, which is exactly when on-disk state is expected to have moved.
class FileExistenceCache {
  final Map<String, bool> _cache = {};

  bool exists(String path) {
    return _cache.putIfAbsent(
      path,
      () => File(path).existsSync() || Directory(path).existsSync(),
    );
  }

  void invalidateAll() => _cache.clear();
}

final fileExistenceCacheProvider = Provider<FileExistenceCache>((ref) {
  final cache = FileExistenceCache();
  ref.listen(allProjectsStreamProvider, (_, _) => cache.invalidateAll());
  return cache;
});

// NOVO PROVIDER CORRIGIDO: Stream que emite a lista bruta de projetos
// Ele usa o novo método watchAllProjects() do repositório (que você precisa garantir que existe)
// This provider automatically invalidates when repositoryProvider changes (profile switch)
final allProjectsStreamProvider = StreamProvider<List<MusicProject>>((
  ref,
) async* {
  // Watch repositoryProvider to automatically restart stream when profile changes
  final repo = await ref.watch(repositoryProvider.future);

  if (kDebugMode) {
    print(
      'allProjectsStreamProvider: Starting stream for profile ${repo.profileId}',
    );
  }

  // OBSERVAÇÃO: Este método (repo.watchAllProjects()) deve existir e retornar Stream<List<MusicProject>>
  yield* repo.watchAllProjects();
});

// PROVIDER CORRIGIDO: Agora observa o allProjectsStreamProvider e o Notifier
final projectsProvider = Provider<List<MusicProject>>((ref) {
  // 1. Observa o stream de todos os projetos (retorna um AsyncValue)
  final allProjectsAsync = ref.watch(allProjectsStreamProvider);

  // 2. Observa o estado ATUAL (QueryParams) do nosso novo Notifier
  final params = ref.watch(queryParamsNotifierProvider);

  // 3. Observa releases e scan roots para filter preserved projects
  final releasesAsync = ref.watch(releasesProvider);
  final scanRoots = ref.watch(scanRootsProvider);
  final fileExistenceCache = ref.watch(fileExistenceCacheProvider);

  // 4. Usa .whenData para acessar a lista quando estiver pronta e aplicar o filtro/ordenação
  return allProjectsAsync
      .whenData((allProjects) {
        var projects = allProjects;

        // --- Collapse version stacks (#94) ---
        // A stacked file is represented in the list by its stack, which owns
        // the shared metadata. Showing both would list the same project twice
        // and double-count it in every total derived from this list. The
        // helper also rolls each stack's work time up from its members, which
        // is where it is actually stored.
        projects = collapseVersionStacks(projects);

        // --- Filter out stale preserved projects ---
        // A "preserved" project is one attached to a release. We hide it only when its
        // source file DOES exist locally but falls outside every active scan root (the
        // user removed the root). Projects whose files are NOT present locally are always
        // shown — they are metadata-only entries restored from a backup on another machine.
        if (!MobileUtils.isMobile()) {
          final releases = releasesAsync.value ?? [];
          final protectedProjectIds = <String>{};
          for (final release in releases) {
            protectedProjectIds.addAll(release.trackIds);
          }

          final activeRootPaths = scanRoots.map((root) {
            final normalized = p.normalize(root.path);
            return normalized.endsWith(p.separator)
                ? normalized
                : normalized + p.separator;
          }).toList();

          projects = projects.where((project) {
            // Projects not attached to any release are always shown.
            if (!protectedProjectIds.contains(project.id)) return true;

            // File not present locally → metadata-only from backup / different machine.
            // Always show so the user can inspect / edit metadata.
            final fileExistsLocally = fileExistenceCache.exists(
              project.filePath,
            );
            if (!fileExistsLocally) return true;

            // File exists locally: only show if it's under an active scan root.
            final projectPath = p.normalize(project.filePath);
            return activeRootPaths.any(
              (rootPath) => projectPath.startsWith(rootPath),
            );
          }).toList();
        } else {
          // Android: show all projects (metadata-only mode, no file system checks).
          if (kDebugMode) {
            print(
              'projectsProvider (Android): Showing all ${projects.length} projects (metadata-only mode)',
            );
          }
        }

        // --- Filter hidden projects ---
        final hiddenMode = ref.watch(showHiddenProjectsProvider);
        if (hiddenMode == 0) {
          // Show only visible projects
          projects = projects.where((p) => !p.hidden).toList();
        } else if (hiddenMode == 2) {
          // Show only hidden projects
          projects = projects.where((p) => p.hidden).toList();
        }
        // If hiddenMode == 1, show all (both visible and hidden)

        // --- Filter by phase ---
        final phaseFilter = ref.watch(phaseFilterProvider);
        if (phaseFilter != null) {
          projects = projects.where((p) => p.status == phaseFilter).toList();
        }

        // --- Filter by DAW ---
        final dawFilter = ref.watch(dawFilterProvider);
        if (dawFilter != null) {
          projects = projects.where((p) => p.dawType == dawFilter).toList();
        }

        // --- Filter by deadline ---
        final deadlineFilter = ref.watch(deadlineFilterProvider);
        if (deadlineFilter != DeadlineFilter.all) {
          switch (deadlineFilter) {
            case DeadlineFilter.hasDeadline:
              projects = projects.where((p) => p.deadline != null).toList();
              break;
            case DeadlineFilter.overdue:
              projects = projects.where((p) {
                if (p.deadline == null) return false;
                final daysUntil = p.daysUntilDeadline ?? 0;
                return daysUntil < 0;
              }).toList();
              break;
            case DeadlineFilter.dueSoon:
              projects = projects.where((p) {
                if (p.deadline == null) return false;
                final daysUntil = p.daysUntilDeadline ?? 0;
                return daysUntil >= 0 && daysUntil <= 7;
              }).toList();
              break;
            case DeadlineFilter.dueToday:
              projects = projects.where((p) {
                if (p.deadline == null) return false;
                final daysUntil = p.daysUntilDeadline ?? 0;
                return daysUntil == 0;
              }).toList();
              break;
            case DeadlineFilter.all:
              break;
          }
        }

        // --- Filter finished projects ---
        final finishedMode = ref.watch(showFinishedProjectsProvider);
        final finishedPhases = ref.watch(finishedPhaseProvider);
        if (finishedMode == 1) {
          // Hide finished projects
          projects = projects
              .where((p) => !finishedPhases.contains(p.status))
              .toList();
        }

        // --- Show only projects with deadline ---
        final showOnlyWithDeadline = ref.watch(showOnlyWithDeadlineProvider);
        if (showOnlyWithDeadline) {
          // Filter to show only projects with deadline
          projects = projects.where((p) => p.deadline != null).toList();
        }

        // --- Aplicação dos Filtros ---
        // Use projects search provider instead of queryParams
        final projectsSearch = ref.watch(projectsSearchProvider);
        if (projectsSearch.trim().isNotEmpty) {
          projects = projects
              .where(
                (p) => fuzzyMatchAny(
                  [
                    p.displayName,
                    p.notes,
                    // projectNotes are the read-only notes extracted from the
                    // DAW file itself — real user content, so searchable too.
                    p.projectNotes,
                    // Instrumentation is searchable too, so "who played bass
                    // on which song" is answerable from the projects list.
                    // Guarded because this runs per project per keystroke and
                    // searchableText builds a string.
                    if (p.parts.isNotEmpty)
                      ProjectPart.searchableText(p.parts),
                    // Marker names go in one entry each rather than joined:
                    // fuzzyMatchAny requires every query word to hit the *same*
                    // entry, so a joined string would match words picked out of
                    // two unrelated markers.
                    ...p.markers.map((m) => m.name),
                  ],
                  projectsSearch,
                ),
              )
              .toList();
        }

        // --- Ordenação ---
        // When "show only with deadline" is active, sort by deadline (nearest first)
        if (showOnlyWithDeadline) {
          projects.sort((a, b) {
            final aDaysUntil = a.daysUntilDeadline;
            final bDaysUntil = b.daysUntilDeadline;

            // Both should have deadline at this point, but safety check
            if (aDaysUntil == null && bDaysUntil == null) return 0;
            if (aDaysUntil == null) return 1;
            if (bDaysUntil == null) return -1;

            // Sort by urgency: overdue first, then due soon, then further out
            // Negative values (overdue) come before positive values (upcoming)
            return aDaysUntil.compareTo(bDaysUntil);
          });
        } else if (deadlineFilter != DeadlineFilter.all) {
          // When deadline filter is active (not 'all'), sort by deadline urgency
          projects.sort((a, b) {
            final aDaysUntil = a.daysUntilDeadline;
            final bDaysUntil = b.daysUntilDeadline;

            // Projects without deadline go to the end
            if (aDaysUntil == null && bDaysUntil == null) return 0;
            if (aDaysUntil == null) return 1;
            if (bDaysUntil == null) return -1;

            // Sort by urgency: overdue first, then due soon, then further out
            // Negative values (overdue) come before positive values (upcoming)
            return aDaysUntil.compareTo(bDaysUntil);
          });
        } else {
          // Default sorting by last modified
          projects.sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
          if (params.sortDesc) {
            projects = projects.reversed.toList();
          }
        }

        return projects;
      })
      .when(
        data: (projects) => projects,
        // Garante que a lista não é nula, mesmo carregando ou com erro
        loading: () => const <MusicProject>[],
        error: (_, _) => const <MusicProject>[],
      );
});

final dateFormatProvider = Provider<DateFormat>((ref) {
  final locale = ref.watch(localeProvider);
  return DateFormat.yMMMd(locale.toString()).add_jm();
});

// Releases Provider
final releasesProvider = StreamProvider<List<Release>>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchAllReleases();
});

// Initial scan state provider
final initialScanStateProvider = NotifierProvider<InitialScanNotifier, bool>(
  () {
    return InitialScanNotifier();
  },
);

class InitialScanNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true; // Start as true (scanning)
  }

  void setScanning(bool scanning) {
    state = scanning;
  }

  void complete() {
    state = false;
  }
}

// Profile switching state provider
final profileSwitchingProvider =
    NotifierProvider<ProfileSwitchingNotifier, bool>(() {
      return ProfileSwitchingNotifier();
    });

class ProfileSwitchingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setSwitching(bool switching) {
    state = switching;
  }

  void complete() {
    state = false;
  }
}

// Profile switching notifier
class ProfileSwitchNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void setProfileId(String? profileId) {
    state = profileId;
  }
}

final profileSwitchProvider = NotifierProvider<ProfileSwitchNotifier, String?>(
  () {
    return ProfileSwitchNotifier();
  },
);

// Locale Provider - manages app language preference
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Load locale asynchronously after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadLocale();
    });
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      final savedLocale = settingsBox.get('locale');
      if (savedLocale != null && savedLocale.isNotEmpty) {
        final parts = savedLocale.split('_');
        if (parts.isNotEmpty) {
          state = Locale(
            parts[0],
            parts.length > 1 && parts[1].isNotEmpty ? parts[1] : '',
          );
        }
      }
    } catch (_) {
      // Use default locale if loading fails
    }
  }

  Future<void> setLocale(Locale locale) async {
    // Update state synchronously to trigger immediate rebuild
    state = locale;
    if (kDebugMode) {
      print('Locale changed to: ${locale.languageCode}');
    }
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      await settingsBox.put(
        'locale',
        '${locale.languageCode}_${locale.countryCode ?? ''}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save locale: $e');
      }
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

// Selected Projects Provider - persists selection across language changes
final selectedProjectsProvider =
    NotifierProvider<SelectedProjectsNotifier, Set<String>>(() {
      return SelectedProjectsNotifier();
    });

class SelectedProjectsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return <String>{};
  }

  void toggle(String projectId) {
    final current = Set<String>.from(state);
    if (current.contains(projectId)) {
      current.remove(projectId);
    } else {
      current.add(projectId);
    }
    state = current;
  }

  void selectAll(List<String> projectIds) {
    state = Set<String>.from(projectIds);
  }

  void clear() {
    state = <String>{};
  }

  void addAll(List<String> projectIds) {
    final current = Set<String>.from(state);
    current.addAll(projectIds);
    state = current;
  }

  void removeAll(List<String> projectIds) {
    final current = Set<String>.from(state);
    current.removeAll(projectIds);
    state = current;
  }

  /// Drops any selected id that is no longer among [visibleIds].
  ///
  /// Selection is a claim about rows on screen, so an id that leaves the list
  /// has to leave the selection with it. Otherwise the selection bar counts
  /// rows the user cannot see or deselect: stacking a project turns it into a
  /// stack member and removes it from the list, and before this the bar went
  /// on reporting "1 project selected" with nothing highlighted anywhere.
  /// Hiding and deleting strand ids the same way.
  ///
  /// No-op when nothing would change, so this can be called on every rebuild
  /// without churning the provider.
  void retainAll(Iterable<String> visibleIds) {
    if (state.isEmpty) return;
    final visible = visibleIds.toSet();
    final kept = state.where(visible.contains).toSet();
    if (kept.length == state.length) return;
    state = kept;
  }

  /// Adds every id between [anchorId] and [targetId] (inclusive) in
  /// [orderedIds] to the current selection — the standard shift-click
  /// behavior for extending a selection from the last individually-clicked
  /// row to the one just shift-clicked. Merges with whatever was already
  /// selected (e.g. from an earlier, unrelated shift-click range) instead of
  /// replacing it, so an earlier range-select isn't lost when the user
  /// clicks a new anchor and shift-clicks again elsewhere in the table.
  /// Falls back to a plain toggle of [targetId] if either id isn't present
  /// in [orderedIds] (e.g. the anchor scrolled out of a filtered view).
  void selectRange(List<String> orderedIds, String anchorId, String targetId) {
    final anchorIndex = orderedIds.indexOf(anchorId);
    final targetIndex = orderedIds.indexOf(targetId);
    if (anchorIndex == -1 || targetIndex == -1) {
      toggle(targetId);
      return;
    }
    final start = anchorIndex < targetIndex ? anchorIndex : targetIndex;
    final end = anchorIndex < targetIndex ? targetIndex : anchorIndex;
    state = {...state, ...orderedIds.sublist(start, end + 1)};
  }
}

// Selected Templates Provider — same shape as SelectedProjectsNotifier but
// kept separate since it tracks a different screen's selection (the
// Project Templates table), not project ids.
final selectedTemplatesProvider =
    NotifierProvider<SelectedTemplatesNotifier, Set<String>>(() {
      return SelectedTemplatesNotifier();
    });

class SelectedTemplatesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String templateId) {
    final current = Set<String>.from(state);
    if (current.contains(templateId)) {
      current.remove(templateId);
    } else {
      current.add(templateId);
    }
    state = current;
  }

  void selectAll(List<String> templateIds) {
    state = Set<String>.from(templateIds);
  }

  void clear() {
    state = <String>{};
  }

  void selectRange(List<String> orderedIds, String anchorId, String targetId) {
    final anchorIndex = orderedIds.indexOf(anchorId);
    final targetIndex = orderedIds.indexOf(targetId);
    if (anchorIndex == -1 || targetIndex == -1) {
      toggle(targetId);
      return;
    }
    final start = anchorIndex < targetIndex ? anchorIndex : targetIndex;
    final end = anchorIndex < targetIndex ? targetIndex : anchorIndex;
    state = {...state, ...orderedIds.sublist(start, end + 1)};
  }
}

// Recently Discovered Projects Provider — IDs of projects the background
// folder watcher (see FolderWatcherService, wired up in main.dart) has found
// since this app session started. Intentionally session-only (not persisted
// to Hive) — "new" only means something within the current run of the app,
// and this naturally resets on restart just like ShowHiddenProjectsProvider.
final recentlyDiscoveredProjectsProvider =
    NotifierProvider<RecentlyDiscoveredProjectsNotifier, Set<String>>(() {
      return RecentlyDiscoveredProjectsNotifier();
    });

class RecentlyDiscoveredProjectsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void addAll(Iterable<String> projectIds) {
    state = {...state, ...projectIds};
  }

  void dismiss(String projectId) {
    if (!state.contains(projectId)) return;
    final updated = Set<String>.from(state)..remove(projectId);
    state = updated;
  }

  /// Dismisses every id in [projectIds] as a single state update — used for
  /// a smart-folder group's badge, which represents several newly-found
  /// projects at once and should clear all of them together on hover rather
  /// than one state update per member.
  void dismissAll(Iterable<String> projectIds) {
    if (projectIds.isEmpty) return;
    final updated = Set<String>.from(state)..removeAll(projectIds);
    if (updated.length == state.length) return;
    state = updated;
  }
}

// Phase Filter Provider - filters projects by phase/status
final phaseFilterProvider = NotifierProvider<PhaseFilterNotifier, String?>(() {
  return PhaseFilterNotifier();
});

class PhaseFilterNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // null means show all phases
  }

  void setPhase(String? phase) {
    state =
        phase; // null to show all, or a specific phase like 'Idea', 'Arranging', etc.
  }

  void clear() {
    state = null;
  }
}

// DAW Filter Provider - filters projects by dawType
final dawFilterProvider = NotifierProvider<DawFilterNotifier, String?>(() {
  return DawFilterNotifier();
});

class DawFilterNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // null means show all DAWs
  }

  void setDaw(String? daw) {
    state =
        daw; // null to show all, or a specific DAW like 'Ableton Live', 'FL Studio', etc.
  }

  void clear() {
    state = null;
  }
}

// Available DAWs provider — distinct, sorted dawType values across every
// project in the current profile (independent of any active filters), so
// the DAW filter dropdown only ever offers DAWs the user actually has.
final availableDawsProvider = Provider<List<String>>((ref) {
  final allProjectsAsync = ref.watch(allProjectsStreamProvider);
  // Collapsed: every version of a stacked project carries the same dawType,
  // and the filter only needs the DAWs the user actually has.
  final projects = collapseVersionStacks(
    allProjectsAsync.value ?? const <MusicProject>[],
  );
  final daws = projects
      .map((p) => p.dawType)
      .whereType<String>()
      .where((d) => d.isNotEmpty)
      .toSet()
      .toList();
  daws.sort();
  return daws;
});

// Template DAW/Key Filter Providers — same null-means-all shape as
// dawFilterProvider, but scoped to the Project Templates table's own
// filter bar rather than the main dashboard's. No BPM equivalent — BPM is
// a continuous value, so an exact-match dropdown of "available BPMs" isn't
// a meaningful filter the way a DAW/Key dropdown is.
final templateDawFilterProvider =
    NotifierProvider<TemplateDawFilterNotifier, String?>(() {
      return TemplateDawFilterNotifier();
    });

class TemplateDawFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null; // null means show all DAWs

  void setDaw(String? daw) {
    state = daw;
  }

  void clear() {
    state = null;
  }
}

final templateKeyFilterProvider =
    NotifierProvider<TemplateKeyFilterNotifier, String?>(() {
      return TemplateKeyFilterNotifier();
    });

class TemplateKeyFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null; // null means show all keys

  void setKey(String? key) {
    state = key;
  }

  void clear() {
    state = null;
  }
}

// Custom phases provider — reads per-profile phases from repository
final customPhasesProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider).asData?.value;
  return repo?.getCustomPhases() ??
      const ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];
});

// Phase color provider — per-profile map of phase name → Color
final phaseColorsProvider = Provider<Map<String, Color>>((ref) {
  final repo = ref.watch(repositoryProvider).asData?.value;
  if (repo == null) return const {};
  return repo.getPhaseColors().map(
    (phase, hex) => MapEntry(phase, hexToColor(hex)),
  );
});

// Finished phases provider — which phase names are treated as "done"
final finishedPhaseProvider = Provider<Set<String>>((ref) {
  final repo = ref.watch(repositoryProvider).asData?.value;
  return repo?.getFinishedPhases() ?? {'Finished'};
});

// Deadline Filter Enum
enum DeadlineFilter {
  all, // Show all projects
  hasDeadline, // Only projects with deadlines (sorted by urgency)
  overdue, // Only overdue projects
  dueSoon, // Due within 7 days
  dueToday, // Due today
}

// Deadline Filter Provider - filters projects by deadline status
final deadlineFilterProvider =
    NotifierProvider<DeadlineFilterNotifier, DeadlineFilter>(() {
      return DeadlineFilterNotifier();
    });

class DeadlineFilterNotifier extends Notifier<DeadlineFilter> {
  @override
  DeadlineFilter build() {
    return DeadlineFilter.all; // Default: show all
  }

  void setFilter(DeadlineFilter filter) {
    state = filter;
  }

  void clear() {
    state = DeadlineFilter.all;
  }
}

// Show Finished Projects Provider - hide/show finished projects
// 0 = show finished (default)
// 1 = hide finished
final showFinishedProjectsProvider =
    NotifierProvider<ShowFinishedProjectsNotifier, int>(() {
      return ShowFinishedProjectsNotifier();
    });

class ShowFinishedProjectsNotifier extends Notifier<int> {
  @override
  int build() {
    // Load saved state asynchronously after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadHideFinishedState();
    });
    return 0; // Default: show finished projects
  }

  Future<void> _loadHideFinishedState() async {
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      final savedState = settingsBox.get('hideFinishedProjects');
      if (savedState != null) {
        state = savedState == '1' ? 1 : 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load hide finished state: $e');
      }
    }
  }

  Future<void> setHideFinished(bool hide) async {
    final newState = hide ? 1 : 0;
    state = newState;

    // Save to Hive
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      await settingsBox.put('hideFinishedProjects', newState.toString());
      if (kDebugMode) {
        print('Hide finished projects state saved: $newState');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save hide finished state: $e');
      }
    }
  }

  bool get isHidingFinished => state == 1;
}

// Show Only Projects with Deadline Provider
// false = show all projects (default)
// true = show only projects with deadline, sorted by deadline
final showOnlyWithDeadlineProvider =
    NotifierProvider<ShowOnlyWithDeadlineNotifier, bool>(() {
      return ShowOnlyWithDeadlineNotifier();
    });

class ShowOnlyWithDeadlineNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Load saved state asynchronously after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadShowOnlyWithDeadlineState();
    });
    return false; // Default: show all projects
  }

  Future<void> _loadShowOnlyWithDeadlineState() async {
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      final savedState = settingsBox.get('showOnlyWithDeadline');
      if (savedState != null) {
        state = savedState == 'true';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load show only with deadline state: $e');
      }
    }
  }

  Future<void> setShowOnlyWithDeadline(bool show) async {
    state = show;

    // Save to Hive
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      await settingsBox.put('showOnlyWithDeadline', show.toString());
      if (kDebugMode) {
        print('Show only with deadline state saved: $show');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save show only with deadline state: $e');
      }
    }
  }
}

// Provider for GoogleDriveSyncService (singleton instance)
final googleDriveSyncServiceProvider = Provider<GoogleDriveSyncService>((ref) {
  return GoogleDriveSyncService();
});

// ---------------------------------------------------------------------------
// Auto Backup Interval
// ---------------------------------------------------------------------------

class AutoBackupIntervalNotifier extends Notifier<AutoBackupInterval> {
  static const _key = 'autoBackupInterval';

  @override
  AutoBackupInterval build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return AutoBackupInterval.off;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      state = AutoBackupInterval.fromStorageKey(box.get(_key));
    } catch (_) {}
  }

  Future<void> setInterval(AutoBackupInterval interval) async {
    state = interval;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      await box.put(_key, interval.name);
    } catch (_) {}
  }
}

final autoBackupIntervalProvider =
    NotifierProvider<AutoBackupIntervalNotifier, AutoBackupInterval>(
      AutoBackupIntervalNotifier.new,
    );

// ---------------------------------------------------------------------------
// Upload Auto-Detected Preview Songs
// ---------------------------------------------------------------------------

class UploadAutoPreviewSongsNotifier extends Notifier<bool> {
  static const _key = 'uploadAutoPreviewSongs';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return false;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      final saved = box.get(_key);
      if (saved != null) state = saved == 'true';
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      await box.put(_key, state.toString());
    } catch (_) {}
  }
}

final uploadAutoPreviewSongsProvider =
    NotifierProvider<UploadAutoPreviewSongsNotifier, bool>(
      UploadAutoPreviewSongsNotifier.new,
    );

// ---------------------------------------------------------------------------
// Update Check Setting
// ---------------------------------------------------------------------------

class CheckForUpdatesNotifier extends Notifier<bool> {
  static const _key = 'checkForUpdates';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return false;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      final saved = box.get(_key);
      if (saved != null) state = saved == 'true';
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      await box.put(_key, state.toString());
    } catch (_) {}
  }
}

final checkForUpdatesProvider = NotifierProvider<CheckForUpdatesNotifier, bool>(
  CheckForUpdatesNotifier.new,
);

// ---------------------------------------------------------------------------
// Diagnostic Logging Setting
// ---------------------------------------------------------------------------

/// Device-local (not synced) toggle for whether CrashLogger records
/// anything at all. Defaults off — opt-in, not opt-out. Every load/toggle
/// pushes the resolved value into [CrashLogger.setEnabled], since
/// CrashLogger itself can't read a provider (it's wired into global error
/// handlers that can fire before any ProviderScope exists).
class DiagnosticLoggingEnabledNotifier extends Notifier<bool> {
  static const _key = 'diagnosticLoggingEnabled';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return false;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      final saved = box.get(_key);
      if (saved != null) state = saved == 'true';
    } catch (_) {}
    CrashLogger.setEnabled(state);
  }

  Future<void> toggle() async {
    state = !state;
    CrashLogger.setEnabled(state);
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      await box.put(_key, state.toString());
    } catch (_) {}
  }
}

final diagnosticLoggingEnabledProvider =
    NotifierProvider<DiagnosticLoggingEnabledNotifier, bool>(
      DiagnosticLoggingEnabledNotifier.new,
    );

/// Holds the latest available version string when a newer release is found; null otherwise.
class AvailableUpdateNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? version) => state = version;
}

final availableUpdateProvider =
    NotifierProvider<AvailableUpdateNotifier, String?>(
      AvailableUpdateNotifier.new,
    );

/// Tracks whether the first-run onboarding wizard has been completed.
class OnboardingCompleteNotifier extends Notifier<bool> {
  static const _key = 'onboardingComplete';

  @override
  bool build() {
    _loadAsync();
    try {
      // Box is already open on subsequent launches — read synchronously.
      final box = Hive.box<String>('settings');
      return box.get(_key) == 'true';
    } catch (_) {
      // Box not open yet on very first frame; _loadAsync will set the real value.
      return false;
    }
  }

  void _loadAsync() async {
    final box = await Hive.openBox<String>('settings');
    state = box.get(_key) == 'true';
  }

  Future<void> complete() async {
    state = true;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, 'true');
  }

  Future<void> reset() async {
    state = false;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, 'false');
  }
}

final onboardingCompleteProvider =
    NotifierProvider<OnboardingCompleteNotifier, bool>(
      OnboardingCompleteNotifier.new,
    );

/// Tracks the project most recently launched in a DAW, shown as a quick-access
/// chip in the title bar.
class ActiveProjectNotifier extends Notifier<MusicProject?> {
  @override
  MusicProject? build() {
    // Keep the active project's data in sync with the repository. When a deep
    // scan or metadata extraction updates the project, the new BPM, key, phase
    // etc. are reflected here without ending or restarting the session.
    ref.listen(allProjectsStreamProvider, (_, next) {
      final active = state;
      if (active == null) return;
      final updated = next.value?.where((p) => p.id == active.id).firstOrNull;
      if (updated != null) state = updated;
    });
    return null;
  }

  void set(MusicProject project) => state = project;
  void clear() => state = null;
}

final activeProjectProvider =
    NotifierProvider<ActiveProjectNotifier, MusicProject?>(
      ActiveProjectNotifier.new,
    );

// Playlists Provider
final playlistsProvider = StreamProvider<List<Playlist>>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchAllPlaylists();
});

// Todo Templates Provider
final todoTemplatesProvider = StreamProvider<List<TodoTemplate>>((ref) async* {
  await ensureHiveInitialized();
  final box = await Hive.openBox<TodoTemplate>('todoTemplates');

  // Emit initial value
  yield box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  // Watch for changes
  await for (final _ in box.watch()) {
    yield box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
});

// Todo Templates Notifier
class TodoTemplatesNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addTemplate(TodoTemplate template) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<TodoTemplate>('todoTemplates');
    await box.put(template.id, template);
  }

  Future<void> updateTemplate(TodoTemplate template) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<TodoTemplate>('todoTemplates');
    await box.put(template.id, template);
  }

  Future<void> deleteTemplate(String id) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<TodoTemplate>('todoTemplates');
    await box.delete(id);
  }
}

final todoTemplatesNotifierProvider =
    NotifierProvider<TodoTemplatesNotifier, void>(() {
      return TodoTemplatesNotifier();
    });

// Part Templates Provider — reusable lineups (drums/bass/guitar/vocals…) a
// song's parts list can be seeded from. Global (not per-profile), mirrors
// TodoTemplate's box pattern.
final partTemplatesProvider = StreamProvider<List<PartTemplate>>((ref) async* {
  await ensureHiveInitialized();
  final box = await Hive.openBox<PartTemplate>('partTemplates');

  yield box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  await for (final _ in box.watch()) {
    yield box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
});

class PartTemplatesNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addTemplate(PartTemplate template) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<PartTemplate>('partTemplates');
    await box.put(template.id, template);
  }

  Future<void> updateTemplate(PartTemplate template) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<PartTemplate>('partTemplates');
    await box.put(template.id, template);
  }

  Future<void> deleteTemplate(String id) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<PartTemplate>('partTemplates');
    await box.delete(id);
  }
}

final partTemplatesNotifierProvider =
    NotifierProvider<PartTemplatesNotifier, void>(() {
      return PartTemplatesNotifier();
    });

// Project Templates Provider — "starter kit" folders a new project can be
// created from. Global (not per-profile), mirrors TodoTemplate's box pattern.
final projectTemplatesProvider = StreamProvider<List<ProjectTemplate>>((
  ref,
) async* {
  await ensureHiveInitialized();
  final box = await Hive.openBox<ProjectTemplate>('projectTemplates');

  yield box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  await for (final _ in box.watch()) {
    yield box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
});

// Filtered Project Templates Provider — applies the templates page's own
// search text + DAW/Key filters on top of projectTemplatesProvider,
// mirroring how projectsProvider layers its filters over allProjectsStreamProvider.
final filteredProjectTemplatesProvider = Provider<List<ProjectTemplate>>((ref) {
  final templatesAsync = ref.watch(projectTemplatesProvider);
  var templates = templatesAsync.value ?? const <ProjectTemplate>[];

  final query = ref.watch(templateSearchProvider).trim().toLowerCase();
  if (query.isNotEmpty) {
    templates = templates
        .where((t) => t.name.toLowerCase().contains(query))
        .toList();
  }

  final dawFilter = ref.watch(templateDawFilterProvider);
  if (dawFilter != null) {
    templates = templates
        .where(
          (t) =>
              MetadataExtractor.getDawTypeFromExtension(
                p.extension(t.mainFileRelativePath),
              ) ==
              dawFilter,
        )
        .toList();
  }

  final keyFilter = ref.watch(templateKeyFilterProvider);
  if (keyFilter != null) {
    templates = templates.where((t) => t.musicalKey == keyFilter).toList();
  }

  return templates;
});

// Available DAWs/Keys across registered templates — feed the respective
// filter dropdowns, mirroring availableDawsProvider. Derived from every
// registered template regardless of active filters, so a dropdown never
// hides an option just because another filter is currently narrowing the
// visible list.
final availableTemplateDawsProvider = Provider<List<String>>((ref) {
  final templatesAsync = ref.watch(projectTemplatesProvider);
  final templates = templatesAsync.value ?? const <ProjectTemplate>[];
  final daws = templates
      .map(
        (t) => MetadataExtractor.getDawTypeFromExtension(
          p.extension(t.mainFileRelativePath),
        ),
      )
      .whereType<String>()
      .where((d) => d.isNotEmpty)
      .toSet()
      .toList();
  daws.sort();
  return daws;
});

final availableTemplateKeysProvider = Provider<List<String>>((ref) {
  final templatesAsync = ref.watch(projectTemplatesProvider);
  final templates = templatesAsync.value ?? const <ProjectTemplate>[];
  final keys = templates
      .map((t) => t.musicalKey)
      .whereType<String>()
      .where((k) => k.isNotEmpty)
      .toSet()
      .toList();
  keys.sort();
  return keys;
});

class ProjectTemplatesNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addTemplate(ProjectTemplate template) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
    await box.put(template.id, template);
  }

  Future<void> updateTemplate(ProjectTemplate template) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
    await box.put(template.id, template);
  }

  Future<void> deleteTemplate(String id) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
    await box.delete(id);
  }

  /// Re-extracts bpm/key/DAW version/project notes from the template's main
  /// file on disk and merges them into the stored template — same shape as
  /// [ProjectRepository.extractFullMetadataForProject], but for a
  /// [ProjectTemplate] instead of a [MusicProject]. Existing values are
  /// preserved for anything extraction doesn't find.
  Future<void> extractMetadataForTemplate(String templateId) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
    final template = box.get(templateId);
    if (template == null) return;

    try {
      final mainFilePath = p.join(
        template.sourceFolderPath,
        template.mainFileRelativePath,
      );
      final extracted = await MetadataExtractor.extractMetadata(mainFilePath);
      final updated = template.copyWith(
        bpm: extracted.bpm ?? template.bpm,
        musicalKey: extracted.key ?? template.musicalKey,
        dawVersion: extracted.dawVersion ?? template.dawVersion,
        projectNotes: extracted.projectNotes ?? template.projectNotes,
        updatedAt: DateTime.now(),
      );
      await box.put(templateId, updated);
    } catch (_) {
      // If extraction fails, silently continue — mirrors
      // ProjectRepository.extractFullMetadataForProject.
    }
  }
}

final projectTemplatesNotifierProvider =
    NotifierProvider<ProjectTemplatesNotifier, void>(() {
      return ProjectTemplatesNotifier();
    });

// Template Roots Provider — registered parent folders scanned for template
// subfolders. Global (not per-profile), refreshed manually (see
// ProjectTemplateService.discoverTemplateCandidates) rather than watched.
final templateRootsProvider = StreamProvider<List<TemplateRoot>>((ref) async* {
  await ensureHiveInitialized();
  final box = await Hive.openBox<TemplateRoot>('templateRoots');

  yield box.values.toList()..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  await for (final _ in box.watch()) {
    yield box.values.toList()..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }
});

class TemplateRootsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addRoot(TemplateRoot root) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<TemplateRoot>('templateRoots');
    await box.put(root.id, root);
  }

  Future<void> updateRoot(TemplateRoot root) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<TemplateRoot>('templateRoots');
    await box.put(root.id, root);
  }

  Future<void> removeRoot(String id) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<TemplateRoot>('templateRoots');
    await box.delete(id);
  }
}

final templateRootsNotifierProvider =
    NotifierProvider<TemplateRootsNotifier, void>(() {
      return TemplateRootsNotifier();
    });

// Warn Before Quit Setting
class WarnBeforeQuitNotifier extends Notifier<bool> {
  // main() awaits `Hive.openBox<String>('settings')` before runApp() ("so
  // providers can read it synchronously on first build" — see main.dart),
  // so the box is guaranteed already open by the time any provider builds.
  // Reading it synchronously here (rather than deferring to a post-frame
  // callback, as this used to) avoids a startup race where a window-close
  // event firing before that callback ran would see the hardcoded `true`
  // default instead of the user's actual saved preference.
  @override
  bool build() {
    try {
      final saved = Hive.box<String>('settings').get('warnBeforeQuit');
      if (saved != null) return saved == 'true';
    } catch (e) {
      if (kDebugMode) print('Failed to load warnBeforeQuit: $e');
    }
    return true;
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box<String>('settings')
          : await Hive.openBox<String>('settings');
      await box.put('warnBeforeQuit', state.toString());
    } catch (e) {
      if (kDebugMode) print('Failed to save warnBeforeQuit: $e');
    }
  }
}

final warnBeforeQuitProvider = NotifierProvider<WarnBeforeQuitNotifier, bool>(
  () {
    return WarnBeforeQuitNotifier();
  },
);

// ---------------------------------------------------------------------------
// Close to Tray (desktop-only device-local preference)
// ---------------------------------------------------------------------------

/// Whether closing the window (the X button) minimizes the app to the
/// system tray / menu bar instead of quitting it. Defaults to false — the
/// window's close button quits the app like any other desktop app unless
/// the user explicitly opts in to keep background services (auto-backup,
/// deadline notifications) running after closing it.
class CloseToTrayNotifier extends Notifier<bool> {
  // Same synchronous-read rationale as WarnBeforeQuitNotifier above — the
  // settings box is guaranteed already open by the time this builds, so
  // there's no need (and no correctness benefit) to defer the real read to
  // a post-frame callback. Deferring it was the actual bug: a window-close
  // event firing before that callback ran would see the hardcoded `true`
  // default and minimize to tray even when the user had turned this off.
  @override
  bool build() {
    try {
      final saved = Hive.box<String>('settings').get('closeToTray');
      if (saved != null) return saved == 'true';
    } catch (e) {
      if (kDebugMode) print('Failed to load closeToTray: $e');
    }
    return false;
  }

  Future<void> set(bool value) async {
    state = value;
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box<String>('settings')
          : await Hive.openBox<String>('settings');
      await box.put('closeToTray', value.toString());
    } catch (e) {
      if (kDebugMode) print('Failed to save closeToTray: $e');
    }
  }
}

final closeToTrayProvider = NotifierProvider<CloseToTrayNotifier, bool>(() {
  return CloseToTrayNotifier();
});

// ---------------------------------------------------------------------------
// Launch at startup (desktop-only device-local preference)
// ---------------------------------------------------------------------------

/// Whether the OS launches the app automatically when the user signs in.
///
/// Unlike every other setting here, the real source of truth lives outside
/// the app — the Windows registry / a macOS login item / a Linux .desktop
/// file — and the user can revoke it from Task Manager or System Settings
/// without the app ever knowing. The Hive value is therefore a *cache*: it
/// exists so the settings switch can paint synchronously on first build
/// (same rationale as [CloseToTrayNotifier]), and [syncWithOs] reconciles it
/// against the OS on every launch.
///
/// Defaults to false — opting a user into a background-launching app without
/// being asked is not a reasonable default.
class AutoStartNotifier extends Notifier<bool> {
  static const _key = 'autoStart';

  @override
  bool build() {
    if (!AutoStartService.isSupported) return false;
    try {
      final saved = Hive.box<String>('settings').get(_key);
      if (saved != null) return saved == 'true';
    } catch (e) {
      if (kDebugMode) print('Failed to load autoStart: $e');
    }
    return false;
  }

  Future<void> _persist(bool value) async {
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box<String>('settings')
          : await Hive.openBox<String>('settings');
      await box.put(_key, value.toString());
    } catch (e) {
      if (kDebugMode) print('Failed to save autoStart: $e');
    }
  }

  /// Registers/unregisters the app with the OS and, only if that succeeded,
  /// caches the new value. Returns false when the OS refused — the caller is
  /// expected to surface that, since a silently-reverted switch looks broken.
  Future<bool> set(bool value) async {
    if (!AutoStartService.isSupported) return false;

    await AutoStartService.setup(minimized: ref.read(startMinimizedProvider));
    final ok = await AutoStartService.setEnabled(value);
    if (!ok) {
      // Leave both the state and the cache untouched so the switch snaps
      // back to what the OS actually has.
      return false;
    }
    state = value;
    await _persist(value);
    return true;
  }

  /// Rewrites the existing registration so it carries a changed
  /// "start minimized" flag. No-op when auto-start is off — there is no
  /// registration to update, and the new flag will be picked up by the next
  /// [set] anyway.
  Future<bool> reapply() async {
    if (!AutoStartService.isSupported || !state) return true;
    final ok = await AutoStartService.reapply(
      minimized: ref.read(startMinimizedProvider),
    );
    if (!ok) {
      // reapply() unregisters before re-registering, so a failure partway
      // through leaves the app genuinely not registered. Reflect that rather
      // than keep claiming auto-start is on until the next launch's
      // syncWithOs() notices.
      state = false;
      await _persist(false);
    }
    return ok;
  }

  /// Reconciles the cached value with what the OS actually reports. Call once
  /// at startup: if the user removed the app from their startup items outside
  /// the app, the settings switch must reflect that rather than keep claiming
  /// the feature is on.
  Future<void> syncWithOs() async {
    if (!AutoStartService.isSupported) return;

    await AutoStartService.setup(minimized: ref.read(startMinimizedProvider));
    final actual = await AutoStartService.isEnabled();
    if (actual == state) return;
    state = actual;
    await _persist(actual);
  }
}

final autoStartProvider = NotifierProvider<AutoStartNotifier, bool>(() {
  return AutoStartNotifier();
});

/// Whether an auto-start launch should come up hidden in the tray / menu bar
/// instead of opening the window.
///
/// Only meaningful alongside [autoStartProvider] — it is delivered as a
/// command-line flag baked into the registration, so a manual launch never
/// carries it and always opens normally. Toggling this while auto-start is
/// already on has to rewrite that registration, hence the [reapply] call.
class StartMinimizedNotifier extends Notifier<bool> {
  static const _key = 'startMinimized';

  @override
  bool build() {
    if (!AutoStartService.isSupported) return false;
    try {
      final saved = Hive.box<String>('settings').get(_key);
      if (saved != null) return saved == 'true';
    } catch (e) {
      if (kDebugMode) print('Failed to load startMinimized: $e');
    }
    return false;
  }

  /// Returns false if auto-start was on but the registration couldn't be
  /// rewritten — the preference is left untouched in that case, since a
  /// stored "start minimized" that the OS won't honour is just a lie.
  Future<bool> set(bool value) async {
    if (!AutoStartService.isSupported) return false;
    if (value == state) return true;

    final previous = state;
    state = value;

    // reapply() reads this provider, so the new value must already be in
    // place before it runs.
    final ok = await ref.read(autoStartProvider.notifier).reapply();
    if (!ok) {
      state = previous;
      return false;
    }

    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box<String>('settings')
          : await Hive.openBox<String>('settings');
      await box.put(_key, value.toString());
    } catch (e) {
      if (kDebugMode) print('Failed to save startMinimized: $e');
    }
    return true;
  }
}

final startMinimizedProvider = NotifierProvider<StartMinimizedNotifier, bool>(
  () {
    return StartMinimizedNotifier();
  },
);

// ---------------------------------------------------------------------------
// Name date stripping
// ---------------------------------------------------------------------------

/// Whether project names hide the date stamps some DAWs bake into file names
/// (Cubase writes `2026-08-02 - Massive Attack - Teardrop.cpr`).
///
/// Device-local display preference — deliberately not Drive-synced and not in
/// `backup_service`, same as theme and layout settings.
///
/// The value is mirrored into [MusicProject.stripDatesFromNames] rather than
/// read through this provider at the point of use: `displayName` is a plain
/// model getter called from ~100 widgets that have no `Ref` to hand. This
/// notifier is that static's only writer.
class NameDateStrippingNotifier extends Notifier<bool> {
  static const _key = 'stripDatesFromNames';

  @override
  bool build() {
    var value = false;
    try {
      value = Hive.box<String>('settings').get(_key) == 'true';
    } catch (e) {
      if (kDebugMode) print('Failed to load stripDatesFromNames: $e');
    }
    MusicProject.stripDatesFromNames = value;
    return value;
  }

  Future<void> set(bool value) async {
    if (value == state) return;
    state = value;
    MusicProject.stripDatesFromNames = value;
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box<String>('settings')
          : await Hive.openBox<String>('settings');
      await box.put(_key, value.toString());
    } catch (e) {
      if (kDebugMode) print('Failed to save stripDatesFromNames: $e');
    }
  }
}

final nameDateStrippingProvider =
    NotifierProvider<NameDateStrippingNotifier, bool>(() {
  return NameDateStrippingNotifier();
});

// ---------------------------------------------------------------------------
// Tab Visibility
// ---------------------------------------------------------------------------

enum AppTab { projects, releases, playlists, queue, statistics, player }

class VisibleTabsNotifier extends Notifier<Set<AppTab>> {
  static const _key = 'visibleTabs';

  // Canonical display order for all tabs.
  static const List<AppTab> canonicalOrder = [
    AppTab.projects,
    AppTab.releases,
    AppTab.playlists,
    AppTab.queue,
    AppTab.statistics,
    AppTab.player,
  ];

  @override
  Set<AppTab> build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    final defaults = {
      AppTab.projects,
      AppTab.releases,
      AppTab.playlists,
      AppTab.queue,
      AppTab.statistics,
      AppTab.player,
    };
    if (MobileUtils.isMobile()) defaults.remove(AppTab.player);
    return defaults;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      final saved = box.get(_key);
      if (saved != null && saved.isNotEmpty) {
        // Format: each entry is either "tabName" (visible) or "!tabName" (hidden).
        // Old format had only visible tab names (no "!" prefix) — those are treated
        // the same way. Any canonical tab absent from the string is a newly
        // introduced tab and defaults to visible.
        final entries = saved.split(',').where((s) => s.isNotEmpty).toList();
        final explicitlyHidden = <AppTab>{};
        final explicitlyVisible = <AppTab>{};

        for (final entry in entries) {
          final hidden = entry.startsWith('!');
          final name = hidden ? entry.substring(1) : entry;
          final tab = AppTab.values.where((t) => t.name == name).firstOrNull;
          if (tab == null) continue;
          if (hidden) {
            explicitlyHidden.add(tab);
          } else {
            explicitlyVisible.add(tab);
          }
        }

        // Build result: explicitly visible, plus any canonical tab not mentioned
        // at all (newly added tabs inherit default = visible).
        final result = Set<AppTab>.from(explicitlyVisible);
        for (final tab in canonicalOrder) {
          if (!explicitlyHidden.contains(tab) &&
              !explicitlyVisible.contains(tab)) {
            result.add(tab); // new tab not yet seen → show by default
          }
        }
        result.add(AppTab.projects); // always visible
        if (MobileUtils.isMobile()) result.remove(AppTab.player);
        state = result;
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load visibleTabs: $e');
    }
  }

  Future<void> setTabVisible(AppTab tab, bool visible) async {
    if (tab == AppTab.projects) return;
    // Player tab is desktop-only; never allow it to be enabled on mobile.
    if (tab == AppTab.player && MobileUtils.isMobile()) return;
    final updated = Set<AppTab>.from(state);
    if (visible) {
      updated.add(tab);
    } else {
      updated.remove(tab);
    }
    state = updated;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      // Save all canonical tabs with visibility marker so new future tabs can be
      // distinguished from explicitly-hidden ones.
      final entries = canonicalOrder
          .map((t) {
            return updated.contains(t) ? t.name : '!${t.name}';
          })
          .join(',');
      await box.put(_key, entries);
    } catch (e) {
      if (kDebugMode) print('Failed to save visibleTabs: $e');
    }
  }
}

final visibleTabsProvider = NotifierProvider<VisibleTabsNotifier, Set<AppTab>>(
  () {
    return VisibleTabsNotifier();
  },
);

// ---------------------------------------------------------------------------
// Tab Position (top vs left rail)
// ---------------------------------------------------------------------------

enum TabPosition { top, left }

class TabPositionNotifier extends Notifier<TabPosition> {
  static const _key = 'tabPosition';

  @override
  TabPosition build() {
    _load();
    return TabPosition.left;
  }

  void _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved == 'top') state = TabPosition.top;
    if (saved == 'left') state = TabPosition.left;
  }

  void set(TabPosition pos) async {
    state = pos;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, pos == TabPosition.left ? 'left' : 'top');
  }
}

final tabPositionProvider = NotifierProvider<TabPositionNotifier, TabPosition>(
  () {
    return TabPositionNotifier();
  },
);

class RailCollapsedNotifier extends Notifier<bool> {
  static const _key = 'railCollapsed';

  @override
  bool build() {
    _load();
    return false;
  }

  void _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved != null) state = saved == 'true';
  }

  void set(bool collapsed) async {
    state = collapsed;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, collapsed ? 'true' : 'false');
  }
}

final railCollapsedProvider = NotifierProvider<RailCollapsedNotifier, bool>(() {
  return RailCollapsedNotifier();
});

// ---------------------------------------------------------------------------
// Statistics — Event Providers + GlobalStats
// ---------------------------------------------------------------------------

/// Computed aggregate statistics across all projects and events.
class GlobalStats {
  final int totalProjects;
  final int inProgressCount;
  final int finishedCount;
  final Duration? avgCompletionTime;

  /// phase name → project count
  final Map<String, int> countPerPhase;

  /// phase name → average days spent in that phase (completed intervals only)
  final Map<String, double> avgDaysPerPhase;

  /// month key "yyyy-MM" → count of projects created that month (last 12 months)
  final Map<String, int> createdPerMonth;

  /// month key "yyyy-MM" → count of projects finished that month (last 12 months)
  final Map<String, int> finishedPerMonth;

  /// projectId → most recent event occurredAt (for sorting by activity)
  final Map<String, DateTime> lastEventPerProject;

  const GlobalStats({
    required this.totalProjects,
    required this.inProgressCount,
    required this.finishedCount,
    required this.avgCompletionTime,
    required this.countPerPhase,
    required this.avgDaysPerPhase,
    required this.createdPerMonth,
    required this.finishedPerMonth,
    required this.lastEventPerProject,
  });

  static const empty = GlobalStats(
    totalProjects: 0,
    inProgressCount: 0,
    finishedCount: 0,
    avgCompletionTime: null,
    countPerPhase: {},
    avgDaysPerPhase: {},
    createdPerMonth: {},
    finishedPerMonth: {},
    lastEventPerProject: {},
  );
}

/// Stream of all events — restarts automatically on profile switch.
final allEventsStreamProvider = StreamProvider<List<ProjectEvent>>((
  ref,
) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield repo.getAllEvents();
  yield* repo.watchEvents().map((_) => repo.getAllEvents());
});

/// Events for a specific project (family, parametrized by projectId).
final eventsForProjectProvider = Provider.family<List<ProjectEvent>, String>((
  ref,
  projectId,
) {
  final eventsAsync = ref.watch(allEventsStreamProvider);
  return eventsAsync
          .whenData((events) {
            final filtered =
                events.where((e) => e.projectId == projectId).toList()
                  ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
            return filtered;
          })
          .asData
          ?.value ??
      [];
});

/// Projects sorted by most recent event activity (most active first).
/// Projects with no events are sorted by updatedAt at the end.
final projectsWithRecentActivityProvider = Provider<List<MusicProject>>((ref) {
  final projectsAsync = ref.watch(allProjectsStreamProvider);
  final eventsAsync = ref.watch(allEventsStreamProvider);
  final hideFinished = ref.watch(statsHideFinishedProvider);
  final finishedPhases = ref.watch(finishedPhaseProvider);

  final allProjects = collapseVersionStacks(projectsAsync.asData?.value ?? []);
  final projects = hideFinished
      ? allProjects.where((p) => !finishedPhases.contains(p.status)).toList()
      : allProjects;
  final events = eventsAsync.asData?.value ?? [];

  // Build map projectId → most recent event time
  final lastEvent = <String, DateTime>{};
  for (final e in events) {
    final existing = lastEvent[e.projectId];
    if (existing == null || e.occurredAt.isAfter(existing)) {
      lastEvent[e.projectId] = e.occurredAt;
    }
  }

  final sorted = List<MusicProject>.from(projects)
    ..sort((a, b) {
      final aTime = lastEvent[a.id];
      final bTime = lastEvent[b.id];
      if (aTime == null && bTime == null) {
        return b.updatedAt.compareTo(a.updatedAt);
      }
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
  return sorted;
});

/// Whether the statistics page should exclude finished projects from all computations.
final statsHideFinishedProvider =
    NotifierProvider<StatsHideFinishedNotifier, bool>(
      StatsHideFinishedNotifier.new,
    );

class StatsHideFinishedNotifier extends Notifier<bool> {
  static const _key = 'statsHideFinished';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return false;
  }

  Future<void> _load() async {
    try {
      final box = await Hive.openBox<String>('settings');
      final saved = box.get(_key);
      if (saved != null) state = saved == 'true';
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final box = await Hive.openBox<String>('settings');
      await box.put(_key, state.toString());
    } catch (_) {}
  }
}

/// Fully computed global statistics derived from projects + events.
final globalStatsProvider = Provider<GlobalStats>((ref) {
  final projectsAsync = ref.watch(allProjectsStreamProvider);
  final eventsAsync = ref.watch(allEventsStreamProvider);
  final hideFinished = ref.watch(statsHideFinishedProvider);
  final finishedPhases = ref.watch(finishedPhaseProvider);

  final allProjects = collapseVersionStacksOrNull(projectsAsync.asData?.value);
  final events = eventsAsync.asData?.value;
  if (allProjects == null || events == null) return GlobalStats.empty;

  final projects = hideFinished
      ? allProjects.where((p) => !finishedPhases.contains(p.status)).toList()
      : allProjects;

  // Basic counts
  final total = projects.length;
  final finished = projects
      .where((p) => finishedPhases.contains(p.status))
      .toList();
  final inProgress = projects
      .where((p) => !finishedPhases.contains(p.status))
      .toList();

  // Average completion time (from model field, only for finished projects)
  Duration? avgCompletion;
  final completionTimes = finished
      .map((p) => p.timeToCompletion(finishedPhases))
      .whereType<Duration>()
      .toList();
  if (completionTimes.isNotEmpty) {
    final totalMs = completionTimes.fold<int>(
      0,
      (sum, d) => sum + d.inMilliseconds,
    );
    avgCompletion = Duration(milliseconds: totalMs ~/ completionTimes.length);
  }

  // Count per phase
  final phases = ref.watch(customPhasesProvider);
  final countPerPhase = <String, int>{for (final ph in phases) ph: 0};
  for (final p in projects) {
    final ph = p.status;
    countPerPhase[ph] = (countPerPhase[ph] ?? 0) + 1;
  }

  // Average days per phase from status_change event log
  // For each project: iterate consecutive status_change events sorted asc.
  // The time spent in phase X = time between entering X and leaving X.
  final daysPerPhase = <String, List<int>>{};
  final statusEventsByProject = <String, List<ProjectEvent>>{};
  for (final e in events) {
    if (e.eventType == ProjectEvent.statusChange) {
      statusEventsByProject.putIfAbsent(e.projectId, () => []).add(e);
    }
  }
  for (final evList in statusEventsByProject.values) {
    evList.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    for (int i = 0; i < evList.length - 1; i++) {
      try {
        final payload =
            jsonDecode(evList[i].payload ?? '{}') as Map<String, dynamic>;
        final phaseEntered = payload['to'] as String?;
        if (phaseEntered == null) continue;
        final days = evList[i + 1].occurredAt
            .difference(evList[i].occurredAt)
            .inDays;
        daysPerPhase.putIfAbsent(phaseEntered, () => []).add(days);
      } catch (_) {
        // Malformed payload — skip
      }
    }
  }
  final avgDaysPerPhase = <String, double>{};
  daysPerPhase.forEach((phase, daysList) {
    avgDaysPerPhase[phase] =
        daysList.fold<int>(0, (sum, d) => sum + d) / daysList.length;
  });

  // Productivity: projects created / finished per month (last 12 months)
  final now = DateTime.now();
  final createdPerMonth = <String, int>{};
  final finishedPerMonth = <String, int>{};
  for (int i = 11; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    createdPerMonth[key] = 0;
    finishedPerMonth[key] = 0;
  }
  for (final p in projects) {
    final key =
        '${p.createdAt.year}-${p.createdAt.month.toString().padLeft(2, '0')}';
    if (createdPerMonth.containsKey(key)) {
      createdPerMonth[key] = createdPerMonth[key]! + 1;
    }
    if (p.status == 'Finished') {
      final finKey =
          '${p.updatedAt.year}-${p.updatedAt.month.toString().padLeft(2, '0')}';
      if (finishedPerMonth.containsKey(finKey)) {
        finishedPerMonth[finKey] = finishedPerMonth[finKey]! + 1;
      }
    }
  }

  // Last event per project map (for projectsWithRecentActivityProvider)
  final lastEventPerProject = <String, DateTime>{};
  for (final e in events) {
    final existing = lastEventPerProject[e.projectId];
    if (existing == null || e.occurredAt.isAfter(existing)) {
      lastEventPerProject[e.projectId] = e.occurredAt;
    }
  }

  return GlobalStats(
    totalProjects: total,
    inProgressCount: inProgress.length,
    finishedCount: finished.length,
    avgCompletionTime: avgCompletion,
    countPerPhase: countPerPhase,
    avgDaysPerPhase: avgDaysPerPhase,
    createdPerMonth: createdPerMonth,
    finishedPerMonth: finishedPerMonth,
    lastEventPerProject: lastEventPerProject,
  );
});

/// Search text within the Statistics tab's project history list.
class StatisticsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String text) => state = text;
  void clear() => state = '';
}

final statisticsSearchProvider =
    NotifierProvider<StatisticsSearchNotifier, String>(
      StatisticsSearchNotifier.new,
    );

class QueueSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String text) => state = text;
  void clear() => state = '';
}

final queueSearchProvider = NotifierProvider<QueueSearchNotifier, String>(
  QueueSearchNotifier.new,
);

// ─── Desktop embedded player ──────────────────────────────────────────────────

/// Carries the project and fully-resolved file path to play in the bottom bar.
/// A new [generation] number is assigned on each play request so that
/// [ValueKey(request.generation)] forces a fresh widget state per track.
class DesktopPlayerRequest {
  final MusicProject project;
  final String resolvedPath;
  final int generation;

  /// True when the track is playing as part of the music-player queue.
  /// False for single-track previews (projects list, player bar quick-play).
  final bool isQueuedPlayback;

  /// Where to start playing, for a track opened at a specific point — jumping
  /// to a project marker on a project that isn't loaded yet. It has to travel
  /// with the request rather than being a seek sent straight afterwards,
  /// because the player bar doesn't exist yet when the request is made.
  final Duration? startAt;

  const DesktopPlayerRequest({
    required this.project,
    required this.resolvedPath,
    required this.generation,
    this.isQueuedPlayback = false,
    this.startAt,
  });
}

class DesktopPlayerNotifier extends Notifier<DesktopPlayerRequest?> {
  @override
  DesktopPlayerRequest? build() => null;

  void play(
    MusicProject project,
    String resolvedPath, {
    bool isQueuedPlayback = false,
    Duration? startAt,
  }) {
    final gen = (state?.generation ?? 0) + 1;
    state = DesktopPlayerRequest(
      project: project,
      resolvedPath: resolvedPath,
      generation: gen,
      isQueuedPlayback: isQueuedPlayback,
      startAt: startAt,
    );
  }

  void close() => state = null;
}

final desktopPlayerProvider =
    NotifierProvider<DesktopPlayerNotifier, DesktopPlayerRequest?>(
      DesktopPlayerNotifier.new,
    );

/// True while the desktop player is actively playing (false when paused/stopped).
class DesktopIsPlayingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final desktopIsPlayingProvider =
    NotifierProvider<DesktopIsPlayingNotifier, bool>(
      DesktopIsPlayingNotifier.new,
    );

/// What the Windows taskbar thumbnail toolbar should show, derived from the
/// desktop preview player.
///
/// Deliberately a single derived provider rather than two listeners on
/// [desktopPlayerProvider] and [desktopIsPlayingProvider]: those two change
/// together on every play/pause and every track switch, so listening to both
/// fired the native shell call twice per user action. `Provider` only notifies
/// when the computed value actually differs, which collapses that to one.
/// See issue #119.
final thumbnailToolbarStateProvider = Provider<ThumbnailToolbarState>((ref) {
  final request = ref.watch(desktopPlayerProvider);
  final isPlaying = ref.watch(desktopIsPlayingProvider);
  return ThumbnailToolbarState(visible: request != null, isPlaying: isPlaying);
});

/// Live playback position of the desktop player's current track, kept in
/// sync by _DesktopPlayerBarState. Lets other widgets that don't own the
/// player (e.g. the music player's per-project task list) read the current
/// timestamp to stamp new tasks when adding one for the track that's
/// actually playing.
class DesktopPlayerPositionNotifier extends Notifier<Duration> {
  @override
  Duration build() => Duration.zero;
  void set(Duration value) => state = value;
}

final desktopPlayerPositionProvider =
    NotifierProvider<DesktopPlayerPositionNotifier, Duration>(
      DesktopPlayerPositionNotifier.new,
    );

/// Bumped to ask whoever owns the desktop player's AudioPlayer (currently
/// _DesktopPlayerBarState) to toggle play/pause on the current track, from
/// UI that doesn't have direct access to that widget's state — e.g. the
/// play button on a project row when that row's track is already loaded.
class DesktopPlayerToggleNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final desktopPlayerToggleRequestProvider =
    NotifierProvider<DesktopPlayerToggleNotifier, int>(
      DesktopPlayerToggleNotifier.new,
    );

/// A request to jump the desktop player to an absolute position in the track
/// it already has loaded — sent by the project marker lists, which live on the
/// project detail page and in the music player's detail pane and so have no
/// access to the player bar's `AudioPlayer`.
///
/// [generation] rather than position alone, so that clicking the same marker
/// twice is two distinguishable requests.
class DesktopPlayerSeekRequest {
  const DesktopPlayerSeekRequest({
    required this.position,
    required this.generation,
  });

  final Duration position;
  final int generation;
}

class DesktopPlayerSeekNotifier extends Notifier<DesktopPlayerSeekRequest?> {
  @override
  DesktopPlayerSeekRequest? build() => null;

  void seekTo(Duration position) {
    state = DesktopPlayerSeekRequest(
      position: position,
      generation: (state?.generation ?? 0) + 1,
    );
  }

  void clear() => state = null;
}

final desktopPlayerSeekRequestProvider =
    NotifierProvider<DesktopPlayerSeekNotifier, DesktopPlayerSeekRequest?>(
      DesktopPlayerSeekNotifier.new,
    );

/// Incremented each time the desktop player finishes a track naturally.
/// Music player listens to this to trigger queue auto-advance.
class DesktopPlayerCompletedNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state++;
}

final desktopPlayerCompletedProvider =
    NotifierProvider<DesktopPlayerCompletedNotifier, int>(
      DesktopPlayerCompletedNotifier.new,
    );

// ─── Queue navigation (prev / next from bottom player bar) ────────────────────

/// Callbacks registered by [MusicPlayerPage] so [_DesktopPlayerBar] can
/// trigger previous/next track navigation without coupling the two widgets.
class QueueNavigationNotifier
    extends Notifier<({void Function()? playNext, void Function()? playPrev})> {
  @override
  ({void Function()? playNext, void Function()? playPrev}) build() =>
      (playNext: null, playPrev: null);

  void register({
    required void Function() playNext,
    required void Function() playPrev,
  }) {
    state = (playNext: playNext, playPrev: playPrev);
  }

  void unregister() => state = (playNext: null, playPrev: null);
}

final queueNavigationProvider =
    NotifierProvider<
      QueueNavigationNotifier,
      ({void Function()? playNext, void Function()? playPrev})
    >(QueueNavigationNotifier.new);

// ─── Waveform peaks cache ─────────────────────────────────────────────────────

/// In-memory cache: resolved file path → extracted [WaveformPeaks].
/// Survives widget rebuilds and navigation so peaks are never re-extracted for
/// the same file within a single app session.
class WaveformCacheNotifier extends Notifier<Map<String, WaveformPeaks>> {
  /// Source-file mtime (µs since epoch) recorded when each entry was cached.
  /// Used to detect files that have been overwritten with new content.
  final Map<String, int> _mtimes = {};

  @override
  Map<String, WaveformPeaks> build() => {};

  WaveformPeaks? get(String path) => state[path];

  void put(String path, WaveformPeaks peaks) {
    try {
      _mtimes[path] = File(path).statSync().modified.microsecondsSinceEpoch;
    } catch (_) {}
    state = {...state, path: peaks};
    WaveformDiskCache.save(path, peaks); // fire-and-forget
  }

  /// Returns cached peaks (memory → disk → fresh extraction), storing the
  /// result so subsequent calls for the same path are instant.
  ///
  /// [onStale] is called synchronously if the memory-cached entry is found to
  /// be stale (source file modified since caching). Use it to clear local
  /// peak state and show a "refreshing" notification before re-extraction begins.
  Future<WaveformPeaks?> getOrExtract(
    String path, {
    VoidCallback? onStale,
  }) async {
    final mem = state[path];
    if (mem != null) {
      // Cheap stat to detect files overwritten with new content at the same path.
      bool stale = false;
      try {
        final currentMtime = File(
          path,
        ).statSync().modified.microsecondsSinceEpoch;
        stale = currentMtime != _mtimes[path];
      } catch (_) {
        return mem; // File inaccessible — return cached data as-is.
      }
      if (!stale) return mem;
      // Evict stale entry and fall through to re-extract.
      onStale?.call();
      state = Map.of(state)..remove(path);
      _mtimes.remove(path);
    }

    final disk = await WaveformDiskCache.load(path);
    if (disk != null) {
      try {
        _mtimes[path] = File(path).statSync().modified.microsecondsSinceEpoch;
      } catch (_) {}
      state = {...state, path: disk};
      return disk;
    }

    final peaks = await AudioAnalysisService.extractWaveformPeaks(path);
    if (peaks != null) put(path, peaks);
    return peaks;
  }
}

final waveformCacheProvider =
    NotifierProvider<WaveformCacheNotifier, Map<String, WaveformPeaks>>(
      WaveformCacheNotifier.new,
    );

// ─── Waveform rendering style ─────────────────────────────────────────────────

/// Which waveform rendering the preview players use.
///
/// Stored in the same device-local `settings` box as the theme: it describes
/// how this machine draws, so it is deliberately not synced or backed up.
class WaveformStyleNotifier extends Notifier<WaveformStyle> {
  static const _boxKey = 'waveformStyle';

  @override
  WaveformStyle build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return WaveformStyle.detailed;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      final saved = box.get(_boxKey);
      if (saved == null || saved.isEmpty) return;
      state = WaveformStyle.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => WaveformStyle.detailed,
      );
    } catch (_) {
      // Keep the default if the box cannot be read.
    }
  }

  Future<void> set(WaveformStyle style) async {
    state = style;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      await box.put(_boxKey, style.name);
    } catch (e) {
      debugPrint('[WaveformStyle] failed to save: $e');
    }
  }
}

final waveformStyleProvider =
    NotifierProvider<WaveformStyleNotifier, WaveformStyle>(
      WaveformStyleNotifier.new,
    );

// ─── Project detail page layout ───────────────────────────────────────────────

/// Whether the project detail page shows one long scroll or a nav rail with
/// one section at a time.
///
/// Device-local, in the same `settings` box as the theme and waveform style:
/// it is a preference about this machine's screen, not project data, so it is
/// deliberately not synced or backed up.
class ProjectDetailLayoutNotifier extends Notifier<ProjectDetailLayout> {
  static const _boxKey = 'projectDetailLayout';

  @override
  ProjectDetailLayout build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return ProjectDetailLayout.classic;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      final saved = box.get(_boxKey);
      if (saved == null || saved.isEmpty) return;
      state = ProjectDetailLayout.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ProjectDetailLayout.classic,
      );
    } catch (_) {
      // Keep the default if the box cannot be read.
    }
  }

  Future<void> set(ProjectDetailLayout layout) async {
    state = layout;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      await box.put(_boxKey, layout.name);
    } catch (e) {
      debugPrint('[ProjectDetailLayout] failed to save: $e');
    }
  }
}

final projectDetailLayoutProvider =
    NotifierProvider<ProjectDetailLayoutNotifier, ProjectDetailLayout>(
      ProjectDetailLayoutNotifier.new,
    );

/// Whether the waveform draws left and right as separate lanes.
///
/// Off by default: on a finished master the two channels correlate above 0.93,
/// so two lanes redraw the same shape at half the vertical resolution. It
/// earns its place on raw session recordings and stems, where the channels
/// genuinely carry different content — hence a per-user toggle rather than
/// always-on. Device-local, like [WaveformStyleNotifier].
class WaveformStereoNotifier extends Notifier<bool> {
  static const _boxKey = 'waveformStereo';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return false;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      final saved = box.get(_boxKey);
      if (saved == null || saved.isEmpty) return;
      state = saved == 'true';
    } catch (_) {
      // Keep the default if the box cannot be read.
    }
  }

  Future<void> set(bool dual) async {
    state = dual;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      await box.put(_boxKey, dual.toString());
    } catch (e) {
      debugPrint('[WaveformStereo] failed to save: $e');
    }
  }
}

final waveformStereoProvider =
    NotifierProvider<WaveformStereoNotifier, bool>(WaveformStereoNotifier.new);

// ---------------------------------------------------------------------------
// Mobile Preview Player (global singleton — persists across navigation)
// ---------------------------------------------------------------------------

enum PlaybackMode { normal, repeatOne, repeatAll, shuffle }

class MobilePlayerState {
  final MusicProject? currentProject;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<MusicProject> queue;
  final int queueIndex;
  final PlaybackMode playbackMode;

  const MobilePlayerState({
    this.currentProject,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.queueIndex = 0,
    this.playbackMode = PlaybackMode.normal,
  });

  bool get hasTrack => currentProject != null;

  String? get effectivePath =>
      currentProject?.previewSongPath?.isNotEmpty == true
      ? currentProject!.previewSongPath
      : currentProject?.previewSongAutoPath;

  MobilePlayerState copyWith({
    MusicProject? currentProject,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<MusicProject>? queue,
    int? queueIndex,
    PlaybackMode? playbackMode,
  }) => MobilePlayerState(
    currentProject: currentProject ?? this.currentProject,
    isPlaying: isPlaying ?? this.isPlaying,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    queue: queue ?? this.queue,
    queueIndex: queueIndex ?? this.queueIndex,
    playbackMode: playbackMode ?? this.playbackMode,
  );
}

// ── helpers ───────────────────────────────────────────────────────────────────

bool get _isAndroid => !kIsWeb && Platform.isAndroid;

/// Setado como true em main.dart quando JustAudioBackground.init() completa.
/// Enquanto false, o player Android usa audioplayers como fallback seguro.
bool _jabInitialized = false;

void markJabInitialized() => _jabInitialized = true;

/// The order in which tracks are visited for [mode]. For shuffle, [current]
/// (if present) is kept first so playback continues from the current track and
/// the rest are randomly permuted; otherwise the natural order is returned
/// unchanged. The result is what drives the player queue, the notification skip
/// buttons, and the swipeable PageView so all three agree.
List<MusicProject> orderedQueueFor(
  List<MusicProject> natural,
  MusicProject? current,
  PlaybackMode mode, {
  Random? random,
}) {
  if (mode != PlaybackMode.shuffle || natural.length <= 1) {
    return List<MusicProject>.of(natural);
  }
  final rng = random ?? Random();
  final rest = natural.where((p) => p.id != current?.id).toList()..shuffle(rng);
  final head = natural.where((p) => p.id == current?.id).toList();
  return [...head, ...rest];
}

/// Next index within an already-ordered queue of [length], or null when at the
/// end in a non-wrapping ([normal]) mode. Because the queue is pre-ordered,
/// "next" is simply the following slot (wrapping for every non-normal mode).
int? nextIndexIn(int length, int current, PlaybackMode mode) {
  if (length <= 0) return null;
  final next = current + 1;
  if (next >= length) return mode == PlaybackMode.normal ? null : 0;
  return next;
}

/// Previous index within an already-ordered queue of [length], or null when at
/// the start in a non-wrapping ([normal]) mode.
int? prevIndexIn(int length, int current, PlaybackMode mode) {
  if (length <= 0) return null;
  final prev = current - 1;
  if (prev < 0) return mode == PlaybackMode.normal ? null : length - 1;
  return prev;
}

class MobilePlayerNotifier extends Notifier<MobilePlayerState> {
  static const _tag = '[MobilePlayer]';

  // Android: just_audio player — background gerenciado pelo just_audio_background.
  ja.AudioPlayer? _jaPlayer;
  ja.ConcatenatingAudioSource? _jaSource;

  // Fila na ordem natural (dashboard). `state.queue` guarda a ordem efetiva de
  // reprodução (idêntica a esta em modo normal, embaralhada em shuffle). Manter
  // a natural permite restaurar a ordem ao desligar o shuffle.
  List<MusicProject> _naturalQueue = [];

  // Cached copy of the app icon used as MediaItem art (shows the logo in the
  // Android media notification). Prepared once, best-effort.
  Uri? _artUri;

  // Subscriptions Android (vivas durante todo o ciclo de vida do notifier).
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<bool>? _jaPlayingSub;
  StreamSubscription<Duration>? _jaPosSub;
  StreamSubscription<Duration?>? _jaDurSub;
  StreamSubscription<ja.PlayerState>? _jaCompleteSub;
  StreamSubscription<ja.PlaybackEvent>? _jaEventSub;

  // Desktop fallback: audioplayers (subscriptions re-criadas por play).
  AudioPlayer? _fallbackPlayer;
  StreamSubscription<PlayerState>? _fbStateSub;
  StreamSubscription<Duration>? _fbPosSub;
  StreamSubscription<Duration>? _fbDurSub;
  StreamSubscription<void>? _fbCompleteSub;

  // Rastreia qual player foi realmente usado no último _play().
  // _jabInitialized pode virar true DEPOIS de _play() ter usado audioplayers,
  // então _useJa não pode depender só de _jabInitialized.
  bool _usingJaPlayer = false;

  @override
  MobilePlayerState build() {
    ref.onDispose(_dispose);
    if (_isAndroid) {
      _jaPlayer = ja.AudioPlayer();
      _attachJaListeners();
      unawaited(_prepareArtUri());
    }
    return const MobilePlayerState();
  }

  /// Copies the bundled app icon into a cache file once, so it can be used as
  /// [MediaItem.artUri] (shows the app logo in the Android media notification).
  Future<void> _prepareArtUri() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'dpm_notification_art.png'));
      if (!await file.exists()) {
        final bytes = await rootBundle.load('app_icon.png');
        await file.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
      }
      _artUri = Uri.file(file.path);
    } catch (e) {
      debugPrint('$_tag failed to prepare notification art: $e');
    }
  }

  // ── Listeners Android ─────────────────────────────────────────────────────

  void _attachJaListeners() {
    final p = _jaPlayer!;
    // ConcatenatingAudioSource avança automaticamente; sincronizamos o estado.
    _indexSub = p.currentIndexStream.listen((idx) {
      if (idx == null) return;
      final q = state.queue;
      if (idx < q.length && idx != state.queueIndex) {
        state = state.copyWith(currentProject: q[idx], queueIndex: idx);
      }
    });
    _jaPlayingSub = p.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    _jaPosSub = p.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _jaDurSub = p.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
    // Toda a fila terminou.
    _jaCompleteSub = p.playerStateStream
        .where((s) => s.processingState == ja.ProcessingState.completed)
        .listen((_) {
          state = state.copyWith(isPlaying: false, position: Duration.zero);
        });
    // Erros do pipeline (fonte inválida, decode) chegam aqui; sem tratá-los, o
    // BehaviorSubject fecha, playingStream para de emitir e isPlaying trava.
    _jaEventSub = p.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        debugPrint('$_tag playback error: $e');
        state = state.copyWith(isPlaying: false);
      },
    );
  }

  // ── Listeners Desktop ─────────────────────────────────────────────────────

  void _cancelFallbackSubs() {
    _fbStateSub?.cancel();
    _fbPosSub?.cancel();
    _fbDurSub?.cancel();
    _fbCompleteSub?.cancel();
  }

  void _attachFallbackListeners() {
    final p = _fallbackPlayer!;
    _fbStateSub = p.onPlayerStateChanged.listen((s) {
      state = state.copyWith(isPlaying: s == PlayerState.playing);
    });
    _fbPosSub = p.onPositionChanged.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _fbDurSub = p.onDurationChanged.listen((dur) {
      state = state.copyWith(duration: dur);
    });
    _fbCompleteSub = p.onPlayerComplete.listen((_) {
      state = state.copyWith(isPlaying: false, position: Duration.zero);
      _autoAdvanceFallback();
    });
  }

  void _autoAdvanceFallback() {
    final q = state.queue;
    if (q.isEmpty) return;

    // The queue is already in play order (shuffled or not), so advancing is the
    // next slot; repeat-one stays on the same track.
    final nextIdx = state.playbackMode == PlaybackMode.repeatOne
        ? state.queueIndex
        : nextIndexIn(q.length, state.queueIndex, state.playbackMode);
    if (nextIdx == null) return;

    final next = q[nextIdx];
    final path = resolvedPreviewPath(next);
    if (path.isNotEmpty) _play(next, path, q, nextIdx);
  }

  // ── Play ──────────────────────────────────────────────────────────────────

  Future<void> playProject(
    MusicProject project,
    String path, {
    List<MusicProject>? queue,
    int? queueIndex,
  }) async {
    final natural = queue ?? [project];
    _naturalQueue = natural;
    // Order the queue for the current mode (shuffled or not) up front, so the
    // queue we hand the player and the PageView is already the play order.
    final ordered = orderedQueueFor(natural, project, state.playbackMode);
    var idx = ordered.indexWhere((p) => p.id == project.id);
    if (idx < 0) {
      idx = ordered.isEmpty
          ? 0
          : (queueIndex ?? 0).clamp(0, ordered.length - 1);
    }
    await _play(project, path, ordered, idx);
  }

  ja.AudioSource _toAudioSource(MusicProject project) {
    final trackPath = resolvedPreviewPath(project);
    return ja.AudioSource.uri(
      Uri.file(trackPath),
      tag: MediaItem(
        id: trackPath,
        title: project.displayName,
        artist: '',
        artUri: _artUri,
      ),
    );
  }

  Future<void> _play(
    MusicProject project,
    String path,
    List<MusicProject> queue,
    int queueIndex,
  ) async {
    debugPrint('$_tag playing ${project.displayName} at $path');
    // Preservar o modo de playback — o reset de estado não deve apagar a
    // escolha do usuário (repeat/shuffle) ao trocar de faixa.
    final savedMode = state.playbackMode;
    state = MobilePlayerState(
      currentProject: project,
      queue: queue,
      queueIndex: queueIndex,
      playbackMode: savedMode,
    );

    if (_isAndroid && _jabInitialized) {
      _usingJaPlayer = true;
      // ConcatenatingAudioSource para que skip prev/next da notificação funcione.
      // A fila já vem na ordem de reprodução (ver playProject/_reorderForMode),
      // então o avanço automático e os botões da notificação seguem o shuffle.
      final sources = queue.map(_toAudioSource).toList();
      _jaSource = ja.ConcatenatingAudioSource(children: sources);
      try {
        await _jaPlayer!.setAudioSource(
          _jaSource!,
          initialIndex: queueIndex,
          initialPosition: Duration.zero,
        );
        await _applyPlaybackMode(savedMode);
        await _jaPlayer!.play();
      } catch (e) {
        // Don't leave the button stuck on "pause" if the source failed to load.
        debugPrint('$_tag failed to start playback: $e');
        state = state.copyWith(isPlaying: false);
      }
    } else {
      _usingJaPlayer = false;
      _cancelFallbackSubs();
      _fallbackPlayer ??= AudioPlayer();
      _attachFallbackListeners();
      await _fallbackPlayer!.stop();
      await _fallbackPlayer!.play(DeviceFileSource(path));
    }
  }

  // ── Controles ─────────────────────────────────────────────────────────────

  bool get _useJa => _usingJaPlayer;

  Future<void> togglePlayPause() async {
    if (!state.hasTrack) return;
    if (_useJa) {
      // Decide off the *live* player state, not the cached `state.isPlaying`.
      // If a stream hiccup left `isPlaying` stale, the cached path could call
      // pause() on an already-stopped player (button appears dead), so read the
      // player directly.
      final playing = _jaPlayer?.playing ?? state.isPlaying;
      if (playing) {
        await _jaPlayer?.pause();
      } else {
        await _jaPlayer?.play();
      }
    } else {
      if (state.isPlaying) {
        await _fallbackPlayer?.pause();
      } else {
        await _fallbackPlayer?.resume();
      }
    }
  }

  Future<void> pause() async {
    if (_useJa) {
      await _jaPlayer?.pause();
    } else {
      await _fallbackPlayer?.pause();
    }
  }

  Future<void> seek(Duration position) async {
    if (_useJa) {
      await _jaPlayer?.seek(position);
    } else {
      await _fallbackPlayer?.seek(position);
    }
  }

  Future<void> playNext() async {
    final target = nextIndexIn(
      state.queue.length,
      state.queueIndex,
      state.playbackMode,
    );
    if (target != null) await playAtIndex(target);
  }

  Future<void> playPrev() async {
    final target = prevIndexIn(
      state.queue.length,
      state.queueIndex,
      state.playbackMode,
    );
    if (target != null) await playAtIndex(target);
  }

  /// Jumps to [index] within the current (already-ordered) `state.queue`. Used
  /// by next/prev, the mini-player swipe, and the full-screen PageView swipe so
  /// they all move through the same order — and therefore respect shuffle.
  Future<void> playAtIndex(int index) async {
    final q = state.queue;
    if (index < 0 || index >= q.length) return;
    if (_useJa) {
      try {
        // The concat is already in play order, so seeking by index follows the
        // shuffle order without rebuilding the source.
        await _jaPlayer?.seek(Duration.zero, index: index);
        await _jaPlayer?.play();
      } catch (e) {
        debugPrint('$_tag failed to seek to index $index: $e');
        state = state.copyWith(isPlaying: false);
      }
    } else {
      final next = q[index];
      final path = resolvedPreviewPath(next);
      if (path.isNotEmpty) await _play(next, path, q, index);
    }
  }

  /// Troca a fonte sem mudar projeto/fila — usado pelo botão mono.
  Future<void> switchSource(String path, Duration seekTo) async {
    if (_useJa) {
      final tag = MediaItem(
        id: path,
        title: state.currentProject?.displayName ?? '',
        artist: '',
        artUri: _artUri,
      );
      await _jaPlayer?.setAudioSource(
        ja.AudioSource.uri(Uri.file(path), tag: tag),
      );
      if (seekTo > Duration.zero) await _jaPlayer?.seek(seekTo);
      await _jaPlayer?.play();
    } else {
      _cancelFallbackSubs();
      _attachFallbackListeners();
      await _fallbackPlayer?.stop();
      await _fallbackPlayer?.play(
        DeviceFileSource(path),
        position: seekTo > Duration.zero ? seekTo : null,
      );
    }
  }

  Future<void> setPlaybackMode(PlaybackMode mode) async {
    final wasShuffle = state.playbackMode == PlaybackMode.shuffle;
    final nowShuffle = mode == PlaybackMode.shuffle;
    if (wasShuffle != nowShuffle &&
        _naturalQueue.length > 1 &&
        state.currentProject != null) {
      // Turning shuffle on/off changes the play order — rebuild the ordered
      // queue (keeping the current track playing) so swipes and skips follow
      // the new order right away.
      await _reorderForMode(mode);
    } else {
      state = state.copyWith(playbackMode: mode);
      if (_useJa) await _applyPlaybackMode(mode);
    }
  }

  Future<void> _reorderForMode(PlaybackMode mode) async {
    final current = state.currentProject!;
    final resumePos = state.position;
    final wasPlaying = state.isPlaying;
    final ordered = orderedQueueFor(_naturalQueue, current, mode);
    var idx = ordered.indexWhere((p) => p.id == current.id);
    if (idx < 0) idx = 0;
    state = state.copyWith(queue: ordered, queueIndex: idx, playbackMode: mode);
    if (_useJa) {
      try {
        _jaSource = ja.ConcatenatingAudioSource(
          children: ordered.map(_toAudioSource).toList(),
        );
        await _jaPlayer!.setAudioSource(
          _jaSource!,
          initialIndex: idx,
          initialPosition: resumePos,
        );
        await _applyPlaybackMode(mode);
        if (wasPlaying) await _jaPlayer!.play();
      } catch (e) {
        debugPrint('$_tag failed to reorder queue: $e');
        state = state.copyWith(isPlaying: false);
      }
    }
  }

  Future<void> cyclePlaybackMode() async {
    final next = switch (state.playbackMode) {
      PlaybackMode.normal => PlaybackMode.repeatOne,
      PlaybackMode.repeatOne => PlaybackMode.repeatAll,
      PlaybackMode.repeatAll => PlaybackMode.normal,
      PlaybackMode.shuffle => PlaybackMode.normal,
    };
    await setPlaybackMode(next);
  }

  Future<void> _applyPlaybackMode(PlaybackMode mode) async {
    // Ordering is handled by _naturalQueue/orderedQueueFor, so just_audio's own
    // shuffle stays OFF; here we only map the loop behaviour.
    await _jaPlayer?.setShuffleModeEnabled(false);
    switch (mode) {
      case PlaybackMode.normal:
        await _jaPlayer?.setLoopMode(ja.LoopMode.off);
      case PlaybackMode.repeatOne:
        await _jaPlayer?.setLoopMode(ja.LoopMode.one);
      case PlaybackMode.repeatAll:
        await _jaPlayer?.setLoopMode(ja.LoopMode.all);
      case PlaybackMode.shuffle:
        // Children are pre-shuffled; loop the shuffled set so it keeps cycling.
        await _jaPlayer?.setLoopMode(ja.LoopMode.all);
    }
  }

  Future<void> stop() async {
    if (_useJa) {
      await _jaPlayer?.stop();
    } else {
      _cancelFallbackSubs();
      await _fallbackPlayer?.stop();
    }
    state = const MobilePlayerState();
  }

  void _dispose() {
    _indexSub?.cancel();
    _jaPlayingSub?.cancel();
    _jaPosSub?.cancel();
    _jaDurSub?.cancel();
    _jaCompleteSub?.cancel();
    _jaEventSub?.cancel();
    _cancelFallbackSubs();
    _jaPlayer?.dispose();
    _fallbackPlayer?.dispose();
  }
}

final mobilePlayerProvider =
    NotifierProvider<MobilePlayerNotifier, MobilePlayerState>(
      MobilePlayerNotifier.new,
    );

/// The local file path the mobile player would use for [p], or '' if none.
String resolvedPreviewPath(MusicProject p) =>
    p.previewSongPath?.isNotEmpty == true
    ? p.previewSongPath!
    : (p.previewSongAutoPath ?? '');

/// Whether [p] has a preview that the mobile player can actually load. Excludes
/// empty paths and `drive://` placeholders (not yet downloaded) — feeding those
/// into the just_audio queue wedges playback, leaving play/pause stuck.
bool isPlayablePreview(MusicProject p) {
  final path = resolvedPreviewPath(p);
  return path.isNotEmpty && !path.startsWith('drive://');
}

/// Projects with a playable preview song, in the same order as the current
/// dashboard list.
final mobilePlayerQueueProvider = Provider<List<MusicProject>>((ref) {
  final projects = ref.watch(projectsProvider);
  return projects.where(isPlayablePreview).toList();
});

// ---------------------------------------------------------------------------
// Session Mode (subscribe-before-launch vs direct launch)
// ---------------------------------------------------------------------------

class SessionModeNotifier extends Notifier<bool> {
  static const _key = 'sessionMode';

  @override
  bool build() {
    _load();
    return false; // default: direct launch
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved != null) state = saved == 'true';
  }

  Future<void> set(bool value) async {
    state = value;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, value.toString());
  }

  Future<void> toggle() async => set(!state);
}

final sessionModeProvider = NotifierProvider<SessionModeNotifier, bool>(
  SessionModeNotifier.new,
);

// ---------------------------------------------------------------------------
// Session Suggestions Enabled
// ---------------------------------------------------------------------------

class SuggestionsEnabledNotifier extends Notifier<bool> {
  static const _key = 'suggestionsEnabled';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved != null) state = saved == 'true';
  }

  Future<void> set(bool value) async {
    state = value;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, value.toString());
  }
}

final suggestionsEnabledProvider =
    NotifierProvider<SuggestionsEnabledNotifier, bool>(
      SuggestionsEnabledNotifier.new,
    );

// ---------------------------------------------------------------------------
// Smart Folder Sort Exclusion
// ---------------------------------------------------------------------------

/// Whether smart-folder group rows should be excluded from the Projects
/// grid's active column sort — folders keep their existing top-level order
/// and only individual project rows (plus each folder's own contents) get
/// reordered. Off by default: this changes a long-standing interleaved-sort
/// behavior, so it ships opt-in until confirmed to work well across
/// different smart-folder workflows.
class ExcludeSmartFoldersFromSortNotifier extends Notifier<bool> {
  static const _key = 'excludeSmartFoldersFromSort';

  // Read synchronously (the `settings` box is already open by the time any
  // provider builds — see main.dart) rather than via a post-frame _load(),
  // since this value feeds the Projects grid's remount key: an async load
  // that flips the value a frame after cold start would make the grid
  // remount again almost immediately, visibly flickering.
  @override
  bool build() {
    try {
      final saved = Hive.box<String>('settings').get(_key);
      if (saved != null) return saved == 'true';
    } catch (_) {
      // Box not open yet on the very first frame — falls back to the
      // opt-in default (false) rather than crash.
    }
    return false;
  }

  Future<void> set(bool value) async {
    state = value;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, value.toString());
  }
}

final excludeSmartFoldersFromSortProvider =
    NotifierProvider<ExcludeSmartFoldersFromSortNotifier, bool>(
      ExcludeSmartFoldersFromSortNotifier.new,
    );

// ---------------------------------------------------------------------------
// Smart Folder Merge-by-Name
// ---------------------------------------------------------------------------

/// Whether top-level smart-folder groups that share the same folder name
/// across different scan roots (e.g. a "0-Ideas" folder under both a Cubase
/// and a Studio One root) should be merged into a single group in the
/// Projects table instead of appearing as separate, identically-labeled
/// groups. Off by default: this changes long-standing grouping behavior, so
/// it ships opt-in like excludeSmartFoldersFromSortProvider above.
class MergeSmartFoldersByNameNotifier extends Notifier<bool> {
  static const _key = 'mergeSmartFoldersByName';

  // Same synchronous-read rationale as ExcludeSmartFoldersFromSortNotifier:
  // this value feeds the Projects grid's remount key.
  @override
  bool build() {
    try {
      final saved = Hive.box<String>('settings').get(_key);
      if (saved != null) return saved == 'true';
    } catch (_) {
      // Box not open yet on the very first frame — falls back to the
      // opt-in default (false) rather than crash.
    }
    return false;
  }

  Future<void> set(bool value) async {
    state = value;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, value.toString());
  }
}

final mergeSmartFoldersByNameProvider =
    NotifierProvider<MergeSmartFoldersByNameNotifier, bool>(
      MergeSmartFoldersByNameNotifier.new,
    );

// ---------------------------------------------------------------------------
// Always Show Smart Folders
// ---------------------------------------------------------------------------

/// Whether a smart-folder group should always render as its own row in the
/// Projects table, even when only one of its projects is currently visible
/// (e.g. after a search or DAW-type filter narrows things down). Off by
/// default: normally a folder with just one currently-visible project
/// demotes to a plain flat row instead of wrapping it in a group — see
/// smartFolderShouldRenderAsGroup() in dashboard_page.dart. Off by default,
/// ships opt-in like the other smart-folder settings above.
class AlwaysShowSmartFoldersNotifier extends Notifier<bool> {
  static const _key = 'alwaysShowSmartFolders';

  // Same synchronous-read rationale as ExcludeSmartFoldersFromSortNotifier:
  // this value feeds the Projects grid's remount key.
  @override
  bool build() {
    try {
      final saved = Hive.box<String>('settings').get(_key);
      if (saved != null) return saved == 'true';
    } catch (_) {
      // Box not open yet on the very first frame — falls back to the
      // opt-in default (false) rather than crash.
    }
    return false;
  }

  Future<void> set(bool value) async {
    state = value;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, value.toString());
  }
}

final alwaysShowSmartFoldersProvider =
    NotifierProvider<AlwaysShowSmartFoldersNotifier, bool>(
      AlwaysShowSmartFoldersNotifier.new,
    );

// ---------------------------------------------------------------------------
// Work Timer Notification Settings
// ---------------------------------------------------------------------------

class WorkTimerNotifEnabledNotifier extends Notifier<bool> {
  static const _key = 'workTimerNotifEnabled';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved != null) state = saved == 'true';
  }

  Future<void> set(bool value) async {
    state = value;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, value.toString());
  }
}

final workTimerNotifEnabledProvider =
    NotifierProvider<WorkTimerNotifEnabledNotifier, bool>(
      WorkTimerNotifEnabledNotifier.new,
    );

class WorkTimerNotifIntervalNotifier extends Notifier<int> {
  // Stored and exposed in SECONDS. Default: 3600 (60 minutes).
  // Legacy values ≤ 120 are treated as minutes and migrated on first load.
  static const _key = 'workTimerNotifIntervalSecs';

  @override
  int build() {
    _load();
    return 3600;
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>('settings');
    // Try new seconds key first, then fall back to legacy minutes key.
    final savedSecs = box.get(_key);
    if (savedSecs != null) {
      state = int.tryParse(savedSecs) ?? 3600;
    } else {
      final legacyMins = box.get('workTimerNotifInterval');
      if (legacyMins != null) {
        final mins = int.tryParse(legacyMins) ?? 60;
        state = mins * 60;
      }
    }
  }

  Future<void> set(int seconds) async {
    state = seconds;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, seconds.toString());
  }
}

final workTimerNotifIntervalProvider =
    NotifierProvider<WorkTimerNotifIntervalNotifier, int>(
      WorkTimerNotifIntervalNotifier.new,
    );

// ---------------------------------------------------------------------------
// Work Timer — tracks time on the subscribed project, fires notifications
// ---------------------------------------------------------------------------

class WorkTimerNotifier extends Notifier<int> {
  // State = elapsed seconds of active work (0 when idle; frozen while paused).
  Timer? _ticker;
  DateTime? _startTime; // adjusted on resume to exclude paused durations
  DateTime? _pausedAt; // set when paused, null otherwise

  @override
  int build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _ticker = null;
    });

    ref.listen<MusicProject?>(activeProjectProvider, (prev, next) {
      // Only save/restart when the project actually changes (different ID or
      // cleared). Same-ID updates are metadata refreshes — don't touch the timer.
      final projectChanged = next == null || next.id != prev?.id;
      if (prev != null && _startTime != null && projectChanged) {
        _saveSession(prev);
      }
      if (next != null && projectChanged) {
        _start();
      } else if (next == null) {
        _stop();
      }
    });

    // If a project is already subscribed when this provider is first read, start tracking.
    if (ref.read(activeProjectProvider) != null) _start();

    return 0;
  }

  void _start() {
    _ticker?.cancel();
    _startTime = DateTime.now();
    _pausedAt = null;
    ref.read(workTimerPausedProvider.notifier).set(false);
    state = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Call immediately after setting the active project when the session was
  /// already in progress (e.g. resolved from a pending folder). Overrides the
  /// start time so elapsed seconds reflect the original session start rather
  /// than the moment the project was set active.
  void continueFrom(DateTime from) {
    _startTime = from;
    state = DateTime.now().difference(from).inSeconds;
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    _startTime = null;
    _pausedAt = null;
    ref.read(workTimerPausedProvider.notifier).set(false);
    state = 0;
  }

  void pause() {
    if (_startTime == null || _pausedAt != null) return;
    // Freeze the elapsed display at the current second count.
    state = DateTime.now().difference(_startTime!).inSeconds;
    _pausedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = null;
    ref.read(workTimerPausedProvider.notifier).set(true);
  }

  void resume() {
    if (_startTime == null || _pausedAt == null) return;
    // Shift _startTime forward by the pause duration so elapsed seconds
    // remain continuous across pause/resume cycles.
    final pauseDuration = DateTime.now().difference(_pausedAt!);
    _startTime = _startTime!.add(pauseDuration);
    _pausedAt = null;
    ref.read(workTimerPausedProvider.notifier).set(false);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _saveSession(MusicProject project) async {
    final start = _startTime;
    if (start == null) return;
    // Use _pausedAt as the end time if paused; otherwise use now.
    final end = _pausedAt ?? DateTime.now();
    final elapsedSeconds = end.difference(start).inSeconds;
    if (elapsedSeconds <= 0) return;
    final repo = await ref.read(repositoryProvider.future);
    final latest = repo.getById(project.id) ?? project;
    final record = SessionRecord(
      id: start.toIso8601String(),
      startedAt: start,
      endedAt: end,
      durationSeconds: elapsedSeconds,
      phase: latest.status,
    );
    final newSessions = [...latest.sessions, record];
    final updated = latest.copyWith(
      totalWorkSeconds: newSessions.fold<int>(
        0,
        (s, r) => s + r.durationSeconds,
      ),
      sessions: newSessions,
      updatedAt: DateTime.now(),
    );
    repo.updateProject(updated);
  }

  void _tick() {
    if (_startTime == null) return;
    final elapsed = DateTime.now().difference(_startTime!);
    state = elapsed.inSeconds;

    if (MobileUtils.isMobile()) return;

    final enabled = ref.read(workTimerNotifEnabledProvider);
    if (!enabled) return;

    final intervalSeconds = ref.read(workTimerNotifIntervalProvider);
    if (elapsed.inSeconds > 0 && elapsed.inSeconds % intervalSeconds == 0) {
      final project = ref.read(activeProjectProvider);
      if (project != null) {
        final locale = ref.read(localeProvider);
        final l10n = lookupAppLocalizations(locale);
        final h = elapsed.inHours;
        final m = elapsed.inMinutes.remainder(60);
        final s = elapsed.inSeconds.remainder(60);
        final timeStr = h > 0
            ? (m > 0 ? '${h}h ${m}m' : '${h}h')
            : m > 0
            ? (s > 0 ? '${m}m ${s}s' : '${m}m')
            : '${s}s';
        final allProfiles = ref.read(allProfilesProvider).value ?? [];
        final profile = ref.read(currentProfileProvider).value;
        final title = (allProfiles.length > 1 && profile != null)
            ? '${project.displayName} · ${profile.name}'
            : project.displayName;
        DeadlineNotificationService().showWorkTimerNotification(
          title,
          l10n.workTimerNotifBody(timeStr),
        );
      }
    }
  }
}

final workTimerProvider = NotifierProvider<WorkTimerNotifier, int>(
  WorkTimerNotifier.new,
);

/// True while the work-timer is paused (ticker stopped, elapsed frozen).
class WorkTimerPausedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final workTimerPausedProvider = NotifierProvider<WorkTimerPausedNotifier, bool>(
  WorkTimerPausedNotifier.new,
);

// ---------------------------------------------------------------------------
// Last-Modified Color Coding Setting
// Green = Finished status; red gradient = older last-modified date.
// When disabled the column shows plain text color.
// ---------------------------------------------------------------------------
class LastModifiedColorNotifier extends Notifier<bool> {
  static const _key = 'lastModifiedColorEnabled';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return true; // enabled by default
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      final saved = box.get(_key);
      if (saved != null) state = saved == 'true';
    } catch (e) {
      if (kDebugMode) print('Failed to load $_key: $e');
    }
  }

  Future<void> toggle() async {
    state = !state;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      await box.put(_key, state.toString());
    } catch (e) {
      if (kDebugMode) print('Failed to save $_key: $e');
    }
  }
}

final lastModifiedColorProvider =
    NotifierProvider<LastModifiedColorNotifier, bool>(
      LastModifiedColorNotifier.new,
    );

// ── Session idle suggestions panel ──────────────────────────────────────────

class SuggestionsPanelExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final suggestionsPanelExpandedProvider =
    NotifierProvider<SuggestionsPanelExpandedNotifier, bool>(
      SuggestionsPanelExpandedNotifier.new,
    );

class DismissedSuggestionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};
  void dismiss(String id) => state = {...state, id};
  void clear() => state = const {};
}

final dismissedSuggestionsProvider =
    NotifierProvider<DismissedSuggestionsNotifier, Set<String>>(
      DismissedSuggestionsNotifier.new,
    );

// Bumped whenever pending folders are added/removed so the UI rebuilds.
class _PendingFoldersDirtyNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state = state + 1;
}

final pendingFoldersDirtyProvider =
    NotifierProvider<_PendingFoldersDirtyNotifier, int>(
      _PendingFoldersDirtyNotifier.new,
    );

final pendingFoldersProvider = Provider<List<PendingFolder>>((ref) {
  ref.watch(pendingFoldersDirtyProvider);
  final repoAsync = ref.watch(repositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) => repo.getPendingFolders(),
    orElse: () => const [],
  );
});
