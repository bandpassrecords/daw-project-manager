import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInException, GoogleSignInExceptionCode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'widgets/desktop_title_bar.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../services/google_drive_sync_service.dart' show GoogleDriveSyncService, UploadCancelledException;
import '../models/backup_progress.dart';
import '../models/auto_backup_interval.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import '../generated/l10n/app_localizations.dart';
import 'google_drive_sync_page_download_dialog.dart';

class GoogleDriveSyncPage extends StatelessWidget {
  const GoogleDriveSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MobileUtils.isMobile();
    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.googleDriveSync),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(
            title: AppLocalizations.of(context)!.googleDriveSync,
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: MobileUtils.getResponsivePadding(context),
              child: const GoogleDriveSyncSection(),
            ),
          ),
        ],
      ),
    );
  }
}

/// The actual Google Drive sign-in / backup / auto-backup UI, extracted so it
/// can be embedded both as its own page (mobile, and desktop's quick-access
/// shortcut) and inline as the Backup tab's Drive section in SettingsPage.
class GoogleDriveSyncSection extends ConsumerStatefulWidget {
  const GoogleDriveSyncSection({super.key});

  @override
  ConsumerState<GoogleDriveSyncSection> createState() => _GoogleDriveSyncSectionState();
}

class _GoogleDriveSyncSectionState extends ConsumerState<GoogleDriveSyncSection> {
  final GoogleDriveSyncService _syncService = GoogleDriveSyncService();
  bool _isSyncing = false;
  String? _syncStatus;
  DateTime? _lastSyncTime;

  bool _isSignedIn = false;
  bool _isCheckingSession = false;
  bool _hasNewerBackupAvailable = false;
  DateTime? _remoteBackupTime;
  DateTime? _lastUploadTime;
  StreamSubscription<bool>? _authStateSubscription;

  // Cached separately from the rest of the sync status so the "Signed in
  // as" row can show its own loading placeholder independent of the
  // timestamp rows below it — see _loadUserEmail.
  String? _userEmail;
  bool _loadingEmail = false;
  // Gates the shimmer placeholders on the four timestamp rows while
  // _loadSyncStatus is in flight, so those fields never render blank.
  bool _loadingTimestamps = true;

  @override
  void initState() {
    super.initState();
    _checkSessionStatusOnce();
    _loadSyncStatus();
    // Keep _isSignedIn in sync with service auth events that fire asynchronously
    // (e.g. lightweight auth completing after the initial 1500 ms timeout).
    _authStateSubscription = GoogleDriveSyncService.authStateStream.listen((isSignedIn) {
      if (mounted) {
        setState(() {
          _isSignedIn = isSignedIn;
          if (isSignedIn && _syncStatus != AppLocalizations.of(context)!.sessionActive) {
            _syncStatus = AppLocalizations.of(context)!.sessionActive;
          }
        });
        if (isSignedIn) {
          _loadSyncStatus();
          _loadUserEmail();
        }
      }
    });
  }

  /// Fetches the signed-in user's email once and caches it, instead of the
  /// FutureBuilder-per-build approach this used to use (which re-issued the
  /// lookup on every rebuild and left the row blank while pending).
  Future<void> _loadUserEmail() async {
    if (!mounted) return;
    setState(() => _loadingEmail = true);
    try {
      final email = await _syncService.getCurrentUserEmail();
      if (mounted) setState(() => _userEmail = email);
    } catch (_) {
      // Row falls back to its empty placeholder below.
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _syncService.dispose();
    super.dispose();
  }

  /// Check session status once when page is created
  /// Session state persists for entire app session - no need to check again
  Future<void> _checkSessionStatusOnce() async {
    if (_isCheckingSession) return;
    
    setState(() {
      _isCheckingSession = true;
    });

    try {
      // Initialize GoogleSignIn (required in 7.x)
      // This will attempt lightweight auth only once per app session
      if (MobileUtils.isMobile()) {
        await _syncService.initialize();
      }
      
      // Initialize credentials storage
      await _syncService.initializeCredentialsStorage();
      
      // On desktop, try to restore session silently first (using saved credentials)
      // This avoids redirecting to browser if we already have valid tokens
      if (!MobileUtils.isMobile()) {
        try {
          final restored = await _syncService.restoreSession();
          if (mounted) {
            setState(() {
              _isSignedIn = restored;
              _isCheckingSession = false;
              if (restored) {
                _syncStatus = AppLocalizations.of(context)!.sessionActive;
              } else {
                _syncStatus = null;
              }
            });
            if (restored) _loadUserEmail();
          }
          return; // Exit early if we restored (or failed to restore) on desktop
        } catch (e) {
          if (kDebugMode) print('Error restoring session on desktop: $e');
          // Continue to check isSignedIn as fallback
        }
      }
      
      // Check if already signed in (without prompting)
      // Wait a bit for lightweight authentication to complete (if it happens on first init)
      if (MobileUtils.isMobile()) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
      
      final isSignedIn = await _syncService.checkSignedInStatus();
      
      if (mounted) {
        setState(() {
          _isSignedIn = isSignedIn;
          _isCheckingSession = false;
          if (isSignedIn) {
            _syncStatus = AppLocalizations.of(context)!.signedIn;
            // Try to restore session silently
            _syncService.restoreSession().then((restored) {
              if (mounted) {
                setState(() {
                  if (restored) {
                    _syncStatus = AppLocalizations.of(context)!.sessionActive;
                  } else {
                    _syncStatus = AppLocalizations.of(context)!.signedIn;
                  }
                });
              }
            }).catchError((e) {
              if (kDebugMode) print('Error restoring session: $e');
            });
          } else {
            _syncStatus = null;
          }
        });
        if (isSignedIn) _loadUserEmail();
      }
    } catch (e) {
      if (kDebugMode) print('Error checking session status: $e');
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _isCheckingSession = false;
          _syncStatus = null;
        });
      }
    }
  }
  
  /// Check if user is already signed in (without prompting)
  /// This is called when user explicitly clicks sign in button
  /// On desktop, automatically restore session from saved credentials
  /// On mobile, just check session status
  Future<void> _checkSessionStatus() async {
    // If already signed in, don't check again
    if (_isSignedIn) {
      if (kDebugMode) print('Already signed in, skipping session check');
      return;
    }
    
    await _checkSessionStatusOnce();
  }

  Future<void> _loadSyncStatus() async {
    if (mounted) setState(() => _loadingTimestamps = true);
    try {
      final lastSync = await _syncService.getLastSyncTime();
      if (lastSync != null) {
        setState(() {
          _lastSyncTime = lastSync;
        });
      }

      // Local record of this device's last upload — still used to compute
      // the auto-backup section's "next backup" label.
      final lastUpload = await _syncService.getLastBackupUploadTimestamp();
      if (mounted) {
        setState(() {
          _lastUploadTime = lastUpload;
        });
      }

      // Populates Remote Backup Time (what's actually on Drive right now,
      // which can differ from Last Sync if another device pushed since) —
      // shown on every platform. Only the "newer backup available" banner
      // itself stays mobile-only, gated at render time below.
      if (_isSignedIn) {
        await _checkForNewerBackup();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading sync status: $e');
    } finally {
      if (mounted) setState(() => _loadingTimestamps = false);
    }
  }

  /// Check if a newer backup is available on Drive
  Future<void> _checkForNewerBackup() async {
    try {
      final backupInfo = await _syncService.getBackupInfo();
      if (mounted) {
        setState(() {
          _hasNewerBackupAvailable = backupInfo['isNewer'] == true;
          _remoteBackupTime = backupInfo['remoteTimestamp'] as DateTime?;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error checking for newer backup: $e');
      if (mounted) {
        setState(() {
          _hasNewerBackupAvailable = false;
          _remoteBackupTime = null;
        });
      }
    }
  }

  Future<void> _signInToGoogleDrive() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncStatus = null;
      });

      if (MobileUtils.isMobile()) {
        // Mobile sign-in
        await _syncService.initialize();
        final success = await _syncService.signIn();

        if (success) {
          // Wait a bit for authenticationEvents to process
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Verify sign-in status after authentication
          final verifiedSignedIn = await _syncService.checkSignedInStatus();
          
          setState(() {
            _isSignedIn = verifiedSignedIn;
            _isSyncing = false;
          });

          if (verifiedSignedIn) {
            // On Android, don't create initial backup automatically
            // User can manually upload backup if needed
            setState(() {
              _syncStatus = AppLocalizations.of(context)!.successfullySignedInToGoogleDrive;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.successfullySignedInToGoogleDriveMessage),
                  backgroundColor: Colors.green,
                ),
              );
            }

            await _loadSyncStatus();
            _loadUserEmail();
          } else {
            setState(() {
              _syncStatus = AppLocalizations.of(context)!.signInCancelledOrFailed;
              _isSyncing = false;
            });
          }
        } else {
          setState(() {
            _isSignedIn = false;
            _syncStatus = AppLocalizations.of(context)!.signInCancelledOrFailed;
            _isSyncing = false;
          });
        }
      } else {
        // Desktop sign-in (loopback flow: browser opens, redirect comes back to local server)
        setState(() {
          _isSyncing = true;
          _syncStatus = null;
        });

        try {
          final authClient = await _syncService.signInDesktopWithLoopback();

          if (authClient == null) {
            setState(() {
              _syncStatus = AppLocalizations.of(context)!.signInCancelledOrFailed;
              _isSyncing = false;
            });
            return;
          }

          // Set up Drive API
          _syncService.driveApi = drive.DriveApi(authClient);
          _syncService.desktopAuthClient = authClient;
          await _syncService.ensureAppDataFolder();

          setState(() {
            _isSignedIn = true;
            _isSyncing = false;
          });

          // On desktop, don't create initial backup automatically
          // User can manually upload backup if needed
          setState(() {
            _syncStatus = AppLocalizations.of(context)!.successfullySignedInToGoogleDrive;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.successfullySignedInToGoogleDriveMessage),
                backgroundColor: Colors.green,
              ),
            );
          }

          await _loadSyncStatus();
          _loadUserEmail();
        } catch (e) {
          setState(() {
            _syncStatus = AppLocalizations.of(context)!.errorSigningIn(e.toString());
            _isSyncing = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.errorSigningIn(e.toString())),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error during sign-in: $e');
      if (!mounted) return;

      String errorMessage = AppLocalizations.of(context)!.unknownError;
      String errorDetails = e.toString();

      if (e is GoogleSignInException) {
        errorMessage = AppLocalizations.of(context)!.googleSignInError;
        errorDetails = e.description ?? e.toString();
        
        if (e.code == GoogleSignInExceptionCode.unknownError) {
          if (e.description?.contains('[28444]') ?? false) {
            errorDetails = AppLocalizations.of(context)!.developerConsoleNotSetUp;
          }
        }
      } else if (e is PlatformException) {
        errorMessage = AppLocalizations.of(context)!.platformError;
        errorDetails = e.message ?? e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $errorDetails'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      setState(() {
        _isSyncing = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _signOutFromGoogleDrive() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncStatus = null;
      });

      await _syncService.signOut();

      setState(() {
        _isSignedIn = false;
        _syncStatus = AppLocalizations.of(context)!.signedOutFromGoogleDrive;
        _lastSyncTime = null;
        _userEmail = null;
      });
    } catch (e) {
      setState(() {
        _syncStatus = AppLocalizations.of(context)!.errorSigningOut(e.toString());
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  /// Check for new backup (doesn't download - just checks if one is available)
  Future<void> _checkForBackupManually() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncStatus = AppLocalizations.of(context)!.checkingForBackup;
      });

      await _checkForNewerBackup();
      
      if (_hasNewerBackupAvailable) {
        setState(() {
          _syncStatus = AppLocalizations.of(context)!.newerBackupAvailable;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.orange,
              content: Row(
                children: [
                  // Texto da mensagem
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.newerBackupAvailable,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  // Botão de Download (como texto clicável)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      _downloadBackupFromDrive();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.download.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // O seu botão de "X" para fechar
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        setState(() {
          _syncStatus = AppLocalizations.of(context)!.backupUpToDate;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backupUpToDate),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _syncStatus = AppLocalizations.of(context)!.errorCheckingBackup(e.toString());
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorCheckingBackup(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  /// Upload backup to Google Drive (manual)
  Future<void> _uploadBackupToDrive() async {
    try {
      // Check if remote backup is newer before uploading
      final backupInfo = await _syncService.getBackupInfo();
      if (!mounted) return;
      if (backupInfo['isNewer'] == true) {
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(AppLocalizations.of(context)!.confirmUpload),
            content: Text(AppLocalizations.of(context)!.remoteBackupIsNewer),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.uploadBackup),
              ),
            ],
          ),
        );
        
        if (confirmed != true) {
          return; // User cancelled
        }
      }
      
      setState(() {
        _isSyncing = true;
        _syncStatus = AppLocalizations.of(context)!.uploadingBackup;
      });

      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfileId = profileRepo.getCurrentProfileId();
      
      if (currentProfileId == null) {
        setState(() {
          _isSyncing = false;
          _syncStatus = AppLocalizations.of(context)!.errorNoProfileSelected;
        });
        return;
      }

      final projectRepo = await ref.read(repositoryProvider.future);
      if (!mounted) return;

      // Show progress dialog on all platforms
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MobileUtils.isMobile()
            ? UploadProgressDialog(progressStream: _syncService.progressStream)
            : _BackupProgressDialog(
                progressStream: _syncService.progressStream,
                syncService: _syncService,
              ),
      );

      await _syncService.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        uploadAutoDetectedSongs: ref.read(uploadAutoPreviewSongsProvider),
      );

      // Close progress dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Reset syncing state IMMEDIATELY after upload completes
      // This unlocks the UI right away
      setState(() {
        _isSyncing = false;
        _syncStatus = AppLocalizations.of(context)!.backupUploadedSuccessfully;
        _lastSyncTime = DateTime.now();
      });

      if (mounted) {
        final warnings = _syncService.lastUploadWarnings;
        if (warnings.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backupUploadedSuccessfullyMessage),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)!.backupUploadedSuccessfullyMessage}'
                '\n⚠ ${warnings.length} file(s) failed to upload:\n${warnings.join('\n')}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } on UploadCancelledException catch (_) {
      // User cancelled - close dialog and show info message (no error)
      if (!MobileUtils.isMobile() && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _syncStatus = AppLocalizations.of(context)!.uploadCancelled;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.backupUploadCancelledByUser),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Other errors - close dialog and show error
      if (!MobileUtils.isMobile() && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _syncStatus = AppLocalizations.of(context)!.errorUploadingBackup(e.toString());
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUploadingBackup(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  /// Download backup from Google Drive (manual)
  Future<void> _downloadBackupFromDrive() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = AppLocalizations.of(context)!.downloadingBackup;
    });

    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      if (!mounted) return;

      // On mobile, allow download even without active profile (will activate first profile after download)
      // On desktop, require active profile
      if (!MobileUtils.isMobile()) {
        final currentProfileId = profileRepo.getCurrentProfileId();
        if (currentProfileId == null) {
          setState(() {
            _isSyncing = false;
            _syncStatus = AppLocalizations.of(context)!.errorNoProfileSelected;
          });
          return;
        }
      }

      // Show progress dialog
      if (MobileUtils.isMobile()) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DownloadProgressDialog(
            progressStream: _syncService.progressStream,
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _BackupProgressDialog(
            progressStream: _syncService.progressStream,
            syncService: _syncService,
            isDownload: true,
          ),
        );
      }

      Map<String, dynamic> remoteData;
      try {
        remoteData = await _syncService.downloadDatabase();
      } catch (e) {
        if (e.toString().contains('Database file not found')) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.noBackupFileFound),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
          setState(() {
            _isSyncing = false;
            _syncStatus = AppLocalizations.of(context)!.noBackupFileFoundStatus;
          });
          return;
        }
        rethrow;
      }

      final projectRepo = await ref.read(repositoryProvider.future);
      final hasLocalData = projectRepo.projectsBox.isNotEmpty || projectRepo.releasesBox.isNotEmpty;

      bool downloadPreviewSongs = true;

      if (!mounted) return;

      if (hasLocalData) {
        final dialogResult = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => _DownloadBackupDialog(
            downloadPreviewSongs: downloadPreviewSongs,
          ),
        );

        if (dialogResult == null || dialogResult['confirm'] != true) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          setState(() {
            _isSyncing = false;
            _syncStatus = AppLocalizations.of(context)!.downloadCancelled;
          });
          return;
        }

        downloadPreviewSongs = dialogResult['downloadPreviewSongs'] as bool? ?? true;
      }

      final result = await _syncService.mergeData(
        remoteData: remoteData,
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: downloadPreviewSongs,
      );

      // Close progress dialog if it's open (mobile)
      if (MobileUtils.isMobile() && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await _syncService.cleanupEmptyProfile(profileRepo);

      // On mobile, if no profile is active, activate the first profile from backup
      if (MobileUtils.isMobile()) {
        final currentProfileId = profileRepo.getCurrentProfileId();
        if (currentProfileId == null) {
          final allProfiles = profileRepo.getAllProfiles();
          if (allProfiles.isNotEmpty) {
            await profileRepo.setCurrentProfileId(allProfiles.first.id);
          }
        }
      }

      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStatus = AppLocalizations.of(context)!.backupDownloadedDetailed(
            result.projectsAdded,
            result.projectsUpdated,
            result.releasesAdded,
            result.releasesUpdated,
            result.previewSongsDownloaded,
            result.previewSongsUpdated,
          );
          _lastSyncTime = DateTime.now();
          _hasNewerBackupAvailable = false;
        });
      }

      if (mounted) {
        ref.invalidate(repositoryProvider);
        ref.invalidate(allProjectsStreamProvider);
        ref.invalidate(releasesProvider);
        ref.invalidate(scanRootsProvider);
        ref.invalidate(currentProfileProvider);
      }

      if (mounted && MobileUtils.isMobile()) {
        await _checkForNewerBackup();
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await ref.read(repositoryProvider.future);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.backupDownloaded(
              result.projectsAdded,
              result.projectsUpdated,
              result.releasesAdded,
              result.releasesUpdated,
            )),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close progress dialog if it's open (mobile)
      if (MobileUtils.isMobile() && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        setState(() {
          _syncStatus = AppLocalizations.of(context)!.errorDownloadingBackup(e.toString());
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorDownloadingBackup(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  /// A single info row (icon + text) that always renders at the same
  /// height regardless of state — real value, shimmer placeholder while
  /// loading, or a muted/dimmed value when signed out. This is what keeps
  /// the whole card a fixed size instead of growing/shrinking as data
  /// becomes available (see the class doc comment).
  Widget _infoRow({required IconData icon, required bool dimmed, required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    final color = dimmed ? cs.onSurfaceVariant.withValues(alpha: 0.5) : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 18,
              child: Align(
                alignment: Alignment.centerLeft,
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 13, color: color),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MobileUtils.isMobile();
    final cs = Theme.of(context).colorScheme;
    final connected = _isSignedIn;
    final locale = Localizations.localeOf(context).toString();
    String fmt(DateTime d) => DateFormat.yMMMd(locale).add_jm().format(d);

    // Always the same four buttons — only which ones are enabled changes —
    // so the button row never grows or shrinks between signed-in/out.
    final signInOutButton = connected
        ? OutlinedButton.icon(
            icon: const Icon(Icons.logout, size: 18),
            label: Text(l10n.signOut),
            onPressed: _isSyncing ? null : _signOutFromGoogleDrive,
          )
        : ElevatedButton.icon(
            icon: const Icon(Icons.login, size: 18),
            label: Text(l10n.signInToGoogleDrive),
            onPressed: (_isSyncing || _isCheckingSession) ? null : _signInToGoogleDrive,
          );
    final checkButton = ElevatedButton.icon(
      icon: const Icon(Icons.refresh, size: 18),
      label: Text(l10n.checkForBackup),
      onPressed: (connected && !_isSyncing) ? _checkForBackupManually : null,
    );
    final uploadButton = ElevatedButton.icon(
      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
      label: Text(l10n.uploadBackup),
      onPressed: (connected && !_isSyncing) ? _uploadBackupToDrive : null,
    );
    final downloadButton = ElevatedButton.icon(
      icon: const Icon(Icons.cloud_download_outlined, size: 18),
      label: Text(l10n.downloadBackup),
      onPressed: (connected && !_isSyncing) ? _downloadBackupFromDrive : null,
    );
    final buttons = [signInOutButton, checkButton, uploadButton, downloadButton];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Theme.of(context).cardColor,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_outlined, size: 22, color: cs.primary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.googleDriveSync,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_isSyncing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < buttons.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            buttons[i],
                          ],
                        ],
                      )
                    : Wrap(spacing: 8, runSpacing: 8, children: buttons),
                const Divider(height: 24),
                Builder(builder: (context) {
                  // Only worth surfacing when something went wrong — "signed in
                  // and everything's fine" is already obvious from the rows
                  // below, so a permanent "Session active" line was just noise.
                  // maintainSize keeps this row's footprint constant whether or
                  // not it has content, so the card never resizes around it.
                  final statusText = _syncStatus;
                  final isError = statusText != null &&
                      (statusText.contains('Error') || statusText.contains('Failed'));
                  return Visibility(
                    visible: isError,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${l10n.status}: ${statusText ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                _infoRow(
                  icon: Icons.person_outline,
                  dimmed: !connected,
                  child: !connected
                      ? Text(l10n.notSignedInYet)
                      : (_loadingEmail
                          ? const _ShimmerLine(width: 170)
                          : Text(
                              _userEmail == null ? l10n.notSignedInYet : l10n.signedInAs(_userEmail!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )),
                ),
                _infoRow(
                  icon: Icons.sync,
                  dimmed: !connected,
                  child: _loadingTimestamps
                      ? const _ShimmerLine(width: 140)
                      : Text(l10n.lastSync(_lastSyncTime == null ? l10n.never : fmt(_lastSyncTime!))),
                ),
                _infoRow(
                  icon: Icons.cloud_queue,
                  dimmed: !connected,
                  child: _loadingTimestamps
                      ? const _ShimmerLine(width: 150)
                      : Text(l10n.remoteBackupTime(_remoteBackupTime == null ? l10n.never : fmt(_remoteBackupTime!))),
                ),
                // Newer-backup banner — mobile only, unrelated to the
                // fixed-size fields above (an alert, not a loading field).
                if (isMobile && _hasNewerBackupAvailable)
                  Container(
                    margin: const EdgeInsets.only(top: 12.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade300, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_download, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.newerBackupAvailable,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).cardColor,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_outlined, size: 22, color: cs.primary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.autoBackup,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.autoBackupDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(l10n.autoBackupInterval, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 16),
                    DropdownButton<AutoBackupInterval>(
                      value: ref.watch(autoBackupIntervalProvider),
                      items: [
                        DropdownMenuItem(
                          value: AutoBackupInterval.off,
                          child: Text(l10n.autoBackupOff),
                        ),
                        DropdownMenuItem(
                          value: AutoBackupInterval.every30min,
                          child: Text(l10n.autoBackupEvery30Min),
                        ),
                        DropdownMenuItem(
                          value: AutoBackupInterval.hourly,
                          child: Text(l10n.autoBackupHourly),
                        ),
                        DropdownMenuItem(
                          value: AutoBackupInterval.every6hours,
                          child: Text(l10n.autoBackupEvery6Hours),
                        ),
                        DropdownMenuItem(
                          value: AutoBackupInterval.daily,
                          child: Text(l10n.autoBackupDaily),
                        ),
                      ],
                      onChanged: !connected
                          ? null
                          : (value) {
                              if (value != null) {
                                ref.read(autoBackupIntervalProvider.notifier).setInterval(value);
                              }
                            },
                    ),
                  ],
                ),
                Builder(builder: (context) {
                  // _lastUploadTime starts null while timestamps are still
                  // loading, so this line would otherwise pop in/out (and
                  // resize the card) once it resolves. maintainSize keeps its
                  // footprint reserved the whole time, same as the Status row
                  // above.
                  final interval = ref.watch(autoBackupIntervalProvider);
                  final showNextBackup = interval != AutoBackupInterval.off && _lastUploadTime != null;
                  return Visibility(
                    visible: showNextBackup,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        showNextBackup
                            ? l10n.autoBackupNextBackup(_nextBackupLabel(l10n, interval, _lastUploadTime!))
                            : '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                }),
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.uploadAutoDetectedPreviewSongs, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    l10n.uploadAutoDetectedPreviewSongsSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: ref.watch(uploadAutoPreviewSongsProvider),
                  onChanged: !connected
                      ? null
                      : (_) => ref.read(uploadAutoPreviewSongsProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _nextBackupLabel(AppLocalizations l10n, AutoBackupInterval interval, DateTime lastUpload) {
    final next = lastUpload.add(interval.duration!);
    final diff = next.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds < 30) return l10n.autoBackupNextSoon;
    if (diff.inMinutes < 60) return l10n.autoBackupNextInMinutes(diff.inMinutes);
    if (diff.inHours == 1) return l10n.autoBackupNextInOneHour;
    if (diff.inHours < 24) return l10n.autoBackupNextInHours(diff.inHours);
    if (diff.inDays == 1) return l10n.autoBackupNextInOneDay;
    return l10n.autoBackupNextInDays(diff.inDays);
  }
}

/// A pulsing translucent bar standing in for a value that's still being
/// fetched — the loading-feedback equivalent of a skeleton screen, scoped
/// to a single text field instead of the whole card.
class _ShimmerLine extends StatefulWidget {
  final double width;

  const _ShimmerLine({this.width = 120});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.25, end: 0.6).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Container(
        width: widget.width,
        height: 12,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: _opacity.value * 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Dialog for confirming backup download with option to download preview songs
class _DownloadBackupDialog extends StatefulWidget {
  final bool downloadPreviewSongs;
  
  const _DownloadBackupDialog({
    required this.downloadPreviewSongs,
  });

  @override
  State<_DownloadBackupDialog> createState() => _DownloadBackupDialogState();
}

class _DownloadBackupDialogState extends State<_DownloadBackupDialog> {
  late bool _downloadPreviewSongs;

  @override
  void initState() {
    super.initState();
    _downloadPreviewSongs = widget.downloadPreviewSongs;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(AppLocalizations.of(context)!.downloadBackup),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.downloadBackupConfirmation,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _downloadPreviewSongs,
            onChanged: (value) {
              setState(() {
                _downloadPreviewSongs = value ?? true;
              });
            },
            title: Text(AppLocalizations.of(context)!.downloadPreviewSongs),
            subtitle: Text(
              AppLocalizations.of(context)!.downloadPreviewSongsExplanation,
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {'confirm': false}),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'confirm': true,
            'downloadPreviewSongs': _downloadPreviewSongs,
          }),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(AppLocalizations.of(context)!.replaceLocalData),
        ),
      ],
    );
  }
}

/// Dialog for entering authorization code (Desktop)
class _AuthorizationCodeDialog extends StatefulWidget {
  @override
  State<_AuthorizationCodeDialog> createState() => _AuthorizationCodeDialogState();
}

class _AuthorizationCodeDialogState extends State<_AuthorizationCodeDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.enterAuthorizationCode),
      content: TextField(
        controller: _codeController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.authorizationCode,
          hintText: AppLocalizations.of(context)!.pasteCodeFromBrowser,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _codeController.text),
          child: Text(AppLocalizations.of(context)!.continueButton),
        ),
      ],
    );
  }
}

/// Dialog for showing backup upload/download progress
class _BackupProgressDialog extends StatefulWidget {
  final Stream<BackupProgress> progressStream;
  final GoogleDriveSyncService syncService;
  final bool isDownload;

  const _BackupProgressDialog({
    required this.progressStream,
    required this.syncService,
    this.isDownload = false,
  });

  @override
  State<_BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<_BackupProgressDialog> {
  bool _isCancelling = false;
  bool _hasCompleted = false;

  String _getStageText(BackupProgressStage stage, BuildContext context) {
    switch (stage) {
      case BackupProgressStage.collectingData:
        return AppLocalizations.of(context)!.collectingData;
      case BackupProgressStage.uploadingPreviewSongs:
        return AppLocalizations.of(context)!.uploadingPreviewSongs;
      case BackupProgressStage.uploadingProfilePhotos:
        return AppLocalizations.of(context)!.uploadingProfilePhotos;
      case BackupProgressStage.uploadingReleaseArtwork:
        return AppLocalizations.of(context)!.uploadingReleaseArtwork;
      case BackupProgressStage.uploadingProjectCoverArt:
        return AppLocalizations.of(context)!.uploadingProjectCoverArt;
      case BackupProgressStage.uploadingDatabase:
        return AppLocalizations.of(context)!.uploadingDatabase;
      case BackupProgressStage.downloadingDatabase:
        return AppLocalizations.of(context)!.downloadingDatabase;
      case BackupProgressStage.downloadingPreviewSongs:
        return AppLocalizations.of(context)!.downloadingPreviewSongs;
      case BackupProgressStage.downloadingProfilePhotos:
        return AppLocalizations.of(context)!.downloadingProfilePhotos;
      case BackupProgressStage.downloadingReleaseArtwork:
        return AppLocalizations.of(context)!.downloadingReleaseArtwork;
      case BackupProgressStage.downloadingProjectCoverArt:
        return AppLocalizations.of(context)!.downloadingProjectCoverArt;
      case BackupProgressStage.mergingData:
        return AppLocalizations.of(context)!.mergingData;
      case BackupProgressStage.completed:
        return AppLocalizations.of(context)!.completed;
    }
  }

  void _handleCompletion() {
    if (!_hasCompleted && !_isCancelling && mounted) {
      _hasCompleted = true;
      // Close dialog after a short delay to show completion
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Row(
        children: [
          Icon(widget.isDownload ? Icons.cloud_download : Icons.cloud_upload, size: 24),
          const SizedBox(width: 8),
          Text(_isCancelling
              ? AppLocalizations.of(context)!.cancelling
              : widget.isDownload
                  ? AppLocalizations.of(context)!.downloadingBackupTitle
                  : AppLocalizations.of(context)!.uploadingBackupTitle),
        ],
      ),
      content: StreamBuilder<BackupProgress>(
        stream: widget.progressStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final progress = snapshot.data!;
          final percentage = (progress.progress * 100).toStringAsFixed(0);

          // Auto-close when completed
          if (progress.stage == BackupProgressStage.completed && progress.progress >= 1.0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleCompletion();
            });
          }

          return SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stage indicator
                Text(
                  _isCancelling ? AppLocalizations.of(context)!.cancellingUpload : _getStageText(progress.stage, context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isCancelling ? Colors.orange : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Current item
                Text(
                  _isCancelling ? AppLocalizations.of(context)!.pleaseWaitCancellingUpload : progress.currentItem,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Progress indicator
                if (progress.totalItems > 0)
                  Text(
                    '${progress.currentIndex} / ${progress.totalItems}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                const SizedBox(height: 8),
                
                // Progress bar
                LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                
                // Percentage
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        if (!widget.isDownload)
          StreamBuilder<BackupProgress>(
            stream: widget.progressStream,
            builder: (context, snapshot) {
              // Only show cancel button if not completed or cancelling
              if (!snapshot.hasData ||
                  snapshot.data!.stage == BackupProgressStage.completed ||
                  _isCancelling) {
                return const SizedBox.shrink();
              }

              return TextButton(
                onPressed: () {
                  setState(() {
                    _isCancelling = true;
                  });
                  widget.syncService.cancelUpload();
                  // Don't close dialog here - let the exception handling close it
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              );
            },
          ),
      ],
    );
  }
}

