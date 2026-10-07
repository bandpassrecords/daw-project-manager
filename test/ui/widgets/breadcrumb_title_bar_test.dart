import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/widgets/desktop_title_bar.dart';

/// A page whose only content is a title bar, so pushing and popping routes
/// exercises exactly the registration the real pages get for free.
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
