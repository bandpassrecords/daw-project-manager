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
      home: Scaffold(
        body: ReleaseTrackDetails(
          project: project,
          phaseLabel: 'Mixing',
          phaseColor: Colors.orange,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectPart _part(String name, PartTakeStatus status) =>
    ProjectPart(id: name, name: name, status: status);

void main() {
  testWidgets('shows DAW, BPM, key, length, phase, parts and note',
      (tester) async {
    await _pump(
      tester,
      TestFactories.makeProject(
        dawType: 'Ableton Live',
        dawVersion: '12',
        bpm: 128,
        musicalKey: 'F# minor',
        autoDurationMs: 225000,
        notes: 'Needs a re-amp',
        parts: [
          _part('Drums', PartTakeStatus.finalTake),
          _part('Bass', PartTakeStatus.needed),
        ],
      ),
    );

    expect(find.text('Ableton Live 12'), findsOneWidget);
    expect(find.textContaining('128'), findsOneWidget);
    expect(find.text('F# minor'), findsOneWidget);
    expect(find.text('3:45'), findsOneWidget);
    expect(find.text('Mixing'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('Needs a re-amp'), findsOneWidget);
  });

  testWidgets('never shows the notes extracted from the DAW file',
      (tester) async {
    await _pump(
      tester,
      TestFactories.makeProject(
        notes: null,
        projectNotes: 'Plug-in scratch from the session',
      ),
    );

    expect(find.textContaining('Plug-in scratch'), findsNothing);
  });

  testWidgets('skips facts the project does not have', (tester) async {
    await _pump(
      tester,
      TestFactories.makeProject(dawType: null, bpm: null, musicalKey: null),
    );

    expect(find.textContaining('BPM'), findsNothing);
    // The phase is always there.
    expect(find.text('Mixing'), findsOneWidget);
  });

  group('isTwoLines', () {
    test('only when the user wrote a note', () {
      expect(
        ReleaseTrackDetails.isTwoLines(TestFactories.makeProject(notes: 'x')),
        isTrue,
      );
      expect(
        ReleaseTrackDetails.isTwoLines(TestFactories.makeProject(notes: null)),
        isFalse,
      );
    });

    test('DAW-extracted notes do not add a line', () {
      expect(
        ReleaseTrackDetails.isTwoLines(
          TestFactories.makeProject(notes: null, projectNotes: 'from the DAW'),
        ),
        isFalse,
      );
    });
  });
}
