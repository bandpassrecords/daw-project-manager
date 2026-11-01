import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../generated/l10n/app_localizations.dart';
import '../main.dart' show navigatorKey, quitApp;
import '../providers/providers.dart';
import 'google_drive_sync_service.dart';

/// Runs the desktop system tray icon (Windows/Linux) / menu bar icon (macOS)
/// so background services (auto-backup, deadline notifications) can keep
/// running while the window is hidden, per [closeToTrayProvider].
class TrayService with TrayListener {
  TrayService(this._container, this._syncService);

  final ProviderContainer _container;
  final GoogleDriveSyncService _syncService;

  bool _initialized = false;
  bool _iconShown = false;
  StreamSubscription<bool>? _authStateSubscription;
  ProviderSubscription<bool>? _iconVisibilitySubscription;

  /// Left click opens the menu on macOS, as a menu bar item does everywhere
  /// else there; Windows and Linux keep it for bringing the window back.
  static bool leftClickOpensMenu({required bool isMacOS}) => isMacOS;

  /// Only macOS can hide the icon (the Dock still leads back into the app).
  static bool iconCanBeHidden({required bool isMacOS}) => isMacOS;

  /// Whether the icon should be on screen for this setting.
  static bool iconVisible({required bool isMacOS, required bool setting}) =>
      !iconCanBeHidden(isMacOS: isMacOS) || setting;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    trayManager.addListener(this);
    if (iconVisible(
        isMacOS: Platform.isMacOS,
        setting: _container.read(showMenuBarIconProvider))) {
      await _showIcon();
    }
    // tray_manager's Linux plugin only implements destroy/setIcon/setTitle/
    // setContextMenu — setToolTip isn't handled there and throws
    // MissingPluginException. Left unguarded, that used to abort init()
    // before the postFrameCallback below was ever registered, so the tray
    // icon appeared (setIcon had already succeeded) but never got a context
    // menu attached — every click, left or right, did nothing.
    // Localized labels need a BuildContext, which isn't ready until the
    // first frame — build the real menu right after that.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_rebuildMenu()));
    // The tray's GoogleDriveSyncService is a separate instance from the one
    // the sign-in UI uses, so it doesn't see sign-in/out unless notified.
    _authStateSubscription =
        GoogleDriveSyncService.authStateStream.listen(_handleAuthStateChanged);
    _iconVisibilitySubscription = _container.listen<bool>(
      showMenuBarIconProvider,
      (_, _) => unawaited(_applyIconVisibility()),
    );
  }

  Future<void> _showIcon() async {
    await trayManager.setIcon(Platform.isWindows ? 'app_icon.ico' : 'app_icon.png');
    try {
      await trayManager.setToolTip('DAW Project Manager');
    } catch (_) {}
    _iconShown = true;
  }

  Future<void> _applyIconVisibility() async {
    final visible = iconVisible(
      isMacOS: Platform.isMacOS,
      setting: _container.read(showMenuBarIconProvider),
    );
    if (visible == _iconShown) return;
    if (visible) {
      await _showIcon();
      await _rebuildMenu();
    } else {
      await trayManager.destroy();
      _iconShown = false;
    }
  }

  Future<void> _handleAuthStateChanged(bool signedIn) async {
    if (signedIn && !_syncService.isSignedIn) {
      await _syncService.restoreSession();
    } else if (!signedIn && _syncService.isSignedIn) {
      _syncService.forgetLocalSession();
    }
    await _rebuildMenu();
  }

  AppLocalizations? get _l10n {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    return AppLocalizations.of(context);
  }

  /// Formats when the last backup happened, for the tray's status line.
  /// Exposed for testing.
  static String formatLastBackupLabel(DateTime timestamp) =>
      DateFormat('MMM d, HH:mm').format(timestamp.toLocal());

  Future<void> _rebuildMenu() async {
    final l10n = _l10n;
    if (l10n == null) return;

    final project = _container.read(activeProjectProvider);
    final paused = _container.read(workTimerPausedProvider);

    DateTime? lastSynced;
    SyncFailure? failure;
    if (GoogleDriveSyncService.isSupported) {
      try {
        lastSynced = await _syncService.getLastSyncedAt() ??
            await _syncService.getLastBackupUploadTimestamp();
        failure = await _syncService.getLastFailure();
      } catch (_) {}
    }

    final items = <MenuItem>[
      MenuItem(key: 'show', label: l10n.trayShowWindow),
      // Drive backup status/action — not offered inside Flatpak, see
      // GoogleDriveSyncService.isSupported. Omitted rather than shown
      // permanently disabled, since there's no way it could ever become
      // available in that sandbox.
      if (GoogleDriveSyncService.isSupported) ...[
        MenuItem.separator(),
        MenuItem(
          key: 'backup_status',
          label: failure != null
              ? l10n.trayLastSyncFailed(formatLastBackupLabel(failure.at))
              : lastSynced != null
                  ? l10n.trayLastBackup(formatLastBackupLabel(lastSynced))
                  : l10n.trayNeverBackedUp,
          disabled: true,
        ),
        MenuItem(
          key: 'backup_now',
          label: l10n.trayBackupNow,
          disabled: !_syncService.isSignedIn,
        ),
      ],
    ];

    if (project != null) {
      items.add(MenuItem.separator());
      items.add(MenuItem(
        key: 'toggle_session',
        label: paused ? l10n.trayResumeSession : l10n.trayPauseSession,
      ));
    }

    if (iconCanBeHidden(isMacOS: Platform.isMacOS)) {
      items.add(MenuItem.separator());
      items.add(MenuItem(key: 'hide_icon', label: l10n.trayHideIcon));
    }

    items.add(MenuItem.separator());
    items.add(MenuItem(key: 'quit', label: l10n.menuQuit));

    await trayManager.setContextMenu(Menu(items: items));
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// The tray's "Sync now": the same merge-then-upload as everywhere else
  /// (it used to overwrite Drive outright, ignoring the auto-detected
  /// preview songs setting), reported on [driveSyncStatusProvider] so a
  /// failure shows on the dashboard and in this menu's status line.
  Future<void> _runManualBackup() async {
    try {
      await _container.read(driveSyncStatusProvider.notifier).syncNow();
    } catch (e) {
      if (kDebugMode) print('[TrayService] Sync failed: $e');
    } finally {
      await _rebuildMenu();
    }
  }

  @override
  void onTrayIconMouseDown() {
    if (leftClickOpensMenu(isMacOS: Platform.isMacOS)) {
      _popUpMenu();
    } else {
      unawaited(_showWindow());
    }
  }

  @override
  void onTrayIconRightMouseDown() => _popUpMenu();

  void _popUpMenu() {
    unawaited(_rebuildMenu().then((_) => trayManager.popUpContextMenu()));
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        unawaited(_showWindow());
        break;
      case 'backup_now':
        unawaited(_runManualBackup());
        break;
      case 'toggle_session':
        final notifier = _container.read(workTimerProvider.notifier);
        if (_container.read(workTimerPausedProvider)) {
          notifier.resume();
        } else {
          notifier.pause();
        }
        break;
      case 'hide_icon':
        unawaited(_container.read(showMenuBarIconProvider.notifier).set(false));
        break;
      case 'quit':
        unawaited(quitApp());
        break;
    }
  }

  Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _iconVisibilitySubscription?.close();
    _iconVisibilitySubscription = null;
    trayManager.removeListener(this);
  }
}
