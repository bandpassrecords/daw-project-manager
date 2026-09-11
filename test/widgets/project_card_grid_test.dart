import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/widgets/project_card_grid.dart';

import '../helpers/test_factories.dart';

/// #111 — the dashboard's card view. Like `ProjectVersionsSection` it takes
/// plain values and callbacks instead of a `Ref`, so all of this runs without
/// opening Hive or a localisation delegate.
void main() {
  final labels = ProjectCardLabels(
    emptyMessage: 'No results for current filter',
    selectTooltip: 'Select project',
    missingFileTooltip: 'Source file not found on this machine',
    bpmTooltip: (bpm) => 'BPM: $bpm',
    keyTooltip: (key) => 'Key: $key',
    today: 'Today',
    daysLeft: (d) => '${d}d left',
    daysLate: (d) => '${d}d late',
    launchTooltip: 'Launch in DAW',
    startSessionTooltip: 'Start session',
    endSessionTooltip: 'End session',
    openFolderTooltip: 'Open folder',
    playPreviewTooltip: 'Play preview',
  );

  MusicProject project(
    String id,
    String name, {
    String status = 'Mixing',
    double? bpm,
    String? musicalKey,
    DateTime? deadline,
    bool isVirtual = false,
    String? cardInitials,
    String? previewSongPath,
    String? previewSongAutoPath,
  }) => TestFactories.makeProject(
    id: id,
    customDisplayName: name,
    status: status,
    bpm: bpm,
    musicalKey: musicalKey,
    deadline: deadline,
    isVirtual: isVirtual,
    cardInitials: cardInitials,
    previewSongPath: previewSongPath,
    previewSongAutoPath: previewSongAutoPath,
  );

  Widget wrap(
    List<MusicProject> projects, {
    Set<String> selectedIds = const {},
    String? activeProjectId,
    bool fileExists = true,
    bool modifierHeld = false,
    bool sessionMode = false,
    void Function(MusicProject)? onPrimaryAction,
    void Function(MusicProject)? onOpenFolder,
    void Function(MusicProject)? onPlayPreview,
    void Function(MusicProject)? onOpen,
    void Function(String)? onToggleSelection,
    void Function(String)? onRowClick,
    void Function(String)? onHighlight,
    void Function(MusicProject, Offset)? onContextMenu,
  }) => MaterialApp(
    home: Scaffold(
      body: ProjectCardGrid(
        projects: projects,
        selectedIds: selectedIds,
        activeProjectId: activeProjectId,
        phaseColor: (_) => Colors.purple,
        phaseLabel: (phase) => 'Phase:$phase',
        dateFormat: (d) => '${d.year}-${d.month}',
        fileExists: (_) => fileExists,
        selectionModifierHeld: () => modifierHeld,
        labels: labels,
        onOpen: onOpen ?? (_) {},
        onToggleSelection: onToggleSelection ?? (_) {},
        onRowClick: onRowClick ?? (_) {},
        onHighlight: onHighlight ?? (_) {},
        onContextMenu: onContextMenu ?? (_, _) {},
        sessionMode: sessionMode,
        onPrimaryAction: onPrimaryAction ?? (_) {},
        onOpenFolder: onOpenFolder ?? (_) {},
        onPlayPreview: onPlayPreview ?? (_) {},
      ),
    ),
  );

  testWidgets('renders one card per project, in the order given', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap([
        project('a', 'Night Drive'),
        project('b', 'Sunrise'),
        project('c', 'Third Rail'),
      ]),
    );

    expect(find.text('Night Drive'), findsOneWidget);
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Third Rail'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(3));

    // The widget renders the list verbatim — the filtering and sorting the
    // table does upstream is the only ordering there is.
    final positions = [
      'Night Drive',
      'Sunrise',
      'Third Rail',
    ].map((n) => tester.getTopLeft(find.text(n)).dx).toList();
    expect(positions, orderedEquals([...positions]..sort()));
  });

  testWidgets('shows the empty message instead of an empty grid', (
    tester,
  ) async {
    await tester.pumpWidget(wrap([]));

    expect(find.text('No results for current filter'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('shows phase, initials, BPM and Camelot code', (tester) async {
    await tester.pumpWidget(
      wrap([
        project(
          'a',
          'Night Drive',
          status: 'Mastering',
          bpm: 128,
          musicalKey: 'A minor',
        ),
      ]),
    );

    expect(find.text('Phase:Mastering'), findsOneWidget);
    expect(find.text('ND'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    // A minor is 8A on the Camelot wheel.
    expect(find.text('8A'), findsOneWidget);
  });

  testWidgets('drops the trailing zero on a whole-number BPM', (tester) async {
    await tester.pumpWidget(wrap([project('a', 'Alpha', bpm: 174)]));

    expect(find.text('174'), findsOneWidget);
    expect(find.text('174.0'), findsNothing);
  });

  testWidgets('marks a project whose file is gone', (tester) async {
    await tester.pumpWidget(
      wrap([project('a', 'Night Drive')], fileExists: false),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });

  testWidgets('leaves the missing-file marker off a version stack', (
    tester,
  ) async {
    // A stack's path is the folder its versions live in, so "no file here" is
    // normal rather than a missing file — same rule the grid applies.
    await tester.pumpWidget(
      wrap([project('a', 'Night Drive', isVirtual: true)], fileExists: false),
    );

    expect(find.byIcon(Icons.cloud_off), findsNothing);
    expect(find.byIcon(Icons.layers), findsOneWidget);
  });

  group('deadline chip', () {
    testWidgets('counts down the days left', (tester) async {
      await tester.pumpWidget(
        wrap([
          project(
            'a',
            'Alpha',
            deadline: DateTime.now().add(const Duration(days: 3)),
          ),
        ]),
      );

      expect(find.text('3d left'), findsOneWidget);
    });

    testWidgets('says today on the day', (tester) async {
      await tester.pumpWidget(
        wrap([project('a', 'Alpha', deadline: DateTime.now())]),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.byIcon(Icons.today), findsOneWidget);
    });

    testWidgets('warns once it is overdue', (tester) async {
      await tester.pumpWidget(
        wrap([
          project(
            'a',
            'Alpha',
            deadline: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]),
      );

      expect(find.text('2d late'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('is absent with no deadline', (tester) async {
      await tester.pumpWidget(wrap([project('a', 'Alpha')]));

      expect(find.byIcon(Icons.schedule), findsNothing);
      expect(find.byIcon(Icons.warning), findsNothing);
    });
  });

  group('selection', () {
    testWidgets('the checkbox toggles exactly one project', (tester) async {
      final toggled = <String>[];
      await tester.pumpWidget(
        wrap([
          project('a', 'Alpha'),
          project('b', 'Beta'),
        ], onToggleSelection: toggled.add),
      );

      await tester.tap(find.byType(Checkbox).at(1));
      // The card's own double-tap recognizer keeps the gesture arena open for
      // the double-tap timeout before the checkbox's tap can win it.
      await tester.pump(const Duration(seconds: 1));

      expect(toggled, ['b']);
    });

    testWidgets('reflects the selection it is handed', (tester) async {
      await tester.pumpWidget(
        wrap([project('a', 'Alpha'), project('b', 'Beta')], selectedIds: {'b'}),
      );

      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes[0].value, isFalse);
      expect(boxes[1].value, isTrue);
    });

    testWidgets('a plain click only moves the highlight', (tester) async {
      final highlighted = <String>[];
      final rowClicks = <String>[];
      await tester.pumpWidget(
        wrap(
          [project('a', 'Alpha')],
          onHighlight: highlighted.add,
          onRowClick: rowClicks.add,
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pump(const Duration(seconds: 1));

      expect(highlighted, ['a']);
      expect(rowClicks, isEmpty);
    });

    testWidgets('a modifier-held click goes to the click-selection rules', (
      tester,
    ) async {
      final highlighted = <String>[];
      final rowClicks = <String>[];
      await tester.pumpWidget(
        wrap(
          [project('a', 'Alpha')],
          modifierHeld: true,
          onHighlight: highlighted.add,
          onRowClick: rowClicks.add,
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pump(const Duration(seconds: 1));

      expect(rowClicks, ['a']);
      expect(highlighted, isEmpty);
    });
  });

  testWidgets('double-tap opens the project', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      wrap([project('a', 'Night Drive')], onOpen: (p) => opened.add(p.id)),
    );

    await tester.tap(find.text('Night Drive'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Night Drive'));
    await tester.pump(const Duration(seconds: 1));

    expect(opened, ['a']);
  });

  testWidgets('lays out without overflow from a narrow window to a wide one', (
    tester,
  ) async {
    // The card is the densest thing on the dashboard — name, phase, DAW logo,
    // two badges and a date inside ~200px. A RenderFlex overflow here would
    // be a test failure, which is the point of pinning both extremes.
    final projects = [
      for (var i = 0; i < 8; i++)
        project(
          'p$i',
          'A Rather Long Project Name $i',
          bpm: 128.5,
          musicalKey: 'A minor',
          deadline: DateTime.now().subtract(const Duration(days: 12)),
        ),
    ];

    for (final size in [const Size(420, 500), const Size(1600, 1000)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(wrap(projects));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  group('card label', () {
    testWidgets('falls back to initials derived from the name', (tester) async {
      await tester.pumpWidget(wrap([project('a', 'Night Drive')]));

      expect(find.text('ND'), findsOneWidget);
    });

    testWidgets('shows what the user typed instead', (tester) async {
      await tester.pumpWidget(
        wrap([project('a', 'Night Drive', cardInitials: 'X7')]),
      );

      expect(find.text('X7'), findsOneWidget);
      expect(find.text('ND'), findsNothing);
    });

    testWidgets('a blank override falls back rather than blanking the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap([project('a', 'Night Drive', cardInitials: '   ')]),
      );

      expect(find.text('ND'), findsOneWidget);
    });
  });

  group('action icons', () {
    testWidgets('launch, open folder and play each report their project', (
      tester,
    ) async {
      final launched = <String>[];
      final folders = <String>[];
      final played = <String>[];
      await tester.pumpWidget(
        wrap(
          [project('a', 'Night Drive')],
          onPrimaryAction: (p) => launched.add(p.id),
          onOpenFolder: (p) => folders.add(p.id),
          onPlayPreview: (p) => played.add(p.id),
        ),
      );

      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump(const Duration(seconds: 1));

      expect(launched, ['a']);
      expect(folders, ['a']);
      expect(played, ['a']);
    });

    testWidgets('the launch icon becomes a session bookmark in session mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap([project('a', 'Night Drive')], sessionMode: true),
      );

      expect(find.byIcon(Icons.open_in_new), findsNothing);
      expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);
    });

    testWidgets('and a filled bookmark on the project being tracked', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          [project('a', 'Night Drive')],
          sessionMode: true,
          activeProjectId: 'a',
        ),
      );

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('the play icon says which kind of preview it would play', (
      tester,
    ) async {
      Color playColor(WidgetTester tester) =>
          tester.widget<Icon>(find.byIcon(Icons.play_arrow)).color!;

      await tester.pumpWidget(wrap([project('a', 'A song')]));
      final none = playColor(tester);

      await tester.pumpWidget(
        wrap([project('b', 'A song', previewSongAutoPath: '/tmp/auto.wav')]),
      );
      final auto = playColor(tester);

      await tester.pumpWidget(
        wrap([project('c', 'A song', previewSongPath: '/tmp/manual.wav')]),
      );
      final manual = playColor(tester);

      expect({none, auto, manual}, hasLength(3));
    });
  });

  testWidgets('a long name does not make its card taller than its neighbours', (
    tester,
  ) async {
    // The whole point of the fixed name block: two cards side by side, one
    // with a name that wraps and one that doesn't, still line up.
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrap([
        project('a', 'Short'),
        project(
          'b',
          'An Extremely Long Project Name That Has To Wrap Onto Two Lines',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final cards = tester.widgetList<Card>(find.byType(Card)).toList();
    expect(cards, hasLength(2));
    final sizes = find.byType(Card).evaluate().map((e) => e.size).toList();
    expect(sizes[0], sizes[1]);
  });
  testWidgets('a long press asks for the context menu', (tester) async {
    final menus = <String>[];
    await tester.pumpWidget(
      wrap([
        project('a', 'Night Drive'),
      ], onContextMenu: (p, _) => menus.add(p.id)),
    );

    await tester.longPress(find.text('Night Drive'));
    await tester.pump(const Duration(seconds: 1));

    expect(menus, ['a']);
  });
}
