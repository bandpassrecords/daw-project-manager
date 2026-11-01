import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/services/project_inspector/compare/anatomy_diff.dart';
import 'package:daw_project_manager/ui/widgets/project_compare_view.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

import '../helpers/semantics_orphans.dart';

const _a = ProjectAnatomy(
  filePath: '/music/Song/Song 2.cpr',
  fileSize: 1,
  dawType: 'Cubase',
  tempo: 145,
  channels: [
    AnatomyChannel(
      name: 'Kick',
      kind: AnatomyChannelKind.audio,
      output: 'Drums',
      volumeDb: 0,
    ),
    AnatomyChannel(
      name: 'Vox',
      kind: AnatomyChannelKind.audio,
      output: 'Stereo Out',
      volumeDb: -4,
      inserts: [AnatomyInsert(slot: 0, plugin: 'Pro-Q 3')],
      sends: [AnatomySend(destination: 'Reverb', levelDb: 12.9)],
    ),
    AnatomyChannel(name: 'Shaker', kind: AnatomyChannelKind.audio),
  ],
);

const _b = ProjectAnatomy(
  filePath: '/music/Song/Song 3.cpr',
  fileSize: 1,
  dawType: 'Cubase',
  tempo: 150,
  channels: [
    AnatomyChannel(
      name: 'Kick',
      kind: AnatomyChannelKind.audio,
      output: 'Drums',
      volumeDb: 0,
    ),
    AnatomyChannel(
      name: 'Vox',
      kind: AnatomyChannelKind.audio,
      output: 'Stereo Out',
      volumeDb: -11.4,
      inserts: [
        AnatomyInsert(slot: 0, plugin: 'Pro-Q 3'),
        AnatomyInsert(slot: 1, plugin: 'Pro-L 2'),
      ],
      sends: [AnatomySend(destination: 'Reverb', levelDb: 8.6)],
    ),
    AnatomyChannel(name: 'Reverb', kind: AnatomyChannelKind.fx),
  ],
);

void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();

  Future<List<String>> pump(
    WidgetTester tester, {
    ProjectAnatomy a = _a,
    ProjectAnatomy b = _b,
    String search = '',
  }) async {
    final calls = <String>[];
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProjectCompareView(
            a: a,
            b: b,
            search: search,
            onSwap: () => calls.add('swap'),
            onClose: () => calls.add('close'),
            onCopySummary: (d) => calls.add('copy ${d.changeCount}'),
            onExportCsv: (d) => calls.add('csv ${d.changeCount}'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('A and B, the totals, the project and each changed channel', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Song 2.cpr'), findsOneWidget);
    expect(find.text('Song 3.cpr'), findsOneWidget);
    expect(find.text('6 changes'), findsOneWidget);
    expect(find.text('1 channel changed'), findsOneWidget);
    expect(find.text('1 unchanged'), findsOneWidget);
    expect(find.text('1 only in A'), findsOneWidget);
    expect(find.text('1 only in B'), findsOneWidget);
    expect(find.text('Tempo 145 → 150 BPM'), findsOneWidget);
    expect(
      find.text(
        'Fader −4.0 dB → −11.4 dB\n'
        'Pro-L 2 inserted in slot 2\n'
        'Send to Reverb +12.9 dB → +8.6 dB',
      ),
      findsOneWidget,
    );
    expect(find.text('Only in A'), findsOneWidget, reason: 'Shaker');
    expect(find.text('Only in B'), findsOneWidget, reason: 'Reverb');
    expect(find.text('Kick'), findsNothing, reason: 'unchanged');
  });

  testWidgets('a filter chip keeps one kind of change', (tester) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sends'));
    await tester.pumpAndSettle();
    expect(find.text('Send to Reverb +12.9 dB → +8.6 dB'), findsOneWidget);
    expect(find.text('Shaker'), findsNothing);
    expect(find.text('Tempo 145 → 150 BPM'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tracks'));
    await tester.pumpAndSettle();
    expect(find.text('Shaker'), findsOneWidget);
    expect(find.text('Vox'), findsNothing);
  });

  testWidgets('the search box finds channels by name or by what changed', (
    tester,
  ) async {
    await pump(tester, search: 'pro-l');
    expect(find.text('Vox'), findsOneWidget);
    expect(find.text('Shaker'), findsNothing);
  });

  testWidgets('a channel opens A and B side by side', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Vox'));
    await tester.pumpAndSettle();
    expect(find.text('1. Pro-Q 3'), findsNWidgets(2));
    expect(find.text('2. Pro-L 2'), findsOneWidget);
    expect(find.text('Fader: −11.4 dB · Pan: C'), findsNothing,
        reason: 'pan not read here');
    expect(find.text('Fader: −11.4 dB'), findsOneWidget);
  });

  testWidgets('two projects that read the same say so', (tester) async {
    await pump(tester, b: _a);
    expect(find.text('No differences found'), findsOneWidget);
  });

  testWidgets("a DAW whose channels aren't read compares its plug-ins", (
    tester,
  ) async {
    await pump(
      tester,
      a: const ProjectAnatomy(
        filePath: '/x/a.flp',
        fileSize: 1,
        dawType: 'FL Studio',
        plugins: [AnatomyPlugin(name: 'Serum')],
      ),
      b: const ProjectAnatomy(
        filePath: '/x/b.flp',
        fileSize: 1,
        dawType: 'FL Studio',
        plugins: [AnatomyPlugin(name: 'Vital')],
      ),
    );
    expect(
      find.textContaining("Channels of FL Studio projects aren't read yet"),
      findsOneWidget,
    );
    expect(find.text('Now uses Vital'), findsOneWidget);
    expect(find.text('No longer uses Serum'), findsOneWidget);
  });

  testWidgets('swap, copy, CSV and close are handed to the page', (
    tester,
  ) async {
    final calls = await pump(tester);
    await tester.tap(find.byTooltip('Swap A and B'));
    await tester.tap(find.byTooltip('Copy summary'));
    await tester.tap(find.byTooltip('Export CSV'));
    await tester.tap(find.byTooltip('Close compare'));
    expect(calls, ['swap', 'copy 6', 'csv 6', 'close']);
  });

  testWidgets('every tooltip shows with no node Windows rejects', (
    tester,
  ) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(binding.orphans, isEmpty);
    expect(await expectNoOrphanSemanticsWhileHovering(tester), greaterThan(0));
    handle.dispose();
  });

  test('the diff the view shows is diffAnatomy', () {
    expect(diffAnatomy(_a, _b).changeCount, 6);
  });
}
