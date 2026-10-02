import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/appimage_update_service.dart';
import 'package:daw_project_manager/services/update_check_service.dart';

void main() {
  group('UpdateCheckService.isSupported', () {
    // The GitHub-releases update check is redundant under Flatpak (Flathub
    // already owns update delivery) and its dialog links out to a GitHub
    // release page, which isn't even the right flow for a Flatpak user — so
    // it's switched off on Linux, the same way Drive sync is (see
    // GoogleDriveSyncService.isSupported) — EXCEPT when running as the
    // AppImage build, which self-updates instead of linking out (see
    // AppImageUpdateService). The unit_tests CI job runs on ubuntu-latest,
    // not inside an AppImage, so AppImageUpdateService.isRunningAsAppImage
    // is false there and this still exercises the isFalse branch for real.
    test('is false on Linux unless running as an AppImage', () {
      final expected = Platform.isLinux && !AppImageUpdateService.isRunningAsAppImage
          ? isFalse
          : isTrue;
      expect(UpdateCheckService.isSupported, expected);
    });
  });

  group('UpdateCheckService.shouldCheckAtStartup', () {
    test('a release build with a real version checks', () {
      expect(UpdateCheckService.shouldCheckAtStartup('2.9.1', isDebug: false), isTrue);
    });

    test('a debug build never checks, whatever its version', () {
      expect(UpdateCheckService.shouldCheckAtStartup('2.9.1', isDebug: true), isFalse);
    });

    test('a local 0.0.0 build does not check, even in release mode', () {
      // Every published release is newer than the placeholder, so checking
      // would pop "update available" on every launch while developing.
      expect(UpdateCheckService.shouldCheckAtStartup('0.0.0', isDebug: false), isFalse);
      expect(UpdateCheckService.shouldCheckAtStartup('0.0.0+0', isDebug: false), isFalse);
    });
  });

  group('UpdateCheckService.isDevelopmentVersion', () {
    test('only the all-zero placeholder counts', () {
      expect(UpdateCheckService.isDevelopmentVersion('0.0.0'), isTrue);
      expect(UpdateCheckService.isDevelopmentVersion('0.0.0+42'), isTrue);
      expect(UpdateCheckService.isDevelopmentVersion('0.0.1'), isFalse);
      expect(UpdateCheckService.isDevelopmentVersion('0.1.0'), isFalse);
      expect(UpdateCheckService.isDevelopmentVersion('2.9.1+15'), isFalse);
    });
  });
}
