import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/section_nav_rail.dart';
import 'package:daw_project_manager/utils/section_rail_width.dart';

/// #104 — the rail was lifted out of the settings page so the project detail
/// page could use the same one. These pin the behaviour both pages rely on,
/// including the search box being optional (the detail page has nothing to
/// search).
void main() {
  const items = [
    SectionNavItem(icon: Icons.tune_outlined, label: 'Details'),
    SectionNavItem(icon: Icons.notes_outlined, label: 'Notes'),
    SectionNavItem(
      icon: Icons.history_outlined,
      label: 'Work Sessions',
      newGroup: true,
    ),
  ];

  Widget wrap({
    int activeIndex = 0,
    ValueChanged<int>? onTap,
    TextEditingController? searchController,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 500,
            child: SectionNavRail(
              items: items,
              activeIndex: activeIndex,
              onTap: onTap ?? (_) {},
              searchController: searchController,
              searchHint: searchController == null ? null : 'Search',
            ),
          ),
        ),
      );

  testWidgets('lists every section', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Work Sessions'), findsOneWidget);
  });

  testWidgets('reports the index that was tapped', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(wrap(onTap: taps.add));

    await tester.tap(find.text('Notes'));
    await tester.pump();

    expect(taps, [1]);
  });

  testWidgets('marks the active section', (tester) async {
    await tester.pumpWidget(wrap(activeIndex: 1));

    final active = tester.widget<Text>(find.text('Notes'));
    final inactive = tester.widget<Text>(find.text('Details'));

    expect(active.style?.fontWeight, FontWeight.w600);
    expect(inactive.style?.fontWeight, FontWeight.normal);
  });

  testWidgets('draws a divider above an item that starts a group',
      (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.byType(Divider), findsOneWidget);
  });

  group('search box', () {
    testWidgets('is absent when no controller is given', (tester) async {
      // The project detail page has nothing to search across.
      await tester.pumpWidget(wrap());

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('appears when a controller is given', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrap(searchController: controller));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('a running search deselects every section', (tester) async {
      // While results from all sections are showing, none of them is "the
      // current one".
      final controller = TextEditingController(text: 'theme');
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrap(activeIndex: 0, searchController: controller));

      final first = tester.widget<Text>(find.text('Details'));
      expect(first.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('the clear button empties the field', (tester) async {
      final controller = TextEditingController(text: 'theme');
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrap(searchController: controller));
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(controller.text, isEmpty);
    });
  });

  group('labels', () {
    // A long translation used to wrap onto a second line, making that row
    // taller than the rest.
    const long = 'Vista previa de la canción y marcadores del proyecto';

    Widget narrow() => const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 300,
              child: SectionNavRail(
                items: [
                  SectionNavItem(icon: Icons.music_note, label: long),
                  SectionNavItem(icon: Icons.notes, label: 'Notas'),
                ],
                activeIndex: 0,
                onTap: _ignore,
              ),
            ),
          ),
        );

    testWidgets('a long label stays on one line', (tester) async {
      await tester.pumpWidget(narrow());

      final text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('a cut label shows the full text on hover', (tester) async {
      await tester.pumpWidget(narrow());

      expect(find.byTooltip(long), findsOneWidget);
    });

    testWidgets('a label that fits gets no tooltip', (tester) async {
      await tester.pumpWidget(narrow());

      expect(find.byTooltip('Notas'), findsNothing);
    });
  });

  group('ResizableRailLayout', () {
    late List<double> resizes;
    late int ends;
    late int resets;

    setUp(() {
      resizes = [];
      ends = 0;
      resets = 0;
    });

    Future<void> pumpLayout(
      WidgetTester tester, {
      double? width,
      double defaultWidth = 200,
      double windowWidth = 1200,
    }) async {
      tester.view.physicalSize = Size(windowWidth, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ResizableRailLayout(
            width: width,
            defaultWidth: defaultWidth,
            onResize: resizes.add,
            onResizeEnd: () => ends++,
            onReset: () => resets++,
            handleTooltip: 'Drag to resize',
            rail: const ColoredBox(
                key: ValueKey('rail'), color: Color(0xFF000000)),
            child: const ColoredBox(
                key: ValueKey('content'), color: Color(0xFFFFFFFF)),
          ),
        ),
      ));
      await tester.pump();
    }

    double railWidth(WidgetTester tester) =>
        tester.getSize(find.byKey(const ValueKey('rail'))).width;

    Finder handle() => find.byWidgetPredicate((w) =>
        w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn);

    testWidgets('uses the page default until the user resizes',
        (tester) async {
      await pumpLayout(tester, defaultWidth: 240);
      expect(railWidth(tester), 240);
    });

    testWidgets('uses the width the user chose', (tester) async {
      await pumpLayout(tester, width: 320);
      expect(railWidth(tester), 320);
    });

    testWidgets('clamps a saved width to the window it opens in',
        (tester) async {
      // Saved on a big monitor, opened in a 500px window: the rail may take
      // at most half, so the content keeps room.
      await pumpLayout(tester, width: 400, windowWidth: 500);
      expect(railWidth(tester), 250);
    });

    testWidgets('the content takes the rest of the row', (tester) async {
      await pumpLayout(tester, width: 300);
      expect(
        tester.getSize(find.byKey(const ValueKey('content'))).width,
        1200 - 300 - ResizableRailLayout.handleWidth,
      );
    });

    testWidgets('shows a resize cursor on the handle', (tester) async {
      await pumpLayout(tester);
      expect(handle(), findsOneWidget);
    });

    testWidgets('dragging reports the new width, then the end of the drag',
        (tester) async {
      await pumpLayout(tester, width: 200);

      await tester.drag(handle(), const Offset(60, 0));
      // Let the double-click window and tooltip delay run out.
      await tester.pump(const Duration(seconds: 1));

      expect(resizes, isNotEmpty);
      expect(resizes.last, closeTo(260, 0.5));
      expect(ends, 1);
    });

    testWidgets('dragging past the limits stops at them', (tester) async {
      await pumpLayout(tester, width: 200);

      await tester.drag(handle(), const Offset(-500, 0));
      // Let the double-click window and tooltip delay run out.
      await tester.pump(const Duration(seconds: 1));
      expect(resizes.last, kSectionRailMinWidth);

      await tester.drag(handle(), const Offset(2000, 0));
      // Let the double-click window and tooltip delay run out.
      await tester.pump(const Duration(seconds: 1));
      expect(resizes.last, kSectionRailMaxWidth);
    });

    testWidgets('double-clicking the handle resets the width', (tester) async {
      await pumpLayout(tester, width: 300);

      final center = tester.getCenter(handle());
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      expect(resets, 1);
    });
  });
}

void _ignore(int _) {}
