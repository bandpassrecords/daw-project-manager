import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/widgets/desktop_title_bar.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

/// A page whose only content is a title bar, so pushing and popping routes
/// exercises exactly the registration the real pages get for free.
class _FullScreen extends WindowFullScreenNotifier {
  _FullScreen(this.value);
  final bool value;
  @override
  bool build() => value;
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.showBack});

  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [DesktopTitleBar(title: title, showBack: showBack)],
      ),
    );
  }
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    // The Windows/Linux bar, whatever machine runs the tests: macOS draws
    // no title on the root page (see the macOS group below).
    DesktopTitleBar.debugMacOSOverride = false;
  });
  tearDown(() {
    container.dispose();
    DesktopTitleBar.debugMacOSOverride = null;
  });

  List<String> labels() =>
      container.read(breadcrumbTrailProvider).map((c) => c.label).toList();

  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a root page registers one crumb', (tester) async {
    await pumpApp(tester, const _Page(title: 'Home', showBack: false));

    expect(labels(), ['Home']);
  });

  testWidgets('pushing a page extends the trail', (tester) async {
    late BuildContext ctx;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const _Page(title: 'Home', showBack: false);
        },
      ),
    );

    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => const _Page(title: 'Summer EP', showBack: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(labels(), ['Home', 'Summer EP']);
  });

  testWidgets('popping a page shortens the trail again', (tester) async {
    late BuildContext ctx;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const _Page(title: 'Home', showBack: false);
        },
      ),
    );

    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => const _Page(title: 'Summer EP', showBack: true),
      ),
    );
    await tester.pumpAndSettle();
    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();

    expect(labels(), ['Home']);
  });

  testWidgets('a trail of one renders as a plain title, not a crumb', (
    tester,
  ) async {
    await pumpApp(tester, const _Page(title: 'Home', showBack: false));

    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('a deeper trail renders separators between the crumbs', (
    tester,
  ) async {
    late BuildContext ctx;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const _Page(title: 'Home', showBack: false);
        },
      ),
    );

    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => const _Page(title: 'Summer EP', showBack: true),
      ),
    );
    await tester.pumpAndSettle();

    // The pushed page's bar shows the whole path; the covered page's bar is
    // still mounted and shows its own plain title.
    expect(find.text('Summer EP'), findsWidgets);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
  });

  testWidgets('tapping an earlier crumb pops back to it', (tester) async {
    late BuildContext ctx;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const _Page(title: 'Home', showBack: false);
        },
      ),
    );

    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => const _Page(title: 'Summer EP', showBack: true),
      ),
    );
    await tester.pumpAndSettle();
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => const _Page(title: 'Parts', showBack: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(labels(), ['Home', 'Summer EP', 'Parts']);

    // The root crumb renders as "Home" whatever the root page's own title is;
    // tapping it should unwind both pushes in one go.
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();

    expect(labels(), ['Home']);
  });

  testWidgets('the way back to the start carries a house, no other crumb does', (
    tester,
  ) async {
    late BuildContext ctx;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const _Page(title: 'Home', showBack: false);
        },
      ),
    );
    // A trail of one is the plain title: nothing to go back to, no house.
    expect(find.byIcon(Icons.home_outlined), findsNothing);

    for (final title in ['Summer EP', 'Parts']) {
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => _Page(title: title, showBack: true),
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(labels(), ['Home'], reason: 'the house unwinds every page at once');
  });

  testWidgets('a page renamed while open updates its crumb in place', (
    tester,
  ) async {
    await pumpApp(tester, const _Page(title: 'Untitled', showBack: false));
    expect(labels(), ['Untitled']);

    await pumpApp(tester, const _Page(title: 'Summer EP', showBack: false));

    expect(labels(), ['Summer EP']);
  });

  group('macOS', () {
    setUp(() => DesktopTitleBar.debugMacOSOverride = true);

    testWidgets('the root page leaves the title to the window', (tester) async {
      await pumpApp(tester, const _Page(title: 'Home', showBack: false));

      expect(find.text('Home'), findsNothing);
      expect(labels(), ['Home'], reason: "it is still the trail's root");
    });

    testWidgets('the root bar fits where the width is unbounded', (
      tester,
    ) async {
      // The dashboard puts it in a NavigationRail's leading, which a Row
      // hands unbounded width. An infinitely wide strip threw there.
      await pumpApp(
        tester,
        Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: 0,
                leading: const DesktopTitleBar(title: 'Home'),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('A'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.star),
                    label: Text('B'),
                  ),
                ],
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(labels(), ['Home'], reason: 'and it still registers the root');
    });

    testWidgets('a pushed page shows its back button and the trail', (
      tester,
    ) async {
      late BuildContext ctx;
      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const _Page(title: 'Home', showBack: false);
          },
        ),
      );
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => const _Page(title: 'Summer EP', showBack: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Summer EP'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('macOS full screen', () {
    setUp(() => DesktopTitleBar.debugMacOSOverride = true);

    test('the traffic lights\' room is given back', () {
      expect(macTrafficLightInset(fullScreen: false), 75);
      expect(macTrafficLightInset(fullScreen: true), 0);
      expect(macTrafficLightStrip(fullScreen: false), 28);
      expect(macTrafficLightStrip(fullScreen: true), 0);
    });

    Future<double> backButtonLeft(WidgetTester tester, bool fullScreen) async {
      container.dispose();
      container = ProviderContainer(overrides: [
        windowFullScreenProvider.overrideWith(() => _FullScreen(fullScreen)),
      ]);
      await pumpApp(tester, const _Page(title: 'Summer EP', showBack: true));
      return tester.getTopLeft(find.byIcon(Icons.arrow_back)).dx;
    }

    testWidgets('the back button moves to the edge in full screen', (
      tester,
    ) async {
      final windowed = await backButtonLeft(tester, false);
      final full = await backButtonLeft(tester, true);

      expect(windowed - full, 75);
    });
  });

  // Regression: a title bar removes its crumb in a post-frame callback,
  // which can run after its container is disposed (a failed test's
  // teardown); that threw into whichever test ran next.
  test('the trail ignores writes once its container is gone', () {
    final gone = ProviderContainer();
    final trail = gone.read(breadcrumbTrailProvider.notifier);
    gone.dispose();
    expect(() => trail.remove('x'), returnsNormally);
    expect(
      () => trail.push(const Breadcrumb(id: 'x', label: 'X', isRoot: true)),
      returnsNormally,
    );
  });
}
