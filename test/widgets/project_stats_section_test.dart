import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/ui/widgets/project_stats_section.dart';

const _labels = ProjectStatsLabels(
  tracks: 'Tracks',
  audio: 'Audio',
  midi: 'MIDI',
  instrument: 'Instrument',
  sampler: 'Sampler',
  bus: 'Groups & FX',
  folder: 'Folders',
  plugins: 'Plug-ins',
  showAll: 'Show all',
  collapse: 'Collapse',
);

Widget _wrap(ProjectStats stats, {int collapsed = 16}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProjectStatsSection(
            stats: stats,
            labels: _labels,
            collapsedPluginCount: collapsed,
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows the total and every kind that has tracks', (tester) async {
    await tester.pumpWidget(_wrap(const ProjectStats(
      audioTracks: 41,
      instrumentTracks: 9,
      busTracks: 3,
    )));

    expect(find.text('Tracks'), findsOneWidget);
    expect(find.text('53'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Instrument'), findsOneWidget);
    expect(find.text('Groups & FX'), findsOneWidget);
  });

  testWidgets('leaves out kinds with no tracks', (tester) async {
    await tester.pumpWidget(_wrap(const ProjectStats(audioTracks: 2)));

    expect(find.text('Sampler'), findsNothing);
    expect(find.text('Folders'), findsNothing);
    expect(find.text('MIDI'), findsNothing);
  });

  testWidgets('lists plug-ins, collapsing a long list behind "Show all"',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const ProjectStats(audioTracks: 1, plugins: ['A', 'B', 'C', 'D']),
      collapsed: 2,
    ));

    expect(find.text('Plug-ins'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsNothing);

    await tester.tap(find.text('Show all'));
    await tester.pump();
    expect(find.text('D'), findsOneWidget);
    expect(find.text('Collapse'), findsOneWidget);
  });

  testWidgets('a project with plug-ins but no tracks shows only plug-ins',
      (tester) async {
    await tester.pumpWidget(_wrap(const ProjectStats(plugins: ['Serum'])));

    expect(find.text('Tracks'), findsNothing);
    expect(find.text('Serum'), findsOneWidget);
  });
}
