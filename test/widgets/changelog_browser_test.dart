import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/services/changelog_service.dart';
import 'package:daw_project_manager/ui/widgets/changelog_browser.dart';

ChangelogRelease _release(
  String version,
  List<String> en, {
  Map<String, List<String>> extra = const {},
  DateTime? date,
}) =>
    ChangelogRelease(
      version: version,
      date: date,
      highlightsByLocale: {'en': en, ...extra},
    );

/// Pumps the browser directly — no asset bundle, no navigation. The loading half
/// lives in `changelog_service_test.dart`.
Future<void> _pumpList(
  WidgetTester tester, {
  required List<ChangelogRelease> releases,
  String? currentVersion,
  String localeCode = 'en',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChangelogBrowser(
            releases: releases,
            currentVersion: currentVersion,
            localeCode: localeCode,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every release it is given', (tester) async {
    await _pumpList(
      tester,
      releases: [
        _release('2.9.0', ['Newest change']),
        _release('2.8.0', ['Older change']),
        _release('2.7.0', ['Oldest change']),
      ],
    );

    expect(find.text('Newest change'), findsOneWidget);
    expect(find.text('Older change'), findsOneWidget);
    expect(find.text('Oldest change'), findsOneWidget);
  });

  testWidgets('marks the installed version', (tester) async {
    await _pumpList(
      tester,
      currentVersion: '2.8.0',
      releases: [
        _release('2.9.0', ['Not installed yet']),
        _release('2.8.0', ['Running this one']),
      ],
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.changelogCurrentVersionBadge), findsOneWidget);
  });

  testWidgets('shows no installed badge when the version is unknown',
      (tester) async {
    await _pumpList(
      tester,
      releases: [_release('2.9.0', ['A change'])],
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.changelogCurrentVersionBadge), findsNothing);
  });

  testWidgets('shows a release date when the entry has one', (tester) async {
    await _pumpList(
      tester,
      releases: [
        _release('2.9.0', ['A change'], date: DateTime(2026, 9, 22)),
      ],
    );

    expect(find.textContaining('2026'), findsOneWidget);
  });

  testWidgets('omits the date rather than showing a blank when it is missing',
      (tester) async {
    await _pumpList(tester, releases: [_release('2.9.0', ['A change'])]);

    expect(tester.takeException(), isNull);
    expect(find.text('A change'), findsOneWidget);
  });

  testWidgets('shows an explanation instead of a blank page when empty',
      (tester) async {
    await _pumpList(tester, releases: const []);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.changelogEmpty), findsOneWidget);
  });

  testWidgets('uses the requested locale\'s highlight text', (tester) async {
    await _pumpList(
      tester,
      localeCode: 'pt',
      releases: [
        _release('2.9.0', ['English line'], extra: {
          'pt': ['Linha em português'],
        }),
      ],
    );

    expect(find.text('Linha em português'), findsOneWidget);
    expect(find.text('English line'), findsNothing);
  });

  group('ChangelogReleaseCards', () {
    // The history runs back to 1.0; seventy-odd open cards would bury the
    // release anyone is looking for, so only the newest few start open.
    Future<void> pumpCards(WidgetTester tester, int count) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChangelogReleaseCards(
                releases: [
                  for (var i = count; i > 0; i--)
                    _release('1.$i.0', ['Change in 1.$i.0']),
                ],
                localeCode: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('opens the newest three and folds the rest', (tester) async {
      await pumpCards(tester, 5);

      expect(find.text('Change in 1.5.0'), findsOneWidget);
      expect(find.text('Change in 1.3.0'), findsOneWidget);
      expect(find.text('Change in 1.2.0'), findsNothing);
      expect(find.text('Change in 1.1.0'), findsNothing);
    });

    testWidgets('a folded release opens when tapped', (tester) async {
      await pumpCards(tester, 5);

      await tester.tap(find.textContaining('1.1.0'));
      await tester.pumpAndSettle();

      expect(find.text('Change in 1.1.0'), findsOneWidget);
    });

    testWidgets('sits inside a page that already scrolls', (tester) async {
      // The Settings pane scrolls; the list must not bring its own scroll view.
      await pumpCards(tester, 5);

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(ChangelogReleaseCards),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
    });
  });

  group('ChangelogBrowser search', () {
    Future<void> pumpBrowser(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChangelogBrowser(
                releases: [
                  _release('2.9.0', ['Volume is remembered']),
                  _release('2.8.0', ['Parts and performers']),
                  _release('2.7.0', ['Zrythm support']),
                  _release('2.6.0', ['Project templates']),
                ],
                localeCode: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('narrows the list as the user types', (tester) async {
      await pumpBrowser(tester);

      await tester.enterText(find.byType(TextField), 'volume');
      await tester.pumpAndSettle();

      expect(find.text('Volume is remembered'), findsOneWidget);
      expect(find.textContaining('2.8.0'), findsNothing);
    });

    testWidgets('opens a match even in a release folded by default',
        (tester) async {
      // 2.6.0 is the fourth release, so it starts folded; a search hit in it
      // must be visible without another click.
      await pumpBrowser(tester);
      expect(find.text('Project templates'), findsNothing);

      await tester.enterText(find.byType(TextField), 'templates');
      await tester.pumpAndSettle();

      expect(find.text('Project templates'), findsOneWidget);
    });

    testWidgets('matches fuzzily, like the dashboard project search',
        (tester) async {
      await pumpBrowser(tester);

      // Word-anchored chunks: "parperf" is par|ts per|formers.
      await tester.enterText(find.byType(TextField), 'parperf');
      await tester.pumpAndSettle();

      expect(find.text('Parts and performers'), findsOneWidget);
      expect(find.textContaining('2.9.0'), findsNothing);
    });

    testWidgets('says so when nothing matches', (tester) async {
      await pumpBrowser(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.changelogNoMatches('zzz')), findsOneWidget);
    });

    testWidgets('clearing the search brings everything back', (tester) async {
      await pumpBrowser(tester);
      await tester.enterText(find.byType(TextField), 'volume');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.textContaining('2.8.0'), findsOneWidget);
      expect(find.textContaining('2.6.0'), findsOneWidget);
    });
  });
}
