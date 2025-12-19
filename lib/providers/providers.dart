import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../utils/app_paths.dart';

import '../models/music_project.dart';
import '../models/scan_root.dart';
import '../models/release.dart';
import '../models/profile.dart';
import '../repository/project_repository.dart';
import '../repository/profile_repository.dart';
import '../services/scanner_service.dart';

// Profile Repository Provider
final profileRepositoryProvider = FutureProvider<ProfileRepository>((ref) async {
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

// Project Repository Provider - depends on ProfileRepository
final repositoryProvider = FutureProvider<ProjectRepository>((ref) async {
  final profileRepo = await ref.watch(profileRepositoryProvider.future);
  return ProjectRepository.init(profileRepo);
});

final rootsWatchProvider = StreamProvider<void>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchRoots().map((_) => null);
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

// scanning state is managed in UI now

class QueryParams {
  final String searchText;
  final bool sortDesc;
  const QueryParams({this.searchText = '', this.sortDesc = true});
  
  // Adiciona o método copyWith para facilitar a atualização
  QueryParams copyWith({
    String? searchText,
    bool? sortDesc,
  }) {
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
final queryParamsNotifierProvider = NotifierProvider<QueryParamsNotifier, QueryParams>(() {
  return QueryParamsNotifier();
});

// Show hidden projects state provider
// 0 = show only visible (default)
// 1 = show all (visible + hidden)
// 2 = show only hidden
class ShowHiddenProjectsNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // Default to showing only visible projects
  }
  
  void setShowAll(bool show) {
    if (show) {
      state = 1; // Show all (visible + hidden)
    } else {
      state = 0; // Show only visible
    }
  }
  
  void setShowOnlyHidden(bool show) {
    if (show) {
      state = 2; // Show only hidden
    } else {
      state = 0; // Show only visible
    }
  }
  
  bool get isShowingAll => state == 1;
  bool get isShowingOnlyHidden => state == 2;
  bool get isShowingVisible => state == 0;
}

final showHiddenProjectsProvider = NotifierProvider<ShowHiddenProjectsNotifier, int>(() {
  return ShowHiddenProjectsNotifier();
});

// REMOVEMOS: projectsWatchProvider (substituído pela reatividade do stream abaixo)

// NOVO PROVIDER CORRIGIDO: Stream que emite a lista bruta de projetos
// Ele usa o novo método watchAllProjects() do repositório (que você precisa garantir que existe)
final allProjectsStreamProvider = StreamProvider<List<MusicProject>>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
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

  // 4. Usa .whenData para acessar a lista quando estiver pronta e aplicar o filtro/ordenação
  return allProjectsAsync.whenData((allProjects) {
    var projects = allProjects;

    // --- Filter out preserved projects (in releases but not in any active scan root) ---
    final releases = releasesAsync.value ?? [];
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }
    
    // Get all active scan root paths (normalized for comparison)
    final activeRootPaths = scanRoots.map((root) {
      final normalized = p.normalize(root.path);
      // Ensure root path ends with separator for proper prefix matching
      return normalized.endsWith(p.separator) ? normalized : normalized + p.separator;
    }).toList();
    
    // Filter out preserved projects: those in releases but not in any active root
    projects = projects.where((project) {
      // If project is not in any release, always show it
      if (!protectedProjectIds.contains(project.id)) {
        return true;
      }
      
      // If project is in a release, check if it's in any active scan root
      final projectPath = p.normalize(project.filePath);
      final isInActiveRoot = activeRootPaths.any((rootPath) {
        // Check if project path starts with the root path
        return projectPath.startsWith(rootPath);
      });
      
      // Only show if it's in an active root (preserved projects not in active roots are hidden)
      return isInActiveRoot;
    }).toList();

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
    
    // --- Aplicação dos Filtros ---
    if (params.searchText.trim().isNotEmpty) {
      final needle = params.searchText.toLowerCase();
      projects = projects.where((p) => p.displayName.toLowerCase().contains(needle)).toList();
    }
    
    // --- Ordenação ---
    // A ordenação é feita pela data de modificação
    projects.sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
    if (params.sortDesc) {
      projects = projects.reversed.toList();
    }
    
    return projects;
  }).when(
    data: (projects) => projects,
    // Garante que a lista não é nula, mesmo carregando ou com erro
    loading: () => const <MusicProject>[], 
    error: (_, __) => const <MusicProject>[],
  );
});

final dateFormatProvider = Provider<DateFormat>((ref) => DateFormat.yMMMd().add_jm());

// Releases Provider
final releasesProvider = StreamProvider<List<Release>>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchAllReleases();
});

// Initial scan state provider
final initialScanStateProvider = NotifierProvider<InitialScanNotifier, bool>(() {
  return InitialScanNotifier();
});

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
final profileSwitchingProvider = NotifierProvider<ProfileSwitchingNotifier, bool>(() {
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

final profileSwitchProvider = NotifierProvider<ProfileSwitchNotifier, String?>(() {
  return ProfileSwitchNotifier();
});

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
      final appDataPath = await getLocalAppDataPath();
      Hive.init(appDataPath);
      final settingsBox = await Hive.openBox<String>('settings');
      final savedLocale = settingsBox.get('locale');
      if (savedLocale != null && savedLocale.isNotEmpty) {
        final parts = savedLocale.split('_');
        if (parts.isNotEmpty) {
          state = Locale(parts[0], parts.length > 1 && parts[1].isNotEmpty ? parts[1] : '');
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
      final appDataPath = await getLocalAppDataPath();
      Hive.init(appDataPath);
      final settingsBox = await Hive.openBox<String>('settings');
      await settingsBox.put('locale', '${locale.languageCode}_${locale.countryCode ?? ''}');
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
