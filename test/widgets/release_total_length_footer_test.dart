import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/widgets/release_total_length_footer.dart';

import '../helpers/test_factories.dart';

MusicProject _track(String id, {int? ms}) =>
    TestFactories.makeProject(id: id, autoDurationMs: ms);

Future<AppLocalizations> _pump(
  WidgetTester tester,
  List<MusicProject> projects,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ReleaseTotalLengthFooter(projects: projects)),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.delegate.load(const Locale('en'));
}

void main() {
  testWidgets('sums every track under the tracklist', (tester) async {
    final l10n = await _pump(tester, [
      _track('a', ms: 180000),
      _track('b', ms: 225000),
    ]);

    expect(find.text(l10n.releaseTotalLengthLabel), findsOneWidget);
    expect(find.text('6:45'), findsOneWidget);
  });

  testWidgets('marks a partial total and says how many tracks are missing',
      (tester) async {
    // The total is a floor when some tracks are untimed; presenting it as
    // exact would be wrong, and the reason belongs on screen, not in a
    // tooltip.
    final l10n = await _pump(tester, [
      _track('a', ms: 180000),
      _track('b'),
    ]);

    expect(find.text('3:00+'), findsOneWidget);
    expect(find.text(l10n.releaseLengthPartial(1)), findsOneWidget);
  });

  testWidgets('still shows up when no track has a length yet', (tester) async {
    // An absent total reads as "this page has no totals"; a dash with the
    // reason says what is missing and how to get it.
    final l10n = await _pump(tester, [_track('a'), _track('b')]);

    expect(find.text('—'), findsOneWidget);
    expect(find.text(l10n.releaseLengthNone), findsOneWidget);
  });

  testWidgets('draws nothing for a release with no tracks', (tester) async {
    await _pump(tester, const []);

    expect(find.byIcon(Icons.timer_outlined), findsNothing);
  });

  testWidgets('crosses the hour mark in h:mm:ss', (tester) async {
    await _pump(
      tester,
      List.generate(20, (i) => _track('t$i', ms: 225000)),
    );

    expect(find.text('1:15:00'), findsOneWidget);
  });
}
