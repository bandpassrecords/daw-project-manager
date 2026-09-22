import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/ui/widgets/release_track_details.dart';

import '../helpers/test_factories.dart';

Future<void> _pump(WidgetTester tester, MusicProject project) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ReleaseTrackDetails(project: project)),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectPart _part(String name, PartTakeStatus status) =>
    ProjectPart(id: name, name: name, status: status);

void main() {
  testWidgets('shows length, parts and note', (tester) async {
    await _pump(
      tester,
      TestFactories.makeProject(
        autoDurationMs: 225000,
        notes: 'Needs a re-amp',
        parts: [
          _part('Drums', PartTakeStatus.finalTake),
          _part('Bass', PartTakeStatus.needed),
        ],
      ),
    );

    expect(find.text('3:45'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('Needs a re-amp'), findsOneWidget);
  });

  testWidgets('leaves out DAW, BPM, key and phase', (tester) async {
    // A release's tracklist asks "how long, is it done, what's left" — the
    // project's own properties live on the dashboard and in the table view.
    await _pump(
      tester,
      TestFactories.makeProject(
        dawType: 'Ableton Live',
        dawVersion: '12',
        bpm: 128,
        musicalKey: 'F# minor',
        status: 'Mixing',
        autoDurationMs: 225000,
      ),
    );

    expect(find.textContaining('Ableton'), findsNothing);
    expect(find.textContaining('128'), findsNothing);
    expect(find.textContaining('F#'), findsNothing);
    expect(find.textContaining('Mixing'), findsNothing);
    expect(find.text('3:45'), findsOneWidget);
  });

  group('hasContent', () {
    test('is false for a track with no length, parts or note', () {
      // No empty subtitle under the name.
      expect(
        ReleaseTrackDetails.hasContent(
          TestFactories.makeProject(notes: null, projectNotes: null),
        ),
        isFalse,
      );
    });

    test('is true when any one of the three exists', () {
      expect(
        ReleaseTrackDetails.hasContent(
          TestFactories.makeProject(autoDurationMs: 1000),
        ),
        isTrue,
      );
      expect(
        ReleaseTrackDetails.hasContent(
          TestFactories.makeProject(notes: 'x'),
        ),
        isTrue,
      );
      expect(
        ReleaseTrackDetails.hasContent(
          TestFactories.makeProject(
            parts: [_part('Bass', PartTakeStatus.needed)],
          ),
        ),
        isTrue,
      );
    });
  });

  group('isTwoLines', () {
    test('only when there is both a length/parts line and a note', () {
      expect(
        ReleaseTrackDetails.isTwoLines(
          TestFactories.makeProject(autoDurationMs: 1000, notes: 'x'),
        ),
        isTrue,
      );
      expect(
        ReleaseTrackDetails.isTwoLines(
          TestFactories.makeProject(notes: 'x'),
        ),
        isFalse,
        reason: 'a note alone is one line',
      );
      expect(
        ReleaseTrackDetails.isTwoLines(
          TestFactories.makeProject(autoDurationMs: 1000, notes: null),
        ),
        isFalse,
      );
    });
  });
}
