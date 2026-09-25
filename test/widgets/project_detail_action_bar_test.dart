import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/project_detail_layout.dart';
import 'package:daw_project_manager/ui/widgets/project_detail_action_bar.dart';

void main() {
  late AppLocalizations l10n;
  late List<String> calls;
  late List<ProjectDetailLayout> layouts;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    calls = [];
    layouts = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    ProjectDetailLayout layout = ProjectDetailLayout.classic,
    bool sourceFileExists = true,
    bool isVirtual = false,
    bool isArchived = false,
    bool sessionMode = false,
    bool isSubscribed = false,
  }) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProjectDetailActionBar(
          layout: layout,
          onLayoutChanged: layouts.add,
          sourceFileExists: sourceFileExists,
          isVirtual: isVirtual,
          isArchived: isArchived,
          sessionMode: sessionMode,
          isSubscribed: isSubscribed,
          onStartSession: () => calls.add('startSession'),
          onEndSession: () => calls.add('endSession'),
          onOpenInDaw: () => calls.add('openInDaw'),
          onOpenFolder: () => calls.add('openFolder'),
          onRename: () => calls.add('rename'),
          onMove: () => calls.add('move'),
          onArchive: () => calls.add('archive'),
          onRestore: () => calls.add('restore'),
          onStats: () => calls.add('stats'),
          onExport: () => calls.add('export'),
          onSaveAsTemplate: () => calls.add('template'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  MenuItemButton menuItem(WidgetTester tester, String label) =>
      tester.widget<MenuItemButton>(
          find.ancestor(of: find.text(label), matching: find.byType(MenuItemButton)));

  Future<void> openFileMenu(WidgetTester tester) async {
    await tester.tap(find.text(l10n.projectFileMenu));
    await tester.pumpAndSettle();
  }

  Future<void> openMoreMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip(l10n.moreActions));
    await tester.pumpAndSettle();
  }

  group('what stays visible', () {
    testWidgets('launch is the one filled button, open folder sits beside it',
        (tester) async {
      await pump(tester);

      expect(
        find.ancestor(
            of: find.text(l10n.openInDaw), matching: find.byType(FilledButton)),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text(l10n.openFolder), findsOneWidget);

      await tester.tap(find.text(l10n.openInDaw));
      await tester.tap(find.text(l10n.openFolder));
      expect(calls, ['openInDaw', 'openFolder']);
    });

    testWidgets('file and project actions are tucked into menus, not the bar',
        (tester) async {
      await pump(tester);

      for (final label in [
        l10n.renameFileButtonLabel,
        l10n.moveProjectButtonLabel,
        l10n.archiveProjectButtonLabel,
        l10n.statsSingleProjectActivity,
        l10n.exportProjectInfo,
        l10n.saveAsTemplate,
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });
  });

  group('session mode', () {
    testWidgets('offers Start session instead of launching', (tester) async {
      await pump(tester, sessionMode: true);

      expect(find.text(l10n.startSession), findsOneWidget);
      expect(find.text(l10n.openInDaw), findsNothing);

      await tester.tap(find.text(l10n.startSession));
      expect(calls, ['startSession']);
    });

    testWidgets('the running project can end its session and still launch',
        (tester) async {
      await pump(tester, sessionMode: true, isSubscribed: true);

      expect(find.text(l10n.endSession), findsOneWidget);
      expect(find.text(l10n.openInDaw), findsOneWidget);

      await tester.tap(find.text(l10n.endSession));
      expect(calls, ['endSession']);
    });
  });

  group('File menu', () {
    testWidgets('holds rename, move and archive', (tester) async {
      await pump(tester);
      await openFileMenu(tester);

      await tester.tap(find.text(l10n.moveProjectButtonLabel));
      await tester.pumpAndSettle();
      await openFileMenu(tester);
      await tester.tap(find.text(l10n.renameFileButtonLabel));
      await tester.pumpAndSettle();
      await openFileMenu(tester);
      await tester.tap(find.text(l10n.archiveProjectButtonLabel));
      await tester.pumpAndSettle();

      expect(calls, ['move', 'rename', 'archive']);
    });

    testWidgets('an archived project offers restore instead of archive',
        (tester) async {
      await pump(tester, isArchived: true);
      await openFileMenu(tester);

      expect(find.text(l10n.archiveProjectButtonLabel), findsNothing);
      await tester.tap(find.text(l10n.restoreProjectButtonLabel));
      await tester.pumpAndSettle();
      expect(calls, ['restore']);
    });

    testWidgets('a version stack can only be renamed', (tester) async {
      await pump(tester, isVirtual: true);
      await openFileMenu(tester);

      expect(find.text(l10n.renameFileButtonLabel), findsOneWidget);
      expect(find.text(l10n.moveProjectButtonLabel), findsNothing);
      expect(find.text(l10n.archiveProjectButtonLabel), findsNothing);
    });

    testWidgets('a missing file disables everything that needs it',
        (tester) async {
      await pump(tester, sourceFileExists: false);

      expect(
        tester
            .widget<FilledButton>(find.ancestor(
                of: find.text(l10n.openInDaw),
                matching: find.byType(FilledButton)))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ButtonStyleButton>(find.ancestor(
                of: find.text(l10n.openFolder),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)))
            .onPressed,
        isNull,
      );

      await openFileMenu(tester);
      expect(menuItem(tester, l10n.renameFileButtonLabel).onPressed, isNull);
      expect(menuItem(tester, l10n.moveProjectButtonLabel).onPressed, isNull);
      expect(menuItem(tester, l10n.archiveProjectButtonLabel).onPressed, isNull);
    });

    testWidgets('restore still works when the original file is gone',
        (tester) async {
      // Archiving with "delete originals" is exactly how the file goes away;
      // restore reads the zip, so it must not be gated on the source.
      await pump(tester, sourceFileExists: false, isArchived: true);
      await openFileMenu(tester);

      expect(menuItem(tester, l10n.restoreProjectButtonLabel).onPressed,
          isNotNull);
    });
  });

  group('More menu', () {
    testWidgets('holds stats, export and save as template', (tester) async {
      await pump(tester);

      await openMoreMenu(tester);
      await tester.tap(find.text(l10n.statsSingleProjectActivity));
      await tester.pumpAndSettle();
      await openMoreMenu(tester);
      await tester.tap(find.text(l10n.exportProjectInfo));
      await tester.pumpAndSettle();
      await openMoreMenu(tester);
      await tester.tap(find.text(l10n.saveAsTemplate));
      await tester.pumpAndSettle();

      expect(calls, ['stats', 'export', 'template']);
    });

    testWidgets('works even when the file is missing', (tester) async {
      await pump(tester, sourceFileExists: false);
      await openMoreMenu(tester);

      expect(menuItem(tester, l10n.statsSingleProjectActivity).onPressed,
          isNotNull);
    });
  });

  group('layout toggle', () {
    testWidgets('switches to sections from the page itself', (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.view_sidebar_outlined));
      await tester.pumpAndSettle();

      expect(layouts, [ProjectDetailLayout.sectioned]);
    });

    testWidgets('switches back to a single scroll', (tester) async {
      await pump(tester, layout: ProjectDetailLayout.sectioned);

      await tester.tap(find.byIcon(Icons.view_stream_outlined));
      await tester.pumpAndSettle();

      expect(layouts, [ProjectDetailLayout.classic]);
    });

    testWidgets('shows which layout is active', (tester) async {
      await pump(tester, layout: ProjectDetailLayout.sectioned);

      final toggle = tester.widget<SegmentedButton<ProjectDetailLayout>>(
          find.byType(SegmentedButton<ProjectDetailLayout>));
      expect(toggle.selected, {ProjectDetailLayout.sectioned});
    });
  });
}
