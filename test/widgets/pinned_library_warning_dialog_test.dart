import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/pinned_library_warning_dialog.dart';

const _warning = PinnedLibraryWarning(
  dirName: 'daw_project_manager_pr141',
  path: r'C:\Users\tester\AppData\Local\daw_project_manager_pr141',
);

/// Pumps the view directly — no Hive, no providers. The persistence half is
/// covered by [shouldWarnAboutPinnedLibrary] below; what matters here is that
/// the view reports the opt-out the person actually ticked.
Future<bool? Function()> _pumpView(
  WidgetTester tester, {
  Locale? locale,
}) async {
  bool? continued;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: PinnedLibraryWarningView(
        warning: _warning,
        onContinue: (dontShowAgain) => continued = dontShowAgain,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return () => continued;
}

void main() {
  // A pull-request build opens a library of its own and says so nowhere: the
  // startup picker and the Settings dev card are both gated on
  // canPickAppDataDir, which a pinned build fails. A tester could therefore
  // spend a session wondering where their projects went, or trust that what
  // they added here reached their real library.
  group('shouldWarnAboutPinnedLibrary', () {
    test('a pinned build warns', () {
      expect(
        shouldWarnAboutPinnedLibrary(isPinned: true, silenced: false),
        isTrue,
      );
    });

    test('a build that is not pinned never warns', () {
      // Covers a shipping release and a build run from source: the latter is
      // isolated too, but chose its library at launch and names it in
      // Settings.
      expect(
        shouldWarnAboutPinnedLibrary(isPinned: false, silenced: false),
        isFalse,
      );
    });

    test('the opt-out silences a pinned build', () {
      expect(
        shouldWarnAboutPinnedLibrary(isPinned: true, silenced: true),
        isFalse,
      );
    });

    test('the opt-out cannot make an unpinned build warn', () {
      expect(
        shouldWarnAboutPinnedLibrary(isPinned: false, silenced: true),
        isFalse,
      );
    });
  });

  group('PinnedLibraryWarningView', () {
    testWidgets('names the library and its location', (tester) async {
      await _pumpView(tester);

      expect(find.text('Test library in use'), findsOneWidget);
      expect(find.text('daw_project_manager_pr141'), findsOneWidget);
      expect(
        find.text(r'C:\Users\tester\AppData\Local\daw_project_manager_pr141'),
        findsOneWidget,
      );
    });

    testWidgets('the path is selectable, so it can be copied out',
        (tester) async {
      await _pumpView(tester);

      expect(find.byType(SelectableText), findsNWidgets(2));
    });

    testWidgets('continuing without ticking the box reports no opt-out',
        (tester) async {
      final result = await _pumpView(tester);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(result(), isFalse);
    });

    testWidgets('ticking the box reports the opt-out', (tester) async {
      final result = await _pumpView(tester);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(result(), isTrue);
    });

    testWidgets('nothing is reported until Continue is pressed',
        (tester) async {
      final result = await _pumpView(tester);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      expect(result(), isNull);
    });

    testWidgets('fits a phone screen without overflowing', (tester) async {
      // CI hands testers a pinned debug APK as well, so this dialog has to
      // survive a narrow screen — a fixed-width content box would overflow.
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpView(tester);

      expect(tester.takeException(), isNull);
      final width = tester.getSize(find.byType(CheckboxListTile)).width;
      expect(width, lessThanOrEqualTo(360));
    });

    testWidgets('is localized, not hardcoded English', (tester) async {
      // Pinned builds are handed to testers as real installers, so unlike the
      // dev-only library picker this dialog does reach people who did not
      // build it — and they do not all read English.
      await _pumpView(tester, locale: const Locale('pt'));

      expect(find.text('Biblioteca de teste em uso'), findsOneWidget);
      expect(find.text('Test library in use'), findsNothing);
      // Still shows the same library, whatever the locale.
      expect(find.text('daw_project_manager_pr141'), findsOneWidget);
    });
  });
}
