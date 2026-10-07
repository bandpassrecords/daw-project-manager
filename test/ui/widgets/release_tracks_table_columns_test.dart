import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/providers/theme_provider.dart';
import 'package:daw_project_manager/ui/widgets/release_tracks_table.dart';
import 'package:daw_project_manager/utils/custom_fields.dart';

import '../../helpers/test_factories.dart';

/// The column layout, handed in rather than read from Hive (widget tests
/// must not touch Hive).
class _Layout extends ProjectsTableColumnsNotifier {
  _Layout(this.layout);
  final List<TableColumnSetting> layout;

  @override
  List<TableColumnSetting> build() => layout;
}

class _TagsOn extends TagsEnabledNotifier {
  @override
  bool build() => true;
}

void main() {
  Future<void> pump(WidgetTester tester, List<TableColumnSetting> layout) async {
    tester.view.physicalSize = const Size(1800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        projectsTableColumnsProvider.overrideWith(() => _Layout(layout)),
        tagsEnabledProvider.overrideWith(_TagsOn.new),
        activeCustomFieldsProvider.overrideWithValue(const []),
        activeThemeProvider.overrideWithValue(AppThemes.classicDarkSpec),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: ReleaseTracksTable(
              projects: [
                TestFactories.makeProject(id: 'a', tags: const ['Trap']),
              ],
              dateFormat: DateFormat.yMd(),
              onViewDetails: (_) {},
              onLaunch: null,
              onRemoveFromRelease: (_) {},
              onOpenParts: (_) {},
              translateStatus: (s) => s,
              statusColor: (_) => Colors.grey,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the tracklist shows the columns switched on for it',
      (tester) async {
    await pump(
      tester,
      normalizeColumnLayout(const [
        // Off in the tracklist, on in the projects table.
        TableColumnSetting('bpm', visible: true, inReleaseTracks: false),
        // On in the tracklist, off in the projects table.
        TableColumnSetting('tags', visible: false, inReleaseTracks: true),
      ]),
    );
    expect(find.text('BPM'), findsNothing);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('Trap'), findsOneWidget, reason: 'the tag itself');
    expect(find.text('Deadline'), findsNothing,
        reason: 'not switched on for tracklists by default');
    expect(find.text('Notes'), findsOneWidget,
        reason: 'what the tracklist always had stays on');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the default layout keeps the tracklist as it was', (tester) async {
    await pump(tester, normalizeColumnLayout(const []));
    for (final title in ['BPM', 'Phase', 'Notes', 'Length']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Tags'), findsNothing);
    expect(find.text('Deadline'), findsNothing);
  });
}
