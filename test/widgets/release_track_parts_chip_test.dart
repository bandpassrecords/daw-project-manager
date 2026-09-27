import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/utils/part_status_display.dart';
import 'package:daw_project_manager/ui/widgets/release_track_parts_chip.dart';

import '../helpers/test_factories.dart';

ProjectPart _part(String name, PartTakeStatus status) =>
    ProjectPart(id: name, name: name, status: status);

Future<void> _pump(
  WidgetTester tester, {
  required List<ProjectPart> parts,
  VoidCallback? onTap,
  bool compact = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ReleaseTrackPartsChip(
          project: TestFactories.makeProject(parts: parts),
          onTap: onTap,
          compact: compact,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('draws nothing for a project with no parts listed',
      (tester) async {
    // Same rule the cover art follows: no generic placeholder on every row.
    await _pump(tester, parts: const []);

    expect(find.byType(InkWell), findsNothing);
    expect(find.byIcon(Icons.piano), findsNothing);
  });

  testWidgets('shows final takes over total', (tester) async {
    await _pump(tester, parts: [
      _part('Drums', PartTakeStatus.finalTake),
      _part('Bass', PartTakeStatus.needed),
      _part('Guitar', PartTakeStatus.recording),
    ]);

    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('counts the parts still needed alongside the progress',
      (tester) async {
    await _pump(tester, parts: [
      _part('Drums', PartTakeStatus.finalTake),
      _part('Bass', PartTakeStatus.needed),
      _part('Keys', PartTakeStatus.needed),
    ]);

    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(PartTakeStatus.needed.icon), findsOneWidget);
  });

  testWidgets('omits the needed marker when nothing is outstanding',
      (tester) async {
    await _pump(tester, parts: [
      _part('Drums', PartTakeStatus.finalTake),
      _part('Bass', PartTakeStatus.earlyTake),
    ]);

    expect(find.text('1/2'), findsOneWidget);
    expect(find.byIcon(PartTakeStatus.needed.icon), findsNothing);
  });

  testWidgets('switches to the done icon once every part is a final take',
      (tester) async {
    await _pump(tester, parts: [
      _part('Drums', PartTakeStatus.finalTake),
      _part('Bass', PartTakeStatus.finalTake),
    ]);

    expect(find.byIcon(PartTakeStatus.finalTake.icon), findsOneWidget);
    expect(find.byIcon(Icons.piano), findsNothing);
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('tapping it calls the supplied handler', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      parts: [_part('Bass', PartTakeStatus.needed)],
      onTap: () => tapped = true,
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('renders compactly without throwing', (tester) async {
    await _pump(
      tester,
      parts: [_part('Bass', PartTakeStatus.needed)],
      compact: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('0/1'), findsOneWidget);
  });

  group('neededCount', () {
    test('counts only the parts nothing has been recorded for', () {
      final project = TestFactories.makeProject(parts: [
        _part('Drums', PartTakeStatus.needed),
        _part('Bass', PartTakeStatus.needed),
        _part('Keys', PartTakeStatus.recording),
        _part('Vox', PartTakeStatus.finalTake),
      ]);

      expect(ReleaseTrackPartsChip.neededCount(project), 2);
    });

    test('is zero for a project with no parts', () {
      expect(
        ReleaseTrackPartsChip.neededCount(
          TestFactories.makeProject(parts: const []),
        ),
        0,
      );
    });
  });
}
