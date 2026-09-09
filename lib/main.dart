import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode, utf8;
import 'dart:math' show sqrt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';
import 'dart:io'
    show
        Platform,
        Process,
        ServerSocket,
        Socket,
        InternetAddress,
        SocketException,
        File,
        Directory,
        FileSystemEntity,
        FileSystemException,
        exit;
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

// NOVO: Importar providers e serviços para a lógica de auto-scan
import 'models/music_project.dart';
import 'providers/providers.dart';
import 'repository/project_repository.dart';
import 'services/scanner_service.dart';
import 'services/deadline_notification_service.dart';
import 'services/notification_background_service.dart';
import 'services/google_drive_sync_service.dart';
import 'services/update_check_service.dart';
import 'services/crash_logger.dart';
import 'services/dock_menu_service.dart';
import 'services/quick_action.dart';
import 'services/tray_notice.dart';
import 'services/tray_service.dart';
import 'services/folder_watcher_service.dart';
import 'services/auto_start_service.dart';
import 'services/thumbnail_toolbar_service.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'models/auto_backup_interval.dart';
import 'models/custom_theme.dart';
import 'utils/app_paths.dart';
import 'utils/mobile_utils.dart';

import 'ui/dashboard_page.dart';
import 'ui/dev_library_picker.dart';
import 'ui/dialogs/create_project_dialog.dart';
import 'ui/onboarding_wizard_page.dart';
import 'ui/project_detail_page.dart';
import 'ui/widgets/macos_menu_bar.dart';
import 'ui/widgets/quit_confirm_dialog.dart';
import 'ui/widgets/update_available_dialog.dart';
import 'providers/theme_provider.dart';
import 'utils/route_observer.dart';

// Global navigator key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Auto-backup state (top-level so it persists for the app lifetime)
bool _autoBackupRunning = false;
Timer? _autoBackupTimer;

// Keeps the single-instance socket alive for the app's lifetime.
// ignore: unused_element
ServerSocket? _singleInstanceSocket;

// Set once the provider container exists. Quick actions arriving before
// this is ready (a launch racing app startup) are simply dropped — bringing
// the window to front still happens regardless.
ProviderContainer? _appContainer;

/// Fully terminates the app on desktop. Destroys the tray icon first —
/// tray_manager keeps a native hook/hidden window alive on Windows for as
/// long as the icon exists. Then force-exits the process: destroying the
/// native window alone doesn't end the Dart isolate, and this app keeps
/// several things running in the background for as long as it lives (the
/// 5-minute auto-backup Timer.periodic, notification services, Drive sync
/// listeners) — any one of those can keep the event loop alive after the
/// window is gone, so without an explicit exit the process lingers until
/// the OS's own "unresponsive app" timeout kills it.
///
/// Cancels the auto-backup timer so a new run can't start, but doesn't wait
/// for one already in flight: the Drive backup file is replaced with a
/// single atomic upload, so killing it mid-flight just leaves the previous
/// backup in place rather than corrupting anything — not worth blocking
/// quit for. (It used to prompt "wait or quit anyway", but that dialog
/// rendered into the hidden window when quitting from the tray while
/// closed-to-tray, making it invisible and undismissable — quit looked
/// hung until the user manually reopened the window.)
Future<void> quitApp() async {
  _autoBackupTimer?.cancel();
  _folderWatcherRepoSub?.close();
  await _folderWatcherRootsSub?.cancel();
  await _folderWatcherChangesSub?.cancel();
  await _folderWatcherService?.dispose();
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      await trayManager.destroy();
    } catch (_) {}
  }
  await windowManager.destroy();
  exit(0);
}

/// Restores and focuses the window in response to a second launch attempt
/// (e.g. clicking a taskbar/desktop shortcut while hidden in the tray).
/// Mirrors [TrayService._showWindow] — kept separate since it must run
/// before the tray service (or even the provider container) exists.
Future<void> _bringWindowToFront() async {
  try {
    await windowManager.show();
    await windowManager.focus();
  } catch (_) {}
}

/// Runs [action] once the navigator has a context, either immediately (if
/// one is already available) or after the next frame — needed since quick
/// actions can arrive before the first frame renders (cold start via a jump
/// list / Dock menu click) as well as long after (an already-running app).
void _runWithNavigatorContext(void Function(BuildContext context) action) {
  final ctx = navigatorKey.currentContext;
  if (ctx != null) {
    action(ctx);
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) action(ctx);
  });
}

void _openProjectById(String id) {
  _runWithNavigatorContext((ctx) {
    Navigator.of(
      ctx,
    ).push(MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: id)));
  });
}

void _showCreateProjectDialog() {
  _runWithNavigatorContext((ctx) {
    showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const CreateProjectDialog(),
    );
  });
}

Future<void> _triggerProjectScan() async {
  final container = _appContainer;
  if (container == null) return;
  try {
    final repo = await container.read(repositoryProvider.future);
    final foundCount = await _runInitialScan(repo, container);
    _runWithNavigatorContext((ctx) {
      final l10n = AppLocalizations.of(ctx);
      if (l10n == null) return;
      final msg = foundCount == 0
          ? l10n.noProjectsFoundInRoots
          : l10n.scanComplete(
              l10n.rescan,
              foundCount,
              foundCount == 1 ? '' : 's',
            );
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
    });
  } catch (_) {}
}

/// Dispatches a quick action requested via the taskbar jump list (Windows)
/// or the Dock menu (macOS forwards these straight from native code instead —
/// see [DockMenuService.setOpenProjectHandler]). [args] is either the
/// process's own command-line arguments (cold start) or the argument list
/// forwarded by a second launch attempt over the single-instance socket.
Future<void> _dispatchQuickAction(List<String> args) async {
  switch (parseQuickAction(args)) {
    case NewProjectQuickAction():
      _showCreateProjectDialog();
    case ScanProjectsQuickAction():
      await _triggerProjectScan();
    case OpenProjectQuickAction(:final projectId):
      _openProjectById(projectId);
    case null:
      break;
  }
}

Future<void> _showAlreadyRunningMessage() async {
  if (Platform.isWindows) {
    await Process.run('powershell', [
      '-Command',
      'Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show("DAW Project Manager is already running. Please close the existing window before opening a new one.", "DAW Project Manager")',
    ]);
  }
}

/// Reads the update-check preference directly from Hive (bypassing the provider
/// which defers its Hive load to after the first frame) and, if enabled, checks
/// for a newer release in the background.
Future<void> _runStartupUpdateCheck(ProviderContainer container) async {
  if (!UpdateCheckService.isSupported) return;
  try {
    final box = await Hive.openBox<String>('app_settings');
    if (box.get('checkForUpdates') != 'true') return;
    const current = String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '0.0.0',
    );
    final newer = await UpdateCheckService.checkForUpdate(current);
    if (newer != null) {
      container.read(availableUpdateProvider.notifier).set(newer);
      // Show dialog once the first frame has rendered (navigator is ready).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) UpdateAvailableDialog.show(ctx, newer);
      });
    }
  } catch (_) {}
}

void _startAutoBackupTimer(
  ProviderContainer container,
  GoogleDriveSyncService syncService,
) {
  _autoBackupTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
    if (_autoBackupRunning) return;
    _autoBackupRunning = true;
    try {
      // Read saved settings from app_settings box
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('app_settings');
      final interval = AutoBackupInterval.fromStorageKey(
        settingsBox.get('autoBackupInterval'),
      );
      final duration = interval.duration;
      if (duration == null) return; // "off"

      // On desktop, try to silently restore session if not already signed in
      if (!syncService.isSignedIn) {
        if (!GoogleDriveSyncService.isSupported) return;
        if (!kIsWeb && !MobileUtils.isMobile()) {
          try {
            final restored = await syncService.restoreSession();
            if (!restored) return;
          } catch (_) {
            return;
          }
        } else {
          return;
        }
      }

      // Check if enough time has elapsed since the last upload
      final lastUpload = await syncService.getLastBackupUploadTimestamp();
      if (lastUpload != null &&
          DateTime.now().difference(lastUpload) < duration) {
        return; // Not due yet
      }

      // Run backup silently. Use syncDatabase (not a raw uploadDatabase) so a
      // newer backup already on Drive — e.g. uploaded from another device —
      // gets downloaded and merged first instead of being blindly overwritten.
      final profileRepo = await container.read(
        profileRepositoryProvider.future,
      );
      final projectRepo = await container.read(repositoryProvider.future);
      final uploadAutoDetected =
          settingsBox.get('uploadAutoPreviewSongs') == 'true';
      await syncService.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        uploadAutoDetectedSongs: uploadAutoDetected,
      );
      if (kDebugMode) print('Auto-backup completed successfully');
    } catch (e) {
      if (kDebugMode) print('Auto-backup failed: $e');
    } finally {
      _autoBackupRunning = false;
    }
  });
}

// Background folder watcher (desktop only) — auto-detects new project files
// dropped into scan roots so they appear without a manual/periodic rescan.
// Lives here (not in DashboardPage) so it survives regardless of which
// tab/screen is open and can rebind cleanly across profile switches, the
// same way the auto-backup timer and tray service do.
FolderWatcherService? _folderWatcherService;
ProviderSubscription<AsyncValue<ProjectRepository>>? _folderWatcherRepoSub;
StreamSubscription<BoxEvent>? _folderWatcherRootsSub;
StreamSubscription<String>? _folderWatcherChangesSub;
ProjectRepository? _folderWatcherActiveRepo;

void _startFolderWatcher(ProviderContainer container) {
  final watcher = FolderWatcherService();
  _folderWatcherService = watcher;

  _folderWatcherChangesSub = watcher.changes.listen((rootPath) {
    final repo = _folderWatcherActiveRepo;
    if (repo != null) _onFolderWatcherActivity(rootPath, repo, container);
  });

  void bindRepo(ProjectRepository repo) {
    if (identical(repo, _folderWatcherActiveRepo)) return;
    _folderWatcherActiveRepo = repo;
    _folderWatcherRootsSub?.cancel();
    watcher.syncRoots(repo.getRoots());
    _folderWatcherRootsSub = repo.watchRoots().listen((_) {
      watcher.syncRoots(repo.getRoots());
    });
  }

  // Rebinds automatically on profile switch, since repositoryProvider
  // resolves to a fresh ProjectRepository (own Hive boxes) per profile.
  _folderWatcherRepoSub = container.listen<AsyncValue<ProjectRepository>>(
    repositoryProvider,
    (previous, next) {
      final repo = next.value;
      if (repo != null) bindRepo(repo);
    },
    fireImmediately: true,
  );
}

/// Finds the project a resolved [PendingFolder] turned into, by matching
/// its path against the folder's own path. Extracted as a standalone,
/// dependency-free function — the surrounding folder-watcher callback
/// touches real Hive/filesystem/Riverpod state and isn't practically unit
/// testable, but this specific matching step is, so the two are kept
/// separate rather than leaving it as unreachable inline logic.
@visibleForTesting
MusicProject? findProjectForPendingFolder(
  List<MusicProject> projects,
  String pendingFolderPath,
) {
  return projects
      .where((p) => p.filePath.startsWith(pendingFolderPath))
      .firstOrNull;
}

/// Whether resolving a pending folder should auto-resume its tracked session
/// (activate the project and start its work timer from [sessionStartedAt]).
/// Only when session mode is on AND the folder was actually stamped for
/// session tracking — a stamp can outlive the user turning session mode off,
/// and starting a session they never asked for is worse than dropping the
/// stray stamp. Kept pure so the rule is regression-testable; the folder
/// watcher itself isn't.
@visibleForTesting
bool shouldResumeSessionOnResolve({
  required bool sessionModeOn,
  required DateTime? sessionStartedAt,
}) =>
    sessionModeOn && sessionStartedAt != null;

/// Runs a targeted, diff-based scan of just [rootPath] — much lighter than
/// the full-root walk in `_runInitialScan`/`_scanAll`, since it skips any
/// path already known to the repository (no wasted metadata re-extraction)
/// and never prunes/removes existing projects (that stays manual-rescan-only
/// so a filesystem-watch hiccup can never delete user data).
Future<void> _onFolderWatcherActivity(
  String rootPath,
  ProjectRepository repo,
  ProviderContainer container,
) async {
  try {
    final scanner = ScannerService();
    final ignoredPaths = repo
        .getIgnoredPaths()
        .map((p) => p.path)
        .toList(growable: false);
    final knownPaths = repo.getAllProjects().map((p) => p.filePath).toSet();

    // Materialize the newly-seen entities first, then persist them in one
    // batched write — upsertFromFileSystemEntity's per-entity Box.put() used
    // to fire one Hive change event per file, which the debounced
    // watchAllProjects stream now smooths over on the read side, but batching
    // here also cuts the write cost itself (see upsertManyFromFileSystemEntities).
    final newEntities = <FileSystemEntity>[];
    await for (final entity in scanner.scanDirectory(
      rootPath,
      ignoredPaths: ignoredPaths,
    )) {
      if (knownPaths.contains(entity.path)) continue;
      newEntities.add(entity);
    }

    final newIds = <String>[];
    if (newEntities.isNotEmpty) {
      await repo.upsertManyFromFileSystemEntities(
        newEntities,
        fullMetadata: false,
      );
      for (final entity in newEntities) {
        final saved = repo.getByPath(entity.path);
        if (saved != null) newIds.add(saved.id);
      }
    }

    if (newIds.isNotEmpty) {
      container
          .read(recentlyDiscoveredProjectsProvider.notifier)
          .addAll(newIds);
      container.invalidate(allProjectsStreamProvider);
    }

    // Resolve pending folders that are now satisfied. Session-tracked
    // entries resolve too — the file existing means the DAW session really
    // did start — rather than being silently left for the next manual
    // rescan (which used to leave the "waiting for project" chip stuck
    // until the user manually clicked Refresh/Scan, even though the
    // project had already appeared in the list). This never pops the
    // interactive "end and record / continue" dialog (that stays
    // manual-only, in DashboardPage._scanAll and the pending-row Refresh
    // action).
    //
    // When session mode is on it takes the equivalent of "continue": the
    // timer keeps running under the resolved project, uninterrupted. That's
    // safe even if a different project is currently active, since switching
    // activeProjectProvider auto-saves the outgoing project's elapsed time
    // as its own SessionRecord first (see WorkTimerNotifier.build's
    // listener). When session mode is off there is no session UI, so the
    // folder just resolves — auto-activating a project and starting its
    // timer here would silently begin a session the user never asked for
    // (the stamp can predate them turning session mode off).
    final resolvable = repo
        .getPendingFolders()
        .where((pf) => !pf.folderExists || pf.hasProjectFile())
        .toList(growable: false);
    if (resolvable.isNotEmpty) {
      final sessionModeOn = container.read(sessionModeProvider);
      for (final pf in resolvable) {
        final sessionStart = pf.sessionStartedAt;
        if (sessionStart != null &&
            shouldResumeSessionOnResolve(
              sessionModeOn: sessionModeOn,
              sessionStartedAt: sessionStart,
            )) {
          final project = findProjectForPendingFolder(
            repo.getAllProjects(),
            pf.path,
          );
          if (project != null) {
            container.read(activeProjectProvider.notifier).set(project);
            container
                .read(workTimerProvider.notifier)
                .continueFrom(sessionStart);
          }
        }
        await repo.removePendingFolder(pf.id);
      }
      container.read(pendingFoldersDirtyProvider.notifier).bump();
    }
  } catch (e) {
    if (kDebugMode) print('[FolderWatcher] scan failed for $rootPath: $e');
  }
}

class _BackIntent extends Intent {
  const _BackIntent();
}

// Handle notification tap - navigate to project details
Future<void> _handleNotificationTap(String projectId) async {
  if (kDebugMode) print('Handling notification tap for project: $projectId');

  final context = navigatorKey.currentContext;
  if (context == null) {
    if (kDebugMode) print('Navigator context not available');
    return;
  }

  try {
    // Navigate to project details page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailPage(projectId: projectId),
      ),
    );
  } catch (e) {
    if (kDebugMode) print('Error navigating to project details: $e');
  }
}

// NOVO: Função para executar o scan
// Returns the number of on-disk projects found/synced — used by the "Scan
// for Projects" quick action to show a result, since this otherwise silent
// path (unlike the dashboard's manual rescan button) gives no feedback.
Future<int> _runInitialScan(
  ProjectRepository repo,
  ProviderContainer container,
) async {
  container.read(initialScanStateProvider.notifier).setScanning(true);
  var foundCount = 0;
  try {
    // Cria o scanner e processa as raízes de scan. Projects whose file goes
    // missing are left alone here — see deleteProjectsPermanently's doc
    // comment for why scans no longer auto-delete anything.
    final scanner = ScannerService();
    final ignoredPaths = repo
        .getIgnoredPaths()
        .map((p) => p.path)
        .toList(growable: false);
    final scanTime = DateTime.now();
    // Snapshot before scanning so files found while the app was last closed
    // can be flagged "New" in the UI. Skipped on a genuinely empty repo (a
    // fresh profile's very first scan) — there, everything found is just the
    // initial population, not a "new since last time" discovery.
    final knownPaths = repo.getAllProjects().map((p) => p.filePath).toSet();
    final newlyDiscoveredIds = <String>[];
    for (final root in repo.getRoots()) {
      final entities = <FileSystemEntity>[];
      await for (final entity in scanner.scanDirectory(
        root.path,
        ignoredPaths: ignoredPaths,
      )) {
        entities.add(entity);
      }
      if (entities.isNotEmpty) {
        await repo.upsertManyFromFileSystemEntities(entities);
        foundCount += entities.length;
      }
      final foundPaths = entities.map((e) => e.path).toSet();
      if (knownPaths.isNotEmpty) {
        for (final path in newlyFoundPaths(foundPaths, knownPaths)) {
          final saved = repo.getByPath(path);
          if (saved != null) newlyDiscoveredIds.add(saved.id);
        }
      }
      // Update lastScanAt timestamp for this root
      await repo.updateRootLastScanAt(root.id, scanTime);
    }
    if (newlyDiscoveredIds.isNotEmpty) {
      container
          .read(recentlyDiscoveredProjectsProvider.notifier)
          .addAll(newlyDiscoveredIds);
    }

    // 3. Mark initial scan as complete
    container.read(initialScanStateProvider.notifier).complete();

    if (kDebugMode) {
      print("Initial scan completed successfully.");
    }
  } catch (e, st) {
    // Mark as complete even on error so UI doesn't stay frozen
    container.read(initialScanStateProvider.notifier).complete();
    if (kDebugMode) {
      print("Error during initial scan: $e");
      print(st);
    }
  }
  return foundCount;
}

void main(List<String> args) {
  runZonedGuarded(() => _main(args), (error, stack) {
    unawaited(CrashLogger.log('zone', error, stack));
  });
}

Future<void> _main(List<String> args) async {
  // 1. Inicialização do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Catch uncaught framework errors (build/layout/paint) and errors that
  // escape the root zone, logging them to disk so a crash that happens
  // while the app is backgrounded leaves a trace instead of vanishing.
  CrashLogger.installGlobalHandlers();

  // Replace the default red/gray error box with a small recoverable
  // placeholder — a single broken widget shouldn't look like the whole
  // app died, and the failure is now logged regardless.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) return ErrorWidget(details.exception);
    return const ColoredBox(
      color: Color(0x00000000),
      child: Center(
        child: Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
      ),
    );
  };

  // 1b. Single-instance guard (Windows/Linux only).
  // macOS is handled natively in AppDelegate.swift before Dart starts.
  if (!kIsWeb && Platform.isWindows) {
    // Not a fixed port: a build pinned to its own app-data directory binds
    // its own, so it starts alongside the installed app instead of being
    // forwarded into it. See singleInstancePort. Resolved before the try so
    // the connect-to-the-existing-instance path below uses the same one.
    final port = singleInstancePort;
    try {
      _singleInstanceSocket = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      // Any connection on this port is a second launch attempt asking us to
      // surface the (possibly tray-hidden) window instead of starting fresh.
      // It may also carry the second instance's command-line args (a jump
      // list quick action) as a JSON-encoded string list payload.
      _singleInstanceSocket!.listen((client) {
        final chunks = <int>[];
        client.listen(
          chunks.addAll,
          onDone: () {
            client.destroy();
            unawaited(_bringWindowToFront());
            if (chunks.isNotEmpty) {
              try {
                final forwarded = (jsonDecode(utf8.decode(chunks)) as List)
                    .cast<String>();
                unawaited(_dispatchQuickAction(forwarded));
              } catch (_) {}
            }
          },
        );
      });
    } on SocketException {
      // Port is already bound — another instance is running. Ask it to show
      // itself (and forward along any quick-action arguments) rather than
      // just telling the user to go close it manually.
      try {
        final socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          port,
          timeout: const Duration(seconds: 2),
        );
        socket.add(utf8.encode(jsonEncode(args)));
        await socket.flush();
        await socket.close();
      } catch (_) {
        await _showAlreadyRunningMessage();
      }
      exit(0);
    }
  }

  // 1c. Generate taskbar overlay icons (Windows only)
  if (!kIsWeb && Platform.isWindows) {
    await _initTaskbarOverlayIcons();
    // Thumbnail toolbar is off — see kThumbnailToolbarEnabled and #119. Skip
    // writing its icons and registering its click handler too, rather than
    // only skipping the pushes: with the button never shown, the handler
    // could not fire anyway, and the .ico files would be dead files on disk.
    if (kThumbnailToolbarEnabled) {
      await _initThumbnailToolbarIcons();
      _registerThumbnailToolbarHandler();
    }
  }

  // 2. Initialize notification services
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      await DeadlineNotificationService().initializeDesktop();
    } catch (e) {
      if (kDebugMode) print('Desktop notification init failed: $e');
    }
  }
  // Background audio: both mobile platforms. The android* parameters below
  // are simply ignored on iOS, where the equivalent capability comes from the
  // UIBackgroundModes "audio" entry in ios/Runner/Info.plist — without that
  // key iOS suspends playback the moment the app leaves the foreground.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // Fire-and-forget: não bloqueia o runApp(). O player usa audioplayers como
    // fallback até init() completar; depois usa just_audio com notificação.
    unawaited(
      JustAudioBackground.init(
            androidNotificationChannelId: 'com.bandpassrecords.dpm.audio',
            androidNotificationChannelName: 'DAW Project Manager',
            androidNotificationChannelDescription:
                'Controles de preview de faixas',
            androidNotificationOngoing: false,
            androidStopForegroundOnPause: true,
            // Brand the media notification: app accent color and the existing
            // monochrome status-bar icon (already used for deadline notifications).
            notificationColor: const Color(0xFFFF6100),
            androidNotificationIcon: 'drawable/ic_notification',
          )
          .timeout(const Duration(seconds: 8))
          .then((_) {
            markJabInitialized();
            if (kDebugMode) print('[JustAudioBackground] initialized OK');
          })
          .catchError((Object e) {
            if (kDebugMode)
              print('[JustAudioBackground] INIT FAILED/TIMEOUT: $e');
          }),
    );

  }

  // Deadline notifications are Android-only for now: DeadlineNotificationService
  // and NotificationBackgroundService both bail out on any other platform, and
  // the background rescheduling half is built on Android WorkManager with no
  // iOS counterpart. Kept as its own gate rather than folded into the block
  // above so enabling background audio on iOS didn't silently switch on a
  // half-implemented notification stack too.
  if (!kIsWeb && Platform.isAndroid) {
    // Notificações de deadline: fire-and-forget para não bloquear o startup.
    try {
      final notificationService = DeadlineNotificationService();
      await notificationService.initialize();
      notificationService.setOnNotificationTapCallback(_handleNotificationTap);
      unawaited(NotificationBackgroundService.initialize());
    } catch (e) {
      if (kDebugMode) print('Error initializing notification services: $e');
    }
  }

  // Set by the OS auto-start registration (see AutoStartService), never by a
  // manual launch — so "start minimized" only ever applies at login.
  final startHidden = AutoStartService.launchedMinimized(args);

  // 3. Window Manager only for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();

    // Configurações da Janela
    const initialSize = Size(1800, 1040); // Fits comfortably on 1080p screens
    const minimumSize = Size(
      800,
      600,
    ); // Allow resizing to a smaller minimum size
    WindowOptions windowOptions = WindowOptions(
      size: initialSize,
      minimumSize: minimumSize,
      center: true,
      title: "DAW Project Manager",
      // macOS: hidden style = fullSizeContentView + transparent title bar.
      // Traffic lights remain visible and float over the Flutter content.
      // Windows/Linux debug: normal (for easy development).
      // Windows/Linux release: hidden (custom Flutter title bar).
      titleBarStyle: (!Platform.isMacOS && kDebugMode)
          ? TitleBarStyle.normal
          : TitleBarStyle.hidden,
    );

    // Criação e exibição da janela.
    // On an auto-start launch with "start minimized" the window is simply
    // never shown — window_manager creates it hidden, so skipping show()
    // leaves it out of the taskbar too, exactly like the close-to-tray path.
    // The tray icon (set up in 4e-2) is then the only way back in, which is
    // why the failure paths below force the window open if it never appears.
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (startHidden) return;
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Dev builds ask which library to open. This has to happen here — before
  // the first ensureHiveInitialized() below — because every path the app uses
  // is derived from the chosen directory. No-ops in release builds and in
  // pull-request builds, which are pinned to their own directory instead.
  await maybePickAppDataLibrary();

  // Pre-open the settings box so providers can read it synchronously on first build.
  await ensureHiveInitialized();
  try {
    await Hive.openBox<String>('settings');
  } on FileSystemException catch (e) {
    // Another instance already holds the Hive lock (errno 35 on macOS).
    // The native AppDelegate check should prevent reaching here, but guard anyway.
    if (kDebugMode) print('[main] Hive lock held by another instance: $e');
    exit(0);
  }

  // NOVO: 4. Configuração do Riverpod e Auto-Scan
  final container = ProviderContainer();
  _appContainer = container;

  // Dock menu (macOS) invokes straight back into this running process —
  // no relaunch/IPC involved, unlike the Windows jump list.
  DockMenuService.setOpenProjectHandler((id) async {
    await _bringWindowToFront();
    _openProjectById(id);
  });

  try {
    // 4a. Pré-carrega o ProfileRepository primeiro
    await container.read(profileRepositoryProvider.future);

    // 4b. Pré-carrega o ProjectRepository (que depende do ProfileRepository)
    final repo = await container.read(repositoryProvider.future);

    // 4c. Executa o Scan Inicial em segundo plano (não aguardamos o Future)
    // O await repo... em cima garante que o Hive está pronto antes do scan.
    _runInitialScan(repo, container);

    // 4c-2. Background folder watcher (desktop only — mobile has no scan
    // roots today) — auto-detects new project files without a full rescan.
    if (!kIsWeb && !MobileUtils.isMobile()) {
      _startFolderWatcher(container);
    }

    // 4d. Schedule deadline notifications (Android only)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final notificationService = DeadlineNotificationService();
        final projects = repo.getAllProjects();

        if (kDebugMode) {
          print('\n🔔 Scheduling deadline notifications on app start...');
          print('📦 Total projects loaded: ${projects.length}');
        }

        await notificationService.scheduleAllDeadlineNotifications(
          projects: projects,
        );
      } catch (e) {
        if (kDebugMode)
          print('❌ Error scheduling notifications on startup: $e');
      }
    }

    // 4e. Start auto-backup timer (desktop: try to restore session silently)
    final autoBackupService = GoogleDriveSyncService();
    // Drive sync isn't offered inside Flatpak (see GoogleDriveSyncService.
    // isSupported) — restoreSession() reads saved credentials via
    // FlutterSecureStorage on non-macOS desktop, which touches libsecret/the
    // OS keyring on Linux. Without this gate that happened unconditionally
    // on every startup even inside Flatpak, where nothing could ever have
    // signed in to restore, surfacing as a spurious "libsecret_error:
    // KeyringLocked" warning (and an unnecessary keyring unlock prompt on
    // some setups). Outside Flatpak this now genuinely runs — the same
    // possible warning/prompt can happen there too on a Linux desktop with
    // no keyring daemon running, but restoreSession() already fails silently
    // (try/catch below) rather than crashing, so it's just a cosmetic risk.
    if (GoogleDriveSyncService.isSupported &&
        !kIsWeb &&
        !MobileUtils.isMobile()) {
      try {
        await autoBackupService.initializeCredentialsStorage();
        await autoBackupService.restoreSession();
      } catch (_) {}
    }
    _startAutoBackupTimer(container, autoBackupService);

    // 4e-2. System tray icon (Windows/macOS/Linux) — lets the app keep
    // auto-backup and notifications running while the window is hidden.
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      final trayInit = TrayService(container, autoBackupService).init();
      if (startHidden) {
        // Started hidden: the tray icon is the only way to reach the app, so
        // if it fails to appear the process would be invisible and
        // unkillable short of Task Manager. Show the window instead.
        unawaited(
          trayInit.catchError((Object e) {
            if (kDebugMode)
              print('[main] Tray init failed on hidden start: $e');
            unawaited(_bringWindowToFront());
          }),
        );
      } else {
        unawaited(trayInit);
      }
    }

    // 4f. Bootstrap work timer (starts listening to activeProjectProvider).
    container.read(workTimerProvider);

    // 4f-2. Bootstrap the name date-stripping preference. Reading it is what
    // mirrors the stored value into MusicProject.stripDatesFromNames, and
    // MusicProject.displayName has no way to reach the provider itself — so
    // without this eager read the first frame would render unstripped names
    // until something else happened to touch the provider.
    container.read(nameDateStrippingProvider);

    // 4g. Check for updates in background (desktop only, if enabled by user)
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _runStartupUpdateCheck(container);
    }

    // 4h. Reconcile the launch-at-startup preference with the OS. The user
    // can revoke it outside the app (Task Manager → Startup apps, macOS
    // System Settings → Login Items), so the cached Hive value can be stale;
    // this corrects it. Not awaited — it touches the registry / a native
    // channel and nothing at startup depends on the answer.
    if (AutoStartService.isSupported) {
      unawaited(container.read(autoStartProvider.notifier).syncWithOs());
    }
  } catch (e) {
    // Mark as complete even on error
    container.read(initialScanStateProvider.notifier).complete();
    if (kDebugMode)
      print("Failed to initialize repository or run initial scan: $e");
    // Tray setup lives inside this try, so a failure above means it never
    // ran — on a hidden start that leaves nothing to reveal the window.
    if (startHidden) {
      unawaited(_bringWindowToFront());
    }
  }

  // 5. Roda o app com o container já configurado
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DawProjectManagerApp(),
    ),
  );

  // Cold start via a jump list quick action (New Project / Scan for
  // Projects / a recent project) — dispatch once the first frame is up.
  unawaited(_dispatchQuickAction(args));
}

// Windows taskbar overlay icon support — calls the native windows_taskbar plugin
// via its method channel without using the Dart wrapper (avoids the asset-path assertion).
const _taskbarChannel = MethodChannel('com.alexmercerind/windows_taskbar');
final _taskbarIconPaths = <String, String>{};

/// Generates a minimal 16×16 32bpp ICO from the given BGRA pixel array.
Uint8List _buildIco(Uint8List pix) {
  const int sz = 16;
  const int andRowBytes = 4;
  const int imgDataSize = sz * sz * 4 + sz * andRowBytes;
  final bd = ByteData(6 + 16 + 40 + imgDataSize);
  int p = 0;
  bd.setUint16(p, 0, Endian.little);
  p += 2;
  bd.setUint16(p, 1, Endian.little);
  p += 2;
  bd.setUint16(p, 1, Endian.little);
  p += 2;
  bd.setUint8(p++, sz);
  bd.setUint8(p++, sz);
  bd.setUint8(p++, 0);
  bd.setUint8(p++, 0);
  bd.setUint16(p, 1, Endian.little);
  p += 2;
  bd.setUint16(p, 32, Endian.little);
  p += 2;
  bd.setUint32(p, 40 + imgDataSize, Endian.little);
  p += 4;
  bd.setUint32(p, 22, Endian.little);
  p += 4;
  bd.setUint32(p, 40, Endian.little);
  p += 4;
  bd.setInt32(p, sz, Endian.little);
  p += 4;
  bd.setInt32(p, sz * 2, Endian.little);
  p += 4;
  bd.setUint16(p, 1, Endian.little);
  p += 2;
  bd.setUint16(p, 32, Endian.little);
  p += 2;
  for (int k = 0; k < 6; k++) {
    bd.setUint32(p, 0, Endian.little);
    p += 4;
  }
  bd.buffer.asUint8List(p, sz * sz * 4).setAll(0, pix);
  return bd.buffer.asUint8List();
}

/// Solid anti-aliased circle of the given RGB color — minimalist status dot.
Uint8List _makeCircleIco(int r, int g, int b) {
  const int sz = 16;
  final pix = Uint8List(sz * sz * 4);
  const double cx = 7.5, cy = 7.5, radius = 7.0;
  for (int row = 0; row < sz; row++) {
    for (int col = 0; col < sz; col++) {
      final d = sqrt((col - cx) * (col - cx) + (row - cy) * (row - cy));
      final a = d <= radius - 1.0
          ? 255
          : d <= radius
          ? ((radius - d) * 255).round().clamp(0, 255)
          : 0;
      final i = ((sz - 1 - row) * sz + col) * 4; // bottom-up DIB order
      pix[i] = b;
      pix[i + 1] = g;
      pix[i + 2] = r;
      pix[i + 3] = a;
    }
  }
  return _buildIco(pix);
}

/// Writes the two overlay ICO files to the system temp dir at startup.
Future<void> _initTaskbarOverlayIcons() async {
  try {
    final tmp = Directory.systemTemp.path;
    final playingBytes = _makeCircleIco(0x22, 0xC5, 0x5E); // #22C55E green
    final pausedBytes = _makeCircleIco(0xFB, 0xBF, 0x24); // #FBBF24 amber
    final playingPath = '$tmp\\daw_pm_session_playing.ico';
    final pausedPath = '$tmp\\daw_pm_session_paused.ico';
    await File(playingPath).writeAsBytes(playingBytes);
    await File(pausedPath).writeAsBytes(pausedBytes);
    _taskbarIconPaths['playing'] = playingPath;
    _taskbarIconPaths['paused'] = pausedPath;
  } catch (_) {}
}

/// Fills a 16×16 icon from a per-pixel predicate, light gray on transparent —
/// good enough contrast for the taskbar thumbnail toolbar in both themes.
Uint8List _makeGlyphIco(bool Function(double x, double y) inside) {
  const int sz = 16;
  final pix = Uint8List(sz * sz * 4);
  for (int row = 0; row < sz; row++) {
    for (int col = 0; col < sz; col++) {
      if (!inside(col + 0.5, row + 0.5)) continue;
      final i = ((sz - 1 - row) * sz + col) * 4; // bottom-up DIB order
      pix[i] = 0xE8;
      pix[i + 1] = 0xE8;
      pix[i + 2] = 0xE8;
      pix[i + 3] = 255;
    }
  }
  return _buildIco(pix);
}

/// A single triangle pointing right (mirror the x coordinate for left).
bool _triangle(
  double x,
  double y, {
  required double apexX,
  required double baseX,
}) {
  const yTop = 4.0, yBot = 12.0, yMid = 8.0;
  final lo = apexX < baseX ? baseX : apexX;
  final hi = apexX < baseX ? apexX : baseX;
  if (x < (lo < hi ? lo : hi) || x > (lo < hi ? hi : lo)) return false;
  final t = (x - baseX).abs() / (apexX - baseX).abs();
  final halfHeight = (yBot - yTop) / 2 * (1 - t);
  return (y - yMid).abs() <= halfHeight;
}

Uint8List _makePlayIco() =>
    _makeGlyphIco((x, y) => _triangle(x, y, apexX: 11.5, baseX: 5.0));

Uint8List _makePauseIco() => _makeGlyphIco((x, y) {
  if (y < 4 || y > 12) return false;
  return (x >= 4.5 && x <= 7) || (x >= 9 && x <= 11.5);
});

/// Writes the play/pause thumbnail toolbar icon to the system temp dir at
/// startup.
Future<void> _initThumbnailToolbarIcons() async {
  try {
    final tmp = Directory.systemTemp.path;
    final entries = {'play': _makePlayIco(), 'pause': _makePauseIco()};
    for (final entry in entries.entries) {
      final path = '$tmp\\daw_pm_thumb_${entry.key}.ico';
      await File(path).writeAsBytes(entry.value);
      _taskbarIconPaths[entry.key] = path;
    }
  } catch (_) {}
}

bool _thumbnailToolbarHandlerRegistered = false;

/// Registers the click handler for the thumbnail toolbar's play/pause
/// button — done once, since the button index → action mapping never
/// changes. [container] is read lazily at click time so this can be called
/// as soon as the channel exists, before the provider tree is ready.
///
/// Desktop preview playback is a separate stack from the mobile player
/// (`desktopPlayerProvider` / `desktopIsPlayingProvider`, driven by
/// `_DesktopPlayerBar` in dashboard_page.dart) — `mobilePlayerProvider` is
/// mobile-only despite the generic-sounding name and never changes here.
void _registerThumbnailToolbarHandler() {
  if (_thumbnailToolbarHandlerRegistered) return;
  _thumbnailToolbarHandlerRegistered = true;
  _taskbarChannel.setMethodCallHandler((call) async {
    if (call.method != 'WM_COMMAND') return;
    final container = _appContainer;
    if (container == null) return;
    if (call.arguments as int == 0) {
      container.read(desktopPlayerToggleRequestProvider.notifier).bump();
    }
  });
}

/// Pushes thumbnail toolbar state (a single hover-preview play/pause button)
/// to the Windows shell, deduplicated and debounced — see the class docs and
/// issue #119 for why both matter.
final _thumbnailToolbar = ThumbnailToolbarController(
  channel: _taskbarChannel,
  resolveIcon: (isPlaying) => _taskbarIconPaths[isPlaying ? 'pause' : 'play'],
  enabled: kThumbnailToolbarEnabled,
);

/// Updates the Windows taskbar overlay icon to reflect session state.
void _updateTaskbarStatus({required bool hasSession, required bool isPaused}) {
  if (kIsWeb || !Platform.isWindows) return;
  try {
    if (!hasSession) {
      _taskbarChannel.invokeMethod('ResetOverlayIcon', <String, Object?>{});
    } else {
      final path = _taskbarIconPaths[isPaused ? 'paused' : 'playing'];
      if (path != null) {
        _taskbarChannel.invokeMethod('SetOverlayIcon', <String, Object?>{
          'icon': path,
          'tooltip': isPaused ? 'Session Paused' : 'Session Active',
        });
      }
    }
  } catch (_) {}
}

class DawProjectManagerApp extends ConsumerStatefulWidget {
  const DawProjectManagerApp({super.key});

  @override
  ConsumerState<DawProjectManagerApp> createState() =>
      _DawProjectManagerAppState();
}

class _DawProjectManagerAppState extends ConsumerState<DawProjectManagerApp>
    with WindowListener, WidgetsBindingObserver {
  static bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// The native macOS window background, painted behind the Flutter view.
  ///
  /// Read off the active theme spec rather than switched over a fixed list of
  /// themes — a user theme has no enum case, and hardcoding one here would
  /// flash the wrong color around the window frame.
  static Color _bgForTheme(CustomTheme spec) => spec.background;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isDesktop) {
      windowManager.addListener(this);
      // Needed on every desktop platform so onWindowClose can decide
      // between hiding to the tray and actually quitting.
      windowManager.setPreventClose(true);
    }
    if (!kIsWeb && Platform.isMacOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        windowManager.setBackgroundColor(
          _bgForTheme(ref.read(activeThemeProvider)),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isDesktop) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Logged so a crash that surfaces right after resuming from background
    // (a known trouble spot on Android) can be correlated with the transition.
    unawaited(CrashLogger.logLifecycle(state));
  }

  /// Shows the one-time "still running in the tray" notification on the very
  /// first close-to-tray, so users don't assume the app quit.
  Future<void> _maybeShowTrayNotice() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    // Capture strings before the async gap — the hidden window keeps the
    // tree alive, but reading the context after awaits is fragile.
    final title = l10n.trayNoticeTitle;
    final body = l10n.trayNoticeBody;
    if (await TrayNotice.claimFirstHide()) {
      await DeadlineNotificationService().showSimpleNotification(title, body);
    }
  }

  @override
  void onWindowClose() async {
    final closeToTray = ref.read(closeToTrayProvider);

    if (!kIsWeb && Platform.isMacOS) {
      // Dev convenience: always fully quit on debug builds rather than
      // lingering in the background between hot restarts.
      if (kDebugMode) {
        await quitApp();
        return;
      }
      if (closeToTray) {
        await windowManager.hide();
        unawaited(_maybeShowTrayNotice());
        return;
      }
      // closeToTray disabled: fall through to the shared quit-warning flow.
    } else if (!kIsWeb && closeToTray) {
      await windowManager.hide();
      unawaited(_maybeShowTrayNotice());
      return;
    }

    // Show quit-warning dialog (Windows/Linux always; macOS only when the
    // user has turned closeToTray off).
    final warn = ref.read(warnBeforeQuitProvider);
    if (!warn) {
      await quitApp();
      return;
    }
    final context = navigatorKey.currentContext;
    if (context == null) {
      await quitApp();
      return;
    }
    final confirmed = await showQuitConfirmDialog(context);
    if (confirmed == true) await quitApp();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final currentLocale = ref.watch(localeProvider);

    // Keep window background colour in sync with the active theme (macOS only)
    if (!kIsWeb && Platform.isMacOS) {
      // activeThemeProvider, not the selected id — editing the colors of the
      // theme that is already selected has to move the window background too.
      ref.listen(activeThemeProvider, (_, next) {
        windowManager.setBackgroundColor(_bgForTheme(next));
      });
    }

    // Taskbar badges (Windows only)
    if (!kIsWeb && Platform.isWindows) {
      // Overlay icon: reflects session active/paused state
      ref.listen(activeProjectProvider, (_, project) {
        final isPaused = ref.read(workTimerPausedProvider);
        _updateTaskbarStatus(hasSession: project != null, isPaused: isPaused);
      });
      ref.listen(workTimerPausedProvider, (_, isPaused) {
        final project = ref.read(activeProjectProvider);
        _updateTaskbarStatus(hasSession: project != null, isPaused: isPaused);
      });
      // Progress bar: indeterminate while scanning, cleared when done
      ref.listen(initialScanStateProvider, (_, isScanning) {
        try {
          if (isScanning) {
            _taskbarChannel.invokeMethod('SetProgressMode', <String, Object?>{
              'mode': 0x1,
            }); // indeterminate
          } else {
            _taskbarChannel.invokeMethod('SetProgressMode', <String, Object?>{
              'mode': 0x0,
            }); // noProgress
          }
        } catch (_) {}
      });
      // Thumbnail toolbar: a single hover-preview play/pause button —
      // reflects the desktop preview player, not the work-session timer.
      // One listener on the derived state, not one per input provider: the
      // two inputs change together, and pushing twice per user action is what
      // first drew attention to this path (#119).
      //
      // Currently disabled — see kThumbnailToolbarEnabled. The controller
      // ignores updates while off, so this listener would be harmless, but
      // there is no reason to keep a subscription alive that can only ever
      // no-op.
      if (kThumbnailToolbarEnabled) {
        ref.listen(
          thumbnailToolbarStateProvider,
          (_, next) => _thumbnailToolbar.update(next),
        );
      }
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DAW Project Manager',
      theme: themeData,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('pt', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('it', ''),
        Locale('de', ''),
        Locale('ru', ''),
        Locale('ja', ''),
        Locale('zh', ''),
      ],
      locale: currentLocale,
      // MacOSMenuBar must build with a context that has localizations — placing
      // it in builder ensures it runs after MaterialApp installs its delegates.
      builder: (context, child) => Shortcuts(
        shortcuts: const {
          // macOS: Cmd+← (standard back in macOS apps)
          SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true):
              _BackIntent(),
          // Windows / Linux: Alt+← (standard back in browsers and file managers)
          SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
              _BackIntent(),
        },
        child: Actions(
          actions: {
            _BackIntent: CallbackAction<_BackIntent>(
              onInvoke: (_) {
                navigatorKey.currentState?.maybePop();
                return null;
              },
            ),
          },
          child: MacOSMenuBar(child: child ?? const SizedBox()),
        ),
      ),
      navigatorObservers: [appRouteObserver],
      home: ref.watch(onboardingCompleteProvider)
          ? const DashboardPage()
          : const OnboardingWizardPage(),
    );
  }
}
