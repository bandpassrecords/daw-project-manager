import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/auto_backup_interval.dart';
import 'package:daw_project_manager/models/drive_sync_status.dart';
import 'package:daw_project_manager/providers/providers.dart'
    show SyncOnStartupNotifier;
import 'package:daw_project_manager/services/drive_sync_errors.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';
import 'package:daw_project_manager/utils/drive_sync_format.dart';

void main() {
  late AppLocalizations en;

  setUpAll(() async {
    // The app gets this from its localizations delegates.
    await initializeDateFormatting('en');
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('syncAgoLabel', () {
    final now = DateTime(2026, 10, 15, 12);
    String ago(Duration d) => syncAgoLabel(en, now.subtract(d), now, locale: 'en');

    test('reads like a person would say it', () {
      expect(ago(const Duration(seconds: 20)), 'just now');
      expect(ago(const Duration(minutes: 1)), '1 minute ago');
      expect(ago(const Duration(minutes: 42)), '42 minutes ago');
      expect(ago(const Duration(hours: 3)), '3 hours ago');
      expect(ago(const Duration(hours: 30)), 'yesterday');
      expect(ago(const Duration(days: 4)), '4 days ago');
      expect(ago(const Duration(days: 40)), 'Sep 5, 2026');
    });

    test('takes a UTC time (Drive gives UTC)', () {
      final when = now.subtract(const Duration(minutes: 5)).toUtc();
      expect(syncAgoLabel(en, when, now, locale: 'en'), '5 minutes ago');
    });
  });

  test('formatSyncBytes goes up to gigabytes', () {
    expect(formatSyncBytes(900), '900 B');
    expect(formatSyncBytes(12 * 1024), '12 KB');
    expect(formatSyncBytes((4.2 * 1024 * 1024).round()), '4.2 MB');
    expect(formatSyncBytes((1.3 * 1024 * 1024 * 1024).round()), '1.3 GB');
  });

  test('mergePreviewLines lists only what changes', () {
    expect(mergePreviewLines(en, const MergePreview()), isEmpty);
    expect(
      mergePreviewLines(
        en,
        const MergePreview(projectsAdded: 3, projectsUpdated: 1, releasesDeleted: 2),
      ),
      [
        '3 new projects',
        '1 project updated',
        '2 releases removed (deleted on another device)',
      ],
    );
  });

  test('uploadPreviewLines lists what this device would send', () {
    expect(uploadPreviewLines(en, const MergePreview()), isEmpty);
    expect(
      uploadPreviewLines(
        en,
        const MergePreview(projectsToUpload: 1, releasesToUpload: 3),
      ),
      ['1 project added or changed here', '3 releases added here'],
    );
  });

  test('the sign-in port is named without a thousands separator', () {
    expect(
      signInFailureSentence(en, DesktopSignInFailure.portInUse),
      contains('port ${GoogleDriveSyncService.loopbackPort}'),
    );
  });

  group('classifySyncError', () {
    test('no connection', () {
      expect(classifySyncError(const SocketException('down')), SyncErrorKind.offline);
      expect(classifySyncError(http.ClientException('x')), SyncErrorKind.offline);
      expect(classifySyncError(TimeoutException('slow')), SyncErrorKind.offline);
    });

    test('Drive full and expired sign-in, from the API error', () {
      expect(
        classifySyncError(drive.DetailedApiRequestError(
          403,
          'The user\'s Drive storage quota has been exceeded.',
        )),
        SyncErrorKind.driveFull,
      );
      expect(
        classifySyncError(drive.DetailedApiRequestError(401, 'Invalid Credentials')),
        SyncErrorKind.signInExpired,
      );
      expect(
        classifySyncError(Exception('Not signed in to Google Drive')),
        SyncErrorKind.signInExpired,
      );
    });

    test('no backup, and everything else', () {
      expect(classifySyncError(const NoBackupOnDriveException()), SyncErrorKind.noBackup);
      expect(
        classifySyncError(drive.DetailedApiRequestError(500, 'oops')),
        SyncErrorKind.other,
      );
      expect(classifySyncError(StateError('?')), SyncErrorKind.other);
    });

    test('a stored kind reads back, unknown ones as other', () {
      expect(syncErrorKindFromName('driveFull'), SyncErrorKind.driveFull);
      expect(syncErrorKindFromName('gremlins'), SyncErrorKind.other);
      expect(syncErrorKindFromName(null), SyncErrorKind.other);
    });

    test('every kind has its own sentence', () {
      final sentences = {
        for (final k in SyncErrorKind.values) syncErrorSentence(en, k),
      };
      expect(sentences.length, SyncErrorKind.values.length);
    });
  });

  group('DriveSyncStatus.indicator', () {
    test('syncing, then a failure, then news, then up to date', () {
      final failed = DriveSyncStatus(signedIn: true, lastFailureAt: DateTime(2026));
      expect(failed.copyWith(syncing: true).indicator, DriveSyncIndicator.syncing);
      expect(failed.copyWith(newerOnDrive: true).indicator, DriveSyncIndicator.failed);
      expect(
        const DriveSyncStatus(signedIn: true, newerOnDrive: true).indicator,
        DriveSyncIndicator.newerOnDrive,
      );
      expect(const DriveSyncStatus(signedIn: true).indicator, DriveSyncIndicator.upToDate);
      expect(const DriveSyncStatus().indicator, DriveSyncIndicator.none);
    });

    test('a failure shows even when signed out (an expired sign-in)', () {
      expect(
        DriveSyncStatus(lastFailureAt: DateTime(2026)).indicator,
        DriveSyncIndicator.failed,
      );
    });

    test('clearFailure drops it', () {
      final s = DriveSyncStatus(
        lastFailureAt: DateTime(2026),
        lastFailureKind: SyncErrorKind.offline,
      ).copyWith(clearFailure: true);
      expect(s.hasFailure, isFalse);
      expect(s.lastFailureKind, isNull);
    });
  });

  group('automatic sync timing', () {
    final now = DateTime(2026, 10, 15, 12);
    final justNow = now.subtract(const Duration(minutes: 1));

    test('at startup, the startup switch decides on its own', () {
      // Startup sync used to happen only with an interval set; now it is
      // its own switch, so a device can sync at startup with no timer.
      expect(
        AutoBackupInterval.off.shouldSyncNow(
          lastSync: justNow,
          now: now,
          syncOnStartup: true,
          atLaunch: true,
        ),
        isTrue,
      );
      expect(
        AutoBackupInterval.daily.shouldSyncNow(
          lastSync: justNow,
          now: now,
          syncOnStartup: false,
          atLaunch: true,
        ),
        isFalse,
      );
    });

    test('with startup sync off, a due interval still syncs at startup', () {
      expect(
        AutoBackupInterval.hourly.shouldSyncNow(
          lastSync: now.subtract(const Duration(hours: 2)),
          now: now,
          syncOnStartup: false,
          atLaunch: true,
        ),
        isTrue,
      );
    });

    test('after startup only the interval counts', () {
      expect(
        AutoBackupInterval.off.shouldSyncNow(
          lastSync: null,
          now: now,
          syncOnStartup: true,
        ),
        isFalse,
      );
      expect(
        AutoBackupInterval.hourly.shouldSyncNow(
          lastSync: now.subtract(const Duration(minutes: 59)),
          now: now,
          syncOnStartup: true,
        ),
        isFalse,
      );
      expect(
        AutoBackupInterval.hourly.shouldSyncNow(
          lastSync: now.subtract(const Duration(minutes: 60)),
          now: now,
          syncOnStartup: true,
        ),
        isTrue,
      );
      expect(
        AutoBackupInterval.hourly.isDue(lastSync: null, now: now),
        isTrue,
      );
    });

    test('a device syncs on its own if either is on', () {
      expect(
        AutoBackupInterval.off.syncsAutomatically(syncOnStartup: false),
        isFalse,
      );
      expect(
        AutoBackupInterval.off.syncsAutomatically(syncOnStartup: true),
        isTrue,
      );
      expect(
        AutoBackupInterval.daily.syncsAutomatically(syncOnStartup: false),
        isTrue,
      );
    });

    test('a sync only because the app started merges only something new', () {
      // Every launch ran the whole sync, whatever Drive held.
      expect(
        AutoBackupInterval.off.syncsOnlyForLaunch(
          lastSync: now,
          now: now,
          syncOnStartup: true,
          atLaunch: true,
        ),
        isTrue,
      );
      expect(
        AutoBackupInterval.hourly.syncsOnlyForLaunch(
          lastSync: now.subtract(const Duration(hours: 2)),
          now: now,
          syncOnStartup: true,
          atLaunch: true,
        ),
        isFalse,
        reason: 'a due interval merges as Sync now does',
      );
      expect(
        AutoBackupInterval.off.syncsOnlyForLaunch(
          lastSync: now,
          now: now,
          syncOnStartup: true,
        ),
        isFalse,
        reason: 'only at launch',
      );
    });

    test('startup sync is on unless turned off', () {
      expect(SyncOnStartupNotifier.fromStored(null), isTrue);
      expect(SyncOnStartupNotifier.fromStored('true'), isTrue);
      expect(SyncOnStartupNotifier.fromStored('false'), isFalse);
    });
  });
}
