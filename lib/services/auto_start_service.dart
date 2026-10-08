import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:launch_at_startup/launch_at_startup.dart';

import '../utils/windows_install.dart';

/// Command-line flag the OS passes back to us on an auto-start launch when
/// the user asked to start minimized. Baked into the registry value /
/// .desktop `Exec=` / LaunchAgent plist at registration time, and read by
/// `main()` to decide whether to show the window.
///
/// Deliberately not `--minimized` alone in the launch path check: a manual
/// launch never carries it, which is the whole point — "start minimized"
/// must only apply to the login launch, not to the user double-clicking the
/// app.
const String kStartMinimizedFlag = '--minimized';

/// Indirection over the OS-level "launch at login" registration so the
/// provider can be unit-tested without touching the Windows registry or the
/// macOS LaunchAgent plist. [AutoStartService.backend] is swapped for a fake
/// in tests.
abstract class AutoStartBackend {
  Future<void> setup({required bool minimized});
  Future<bool> isEnabled();
  Future<bool> enable();
  Future<bool> disable();
}

/// Real backend, delegating to `launch_at_startup`:
/// - Windows: `HKCU\...\CurrentVersion\Run` (or a Startup-folder shortcut when
///   running from an MSIX install, which is why [kMsixPackageName] must match
///   `msix_config.identity_name` in pubspec.yaml).
/// - macOS: a login item registered through the plugin's method channel,
///   which `macos/Runner/MainFlutterWindow.swift` answers.
/// - Linux: a `.desktop` file in `~/.config/autostart`.
class _LaunchAtStartupBackend implements AutoStartBackend {
  // Same channel launch_at_startup's macOS backend talks on.
  static const _macChannel = MethodChannel('launch_at_startup');

  /// launch_at_startup only detects an MSIX install by matching
  /// [kMsixPackageName] against the resolved executable path, the same test
  /// as [isRunningAsMsix]. A mismatch would make it write a Run registry
  /// entry that a packaged (containerized) install cannot honour, and using
  /// the same test keeps the quoting decision below on the path it takes.
  bool get _isMsix => isRunningAsMsix;

  @override
  Future<void> setup({required bool minimized}) async {
    var appPath = Platform.resolvedExecutable;

    // On the Windows registry path the package builds the value as
    // "$appPath $args", unquoted. Without quotes an install under
    // "C:\Program Files\..." is ambiguous once an argument follows it, so
    // quote it ourselves. Not for MSIX: there appPath is interpolated into a
    // PowerShell string that already quotes it, and double-quoting breaks
    // the generated shortcut.
    if (Platform.isWindows && !_isMsix && appPath.contains(' ')) {
      appPath = '"$appPath"';
    }

    launchAtStartup.setup(
      // On Windows this string is the registry value name, so it must stay
      // stable across releases — changing it would orphan the old entry and
      // leave the app registered twice.
      appName: 'DAW Project Manager',
      appPath: appPath,
      packageName: kMsixPackageName,
      args: minimized ? const [kStartMinimizedFlag] : const [],
    );

    // launch_at_startup's macOS backend drops `args` entirely — it only ever
    // sends an on/off bool over the channel. Tell the native side separately
    // so it can pick a registration mechanism that can carry the flag (see
    // MainFlutterWindow.swift).
    if (Platform.isMacOS) {
      await _macChannel.invokeMethod<void>(
        'launchAtStartupSetLaunchMinimized',
        {'minimized': minimized},
      );
    }
  }

  @override
  Future<bool> isEnabled() => launchAtStartup.isEnabled();

  @override
  Future<bool> enable() => launchAtStartup.enable();

  @override
  Future<bool> disable() => launchAtStartup.disable();
}

/// Desktop-only "start the app when I sign in" registration.
///
/// Every method is failure-tolerant: registering at login touches the
/// registry / the filesystem / a native channel, all of which can fail for
/// reasons the user can't act on (locked-down machine, sandboxed install,
/// plugin missing on an unsupported platform). None of that should break a
/// settings toggle, so failures are logged in debug and reported as `false`.
class AutoStartService {
  AutoStartService._();

  @visibleForTesting
  static AutoStartBackend backend = _LaunchAtStartupBackend();

  /// Resets [backend] to the real implementation. For tests that swap it.
  @visibleForTesting
  static void resetBackend() => backend = _LaunchAtStartupBackend();

  /// Launch-at-login only exists on desktop. Mobile OSes don't let an app
  /// register itself to start at boot, so the whole feature is hidden there.
  static bool get isSupported =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Whether this process was launched by the OS's auto-start mechanism with
  /// the "start minimized" flag. Only ever true on a login launch.
  static bool launchedMinimized(List<String> args) =>
      isSupported && args.contains(kStartMinimizedFlag);

  // Tracked rather than a plain bool: the arguments are baked in at setup()
  // time, so a change to `minimized` has to re-run setup before the next
  // enable() or the registration would keep the stale flag.
  static bool? _setUpMinimized;

  /// Must run before any other call. Cheap to call repeatedly — it only does
  /// work when [minimized] differs from the last setup.
  static Future<void> setup({required bool minimized}) async {
    if (!isSupported || _setUpMinimized == minimized) return;
    try {
      await backend.setup(minimized: minimized);
      _setUpMinimized = minimized;
    } catch (e) {
      if (kDebugMode) print('[AutoStartService] setup failed: $e');
    }
  }

  /// Whether the OS currently has the app registered to launch at login.
  static Future<bool> isEnabled() async {
    if (!isSupported) return false;
    try {
      return await backend.isEnabled();
    } catch (e) {
      if (kDebugMode) print('[AutoStartService] isEnabled failed: $e');
      return false;
    }
  }

  /// Registers or unregisters the app. Returns whether the OS state ended up
  /// matching [value] — a `false` return means the toggle didn't take effect
  /// and the caller should not persist [value] as the user's preference.
  static Future<bool> setEnabled(bool value) async {
    if (!isSupported) return false;
    try {
      return value ? await backend.enable() : await backend.disable();
    } catch (e) {
      if (kDebugMode) print('[AutoStartService] setEnabled($value) failed: $e');
      return false;
    }
  }

  /// Rewrites an existing registration so it picks up a changed [minimized]
  /// flag. Unregisters first because the flag lives *inside* the registration
  /// (registry value / Exec= line / plist) and, on macOS, changing it can
  /// even change which mechanism is used — so re-enabling over the top would
  /// either no-op or leave the old one behind.
  static Future<bool> reapply({required bool minimized}) async {
    if (!isSupported) return false;
    try {
      await backend.disable();
      _setUpMinimized = null;
      await setup(minimized: minimized);
      return await backend.enable();
    } catch (e) {
      if (kDebugMode) print('[AutoStartService] reapply failed: $e');
      return false;
    }
  }

  @visibleForTesting
  static void resetSetupFlagForTest() => _setUpMinimized = null;
}
