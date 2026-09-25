import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/services/release_artwork_service.dart';
import 'package:daw_project_manager/ui/dialogs/release_artwork_carryover_dialog.dart';

ReleaseArtworkCandidate _candidate(String id, String name, String path) =>
    ReleaseArtworkCandidate(
      projectId: id,
      projectName: name,
      imagePath: path,
    );

/// Pumps the view directly — no repository, no filesystem. The "which
/// thumbnails are worth offering" half lives in
/// `release_artwork_service_test.dart`; what matters here is which path the
/// dialog hands back.
///
/// The images themselves never load (the paths don't exist), so every tile
/// falls through to its errorBuilder — which is exactly the state the tile
/// has to survive, and it leaves the project name as the thing to tap.
Future<ReleaseArtworkChoice? Function()> _pumpView(
  WidgetTester tester, {
  required List<ReleaseArtworkCandidate> candidates,
}) async {
  ReleaseArtworkChoice? choice;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReleaseArtworkCarryOverView(
        candidates: candidates,
        onChoice: (c) => choice = c,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return () => choice;
}

void main() {
  testWidgets('shows a tile per candidate, labelled by project', (tester) async {
    await _pumpView(
      tester,
      candidates: [
        _candidate('p1', 'First Song', '/art/a.png'),
        _candidate('p2', 'Second Song', '/art/b.png'),
      ],
    );

    expect(find.text('First Song'), findsOneWidget);
    expect(find.text('Second Song'), findsOneWidget);
  });

  testWidgets('pre-selects the first candidate so one click confirms it',
      (tester) async {
    final choice = await _pumpView(
      tester,
      candidates: [
        _candidate('p1', 'First Song', '/art/a.png'),
        _candidate('p2', 'Second Song', '/art/b.png'),
      ],
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(choice()?.imagePath, '/art/a.png');
  });

  testWidgets('returns the path of whichever tile was tapped', (tester) async {
    final choice = await _pumpView(
      tester,
      candidates: [
        _candidate('p1', 'First Song', '/art/a.png'),
        _candidate('p2', 'Second Song', '/art/b.png'),
      ],
    );

    await tester.tap(find.text('Second Song'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(choice()?.imagePath, '/art/b.png');
  });

  testWidgets('skipping returns no artwork rather than the pre-selection',
      (tester) async {
    final choice = await _pumpView(
      tester,
      candidates: [_candidate('p1', 'First Song', '/art/a.png')],
    );

    await tester.tap(find.byType(TextButton));
    await tester.pump();

    expect(choice(), isNotNull);
    expect(choice()!.imagePath, isNull);
  });

  testWidgets('a tile whose image cannot be decoded stays usable',
      (tester) async {
    // The candidate list already skipped missing files, but a file can still
    // turn out not to be a decodable image. That must not throw, and — more
    // importantly — the tile must stay labelled and selectable, because its
    // label is all the user has left to tell the options apart.
    final choice = await _pumpView(
      tester,
      candidates: [
        _candidate('p1', 'First Song', '/art/not-an-image.png'),
        _candidate('p2', 'Second Song', '/art/also-not.png'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Second Song'), findsOneWidget);

    await tester.tap(find.text('Second Song'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(choice()?.imagePath, '/art/also-not.png');
  });

  group('showReleaseArtworkCarryOverDialog', () {
    testWidgets('skips without opening anything when there is nothing to offer',
        (tester) async {
      // Callers invoke it unconditionally, so an empty candidate list must be
      // a silent no-op rather than an empty dialog in the way of creating the
      // release.
      ReleaseArtworkChoice? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showReleaseArtworkCarryOverDialog(
                  context,
                  const [],
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(result?.imagePath, isNull);
    });
  });
}
