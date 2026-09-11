import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:daw_project_manager/utils/mobile_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/custom_theme.dart';
import '../models/profile.dart';
import '../models/music_project.dart';
import '../models/project_attachment.dart';
import '../models/project_marker.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../models/scan_root.dart';
import '../models/todo_item.dart';
import '../models/todo_template.dart';
import '../models/part_template.dart';
import '../models/project_part.dart';
import '../models/project_template.dart';
import '../models/template_root.dart';
import '../models/backup_progress.dart';
import '../repository/profile_repository.dart';
import '../repository/project_repository.dart';
import 'custom_theme_merge.dart';
import '../utils/app_paths.dart'
    show
        appDataDirName,
        ensureHiveInitialized,
        getLocalAppDataPath,
        getPreviewSongsPath,
        getProjectCoverArtPath,
        getReleaseArtworkPath,
        isUsingIsolatedAppData;
import '../config/oauth_config.dart' show desktopClientSecret, desktopClientId, androidWebClientId;

/// Exception thrown when user cancels an upload operation
class UploadCancelledException implements Exception {
  final String message;
  UploadCancelledException([this.message = 'Upload cancelled by user']);
  
  @override
  String toString() => message;
}

/// Service for synchronizing database data with Google Drive
class GoogleDriveSyncService {
  /// Whether Drive sync can be offered on this platform at all.
  ///
  /// False only inside a Flatpak sandbox — not on Linux generally. The
  /// desktop OAuth flow (see signInDesktopWithLoopback below) requires a
  /// client secret — Google's token endpoint rejects the exchange without
  /// one for this app's "Desktop app" OAuth client type, even with PKCE
  /// (verified against a live Google sign-in attempt; see the
  /// PKCE-removal revert in git history for the investigation). That's fine
  /// for Windows/macOS/the Linux tarball/AppImage, which all get the real
  /// secret injected from this repo's own private CI (see `build_linux` in
  /// release.yml) — none of them ever distribute the secret outside that
  /// trusted pipeline. It's specifically Flathub that can't have it: its
  /// build sandbox has no secret-injection mechanism at all, so the file
  /// would have to be committed in the open in the public Flathub submission
  /// repo. Rather than ship a secret that broadly, Drive sync is disabled
  /// only when actually running inside the Flatpak sandbox, detected via the
  /// `/.flatpak-info` marker file every Flatpak app has at runtime — see
  /// flatpak/README.md and CLAUDE.md for the rest of that story, and
  /// BackupService for the local-file backup/restore Flatpak uses instead.
  static bool get isSupported => !_isFlatpakSandbox;

  static bool get _isFlatpakSandbox => isFlatpakSandboxFor(
        isLinux: Platform.isLinux,
        flatpakInfoExists: Platform.isLinux && File('/.flatpak-info').existsSync(),
      );

  /// Pure predicate behind [_isFlatpakSandbox], split out so the actual
  /// decision logic is unit-testable without needing to run inside a real
  /// Flatpak sandbox (mirrors looksLikeFlatpakPortalPath in
  /// settings_page.dart, the existing precedent for this kind of check).
  @visibleForTesting
  static bool isFlatpakSandboxFor({
    required bool isLinux,
    required bool flatpakInfoExists,
  }) =>
      isLinux && flatpakInfoExists;

  /// Drive folder this build syncs into.
  ///
  /// An isolated build (a pull-request build handed to a tester, or a local
  /// dev run — see [appDataDirName]) gets its own folder. Without this, a
  /// tester signing in from a PR build would overwrite the real
  /// `database_backup.json` of the stable app they already use: isolating the
  /// on-disk library alone would still leave their cloud backup exposed.
  static String get _appDataFolderName => isUsingIsolatedAppData
      ? 'DAW Project Manager ($appDataDirName)'
      : 'DAW Project Manager';
  static const String _databaseFileName = 'database_backup.json';
  static const String _metadataFileName = 'sync_metadata.json';
  static const String _credentialsStorageKey = 'google_drive_credentials_json';
  static const String _backupTimestampBoxName = 'backup_timestamps';
  
  bool _isInitialized = false;
  bool _isAuthenticated = false; // has granted permissions?
  GoogleSignInAccount? _currentUser; // Current signed-in user
  drive.DriveApi? _driveApi;
  String? _appDataFolderId;
  auth_io.AutoRefreshingAuthClient? _desktopAuthClient; // For desktop OAuth
  Box<String>? _backupTimestampBox; // For storing last backup download timestamp
  StreamSubscription? _authEventsSubscription; // Listen to authentication events
  static bool _sessionInitialized = false; // Track if lightweight auth was attempted this session

  static final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  /// Stream that emits the new isSignedIn value whenever auth state changes.
  static Stream<bool> get authStateStream => _authStateController.stream;

  // Stream controller for backup progress
  final _progressController = StreamController<BackupProgress>.broadcast();
  Stream<BackupProgress> get progressStream => _progressController.stream;

  // Matches local backup-download filenames like "{uuid}_preview.wav" — not real display names
  static final _uuidPreviewRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_preview\.',
    caseSensitive: false,
  );
  
  // Cancellation flag for backup uploads
  bool _isCancelled = false;

  // Per-merge hash cache: path → MD5 hex. Cleared at the start of each mergeData() call
  // so the same local file is only read from disk once per sync operation.
  final Map<String, String> _mergeHashCache = {};

  // Warnings from the most recent upload (files that failed to upload).
  // Cleared at the start of each uploadDatabase() call.
  List<String> _lastUploadWarnings = [];
  List<String> get lastUploadWarnings => List.unmodifiable(_lastUploadWarnings);
  
  // Cancel current upload operation
  void cancelUpload() {
    _isCancelled = true;
  }
  
  // Public getters for user state (following official example)
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn {
    if (MobileUtils.isMobile()) {
      return _currentUser != null && _isAuthenticated;
    }
    return _desktopAuthClient != null && _driveApi != null;
  }
  
  // Public getters for desktop flow
  drive.DriveApi? get driveApi => _driveApi;
  set driveApi(drive.DriveApi? api) => _driveApi = api;
  auth_io.AutoRefreshingAuthClient? get desktopAuthClient => _desktopAuthClient;
  set desktopAuthClient(auth_io.AutoRefreshingAuthClient? client) => _desktopAuthClient = client;

  // Desktop Client ID - loaded from oauth_config.dart (injected during build or from local file)
  // The ID is obfuscated (base64) and decoded at runtime
  static String get _desktopClientId {
    try {
      // Decode obfuscated client ID (base64)
      final decoded = utf8.decode(base64Decode(desktopClientId));
      return decoded;
    } catch (e) {
      // If decoding fails, assume it's not obfuscated (for backward compatibility)
      if (kDebugMode) print('Warning: Could not decode desktop client ID, using as-is: $e');
      return desktopClientId;
    }
  }
  
  // Desktop Client Secret - loaded from oauth_config.dart (injected during build or from local file)
  // The secret is obfuscated (base64) and decoded at runtime
  static String get _desktopClientSecret {
    try {
      // Decode obfuscated secret (base64)
      final decoded = utf8.decode(base64Decode(desktopClientSecret));
      return decoded;
    } catch (e) {
      // If decoding fails, assume it's not obfuscated (for backward compatibility)
      if (kDebugMode) print('Warning: Could not decode secret, using as-is: $e');
      return desktopClientSecret;
    }
  }
  
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    // Removed drive.appdata since we're using a shared folder in root Drive instead
    // 'https://www.googleapis.com/auth/drive.appdata',
  ];

  // Android Web Client ID - loaded from oauth_config.dart (injected during build or from local file)
  // Google automatically detects debug/release by package name, so only one Client ID is needed
  // The ID is obfuscated (base64) and decoded at runtime
  static String get _androidWebClientId {
    try {
      // Decode obfuscated client ID (base64)
      final decoded = utf8.decode(base64Decode(androidWebClientId));
      return decoded;
    } catch (e) {
      // If decoding fails, assume it's not obfuscated (for backward compatibility)
      if (kDebugMode) print('Warning: Could not decode android web client ID, using as-is: $e');
      return androidWebClientId;
    }
  }

  GoogleDriveSyncService({String? serverClientId}) {
    // In 7.x, GoogleSignIn is a singleton accessed via GoogleSignIn.instance
    // Configuration is done via initialize() method
    // For now, we'll store the serverClientId for use in initialize()
    if (MobileUtils.isMobile()) {
      final webClientId = serverClientId ?? _androidWebClientId;
      if (kDebugMode) {
        print('=== GoogleSignIn Configuration (7.x) ===');
        print('Platform: Android');
        print('Build Mode: ${kDebugMode ? "Debug" : "Release"}');
        print('Server Client ID (Web): $webClientId');
        print('Scopes: $_scopes');
        print('Package name should be: com.bandpassrecords.dpm');
        print('SHA-1 (Debug) should be: 54:AD:3C:3C:49:AE:7B:AF:A1:5D:46:D3:01:F3:6A:4E:0E:34:D4:69');
        print('SHA-1 (Release) should be: 43:79:D2:9B:12:D6:19:91:0B:10:BE:A5:72:17:A2:29:5A:11:72:F7');
        print('Note: Call initialize() before using the service');
        print('===================================');
      }
    }
    // Para Desktop: não usa google_sign_in (não tem implementação)
    // Usaremos googleapis_auth diretamente
  }

  /// Initialize GoogleSignIn (following official example pattern)
  /// In 7.x, this is required before any other methods
  /// Only attempts lightweight auth once per app session
  Future<void> initialize({String? serverClientId, bool forceReinitialize = false}) async {
    if (_isInitialized && !forceReinitialize) {
      return;
    }

    if (MobileUtils.isMobile()) {
      try {
        final webClientId = serverClientId ?? _androidWebClientId;

        final GoogleSignIn signIn = GoogleSignIn.instance;
        unawaited(
          signIn.initialize(
            clientId: null, // Not needed for Android
            serverClientId: webClientId,
          ).then((_) {

            // Listen to authentication events (following official example)
            // Only set up listener once per instance
            if (_authEventsSubscription == null) {
              _authEventsSubscription = signIn.authenticationEvents
                  .listen(_handleAuthenticationEvent);
              _authEventsSubscription?.onError(_handleAuthenticationError);
            } else {
            }

            // Attempt lightweight authentication to restore the current signed-in user.
            // We call this whenever _currentUser is null (i.e. a new instance was created
            // after page navigation) so the auth event fires and populates _currentUser.
            // It's non-interactive, so calling it more than once per session is safe.
            if (!_sessionInitialized || _currentUser == null) {
              signIn.attemptLightweightAuthentication();
              _sessionInitialized = true;
            } else {
            }
          }),
        );

        _isInitialized = true;
      } catch (e) {
        rethrow;
      }
    } else {
      _isInitialized = true; // Desktop doesn't need GoogleSignIn
    }
  }

  /// Handle authentication events (following official example pattern)
  Future<void> _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) async {

    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    if (user != null) {
    } else {
    }

    // authorizationForScopes is a cache-only lookup — returns null when the
    // token is not in the local in-process cache (e.g. after a fresh page load
    // with a new service instance). This is NOT the same as "not authorized".
    GoogleSignInClientAuthorization? authorization = await user
        ?.authorizationClient
        .authorizationForScopes(_scopes);

    _currentUser = user;

    // If the user is identified but we have no cached token, call authorizeScopes()
    // to perform a silent token refresh. For returning users (scopes previously
    // granted) this completes without any UI prompt. Only shows consent UI the
    // very first time scopes are requested.
    if (user != null && authorization == null) {
      try {
        authorization = await user.authorizationClient.authorizeScopes(_scopes);
      } catch (e) {
      }
    }

    _isAuthenticated = authorization != null;

    if (user != null && _isAuthenticated) {
      await _initializeDriveApi(user);
    } else {
      _driveApi = null;
    }
    _authStateController.add(_isAuthenticated);
  }

  /// Handle authentication errors (following official example pattern)
  Future<void> _handleAuthenticationError(Object e) async {
    if (e is GoogleSignInException) {
    } else {
    }
    _currentUser = null;
    _isAuthenticated = false;
    _driveApi = null;
    _authStateController.add(false);
  }

  /// Initialize Drive API with user's authorization
  Future<void> _initializeDriveApi(GoogleSignInAccount user) async {
    try {
      // Get authorization headers (following official example pattern)
      final Map<String, String>? headers = await user.authorizationClient
          .authorizationHeaders(_scopes);
      
      if (headers == null) {
        if (kDebugMode) print('Failed to get authorization headers');
        _driveApi = null;
        return;
      }

      // Create authenticated HTTP client
      final baseClient = http.Client();
      final authenticatedClient = _AuthenticatedHttpClient(baseClient, headers);
      _driveApi = drive.DriveApi(authenticatedClient);
      
      // Ensure app data folder exists
      await ensureAppDataFolder();
      
      if (kDebugMode) print('✓ Drive API initialized successfully');
    } catch (e) {
      if (kDebugMode) print('Error initializing Drive API: $e');
      _driveApi = null;
    }
  }

  /// Dispose resources
  void dispose() {
    _authEventsSubscription?.cancel();
    _authEventsSubscription = null;
    _progressController.close();
  }

  /// Initialize credentials storage (call this before using the service)
  /// No-op kept for API compatibility — credentials are now stored directly
  /// in flutter_secure_storage, removing the fragile Hive AES intermediate layer.
  Future<void> initializeCredentialsStorage() async {}

  /// Initialize backup timestamp storage (local, unencrypted)
  Future<void> _initializeBackupTimestampStorage() async {
    try {
      await ensureHiveInitialized();
      if (!Hive.isBoxOpen(_backupTimestampBoxName)) {
        _backupTimestampBox = await Hive.openBox<String>(_backupTimestampBoxName);
      } else {
        _backupTimestampBox = Hive.box<String>(_backupTimestampBoxName);
      }
    } catch (e) {
      if (kDebugMode) print('Error initializing backup timestamp storage: $e');
    }
  }

  /// Save last backup download timestamp
  Future<void> saveLastBackupDownloadTimestamp(DateTime timestamp) async {
    try {
      await _initializeBackupTimestampStorage();
      if (_backupTimestampBox != null) {
        await _backupTimestampBox!.put('lastDownload', timestamp.toIso8601String());
        if (kDebugMode) print('Saved last backup download timestamp: ${timestamp.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) print('Error saving last backup download timestamp: $e');
    }
  }

  /// Save last backup upload timestamp
  Future<void> saveLastBackupUploadTimestamp(DateTime timestamp) async {
    try {
      await _initializeBackupTimestampStorage();
      if (_backupTimestampBox != null) {
        await _backupTimestampBox!.put('lastUpload', timestamp.toIso8601String());
        if (kDebugMode) print('Saved last backup upload timestamp: ${timestamp.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) print('Error saving last backup upload timestamp: $e');
    }
  }

  /// Get last backup download timestamp
  Future<DateTime?> getLastBackupDownloadTimestamp() async {
    try {
      await _initializeBackupTimestampStorage();
      if (_backupTimestampBox != null) {
        final timestampString = _backupTimestampBox!.get('lastDownload');
        if (timestampString != null) {
          return DateTime.parse(timestampString);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting last backup download timestamp: $e');
      return null;
    }
  }

  /// Get last backup upload timestamp
  Future<DateTime?> getLastBackupUploadTimestamp() async {
    try {
      await _initializeBackupTimestampStorage();
      if (_backupTimestampBox != null) {
        final timestampString = _backupTimestampBox!.get('lastUpload');
        if (timestampString != null) {
          return DateTime.parse(timestampString);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting last backup upload timestamp: $e');
      return null;
    }
  }

  /// Get the most recent local backup timestamp (either upload or download)
  Future<DateTime?> getLastLocalBackupTimestamp() async {
    final lastDownload = await getLastBackupDownloadTimestamp();
    final lastUpload = await getLastBackupUploadTimestamp();
    
    if (lastDownload == null && lastUpload == null) {
      return null;
    } else if (lastDownload == null) {
      return lastUpload;
    } else if (lastUpload == null) {
      return lastDownload;
    } else {
      // Return the most recent one
      return lastDownload.isAfter(lastUpload) ? lastDownload : lastUpload;
    }
  }

  /// Check if remote backup is newer than local
  /// Returns true if remote backup should be downloaded
  Future<bool> isRemoteBackupNewer() async {
    final remoteTimestamp = await getRemoteBackupTimestamp();
    if (remoteTimestamp == null) {
      return false; // No remote backup exists
    }
    
    final localTimestamp = await getLastLocalBackupTimestamp();
    if (localTimestamp == null) {
      return true; // No local backup, so remote is "newer"
    }
    
    // Remote is newer if its timestamp is after local
    return remoteTimestamp.isAfter(localTimestamp);
  }

  /// Get all backup timestamps for display in UI
  Future<Map<String, DateTime?>> getAllBackupTimestamps() async {
    return {
      'lastDownload': await getLastBackupDownloadTimestamp(),
      'lastUpload': await getLastBackupUploadTimestamp(),
      'remote': await getRemoteBackupTimestamp(),
    };
  }

  /// Get remote backup timestamp from Drive
  Future<DateTime?> getRemoteBackupTimestamp() async {
    try {
      if (_driveApi == null || _appDataFolderId == null) {
        return null;
      }

      final response = await _driveApi!.files.list(
        q: "name='$_databaseFileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files == null || response.files!.isEmpty) {
        return null; // No backup file found
      }

      // Get file metadata to check modified time
      // Use modifiedTime from the file in the list response (already available)
      final fileInList = response.files!.first;
      if (fileInList.modifiedTime != null) {
        // modifiedTime comes from Google Drive in UTC, convert to local timezone
        return fileInList.modifiedTime!.toLocal();
      }

      // If modifiedTime not in list response, try to get it explicitly
      try {
        final fileId = fileInList.id!;
        final fileResult = await _driveApi!.files.get(fileId, $fields: 'modifiedTime');
        if (fileResult is drive.File && fileResult.modifiedTime != null) {
          // modifiedTime comes from Google Drive in UTC, convert to local timezone
          return fileResult.modifiedTime!.toLocal();
        }
      } catch (_) {
        // If getting file fails, continue to fallback
      }

      // Fallback: try to download and parse the backup JSON to get timestamp
      try {
        final backupData = await downloadDatabase();
        if (backupData['timestamp'] != null) {
          // Parse and convert to local timezone
          return DateTime.parse(backupData['timestamp'] as String).toLocal();
        }
      } catch (_) {
        // If download fails, return null
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting remote backup timestamp: $e');
      return null;
    }
  }

  /// Check if a newer backup is available on Drive
  /// Returns true if remote backup is newer than last download time
  Future<bool> isNewerBackupAvailable() async {
    try {
      final lastDownload = await getLastBackupDownloadTimestamp();
      final remoteTimestamp = await getRemoteBackupTimestamp();

      if (remoteTimestamp == null) {
        return false; // No backup available on Drive
      }

      if (lastDownload == null) {
        return true; // Never downloaded, so remote backup should be downloaded
      }

      // Remote is newer if it was modified after our last download
      // Add a small buffer (5 seconds) to avoid false positives from clock differences
      final isNewer = remoteTimestamp.isAfter(lastDownload.add(const Duration(seconds: 5)));
      
      if (kDebugMode) {
        print('Backup comparison:');
        print('  Last download: $lastDownload');
        print('  Remote backup: $remoteTimestamp');
        print('  Is newer: $isNewer');
      }
      
      return isNewer;
    } catch (e) {
      if (kDebugMode) print('Error checking if newer backup is available: $e');
      return false;
    }
  }
  
  /// Get backup information for display
  Future<Map<String, dynamic>> getBackupInfo() async {
    try {
      final remoteTimestamp = await getRemoteBackupTimestamp();
      final lastDownload = await getLastBackupDownloadTimestamp();
      final lastUpload = await getLastBackupUploadTimestamp();
      
      // Determine if remote is newer than local download
      bool isNewer = false;
      if (remoteTimestamp != null) {
        if (lastDownload == null) {
          // Never downloaded, so remote backup should be downloaded
          isNewer = true;
        } else {
          // Remote is newer if it was modified after our last download
          isNewer = remoteTimestamp.isAfter(lastDownload.add(const Duration(seconds: 5)));
        }
      }
      
      return {
        'remoteTimestamp': remoteTimestamp,
        'lastDownload': lastDownload,
        'lastUpload': lastUpload,
        'hasRemote': remoteTimestamp != null,
        'isNewer': isNewer,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting backup info: $e');
      return {};
    }
  }

  /// Check if user is signed in (async check) - following official example
  /// Use the getter `isSignedIn` for synchronous check
  Future<bool> checkSignedInStatus() async {
    try {
      if (MobileUtils.isMobile()) {
        if (!_isInitialized) {
          await initialize();
        }

        if (_currentUser != null) {
          try {
            final GoogleSignInClientAuthorization? authorization = await _currentUser!
                .authorizationClient
                .authorizationForScopes(_scopes);
            _isAuthenticated = authorization != null;
            return _isAuthenticated;
          } catch (e) {
            _isAuthenticated = false;
            return false;
          }
        } else {
          _isAuthenticated = false;
          return false;
        }
      } else {
        final result = _desktopAuthClient != null && _driveApi != null;
        return result;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
      return false;
    }
  }

  /// Sign in to Google (following official example pattern)
  /// This method triggers interactive authentication if needed
  /// Following official example: authenticate() is called explicitly
  Future<bool> signIn() async {
    try {
      if (kDebugMode) {
        print('=== Google Sign-In Attempt (following official example) ===');
        print('Platform: ${Platform.operatingSystem}');
      }
      
      if (MobileUtils.isMobile()) {
        // Ensure GoogleSignIn is initialized
        if (!_isInitialized) {
          await initialize();
        }

        // Following official example: authenticate() is called explicitly
        // The authenticationEvents stream will handle the result
        if (GoogleSignIn.instance.supportsAuthenticate()) {
          if (kDebugMode) print('Attempting interactive authentication...');
          try {
            // Authenticate interactively (following official example)
            await GoogleSignIn.instance.authenticate();
            
            // Wait a bit for authenticationEvents to process
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Check if we have a user and authorization
            if (_currentUser != null) {
              // Check for existing authorization (following official example)
              final GoogleSignInClientAuthorization? authorization = await _currentUser!
                  .authorizationClient
                  .authorizationForScopes(_scopes);
              
              if (authorization != null) {
                // Already authorized, initialize Drive API
                await _initializeDriveApi(_currentUser!);
                await ensureAppDataFolder();
                if (kDebugMode) {
                  print('✓ Sign-in complete with existing authorization');
                }
                return true;
              } else {
                // Need to authorize scopes (following official example)
                if (kDebugMode) print('Requesting scope authorization...');
                try {
                  final GoogleSignInClientAuthorization authorization = await _currentUser!
                      .authorizationClient
                      .authorizeScopes(_scopes);
                  
                  // Initialize Drive API with authorization
                  await _initializeDriveApi(_currentUser!);
                  await ensureAppDataFolder();
                  
                  if (kDebugMode) {
                    print('✓ Sign-in complete with new authorization');
                  }
                  return true;
                } on GoogleSignInException catch (e) {
                  if (e.code == GoogleSignInExceptionCode.canceled) {
                    if (kDebugMode) print('User canceled authorization');
                    return false;
                  }
                  if (kDebugMode) {
                    print('✗ ERROR authorizing scopes: ${e.code}: ${e.description}');
                  }
                  rethrow;
                }
              }
            } else {
              if (kDebugMode) print('User cancelled the Google sign-in flow');
              return false;
            }
          } on GoogleSignInException catch (e) {
            if (e.code == GoogleSignInExceptionCode.canceled) {
              if (kDebugMode) print('User canceled authentication');
              return false;
            }
            // Check for developer console setup errors
            if (e.description?.contains('28444') == true || 
                e.description?.contains('Developer console is not set up correctly') == true) {
              if (kDebugMode) {
                print('✗ DEVELOPER CONSOLE CONFIGURATION ERROR:');
                print('  Error code: 28444');
                print('  This means the Android Client ID is not properly configured in Google Cloud Console');
                print('  Verify:');
                print('    1. Android Client ID exists in Google Cloud Console');
                print('    2. Package name: com.bandpassrecords.dpm (exactly)');
                print('    3. SHA-1: 54:AD:3C:3C:49:AE:7B:AF:A1:5D:46:D3:01:F3:6A:4E:0E:34:D4:69 (exactly)');
                print('    4. OAuth Consent Screen - Test users: Email added');
                print('    5. Wait 15-30 minutes after changes');
              }
            }
            if (kDebugMode) {
              print('✗ ERROR during authenticate():');
              print('  Error code: ${e.code}');
              print('  Error: ${e.description}');
            }
            rethrow;
          } catch (e) {
            if (kDebugMode) {
              print('✗ ERROR during authenticate():');
              print('  Error type: ${e.runtimeType}');
              print('  Error: $e');
            }
            rethrow;
          }
        } else {
          if (kDebugMode) print('Platform does not support authenticate()');
          return false;
        }
      } else {
        // Desktop: OAuth2 flow requires manual code entry
        if (kDebugMode) {
          print('Desktop platform detected.');
          print('Desktop sign-in uses loopback flow. Use signInDesktopWithLoopback() instead.');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('✗ ERROR during sign-in:');
        print('  Error type: ${e.runtimeType}');
        print('  Error message: $e');
        print('  Stack trace:');
        print(stackTrace);
      }
      _currentUser = null;
      _isAuthenticated = false;
      rethrow;
    }
  }

  /// Loopback port for desktop OAuth (Google requires a fixed redirect URI in the console).
  /// Add http://127.0.0.1:4567/ to your Desktop OAuth client's authorized redirect URIs.
  static const int _desktopLoopbackPort = 4567;
  static Uri get _desktopRedirectUri =>
      Uri.parse('http://127.0.0.1:$_desktopLoopbackPort/');

  /// xcodebuild -showBuildSettings -project ios/Runner.xcodeproj | grep PRODUCT_BUNDLE_IDENTIFIERon desktop using OAuth2 loopback flow (no manual code entry).
  /// Opens browser; after user consents, Google redirects to a local server and we exchange the code.
  /// Migrated from deprecated OOB flow (urn:ietf:wg:oauth:2.0:oob) per Google's migration guide.
  Future<auth_io.AutoRefreshingAuthClient?> signInDesktopWithLoopback() async {
    final state = _generateState();
    HttpServer? server;
    final codeCompleter = Completer<String?>();

    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, _desktopLoopbackPort);
      if (kDebugMode) print('Loopback server listening on http://127.0.0.1:$_desktopLoopbackPort/');

      server.listen((request) async {
        if (codeCompleter.isCompleted) return;
        final uri = request.uri;
        if (uri.queryParameters.containsKey('code')) {
          final code = uri.queryParameters['code'];
          final returnedState = uri.queryParameters['state'];
          if (returnedState != state) {
            if (kDebugMode) print('State mismatch in OAuth callback');
            request.response
              ..statusCode = 400
              ..headers.contentType = ContentType.html
              ..write(_loopbackResponsePage(
                heading: 'Something went wrong',
                message: 'Invalid sign-in state. Please close this window and try again from DAW Project Manager.',
                isError: true,
              ));
            await request.response.close();
            codeCompleter.complete(null);
            return;
          }
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(_loopbackResponsePage(
              heading: 'Sign-in successful',
              message: 'You can close this window and return to DAW Project Manager.',
            ));
          await request.response.close();
          codeCompleter.complete(code);
        } else if (uri.queryParameters.containsKey('error')) {
          if (kDebugMode) print('OAuth error: ${uri.queryParameters['error']}');
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(_loopbackResponsePage(
              heading: 'Sign-in cancelled',
              message: 'Sign-in was denied or failed. You can close this window and return to DAW Project Manager to try again.',
              isError: true,
            ));
          await request.response.close();
          codeCompleter.complete(null);
        }
      });

      final authUrl = Uri.parse('https://accounts.google.com/o/oauth2/v2/auth').replace(
        queryParameters: {
          'client_id': _desktopClientId,
          'redirect_uri': _desktopRedirectUri.toString(),
          'response_type': 'code',
          'scope': _scopes.join(' '),
          'access_type': 'offline',
          'prompt': 'consent',
          'state': state,
        },
      );

      if (kDebugMode) {
        print('Desktop OAuth2 loopback: opening browser');
        print('Redirect URI: $_desktopRedirectUri');
      }

      final launched = await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        codeCompleter.complete(null);
        return null;
      }

      final code = await codeCompleter.future;
      if (code == null || code.isEmpty) return null;
      return _exchangeDesktopCode(code);
    } on SocketException catch (e) {
      if (kDebugMode) print('Loopback server bind failed (port in use?): $e');
      return null;
    } finally {
      await server?.close(force: true);
    }
  }

  /// HTML page shown in the system browser tab the loopback redirect lands
  /// on — the only feedback the user gets there, since control then returns
  /// to the app via the already-running loopback server, not a deep link.
  /// Styled to match the color palette/typography of the dpm.bandpassrecords.com
  /// marketing site (see styles.css there) rather than an unbranded system page.
  static String _loopbackResponsePage({required String heading, required String message, bool isError = false}) {
    final accent = isError ? '#FF6B6B' : '#4A9EFF';
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>DAW Project Manager</title>
<style>
  :root {
    --bg-darker: #0F1113;
    --bg-card: #2B2D31;
    --text-primary: #FFFFFF;
    --text-secondary: #B0B3B8;
    --border-color: #3C3F43;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
    background: var(--bg-darker);
    color: var(--text-primary);
  }
  main {
    max-width: 420px;
    width: 100%;
    text-align: center;
    padding: 2.5rem 2rem;
    margin: 1.5rem;
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: 12px;
  }
  .icon {
    width: 48px;
    height: 48px;
    margin: 0 auto 1.25rem;
    border-radius: 50%;
    background: $accent;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.5rem;
  }
  h1 {
    font-size: 1.25rem;
    font-weight: 600;
    margin-bottom: 0.75rem;
  }
  p {
    color: var(--text-secondary);
    line-height: 1.6;
    font-size: 0.95rem;
  }
</style>
</head>
<body>
<main>
<div class="icon">${isError ? '!' : '✓'}</div>
<h1>$heading</h1>
<p>$message</p>
</main>
</body>
</html>''';
  }

  static String _generateState() {
    final bytes = sha256.convert(utf8.encode('${DateTime.now().microsecondsSinceEpoch}-$_desktopClientId')).bytes;
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Exchange authorization code for tokens (used by loopback flow; redirect_uri must match).
  Future<auth_io.AutoRefreshingAuthClient?> _exchangeDesktopCode(String code) async {
    try {
      final clientId = auth_io.ClientId(
        _desktopClientId,
        _desktopClientSecret.isEmpty ? null : _desktopClientSecret,
      );

      if (kDebugMode) {
        print('Exchanging authorization code for access token...');
        print('Redirect URI: $_desktopRedirectUri');
      }

      final tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');
      final bodyParams = <String, String>{
        'code': code.trim(),
        'client_id': _desktopClientId,
        'redirect_uri': _desktopRedirectUri.toString(),
        'grant_type': 'authorization_code',
      };
      if (_desktopClientSecret.isNotEmpty) {
        bodyParams['client_secret'] = _desktopClientSecret;
      }
      
      final tokenResponse = await http.post(
        tokenEndpoint,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: bodyParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'),
      );
      
      if (tokenResponse.statusCode != 200) {
        if (kDebugMode) {
          print('Token exchange failed: ${tokenResponse.statusCode}');
          print('Response: ${tokenResponse.body}');
        }
        throw Exception('Token exchange failed: ${tokenResponse.statusCode} - ${tokenResponse.body}');
      }
      
      final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessTokenString = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String?;
      final expiresIn = tokenData['expires_in'] as int? ?? 3600;
      
      if (kDebugMode) {
        print('Access token obtained successfully');
        print('Has refresh token: ${refreshToken != null}');
        print('Token expires in: $expiresIn seconds');
      }
      
      // Create AccessToken object using googleapis_auth
      // AccessCredentials requires an AccessToken object, not a string
      // IMPORTANT: Use expires_in directly without manual buffer calculation
      // The autoRefreshingClient will manage token refresh timing internally,
      // which is safer than manually calculating expiry time (avoids clock sync issues)
      final expiryTime = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
      
      final accessToken = auth_io.AccessToken(
        'Bearer',
        accessTokenString,
        expiryTime,
      );
      
      // Create AccessCredentials using googleapis_auth
      // This follows the recommended pattern for using googleapis_auth
      final credentials = auth_io.AccessCredentials(
        accessToken,
        refreshToken,
        _scopes,
      );
      
      // Create auto-refreshing client using googleapis_auth
      // This client will automatically refresh the token when needed
      // This is the recommended way to use googleapis_auth with googleapis
      final baseClient = http.Client();
      final authClient = auth_io.autoRefreshingClient(
        clientId,
        credentials,
        baseClient,
      );
      
      // Save credentials for session persistence
      if (refreshToken != null) {
        await _saveCredentials(refreshToken, accessTokenString, expiryTime);
      }

      // Other GoogleDriveSyncService instances (e.g. the tray service's) hold
      // their own auth state — notify them so they can pick up the freshly
      // persisted credentials via restoreSession().
      _authStateController.add(true);

      if (kDebugMode) print('Authenticated client created successfully using googleapis_auth');
      return authClient;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in desktop sign-in: $e');
        print('Stack: $stackTrace');
      }
      return null;
    }
  }

  /// Sign out from Google (following official example pattern)
  /// Disconnect instead of just signing out, to reset the state as much as possible
  Future<void> signOut() async {
    try {
      if (MobileUtils.isMobile()) {
        if (!_isInitialized) {
          await initialize();
        }
        // Disconnect (following official example - resets state more completely)
        await GoogleSignIn.instance.disconnect();
        // State will be cleared by authenticationEvents listener
        // Reset session flag so lightweight auth can be attempted again on next login
        _sessionInitialized = false;
      } else {
        // Desktop: close auth client and clear saved credentials
        _desktopAuthClient?.close();
        _desktopAuthClient = null;
        await _clearCredentials();
        _currentUser = null;
        _isAuthenticated = false;
      }
      _driveApi = null;
      _appDataFolderId = null;
      _authStateController.add(false);

      if (kDebugMode) print('✓ Signed out successfully');
    } catch (e) {
      if (kDebugMode) print('Error signing out: $e');
      // Clear user state even if there was an error
      _currentUser = null;
      _isAuthenticated = false;
      _driveApi = null;
      _authStateController.add(false);
    }
  }

  /// Clears this instance's in-memory auth state only — does not touch
  /// persisted credentials or the auth client (which belongs to whichever
  /// instance owns it). Used to bring a passive instance (e.g. the tray
  /// service's) back in sync after another instance's [signOut] broadcast
  /// on [authStateStream], without re-triggering that broadcast.
  void forgetLocalSession() {
    _desktopAuthClient = null;
    _driveApi = null;
    _currentUser = null;
    _isAuthenticated = false;
    _appDataFolderId = null;
  }

  /// Returns the credentials file path for macOS (avoids Keychain prompts).
  Future<File> _credentialsFile() async {
    final dir = await getLocalAppDataPath();
    return File(path.join(dir, 'google_drive_credentials.json'));
  }

  /// Save desktop credentials for session persistence.
  /// On macOS: plain JSON file in app-support dir (avoids Keychain prompts).
  /// On Windows/Linux: flutter_secure_storage.
  Future<void> _saveCredentials(String refreshToken, String accessToken, DateTime expiryTime) async {
    if (MobileUtils.isMobile()) return;

    final credentialsData = {
      'refresh_token': refreshToken,
      'access_token': accessToken,
      'expiry_time': expiryTime.toIso8601String(),
    };
    try {
      if (Platform.isMacOS) {
        final file = await _credentialsFile();
        await file.writeAsString(jsonEncode(credentialsData));
      } else {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(key: _credentialsStorageKey, value: jsonEncode(credentialsData));
      }
      if (kDebugMode) print('Credentials saved for session persistence');
    } catch (e) {
      if (kDebugMode) print('Error saving credentials: $e');
    }
  }

  /// Clear saved credentials
  Future<void> _clearCredentials() async {
    if (MobileUtils.isMobile()) return;

    try {
      if (Platform.isMacOS) {
        final file = await _credentialsFile();
        if (await file.exists()) await file.delete();
      } else {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.delete(key: _credentialsStorageKey);
      }
      if (kDebugMode) print('Credentials cleared');
    } catch (e) {
      if (kDebugMode) print('Error clearing credentials: $e');
    }
  }

  /// Restore session from saved credentials (Desktop only)
  /// Android: authenticationEvents stream handles session restoration automatically
  Future<bool> restoreSession() async {
    if (MobileUtils.isMobile()) {
      // Android: attemptLightweightAuthentication is called in initialize()
      // The authenticationEvents stream will handle the result
      // Just check if we're already signed in
      if (!_isInitialized) {
        await initialize();
      }
      // Wait a bit for authenticationEvents to process
      await Future.delayed(const Duration(milliseconds: 500));
      return _currentUser != null && _isAuthenticated;
    }

    // Desktop: restore from saved credentials
    try {
      String? credentialsJson;
      if (Platform.isMacOS) {
        final file = await _credentialsFile();
        if (await file.exists()) credentialsJson = await file.readAsString();
      } else {
        const secureStorage = FlutterSecureStorage();
        credentialsJson = await secureStorage.read(key: _credentialsStorageKey);
      }
      if (credentialsJson == null) {
        if (kDebugMode) print('No saved credentials found');
        return false;
      }

      final credentialsData = jsonDecode(credentialsJson) as Map<String, dynamic>;
      final refreshToken = credentialsData['refresh_token'] as String?;
      final savedAccessToken = credentialsData['access_token'] as String?;
      final expiryTimeStr = credentialsData['expiry_time'] as String?;

      if (refreshToken == null) {
        if (kDebugMode) print('No refresh token in saved credentials');
        return false;
      }

      // Check if access token is still valid
      DateTime? expiryTime;
      if (expiryTimeStr != null) {
        expiryTime = DateTime.parse(expiryTimeStr);
        // If token expired, we'll use refresh token to get a new one
        if (expiryTime.isBefore(DateTime.now().toUtc())) {
          if (kDebugMode) print('Saved access token expired, will refresh');
        }
      }

      // Create client ID
      final clientId = auth_io.ClientId(_desktopClientId, _desktopClientSecret.isEmpty ? null : _desktopClientSecret);

      // Create credentials object
      auth_io.AccessCredentials credentials;
      
      if (savedAccessToken != null && expiryTime != null && expiryTime.isAfter(DateTime.now().toUtc())) {
        // Use saved access token if still valid
        final accessToken = auth_io.AccessToken(
          'Bearer',
          savedAccessToken,
          expiryTime,
        );
        credentials = auth_io.AccessCredentials(
          accessToken,
          refreshToken,
          _scopes,
        );
        if (kDebugMode) print('Using saved access token (still valid)');
      } else {
        // Access token expired or missing, create a placeholder - autoRefreshingClient will refresh it
        // We need to get a new access token using the refresh token
        final newAccessToken = await _refreshAccessToken(refreshToken);
        if (newAccessToken == null) {
          if (kDebugMode) print('Failed to refresh access token');
          return false;
        }
        
        credentials = auth_io.AccessCredentials(
          newAccessToken.accessToken,
          refreshToken,
          _scopes,
        );
        if (kDebugMode) print('Refreshed access token successfully');
      }

      // Create auto-refreshing client
      final baseClient = http.Client();
      final authClient = auth_io.autoRefreshingClient(
        clientId,
        credentials,
        baseClient,
      );

      _desktopAuthClient = authClient;
      _driveApi = drive.DriveApi(authClient);
      
      // Ensure app data folder exists (with timeout to avoid blocking)
      try {
        await ensureAppDataFolder().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) print('ensureAppDataFolder timed out, continuing anyway');
          },
        );
      } catch (e) {
        if (kDebugMode) print('Error ensuring app data folder during restore: $e');
        // Continue anyway - folder will be created on next sync
      }
      
      if (kDebugMode) print('Desktop session restored successfully');
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error restoring session: $e');
        print('Stack: $stackTrace');
      }
      // Clear invalid credentials
      await _clearCredentials();
      return false;
    }
  }

  /// Refresh access token using refresh token
  Future<auth_io.AccessCredentials?> _refreshAccessToken(String refreshToken) async {
    try {
      final clientId = auth_io.ClientId(_desktopClientId, _desktopClientSecret.isEmpty ? null : _desktopClientSecret);
      final tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');
      
      final bodyParams = <String, String>{
        'refresh_token': refreshToken,
        'client_id': _desktopClientId,
        'grant_type': 'refresh_token',
      };
      if (_desktopClientSecret.isNotEmpty) {
        bodyParams['client_secret'] = _desktopClientSecret;
      }

      final tokenResponse = await http.post(
        tokenEndpoint,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: bodyParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Token refresh request timed out');
        },
      );

      if (tokenResponse.statusCode != 200) {
        if (kDebugMode) {
          print('Token refresh failed: ${tokenResponse.statusCode}');
          print('Response: ${tokenResponse.body}');
        }
        return null;
      }

      final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessTokenString = tokenData['access_token'] as String;
      final expiresIn = tokenData['expires_in'] as int? ?? 3600;
      // Use expires_in directly - autoRefreshingClient manages refresh timing internally
      final expiryTime = DateTime.now().toUtc().add(Duration(seconds: expiresIn));

      final accessToken = auth_io.AccessToken(
        'Bearer',
        accessTokenString,
        expiryTime,
      );

      // Save updated credentials
      await _saveCredentials(refreshToken, accessTokenString, expiryTime);

      return auth_io.AccessCredentials(
        accessToken,
        refreshToken,
        _scopes,
      );
    } catch (e) {
      if (kDebugMode) print('Error refreshing access token: $e');
      return null;
    }
  }

  /// Get current user email
  /// Uses cached user info if available, otherwise queries Drive API
  Future<String?> getCurrentUserEmail() async {
    try {
      if (MobileUtils.isMobile()) {
        // First try to use cached user info from _currentUser
        if (_currentUser != null) {
          return _currentUser!.email;
        }
        
        // If no cached user, try to get from Drive API
        if (_driveApi == null) {
          // Try to restore session
          final restored = await restoreSession();
          if (!restored) {
            return null;
          }
        }
        
        if (_driveApi != null) {
          final about = await _driveApi!.about.get($fields: 'user');
          return about.user?.emailAddress;
        }
        return null;
      } else {
        // Desktop: get user info from Drive API
        if (_driveApi == null) return null;
        final about = await _driveApi!.about.get($fields: 'user');
        return about.user?.emailAddress;
      }
    } catch (e) {
      if (kDebugMode) print('Error getting user email: $e');
      return null;
    }
  }

  /// Ensure app data folder exists in Google Drive
  Future<void> ensureAppDataFolder() async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      if (kDebugMode) {
        print('=== Ensuring Shared Folder ===');
        print('Platform: ${Platform.operatingSystem}');
        print('Folder name: $_appDataFolderName');
        print('Location: Root of Google Drive (shared folder)');
      }
      
      // Search for folder in root of Google Drive (not appDataFolder)
      // Look for folder with the app name - first try in root, then anywhere
      var response = await _driveApi!.files.list(
        q: "name='$_appDataFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false and 'root' in parents",
        spaces: 'drive',
      );

      // If not found in root, search anywhere (in case it was moved)
      if (response.files == null || response.files!.isEmpty) {
        if (kDebugMode) {
          print('Folder not found in root, searching anywhere in Drive...');
        }
        response = await _driveApi!.files.list(
          q: "name='$_appDataFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
          spaces: 'drive',
        );
      }
      
      // If still not found, try a broader search to see what folders exist
      if (response.files == null || response.files!.isEmpty) {
        if (kDebugMode) {
          print('Folder not found with exact name, listing all folders to debug...');
          try {
            final allFolders = await _driveApi!.files.list(
              q: "mimeType='application/vnd.google-apps.folder' and trashed=false",
              spaces: 'drive',
              pageSize: 50,
            );
            if (allFolders.files != null && allFolders.files!.isNotEmpty) {
              print('All folders found in Drive (showing first 50):');
              for (final folder in allFolders.files!) {
                print('  - ${folder.name} (ID: ${folder.id})');
                if (folder.name?.toLowerCase().contains('daw') == true || 
                    folder.name?.toLowerCase().contains('project') == true ||
                    folder.name?.toLowerCase().contains('manager') == true) {
                  print('    ⚠️ This might be the folder we\'re looking for!');
                }
              }
            }
          } catch (e) {
            print('Error listing folders: $e');
          }
        }
      }

      if (response.files != null && response.files!.isNotEmpty) {
        _appDataFolderId = response.files!.first.id;
        if (kDebugMode) {
          print('Found existing shared folder: $_appDataFolderId');
          print('This folder is accessible from both desktop and mobile');
        }
        return;
      }

      // Create folder in root of Google Drive if it doesn't exist
      if (kDebugMode) {
        print('Creating new shared folder in root: $_appDataFolderName');
      }
      final folder = drive.File();
      folder.name = _appDataFolderName;
      folder.mimeType = 'application/vnd.google-apps.folder';
      // No parents means root of Drive - this creates a shared folder visible to all Client IDs

      final createdFolder = await _driveApi!.files.create(folder);
      _appDataFolderId = createdFolder.id;
      if (kDebugMode) {
        print('Created shared folder with ID: $_appDataFolderId');
        print('This folder is now accessible from both desktop and mobile');
        print('You can see it in your Google Drive at: https://drive.google.com');
      }
    } catch (e) {
      if (kDebugMode) print('Error ensuring app data folder: $e');
      rethrow;
    }
  }

  /// Ensure preview songs folder exists in Google Drive
  Future<String> _ensurePreviewSongsFolder() async {
    if (_driveApi == null || _appDataFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    const folderName = 'preview_songs';
    
    // Search for folder in app data folder
    var response = await _driveApi!.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and parents in '$_appDataFolderId' and trashed=false",
      spaces: 'drive',
    );

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id!;
    }

    // Create folder if it doesn't exist
    final folder = drive.File();
    folder.name = folderName;
    folder.mimeType = 'application/vnd.google-apps.folder';
    folder.parents = [_appDataFolderId!];

    final createdFolder = await _driveApi!.files.create(folder);
    if (kDebugMode) print('Created preview_songs folder: ${createdFolder.id}');
    return createdFolder.id!;
  }

  /// Ensure profile_photos folder exists in app data folder
  Future<String> _ensureProfilePhotosFolder() async {
    if (_driveApi == null || _appDataFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    const folderName = 'profile_photos';
    
    // Search for folder in app data folder
    var response = await _driveApi!.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and parents in '$_appDataFolderId' and trashed=false",
      spaces: 'drive',
    );

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id!;
    }

    // Create folder if it doesn't exist
    final folder = drive.File();
    folder.name = folderName;
    folder.mimeType = 'application/vnd.google-apps.folder';
    folder.parents = [_appDataFolderId!];

    final createdFolder = await _driveApi!.files.create(folder);
    if (kDebugMode) print('Created profile_photos folder: ${createdFolder.id}');
    return createdFolder.id!;
  }

  /// Ensure the release_artwork folder exists in Google Drive
  Future<String> _ensureReleaseArtworkFolder() async {
    if (_driveApi == null || _appDataFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    const folderName = 'release_artwork';
    
    // Search for folder in app data folder
    var response = await _driveApi!.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and parents in '$_appDataFolderId' and trashed=false",
      spaces: 'drive',
    );

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id!;
    }

    // Create folder if it doesn't exist
    final folder = drive.File();
    folder.name = folderName;
    folder.mimeType = 'application/vnd.google-apps.folder';
    folder.parents = [_appDataFolderId!];

    final createdFolder = await _driveApi!.files.create(folder);
    if (kDebugMode) print('Created release_artwork folder: ${createdFolder.id}');
    return createdFolder.id!;
  }

  /// Ensure the project_cover_art folder exists in Google Drive (#110)
  Future<String> _ensureProjectCoverArtFolder() async {
    if (_driveApi == null || _appDataFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    const folderName = 'project_cover_art';

    var response = await _driveApi!.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and parents in '$_appDataFolderId' and trashed=false",
      spaces: 'drive',
    );

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id!;
    }

    final folder = drive.File();
    folder.name = folderName;
    folder.mimeType = 'application/vnd.google-apps.folder';
    folder.parents = [_appDataFolderId!];

    final createdFolder = await _driveApi!.files.create(folder);
    if (kDebugMode) print('Created project_cover_art folder: ${createdFolder.id}');
    return createdFolder.id!;
  }

  /// Upload a preview song file to Google Drive
  /// Returns the file ID in Google Drive, the file hash, and the original filename
  /// Only uploads if the file hash has changed
  Future<Map<String, String>?> _uploadPreviewSongFile({
    required String projectId,
    required String localFilePath,
    String? existingHash, // Hash from previous backup (if available)
  }) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    final file = File(localFilePath);
    if (!await file.exists()) {
      if (kDebugMode) print('Preview song file not found: $localFilePath');
      return null;
    }

    try {
      // Calculate current file hash
      final currentHash = await _calculateFileHash(localFilePath);
      
      // If hash exists and matches, skip upload
      if (existingHash != null && existingHash == currentHash) {
        if (kDebugMode) {
          print('Preview song unchanged for project $projectId (hash: $currentHash), skipping upload');
        }
        // Still return the file ID if it exists in Drive
        final previewSongsFolderId = await _ensurePreviewSongsFolder();
        final fileName = path.basename(localFilePath);
        final fileExtension = path.extension(fileName);
        final driveFileName = '${projectId}_preview$fileExtension';
        
        var response = await _driveApi!.files.list(
          q: "name='$driveFileName' and parents in '$previewSongsFolderId' and trashed=false",
          spaces: 'drive',
        );
        
        if (response.files != null && response.files!.isNotEmpty) {
          return {
            'fileId': response.files!.first.id!,
            'hash': currentHash,
            'fileName': fileName, // Original filename
          };
        }
        // If file doesn't exist in Drive but hash matches, something is wrong
        // Fall through to upload
      }
      
      // Hash changed or file doesn't exist - upload
      if (kDebugMode) {
        if (existingHash != null) {
          print('Preview song changed for project $projectId (old: $existingHash, new: $currentHash), uploading...');
        } else {
          print('Uploading new preview song for project $projectId (hash: $currentHash)');
        }
      }
      
      // Ensure preview songs folder exists
      final previewSongsFolderId = await _ensurePreviewSongsFolder();
      
      // Generate a unique filename based on project ID
      final fileName = path.basename(localFilePath);
      final fileExtension = path.extension(fileName);
      final driveFileName = '${projectId}_preview$fileExtension';
      
      // Check if file already exists
      var response = await _driveApi!.files.list(
        q: "name='$driveFileName' and parents in '$previewSongsFolderId' and trashed=false",
        spaces: 'drive',
      );

      final fileBytes = await file.readAsBytes();
      final media = drive.Media(
        Stream.value(fileBytes),
        fileBytes.length,
        contentType: _getContentTypeForFile(fileExtension),
      );

      String fileId;
      if (response.files != null && response.files!.isNotEmpty) {
        // Update existing file
        fileId = response.files!.first.id!;
        await _driveApi!.files.update(
          drive.File()..name = driveFileName,
          fileId,
          uploadMedia: media,
        );
        if (kDebugMode) print('Updated preview song: $driveFileName (ID: $fileId)');
      } else {
        // Create new file
        final driveFile = drive.File();
        driveFile.name = driveFileName;
        driveFile.parents = [previewSongsFolderId];
        
        final createdFile = await _driveApi!.files.create(driveFile, uploadMedia: media);
        fileId = createdFile.id!;
        if (kDebugMode) print('Uploaded preview song: $driveFileName (ID: $fileId)');
      }
      
      return {
        'fileId': fileId,
        'hash': currentHash,
        'fileName': fileName, // Original filename
      };
    } catch (e) {
      if (kDebugMode) print('Error uploading preview song: $e');
      return null;
    }
  }

  /// Upload a profile photo file to Google Drive
  /// Returns the file ID in Google Drive and the file hash
  /// Only uploads if the file hash has changed
  Future<Map<String, String>?> _uploadProfilePhotoFile({
    required String profileId,
    required String localFilePath,
    String? existingHash, // Hash from previous backup (if available)
  }) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    final file = File(localFilePath);
    if (!await file.exists()) {
      if (kDebugMode) print('Profile photo file not found: $localFilePath');
      return null;
    }

    try {
      // Calculate current file hash
      final currentHash = await _calculateFileHash(localFilePath);
      
      // If hash exists and matches, skip upload
      if (existingHash != null && existingHash == currentHash) {
        if (kDebugMode) {
          print('Profile photo unchanged for profile $profileId (hash: $currentHash), skipping upload');
        }
        // Still return the file ID if it exists in Drive
        final profilePhotosFolderId = await _ensureProfilePhotosFolder();
        final fileExtension = path.extension(localFilePath);
        final driveFileName = '${profileId}_photo$fileExtension';
        
        var response = await _driveApi!.files.list(
          q: "name='$driveFileName' and parents in '$profilePhotosFolderId' and trashed=false",
          spaces: 'drive',
        );
        
        if (response.files != null && response.files!.isNotEmpty) {
          return {
            'fileId': response.files!.first.id!,
            'hash': currentHash,
          };
        }
        // If file doesn't exist in Drive but hash matches, something is wrong
        // Fall through to upload
      }
      
      // Hash changed or file doesn't exist - upload
      if (kDebugMode) {
        if (existingHash != null) {
          print('Profile photo changed for profile $profileId (old: $existingHash, new: $currentHash), uploading...');
        } else {
          print('Uploading new profile photo for profile $profileId (hash: $currentHash)');
        }
      }
      
      // Ensure profile photos folder exists
      final profilePhotosFolderId = await _ensureProfilePhotosFolder();
      
      // Generate a unique filename based on profile ID
      final fileExtension = path.extension(localFilePath);
      final driveFileName = '${profileId}_photo$fileExtension';
      
      // Check if file already exists
      var response = await _driveApi!.files.list(
        q: "name='$driveFileName' and parents in '$profilePhotosFolderId' and trashed=false",
        spaces: 'drive',
      );

      final fileBytes = await file.readAsBytes();
      final media = drive.Media(
        Stream.value(fileBytes),
        fileBytes.length,
        contentType: _getContentTypeForFile(fileExtension),
      );

      String fileId;
      if (response.files != null && response.files!.isNotEmpty) {
        // Update existing file
        fileId = response.files!.first.id!;
        await _driveApi!.files.update(
          drive.File()..name = driveFileName,
          fileId,
          uploadMedia: media,
        );
        if (kDebugMode) print('Updated profile photo: $driveFileName (ID: $fileId)');
      } else {
        // Create new file
        final driveFile = drive.File();
        driveFile.name = driveFileName;
        driveFile.parents = [profilePhotosFolderId];
        
        final createdFile = await _driveApi!.files.create(driveFile, uploadMedia: media);
        fileId = createdFile.id!;
        if (kDebugMode) print('Uploaded profile photo: $driveFileName (ID: $fileId)');
      }
      
      return {
        'fileId': fileId,
        'hash': currentHash,
      };
    } catch (e) {
      if (kDebugMode) print('Error uploading profile photo: $e');
      return null;
    }
  }

  /// Upload release artwork file to Google Drive
  /// Returns the file ID in Google Drive and the file hash
  /// Uses hash comparison to avoid unnecessary uploads
  Future<Map<String, String>?> _uploadReleaseArtworkFile({
    required String releaseId,
    required String localFilePath,
    String? existingHash, // Hash from previous backup (if available)
  }) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    final file = File(localFilePath);
    if (!await file.exists()) {
      if (kDebugMode) print('Release artwork file not found: $localFilePath');
      return null;
    }

    try {
      // Calculate current file hash
      final currentHash = await _calculateFileHash(localFilePath);
      
      // If hash exists and matches, skip upload
      if (existingHash != null && existingHash == currentHash) {
        if (kDebugMode) {
          print('Release artwork unchanged for release $releaseId (hash: $currentHash), skipping upload');
        }
        // Still return the file ID if it exists in Drive
        final releaseArtworkFolderId = await _ensureReleaseArtworkFolder();
        final fileExtension = path.extension(localFilePath);
        final driveFileName = '${releaseId}_artwork$fileExtension';
        
        var response = await _driveApi!.files.list(
          q: "name='$driveFileName' and parents in '$releaseArtworkFolderId' and trashed=false",
          spaces: 'drive',
        );
        
        if (response.files != null && response.files!.isNotEmpty) {
          return {
            'fileId': response.files!.first.id!,
            'hash': currentHash,
          };
        }
        // If file doesn't exist in Drive but hash matches, something is wrong
        // Fall through to upload
      }
      
      // Hash changed or file doesn't exist - upload
      if (kDebugMode) {
        if (existingHash != null) {
          print('Release artwork changed for release $releaseId (old: $existingHash, new: $currentHash), uploading...');
        } else {
          print('Uploading new release artwork for release $releaseId (hash: $currentHash)');
        }
      }
      
      // Ensure release artwork folder exists
      final releaseArtworkFolderId = await _ensureReleaseArtworkFolder();
      
      // Generate a unique filename based on release ID
      final fileExtension = path.extension(localFilePath);
      final driveFileName = '${releaseId}_artwork$fileExtension';
      
      // Check if file already exists
      var response = await _driveApi!.files.list(
        q: "name='$driveFileName' and parents in '$releaseArtworkFolderId' and trashed=false",
        spaces: 'drive',
      );

      final fileBytes = await file.readAsBytes();
      final media = drive.Media(
        Stream.value(fileBytes),
        fileBytes.length,
        contentType: _getContentTypeForFile(fileExtension),
      );

      String fileId;
      if (response.files != null && response.files!.isNotEmpty) {
        // Update existing file
        fileId = response.files!.first.id!;
        await _driveApi!.files.update(
          drive.File()..name = driveFileName,
          fileId,
          uploadMedia: media,
        );
        if (kDebugMode) print('Updated release artwork: $driveFileName (ID: $fileId)');
      } else {
        // Create new file
        final driveFile = drive.File();
        driveFile.name = driveFileName;
        driveFile.parents = [releaseArtworkFolderId];
        
        final createdFile = await _driveApi!.files.create(driveFile, uploadMedia: media);
        fileId = createdFile.id!;
        if (kDebugMode) print('Uploaded release artwork: $driveFileName (ID: $fileId)');
      }
      
      return {
        'fileId': fileId,
        'hash': currentHash,
      };
    } catch (e) {
      if (kDebugMode) print('Error uploading release artwork: $e');
      return null;
    }
  }

  /// Upload a project's cover art to Google Drive (#110).
  ///
  /// Mirrors [_uploadReleaseArtworkFile]: hash-gated so an unchanged cover
  /// costs one metadata query instead of a re-upload, and named
  /// `<projectId>_cover<ext>` so the file is addressable without the manifest.
  /// Returns the Drive file id and the hash that was uploaded, or null when
  /// there was nothing to upload.
  Future<Map<String, String>?> _uploadProjectCoverArtFile({
    required String projectId,
    required String localFilePath,
    String? existingHash, // Hash from previous backup (if available)
  }) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    final file = File(localFilePath);
    if (!await file.exists()) {
      if (kDebugMode) print('Project cover art file not found: $localFilePath');
      return null;
    }

    try {
      final currentHash = await _calculateFileHash(localFilePath);
      final fileExtension = path.extension(localFilePath);
      final driveFileName = '${projectId}_cover$fileExtension';
      final coverArtFolderId = await _ensureProjectCoverArtFolder();

      if (existingHash != null && existingHash == currentHash) {
        if (kDebugMode) {
          print('Project cover art unchanged for project $projectId (hash: $currentHash), skipping upload');
        }
        var response = await _driveApi!.files.list(
          q: "name='$driveFileName' and parents in '$coverArtFolderId' and trashed=false",
          spaces: 'drive',
        );
        if (response.files != null && response.files!.isNotEmpty) {
          return {'fileId': response.files!.first.id!, 'hash': currentHash};
        }
        // Hash matched but the file isn't on Drive — fall through and upload.
      }

      if (kDebugMode) {
        if (existingHash != null) {
          print('Project cover art changed for project $projectId (old: $existingHash, new: $currentHash), uploading...');
        } else {
          print('Uploading new project cover art for project $projectId (hash: $currentHash)');
        }
      }

      var response = await _driveApi!.files.list(
        q: "name='$driveFileName' and parents in '$coverArtFolderId' and trashed=false",
        spaces: 'drive',
      );

      final fileBytes = await file.readAsBytes();
      final media = drive.Media(
        Stream.value(fileBytes),
        fileBytes.length,
        contentType: _getContentTypeForFile(fileExtension),
      );

      String fileId;
      if (response.files != null && response.files!.isNotEmpty) {
        fileId = response.files!.first.id!;
        await _driveApi!.files.update(
          drive.File()..name = driveFileName,
          fileId,
          uploadMedia: media,
        );
        if (kDebugMode) print('Updated project cover art: $driveFileName (ID: $fileId)');
      } else {
        final driveFile = drive.File();
        driveFile.name = driveFileName;
        driveFile.parents = [coverArtFolderId];

        final createdFile = await _driveApi!.files.create(driveFile, uploadMedia: media);
        fileId = createdFile.id!;
        if (kDebugMode) print('Uploaded project cover art: $driveFileName (ID: $fileId)');
      }

      return {'fileId': fileId, 'hash': currentHash};
    } catch (e) {
      if (kDebugMode) print('Error uploading project cover art: $e');
      return null;
    }
  }

  /// Download a project's cover art from Google Drive to local storage (#110).
  ///
  /// Returns the local file path, or null if the download failed. Unlike a
  /// preview song, a cover that fails to download stores nothing: the avatar
  /// falls back to the project's accent colour and icon, which is a better
  /// result than a `drive://` path no image widget can open.
  Future<String?> downloadProjectCoverArtFile({
    required String driveFileId,
    required String projectId,
    String? expectedHash,
    String? fileExtension,
  }) async {
    if (_driveApi == null) {
      if (kDebugMode) print('Drive API not initialized, attempting to restore session...');
      final restored = await restoreSession();
      if (!restored) {
        if (kDebugMode) print('Failed to restore session for project cover art download');
        return null;
      }
    }

    try {
      final coverArtPath = await getProjectCoverArtPath();
      final coverArtDir = Directory(coverArtPath);
      if (!await coverArtDir.exists()) {
        await coverArtDir.create(recursive: true);
      }

      final ext = fileExtension ?? '.jpg';
      final localFilePath = path.join(coverArtPath, '${projectId}_cover$ext');

      final existingFile = File(localFilePath);
      if (await existingFile.exists() && expectedHash != null) {
        try {
          final existingHash = await _calculateFileHash(localFilePath);
          if (existingHash == expectedHash) {
            if (kDebugMode) {
              print('Project cover art already downloaded with matching hash, skipping download');
            }
            return localFilePath;
          }
          await existingFile.delete();
        } catch (e) {
          if (kDebugMode) print('Error checking existing project cover art hash: $e, will re-download');
          if (await existingFile.exists()) {
            await existingFile.delete();
          }
        }
      }

      final file = File(localFilePath);
      await _withRetry(() async {
        final media = (await _driveApi!.files.get(
          driveFileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        )) as drive.Media;

        if (await file.exists()) await file.delete();

        final sink = file.openWrite();
        try {
          await for (final chunk in media.stream) {
            sink.add(chunk);
          }
        } catch (e) {
          await sink.close();
          if (await file.exists()) await file.delete();
          rethrow;
        }
        await sink.close();
      });

      if (expectedHash != null) {
        final downloadedHash = await _calculateFileHash(localFilePath);
        if (downloadedHash != expectedHash && kDebugMode) {
          print('WARNING: Downloaded project cover art hash mismatch! Expected: $expectedHash, Got: $downloadedHash');
        }
      }

      if (kDebugMode) print('Downloaded project cover art to: $localFilePath');
      return localFilePath;
    } catch (e) {
      if (kDebugMode) print('Error downloading project cover art: $e');
      return null;
    }
  }

  /// Download preview song file from Google Drive to local storage
  /// Returns the local file path, or null if download failed
  /// Uses hash comparison to avoid unnecessary downloads
  Future<String?> downloadPreviewSongFile({
    required String driveFileId,
    required String projectId,
    String? expectedHash, // Hash from project.uploadedPreviewSongHash
    String? fileExtension, // File extension from previewSongFileName or default to .mp3
  }) async {
    if (_driveApi == null) {
      if (kDebugMode) print('Drive API not initialized, attempting to restore session...');
      final restored = await restoreSession();
      if (!restored) {
        if (kDebugMode) print('Failed to restore session for download');
        return null;
      }
    }

    try {
      // Get local preview songs directory
      final previewSongsDir = await getPreviewSongsPath();
      final ext = fileExtension ?? '.mp3';
      final localFilePath = path.join(previewSongsDir, '${projectId}_preview$ext');
      
      // Check if file already exists and hash matches
      final existingFile = File(localFilePath);
      if (await existingFile.exists() && expectedHash != null) {
        try {
          final existingHash = await _calculateFileHash(localFilePath);
          if (existingHash == expectedHash) {
            if (kDebugMode) {
              print('Preview song already downloaded with matching hash, skipping download');
            }
            return localFilePath;
          } else {
            if (kDebugMode) {
              print('Preview song hash mismatch (local: $existingHash, expected: $expectedHash), re-downloading...');
            }
            // Delete old file
            await existingFile.delete();
          }
        } catch (e) {
          if (kDebugMode) print('Error checking existing file hash: $e, will re-download');
          // If hash check fails, delete and re-download
          if (await existingFile.exists()) {
            await existingFile.delete();
          }
        }
      }
      
      if (kDebugMode) {
        print('Downloading preview song from Drive: $driveFileId');
      }
      
      // Download file using Drive API, retrying the full download (including
      // stream consumption) so transient network errors mid-stream are retried.
      final file = File(localFilePath);
      await _withRetry(() async {
        // Get a fresh Media handle on every attempt so the stream is not reused.
        final media = (await _driveApi!.files.get(
          driveFileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        )) as drive.Media;

        // Delete any partial file left by a previous failed attempt.
        if (await file.exists()) await file.delete();

        final sink = file.openWrite();
        try {
          await for (final chunk in media.stream) {
            sink.add(chunk);
          }
        } catch (e) {
          // Always close the sink and remove the partial file before rethrowing
          // so we never leak file handles or leave corrupt data on disk.
          await sink.close();
          if (await file.exists()) await file.delete();
          rethrow;
        }
        await sink.close();
      });

      // Verify hash if expected hash was provided
      if (expectedHash != null) {
        final downloadedHash = await _calculateFileHash(localFilePath);
        if (downloadedHash != expectedHash) {
          if (kDebugMode) {
            print('WARNING: Downloaded file hash mismatch! Expected: $expectedHash, Got: $downloadedHash');
          }
          // Still return the file, but log the warning
        } else {
          if (kDebugMode) {
            print('Downloaded file hash verified: $downloadedHash');
          }
        }
      }

      if (kDebugMode) {
        print('Downloaded preview song to: $localFilePath');
      }

      return localFilePath;
    } catch (e) {
      if (kDebugMode) print('Error downloading preview song: $e');
      return null;
    }
  }

  /// Download profile photo file from Google Drive to local storage
  /// Returns the local file path, or null if download failed
  /// Uses hash comparison to avoid unnecessary downloads
  Future<String?> downloadProfilePhotoFile({
    required String driveFileId,
    required String profileId,
    String? expectedHash, // Hash from profile.uploadedPhotoHash
    String? fileExtension, // File extension from photoPath or default to .jpg
  }) async {
    if (_driveApi == null) {
      if (kDebugMode) print('Drive API not initialized, attempting to restore session...');
      final restored = await restoreSession();
      if (!restored) {
        if (kDebugMode) print('Failed to restore session for profile photo download');
        return null;
      }
    }

    try {
      // Get local app directory for profile photos
      final appDir = await getApplicationDocumentsDirectory();
      final profilePhotosDir = Directory(path.join(appDir.path, 'profile_photos'));
      if (!await profilePhotosDir.exists()) {
        await profilePhotosDir.create(recursive: true);
      }
      
      final ext = fileExtension ?? '.jpg';
      final localFilePath = path.join(profilePhotosDir.path, '${profileId}_photo$ext');
      
      // Check if file already exists and hash matches
      final existingFile = File(localFilePath);
      if (await existingFile.exists() && expectedHash != null) {
        try {
          final existingHash = await _calculateFileHash(localFilePath);
          if (existingHash == expectedHash) {
            if (kDebugMode) {
              print('Profile photo already downloaded with matching hash, skipping download');
            }
            return localFilePath;
          } else {
            if (kDebugMode) {
              print('Profile photo hash mismatch (local: $existingHash, expected: $expectedHash), re-downloading...');
            }
            // Delete old file
            await existingFile.delete();
          }
        } catch (e) {
          if (kDebugMode) print('Error checking existing profile photo hash: $e, will re-download');
          // If hash check fails, delete and re-download
          if (await existingFile.exists()) {
            await existingFile.delete();
          }
        }
      }
      
      if (kDebugMode) {
        print('Downloading profile photo from Drive: $driveFileId');
      }
      
      // Download file using Drive API, retrying the full download (including
      // stream consumption) so transient network errors mid-stream are retried.
      final file = File(localFilePath);
      await _withRetry(() async {
        final media = (await _driveApi!.files.get(
          driveFileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        )) as drive.Media;

        if (await file.exists()) await file.delete();

        final sink = file.openWrite();
        try {
          await for (final chunk in media.stream) {
            sink.add(chunk);
          }
        } catch (e) {
          await sink.close();
          if (await file.exists()) await file.delete();
          rethrow;
        }
        await sink.close();
      });

      // Verify hash if expected hash was provided
      if (expectedHash != null) {
        final downloadedHash = await _calculateFileHash(localFilePath);
        if (downloadedHash != expectedHash) {
          if (kDebugMode) {
            print('WARNING: Downloaded profile photo hash mismatch! Expected: $expectedHash, Got: $downloadedHash');
          }
          // Still return the file, but log the warning
        } else {
          if (kDebugMode) {
            print('Downloaded profile photo hash verified: $downloadedHash');
          }
        }
      }

      if (kDebugMode) {
        print('Downloaded profile photo to: $localFilePath');
      }

      return localFilePath;
    } catch (e) {
      if (kDebugMode) print('Error downloading profile photo: $e');
      return null;
    }
  }

  /// Download release artwork file from Google Drive to local storage
  /// Returns the local file path, or null if download failed
  /// Uses hash comparison to avoid unnecessary downloads
  Future<String?> downloadReleaseArtworkFile({
    required String driveFileId,
    required String releaseId,
    String? expectedHash, // Hash from backup metadata
    String? fileExtension, // File extension from artworkImagePath or default to .jpg
  }) async {
    if (_driveApi == null) {
      if (kDebugMode) print('Drive API not initialized, attempting to restore session...');
      final restored = await restoreSession();
      if (!restored) {
        if (kDebugMode) print('Failed to restore session for release artwork download');
        return null;
      }
    }

    try {
      // Get local release artwork directory
      final releaseArtworkPath = await getReleaseArtworkPath();
      final releaseArtworkDir = Directory(releaseArtworkPath);
      if (!await releaseArtworkDir.exists()) {
        await releaseArtworkDir.create(recursive: true);
      }
      
      final ext = fileExtension ?? '.jpg';
      final localFilePath = path.join(releaseArtworkPath, '${releaseId}_artwork$ext');
      
      // Check if file already exists and hash matches
      final existingFile = File(localFilePath);
      if (await existingFile.exists() && expectedHash != null) {
        try {
          final existingHash = await _calculateFileHash(localFilePath);
          if (existingHash == expectedHash) {
            if (kDebugMode) {
              print('Release artwork already downloaded with matching hash, skipping download');
            }
            return localFilePath;
          } else {
            if (kDebugMode) {
              print('Release artwork hash mismatch (local: $existingHash, expected: $expectedHash), re-downloading...');
            }
            // Delete old file
            await existingFile.delete();
          }
        } catch (e) {
          if (kDebugMode) print('Error checking existing release artwork hash: $e, will re-download');
          // If hash check fails, delete and re-download
          if (await existingFile.exists()) {
            await existingFile.delete();
          }
        }
      }
      
      if (kDebugMode) {
        print('Downloading release artwork from Drive: $driveFileId');
      }
      
      // Download file using Drive API, retrying the full download (including
      // stream consumption) so transient network errors mid-stream are retried.
      final file = File(localFilePath);
      await _withRetry(() async {
        final media = (await _driveApi!.files.get(
          driveFileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        )) as drive.Media;

        if (await file.exists()) await file.delete();

        final sink = file.openWrite();
        try {
          await for (final chunk in media.stream) {
            sink.add(chunk);
          }
        } catch (e) {
          await sink.close();
          if (await file.exists()) await file.delete();
          rethrow;
        }
        await sink.close();
      });

      // Verify hash if expected hash was provided
      if (expectedHash != null) {
        final downloadedHash = await _calculateFileHash(localFilePath);
        if (downloadedHash != expectedHash) {
          if (kDebugMode) {
            print('WARNING: Downloaded release artwork hash mismatch! Expected: $expectedHash, Got: $downloadedHash');
          }
          // Still return the file, but log the warning
        } else {
          if (kDebugMode) {
            print('Downloaded release artwork hash verified: $downloadedHash');
          }
        }
      }

      if (kDebugMode) {
        print('Downloaded release artwork to: $localFilePath');
      }

      return localFilePath;
    } catch (e) {
      if (kDebugMode) print('Error downloading release artwork: $e');
      return null;
    }
  }


  /// Check if a preview song path is a Google Drive file reference
  /// Format: "drive://{fileId}"
  bool _isDriveFileReference(String? path) {
    return path != null && path.startsWith('drive://');
  }

  /// Extract drive file ID from a drive file reference
  /// Format: "drive://{fileId}" -> "{fileId}"
  String? _extractDriveFileId(String path) {
    if (!_isDriveFileReference(path)) return null;
    return path.substring(8); // Remove "drive://" prefix
  }

  /// Create a drive file reference from a file ID
  /// Format: "{fileId}" -> "drive://{fileId}"
  String _createDriveFileReference(String fileId) {
    return 'drive://$fileId';
  }

  /// Calculate MD5 hash of a file
  /// Calculate MD5 hash of a file
  /// Public method so it can be called from UI when adding preview songs
  Future<String> calculateFileHash(String filePath) async {
    return _calculateFileHash(filePath);
  }
  
  Future<String> _calculateFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // Use streaming to avoid loading large files into memory (important for Android)
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  /// Like [_calculateFileHash] but memoises the result in [_mergeHashCache] so
  /// the same file is only read from disk once per merge operation.
  Future<String> _cachedFileHash(String filePath) async {
    return _mergeHashCache[filePath] ??= await _calculateFileHash(filePath);
  }

  /// Returns the basename of [filePath] to use as a preview song's display name,
  /// unless it looks like one of our own Drive-download filenames
  /// (`<uuid>_preview.<ext>`) — in which case there is no real original name to
  /// recover from it and null is returned instead. Used as the fallback when
  /// restoring a backup that predates the `previewSongFileNames` manifest map,
  /// so a UUID never gets stored as a project's "original" preview filename.
  String? _realPreviewFileNameOrNull(String? filePath) {
    if (filePath == null) return null;
    final basename = path.basename(filePath);
    return _uuidPreviewRe.hasMatch(basename) ? null : basename;
  }

  /// Returns true if [localProject.previewSongAutoPath] already points at a file on
  /// disk whose hash matches [expectedHash] (falling back to the project's last
  /// recorded [MusicProject.uploadedPreviewSongHash] when [expectedHash] is
  /// unavailable). Used during merge to avoid re-downloading a preview from Drive
  /// into `previewSongPath` when the auto-detected file already on this device is
  /// the same one that's already backed up — downloading it anyway would duplicate
  /// the file under a UUID-named copy and silently promote an auto-detected preview
  /// into a manually-pinned one, overriding the "auto-detected" status in the UI.
  Future<bool> _autoPreviewAlreadyMatches(MusicProject localProject, String? expectedHash) async {
    final autoPath = localProject.previewSongAutoPath;
    if (autoPath == null || autoPath.isEmpty) return false;
    final hashToMatch = expectedHash ?? localProject.uploadedPreviewSongHash;
    if (hashToMatch == null) return false;
    try {
      final autoFile = File(autoPath);
      if (!await autoFile.exists()) return false;
      final autoHash = await _cachedFileHash(autoPath);
      return autoHash == hashToMatch;
    } catch (_) {
      return false;
    }
  }

  /// Retry [fn] up to [maxAttempts] times on transient Drive/network errors using
  /// exponential backoff (2 s, 4 s, 8 s …) with ±25 % jitter.
  /// Throws immediately on cancellation or non-retryable errors.
  Future<T> _withRetry<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
    int attempt = 0;
    while (true) {
      if (_isCancelled) throw UploadCancelledException('Cancelled by user');
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts || !_isRetryableError(e) || _isCancelled) rethrow;
        final base = Duration(seconds: 1 << attempt); // 2 s, 4 s, 8 s
        final jitterMs = (base.inMilliseconds * 0.25 * (DateTime.now().millisecondsSinceEpoch % 100) / 100).round();
        if (kDebugMode) print('Drive retry $attempt/$maxAttempts after ${base.inMilliseconds + jitterMs}ms: $e');
        await Future.delayed(base + Duration(milliseconds: jitterMs));
      }
    }
  }

  bool _isRetryableError(Object e) {
    if (e is SocketException || e is HttpException) return true;
    final s = e.toString();
    return s.contains('429') || s.contains('500') || s.contains('502') ||
        s.contains('503') || s.contains('504');
  }

  /// Get content type for file extension
  String _getContentTypeForFile(String extension) {
    switch (extension.toLowerCase()) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
        return 'audio/ogg';
      case '.flac':
        return 'audio/flac';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload database to Google Drive
  /// Backs up the ENTIRE application (all profiles, projects, releases, etc.)
  /// Mobile will mirror the desktop app - it doesn't need its own functionality
  Future<void> uploadDatabase({
    required ProjectRepository projectRepo,
    required ProfileRepository profileRepo,
    String? profileId, // Optional - kept for compatibility but not used in filename
    bool uploadAutoDetectedSongs = false,
  }) async {
    if (_driveApi == null || _appDataFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    // Reset cancellation flag at the start
    _isCancelled = false;

    try {
      // Serialize ALL data from the entire application
      // Collect data from ALL profiles, not just the current one
      final allProfiles = profileRepo.getAllProfiles();
      
      // Collect projects, releases, and roots from ALL profiles
      // IMPORTANT: We need to track which profile each project/release/root belongs to
      final allProjects = <MusicProject>[];
      final allReleases = <Release>[];
      final allRoots = <ScanRoot>[];

      // Shared box for global/per-profile preferences (app_settings)
      final appSettingsBox = await Hive.openBox<String>('app_settings');
      // Per-profile phase customization: profileId -> {phases, phaseColors, finishedPhases}
      final phaseSettingsByProfile = <String, Map<String, dynamic>>{};

      // Maps to track which profile each item belongs to
      final projectToProfileMap = <String, String>{}; // projectId -> profileId
      final releaseToProfileMap = <String, String>{}; // releaseId -> profileId
      final rootToProfileMap = <String, String>{}; // rootId -> profileId
      
      // Map to track preview song files in Google Drive
      // projectId -> driveFileId
      final previewSongFileMap = <String, String>{};
      // Map to track preview song hashes
      // projectId -> fileHash
      final previewSongHashes = <String, String>{};
      // Map to track original filenames
      // projectId -> originalFileName
      final previewSongFileNames = <String, String>{};
      
      // Map to track profile photo files in Google Drive
      // profileId -> driveFileId
      final profilePhotoFileMap = <String, String>{};
      // Map to track profile photo hashes
      // profileId -> fileHash
      final profilePhotoHashes = <String, String>{};
      
      // Map to track release artwork files in Google Drive
      // releaseId -> driveFileId
      final releaseArtworkFileMap = <String, String>{};
      // Map to track release artwork hashes
      // releaseId -> fileHash
      final releaseArtworkHashes = <String, String>{};

      // Map to track project cover art files in Google Drive (#110)
      // projectId -> driveFileId
      final projectCoverArtFileMap = <String, String>{};
      // Map to track project cover art hashes
      // projectId -> fileHash
      final projectCoverArtHashes = <String, String>{};
      
      // Get existing hashes from previous backup (if available) to avoid unnecessary uploads
      Map<String, String> existingHashes = {};
      Map<String, String> existingProfilePhotoHashes = {};
      Map<String, String> existingReleaseArtworkHashes = {};
      Map<String, String> existingProjectCoverArtHashes = {};
      try {
        final existingBackup = await downloadDatabase();
        if (existingBackup['previewSongHashes'] != null) {
          existingHashes = Map<String, String>.from(existingBackup['previewSongHashes'] as Map);
          if (kDebugMode) {
            print('Found ${existingHashes.length} existing preview song hashes from previous backup');
          }
        }
        if (existingBackup['profilePhotoHashes'] != null) {
          existingProfilePhotoHashes = Map<String, String>.from(existingBackup['profilePhotoHashes'] as Map);
          if (kDebugMode) {
            print('Found ${existingProfilePhotoHashes.length} existing profile photo hashes from previous backup');
          }
        }
        if (existingBackup['releaseArtworkHashes'] != null) {
          existingReleaseArtworkHashes = Map<String, String>.from(existingBackup['releaseArtworkHashes'] as Map);
          if (kDebugMode) {
            print('Found ${existingReleaseArtworkHashes.length} existing release artwork hashes from previous backup');
          }
        }
        if (existingBackup['projectCoverArtHashes'] != null) {
          existingProjectCoverArtHashes = Map<String, String>.from(existingBackup['projectCoverArtHashes'] as Map);
          if (kDebugMode) {
            print('Found ${existingProjectCoverArtHashes.length} existing project cover art hashes from previous backup');
          }
        }
      } catch (_) {
        // No previous backup or error reading it - that's okay, we'll upload everything
        if (kDebugMode) {
          print('No previous backup found or error reading it - will upload all media files');
        }
      }
      
      if (kDebugMode) {
        print('Collecting data from ${allProfiles.length} profiles...');
      }
      
      // Emit progress: collecting data
      _progressController.add(BackupProgress(
        stage: BackupProgressStage.collectingData,
        currentItem: 'Collecting data from profiles...',
        currentIndex: 0,
        totalItems: allProfiles.length,
        progress: 0.0,
      ));
      
      if (allProfiles.isEmpty) {
        if (kDebugMode) {
          print('WARNING: No profiles found! Cannot create backup.');
        }
        throw Exception('No profiles found - cannot create backup');
      }
      
      // Structure to hold preview songs that need upload
      final previewSongsToUpload = <Map<String, dynamic>>[];
      
      // Structure to hold profile photos that need upload
      final profilePhotosToUpload = <Map<String, dynamic>>[];
      
      // Structure to hold release artwork that needs upload
      final releaseArtworkToUpload = <Map<String, dynamic>>[];

      // Structure to hold project cover art that needs upload (#110)
      final projectCoverArtToUpload = <Map<String, dynamic>>[];
      
      int profileIndex = 0;
      for (final profile in allProfiles) {
        // Check for cancellation
        if (_isCancelled) {
          throw UploadCancelledException();
        }
        
        profileIndex++;
        
        // Emit progress for this profile
        _progressController.add(BackupProgress(
          stage: BackupProgressStage.collectingData,
          currentItem: 'Collecting data from profile: ${profile.name}',
          currentIndex: profileIndex,
          totalItems: allProfiles.length,
          progress: profileIndex / allProfiles.length * 0.2, // 20% of total for collecting
        ));
        try {
          if (kDebugMode) {
            print('  Processing profile: ${profile.name} (${profile.id})');
          }
          
          // Open boxes for this profile
          final profileProjectsBox = await Hive.openBox<MusicProject>('${profile.id}_projects');
          final profileReleasesBox = await Hive.openBox<Release>('${profile.id}_releases');
          final profileRootsBox = await Hive.openBox<ScanRoot>('${profile.id}_roots');

          if (kDebugMode) {
            print('    Opened boxes: ${profileProjectsBox.length} projects, ${profileReleasesBox.length} releases, ${profileRootsBox.length} roots');
          }

          // Collect phase customization for this profile (custom phase names, colors, finished set)
          try {
            final phasesRaw = appSettingsBox.get('${profile.id}_phases');
            final colorsRaw = appSettingsBox.get('${profile.id}_phase_colors');
            final finishedRaw = appSettingsBox.get('${profile.id}_finished_phases');
            final legacyFinishedRaw = appSettingsBox.get('${profile.id}_finished_phase');
            final phaseSettings = <String, dynamic>{};
            if (phasesRaw != null) phaseSettings['phases'] = jsonDecode(phasesRaw);
            if (colorsRaw != null) phaseSettings['phaseColors'] = jsonDecode(colorsRaw);
            if (finishedRaw != null) {
              phaseSettings['finishedPhases'] = jsonDecode(finishedRaw);
            } else if (legacyFinishedRaw != null) {
              phaseSettings['finishedPhases'] = [legacyFinishedRaw];
            }
            if (phaseSettings.isNotEmpty) {
              phaseSettingsByProfile[profile.id] = phaseSettings;
            }
          } catch (e) {
            if (kDebugMode) print('Error collecting phase settings for profile ${profile.id}: $e');
          }
          
          // Collect projects and track which profile they belong to
          final profileProjectsList = profileProjectsBox.values.toList();
          int profileProjectIndex = 0;
          for (final project in profileProjectsList) {
            profileProjectIndex++;
            final projectFraction = profileProjectsList.isEmpty
                ? 1.0
                : profileProjectIndex / profileProjectsList.length;
            _progressController.add(BackupProgress(
              stage: BackupProgressStage.collectingData,
              currentItem: 'Checking: ${project.displayName}',
              currentIndex: profileProjectIndex,
              totalItems: profileProjectsList.length,
              progress: ((profileIndex - 1) + projectFraction) / allProfiles.length * 0.2,
            ));
            if (!allProjects.any((p) => p.id == project.id)) {
              allProjects.add(project);
            }
            // Track that this project belongs to this profile
            projectToProfileMap[project.id] = profile.id;

            // Check project cover art status (#110). Unlike preview songs and
            // release artwork this runs on mobile too: the appearance dialog
            // is available there, and a cover is a few dozen KB — skipping the
            // upload would silently strand every cover set on a phone.
            if (project.thumbnailPath != null && project.thumbnailPath!.isNotEmpty) {
              try {
                final latestProject = profileProjectsBox.get(project.id);
                final coverPath = latestProject?.thumbnailPath;
                if (latestProject != null && coverPath != null && coverPath.isNotEmpty) {
                  final currentLocalHash = await _calculateFileHash(coverPath);
                  final existingHash = existingProjectCoverArtHashes[latestProject.id];

                  if (existingHash != null && existingHash == currentLocalHash) {
                    // Hash matches — only skip the upload if the file really is
                    // still on Drive.
                    final coverArtFolderId = await _ensureProjectCoverArtFolder();
                    final driveFileName = '${latestProject.id}_cover${path.extension(coverPath)}';
                    final response = await _driveApi!.files.list(
                      q: "name='$driveFileName' and parents in '$coverArtFolderId' and trashed=false",
                      spaces: 'drive',
                    );
                    if (response.files != null && response.files!.isNotEmpty) {
                      projectCoverArtFileMap[latestProject.id] = response.files!.first.id!;
                      projectCoverArtHashes[latestProject.id] = currentLocalHash;
                      if (kDebugMode) print('  Project cover art found in Drive, skipping upload');
                    } else {
                      projectCoverArtToUpload.add({
                        'project': latestProject,
                        'filePath': coverPath,
                        'existingHash': existingHash,
                      });
                    }
                  } else {
                    projectCoverArtToUpload.add({
                      'project': latestProject,
                      'filePath': coverPath,
                      'existingHash': existingHash,
                    });
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  print('  Error checking cover art for project ${project.id}: $e');
                }
              }
            }

            // Check preview song status (only on desktop - mobile doesn't add preview songs)
            // On mobile, we only download preview songs, never upload them
            if (!MobileUtils.isMobile()) {
              if (project.previewSongPath != null && project.previewSongPath!.isNotEmpty) {
                // Skip if it's a Drive reference (already uploaded)
                if (!project.previewSongPath!.startsWith('drive://')) {
                  try {
                    // Retrieve the latest project from Hive to ensure we have the most recent hash
                    final latestProject = profileProjectsBox.get(project.id);
                    if (latestProject == null) {
                      if (kDebugMode) {
                        print('  Project ${project.id} not found in Hive, skipping preview song upload');
                      }
                      continue;
                    }
                    
                    // Calculate current file hash first
                    final currentLocalHash = await _calculateFileHash(latestProject.previewSongPath!);
                    
                    // Compare with hash stored in local database (retrieved from Hive)
                    // Only use existingHashes from backup if project.uploadedPreviewSongHash is null
                    final storedHash = latestProject.uploadedPreviewSongHash;
                    
                    // If hash matches, check if file exists in Drive
                    if (storedHash != null && storedHash == currentLocalHash) {
                      if (kDebugMode) {
                        print('  Preview song hash matches for project ${latestProject.id} (hash: $currentLocalHash), checking Drive...');
                      }
                      // Check if file exists in Drive
                      final previewSongsFolderId = await _ensurePreviewSongsFolder();
                      final fileName = path.basename(latestProject.previewSongPath!);
                      final fileExtension = path.extension(fileName);
                      final driveFileName = '${latestProject.id}_preview$fileExtension';
                      
                      var response = await _driveApi!.files.list(
                        q: "name='$driveFileName' and parents in '$previewSongsFolderId' and trashed=false",
                        spaces: 'drive',
                      );
                      
                      if (response.files != null && response.files!.isNotEmpty) {
                        // File exists in Drive and hash matches - skip upload
                        previewSongFileMap[latestProject.id] = response.files!.first.id!;
                        previewSongHashes[latestProject.id] = currentLocalHash;
                        // Store display name only if it's a real filename (not a UUID backup name)
                        final localBasename = path.basename(latestProject.previewSongPath!);
                        final displayName = latestProject.previewSongFileName ??
                            (_uuidPreviewRe.hasMatch(localBasename) ? null : localBasename);
                        if (displayName != null) {
                          previewSongFileNames[latestProject.id] = displayName;
                        }
                        if (kDebugMode) {
                          print('  Preview song found in Drive, skipping upload');
                        }
                        continue; // Skip to next project
                      } else {
                        // Hash matches but file NOT in Drive - need to upload!
                        if (kDebugMode) {
                          print('  Preview song NOT found in Drive despite matching hash, will upload');
                        }
                        // Fall through to add to upload queue
                      }
                    }
                    
                    // Hash changed or doesn't exist - add to upload queue
                    // Retrieve hash from Hive database (ensure we have the latest version)
                    // Use stored hash from project first, then fallback to existingHashes from backup
                    final existingHash = storedHash ?? existingHashes[latestProject.id];
                    
                    // Add to queue for later upload
                    previewSongsToUpload.add({
                      'project': latestProject,
                      'projectBox': profileProjectsBox,
                      'existingHash': existingHash,
                      'filePath': latestProject.previewSongPath!,
                    });

                    if (kDebugMode) {
                      print('  Preview song needs upload for project ${latestProject.id}');
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('  Error checking preview song for project ${project.id}: $e');
                    }
                  }
                } else {
                  // It's a Drive reference - use hash from project if available
                  if (project.uploadedPreviewSongHash != null) {
                    previewSongHashes[project.id] = project.uploadedPreviewSongHash!;
                  }
                }
              } else if (uploadAutoDetectedSongs &&
                  (project.previewSongPath == null || project.previewSongPath!.isEmpty) &&
                  project.previewSongAutoPath != null &&
                  project.previewSongAutoPath!.isNotEmpty) {
                // No manually-set path — upload the auto-detected one if the setting is on
                try {
                  final latestProject = profileProjectsBox.get(project.id);
                  if (latestProject == null) continue;
                  final autoPath = latestProject.previewSongAutoPath;
                  if (autoPath == null || autoPath.isEmpty) continue;

                  final currentHash = await _calculateFileHash(autoPath);
                  final storedHash = latestProject.uploadedPreviewSongHash;

                  if (storedHash != null && storedHash == currentHash) {
                    // Hash matches — check if already on Drive
                    final previewSongsFolderId = await _ensurePreviewSongsFolder();
                    final driveFileName = '${latestProject.id}_preview${path.extension(autoPath)}';
                    final response = await _driveApi!.files.list(
                      q: "name='$driveFileName' and parents in '$previewSongsFolderId' and trashed=false",
                      spaces: 'drive',
                    );
                    if (response.files != null && response.files!.isNotEmpty) {
                      previewSongFileMap[latestProject.id] = response.files!.first.id!;
                      previewSongHashes[latestProject.id] = currentHash;
                      previewSongFileNames[latestProject.id] = path.basename(autoPath);
                      if (kDebugMode) print('  Auto preview song already on Drive, skipping upload');
                      continue;
                    }
                  }

                  previewSongsToUpload.add({
                    'project': latestProject,
                    'projectBox': profileProjectsBox,
                    'existingHash': storedHash ?? existingHashes[latestProject.id],
                    'filePath': autoPath,
                  });
                  if (kDebugMode) print('  Auto preview song queued for upload: $autoPath');
                } catch (e) {
                  if (kDebugMode) print('  Error checking auto preview song for project ${project.id}: $e');
                }
              }
            }
          }
          
          // Collect releases and track which profile they belong to
          for (final release in profileReleasesBox.values) {
            if (!allReleases.any((r) => r.id == release.id)) {
              allReleases.add(release);
            }
            // Track that this release belongs to this profile
            releaseToProfileMap[release.id] = profile.id;
            
            // Check release artwork status (only on desktop - mobile doesn't upload artwork)
            // On mobile, we only download artwork, never upload them
            if (!MobileUtils.isMobile()) {
              if (release.artworkImagePath != null && release.artworkImagePath!.isNotEmpty) {
                try {
                  // Calculate current file hash
                  final currentLocalHash = await _calculateFileHash(release.artworkImagePath!);
                  
                  // Compare with hash from existing backup
                  final existingHash = existingReleaseArtworkHashes[release.id];
                  
                  // If hash matches, check if file exists in Drive
                  if (existingHash != null && existingHash == currentLocalHash) {
                    if (kDebugMode) {
                      print('  Release artwork hash matches for release ${release.id} (hash: $currentLocalHash), checking Drive...');
                    }
                    // Check if file exists in Drive
                    final releaseArtworkFolderId = await _ensureReleaseArtworkFolder();
                    final fileExtension = path.extension(release.artworkImagePath!);
                    final driveFileName = '${release.id}_artwork$fileExtension';
                    
                    var response = await _driveApi!.files.list(
                      q: "name='$driveFileName' and parents in '$releaseArtworkFolderId' and trashed=false",
                      spaces: 'drive',
                    );
                    
                    if (response.files != null && response.files!.isNotEmpty) {
                      // File exists in Drive and hash matches - skip upload
                      releaseArtworkFileMap[release.id] = response.files!.first.id!;
                      releaseArtworkHashes[release.id] = currentLocalHash;
                      if (kDebugMode) {
                        print('  Release artwork found in Drive, skipping upload');
                      }
                    } else {
                      // Hash matches but file NOT in Drive - need to upload!
                      if (kDebugMode) {
                        print('  Release artwork NOT found in Drive despite matching hash, will upload');
                      }
                      // Add to upload queue
                      releaseArtworkToUpload.add({
                        'release': release,
                        'existingHash': existingHash,
                      });
                    }
                  } else {
                    // Hash changed or doesn't exist - add to upload queue
                    releaseArtworkToUpload.add({
                      'release': release,
                      'existingHash': existingHash,
                    });
                    
                    if (kDebugMode) {
                      print('  Release artwork needs upload for release ${release.id}');
                    }
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('  Error checking release artwork for release ${release.id}: $e');
                  }
                }
              }
            }
          }
          
          // Collect roots and track which profile they belong to
          for (final root in profileRootsBox.values) {
            if (!allRoots.any((r) => r.id == root.id)) {
              allRoots.add(root);
            }
            // Track that this root belongs to this profile
            rootToProfileMap[root.id] = profile.id;
          }
          
          if (kDebugMode) {
            print('  Profile ${profile.name}: ${profileProjectsBox.length} projects, ${profileReleasesBox.length} releases, ${profileRootsBox.length} roots');
          }
          
          // Check profile photo status (only on desktop - mobile doesn't upload profile photos)
          // On mobile, we only download profile photos, never upload them
          if (!MobileUtils.isMobile()) {
            if (profile.photoPath != null && profile.photoPath!.isNotEmpty) {
              try {
                // Calculate current file hash
                final currentLocalHash = await _calculateFileHash(profile.photoPath!);
                
                // Compare with hash from existing backup
                final existingHash = existingProfilePhotoHashes[profile.id];
                
                // If hash matches, check if file exists in Drive
                if (existingHash != null && existingHash == currentLocalHash) {
                  if (kDebugMode) {
                    print('  Profile photo hash matches for profile ${profile.id} (hash: $currentLocalHash), checking Drive...');
                  }
                  // Check if file exists in Drive
                  final profilePhotosFolderId = await _ensureProfilePhotosFolder();
                  final fileExtension = path.extension(profile.photoPath!);
                  final driveFileName = '${profile.id}_photo$fileExtension';
                  
                  var response = await _driveApi!.files.list(
                    q: "name='$driveFileName' and parents in '$profilePhotosFolderId' and trashed=false",
                    spaces: 'drive',
                  );
                  
                  if (response.files != null && response.files!.isNotEmpty) {
                    // File exists in Drive and hash matches - skip upload
                    profilePhotoFileMap[profile.id] = response.files!.first.id!;
                    profilePhotoHashes[profile.id] = currentLocalHash;
                    if (kDebugMode) {
                      print('  Profile photo found in Drive, skipping upload');
                    }
                  } else {
                    // Hash matches but file NOT in Drive - need to upload!
                    if (kDebugMode) {
                      print('  Profile photo NOT found in Drive despite matching hash, will upload');
                    }
                    // Add to upload queue
                    profilePhotosToUpload.add({
                      'profile': profile,
                      'existingHash': existingHash,
                    });
                  }
                } else {
                  // Hash changed or doesn't exist - add to upload queue
                  profilePhotosToUpload.add({
                    'profile': profile,
                    'existingHash': existingHash,
                  });
                  
                  if (kDebugMode) {
                    print('  Profile photo needs upload for profile ${profile.id}');
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  print('  Error checking profile photo for profile ${profile.id}: $e');
                }
              }
            }
          }
          
          // Close boxes after collecting data to free resources
          // Note: We don't close them here because they might be in use by the current repository
          // Instead, we'll let Hive manage them
        } catch (e) {
          if (kDebugMode) {
            print('Error collecting data for profile ${profile.id}: $e');
          }
        }
      }
      
      // Now upload all preview songs that need uploading
      if (kDebugMode) {
        print('Found ${previewSongsToUpload.length} preview songs that need upload');
      }
      
      _lastUploadWarnings = [];

      int uploadedCount = 0;
      for (final uploadInfo in previewSongsToUpload) {
        // Check for cancellation
        if (_isCancelled) {
          throw UploadCancelledException();
        }
        
        uploadedCount++;
        final project = uploadInfo['project'] as MusicProject;
        final projectBox = uploadInfo['projectBox'] as Box<MusicProject>;
        final existingHash = uploadInfo['existingHash'] as String?;
        final filePath = uploadInfo['filePath'] as String;

        // Emit progress
        _progressController.add(BackupProgress(
          stage: BackupProgressStage.uploadingPreviewSongs,
          currentItem: 'Uploading preview: ${path.basename(filePath)}',
          currentIndex: uploadedCount,
          totalItems: previewSongsToUpload.length,
          progress: 0.2 + (uploadedCount / previewSongsToUpload.length * 0.6), // 20-80% range
        ));

        try {
          final result = await _uploadPreviewSongFile(
            projectId: project.id,
            localFilePath: filePath,
            existingHash: existingHash,
          );
          
          if (result != null) {
            previewSongFileMap[project.id] = result['fileId']!;
            final newHash = result['hash']!;
            previewSongHashes[project.id] = newHash;
            if (result.containsKey('fileName')) {
              final basename = result['fileName']!;
              final displayName = project.previewSongFileName ??
                  (_uuidPreviewRe.hasMatch(basename) ? null : basename);
              if (displayName != null) {
                previewSongFileNames[project.id] = displayName;
              }
            }

            // Update project with new hash after successful upload
            final currentProject = projectBox.get(project.id);
            if (currentProject != null) {
              final updatedProject = currentProject.copyWith(uploadedPreviewSongHash: newHash);
              await projectBox.put(project.id, updatedProject);
              await projectBox.flush();
              if (kDebugMode) {
                print('  Updated project ${project.id} with preview song hash: $newHash');
              }
            }

            if (kDebugMode) {
              print('  Uploaded preview song for project ${project.id}: ${result['fileId']} (hash: $newHash)');
            }
          } else {
            _lastUploadWarnings.add('Preview song failed to upload: ${project.displayName}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  Error uploading preview song for project ${project.id}: $e');
          }
          _lastUploadWarnings.add('Preview song error (${project.displayName}): $e');
        }
      }
      
      // Now upload all profile photos that need uploading
      if (kDebugMode) {
        print('Found ${profilePhotosToUpload.length} profile photos that need upload');
      }
      
      uploadedCount = 0;
      for (final uploadInfo in profilePhotosToUpload) {
        // Check for cancellation
        if (_isCancelled) {
          throw UploadCancelledException();
        }
        
        uploadedCount++;
        final profile = uploadInfo['profile'] as Profile;
        final existingHash = uploadInfo['existingHash'] as String?;
        
        // Emit progress
        _progressController.add(BackupProgress(
          stage: BackupProgressStage.uploadingPreviewSongs, // Reuse same stage for simplicity
          currentItem: 'Uploading profile photo: ${profile.name}',
          currentIndex: uploadedCount,
          totalItems: profilePhotosToUpload.length,
          progress: 0.2 + (uploadedCount / profilePhotosToUpload.length * 0.6), // 20-80% range
        ));
        
        try {
          final result = await _uploadProfilePhotoFile(
            profileId: profile.id,
            localFilePath: profile.photoPath!,
            existingHash: existingHash,
          );
          
          if (result != null) {
            profilePhotoFileMap[profile.id] = result['fileId']!;
            final newHash = result['hash']!;
            profilePhotoHashes[profile.id] = newHash;

            if (kDebugMode) {
              print('  Uploaded profile photo for profile ${profile.id}: ${result['fileId']} (hash: $newHash)');
            }
          } else {
            _lastUploadWarnings.add('Profile photo failed to upload: ${profile.name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  Error uploading profile photo for profile ${profile.id}: $e');
          }
          _lastUploadWarnings.add('Profile photo error (${profile.name}): $e');
        }
      }
      
      // Now upload all release artwork that needs uploading
      if (kDebugMode) {
        print('Found ${releaseArtworkToUpload.length} release artworks that need upload');
      }
      
      uploadedCount = 0;
      for (final uploadInfo in releaseArtworkToUpload) {
        // Check for cancellation
        if (_isCancelled) {
          throw UploadCancelledException();
        }
        
        uploadedCount++;
        final release = uploadInfo['release'] as Release;
        final existingHash = uploadInfo['existingHash'] as String?;
        
        // Emit progress
        _progressController.add(BackupProgress(
          stage: BackupProgressStage.uploadingReleaseArtwork,
          currentItem: 'Uploading release artwork: ${release.title}',
          currentIndex: uploadedCount,
          totalItems: releaseArtworkToUpload.length,
          progress: 0.2 + (uploadedCount / releaseArtworkToUpload.length * 0.6), // 20-80% range
        ));
        
        try {
          final result = await _uploadReleaseArtworkFile(
            releaseId: release.id,
            localFilePath: release.artworkImagePath!,
            existingHash: existingHash,
          );
          
          if (result != null) {
            releaseArtworkFileMap[release.id] = result['fileId']!;
            final newHash = result['hash']!;
            releaseArtworkHashes[release.id] = newHash;

            if (kDebugMode) {
              print('  Uploaded release artwork for release ${release.id}: ${result['fileId']} (hash: $newHash)');
            }
          } else {
            _lastUploadWarnings.add('Release artwork failed to upload: ${release.title}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  Error uploading release artwork for release ${release.id}: $e');
          }
          _lastUploadWarnings.add('Release artwork error (${release.title}): $e');
        }
      }
      
      // Now upload all project cover art that needs uploading (#110)
      if (kDebugMode) {
        print('Found ${projectCoverArtToUpload.length} project covers that need upload');
      }

      uploadedCount = 0;
      for (final uploadInfo in projectCoverArtToUpload) {
        if (_isCancelled) {
          throw UploadCancelledException();
        }

        uploadedCount++;
        final project = uploadInfo['project'] as MusicProject;
        final filePath = uploadInfo['filePath'] as String;
        final existingHash = uploadInfo['existingHash'] as String?;

        _progressController.add(BackupProgress(
          stage: BackupProgressStage.uploadingProjectCoverArt,
          currentItem: 'Uploading cover art: ${project.displayName}',
          currentIndex: uploadedCount,
          totalItems: projectCoverArtToUpload.length,
          progress: 0.2 + (uploadedCount / projectCoverArtToUpload.length * 0.6), // 20-80% range
        ));

        try {
          final result = await _uploadProjectCoverArtFile(
            projectId: project.id,
            localFilePath: filePath,
            existingHash: existingHash,
          );

          if (result != null) {
            projectCoverArtFileMap[project.id] = result['fileId']!;
            projectCoverArtHashes[project.id] = result['hash']!;
            if (kDebugMode) {
              print('  Uploaded cover art for project ${project.id}: ${result['fileId']} (hash: ${result['hash']})');
            }
          } else {
            _lastUploadWarnings.add('Project cover art failed to upload: ${project.displayName}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  Error uploading cover art for project ${project.id}: $e');
          }
          _lastUploadWarnings.add('Project cover art error (${project.displayName}): $e');
        }
      }

      // Collect TODO templates (global, not per-profile)
      final List<TodoTemplate> allTemplates = [];
      try {
        final templatesBox = await Hive.openBox<TodoTemplate>('todoTemplates');
        allTemplates.addAll(templatesBox.values);
        if (kDebugMode) {
          print('Collected ${allTemplates.length} TODO templates');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error collecting TODO templates: $e');
        }
      }

      // Collect part templates (global, not per-profile)
      final List<PartTemplate> allPartTemplates = [];
      try {
        final partTemplatesBox = await Hive.openBox<PartTemplate>('partTemplates');
        allPartTemplates.addAll(partTemplatesBox.values);
        if (kDebugMode) {
          print('Collected ${allPartTemplates.length} part templates');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error collecting part templates: $e');
        }
      }

      // Collect project templates (global, not per-profile)
      final List<ProjectTemplate> allProjectTemplates = [];
      try {
        final projectTemplatesBox = await Hive.openBox<ProjectTemplate>('projectTemplates');
        allProjectTemplates.addAll(projectTemplatesBox.values);
        if (kDebugMode) {
          print('Collected ${allProjectTemplates.length} project templates');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error collecting project templates: $e');
        }
      }

      // Collect template roots (global, not per-profile)
      final List<TemplateRoot> allTemplateRoots = [];
      try {
        final templateRootsBox = await Hive.openBox<TemplateRoot>('templateRoots');
        allTemplateRoots.addAll(templateRootsBox.values);
        if (kDebugMode) {
          print('Collected ${allTemplateRoots.length} template roots');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error collecting template roots: $e');
        }
      }

      // Collect custom mixdown folders (global preference, not per-profile)
      List<String> customMixdownFolders = [];
      try {
        final raw = appSettingsBox.get('customMixdownFolders');
        if (raw != null) {
          customMixdownFolders = (jsonDecode(raw) as List).map((e) => e.toString()).toList();
        }
        if (kDebugMode) {
          print('Collected ${customMixdownFolders.length} custom mixdown folders');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error collecting custom mixdown folders: $e');
        }
      }

      // Collect user-authored themes (global preference, not per-profile).
      // The theme *definitions* sync; which one is selected does not — that
      // is device-local, so a laptop and a desktop can sit on different
      // themes while both still have the whole set available.
      List<dynamic> customThemes = [];
      try {
        final raw = appSettingsBox.get('customThemes');
        if (raw != null) {
          customThemes = jsonDecode(raw) as List;
        }
        if (kDebugMode) {
          print('Collected ${customThemes.length} custom themes');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error collecting custom themes: $e');
        }
      }

      // Collect per-DAW custom mixdown folders (global preference, not per-profile)
      Map<String, dynamic> customMixdownFoldersByDaw = {};
      try {
        final raw = appSettingsBox.get('customMixdownFoldersByDaw');
        if (raw != null) {
          customMixdownFoldersByDaw = jsonDecode(raw) as Map<String, dynamic>;
        }
        if (kDebugMode) {
          print('Collected per-DAW mixdown folders for ${customMixdownFoldersByDaw.length} DAWs');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error collecting per-DAW custom mixdown folders: $e');
        }
      }

      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.7', // Incremented to include custom themes
        'profiles': allProfiles.map((p) => _serializeProfile(p)).toList(),
        'projects': allProjects.map((p) => _serializeProject(p)).toList(),
        'releases': allReleases.map((r) => _serializeRelease(r)).toList(),
        'roots': allRoots.map((r) => _serializeRoot(r)).toList(),
        'templates': allTemplates.map((t) => _serializeTemplate(t)).toList(),
        'partTemplates': allPartTemplates.map((t) => t.toJson()).toList(),
        'projectTemplates': allProjectTemplates.map((t) => _serializeProjectTemplate(t)).toList(),
        'templateRoots': allTemplateRoots.map((r) => _serializeTemplateRoot(r)).toList(),
        // NEW: Custom mixdown folder names (global preference, not per-profile)
        'customMixdownFolders': customMixdownFolders,
        // NEW: Per-DAW custom mixdown folder names (global preference, not per-profile)
        'customMixdownFoldersByDaw': customMixdownFoldersByDaw,
        // NEW: User-authored themes (global preference, not per-profile).
        // Definitions only — the selected theme stays device-local.
        'customThemes': customThemes,
        // NEW: Per-profile phase customization (custom phase names, colors, finished set)
        'phaseSettingsByProfile': phaseSettingsByProfile,
        // NEW: Profile mappings to restore correct associations
        'projectToProfile': projectToProfileMap,
        'releaseToProfile': releaseToProfileMap,
        'rootToProfile': rootToProfileMap,
        // NEW: Preview song file mappings (projectId -> driveFileId)
        'previewSongFiles': previewSongFileMap,
        // NEW: Preview song hashes (projectId -> fileHash) for change detection
        'previewSongHashes': previewSongHashes,
        // NEW: Preview song original filenames (projectId -> originalFileName)
        'previewSongFileNames': previewSongFileNames,
        // NEW: Profile photo file mappings (profileId -> driveFileId)
        'profilePhotoFiles': profilePhotoFileMap,
        // NEW: Profile photo hashes (profileId -> fileHash) for change detection
        'profilePhotoHashes': profilePhotoHashes,
        // NEW: Release artwork file mappings (releaseId -> driveFileId)
        'releaseArtworkFiles': releaseArtworkFileMap,
        // NEW: Release artwork hashes (releaseId -> fileHash) for change detection
        'releaseArtworkHashes': releaseArtworkHashes,
        // NEW: Project cover art file mappings (projectId -> driveFileId) (#110)
        'projectCoverArtFiles': projectCoverArtFileMap,
        // NEW: Project cover art hashes (projectId -> fileHash) for change detection
        'projectCoverArtHashes': projectCoverArtHashes,
      };

      // Check for cancellation before database upload
      if (_isCancelled) {
        throw UploadCancelledException();
      }
      
      // Emit progress: uploading database
      _progressController.add(BackupProgress(
        stage: BackupProgressStage.uploadingDatabase,
        currentItem: 'Uploading database backup...',
        currentIndex: 1,
        totalItems: 1,
        progress: 0.85, // 85%
      ));
      
      final jsonData = jsonEncode(data);
      final bytes = utf8.encode(jsonData);

      // Use a single filename for the entire application backup
      // No profileId in filename - this is the complete app backup
      final fileName = _databaseFileName;
      if (kDebugMode) {
        print('=== Upload Complete Application Backup ===');
        print('Platform: ${Platform.operatingSystem}');
        print('File name: $fileName');
        print('Shared folder ID: $_appDataFolderId');
        print('Shared folder name: $_appDataFolderName');
        print('Spaces: drive (shared folder)');
        print('Profiles included: ${(data['profiles'] as List).length}');
        print('Projects included: ${(data['projects'] as List).length}');
        print('Releases included: ${(data['releases'] as List).length}');
        print('Templates included: ${(data['templates'] as List).length}');
        print('Part templates included: ${(data['partTemplates'] as List).length}');
        print('Project templates included: ${(data['projectTemplates'] as List).length}');
        print('Template roots included: ${(data['templateRoots'] as List).length}');
      }
      final response = await _driveApi!.files.list(
        q: "name='$fileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files != null && response.files!.isNotEmpty) {
        // Update existing file
        final fileId = response.files!.first.id!;
        await _withRetry(() => _driveApi!.files.update(
          drive.File()..name = fileName,
          fileId,
          uploadMedia: drive.Media(Stream.value(bytes), bytes.length, contentType: 'application/json'),
        ));
        if (kDebugMode) print('✓ Updated existing backup file');
      } else {
        // Create new file
        final driveFile = drive.File()
          ..name = fileName
          ..parents = [_appDataFolderId!];
        await _withRetry(() => _driveApi!.files.create(
          driveFile,
          uploadMedia: drive.Media(Stream.value(bytes), bytes.length, contentType: 'application/json'),
        ));
        if (kDebugMode) print('✓ Created new backup file');
      }

      // Update sync metadata (global, not per-profile)
      final uploadTimestamp = DateTime.now();
      await _updateSyncMetadata(uploadTimestamp);
      
      // Save local timestamp for this device's last upload
      await saveLastBackupUploadTimestamp(uploadTimestamp);
      
      // After uploading, this device has the most recent version
      // Update last download timestamp to reflect that we're in sync
      await saveLastBackupDownloadTimestamp(uploadTimestamp);
      
      // Emit progress: completed (include any non-fatal warnings)
      _progressController.add(BackupProgress(
        stage: BackupProgressStage.completed,
        currentItem: _lastUploadWarnings.isEmpty
            ? 'Backup completed successfully!'
            : 'Backup completed with ${_lastUploadWarnings.length} warning(s)',
        currentIndex: 1,
        totalItems: 1,
        progress: 1.0,
        warnings: List.unmodifiable(_lastUploadWarnings),
      ));
    } catch (e) {
      if (kDebugMode) print('Error uploading database: $e');
      rethrow;
    }
  }

  /// Download database from Google Drive
  /// Downloads the complete application backup (all profiles, projects, releases, etc.)
  /// Mobile will use this to mirror the desktop app
  Future<Map<String, dynamic>> downloadDatabase() async {
    if (_driveApi == null || _appDataFolderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      // Use a single filename for the entire application backup
      // No profileId in filename - this is the complete app backup
      final fileName = _databaseFileName;
      if (kDebugMode) {
        print('=== Download Complete Application Backup ===');
        print('Platform: ${Platform.operatingSystem}');
        print('File name searched: $fileName');
        print('Shared folder ID: $_appDataFolderId');
        print('Shared folder name: $_appDataFolderName');
        print('Spaces: drive (shared folder)');
      }
      final response = await _driveApi!.files.list(
        q: "name='$fileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files == null || response.files!.isEmpty) {
        if (kDebugMode) {
          print('❌ Database file not found in Google Drive');
          print('File name searched: $fileName');
          print('Shared folder ID: $_appDataFolderId');
          print('Shared folder name: $_appDataFolderName');
          print('');
          print('🔍 DEBUG: Listing all files in shared folder...');
          // List all files in shared folder to help debug
          try {
            final allFiles = await _driveApi!.files.list(
              q: "parents in '$_appDataFolderId' and trashed=false",
              spaces: 'drive',
            );
            if (allFiles.files != null && allFiles.files!.isNotEmpty) {
              print('✅ Files found in shared folder (${allFiles.files!.length} files):');
              for (final file in allFiles.files!) {
                print('  - ${file.name} (ID: ${file.id})');
                // Check if this file matches the pattern we're looking for
                if (file.name?.contains('database_backup.json') == true) {
                  print('    ⚠️ This is a backup file but with a different name?');
                  print('    Expected: $fileName');
                  print('    Found: ${file.name}');
                }
              }
              print('');
              print('💡 TIP: The backup file should be named exactly: $fileName');
              print('   This is the complete application backup (all profiles included).');
            } else {
              print('❌ No files found in shared folder');
              print('   The folder exists but is empty.');
            }
          } catch (e) {
            print('❌ Error listing files: $e');
          }
          
          // Also try to find the folder by name to verify it exists
          print('');
          print('🔍 DEBUG: Verifying folder exists...');
          try {
            final folderCheck = await _driveApi!.files.list(
              q: "name='$_appDataFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
              spaces: 'drive',
            );
            if (folderCheck.files != null && folderCheck.files!.isNotEmpty) {
              print('✅ Folder found: ${folderCheck.files!.first.name} (ID: ${folderCheck.files!.first.id})');
              if (folderCheck.files!.first.id != _appDataFolderId) {
                print('⚠️ WARNING: Folder ID mismatch!');
                print('   Expected: $_appDataFolderId');
                print('   Found: ${folderCheck.files!.first.id}');
              }
            } else {
              print('❌ Folder not found!');
            }
          } catch (e) {
            print('❌ Error checking folder: $e');
          }
        }
        throw Exception('Database file not found in Google Drive');
      }

      final fileId = response.files!.first.id!;
      final media = await _withRetry(() async => (await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      )) as drive.Media);

      // Read file content
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Save timestamp of this download
      // Use timestamp from backup JSON if available, otherwise use current time
      DateTime downloadTimestamp = DateTime.now();
      if (backupData['timestamp'] != null) {
        try {
          downloadTimestamp = DateTime.parse(backupData['timestamp'] as String);
        } catch (_) {
          // If parsing fails, use current time
        }
      }
      await saveLastBackupDownloadTimestamp(downloadTimestamp);
      
      return backupData;
    } catch (e) {
      if (kDebugMode) {
        if (e.toString().contains('Database file not found')) {
          print('No backup file found (this is normal for first-time setup)');
          print('You can create an initial backup by syncing or uploading your data');
        } else {
          print('Error downloading database: $e');
        }
      }
      rethrow;
    }
  }

  /// Get last sync time for the application (global, not per-profile)
  Future<DateTime?> getLastSyncTime() async {
    try {
      final metadata = await _getSyncMetadata();
      // Metadata now stores a single 'lastSync' timestamp for the entire app
      return metadata['lastSync'] != null 
          ? DateTime.parse(metadata['lastSync'] as String)
          : null;
    } catch (e) {
      if (kDebugMode) print('Error getting last sync time: $e');
      return null;
    }
  }

  /// Update sync metadata (global for entire application)
  Future<void> _updateSyncMetadata(DateTime syncTime) async {
    if (_driveApi == null || _appDataFolderId == null) {
      return;
    }

    try {
      Map<String, dynamic> metadata = {};
      
      // Try to get existing metadata
      try {
        final existingMetadata = await _getSyncMetadata();
        metadata = existingMetadata;
      } catch (_) {
        // Metadata doesn't exist yet, create new
      }

      // Store single timestamp for the entire application
      metadata['lastSync'] = syncTime.toIso8601String();

      final jsonData = jsonEncode(metadata);
      final bytes = utf8.encode(jsonData);

      // Find or create metadata file
      final response = await _driveApi!.files.list(
        q: "name='$_metadataFileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files != null && response.files!.isNotEmpty) {
        // Update existing file
        final fileId = response.files!.first.id!;
        final media = drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: 'application/json',
        );
        await _driveApi!.files.update(
          drive.File()..name = _metadataFileName,
          fileId,
          uploadMedia: media,
        );
      } else {
        // Create new file
        final file = drive.File();
        file.name = _metadataFileName;
        file.parents = [_appDataFolderId!];
        
        final media = drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: 'application/json',
        );
        await _driveApi!.files.create(file, uploadMedia: media);
      }
    } catch (e) {
      if (kDebugMode) print('Error updating sync metadata: $e');
    }
  }

  /// Get sync metadata
  Future<Map<String, dynamic>> _getSyncMetadata() async {
    if (_driveApi == null || _appDataFolderId == null) {
      return {};
    }

    try {
      final response = await _driveApi!.files.list(
        q: "name='$_metadataFileName' and parents in '$_appDataFolderId' and trashed=false",
        spaces: 'drive',
      );

      if (response.files == null || response.files!.isEmpty) {
        return {};
      }

      final fileId = response.files!.first.id!;
      final media = await _withRetry(() async => (await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      )) as drive.Media);

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) print('Error getting sync metadata: $e');
      return {};
    }
  }

  /// Sync database (merge local and remote) with conflict detection
  /// Syncs the ENTIRE application (all profiles, projects, releases, etc.)
  /// Mobile will mirror the desktop app
  Future<SyncResult> syncDatabase({
    required ProjectRepository projectRepo,
    required ProfileRepository profileRepo,
    String? profileId, // Optional - kept for compatibility but not used
    bool uploadAutoDetectedSongs = false,
  }) async {
    try {
      if (kDebugMode) print('Starting complete application sync...');
      
      // Get last sync times (global, not per-profile)
      final localLastModified = await _getLocalLastModified(profileRepo);
      final remoteLastSync = await getLastSyncTime();
      
      if (kDebugMode) {
        print('Local last modified: $localLastModified');
        print('Remote last sync: $remoteLastSync');
      }

      // Check if remote backup exists
      bool remoteExists = false;
      try {
        await downloadDatabase();
        remoteExists = true;
      } catch (_) {
        // Remote doesn't exist yet
        remoteExists = false;
      }

      // If no remote backup exists, just upload
      if (!remoteExists) {
        if (kDebugMode) print('No remote backup found, uploading complete local data...');
        await uploadDatabase(
          projectRepo: projectRepo,
          profileRepo: profileRepo,
          uploadAutoDetectedSongs: uploadAutoDetectedSongs,
        );
        return SyncResult(
          projectsAdded: 0,
          projectsUpdated: 0,
          releasesAdded: 0,
          releasesUpdated: 0,
        );
      }

      // Download remote data to check for conflicts
      final remoteData = await downloadDatabase();
      final remoteTimestamp = remoteData['timestamp'] != null 
          ? DateTime.parse(remoteData['timestamp'] as String)
          : null;

      // Conflict detection: if both local and remote were modified since last sync
      bool hasConflict = false;
      if (localLastModified != null && remoteLastSync != null && remoteTimestamp != null) {
        // Check if local was modified after last sync
        final localModifiedAfterSync = localLastModified.isAfter(remoteLastSync);
        // Check if remote was modified after last sync
        final remoteModifiedAfterSync = remoteTimestamp.isAfter(remoteLastSync);
        
        // Conflict: both were modified
        hasConflict = localModifiedAfterSync && remoteModifiedAfterSync;
        
        if (kDebugMode) {
          print('Conflict detection:');
          print('  Local modified after sync: $localModifiedAfterSync');
          print('  Remote modified after sync: $remoteModifiedAfterSync');
          print('  Has conflict: $hasConflict');
        }
      }

      if (hasConflict) {
        if (kDebugMode) print('Conflict detected! Both local and remote were modified.');
        // For conflicts, we'll merge intelligently (prefer newer data)
        // This could be improved with user interaction to choose which version to keep
      }

      // Merge data (handles conflicts by preferring newer timestamps)
      // This merges ALL profiles, projects, and releases
      // For sync operations, always download preview songs (default behavior)
      final result = await mergeData(
        remoteData: remoteData,
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: true, // Always download during sync
      );

      // Upload merged data (complete application backup)
      await uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        uploadAutoDetectedSongs: uploadAutoDetectedSongs,
      );

      if (kDebugMode) {
        print('Sync completed:');
        print('  Projects: +${result.projectsAdded} ~${result.projectsUpdated}');
        print('  Releases: +${result.releasesAdded} ~${result.releasesUpdated}');
        if (hasConflict) print('  ⚠️ Conflict was resolved by merging');
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('Error syncing database: $e');
      rethrow;
    }
  }

  /// Get local last modified time (checks ALL profiles)
  Future<DateTime?> _getLocalLastModified(ProfileRepository profileRepo) async {
    try {
      DateTime? lastModified;
      
      // Check all profiles
      for (final profile in profileRepo.getAllProfiles()) {
        try {
          final projectsBox = await Hive.openBox<MusicProject>('${profile.id}_projects');
          final releasesBox = await Hive.openBox<Release>('${profile.id}_releases');
          
          for (final project in projectsBox.values) {
            if (lastModified == null || project.updatedAt.isAfter(lastModified)) {
              lastModified = project.updatedAt;
            }
          }
          
          for (final release in releasesBox.values) {
            // Releases don't have updatedAt, use a default
            final releaseTime = DateTime.now();
            if (lastModified == null || releaseTime.isAfter(lastModified)) {
              lastModified = releaseTime;
            }
          }
        } catch (e) {
          // Skip if box doesn't exist for this profile
          if (kDebugMode) print('Skipping profile ${profile.id}: $e');
        }
      }
      
      return lastModified;
    } catch (e) {
      if (kDebugMode) print('Error getting local last modified: $e');
      return null;
    }
  }

  /// Helper to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Compare todos lists (by content, not just reference)
  bool _todosEqual(List<TodoItem> a, List<TodoItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].text != b[i].text ||
          a[i].completed != b[i].completed ||
          a[i].dueAt != b[i].dueAt) {
        return false;
      }
    }
    return true;
  }

  /// Check if metadata fields changed (user-editable fields, not file system fields)
  /// Android only modifies metadata (todos, notes, bpm, key, status, etc.)
  /// We don't use updatedAt because it can change when file is modified on disk
  bool _hasMetadataChanged(MusicProject remote, MusicProject local) {
    // Compare metadata fields (user-editable) AND date fields from the DAW file.
    // lastModifiedAt and fileCreatedAt come from the desktop filesystem via the backup
    // and must be propagated to mobile — they are NOT derived from the Android filesystem.
    return remote.notes != local.notes ||
        !_todosEqual(remote.todos, local.todos) ||
        !_listEquals(remote.parts, local.parts) ||
        !_listEquals(remote.attachments, local.attachments) ||
        remote.bpm != local.bpm ||
        remote.musicalKey != local.musicalKey ||
        remote.status != local.status ||
        remote.customDisplayName != local.customDisplayName ||
        remote.hidden != local.hidden ||
        remote.deadline != local.deadline ||
        remote.ignoredNewerSongPath != local.ignoredNewerSongPath ||
        remote.lastModifiedAt != local.lastModifiedAt ||
        remote.fileCreatedAt != local.fileCreatedAt ||
        remote.accentColor != local.accentColor ||
        remote.iconKey != local.iconKey;
  }

  /// Merge remote data with local data
  /// Merges ALL profiles, projects, and releases from the complete application backup
  /// Made public for manual download operations
  /// [downloadPreviewSongs] - If true, downloads preview song files during merge (default: true)
  Future<SyncResult> mergeData({
    required Map<String, dynamic> remoteData,
    required ProjectRepository projectRepo,
    required ProfileRepository profileRepo,
    bool downloadPreviewSongs = true,
  }) async {
    _mergeHashCache.clear();

    int projectsAdded = 0;
    int projectsUpdated = 0;
    int releasesAdded = 0;
    int releasesUpdated = 0;
    int previewSongsDownloaded = 0;
    int previewSongsUpdated = 0;

    // Emit initial progress
    _progressController.add(BackupProgress(
      stage: BackupProgressStage.mergingData,
      currentItem: 'Starting backup download...',
      currentIndex: 0,
      totalItems: 1,
      progress: 0.0,
    ));

    // First, merge profiles
    if (remoteData['profiles'] != null) {
      final remoteProfiles = (remoteData['profiles'] as List)
          .map((p) => _deserializeProfile(p as Map<String, dynamic>))
          .toList();
      
      // Get profile photo file mappings (if available)
      // Maps profileId -> driveFileId
      final profilePhotoFiles = remoteData['profilePhotoFiles'] as Map<String, dynamic>?;
      // Get profile photo hashes (if available)
      // Maps profileId -> fileHash
      final profilePhotoHashes = remoteData['profilePhotoHashes'] as Map<String, dynamic>?;
      
      // Count photos to download
      int photosToDownload = 0;
      if (downloadPreviewSongs && profilePhotoFiles != null) {
        photosToDownload = profilePhotoFiles.length;
      }
      
      int photoIndex = 0;
      
      for (final remoteProfile in remoteProfiles) {
        if (_isCancelled) throw UploadCancelledException('Download cancelled by user');
        final localProfile = profileRepo.getProfileById(remoteProfile.id);
        
        // Download profile photo if available and downloadPreviewSongs is true
        Profile profileToSave = remoteProfile;
        if (downloadPreviewSongs && profilePhotoFiles != null && profilePhotoFiles.containsKey(remoteProfile.id)) {
          try {
            photoIndex++;
            
            // Emit progress for profile photo download
            _progressController.add(BackupProgress(
              stage: BackupProgressStage.downloadingProfilePhotos,
              currentItem: 'Downloading profile photo: ${remoteProfile.name}',
              currentIndex: photoIndex,
              totalItems: photosToDownload,
              progress: 0.05 + (photoIndex / photosToDownload * 0.15), // 5-20%
            ));
            
            final driveFileId = profilePhotoFiles[remoteProfile.id] as String;
            String? expectedHash;
            if (profilePhotoHashes != null && profilePhotoHashes.containsKey(remoteProfile.id)) {
              expectedHash = profilePhotoHashes[remoteProfile.id] as String;
            }
            
            // Determine file extension from remote photoPath
            String? fileExtension;
            if (remoteProfile.photoPath != null) {
              fileExtension = path.extension(remoteProfile.photoPath!);
            }
            
            // Download profile photo file
            final localFilePath = await downloadProfilePhotoFile(
              driveFileId: driveFileId,
              profileId: remoteProfile.id,
              expectedHash: expectedHash,
              fileExtension: fileExtension,
            );
            
            if (localFilePath != null) {
              profileToSave = remoteProfile.copyWith(
                photoPath: localFilePath,
              );
              if (kDebugMode) {
                print('    Downloaded profile photo for profile: ${remoteProfile.name} (ID: $driveFileId)');
              }
            } else {
              // Download failed, keep remote photoPath as is
              if (kDebugMode) {
                print('    Failed to download profile photo for: ${remoteProfile.name}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('    Error downloading profile photo for profile ${remoteProfile.id}: $e');
            }
            // Continue without profile photo
          }
        }
        
        if (localProfile == null) {
          // New profile from remote - add it
          await profileRepo.profilesBox.put(profileToSave.id, profileToSave);
          if (kDebugMode) print('Added new profile from backup: ${profileToSave.name}');
        } else {
          // Update existing profile (merge metadata)
          await profileRepo.profilesBox.put(profileToSave.id, profileToSave);
          if (kDebugMode) print('Updated profile from backup: ${profileToSave.name}');
        }
      }
    }

    // Now merge projects and releases for the CORRECT profiles
    // The backup contains profile mappings to restore correct associations
    // Get all profiles (including newly merged ones)
    final allProfiles = profileRepo.getAllProfiles();
    
    // Get profile mappings from backup (if available, for version 1.1+)
    final projectToProfileMap = remoteData['projectToProfile'] as Map<String, dynamic>?;
    final releaseToProfileMap = remoteData['releaseToProfile'] as Map<String, dynamic>?;
    final rootToProfileMap = remoteData['rootToProfile'] as Map<String, dynamic>?;
    
    // Get preview song file mappings (if available, for version 1.2+)
    // Maps projectId -> driveFileId
    final previewSongFiles = remoteData['previewSongFiles'] as Map<String, dynamic>?;
    // Get preview song original filenames (if available, for version 1.3+)
    // Maps projectId -> originalFileName
    final previewSongFileNames = remoteData['previewSongFileNames'] as Map<String, dynamic>?;
    // Get preview song hashes (if available, for version 1.3+)
    // Maps projectId -> fileHash
    final previewSongHashes = remoteData['previewSongHashes'] as Map<String, dynamic>?;
    
    // Get release artwork file mappings (if available, for version 1.6+)
    // Maps releaseId -> driveFileId
    final releaseArtworkFiles = remoteData['releaseArtworkFiles'] as Map<String, dynamic>?;
    // Get release artwork hashes (if available, for version 1.6+)
    // Maps releaseId -> fileHash
    final releaseArtworkHashes = remoteData['releaseArtworkHashes'] as Map<String, dynamic>?;
    
    // Count release artwork files to download
    int artworkToDownload = 0;
    if (downloadPreviewSongs && releaseArtworkFiles != null) {
      artworkToDownload = releaseArtworkFiles.length;
    }
    
    int artworkIndex = 0;

    // Get project cover art mappings (#110). Maps projectId -> driveFileId and
    // projectId -> fileHash; both absent on any backup written before #110.
    final projectCoverArtFiles = remoteData['projectCoverArtFiles'] as Map<String, dynamic>?;
    final projectCoverArtHashes = remoteData['projectCoverArtHashes'] as Map<String, dynamic>?;

    int coverArtToDownload = 0;
    if (downloadPreviewSongs && projectCoverArtFiles != null) {
      coverArtToDownload = projectCoverArtFiles.length;
    }

    int coverArtIndex = 0;
    
    // Create reverse lookup: profileId -> list of project/release/root IDs
    final profileToProjects = <String, List<String>>{};
    final profileToReleases = <String, List<String>>{};
    final profileToRoots = <String, List<String>>{};
    
    if (projectToProfileMap != null) {
      // New format (v1.1+): Use profile mappings
      projectToProfileMap.forEach((projectId, profileId) {
        profileToProjects.putIfAbsent(profileId.toString(), () => []).add(projectId);
      });
    }
    
    if (releaseToProfileMap != null) {
      releaseToProfileMap.forEach((releaseId, profileId) {
        profileToReleases.putIfAbsent(profileId.toString(), () => []).add(releaseId);
      });
    }
    
    if (rootToProfileMap != null) {
      rootToProfileMap.forEach((rootId, profileId) {
        profileToRoots.putIfAbsent(profileId.toString(), () => []).add(rootId);
      });
    }
    
    // Count total preview songs to download for progress tracking
    int totalPreviewSongs = 0;
    int downloadedPreviewSongs = 0;
    if (downloadPreviewSongs && previewSongFiles != null) {
      totalPreviewSongs = previewSongFiles.length;
    }
    
    if (kDebugMode) {
      if (projectToProfileMap != null) {
        print('Using profile mappings from backup (v1.1+)');
        print('Projects will be distributed to correct profiles');
      } else {
        print('No profile mappings found (old backup format) - distributing to ALL profiles');
      }
      if (totalPreviewSongs > 0) {
        print('Found $totalPreviewSongs preview songs to download');
      }
    }
    
    // Merge projects - distribute to CORRECT profiles (or ALL if no mappings)
    if (remoteData['projects'] != null) {
      final remoteProjects = (remoteData['projects'] as List)
          .map((p) => _deserializeProject(p as Map<String, dynamic>))
          .toList();
      
      // If we have profile mappings, use them; otherwise distribute to all profiles (backward compatibility)
      final targetProfiles = projectToProfileMap != null 
          ? allProfiles.where((p) => profileToProjects.containsKey(p.id)).toList()
          : allProfiles;
      
      for (final profile in targetProfiles) {
        try {
          final profileProjectsBox = await Hive.openBox<MusicProject>('${profile.id}_projects');
          int profileProjectsAdded = 0;
          int profileProjectsUpdated = 0;
          
          // Get projects that belong to this profile
          final profileProjectIds = projectToProfileMap != null
              ? (profileToProjects[profile.id] ?? [])
              : remoteProjects.map((p) => p.id).toList(); // All projects if no mapping
          
          for (final remoteProject in remoteProjects) {
            if (_isCancelled) throw UploadCancelledException('Download cancelled by user');
            // Only process if this project belongs to this profile (or all if no mapping)
            if (profileProjectIds.contains(remoteProject.id)) {
              final localProject = profileProjectsBox.get(remoteProject.id);
              
              if (localProject == null) {
                // New project from remote
                MusicProject projectToSave = remoteProject;
                if (previewSongFiles != null && previewSongFiles.containsKey(remoteProject.id)) {
                  try {
                    downloadedPreviewSongs++;
                    
                    final driveFileId = previewSongFiles[remoteProject.id] as String;
                    // Get original filename and hash if available
                    String? originalFileName;
                    String? expectedHash;
                    if (previewSongFileNames != null && previewSongFileNames.containsKey(remoteProject.id)) {
                      originalFileName = previewSongFileNames[remoteProject.id] as String;
                    }
                    // Fallback for old backups that predate the previewSongFileNames map:
                    // use the basename of the remote project's path (the real filename on
                    // the uploading machine) rather than showing a UUID filename.
                    if (originalFileName == null &&
                        remoteProject.previewSongPath != null &&
                        !_isDriveFileReference(remoteProject.previewSongPath!)) {
                      originalFileName = _realPreviewFileNameOrNull(remoteProject.previewSongPath);
                    }
                    if (previewSongHashes != null && previewSongHashes.containsKey(remoteProject.id)) {
                      expectedHash = previewSongHashes[remoteProject.id] as String;
                    }

                    // Emit progress for preview song download
                    _progressController.add(BackupProgress(
                      stage: BackupProgressStage.downloadingPreviewSongs,
                      currentItem: 'Downloading preview: ${originalFileName ?? remoteProject.displayName}',
                      currentIndex: downloadedPreviewSongs,
                      totalItems: totalPreviewSongs,
                      progress: 0.20 + (downloadedPreviewSongs / totalPreviewSongs * 0.70), // 20-90%
                    ));
                    
                    // Download preview song file (all platforms)
                    String? fileExtension;
                    if (originalFileName != null) {
                      fileExtension = path.extension(originalFileName);
                    }
                    
                    final localFilePath = await downloadPreviewSongFile(
                      driveFileId: driveFileId,
                      projectId: remoteProject.id,
                      expectedHash: expectedHash,
                      fileExtension: fileExtension,
                    );
                    
                    if (localFilePath != null) {
                      projectToSave = remoteProject.copyWith(
                        previewSongPath: localFilePath,
                        previewSongFileName: originalFileName,
                        uploadedPreviewSongHash: expectedHash,
                      );
                      previewSongsDownloaded++;
                      if (kDebugMode) {
                        print('    Downloaded preview song for new project: ${remoteProject.displayName} (ID: $driveFileId)');
                      }
                    } else {
                      // Download failed, store Drive reference as fallback
                      final driveReference = _createDriveFileReference(driveFileId);
                      projectToSave = remoteProject.copyWith(
                        previewSongPath: driveReference,
                        previewSongFileName: originalFileName,
                        uploadedPreviewSongHash: expectedHash,
                      );
                      if (kDebugMode) {
                        print('    Download failed, stored Drive reference for: ${remoteProject.displayName} (ID: $driveFileId)');
                      }
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('    Error processing preview song for project ${remoteProject.id}: $e');
                    }
                    // Continue without preview song
                  }
                }
                
                await profileProjectsBox.put(projectToSave.id, projectToSave);
                projectsAdded++;
                profileProjectsAdded++;
                if (kDebugMode) {
                  print('    + Added new project: ${remoteProject.displayName}');
                }
              } else {
                // Merge: Compare metadata fields (not file system changes)
                // Android only modifies metadata (todos, notes, bpm, key, status, etc.)
                // We need to check if any metadata field changed, not just updatedAt
                // (updatedAt can change when file is modified on disk, not just metadata)
                
                final metadataChanged = _hasMetadataChanged(remoteProject, localProject);
                // Only let remote's metadata win if it is actually the newer side.
                // Without this check, a project edited locally after the last upload
                // (but before this merge runs) would have those fresh local edits
                // silently discarded in favor of a stale remote copy — the opposite
                // of the "prefer newer data" conflict resolution this is meant to do.
                final remoteIsNewer = remoteProject.updatedAt.isAfter(localProject.updatedAt);

                if (metadataChanged && remoteIsNewer) {
                  // Metadata changed - merge intelligently
                  // Keep file system fields from local (filePath, fileName, fileSizeBytes, lastModifiedAt, etc.)
                  // But update metadata fields from remote (todos, notes, bpm, key, status, etc.)
                  
                  // Update preview song reference if available
                  String? previewSongPath = localProject.previewSongPath;
                  String? previewSongFileName;
                  String? uploadedPreviewSongHash;
                  if (previewSongFiles != null && previewSongFiles.containsKey(remoteProject.id)) {
                    try {
                      final driveFileId = previewSongFiles[remoteProject.id] as String;
                      // Get original filename and hash if available
                      if (previewSongFileNames != null && previewSongFileNames.containsKey(remoteProject.id)) {
                        previewSongFileName = previewSongFileNames[remoteProject.id] as String;
                      }
                      // Fallback for old backups: derive display name from the remote
                      // project's path (real filename on the uploading machine).
                      if (previewSongFileName == null &&
                          remoteProject.previewSongPath != null &&
                          !_isDriveFileReference(remoteProject.previewSongPath!)) {
                        previewSongFileName = _realPreviewFileNameOrNull(remoteProject.previewSongPath);
                      }
                      if (previewSongHashes != null && previewSongHashes.containsKey(remoteProject.id)) {
                        uploadedPreviewSongHash = previewSongHashes[remoteProject.id] as String;
                      }

                      if (downloadPreviewSongs) {
                        // On mobile, only download preview songs after backup is downloaded
                        // Check if we need to download (if path is Drive reference or hash changed)
                        bool needsDownload = false;
                        
                        // First, check if file exists locally (especially on mobile)
                        String? localFilePath;
                        if (previewSongPath != null && !_isDriveFileReference(previewSongPath)) {
                          // Path exists and is not a Drive reference - check if file actually exists
                          final localFile = File(previewSongPath);
                          if (await localFile.exists()) {
                            localFilePath = previewSongPath;
                            // File exists locally - verify hash if we have expected hash
                            if (uploadedPreviewSongHash != null) {
                              // Fast path: if the hash we stored locally already equals the
                              // expected hash, the file is current — skip the expensive disk read.
                              if (localProject.uploadedPreviewSongHash == uploadedPreviewSongHash) {
                                if (kDebugMode) {
                                  print('    Preview song hash already matches stored hash for: ${remoteProject.displayName}, skipping disk read');
                                }
                                needsDownload = false;
                              } else {
                                try {
                                  final localHash = await _cachedFileHash(previewSongPath);
                                  if (localHash == uploadedPreviewSongHash) {
                                    // Hash matches - no download needed
                                    if (kDebugMode) {
                                      print('    Preview song already exists locally with matching hash for: ${remoteProject.displayName}');
                                    }
                                    needsDownload = false;
                                  } else {
                                    // Hash mismatch - need to re-download
                                    if (kDebugMode) {
                                      print('    Preview song hash mismatch (local: $localHash, expected: $uploadedPreviewSongHash) for: ${remoteProject.displayName}, will re-download');
                                    }
                                    needsDownload = true;
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('    Error checking local file hash: $e, will re-download');
                                  }
                                  needsDownload = true;
                                }
                              }
                            } else {
                              // No expected hash - check if local hash matches project hash
                              if (localProject.uploadedPreviewSongHash != null) {
                                try {
                                  final localHash = await _cachedFileHash(previewSongPath);
                                  if (localHash == localProject.uploadedPreviewSongHash) {
                                    // Local hash matches project hash - no download needed
                                    if (kDebugMode) {
                                      print('    Preview song already exists locally with matching hash for: ${remoteProject.displayName}');
                                    }
                                    needsDownload = false;
                                  } else {
                                    // Hash mismatch - need to re-download
                                    needsDownload = true;
                                  }
                                } catch (e) {
                                  needsDownload = true;
                                }
                              } else {
                                // No hash to compare - assume file is valid if it exists
                                needsDownload = false;
                              }
                            }
                          } else {
                            // Path exists but file doesn't - need to download
                            needsDownload = true;
                          }
                        } else if (previewSongPath == null) {
                          // No manually-set local path. Before downloading, check whether
                          // the auto-detected preview already on this device is the exact
                          // file that's on Drive (e.g. this device is the one that uploaded
                          // it) - if so, skip the download so we don't duplicate it under a
                          // UUID filename and silently promote previewSongAutoPath into
                          // previewSongPath.
                          needsDownload = !await _autoPreviewAlreadyMatches(localProject, uploadedPreviewSongHash);
                        } else if (_isDriveFileReference(previewSongPath)) {
                          // Drive reference - need to download
                          needsDownload = true;
                        } else if (uploadedPreviewSongHash != null && localProject.uploadedPreviewSongHash != uploadedPreviewSongHash) {
                          // Hash changed - need to download
                          needsDownload = true;
                        }

                        if (needsDownload) {
                          downloadedPreviewSongs++;
                          
                          // Emit progress for preview song download
                          _progressController.add(BackupProgress(
                            stage: BackupProgressStage.downloadingPreviewSongs,
                            currentItem: 'Downloading preview: ${previewSongFileName ?? remoteProject.displayName}',
                            currentIndex: downloadedPreviewSongs,
                            totalItems: totalPreviewSongs,
                            progress: 0.20 + (downloadedPreviewSongs / totalPreviewSongs * 0.70), // 20-90%
                          ));
                          
                          String? fileExtension;
                          if (previewSongFileName != null) {
                            fileExtension = path.extension(previewSongFileName);
                          }
                          
                          final downloadedFilePath = await downloadPreviewSongFile(
                            driveFileId: driveFileId,
                            projectId: remoteProject.id,
                            expectedHash: uploadedPreviewSongHash,
                            fileExtension: fileExtension,
                          );
                          
                          if (downloadedFilePath != null) {
                            previewSongPath = downloadedFilePath;
                            previewSongsUpdated++;
                            if (kDebugMode) {
                              print('    Downloaded preview song for project: ${remoteProject.displayName} (ID: $driveFileId)');
                            }
                          } else {
                            // Download failed, keep Drive reference
                            previewSongPath = _createDriveFileReference(driveFileId);
                            if (kDebugMode) {
                              print('    Download failed, kept Drive reference for: ${remoteProject.displayName}');
                            }
                          }
                        } else {
                          // File already downloaded and hash matches, keep local path
                          if (kDebugMode) {
                            print('    Preview song already downloaded with matching hash for: ${remoteProject.displayName}');
                          }
                        }
                      } else {
                        // Skip download, store Drive reference
                        previewSongPath = _createDriveFileReference(driveFileId);
                        if (kDebugMode) {
                          print('    Skipped preview song download for project: ${remoteProject.displayName} (ID: $driveFileId)');
                        }
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('    Error updating preview song for project ${remoteProject.id}: $e');
                      }
                    }
                  } else if (remoteProject.previewSongPath != null && remoteProject.previewSongPath != localProject.previewSongPath) {
                    // Remote has preview song but no file mapping (old backup format)
                    // If it's a local file path, check if it exists
                    if (!_isDriveFileReference(remoteProject.previewSongPath)) {
                      final remoteFile = File(remoteProject.previewSongPath!);
                      if (await remoteFile.exists()) {
                        previewSongPath = remoteProject.previewSongPath;
                      }
                    } else {
                      // It's already a Drive reference, use it
                      previewSongPath = remoteProject.previewSongPath;
                    }
                  }
                  
                  final mergedProject = localProject.copyWith(
                    // Metadata fields from remote (user-editable)
                    notes: remoteProject.notes,
                    todos: remoteProject.todos,
                    parts: remoteProject.parts,
                    attachments: remoteProject.attachments,
                    bpm: remoteProject.bpm,
                    musicalKey: remoteProject.musicalKey,
                    status: remoteProject.status,
                    customDisplayName: remoteProject.customDisplayName,
                    hidden: remoteProject.hidden,
                    deadline: remoteProject.deadline,
                    clearDeadline: remoteProject.deadline == null,
                    statusChangedAt: remoteProject.statusChangedAt,
                    ignoredNewerSongPath: remoteProject.ignoredNewerSongPath,
                    clearIgnoredNewerSongPath: remoteProject.ignoredNewerSongPath == null,
                    // Appearance overrides are user data like any other; the
                    // clear flags are what let "reset to automatic" propagate
                    // rather than being read as "nothing to say".
                    accentColor: remoteProject.accentColor,
                    clearAccentColor: remoteProject.accentColor == null,
                    iconKey: remoteProject.iconKey,
                    clearIconKey: remoteProject.iconKey == null,
                    previewSongPath: previewSongPath,
                    previewSongFileName: previewSongFileName ?? remoteProject.previewSongFileName,
                    uploadedPreviewSongHash: uploadedPreviewSongHash ?? remoteProject.uploadedPreviewSongHash,
                    // Use remote updatedAt so the UI shows the actual modification time, not download time
                    updatedAt: remoteProject.updatedAt,
                    // lastModifiedAt/fileCreatedAt come from stat-ing the DAW file on disk.
                    // On mobile there is no such file to stat, so remote (desktop) is always
                    // the authoritative source and must be propagated. On desktop, the local
                    // scan is the ground truth — pulling in remote's copy here would overwrite
                    // fresh filesystem data with whatever a possibly-stale backup last saw.
                    lastModifiedAt: MobileUtils.isMobile() ? remoteProject.lastModifiedAt : localProject.lastModifiedAt,
                    fileCreatedAt: MobileUtils.isMobile() ? remoteProject.fileCreatedAt : localProject.fileCreatedAt,
                    // Keep other file system fields from local (file-based)
                    // filePath, fileName, fileSizeBytes, fileExtension stay from local
                  );
                  
                  // Save the merged project
                  await profileProjectsBox.put(mergedProject.id, mergedProject);
                  projectsUpdated++;
                  profileProjectsUpdated++;
                  
                  // CRITICAL: Force Hive to persist the data by calling flush
                  // This ensures the data is written to disk immediately
                  await profileProjectsBox.flush();
                  
                  // CRITICAL: Force Hive to notify listeners by doing a second put
                  // This ensures Hive emits a BoxEvent even if the object reference is the same
                  // We use copyWith to create a new instance, ensuring Hive detects the change
                  await profileProjectsBox.put(mergedProject.id, mergedProject.copyWith());
                  
                  // Flush again to ensure the second put is also persisted
                  await profileProjectsBox.flush();
                  
                  if (kDebugMode) {
                    final changes = <String>[];
                    if (remoteProject.notes != localProject.notes) changes.add('notes');
                    if (!_todosEqual(remoteProject.todos, localProject.todos)) {
                      changes.add('todos (${remoteProject.todos.length} vs ${localProject.todos.length})');
                    }
                    if (!_listEquals(remoteProject.parts, localProject.parts)) {
                      changes.add('parts (${remoteProject.parts.length} vs ${localProject.parts.length})');
                    }
                    if (remoteProject.bpm != localProject.bpm) changes.add('bpm');
                    if (remoteProject.musicalKey != localProject.musicalKey) changes.add('key');
                    if (remoteProject.status != localProject.status) changes.add('status');
                    if (remoteProject.customDisplayName != localProject.customDisplayName) changes.add('displayName');
                    if (remoteProject.hidden != localProject.hidden) changes.add('hidden');
                    print('    ~ Updated project metadata: ${remoteProject.displayName} (${changes.join(", ")})');
                    
                    if (kDebugMode) {
                      print('      ✓ Project saved and notification triggered for: ${remoteProject.displayName}');
                    }
                  }
                } else {
                  // No metadata changes - but still check if preview song needs to be downloaded
                  // This is important for mobile apps that might not have the preview song file yet
                  String? previewSongPath = localProject.previewSongPath;
                  String? previewSongFileName = localProject.previewSongFileName;
                  String? uploadedPreviewSongHash = localProject.uploadedPreviewSongHash;
                  
                  // Check if preview song exists in backup
                  if (previewSongFiles != null && previewSongFiles.containsKey(remoteProject.id)) {
                    try {
                      final driveFileId = previewSongFiles[remoteProject.id] as String;
                      
                      // Get original filename and hash if available
                      String? originalFileName;
                      String? expectedHash;
                      if (previewSongFileNames != null && previewSongFileNames.containsKey(remoteProject.id)) {
                        originalFileName = previewSongFileNames[remoteProject.id] as String;
                      }
                      // Fallback for old backups: derive display name from the remote
                      // project's path (real filename on the uploading machine).
                      if (originalFileName == null &&
                          remoteProject.previewSongPath != null &&
                          !_isDriveFileReference(remoteProject.previewSongPath!)) {
                        originalFileName = _realPreviewFileNameOrNull(remoteProject.previewSongPath);
                      }
                      if (previewSongHashes != null && previewSongHashes.containsKey(remoteProject.id)) {
                        expectedHash = previewSongHashes[remoteProject.id] as String;
                      }

                      if (downloadPreviewSongs) {
                        // On mobile, only download preview songs after backup is downloaded
                        // Check if we need to download (if path is Drive reference or hash changed)
                        bool needsDownload = false;
                        
                        // First, check if file exists locally (especially on mobile)
                        if (previewSongPath != null && !_isDriveFileReference(previewSongPath)) {
                          // Path exists and is not a Drive reference - check if file actually exists
                          final localFile = File(previewSongPath);
                          if (await localFile.exists()) {
                            // File exists locally - verify hash if we have expected hash
                            if (expectedHash != null) {
                              // Fast path: if the hash we stored locally already equals the
                              // expected hash, the file is current — skip the expensive disk read.
                              if (localProject.uploadedPreviewSongHash == expectedHash) {
                                if (kDebugMode) {
                                  print('    Preview song hash already matches stored hash for: ${localProject.displayName}, skipping disk read');
                                }
                                needsDownload = false;
                              } else {
                                try {
                                  final localHash = await _cachedFileHash(previewSongPath);
                                  if (localHash == expectedHash) {
                                    // Hash matches - no download needed
                                    if (kDebugMode) {
                                      print('    Preview song already exists locally with matching hash for: ${localProject.displayName}');
                                    }
                                    needsDownload = false;
                                  } else {
                                    // Hash mismatch - need to re-download
                                    if (kDebugMode) {
                                      print('    Preview song hash mismatch (local: $localHash, expected: $expectedHash) for: ${localProject.displayName}, will re-download');
                                    }
                                    needsDownload = true;
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('    Error checking local file hash: $e, will re-download');
                                  }
                                  needsDownload = true;
                                }
                              }
                            } else {
                              // No expected hash - check if local hash matches project hash
                              if (localProject.uploadedPreviewSongHash != null) {
                                try {
                                  final localHash = await _cachedFileHash(previewSongPath);
                                  if (localHash == localProject.uploadedPreviewSongHash) {
                                    // Local hash matches project hash - no download needed
                                    if (kDebugMode) {
                                      print('    Preview song already exists locally with matching hash for: ${localProject.displayName}');
                                    }
                                    needsDownload = false;
                                  } else {
                                    // Hash mismatch - need to re-download
                                    needsDownload = true;
                                  }
                                } catch (e) {
                                  needsDownload = true;
                                }
                              } else {
                                // No hash to compare - assume file is valid if it exists
                                needsDownload = false;
                              }
                            }
                          } else {
                            // Path exists but file doesn't - need to download
                            needsDownload = true;
                          }
                        } else if (previewSongPath == null) {
                          // No manually-set local path. Before downloading, check whether
                          // the auto-detected preview already on this device is the exact
                          // file that's on Drive (e.g. this device is the one that uploaded
                          // it) - if so, skip the download so we don't duplicate it under a
                          // UUID filename and silently promote previewSongAutoPath into
                          // previewSongPath.
                          needsDownload = !await _autoPreviewAlreadyMatches(localProject, expectedHash);
                        } else if (_isDriveFileReference(previewSongPath)) {
                          // Drive reference - need to download
                          needsDownload = true;
                        } else if (expectedHash != null && uploadedPreviewSongHash != expectedHash) {
                          // Hash changed - need to download
                          needsDownload = true;
                        }
                        
                        if (needsDownload) {
                          downloadedPreviewSongs++;
                          
                          // Emit progress for preview song download
                          _progressController.add(BackupProgress(
                            stage: BackupProgressStage.downloadingPreviewSongs,
                            currentItem: 'Downloading preview: ${originalFileName ?? localProject.displayName}',
                            currentIndex: downloadedPreviewSongs,
                            totalItems: totalPreviewSongs,
                            progress: 0.20 + (downloadedPreviewSongs / totalPreviewSongs * 0.70), // 20-90%
                          ));
                          
                          String? fileExtension;
                          if (originalFileName != null) {
                            fileExtension = path.extension(originalFileName);
                          }
                          
                          final localFilePath = await downloadPreviewSongFile(
                            driveFileId: driveFileId,
                            projectId: remoteProject.id,
                            expectedHash: expectedHash,
                            fileExtension: fileExtension,
                          );
                          
                          if (localFilePath != null) {
                            previewSongPath = localFilePath;
                            previewSongFileName = originalFileName;
                            uploadedPreviewSongHash = expectedHash;
                            
                            // Update project with downloaded file path
                            final updatedProject = localProject.copyWith(
                              previewSongPath: previewSongPath,
                              previewSongFileName: previewSongFileName,
                              uploadedPreviewSongHash: uploadedPreviewSongHash,
                              updatedAt: DateTime.now(),
                            );
                            await profileProjectsBox.put(updatedProject.id, updatedProject);
                            await profileProjectsBox.flush();
                            
                            previewSongsDownloaded++;
                            if (kDebugMode) {
                              print('    Downloaded preview song for project: ${localProject.displayName} (ID: $driveFileId)');
                            }
                          } else {
                            // Download failed, store Drive reference as fallback
                            previewSongPath = _createDriveFileReference(driveFileId);
                            previewSongFileName = originalFileName;
                            uploadedPreviewSongHash = expectedHash;
                            
                            final updatedProject = localProject.copyWith(
                              previewSongPath: previewSongPath,
                              previewSongFileName: previewSongFileName,
                              uploadedPreviewSongHash: uploadedPreviewSongHash,
                              updatedAt: DateTime.now(),
                            );
                            await profileProjectsBox.put(updatedProject.id, updatedProject);
                            await profileProjectsBox.flush();
                            
                            if (kDebugMode) {
                              print('    Download failed, stored Drive reference for: ${localProject.displayName}');
                            }
                          }
                        } else {
                          // File already downloaded and hash matches, just update filename/hash if needed
                          if (originalFileName != previewSongFileName || expectedHash != uploadedPreviewSongHash) {
                            final updatedProject = localProject.copyWith(
                              previewSongFileName: originalFileName ?? previewSongFileName,
                              uploadedPreviewSongHash: expectedHash ?? uploadedPreviewSongHash,
                              updatedAt: DateTime.now(),
                            );
                            await profileProjectsBox.put(updatedProject.id, updatedProject);
                            await profileProjectsBox.flush();
                            
                            if (kDebugMode) {
                              print('    Updated preview song metadata for: ${localProject.displayName}');
                            }
                          }
                        }
                      } else {
                        // Skip download, store Drive reference
                        previewSongPath = _createDriveFileReference(driveFileId);
                        previewSongFileName = originalFileName;
                        uploadedPreviewSongHash = expectedHash;
                        
                        // Only update if it's different from current path or filename
                        if (previewSongPath != localProject.previewSongPath || originalFileName != previewSongFileName || expectedHash != uploadedPreviewSongHash) {
                          final updatedProject = localProject.copyWith(
                            previewSongPath: previewSongPath,
                            previewSongFileName: previewSongFileName,
                            uploadedPreviewSongHash: uploadedPreviewSongHash,
                            updatedAt: DateTime.now(),
                          );
                          await profileProjectsBox.put(updatedProject.id, updatedProject);
                          await profileProjectsBox.flush();
                          
                          if (kDebugMode) {
                            print('    Skipped preview song download, stored Drive reference for: ${localProject.displayName} (ID: $driveFileId)');
                          }
                        }
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('    Error updating preview song for project ${remoteProject.id}: $e');
                      }
                    }
                  }
                  
                  if (kDebugMode) {
                    print('    = No metadata changes: ${localProject.displayName}');
                  }
                }
              }
            }
          }
          
          // Project cover art (#110). A separate pass over the manifest rather
          // than a branch inside the merge above: the cover is a file sitting
          // beside the metadata, not one of its fields, and the merge's three
          // paths (added / metadata-changed / unchanged) would each need the
          // identical download. Working off the stored project also means a
          // cover lands correctly whichever of those paths the row took.
          if (downloadPreviewSongs && projectCoverArtFiles != null) {
            for (final coverEntry in projectCoverArtFiles.entries) {
              if (_isCancelled) throw UploadCancelledException('Download cancelled by user');
              final coverProjectId = coverEntry.key;
              if (!profileProjectIds.contains(coverProjectId)) continue;
              final storedProject = profileProjectsBox.get(coverProjectId);
              if (storedProject == null) continue;

              try {
                coverArtIndex++;
                _progressController.add(BackupProgress(
                  stage: BackupProgressStage.downloadingProjectCoverArt,
                  currentItem: 'Downloading cover art: ${storedProject.displayName}',
                  currentIndex: coverArtIndex,
                  totalItems: coverArtToDownload,
                  progress: 0.20 + (coverArtIndex / coverArtToDownload * 0.10), // 20-30%
                ));

                final expectedHash = projectCoverArtHashes?[coverProjectId] as String?;

                // The extension comes from whatever the uploading machine's
                // path had; the local filename is ours either way.
                String? fileExtension;
                for (final remoteProject in remoteProjects) {
                  if (remoteProject.id == coverProjectId) {
                    final remoteCover = remoteProject.thumbnailPath;
                    if (remoteCover != null && remoteCover.isNotEmpty) {
                      fileExtension = path.extension(remoteCover);
                    }
                    break;
                  }
                }

                final localCoverPath = await downloadProjectCoverArtFile(
                  driveFileId: coverEntry.value as String,
                  projectId: coverProjectId,
                  expectedHash: expectedHash,
                  fileExtension: fileExtension,
                );

                if (localCoverPath != null && localCoverPath != storedProject.thumbnailPath) {
                  await profileProjectsBox.put(
                    coverProjectId,
                    storedProject.copyWith(thumbnailPath: localCoverPath),
                  );
                  if (kDebugMode) {
                    print('    Downloaded cover art for: ${storedProject.displayName}');
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  print('    Error downloading cover art for project $coverProjectId: $e');
                }
                // A missing cover falls back to the accent colour and icon —
                // never a reason to fail the whole restore.
              }
            }
          }

          // Force box to notify listeners by doing a dummy update on modified projects
          // This ensures Hive streams detect the changes even after batch updates
          if (profileProjectsUpdated > 0 && profileProjectsBox.isNotEmpty) {
            // Touch all modified projects to trigger notifications
            // This ensures the stream emits for the projects that were actually changed
            final modifiedProjectIds = <String>{};
            for (final remoteProject in remoteProjects) {
              if (profileProjectIds.contains(remoteProject.id)) {
                final localProject = profileProjectsBox.get(remoteProject.id);
                if (localProject != null && _hasMetadataChanged(remoteProject, localProject)) {
                  modifiedProjectIds.add(remoteProject.id);
                }
              }
            }
            
            // Touch each modified project to trigger stream notifications
            for (final projectId in modifiedProjectIds) {
              final project = profileProjectsBox.get(projectId);
              if (project != null) {
                await profileProjectsBox.put(projectId, project);
                if (kDebugMode) {
                  print('      Triggered notification for modified project: ${project.displayName}');
                }
              }
            }
          } else if (profileProjectsBox.isNotEmpty && profileProjectsAdded > 0) {
            // If only new projects were added, touch the first one to trigger notification
            final firstProject = profileProjectsBox.values.first;
            await profileProjectsBox.put(firstProject.id, firstProject);
          }
          
          // CRITICAL: Flush the box to ensure all changes are persisted to disk
          // This is especially important when switching profiles, as the box might be closed
          await profileProjectsBox.flush();
          
          if (kDebugMode) {
            print('  Profile ${profile.name}: ${profileProjectsBox.length} projects (+$profileProjectsAdded ~$profileProjectsUpdated)');
            print('  Box flushed to disk for profile ${profile.name}');
          }
        } catch (e) {
          if (kDebugMode) print('Error merging projects for profile ${profile.id}: $e');
        }
      }
    }

    // Merge releases - distribute to CORRECT profiles (or ALL if no mappings)
    if (remoteData['releases'] != null) {
      final remoteReleases = (remoteData['releases'] as List)
          .map((r) => _deserializeRelease(r as Map<String, dynamic>))
          .toList();
      
      // If we have profile mappings, use them; otherwise distribute to all profiles (backward compatibility)
      final targetProfiles = releaseToProfileMap != null 
          ? allProfiles.where((p) => profileToReleases.containsKey(p.id)).toList()
          : allProfiles;
      
      for (final profile in targetProfiles) {
        try {
          final profileReleasesBox = await Hive.openBox<Release>('${profile.id}_releases');
          int profileReleasesAdded = 0;
          int profileReleasesUpdated = 0;
          
          // Get releases that belong to this profile
          final profileReleaseIds = releaseToProfileMap != null
              ? (profileToReleases[profile.id] ?? [])
              : remoteReleases.map((r) => r.id).toList(); // All releases if no mapping
          
          for (final remoteRelease in remoteReleases) {
            if (_isCancelled) throw UploadCancelledException('Download cancelled by user');
            // Only process if this release belongs to this profile (or all if no mapping)
            if (profileReleaseIds.contains(remoteRelease.id)) {
              final localRelease = profileReleasesBox.get(remoteRelease.id);
              
              // Download release artwork if available
              var releaseToSave = remoteRelease;
              if (downloadPreviewSongs && releaseArtworkFiles != null && releaseArtworkFiles.containsKey(remoteRelease.id)) {
                try {
                  artworkIndex++;
                  
                  // Emit progress for release artwork download
                  _progressController.add(BackupProgress(
                    stage: BackupProgressStage.downloadingReleaseArtwork,
                    currentItem: 'Downloading release artwork: ${remoteRelease.title}',
                    currentIndex: artworkIndex,
                    totalItems: artworkToDownload,
                    progress: 0.20 + (artworkIndex / artworkToDownload * 0.15), // 20-35%
                  ));
                  
                  final driveFileId = releaseArtworkFiles[remoteRelease.id] as String;
                  String? expectedHash;
                  if (releaseArtworkHashes != null && releaseArtworkHashes.containsKey(remoteRelease.id)) {
                    expectedHash = releaseArtworkHashes[remoteRelease.id] as String;
                  }
                  
                  // Determine file extension from remote artworkImagePath
                  String? fileExtension;
                  if (remoteRelease.artworkImagePath != null) {
                    fileExtension = path.extension(remoteRelease.artworkImagePath!);
                  }
                  
                  // Download release artwork file
                  final localFilePath = await downloadReleaseArtworkFile(
                    driveFileId: driveFileId,
                    releaseId: remoteRelease.id,
                    expectedHash: expectedHash,
                    fileExtension: fileExtension,
                  );
                  
                  if (localFilePath != null) {
                    releaseToSave = remoteRelease.copyWith(
                      artworkImagePath: localFilePath,
                    );
                    if (kDebugMode) {
                      print('    Downloaded release artwork for: ${remoteRelease.title} (ID: $driveFileId)');
                    }
                  } else {
                    // Download failed, keep remote artworkImagePath as is
                    if (kDebugMode) {
                      print('    Failed to download release artwork for: ${remoteRelease.title}');
                    }
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('    Error downloading release artwork for release ${remoteRelease.id}: $e');
                  }
                  // Continue without artwork
                }
              }
              
              if (localRelease == null) {
                // New release from remote
                await profileReleasesBox.put(releaseToSave.id, releaseToSave);
                releasesAdded++;
                profileReleasesAdded++;
                if (kDebugMode) {
                  print('    + Added new release: ${releaseToSave.title}');
                }
              } else {
                // For releases, we compare based on content changes
                // Since Release doesn't have updatedAt, we check if content changed
                final hasChanges = releaseToSave.title != localRelease.title ||
                    releaseToSave.description != localRelease.description ||
                    releaseToSave.releaseDate != localRelease.releaseDate ||
                    releaseToSave.artworkImagePath != localRelease.artworkImagePath ||
                    releaseToSave.trackIds.length != localRelease.trackIds.length ||
                    !_listEquals(releaseToSave.trackIds, localRelease.trackIds) ||
                    releaseToSave.todos.length != localRelease.todos.length ||
                    releaseToSave.files.length != localRelease.files.length;
                
                if (hasChanges) {
                  // Content changed - update (remote takes precedence for releases)
                  // This ensures changes from Android (todos, description, etc.) sync back to desktop
                  await profileReleasesBox.put(releaseToSave.id, releaseToSave);
                  releasesUpdated++;
                  profileReleasesUpdated++;
                  if (kDebugMode) {
                    final changes = <String>[];
                    if (releaseToSave.title != localRelease.title) changes.add('title');
                    if (releaseToSave.description != localRelease.description) changes.add('description');
                    if (releaseToSave.todos.length != localRelease.todos.length) {
                      changes.add('todos (${releaseToSave.todos.length} vs ${localRelease.todos.length})');
                    }
                    if (releaseToSave.trackIds.length != localRelease.trackIds.length) {
                      changes.add('tracks (${releaseToSave.trackIds.length} vs ${localRelease.trackIds.length})');
                    }
                    print('    ~ Updated release: ${releaseToSave.title} (${changes.join(", ")})');
                  }
                } else {
                  // No changes - skip
                  if (kDebugMode) {
                    print('    = No change needed: ${localRelease.title}');
                  }
                }
              }
            }
          }
          
          // Force box to notify listeners by doing a dummy update on the first release
          // This ensures Hive streams detect the changes even after batch updates
          if (profileReleasesBox.isNotEmpty) {
            final firstRelease = profileReleasesBox.values.first;
            // Touch the box to trigger notifications - this will cause the stream to emit
            await profileReleasesBox.put(firstRelease.id, firstRelease);
            if (kDebugMode) {
              print('  Profile ${profile.name}: ${profileReleasesBox.length} releases (+$profileReleasesAdded ~$profileReleasesUpdated)');
            }
          }
        } catch (e) {
          if (kDebugMode) print('Error merging releases for profile ${profile.id}: $e');
        }
      }
    }

    // Merge roots - distribute to CORRECT profiles (or ALL if no mappings)
    if (remoteData['roots'] != null) {
      final remoteRoots = (remoteData['roots'] as List)
          .map((r) => _deserializeRoot(r as Map<String, dynamic>))
          .toList();
      
      // If we have profile mappings, use them; otherwise distribute to all profiles (backward compatibility)
      final targetProfiles = rootToProfileMap != null 
          ? allProfiles.where((p) => profileToRoots.containsKey(p.id)).toList()
          : allProfiles;
      
      for (final profile in targetProfiles) {
        try {
          final profileRootsBox = await Hive.openBox<ScanRoot>('${profile.id}_roots');
          
          // Get roots that belong to this profile
          final profileRootIds = rootToProfileMap != null
              ? (profileToRoots[profile.id] ?? [])
              : remoteRoots.map((r) => r.id).toList(); // All roots if no mapping
          
          for (final remoteRoot in remoteRoots) {
            if (_isCancelled) throw UploadCancelledException('Download cancelled by user');
            // Only process if this root belongs to this profile (or all if no mapping)
            if (profileRootIds.contains(remoteRoot.id)) {
              final localRoot = profileRootsBox.get(remoteRoot.id);
              if (localRoot == null) {
                // New root from remote
                await profileRootsBox.put(remoteRoot.id, remoteRoot);
              }
            }
          }
          
          if (kDebugMode) {
            print('  Profile ${profile.name}: ${profileRootsBox.length} roots');
          }
        } catch (e) {
          if (kDebugMode) print('Error merging roots for profile ${profile.id}: $e');
        }
      }
    }

    // Merge custom mixdown folders (global preference, not per-profile) - union of local and remote
    if (remoteData['customMixdownFolders'] != null) {
      try {
        final remoteCustomMixdownFolders = (remoteData['customMixdownFolders'] as List)
            .map((f) => f.toString())
            .toList();
        if (remoteCustomMixdownFolders.isNotEmpty) {
          final appSettingsBox = await Hive.openBox<String>('app_settings');
          final localRaw = appSettingsBox.get('customMixdownFolders');
          final localFolders = localRaw != null
              ? (jsonDecode(localRaw) as List).map((e) => e.toString()).toList()
              : <String>[];
          final merged = [...localFolders];
          for (final folder in remoteCustomMixdownFolders) {
            if (!merged.any((f) => f.toLowerCase() == folder.toLowerCase())) {
              merged.add(folder);
            }
          }
          await appSettingsBox.put('customMixdownFolders', jsonEncode(merged));
          if (kDebugMode) {
            print('  Custom mixdown folders: ${merged.length} after merge');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error merging custom mixdown folders: $e');
      }
    }

    // Merge user-authored themes (global preference, not per-profile) — union
    // by theme id, newest updatedAt winning a same-id collision.
    //
    // Never deletes: a theme this device has and the remote doesn't is one
    // the user made here and hasn't pushed yet, not one they removed.
    if (remoteData['customThemes'] != null) {
      try {
        final remoteThemes =
            customThemesFromJson(remoteData['customThemes'] as List);
        if (remoteThemes.isNotEmpty) {
          final appSettingsBox = await Hive.openBox<String>('app_settings');
          final localRaw = appSettingsBox.get('customThemes');
          final localThemes = localRaw != null
              ? customThemesFromJson(jsonDecode(localRaw) as List)
              : <CustomTheme>[];
          final merged = mergeCustomThemes(localThemes, remoteThemes);
          await appSettingsBox.put(
            'customThemes',
            jsonEncode(merged.map((t) => t.toJson()).toList()),
          );
          if (kDebugMode) {
            print('  Custom themes: ${merged.length} after merge');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error merging custom themes: $e');
      }
    }

    // Merge per-DAW custom mixdown folders (global preference, not per-profile)
    // - union per DAW key, same as the flat list above.
    if (remoteData['customMixdownFoldersByDaw'] != null) {
      try {
        final remoteByDaw =
            (remoteData['customMixdownFoldersByDaw'] as Map).map(
          (key, value) => MapEntry(
            key as String,
            (value as List).map((f) => f.toString()).toList(),
          ),
        );
        if (remoteByDaw.isNotEmpty) {
          final appSettingsBox = await Hive.openBox<String>('app_settings');
          final localRaw = appSettingsBox.get('customMixdownFoldersByDaw');
          final localByDaw = localRaw != null
              ? (jsonDecode(localRaw) as Map).map(
                  (key, value) => MapEntry(
                    key as String,
                    (value as List).map((f) => f.toString()).toList(),
                  ),
                )
              : <String, List<String>>{};
          final merged = <String, List<String>>{
            for (final entry in localByDaw.entries) entry.key: [...entry.value],
          };
          for (final entry in remoteByDaw.entries) {
            final existing = merged.putIfAbsent(entry.key, () => []);
            for (final folder in entry.value) {
              if (!existing.any((f) => f.toLowerCase() == folder.toLowerCase())) {
                existing.add(folder);
              }
            }
          }
          await appSettingsBox.put('customMixdownFoldersByDaw', jsonEncode(merged));
          if (kDebugMode) {
            print('  Per-DAW custom mixdown folders: ${merged.length} DAWs after merge');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error merging per-DAW custom mixdown folders: $e');
      }
    }

    // Merge part templates (global, not per-profile) - same newer-wins rule as
    // project templates below, so a lineup edited locally since the last backup
    // isn't clobbered by an older remote copy.
    if (remoteData['partTemplates'] != null) {
      try {
        final remotePartTemplates = (remoteData['partTemplates'] as List)
            .map((t) => PartTemplate.fromJson(t as Map<String, dynamic>))
            .toList();
        final partTemplatesBox = await Hive.openBox<PartTemplate>('partTemplates');
        for (final remoteTemplate in remotePartTemplates) {
          final localTemplate = partTemplatesBox.get(remoteTemplate.id);
          if (localTemplate == null ||
              remoteTemplate.updatedAt.isAfter(localTemplate.updatedAt)) {
            await partTemplatesBox.put(remoteTemplate.id, remoteTemplate);
          }
        }
        if (kDebugMode) {
          print('  Part templates: ${partTemplatesBox.length} after merge');
        }
      } catch (e) {
        if (kDebugMode) print('Error merging part templates: $e');
      }
    }

    // Merge TODO templates (global, not per-profile) - same newer-wins rule as
    // project templates below. These are uploaded in every backup under
    // 'templates'; without this block they were silently dropped on restore.
    if (remoteData['templates'] != null) {
      try {
        final remoteTemplates = (remoteData['templates'] as List)
            .map((t) => _deserializeTemplate(t as Map<String, dynamic>))
            .toList();
        final templatesBox = await Hive.openBox<TodoTemplate>('todoTemplates');
        for (final remoteTemplate in remoteTemplates) {
          final localTemplate = templatesBox.get(remoteTemplate.id);
          if (localTemplate == null || remoteTemplate.updatedAt.isAfter(localTemplate.updatedAt)) {
            await templatesBox.put(remoteTemplate.id, remoteTemplate);
          }
        }
        if (kDebugMode) {
          print('  TODO templates: ${templatesBox.length} after merge');
        }
      } catch (e) {
        if (kDebugMode) print('Error merging TODO templates: $e');
      }
    }

    // Merge project templates (global, not per-profile) - remote wins per id only
    // when it's newer, so a local template created/edited since the last backup
    // isn't clobbered by an older remote copy.
    if (remoteData['projectTemplates'] != null) {
      try {
        final remoteProjectTemplates = (remoteData['projectTemplates'] as List)
            .map((t) => _deserializeProjectTemplate(t as Map<String, dynamic>))
            .toList();
        final projectTemplatesBox = await Hive.openBox<ProjectTemplate>('projectTemplates');
        for (final remoteTemplate in remoteProjectTemplates) {
          final localTemplate = projectTemplatesBox.get(remoteTemplate.id);
          if (localTemplate == null || remoteTemplate.updatedAt.isAfter(localTemplate.updatedAt)) {
            await projectTemplatesBox.put(remoteTemplate.id, remoteTemplate);
          }
        }
        if (kDebugMode) {
          print('  Project templates: ${projectTemplatesBox.length} after merge');
        }
      } catch (e) {
        if (kDebugMode) print('Error merging project templates: $e');
      }
    }

    // Merge template roots (global, not per-profile) - add any remote root not
    // already present locally by id; never overwrites an existing local root.
    if (remoteData['templateRoots'] != null) {
      try {
        final remoteTemplateRoots = (remoteData['templateRoots'] as List)
            .map((r) => _deserializeTemplateRoot(r as Map<String, dynamic>))
            .toList();
        final templateRootsBox = await Hive.openBox<TemplateRoot>('templateRoots');
        for (final remoteRoot in remoteTemplateRoots) {
          if (templateRootsBox.get(remoteRoot.id) == null) {
            await templateRootsBox.put(remoteRoot.id, remoteRoot);
          }
        }
        if (kDebugMode) {
          print('  Template roots: ${templateRootsBox.length} after merge');
        }
      } catch (e) {
        if (kDebugMode) print('Error merging template roots: $e');
      }
    }

    // Merge per-profile phase customization (custom phase names, colors, finished set)
    // Only fills in slots that are still unset locally - never overwrites local customization.
    if (remoteData['phaseSettingsByProfile'] != null) {
      try {
        final remotePhaseSettings = Map<String, dynamic>.from(remoteData['phaseSettingsByProfile'] as Map);
        final appSettingsBox = await Hive.openBox<String>('app_settings');
        for (final profile in allProfiles) {
          final remoteForProfile = remotePhaseSettings[profile.id];
          if (remoteForProfile == null) continue;
          final remoteMap = Map<String, dynamic>.from(remoteForProfile as Map);

          if (remoteMap['phases'] != null && appSettingsBox.get('${profile.id}_phases') == null) {
            await appSettingsBox.put('${profile.id}_phases', jsonEncode(remoteMap['phases']));
          }
          if (remoteMap['phaseColors'] != null && appSettingsBox.get('${profile.id}_phase_colors') == null) {
            await appSettingsBox.put('${profile.id}_phase_colors', jsonEncode(remoteMap['phaseColors']));
          }
          if (remoteMap['finishedPhases'] != null &&
              appSettingsBox.get('${profile.id}_finished_phases') == null &&
              appSettingsBox.get('${profile.id}_finished_phase') == null) {
            await appSettingsBox.put('${profile.id}_finished_phases', jsonEncode(remoteMap['finishedPhases']));
          }
        }
        if (kDebugMode) {
          print('  Phase settings: merged for ${remotePhaseSettings.length} profile(s)');
        }
      } catch (e) {
        if (kDebugMode) print('Error merging phase settings: $e');
      }
    }

    if (kDebugMode) {
      print('Merge completed:');
      print('  Profiles: merged from backup');
      print('  Projects: +$projectsAdded ~$projectsUpdated');
      print('  Releases: +$releasesAdded ~$releasesUpdated');
    }

    _progressController.add(BackupProgress(
      stage: BackupProgressStage.completed,
      currentItem: 'Download completed successfully!',
      currentIndex: 0,
      totalItems: 0,
      progress: 1.0,
    ));

    return SyncResult(
      projectsAdded: projectsAdded,
      projectsUpdated: projectsUpdated,
      releasesAdded: releasesAdded,
      releasesUpdated: releasesUpdated,
      previewSongsDownloaded: previewSongsDownloaded,
      previewSongsUpdated: previewSongsUpdated,
    );
  }

  /// After a restore, if the currently active profile is empty but a restored
  /// profile has data, switch to the restored profile and delete the empty one.
  ///
  /// Extracted from [mergeData] so it runs AFTER the progress dialog is closed,
  /// preventing the dialog from getting stuck on iOS due to Hive file I/O.
  Future<void> cleanupEmptyProfile(ProfileRepository profileRepo) async {
    try {
      final currentProfileId = profileRepo.getCurrentProfileId();
      if (currentProfileId == null) return;

      final currentProjectsBox = await Hive.openBox<MusicProject>('${currentProfileId}_projects');
      final currentReleasesBox = await Hive.openBox<Release>('${currentProfileId}_releases');
      final isCurrentEmpty = currentProjectsBox.isEmpty && currentReleasesBox.isEmpty;

      if (kDebugMode) {
        print('Post-merge profile check:');
        print('  Current profile: $currentProfileId');
        print('  Current projects: ${currentProjectsBox.length}');
        print('  Current releases: ${currentReleasesBox.length}');
        print('  Is current empty: $isCurrentEmpty');
      }

      if (!isCurrentEmpty) return;

      // Find the first non-current profile that has projects
      Profile? targetProfile;
      for (final profile in profileRepo.getAllProfiles()) {
        if (profile.id == currentProfileId) continue;
        final box = await Hive.openBox<MusicProject>('${profile.id}_projects');
        if (box.isNotEmpty) {
          targetProfile = profile;
          break;
        }
      }

      if (targetProfile == null) return;

      // Switch the active profile — the critical step.
      await profileRepo.setCurrentProfileId(targetProfile.id);

      // Remove the empty profile entry so it no longer appears in the list.
      await profileRepo.profilesBox.delete(currentProfileId);

      // NOTE: We intentionally skip box.close() and Hive.deleteBoxFromDisk().
      // On iOS with Hive CE, closing a box that has active stream watchers
      // (allProjectsStreamProvider) deadlocks. The leftover empty box files
      // are harmless — they are cleaned up when the repository reinitialises.
    } catch (e) {
      if (kDebugMode) print('Error switching to restored profile: $e');
      // Non-critical — don't rethrow
    }
  }

  // Serialization helpers
  Map<String, dynamic> _serializeProfile(Profile profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'createdAt': profile.createdAt.toIso8601String(),
      'lastUsedAt': profile.lastUsedAt?.toIso8601String(),
      'photoPath': profile.photoPath,
      'bio': profile.bio,
      'artworkPath': profile.artworkPath,
      'pressKitPath': profile.pressKitPath,
      'additionalAssets': profile.additionalAssets,
      'artworkPaths': profile.artworkPaths,
      'pressKitPaths': profile.pressKitPaths,
    };
  }

  Profile _deserializeProfile(Map<String, dynamic> data) {
    return Profile(
      id: data['id'] as String,
      name: data['name'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      lastUsedAt: data['lastUsedAt'] != null 
          ? DateTime.parse(data['lastUsedAt'] as String)
          : null,
      photoPath: data['photoPath'] as String?,
      bio: data['bio'] as String?,
      artworkPath: data['artworkPath'] as String?,
      pressKitPath: data['pressKitPath'] as String?,
      additionalAssets: data['additionalAssets'] != null
          ? Map<String, String>.from(data['additionalAssets'] as Map)
          : null,
      artworkPaths: data['artworkPaths'] != null
          ? List<String>.from(data['artworkPaths'] as List)
          : null,
      pressKitPaths: data['pressKitPaths'] != null
          ? List<String>.from(data['pressKitPaths'] as List)
          : null,
    );
  }

  Map<String, dynamic> _serializeProject(MusicProject project) {
    return {
      'id': project.id,
      'filePath': project.filePath,
      'fileName': project.fileName,
      'fileSizeBytes': project.fileSizeBytes,
      'lastModifiedAt': project.lastModifiedAt.toIso8601String(),
      'customDisplayName': project.customDisplayName,
      'thumbnailPath': project.thumbnailPath,
      'status': project.status,
      'fileExtension': project.fileExtension,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'bpm': project.bpm,
      'musicalKey': project.musicalKey,
      'notes': project.notes,
      'dawType': project.dawType,
      'dawVersion': project.dawVersion,
      'todos': project.todos.map((t) => {
        'id': t.id,
        'text': t.text,
        'completed': t.completed,
        'createdAt': t.createdAt.toIso8601String(),
        'dueAt': t.dueAt?.toIso8601String(),
      }).toList(),
      'parts': project.parts.map((p) => p.toJson()).toList(),
      'hidden': project.hidden,
      'previewSongPath': project.previewSongPath,
      'previewSongFileName': project.previewSongFileName,
      'previewSongHash': project.uploadedPreviewSongHash, // Keep 'previewSongHash' key in JSON for backward compatibility
      'fileCreatedAt': project.fileCreatedAt?.toIso8601String(),
      'statusChangedAt': project.statusChangedAt?.toIso8601String(),
      'deadline': project.deadline?.toIso8601String(),
      'totalWorkSeconds': project.totalWorkSeconds,
      'sessions': project.sessions.map((s) => s.toMap()).toList(),
      'metadataScanned': project.metadataScanned,
      'previewSongAutoPath': project.previewSongAutoPath,
      'parentProjectId': project.parentProjectId,
      'ignoredNewerSongPath': project.ignoredNewerSongPath,
      'projectNotes': project.projectNotes,
      'sourceTemplateId': project.sourceTemplateId,
      // Version stacking (#94). A stack is a project row with no file, so if
      // these are skipped every stack silently dissolves on restore, taking
      // the shared metadata and work history of each song with it.
      'isVirtual': project.isVirtual,
      'memberProjectIds': project.memberProjectIds,
      'defaultLaunchMemberId': project.defaultLaunchMemberId,
      'stackId': project.stackId,
      'markers': project.markers.map((m) => m.toMap()).toList(),
      // Attachments (#112) are user data — the reference track, the
      // stem-delivery link, the contract. Only the path/URL travels, never the
      // file itself, exactly as with `filePath` and `previewSongPath`.
      'attachments': project.attachments.map((a) => a.toMap()).toList(),
      // Per-project appearance (#110). Overrides only — null means the
      // accent/icon is derived from the id, which every machine agrees on
      // without any of it travelling.
      'accentColor': project.accentColor,
      'iconKey': project.iconKey,
      // User data: someone typed these two letters onto the card.
      'cardInitials': project.cardInitials,
    };
  }

  MusicProject _deserializeProject(Map<String, dynamic> data) {
    return MusicProject(
      id: data['id'] as String,
      filePath: data['filePath'] as String,
      fileName: data['fileName'] as String,
      fileSizeBytes: data['fileSizeBytes'] as int,
      lastModifiedAt: DateTime.parse(data['lastModifiedAt'] as String),
      customDisplayName: data['customDisplayName'] as String?,
      thumbnailPath: data['thumbnailPath'] as String?,
      status: data['status'] as String,
      fileExtension: data['fileExtension'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      bpm: (data['bpm'] as num?)?.toDouble(),
      musicalKey: data['musicalKey'] as String?,
      notes: data['notes'] as String?,
      dawType: data['dawType'] as String?,
      dawVersion: data['dawVersion'] as String?,
      todos: (data['todos'] as List?)?.map((t) => TodoItem(
        id: t['id'] as String,
        text: t['text'] as String,
        completed: t['completed'] as bool? ?? false,
        createdAt: DateTime.parse(t['createdAt'] as String),
        dueAt: t['dueAt'] != null ? DateTime.parse(t['dueAt'] as String) : null,
      )).toList() ?? const [],
      parts: (data['parts'] as List?)
              ?.map((p) => ProjectPart.fromJson(p as Map<dynamic, dynamic>))
              .toList() ??
          const [],
      hidden: data['hidden'] as bool? ?? false,
      previewSongPath: data['previewSongPath'] as String?,
      previewSongFileName: data['previewSongFileName'] as String?,
      uploadedPreviewSongHash: data['previewSongHash'] as String?, // Keep 'previewSongHash' key in JSON for backward compatibility
      fileCreatedAt: data['fileCreatedAt'] != null
          ? DateTime.parse(data['fileCreatedAt'] as String)
          : null,
      statusChangedAt: data['statusChangedAt'] != null
          ? DateTime.parse(data['statusChangedAt'] as String)
          : null,
      deadline: data['deadline'] != null
          ? DateTime.parse(data['deadline'] as String)
          : null,
      totalWorkSeconds: data['totalWorkSeconds'] as int? ?? 0,
      sessions: (data['sessions'] as List?)
              ?.map((e) => SessionRecord.fromMap(e as Map))
              .toList() ??
          const [],
      metadataScanned: data['metadataScanned'] as bool? ?? false,
      previewSongAutoPath: data['previewSongAutoPath'] as String?,
      parentProjectId: data['parentProjectId'] as String?,
      ignoredNewerSongPath: data['ignoredNewerSongPath'] as String?,
      projectNotes: data['projectNotes'] as String?,
      sourceTemplateId: data['sourceTemplateId'] as String?,
      isVirtual: data['isVirtual'] as bool? ?? false,
      memberProjectIds:
          (data['memberProjectIds'] as List?)?.cast<String>() ??
          const <String>[],
      defaultLaunchMemberId: data['defaultLaunchMemberId'] as String?,
      stackId: data['stackId'] as String?,
      markers: (data['markers'] as List?)
              ?.map((e) => ProjectMarker.fromMap(e as Map))
              .toList() ??
          const [],
      attachments: (data['attachments'] as List?)
              ?.map((e) => ProjectAttachment.fromMap(e as Map))
              .toList() ??
          const [],
      accentColor: (data['accentColor'] as num?)?.toInt(),
      iconKey: data['iconKey'] as String?,
      cardInitials: data['cardInitials'] as String?,
    );
  }

  /// Test-only accessors for the private serialize/deserialize pair above —
  /// mirrors the pattern in BackupService so round-trip tests don't need to
  /// go through a full Drive upload/download cycle.
  @visibleForTesting
  Map<String, dynamic> serializeProjectForTest(MusicProject project) =>
      _serializeProject(project);

  @visibleForTesting
  MusicProject deserializeProjectForTest(Map<String, dynamic> data) =>
      _deserializeProject(data);

  @visibleForTesting
  Map<String, dynamic> serializeReleaseForTest(Release release) =>
      _serializeRelease(release);

  @visibleForTesting
  Release deserializeReleaseForTest(Map<String, dynamic> data) =>
      _deserializeRelease(data);

  /// Test-only accessor for [_autoPreviewAlreadyMatches] — the merge-time check
  /// that stops a locally auto-detected preview from being re-downloaded (and
  /// promoted into [MusicProject.previewSongPath]) when it's already the same
  /// file that's on Drive.
  @visibleForTesting
  Future<bool> autoPreviewAlreadyMatchesForTest(MusicProject localProject, String? expectedHash) =>
      _autoPreviewAlreadyMatches(localProject, expectedHash);

  /// Test-only accessor for [_realPreviewFileNameOrNull].
  @visibleForTesting
  String? realPreviewFileNameOrNullForTest(String? filePath) =>
      _realPreviewFileNameOrNull(filePath);

  Map<String, dynamic> _serializeRelease(Release release) {
    return {
      'id': release.id,
      'title': release.title,
      'releaseDate': release.releaseDate?.toIso8601String(),
      'artworkImagePath': release.artworkImagePath,
      'description': release.description,
      'trackIds': release.trackIds,
      'files': release.files.map((f) => {
        'id': f.id,
        'fileName': f.fileName,
        'filePath': f.filePath,
        'fileType': f.fileType,
        'fileSizeBytes': f.fileSizeBytes,
        'addedAt': f.addedAt.toIso8601String(),
        'description': f.description,
      }).toList(),
      'todos': release.todos.map((t) => {
        'id': t.id,
        'text': t.text,
        'completed': t.completed,
        'createdAt': t.createdAt.toIso8601String(),
        'dueAt': t.dueAt?.toIso8601String(),
      }).toList(),
    };
  }

  Release _deserializeRelease(Map<String, dynamic> data) {
    return Release(
      id: data['id'] as String,
      title: data['title'] as String,
      releaseDate: data['releaseDate'] != null
          ? DateTime.parse(data['releaseDate'] as String)
          : null,
      artworkImagePath: data['artworkImagePath'] as String?,
      description: data['description'] as String?,
      trackIds: List<String>.from(data['trackIds'] as List),
      files: (data['files'] as List?)?.map((f) => ReleaseFile(
        id: f['id'] as String,
        fileName: f['fileName'] as String,
        filePath: f['filePath'] as String,
        fileType: f['fileType'] as String,
        fileSizeBytes: f['fileSizeBytes'] as int,
        addedAt: DateTime.parse(f['addedAt'] as String),
        description: f['description'] as String?,
      )).toList() ?? const [],
      todos: (data['todos'] as List?)?.map((t) => TodoItem(
        id: t['id'] as String,
        text: t['text'] as String,
        completed: t['completed'] as bool,
        createdAt: DateTime.parse(t['createdAt'] as String),
        dueAt: t['dueAt'] != null ? DateTime.parse(t['dueAt'] as String) : null,
      )).toList() ?? const [],
    );
  }

  Map<String, dynamic> _serializeRoot(ScanRoot root) {
    return {
      'id': root.id,
      'path': root.path,
      'addedAt': root.addedAt.toIso8601String(),
      'lastScanAt': root.lastScanAt?.toIso8601String(),
    };
  }

  ScanRoot _deserializeRoot(Map<String, dynamic> data) {
    return ScanRoot(
      id: data['id'] as String,
      path: data['path'] as String,
      addedAt: DateTime.parse(data['addedAt'] as String),
      lastScanAt: data['lastScanAt'] != null
          ? DateTime.parse(data['lastScanAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> _serializeTemplate(TodoTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'items': template.items,
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': template.updatedAt.toIso8601String(),
    };
  }

  TodoTemplate _deserializeTemplate(Map<String, dynamic> data) {
    return TodoTemplate(
      id: data['id'] as String,
      name: data['name'] as String,
      items: (data['items'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }

  Map<String, dynamic> _serializeProjectTemplate(ProjectTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'sourceFolderPath': template.sourceFolderPath,
      'mainFileRelativePath': template.mainFileRelativePath,
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': template.updatedAt.toIso8601String(),
      'bpm': template.bpm,
      'musicalKey': template.musicalKey,
      'dawVersion': template.dawVersion,
      'notes': template.notes,
      'projectNotes': template.projectNotes,
    };
  }

  ProjectTemplate _deserializeProjectTemplate(Map<String, dynamic> data) {
    return ProjectTemplate(
      id: data['id'] as String,
      name: data['name'] as String,
      sourceFolderPath: data['sourceFolderPath'] as String,
      mainFileRelativePath: data['mainFileRelativePath'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      bpm: (data['bpm'] as num?)?.toDouble(),
      musicalKey: data['musicalKey'] as String?,
      dawVersion: data['dawVersion'] as String?,
      notes: data['notes'] as String?,
      projectNotes: data['projectNotes'] as String?,
    );
  }

  Map<String, dynamic> _serializeTemplateRoot(TemplateRoot root) {
    return {
      'id': root.id,
      'path': root.path,
      'addedAt': root.addedAt.toIso8601String(),
      'lastRefreshedAt': root.lastRefreshedAt?.toIso8601String(),
    };
  }

  TemplateRoot _deserializeTemplateRoot(Map<String, dynamic> data) {
    return TemplateRoot(
      id: data['id'] as String,
      path: data['path'] as String,
      addedAt: DateTime.parse(data['addedAt'] as String),
      lastRefreshedAt: data['lastRefreshedAt'] != null
          ? DateTime.parse(data['lastRefreshedAt'] as String)
          : null,
    );
  }

  /// Restores a single project from the Google Drive backup.
  /// Downloads and merges the project's metadata, preview song, and any related
  /// release artwork. Preserves local filesystem fields (filePath, fileName, etc.).
  Future<void> restoreSingleProject({
    required String projectId,
    required ProfileRepository profileRepo,
  }) async {
    if (!isSignedIn) {
      throw Exception('Not signed in to Google Drive');
    }

    final remoteData = await downloadDatabase();

    final projectsList = remoteData['projects'] as List?;
    if (projectsList == null || projectsList.isEmpty) {
      throw Exception('No projects found in backup');
    }

    Map<String, dynamic>? projectMap;
    for (final p in projectsList) {
      if ((p as Map<String, dynamic>)['id'] == projectId) {
        projectMap = p;
        break;
      }
    }
    if (projectMap == null) {
      throw Exception('Project not found in backup');
    }

    final remoteProject = _deserializeProject(projectMap);

    // Locate the Hive box that holds this project, guided by the profile mapping if present
    final projectToProfileMap = remoteData['projectToProfile'] as Map<String, dynamic>?;
    final profileId = projectToProfileMap?[projectId] as String?;

    Box<MusicProject>? profileProjectsBox;
    MusicProject? localProject;

    if (profileId != null) {
      profileProjectsBox = await Hive.openBox<MusicProject>('${profileId}_projects');
      localProject = profileProjectsBox.get(projectId);
    } else {
      for (final profile in profileRepo.getAllProfiles()) {
        final box = await Hive.openBox<MusicProject>('${profile.id}_projects');
        final found = box.get(projectId);
        if (found != null) {
          profileProjectsBox = box;
          localProject = found;
          break;
        }
      }
      if (profileProjectsBox == null) {
        final profiles = profileRepo.getAllProfiles();
        if (profiles.isEmpty) throw Exception('No profiles found');
        profileProjectsBox = await Hive.openBox<MusicProject>('${profiles.first.id}_projects');
      }
    }

    // Download preview song if available
    final previewSongFiles = remoteData['previewSongFiles'] as Map<String, dynamic>?;
    final previewSongHashes = remoteData['previewSongHashes'] as Map<String, dynamic>?;
    final previewSongFileNames = remoteData['previewSongFileNames'] as Map<String, dynamic>?;

    String? previewSongPath = localProject?.previewSongPath;
    String? previewSongFileName;
    String? uploadedPreviewSongHash;

    if (previewSongFiles != null && previewSongFiles.containsKey(projectId)) {
      final driveFileId = previewSongFiles[projectId] as String;
      String? originalFileName = previewSongFileNames?[projectId] as String?;
      if (originalFileName == null &&
          remoteProject.previewSongPath != null &&
          !_isDriveFileReference(remoteProject.previewSongPath!)) {
        originalFileName = _realPreviewFileNameOrNull(remoteProject.previewSongPath);
      }
      final expectedHash = previewSongHashes?[projectId] as String?;
      final fileExtension =
          originalFileName != null ? path.extension(originalFileName) : null;

      final downloadedPath = await downloadPreviewSongFile(
        driveFileId: driveFileId,
        projectId: projectId,
        expectedHash: expectedHash,
        fileExtension: fileExtension,
      );
      previewSongPath = downloadedPath ?? _createDriveFileReference(driveFileId);
      previewSongFileName = originalFileName;
      uploadedPreviewSongHash = expectedHash;
    }

    // Download this project's cover art if the backup carries one (#110).
    // A failed download leaves the local path untouched — the avatar falls
    // back to the accent colour and icon rather than to a broken image.
    final projectCoverArtFiles = remoteData['projectCoverArtFiles'] as Map<String, dynamic>?;
    final projectCoverArtHashes = remoteData['projectCoverArtHashes'] as Map<String, dynamic>?;

    String? coverArtPath = localProject?.thumbnailPath;
    if (projectCoverArtFiles != null && projectCoverArtFiles.containsKey(projectId)) {
      final remoteCover = remoteProject.thumbnailPath;
      final downloadedCover = await downloadProjectCoverArtFile(
        driveFileId: projectCoverArtFiles[projectId] as String,
        projectId: projectId,
        expectedHash: projectCoverArtHashes?[projectId] as String?,
        fileExtension: remoteCover != null && remoteCover.isNotEmpty
            ? path.extension(remoteCover)
            : null,
      );
      if (downloadedCover != null) coverArtPath = downloadedCover;
    }

    // Merge into local project or use remote directly for a new project
    final MusicProject projectToSave;
    if (localProject != null) {
      projectToSave = localProject.copyWith(
        notes: remoteProject.notes,
        todos: remoteProject.todos,
        parts: remoteProject.parts,
        attachments: remoteProject.attachments,
        bpm: remoteProject.bpm,
        musicalKey: remoteProject.musicalKey,
        status: remoteProject.status,
        customDisplayName: remoteProject.customDisplayName,
        hidden: remoteProject.hidden,
        deadline: remoteProject.deadline,
        clearDeadline: remoteProject.deadline == null,
        statusChangedAt: remoteProject.statusChangedAt,
        previewSongPath: previewSongPath,
        previewSongFileName:
            previewSongFileName ?? remoteProject.previewSongFileName,
        uploadedPreviewSongHash:
            uploadedPreviewSongHash ?? remoteProject.uploadedPreviewSongHash,
        updatedAt: remoteProject.updatedAt,
        lastModifiedAt: remoteProject.lastModifiedAt,
        fileCreatedAt: remoteProject.fileCreatedAt,
        thumbnailPath: coverArtPath,
        clearThumbnailPath: coverArtPath == null,
        accentColor: remoteProject.accentColor,
        clearAccentColor: remoteProject.accentColor == null,
        iconKey: remoteProject.iconKey,
        clearIconKey: remoteProject.iconKey == null,
      );
    } else {
      projectToSave = remoteProject.copyWith(
        previewSongPath: previewSongPath ?? remoteProject.previewSongPath,
        previewSongFileName:
            previewSongFileName ?? remoteProject.previewSongFileName,
        uploadedPreviewSongHash:
            uploadedPreviewSongHash ?? remoteProject.uploadedPreviewSongHash,
        thumbnailPath: coverArtPath,
        clearThumbnailPath: coverArtPath == null,
      );
    }

    await profileProjectsBox.put(projectToSave.id, projectToSave);
    await profileProjectsBox.flush();
    // Second put forces Hive to emit a BoxEvent even if the object reference is unchanged
    await profileProjectsBox.put(projectToSave.id, projectToSave.copyWith());
    await profileProjectsBox.flush();

    // Download related release artwork for any release that contains this project
    final releaseArtworkFiles = remoteData['releaseArtworkFiles'] as Map<String, dynamic>?;
    final releaseArtworkHashes = remoteData['releaseArtworkHashes'] as Map<String, dynamic>?;

    if (releaseArtworkFiles != null) {
      final releasesList = remoteData['releases'] as List?;
      if (releasesList != null) {
        for (final releaseMap in releasesList.cast<Map<String, dynamic>>()) {
          final trackIds =
              (releaseMap['trackIds'] as List?)?.cast<String>() ?? <String>[];
          if (trackIds.contains(projectId)) {
            final releaseId = releaseMap['id'] as String;
            if (releaseArtworkFiles.containsKey(releaseId)) {
              final driveFileId = releaseArtworkFiles[releaseId] as String;
              final expectedHash = releaseArtworkHashes?[releaseId] as String?;
              final artworkPath = releaseMap['artworkImagePath'] as String?;
              final fileExtension =
                  artworkPath != null ? path.extension(artworkPath) : null;
              await downloadReleaseArtworkFile(
                driveFileId: driveFileId,
                releaseId: releaseId,
                expectedHash: expectedHash,
                fileExtension: fileExtension,
              );
            }
            break;
          }
        }
      }
    }
  }
}

/// Custom HTTP client that adds Google authentication headers to requests
/// Custom HTTP client that adds authentication headers to requests
/// Similar to GoogleHttpClient pattern from flutter_gdrive repository
/// This wraps a base http.Client and adds auth headers from GoogleSignIn
class _AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;

  _AuthenticatedHttpClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Add authentication headers to the request
    // This follows the same pattern as GoogleHttpClient in flutter_gdrive
    _headers.forEach((key, value) {
      request.headers[key] = value;
    });
    return _inner.send(request);
  }

  @override
  Future<http.Response> head(Object url, {Map<String, String>? headers}) {
    final mergedHeaders = <String, String>{..._headers};
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }
    // Convert url to Uri if it's a String
    final uri = url is Uri ? url : Uri.parse(url.toString());
    return _inner.head(uri, headers: mergedHeaders);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Result of a sync operation
class SyncResult {
  final int projectsAdded;
  final int projectsUpdated;
  final int projectsDeleted;
  final int releasesAdded;
  final int releasesUpdated;
  final int releasesDeleted;
  final int previewSongsDownloaded;
  final int previewSongsUpdated;

  SyncResult({
    required this.projectsAdded,
    required this.projectsUpdated,
    this.projectsDeleted = 0,
    required this.releasesAdded,
    required this.releasesUpdated,
    this.releasesDeleted = 0,
    this.previewSongsDownloaded = 0,
    this.previewSongsUpdated = 0,
  });
}

