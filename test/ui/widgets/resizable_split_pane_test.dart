import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/resizable_split_pane.dart';

void main() {
  group('clampSplitFraction', () {
    test('keeps both panes at least the minimum height', () {
      expect(clampSplitFraction(0.99, available: 1000, minPane: 100), 0.9);
      expect(clampSplitFraction(0.01, available: 1000, minPane: 100), 0.1);
      expect(clampSplitFraction(0.6, available: 1000, minPane: 100), 0.6);
    });

    test('splits evenly when two minimum panes do not fit', () {
      expect(clampSplitFraction(0.9, available: 150, minPane: 100), 0.5);
    });

    test('splits evenly for NaN or an unbounded height', () {
      expect(clampSplitFraction(double.nan, available: 1000), 0.5);
      expect(clampSplitFraction(0.7, available: double.infinity), 0.5);
    });
  });

  group('ResizableVerticalSplit', () {
    late List<double> resized;
    late int ended;
    late int resets;

    setUp(() {
      resized = [];
      ended = 0;
      resets = 0;
    });

    Future<void> pump(WidgetTester tester, {double? fraction}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 407, // 400 of panes + the 7 px handle
              child: ResizableVerticalSplit(
                fraction: fraction,
                defaultFraction: 0.5,
                onResize: resized.add,
                onResizeEnd: () => ended++,
                onReset: () => resets++,
                top: const ColoredBox(
                    key: ValueKey('top'), color: Colors.red),
                bottom: const ColoredBox(
                    key: ValueKey('bottom'), color: Colors.blue),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('gives the top pane its share of the height', (tester) async {
      await pump(tester, fraction: 0.6);

      expect(tester.getSize(find.byKey(const ValueKey('top'))).height, 240);
      expect(tester.getSize(find.byKey(const ValueKey('bottom'))).height, 160);
    });

    testWidgets('uses the default until the user has resized', (tester) async {
      await pump(tester);

      expect(tester.getSize(find.byKey(const ValueKey('top'))).height, 200);
    });

    testWidgets('dragging the handle reports the new share, then the end',
        (tester) async {
      await pump(tester, fraction: 0.5);
      final handleCenter = tester.getBottomLeft(find.byKey(const ValueKey('top'))) +
          const Offset(100, ResizableVerticalSplit.handleHeight / 2);

      final gesture = await tester.startGesture(handleCenter);
      await gesture.moveBy(const Offset(0, 60));
      await gesture.up();
      await tester.pump();

      // Let the double-tap recognizer's window run out.
      await tester.pump(const Duration(seconds: 1));

      expect(resized, isNotEmpty);
      expect(resized.last, closeTo(0.65, 0.01));
      expect(ended, 1);
    });

    testWidgets('double-clicking the handle resets', (tester) async {
      await pump(tester, fraction: 0.6);
      final handleCenter = tester.getBottomLeft(find.byKey(const ValueKey('top'))) +
          const Offset(100, ResizableVerticalSplit.handleHeight / 2);

      await tester.tapAt(handleCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(handleCenter);
      await tester.pump(const Duration(seconds: 1));

      expect(resets, 1);
    });
  });
}
