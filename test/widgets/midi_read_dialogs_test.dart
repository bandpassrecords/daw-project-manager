import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/services/midi/melodic_midi_reading.dart';
import 'package:daw_project_manager/ui/widgets/midi_read_dialogs.dart';

import '../helpers/test_factories.dart';

MusicProject _p(int i) => TestFactories.makeProject(
      id: 'p$i',
      filePath: p.join('songs', 'Song $i.cpr'),
      fileName: 'Song $i.cpr',
    );

Widget _app(Widget Function(BuildContext) body) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: body),
    );

void main() {
  group('askMidiRead', () {
    Future<MidiReadChoice?> choose(WidgetTester tester, String button) async {
      MidiReadChoice? result;
      await tester.pumpWidget(_app((context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await askMidiRead(context,
                  count: 12, bytes: 3 * 1024 * 1024 * 1024),
              child: const Text('open'),
            ),
          )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('12 projects (3.0 GB)'), findsOneWidget,
          reason: 'says how many and how big');
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('read and export', (tester) async {
      expect(await choose(tester, 'Read and export'),
          MidiReadChoice.readThenExport);
    });

    testWidgets('export what is read', (tester) async {
      expect(await choose(tester, "Export what's read"),
          MidiReadChoice.exportWhatIsRead);
    });

    testWidgets('cancel', (tester) async {
      expect(await choose(tester, 'Cancel'), MidiReadChoice.cancel);
    });
  });

  group('MidiReadDialog', () {
    Future<MidiReadOutcome?> run(
      WidgetTester tester,
      List<MusicProject> projects,
      Future<void> Function(MusicProject) read,
    ) async {
      MidiReadOutcome? outcome;
      await tester.pumpWidget(_app((context) => Scaffold(
            body: TextButton(
              onPressed: () async => outcome = await showDialog<MidiReadOutcome>(
                context: context,
                barrierDismissible: false,
                builder: (_) => MidiReadDialog(projects: projects, read: read),
              ),
              child: const Text('open'),
            ),
          )));
      await tester.tap(find.text('open'));
      await tester.pump();
      return outcome;
    }

    testWidgets('reads every project and closes with the outcome',
        (tester) async {
      final read = <String>[];
      MidiReadOutcome? outcome;
      await tester.pumpWidget(_app((context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  outcome = await showDialog<MidiReadOutcome>(
                context: context,
                builder: (_) => MidiReadDialog(
                  projects: [_p(0), _p(1), _p(2)],
                  read: (project) async => read.add(project.id),
                ),
              ),
              child: const Text('open'),
            ),
          )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(read, ['p0', 'p1', 'p2']);
      expect(outcome?.read, 3);
      expect(find.byType(MidiReadDialog), findsNothing);
    });

    testWidgets('shows where it is while a project is being read',
        (tester) async {
      final gate = Completer<void>();
      await run(tester, [_p(0), _p(1)], (project) => gate.future);
      await tester.pump();
      expect(find.text('1 of 2: Song 0.cpr'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('stop ends the reading after the current project',
        (tester) async {
      final gate = Completer<void>();
      final read = <String>[];
      MidiReadOutcome? outcome;
      await tester.pumpWidget(_app((context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  outcome = await showDialog<MidiReadOutcome>(
                context: context,
                builder: (_) => MidiReadDialog(
                  projects: [_p(0), _p(1), _p(2)],
                  read: (project) async {
                    read.add(project.id);
                    await gate.future;
                  },
                ),
              ),
              child: const Text('open'),
            ),
          )));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.tap(find.text("Stop and export what's read"));
      await tester.pump();
      gate.complete();
      await tester.pumpAndSettle();
      expect(read, ['p0'], reason: 'the one in flight finishes, no more start');
      expect(outcome?.stopped, isTrue);
      expect(outcome?.read, 1);
    });
  });
}
