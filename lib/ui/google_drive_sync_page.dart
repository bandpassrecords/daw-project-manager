import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInException, GoogleSignInExceptionCode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/drive_sync_panel.dart';
import 'dialogs/drive_sync_dialogs.dart';
import '../services/google_drive_sync_service.dart';
import '../services/drive_sync_errors.dart';
import '../models/auto_backup_interval.dart';
import '../models/drive_sync_status.dart';
import '../providers/providers.dart';
import '../utils/first_connection.dart';
import '../utils/drive_sync_format.dart';
import '../utils/mobile_utils.dart';
import '../generated/l10n/app_localizations.dart';
import 'app_snack_bar.dart';

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

/// A sentence for something that went wrong here, and the raw error under it.
class _ShownError {
  const _ShownError(this.text, [this.details]);
  final String text;
  final String? details;
}

/// The Google Drive sign-in / sync / automatic sync UI, embedded both as its
/// own page (mobile, and desktop's quick-access shortcut) and inline as the
/// Backup section of SettingsPage.
///
/// This is the glue: it talks to the shared [GoogleDriveSyncService] and
/// [driveSyncStatusProvider] and hands [DriveSyncPanel] plain values.
class GoogleDriveSyncSection extends ConsumerStatefulWidget {
  const GoogleDriveSyncSection({super.key});

  @override
  ConsumerState<GoogleDriveSyncSection> createState() => _GoogleDriveSyncSectionState();
}

class _GoogleDriveSyncSectionState extends ConsumerState<GoogleDriveSyncSection> {
  // Read once in initState: `ref` is unusable in dispose(), and in the
  // finally blocks of operations still running when the page is closed.
  late final GoogleDriveSyncService _service;
  late final DriveSyncStatusNotifier _status;

  bool _checkingSession = true;
  bool _signingIn = false;
  bool _waitingForBrowser = false;
  bool _busy = false;
  String? _email;
  DateTime? _lastUpload;
  _ShownError? _error;
  StreamSubscription<bool>? _authStateSubscription;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _service = ref.read(googleDriveSyncServiceProvider);
    _status = ref.read(driveSyncStatusProvider.notifier);
    unawaited(_checkSession());
    _authStateSubscription = GoogleDriveSyncService.authStateStream.listen((signedIn) {
      if (!mounted) return;
      unawaited(_status.refresh());
      if (signedIn) unawaited(_loadAccount());
    });
    // Keeps "5 min ago" honest while the page stays open.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // The service is shared app-wide; it is not this page's to dispose.
    _authStateSubscription?.cancel();
    _clock?.cancel();
    if (_service.isWaitingForBrowser) _service.cancelDesktopSignIn();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  Future<void> _checkSession() async {
    try {
      if (!_service.isSignedIn) {
        if (MobileUtils.isMobile()) {
          await _service.initialize();
          // Lightweight auth reports through an event stream, a moment later.
          await Future.delayed(const Duration(milliseconds: 1500));
          if (await _service.checkSignedInStatus()) {
            await _service.restoreSession();
          }
        } else {
          await _service.restoreSession();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error checking session status: $e');
    }
    if (!mounted) return;
    setState(() => _checkingSession = false);
    await _status.refresh();
    if (_service.isSignedIn) await _loadAccount();
  }

  Future<void> _loadAccount() async {
    final email = await _service.getCurrentUserEmail();
    final lastUpload = await _service.getLastBackupUploadTimestamp();
    if (!mounted) return;
    setState(() {
      _email = email;
      _lastUpload = lastUpload;
    });
  }

  void _showError(Object error) {
    final kind = classifySyncError(error);
    setState(() => _error = _ShownError(
          syncErrorSentence(_l10n, kind),
          kind == SyncErrorKind.other ? '$error' : null,
        ));
    ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(
      content: Text(syncErrorSentence(_l10n, kind)),
      backgroundColor: Colors.red,
    ));
  }

  void _showCancelled() {
    ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(
      content: Text(_l10n.driveOperationCancelled),
      backgroundColor: Colors.orange,
    ));
  }

  // ---------------------------------------------------------------- sign in

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      final ok = MobileUtils.isMobile() ? await _signInMobile() : await _signInDesktop();
      if (!mounted || !ok) return;
      await _status.refresh();
      await _loadAccount();
      if (!mounted) return;
      // A device that has never synced starts manual: the app opening must
      // not upload a library nobody has looked at. Choosing to keep in sync
      // in the dialog below turns the automatic modes on.
      if (firstConnectionStaysManual(
        syncedBefore: await _service.getLastBackupUploadTimestamp() != null,
        startupChoiceStored: await SyncOnStartupNotifier.hasStoredChoice(),
      )) {
        await ref.read(syncOnStartupProvider.notifier).set(false);
      }
      if (mounted) await _offerFirstSync();
    } on DesktopSignInException catch (e) {
      if (mounted) setState(() => _error = _ShownError(signInFailureSentence(_l10n, e.failure)));
    } catch (e) {
      if (!mounted) return;
      var details = e.toString();
      if (e is GoogleSignInException) {
        details = e.description ?? details;
        if (e.code == GoogleSignInExceptionCode.unknownError &&
            (e.description?.contains('[28444]') ?? false)) {
          details = _l10n.developerConsoleNotSetUp;
        }
      } else if (e is PlatformException) {
        details = e.message ?? details;
      }
      setState(() => _error = _ShownError(_l10n.signInCancelledOrFailed, details));
    } finally {
      if (mounted) {
        setState(() {
          _signingIn = false;
          _waitingForBrowser = false;
        });
      }
    }
  }

  Future<bool> _signInMobile() async {
    await _service.initialize();
    if (!await _service.signIn()) return false;
    await Future.delayed(const Duration(milliseconds: 500));
    return _service.checkSignedInStatus();
  }

  Future<bool> _signInDesktop() async {
    setState(() => _waitingForBrowser = true);
    final client = await _service.signInDesktopWithLoopback(
      pageTexts: loopbackPageTexts(_l10n),
    );
    if (client == null) return false; // Refused or cancelled: nothing to say.
    _service.driveApi = drive.DriveApi(client);
    _service.desktopAuthClient = client;
    await _service.ensureAppDataFolder();
    return true;
  }

  /// Right after signing in: offer to bring a found backup here, or to
  /// upload this device's library, and to keep syncing automatically.
  Future<void> _offerFirstSync() async {
    final profileRepo = await ref.read(profileRepositoryProvider.future);
    final offerKeepInSync = ref.read(autoBackupIntervalProvider) == AutoBackupInterval.off;
    FirstSyncChoice? choice;
    try {
      final info = await _service.getRemoteBackupInfo();
      if (!mounted) return;
      if (info != null) {
        final backup = await _service.fetchBackup();
        final preview = await _service.previewMerge(backup.data, profileRepo);
        if (!mounted) return;
        choice = await showFirstSyncDialog(
          context,
          hasBackup: true,
          backupLine: _remoteLine(info.modifiedTime, info.device),
          previewLines: mergePreviewLines(_l10n, preview),
          uploadLines: uploadPreviewLines(_l10n, preview),
          offerKeepInSync: offerKeepInSync,
        );
      } else {
        final estimate = await _service.estimateUpload(
          profileRepo: profileRepo,
          includeAutoDetected: ref.read(uploadAutoPreviewSongsProvider),
        );
        if (!mounted) return;
        choice = await showFirstSyncDialog(
          context,
          hasBackup: false,
          estimateLine: estimate.files == 0
              ? null
              : _l10n.driveUploadEstimate(estimate.files, formatSyncBytes(estimate.bytes)),
          offerKeepInSync: offerKeepInSync,
        );
      }
    } catch (e) {
      if (kDebugMode) print('Could not look at Drive after sign-in: $e');
      return;
    }
    if (choice == null || !mounted) return;
    if (choice.keepInSync) {
      await ref.read(autoBackupIntervalProvider.notifier).setInterval(AutoBackupInterval.hourly);
      await ref.read(syncOnStartupProvider.notifier).set(true);
    }
    if (choice.syncNow) await _syncNow();
  }

  String _remoteLine(DateTime when, String? device) {
    final ago = syncAgoLabel(_l10n, when, DateTime.now(),
        locale: Localizations.localeOf(context).toString());
    if (device == GoogleDriveSyncService.deviceName) {
      return _l10n.driveUpdatedFrom(ago, _l10n.driveThisDevice);
    }
    return device == null ? _l10n.driveUpdatedAt(ago) : _l10n.driveUpdatedFrom(ago, device);
  }

  Future<void> _signOut() async {
    final confirmed = await showDriveConfirmDialog(
      context,
      title: _l10n.driveSignOutTitle,
      body: _l10n.driveSignOutBody,
      confirmLabel: _l10n.signOut,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.signOut();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _email = null;
          _error = null;
        });
      }
      await _status.refresh(checkDrive: false);
    }
  }

  // ------------------------------------------------------------- operations

  /// Shows the progress dialog over [operation] and closes it exactly once.
  Future<T> _withProgress<T>(String title, Future<T> Function() operation) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DriveSyncProgressDialog(
        title: title,
        progress: _service.progressStream,
        onCancel: _service.cancelUpload,
      ),
    ));
    try {
      return await operation();
    } finally {
      navigator.pop();
    }
  }

  /// After anything merged data in: drop an empty starter profile, pick a
  /// profile on a phone that had none, and reload what the app shows.
  Future<void> _afterMerge() async {
    final profileRepo = await ref.read(profileRepositoryProvider.future);
    await _service.cleanupEmptyProfile(profileRepo);
    if (MobileUtils.isMobile() && profileRepo.getCurrentProfileId() == null) {
      final all = profileRepo.getAllProfiles();
      if (all.isNotEmpty) await profileRepo.setCurrentProfileId(all.first.id);
    }
    if (!mounted) return;
    ref.invalidate(repositoryProvider);
    ref.invalidate(allProjectsStreamProvider);
    ref.invalidate(releasesProvider);
    ref.invalidate(scanRootsProvider);
    ref.invalidate(currentProfileProvider);
  }

  void _reportResult(SyncResult result, {required bool uploaded}) {
    final changed = result.projectsAdded + result.projectsUpdated + result.projectsDeleted +
        result.releasesAdded + result.releasesUpdated + result.releasesDeleted;
    var message = changed == 0
        ? _l10n.driveSyncedNothingNew
        : _l10n.driveSyncedSummary(
            result.projectsAdded + result.releasesAdded,
            result.projectsUpdated + result.releasesUpdated,
            result.projectsDeleted + result.releasesDeleted,
          );
    final warnings = uploaded ? _service.lastUploadWarnings : const <String>[];
    if (warnings.isNotEmpty) {
      message = '$message\n${_l10n.driveFilesFailedToUpload(warnings.length)}\n${warnings.join('\n')}';
    }
    ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: warnings.isEmpty ? Colors.green : Colors.orange,
      // showAppSnackBar sizes the timeout to the message; a list of failed
      // files needs longer to read.
      duration: warnings.isEmpty ? const Duration(seconds: 4) : const Duration(seconds: 8),
    ));
  }

  Future<void> _syncNow() async {
    setState(() => _error = null);
    try {
      final result = await _withProgress(
        _l10n.driveSyncingTitle,
        () => _status.syncNow(),
      );
      await _afterMerge();
      await _loadAccount();
      if (mounted) _reportResult(result, uploaded: true);
    } on UploadCancelledException {
      if (mounted) _showCancelled();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  /// Merge only: brings this device up to date, uploads nothing.
  Future<void> _restoreFromDrive() async {
    setState(() => _error = null);
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final projectRepo = await ref.read(repositoryProvider.future);
      final backup = await _service.fetchBackup();
      final preview = await _service.previewMerge(backup.data, profileRepo);
      if (!mounted) return;
      final previewSongs = await showMergeConfirmDialog(
        context,
        title: _l10n.driveMergeTitle,
        previewLines: mergePreviewLines(_l10n, preview),
        confirmLabel: _l10n.driveMergeConfirm,
      );
      if (previewSongs == null || !mounted) return;
      final result = await _withProgress(
        _l10n.downloadingBackupTitle,
        () => _status.track((service) async {
          final result = await service.mergeData(
            remoteData: backup.data,
            projectRepo: projectRepo,
            profileRepo: profileRepo,
            downloadPreviewSongs: previewSongs,
          );
          await service.markMerged(backup);
          return result;
        }),
      );
      await _afterMerge();
      if (mounted) _reportResult(result, uploaded: false);
    } on UploadCancelledException {
      if (mounted) _showCancelled();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  /// Merge an earlier backup back in, then sync so Drive has it too.
  Future<void> _recoverEarlier() async {
    setState(() => _error = null);
    try {
      final snapshots = await _service.listSnapshots();
      if (!mounted) return;
      final locale = Localizations.localeOf(context).toString();
      final picked = await showSnapshotPicker(
        context,
        snapshots: snapshots,
        snapshotsKept: GoogleDriveSyncService.snapshotsKept,
        describe: (s) {
          final when = DateFormat.yMMMd(locale).add_jm().format(s.takenAt.toLocal());
          return s.device == null ? when : _l10n.driveSnapshotItem(when, s.device!);
        },
      );
      if (picked == null || !mounted) return;
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final projectRepo = await ref.read(repositoryProvider.future);
      final data = await _service.downloadSnapshot(picked);
      final preview = await _service.previewMerge(data, profileRepo);
      if (!mounted) return;
      final previewSongs = await showMergeConfirmDialog(
        context,
        title: _l10n.driveRecoverConfirmTitle,
        previewLines: mergePreviewLines(_l10n, preview),
        confirmLabel: _l10n.driveRecoverConfirm,
      );
      if (previewSongs == null || !mounted) return;
      final settings = ref.read(uploadAutoPreviewSongsProvider);
      final result = await _withProgress(
        _l10n.driveSyncingTitle,
        () => _status.track((service) async {
          final result = await service.mergeData(
            remoteData: data,
            projectRepo: projectRepo,
            profileRepo: profileRepo,
            downloadPreviewSongs: previewSongs,
          );
          await service.syncDatabase(
            projectRepo: projectRepo,
            profileRepo: profileRepo,
            uploadAutoDetectedSongs: settings,
            downloadPreviewSongs: previewSongs,
          );
          return result;
        }),
      );
      await _afterMerge();
      if (mounted) _reportResult(result, uploaded: true);
    } on UploadCancelledException {
      if (mounted) _showCancelled();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _overwriteDrive() async {
    final confirmed = await showDriveConfirmDialog(
      context,
      title: _l10n.driveOverwriteTitle,
      body: _l10n.driveOverwriteBody,
      confirmLabel: _l10n.driveOverwriteConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _error = null);
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final projectRepo = await ref.read(repositoryProvider.future);
      final autoDetected = ref.read(uploadAutoPreviewSongsProvider);
      await _withProgress(
        _l10n.uploadingBackupTitle,
        () => _status.track((service) => service.uploadDatabase(
              projectRepo: projectRepo,
              profileRepo: profileRepo,
              uploadAutoDetectedSongs: autoDetected,
            )),
      );
      await _loadAccount();
      if (!mounted) return;
      final warnings = _service.lastUploadWarnings;
      ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(
        content: Text(warnings.isEmpty
            ? _l10n.backupUploadedSuccessfullyMessage
            : '${_l10n.backupUploadedSuccessfullyMessage}\n'
                '${_l10n.driveFilesFailedToUpload(warnings.length)}\n${warnings.join('\n')}'),
        backgroundColor: warnings.isEmpty ? Colors.green : Colors.orange,
      ));
    } on UploadCancelledException {
      if (mounted) _showCancelled();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _deleteDriveData() async {
    final confirmed = await showDriveConfirmDialog(
      context,
      title: _l10n.driveDeleteTitle,
      body: _l10n.driveDeleteBody,
      confirmLabel: _l10n.driveDeleteConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _error = null);
    try {
      await _status.track((service) => service.deleteAllDriveData());
      // Otherwise the next tick would upload everything straight back.
      await ref.read(autoBackupIntervalProvider.notifier).setInterval(AutoBackupInterval.off);
      await _loadAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(
        content: Text(_l10n.driveDeleted),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(driveSyncStatusProvider);
    final interval = ref.watch(autoBackupIntervalProvider);
    final now = DateTime.now();
    final l10n = _l10n;

    // Something that just failed here wins; otherwise a failure recorded by
    // an automatic or tray sync, which would otherwise go unseen.
    var error = _error;
    String? errorTitle;
    if (error == null && status.hasFailure) {
      final kind = status.lastFailureKind ?? SyncErrorKind.other;
      errorTitle = l10n.driveLastSyncFailed(syncAgoLabel(
        l10n,
        status.lastFailureAt!,
        now,
        locale: Localizations.localeOf(context).toString(),
      ));
      error = _ShownError(
        syncErrorSentence(l10n, kind),
        kind == SyncErrorKind.other ? status.lastFailureMessage : null,
      );
    }

    return DriveSyncPanel(
      data: DriveSyncPanelData(
        now: now,
        checkingSession: _checkingSession,
        signedIn: _service.isSignedIn && !_checkingSession,
        waitingForBrowser: _waitingForBrowser,
        busy: _busy || _signingIn || status.syncing || status.backgroundSyncing,
        email: _email,
        lastSyncedAt: status.lastSyncedAt,
        remoteUpdatedAt: status.remoteUpdatedAt,
        remoteDevice: status.remoteDevice,
        remoteIsThisDevice: status.remoteDevice == GoogleDriveSyncService.deviceName,
        newerOnDrive: status.newerOnDrive,
        errorTitle: errorTitle,
        errorText: error?.text,
        errorDetails: error?.details,
        interval: interval,
        lastAutoSyncAt: _lastUpload,
        uploadAutoDetected: ref.watch(uploadAutoPreviewSongsProvider),
        syncOnStartup: ref.watch(syncOnStartupProvider),
        isMobile: MobileUtils.isMobile(),
      ),
      snapshotsKept: GoogleDriveSyncService.snapshotsKept,
      onSignIn: _signIn,
      onCancelSignIn: _service.cancelDesktopSignIn,
      onSignOut: _signOut,
      onSyncNow: _syncNow,
      onRestoreFromDrive: _restoreFromDrive,
      onRecoverEarlier: _recoverEarlier,
      onOverwriteDrive: _overwriteDrive,
      onDeleteDriveData: _deleteDriveData,
      onIntervalChanged: (v) => ref.read(autoBackupIntervalProvider.notifier).setInterval(v),
      onUploadAutoDetectedChanged: (_) => ref.read(uploadAutoPreviewSongsProvider.notifier).toggle(),
      onSyncOnStartupChanged: (v) => ref.read(syncOnStartupProvider.notifier).set(v),
    );
  }
}

/// The dashboard's cloud button, showing what [driveSyncStatusProvider]
/// knows: syncing, failed, newer on Drive, or up to date.
class DriveSyncStatusButton extends ConsumerWidget {
  const DriveSyncStatusButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicator = ref.watch(driveSyncStatusProvider).indicator;
    return IconButton(
      tooltip: driveSyncStatusTooltip(AppLocalizations.of(context)!, indicator),
      onPressed: onPressed,
      icon: const DriveSyncStatusRailIcon(),
    );
  }
}

/// The same status as [DriveSyncStatusButton], as a bare icon for places
/// that bring their own button (the side rail).
class DriveSyncStatusRailIcon extends ConsumerStatefulWidget {
  const DriveSyncStatusRailIcon({super.key});

  @override
  ConsumerState<DriveSyncStatusRailIcon> createState() => _DriveSyncStatusRailIconState();
}

class _DriveSyncStatusRailIconState extends ConsumerState<DriveSyncStatusRailIcon> {
  bool _justSynced = false;
  Timer? _flash;

  @override
  void dispose() {
    _flash?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A sync the user started that ends well flashes a check, as a rescan
    // does.
    ref.listen<DriveSyncStatus>(driveSyncStatusProvider, (previous, next) {
      if (previous?.syncing == true && !next.syncing && !next.hasFailure) {
        _flash?.cancel();
        setState(() => _justSynced = true);
        _flash = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _justSynced = false);
        });
      }
    });
    return DriveSyncStatusGlyph(
      indicator: ref.watch(driveSyncStatusProvider).indicator,
      justSynced: _justSynced,
    );
  }
}

String driveSyncStatusTooltip(AppLocalizations l10n, DriveSyncIndicator indicator) =>
    switch (indicator) {
      DriveSyncIndicator.none => l10n.syncWithGoogleDrive,
      DriveSyncIndicator.syncing => l10n.driveStatusSyncing,
      DriveSyncIndicator.failed => l10n.driveStatusFailed,
      DriveSyncIndicator.newerOnDrive => l10n.driveStatusNewer,
      DriveSyncIndicator.upToDate => l10n.driveStatusUpToDate,
    };

/// A cloud icon carrying the sync status, drawn like the rescan button's:
/// the icon gives way to a spinner of its size while syncing and to a green
/// check for a moment after ([justSynced]); a red dot marks a failure and
/// an accent dot news on Drive. (A small spinner tucked into the cloud's
/// corner read as out of focus.)
class DriveSyncStatusGlyph extends StatelessWidget {
  const DriveSyncStatusGlyph({
    super.key,
    required this.indicator,
    this.justSynced = false,
  });

  final DriveSyncIndicator indicator;
  final bool justSynced;

  @override
  Widget build(BuildContext context) {
    if (indicator == DriveSyncIndicator.syncing) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (justSynced && indicator == DriveSyncIndicator.upToDate) {
      return const Icon(Icons.check, color: Colors.green);
    }
    final cs = Theme.of(context).colorScheme;
    final Color? dot = switch (indicator) {
      DriveSyncIndicator.failed => cs.error,
      DriveSyncIndicator.newerOnDrive => cs.primary,
      _ => null,
    };
    final icon = switch (indicator) {
      DriveSyncIndicator.failed => Icons.cloud_off_outlined,
      DriveSyncIndicator.upToDate => Icons.cloud_done_outlined,
      _ => Icons.cloud_outlined,
    };
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (dot != null)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              key: ValueKey('drive-status-dot-${indicator.name}'),
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}
