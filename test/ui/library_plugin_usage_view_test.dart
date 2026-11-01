import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/services/project_inspector/library/plugin_usage.dart';
import 'package:daw_project_manager/ui/widgets/library_plugin_usage_view.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

import '../helpers/semantics_orphans.dart';
import '../helpers/test_factories.dart';

MusicProject _p(String id, List<String> plugins, {DateTime? at}) =>
    TestFactories.makeProject(
      id: id,
      customDisplayName: 'Song $id',
      dawType: 'Cubase',
      lastModifiedAt: at ?? DateTime(2026, 5, 1),
      stats: ProjectStats(plugins: plugins),
    );

final _report = buildPluginUsage([
  _p('1', ['Serum', 'Frequency 2', 'OTT'], at: DateTime(2026, 5, 1)),
  _p('2', ['Serum', 'Frequency 2'], at: DateTime(2026, 6, 1)),
  _p('3', ['Serum']),
  TestFactories.makeProject(id: 'unread'),
]);

void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());

  Future<List<String>> pump(
    WidgetTester tester, {
    PluginUsageReport? report,
    String search = '',
    bool countable = false,
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
          body: LibraryPluginUsageView(
            report: report ?? _report,
            search: search,
            onClose: () => calls.add('close'),
            onShowProjects: (u) => calls.add('show ${u.name}'),
            onExportCsv: () => calls.add('csv'),
            onCountInstances: countable ? () => calls.add('count') : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('totals, most used first, stock hidden by default', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('3 plug-ins in use'), findsOneWidget);
    expect(find.text('3 projects read'), findsOneWidget);
    expect(find.text('1 used in one song only'), findsOneWidget);
    expect(
      find.text('1 project not read yet — a deep scan counts its plug-ins'),
      findsOneWidget,
    );
    expect(find.text('Serum'), findsOneWidget);
    expect(
      find.text('3 songs · 3 projects · last used Jun 1, 2026 · Cubase'),
      findsOneWidget,
    );
    expect(find.text('Frequency 2'), findsNothing, reason: "Cubase's own");
    expect(
      tester.getTopLeft(find.text('Serum')).dy,
      lessThan(tester.getTopLeft(find.text('OTT')).dy),
    );

    await tester.tap(find.text('Hide stock plug-ins'));
    await tester.pumpAndSettle();
    expect(find.text('Frequency 2'), findsOneWidget);
  });

  testWidgets('"Used once" keeps the rare ones', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Used once'));
    await tester.pumpAndSettle();
    expect(find.text('OTT'), findsOneWidget);
    expect(find.text('Serum'), findsNothing);
  });

  testWidgets('the search box filters by name', (tester) async {
    await pump(tester, search: 'ot');
    expect(find.text('OTT'), findsOneWidget);
    expect(find.text('Serum'), findsNothing);
  });

  testWidgets('a plug-in lists its projects and shows them in the list', (
    tester,
  ) async {
    final calls = await pump(tester);
    await tester.tap(find.text('Serum'));
    await tester.pumpAndSettle();
    expect(find.text('Song 2 · Jun 1, 2026'), findsOneWidget);
    await tester.tap(find.text('Show these projects'));
    expect(calls, ['show Serum']);
  });

  testWidgets('counting instances is offered only when there is some to read', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Count instances in Cubase projects…'), findsNothing);
    final calls = await pump(tester, countable: true);
    await tester.tap(find.text('Count instances in Cubase projects…'));
    await tester.tap(find.byTooltip('Export CSV'));
    await tester.tap(find.byTooltip('Close'));
    expect(calls, ['count', 'csv', 'close']);
  });

  testWidgets('nothing read yet says how to get there', (tester) async {
    await pump(tester, report: buildPluginUsage(const []));
    expect(
      find.text(
        'No plug-ins found yet. A deep scan reads which plug-ins each '
        'project uses.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('every tooltip shows with no node Windows rejects', (
    tester,
  ) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await pump(tester, countable: true);
    expect(binding.orphans, isEmpty);
    expect(await expectNoOrphanSemanticsWhileHovering(tester), greaterThan(0));
    handle.dispose();
  });

  test('the CSV: a row per plug-in, most used first', () {
    final lines = pluginUsageCsv(_report).split('\n');
    expect(
      lines[0],
      '﻿plugin,songs,projects,instances,last_used,daws,stock,project_names',
    );
    expect(lines[1], 'Serum,3,3,,2026-06-01,Cubase,false,Song 2; Song 1; Song 3');
  });
}
