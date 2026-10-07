import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/ui/widgets/project_info_columns.dart';

import '../../helpers/test_factories.dart';

MusicProject _song() => TestFactories.makeProject(
      id: 'p',
      notes: 'Bridge needs a new synth line.\n\nAsk Ana for the vocal comp.',
      parts: const [
        ProjectPart(id: 'a', name: 'Vocals'),
        ProjectPart(id: 'b', name: 'Bass', status: PartTakeStatus.finalTake),
        ProjectPart(id: 'c', name: 'Keys'),
      ],
    ).copyWith(durationMs: 225000);

void main() {
  test('a project row: its length, notes and how many parts are still needed',
      () {
    final cells = projectInfoCells(_song());
    expect(cells[kLengthColumnField]!.value, 225000);
    expect(cells[kNotesColumnField]!.value,
        'Bridge needs a new synth line. Ask Ana for the vocal comp.',
        reason: 'the project\'s own notes, on one line');
    expect(cells[kPartsColumnField]!.value, 2);
  });

  test('tags and deadline are shared too', () {
    final p = TestFactories.makeProject(id: 't', tags: const ['Trap', 'Demo']);
    final cells = projectInfoCells(p);
    expect(cells[kTagsColumnField]!.value, 'Trap, Demo');
    expect(cells.containsKey(kDeadlineColumnField), isTrue);
  });

  test('deadline badges: late, today, this week, later', () {
    expect(deadlineBadgeOf(-3).kind, DeadlineBadgeKind.late);
    expect(deadlineBadgeOf(-3).days, 3);
    expect(deadlineBadgeOf(0).kind, DeadlineBadgeKind.today);
    expect(deadlineBadgeOf(5).kind, DeadlineBadgeKind.soon);
    expect(deadlineBadgeOf(30).kind, DeadlineBadgeKind.later);
    expect(deadlineBadgeOf(30).days, 30,
        reason: 'shown through the translated "days left", no longer a '
            'hardcoded English "30d left"');
  });

  test('a project with nothing to show: empty, sorting as zero', () {
    final cells = projectInfoCells(TestFactories.makeProject(id: 'q'));
    expect(cells[kLengthColumnField]!.value, 0);
    expect(cells[kNotesColumnField]!.value, '');
    expect(cells[kPartsColumnField]!.value, 0);
    expect(emptyProjectInfoCells().keys, cells.keys,
        reason: 'a group row carries every cell the columns need');
  });

  testWidgets('the columns draw the notes, the length and the parts',
      (tester) async {
    final song = _song();
    await tester.pumpWidget(MaterialApp(
      // The parts chip speaks through the app's strings.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 900,
          height: 200,
          child: TrinaGrid(
            columns: [
              projectNotesColumn(title: 'Notes'),
              projectLengthColumn(title: 'Length'),
              projectPartsColumn(title: 'Parts'),
              TrinaColumn(
                title: 'data',
                field: 'data',
                type: TrinaColumnType.text(),
                hide: true,
              ),
            ],
            rows: [
              TrinaRow(cells: {
                ...projectInfoCells(song),
                'data': TrinaCell(value: song),
              }),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Bridge needs a new synth line. Ask Ana for the vocal comp.'),
        findsOneWidget);
    expect(find.text('3:45'), findsOneWidget);
    expect(find.byTooltip(
            'Bridge needs a new synth line. Ask Ana for the vocal comp.'),
        findsOneWidget, reason: 'the full note on hover');
    expect(tester.takeException(), isNull);
  });
}
