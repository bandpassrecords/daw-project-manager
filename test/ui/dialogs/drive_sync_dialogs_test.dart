import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/backup_progress.dart';
import 'package:daw_project_manager/ui/dialogs/drive_sync_dialogs.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

void main() {
  Future<void> pumpOpener(
    WidgetTester tester,
    Future<void> Function(BuildContext) open, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  group('merge confirmation', () {
    testWidgets('lists what changes and is no longer a red "replace" warning',
        (tester) async {
      // It used to say "This will replace your local data" over a red
      // Replace Local Data button — for a merge that never replaces anything.
      bool? result = false;
      await pumpOpener(tester, (context) async {
        result = await showMergeConfirmDialog(
          context,
          title: "Get Drive's changes?",
          previewLines: const ['3 new projects'],
          confirmLabel: 'Get changes',
        );
      });
      expect(find.text('3 new projects'), findsOneWidget);
      expect(find.text('Replace Local Data'), findsNothing);
      expect(find.textContaining('replace your local data'), findsNothing);

      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Get changes'));
      await tester.pumpAndSettle();
      expect(result, isFalse, reason: 'preview songs were unticked');
    });

    testWidgets('cancel returns null', (tester) async {
      bool? result = true;
      await pumpOpener(tester, (context) async {
        result = await showMergeConfirmDialog(
          context,
          title: 't',
          previewLines: const [],
          confirmLabel: 'go',
        );
      });
      expect(find.text('Nothing on Drive is new to this device.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('first sync after sign-in', () {
    testWidgets('with a backup: offers to sync and to keep in sync',
        (tester) async {
      FirstSyncChoice? choice;
      await pumpOpener(tester, (context) async {
        choice = await showFirstSyncDialog(
          context,
          hasBackup: true,
          backupLine: 'Drive updated 2 hours ago from Laptop',
          previewLines: const ['12 new projects'],
          offerKeepInSync: true,
        );
      });
      expect(find.text('Found a backup on Google Drive'), findsOneWidget);
      expect(find.text('Drive updated 2 hours ago from Laptop'), findsOneWidget);
      expect(find.textContaining('12 new projects'), findsOneWidget);
      await tester.tap(find.text('Sync now'));
      await tester.pumpAndSettle();
      expect(choice!.syncNow, isTrue);
      expect(choice!.keepInSync, isFalse,
          reason: 'automatic sync is offered, not assumed');
    });

    testWidgets('automatic sync starts unchecked and is a choice to make',
        (tester) async {
      FirstSyncChoice? choice;
      await pumpOpener(tester, (context) async {
        choice = await showFirstSyncDialog(
          context,
          hasBackup: false,
          offerKeepInSync: true,
        );
      });
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox)).value,
        isFalse,
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sync now'));
      await tester.pumpAndSettle();
      expect(choice!.syncNow, isTrue);
      expect(choice!.keepInSync, isTrue);
    });

    testWidgets('"Later" with the box left alone changes nothing',
        (tester) async {
      FirstSyncChoice? choice;
      await pumpOpener(tester, (context) async {
        choice = await showFirstSyncDialog(
          context,
          hasBackup: false,
          offerKeepInSync: true,
        );
      });
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(choice!.syncNow, isFalse);
      expect(choice!.keepInSync, isFalse);
    });

    testWidgets('says so when this device and Drive already match',
        (tester) async {
      FirstSyncChoice? choice;
      await pumpOpener(tester, (context) async {
        choice = await showFirstSyncDialog(
          context,
          hasBackup: true,
          backupLine: 'Drive updated 2 minutes ago from this device',
          offerKeepInSync: false,
        );
      });
      expect(find.byKey(const ValueKey('drive-in-sync')), findsOneWidget);
      expect(find.text('Sync now'), findsNothing);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(choice!.syncNow, isFalse);
    });

    testWidgets('shows both directions separately', (tester) async {
      await pumpOpener(tester, (context) async {
        await showFirstSyncDialog(
          context,
          hasBackup: true,
          previewLines: const ['1 new project'],
          uploadLines: const ['2 projects added or changed here'],
          offerKeepInSync: false,
        );
      });
      expect(find.text('From Google Drive'), findsOneWidget);
      expect(find.text('From this device'), findsOneWidget);
      expect(find.textContaining('2 projects added or changed here'), findsOneWidget);
      expect(find.text('Sync now'), findsOneWidget);
    });

    testWidgets('without one: says how much would go up', (tester) async {
      FirstSyncChoice? choice;
      await pumpOpener(tester, (context) async {
        choice = await showFirstSyncDialog(
          context,
          hasBackup: false,
          estimateLine: 'About 23 files (140.0 MB) go up with it.',
          offerKeepInSync: false,
        );
      });
      expect(find.text('Nothing on Google Drive yet'), findsOneWidget);
      expect(find.text('About 23 files (140.0 MB) go up with it.'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing,
          reason: 'automatic sync is already on');
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(choice!.syncNow, isFalse);
      expect(choice!.keepInSync, isFalse);
    });
  });

  testWidgets('a destructive confirmation has readable white text',
      (tester) async {
    await pumpOpener(tester, (context) async {
      await showDriveConfirmDialog(
        context,
        title: 'Delete?',
        body: 'Really.',
        confirmLabel: 'Delete from Drive',
        destructive: true,
      );
    });
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete from Drive'),
    );
    final fg = button.style!.foregroundColor!.resolve({});
    expect(fg, Colors.white);
  });

  testWidgets('the progress dialog never closes itself, even on "completed"',
      (tester) async {
    // The merge reports "completed" halfway through a sync; the old dialog
    // closed on it and the caller then popped whatever was underneath.
    final progress = StreamController<BackupProgress>.broadcast();
    var cancelled = 0;
    await pumpOpener(tester, (context) async {
      await showDialog<void>(
        context: context,
        builder: (_) => DriveSyncProgressDialog(
          title: 'Syncing with Google Drive',
          progress: progress.stream,
          onCancel: () => cancelled++,
        ),
      );
    }, settle: false);
    progress.add(BackupProgress(
      stage: BackupProgressStage.completed,
      currentItem: '',
      currentIndex: 1,
      totalItems: 1,
      progress: 1,
    ));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Syncing with Google Drive'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(cancelled, 1);
    await progress.close();
  });
}
