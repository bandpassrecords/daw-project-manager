import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/project_context_menu.dart';
import 'package:daw_project_manager/ui/widgets/anchored_menu.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_factories.dart';

void main() {
  late BuildContext host;
  late Future<String?> chosen;

  Future<void> openMenu(
    WidgetTester tester,
    MusicProject project, {
    bool sessionMode = false,
    bool filesPresent = true,
    bool extractionSupported = true,
    bool driveRestoreOffered = true,
    bool previewShareable = false,
    bool includeCardOptions = false,
    bool captureOffered = false,
    bool inspectOffered = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) {
          host = context;
          return const SizedBox.expand();
        }),
      ),
    ));
    final l10n = AppLocalizations.of(host)!;
    chosen = showAnchoredMenu<String>(
      context: host,
      position: const Offset(20, 20),
      builder: (choose) => projectMenuChildren(
        l10n: l10n,
        project: project,
        choose: choose,
        sessionMode: sessionMode,
        isSubscribed: false,
        includeCardOptions: includeCardOptions,
        filesPresent: filesPresent,
        extractionSupported: extractionSupported,
        archivedFilesPresent: project.isArchived && filesPresent,
        driveRestoreOffered: driveRestoreOffered,
        previewShareable: previewShareable,
        captureOffered: captureOffered,
        inspectOffered: inspectOffered,
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder entry(String value) => find.byKey(ValueKey('project-menu-$value'));

  Future<void> openSubmenu(WidgetTester tester, String key) async {
    await tester.tap(entry(key));
    await tester.pumpAndSettle();
  }

  testWidgets('the everyday actions are on top, the rest in two submenus',
      (tester) async {
    await openMenu(tester, TestFactories.makeProject(), previewShareable: true);

    for (final value in [
      'launch', 'view', 'openFolder', 'share', 'files', 'update', 'hide',
      'moveToProfile', 'delete',
    ]) {
      expect(entry(value), findsOneWidget, reason: value);
    }
    // Inside a submenu until it opens.
    expect(entry('move'), findsNothing);
    expect(entry('refresh'), findsNothing);

    await openSubmenu(tester, 'files');
    expect(entry('move'), findsOneWidget);
    expect(entry('archive'), findsOneWidget);
    await tester.tap(entry('archive'));
    await tester.pumpAndSettle();
    expect(await chosen, 'archive');
  });

  testWidgets('Inspect is offered only where the caller says, and chosen',
      (tester) async {
    await openMenu(tester, TestFactories.makeProject());
    expect(entry('inspect'), findsNothing,
        reason: 'a phone, a stack, a missing file or a hidden tab');
    await tester.tap(entry('view'));
    await tester.pumpAndSettle();

    await openMenu(tester, TestFactories.makeProject(), inspectOffered: true);
    expect(entry('inspect'), findsOneWidget);
    await tester.tap(entry('inspect'));
    await tester.pumpAndSettle();
    expect(await chosen, 'inspect');
  });

  testWidgets('Update details holds the re-reading actions', (tester) async {
    await openMenu(tester, TestFactories.makeProject());
    await openSubmenu(tester, 'update');
    expect(entry('refresh'), findsOneWidget);
    expect(entry('extractMetadata'), findsOneWidget);
    expect(entry('restoreFromDrive'), findsOneWidget);
    await tester.tap(entry('refresh'));
    await tester.pumpAndSettle();
    expect(await chosen, 'refresh');
  });

  testWidgets('no Drive restore where Drive is not offered (Flatpak)',
      (tester) async {
    await openMenu(tester, TestFactories.makeProject(),
        driveRestoreOffered: false);
    await openSubmenu(tester, 'update');
    expect(entry('refresh'), findsOneWidget);
    expect(entry('restoreFromDrive'), findsNothing);
  });

  testWidgets('a missing file leaves nothing to re-read, without Drive',
      (tester) async {
    await openMenu(tester, TestFactories.makeProject(),
        filesPresent: false, driveRestoreOffered: false);
    expect(entry('update'), findsNothing, reason: 'an empty submenu is hidden');
  });

  testWidgets('a DAW whose files cannot be read greys out extraction',
      (tester) async {
    await openMenu(tester, TestFactories.makeProject(),
        extractionSupported: false);
    await openSubmenu(tester, 'update');
    expect(
        tester.widget<MenuItemButton>(entry('extractMetadata')).onPressed,
        isNull);
  });

  testWidgets('a stack has no files to move, archive or delete',
      (tester) async {
    await openMenu(tester, TestFactories.makeProject(isVirtual: true));
    expect(entry('files'), findsNothing);
    expect(entry('delete'), findsNothing);
    expect(entry('moveToProfile'), findsOneWidget);
  });

  testWidgets('an archived project restores, and is never deleted or moved',
      (tester) async {
    await openMenu(tester,
        TestFactories.makeProject(archivePath: '/archive/song.zip'));
    expect(entry('delete'), findsNothing);
    expect(entry('moveToProfile'), findsNothing);
    await openSubmenu(tester, 'files');
    expect(entry('restore'), findsOneWidget);
    expect(entry('archive'), findsNothing);
    expect(entry('discardArchive'), findsOneWidget,
        reason: 'the files are still here, so the zip can go');
  });

  testWidgets("the DAW plugin's latest capture plays from the menu, where offered",
      (tester) async {
    await openMenu(tester, TestFactories.makeProject(), captureOffered: true);
    expect(entry('playCapture'), findsOneWidget);

    await tester.tap(entry('playCapture'));
    await tester.pumpAndSettle();
    expect(await chosen, 'playCapture');
  });

  testWidgets('no capture entry where none is offered', (tester) async {
    await openMenu(tester, TestFactories.makeProject());
    expect(entry('playCapture'), findsNothing);
  });

  testWidgets('session mode swaps launching for the session', (tester) async {
    await openMenu(tester, TestFactories.makeProject(), sessionMode: true);
    expect(entry('launch'), findsNothing);
    expect(entry('startSession'), findsOneWidget);
  });

  testWidgets('a hidden project offers to unhide it; cards get initials',
      (tester) async {
    await openMenu(tester, TestFactories.makeProject(hidden: true),
        includeCardOptions: true);
    expect(entry('unhide'), findsOneWidget);
    expect(entry('hide'), findsNothing);
    expect(entry('cardInitials'), findsOneWidget);
  });
}
