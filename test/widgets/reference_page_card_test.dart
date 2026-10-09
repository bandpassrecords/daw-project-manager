import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/widgets/midi_read_dialogs.dart';
import 'package:daw_project_manager/ui/widgets/reference_page_card.dart';

import '../helpers/test_factories.dart';

Widget _app(Widget Function(BuildContext) body) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: body),
    );

void main() {
  group('ReferencePageCard', () {
    Future<List<int>> pumpCard(WidgetTester tester, {bool busy = false}) async {
      final taps = <int>[];
      await tester.pumpWidget(_app((_) => Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 900,
                child: ReferencePageCard(
                    busy: busy, onGenerate: () => taps.add(1)),
              ),
            ),
          )));
      return taps;
    }

    testWidgets('lays out, and the button generates', (tester) async {
      final taps = await pumpCard(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Insert reference page'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, hasLength(1));
    });

    testWidgets('while busy the button does nothing', (tester) async {
      final taps = await pumpCard(tester, busy: true);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(taps, isEmpty);
    });
  });

  group('askProjectRead', () {
    testWidgets('uses the words it is given and reports the choice',
        (tester) async {
      MidiReadChoice? result;
      await tester.pumpWidget(_app((context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await askProjectRead(
                context,
                title: 'Read these?',
                body: 'Three files.',
                readLabel: 'Do it',
                skipLabel: 'Skip it',
              ),
              child: const Text('open'),
            ),
          )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Read these?'), findsOneWidget);
      expect(find.text('Three files.'), findsOneWidget);
      await tester.tap(find.text('Skip it'));
      await tester.pumpAndSettle();
      expect(result, MidiReadChoice.exportWhatIsRead);
    });
  });

  group('MidiReadDialog words', () {
    testWidgets('a given title and stop label replace the MIDI ones',
        (tester) async {
      final MusicProject project = TestFactories.makeProject(
        id: 'a',
        filePath: p.join('songs', 'A.cpr'),
        fileName: 'A.cpr',
      );
      final gate = Completer<void>();
      await tester.pumpWidget(_app((context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => MidiReadDialog(
                  projects: [project],
                  title: 'Reading Cubase projects',
                  stopLabel: 'Enough',
                  read: (_) => gate.future,
                ),
              ),
              child: const Text('open'),
            ),
          )));
      await tester.tap(find.text('open'));
      await tester.pump();
      expect(find.text('Reading Cubase projects'), findsOneWidget);
      expect(find.text('Enough'), findsOneWidget);
      expect(find.text('Reading MIDI'), findsNothing);
      expect(find.text("Stop and export what's read"), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
    });
  });
}
