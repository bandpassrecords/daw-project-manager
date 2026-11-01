import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/google_drive_sync_service.dart';
import 'package:daw_project_manager/services/tray_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrayService.formatLastBackupLabel', () {
    test('formats a fixed timestamp as month, day and 24h time', () {
      final label = TrayService.formatLastBackupLabel(DateTime(2026, 3, 5, 14, 7));
      expect(label, 'Mar 5, 14:07');
    });

    test('pads single-digit minutes', () {
      final label = TrayService.formatLastBackupLabel(DateTime(2026, 1, 1, 9, 2));
      expect(label, 'Jan 1, 09:02');
    });
  });

  group('menu bar icon on macOS', () {
    test('a left click opens the menu on macOS only', () {
      expect(TrayService.leftClickOpensMenu(isMacOS: true), isTrue);
      expect(TrayService.leftClickOpensMenu(isMacOS: false), isFalse);
    });

    test('the icon can be hidden on macOS only', () {
      expect(TrayService.iconCanBeHidden(isMacOS: true), isTrue);
      expect(TrayService.iconCanBeHidden(isMacOS: false), isFalse);
    });

    test('the setting hides the icon on macOS, never elsewhere', () {
      expect(TrayService.iconVisible(isMacOS: true, setting: false), isFalse);
      expect(TrayService.iconVisible(isMacOS: true, setting: true), isTrue);
      expect(TrayService.iconVisible(isMacOS: false, setting: false), isTrue);
    });
  });

  group('TrayService.init', () {
    const channel = MethodChannel('tray_manager');

    tearDown(() {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('completes even when the native plugin has no setToolTip handler (Linux)', () async {
      // Regression: tray_manager's Linux plugin only implements
      // destroy/setIcon/setTitle/setContextMenu — a call to setToolTip
      // returns "not implemented" and throws MissingPluginException on the
      // Dart side. Left unguarded, that exception used to abort init()
      // before it ever registered the postFrameCallback that builds the
      // context menu, so the tray icon appeared (setIcon had already
      // succeeded) but no menu was ever attached — every click did nothing.
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'setToolTip') {
          throw MissingPluginException('No implementation found for method setToolTip');
        }
        return true;
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = TrayService(container, GoogleDriveSyncService());
      addTearDown(service.dispose);

      await expectLater(service.init(), completes);
    });
  });
}
