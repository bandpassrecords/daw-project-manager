import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'mobile_utils.dart';

/// The directory name a shipping release stores its library under.
const String defaultAppDataDirName = 'daw_project_manager';

/// Compile-time override of the app-data directory name, set with
/// `--dart-define=DPM_DATA_DIR=…`.
///
/// CI passes this for pull-request builds so a build handed to a tester can
/// never write into the library of the stable app they already have
/// installed. Compile-time rather than an environment variable so it behaves
/// the same however the app is launched, and cannot be inherited by accident.
const String _dataDirOverride = String.fromEnvironment('DPM_DATA_DIR');

/// Everything the app stores on disk — Hive boxes, preview songs, release
/// artwork, profile photos, crash logs — hangs off this one name, so changing
/// it moves the whole library in one step.
///
/// Debug and profile builds get their own directory by default: running from
/// the IDE against the installed app's data is how a newly added Hive type
/// ends up in a box the released build cannot read.
String get appDataDirName => _runtimeDirName ??
    resolveAppDataDirName(override: _dataDirOverride, isRelease: kReleaseMode);

/// Set by the startup library picker in dev builds. Null until chosen.
String? _runtimeDirName;

/// Whether this build may ask which library to open at startup.
///
/// Never in a release build, and never when [_dataDirOverride] pinned it: a
/// pull-request build handed to a tester must not offer them the library of
/// the stable app they already have installed, which is the whole point of
/// pinning it.
bool get canPickAppDataDir => !kReleaseMode && _dataDirOverride.isEmpty;

/// Whether `--dart-define=DPM_DATA_DIR=…` pinned this build to a library of
/// its own.
///
/// A pinned build is the one case that ends up with no in-app trace of which
/// library it opened: it never sees the startup picker, and the Settings card
/// that names the library in use is gated on [canPickAppDataDir] too. So it
/// is the case worth warning the person running it about — see
/// `showPinnedLibraryWarningDialog`. Never true in a shipping release, which
/// passes no override.
bool get isAppDataDirPinned => resolveIsAppDataDirPinned(_dataDirOverride);

/// Whether [override] really pins a library, i.e. whether anything survives
/// sanitizing. `--dart-define=DPM_DATA_DIR=..` is non-empty but pins nothing.
///
/// Pure — exposed for testing.
@visibleForTesting
bool resolveIsAppDataDirPinned(String override) =>
    _sanitizeAppDataDirName(override).isNotEmpty;

/// Points this run at [dirName]. Must be called before anything resolves a
/// path — everything downstream (Hive boxes, preview songs, artwork) is
/// derived from it and several are opened during startup.
void selectAppDataDir(String dirName) {
  if (!canPickAppDataDir) {
    throw StateError(
      'The app-data directory is fixed in this build and cannot be chosen at '
      'runtime.',
    );
  }
  _runtimeDirName =
      resolveAppDataDirName(override: dirName, isRelease: kReleaseMode);
}

/// The loopback port the Windows single-instance guard binds.
///
/// A second launch that finds this port taken concludes the app is already
/// running, hands its arguments to the instance that holds it, and exits.
/// That is right for two copies of the *same* library and wrong for a build
/// pinned to its own one: a PR build handed to a tester would be bounced
/// into the stable app they already have open, never starting at all — so
/// an isolated build gets its own port and can run alongside it.
int get singleInstancePort =>
    resolveSingleInstancePort(appDataDirName, isolated: isUsingIsolatedAppData);

/// The port a shipping release binds. Isolated builds derive their own from
/// [resolveSingleInstancePort] instead.
const int defaultSingleInstancePort = 57321;

/// Resolves the single-instance port for [dirName].
///
/// Isolated builds hash the directory name into the IANA dynamic/private
/// range, deliberately stopping below [defaultSingleInstancePort] so a
/// derived port can never collide with the real library's. Deterministic, so
/// the same build binds the same port on every launch — a port that moved
/// between runs would make each launch look like a first one and defeat the
/// guard for that build entirely.
///
/// Pure — exposed for testing.
@visibleForTesting
int resolveSingleInstancePort(String dirName, {required bool isolated}) {
  if (!isolated) return defaultSingleInstancePort;
  var hash = 0;
  for (final unit in dirName.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return 49152 + (hash % 8000);
}

/// Test-only: drop a runtime selection made by an earlier test.
@visibleForTesting
void resetSelectedAppDataDir() => _runtimeDirName = null;

/// Whether this build is pointed somewhere other than the real library, and
/// so will look empty on first run. Worth surfacing in the UI.
bool get isUsingIsolatedAppData => appDataDirName != defaultAppDataDirName;

/// Resolution order: explicit override, then build mode.
///
/// The override is reduced to safe filename characters — it ends up as a path
/// segment, and `..` or a separator in it would escape the app-data root.
@visibleForTesting
String resolveAppDataDirName({
  required String override,
  required bool isRelease,
}) {
  final sanitized = _sanitizeAppDataDirName(override);
  if (sanitized.isNotEmpty) return sanitized;
  return isRelease ? defaultAppDataDirName : '${defaultAppDataDirName}_dev';
}

/// Reduces [override] to safe filename characters — it ends up as a path
/// segment, and `..` or a separator in it would escape the app-data root.
String _sanitizeAppDataDirName(String override) => override
    // Anything that could act as a separator is dropped outright…
    .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '')
    // …and leading dots go too, so what is left of a traversal attempt is a
    // plain name rather than '..' or '....'.
    .replaceAll(RegExp(r'^\.+'), '')
    .trim();

/// Static flag to track if Hive has been initialized
bool _hiveInitialized = false;

/// Initializes Hive only once to prevent multiple initializations and lock conflicts
/// This should be called before any Hive operations
Future<void> ensureHiveInitialized() async {
  if (_hiveInitialized) {
    if (kDebugMode) print('Hive already initialized, skipping...');
    return;
  }

  // Under `flutter test`, never fall back to the real on-disk app-data
  // directory. This flag only tracks "has *this* function called
  // Hive.init()", not whether Hive itself is already initialized — so the
  // first test (in a process that may run many test files) to reach this
  // function via some provider's fire-and-forget _load() would otherwise
  // silently call Hive.init(realAppDataPath), redirecting every later
  // Hive.openBox() in that process to the developer's actual app data,
  // even if an earlier test file had already called Hive.init(tempDir)
  // itself. A test that needs Hive must call Hive.init(tempDir) itself
  // (see HiveTestHelper.setUp); anything else silently no-ops here instead
  // of touching real user data.
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    _hiveInitialized = true;
    return;
  }

  try {
    final appDataPath = await getLocalAppDataPath();
    Hive.init(appDataPath);
    _hiveInitialized = true;
    if (kDebugMode) print('Hive initialized at: $appDataPath');
  } catch (e) {
    if (kDebugMode) print('Error initializing Hive: $e');
    // If init fails, try to continue anyway - might be already initialized
    _hiveInitialized = true;
  }
}

/// The OS application-support directory itself (on Windows: `%LOCALAPPDATA%`),
/// unscoped and independent of any runtime library selection.
///
/// The dev-build candidate libraries — and the startup picker's
/// remembered-choice file — all live directly under this. It is deliberately
/// NOT derived from [getLocalAppDataPath]: that resolves to a path *inside*
/// the chosen library and moves up a level once a non-isolated (release)
/// library is selected, which made the picker write its choice to one
/// directory and the settings card look for it in another.
Future<Directory> getAppSupportRoot() async {
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) return Directory(localAppData);
  }
  return getApplicationSupportDirectory();
}

/// Gets the LocalAppData directory path for the application.
/// On Windows, this returns %LocalAppData%\[appDataDirName]
/// On other platforms, it returns the application support directory — with
/// [appDataDirName] appended when this build is isolated, since the support
/// directory itself is fixed by the OS bundle id.
Future<String> getLocalAppDataPath() async {
  if (Platform.isWindows) {
    // On Windows, use LOCALAPPDATA environment variable
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final appDir = Directory(path.join(localAppData, appDataDirName));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir.path;
    }
    // Fallback to application support directory if LOCALAPPDATA is not available
    return _appSupportPath();
  } else {
    // On other platforms, use application support directory
    return _appSupportPath();
  }
}

Future<String> _appSupportPath() async {
  final appSupportDir = await getApplicationSupportDirectory();
  if (!isUsingIsolatedAppData) return appSupportDir.path;
  final scoped = Directory(path.join(appSupportDir.path, appDataDirName));
  if (!await scoped.exists()) {
    await scoped.create(recursive: true);
  }
  return scoped.path;
}

/// Gets the path for release files storage
Future<String> getReleaseFilesPath(String releaseId) async {
  final basePath = await getLocalAppDataPath();
  return path.join(basePath, 'release_files', releaseId);
}

/// Gets the path for release artwork storage
Future<String> getReleaseArtworkPath() async {
  final basePath = await getLocalAppDataPath();
  return path.join(basePath, 'release_artwork');
}

/// Gets the path for per-project cover art storage (#110).
///
/// Managed copies live here — the picker copies the chosen image in rather
/// than pointing at wherever the user had it, so moving or deleting the
/// original doesn't blank the cover, and Drive sync/local backup have one
/// place to look.
Future<String> getProjectCoverArtPath() async {
  final basePath = await getLocalAppDataPath();
  return path.join(basePath, 'project_cover_art');
}

/// Gets the path for preview songs storage
/// On mobile, this uses the application documents directory for persistence
/// On desktop, this uses the app data directory
Future<String> getPreviewSongsPath() async {
  if (MobileUtils.isMobile()) {
    // On mobile, use application documents directory for persistent storage
    // This ensures preview songs are not deleted by the system
    final appDocDir = await getApplicationDocumentsDirectory();
    final previewSongsDir = Directory(path.join(appDocDir.path, 'preview_songs'));
    if (!await previewSongsDir.exists()) {
      await previewSongsDir.create(recursive: true);
    }
    return previewSongsDir.path;
  } else {
    // On desktop, use app data directory
    final basePath = await getLocalAppDataPath();
    final previewSongsDir = Directory(path.join(basePath, 'preview_songs'));
    if (!await previewSongsDir.exists()) {
      await previewSongsDir.create(recursive: true);
    }
    return previewSongsDir.path;
  }
}

/// Gets the path where placeholder project files for the demo/screenshot
/// profile are created, so real DAW project files exist on disk (avoiding
/// the "source file not found" warning) without touching the user's own
/// project folders.
Future<String> getDemoProjectsPath() async {
  final basePath = await getLocalAppDataPath();
  final demoProjectsDir = Directory(path.join(basePath, 'demo_projects'));
  if (!await demoProjectsDir.exists()) {
    await demoProjectsDir.create(recursive: true);
  }
  return demoProjectsDir.path;
}

