import 'dart:async';
import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// hide TextDirection: intl exports its own (LTR/RTL) which would shadow the
// dart:ui one that TextPainter needs (see dawColumnWidth).
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, kIsWeb, listEquals, visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path; // 🚨 NOVO IMPORT
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';

import '../services/scanner_service.dart';
import '../services/audio_analysis_service.dart';
import '../services/metadata_extractor.dart';
import '../services/mixdown_detector_service.dart';
import 'row_click_selection.dart';
import 'widgets/shortcuts_help_dialog.dart';
import 'widgets/waveform_widget.dart';
import 'music_player_page.dart';
import '../utils/app_paths.dart' show isAppDataDirPinned;
import 'widgets/pinned_library_warning_dialog.dart';
import 'widgets/startup_dialog.dart';
import 'widgets/tab_customization_dialog.dart';
import '../services/dock_menu_service.dart';
import '../utils/daw_logo.dart';
import '../utils/mobile_utils.dart';
import '../utils/phase_colors.dart';
import '../utils/project_file_status.dart';
import '../utils/project_sort.dart';
import '../utils/theme_derivations.dart';
import '../providers/theme_provider.dart';
import '../utils/file_launcher.dart';
import '../utils/search_utils.dart';
import '../utils/route_observer.dart';
import '../utils/trina_grid_locale.dart';
import 'widgets/trina_grid_menu_delegate.dart';
import 'project_detail_page.dart';
import 'releases_tab_page.dart';
import 'release_detail_page.dart';
import 'profile_manager_page.dart';
import 'settings_page.dart';
import 'metadata_extraction_info_page.dart';
import 'playlists_page.dart';
import 'google_drive_sync_page.dart';
import 'statistics_page.dart';
import 'queue_page.dart';
import 'notification_settings_page.dart';
import 'widgets/conversion_progress_dialog.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/project_card_grid.dart';
import 'widgets/drag_to_share_button.dart';
import 'widgets/filter_dropdown.dart';
import 'widgets/language_switcher.dart';
import 'widgets/theme_switcher.dart';
import 'widgets/mobile_mini_player.dart';
import 'widgets/project_cover_avatar.dart';
import '../utils/project_visuals.dart';
import '../generated/l10n/app_localizations.dart';
import 'session_actions.dart';
import 'dialogs/create_project_dialog.dart';
import 'dialogs/archive_project_dialog.dart';
import 'dialogs/move_project_dialog.dart';
import 'dialogs/stack_metadata_source_dialog.dart';
import 'dialogs/preview_song_not_found_dialog.dart';
import 'preview_share.dart';
import 'project_context_menu.dart';
import 'project_templates_page.dart';
import '../models/pending_folder.dart';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/music_project.dart';
import '../models/release.dart';
import '../models/scan_mode.dart';
import '../models/dashboard_view_mode.dart';
import '../models/scan_root.dart';
import '../models/todo_item.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../services/google_drive_sync_service.dart' show GoogleDriveSyncService;
import '../utils/playback_todo_utils.dart';
import 'package:uuid/uuid.dart';

/// App version embedded at build-time (CI passes `--dart-define=APP_VERSION=x.y.z`).
/// For PR/local builds, we fall back to a dummy version.
const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '0.0.0',
);

/// Horizontal inset the projects grid's Name cell applies itself.
///
/// Matches TrinaGrid's own `defaultCellPadding`, which the column opts out of
/// so cover art can reach the cell's left border (#110).
const double _kNameCellInsetX = 10;
const EdgeInsets _kNameCellInset =
    EdgeInsets.symmetric(horizontal: _kNameCellInsetX);

/// Row height of the projects grid, which the cover-art bleed matches so the
/// artwork spans the row from top border to bottom.
const double _kNameCellBleedHeight = 48;

/// Total width the bleeding cover art occupies: a square at full strength,
/// then an equally wide tail fading to nothing under the start of the name.
const double _kNameCellBleedWidth = _kNameCellBleedHeight * 2;

/// Leading space the name gives up on a row that has cover art, so it starts
/// clear of the artwork's solid half and only ever sits over the faded tail.
/// Offsets [_kNameCellInset], which the artwork does not observe.
const double _kNameCellBleedTextOffset =
    _kNameCellBleedHeight - _kNameCellInsetX;

/// Width of the tree connector drawn for a row nested inside a folder group.
const double _kNameCellTreeConnectorWidth = 20;

/// Returns true when any text input (TextField / EditableText) currently has
/// focus. Used by keyboard handlers to avoid stealing Space / arrow keys while
/// the user is typing.
///
/// Reliable approach: the inner [Focus] widget created by [EditableText] is a
/// widget-tree descendant of [EditableText], so walking ancestors from its
/// BuildContext will find [EditableText] as a parent.
bool _isTextInputFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return context.findAncestorWidgetOfExactType<EditableText>() != null;
}

// Intent classes for keyboard shortcuts
class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _FocusTableIntent extends Intent {
  const _FocusTableIntent();
}

class _RescanIntent extends Intent {
  const _RescanIntent();
}

// Action classes for keyboard shortcuts
class _SearchAction extends Action<_SearchIntent> {
  final VoidCallback onSearch;

  _SearchAction(this.onSearch);

  @override
  Object? invoke(_SearchIntent intent) {
    onSearch();
    return null;
  }
}

class _RescanAction extends Action<_RescanIntent> {
  final VoidCallback onRescan;

  _RescanAction(this.onRescan);

  @override
  Object? invoke(_RescanIntent intent) {
    onRescan();
    return null;
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin, RouteAware {
  bool _scanning = false;
  bool _deepScanning = false;
  // Set by _cancelScan(); checked at safe break points inside _scanAll's
  // enumeration and upsert loops so an unexpectedly huge/hung scan (see the
  // Linux Flatpak document-portal caveat around scanner_service.dart) can
  // actually be stopped instead of running to whatever completion it finds.
  bool _scanCancelRequested = false;
  bool _extractingMetadata = false;
  // Progress for the blocking scan overlay (see shouldBlockForOperation):
  // how many of the projects found by the current scan have been processed
  // so far, and how many there are in total. Both reset to 0 outside a scan.
  int _scanProgressCurrent = 0;
  int _scanProgressTotal = 0;
  // Paths that failed to process during the most recently completed scan
  // (e.g. a file deleted or locked mid-scan) — reported once the scan
  // finishes rather than aborting the rest of the batch.
  List<String> _lastScanFailures = const [];
  // Briefly true right after a scan finishes successfully, so the
  // corresponding button's icon can flash a checkmark — see rescanIconState/
  // deepScanIconState and _flashScanSuccess.
  bool _rescanJustSucceeded = false;
  bool _deepScanJustSucceeded = false;
  Timer? _scanSuccessFlashTimer;
  Timer? _searchDebounceTimer;
  bool _isSearchingMobile = false;
  bool _isSearchingDesktop = false;
  double _railWidth = 130.0;
  late TabController _tabController;

  // Startup dialog
  bool _startupDialogShown = false;
  bool _hideStartupDialog = false;

  // Pinned-library warning. Pending covers both "still loading the
  // preference" and "the dialog is up", so the first-launch startup dialog
  // below can wait its turn instead of stacking on top of this one. Starts
  // out false on mobile and in every build that is not pinned, which is all
  // of them except a pull-request artifact.
  bool _pinnedWarningPending = false;
  bool _pinnedWarningShown = false;
  PinnedLibraryWarning? _pinnedWarning;

  // Ordered list of currently visible tabs (derived from provider, updated via ref.listen)
  List<AppTab> _currentVisibleTabs = [
    AppTab.projects,
    AppTab.releases,
    AppTab.queue,
    AppTab.statistics,
  ];

  // The tab the user is currently on, by identity (not index).
  AppTab get _currentTab {
    final idx = _tabController.index;
    if (idx < 0 || idx >= _currentVisibleTabs.length) return AppTab.projects;
    return _currentVisibleTabs[idx];
  }

  // Compute the ordered list from the provider's Set, filtered for the current platform.
  List<AppTab> _orderedFrom(Set<AppTab> visible) => VisibleTabsNotifier
      .canonicalOrder
      .where((t) => visible.contains(t))
      .where((t) => MobileUtils.isMobile() || t != AppTab.playlists)
      .where((t) => !MobileUtils.isMobile() || t != AppTab.player)
      .toList();

  // Generation counter — incremented each time we schedule a tab update so that
  // stale post-frame callbacks (from rapid toggles) are silently dropped.
  int _tabUpdateGen = 0;

  // Schedule a safe, deferred swap of the TabController + visible-tab list.
  // Using addPostFrameCallback avoids running inside build or inside a setState
  // callback, which caused double-dispose and length-mismatch errors.
  void _updateVisibleTabs(Set<AppTab> newVisible) {
    final ordered = _orderedFrom(newVisible);
    if (listEquals(_currentVisibleTabs, ordered)) return;
    final gen = ++_tabUpdateGen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _tabUpdateGen) return;
      final reordered = _orderedFrom(newVisible);
      if (listEquals(_currentVisibleTabs, reordered)) return;

      final previousTab = _currentTab;
      final newIndex =
          (reordered.contains(previousTab) ? reordered.indexOf(previousTab) : 0)
              .clamp(0, reordered.length - 1);

      // Create new controller BEFORE disposing the old one.
      final newCtrl = TabController(
        length: reordered.length,
        vsync: this,
        initialIndex: newIndex,
      );
      newCtrl.addListener(_onTabChanged);

      // Atomic swap so _tabController and _currentVisibleTabs are always in sync.
      final oldCtrl = _tabController;
      _tabController = newCtrl;
      _currentVisibleTabs = reordered;

      oldCtrl.removeListener(_onTabChanged);
      oldCtrl.dispose();

      setState(() {});
    });
  }

  // 1. FocusNode para a barra de pesquisa
  final FocusNode _searchFocusNode = FocusNode();

  // Key to reach the projects table and request focus on it
  final _tableKey = GlobalKey<_PlutoProjectsTableWithSelectionState>();

  // FocusNode para capturar eventos de teclado globalmente (debug)
  final FocusNode _debugKeyboardFocusNode = FocusNode();

  // TextEditingController para a barra de pesquisa
  late final TextEditingController _searchController;

  // Flag to track if Ctrl+F was recently pressed (to prevent aggressive focus recovery)
  bool _shouldMaintainSearchFocus = false;
  DateTime? _lastCtrlFPressTime;

  @override
  void initState() {
    super.initState();
    _currentVisibleTabs = _orderedFrom(ref.read(visibleTabsProvider));
    _tabController = TabController(
      length: _currentVisibleTabs.length,
      vsync: this,
    );
    _searchController = TextEditingController();
    if (!MobileUtils.isMobile()) {
      loadHideStartupDialog().then((v) {
        if (mounted) setState(() => _hideStartupDialog = v);
      });
    }

    // Not gated on desktop: CI hands testers a pinned debug APK too
    // (build_android), and it is isolated from their installed app in exactly
    // the same way.
    if (isAppDataDirPinned) {
      _pinnedWarningPending = true;
      loadPinnedLibraryWarning().then((warning) {
        if (!mounted) return;
        setState(() {
          _pinnedWarning = warning;
          // Silenced for this library: stop holding the startup dialog back.
          if (warning == null) _pinnedWarningPending = false;
        });
      });
    }

    // Add listener to TabController to rebuild when tab changes (for search placeholder update)
    _tabController.addListener(_onTabChanged);

    // Add listener to FocusNode to track focus changes
    // Only aggressively recover focus if Ctrl+F was recently pressed
    _searchFocusNode.addListener(() {
      // Only try to recover focus if Ctrl+F was recently pressed (within last 1 second)
      if (!_searchFocusNode.hasFocus &&
          _shouldMaintainSearchFocus &&
          _searchFocusNode.canRequestFocus) {
        final now = DateTime.now();
        if (_lastCtrlFPressTime != null &&
            now.difference(_lastCtrlFPressTime!).inSeconds < 1) {
          // Check if something else stole the focus
          final thief = FocusManager.instance.primaryFocus;
          if (thief != null && thief != _searchFocusNode) {
            // Unfocus the thief and request focus again
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_searchFocusNode.hasFocus && _shouldMaintainSearchFocus) {
                final currentThief = FocusManager.instance.primaryFocus;
                if (currentThief != null && currentThief != _searchFocusNode) {
                  currentThief.unfocus();
                }
                if (_searchFocusNode.canRequestFocus) {
                  _searchFocusNode.requestFocus();
                }
              }
            });
          }
        } else {
          // Ctrl+F was not recent, stop trying to maintain focus
          _shouldMaintainSearchFocus = false;
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    // Don't close the player here — DropdownButton/showMenu also push ModalRoutes,
    // which would close the player on every filter/combo interaction. Tab changes
    // are handled in _onTabChanged instead.
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      switch (_currentTab) {
        case AppTab.projects:
          final projectsSearch = ref.read(projectsSearchProvider);
          if (_searchController.text != projectsSearch)
            _searchController.text = projectsSearch;
        case AppTab.releases:
          final releasesSearch = ref.read(releasesSearchProvider);
          if (_searchController.text != releasesSearch)
            _searchController.text = releasesSearch;
        case AppTab.queue:
          final queueSearch = ref.read(queueSearchProvider);
          if (_searchController.text != queueSearch)
            _searchController.text = queueSearch;
        case AppTab.statistics:
          final statsSearch = ref.read(statisticsSearchProvider);
          if (_searchController.text != statsSearch)
            _searchController.text = statsSearch;
        case AppTab.playlists:
        case AppTab.player:
          _searchController.clear();
      }
      if (MobileUtils.isMobile() && _isSearchingMobile)
        _isSearchingMobile = false;
      setState(() {});
    }
  }

  void _clearCurrentTabSearch() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    switch (_currentTab) {
      case AppTab.projects:
        ref.read(projectsSearchProvider.notifier).clear();
      case AppTab.releases:
        ref.read(releasesSearchProvider.notifier).clear();
      case AppTab.queue:
        ref.read(queueSearchProvider.notifier).clear();
      case AppTab.statistics:
      case AppTab.playlists:
      case AppTab.player:
        ref.read(statisticsSearchProvider.notifier).set('');
    }
  }

  // Debounces the provider write (which drives filtering across the whole
  // visible list) so a fast typist doesn't re-filter on every keystroke.
  // Clearing to empty is applied immediately — that's a deliberate,
  // discrete action, not a keystroke, and shouldn't feel laggy.
  void _updateCurrentTabSearch(String text) {
    _searchDebounceTimer?.cancel();
    if (text.isEmpty) {
      _applyCurrentTabSearch(text);
      return;
    }
    _searchDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      _applyCurrentTabSearch(text);
    });
  }

  void _applyCurrentTabSearch(String text) {
    switch (_currentTab) {
      case AppTab.projects:
        ref.read(projectsSearchProvider.notifier).setSearchText(text);
      case AppTab.releases:
        ref.read(releasesSearchProvider.notifier).setSearchText(text);
      case AppTab.queue:
        ref.read(queueSearchProvider.notifier).set(text);
      case AppTab.statistics:
      case AppTab.playlists:
      case AppTab.player:
        ref.read(statisticsSearchProvider.notifier).set(text);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchFocusNode.dispose();
    _debugKeyboardFocusNode.dispose();
    _searchController.dispose();
    _scanSuccessFlashTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// Briefly flags [deep]'s scan button as just-succeeded so its icon can
  /// flash a checkmark (see rescanIconState/deepScanIconState) before
  /// reverting to normal — the only feedback a scan gets now that neither a
  /// plain scan nor (eventually) a deep scan blocks the UI with an overlay.
  void _flashScanSuccess({required bool deep}) {
    if (!mounted) return;
    _scanSuccessFlashTimer?.cancel();
    setState(() {
      if (deep) {
        _deepScanJustSucceeded = true;
      } else {
        _rescanJustSucceeded = true;
      }
    });
    _scanSuccessFlashTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _rescanJustSucceeded = false;
        _deepScanJustSucceeded = false;
      });
    });
  }

  // Track last processed key to avoid duplicate processing
  LogicalKeyboardKey? _lastProcessedKey;
  DateTime? _lastProcessedTime;

  // Method to track all keyboard events and handle shortcuts directly
  void _handleDebugKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final logicalKey = event.logicalKey;
    final isControl = event.isControlPressed;
    final isMeta = event.isMetaPressed;

    // Handle Ctrl+F / Cmd+F directly in RawKeyboardListener
    if (logicalKey == LogicalKeyboardKey.keyF && (isControl || isMeta)) {
      // Prevent duplicate processing (same key pressed multiple times in quick succession)
      final now = DateTime.now();
      if (_lastProcessedKey == logicalKey &&
          _lastProcessedTime != null &&
          now.difference(_lastProcessedTime!).inMilliseconds < 100) {
        return;
      }

      _lastProcessedKey = logicalKey;
      _lastProcessedTime = now;

      // Set flag to maintain focus for the next 1 second (only when Ctrl+F is pressed)
      _shouldMaintainSearchFocus = true;
      _lastCtrlFPressTime = DateTime.now();

      // Execute the action directly
      _focusSearchAndSelectAll();
      return;
    }

    // Handle Ctrl+R / Cmd+R directly in RawKeyboardListener
    if (logicalKey == LogicalKeyboardKey.keyR && (isControl || isMeta)) {
      // Prevent duplicate processing
      final now = DateTime.now();
      if (_lastProcessedKey == logicalKey &&
          _lastProcessedTime != null &&
          now.difference(_lastProcessedTime!).inMilliseconds < 100) {
        return;
      }

      _lastProcessedKey = logicalKey;
      _lastProcessedTime = now;

      // Execute the action directly
      _scanAll();
      return;
    }

    // Handle Ctrl+T / Cmd+T directly in RawKeyboardListener
    if (logicalKey == LogicalKeyboardKey.keyT && (isControl || isMeta)) {
      final now = DateTime.now();
      if (_lastProcessedKey == logicalKey &&
          _lastProcessedTime != null &&
          now.difference(_lastProcessedTime!).inMilliseconds < 100) {
        return;
      }

      _lastProcessedKey = logicalKey;
      _lastProcessedTime = now;

      _tableKey.currentState?.focusTable();
      return;
    }
  }

  void _collapseDesktopSearch() {
    _clearCurrentTabSearch();
    _shouldMaintainSearchFocus = false;
    _searchFocusNode.unfocus();
    setState(() => _isSearchingDesktop = false);
  }

  // Método para focar na busca e selecionar texto
  void _focusSearchAndSelectAll() {
    if (!MobileUtils.isMobile() && !_isSearchingDesktop) {
      setState(() => _isSearchingDesktop = true);
    }
    // Set flag to maintain focus for the next 1 second (only when Ctrl+F is pressed)
    _shouldMaintainSearchFocus = true;
    _lastCtrlFPressTime = DateTime.now();

    // CRITICAL: First, unfocus ALL widgets to prevent PlutoGrid or other widgets from stealing focus
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus != _searchFocusNode) {
      primaryFocus.unfocus();
    }

    // Use multiple post-frame callbacks to ensure focus is maintained
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Unfocus again to be sure (in case something grabbed focus in the meantime)
      final currentFocus = FocusManager.instance.primaryFocus;
      if (currentFocus != null && currentFocus != _searchFocusNode) {
        currentFocus.unfocus();
      }

      // First attempt: request focus
      if (_searchFocusNode.canRequestFocus) {
        _searchFocusNode.requestFocus();

        // Second post-frame callback to ensure focus is maintained and select text
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // If focus was lost or stolen, unfocus the thief and try again
          if (!_searchFocusNode.hasFocus) {
            final thief = FocusManager.instance.primaryFocus;
            if (thief != null && thief != _searchFocusNode) {
              thief.unfocus();
            }

            if (_searchFocusNode.canRequestFocus) {
              _searchFocusNode.requestFocus();
            }
          }

          // Select text if there is any
          if (_searchController.text.isNotEmpty) {
            _searchController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _searchController.text.length,
            );
          }

          // Third post-frame callback as final check
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Final attempt if focus is still lost
            if (!_searchFocusNode.hasFocus) {
              final thief = FocusManager.instance.primaryFocus;
              if (thief != null && thief != _searchFocusNode) {
                thief.unfocus();
              }

              if (_searchFocusNode.canRequestFocus) {
                _searchFocusNode.requestFocus();
              }
            }

            // Fourth callback - aggressive focus maintenance
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_searchFocusNode.hasFocus &&
                  _searchFocusNode.canRequestFocus) {
                final thief = FocusManager.instance.primaryFocus;
                if (thief != null && thief != _searchFocusNode) {
                  thief.unfocus();
                }
                _searchFocusNode.requestFocus();
              }
            });
          });
        });
      }
    });
  }

  Future<void> _quickSwitchProfile(BuildContext context) async {
    final allProfiles = ref.read(allProfilesProvider).value;
    if (allProfiles == null || allProfiles.length < 2) return;

    final currentProfile = ref.read(currentProfileProvider).value;

    if (allProfiles.length == 2) {
      final target = allProfiles.firstWhere(
        (p) => p.id != currentProfile?.id,
        orElse: () => allProfiles[0],
      );
      await _performProfileSwitch(target.id);
    } else {
      if (!context.mounted) return;
      final target = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(AppLocalizations.of(ctx)!.switchProfile),
          children: allProfiles
              .where((p) => p.id != currentProfile?.id)
              .map(
                (p) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(p.id),
                  child: Text(p.name),
                ),
              )
              .toList(),
        ),
      );
      if (target != null) await _performProfileSwitch(target);
    }
  }

  Future<void> _performProfileSwitch(String profileId) async {
    final profileRepo = await ref.read(profileRepositoryProvider.future);
    if (!mounted) return;
    final profileSwitchingNotifier = ref.read(
      profileSwitchingProvider.notifier,
    );
    final container = ProviderScope.containerOf(context);

    try {
      await profileRepo.setCurrentProfileId(profileId);
      profileSwitchingNotifier.setSwitching(true);

      container.invalidate(repositoryProvider);
      container.invalidate(allProjectsStreamProvider);
      container.invalidate(releasesProvider);
      container.invalidate(scanRootsProvider);
      container.invalidate(currentProfileProvider);

      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(repositoryProvider.future);
      profileSwitchingNotifier.complete();
    } catch (e) {
      profileSwitchingNotifier.complete();
    }
  }

  /// Handler for the empty-library floating action button: picks a folder,
  /// registers it as a scan root, and scans it immediately so the projects
  /// table populates without a separate manual "Rescan" step.
  Future<void> _addFirstScanFolder() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.selectProjectsFolder,
    );
    if (picked == null) return;

    final repo = await ref.read(repositoryProvider.future);
    await repo.addRoot(picked);
    ref.invalidate(rootsWatchProvider);
    ref.invalidate(scanRootsProvider);
    if (!mounted) return;
    await _scanAll();
  }

  /// Requests that an in-progress [_scanAll] stop at its next safe check
  /// point instead of running to completion. No-op if no scan is running.
  void _cancelScan() {
    if (!_scanning) return;
    setState(() => _scanCancelRequested = true);
  }

  Future<void> _scanAll({
    bool fullMetadata = false,
    bool onlyUnscanned = false,
  }) async {
    if (_scanning) return;
    final repo = await ref.read(repositoryProvider.future);
    setState(() {
      _scanning = true;
      _scanCancelRequested = false;
      _scanProgressCurrent = 0;
      _scanProgressTotal = 0;
      _lastScanFailures = const [];
    });
    try {
      final scanner = ScannerService();
      int foundCount = 0;
      // Snapshot before the scan so we can tell genuinely new projects
      // (surfaced with the "New" badge) apart from ones just re-confirmed
      // as still present — this scan no longer blocks the UI, so the grid
      // can visibly change under the user while it runs. Skipped on an empty
      // repo: that's an initial population, not a "new" discovery.
      final knownPaths = repo.getAllProjects().map((p) => p.filePath).toSet();
      final newlyDiscoveredIds = <String>[];
      final allFailures = <String>[];
      final ignoredPaths = repo
          .getIgnoredPaths()
          .map((p) => p.path)
          .toList(growable: false);
      final scanTime = DateTime.now();

      // Enumerate every root's entities up front (a cheap directory listing)
      // so the progress overlay can show an accurate "X of Y" total before
      // the slow part — per-file metadata extraction — begins below.
      final entitiesByRoot = <ScanRoot, List<FileSystemEntity>>{};
      for (final root in repo.getRoots()) {
        if (_scanCancelRequested) break;
        if (kDebugMode) debugPrint('[_scanAll] enumerating root ${root.path}...');
        final entities = <FileSystemEntity>[];
        await for (final entity in scanner.scanDirectory(
          root.path,
          ignoredPaths: ignoredPaths,
        )) {
          // Checked per-entity, not just per-root, since a single root's
          // enumeration is exactly what can run away indefinitely (see the
          // Linux Flatpak document-portal caveat in scanner_service.dart).
          if (_scanCancelRequested) break;
          entities.add(entity);
        }
        if (kDebugMode) {
          debugPrint('[_scanAll] root ${root.path}: found ${entities.length} project files');
        }
        entitiesByRoot[root] = entities;
      }

      if (_scanCancelRequested) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.scanCancelled)),
          );
        }
        return;
      }

      final totalEntities = entitiesByRoot.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
      if (mounted) setState(() => _scanProgressTotal = totalEntities);

      var processedBeforeThisRoot = 0;
      for (final entry in entitiesByRoot.entries) {
        if (_scanCancelRequested) break;
        final root = entry.key;
        final entities = entry.value;
        if (entities.isNotEmpty) {
          final processedBeforeThisRootSnapshot = processedBeforeThisRoot;
          final failures = await repo.upsertManyFromFileSystemEntities(
            entities,
            fullMetadataFor: (entity) =>
                fullMetadata &&
                (!onlyUnscanned ||
                    repo.getByPath(entity.path)?.metadataScanned != true),
            onProgress: (processed, total) {
              if (mounted) {
                setState(
                  () => _scanProgressCurrent =
                      processedBeforeThisRootSnapshot + processed,
                );
              }
            },
          );
          allFailures.addAll(failures);
          foundCount += entities.length;
        }
        processedBeforeThisRoot += entities.length;
        final foundPaths = entities.map((e) => e.path).toSet();
        if (knownPaths.isNotEmpty) {
          for (final path in newlyFoundPaths(foundPaths, knownPaths)) {
            final saved = repo.getByPath(path);
            if (saved != null) newlyDiscoveredIds.add(saved.id);
          }
        }
        await repo.updateRootLastScanAt(root.id, scanTime);
      }

      if (_scanCancelRequested) {
        // Partial results already upserted above are kept — cancelling
        // doesn't roll those back, it just stops finding/processing more.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.scanCancelled)),
          );
          ref.invalidate(allProjectsStreamProvider);
        }
        return;
      }

      if (newlyDiscoveredIds.isNotEmpty) {
        ref
            .read(recentlyDiscoveredProjectsProvider.notifier)
            .addAll(newlyDiscoveredIds);
      }

      // Repairs stacks left broken by older builds, whose scans dropped the
      // stackId from every version (see _buildProjectAndEvent). No-op once a
      // library is healthy.
      await repo.cleanUpDanglingStackLinks();

      // Roots set to Version Stack mode turn each project folder into one
      // main project. Runs after every root is upserted so a folder spanning
      // two roots is considered once, with all of its files present.
      await repo.autoStackFolders();

      // Snapshot pending folders with active session tracking before resolving,
      // so we can reconcile sessions for any that get resolved by this scan.
      final pendingWithSession = repo
          .getPendingFolders()
          .where((pf) => pf.sessionStartedAt != null)
          .toList(growable: false);
      if (kDebugMode) {
        print(
          '[_scanAll] pendingWithSession count=${pendingWithSession.length}',
        );
      }

      // Resolve pending folders: remove entries whose folder now has a real project
      // file (the scan just upserted it) or whose folder no longer exists.
      final resolved = await repo.resolveCompletedPendingFolders();
      if (kDebugMode) {
        print('[_scanAll] resolved=${resolved.toList()}');
      }
      if (resolved.isNotEmpty) {
        ref.read(pendingFoldersDirtyProvider.notifier).bump();
      }

      // Show session-reconciliation dialogs for any resolved folders that had
      // an active session stamp — but only while session mode is on. With it
      // off there is no session UI, so the "end and record / continue" prompt
      // would be meaningless; the folders are already resolved and removed
      // above, we just skip the prompt (equivalent to "continue").
      for (final pf in pendingWithSession) {
        if (!ref.read(sessionModeProvider)) break;
        if (!resolved.contains(pf.id)) continue;
        if (!mounted) break;
        final sessionStart = pf.sessionStartedAt!;
        final project = repo
            .getAllProjects()
            .where((p) => p.filePath.startsWith(pf.path))
            .firstOrNull;
        if (kDebugMode) {
          print(
            '[_scanAll] session pf=${pf.id} project=${project?.displayName}',
          );
        }
        if (project == null || !mounted) continue;

        final elapsed = DateTime.now().difference(sessionStart);
        final h = elapsed.inHours;
        final m = elapsed.inMinutes.remainder(60);
        final durationLabel = h > 0 ? '${h}h ${m}m' : '${m}m';
        final l10n = AppLocalizations.of(context)!;

        final choice = await showDialog<_SessionChoice>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.pendingFolderSessionTitle),
            content: Text(
              l10n.pendingFolderSessionBody(
                project.displayName.isNotEmpty
                    ? project.displayName
                    : pf.folderName,
                durationLabel,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pop(ctx, _SessionChoice.endAndRecord),
                child: Text(l10n.pendingFolderSessionEndRecord),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(ctx, _SessionChoice.continueSession),
                child: Text(l10n.pendingFolderSessionContinue),
              ),
            ],
          ),
        );
        if (choice == null || !mounted) continue;
        if (kDebugMode) {
          print('[_scanAll] sessionChoice=$choice for ${project.id}');
        }

        if (choice == _SessionChoice.endAndRecord) {
          final now = DateTime.now();
          final elapsedSecs = now.difference(sessionStart).inSeconds;
          if (elapsedSecs > 0) {
            final latest = repo.getById(project.id) ?? project;
            final record = SessionRecord(
              id: sessionStart.toIso8601String(),
              startedAt: sessionStart,
              endedAt: now,
              durationSeconds: elapsedSecs,
              phase: latest.status,
            );
            final newSessions = [...latest.sessions, record];
            await repo.updateProject(
              latest.copyWith(
                totalWorkSeconds: newSessions.fold<int>(
                  0,
                  (s, r) => s + r.durationSeconds,
                ),
                sessions: newSessions,
                updatedAt: now,
              ),
            );
            if (kDebugMode) {
              print(
                '[_scanAll] session saved elapsedSecs=$elapsedSecs for ${project.id}',
              );
            }
          }
        } else if (mounted) {
          // Continue session — WorkTimerNotifier saves it when the project
          // is eventually deactivated. Don't record a duplicate now.
          final updated = repo.getById(project.id) ?? project;
          final currentActive = ref.read(activeProjectProvider);
          if (currentActive != null &&
              currentActive.id != updated.id &&
              mounted) {
            final l = AppLocalizations.of(context)!;
            final confirmSwitch = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l.activeSessionSwitchTitle),
                content: Text(
                  l.activeSessionSwitchBody(
                    currentActive.displayName.isNotEmpty
                        ? currentActive.displayName
                        : currentActive.fileName,
                    updated.displayName.isNotEmpty
                        ? updated.displayName
                        : updated.fileName,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l.activeSessionSwitch),
                  ),
                ],
              ),
            );
            if (confirmSwitch != true || !mounted) continue;
          }
          ref.read(activeProjectProvider.notifier).set(updated);
          ref.read(workTimerProvider.notifier).continueFrom(sessionStart);
        }
      }

      // Auto-detect preview songs for projects that have neither a manual nor
      // a previously auto-detected path. Runs after the full scan so all upserts
      // are committed before we read back the project list.
      final customFolders = ref.read(customMixdownFoldersProvider).value;
      final customFoldersByDaw = ref
          .read(customMixdownFoldersByDawProvider)
          .value;
      for (final project in repo.getAllProjects()) {
        if (project.previewSongPath != null ||
            project.previewSongAutoPath != null)
          continue;
        final detected = MixdownDetectorService.findLatestMixdown(
          project,
          customFolders: customFolders,
          customFoldersByDaw: customFoldersByDaw,
        );
        if (detected != null) {
          await repo.updateProject(
            project.copyWith(previewSongAutoPath: detected.path),
          );
        }
      }

      ref.invalidate(allProjectsStreamProvider);

      if (mounted) setState(() => _lastScanFailures = allFailures);

      if (mounted) {
        final scanType = fullMetadata
            ? AppLocalizations.of(context)!.deepScan
            : AppLocalizations.of(context)!.rescan;
        final msg = foundCount == 0
            ? AppLocalizations.of(context)!.noProjectsFoundInRoots
            : AppLocalizations.of(
                context,
              )!.scanComplete(scanType, foundCount, foundCount == 1 ? '' : 's');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));

        // A failed file must never look like data loss with no explanation —
        // surfaced separately (rather than folded into the success message
        // above) since it can queue behind it without the two competing for
        // the same line of text.
        if (allFailures.isNotEmpty) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.scanFailuresSnackbar(
                  allFailures.length,
                  allFailures.length == 1 ? '' : 's',
                ),
              ),
              action: SnackBarAction(
                label: l10n.scanFailuresSnackbarAction,
                onPressed: () => _showScanFailuresDialog(allFailures),
              ),
            ),
          );
        }
      }
      _flashScanSuccess(deep: fullMetadata);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// Lists the file paths that failed to process during the most recent
  /// scan (see [_scanAll] and [ProjectRepository.upsertManyFromFileSystemEntities])
  /// — surfaced on demand via the failures SnackBar's action, rather than
  /// dumping every path directly into the SnackBar itself.
  void _showScanFailuresDialog(List<String> failedPaths) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.scanFailuresDialogTitle),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.scanFailuresDialogIntro),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final path in failedPaths)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText(
                          path,
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ],
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

  /// Pull-to-refresh on the mobile Projects tab. Mobile has no scan roots —
  /// projects there are metadata-only entries synced via Google Drive, not
  /// local files discovered by [_scanAll] — so running the desktop folder
  /// scan here always found 0 files and surfaced a confusing "no projects
  /// found in the selected folders" snackbar. Just re-read local storage.
  Future<void> _refreshMobileProjects() async {
    ref.invalidate(allProjectsStreamProvider);
  }

  Future<void> _fullScanAll({bool onlyUnscanned = true}) async {
    if (_scanning || _deepScanning) return;
    setState(() => _deepScanning = true);
    try {
      await _scanAll(fullMetadata: true, onlyUnscanned: onlyUnscanned);
    } finally {
      if (mounted) setState(() => _deepScanning = false);
    }
  }

  Future<void> _createReleaseFromSelectedProjects(
    BuildContext context,
    WidgetRef ref,
    List<MusicProject> selectedProjects,
  ) async {
    if (selectedProjects.isEmpty) return;

    String releaseTitle;

    // If single project, use project name; otherwise create with empty title
    if (selectedProjects.length == 1) {
      releaseTitle = selectedProjects.first.displayName;
    } else {
      releaseTitle = ''; // Empty title, user will fill it in the release page
    }

    final selectedProjectIds = selectedProjects.map((p) => p.id).toList();
    await _createRelease(context, ref, selectedProjectIds, releaseTitle);

    // Clear selection after creating release
    ref.read(selectedProjectsProvider.notifier).clear();
  }

  /// Combines the selected projects into one stacked song (#94).
  ///
  /// Only real, unstacked projects can be stacked, so the selection is filtered
  /// rather than rejected wholesale: selecting a folder's worth of rows where
  /// one is already a stack should stack the rest, not refuse the lot.
  Future<void> _stackSelectedProjects(
    BuildContext context,
    WidgetRef ref,
    List<MusicProject> selectedProjects,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final stackable = selectedProjects
        .where((p) => !p.isVirtual && !p.isStackMember)
        .toList();

    if (stackable.length < 2) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.stackNeedsTwoVersions)),
      );
      return;
    }

    // Stacking promotes exactly one member's metadata onto the song and
    // leaves the rest untouched — nothing is merged. Ask which one only when
    // more than one actually has details, otherwise the answer is forced.
    final suggested = defaultStackMetadataSource(stackable);
    var metadataSource = suggested;
    final candidates = stackMetadataSourceCandidates(stackable);
    if (candidates.isNotEmpty) {
      final chosen = await showStackMetadataSourceDialog(
        context,
        candidates: candidates,
        // The suggestion has to be one of the rows on offer: the oldest
        // member may itself have no details, in which case it isn't listed.
        suggested: candidates.contains(suggested)
            ? suggested
            : defaultStackMetadataSource(candidates),
        summaryBuilder: (project) => _stackMetadataSummary(context, project),
      );
      if (chosen == null) return;
      metadataSource = chosen;
    }

    final repo = await ref.read(repositoryProvider.future);
    await repo.stackProjects(
      memberIds: stackable.map((p) => p.id).toList(),
      metadataSourceId: metadataSource.id,
    );

    ref.read(selectedProjectsProvider.notifier).clear();
    ref.invalidate(allProjectsStreamProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.stackCreatedMessage(stackable.length))),
    );
  }

  /// One-line summary of what a project would contribute as the main
  /// project's metadata.
  ///
  /// Covers exactly the fields [MusicProject.hasUserMetadata] counts. A
  /// project appears in the chooser *because* that getter said it has
  /// details, so any field it counts but this omits produces a row offered to
  /// the user over "No details yet" — which reads as a bug in the dialog.
  static String _stackMetadataSummary(
    BuildContext context,
    MusicProject project,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final parts = <String>[
      if (project.customDisplayName?.trim().isNotEmpty ?? false)
        l10n.stackMetadataRenamedLabel,
      if (project.bpm != null) '${project.bpm!.round()} ${l10n.bpm}',
      if (project.musicalKey?.trim().isNotEmpty ?? false)
        project.musicalKey!.trim(),
      if (project.notes?.trim().isNotEmpty ?? false)
        l10n.stackMetadataNotesLabel,
      if (project.deadline != null) l10n.stackMetadataDeadlineLabel,
      if (project.todos.isNotEmpty)
        l10n.stackMetadataTodosLabel(project.todos.length),
      if (project.parts.isNotEmpty)
        l10n.stackMetadataPartsLabel(project.parts.length),
      if (project.totalWorkSeconds > 0)
        l10n.stackMetadataWorkHours(
          (project.totalWorkSeconds / 3600).toStringAsFixed(1),
        ),
    ];
    return parts.isEmpty ? l10n.stackMetadataNoneLabel : parts.join('  ·  ');
  }

  Future<void> _hideProjects(
    BuildContext context,
    WidgetRef ref,
    List<String> selectedProjectIds, {
    // False when this call is itself the "Undo" of an unhide — the resulting
    // snackbar then omits its own Undo action so the two don't ping-pong.
    bool allowUndo = true,
  }) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final allProjectsAsync = ref.read(allProjectsStreamProvider);
      final allProjects = allProjectsAsync.value ?? [];

      for (final projectId in selectedProjectIds) {
        final project = allProjects.firstWhere((p) => p.id == projectId);
        final updated = project.copyWith(hidden: true);
        await repo.updateProject(updated);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.projectsHidden(
                selectedProjectIds.length,
                selectedProjectIds.length == 1 ? '' : 's',
              ),
            ),
            action: allowUndo
                ? SnackBarAction(
                    label: l10n.undo,
                    onPressed: () => _unhideProjects(
                      context,
                      ref,
                      selectedProjectIds,
                      allowUndo: false,
                    ),
                  )
                : null,
          ),
        );
        // Invalidate to refresh the list
        ref.invalidate(allProjectsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToHideProjects(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _unhideProjects(
    BuildContext context,
    WidgetRef ref,
    List<String> selectedProjectIds, {
    // False when this call is itself the "Undo" of a hide (see _hideProjects).
    bool allowUndo = true,
  }) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final allProjectsAsync = ref.read(allProjectsStreamProvider);
      final allProjects = allProjectsAsync.value ?? [];

      // Check if we're in "show only hidden" mode
      final hiddenMode = ref.read(showHiddenProjectsProvider);
      final isShowingOnlyHidden = hiddenMode == 2;

      // Unhide all selected projects
      for (final projectId in selectedProjectIds) {
        final project = allProjects.firstWhere((p) => p.id == projectId);
        if (kDebugMode) {
          print(
            'DEBUG [Unhide]: Project ${project.displayName} - hidden before: ${project.hidden}',
          );
        }
        // Always set hidden to false, regardless of current state
        final updated = project.copyWith(hidden: false);
        await repo.updateProject(updated);

        // Verify the update was saved
        if (kDebugMode) {
          final verifyProject = repo.getAllProjects().firstWhere(
            (p) => p.id == projectId,
          );
          print(
            'DEBUG [Unhide]: Project ${verifyProject.displayName} - hidden after: ${verifyProject.hidden}',
          );
        }
      }

      // Invalidate to refresh the list
      ref.invalidate(allProjectsStreamProvider);

      // Wait a bit for the data to refresh, then check if there are any hidden projects left
      await Future.delayed(const Duration(milliseconds: 100));
      final updatedProjectsAsync = ref.read(allProjectsStreamProvider);
      final updatedProjects = updatedProjectsAsync.value ?? [];
      final remainingHiddenCount = updatedProjects
          .where((p) => p.hidden)
          .length;

      // If we were showing only hidden and there are no hidden projects left, switch back to visible
      if (isShowingOnlyHidden && remainingHiddenCount == 0) {
        ref.read(showHiddenProjectsProvider.notifier).setShowOnlyHidden(false);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.projectsUnhidden(
                selectedProjectIds.length,
                selectedProjectIds.length == 1 ? '' : 's',
              ),
            ),
            action: allowUndo
                ? SnackBarAction(
                    label: l10n.undo,
                    onPressed: () => _hideProjects(
                      context,
                      ref,
                      selectedProjectIds,
                      allowUndo: false,
                    ),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.failedToUnhideProjects(e.toString()),
            ),
          ),
        );
      }
    }
  }

  /// Permanently deletes whichever of [selectedProjectIds] are currently
  /// missing (file gone from disk) — projects still present on disk are left
  /// untouched even if selected alongside missing ones. Scans no longer
  /// auto-delete anything on their own (see
  /// ProjectRepository.deleteProjectsPermanently's doc comment); this is now
  /// the only way to actually remove a project's entry.
  ///
  /// Missing projects still referenced by a release are excluded by default,
  /// matching every other deletion path in the app (removeRoot,
  /// _deleteProjectsUnderPathPrefix, clearAllData) — losing one would
  /// silently drop a track from that release. The confirmation dialog offers
  /// an explicit opt-in checkbox to delete them anyway; choosing to also
  /// scrubs the deleted ids out of every release's trackIds so none are left
  /// dangling.
  Future<void> _deleteMissingProjects(
    BuildContext context,
    WidgetRef ref,
    List<String> selectedProjectIds,
  ) async {
    final allProjectsAsync = ref.read(allProjectsStreamProvider);
    final allProjects = allProjectsAsync.value ?? [];
    final missingIds = missingProjectIds(allProjects, selectedProjectIds);
    if (missingIds.isEmpty) return;

    final releases = ref.read(releasesProvider).value ?? [];
    final protectedIds = releaseProtectedProjectIds(releases);
    final releaseTrackedIds = missingIds.where(protectedIds.contains).toList();
    final freeIds = missingIds
        .where((id) => !protectedIds.contains(id))
        .toList();

    final l10n = AppLocalizations.of(context)!;
    var alsoDeleteReleaseTracked = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final idsToDelete = alsoDeleteReleaseTracked ? missingIds : freeIds;
          final plural = idsToDelete.length == 1 ? '' : 's';
          return AlertDialog(
            title: Text(l10n.deleteMissingProjectsTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteMissingProjectsConfirm(idsToDelete.length, plural),
                ),
                if (releaseTrackedIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: alsoDeleteReleaseTracked,
                    onChanged: (v) => setDialogState(
                      () => alsoDeleteReleaseTracked = v ?? false,
                    ),
                    title: Text(
                      l10n.deleteMissingProjectsAlsoDeleteReleaseTracked(
                        releaseTrackedIds.length,
                        releaseTrackedIds.length == 1 ? '' : 's',
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
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
                onPressed: idsToDelete.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.deleteMissingProjectsConfirmButton),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true || !mounted) return;

    final idsToDelete = alsoDeleteReleaseTracked ? missingIds : freeIds;
    if (idsToDelete.isEmpty) return;

    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.deleteProjectsPermanently(idsToDelete);

      if (alsoDeleteReleaseTracked) {
        final deleted = idsToDelete.toSet();
        for (final release in releases) {
          if (!release.trackIds.any(deleted.contains)) continue;
          await repo.updateRelease(
            release.copyWith(trackIds: trackIdsAfterRemoving(release, deleted)),
          );
        }
      }

      ref.invalidate(allProjectsStreamProvider);
      if (mounted) {
        final plural = idsToDelete.length == 1 ? '' : 's';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.missingProjectsDeleted(idsToDelete.length, plural),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }

  Future<void> _createRelease(
    BuildContext context,
    WidgetRef ref,
    List<String> selectedProjectIds,
    String releaseTitle,
  ) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final newRelease = Release(
        id: const Uuid().v4(),
        title: releaseTitle,
        trackIds: selectedProjectIds,
        releaseDate: DateTime.now(),
      );
      await repo.addRelease(newRelease);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.releaseCreated(releaseTitle),
            ),
          ),
        );
        // Switch to releases tab and navigate to the new release
        _tabController.animateTo(1);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReleaseDetailPage(releaseId: newRelease.id),
            ),
          );
          // Refresh releases data when returning from detail page
          if (mounted) {
            ref.invalidate(releasesProvider);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToCreateRelease(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = ref.watch(dateFormatProvider);
    final repoAsync = ref.watch(repositoryProvider);
    final roots = ref.watch(scanRootsProvider);

    // repositoryProvider's .value can still point at a repo whose Hive boxes
    // were just closed (Clear Library / Delete All Data racing this widget's
    // rebuild against the provider actually being invalidated) — reading
    // through safeGetAllProjects instead of calling getAllProjects() directly
    // avoids a HiveError("Box has already been closed") crashing this build.
    final loadedProjects = repoAsync.hasValue
        ? safeGetAllProjects(repoAsync.value!)
        : null;

    // Defaults to true (has projects) while still loading, so the "add a
    // scan folder" FAB below doesn't flash on before data arrives.
    final hasAnyProjects = loadedProjects?.isNotEmpty ?? true;

    // Warn a pinned build (a pull-request artifact) that it opened a library
    // of its own. It is the only build with no other in-app trace of which
    // one: no startup picker, and no Settings dev card.
    if (_pinnedWarning != null && !_pinnedWarningShown) {
      _pinnedWarningShown = true;
      final warning = _pinnedWarning!;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showPinnedLibraryWarningDialog(context, warning);
        // Releases the startup dialog below, and rebuilds so it can run.
        if (mounted) setState(() => _pinnedWarningPending = false);
      });
    }

    // Show first-launch dialog on desktop when the profile is truly blank (no
    // roots AND no projects). Profiles that have projects but no roots (e.g.
    // restored from Google Drive) are already set up and should not see this.
    if (!MobileUtils.isMobile() &&
        !_startupDialogShown &&
        !_hideStartupDialog &&
        !_pinnedWarningPending &&
        loadedProjects != null &&
        roots.isEmpty &&
        loadedProjects.isEmpty) {
      _startupDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showStartupDialog(context);
      });
    }

    // Keep visible tabs in sync with the provider.
    ref.listen(visibleTabsProvider, (_, next) {
      if (mounted) setState(() => _updateVisibleTabs(next));
    });

    // The background initial scan at app launch also drives the Rescan
    // button's icon (see isScanning below), so flash the same success
    // checkmark when it finishes as a manual rescan gets.
    ref.listen<bool>(initialScanStateProvider, (previous, next) {
      if (previous == true && next == false) _flashScanSuccess(deep: false);
    });

    // Get current search text based on active tab
    final currentSearch = switch (_currentTab) {
      AppTab.projects => ref.watch(projectsSearchProvider),
      AppTab.releases => ref.watch(releasesSearchProvider),
      AppTab.queue => ref.watch(queueSearchProvider),
      AppTab.statistics => ref.watch(statisticsSearchProvider),
      AppTab.playlists => '',
      AppTab.player => '',
    };
    final projects = ref.watch(projectsProvider);
    // Keep macOS dock menu (and Windows jump list) in sync with latest projects
    ref.listen(
      projectsProvider,
      (_, next) => DockMenuService.updateRecentProjects(next),
    );
    final hiddenMode = ref.watch(showHiddenProjectsProvider);
    final hiddenNotifier = ref.read(showHiddenProjectsProvider.notifier);
    final finishedMode = ref.watch(showFinishedProjectsProvider);
    final finishedNotifier = ref.read(showFinishedProjectsProvider.notifier);
    final phaseFilter = ref.watch(phaseFilterProvider);
    final customPhases = ref.watch(customPhasesProvider);
    final dawFilter = ref.watch(dawFilterProvider);
    final availableDaws = ref.watch(availableDawsProvider);
    final deadlineFilter = ref.watch(deadlineFilterProvider);
    final initialScanning = ref.watch(initialScanStateProvider);
    final isProfileSwitching = ref.watch(profileSwitchingProvider);
    final isScanning = _scanning || initialScanning;
    final isAnyOperation =
        isScanning || isProfileSwitching || _extractingMetadata;
    final blockingOperation = shouldBlockForOperation(
      scanning: _scanning,
      deepScanning: _deepScanning,
      profileSwitching: isProfileSwitching,
      extractingMetadata: _extractingMetadata,
    );
    final isLeftRail =
        !MobileUtils.isMobile() &&
        ref.watch(tabPositionProvider) == TabPosition.left;
    final railCollapsed = ref.watch(railCollapsedProvider);

    // Sync search controller with provider state
    if (_searchController.text != currentSearch) {
      _searchController.text = currentSearch;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: currentSearch.length),
      );
    }

    // Get all projects and filter out preserved projects (same logic as projectsProvider)
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);
    final allProjects = allProjectsAsync.value ?? [];
    final releasesAsync = ref.watch(releasesProvider);
    final scanRoots = ref.watch(scanRootsProvider);

    // Filter out preserved projects (in releases but not in any active scan root)
    // On mobile, we're only syncing metadata, so show ALL projects (both in releases and not)
    // On desktop, filter preserved projects that aren't in active scan roots
    final List<MusicProject> filteredProjects;
    if (MobileUtils.isMobile()) {
      // Mobile: show all projects (metadata-only mode, no file system checks)
      filteredProjects = allProjects;
    } else {
      // Desktop: filter preserved projects that aren't in active scan roots
      final releases = releasesAsync.value ?? [];
      final protectedProjectIds = <String>{};
      for (final release in releases) {
        protectedProjectIds.addAll(release.trackIds);
      }

      // Get all active scan root paths (normalized for comparison)
      final activeRootPaths = scanRoots.map((root) {
        final normalized = path.normalize(root.path);
        // Ensure root path ends with separator for proper prefix matching
        return normalized.endsWith(path.separator)
            ? normalized
            : normalized + path.separator;
      }).toList();

      // Filter out preserved projects before counting
      filteredProjects = allProjects.where((project) {
        // If project is not in any release, always include it
        if (!protectedProjectIds.contains(project.id)) {
          return true;
        }

        // If project is in a release, check if it's in any active scan root
        final projectPath = path.normalize(project.filePath);
        final isInActiveRoot = activeRootPaths.any((rootPath) {
          // Check if project path starts with the root path
          return projectPath.startsWith(rootPath);
        });

        // Only include if it's in an active root (preserved projects not in active roots are excluded)
        return isInActiveRoot;
      }).toList();
    }

    // Count visible and hidden from filtered projects only
    final visibleCount = filteredProjects.where((p) => !p.hidden).length;
    final hiddenCount = filteredProjects.where((p) => p.hidden).length;

    // RawKeyboardListener is now the primary handler for Ctrl+F and Ctrl+R
    // This ensures it works even when other widgets (like PlutoGrid) have focus
    return RawKeyboardListener(
      focusNode: _debugKeyboardFocusNode,
      autofocus: true, // Autofocus to ensure we capture keyboard events
      onKey: _handleDebugKeyEvent,
      child: FocusScope(
        child: Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(
              Platform.isMacOS
                  ? LogicalKeyboardKey.meta
                  : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyF,
            ): const _SearchIntent(),
            LogicalKeySet(
              Platform.isMacOS
                  ? LogicalKeyboardKey.meta
                  : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyR,
            ): const _RescanIntent(),
            LogicalKeySet(
              Platform.isMacOS
                  ? LogicalKeyboardKey.meta
                  : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyT,
            ): const _FocusTableIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _SearchIntent: _SearchAction(() {
                _focusSearchAndSelectAll();
              }),
              _RescanIntent: _RescanAction(() {
                _scanAll();
              }),
              _FocusTableIntent: CallbackAction<_FocusTableIntent>(
                onInvoke: (_) => _tableKey.currentState?.focusTable(),
              ),
            },
            child: Focus(
              autofocus: true,
              canRequestFocus: true,
              child: Stack(
                children: [
                  Scaffold(
                    appBar: MobileUtils.isMobile()
                        ? AppBar(
                            leading: _isSearchingMobile
                                ? IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () {
                                      setState(
                                        () => _isSearchingMobile = false,
                                      );
                                      _clearCurrentTabSearch();
                                    },
                                  )
                                : null,
                            title: _isSearchingMobile
                                ? TextField(
                                    autofocus: true,
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: switch (_currentTab) {
                                        AppTab.projects => AppLocalizations.of(
                                          context,
                                        )!.searchProjects,
                                        AppTab.releases => AppLocalizations.of(
                                          context,
                                        )!.searchReleases,
                                        AppTab.queue => AppLocalizations.of(
                                          context,
                                        )!.queueSearchHint,
                                        _ => AppLocalizations.of(
                                          context,
                                        )!.statsSearchProjects,
                                      },
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                    onChanged: _updateCurrentTabSearch,
                                  )
                                : Image.asset('app_icon.png', height: 32),
                            actions: _isSearchingMobile
                                ? [
                                    if (currentSearch.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          _clearCurrentTabSearch();
                                        },
                                      ),
                                  ]
                                : [
                                    // Search icon (hidden on Playlists tab)
                                    if (_currentTab != AppTab.playlists)
                                      IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () => setState(
                                          () => _isSearchingMobile = true,
                                        ),
                                      ),
                                    // Notification settings button (Android only)
                                    if (Platform.isAndroid)
                                      IconButton(
                                        icon: const Icon(Icons.notifications),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const NotificationSettingsPage(),
                                            ),
                                          );
                                        },
                                        tooltip: AppLocalizations.of(
                                          context,
                                        )!.notificationSettings,
                                      ),
                                    // Google Drive sync (hidden when left rail — shown there instead).
                                    // Not offered inside Flatpak — see
                                    // GoogleDriveSyncService.isSupported.
                                    if (!isLeftRail &&
                                        GoogleDriveSyncService.isSupported)
                                      IconButton(
                                        icon: const Icon(Icons.cloud_outlined),
                                        tooltip: AppLocalizations.of(
                                          context,
                                        )!.syncWithGoogleDrive,
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const GoogleDriveSyncPage(),
                                              ),
                                            ),
                                      ),
                                    // Quick profile switch button (hidden when left rail)
                                    if (!isLeftRail)
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final allProfiles = ref
                                              .watch(allProfilesProvider)
                                              .value;
                                          if (allProfiles == null ||
                                              allProfiles.length < 2)
                                            return const SizedBox.shrink();
                                          return IconButton(
                                            icon: const Icon(Icons.swap_horiz),
                                            tooltip: AppLocalizations.of(
                                              context,
                                            )!.switchProfile,
                                            onPressed: () =>
                                                _quickSwitchProfile(context),
                                          );
                                        },
                                      ),
                                    // Profile button (hidden when left rail)
                                    if (!isLeftRail)
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final currentProfileAsync = ref.watch(
                                            currentProfileProvider,
                                          );
                                          return currentProfileAsync.when(
                                            loading: () => IconButton(
                                              icon: const Icon(Icons.person),
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const ProfileManagerPage(),
                                                  ),
                                                );
                                              },
                                              tooltip: AppLocalizations.of(
                                                context,
                                              )!.profileManager,
                                            ),
                                            error: (_, _) => IconButton(
                                              icon: const Icon(Icons.person),
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const ProfileManagerPage(),
                                                  ),
                                                );
                                              },
                                              tooltip: AppLocalizations.of(
                                                context,
                                              )!.profileManager,
                                            ),
                                            data: (currentProfile) {
                                              Widget profileIcon;
                                              if (currentProfile?.photoPath !=
                                                      null &&
                                                  File(
                                                    currentProfile!.photoPath!,
                                                  ).existsSync()) {
                                                profileIcon = ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.file(
                                                    File(
                                                      currentProfile.photoPath!,
                                                    ),
                                                    width: 32,
                                                    height: 32,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return const Icon(
                                                            Icons.person,
                                                          );
                                                        },
                                                  ),
                                                );
                                              } else {
                                                profileIcon = const Icon(
                                                  Icons.person,
                                                );
                                              }
                                              return IconButton(
                                                icon: profileIcon,
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          const ProfileManagerPage(),
                                                    ),
                                                  );
                                                },
                                                tooltip:
                                                    currentProfile?.name ??
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.profileManager,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                  ],
                          )
                        : null,
                    bottomNavigationBar: MobileUtils.isMobile()
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MobileMiniPlayer(),
                              NavigationBar(
                                selectedIndex: _tabController.index,
                                onDestinationSelected: (i) {
                                  _tabController.animateTo(i);
                                  setState(() {});
                                },
                                destinations: [
                                  for (final tab in _currentVisibleTabs)
                                    switch (tab) {
                                      AppTab.projects => NavigationDestination(
                                        icon: const Icon(
                                          Icons.library_music_outlined,
                                        ),
                                        selectedIcon: const Icon(
                                          Icons.library_music,
                                        ),
                                        label: AppLocalizations.of(
                                          context,
                                        )!.projects,
                                      ),
                                      AppTab.releases => NavigationDestination(
                                        icon: const Icon(Icons.album_outlined),
                                        selectedIcon: const Icon(Icons.album),
                                        label: AppLocalizations.of(
                                          context,
                                        )!.releasesTab,
                                      ),
                                      AppTab.playlists => NavigationDestination(
                                        icon: const Icon(
                                          Icons.playlist_play_outlined,
                                        ),
                                        selectedIcon: const Icon(
                                          Icons.playlist_play,
                                        ),
                                        label: AppLocalizations.of(
                                          context,
                                        )!.playlists,
                                      ),
                                      AppTab.queue => NavigationDestination(
                                        icon: const Icon(
                                          Icons.checklist_outlined,
                                        ),
                                        selectedIcon: const Icon(
                                          Icons.checklist,
                                        ),
                                        label: AppLocalizations.of(
                                          context,
                                        )!.queueTab,
                                      ),
                                      AppTab.statistics =>
                                        NavigationDestination(
                                          icon: const Icon(
                                            Icons.bar_chart_outlined,
                                          ),
                                          selectedIcon: const Icon(
                                            Icons.bar_chart_rounded,
                                          ),
                                          label: AppLocalizations.of(
                                            context,
                                          )!.statisticsTab,
                                        ),
                                      AppTab.player => NavigationDestination(
                                        icon: const Icon(
                                          Icons.headphones_outlined,
                                        ),
                                        selectedIcon: const Icon(
                                          Icons.headphones,
                                        ),
                                        label: AppLocalizations.of(
                                          context,
                                        )!.playerTitle,
                                      ),
                                    },
                                ],
                              ),
                            ],
                          )
                        : () {
                            final playerRequest = ref.watch(
                              desktopPlayerProvider,
                            );
                            if (playerRequest == null) return null;
                            return _DesktopPlayerBar(
                              key: const Key('desktop_player_bar'),
                              request: playerRequest,
                            );
                          }(),
                    floatingActionButton:
                        (!MobileUtils.isMobile() &&
                            _currentTab == AppTab.projects &&
                            !hasAnyProjects)
                        ? FloatingActionButton(
                            onPressed: _addFirstScanFolder,
                            tooltip: AppLocalizations.of(context)!.addFolder,
                            child: const Icon(Icons.add),
                          )
                        : null,
                    body: Builder(
                      builder: (context) {
                        // Action bar: search field and filter toolbar.
                        final actionBar = Builder(
                          builder: (context) {
                            final isMobile = MobileUtils.isMobile();
                            if (isMobile) return const SizedBox.shrink();
                            return Padding(
                              padding: Platform.isMacOS
                                  ? const EdgeInsets.fromLTRB(16, 14, 16, 16)
                                  : MobileUtils.getResponsivePadding(context),
                              child: isMobile
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Search bar on top for mobile (hidden on Playlists tab)
                                        if (_currentTab != AppTab.playlists)
                                          TextField(
                                            focusNode: _searchFocusNode,
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              hintText: switch (_currentTab) {
                                                AppTab.projects =>
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.searchProjects,
                                                AppTab.releases =>
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.searchReleases,
                                                AppTab.queue =>
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.queueSearchHint,
                                                _ => AppLocalizations.of(
                                                  context,
                                                )!.statsSearchProjects,
                                              },
                                              isDense: true,
                                              border:
                                                  const OutlineInputBorder(),
                                              prefixIcon: const Icon(
                                                Icons.search,
                                              ),
                                              suffixIcon: () {
                                                final cs = currentSearch;
                                                return cs.isNotEmpty
                                                    ? IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                        ),
                                                        onPressed:
                                                            _clearCurrentTabSearch,
                                                      )
                                                    : null;
                                              }(),
                                            ),
                                            onChanged: _updateCurrentTabSearch,
                                          ),
                                        if (_currentTab != AppTab.playlists)
                                          const SizedBox(height: 12),
                                        // Filters and info row (only show on Projects tab)
                                        if (_currentTab == AppTab.projects) ...[
                                          Row(
                                            children: [
                                              Expanded(
                                                child: repoAsync.when(
                                                  loading: () =>
                                                      const SizedBox.shrink(),
                                                  error: (_, _) =>
                                                      const SizedBox.shrink(),
                                                  data: (repo) {
                                                    String projectText;
                                                    final l10n =
                                                        AppLocalizations.of(
                                                          context,
                                                        )!;
                                                    // On mobile, don't show roots count (Android doesn't use scan roots)
                                                    if (hiddenMode == 2) {
                                                      projectText =
                                                          '${l10n.projectsCount(hiddenCount)} ${l10n.hiddenOnly}';
                                                    } else {
                                                      projectText = l10n
                                                          .projectsCount(
                                                            visibleCount,
                                                          );
                                                      if (hiddenCount > 0 &&
                                                          hiddenMode == 0) {
                                                        projectText +=
                                                            ' ${l10n.hiddenCount(hiddenCount)}';
                                                      }
                                                    }
                                                    return Text(
                                                      projectText,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: hiddenMode == 2
                                                            ? Colors
                                                                  .orange
                                                                  .shade300
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Filter row
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              // Show Hidden Projects checkbox (Mobile) - only show if there are hidden projects
                                              if (hiddenCount > 0)
                                                InkWell(
                                                  onTap: () {
                                                    final currentValue =
                                                        hiddenMode == 1;
                                                    if (!currentValue) {
                                                      hiddenNotifier.setShowAll(
                                                        true,
                                                      );
                                                    } else {
                                                      hiddenNotifier.setShowAll(
                                                        false,
                                                      );
                                                    }
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Checkbox(
                                                        value: hiddenMode == 1,
                                                        onChanged: (value) {
                                                          if (value == true) {
                                                            hiddenNotifier
                                                                .setShowAll(
                                                                  true,
                                                                );
                                                          } else {
                                                            hiddenNotifier
                                                                .setShowAll(
                                                                  false,
                                                                );
                                                          }
                                                        },
                                                      ),
                                                      Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.showHidden,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              // Hide Finished Projects checkbox (Mobile)
                                              InkWell(
                                                onTap: () {
                                                  final currentValue =
                                                      finishedMode == 1;
                                                  if (!currentValue) {
                                                    finishedNotifier
                                                        .setHideFinished(true);
                                                  } else {
                                                    finishedNotifier
                                                        .setHideFinished(false);
                                                  }
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Checkbox(
                                                      value: finishedMode == 1,
                                                      onChanged: (value) {
                                                        if (value == true) {
                                                          finishedNotifier
                                                              .setHideFinished(
                                                                true,
                                                              );
                                                        } else {
                                                          finishedNotifier
                                                              .setHideFinished(
                                                                false,
                                                              );
                                                        }
                                                      },
                                                    ),
                                                    Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.hideFinished,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Show Deadline checkbox (Mobile)
                                              InkWell(
                                                onTap: () {
                                                  final currentValue = ref.read(
                                                    showOnlyWithDeadlineProvider,
                                                  );
                                                  ref
                                                      .read(
                                                        showOnlyWithDeadlineProvider
                                                            .notifier,
                                                      )
                                                      .setShowOnlyWithDeadline(
                                                        !currentValue,
                                                      );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Checkbox(
                                                      value: ref.watch(
                                                        showOnlyWithDeadlineProvider,
                                                      ),
                                                      onChanged: (value) {
                                                        ref
                                                            .read(
                                                              showOnlyWithDeadlineProvider
                                                                  .notifier,
                                                            )
                                                            .setShowOnlyWithDeadline(
                                                              value == true,
                                                            );
                                                      },
                                                    ),
                                                    Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.showOnlyDeadlines,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (hiddenCount > 0)
                                                TextButton.icon(
                                                  icon: Icon(
                                                    hiddenMode == 2
                                                        ? Icons.visibility
                                                        : Icons
                                                              .visibility_off_outlined,
                                                    size: 16,
                                                  ),
                                                  label: Text(
                                                    hiddenMode == 2
                                                        ? AppLocalizations.of(
                                                            context,
                                                          )!.showAll
                                                        : AppLocalizations.of(
                                                            context,
                                                          )!.showOnlyHidden,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        hiddenMode == 2
                                                        ? Colors.orange.shade700
                                                        : null,
                                                    foregroundColor:
                                                        hiddenMode == 2
                                                        ? Colors.white
                                                        : Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.color,
                                                  ),
                                                  onPressed: () {
                                                    if (hiddenMode == 2) {
                                                      hiddenNotifier
                                                          .setShowOnlyHidden(
                                                            false,
                                                          );
                                                    } else {
                                                      hiddenNotifier
                                                          .setShowOnlyHidden(
                                                            true,
                                                          );
                                                    }
                                                  },
                                                ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.filter_list,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  DropdownButton<String>(
                                                    value: phaseFilter,
                                                    hint: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.filterByPhase,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.color,
                                                      ),
                                                    ),
                                                    underline:
                                                        const SizedBox.shrink(),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.color,
                                                    ),
                                                    icon:
                                                        const SizedBox.shrink(),
                                                    items: [
                                                      DropdownMenuItem<String>(
                                                        value: null,
                                                        child: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.allPhases,
                                                        ),
                                                      ),
                                                      ...customPhases.map(
                                                        (phase) =>
                                                            DropdownMenuItem<
                                                              String
                                                            >(
                                                              value: phase,
                                                              child: Text(
                                                                phase,
                                                              ),
                                                            ),
                                                      ),
                                                    ],
                                                    onChanged: (String? value) {
                                                      ref
                                                          .read(
                                                            phaseFilterProvider
                                                                .notifier,
                                                          )
                                                          .setPhase(value);
                                                    },
                                                  ),
                                                ],
                                              ),
                                              // DAW Filter dropdown — only offers DAWs actually present in this profile
                                              if (availableDaws.isNotEmpty)
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.piano,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.color,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    DropdownButton<String>(
                                                      value: dawFilter,
                                                      hint: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.filterByDaw,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.color,
                                                        ),
                                                      ),
                                                      underline:
                                                          const SizedBox.shrink(),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.color,
                                                      ),
                                                      icon:
                                                          const SizedBox.shrink(),
                                                      items: [
                                                        DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: null,
                                                          child: Text(
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.allDaws,
                                                          ),
                                                        ),
                                                        ...availableDaws.map(
                                                          (daw) =>
                                                              DropdownMenuItem<
                                                                String
                                                              >(
                                                                value: daw,
                                                                child: Text(
                                                                  daw,
                                                                ),
                                                              ),
                                                        ),
                                                      ],
                                                      onChanged: (String? value) {
                                                        ref
                                                            .read(
                                                              dawFilterProvider
                                                                  .notifier,
                                                            )
                                                            .setDaw(value);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              // Deadline Filter dropdown (Desktop only)
                                              if (!MobileUtils.isMobile())
                                                DropdownButton<DeadlineFilter>(
                                                  value: deadlineFilter,
                                                  hint: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.filterByDeadline,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color,
                                                    ),
                                                  ),
                                                  underline:
                                                      const SizedBox.shrink(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                                  ),
                                                  icon: Icon(
                                                    Icons.schedule,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                                  ),
                                                  items: [
                                                    DropdownMenuItem<
                                                      DeadlineFilter
                                                    >(
                                                      value: DeadlineFilter.all,
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.allDeadlines,
                                                      ),
                                                    ),
                                                    DropdownMenuItem<
                                                      DeadlineFilter
                                                    >(
                                                      value: DeadlineFilter
                                                          .hasDeadline,
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.hasDeadline,
                                                      ),
                                                    ),
                                                    DropdownMenuItem<
                                                      DeadlineFilter
                                                    >(
                                                      value: DeadlineFilter
                                                          .overdue,
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.warning,
                                                            color: Colors.red,
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.overdue,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    DropdownMenuItem<
                                                      DeadlineFilter
                                                    >(
                                                      value: DeadlineFilter
                                                          .dueSoon,
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.schedule,
                                                            color:
                                                                Colors.orange,
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.dueSoon,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    DropdownMenuItem<
                                                      DeadlineFilter
                                                    >(
                                                      value: DeadlineFilter
                                                          .dueToday,
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.today,
                                                            color: Colors.red,
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.dueToday,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  onChanged:
                                                      (DeadlineFilter? value) {
                                                        if (value != null) {
                                                          ref
                                                              .read(
                                                                deadlineFilterProvider
                                                                    .notifier,
                                                              )
                                                              .setFilter(value);
                                                        }
                                                      },
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        // Ações de Root e Scan
                                        Row(
                                          children: [
                                            // Quick profile switch button (hidden when left rail)
                                            if (!isLeftRail)
                                              Consumer(
                                                builder: (context, ref, child) {
                                                  final allProfiles = ref
                                                      .watch(
                                                        allProfilesProvider,
                                                      )
                                                      .value;
                                                  if (allProfiles == null ||
                                                      allProfiles.length < 2)
                                                    return const SizedBox.shrink();
                                                  return IconButton(
                                                    icon: const Icon(
                                                      Icons.swap_horiz,
                                                    ),
                                                    tooltip:
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.switchProfile,
                                                    onPressed: () =>
                                                        _quickSwitchProfile(
                                                          context,
                                                        ),
                                                  );
                                                },
                                              ),
                                            // Profile button (hidden when left rail)
                                            if (!isLeftRail)
                                              Consumer(
                                                builder: (context, ref, child) {
                                                  final currentProfileAsync =
                                                      ref.watch(
                                                        currentProfileProvider,
                                                      );
                                                  return currentProfileAsync.when(
                                                    loading: () => Tooltip(
                                                      message:
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.profileManager,
                                                      child: TextButton.icon(
                                                        icon: const Icon(
                                                          Icons.person,
                                                          size: 24,
                                                        ),
                                                        label: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.profileManager,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).push(
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  const ProfileManagerPage(),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    error: (_, _) => Tooltip(
                                                      message:
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.profileManager,
                                                      child: TextButton.icon(
                                                        icon: const Icon(
                                                          Icons.person,
                                                          size: 24,
                                                        ),
                                                        label: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.profileManager,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).push(
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  const ProfileManagerPage(),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    data: (currentProfile) {
                                                      Widget profileIcon;
                                                      if (currentProfile
                                                                  ?.photoPath !=
                                                              null &&
                                                          File(
                                                            currentProfile!
                                                                .photoPath!,
                                                          ).existsSync()) {
                                                        profileIcon = ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          child: Image.file(
                                                            File(
                                                              currentProfile
                                                                  .photoPath!,
                                                            ),
                                                            width: 24,
                                                            height: 24,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return const Icon(
                                                                    Icons
                                                                        .person,
                                                                    size: 24,
                                                                  );
                                                                },
                                                          ),
                                                        );
                                                      } else {
                                                        profileIcon =
                                                            const Icon(
                                                              Icons.person,
                                                              size: 24,
                                                            );
                                                      }

                                                      final profileName =
                                                          currentProfile
                                                              ?.name ??
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.profileManager;

                                                      return Tooltip(
                                                        message: profileName,
                                                        child: TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                              context,
                                                            ).push(
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    const ProfileManagerPage(),
                                                              ),
                                                            );
                                                          },
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              profileIcon,
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Flexible(
                                                                child: ConstrainedBox(
                                                                  constraints:
                                                                      const BoxConstraints(
                                                                        maxWidth:
                                                                            150,
                                                                      ),
                                                                  child: Text(
                                                                    profileName,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 1,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            if (!isLeftRail)
                                              const SizedBox(width: 8),
                                            if (!isLeftRail &&
                                                !kIsWeb &&
                                                (Platform.isWindows ||
                                                    Platform.isMacOS ||
                                                    Platform.isLinux)) ...[
                                              OutlinedButton.icon(
                                                onPressed: isAnyOperation
                                                    ? null
                                                    : () async {
                                                        await Navigator.of(
                                                          context,
                                                        ).push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                const SettingsPage(),
                                                          ),
                                                        );
                                                      },
                                                icon: const Icon(
                                                  Icons.settings_outlined,
                                                ),
                                                label: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.settings,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                            ],
                                            if (!isLeftRail)
                                              ElevatedButton.icon(
                                                onPressed:
                                                    (_scanning && !_deepScanning)
                                                    ? _cancelScan
                                                    : isAnyOperation
                                                    ? null
                                                    : () async {
                                                        await _scanAll();
                                                      },
                                                icon: switch (rescanIconState(
                                                  isScanning: isScanning,
                                                  deepScanning: _deepScanning,
                                                  justSucceeded:
                                                      _rescanJustSucceeded,
                                                )) {
                                                  ScanIconState.spinning =>
                                                    const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  ScanIconState.justSucceeded =>
                                                    const Icon(
                                                      Icons.check,
                                                      color: Colors.green,
                                                    ),
                                                  ScanIconState.idle =>
                                                    const Icon(Icons.refresh),
                                                },
                                                label: Text(
                                                  (_scanning && !_deepScanning)
                                                      ? AppLocalizations.of(
                                                          context,
                                                        )!.cancel
                                                      : (isScanning &&
                                                            !_deepScanning)
                                                      ? AppLocalizations.of(
                                                          context,
                                                        )!.scanning
                                                      : AppLocalizations.of(
                                                          context,
                                                        )!.rescan,
                                                ),
                                              ),
                                            if (!isLeftRail) ...[
                                              const SizedBox(width: 12),
                                              ElevatedButton.icon(
                                                onPressed: isAnyOperation
                                                    ? null
                                                    : () async {
                                                        bool onlyUnscanned =
                                                            true;
                                                        final confirm = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => StatefulBuilder(
                                                            builder: (ctx, setDialogState) => AlertDialog(
                                                              backgroundColor:
                                                                  Theme.of(
                                                                    context,
                                                                  ).cardColor,
                                                              title: Text(
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.deepScan,
                                                              ),
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    AppLocalizations.of(
                                                                      context,
                                                                    )!.deepScanConfirm,
                                                                  ),
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    child: TextButton.icon(
                                                                      onPressed: () => Navigator.of(context).push(
                                                                        MaterialPageRoute(
                                                                          builder: (_) =>
                                                                              const MetadataExtractionInfoPage(),
                                                                        ),
                                                                      ),
                                                                      icon: const Icon(
                                                                        Icons
                                                                            .table_chart_outlined,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                      label: Text(
                                                                        AppLocalizations.of(
                                                                          context,
                                                                        )!.deepScanViewSupportedDaws,
                                                                      ),
                                                                      style: TextButton.styleFrom(
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        minimumSize:
                                                                            Size.zero,
                                                                        tapTargetSize:
                                                                            MaterialTapTargetSize.shrinkWrap,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 12,
                                                                  ),
                                                                  CheckboxListTile(
                                                                    value:
                                                                        onlyUnscanned,
                                                                    onChanged: (v) => setDialogState(
                                                                      () => onlyUnscanned =
                                                                          v ??
                                                                          true,
                                                                    ),
                                                                    title: Text(
                                                                      AppLocalizations.of(
                                                                        context,
                                                                      )!.deepScanOnlyUnscanned,
                                                                    ),
                                                                    controlAffinity:
                                                                        ListTileControlAffinity
                                                                            .leading,
                                                                    contentPadding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                  ),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                        ctx,
                                                                        false,
                                                                      ),
                                                                  child: Text(
                                                                    AppLocalizations.of(
                                                                      context,
                                                                    )!.cancel,
                                                                  ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                        ctx,
                                                                        true,
                                                                      ),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor:
                                                                        Theme.of(
                                                                          context,
                                                                        ).colorScheme.primary,
                                                                  ),
                                                                  child: Text(
                                                                    AppLocalizations.of(
                                                                      context,
                                                                    )!.deepScan,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                        if (confirm == true) {
                                                          await _fullScanAll(
                                                            onlyUnscanned:
                                                                onlyUnscanned,
                                                          );
                                                        }
                                                      },
                                                icon: switch (deepScanIconState(
                                                  deepScanning: _deepScanning,
                                                  justSucceeded:
                                                      _deepScanJustSucceeded,
                                                )) {
                                                  ScanIconState.spinning =>
                                                    const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  ScanIconState.justSucceeded =>
                                                    const Icon(
                                                      Icons.check,
                                                      color: Colors.green,
                                                    ),
                                                  ScanIconState.idle =>
                                                    const Icon(Icons.search),
                                                },
                                                label: Text(
                                                  _deepScanning
                                                      ? AppLocalizations.of(
                                                          context,
                                                        )!.scanning
                                                      : AppLocalizations.of(
                                                          context,
                                                        )!.deepScan,
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        // Google Drive sync (hidden when left rail — shown there instead).
                                        // Not offered inside Flatpak — see
                                        // GoogleDriveSyncService.isSupported.
                                        if (!MobileUtils.isMobile() &&
                                            !isLeftRail &&
                                            GoogleDriveSyncService.isSupported)
                                          Tooltip(
                                            message: AppLocalizations.of(
                                              context,
                                            )!.syncWithGoogleDrive,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.cloud_outlined,
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          const SettingsPage(
                                                            initialSection:
                                                                SettingsSection
                                                                    .backup,
                                                          ),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        if (!MobileUtils.isMobile() &&
                                            !isLeftRail)
                                          Tooltip(
                                            message: AppLocalizations.of(
                                              context,
                                            )!.createProjectTooltip,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons
                                                    .create_new_folder_outlined,
                                              ),
                                              onPressed: () => showDialog<String>(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (_) =>
                                                    const CreateProjectDialog(),
                                              ),
                                            ),
                                          ),
                                        if (!MobileUtils.isMobile() &&
                                            !isLeftRail)
                                          Tooltip(
                                            message: AppLocalizations.of(
                                              context,
                                            )!.projectTemplates,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.folder_copy_outlined,
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          const ProjectTemplatesPage(),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        const SizedBox(width: 16),
                                        // Active DAW session chip / idle suggestions.
                                        // Fixed height prevents the bar from resizing when the chip appears.
                                        SizedBox(
                                          height: 56,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Consumer(
                                              builder: (ctx, cRef, _) {
                                                final active = cRef.watch(
                                                  activeProjectProvider,
                                                );
                                                final suggestionsOn = cRef.watch(
                                                  suggestionsEnabledProvider,
                                                );
                                                if (active != null)
                                                  return const _ActiveProjectChip();
                                                if (suggestionsOn) {
                                                  return const _SessionIdleSuggestions();
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Search bar (desktop only — hidden on Playlists tab)
                                        if (!MobileUtils.isMobile())
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                ClipRect(
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                    width:
                                                        (isLeftRail ||
                                                            _isSearchingDesktop)
                                                        ? 400
                                                        : 0,
                                                    child: Focus(
                                                      onKeyEvent: (node, event) {
                                                        if (event
                                                                is KeyDownEvent &&
                                                            event.logicalKey ==
                                                                LogicalKeyboardKey
                                                                    .escape) {
                                                          _collapseDesktopSearch();
                                                          return KeyEventResult
                                                              .handled;
                                                        }
                                                        return KeyEventResult
                                                            .ignored;
                                                      },
                                                      child: TextField(
                                                        focusNode:
                                                            _searchFocusNode,
                                                        controller:
                                                            _searchController,
                                                        decoration: InputDecoration(
                                                          hintText: () {
                                                            final base = switch (_currentTab) {
                                                              AppTab.projects =>
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.searchProjects,
                                                              AppTab.releases =>
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.searchReleases,
                                                              AppTab.queue =>
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.queueSearchHint,
                                                              _ =>
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.statsSearchProjects,
                                                            };
                                                            if (!isLeftRail)
                                                              return base;
                                                            final shortcut =
                                                                Platform.isMacOS
                                                                ? '⌘F'
                                                                : 'Ctrl+F';
                                                            return '$base ($shortcut)';
                                                          }(),
                                                          isDense: true,
                                                          border:
                                                              const OutlineInputBorder(),
                                                          prefixIcon:
                                                              const Icon(
                                                                Icons.search,
                                                              ),
                                                          suffixIcon: isLeftRail
                                                              ? (_searchController
                                                                        .text
                                                                        .isNotEmpty
                                                                    ? IconButton(
                                                                        icon: const Icon(
                                                                          Icons
                                                                              .close,
                                                                          size:
                                                                              18,
                                                                        ),
                                                                        tooltip: AppLocalizations.of(
                                                                          context,
                                                                        )!.clear,
                                                                        onPressed: () {
                                                                          _searchController
                                                                              .clear();
                                                                          _updateCurrentTabSearch(
                                                                            '',
                                                                          );
                                                                        },
                                                                      )
                                                                    : null)
                                                              : IconButton(
                                                                  icon: const Icon(
                                                                    Icons.close,
                                                                    size: 18,
                                                                  ),
                                                                  onPressed:
                                                                      _collapseDesktopSearch,
                                                                ),
                                                        ),
                                                        onChanged:
                                                            _updateCurrentTabSearch,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (!isLeftRail)
                                                  Tooltip(
                                                    message:
                                                        '${AppLocalizations.of(context)!.searchProjects} (${Platform.isMacOS ? 'Cmd+F' : 'Ctrl+F'})',
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.search,
                                                      ),
                                                      onPressed:
                                                          _focusSearchAndSelectAll,
                                                    ),
                                                  ),
                                                const SizedBox(width: 4),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                            );
                          },
                        );

                        // Title bar (Windows/Linux) or traffic-light spacer (macOS).
                        final titleBar = DesktopTitleBar(
                          title: AppLocalizations.of(
                            context,
                          )!.appTitleWithVersion(appVersion),
                          actions: [
                            // Donate button
                            Consumer(
                              builder: (context, ref, child) {
                                final l10n = AppLocalizations.of(context)!;
                                return Tooltip(
                                  message: l10n.supportTheProject,
                                  child: TextButton.icon(
                                    icon: Icon(
                                      Icons.card_giftcard,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    ),
                                    label: Text(
                                      l10n.support,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onPressed: () async {
                                      final uri = Uri.parse(
                                        'https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL',
                                      );
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            const ThemeSwitcher(),
                            const SizedBox(width: 8),
                            const LanguageSwitcher(),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: AppLocalizations.of(
                                context,
                              )!.menuDocumentation,
                              child: IconButton(
                                icon: Icon(
                                  Icons.menu_book_outlined,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                                onPressed: () => launchUrl(
                                  Uri.parse(
                                    'https://dpm.bandpassrecords.com/docs.html',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: AppLocalizations.of(
                                context,
                              )!.keyboardShortcuts,
                              child: IconButton(
                                icon: Icon(
                                  Icons.keyboard_outlined,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                                onPressed: () =>
                                    showShortcutsHelpDialog(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: AppLocalizations.of(
                                context,
                              )!.customizeTabs,
                              child: IconButton(
                                icon: Icon(
                                  Icons.tab_outlined,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                                onPressed: () =>
                                    showTabCustomizationDialog(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        );

                        final col = Column(
                          children: [
                            // Kept here when not using the left rail. When the left rail is
                            // active, the title bar is either hoisted (Windows/Linux) or omitted
                            // from the content column entirely (macOS — traffic-light clearance is
                            // in the rail's leading instead).
                            if (!isLeftRail) titleBar,

                            actionBar,

                            // Zero-height anchor used to position the suggestions overlay.
                            if (!MobileUtils.isMobile())
                              SizedBox(
                                key: _suggestionsPanelAnchorKey,
                                height: 0,
                              ),

                            // Project folders are managed in the dedicated desktop-only settings page.
                            // Tab Bar (desktop only - mobile uses AppBar bottom)
                            if (!MobileUtils.isMobile() &&
                                ref.watch(tabPositionProvider) ==
                                    TabPosition.top)
                              Builder(
                                builder: (context) => TabBar(
                                  controller: _tabController,
                                  tabs: [
                                    for (final tab in _currentVisibleTabs)
                                      switch (tab) {
                                        AppTab.projects => Tab(
                                          icon: const Icon(Icons.library_music),
                                          text: AppLocalizations.of(
                                            context,
                                          )!.projectsTab,
                                        ),
                                        AppTab.releases => Tab(
                                          icon: const Icon(Icons.album),
                                          text: AppLocalizations.of(
                                            context,
                                          )!.releasesTab,
                                        ),
                                        AppTab.playlists => Tab(
                                          icon: const Icon(Icons.playlist_play),
                                          text: AppLocalizations.of(
                                            context,
                                          )!.playlists,
                                        ),
                                        AppTab.queue => Tab(
                                          icon: const Icon(Icons.checklist),
                                          text: AppLocalizations.of(
                                            context,
                                          )!.queueTab,
                                        ),
                                        AppTab.statistics => Tab(
                                          icon: const Icon(
                                            Icons.bar_chart_rounded,
                                          ),
                                          text: AppLocalizations.of(
                                            context,
                                          )!.statisticsTab,
                                        ),
                                        AppTab.player => const Tab(
                                          icon: Icon(Icons.headphones),
                                          text: 'Music Player',
                                        ),
                                      },
                                  ],
                                  labelColor: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.color,
                                  unselectedLabelColor: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                  indicatorColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                              ),
                            // Tab Bar View (with optional left NavigationRail)
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final tabView = TabBarView(
                                    controller: _tabController,
                                    // Tabs are switched via the NavigationBar/rail or the tab
                                    // bar itself; swiping or trackpad/mouse-wheel horizontal
                                    // scroll between them is easy to trigger by accident while
                                    // scrolling a list, so the gesture is disabled everywhere,
                                    // not just on mobile.
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      for (final tab in _currentVisibleTabs)
                                        switch (tab) {
                                          AppTab.projects => Column(
                                            children: [
                                              const _PendingFoldersSection(),
                                              Expanded(
                                                child: MobileUtils.isMobile()
                                                    ? _MobileProjectsList(
                                                        projects: projects,
                                                        dateFormat: dateFormat,
                                                        onCreateRelease:
                                                            (selectedProjects) {
                                                              _createReleaseFromSelectedProjects(
                                                                context,
                                                                ref,
                                                                selectedProjects,
                                                              );
                                                            },
                                                        onStackProjects:
                                                            (
                                                              selectedProjects,
                                                            ) async {
                                                              await _stackSelectedProjects(
                                                                context,
                                                                ref,
                                                                selectedProjects,
                                                              );
                                                            },
                                                        onHideProjects:
                                                            (
                                                              selectedProjectIds,
                                                            ) async {
                                                              await _hideProjects(
                                                                context,
                                                                ref,
                                                                selectedProjectIds,
                                                              );
                                                            },
                                                        onUnhideProjects:
                                                            (
                                                              selectedProjectIds,
                                                            ) async {
                                                              await _unhideProjects(
                                                                context,
                                                                ref,
                                                                selectedProjectIds,
                                                              );
                                                            },
                                                        // No onDeleteMissingProjects here: mobile projects are
                                                        // metadata-only entries synced via Drive, not local files
                                                        // (see FolderWatcher/_scanAll comments) — every one of them
                                                        // would spuriously read as "missing" by a File.existsSync()
                                                        // check against a desktop path, so the concept (and the
                                                        // "cloud_off" indicator it's paired with) is desktop-only.
                                                        showHidden:
                                                            hiddenMode == 1 ||
                                                            hiddenMode == 2,
                                                        onRefresh: () =>
                                                            _refreshMobileProjects(),
                                                      )
                                                    : _PlutoProjectsTableWithSelection(
                                                        key: _tableKey,
                                                        projects: projects,
                                                        dateFormat: dateFormat,
                                                        onCreateRelease:
                                                            (selectedProjects) {
                                                              _createReleaseFromSelectedProjects(
                                                                context,
                                                                ref,
                                                                selectedProjects,
                                                              );
                                                            },
                                                        onStackProjects:
                                                            (
                                                              selectedProjects,
                                                            ) async {
                                                              await _stackSelectedProjects(
                                                                context,
                                                                ref,
                                                                selectedProjects,
                                                              );
                                                            },
                                                        onHideProjects:
                                                            (
                                                              selectedProjectIds,
                                                            ) async {
                                                              await _hideProjects(
                                                                context,
                                                                ref,
                                                                selectedProjectIds,
                                                              );
                                                            },
                                                        onUnhideProjects:
                                                            (
                                                              selectedProjectIds,
                                                            ) async {
                                                              await _unhideProjects(
                                                                context,
                                                                ref,
                                                                selectedProjectIds,
                                                              );
                                                            },
                                                        onDeleteMissingProjects:
                                                            (
                                                              selectedProjectIds,
                                                            ) async {
                                                              await _deleteMissingProjects(
                                                                context,
                                                                ref,
                                                                selectedProjectIds,
                                                              );
                                                            },
                                                        showHidden:
                                                            hiddenMode == 1 ||
                                                            hiddenMode == 2,
                                                        onExtractingMetadataChanged:
                                                            (extracting) {
                                                              setState(
                                                                () => _extractingMetadata =
                                                                    extracting,
                                                              );
                                                            },
                                                        isAnyOperation:
                                                            isAnyOperation,
                                                        visibleCount:
                                                            visibleCount,
                                                        hiddenCount:
                                                            hiddenCount,
                                                      ),
                                              ),
                                            ],
                                          ),
                                          AppTab.releases =>
                                            const ReleasesTabPage(),
                                          AppTab.playlists =>
                                            const PlaylistsPage(),
                                          AppTab.queue => const QueuePage(),
                                          AppTab.statistics =>
                                            const StatisticsPage(),
                                          AppTab.player =>
                                            const MusicPlayerPage(),
                                        },
                                    ],
                                  );
                                  return tabView;
                                },
                              ),
                            ),
                          ],
                        );
                        if (!isLeftRail) return col;
                        final row = Row(
                          children: [
                            NavigationRail(
                              selectedIndex: _tabController.index,
                              onDestinationSelected: (i) =>
                                  _tabController.animateTo(i),
                              minWidth: railCollapsed
                                  ? (Platform.isMacOS ? 80.0 : 64.0)
                                  : _railWidth,
                              labelType: railCollapsed
                                  ? NavigationRailLabelType.none
                                  : NavigationRailLabelType.all,
                              leading: Column(
                                children: [
                                  // Clear macOS traffic-light buttons (float over top-left).
                                  if (Platform.isMacOS)
                                    const SizedBox(height: 28),
                                  // Collapse/expand toggle
                                  Tooltip(
                                    message: railCollapsed
                                        ? AppLocalizations.of(context)!.expand
                                        : AppLocalizations.of(
                                            context,
                                          )!.collapse,
                                    child: IconButton(
                                      icon: Icon(
                                        railCollapsed
                                            ? Icons.chevron_right
                                            : Icons.chevron_left,
                                      ),
                                      onPressed: () {
                                        if (railCollapsed)
                                          setState(() => _railWidth = 130.0);
                                        ref
                                            .read(
                                              railCollapsedProvider.notifier,
                                            )
                                            .set(!railCollapsed);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Profile avatar + name
                                  Consumer(
                                    builder: (ctx, ref, _) {
                                      final profile = ref
                                          .watch(currentProfileProvider)
                                          .value;
                                      final hasPhoto =
                                          profile?.photoPath != null &&
                                          File(
                                            profile!.photoPath!,
                                          ).existsSync();
                                      const avatarSize = 44.0;
                                      final Widget avatar = hasPhoto
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    avatarSize,
                                                  ),
                                              child: Image.file(
                                                File(profile.photoPath!),
                                                width: avatarSize,
                                                height: avatarSize,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              width: avatarSize,
                                              height: avatarSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                size: 26,
                                              ),
                                            );
                                      final inkWell = InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ProfileManagerPage(),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 4,
                                          ),
                                          child: railCollapsed
                                              ? avatar
                                              : Column(
                                                  children: [
                                                    avatar,
                                                    if (profile?.name !=
                                                        null) ...[
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        width: _railWidth - 24,
                                                        child: Text(
                                                          profile!.name,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelSmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                        ),
                                      );
                                      return inkWell;
                                    },
                                  ),
                                  // Quick profile switch (multiple profiles only)
                                  Consumer(
                                    builder: (ctx, ref, _) {
                                      final allProfiles = ref
                                          .watch(allProfilesProvider)
                                          .value;
                                      if (allProfiles == null ||
                                          allProfiles.length < 2) {
                                        return const SizedBox.shrink();
                                      }
                                      return IconButton(
                                        icon: const Icon(
                                          Icons.swap_horiz,
                                          size: 18,
                                        ),
                                        tooltip: AppLocalizations.of(
                                          context,
                                        )!.switchProfile,
                                        onPressed: () =>
                                            _quickSwitchProfile(context),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                              destinations: [
                                for (final tab in _currentVisibleTabs)
                                  switch (tab) {
                                    AppTab.projects =>
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.library_music),
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.projectsTab,
                                        ),
                                      ),
                                    AppTab.releases =>
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.album),
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.releasesTab,
                                        ),
                                      ),
                                    AppTab.playlists =>
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.playlist_play),
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.playlists,
                                        ),
                                      ),
                                    AppTab.queue => NavigationRailDestination(
                                      icon: const Icon(Icons.checklist),
                                      label: Text(
                                        AppLocalizations.of(context)!.queueTab,
                                      ),
                                    ),
                                    AppTab.statistics =>
                                      NavigationRailDestination(
                                        icon: const Icon(
                                          Icons.bar_chart_rounded,
                                        ),
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.statisticsTab,
                                        ),
                                      ),
                                    AppTab.player => NavigationRailDestination(
                                      icon: const Icon(Icons.headphones),
                                      label: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.musicPlayerTab,
                                      ),
                                    ),
                                  },
                              ],
                              trailing: Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Create new project
                                        RailAction(
                                          icon: const Icon(
                                            Icons.create_new_folder_outlined,
                                          ),
                                          label: AppLocalizations.of(
                                            context,
                                          )!.createProject,
                                          showLabel: !railCollapsed,
                                          onPressed: () {
                                            showDialog<String>(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) =>
                                                  const CreateProjectDialog(),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        // Manage project templates
                                        RailAction(
                                          icon: const Icon(
                                            Icons.folder_copy_outlined,
                                          ),
                                          label: AppLocalizations.of(
                                            context,
                                          )!.projectTemplates,
                                          showLabel: !railCollapsed,
                                          onPressed: () =>
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ProjectTemplatesPage(),
                                                ),
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Google Drive sync — not offered
                                        // inside Flatpak, see
                                        // GoogleDriveSyncService.isSupported.
                                        if (GoogleDriveSyncService.isSupported)
                                          RailAction(
                                            icon: const Icon(
                                              Icons.cloud_outlined,
                                            ),
                                            label: AppLocalizations.of(
                                              context,
                                            )!.googleDrive,
                                            showLabel: !railCollapsed,
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const SettingsPage(
                                                          initialSection:
                                                              SettingsSection
                                                                  .backup,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        const SizedBox(height: 8),
                                        // Rescan
                                        RailAction(
                                          icon: switch (rescanIconState(
                                            isScanning: isScanning,
                                            deepScanning: _deepScanning,
                                            justSucceeded: _rescanJustSucceeded,
                                          )) {
                                            ScanIconState.spinning =>
                                              const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ScanIconState.justSucceeded =>
                                              const Icon(
                                                Icons.check,
                                                color: Colors.green,
                                              ),
                                            ScanIconState.idle => const Icon(
                                              Icons.refresh,
                                            ),
                                          },
                                          label: (_scanning && !_deepScanning)
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.cancel
                                              : (isScanning && !_deepScanning)
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.scanning
                                              : AppLocalizations.of(
                                                  context,
                                                )!.rescan,
                                          showLabel: !railCollapsed,
                                          onPressed: (_scanning && !_deepScanning)
                                              ? _cancelScan
                                              : isAnyOperation
                                              ? null
                                              : () => _scanAll(),
                                        ),
                                        const SizedBox(height: 8),
                                        // Deep scan
                                        RailAction(
                                          icon: switch (deepScanIconState(
                                            deepScanning: _deepScanning,
                                            justSucceeded:
                                                _deepScanJustSucceeded,
                                          )) {
                                            ScanIconState.spinning =>
                                              const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ScanIconState.justSucceeded =>
                                              const Icon(
                                                Icons.check,
                                                color: Colors.green,
                                              ),
                                            ScanIconState.idle => const Icon(
                                              Icons.search,
                                            ),
                                          },
                                          label: AppLocalizations.of(
                                            context,
                                          )!.deepScan,
                                          showLabel: !railCollapsed,
                                          onPressed: isAnyOperation
                                              ? null
                                              : () async {
                                                  bool onlyUnscanned = true;
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => StatefulBuilder(
                                                      builder: (ctx, setDialogState) => AlertDialog(
                                                        backgroundColor:
                                                            Theme.of(
                                                              context,
                                                            ).cardColor,
                                                        title: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.deepScan,
                                                        ),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.deepScanConfirm,
                                                            ),
                                                            Align(
                                                              alignment: Alignment
                                                                  .centerLeft,
                                                              child: TextButton.icon(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).push(
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (
                                                                              _,
                                                                            ) =>
                                                                                const MetadataExtractionInfoPage(),
                                                                      ),
                                                                    ),
                                                                icon: const Icon(
                                                                  Icons
                                                                      .table_chart_outlined,
                                                                  size: 18,
                                                                ),
                                                                label: Text(
                                                                  AppLocalizations.of(
                                                                    context,
                                                                  )!.deepScanViewSupportedDaws,
                                                                ),
                                                                style: TextButton.styleFrom(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  minimumSize:
                                                                      Size.zero,
                                                                  tapTargetSize:
                                                                      MaterialTapTargetSize
                                                                          .shrinkWrap,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 12,
                                                            ),
                                                            CheckboxListTile(
                                                              value:
                                                                  onlyUnscanned,
                                                              onChanged: (v) =>
                                                                  setDialogState(
                                                                    () =>
                                                                        onlyUnscanned =
                                                                            v ??
                                                                            true,
                                                                  ),
                                                              title: Text(
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.deepScanOnlyUnscanned,
                                                              ),
                                                              controlAffinity:
                                                                  ListTileControlAffinity
                                                                      .leading,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  false,
                                                                ),
                                                            child: Text(
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.cancel,
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  true,
                                                                ),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary,
                                                            ),
                                                            child: Text(
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.deepScan,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                  if (confirm == true)
                                                    await _fullScanAll(
                                                      onlyUnscanned:
                                                          onlyUnscanned,
                                                    );
                                                },
                                        ),
                                        const SizedBox(height: 8),
                                        // Settings
                                        RailAction(
                                          icon: const Icon(
                                            Icons.settings_outlined,
                                          ),
                                          label: AppLocalizations.of(
                                            context,
                                          )!.settings,
                                          showLabel: !railCollapsed,
                                          onPressed: () =>
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const SettingsPage(),
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Drag handle to resize the rail
                            MouseRegion(
                              cursor: SystemMouseCursors.resizeColumn,
                              child: GestureDetector(
                                onHorizontalDragUpdate: railCollapsed
                                    ? null
                                    : (details) => setState(() {
                                        _railWidth =
                                            (_railWidth + details.delta.dx)
                                                .clamp(120.0, 400.0);
                                      }),
                                child: Container(
                                  width: 6,
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Container(
                                      width: 1,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(child: col),
                          ],
                        );
                        // On Windows/Linux hoist the title bar above the Row so the
                        // NavigationRail background starts below the window chrome.
                        // On macOS the rail extends to the top — the traffic-light
                        // clearance SizedBox is in the rail's leading instead.
                        return Column(
                          children: [
                            if (!Platform.isMacOS) titleBar,
                            Expanded(child: row),
                          ],
                        );
                      },
                    ),
                  ),
                  // Loading overlay
                  if (blockingOperation)
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
                                ...(_deepScanning && _scanProgressTotal > 0
                                    ? [
                                        SizedBox(
                                          width: 260,
                                          child: LinearProgressIndicator(
                                            value:
                                                _scanProgressCurrent /
                                                _scanProgressTotal,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.scanProgressLabel(
                                            _scanProgressCurrent,
                                            _scanProgressTotal,
                                          ),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ]
                                    : [
                                        const CircularProgressIndicator(),
                                        const SizedBox(height: 16),
                                        Text(
                                          isProfileSwitching
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.switchingProfiles
                                              : AppLocalizations.of(
                                                  context,
                                                )!.scanningProjects,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ]),
                                // Deep scan's enumeration phase goes through
                                // the same scanner.scanDirectory() call as a
                                // regular scan, so it's vulnerable to the
                                // same runaway-hang case — and unlike a
                                // regular scan, this overlay blocks the UI,
                                // so a way out matters even more here.
                                if (_deepScanning) ...[
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _cancelScan,
                                    child: Text(
                                      AppLocalizations.of(context)!.cancel,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlutoProjectsTableWithSelection extends ConsumerStatefulWidget {
  final List<MusicProject> projects;
  final DateFormat dateFormat;
  final Function(List<MusicProject>) onCreateRelease;
  final Function(List<MusicProject>) onStackProjects;
  final Function(List<String>) onHideProjects;
  final Function(List<String>) onUnhideProjects;
  final Function(List<String>) onDeleteMissingProjects;
  final bool showHidden;
  final Function(bool) onExtractingMetadataChanged;
  final bool isAnyOperation;
  final int visibleCount;
  final int hiddenCount;

  const _PlutoProjectsTableWithSelection({
    super.key,
    required this.projects,
    required this.dateFormat,
    required this.onCreateRelease,
    required this.onStackProjects,
    required this.onHideProjects,
    required this.onUnhideProjects,
    required this.onDeleteMissingProjects,
    required this.showHidden,
    required this.onExtractingMetadataChanged,
    required this.isAnyOperation,
    required this.visibleCount,
    required this.hiddenCount,
  });

  @override
  ConsumerState<_PlutoProjectsTableWithSelection> createState() =>
      _PlutoProjectsTableWithSelectionState();
}

class _PlutoProjectsTableWithSelectionState
    extends ConsumerState<_PlutoProjectsTableWithSelection> {
  final _innerTableKey = GlobalKey<_PlutoProjectsTableState>();
  final _groupExpandState = ValueNotifier<({bool hasGroups, bool anyExpanded})>(
    (hasGroups: false, anyExpanded: false),
  );

  @override
  void didUpdateWidget(_PlutoProjectsTableWithSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rows can leave the list while they are selected — stacking turns a
    // project into a stack member and collapses it out of the list, and
    // hiding or deleting do the same. The id has to leave the selection with
    // the row, or the action bar counts rows that are nowhere on screen.
    if (!identical(oldWidget.projects, widget.projects)) {
      // Deferred: didUpdateWidget runs during the build phase, and Riverpod
      // forbids provider writes at that point.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(selectedProjectsProvider.notifier)
            .retainAll(widget.projects.map((p) => p.id));
      });
    }
  }

  @override
  void dispose() {
    _groupExpandState.dispose();
    super.dispose();
  }

  void focusTable() => _innerTableKey.currentState?.focusTable();

  Set<String> get _selectedProjectIds => ref.watch(selectedProjectsProvider);

  /// Ctrl/cmd- and shift-click selection for this table, shared with every
  /// other table in the app (see `row_click_selection.dart`).
  late final _clickSelection = RowClickSelectionController(
    notifier: () => ref.read(selectedProjectsProvider.notifier),
    selectedIds: () => ref.read(selectedProjectsProvider),
    orderedIds: () => widget.projects.map((p) => p.id).toList(),
  );

  void _clearSelection() => _clickSelection.clear();

  bool get _areAllSelected {
    if (widget.projects.isEmpty) return false;
    return _selectedProjectIds.length == widget.projects.length &&
        widget.projects.every((p) => _selectedProjectIds.contains(p.id));
  }

  /// Selects or deselects every project inside one smart-folder group,
  /// leaving the rest of the current selection untouched (unlike the header
  /// "select all", which is a global select-everything/clear-everything
  /// toggle). Lets a user pick a single group's checkbox to bulk-edit just
  /// that folder — e.g. move every project in it to a new phase — without
  /// first selecting everything else and without needing the group expanded.
  String _sortFieldLabel(AppLocalizations l10n, ProjectSortField field) =>
      switch (field) {
        ProjectSortField.lastModified => l10n.sortByLastModified,
        ProjectSortField.name => l10n.sortByName,
        ProjectSortField.phase => l10n.sortByPhase,
        ProjectSortField.createdAt => l10n.sortByCreatedAt,
        ProjectSortField.bpm => l10n.sortByBpm,
        ProjectSortField.deadline => l10n.sortByDeadline,
      };

  void _toggleGroupSelection(Set<String> groupProjectIds) {
    if (groupProjectIds.isEmpty) return;
    if (groupCheckboxShouldSelect(groupProjectIds, _selectedProjectIds)) {
      _clickSelection.addAll(groupProjectIds.toList());
    } else {
      _clickSelection.removeAll(groupProjectIds.toList());
    }
  }

  Future<void> _showChangeStatusDialog(BuildContext context) async {
    String? selectedStatus;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.changeStatus),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.selectNewStatus),
              const SizedBox(height: 16),
              ...ref
                  .read(customPhasesProvider)
                  .map(
                    (phase) => RadioListTile<String>(
                      title: Text(phase),
                      value: phase,
                      groupValue: selectedStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                  ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: selectedStatus == null
                  ? null
                  : () => Navigator.pop(ctx, selectedStatus),
              child: Text(AppLocalizations.of(context)!.changeStatus),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _changeProjectsStatus(context, result);
    }
  }

  Future<void> _changeProjectsStatus(
    BuildContext context,
    String newStatus,
  ) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final allProjectsAsync = ref.read(allProjectsStreamProvider);
      final allProjects = allProjectsAsync.value ?? [];

      int successCount = 0;
      int failCount = 0;

      for (final projectId in _selectedProjectIds) {
        try {
          final project = allProjects.firstWhere((p) => p.id == projectId);
          // Track when status changes
          final statusChanged = project.status != newStatus;
          final updated = project.copyWith(
            status: newStatus,
            statusChangedAt: statusChanged ? DateTime.now() : null,
          );
          await repo.updateProject(updated);
          successCount++;
        } catch (e) {
          failCount++;
          if (kDebugMode) {
            print('Failed to update project $projectId: $e');
          }
        }
      }

      // Refresh the projects list
      ref.invalidate(allProjectsStreamProvider);

      if (mounted) {
        final statusText = _translateStatus(context, newStatus);
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.statusChangedForProjects(
                  successCount,
                  successCount == 1 ? '' : 's',
                  statusText,
                ),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.statusChangedForProjectsWithErrors(
                  successCount,
                  successCount == 1 ? '' : 's',
                  failCount,
                  failCount == 1 ? '' : 's',
                  statusText,
                ),
              ),
            ),
          );
        }
      }

      _clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToChangeStatus(e.toString()),
            ),
          ),
        );
      }
    }
  }

  String _translateStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'Idea':
        return l10n.projectPhaseIdea;
      case 'Arranging':
        return l10n.projectPhaseArranging;
      case 'Mixing':
        return l10n.projectPhaseMixing;
      case 'Mastering':
        return l10n.projectPhaseMastering;
      case 'Finished':
        return l10n.projectPhaseFinished;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hiddenMode = ref.watch(showHiddenProjectsProvider);
    final hiddenNotifier = ref.read(showHiddenProjectsProvider.notifier);
    final finishedMode = ref.watch(showFinishedProjectsProvider);
    final finishedNotifier = ref.read(showFinishedProjectsProvider.notifier);
    final phaseFilter = ref.watch(phaseFilterProvider);
    final customPhases = ref.watch(customPhasesProvider);
    final dawFilter = ref.watch(dawFilterProvider);
    final availableDaws = ref.watch(availableDawsProvider);
    final scanRoots = ref.watch(scanRootsProvider);
    final viewMode = ref.watch(dashboardViewModeProvider);
    final cardSort = ref.watch(dashboardCardSortProvider);
    final l10n = AppLocalizations.of(context)!;

    // Filtering an empty grid makes no sense — hide the whole filter bar
    // whenever there are no projects yet, even if scan roots are already
    // configured (e.g. a freshly added root that hasn't found anything),
    // rather than showing dropdowns and checkboxes with nothing to act on.
    // Uses the raw, unfiltered project count (not the currently-displayed
    // one) so a legitimate search filtered down to zero results doesn't
    // also hide the filter bar that could clear it.
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);
    final hasAnyProjects = allProjectsAsync.value?.isNotEmpty ?? false;

    return Column(
      children: [
        // Filter bar
        if (hasAnyProjects)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Project count — all three mode variants are stacked and
                // rendered simultaneously; only the active one is opaque.
                // The Stack always sizes to the widest variant so the bar
                // never shifts regardless of which mode is active.
                Stack(
                  children: [
                    // Mode 0: "X projects (N hidden)"
                    Opacity(
                      opacity: hiddenMode == 0 ? 1.0 : 0.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.projectsCount(widget.visibleCount),
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (widget.hiddenCount > 0)
                            Text(
                              ' ${l10n.hiddenCount(widget.hiddenCount)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    // Mode 1: "X projects" (show-all — visible count only)
                    Opacity(
                      opacity: hiddenMode == 1 ? 1.0 : 0.0,
                      child: Text(
                        l10n.projectsCount(widget.visibleCount),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    // Mode 2: "N projects hidden only"
                    if (widget.hiddenCount > 0)
                      Opacity(
                        opacity: hiddenMode == 2 ? 1.0 : 0.0,
                        child: Text(
                          '${l10n.projectsCount(widget.hiddenCount)} ${l10n.hiddenOnly}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade300,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                if (widget.hiddenCount > 0) ...[
                  InkWell(
                    onTap: () {
                      if (hiddenMode == 1) {
                        hiddenNotifier.setShowAll(false);
                      } else {
                        hiddenNotifier.setShowAll(true);
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: hiddenMode == 1,
                          onChanged: (value) {
                            if (value == true) {
                              hiddenNotifier.setShowAll(true);
                            } else {
                              hiddenNotifier.setShowAll(false);
                            }
                          },
                        ),
                        Text(
                          l10n.showHidden,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stack keeps the button at the width of whichever label
                  // is wider — the ghost (opposite label, opacity 0) pins the
                  // layout; the Stack always takes the max of both children.
                  Stack(
                    children: [
                      Opacity(
                        opacity: 0,
                        child: IgnorePointer(
                          child: TextButton.icon(
                            icon: Icon(
                              hiddenMode == 2
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility,
                              size: 16,
                            ),
                            label: Text(
                              hiddenMode == 2
                                  ? l10n.showOnlyHidden
                                  : l10n.showAll,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: hiddenMode != 2
                                  ? Colors.orange.shade700
                                  : null,
                              foregroundColor: hiddenMode != 2
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          hiddenMode == 2
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                          size: 16,
                        ),
                        label: Text(
                          hiddenMode == 2 ? l10n.showAll : l10n.showOnlyHidden,
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: hiddenMode == 2
                              ? Colors.orange.shade700
                              : null,
                          foregroundColor: hiddenMode == 2
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () {
                          if (hiddenMode == 2) {
                            hiddenNotifier.setShowOnlyHidden(false);
                          } else {
                            hiddenNotifier.setShowOnlyHidden(true);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: () {
                    if (finishedMode == 1) {
                      finishedNotifier.setHideFinished(false);
                    } else {
                      finishedNotifier.setHideFinished(true);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: finishedMode == 1,
                        onChanged: (value) {
                          if (value == true) {
                            finishedNotifier.setHideFinished(true);
                          } else {
                            finishedNotifier.setHideFinished(false);
                          }
                        },
                      ),
                      Text(
                        l10n.hideFinished,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final currentValue = ref.read(showOnlyWithDeadlineProvider);
                    ref
                        .read(showOnlyWithDeadlineProvider.notifier)
                        .setShowOnlyWithDeadline(!currentValue);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: ref.watch(showOnlyWithDeadlineProvider),
                        onChanged: (value) {
                          ref
                              .read(showOnlyWithDeadlineProvider.notifier)
                              .setShowOnlyWithDeadline(value == true);
                        },
                      ),
                      Text(
                        l10n.showOnlyDeadlines,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Archived filter (#116). Counted from the unfiltered library
                // rather than from `widget.projects`, which has already had
                // archived rows removed by the default mode — counting there
                // would always give 0 and the control would never appear.
                Builder(
                  builder: (context) {
                    final archivedCount =
                        ref
                            .watch(allProjectsStreamProvider)
                            .value
                            ?.where((p) => p.isArchived)
                            .length ??
                        0;
                    if (archivedCount == 0) return const SizedBox.shrink();
                    final mode = ref.watch(showArchivedProjectsProvider);
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      // A three-state axis reads badly as a checkbox, which is
                      // why this isn't built like the hidden pair beside it.
                      child: FilterDropdown<int>(
                        icon: Icons.archive_outlined,
                        value: mode,
                        hintText: l10n.archivedFilterLabel,
                        items: [
                          DropdownMenuItem<int>(
                            value: 0,
                            child: Text(l10n.hideArchivedProjects),
                          ),
                          DropdownMenuItem<int>(
                            value: 1,
                            child: Text(l10n.showArchivedProjects),
                          ),
                          DropdownMenuItem<int>(
                            value: 2,
                            child: Text(l10n.showOnlyArchivedProjects),
                          ),
                        ],
                        onChanged: (int? value) {
                          final notifier = ref.read(
                            showArchivedProjectsProvider.notifier,
                          );
                          switch (value ?? 0) {
                            case 1:
                              notifier.setShowAll(true);
                            case 2:
                              notifier.setShowOnlyArchived(true);
                            default:
                              notifier.setShowAll(false);
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterDropdown<String>(
                  icon: Icons.filter_list,
                  value: phaseFilter,
                  hintText: l10n.filterByPhase,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(l10n.allPhases),
                    ),
                    ...customPhases.map(
                      (phase) => DropdownMenuItem<String>(
                        value: phase,
                        child: Text(_translateStatus(context, phase)),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    ref.read(phaseFilterProvider.notifier).setPhase(value);
                  },
                ),
                if (availableDaws.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  FilterDropdown<String>(
                    icon: Icons.piano,
                    value: dawFilter,
                    hintText: l10n.filterByDaw,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(l10n.allDaws),
                      ),
                      ...availableDaws.map(
                        (daw) => DropdownMenuItem<String>(
                          value: daw,
                          child: Text(daw),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      ref.read(dawFilterProvider.notifier).setDaw(value);
                    },
                  ),
                ],
                const Spacer(),
                // Cards have no column headers to click, so the order needs
                // its own control. Hidden in table mode, where TrinaGrid's
                // headers already own sorting.
                if (viewMode == DashboardViewMode.cards) ...[
                  Icon(
                    cardSort.descending
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 2),
                  Tooltip(
                    message: l10n.sortByLabel,
                    child: DropdownButton<ProjectSortField>(
                      value: cardSort.field,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: const TextStyle(fontSize: 12),
                      selectedItemBuilder: (context) => [
                        for (final field in ProjectSortField.values)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _sortFieldLabel(l10n, field),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                      ],
                      items: [
                        for (final field in ProjectSortField.values)
                          DropdownMenuItem(
                            value: field,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_sortFieldLabel(l10n, field)),
                                // The field already in use flips direction
                                // when picked again, so show which way it
                                // currently points.
                                if (field == cardSort.field) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    cardSort.descending
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    size: 12,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                      onChanged: (field) {
                        if (field == null) return;
                        ref
                            .read(dashboardCardSortProvider.notifier)
                            .selectField(field);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Table ⇄ cards. Same projects either way — the toggle only
                // changes how the already-filtered list is drawn.
                SegmentedButton<DashboardViewMode>(
                  segments: [
                    ButtonSegment(
                      value: DashboardViewMode.table,
                      icon: const Icon(Icons.table_rows, size: 16),
                      tooltip: l10n.viewModeTable,
                    ),
                    ButtonSegment(
                      value: DashboardViewMode.cards,
                      icon: const Icon(Icons.grid_view, size: 16),
                      tooltip: l10n.viewModeCards,
                    ),
                  ],
                  selected: {viewMode},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onSelectionChanged: (selection) => ref
                      .read(dashboardViewModeProvider.notifier)
                      .set(selection.first),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<({bool hasGroups, bool anyExpanded})>(
                  valueListenable: _groupExpandState,
                  builder: (context, state, _) {
                    // Smart-folder groups are a table shape; the card grid is
                    // flat, so the expand/collapse pair has nothing to act on.
                    if (viewMode == DashboardViewMode.cards ||
                        !state.hasGroups) {
                      return const SizedBox.shrink();
                    }
                    return TextButton.icon(
                      icon: Icon(
                        state.anyExpanded
                            ? Icons.unfold_less
                            : Icons.unfold_more,
                        size: 16,
                      ),
                      label: Text(
                        state.anyExpanded
                            ? '${l10n.collapse} All'
                            : '${l10n.expand} All',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        if (state.anyExpanded) {
                          _innerTableKey.currentState?._collapseAll();
                        } else {
                          _innerTableKey.currentState?._expandAll();
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: viewMode == DashboardViewMode.cards
              ? ProjectCardGrid(
                  // The only thing the card view does to the shared list is
                  // reorder it — filtering and searching stay in
                  // projectsProvider, where both views read them from.
                  projects: sortProjects(
                    widget.projects,
                    cardSort.field,
                    descending: cardSort.descending,
                  ),
                  selectedIds: _selectedProjectIds,
                  activeProjectId: ref.watch(activeProjectProvider)?.id,
                  phaseColor: (phase) => resolvePhaseColor(
                    phase,
                    ref.watch(phaseColorsProvider),
                    customPhases,
                  ),
                  phaseLabel: (phase) => _translateStatus(context, phase),
                  dateFormat: ref.watch(compactDateFormatProvider).format,
                  fileExists: projectFileExists,
                  selectionModifierHeld: selectionModifierHeld,
                  labels: ProjectCardLabels(
                    emptyMessage: l10n.noResultsForFilter,
                    selectTooltip: l10n.selectProject,
                    missingFileTooltip: l10n.sourceFileNotFoundOnThisMachine,
                    bpmTooltip: l10n.bpmInfoLabel,
                    keyTooltip: l10n.keyInfoLabel,
                    today: l10n.today,
                    daysLeft: l10n.daysLeft,
                    daysLate: l10n.daysLate,
                    launchTooltip: l10n.tooltipLaunchInDaw,
                    startSessionTooltip: l10n.startSession,
                    endSessionTooltip: l10n.endSession,
                    openFolderTooltip: l10n.openFolder,
                    playPreviewTooltip: l10n.playPreview,
                    archivedWithLocalCopyTooltip: l10n.archivedWithLocalCopy,
                    archivedAwayTooltip: l10n.archivedAwayTooltip,
                  ),
                  sessionMode: ref.watch(sessionModeProvider),
                  onPrimaryAction: (project) async {
                    // Session mode turns "launch" into "start/end the session
                    // on this project", exactly as the grid row and the
                    // context menu already behave.
                    if (!ref.read(sessionModeProvider)) {
                      await launchProjectFromMenu(context, ref, project);
                      return;
                    }
                    if (!context.mounted) return;
                    if (ref.read(activeProjectProvider)?.id == project.id) {
                      await confirmEndSession(context, ref);
                    } else {
                      await confirmStartSession(context, ref, project);
                    }
                  },
                  onOpenFolder: (project) =>
                      openProjectFolder(context, project),
                  onPlayPreview: (project) =>
                      playProjectPreview(context, ref, project),
                  onOpen: (project) => openProjectDetail(context, project),
                  onToggleSelection: _clickSelection.toggle,
                  onRowClick: _clickSelection.handleRowClick,
                  onHighlight: _clickSelection.handleRowHighlight,
                  onContextMenu: (project, position) => showProjectContextMenu(
                    context: context,
                    ref: ref,
                    project: project,
                    position: position,
                    onHideProjects: widget.onHideProjects,
                    onUnhideProjects: widget.onUnhideProjects,
                    onExtractingMetadataChanged:
                        widget.onExtractingMetadataChanged,
                    includeCardOptions: true,
                  ),
                )
              : _PlutoProjectsTable(
                key: _innerTableKey,
                projects: widget.projects,
                scanRoots: scanRoots,
                dateFormat: widget.dateFormat,
                selectedIds: _selectedProjectIds,
                onToggleSelection: _clickSelection.toggle,
                onRowClickSelection: _clickSelection.handleRowClick,
                onRowHighlighted: _clickSelection.handleRowHighlight,
                onToggleGroupSelection: _toggleGroupSelection,
                onHideProjects: widget.onHideProjects,
                onUnhideProjects: widget.onUnhideProjects,
                areAllSelected: _areAllSelected,
                onToggleSelectAll: () {
                  if (_areAllSelected) {
                    _clickSelection.clear();
                  } else {
                    _clickSelection.selectAll();
                  }
                },
                onExtractingMetadataChanged: widget.onExtractingMetadataChanged,
                isScanning: widget.isAnyOperation,
                groupExpandNotifier: _groupExpandState,
              ),
        ),
        // Selection action bar
        if (_selectedProjectIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.projectsSelected(
                    _selectedProjectIds.length,
                    _selectedProjectIds.length == 1 ? '' : 's',
                  ),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                if (_selectedProjectIds.isNotEmpty)
                  Row(
                    children: [
                      TextButton(
                        onPressed: _clearSelection,
                        child: Text(
                          AppLocalizations.of(context)!.clearSelection,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Check if selected projects are hidden or visible
                      Consumer(
                        builder: (context, ref, child) {
                          // Get current selection from provider
                          final selectedIds = ref.watch(
                            selectedProjectsProvider,
                          );
                          // Check the state of selected projects
                          final selectedProjects = widget.projects
                              .where((p) => selectedIds.contains(p.id))
                              .toList();
                          final allHidden =
                              selectedProjects.isNotEmpty &&
                              selectedProjects.every((p) => p.hidden);
                          final allVisible =
                              selectedProjects.isNotEmpty &&
                              selectedProjects.every((p) => !p.hidden);

                          // Show Unhide button if all selected are hidden, Hide button if all are visible
                          // If mixed, show both or the appropriate one
                          if (allHidden) {
                            return ElevatedButton.icon(
                              icon: const Icon(Icons.visibility),
                              label: Text(AppLocalizations.of(context)!.unhide),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                              ),
                              onPressed: () {
                                widget.onUnhideProjects(selectedIds.toList());
                                _clearSelection();
                              },
                            );
                          } else if (allVisible) {
                            return ElevatedButton.icon(
                              icon: const Icon(Icons.visibility_off),
                              label: Text(AppLocalizations.of(context)!.hide),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                              ),
                              onPressed: () {
                                widget.onHideProjects(selectedIds.toList());
                                _clearSelection();
                              },
                            );
                          } else {
                            // Mixed selection - show both buttons
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.visibility),
                                  label: Text(
                                    AppLocalizations.of(context)!.unhide,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                  onPressed: () {
                                    widget.onUnhideProjects(
                                      selectedIds.toList(),
                                    );
                                    _clearSelection();
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.visibility_off),
                                  label: Text(
                                    AppLocalizations.of(context)!.hide,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                  ),
                                  onPressed: () {
                                    widget.onHideProjects(selectedIds.toList());
                                    _clearSelection();
                                  },
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final selectedProjects = widget.projects
                              .where((p) => _selectedProjectIds.contains(p.id));
                          final anyFileFound = selectedProjects.any(
                            (p) =>
                                File(p.filePath).existsSync() ||
                                Directory(p.filePath).existsSync(),
                          );
                          final anySupported = selectedProjects.any(
                            (p) =>
                                (File(p.filePath).existsSync() ||
                                    Directory(p.filePath).existsSync()) &&
                                MetadataExtractor.supportsFullExtraction(
                                  p.filePath,
                                ),
                          );
                          return Tooltip(
                            message: !anyFileFound
                                ? AppLocalizations.of(
                                    context,
                                  )!.sourceFileNotFoundOnThisMachine
                                : !anySupported
                                    ? AppLocalizations.of(
                                        context,
                                      )!.metadataExtractionNotSupportedForDaw
                                    : '',
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.search),
                              label: Text(
                                AppLocalizations.of(context)!.extractMetadata,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                              onPressed: widget.isAnyOperation || !anySupported
                                  ? null
                                  : () async {
                                      widget.onExtractingMetadataChanged(true);
                                      final repo = await ref.read(
                                        repositoryProvider.future,
                                      );
                                      int successCount = 0;
                                      int failCount = 0;

                                      for (final projectId
                                          in _selectedProjectIds) {
                                        final project = widget.projects
                                            .firstWhere((p) => p.id == projectId);
                                        if (!MetadataExtractor
                                            .supportsFullExtraction(
                                              project.filePath,
                                            )) {
                                          continue;
                                        }
                                        try {
                                          await repo
                                              .extractFullMetadataForProject(
                                                projectId,
                                              );
                                          successCount++;
                                        } catch (_) {
                                          failCount++;
                                        }
                                      }

                                      // Refresh the projects list
                                      ref.invalidate(allProjectsStreamProvider);

                                      if (mounted) {
                                        final plural = successCount == 1
                                            ? ''
                                            : 's';
                                        final failures = failCount > 0
                                            ? AppLocalizations.of(
                                                context,
                                              )!.extractionFailures(
                                                failCount,
                                                failCount == 1 ? '' : 's',
                                              )
                                            : '';
                                        final message =
                                            AppLocalizations.of(
                                              context,
                                            )!.metadataExtractedForProjects(
                                              successCount,
                                              plural,
                                              failures,
                                            );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );
                                      }

                                      widget.onExtractingMetadataChanged(false);
                                      _clearSelection();
                                    },
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: Text(AppLocalizations.of(context)!.changeStatus),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                        onPressed: () => _showChangeStatusDialog(context),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.album),
                        label: Text(
                          AppLocalizations.of(context)!.createRelease,
                        ),
                        onPressed: () {
                          final selectedProjects = widget.projects
                              .where((p) => _selectedProjectIds.contains(p.id))
                              .toList();
                          widget.onCreateRelease(selectedProjects);
                          _clearSelection();
                        },
                      ),
                      // Stacking needs two or more standalone projects. The
                      // button hides rather than disabling when it can't apply
                      // — an always-visible dead button next to four live ones
                      // reads as broken.
                      Builder(
                        builder: (context) {
                          final stackable = widget.projects
                              .where(
                                (p) =>
                                    _selectedProjectIds.contains(p.id) &&
                                    !p.isVirtual &&
                                    !p.isStackMember,
                              )
                              .toList();
                          if (stackable.length < 2) {
                            return const SizedBox.shrink();
                          }
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.layers),
                                label: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.stackAsVersions,
                                ),
                                onPressed: () =>
                                    widget.onStackProjects(stackable),
                              ),
                            ],
                          );
                        },
                      ),
                      // Archiving needs at least one real, not-yet-archived
                      // project. Hides rather than disables, same reasoning as
                      // the stack button above.
                      Builder(
                        builder: (context) {
                          final archivable = widget.projects
                              .where(
                                (p) =>
                                    _selectedProjectIds.contains(p.id) &&
                                    !p.isVirtual &&
                                    !p.isArchived,
                              )
                              .toList();
                          if (archivable.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.archive_outlined),
                                label: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.archiveBulkButtonLabel,
                                ),
                                onPressed: () async {
                                  final archived =
                                      await showArchiveProjectsBulkDialog(
                                    context,
                                    ref,
                                    archivable,
                                  );
                                  if (archived > 0) _clearSelection();
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      Builder(
                        builder: (context) {
                          final missingIds = missingProjectIds(
                            widget.projects,
                            _selectedProjectIds,
                          );
                          if (missingIds.isEmpty)
                            return const SizedBox.shrink();
                          // Shown whenever anything selected is missing, even if it later
                          // turns out to be entirely release-protected — _deleteMissingProjects
                          // explains that rather than hiding the button with no feedback.
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.delete_forever),
                                label: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.deleteMissingProjects,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  widget.onDeleteMissingProjects(
                                    _selectedProjectIds.toList(),
                                  );
                                  _clearSelection();
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
      ],
    );
  }
}


/// Plays a project's preview song, resolving what "the preview song" is along
/// the way: the manually set file, the auto-detected mixdown, a newly detected
/// one, or a file the user picks when there is none. Also offers to adopt a
/// newer export sitting next to the current one, and recovers a preview whose
/// file has since moved.
///
/// Top-level because three call sites need it — the projects table, the mobile
/// list and the dashboard card (#111) — and it was already duplicated verbatim
/// between the first two. It stays in this file rather than moving out to its
/// own because of `_PreviewSongDialog`, which is private to it.
Future<void> playProjectPreview(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  final customFolders = ref.read(customMixdownFoldersProvider).value;
  final customFoldersByDaw = ref
      .read(customMixdownFoldersByDawProvider)
      .value;
  var effectivePath = project.previewSongPath?.isNotEmpty == true
      ? project.previewSongPath!
      : project.previewSongAutoPath;

  if (effectivePath == null) {
    final detected = MixdownDetectorService.findLatestMixdown(
      project,
      customFolders: customFolders,
      customFoldersByDaw: customFoldersByDaw,
    );
    if (detected != null) {
      effectivePath = detected.path;
      final repo = await ref.read(repositoryProvider.future);
      await repo.updateProject(
        project.copyWith(previewSongAutoPath: detected.path),
      );
      ref.invalidate(allProjectsStreamProvider);
    }
  }

  if (effectivePath == null) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.audio_file_outlined, size: 20),
            const SizedBox(width: 8),
            Text(l10n.noPreviewSongTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.noPreviewSongMessage),
            if (!MobileUtils.isMobile()) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.drag_indicator,
                    size: 16,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.noPreviewSongDragHint,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
                ],
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
            child: Text(l10n.selectPreviewSong),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: previewAudioExtensions,
      dialogTitle: l10n.selectPreviewSong,
    );
    if (!context.mounted || picked == null || picked.files.single.path == null)
      return;
    final newPath = picked.files.single.path!;
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(
      project.copyWith(
        previewSongPath: newPath,
        previewSongFileName: path.basename(newPath),
      ),
    );
    if (!context.mounted) return;
    if (MobileUtils.isMobile()) {
      final pickedProject = project.copyWith(
        previewSongPath: newPath,
        previewSongFileName: path.basename(newPath),
      );
      final queue = ref.read(mobilePlayerQueueProvider);
      final idx = queue.indexWhere((p) => p.id == pickedProject.id);
      await ref
          .read(mobilePlayerProvider.notifier)
          .playProject(
            pickedProject,
            newPath,
            queue: queue,
            queueIndex: idx >= 0 ? idx : null,
          );
    } else {
      await showDialog(
        context: context,
        builder: (dialogContext) => _PreviewSongDialog(
          project: project.copyWith(
            previewSongPath: newPath,
            previewSongFileName: path.basename(newPath),
          ),
          onClose: () {},
        ),
      );
    }
    return;
  }

  final file = File(effectivePath);
  if (!await file.exists()) {
    if (!context.mounted) return;
    final recovered = await recoverMissingPreviewSong(context, ref, project);
    if (!context.mounted || recovered == null) return;
    // Adopt the persisted project, not the stale one this method was called
    // with — everything below (the newer-export check, the object handed to
    // the player) has to agree with what the grid row will refresh to.
    project = recovered.project;
    effectivePath = recovered.path;
  }

  // Check for a newer audio file in the same folder as the current preview,
  // regardless of whether the path was manually set or auto-detected.
  // Skip the prompt if the user previously rejected this specific file.
  final newer = MixdownDetectorService.findNewerFileInSameFolder(
    effectivePath,
    ignoredPath: project.ignoredNewerSongPath,
  );
  if (newer != null && context.mounted) {
    final l10n = AppLocalizations.of(context)!;
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newerExportFound),
        content: Text(
          l10n.newerExportFoundMessage(path.basename(newer.path)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.keepCurrent),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.replaceAndPlay),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (replace == null) return;
    final repo = await ref.read(repositoryProvider.future);
    if (replace) {
      final isManual = project.previewSongPath?.isNotEmpty == true;
      final updated = isManual
          ? project.copyWith(
              previewSongPath: newer.path,
              previewSongFileName: path.basename(newer.path),
            )
          : project.copyWith(previewSongAutoPath: newer.path);
      await repo.updateProject(updated);
      project = updated;
      effectivePath = newer.path;
    } else {
      // "Keep Current" — remember the user rejected this specific file so
      // we don't ask again unless an even newer file appears.
      project = project.copyWith(ignoredNewerSongPath: newer.path);
      await repo.updateProject(project);
    }
    // Refresh the grid row's cached MusicProject; without it the row's play
    // button keeps advertising the old export until the next scan.
    ref.invalidate(allProjectsStreamProvider);
  }

  if (!context.mounted) return;
  // Always build playProject from effectivePath so the player shows the
  // correct filename whether we replaced or not.
  final playProject = project.copyWith(
    previewSongPath: effectivePath,
    previewSongFileName: path.basename(effectivePath),
  );

  if (MobileUtils.isMobile()) {
    final queue = ref.read(mobilePlayerQueueProvider);
    final idx = queue.indexWhere((p) => p.id == playProject.id);
    await ref
        .read(mobilePlayerProvider.notifier)
        .playProject(
          playProject,
          effectivePath,
          queue: queue,
          queueIndex: idx >= 0 ? idx : null,
        );
  } else {
    ref.read(desktopPlayerProvider.notifier).play(playProject, effectivePath);
  }
}

class _PlutoProjectsTable extends ConsumerStatefulWidget {
  final List<MusicProject> projects;
  final List<ScanRoot> scanRoots;
  final DateFormat dateFormat;
  final Set<String> selectedIds;
  final Function(String) onToggleSelection;

  /// A primary-button click anywhere on a project row, modifiers included —
  /// the row-level counterpart to clicking the checkbox column. The parent
  /// owns the anchor and the modifier rules, so this just reports the row.
  final Function(String) onRowClickSelection;

  /// The row highlight landed on a project with no selection modifier held.
  final Function(String) onRowHighlighted;
  final Function(Set<String>) onToggleGroupSelection;
  final Function(List<String>) onHideProjects;
  final Function(List<String>) onUnhideProjects;
  final bool areAllSelected;
  final VoidCallback onToggleSelectAll;
  final Function(bool) onExtractingMetadataChanged;
  final ValueNotifier<({bool hasGroups, bool anyExpanded})>?
  groupExpandNotifier;
  final bool isScanning;
  const _PlutoProjectsTable({
    super.key,
    required this.projects,
    required this.scanRoots,
    required this.dateFormat,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onRowClickSelection,
    required this.onRowHighlighted,
    required this.onToggleGroupSelection,
    required this.onHideProjects,
    required this.onUnhideProjects,
    required this.areAllSelected,
    required this.onToggleSelectAll,
    required this.onExtractingMetadataChanged,
    required this.isScanning,
    this.groupExpandNotifier,
  });

  @override
  ConsumerState<_PlutoProjectsTable> createState() =>
      _PlutoProjectsTableState();
}

/// Whether the full-screen loading overlay (which prevents all interaction)
/// should be shown for the given in-flight operations.
///
/// A plain scan — whether the background one at app launch or a
/// user-triggered "Rescan" — never blocks: both are diff-based against what's
/// already on screen, so browsing through them is safe. Newly-found projects
/// surface via the "New" badge (`recentlyDiscoveredProjectsProvider`) instead
/// of a blocking spinner; any pruning of missing projects or session-
/// reconciliation dialogs a rescan triggers can happen against a still-
/// interactive grid.
///
/// Deep scan still blocks for now: it rewrites metadata in place on existing
/// projects, and — unlike a plain scan adding rows the user can simply
/// ignore until they're ready — an in-place rewrite could show a project
/// half-updated if opened mid-scan. `scanning` is accepted (deep scan always
/// implies it) so the call site doesn't need to special-case which flag to
/// pass, and to leave room to fold deep scan into this same non-blocking
/// treatment later. Switching profiles or extracting metadata both mutate
/// state the user could otherwise interact with mid-flight, so those still
/// block too.

/// Reads all projects from [repo], returning null instead of throwing if its
/// Hive boxes were already closed — e.g. Clear Library / Delete All Data
/// (settings_page.dart) closing/clearing boxes while this widget is still
/// holding the pre-invalidation repositoryProvider value. Callers should
/// treat a null result the same as "not loaded yet".
@visibleForTesting
List<MusicProject>? safeGetAllProjects(ProjectRepository repo) {
  try {
    return repo.getAllProjects();
  } on HiveError {
    return null;
  }
}

/// Why the Projects grid is showing its empty state, so the message can be
/// tailored instead of a single generic "no projects found" covering both a
/// fresh install and a scan root that turned up nothing.
@visibleForTesting
enum ProjectsEmptyStateReason {
  /// Projects exist, but the current search/filter narrowed them to zero.
  filteredToZero,

  /// No scan roots configured yet — a genuinely fresh install.
  noScanRootsYet,

  /// At least one scan root is configured, but it hasn't found any projects
  /// (wrong folder, DAW files not created yet, etc.) — the user has already
  /// done the "add a folder" step, so telling them to do it again is wrong.
  scanRootsFoundNothing,
}

@visibleForTesting
ProjectsEmptyStateReason projectsEmptyStateReason({
  required bool hasProjects,
  required bool hasScanRoots,
}) {
  if (hasProjects) return ProjectsEmptyStateReason.filteredToZero;
  if (hasScanRoots) return ProjectsEmptyStateReason.scanRootsFoundNothing;
  return ProjectsEmptyStateReason.noScanRootsYet;
}

@visibleForTesting
bool shouldBlockForOperation({
  required bool scanning,
  required bool deepScanning,
  required bool profileSwitching,
  required bool extractingMetadata,
}) {
  return deepScanning || profileSwitching || extractingMetadata;
}

/// The subset of [selectedIds] among [projects] whose file no longer exists
/// on disk — the exact set the "Delete Missing" bulk action targets.
/// Projects still present on disk are left alone even if selected alongside
/// missing ones, so a mixed selection only ever deletes the missing half.
@visibleForTesting
List<String> missingProjectIds(
  List<MusicProject> projects,
  Iterable<String> selectedIds,
) {
  final selected = selectedIds.toSet();
  return projects
      .where(
        (p) =>
            selected.contains(p.id) &&
            // A stack's path points at a folder, not a file, so it never
            // resolves — without this it would read as missing and offer to
            // delete the one row holding the song's shared metadata.
            p.isMissingFileCandidate &&
            !projectFileExists(p),
      )
      .map((p) => p.id)
      .toList();
}

/// A left-rail trailing action: an icon with an optional label below it,
/// where the whole tile (icon + label) is a single tap target rather than
/// just the icon.
class RailAction extends StatelessWidget {
  const RailAction({
    super.key,
    required this.icon,
    required this.label,
    required this.showLabel,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final bool showLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = onPressed == null
        ? Theme.of(context).disabledColor
        : cs.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme.merge(
              data: IconThemeData(color: color),
              child: icon,
            ),
            if (showLabel) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What a scan-triggering button's icon should show: a spinner while its
/// scan runs, a checkmark for a brief window right after it finishes
/// successfully (so the user gets positive confirmation the non-blocking
/// scan actually completed, since there's no overlay forcing their
/// attention anymore), or the button's normal idle icon otherwise.
enum ScanIconState { idle, spinning, justSucceeded }

/// Icon state for the "Rescan" button. Deep scan also sets `isScanning`
/// (see `_scanAll`/`_fullScanAll`) but owns its own spinner via the
/// dedicated Deep Scan button, so it's explicitly excluded here.
@visibleForTesting
ScanIconState rescanIconState({
  required bool isScanning,
  required bool deepScanning,
  required bool justSucceeded,
}) {
  if (isScanning && !deepScanning) return ScanIconState.spinning;
  if (justSucceeded) return ScanIconState.justSucceeded;
  return ScanIconState.idle;
}

/// Icon state for the "Deep Scan" button.
@visibleForTesting
ScanIconState deepScanIconState({
  required bool deepScanning,
  required bool justSucceeded,
}) {
  if (deepScanning) return ScanIconState.spinning;
  if (justSucceeded) return ScanIconState.justSucceeded;
  return ScanIconState.idle;
}

/// Parses a persisted `settings` box value back into a [TrinaColumnSort].
/// Returns null for anything other than the two values this ever writes
/// ('ascending'/'descending') — including a missing key or a corrupt/stale
/// value — so a garbled preference is treated as "no persisted sort" rather
/// than silently defaulting to ascending.
@visibleForTesting
TrinaColumnSort? sortDirectionFromPrefsValue(String? value) {
  return switch (value) {
    'ascending' => TrinaColumnSort.ascending,
    'descending' => TrinaColumnSort.descending,
    _ => null,
  };
}

/// The inverse of [sortDirectionFromPrefsValue] — null for
/// [TrinaColumnSort.none] or a null direction, since "no sort" is persisted
/// by deleting the key rather than writing a sentinel value.
@visibleForTesting
String? sortDirectionToPrefsValue(TrinaColumnSort? direction) {
  if (direction == null || direction.isNone) return null;
  return direction.isDescending ? 'descending' : 'ascending';
}

/// Compares two 'lastModified' cell values chronologically. Used as the
/// Projects table's Last Modified column `compare` callback: that column's
/// cell values are raw [DateTime]s (not the formatted display string), so
/// ascending/descending sort orders by actual date rather than by the
/// alphabetical order of a formatted date string — e.g. "Jul" sorting after
/// "Jun" alphabetically would otherwise put a July date after a June one
/// even in years where July came first chronologically.
@visibleForTesting
int compareLastModifiedCellValues(dynamic a, dynamic b) {
  return (a as DateTime).compareTo(b as DateTime);
}

/// Collects the [MusicProject.id] of every project-backed row in [topLevelRows],
/// including rows nested inside collapsed or expanded smart-folder groups.
///
/// Smart-folder groups (`TrinaRowType.group`) keep their member rows in
/// `row.type.group.children`, not in the top-level row list, so a naive scan
/// of only top-level rows sees group *headers* (whose `data` cell is null)
/// instead of the projects inside them. That previously made the grouped-view
/// row/project ID comparison in `_tableRowsMatchProjects` fail on every
/// refresh, forcing a full row rebuild (and losing group expansion + sort
/// state) even when nothing structurally changed.
@visibleForTesting
Set<String> collectProjectRowIds(List<TrinaRow> topLevelRows) {
  final ids = <String>{};
  for (final row in topLevelRows) {
    if (row.type.isGroup) {
      for (final child in row.type.group.children.originalList) {
        final id = (child.cells['data']?.value as MusicProject?)?.id;
        if (id != null) ids.add(id);
      }
    } else {
      final id = (row.cells['data']?.value as MusicProject?)?.id;
      if (id != null) ids.add(id);
    }
  }
  return ids;
}

/// The [MusicProject.id] of every project inside [groupRow] (a single
/// smart-folder group row), or empty if [groupRow] isn't a group. Used to
/// derive a group's own "New" badge from whichever of its members were just
/// discovered — a project that used to sit alone (flat) and gets grouped
/// with a newly-found sibling should visibly read as "something changed
/// here" even though the folder row itself isn't new.
@visibleForTesting
Set<String> groupChildProjectIds(TrinaRow groupRow) {
  if (!groupRow.type.isGroup) return {};
  return groupRow.type.group.children.originalList
      .map((r) => (r.cells['data']?.value as MusicProject?)?.id)
      .whereType<String>()
      .toSet();
}

/// Whether clicking a smart-folder group's own checkbox should select its
/// members, as opposed to deselecting them. Selects unless every member of
/// [groupProjectIds] is already in [currentlySelected] — so a partially- or
/// un-selected group fills in the rest, and a fully-selected group clears
/// out. Mirrors a standard "select all in this folder" checkbox rather than
/// a plain per-item toggle, since the group checkbox represents many
/// projects at once.
@visibleForTesting
bool groupCheckboxShouldSelect(
  Set<String> groupProjectIds,
  Set<String> currentlySelected,
) {
  return !(groupProjectIds.isNotEmpty &&
      groupProjectIds.every(currentlySelected.contains));
}

/// The key used to bucket a project into its smart-folder group during
/// `_mapProjectsToRows()`. [rootPath] is the scan root the project lives
/// under; [relativeParts] is its path relative to that root, already split
/// into segments (so `relativeParts[0]` is the top-level subfolder).
///
/// Normally each root's own top-level subfolder is its own group, keyed by
/// its full path — so a "0-Ideas" folder under a Cubase root and a
/// "0-Ideas" folder under a Studio One root stay separate even though they
/// share a name. When [mergeSameName] is on (see
/// `mergeSmartFoldersByNameProvider`), the key is just the folder's
/// basename, so same-named top-level folders from different scan roots
/// collapse into a single merged group.
@visibleForTesting
String smartFolderGroupKey(
  String rootPath,
  List<String> relativeParts, {
  required bool mergeSameName,
}) {
  final topLevel = path.join(rootPath, relativeParts[0]);
  return mergeSameName ? path.basename(topLevel) : topLevel;
}

/// Whether a smart-folder group with [memberCount] currently-visible
/// projects should render as an actual group row, rather than demoting its
/// lone member to a plain flat row.
///
/// Normally a folder with only one *currently visible* project isn't worth
/// wrapping in a group row, so it demotes to flat. Two opt-in settings
/// override that:
/// - [mergeByName] (`mergeSmartFoldersByNameProvider`): a member count of 1
///   is often just the active DAW-type filter hiding that folder's merge
///   partner(s) from another scan root — reported after the merge feature
///   shipped: a brand-new Cubase project dropped into a "1-Active Projects"
///   folder correctly merged with an existing same-named Studio One folder
///   while showing all DAWs, but filtering the view down to Cubase only made
///   it "disappear" back into an orphaned flat row, since only that one
///   Cubase project remained in the bucket once its Studio One siblings were
///   filtered out.
/// - [alwaysShow] (`alwaysShowSmartFoldersProvider`): a general-purpose
///   version of the same override for anyone who'd simply rather a smart
///   folder never collapse away, regardless of why it's down to one visible
///   member (a search, a phase filter, etc.), not just the merge-by-name
///   case above.
@visibleForTesting
bool smartFolderShouldRenderAsGroup(
  int memberCount, {
  required bool mergeByName,
  required bool alwaysShow,
}) {
  if (mergeByName || alwaysShow) return true;
  return memberCount > 1;
}

/// Sorts [rows] by each row's cell value at [field] — string comparison,
/// matching `TrinaColumnType.text().compare()`, the type every column in
/// this table uses — and recursively sorts each group row's children the
/// same way. Mirrors what `TrinaGridStateManager.sortAscending/Descending`
/// do internally (including their row-group delegation), but runs on plain
/// [TrinaRow] lists before they're ever attached to a grid.
///
/// Used to build a freshly-mounted TrinaGrid's *initial* rows already in the
/// desired order: TrinaGrid only calls `onLoaded` (and hence any state-
/// manager-level sort restore) via `addPostFrameCallback`, i.e. after its
/// first frame has already painted. Waiting for that to reapply a sort
/// causes a one-frame flash of the natural/unsorted order every time the
/// grid remounts (switching theme or language both do, since TrinaGrid's key
/// includes both) — pre-sorting the initial rows means that first frame is
/// already correct.
@visibleForTesting
void applySortSnapshot(
  List<TrinaRow> rows,
  String field,
  TrinaColumnSort direction, {
  bool excludeGroupsFromSort = false,
}) {
  if (direction.isNone) return;
  int compare(TrinaRow a, TrinaRow b) {
    final av = a.cells[field]?.value;
    final bv = b.cells[field]?.value;
    if (av == null || bv == null) {
      return av == bv ? 0 : (av == null ? -1 : 1);
    }
    return av.toString().compareTo(bv.toString());
  }

  final effectiveCompare = direction.isDescending
      ? (TrinaRow a, TrinaRow b) => compare(b, a)
      : compare;
  if (excludeGroupsFromSort) {
    rows.setAll(0, sortFlatRowsKeepingGroupsInPlace(rows, effectiveCompare));
  } else {
    rows.sort(effectiveCompare);
  }
  for (final row in rows) {
    if (row.type.isGroup) {
      row.type.group.children.sort(effectiveCompare);
    }
  }
}

/// The row order that results from sorting only the non-group ("flat") rows
/// in [currentOrder] by [compare] — every group (smart-folder) row keeps its
/// current top-level index, with sorted flat rows filling the remaining
/// slots in order. Used so a column sort doesn't move smart-folder groups
/// around (see `excludeSmartFoldersFromSortProvider`) while the individual
/// project rows still sort normally.
@visibleForTesting
List<TrinaRow> sortFlatRowsKeepingGroupsInPlace(
  List<TrinaRow> currentOrder,
  int Function(TrinaRow, TrinaRow) compare,
) {
  final sortedFlat = currentOrder.where((r) => !r.type.isGroup).toList()
    ..sort(compare);
  var flatIndex = 0;
  return [
    for (final row in currentOrder)
      if (row.type.isGroup) row else sortedFlat[flatIndex++],
  ];
}

/// Row-group delegate identical to [TrinaRowGroupTreeDelegate] except its
/// [sort] leaves group (smart-folder) rows in their current top-level order
/// — only the non-group rows and each group's own children get reordered by
/// the active column sort. Used for the live grid when
/// `excludeSmartFoldersFromSortProvider` is on; [applySortSnapshot] mirrors
/// the same behavior (via [sortFlatRowsKeepingGroupsInPlace]) for the
/// initial/rebuilt row list, since that's built and pre-sorted before the
/// grid — and this delegate — ever exist.
class _GroupOrderStableRowGroupDelegate extends TrinaRowGroupTreeDelegate {
  _GroupOrderStableRowGroupDelegate({
    required super.resolveColumnDepth,
    required super.showText,
    super.showFirstExpandableIcon,
    super.showCount,
  });

  @override
  void sort({
    required TrinaColumn column,
    required FilteredList<TrinaRow> rows,
    required int Function(TrinaRow, TrinaRow) compare,
  }) {
    if (rows.originalList.isEmpty) return;

    // rows.sort() only accepts a Comparator, not an explicit target order —
    // so express the desired order as one: every row gets a unique target
    // index, which sidesteps needing List.sort to be stable (it isn't
    // guaranteed to be) since no two rows ever compare equal.
    final desiredOrder = sortFlatRowsKeepingGroupsInPlace(
      rows.originalList,
      compare,
    );
    final targetIndex = {
      for (var i = 0; i < desiredOrder.length; i++) desiredOrder[i]: i,
    };
    rows.sort((a, b) => targetIndex[a]!.compareTo(targetIndex[b]!));

    final children = TrinaRowGroupHelper.iterateWithFilter(
      rows.originalList,
      filter: (r) => r.type.isGroup,
    );
    for (final child in children) {
      child.type.group.children.sort(compare);
    }
  }
}

/// The set of currently-expanded smart-folder group names among [rows].
///
/// Used to snapshot expand state before it can be lost — TrinaGrid's key
/// includes both locale and theme, so switching either one remounts the
/// entire grid with a brand new [TrinaGridStateManager] whose groups start
/// out collapsed by default, with nothing left to read the old expand state
/// back from.
/// The "DAW" grid column label for a project: `"<DAW> <version>"` when a
/// version is known (e.g. `"Logic Pro 12.3.1"`), just the DAW name otherwise,
/// or empty when the DAW is unknown.
@visibleForTesting
String dawDisplayLabel(String? dawType, String? dawVersion) {
  if (dawType == null || dawType.isEmpty) return '';
  if (dawVersion != null && dawVersion.isNotEmpty) return '$dawType $dawVersion';
  return dawType;
}

/// Width for the "DAW" grid column, sized to the widest `"<DAW> <version>"`
/// label actually present in [labels] — measured with a [TextPainter] since
/// the cell font is proportional — plus room for the DAW logo and cell
/// padding. Clamped so a library of one short-named DAW can't make it
/// vanish, and a stray long label can't let it hog the table. Recomputed
/// each time the grid is (re)built, so it tracks the visible rows: this is
/// what keeps e.g. "Logic Pro 12.3.1" from being clipped at the old fixed
/// 140px.
@visibleForTesting
double dawColumnWidth(Iterable<String> labels) {
  const style = TextStyle(fontSize: 14); // TrinaGrid's default cell text size
  const chrome = 16.0 /*logo*/ + 6.0 /*logo gap*/ + 36.0 /*cell padding + slack*/;
  var widest = 0.0;
  for (final label in labels.toSet()) {
    if (label.isEmpty) continue;
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
  }
  // 1.04×: TextPainter measures the raw glyph advance; the Text widget wants a
  // hair more before it stops showing an ellipsis (sub-pixel rounding, the
  // Flexible's constraint). A proportional bump keeps longer labels safe too.
  return (widest * 1.04 + chrome).clamp(140.0, 280.0);
}

@visibleForTesting
Set<String> expandedGroupNames(List<TrinaRow> rows) {
  return {
    for (final row in rows)
      if (row.type.isGroup && row.type.group.expanded)
        row.cells['name']?.value as String? ?? '',
  };
}

/// Which of [rows] are collapsed groups whose name appears in
/// [namesToExpand] — i.e. the rows that still need `toggleExpandedRowGroup`
/// called on them to restore a previously-captured [expandedGroupNames]
/// snapshot after the row list was rebuilt (or the whole grid remounted)
/// collapsed by default. Groups are matched by name only, so a folder that
/// no longer exists after the rebuild is silently dropped, and a rebuilt
/// group that happens to share a name with a still-expanded one is expanded
/// to match.
@visibleForTesting
List<TrinaRow> groupRowsToExpand(
  List<TrinaRow> rows,
  Set<String> namesToExpand,
) {
  return [
    for (final row in rows)
      if (row.type.isGroup &&
          !row.type.group.expanded &&
          namesToExpand.contains(row.cells['name']?.value as String? ?? ''))
        row,
  ];
}

class _PlutoProjectsTableState extends ConsumerState<_PlutoProjectsTable>
    with RouteAwareDropTargetState<_PlutoProjectsTable> {
  TrinaGridStateManager? stateManager;
  bool _isRebuildingRows = false;
  // Set to true when the theme changes so onLoaded can schedule a _rebuildRows()
  // call that busts TrinaGrid's renderer cache (which only invalidates on cell/
  // row/selection changes, not on theme changes).
  bool _needsThemeRefresh = false;

  // Continuously-updated snapshot of group-expand and column-sort state, kept
  // in sync (via _onStateManagerChanged) every time the live grid actually
  // changes. TrinaGrid's key includes both locale and theme
  // (`trina_grid_${locale}_${theme}`), so switching either one discards the
  // old TrinaGridStateManager entirely and mounts a brand new one — losing
  // all group-expand and sort state, since a fresh grid has nothing to read
  // that state back from. This snapshot survives that remount and is
  // reapplied in onLoaded once the new stateManager is live.
  //
  // The sort half is also persisted to the `settings` Hive box (group-expand
  // deliberately isn't — that's noisier and easy to re-expand by hand) so it
  // survives a full app restart too, not just an in-session remount. Seeded
  // synchronously in initState from whatever's on disk, so the very first
  // frame is already sorted correctly instead of flashing unsorted rows
  // first (same reasoning as _mapProjectsToRows pre-sorting on remount).
  static const _sortFieldPrefsKey = 'projectsSortField';
  static const _sortDirectionPrefsKey = 'projectsSortDirection';

  Set<String> _lastKnownExpandedGroupNames = {};
  String? _lastKnownSortField;
  TrinaColumnSort? _lastKnownSortDirection;

  @override
  void initState() {
    super.initState();
    try {
      final box = Hive.box<String>('settings');
      final field = box.get(_sortFieldPrefsKey);
      final direction = sortDirectionFromPrefsValue(
        box.get(_sortDirectionPrefsKey),
      );
      if (field != null && direction != null) {
        _lastKnownSortField = field;
        _lastKnownSortDirection = direction;
      }
    } catch (_) {
      // 'settings' box isn't open yet — main() should always open it before
      // runApp(), but fall back to unsorted rather than crash if it isn't.
    }
  }

  void _persistSortPreference(String? field, TrinaColumnSort? direction) async {
    try {
      final box = await Hive.openBox<String>('settings');
      final directionValue = sortDirectionToPrefsValue(direction);
      if (field == null || directionValue == null) {
        await box.delete(_sortFieldPrefsKey);
        await box.delete(_sortDirectionPrefsKey);
      } else {
        await box.put(_sortFieldPrefsKey, field);
        await box.put(_sortDirectionPrefsKey, directionValue);
      }
    } catch (_) {}
  }

  void _captureTableStateSnapshot() {
    final sm = stateManager;
    if (sm == null) return;
    _lastKnownExpandedGroupNames = expandedGroupNames(sm.rows);
    final sortedColumn = sm.getSortedColumn;
    final newField = sortedColumn?.field;
    final newDirection = sortedColumn?.sort;
    if (newField != _lastKnownSortField ||
        newDirection != _lastKnownSortDirection) {
      final hadSort = _lastKnownSortField != null;
      _lastKnownSortField = newField;
      _lastKnownSortDirection = newDirection;
      _persistSortPreference(newField, newDirection);
      // Clicking a column header a third time clears its sort by calling
      // TrinaGrid's own sortBySortIdx(), which restores each row's *baked-in*
      // sortIdx — the row order from whenever rows were last (re)built, not
      // necessarily our app's actual default order. Those two only coincide
      // if nothing was ever sorted since that last build; if the table was
      // last rebuilt while some other column's sort was active (e.g. after a
      // background refresh), sortIdx bakes in that stale order instead.
      // Force a full rebuild so cycling any column back to "no sort" always
      // lands on the same newest-first default _mapProjectsToRows()
      // establishes on a fresh mount, not whatever TrinaGrid had cached.
      if (hadSort && newField == null) {
        _rebuildRows();
      }
    }
  }

  // Applies _lastKnownSortField/_lastKnownSortDirection to whichever live
  // column matches by field. Deliberately reads the *persistent* snapshot
  // rather than sm.getSortedColumn: on a freshly-mounted grid (theme/locale
  // remount) the fresh TrinaColumn objects always start with sort:none —
  // _mapProjectsToRows() pre-sorts the row *data* for the first frame, but
  // nothing sets the column's own sort flag until this runs. Reading the
  // live column instead of the snapshot here would silently skip restoring
  // it whenever this is the first thing to touch sort after a remount,
  // leaving the header's sort-direction icon stuck on neutral even though
  // the rows are genuinely sorted.
  void _applyKnownSort(TrinaGridStateManager sm) {
    final sortField = _lastKnownSortField;
    final sortMode = _lastKnownSortDirection;
    if (sortField == null || sortMode == null) return;
    for (final column in sm.columns) {
      if (column.field != sortField) continue;
      if (sortMode.isAscending) {
        sm.sortAscending(column, notify: false);
      } else if (sortMode.isDescending) {
        sm.sortDescending(column, notify: false);
      }
      break;
    }
  }

  void _restoreTableStateSnapshot() {
    final sm = stateManager;
    if (sm == null) return;
    // notify:false throughout — toggleExpandedRowGroup() defaults to
    // notify:true, which used to fire _onStateManagerChanged() synchronously
    // mid-restore (the listener is already attached by the time this runs)
    // and re-run _captureTableStateSnapshot() on the *partially* restored
    // grid — before the sort below had been reapplied — clobbering
    // _lastKnownSortField/_lastKnownSortDirection back to null right before
    // they're read a few lines down. That silently no-opped sort restoration
    // on every single remount, not just subsequent ones.
    for (final row in groupRowsToExpand(
      sm.rows,
      _lastKnownExpandedGroupNames,
    )) {
      sm.toggleExpandedRowGroup(rowGroup: row, notify: false);
    }
    _applyKnownSort(sm);
    // Single batched notification now that expand + sort are both settled,
    // instead of one repaint per toggled group.
    sm.notifyListeners();
  }

  // Returns true when the project set is identical (same IDs) — only cell
  // values may have changed (BPM, key, lastModified, etc.). In that case we
  // can update cells in-place instead of rebuilding the entire row tree, which
  // avoids disturbing group expansion state.
  bool _sameProjectIds(List<MusicProject> a, List<MusicProject> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((p) => p.id).toSet();
    final bIds = b.map((p) => p.id).toSet();
    return aIds.length == bIds.length && aIds.containsAll(bIds);
  }

  // Returns true when the table rows already reflect the given project list.
  // Used to detect when the table is stale after a profile switch: the widget's
  // oldProjects and newProjects both hold the new-profile data (the in-flight
  // update was suppressed by isScanning), but the rendered rows still contain
  // the previous profile's IDs — so _sameProjectIds(old, new) would incorrectly
  // green-light an in-place update that matches nothing.
  bool _tableRowsMatchProjects(List<MusicProject> projects) {
    final sm = stateManager;
    if (sm == null) return false;
    final rowIds = collectProjectRowIds(sm.refRows.originalList);
    final projectIds = projects.map((p) => p.id).toSet();
    return rowIds.length == projectIds.length && rowIds.containsAll(projectIds);
  }

  void _updateCellsInPlace(List<MusicProject> newProjects) {
    final sm = stateManager;
    if (sm == null) return;

    final projectById = {for (final p in newProjects) p.id: p};

    String dawDisplay(MusicProject p) {
      if (p.dawType == null) return '';
      if (p.dawVersion?.isNotEmpty == true)
        return '${p.dawType} ${p.dawVersion}';
      return p.dawType!;
    }

    void updateProjectRow(TrinaRow row) {
      final project = row.cells['data']?.value as MusicProject?;
      if (project == null) return;
      final updated = projectById[project.id];
      if (updated == null) return;
      row.cells['data']!.value = updated;
      row.cells['name']?.value = updated.displayName;
      row.cells['status']?.value = updated.status;
      row.cells['dawType']?.value = dawDisplay(updated);
      row.cells['bpm']?.value = updated.bpm?.toString() ?? '';
      row.cells['key']?.value = updated.musicalKey ?? '';
      row.cells['lastModified']?.value = updated.lastModifiedAt;
      row.cells['deadline']?.value = updated.deadlineStatus ?? '';
      // Update the launch cell's own value so TrinaGrid re-renders the action
      // column (play button) when preview song data changes.
      row.cells['launch']?.value =
          updated.previewSongPath ?? updated.previewSongAutoPath ?? '';
    }

    // Walk top-level rows; for group rows also update their children (including
    // children of collapsed groups that are not in refRows directly).
    final topLevel = sm.refRows.originalList.where((r) => r.isMain).toList();
    for (final row in topLevel) {
      if (row.type.isGroup) {
        DateTime? latestModified;
        for (final child in row.type.group.children.originalList) {
          updateProjectRow(child);
          final p =
              projectById[(child.cells['data']?.value as MusicProject?)?.id];
          if (p != null &&
              (latestModified == null ||
                  p.lastModifiedAt.isAfter(latestModified))) {
            latestModified = p.lastModifiedAt;
          }
        }
        if (latestModified != null) {
          row.cells['lastModified']?.value = latestModified;
        }
      } else {
        updateProjectRow(row);
      }
    }

    sm.notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateGroupExpandNotifier();
    });
  }

  void focusTable() {
    final sm = stateManager;
    if (sm == null) return;
    sm.gridFocusNode.requestFocus();
    if (sm.currentRow == null && sm.rows.isNotEmpty) {
      sm.setCurrentCell(sm.rows.first.cells.values.first, 0);
    }
  }

  void _updateGroupExpandNotifier() {
    final sm = stateManager;
    final notifier = widget.groupExpandNotifier;
    if (notifier == null) return;
    notifier.value = (
      hasGroups: sm?.rows.any((r) => r.type.isGroup) ?? false,
      anyExpanded:
          sm?.rows.any((r) => r.type.isGroup && r.type.group.expanded) ?? false,
    );
  }

  void _onStateManagerChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_isRebuildingRows) {
      _captureTableStateSnapshot();
      _updateGroupExpandNotifier();
    }
  }

  void _rebuildRows() {
    final sm = stateManager;
    if (sm == null) return;
    _isRebuildingRows = true;
    final wasCollapsed = <String, bool>{};
    for (final row in sm.rows) {
      if (row.type.isGroup) {
        wasCollapsed[row.cells['name']?.value as String? ?? ''] =
            !row.type.group.expanded;
      }
    }
    final newRows = _mapProjectsToRows(widget.projects);
    sm.removeRows(sm.rows, notify: false);
    sm.insertRows(0, newRows);
    for (final row in sm.rows) {
      if (row.type.isGroup) {
        final name = row.cells['name']?.value as String? ?? '';
        // _mapProjectsToRows() already applies _lastKnownExpandedGroupNames
        // when building fresh group rows (see applySortSnapshot's doc
        // comment for why), so a group may already start expanded here —
        // toggleExpandedRowGroup() *toggles*, so calling it unconditionally
        // on an already-expanded row would collapse it right back. Only
        // toggle when the row's current state doesn't already match.
        final shouldBeExpanded = wasCollapsed[name] == false;
        if (shouldBeExpanded != row.type.group.expanded) {
          sm.toggleExpandedRowGroup(rowGroup: row, notify: false);
        }
      }
    }
    // newRows' *data* is already in the right order — _mapProjectsToRows()
    // pre-sorts it — but insertRows() doesn't touch the live TrinaColumn's
    // sort flag, so the header's sort-direction icon would otherwise stay
    // neutral. This sets that bookkeeping. Uses the persistent snapshot
    // rather than sm.getSortedColumn — see _applyKnownSort's doc comment for
    // why that matters on a remount.
    _applyKnownSort(sm);
    sm.notifyListeners();
    _isRebuildingRows = false;
    // _rebuildRows is called from didUpdateWidget (i.e. during the build phase).
    // Setting ValueNotifier.value synchronously here would call setState on the
    // ValueListenableBuilder in the parent tree mid-build. Defer to post-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateGroupExpandNotifier();
    });
  }

  void _collapseAll() {
    final sm = stateManager;
    if (sm == null) return;
    for (final row in sm.rows) {
      if (row.type.isGroup && row.type.group.expanded) {
        sm.toggleExpandedRowGroup(rowGroup: row);
      }
    }
  }

  void _expandAll() {
    final sm = stateManager;
    if (sm == null) return;
    for (final row in sm.rows) {
      if (row.type.isGroup && !row.type.group.expanded) {
        sm.toggleExpandedRowGroup(rowGroup: row);
      }
    }
  }

  // Drag-and-drop preview assignment
  double? _dragOverRowTop; // top Y of the highlighted row in local coords

  static const double _gridHeaderHeight = 45.0;
  static const double _gridRowHeight = 48.0;

  static const Set<String> _audioExtensions = {
    '.mp3',
    '.wav',
    '.m4a',
    '.aac',
    '.ogg',
    '.flac',
    '.aif',
    '.aiff',
  };

  void _updateDragTarget(Offset localPos) {
    final sm = stateManager;
    if (sm == null) return;
    final scrollOffset = sm.scroll.bodyRowsVertical?.offset ?? 0;
    final rowTotalHeight = sm.rowTotalHeight;
    final rowIndex =
        ((localPos.dy - _gridHeaderHeight + scrollOffset) / rowTotalHeight)
            .floor();
    if (rowIndex >= 0 && rowIndex < sm.rows.length) {
      final rowTop =
          _gridHeaderHeight + rowIndex * rowTotalHeight - scrollOffset;
      setState(() {
        _dragOverRowTop = rowTop;
      });
    } else {
      setState(() {
        _dragOverRowTop = null;
      });
    }
  }

  Future<void> _setPreviewSong(MusicProject project, String filePath) async {
    final ext = filePath.split('.').last.toLowerCase();
    if (!_audioExtensions.contains('.$ext')) return;
    final repo = await ref.read(repositoryProvider.future);
    final updated = project.copyWith(
      previewSongPath: filePath,
      previewSongFileName: filePath.split('/').last,
    );
    await repo.updateProject(updated);
    ref.invalidate(allProjectsStreamProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${updated.previewSongFileName} set as preview for ${updated.displayName}',
          ),
        ),
      );
    }
  }

  Future<void> _playPreviewSong(MusicProject project) =>
      playProjectPreview(context, ref, project);

  String _translateStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'Idea':
        return l10n.projectPhaseIdea;
      case 'Arranging':
        return l10n.projectPhaseArranging;
      case 'Mixing':
        return l10n.projectPhaseMixing;
      case 'Mastering':
        return l10n.projectPhaseMastering;
      case 'Finished':
        return l10n.projectPhaseFinished;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) => resolvePhaseColor(
    status,
    ref.read(phaseColorsProvider),
    ref.read(customPhasesProvider),
  );

  // In session mode, tapping/launching a row toggles the session instead of
  // launching — see the session-mode branches elsewhere that call
  // confirmStartSession/confirmEndSession for that path.
  Future<void> _launchProject(MusicProject project) =>
      launchProjectFromMenu(context, ref, project);

  Future<void> _viewProjectDetails(MusicProject project) =>
      openProjectDetail(context, project);

  Future<void> _openProjectFolder(MusicProject project) =>
      openProjectFolder(context, project);

  Future<void> _toggleSession(MusicProject project) async {
    if (!mounted) return;
    final sessionMode = ref.read(sessionModeProvider);
    if (!sessionMode) return;
    final activeProject = ref.read(activeProjectProvider);
    if (activeProject?.id == project.id) {
      await confirmEndSession(context, ref);
    } else {
      await confirmStartSession(context, ref, project);
    }
    // Explicitly repaint rows so the green/yellow session color applies immediately.
    if (mounted) stateManager?.notifyListeners();
  }

  Future<void> _showPhaseMenu(
    BuildContext context,
    MusicProject project,
    Offset position,
    TrinaColumnRendererContext rendererContext,
  ) async {
    final phases = ref.read(customPhasesProvider);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: Theme.of(context).cardColor,
      items: phases.map((phase) {
        final isCurrent = project.status == phase;
        return PopupMenuItem<String>(
          value: phase,
          child: Row(
            children: [
              Icon(
                isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 16,
                color: _getStatusColor(phase),
              ),
              const SizedBox(width: 8),
              Text(
                _translateStatus(context, phase),
                style: TextStyle(
                  color: _getStatusColor(phase),
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null && selected != project.status && mounted) {
      final repo = await ref.read(repositoryProvider.future);
      final updated = project.copyWith(status: selected);
      await repo.updateProject(updated);
      // Update cells in-place so the row reflects the change immediately
      rendererContext.row.cells['status']?.value = selected;
      rendererContext.row.cells['data']?.value = updated;
      rendererContext.stateManager.notifyListeners();
    }
  }

  /// Delegates to the shared menu the card view uses too — see
  /// `project_context_menu.dart`.
  Future<void> _showContextMenu(
    BuildContext context,
    MusicProject project,
    Offset position,
  ) async {
    await showProjectContextMenu(
      context: context,
      ref: ref,
      project: project,
      position: position,
      onHideProjects: widget.onHideProjects,
      onUnhideProjects: widget.onUnhideProjects,
      onExtractingMetadataChanged: widget.onExtractingMetadataChanged,
    );
  }

  TrinaRow _projectToRow(MusicProject p) {
    final dawDisplay = dawDisplayLabel(p.dawType, p.dawVersion);
    return TrinaRow(
      cells: {
        'checkbox': TrinaCell(value: ''),
        'name': TrinaCell(value: p.displayName),
        'status': TrinaCell(value: p.status),
        'dawType': TrinaCell(value: dawDisplay),
        'bpm': TrinaCell(value: p.bpm?.toString() ?? ''),
        'key': TrinaCell(value: p.musicalKey ?? ''),
        'lastModified': TrinaCell(value: p.lastModifiedAt),
        'deadline': TrinaCell(value: p.deadlineStatus ?? ''),
        'launch': TrinaCell(value: ''),
        'data': TrinaCell(value: p),
      },
    );
  }

  List<TrinaRow> _mapProjectsToRows(List<MusicProject> projects) {
    // Build normalized root path → ScanMode lookup.
    final rootModes = <String, ScanMode>{
      for (final r in widget.scanRoots) path.normalize(r.path): r.scanMode,
    };

    // Normalise a stored path to forward slashes so that Windows paths
    // synced into the macOS database (C:\...) still match their scan root.
    String normForward(String p) => p.replaceAll('\\', '/');

    String? findRoot(String filePath) {
      final norm = normForward(path.normalize(filePath));
      for (final rootPath in rootModes.keys) {
        final normRoot = normForward(rootPath);
        final prefix = normRoot.endsWith('/') ? normRoot : '$normRoot/';
        if (norm.startsWith(prefix)) return rootPath;
      }
      return null;
    }

    final mergeFoldersByName = ref.read(mergeSmartFoldersByNameProvider);
    final alwaysShowSmartFolders = ref.read(alwaysShowSmartFoldersProvider);
    final flatProjects = <MusicProject>[];
    final folderGroups = <String, List<MusicProject>>{};

    for (final proj in projects) {
      final rootPath = findRoot(proj.filePath);
      final mode = rootPath != null
          ? (rootModes[rootPath] ?? ScanMode.flat)
          : ScanMode.flat;

      if (mode == ScanMode.smartFolder && rootPath != null) {
        // Normalise separators before computing relative path so Windows paths
        // (C:\...) resolve correctly when the database is opened on macOS.
        final normFilePath = normForward(path.normalize(proj.filePath));
        final normRootPath = normForward(rootPath);
        final rel = path.relative(normFilePath, from: normRootPath);
        final parts = path.split(rel);
        if (parts.length <= 1) {
          // Project sits directly in the root — no subfolder to group by.
          flatProjects.add(proj);
        } else {
          final key = smartFolderGroupKey(
            rootPath,
            parts,
            mergeSameName: mergeFoldersByName,
          );
          folderGroups.putIfAbsent(key, () => []).add(proj);
        }
      } else {
        flatProjects.add(proj);
      }
    }

    // Groups with only 1 currently-visible project are demoted to flat
    // (unless merge-by-name or always-show is on — see
    // smartFolderShouldRenderAsGroup).
    for (final entry in folderGroups.entries) {
      if (!smartFolderShouldRenderAsGroup(
        entry.value.length,
        mergeByName: mergeFoldersByName,
        alwaysShow: alwaysShowSmartFolders,
      )) {
        flatProjects.add(entry.value.first);
      }
    }
    final realGroups = Map.fromEntries(
      folderGroups.entries.where(
        (e) => smartFolderShouldRenderAsGroup(
          e.value.length,
          mergeByName: mergeFoldersByName,
          alwaysShow: alwaysShowSmartFolders,
        ),
      ),
    );

    // Build display items as (latestModified, row) so we can sort interleaved.
    final items = <(DateTime, TrinaRow)>[];

    for (final proj in flatProjects) {
      items.add((proj.lastModifiedAt, _projectToRow(proj)));
    }

    for (final entry in realGroups.entries) {
      final dir = entry.key;
      final group = List<MusicProject>.from(entry.value)
        ..sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
      final latestModified = group
          .map((p) => p.lastModifiedAt)
          .reduce((x, y) => x.isAfter(y) ? x : y);

      items.add((
        latestModified,
        TrinaRow(
          cells: {
            'checkbox': TrinaCell(value: ''),
            'name': TrinaCell(value: path.basename(dir)),
            'status': TrinaCell(value: ''),
            'dawType': TrinaCell(value: ''),
            'bpm': TrinaCell(value: ''),
            'key': TrinaCell(value: ''),
            'lastModified': TrinaCell(value: latestModified),
            'deadline': TrinaCell(value: ''),
            'launch': TrinaCell(value: ''),
            'data': TrinaCell(value: null),
          },
          type: TrinaRowType.group(
            children: FilteredList(
              initialList: group.map(_projectToRow).toList(),
            ),
            expanded: _lastKnownExpandedGroupNames.contains(path.basename(dir)),
          ),
        ),
      ));
    }

    // Sort all display items newest-first (the natural/default order).
    items.sort((a, b) => b.$1.compareTo(a.$1));
    final rows = items.map((e) => e.$2).toList();

    // Reapply whatever column sort was active before this row list was
    // (re)built — see applySortSnapshot's doc comment for why this can't
    // just wait for the state-manager-level restore in onLoaded.
    final sortField = _lastKnownSortField;
    final sortDirection = _lastKnownSortDirection;
    if (sortField != null && sortDirection != null) {
      applySortSnapshot(
        rows,
        sortField,
        sortDirection,
        excludeGroupsFromSort: ref.read(excludeSmartFoldersFromSortProvider),
      );
    }

    return rows;
  }

  @override
  void didUpdateWidget(_PlutoProjectsTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    final projectsChanged = oldWidget.projects != widget.projects;
    final scanJustFinished = oldWidget.isScanning && !widget.isScanning;
    final rootsChanged = oldWidget.scanRoots != widget.scanRoots;

    if (rootsChanged && !widget.isScanning) {
      _rebuildRows();
      return;
    }

    if (projectsChanged || scanJustFinished) {
      // While scanning, skip every intermediate update — the blocking overlay
      // covers the table. Do one clean rebuild when the scan finishes.
      if (!widget.isScanning) {
        // If the set of project IDs hasn't changed (only cell values like BPM,
        // key, lastModified, etc. were updated), update cells in-place so group
        // expansion state is never disturbed. Fall back to _rebuildRows() when
        // projects are structurally added or removed.
        if (_sameProjectIds(oldWidget.projects, widget.projects) &&
            _tableRowsMatchProjects(widget.projects)) {
          _updateCellsInPlace(widget.projects);
        } else {
          _rebuildRows();
        }
      }
    } else if (oldWidget.selectedIds != widget.selectedIds) {
      // Selection changed only — update cell values to invalidate renderer cache
      // without destroying rows (which would reset folder expanded/collapsed state).
      if (stateManager != null) {
        for (final row in stateManager!.rows) {
          final project = row.cells['data']?.value as MusicProject?;
          if (project != null) {
            row.cells['checkbox']?.value =
                widget.selectedIds.contains(project.id) ? 'selected' : '';
          }
        }
        stateManager!.notifyListeners();
      }
    }

    // Also check if any project's lastModifiedAt changed (for color updates during scanning)
    if (oldWidget.projects.length == widget.projects.length) {
      bool hasModifiedDates = false;
      for (int i = 0; i < widget.projects.length; i++) {
        if (i < oldWidget.projects.length) {
          if (widget.projects[i].lastModifiedAt !=
              oldWidget.projects[i].lastModifiedAt) {
            hasModifiedDates = true;
            break;
          }
        }
      }

      if (hasModifiedDates && stateManager != null) {
        // Update the lastModified cell values to trigger renderer refresh
        for (
          int i = 0;
          i < stateManager!.rows.length && i < widget.projects.length;
          i++
        ) {
          final project = widget.projects[i];
          final row = stateManager!.rows[i];
          if (row.cells['lastModified'] != null) {
            row.cells['lastModified']!.value = project.lastModifiedAt;
          }
        }
        stateManager!.notifyListeners();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Rebuild rows when phase config changes so renderer closures re-run
    // with fresh colors/names. notifyListeners() alone only repaints cells
    // whose values changed; _rebuildRows() forces a full renderer re-invoke.
    void rebuildForPhaseConfig() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildRows();
      });
    }

    ref.listen(phaseColorsProvider, (_, _) => rebuildForPhaseConfig());
    ref.listen(customPhasesProvider, (_, _) => rebuildForPhaseConfig());
    ref.listen(finishedPhaseProvider, (_, _) => rebuildForPhaseConfig());
    // Flag that the grid (recreated via key change) needs a full row rebuild
    // once onLoaded fires, to bust TrinaGrid's renderer cache on theme switch.
    ref.listen(activeThemeProvider, (prev, next) {
      if (prev != next) _needsThemeRefresh = true;
    });
    // When the search query changes, ask TrinaGrid to repaint so the
    // "matched in description" icon in the name renderer reflects the new query.
    ref.listen(projectsSearchProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stateManager?.notifyListeners();
      });
    });
    // Repaint rows when the currently playing track changes (for highlight).
    ref.listen(desktopPlayerProvider, (prev, next) {
      if (prev?.project.id != next?.project.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stateManager?.notifyListeners();
        });
      }
    });
    ref.listen(sessionModeProvider, (prev, next) {
      if (prev != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stateManager?.notifyListeners();
        });
      }
    });
    ref.listen(activeProjectProvider, (prev, next) {
      if (prev?.id != next?.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stateManager?.notifyListeners();
        });
      }
    });
    ref.listen(workTimerPausedProvider, (prev, next) {
      if (prev != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stateManager?.notifyListeners();
        });
      }
    });
    ref.listen(lastModifiedColorProvider, (prev, next) {
      if (prev != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stateManager?.notifyListeners();
        });
      }
    });
    final columns = [
      TrinaColumn(
        title: '',
        field: 'checkbox',
        type: TrinaColumnType.text(),
        width: 50,
        minWidth: 50,
        frozen: TrinaColumnFrozen.start,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableFilterMenuItem: false,
        enableSorting: false,
        enableEditingMode: false,
        titleRenderer: (rendererContext) {
          final style = rendererContext.stateManager.configuration.style;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: rendererContext.column.backgroundColor,
              border: BorderDirectional(
                end: style.enableColumnBorderVertical
                    ? BorderSide(color: style.borderColor)
                    : BorderSide.none,
              ),
            ),
            child: Center(
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: widget.areAllSelected,
                  tristate:
                      widget.selectedIds.isNotEmpty && !widget.areAllSelected,
                  onChanged: (_) => widget.onToggleSelectAll(),
                ),
              ),
            ),
          );
        },
        renderer: (rendererContext) {
          final row = rendererContext.row;
          final project = row.cells['data']?.value as MusicProject?;
          if (project == null) {
            if (row.type.isGroup) {
              // Selects/deselects every project in this smart-folder group in
              // one click — the group may be collapsed, or only partially
              // selected from prior individual clicks, so this reads live
              // off the group's own children rather than any cached count.
              final childIds = groupChildProjectIds(row);
              final allSelected =
                  childIds.isNotEmpty &&
                  childIds.every(widget.selectedIds.contains);
              final anySelected = childIds.any(widget.selectedIds.contains);
              return Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: allSelected,
                  tristate: anySelected && !allSelected,
                  onChanged: childIds.isEmpty
                      ? null
                      : (_) => widget.onToggleGroupSelection(childIds),
                ),
              );
            }
            return _ExpandArrowCell(
              row: row,
              stateManager: rendererContext.stateManager,
            );
          }
          final isSelected = widget.selectedIds.contains(project.id);
          return Transform.scale(
            scale: 0.78,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) {
                // A modifier-held click on this cell is already handled once,
                // at row level, by the grid's rowWrapper below — this cell is
                // part of the row it wraps. Acting on it here as well would
                // toggle the same project twice and cancel itself out.
                if (selectionModifierHeld()) return;
                widget.onToggleSelection(project.id);
              },
            ),
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.name,
        field: 'name',
        type: TrinaColumnType.text(),
        enableColumnDrag: true,
        enableContextMenu: false,
        enableEditingMode: false,
        width: 600,
        minWidth: 200,
        frozen: TrinaColumnFrozen.start,
        // Zeroed so cover art can sit flush against the cell's left border and
        // run the full row height; everything else in the cell re-applies the
        // grid's usual horizontal inset itself.
        cellPadding: EdgeInsets.zero,
        renderer: (rendererContext) {
          final project =
              rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) {
            return Padding(
              padding: _kNameCellInset,
              child: _FolderNameCell(
                row: rendererContext.row,
                stateManager: rendererContext.stateManager,
                folderName: rendererContext.cell.value.toString(),
              ),
            );
          }

          final fileExists = ref
              .read(fileExistenceCacheProvider)
              .exists(project.filePath);

          final currentQuery = ref.read(projectsSearchProvider);
          final matchedOutsideName =
              currentQuery.trim().isNotEmpty &&
              !fuzzyMatchAll(project.displayName, currentQuery);
          final isNotesMatch =
              matchedOutsideName &&
              project.notes != null &&
              fuzzyMatchAll(project.notes!, currentQuery);
          final isProjectNotesMatch =
              matchedOutsideName &&
              !isNotesMatch &&
              project.projectNotes != null &&
              fuzzyMatchAll(project.projectNotes!, currentQuery);

          final isNewlyDiscovered = ref
              .watch(recentlyDiscoveredProjectsProvider)
              .contains(project.id);

          // Tree connector for child rows inside a folder group
          final depth = rendererContext.row.depth;
          final parent = rendererContext.row.parent;
          final isLastChild =
              parent == null ||
              !parent.type.isGroup ||
              parent.type.group.children.isEmpty ||
              parent.type.group.children.last == rendererContext.row;

          // Cover art (#110) bleeds off the cell's left border at full row
          // height and fades out to the right, so the artwork reads larger
          // than the square it occupies and the row's text can start over its
          // tail. Undecorated projects get nothing — no placeholder, no
          // auto-assigned colour — so the list stays as quiet as it was.
          final hasBleed = projectHasCoverArt(project);
          // Nested rows keep their tree connector clear of the artwork —
          // a guide line drawn across a cover reads as damage, not structure.
          final bleedLeft = depth > 0 ? _kNameCellTreeConnectorWidth : 0.0;

          final content = Row(
            children: [
              if (depth > 0)
                SizedBox(
                  width: _kNameCellTreeConnectorWidth,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: _TreeConnectorPainter(
                      isLast: isLastChild,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              // Cover art is drawn behind this row, so only the accent badge
              // sits inline — and that is nothing at all unless the user chose
              // a colour or an icon. Either way the name clears the artwork's
              // solid half.
              if (hasBleed)
                const SizedBox(width: _kNameCellBleedTextOffset)
              else if (projectHasVisualIdentity(project)) ...[
                ProjectCoverAvatar(project: project, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(rendererContext.cell.value.toString())),
              // Version count, so a stacked song is distinguishable from an
              // ordinary project at a glance rather than only once opened.
              if (project.isVirtual) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: AppLocalizations.of(
                    context,
                  )!.stackTooltipStacked(project.versionCount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.layers,
                          size: 11,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${project.versionCount}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (isNewlyDiscovered) ...[
                const SizedBox(width: 6),
                _NewProjectBadge(
                  onDismiss: () => ref
                      .read(recentlyDiscoveredProjectsProvider.notifier)
                      .dismiss(project.id),
                ),
              ],
              if (isNotesMatch)
                Tooltip(
                  message: AppLocalizations.of(context)!.matchedInDescription,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.notes,
                      size: 14,
                      color: Colors.amber.shade600,
                    ),
                  ),
                ),
              if (isProjectNotesMatch)
                Tooltip(
                  message: AppLocalizations.of(
                    context,
                  )!.matchedInProjectNotes,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: Colors.amber.shade600,
                    ),
                  ),
                ),
              // An archived row stays in the list when its originals were
              // kept, and would otherwise look exactly like any other — the
              // badge is the only thing saying a zip of it exists. The tooltip
              // distinguishes the two archived states, since one is still
              // openable in the DAW and the other is not.
              if (project.isArchived && !MobileUtils.isMobile())
                Tooltip(
                  message: fileExists
                      ? AppLocalizations.of(context)!.archivedWithLocalCopy
                      : AppLocalizations.of(context)!.archivedAwayTooltip,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.archive_outlined,
                      size: 14,
                      color: fileExists
                          ? Colors.blueGrey.shade300
                          : Colors.blueGrey.shade200,
                    ),
                  ),
                ),
              // isMissingFileCandidate keeps this off stacks: their path is a
              // folder, so "no file here" is normal, not a missing file. It
              // keeps it off archived projects too — their files are gone on
              // purpose, and the archive badge above already says so.
              if (!fileExists &&
                  project.isMissingFileCandidate &&
                  !MobileUtils.isMobile())
                Tooltip(
                  message: AppLocalizations.of(
                    context,
                  )!.sourceFileNotFoundOnThisMachine,
                  child: Icon(
                    Icons.cloud_off,
                    size: 14,
                    color: Colors.orange.shade400,
                  ),
                ),
            ],
          );

          if (!hasBleed) {
            return Padding(padding: _kNameCellInset, child: content);
          }

          // The artwork is painted first and the text over it: the fade has
          // already taken it to near-nothing by the time the two overlap.
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: bleedLeft,
                top: 0,
                bottom: 0,
                child: ProjectCoverBleed(
                  project: project,
                  height: _kNameCellBleedHeight,
                  width: _kNameCellBleedWidth,
                  solidFraction:
                      _kNameCellBleedHeight / _kNameCellBleedWidth,
                ),
              ),
              Padding(padding: _kNameCellInset, child: content),
            ],
          );
        },
      ),
      TrinaColumn(
        title: l10n.phase,
        field: 'status',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 140,
        minWidth: 120,
        renderer: (rendererContext) {
          final project =
              rendererContext.row.cells['data']?.value as MusicProject?;
          final status = rendererContext.cell.value as String? ?? '';
          final translatedStatus = _translateStatus(context, status);
          final textWidget = Row(
            children: [
              Text(
                translatedStatus,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: _getStatusColor(status).withValues(alpha: 0.7),
              ),
            ],
          );

          if (project == null) return const SizedBox.shrink();

          return GestureDetector(
            onTapDown: (TapDownDetails details) {
              _showPhaseMenu(
                context,
                project,
                details.globalPosition,
                rendererContext,
              );
            },
            child: textWidget,
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.daw,
        field: 'dawType',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: dawColumnWidth(
          widget.projects.map((p) => dawDisplayLabel(p.dawType, p.dawVersion)),
        ),
        minWidth: 100,
        renderer: (rendererContext) {
          final project =
              rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) return const SizedBox.shrink();
          final dawType = rendererContext.cell.value as String? ?? '';
          final logoPath = getDawLogoPath(dawType);

          final content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logoPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Image.asset(
                    logoPath,
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              Flexible(child: Text(dawType, overflow: TextOverflow.ellipsis)),
            ],
          );

          return content;
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.bpm,
        field: 'bpm',
        type: TrinaColumnType.text(),
        width: 80,
        minWidth: 70,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final project =
              rendererContext.row.cells['data']?.value as MusicProject?;
          final textWidget = Text(rendererContext.cell.value.toString());

          if (project == null) return textWidget;

          return textWidget;
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.key
            .split(' ')
            .first, // Get just "Key" from "Key (e.g., C#m, F major)"
        field: 'key',
        type: TrinaColumnType.text(),
        width: 160,
        minWidth: 140,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final project =
              rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) {
            return Text(rendererContext.cell.value.toString());
          }

          final key = project.musicalKey;
          final camelot = project.camelotCode;

          if (key == null || key.isEmpty) {
            return const SizedBox.shrink();
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  key,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (camelot != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: 1,
                    height: 14,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    camelot,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.lastModifiedColumn,
        field: 'lastModified',
        // Cell values are raw DateTimes (not the formatted display string)
        // so ascending/descending sort compares chronologically instead of
        // alphabetically — a locale format like "Jul 21, 2026" would
        // otherwise sort by month name text, not by actual date.
        type: TrinaColumnType.custom(compare: compareLastModifiedCellValues),
        enableEditingMode: false,
        width: 200,
        minWidth: 160,
        renderer: (rendererContext) {
          final project =
              rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) return const SizedBox.shrink();

          return Consumer(
            builder: (context, ref, _) {
              final colorEnabled = ref.watch(lastModifiedColorProvider);
              final finishedPhases = ref.watch(finishedPhaseProvider);
              final defaultColor =
                  Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

              Color textColor;
              if (!colorEnabled) {
                textColor = defaultColor;
              } else {
                final status = project.status;
                if (finishedPhases.contains(status)) {
                  textColor = Colors.green;
                } else {
                  final now = DateTime.now();
                  final daysSinceModified = now
                      .difference(project.lastModifiedAt)
                      .inDays;

                  if (daysSinceModified < 21) {
                    textColor = defaultColor;
                  } else if (daysSinceModified < 60) {
                    final ratio = (daysSinceModified - 21) / 39.0;
                    textColor = Color.lerp(
                      Colors.yellow.shade300,
                      Colors.orange.shade400,
                      ratio,
                    )!;
                  } else {
                    final ratio = ((daysSinceModified - 60) / 60.0).clamp(
                      0.0,
                      1.0,
                    );
                    textColor = Color.lerp(
                      Colors.orange.shade400,
                      Colors.red.shade400,
                      ratio,
                    )!;
                  }
                }
              }

              return Text(
                widget.dateFormat.format(project.lastModifiedAt),
                style: TextStyle(color: textColor),
              );
            },
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.deadline,
        field: 'deadline',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
        renderer: (rendererContext) {
          final project =
              rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null || project.deadline == null) {
            return const SizedBox.shrink();
          }
          return Consumer(
            builder: (context, ref, _) {
              final finishedPhases = ref.watch(finishedPhaseProvider);
              if (finishedPhases.contains(project.status))
                return const SizedBox.shrink();

              final daysUntil = project.daysUntilDeadline ?? 0;

              Color iconColor;
              IconData iconData;
              String text;

              if (daysUntil < 0) {
                iconColor = Colors.red;
                iconData = Icons.warning;
                text = AppLocalizations.of(context)!.daysLate(daysUntil.abs());
              } else if (daysUntil == 0) {
                iconColor = Colors.red;
                iconData = Icons.today;
                text = AppLocalizations.of(context)!.dueToday;
              } else if (daysUntil <= 7) {
                iconColor = Colors.orange;
                iconData = Icons.schedule;
                text = AppLocalizations.of(context)!.daysLeft(daysUntil);
              } else {
                iconColor = Colors.blue;
                iconData = Icons.calendar_today;
                text = '${daysUntil}d left';
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconData, size: 12, color: iconColor),
                    const SizedBox(width: 3),
                    Text(
                      text,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.actions,
        field: 'launch',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        enableSorting: false,
        enableColumnDrag: false,
        width: 290, // Increased width to accommodate all action buttons
        minWidth: 250,
        renderer: (ctx) {
          final project = ctx.row.cells['data']?.value as MusicProject?;
          if (project == null) return const SizedBox.shrink();

          // Lógica para determinar o diretório pai
          final String projectPath = project.filePath;
          final bool sourceFileExists =
              File(projectPath).existsSync() ||
              Directory(projectPath).existsSync();
          final String folderPath =
              FileSystemEntity.isDirectorySync(projectPath)
              ? projectPath // Se for um diretório, usa o próprio caminho
              : path.dirname(
                  projectPath,
                ); // Se for um arquivo, usa o diretório pai

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play Preview Song button (always show, but disabled if no preview)
              Consumer(
                builder: (context, ref, _) {
                  final playerRequest = ref.watch(desktopPlayerProvider);
                  final isPlaying = ref.watch(desktopIsPlayingProvider);
                  final isCurrent = playerRequest?.project.id == project.id;
                  final isActive = isPlaying && isCurrent;
                  final hasPreview =
                      project.previewSongPath?.isNotEmpty == true ||
                      project.previewSongAutoPath != null;
                  final iconColor = project.previewSongPath?.isNotEmpty == true
                      ? Colors.green
                      : project.previewSongAutoPath != null
                      ? Colors.amber
                      : Colors.grey;
                  return _PlayButtonWithGlow(
                    isActive: isActive,
                    glowColor: iconColor,
                    child: IconButton(
                      icon: Icon(
                        isCurrent
                            ? (isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle)
                            : (hasPreview
                                  ? Icons.play_circle
                                  : Icons.play_circle_outline),
                      ),
                      iconSize: 24,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: isCurrent
                          ? (isPlaying
                                ? AppLocalizations.of(context)!.pause
                                : AppLocalizations.of(context)!.playPreview)
                          : project.previewSongAutoPath != null &&
                                project.previewSongPath?.isNotEmpty != true
                          ? '${AppLocalizations.of(context)!.playPreview} (P)\n⚡ ${AppLocalizations.of(context)!.autoDetected}: ${path.basename(project.previewSongAutoPath!)}'
                          : '${AppLocalizations.of(context)!.playPreview} (P)',
                      onPressed: () {
                        if (isCurrent) {
                          ref
                              .read(desktopPlayerToggleRequestProvider.notifier)
                              .bump();
                        } else {
                          _playPreviewSong(project);
                        }
                      },
                      color: iconColor,
                    ),
                  );
                },
              ),
              // Separator (always show)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Text(
                  '|',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ),
              // Launch / Start Session button — Consumer makes it self-reactive to
              // sessionModeProvider and activeProjectProvider without relying on
              // TrinaGrid to rebuild its cached column objects.
              Consumer(
                builder: (context, ref, _) {
                  final mode = ref.watch(sessionModeProvider);
                  final subProject = ref.watch(activeProjectProvider);
                  if (!mode) {
                    return IconButton(
                      icon: const Icon(Icons.open_in_new),
                      iconSize: 24,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: '${AppLocalizations.of(context)!.openInDaw} (O)',
                      onPressed: () => _launchProject(project),
                    );
                  }
                  final isSubscribed = subProject?.id == project.id;
                  return IconButton(
                    icon: Icon(
                      isSubscribed
                          ? Icons.bookmark
                          : Icons.bookmark_add_outlined,
                    ),
                    iconSize: 24,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: isSubscribed
                        ? '${AppLocalizations.of(context)!.endSession} (S)'
                        : '${AppLocalizations.of(context)!.startSession} (S)',
                    color: isSubscribed ? Colors.green.shade400 : null,
                    onPressed: () {
                      if (isSubscribed) {
                        confirmEndSession(context, ref);
                      } else {
                        confirmStartSession(context, ref, project);
                      }
                    },
                  );
                },
              ),
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Text(
                  '|',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ),
              // View button
              IconButton(
                icon: const Icon(Icons.assignment),
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip:
                    '${AppLocalizations.of(context)!.tooltipViewDetails} (D)',
                onPressed: () => _viewProjectDetails(project),
              ),
              // Open Folder button (desktop only — no file manager on mobile)
              if (!MobileUtils.isMobile())
                Tooltip(
                  message: sourceFileExists
                      ? ''
                      : AppLocalizations.of(
                          context,
                        )!.sourceFileNotFoundOnThisMachine,
                  child: IconButton(
                    icon: const Icon(Icons.folder_open),
                    iconSize: 24,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: sourceFileExists
                        ? '${AppLocalizations.of(context)!.openFolder} (F)'
                        : null,
                    onPressed: sourceFileExists
                        ? () => _openProjectFolder(project)
                        : null,
                  ),
                ),
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Text(
                  '|',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ),
              // Hidden button
              IconButton(
                icon: Icon(
                  project.hidden ? Icons.visibility : Icons.visibility_off,
                ),
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                color: project.hidden
                    ? Colors.green.shade300
                    : Colors.red.shade300,
                tooltip: project.hidden
                    ? AppLocalizations.of(context)!.unhide
                    : AppLocalizations.of(context)!.hide,
                onPressed: () async {
                  if (project.hidden) {
                    // Unhide - no confirmation needed
                    widget.onUnhideProjects([project.id]);
                  } else {
                    // Hide - show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).cardColor,
                        title: Text(AppLocalizations.of(context)!.hide),
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!.hideProjectMessage(project.displayName),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade300,
                              foregroundColor: Colors.black,
                            ),
                            child: Text(AppLocalizations.of(context)!.hide),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      widget.onHideProjects([project.id]);
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
      // Hidden backing column for passing the model instance
      TrinaColumn(
        title: 'data',
        field: 'data',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 0,
        hide: true,
      ),
    ]; // <-- Semicolon final do array de colunas

    // Watched (not read) so toggling it rebuilds this widget and — via the
    // grid's key below — remounts the grid, reusing the same restore path
    // that already survives a theme/locale remount to reapply expand/sort
    // state, now also correctly under the new group-sort behavior.
    final excludeFoldersFromSort = ref.watch(
      excludeSmartFoldersFromSortProvider,
    );
    // Same remount rationale: toggling this changes which projects land in
    // which group (see smartFolderGroupKey), so the grid needs a fresh key
    // to rebuild its row-group tree rather than diffing stale groups.
    final mergeFoldersByName = ref.watch(mergeSmartFoldersByNameProvider);
    // Same remount rationale again: toggling this changes which groups
    // demote to flat rows (see smartFolderShouldRenderAsGroup).
    final alwaysShowSmartFolders = ref.watch(alwaysShowSmartFoldersProvider);
    final initialRows = _mapProjectsToRows(widget.projects);

    if (widget.projects.isEmpty) {
      final allProjectsAsync = ref.watch(allProjectsStreamProvider);
      final hasProjects = (allProjectsAsync.value?.isNotEmpty) ?? false;
      final hasScanRoots = ref.watch(scanRootsProvider).isNotEmpty;
      final reason = projectsEmptyStateReason(
        hasProjects: hasProjects,
        hasScanRoots: hasScanRoots,
      );
      final String title;
      final String hint;
      switch (reason) {
        case ProjectsEmptyStateReason.filteredToZero:
          title = l10n.noResultsForFilter;
          hint = l10n.noResultsForFilterHint;
        case ProjectsEmptyStateReason.noScanRootsYet:
          title = l10n.noProjectsFound;
          hint = l10n.noProjectsFoundHint;
        case ProjectsEmptyStateReason.scanRootsFoundNothing:
          title = l10n.noProjectsFound;
          hint = l10n.noProjectsFoundInFoldersHint;
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasProjects ? Icons.search_off : Icons.library_music_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Read from Riverpod so the spec and all theme colors come from the same
    // build tick, preventing a one-frame inversion when the user switches
    // themes.
    final activeTheme = ref.watch(themeDataProvider);
    final themeSpec = ref.watch(activeThemeProvider);
    // Was `themeType == AppThemeType.neonDark`. A user theme with a saturated
    // accent gets the accent-tinted grid chrome too; a muted one falls back
    // to divider/text colors the way Classic Dark always has.
    final isVividAccent = themeSpec.hasVividAccent;

    final playingHighlightColor = activeTheme.colorScheme.primary.withValues(
      alpha: 0.32,
    );
    // Row colors come off the spec rather than a "is this Neon Dark?" check —
    // see ThemeDerivations for why a muted accent gets different treatment.
    final rowSelectColor = themeSpec.gridRowSelectColor;
    final oddColor = themeSpec.gridRowOddColor;
    final evenColor = themeSpec.gridRowEvenColor;

    final grid = TrinaGrid(
      key: ValueKey(
        // nameDateStripping is in the key because displayName is cached into
        // TrinaCell values at row-build time — notifyListeners() alone would
        // leave the old, date-prefixed names on screen until the next scan.
        // themeSpec.identityKey rather than just the theme id: editing a user
        // theme's colors keeps the same id, and TrinaGrid caches its renderer
        // colors, so the id alone would leave the old palette on screen.
        'trina_grid_${l10n.localeName}_${themeSpec.identityKey}_${excludeFoldersFromSort}_${mergeFoldersByName}_${alwaysShowSmartFolders}_${ref.watch(nameDateStrippingProvider)}',
      ),
      columnMenuDelegate: const FitAllColumnsMenuDelegate(),
      columns: columns,
      rows: initialRows,
      // Ctrl/cmd- and shift-click anywhere on a row extend the checkbox
      // selection, so building a multi-selection doesn't mean aiming at the
      // 50px checkbox column. Group header rows carry no project, so they stay
      // unwrapped and keep their own (whole-folder) checkbox behavior.
      rowWrapper: (context, rowWidget, row, _) => rowClickSelectionWrapper(
        row: row,
        rowWidget: rowWidget,
        rowId: (r) => (r.cells['data']?.value as MusicProject?)?.id,
        onRowClick: widget.onRowClickSelection,
      ),
      // Keeps the shift-click anchor on whichever row is highlighted, however
      // the highlight got there — a plain click or an arrow-key move. Skipped
      // while a selection modifier is held: a shift-click moves the highlight
      // to the row it just range-selected to, which must not become the anchor
      // for the *next* shift-click, and a ctrl-click has already recorded its
      // own anchor by the time this fires.
      onActiveCellChanged: (TrinaGridOnActiveCellChangedEvent event) {
        if (selectionModifierHeld()) return;
        final project = event.cell?.row.cells['data']?.value as MusicProject?;
        if (project != null) widget.onRowHighlighted(project.id);
      },
      rowColorCallback: (TrinaRowColorContext ctx) {
        final project = ctx.row.cells['data']?.value as MusicProject?;
        if (project != null) {
          final playing = ref.read(desktopPlayerProvider);
          if (playing?.project.id == project.id) return playingHighlightColor;
          final isSession = ref.read(activeProjectProvider)?.id == project.id;
          final isActivated = stateManager?.currentRow == ctx.row;
          if (isSession) {
            // Read current paused state directly so notifyListeners refreshes pick it up.
            final isPaused = ref.read(workTimerPausedProvider);
            return isPaused
                ? const Color(0x70FBBF24) // amber when paused
                : const Color(0x7022C55E); // green when active
          }
          if (isActivated) return rowSelectColor;
        }
        return ctx.rowIdx.isOdd ? oddColor : evenColor;
      },
      onLoaded: (TrinaGridOnLoadedEvent event) {
        stateManager = event.stateManager;
        // TrinaGrid defaults to cell selection, so dragging across the table
        // paints a range and leaves cells outlined. Nothing here acts on a
        // selected range — bulk actions go through the checkbox column — so
        // turn it off entirely. `currentCell` still tracks the last tapped
        // cell, which is what the row highlight and the single-key shortcuts
        // (P/O/D/F/S, Enter) navigate from.
        stateManager!.setSelectingMode(TrinaGridSelectingMode.none);
        stateManager!.setRowGroup(
          excludeFoldersFromSort
              ? _GroupOrderStableRowGroupDelegate(
                  // Returning null for all columns disables TrinaGrid's auto
                  // expand icon; we render our own in the checkbox column.
                  resolveColumnDepth: (column) => null,
                  showText: (cell) => true,
                  showFirstExpandableIcon: false,
                  showCount: false,
                )
              : TrinaRowGroupTreeDelegate(
                  resolveColumnDepth: (column) => null,
                  showText: (cell) => true,
                  showFirstExpandableIcon: false,
                  showCount: false,
                ),
        );
        stateManager!.addListener(_onStateManagerChanged);
        if (_needsThemeRefresh) {
          // The deferred _rebuildRows() below busts the renderer cache
          // AND restores expand/sort state itself, so don't also call
          // _restoreTableStateSnapshot() here — _mapProjectsToRows()
          // already pre-applied the same snapshot when building
          // initialRows above, so both calls would just be settling an
          // already-correct grid a second time. Two separate repaints
          // (one now, one a frame later) of visually-identical content is
          // exactly what reads as the smart folder flickering on a quick
          // theme switch, since each one replaces the group row's object
          // identity. One settle instead of two.
          _needsThemeRefresh = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _rebuildRows();
          });
        } else {
          // Locale switches (or any other remount) have no renderer-cache
          // issue to fix, so a synchronous restore is enough — no need to
          // wait a frame like the theme-refresh path above.
          _restoreTableStateSnapshot();
        }
        _updateGroupExpandNotifier();
      },
      onRowSecondaryTap: (TrinaGridOnRowSecondaryTapEvent event) {
        final project = event.row.cells['data']?.value as MusicProject?;
        if (project != null && mounted) {
          _showContextMenu(context, project, event.offset);
        }
      },
      // The dashboard is a read-only view: BPM and key are edited on the
      // project detail page, which is also where the bpm.txt / key.txt
      // sidecars are written (MetadataSidecarService). Inline editing here
      // also meant an in-cell TextField with its own border, which is what
      // made cells look randomly "selected".
      mode: TrinaGridMode.readOnly,
      configuration: TrinaGridConfiguration(
        localeText: trinaGridLocaleTextFor(context),
        style: TrinaGridStyleConfig(
          gridBackgroundColor: activeTheme.cardColor,
          gridBorderColor: isVividAccent
              ? activeTheme.colorScheme.primary.withValues(alpha: 0.25)
              : activeTheme.dividerColor.withValues(alpha: 0.4),
          borderColor: isVividAccent
              ? activeTheme.colorScheme.primary.withValues(alpha: 0.15)
              : activeTheme.dividerColor.withValues(alpha: 0.25),
          gridBorderRadius: BorderRadius.zero,
          // Match gridBackgroundColor so the empty area below rows is uniform
          // across frozen (checkbox+name) and scrollable columns.
          rowColor: activeTheme.cardColor,
          cellColorInEditState: Colors.transparent,
          cellColorInReadOnlyState: Colors.transparent,
          columnTextStyle: TextStyle(
            color: isVividAccent
                ? activeTheme.colorScheme.primary
                : activeTheme.textTheme.titleMedium?.color,
            fontWeight: FontWeight.w600,
          ),
          cellTextStyle: TextStyle(
            color: activeTheme.textTheme.bodyMedium?.color,
          ),
          columnHeight: 44,
          rowHeight: _kNameCellBleedHeight,
          // Transparent so rowColorCallback controls all row backgrounds
          // (session green/yellow, playing, and click-selection) with no
          // per-cell border/fill on click.
          activatedBorderColor: Colors.transparent,
          activatedColor: Colors.transparent,
          iconColor: isVividAccent
              ? activeTheme.colorScheme.primary.withValues(alpha: 0.7)
              : activeTheme.textTheme.bodyMedium?.color ?? Colors.grey,
          menuBackgroundColor: activeTheme.cardColor,
          oddRowColor: oddColor,
          evenRowColor: evenColor,
        ),
        scrollbar: const TrinaGridScrollbarConfig(showHorizontal: false),
        // rowClickSelectionWrapper only adds a Listener around each row, so
        // every row still measures exactly rowHeight. Saying so keeps
        // TrinaGrid's ListView itemExtent fast path, which it otherwise drops
        // for variable-height wrappers.
        rowWrapperIsConstantHeight: true,
        columnSize: const TrinaGridColumnSizeConfig(
          autoSizeMode: TrinaAutoSizeMode.scale,
          resizeMode: TrinaResizeMode.pushAndPull,
        ),
        shortcut: TrinaGridShortcut(
          actions: {
            ...TrinaGridShortcut.defaultActions,
            LogicalKeySet(LogicalKeyboardKey.enter): _TrinaProjectAction(
              _viewProjectDetails,
            ),
            LogicalKeySet(LogicalKeyboardKey.numpadEnter): _TrinaProjectAction(
              _viewProjectDetails,
            ),
            LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
                _TrinaProjectAction(_viewProjectDetails),
            LogicalKeySet(LogicalKeyboardKey.keyP): _TrinaProjectAction(
              _playPreviewSong,
            ),
            LogicalKeySet(LogicalKeyboardKey.keyO): _TrinaProjectAction(
              _launchProject,
            ),
            LogicalKeySet(LogicalKeyboardKey.keyD): _TrinaProjectAction(
              _viewProjectDetails,
            ),
            LogicalKeySet(LogicalKeyboardKey.keyF): _TrinaProjectAction(
              _openProjectFolder,
            ),
            LogicalKeySet(LogicalKeyboardKey.keyS): _TrinaProjectAction(
              _toggleSession,
            ),
          },
        ),
      ),
      onRowChecked: null,
      onSelected: null,
      onRowDoubleTap: (TrinaGridOnRowDoubleTapEvent event) async {
        final project = event.row.cells['data']?.value as MusicProject?;
        if (project == null) return;

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDetailPage(projectId: project.id),
          ),
        );
      },
      createFooter: (stateManager) => const SizedBox.shrink(),
    );

    final dropTarget = DropTarget(
      enable: dropTargetEnabled,
      onDragUpdated: (detail) => _updateDragTarget(detail.localPosition),
      onDragExited: (_) => setState(() {
        _dragOverRowTop = null;
      }),
      onDragDone: (detail) {
        final sm = stateManager;
        MusicProject? targetProject;
        if (sm != null) {
          final scrollOffset = sm.scroll.bodyRowsVertical?.offset ?? 0;
          final rowIndex =
              ((detail.localPosition.dy - _gridHeaderHeight + scrollOffset) /
                      sm.rowTotalHeight)
                  .floor();
          if (rowIndex >= 0 && rowIndex < sm.rows.length) {
            targetProject =
                sm.rows[rowIndex].cells['data']?.value as MusicProject?;
          }
        }
        setState(() {
          _dragOverRowTop = null;
        });
        if (targetProject == null) return;
        for (final xFile in detail.files) {
          final path = xFile.path;
          final ext = '.${path.split('.').last.toLowerCase()}';
          if (_audioExtensions.contains(ext)) {
            _setPreviewSong(targetProject, path);
            return;
          }
        }
      },
      child: Stack(
        children: [
          grid,
          if (_dragOverRowTop != null)
            Positioned(
              top: _dragOverRowTop!,
              left: 0,
              right: 0,
              height: stateManager?.rowTotalHeight ?? _gridRowHeight,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.audio_file,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Drop to set as preview',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return dropTarget;
  }

  @override
  void dispose() {
    stateManager?.removeListener(_onStateManagerChanged);
    super.dispose();
  }
}

/// Custom TrinaGrid shortcut action that operates on the focused project row.
class _TrinaProjectAction extends TrinaGridShortcutAction {
  final Future<void> Function(MusicProject project) onProject;

  const _TrinaProjectAction(this.onProject);

  @override
  void execute({
    required TrinaKeyManagerEvent keyEvent,
    required TrinaGridStateManager stateManager,
  }) {
    if (stateManager.isEditing) return;
    final project = stateManager.currentRow?.cells['data']?.value;
    if (project is MusicProject) unawaited(onProject(project));
  }
}

class _ReleaseTitleDialog extends StatefulWidget {
  @override
  State<_ReleaseTitleDialog> createState() => _ReleaseTitleDialogState();
}

class _ReleaseTitleDialogState extends State<_ReleaseTitleDialog> {
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(AppLocalizations.of(context)!.enterReleaseTitle),
      content: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.releaseTitle,
          hintText: AppLocalizations.of(context)!.enterReleaseTitleHint,
        ),
        autofocus: true,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.pop(context, value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _titleController.text.trim()),
          child: Text(AppLocalizations.of(context)!.create),
        ),
      ],
    );
  }
}

class _TogglePlayPauseIntent extends Intent {
  const _TogglePlayPauseIntent();
}

class _SeekIntent extends Intent {
  final int seconds;
  const _SeekIntent(this.seconds);
}

class _PreviewSongDialog extends ConsumerStatefulWidget {
  final MusicProject project;
  final VoidCallback onClose;

  const _PreviewSongDialog({required this.project, required this.onClose});

  @override
  ConsumerState<_PreviewSongDialog> createState() => _PreviewSongDialogState();
}

class _PreviewSongDialogState extends ConsumerState<_PreviewSongDialog> {
  AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer? _warmPlayer;
  int _playerGen = 0;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  bool _isMono = false;
  bool _isGeneratingMono = false;
  String? _monoFilePath;
  AudioFileInfo? _fileInfo;
  String? _autoDetectedPath;

  String? get _effectivePreviewPath =>
      widget.project.previewSongPath?.isNotEmpty == true
      ? widget.project.previewSongPath
      : (_autoDetectedPath ?? widget.project.previewSongAutoPath);

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
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _attachListeners(_audioPlayer, _playerGen);
    if (widget.project.previewSongPath?.isNotEmpty == true) {
      _startPlayback();
      _startBackgroundPrep();
    } else if (widget.project.previewSongAutoPath != null) {
      _autoDetectedPath = widget.project.previewSongAutoPath;
      _startPlayback();
      _startBackgroundPrep();
    } else {
      Future.microtask(() async {
        final customFolders = ref.read(customMixdownFoldersProvider).value;
        final customFoldersByDaw = ref
            .read(customMixdownFoldersByDawProvider)
            .value;
        final file = MixdownDetectorService.findLatestMixdown(
          widget.project,
          customFolders: customFolders,
          customFoldersByDaw: customFoldersByDaw,
        );
        if (mounted && file != null) {
          setState(() => _autoDetectedPath = file.path);
          final repo = await ref.read(repositoryProvider.future);
          await repo.updateProject(
            widget.project.copyWith(previewSongAutoPath: file.path),
          );
          ref.invalidate(allProjectsStreamProvider);
          _startPlayback();
          _startBackgroundPrep();
        }
      });
    }
  }

  bool _hasAudioFile() {
    final p2 = _effectivePreviewPath;
    return p2 != null && p2.isNotEmpty;
  }

  bool _supportsMonoMix() {
    final p2 = _effectivePreviewPath;
    if (p2 == null || p2.isEmpty) return false;
    final ext = p2.toLowerCase().split('.').last;
    if (ext == 'wav') return true;
    if (Platform.isMacOS || Platform.isIOS) {
      return const {'mp3', 'flac', 'aif', 'aiff', 'aac', 'm4a'}.contains(ext);
    }
    return const {
      'mp3',
      'flac',
      'aif',
      'aiff',
      'ogg',
      'aac',
      'm4a',
    }.contains(ext);
  }

  Source _currentSource() {
    if (_isMono && _monoFilePath != null)
      return DeviceFileSource(_monoFilePath!);
    return DeviceFileSource(_effectivePreviewPath!);
  }

  void _startBackgroundPrep() {
    if (!_hasAudioFile()) return;
    final filePath = _effectivePreviewPath!;
    AudioAnalysisService.getFileInfo(filePath).then((info) {
      if (mounted && info != null) setState(() => _fileInfo = info);
    });
    if (_supportsMonoMix()) _prepareMonoFile(filePath);
  }

  Future<void> _prepareMonoFile(String filePath) async {
    final tmpDir = await getTemporaryDirectory();
    final outPath = '${tmpDir.path}/mono_${widget.project.id}.wav';
    final ok = await AudioAnalysisService.writeMonoWavFile(filePath, outPath);
    if (!mounted) return;
    if (ok) {
      setState(() => _monoFilePath = outPath);
      _preWarmAlt(DeviceFileSource(outPath));
    } else {
      final channels = await AudioAnalysisService.getChannelCount(filePath);
      if (mounted && channels == 1) {
        setState(() => _monoFilePath = filePath);
        _preWarmAlt(DeviceFileSource(filePath));
      }
    }
  }

  void _preWarmAlt(Source source) {
    _warmPlayer?.dispose();
    _warmPlayer = AudioPlayer();
    _warmPlayer!.setVolume(_volume);
    _warmPlayer!.setSource(source);
  }

  void _fadeIn(AudioPlayer player) {
    const steps = 12;
    const stepMs = 10;
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
        player.setVolume(_volume);
      }
    });
  }

  Future<void> _toggleMono() async {
    if (!_supportsMonoMix()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.monoRequiresWav)),
      );
      return;
    }
    final newMono = !_isMono;
    if (newMono && _monoFilePath == null) {
      setState(() => _isGeneratingMono = true);
      final tmpDir = await getTemporaryDirectory();
      final outPath = '${tmpDir.path}/mono_${widget.project.id}.wav';
      final ok = await AudioAnalysisService.writeMonoWavFile(
        _effectivePreviewPath!,
        outPath,
      );
      if (!mounted) return;
      if (!ok) {
        final channels = await AudioAnalysisService.getChannelCount(
          _effectivePreviewPath!,
        );
        if (!mounted) return;
        if (channels == 1) {
          setState(() {
            _monoFilePath = _effectivePreviewPath!;
            _isGeneratingMono = false;
          });
        } else {
          setState(() => _isGeneratingMono = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.monoUnsupportedFormat,
              ),
            ),
          );
          return;
        }
      } else {
        setState(() {
          _monoFilePath = outPath;
          _isGeneratingMono = false;
        });
      }
    }

    final wasPlaying = _isPlaying;
    final savedPosition = _position;
    setState(() => _isMono = newMono);

    final newActive = _warmPlayer ?? AudioPlayer();
    _warmPlayer = null;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.monoSwitchFailed(e.toString()),
            ),
          ),
        );
      }
    }

    await oldActive.stop();
    final altSource = _isMono
        ? DeviceFileSource(_effectivePreviewPath!)
        : (_monoFilePath != null ? DeviceFileSource(_monoFilePath!) : null);
    if (altSource != null) {
      _warmPlayer = oldActive;
      _warmPlayer!.setVolume(_volume);
      _warmPlayer!.setSource(altSource);
    } else {
      oldActive.dispose();
    }
  }

  Future<void> _startPlayback() async {
    if (!_hasAudioFile()) return;

    final file = File(_effectivePreviewPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.previewSongFileNotFound,
            ),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      await _audioPlayer.play(_currentSource());
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

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _warmPlayer?.dispose();
    widget.onClose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero || _position >= _duration) {
          await _audioPlayer.play(DeviceFileSource(_effectivePreviewPath!));
        } else {
          await _audioPlayer.resume();
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

  Future<void> _seek(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = target.isNegative
        ? Duration.zero
        : (_duration > Duration.zero && target > _duration
              ? _duration
              : target);
    await _audioPlayer.seek(clamped);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0
        ? '${twoDigits(hours)}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  static final _uuidPreviewRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_preview\.',
    caseSensitive: false,
  );

  String? _displayFileName() {
    // Prefer the stored display name, unless it's itself a UUID backup name
    final storedName = widget.project.previewSongFileName;
    if (storedName != null &&
        storedName.isNotEmpty &&
        !_uuidPreviewRe.hasMatch(storedName)) {
      return storedName;
    }
    // Fall back to the path basename, suppressing UUID-named backup downloads
    final fallback = path.basename(_effectivePreviewPath ?? '');
    if (fallback.isEmpty || _uuidPreviewRe.hasMatch(fallback)) return null;
    return fallback;
  }

  Widget _buildAndroidPlayerLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File name
        if (_autoDetectedPath != null &&
            widget.project.previewSongPath?.isNotEmpty != true)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.folder_open, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                const Text(
                  'Auto-detected from mixdown folder',
                  style: TextStyle(fontSize: 11, color: Colors.amber),
                ),
              ],
            ),
          ),
        if (_displayFileName() != null)
          Text(
            _displayFileName()!,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        if (_displayFileName() != null) const SizedBox(height: 8),
        const SizedBox(height: 8),
        // Transport controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_5),
              onPressed: () => _seek(-5),
              iconSize: 32,
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
              iconSize: 48,
              color:
                  _autoDetectedPath != null &&
                      widget.project.previewSongPath?.isNotEmpty != true
                  ? Colors.amber
                  : Theme.of(context).colorScheme.primary,
            ),
            IconButton(
              icon: const Icon(Icons.forward_5),
              onPressed: () => _seek(5),
              iconSize: 32,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Seek bar
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Theme.of(context).colorScheme.primary,
                thumbColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.25),
                overlayColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                trackHeight: 4.0,
              ),
              child: Slider(
                value: _duration.inMilliseconds > 0
                    ? _position.inMilliseconds.toDouble()
                    : 0.0,
                max: _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 100.0,
                onChanged: (value) async {
                  final position = Duration(milliseconds: value.toInt());
                  await _audioPlayer.seek(position);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Volume + mono on a single row
        Row(
          children: [
            Icon(
              _volume == 0
                  ? Icons.volume_off
                  : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
              size: 24,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            Expanded(
              child: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) async {
                  setState(() {
                    _volume = value;
                  });
                  await _audioPlayer.setVolume(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Toggle mono playback',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: _isGeneratingMono
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Checkbox(
                            value: _isMono,
                            onChanged: (_) => _toggleMono(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
    );
  }

  Widget _buildDesktopPlayerLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_displayFileName() != null) ...[
          Text(
            _displayFileName()!,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
        ],
        // Audio player controls
        Row(
          children: [
            Tooltip(
              message: '← −5s',
              child: IconButton(
                icon: const Icon(Icons.replay_5),
                onPressed: () => _seek(-5),
              ),
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
              iconSize: 32,
              color:
                  _autoDetectedPath != null &&
                      widget.project.previewSongPath?.isNotEmpty != true
                  ? Colors.amber
                  : null,
            ),
            Tooltip(
              message: '→ +5s',
              child: IconButton(
                icon: const Icon(Icons.forward_5),
                onPressed: () => _seek(5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      thumbColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.25),
                      overlayColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      trackHeight: 3.0,
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds.toDouble()
                          : 0.0,
                      max: _duration.inMilliseconds > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 100.0,
                      onChanged: (value) async {
                        final position = Duration(milliseconds: value.toInt());
                        await _audioPlayer.seek(position);
                      },
                    ),
                  ),
                  Row(
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
                ],
              ),
            ),
            // Volume control
            const SizedBox(width: 8),
            Icon(
              _volume == 0
                  ? Icons.volume_off
                  : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            SizedBox(
              width: 120,
              child: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) async {
                  setState(() {
                    _volume = value;
                  });
                  await _audioPlayer.setVolume(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Tooltip(
              message: 'Toggle mono playback',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: _isGeneratingMono
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Checkbox(
                            value: _isMono,
                            onChanged: (_) => _toggleMono(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
            const SizedBox(width: 12),
            Builder(
              builder: (ctx) {
                final dim = Theme.of(ctx).textTheme.bodySmall?.color;
                final ext = (widget.project.previewSongPath ?? '')
                    .toLowerCase()
                    .split('.')
                    .last;
                final formatLabel = switch (ext) {
                  'wav' => 'WAV',
                  'mp3' => 'MP3',
                  'flac' => 'FLAC',
                  'aif' || 'aiff' => 'AIFF',
                  'ogg' => 'OGG',
                  'aac' => 'AAC',
                  'm4a' => 'M4A',
                  _ => ext.toUpperCase(),
                };
                final parts = <String>[];
                if (_fileInfo != null) {
                  final sr = _fileInfo!.sampleRate;
                  parts.add(
                    sr % 1000 == 0
                        ? '${sr ~/ 1000} kHz'
                        : '${(sr / 1000).toStringAsFixed(1)} kHz',
                  );
                  if (_fileInfo!.bitDepth != null) {
                    parts.add('${_fileInfo!.bitDepth}-bit');
                  } else if (_fileInfo!.bitrateKbps != null) {
                    parts.add('${_fileInfo!.bitrateKbps} kbps');
                  }
                  parts.add(
                    _fileInfo!.channels == 1
                        ? 'Mono'
                        : _fileInfo!.channels == 2
                        ? 'Stereo'
                        : '${_fileInfo!.channels}ch',
                  );
                }
                parts.add(formatLabel);
                return Text(
                  parts.join(' · '),
                  style: TextStyle(fontSize: 11, color: dim),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _sharePreviewSong() async {
    // Covers a manually-selected preview song AND an auto-detected mixdown —
    // both are equally shareable, only the source of the path differs.
    final effectivePath = _effectivePreviewPath;
    if (effectivePath == null || effectivePath.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[preview_share] No effective preview path for project=${widget.project.id}',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.previewSongFileNotFound,
            ),
          ),
        );
      }
      return;
    }

    // Skip if it's a Drive file reference (not downloaded)
    if (effectivePath.startsWith('drive://')) {
      if (kDebugMode) {
        debugPrint(
          '[preview_share] Path is Drive reference (not downloaded): $effectivePath',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.previewSongNotAvailableDownloadFirst,
            ),
          ),
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
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.previewSongFileNotFound,
              ),
            ),
          );
        }
        return;
      }

      // WhatsApp enforces a ~64MB limit for audio messages, but typically allows larger files as "documents".
      // Keep default share here (audio). A separate "Share as ZIP" action is also available.
      final fileSizeBytes = await sourceFile.length();
      if (kDebugMode) {
        debugPrint('[preview_share] sizeBytes=$fileSizeBytes');
      }

      // Get the original filename — prefer stored name, fall back to project name
      String originalFileName =
          widget.project.previewShareFileName ?? path.basename(effectivePath);

      // Ensure the filename has an extension
      if (!originalFileName.contains('.')) {
        final ext = path.extension(effectivePath);
        originalFileName = '$originalFileName$ext';
      }

      // WhatsApp (confirmed via manual testing, including plain OS
      // drag-and-drop of the raw file) rejects WAV/AIFF/FLAC as a direct
      // audio attachment with no error shown to us — convert to a
      // compatible format first so the shared file is actually accepted.
      var fileToShare = sourceFile;
      var shareFileName = originalFileName;
      if (AudioAnalysisService.needsConversionForSharing(effectivePath) &&
          mounted) {
        if (kDebugMode) {
          debugPrint(
            '[preview_share] converting for messaging-app compatibility...',
          );
        }
        final converted = await convertForSharingWithProgress(
          context,
          effectivePath,
        );
        if (converted != null) {
          fileToShare = converted;
          shareFileName = path.basename(converted.path);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.mp3ConversionFailed),
            ),
          );
        }
      }

      if (!mounted) return;
      final shareText = AppLocalizations.of(
        context,
      )!.sharePreviewSongText(widget.project.displayName);

      // On mobile, copy to cache directory with original name for sharing
      if (MobileUtils.isMobile()) {
        final shareFile = await stageFileForMobileShare(
          fileToShare,
          shareFileName,
        );
        if (shareFile == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.failedToSharePreviewSong(shareFileName),
                ),
              ),
            );
          }
          return;
        }
        if (kDebugMode) {
          debugPrint(
            '[preview_share] staged at ${shareFile.path}, invoking share sheet...',
          );
        }

        // Share the file (default behavior)
        final result = await Share.shareXFiles([
          XFile(
            shareFile.path,
            name: shareFileName,
            mimeType: shareMimeTypeForFileName(shareFileName),
          ),
        ], text: shareText);
        if (kDebugMode) {
          debugPrint(
            '[preview_share] Share.shareXFiles returned (user completed/dismissed share sheet)',
          );
          debugPrint(
            '[preview_share] ShareResult: status=${result.status} raw=${result.raw}',
          );
        }
      } else {
        // On other platforms, share the file directly
        if (kDebugMode) {
          debugPrint(
            '[preview_share] non-Android direct share, invoking share sheet...',
          );
        }
        final result = await Share.shareXFiles([
          XFile(fileToShare.path),
        ], text: shareText);
        if (kDebugMode) {
          debugPrint(
            '[preview_share] ShareResult: status=${result.status} raw=${result.raw}',
          );
        }
        // Unpackaged Windows builds have no working share sheet
        // (DataTransferManager needs MSIX) — without this the click does
        // nothing visible at all.
        if (result.status == ShareResultStatus.unavailable && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.shareSheetUnavailable,
              ),
            ),
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
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.failedToSharePreviewSong(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _sharePreviewSongAsZip() async {
    final l10n = AppLocalizations.of(context)!;
    if (!MobileUtils.isMobile()) return;

    final effectivePath = _effectivePreviewPath;
    if (effectivePath == null || effectivePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.previewSongFileNotFound,
            ),
          ),
        );
      }
      return;
    }

    // Skip if it's a Drive file reference (not downloaded)
    if (effectivePath.startsWith('drive://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.previewSongNotAvailableDownloadFirst,
            ),
          ),
        );
      }
      return;
    }

    try {
      final sourceFile = File(effectivePath);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.previewSongFileNotFound,
              ),
            ),
          );
        }
        return;
      }

      // Get the original filename — prefer stored name, fall back to project name
      String originalFileName =
          widget.project.previewShareFileName ?? path.basename(effectivePath);
      if (!originalFileName.contains('.')) {
        final ext = path.extension(effectivePath);
        originalFileName = '$originalFileName$ext';
      }

      // Copy to cache and zip it
      final cacheDir = await getTemporaryDirectory();
      final shareFile = File(path.join(cacheDir.path, originalFileName));
      await sourceFile.copy(shareFile.path);

      final zipBase = path.basenameWithoutExtension(originalFileName);
      var zipPath = path.join(cacheDir.path, '$zipBase.zip');
      var zipFile = File(zipPath);
      if (await zipFile.exists()) {
        zipPath = path.join(
          cacheDir.path,
          '${zipBase}_${DateTime.now().millisecondsSinceEpoch}.zip',
        );
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

      final result = await Share.shareXFiles([
        XFile(
          zipFile.path,
          name: path.basename(zipFile.path),
          mimeType: 'application/zip',
        ),
      ], text: l10n.sharePreviewSongZipText(widget.project.displayName));
      if (kDebugMode) {
        debugPrint(
          '[preview_share_zip] Share.shareXFiles returned (user completed/dismissed share sheet)',
        );
        debugPrint(
          '[preview_share_zip] ShareResult: status=${result.status} raw=${result.raw}',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[preview_share_zip] ERROR: $e');
        debugPrint('$st');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.failedToSharePreviewSongAsZip(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent)
          return KeyEventResult.ignored;
        if (_isTextInputFocused()) return KeyEventResult.ignored;
        final isModified =
            HardwareKeyboard.instance.isControlPressed ||
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
      child: AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        constraints: BoxConstraints(
          minWidth: MobileUtils.isMobile() ? 320 : 780,
          maxWidth: MobileUtils.isMobile() ? double.infinity : 840,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.project.displayName,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_effectivePreviewPath != null &&
                _effectivePreviewPath!.isNotEmpty &&
                !_effectivePreviewPath!.startsWith('drive://')) ...[
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: AppLocalizations.of(context)!.sharePreviewSong,
                onPressed: _sharePreviewSong,
              ),
              if (MobileUtils.isMobile())
                IconButton(
                  icon: const Icon(Icons.archive),
                  tooltip: AppLocalizations.of(context)!.shareAsZip,
                  onPressed: _sharePreviewSongAsZip,
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: DragToShareButton(sourcePath: _effectivePreviewPath!),
                ),
            ],
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: MobileUtils.isMobile() ? double.infinity : 600,
          child: MobileUtils.isMobile()
              ? _buildAndroidPlayerLayout(context)
              : _buildDesktopPlayerLayout(context),
        ),
      ),
    );
  }
}

// ─── Desktop embedded bottom player ──────────────────────────────────────────

/// Smallest the desktop player bar may be dragged to.
const double kDesktopPlayerMinHeight = 100.0;

/// Tallest the desktop player bar may be dragged to, for a window of
/// [windowHeight].
///
/// Proportional rather than a fixed number so a large display can actually
/// give two stereo lanes room, while a short window can never end up with a
/// player that leaves nothing for the project list. The absolute ceiling stops
/// it running away on a very tall monitor.
double desktopPlayerMaxHeight(double windowHeight) =>
    (windowHeight * 0.6).clamp(kDesktopPlayerMinHeight + 20.0, 720.0);

class _DesktopPlayerBar extends ConsumerStatefulWidget {
  final DesktopPlayerRequest request;
  const _DesktopPlayerBar({super.key, required this.request});

  @override
  ConsumerState<_DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends ConsumerState<_DesktopPlayerBar> {
  late AudioPlayer _player;
  late DesktopIsPlayingNotifier _isPlayingNotifier;
  late DesktopPlayerPositionNotifier _positionNotifier;
  late DesktopPlayerDurationNotifier _durationNotifier;
  bool _isPlaying = false;
  bool _playbackEnded = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _preMuteVolume = 1.0;
  bool _isMono = false;
  bool _isGeneratingMono = false;
  String? _monoFilePath;
  AudioFileInfo? _fileInfo;
  WaveformPeaks? _peaks;
  double _barHeight = 200.0;
  final FocusNode _focusNode = FocusNode();

  static const _kBarHeightKey = 'player_bar_height';

  String get _activePath => _isMono && _monoFilePath != null
      ? _monoFilePath!
      : widget.request.resolvedPath;

  bool _supportsMonoMix() {
    final ext = widget.request.resolvedPath.toLowerCase().split('.').last;
    if (ext == 'wav') return true;
    if (Platform.isMacOS || Platform.isIOS) {
      return const {'mp3', 'flac', 'aif', 'aiff', 'aac', 'm4a'}.contains(ext);
    }
    return const {
      'mp3',
      'flac',
      'aif',
      'aiff',
      'ogg',
      'aac',
      'm4a',
    }.contains(ext);
  }

  Future<void> _loadBarHeight() async {
    final box = await Hive.openBox<String>('app_settings');
    final saved = box.get(_kBarHeightKey);
    if (saved != null && mounted) {
      setState(() => _barHeight = double.tryParse(saved) ?? 200.0);
    }
  }

  Future<void> _saveBarHeight() async {
    final box = await Hive.openBox<String>('app_settings');
    await box.put(_kBarHeightKey, _barHeight.toString());
  }

  bool _handleKeyboard(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    // Never steal keys from text inputs.
    if (_isTextInputFocused()) return false;

    final modified =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return true;
    }
    // Arrow keys only when the player bar has focus — avoids conflicting with
    // table row navigation when the user has clicked into the projects table.
    if (!_focusNode.hasFocus) return false;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _seek(modified ? -30 : -5);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _seek(modified ? 30 : 5);
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _isPlayingNotifier = ref.read(desktopIsPlayingProvider.notifier);
    _positionNotifier = ref.read(desktopPlayerPositionProvider.notifier);
    _durationNotifier = ref.read(desktopPlayerDurationProvider.notifier);
    _loadBarHeight();
    HardwareKeyboard.instance.addHandler(_handleKeyboard);
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      final playing = s == PlayerState.playing;
      setState(() => _isPlaying = playing);
      _isPlayingNotifier.set(playing);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
      _durationNotifier.set(d);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
      _positionNotifier.set(p);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _playbackEnded = true;
      });
      _isPlayingNotifier.set(false);
      _positionNotifier.set(Duration.zero);
      if (widget.request.isQueuedPlayback) {
        ref.read(desktopPlayerCompletedProvider.notifier).increment();
      }
    });
    _player.play(
      DeviceFileSource(widget.request.resolvedPath),
      // Non-null when the track was opened at a project marker rather
      // than from the top.
      position: widget.request.startAt,
    );
    _loadBackgroundData();
  }

  @override
  void didUpdateWidget(_DesktopPlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.resolvedPath != widget.request.resolvedPath ||
        oldWidget.request.generation != widget.request.generation) {
      _player.stop();
      // Defer provider mutation — didUpdateWidget is called during the build
      // phase and Riverpod forbids provider writes at that point.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _isPlayingNotifier.set(false);
        _positionNotifier.set(Duration.zero);
        _durationNotifier.set(Duration.zero);
      });
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
      });
      _player.play(
        DeviceFileSource(widget.request.resolvedPath),
        position: widget.request.startAt,
      );
      _loadBackgroundData();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyboard);
    _focusNode.dispose();
    _player.stop();
    _player.dispose();
    // dispose() can run during widget-tree finalization (e.g. this bar
    // getting torn down while switching preview songs), when Riverpod
    // forbids synchronous provider writes — same reason didUpdateWidget
    // above defers its own notifier writes, just via a Future here since
    // there's no guarantee another frame gets scheduled after disposal.
    Future(() => _isPlayingNotifier.set(false));
    super.dispose();
  }

  void _loadBackgroundData() {
    final filePath = widget.request.resolvedPath;

    // Waveform peaks — memory → disk → extraction
    ref
        .read(waveformCacheProvider.notifier)
        .getOrExtract(
          filePath,
          onStale: () {
            if (!mounted) return;
            setState(() => _peaks = null);
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.previewAudioChangedRefreshing,
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        )
        .then((peaks) {
          if (!mounted || peaks == null) return;
          setState(() => _peaks = peaks);
        });

    // File info
    AudioAnalysisService.getFileInfo(filePath).then((info) {
      if (mounted && info != null) setState(() => _fileInfo = info);
    });

    // Pre-generate mono in background
    if (_supportsMonoMix()) _prepareMonoFile(filePath);
  }

  Future<void> _prepareMonoFile(String filePath) async {
    final tmpDir = await getTemporaryDirectory();
    final outPath = '${tmpDir.path}/mono_bar_${widget.request.project.id}.wav';
    final ok = await AudioAnalysisService.writeMonoWavFile(filePath, outPath);
    if (!mounted) return;
    if (ok) {
      setState(() => _monoFilePath = outPath);
    } else {
      final channels = await AudioAnalysisService.getChannelCount(filePath);
      if (mounted && channels == 1) setState(() => _monoFilePath = filePath);
    }
  }

  Future<void> _toggleMono() async {
    if (!_supportsMonoMix()) return;
    final newMono = !_isMono;
    if (newMono && _monoFilePath == null) {
      setState(() => _isGeneratingMono = true);
      final tmpDir = await getTemporaryDirectory();
      final outPath =
          '${tmpDir.path}/mono_bar_${widget.request.project.id}.wav';
      final ok = await AudioAnalysisService.writeMonoWavFile(
        widget.request.resolvedPath,
        outPath,
      );
      if (!mounted) return;
      if (!ok) {
        final ch = await AudioAnalysisService.getChannelCount(
          widget.request.resolvedPath,
        );
        if (!mounted) return;
        if (ch == 1) {
          setState(() {
            _monoFilePath = widget.request.resolvedPath;
            _isGeneratingMono = false;
          });
        } else {
          setState(() => _isGeneratingMono = false);
          return;
        }
      } else {
        setState(() {
          _monoFilePath = outPath;
          _isGeneratingMono = false;
        });
      }
    }
    final wasPlaying = _isPlaying;
    final savedPos = _position;
    setState(() => _isMono = newMono);
    try {
      if (wasPlaying) {
        await _player.play(DeviceFileSource(_activePath), position: savedPos);
      } else {
        await _player.setSource(DeviceFileSource(_activePath));
        if (savedPos > Duration.zero) await _player.seek(savedPos);
      }
    } catch (_) {}
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_playbackEnded) {
        setState(() => _playbackEnded = false);
        await _player.stop();
        await _player.play(
          DeviceFileSource(_activePath),
          position: _position > Duration.zero ? _position : null,
        );
      } else if (_position == Duration.zero || _position >= _duration) {
        await _player.play(DeviceFileSource(_activePath));
      } else {
        await _player.resume();
      }
    }
  }

  Future<void> _seek(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = target.isNegative
        ? Duration.zero
        : (_duration > Duration.zero && target > _duration
              ? _duration
              : target);
    await _player.seek(clamped);
  }

  /// Jump to an absolute position — project markers, whose positions come from
  /// the DAW timeline and can therefore sit past the end of a preview song
  /// that only covers part of the session.
  Future<void> _seekTo(Duration position) async {
    final clamped = position.isNegative
        ? Duration.zero
        : (_duration > Duration.zero && position > _duration
              ? _duration
              : position);
    await _player.seek(clamped);
    setState(() => _position = clamped);
    _positionNotifier.set(clamped);
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '${two(h)}:$m:$s' : '$m:$s';
  }

  Future<void> _addTodoAtTimestamp() async {
    final l10n = AppLocalizations.of(context)!;
    final position = _position;
    final timestamp = formatPlaybackTimestamp(position);
    final controller = TextEditingController();

    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.addTodoAtTimestamp(timestamp)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.todoText,
            hintText: l10n.enterTodoText,
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();

    final noteText = note?.trim();
    if (noteText == null || noteText.isEmpty) return;
    if (!mounted) return;

    final newTodo = TodoItem(
      id: const Uuid().v4(),
      text: buildTimestampedTodoText(position, noteText),
      completed: false,
      createdAt: DateTime.now(),
    );

    final repo = await ref.read(repositoryProvider.future);
    final allProjects = ref.read(allProjectsStreamProvider).value ?? [];
    final project = allProjects.firstWhere(
      (p) => p.id == widget.request.project.id,
      orElse: () => widget.request.project,
    );
    await repo.updateProject(
      project.copyWith(todos: [...project.todos, newTodo]),
    );

    if (!mounted) return;
    ref.invalidate(allProjectsStreamProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.todoAddedAtTimestamp(timestamp))),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(desktopPlayerProvider, (prev, next) {
      if (next == null) _player.stop();
    });
    // External toggle request (e.g. clicking the play button on this same
    // project's row again while it's already loaded here).
    ref.listen(desktopPlayerToggleRequestProvider, (prev, next) {
      if (prev != null && prev != next) _togglePlayPause();
    });
    // Jump to a project marker clicked somewhere else in the app, on the
    // track this bar already has loaded.
    ref.listen(desktopPlayerSeekRequestProvider, (prev, next) {
      if (next != null && prev?.generation != next.generation) {
        _seekTo(next.position);
      }
    });
    final queueNav = ref.watch(queueNavigationProvider);
    final isQueued = widget.request.isQueuedPlayback;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final project = widget.request.project;
    final isAutoDetected =
        (project.previewSongPath?.isEmpty ?? true) &&
        project.previewSongAutoPath == widget.request.resolvedPath;

    final ext = widget.request.resolvedPath.toLowerCase().split('.').last;
    final formatLabel = switch (ext) {
      'wav' => 'WAV',
      'mp3' => 'MP3',
      'flac' => 'FLAC',
      'aif' || 'aiff' => 'AIFF',
      'ogg' => 'OGG',
      'aac' => 'AAC',
      'm4a' => 'M4A',
      _ => ext.toUpperCase(),
    };
    final infoParts = <String>[];
    if (_fileInfo != null) {
      final sr = _fileInfo!.sampleRate;
      infoParts.add(
        sr % 1000 == 0
            ? '${sr ~/ 1000}kHz'
            : '${(sr / 1000).toStringAsFixed(1)}kHz',
      );
      if (_fileInfo!.bitDepth != null) {
        infoParts.add('${_fileInfo!.bitDepth}-bit');
      } else if (_fileInfo!.bitrateKbps != null) {
        infoParts.add('${_fileInfo!.bitrateKbps}kbps');
      }
      infoParts.add(
        _fileInfo!.channels == 1
            ? 'Mono'
            : _fileInfo!.channels == 2
            ? 'Stereo'
            : '${_fileInfo!.channels}ch',
      );
    }
    infoParts.add(formatLabel);

    const iconConstraints = BoxConstraints(minWidth: 32, minHeight: 32);
    const iconPad = EdgeInsets.zero;

    final modKey = Platform.isMacOS ? '⌘' : 'Ctrl';

    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _focusNode.requestFocus(),
        child: Material(
          elevation: 8,
          color: theme.cardColor,
          child: SizedBox(
            height: _barHeight.clamp(
              kDesktopPlayerMinHeight,
              desktopPlayerMaxHeight(MediaQuery.sizeOf(context).height),
            ),
            child: Column(
              children: [
                // Resize grip — drag upward to make the player taller. The
                // ceiling scales with the window rather than being a fixed
                // 300 px: two stereo lanes plus the transport chrome need real
                // height before each lane is worth reading.
                MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _barHeight = (_barHeight - details.delta.dy).clamp(
                          kDesktopPlayerMinHeight,
                          desktopPlayerMaxHeight(
                              MediaQuery.sizeOf(context).height),
                        );
                      });
                    },
                    onVerticalDragEnd: (_) => _saveBarHeight(),
                    child: SizedBox(
                      height: 8,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outline.withValues(alpha: 0.18),
                ),
                // ── Row 1: transport · volume · [centered name] · time · mono · info · close ─
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                  child: Row(
                    children: [
                      // Transport controls
                      if (isQueued)
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 20,
                          padding: iconPad,
                          constraints: iconConstraints,
                          tooltip: l10n.playerPreviousTrack,
                          onPressed: queueNav.playPrev,
                        ),
                      Tooltip(
                        message: '−5s  (←)  •  $modKey+← −30s',
                        child: IconButton(
                          icon: const Icon(Icons.replay_5),
                          iconSize: 20,
                          padding: iconPad,
                          constraints: iconConstraints,
                          onPressed: () => _seek(-5),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                        ),
                        iconSize: 34,
                        color: cs.primary,
                        padding: iconPad,
                        constraints: const BoxConstraints(
                          minWidth: 38,
                          minHeight: 38,
                        ),
                        tooltip: '${l10n.playPauseTooltip}  (Space)',
                        onPressed: _togglePlayPause,
                      ),
                      Tooltip(
                        message: '+5s  (→)  •  $modKey+→ +30s',
                        child: IconButton(
                          icon: const Icon(Icons.forward_5),
                          iconSize: 20,
                          padding: iconPad,
                          constraints: iconConstraints,
                          onPressed: () => _seek(5),
                        ),
                      ),
                      if (isQueued)
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          iconSize: 20,
                          padding: iconPad,
                          constraints: iconConstraints,
                          tooltip: l10n.playerNextTrack,
                          onPressed: queueNav.playNext,
                        ),
                      // Volume (immediately after transport)
                      IconButton(
                        icon: Icon(
                          _volume == 0
                              ? Icons.volume_off
                              : (_volume < 0.5
                                    ? Icons.volume_down
                                    : Icons.volume_up),
                        ),
                        iconSize: 18,
                        color: cs.onSurface.withValues(alpha: 0.6),
                        padding: iconPad,
                        constraints: iconConstraints,
                        tooltip: _volume == 0 ? 'Unmute' : 'Mute',
                        onPressed: () {
                          if (_volume > 0) {
                            _preMuteVolume = _volume;
                            setState(() => _volume = 0);
                          } else {
                            setState(
                              () => _volume = _preMuteVolume > 0
                                  ? _preMuteVolume
                                  : 1.0,
                            );
                          }
                          _player.setVolume(_volume);
                        },
                      ),
                      SizedBox(
                        width: 135,
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 1,
                          onChanged: (v) {
                            setState(() => _volume = v);
                            if (v > 0) _preMuteVolume = v;
                            _player.setVolume(v);
                          },
                        ),
                      ),
                      // Centered track name + filename
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isAutoDetected) ...[
                                    const Icon(
                                      Icons.folder_open,
                                      size: 11,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                  Flexible(
                                    child: Text(
                                      project.displayName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                path.basename(widget.request.resolvedPath),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Time display (fixed-width to prevent jitter)
                      SizedBox(
                        width: 92,
                        child: Text(
                          '${_fmt(_position)} / ${_fmt(_duration)}',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mono toggle
                      if (_supportsMonoMix())
                        Tooltip(
                          message: 'Toggle mono playback',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: _isGeneratingMono
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      )
                                    : Checkbox(
                                        value: _isMono,
                                        onChanged: (_) => _toggleMono(),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        activeColor: Colors.red,
                                      ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _isGeneratingMono ? null : _toggleMono,
                                child: Text(
                                  AppLocalizations.of(context)!.monoLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _isMono ? Colors.red : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      // File info
                      Text(
                        infoParts.join(' · '),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Session bookmark (only when session mode is on)
                      Consumer(
                        builder: (context, ref, _) {
                          final sessionMode = ref.watch(sessionModeProvider);
                          if (!sessionMode) return const SizedBox.shrink();
                          final activeProject = ref.watch(
                            activeProjectProvider,
                          );
                          final isSubscribed = activeProject?.id == project.id;
                          return IconButton(
                            icon: Icon(
                              isSubscribed
                                  ? Icons.bookmark
                                  : Icons.bookmark_add_outlined,
                            ),
                            iconSize: 18,
                            padding: iconPad,
                            constraints: iconConstraints,
                            tooltip: isSubscribed
                                ? l10n.endSession
                                : l10n.startSession,
                            color: isSubscribed ? Colors.green.shade400 : null,
                            onPressed: () {
                              if (isSubscribed) {
                                confirmEndSession(context, ref);
                              } else {
                                confirmStartSession(context, ref, project);
                              }
                            },
                          );
                        },
                      ),
                      // View Details
                      IconButton(
                        icon: const Icon(Icons.assignment),
                        iconSize: 18,
                        padding: iconPad,
                        constraints: iconConstraints,
                        tooltip: l10n.projectDetails,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectDetailPage(projectId: project.id),
                          ),
                        ),
                      ),
                      // Add todo at current timestamp
                      IconButton(
                        icon: const Icon(Icons.add_task),
                        iconSize: 18,
                        padding: iconPad,
                        constraints: iconConstraints,
                        tooltip: l10n.addTodoAtTimestamp(_fmt(_position)),
                        onPressed: _addTodoAtTimestamp,
                      ),
                      // Open Folder
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        iconSize: 18,
                        padding: iconPad,
                        constraints: iconConstraints,
                        tooltip: l10n.openFolder,
                        onPressed: () async {
                          final folderPath =
                              ScannerService.projectContainingFolder(
                            project.filePath,
                          );
                          if (Directory(folderPath).existsSync()) {
                            await FileLauncher.openFolder(folderPath);
                          }
                        },
                      ),
                      // Close
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 18,
                        padding: iconPad,
                        constraints: iconConstraints,
                        tooltip: l10n.close,
                        onPressed: () =>
                            ref.read(desktopPlayerProvider.notifier).close(),
                      ),
                    ],
                  ),
                ),
                // ── Row 2: waveform (full width) ──────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                    child: WaveformWidget(
                      peaks: _peaks,
                      progress: progress,
                      height: null,
                      onSeek: (p) {
                        _focusNode.requestFocus();
                        if (_duration > Duration.zero) {
                          final target = Duration(
                            milliseconds: (p * _duration.inMilliseconds)
                                .round(),
                          );
                          setState(() => _position = target);
                          _positionNotifier.set(target);
                          _player.seek(target);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Mobile-friendly projects list widget for Android
class _MobileProjectsList extends ConsumerStatefulWidget {
  final List<MusicProject> projects;
  final DateFormat dateFormat;
  final Function(List<MusicProject>) onCreateRelease;
  final Function(List<MusicProject>) onStackProjects;
  final Function(List<String>) onHideProjects;
  final Function(List<String>) onUnhideProjects;
  final bool showHidden;
  final Future<void> Function()? onRefresh;

  const _MobileProjectsList({
    required this.projects,
    required this.dateFormat,
    required this.onCreateRelease,
    required this.onStackProjects,
    required this.onHideProjects,
    required this.onUnhideProjects,
    required this.showHidden,
    this.onRefresh,
  });

  @override
  ConsumerState<_MobileProjectsList> createState() =>
      _MobileProjectsListState();
}

class _MobileProjectsListState extends ConsumerState<_MobileProjectsList> {
  final Set<String> _selectedProjectIds = {};
  bool _isSelectionMode = false;
  ProjectSortField _sortField = ProjectSortField.lastModified;

  @override
  void didUpdateWidget(_MobileProjectsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Same reconcile as the desktop table: a selected row can be stacked,
    // hidden or deleted out of the list, and its id has to go with it or the
    // action bar counts rows that are nowhere on screen. Local state here, so
    // no deferral needed.
    if (identical(oldWidget.projects, widget.projects) ||
        _selectedProjectIds.isEmpty) {
      return;
    }
    final visible = widget.projects.map((p) => p.id).toSet();
    if (_selectedProjectIds.every(visible.contains)) return;
    setState(() {
      _selectedProjectIds.removeWhere((id) => !visible.contains(id));
      if (_selectedProjectIds.isEmpty) _isSelectionMode = false;
    });
  }

  /// Shared with the desktop card grid so "sort by phase" means the same
  /// thing in both — see `lib/utils/project_sort.dart`.
  List<MusicProject> _sorted(List<MusicProject> projects) => sortProjects(
    projects,
    _sortField,
    descending: defaultDescendingFor(_sortField),
  );

  void _toggleProjectSelection(String projectId) {
    setState(() {
      if (_selectedProjectIds.contains(projectId)) {
        _selectedProjectIds.remove(projectId);
        // Exit selection mode if no items are selected
        if (_selectedProjectIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProjectIds.add(projectId);
        // Enter selection mode when first item is selected
        if (!_isSelectionMode) {
          _isSelectionMode = true;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProjectIds.clear();
      _isSelectionMode = false;
    });
  }

  void _enterSelectionMode(String projectId) {
    setState(() {
      _isSelectionMode = true;
      _selectedProjectIds.add(projectId);
    });
  }

  /// Long-press menu for a row in the mobile list — the phone's answer to the
  /// desktop grid's right-click menu.
  ///
  /// Long-press used to go straight into multi-select; that's still reachable
  /// from here as one entry among several, which is what makes room for Share
  /// (and for whatever per-project action comes next) without spending the
  /// row's only remaining gesture on it.
  Future<void> _showMobileProjectActions(MusicProject project) async {
    final l10n = AppLocalizations.of(context)!;
    final hasPreview = effectivePreviewPathFor(project)?.isNotEmpty == true;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                project.displayName,
                style: Theme.of(sheetContext).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(project.status),
            ),
            const Divider(height: 1),
            if (hasPreview) ...[
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: Text(l10n.playPreview),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _playPreviewSong(project);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.sharePreviewSong),
                onTap: () {
                  Navigator.pop(sheetContext);
                  shareProjectPreview(context, project);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.assignment),
              title: Text(l10n.tooltipViewDetails),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailPage(projectId: project.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: Text(l10n.selectProjects),
              onTap: () {
                Navigator.pop(sheetContext);
                _enterSelectionMode(project.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playPreviewSong(MusicProject project) =>
      playProjectPreview(context, ref, project);

  String _getStatusDisplayName(String status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'Idea':
        return l10n.projectPhaseIdea;
      case 'Arranging':
        return l10n.projectPhaseArranging;
      case 'Mixing':
        return l10n.projectPhaseMixing;
      case 'Mastering':
        return l10n.projectPhaseMastering;
      case 'Finished':
        return l10n.projectPhaseFinished;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) => resolvePhaseColor(
    status,
    ref.read(phaseColorsProvider),
    ref.read(customPhasesProvider),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(phaseColorsProvider); // rebuild when colors change

    if (widget.projects.isEmpty) {
      final allProjectsAsync = ref.watch(allProjectsStreamProvider);
      final totalProjects = allProjectsAsync.value?.length ?? 0;
      final hasProjectsButFiltered = totalProjects > 0;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: hasProjectsButFiltered
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noResultsForFilter,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noResultsForFilterHint,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_sync,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.firstTimeSyncTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.firstTimeSyncMessage,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GoogleDriveSyncPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(l10n.syncWithGoogleDrive),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    final sortedProjects = _sorted(widget.projects);

    return Column(
      children: [
        // Sort bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.sort,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              DropdownButton<ProjectSortField>(
                value: _sortField,
                underline: const SizedBox.shrink(),
                isDense: true,
                style: Theme.of(context).textTheme.bodySmall,
                items: [
                  DropdownMenuItem(
                    value: ProjectSortField.lastModified,
                    child: Text(l10n.sortByLastModified),
                  ),
                  DropdownMenuItem(
                    value: ProjectSortField.name,
                    child: Text(l10n.sortByName),
                  ),
                  DropdownMenuItem(
                    value: ProjectSortField.phase,
                    child: Text(l10n.sortByPhase),
                  ),
                  DropdownMenuItem(
                    value: ProjectSortField.createdAt,
                    child: Text(l10n.sortByCreatedAt),
                  ),
                  DropdownMenuItem(
                    value: ProjectSortField.bpm,
                    child: Text(l10n.sortByBpm),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _sortField = v);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            child: ListView.builder(
              itemCount: sortedProjects.length,
              itemBuilder: (context, index) {
                final project = sortedProjects[index];
                final isSelected = _selectedProjectIds.contains(project.id);
                final searchQuery = ref.read(projectsSearchProvider);
                final matchedOutsideName =
                    searchQuery.trim().isNotEmpty &&
                    !fuzzyMatchAll(project.displayName, searchQuery);
                final isNotesMatch =
                    matchedOutsideName &&
                    project.notes != null &&
                    fuzzyMatchAll(project.notes!, searchQuery);
                final isProjectNotesMatch =
                    matchedOutsideName &&
                    !isNotesMatch &&
                    project.projectNotes != null &&
                    fuzzyMatchAll(project.projectNotes!, searchQuery);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) =>
                                _toggleProjectSelection(project.id),
                          )
                        // Only when the user gave this project a look of its
                        // own — an undecorated song keeps the tile it has
                        // always had, with no leading gutter (#110).
                        : projectHasVisualIdentity(project)
                        ? ProjectCoverAvatar(project: project, size: 40)
                        : null,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (ref
                            .watch(recentlyDiscoveredProjectsProvider)
                            .contains(project.id)) ...[
                          const SizedBox(width: 6),
                          _NewProjectBadge(
                            onDismiss: () => ref
                                .read(
                                  recentlyDiscoveredProjectsProvider.notifier,
                                )
                                .dismiss(project.id),
                          ),
                        ],
                        if (isNotesMatch)
                          Tooltip(
                            message: AppLocalizations.of(
                              context,
                            )!.matchedInDescription,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.notes,
                                size: 14,
                                color: Colors.amber.shade600,
                              ),
                            ),
                          ),
                        if (isProjectNotesMatch)
                          Tooltip(
                            message: AppLocalizations.of(
                              context,
                            )!.matchedInProjectNotes,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: Colors.amber.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        // Phase and DAW on the same line
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n.phase}: ${_getStatusDisplayName(project.status, context)}',
                                style: TextStyle(
                                  color: _getStatusColor(project.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (project.dawType != null) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.dawInfoLabel(
                                    '${project.dawType}${project.dawVersion != null ? ' ${project.dawVersion}' : ''}',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // BPM and Key on the same line
                        if (project.bpm != null || project.musicalKey != null)
                          Row(
                            children: [
                              if (project.bpm != null)
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.bpmInfoLabel('${project.bpm}'),
                                  ),
                                ),
                              if (project.bpm != null &&
                                  project.musicalKey != null)
                                const SizedBox(width: 16),
                              if (project.musicalKey != null)
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.keyInfoLabel(project.musicalKey!),
                                  ),
                                ),
                            ],
                          ),
                        // Deadline display on mobile
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Modified: ${widget.dateFormat.format(project.lastModifiedAt)}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (project.deadline != null &&
                                !ref
                                    .watch(finishedPhaseProvider)
                                    .contains(project.status))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: project.daysUntilDeadline! < 0
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : project.daysUntilDeadline! == 0
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : project.daysUntilDeadline! <= 7
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: project.daysUntilDeadline! < 0
                                        ? Colors.red.withValues(alpha: 0.3)
                                        : project.daysUntilDeadline! == 0
                                        ? Colors.red.withValues(alpha: 0.3)
                                        : project.daysUntilDeadline! <= 7
                                        ? Colors.orange.withValues(alpha: 0.3)
                                        : Colors.blue.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      project.daysUntilDeadline! < 0
                                          ? Icons.warning
                                          : project.daysUntilDeadline! == 0
                                          ? Icons.today
                                          : Icons.schedule,
                                      size: 12,
                                      color: project.daysUntilDeadline! < 0
                                          ? Colors.red
                                          : project.daysUntilDeadline! == 0
                                          ? Colors.red
                                          : project.daysUntilDeadline! <= 7
                                          ? Colors.orange
                                          : Colors.blue,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      project.daysUntilDeadline! < 0
                                          ? AppLocalizations.of(
                                              context,
                                            )!.daysLate(
                                              project.daysUntilDeadline!.abs(),
                                            )
                                          : project.daysUntilDeadline! == 0
                                          ? AppLocalizations.of(context)!.today
                                          : AppLocalizations.of(
                                              context,
                                            )!.daysLeft(
                                              project.daysUntilDeadline!,
                                            ),
                                      style: TextStyle(
                                        color: project.daysUntilDeadline! < 0
                                            ? Colors.red
                                            : project.daysUntilDeadline! == 0
                                            ? Colors.red
                                            : project.daysUntilDeadline! <= 7
                                            ? Colors.orange
                                            : Colors.blue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: _isSelectionMode
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.play_arrow),
                            tooltip:
                                project.previewSongAutoPath != null &&
                                    project.previewSongPath?.isNotEmpty != true
                                ? '${AppLocalizations.of(context)!.playPreview}\n⚡ ${AppLocalizations.of(context)!.autoDetected}: ${path.basename(project.previewSongAutoPath!)}'
                                : AppLocalizations.of(context)!.playPreview,
                            onPressed: () => _playPreviewSong(project),
                            color: project.previewSongPath?.isNotEmpty == true
                                ? Colors.green
                                : project.previewSongAutoPath != null
                                ? Colors.amber
                                : Colors.grey,
                          ),
                    onTap: () {
                      if (_isSelectionMode) {
                        // In selection mode, tap toggles selection
                        _toggleProjectSelection(project.id);
                      } else {
                        // Normal mode, navigate to project detail
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectDetailPage(projectId: project.id),
                          ),
                        );
                      }
                    },
                    onLongPress: () {
                      // Already selecting: keep long-press as a plain toggle,
                      // so building a selection stays one gesture per row
                      // instead of a sheet each time.
                      if (_isSelectionMode) {
                        _toggleProjectSelection(project.id);
                      } else {
                        _showMobileProjectActions(project);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
        // Selection action bar
        if (_selectedProjectIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  l10n.projectsSelected(
                    _selectedProjectIds.length,
                    _selectedProjectIds.length == 1 ? '' : 's',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.album),
                    label: Text(l10n.createRelease),
                    onPressed: () {
                      final selectedProjects = widget.projects
                          .where((p) => _selectedProjectIds.contains(p.id))
                          .toList();
                      widget.onCreateRelease(selectedProjects);
                      _clearSelection();
                    },
                  ),
                ),
                // Icon-only here: this bar is already three buttons wide on a
                // phone, and a fourth label would wrap them all.
                Builder(
                  builder: (context) {
                    final stackable = widget.projects
                        .where(
                          (p) =>
                              _selectedProjectIds.contains(p.id) &&
                              !p.isVirtual &&
                              !p.isStackMember,
                        )
                        .toList();
                    if (stackable.length < 2) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: IconButton.filled(
                        icon: const Icon(Icons.layers),
                        tooltip: l10n.stackAsVersions,
                        onPressed: () => widget.onStackProjects(stackable),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Check if selected projects are hidden or visible
                Builder(
                  key: ValueKey(
                    '${_selectedProjectIds.length}_${widget.projects.where((p) => _selectedProjectIds.contains(p.id)).map((p) => '${p.id}_${p.hidden}').join(',')}',
                  ),
                  builder: (context) {
                    // Check the state of selected projects
                    final selectedProjects = widget.projects
                        .where((p) => _selectedProjectIds.contains(p.id))
                        .toList();
                    final allHidden =
                        selectedProjects.isNotEmpty &&
                        selectedProjects.every((p) => p.hidden);
                    final allVisible =
                        selectedProjects.isNotEmpty &&
                        selectedProjects.every((p) => !p.hidden);

                    // Show Unhide button if all selected are hidden, Hide button if all are visible
                    // If mixed, show both
                    if (allHidden) {
                      return IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: l10n.unhide,
                        onPressed: () {
                          widget.onUnhideProjects(_selectedProjectIds.toList());
                          _clearSelection();
                        },
                      );
                    } else if (allVisible) {
                      return IconButton(
                        icon: const Icon(Icons.visibility_off),
                        tooltip: l10n.hide,
                        onPressed: () {
                          widget.onHideProjects(_selectedProjectIds.toList());
                          _clearSelection();
                        },
                      );
                    } else {
                      // Mixed selection - show both buttons
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: l10n.unhide,
                            onPressed: () {
                              widget.onUnhideProjects(
                                _selectedProjectIds.toList(),
                              );
                              _clearSelection();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility_off),
                            tooltip: l10n.hide,
                            onPressed: () {
                              widget.onHideProjects(
                                _selectedProjectIds.toList(),
                              );
                              _clearSelection();
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.clearSelection,
                  onPressed: _clearSelection,
                ),
              ],
            ),
          ),
      ],
    );
  }
}


/// Shows a confirmation dialog before starting a session on a project.
/// If another session is already active, offers to switch instead.
Future<void> _launchSuggestionProject(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  await launchProjectInDaw(context, ref, project);
}

// ── Session idle suggestions ────────────────────────────────────────────────

enum SuggestionType {
  newlyCreated,
  deadlineOverdue,
  deadlineSoon,
  lastWorked,
  recentlyModified,
}

class Suggestion {
  final SuggestionType type;
  final MusicProject project;
  const Suggestion({required this.type, required this.project});
}

// Anchor key: zero-height SizedBox in the column at the exact toolbar bottom.
// _SessionIdleSuggestionsState reads this to position the overlay correctly.
final _suggestionsPanelAnchorKey = GlobalKey();

List<Suggestion> buildIdleSuggestions(
  List<MusicProject> all,
  Set<String> dismissed,
  Set<String> finishedPhases, [
  Set<String> recentlyCreated = const {},
]) {
  final visible = all.where((p) => !p.hidden).toList();
  final result = <Suggestion>[];
  final seen = <String>{};

  void add(SuggestionType type, MusicProject p) {
    if (dismissed.contains(p.id)) return;
    if (seen.add(p.id)) result.add(Suggestion(type: type, project: p));
  }

  // Freshly created (e.g. from a template) — the newest, most relevant
  // signal, so it's checked first and wins the dedup over any other
  // category (deadline/last-worked/recently-modified) the same project
  // might also match.
  final freshlyCreated =
      visible.where((p) => recentlyCreated.contains(p.id)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final p in freshlyCreated.take(2)) {
    add(SuggestionType.newlyCreated, p);
  }

  // Overdue & due-today, non-finished (most overdue first)
  final urgentDeadlines =
      visible
          .where(
            (p) =>
                !finishedPhases.contains(p.status) &&
                p.daysUntilDeadline != null &&
                p.daysUntilDeadline! <= 0,
          )
          .toList()
        ..sort((a, b) => a.daysUntilDeadline!.compareTo(b.daysUntilDeadline!));
  for (final p in urgentDeadlines.take(3)) {
    add(SuggestionType.deadlineOverdue, p);
  }

  // Due soon (1–7 days), non-finished
  final dueSoon =
      visible
          .where(
            (p) =>
                !finishedPhases.contains(p.status) &&
                p.daysUntilDeadline != null &&
                p.daysUntilDeadline! > 0 &&
                p.daysUntilDeadline! <= 7,
          )
          .toList()
        ..sort((a, b) => a.daysUntilDeadline!.compareTo(b.daysUntilDeadline!));
  for (final p in dueSoon.take(2)) {
    add(SuggestionType.deadlineSoon, p);
  }

  // Last worked (project with the most recently ended session)
  MusicProject? lastWorked;
  DateTime? latestEnd;
  for (final p in visible) {
    if (p.sessions.isEmpty) continue;
    final end = p.sessions.last.endedAt;
    if (latestEnd == null || end.isAfter(latestEnd)) {
      latestEnd = end;
      lastWorked = p;
    }
  }
  if (lastWorked != null) add(SuggestionType.lastWorked, lastWorked);

  // Most recently modified non-finished (if not already listed)
  final recent =
      visible.where((p) => !finishedPhases.contains(p.status)).toList()
        ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
  if (recent.isNotEmpty) add(SuggestionType.recentlyModified, recent.first);

  return result;
}

(Color, IconData, String) suggestionVisuals(
  Suggestion s,
  ThemeData theme,
  AppLocalizations l10n,
) => switch (s.type) {
  SuggestionType.newlyCreated => (
    Colors.green.shade400,
    Icons.auto_awesome,
    '${l10n.suggestionNewProject}: ${s.project.displayName}',
  ),
  SuggestionType.deadlineOverdue => (
    const Color(0xFFFF6B6B),
    Icons.alarm,
    s.project.daysUntilDeadline! == 0
        ? '${l10n.dueToday}: ${s.project.displayName}'
        : '${l10n.daysLate(-s.project.daysUntilDeadline!)}: ${s.project.displayName}',
  ),
  SuggestionType.deadlineSoon => (
    const Color(0xFFFBBF24),
    Icons.alarm_outlined,
    '${l10n.daysLeft(s.project.daysUntilDeadline!)}: ${s.project.displayName}',
  ),
  SuggestionType.lastWorked => (
    theme.colorScheme.primary,
    Icons.history,
    '${l10n.resume}: ${s.project.displayName}',
  ),
  SuggestionType.recentlyModified => (
    theme.colorScheme.secondary,
    Icons.edit_outlined,
    '${l10n.continueButton}: ${s.project.displayName}',
  ),
};

/// Carousel chip row shown in the toolbar when session mode is on and idle.
/// The expand/collapse button toggles [_SuggestionsPanelBar] via provider.
class _SessionIdleSuggestions extends ConsumerStatefulWidget {
  const _SessionIdleSuggestions();

  @override
  ConsumerState<_SessionIdleSuggestions> createState() =>
      _SessionIdleSuggestionsState();
}

class _SessionIdleSuggestionsState
    extends ConsumerState<_SessionIdleSuggestions> {
  int _index = 0;
  OverlayEntry? _overlayEntry;
  final GlobalKey _toggleKey = GlobalKey();

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _hideOverlay();
    final anchorBox =
        _suggestionsPanelAnchorKey.currentContext?.findRenderObject()
            as RenderBox?;
    final toggleBox =
        _toggleKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchorBox == null || toggleBox == null || !mounted) return;

    final anchorPos = anchorBox.localToGlobal(Offset.zero);
    final togglePos = toggleBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    const popupWidth = 360.0;

    // Right-align popup to the toggle button; clamp within screen bounds.
    double left = (togglePos.dx + toggleBox.size.width - popupWidth).clamp(
      8.0,
      screenWidth - popupWidth - 8.0,
    );

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Transparent barrier — tap anywhere outside to close.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => ref
                  .read(suggestionsPanelExpandedProvider.notifier)
                  .set(false),
            ),
          ),
          Positioned(
            top: anchorPos.dy + 4,
            left: left,
            width: popupWidth,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const _SuggestionsPanelBar(),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _openDetails(MusicProject p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: p.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allProjectsStreamProvider).value ?? [];
    final dismissed = ref.watch(dismissedSuggestionsProvider);
    final panelExpanded = ref.watch(suggestionsPanelExpandedProvider);
    final finishedPhases = ref.watch(finishedPhaseProvider);
    final recentlyCreated = ref.watch(recentlyDiscoveredProjectsProvider);
    final suggestions = buildIdleSuggestions(
      all,
      dismissed,
      finishedPhases,
      recentlyCreated,
    );
    final total = suggestions.length;
    final idx = total > 0 ? _index.clamp(0, total - 1) : 0;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(suggestionsPanelExpandedProvider, (_, next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showOverlay();
        });
      } else {
        _hideOverlay();
      }
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ← prev
        if (total > 1)
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              icon: Icon(
                Icons.chevron_left,
                color: theme.textTheme.bodySmall?.color,
              ),
              onPressed: () =>
                  setState(() => _index = (idx - 1 + total) % total),
            ),
          ),

        // Chip
        if (total > 0)
          _buildChip(
            suggestions[idx],
            theme,
            l10n,
            ref.watch(sessionModeProvider),
          ),

        // → next + counter
        if (total > 1) ...[
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              icon: Icon(
                Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color,
              ),
              onPressed: () => setState(() => _index = (idx + 1) % total),
            ),
          ),
          Text(
            '${idx + 1}/$total',
            style: TextStyle(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        ],

        // Toggle: shows "Suggestions ▾" label only when no chips are showing
        const SizedBox(width: 4),
        InkWell(
          key: _toggleKey,
          borderRadius: BorderRadius.circular(4),
          onTap: () => ref
              .read(suggestionsPanelExpandedProvider.notifier)
              .set(!panelExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (total == 0) ...[
                  Icon(
                    Icons.lightbulb_outline,
                    size: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    l10n.suggestionsLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                Icon(
                  panelExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: panelExpanded
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    Suggestion s,
    ThemeData theme,
    AppLocalizations l10n,
    bool sessionMode,
  ) {
    final (accent, icon, label) = suggestionVisuals(s, theme, l10n);
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.only(left: 8, right: 4, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: sessionMode ? l10n.startSession : l10n.openInDaw,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => sessionMode
                  ? confirmStartSession(context, ref, s.project)
                  : _launchSuggestionProject(context, ref, s.project),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  sessionMode ? Icons.bookmark_add_outlined : Icons.open_in_new,
                  size: 14,
                  color: accent,
                ),
              ),
            ),
          ),
          Tooltip(
            message: l10n.tooltipViewDetails,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openDetails(s.project),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.assignment,
                  size: 12,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay suggestions panel shown when the user expands the toolbar toggle.
/// Rendered inside an [OverlayEntry] by [_SessionIdleSuggestionsState].
class _SuggestionsPanelBar extends ConsumerWidget {
  const _SuggestionsPanelBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allProjectsStreamProvider).value ?? [];
    final dismissed = ref.watch(dismissedSuggestionsProvider);
    final sessionMode = ref.watch(sessionModeProvider);
    final finishedPhases = ref.watch(finishedPhaseProvider);
    final recentlyCreated = ref.watch(recentlyDiscoveredProjectsProvider);
    final suggestions = buildIdleSuggestions(
      all,
      dismissed,
      finishedPhases,
      recentlyCreated,
    );
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      color: theme.cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 4),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 15,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.suggestionsLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.refresh, size: 13),
                  label: Text(
                    l10n.suggestionsRefresh,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () =>
                      ref.read(dismissedSuggestionsProvider.notifier).clear(),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  icon: const Icon(Icons.expand_less, size: 15),
                  onPressed: () => ref
                      .read(suggestionsPanelExpandedProvider.notifier)
                      .set(false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Items / empty state ────────────────────────────────────
          if (suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                l10n.suggestionsEmptyState,
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: suggestions.length,
              separatorBuilder: (_, i) =>
                  const Divider(height: 1, indent: 14, endIndent: 14),
              itemBuilder: (ctx, i) {
                final s = suggestions[i];
                final (accent, icon, label) = suggestionVisuals(s, theme, l10n);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: sessionMode
                            ? l10n.startSession
                            : l10n.openInDaw,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            ref
                                .read(suggestionsPanelExpandedProvider.notifier)
                                .set(false);
                            if (sessionMode) {
                              confirmStartSession(context, ref, s.project);
                            } else {
                              _launchSuggestionProject(context, ref, s.project);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              sessionMode
                                  ? Icons.bookmark_add_outlined
                                  : Icons.open_in_new,
                              size: 18,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: l10n.tooltipViewDetails,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProjectDetailPage(projectId: s.project.id),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.assignment,
                              size: 16,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: l10n.close,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => ref
                              .read(dismissedSuggestionsProvider.notifier)
                              .dismiss(s.project.id),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Compact chip displayed in the toolbar when a project session is active.
/// Shows a pulsing dot, project name, session timer, and quick-action buttons.
class _ActiveProjectChip extends ConsumerStatefulWidget {
  const _ActiveProjectChip();

  @override
  ConsumerState<_ActiveProjectChip> createState() => _ActiveProjectChipState();
}

class _ActiveProjectChipState extends ConsumerState<_ActiveProjectChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static const _dot = Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Text('·', style: TextStyle(color: Color(0x4DFFFFFF), fontSize: 11)),
  );

  String _formatWorkTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final sessionElapsed = ref.watch(workTimerProvider);
    final isPaused = ref.watch(workTimerPausedProvider);

    if (project == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final dawLabel =
        project.dawType ??
        project.fileExtension.replaceFirst('.', '').toUpperCase();
    const green = Color(0xFF22C55E);
    const yellow = Color(0xFFFBBF24);
    final chipColor = isPaused ? yellow : green;

    // Always pulse — color (green vs yellow) does the state communication.
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: chipColor.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pulsing dot — green when active, yellow when paused; always animates.
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final v = _anim.value;
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.35 + 0.65 * v),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: chipColor.withValues(alpha: 0.7 * v),
                      blurRadius: 5 + 5 * v,
                      spreadRadius: 0.5 + 2 * v,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // Two-line content block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Line 1 — project name (tooltip shows full name when truncated)
              Tooltip(
                message: project.displayName,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Text(
                    project.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Line 2 — DAW version, BPM, key, Camelot, total work, session timer
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // DAW name + version
                  Text(
                    project.dawVersion != null
                        ? '$dawLabel ${project.dawVersion}'
                        : dawLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                  // BPM
                  if (project.bpm != null) ...[
                    _dot,
                    Icon(
                      Icons.speed,
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${project.bpm! % 1 == 0 ? project.bpm!.toInt() : project.bpm!.toStringAsFixed(1)} BPM',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  // Musical key
                  if (project.musicalKey != null &&
                      project.musicalKey!.isNotEmpty) ...[
                    _dot,
                    Icon(
                      Icons.music_note,
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      project.musicalKey!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  // Camelot code badge
                  if (project.camelotCode != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        project.camelotCode!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  // Total accumulated work time
                  if (project.totalWorkSeconds > 0) ...[
                    _dot,
                    Icon(
                      Icons.history,
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 2),
                    SizedBox(
                      width: 56,
                      child: Text(
                        _formatWorkTime(project.totalWorkSeconds),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  // Session elapsed timer
                  const SizedBox(width: 6),
                  Icon(
                    Icons.timer_outlined,
                    size: 11,
                    color: chipColor.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 52,
                    child: Text(
                      _formatWorkTime(sessionElapsed),
                      style: TextStyle(
                        color: chipColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Action buttons — icon-only with tooltips
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: l10n.launch,
                child: IconButton(
                  icon: const Icon(Icons.launch),
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  color: Colors.white70,
                  onPressed: () => launchProjectInDaw(context, ref, project),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: l10n.projectDetails,
                child: IconButton(
                  icon: const Icon(Icons.assignment),
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  color: Colors.white70,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailPage(projectId: project.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _PauseSessionButton(
                isPaused: isPaused,
                onPressed: () {
                  if (isPaused) {
                    ref.read(workTimerProvider.notifier).resume();
                  } else {
                    ref.read(workTimerProvider.notifier).pause();
                  }
                },
              ),
              const SizedBox(width: 4),
              _StopSessionButton(
                onPressed: () => confirmEndSession(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints the ├── / └── tree connector for child rows in the folder tree view.
class _TreeConnectorPainter extends CustomPainter {
  final bool isLast;
  final Color color;

  const _TreeConnectorPainter({required this.isLast, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const x = 8.0; // horizontal position of the vertical trunk line
    final midY = size.height / 2;

    // Vertical segment: top → midY for last child (└), top → bottom for others (├)
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, isLast ? midY : size.height),
      paint,
    );

    // Horizontal branch: trunk → right edge at mid-height
    canvas.drawLine(Offset(x, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(_TreeConnectorPainter old) =>
      old.isLast != isLast || old.color != color;
}

class _PauseSessionButton extends StatefulWidget {
  final bool isPaused;
  final VoidCallback onPressed;
  const _PauseSessionButton({required this.isPaused, required this.onPressed});

  @override
  State<_PauseSessionButton> createState() => _PauseSessionButtonState();
}

class _PauseSessionButtonState extends State<_PauseSessionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const yellow = Color(0xFFFBBF24);
    const green = Color(0xFF22C55E);

    final baseColor = widget.isPaused ? yellow : Colors.white54;
    final hoverColor = widget.isPaused ? green : yellow;
    final color = _hovered ? hoverColor : baseColor;
    final glowColor = _hovered ? hoverColor : yellow;
    final icon = widget.isPaused
        ? Icons.play_arrow_rounded
        : Icons.pause_rounded;

    return Tooltip(
      message: widget.isPaused ? l10n.resume : l10n.pause,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
              color: color.withValues(
                alpha: _hovered ? 0.10 : (widget.isPaused ? 0.08 : 0.0),
              ),
              boxShadow: (_hovered || widget.isPaused)
                  ? [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: _hovered ? 0.35 : 0.2,
                        ),
                        blurRadius: _hovered ? 8 : 5,
                      ),
                    ]
                  : const [],
            ),
            child: Center(child: Icon(icon, size: 16, color: color)),
          ),
        ),
      ),
    );
  }
}

class _StopSessionButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _StopSessionButton({required this.onPressed});

  @override
  State<_StopSessionButton> createState() => _StopSessionButtonState();
}

class _StopSessionButtonState extends State<_StopSessionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const red = Color(0xFFEF5350);
    final color = _hovered ? red : Colors.white54;

    return Tooltip(
      message: l10n.stop,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
              color: color.withValues(alpha: _hovered ? 0.10 : 0.0),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: red.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ]
                  : const [],
            ),
            child: Center(
              child: Icon(Icons.stop_rounded, size: 16, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

// Subscribes to stateManager to react to row group expand/collapse changes.
class _ExpandArrowCell extends StatefulWidget {
  final TrinaRow row;
  final TrinaGridStateManager stateManager;
  const _ExpandArrowCell({required this.row, required this.stateManager});

  @override
  State<_ExpandArrowCell> createState() => _ExpandArrowCellState();
}

class _ExpandArrowCellState extends State<_ExpandArrowCell> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.row.type.isGroup && widget.row.type.group.expanded;
    widget.stateManager.addListener(_sync);
  }

  void _sync() {
    if (!mounted) return;
    final now = widget.row.type.isGroup && widget.row.type.group.expanded;
    if (now != _expanded) setState(() => _expanded = now);
  }

  @override
  void dispose() {
    widget.stateManager.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          widget.stateManager.toggleExpandedRowGroup(rowGroup: widget.row),
      child: Center(
        child: Icon(
          _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// Small pill shown next to a project's (or smart-folder group's) name when
// the background folder watcher / scan just found it (see
// FolderWatcherService / recentlyDiscoveredProjectsProvider). Styled to
// match the existing deadline badge (Container + tinted border) rather than
// introducing a new visual language. No tooltip by design — hovering it is
// itself the dismissal, so a tooltip would appear only to vanish immediately
// (mirrors "peeking" at a snackbar right as it's swiped away).
class _NewProjectBadge extends StatelessWidget {
  final VoidCallback onDismiss;
  const _NewProjectBadge({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onDismiss(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.newProjectBadge,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _FolderNameCell extends ConsumerStatefulWidget {
  final TrinaRow row;
  final TrinaGridStateManager stateManager;
  final String folderName;
  const _FolderNameCell({
    required this.row,
    required this.stateManager,
    required this.folderName,
  });

  @override
  ConsumerState<_FolderNameCell> createState() => _FolderNameCellState();
}

class _FolderNameCellState extends ConsumerState<_FolderNameCell> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.row.type.isGroup && widget.row.type.group.expanded;
    widget.stateManager.addListener(_sync);
  }

  void _sync() {
    if (!mounted) return;
    final now = widget.row.type.isGroup && widget.row.type.group.expanded;
    if (now != _expanded) setState(() => _expanded = now);
  }

  @override
  void dispose() {
    widget.stateManager.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childIds = groupChildProjectIds(widget.row);
    final recentlyDiscovered = ref.watch(recentlyDiscoveredProjectsProvider);
    final hasNewChild = childIds.any(recentlyDiscovered.contains);

    return GestureDetector(
      onTap: () =>
          widget.stateManager.toggleExpandedRowGroup(rowGroup: widget.row),
      child: Row(
        children: [
          Icon(
            _expanded ? Icons.folder_open : Icons.folder,
            size: 15,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.folderName,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasNewChild) ...[
            const SizedBox(width: 6),
            _NewProjectBadge(
              onDismiss: () => ref
                  .read(recentlyDiscoveredProjectsProvider.notifier)
                  .dismissAll(childIds),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending Folders Section — shown above the projects table
// ---------------------------------------------------------------------------

enum _DismissChoice { keepAndDismiss, deleteAndDismiss }

enum _SessionChoice { continueSession, endAndRecord }

class _PendingFoldersSection extends ConsumerWidget {
  const _PendingFoldersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingFoldersProvider);
    if (pending.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Column(
        children: pending
            .map((pf) => _PendingFolderRow(pendingFolder: pf))
            .toList(),
      ),
    );
  }
}

class _PendingFolderRow extends ConsumerWidget {
  final PendingFolder pendingFolder;

  const _PendingFolderRow({required this.pendingFolder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pf = pendingFolder;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            Icon(
              Icons.folder_special_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pf.folderName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Row(
                    children: [
                      Text(
                        l10n.pendingProjectWaiting,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      if (pf.intendedDawName != null) ...[
                        Text(
                          ' · ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          pf.intendedDawName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  if (pf.sessionStartedAt != null)
                    StreamBuilder<int>(
                      stream: Stream.periodic(
                        const Duration(seconds: 1),
                        (i) => i,
                      ),
                      builder: (context, _) {
                        final elapsed = DateTime.now().difference(
                          pf.sessionStartedAt!,
                        );
                        final h = elapsed.inHours;
                        final m = elapsed.inMinutes.remainder(60);
                        final s = elapsed.inSeconds.remainder(60);
                        final label = h > 0
                            ? '⏱ ${h}h ${m}m'
                            : m > 0
                            ? '⏱ ${m}m ${s}s'
                            : '⏱ ${s}s';
                        return Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Copy folder name
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 18),
              tooltip: l10n.createProjectCopyName,
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: pf.folderName));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.createProjectNameCopied),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            // Open folder
            IconButton(
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              tooltip: l10n.openFolder,
              visualDensity: VisualDensity.compact,
              onPressed: () => FileLauncher.openFolder(pf.path),
            ),
            // Refresh — scan the folder then resolve pending entry
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: l10n.pendingProjectRefresh,
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final repo = await ref.read(repositoryProvider.future);
                // Re-read the pending folder from the repository so we get the
                // latest sessionStartedAt even if the widget hasn't rebuilt yet.
                final livePf =
                    repo
                        .getPendingFolders()
                        .where((f) => f.id == pf.id)
                        .firstOrNull ??
                    pf;
                final sessionStart = livePf.sessionStartedAt;
                if (kDebugMode) {
                  print(
                    '[PendingRefresh] id=${pf.id} sessionStart=$sessionStart',
                  );
                }

                final scanner = ScannerService();
                final ignoredPaths = repo
                    .getIgnoredPaths()
                    .map((p) => p.path)
                    .toList(growable: false);
                int scanned = 0;
                await for (final entity in scanner.scanDirectory(
                  pf.path,
                  ignoredPaths: ignoredPaths,
                )) {
                  await repo.upsertFromFileSystemEntity(
                    entity,
                    fullMetadata: true,
                  );
                  scanned++;
                }
                ref.invalidate(allProjectsStreamProvider);
                if (kDebugMode) {
                  print(
                    '[PendingRefresh] scanned $scanned entities in ${pf.path}',
                  );
                }

                final resolved = await repo.resolveCompletedPendingFolders();
                if (kDebugMode) {
                  print(
                    '[PendingRefresh] resolved=${resolved.toList()} contains(${pf.id})=${resolved.contains(pf.id)}',
                  );
                }
                if (!resolved.contains(pf.id)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.pendingProjectNotFound)),
                    );
                  }
                  return;
                }

                // --- Session dialogs BEFORE bump() ---
                // bump() removes this widget from the tree, making context
                // invalid. All dialogs must be shown while the widget is still
                // mounted, then we bump and do the async work without context.
                _SessionChoice? sessionChoice;
                MusicProject? sessionProject;
                bool shouldSetActive = false;

                // Only reconcile the session interactively while session mode
                // is on — otherwise there is no session UI for the "end and
                // record / continue" prompt to belong to. The folder still
                // resolves and is removed below via bump().
                if (sessionStart != null &&
                    context.mounted &&
                    ref.read(sessionModeProvider)) {
                  sessionProject = repo
                      .getAllProjects()
                      .where((p) => p.filePath.startsWith(pf.path))
                      .firstOrNull;
                  if (kDebugMode) {
                    print(
                      '[PendingRefresh] project=${sessionProject?.displayName} (searching in ${pf.path})',
                    );
                  }

                  if (sessionProject != null) {
                    final elapsed = DateTime.now().difference(sessionStart);
                    final h = elapsed.inHours;
                    final m = elapsed.inMinutes.remainder(60);
                    final durationLabel = h > 0 ? '${h}h ${m}m' : '${m}m';

                    sessionChoice = await showDialog<_SessionChoice>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.pendingFolderSessionTitle),
                        content: Text(
                          l10n.pendingFolderSessionBody(
                            sessionProject!.displayName.isNotEmpty
                                ? sessionProject.displayName
                                : pf.folderName,
                            durationLabel,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l10n.cancel),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(ctx, _SessionChoice.endAndRecord),
                            child: Text(l10n.pendingFolderSessionEndRecord),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(
                              ctx,
                              _SessionChoice.continueSession,
                            ),
                            child: Text(l10n.pendingFolderSessionContinue),
                          ),
                        ],
                      ),
                    );
                    if (kDebugMode) {
                      print('[PendingRefresh] sessionChoice=$sessionChoice');
                    }

                    if (sessionChoice == _SessionChoice.continueSession &&
                        context.mounted) {
                      final currentActive = ref.read(activeProjectProvider);
                      if (currentActive != null &&
                          currentActive.id != sessionProject.id) {
                        final confirmSwitch = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.activeSessionSwitchTitle),
                            content: Text(
                              l10n.activeSessionSwitchBody(
                                currentActive.displayName.isNotEmpty
                                    ? currentActive.displayName
                                    : currentActive.fileName,
                                sessionProject!.displayName.isNotEmpty
                                    ? sessionProject.displayName
                                    : sessionProject.fileName,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l10n.cancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l10n.activeSessionSwitch),
                              ),
                            ],
                          ),
                        );
                        shouldSetActive = confirmSwitch == true;
                      } else {
                        shouldSetActive = true;
                      }
                    }
                  }
                }

                // Capture ref-dependent notifiers BEFORE bump() disposes
                // this widget. After bump() the widget is unmounted and ref
                // reads would throw "Using ref when widget is unmounted".
                final dirtyNotifier = ref.read(
                  pendingFoldersDirtyProvider.notifier,
                );
                final activeNotifier = ref.read(activeProjectProvider.notifier);
                final workTimerNotifier = ref.read(workTimerProvider.notifier);

                // NOW bump — removes this widget from the tree.
                // No context or ref access after this point.
                dirtyNotifier.bump();

                // Handle session outcome (no context/ref reads after this point).
                if (sessionProject != null && sessionChoice != null) {
                  if (sessionChoice == _SessionChoice.endAndRecord) {
                    // Record the elapsed time as a completed historical session.
                    final now = DateTime.now();
                    final elapsedSecs = now.difference(sessionStart!).inSeconds;
                    if (kDebugMode) {
                      print(
                        '[PendingRefresh] endAndRecord elapsedSecs=$elapsedSecs for project ${sessionProject.id}',
                      );
                    }
                    if (elapsedSecs > 0) {
                      final latest =
                          repo.getById(sessionProject.id) ?? sessionProject;
                      final record = SessionRecord(
                        id: sessionStart.toIso8601String(),
                        startedAt: sessionStart,
                        endedAt: now,
                        durationSeconds: elapsedSecs,
                        phase: latest.status,
                      );
                      final newSessions = [...latest.sessions, record];
                      await repo.updateProject(
                        latest.copyWith(
                          totalWorkSeconds: newSessions.fold<int>(
                            0,
                            (s, r) => s + r.durationSeconds,
                          ),
                          sessions: newSessions,
                          updatedAt: now,
                        ),
                      );
                      if (kDebugMode) {
                        print(
                          '[PendingRefresh] session saved to project ${sessionProject.id}',
                        );
                      }
                    }
                  } else if (shouldSetActive) {
                    // Continue session — do NOT record now; WorkTimerNotifier
                    // will save it when the project is eventually deactivated.
                    final updated =
                        repo.getById(sessionProject.id) ?? sessionProject;
                    // Set the project active (triggers WorkTimerNotifier._start()).
                    activeNotifier.set(updated);
                    // Override the start time so the timer shows the full
                    // duration since the original session start, not just
                    // the time since "Refresh" was pressed.
                    workTimerNotifier.continueFrom(sessionStart!);
                  }
                }
              },
            ),
            // Delete — always visible; dialog content varies based on whether
            // user files exist inside the folder.
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: l10n.pendingProjectDelete,
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final hasUserFiles = !pf.isEmptyOrOnlyMarker;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      hasUserFiles
                          ? l10n.pendingProjectDeleteNotEmptyTitle
                          : l10n.pendingProjectDeleteTitle,
                    ),
                    content: Text(
                      hasUserFiles
                          ? l10n.pendingProjectDeleteNotEmptyBody(pf.folderName)
                          : l10n.pendingProjectDeleteBody(pf.folderName),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        style: hasUserFiles
                            ? FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  ctx,
                                ).colorScheme.error,
                              )
                            : null,
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  try {
                    await Directory(pf.path).delete(recursive: true);
                  } catch (_) {}
                  final repo = await ref.read(repositoryProvider.future);
                  await repo.removePendingFolder(pf.id);
                  ref.read(pendingFoldersDirtyProvider.notifier).bump();
                }
              },
            ),
            // Dismiss (stop tracking, with option to delete)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l10n.pendingProjectDismiss,
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final choice = await showDialog<_DismissChoice>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.pendingProjectDismissTitle),
                    content: Text(pf.folderName),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.cancel),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(l10n.pendingProjectDismissDelete),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(ctx).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                        onPressed: () =>
                            Navigator.pop(ctx, _DismissChoice.deleteAndDismiss),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(ctx, _DismissChoice.keepAndDismiss),
                        child: Text(l10n.pendingProjectDismissKeep),
                      ),
                    ],
                  ),
                );
                if (choice == null || !context.mounted) return;
                if (choice == _DismissChoice.deleteAndDismiss) {
                  try {
                    await Directory(pf.path).delete(recursive: true);
                  } catch (_) {}
                }
                final repo = await ref.read(repositoryProvider.future);
                await repo.removePendingFolder(pf.id);
                ref.read(pendingFoldersDirtyProvider.notifier).bump();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButtonWithGlow extends StatefulWidget {
  final bool isActive;
  final Color glowColor;
  final Widget child;

  const _PlayButtonWithGlow({
    required this.isActive,
    required this.glowColor,
    required this.child,
  });

  @override
  State<_PlayButtonWithGlow> createState() => _PlayButtonWithGlowState();
}

class _PlayButtonWithGlowState extends State<_PlayButtonWithGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(
      begin: 0.15,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PlayButtonWithGlow old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isActive && old.isActive) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Positioned so it does not affect the Stack's layout size.
          // The glow overflows visually but the button's footprint stays constant.
          Positioned(
            left: -3,
            right: -3,
            top: -3,
            bottom: -3,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.glowColor.withValues(alpha: _anim.value * 0.28),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}
