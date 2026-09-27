import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/scroll_more_hint.dart';

/// Pumps the hint around a list of [itemCount] fixed-height rows inside a
/// [height]-tall box, so "does the content overflow" is decided by arithmetic
/// rather than by guesswork.
Future<ScrollController> _pump(
  WidgetTester tester, {
  required int itemCount,
  double height = 200,
  double itemHeight = 50,
}) async {
  late ScrollController captured;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            height: height,
            child: ScrollMoreHint(
              builder: (context, controller) {
                captured = controller;
                return ListView.builder(
                  controller: controller,
                  itemCount: itemCount,
                  itemBuilder: (_, i) =>
                      SizedBox(height: itemHeight, child: Text('row $i')),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets('hints at once when the content overflows, before any scrolling',
      (tester) async {
    // The case that prompted this: a file sitting just past the fold, with
    // nothing to say the list continues. The hint has to be there on first
    // paint, not after the user has already discovered scrolling.
    await _pump(tester, itemCount: 10);

    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });

  testWidgets('shows no hint when everything already fits', (tester) async {
    await _pump(tester, itemCount: 2);

    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('drops the hint once the end is reached', (tester) async {
    final controller = await _pump(tester, itemCount: 10);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('brings the hint back on scrolling away from the end',
      (tester) async {
    final controller = await _pump(tester, itemCount: 10);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);

    controller.jumpTo(0);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });

  testWidgets('keeps hinting part-way down a long list', (tester) async {
    final controller = await _pump(tester, itemCount: 40);
    controller.jumpTo(300);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });

  testWidgets('shows an always-visible scrollbar rather than a transient one',
      (tester) async {
    await _pump(tester, itemCount: 10);

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isTrue);
  });

  testWidgets('the hint never swallows a tap meant for the content',
      (tester) async {
    // The fade sits over the last visible row; it must not intercept clicks.
    await _pump(tester, itemCount: 10);

    // Several IgnorePointers sit above the icon (Scrollbar and Tooltip add
    // their own, inactive); what matters is that one of them is actually
    // ignoring, so the fade cannot eat a click on the row beneath it.
    final ignoring = tester
        .widgetList<IgnorePointer>(find.ancestor(
          of: find.byIcon(Icons.keyboard_arrow_down),
          matching: find.byType(IgnorePointer),
        ))
        .where((w) => w.ignoring);

    expect(ignoring, hasLength(1));
  });

  testWidgets('an empty list hints at nothing', (tester) async {
    await _pump(tester, itemCount: 0);

    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });
}
