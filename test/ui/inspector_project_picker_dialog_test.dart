import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/services/project_inspector/library/project_choices.dart';
import 'package:daw_project_manager/ui/dialogs/inspector_project_picker_dialog.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

import '../helpers/semantics_orphans.dart';
import '../helpers/test_factories.dart';

void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();
  final song = p.join(p.separator, 'music', 'Song');
  final other = p.join(p.separator, 'music', 'Other');

  MusicProject project(String path, {String daw = 'Cubase'}) =>
      TestFactories.makeProject(
        id: path,
        filePath: path,
        fileName: p.basename(path),
        dawType: daw,
        lastModifiedAt: DateTime(2026, 3, 4),
      );

  final v1 = project(p.join(song, 'Song-01.cpr'));
  final jam = project(p.join(other, 'Jam.als'), daw: 'Ableton Live');
  final beat = project(p.join(other, 'Beat.rpp'), daw: 'REAPER');

  /// Opens the dialog and returns what it chose.
  Future<InspectorPick?> open(
    WidgetTester tester,
    InspectorProjectChoices choices, {
    Future<void> Function()? then,
  }) async {
    InspectorPick? chosen;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => chosen = await showDialog<InspectorPick>(
                context: context,
                builder: (_) => InspectorProjectPickerDialog(
                  title: 'Choose a project to inspect',
                  choices: choices,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    if (then != null) {
      await then();
      await tester.pumpAndSettle();
    }
    return chosen;
  }

  testWidgets('lists the library; a tap picks that project\'s file', (
    tester,
  ) async {
    final pick = await open(tester, (
      versions: const [],
      others: [jam, beat],
    ), then: () => tester.tap(find.text('Beat')));
    expect(pick?.path, beat.filePath);
    expect(pick?.browse, isFalse);
  });

  testWidgets('no headings with only one list', (tester) async {
    await open(tester, (versions: const [], others: [jam, beat]));
    expect(find.text('Jam'), findsOneWidget);
    expect(find.text('Ableton Live · $other'), findsOneWidget);
    expect(find.text('Versions of this song'), findsNothing);
    expect(find.text('Other projects'), findsNothing);
  });

  testWidgets('comparing: the versions first, under their heading', (
    tester,
  ) async {
    await open(tester, (versions: [v1], others: [jam]));
    final versionsY = tester.getTopLeft(find.text('Versions of this song')).dy;
    final v1Y = tester.getTopLeft(find.text('Song-01')).dy;
    final othersY = tester.getTopLeft(find.text('Other projects')).dy;
    final jamY = tester.getTopLeft(find.text('Jam')).dy;
    expect(versionsY < v1Y && v1Y < othersY && othersY < jamY, isTrue);
  });

  testWidgets('the search narrows the list, and says when nothing matches', (
    tester,
  ) async {
    await open(tester, (versions: [v1], others: [jam, beat]));
    await tester.enterText(find.byType(TextField), 'reaper');
    await tester.pump();
    expect(find.text('Beat'), findsOneWidget);
    expect(find.text('Jam'), findsNothing);
    expect(find.text('Song-01'), findsNothing);
    expect(find.text('Versions of this song'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing like it');
    await tester.pump();
    expect(find.text('No project matches'), findsOneWidget);
  });

  testWidgets('Browse files… asks for a file dialog; Cancel picks nothing', (
    tester,
  ) async {
    final browse = await open(tester, (
      versions: const [],
      others: [jam],
    ), then: () => tester.tap(find.text('Browse files…')));
    expect(browse?.browse, isTrue);

    final none = await open(tester, (
      versions: const [],
      others: [jam],
    ), then: () => tester.tap(find.text('Cancel')));
    expect(none, isNull);
  });

  testWidgets('no node Windows rejects', (tester) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await open(tester, (versions: [v1], others: [jam, beat]));
    expect(binding.orphans, isEmpty);
    handle.dispose();
  });
}
