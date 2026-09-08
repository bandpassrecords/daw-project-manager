import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/widgets/project_versions_section.dart';

import '../helpers/test_factories.dart';

/// #94 — the Versions list on a stacked song's detail page. Like the markers
/// section it takes plain values and callbacks rather than a `Ref`, so all of
/// this runs without opening Hive.
void main() {
  MusicProject version(String id, String name) =>
      TestFactories.makeProject(id: id, customDisplayName: name);

  final v1 = version('v1', 'Track v1');
  final v2 = version('v2', 'Track v2');
  final v3 = version('v3', 'Track v3');

  Widget wrap(
    List<MusicProject> members, {
    String? defaultLaunchMemberId = 'v2',
    VoidCallback? onAdd,
    void Function(MusicProject)? onRemove,
    void Function(MusicProject)? onSetDefault,
    void Function(MusicProject)? onOpen,
    VoidCallback? onUnstack,
    String? emptyTitle = 'Not stacked yet',
    String? emptyDescription = 'Add another project file.',
  }) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ProjectVersionsSection(
          members: members,
          defaultLaunchMemberId: defaultLaunchMemberId,
          title: 'Versions',
          countLabel: '${members.length} versions',
          addLabel: 'Add Version',
          unstackLabel: 'Unstack',
          defaultBadgeLabel: 'Opens by default',
          setDefaultTooltip: 'Open this version by default',
          removeTooltip: 'Remove from stack',
          subtitleBuilder: (m) => m.fileName,
          emptyTitle: emptyTitle,
          emptyDescription: emptyDescription,
          onAdd: onAdd,
          onRemove: onRemove,
          onSetDefault: onSetDefault,
          onOpen: onOpen,
          onUnstack: onUnstack,
        ),
      ),
    ),
  );

  testWidgets('lists every version in the stack', (tester) async {
    await tester.pumpWidget(wrap([v1, v2, v3]));

    expect(find.text('Track v1'), findsOneWidget);
    expect(find.text('Track v2'), findsOneWidget);
    expect(find.text('Track v3'), findsOneWidget);
  });

  testWidgets('shows the version count next to the heading', (tester) async {
    await tester.pumpWidget(wrap([v1, v2, v3]));

    expect(find.text('3 versions'), findsOneWidget);
  });

  testWidgets('marks the version that opens by default', (tester) async {
    await tester.pumpWidget(wrap([v1, v2, v3], onSetDefault: (_) {}));

    expect(find.text('Opens by default'), findsOneWidget);
    // Exactly one row carries the filled star.
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
  });

  testWidgets('the badge shows even when nomination is unavailable',
      (tester) async {
    await tester.pumpWidget(wrap([v1, v2, v3]));

    // Which version opens is worth knowing even where it can't be changed.
    expect(find.text('Opens by default'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('no default nominated leaves every row unstarred',
      (tester) async {
    await tester.pumpWidget(
      wrap([v1, v2], defaultLaunchMemberId: null, onSetDefault: (_) {}),
    );

    expect(find.text('Opens by default'), findsNothing);
    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
  });

  testWidgets('reports which version was removed', (tester) async {
    MusicProject? removed;
    await tester.pumpWidget(
      wrap([v1, v2, v3], onRemove: (m) => removed = m),
    );

    await tester.tap(find.byIcon(Icons.close).at(2));
    await tester.pump();

    expect(removed?.id, 'v3');
  });

  testWidgets('reports which version was nominated as the default',
      (tester) async {
    MusicProject? nominated;
    await tester.pumpWidget(
      wrap([v1, v2, v3], onSetDefault: (m) => nominated = m),
    );

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump();

    expect(nominated?.id, 'v1');
  });

  testWidgets('the current default cannot be re-nominated', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap([v1, v2, v3], onSetDefault: (_) => taps++),
    );

    // The star stays visible but inert — a row that loses its control when
    // you pick it reads as the control breaking.
    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('reports which version was opened', (tester) async {
    MusicProject? opened;
    await tester.pumpWidget(wrap([v1, v2], onOpen: (m) => opened = m));

    await tester.tap(find.text('Track v2'));
    await tester.pump();

    expect(opened?.id, 'v2');
  });

  testWidgets('add and unstack fire their callbacks', (tester) async {
    var added = 0;
    var unstacked = 0;
    await tester.pumpWidget(
      wrap([v1, v2], onAdd: () => added++, onUnstack: () => unstacked++),
    );

    await tester.tap(find.text('Add Version'));
    await tester.pump();
    await tester.tap(find.text('Unstack'));
    await tester.pump();

    expect(added, 1);
    expect(unstacked, 1);
  });

  testWidgets('actions with no callback are absent rather than dead',
      (tester) async {
    await tester.pumpWidget(wrap([v1, v2]));

    expect(find.text('Add Version'), findsNothing);
    expect(find.text('Unstack'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  group('empty state', () {
    // An unstacked project still gets the section, so a stack can be started
    // from the project you are already looking at rather than only from a
    // multi-selection in the grid.
    testWidgets('explains how to start a stack', (tester) async {
      await tester.pumpWidget(wrap(const [], onAdd: () {}));

      expect(find.text('Not stacked yet'), findsOneWidget);
      expect(find.text('Add another project file.'), findsOneWidget);
      expect(find.text('Add Version'), findsOneWidget);
    });

    testWidgets('shows no version count', (tester) async {
      await tester.pumpWidget(wrap(const [], onAdd: () {}));

      // "0 versions" next to the heading reads as a broken stack rather than
      // as a project that simply has none.
      expect(find.text('0 versions'), findsNothing);
    });

    testWidgets('offers no member actions', (tester) async {
      await tester.pumpWidget(wrap(const [], onAdd: () {}));

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });
  });
}
