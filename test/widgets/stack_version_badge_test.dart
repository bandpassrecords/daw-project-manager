import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/stack_version_badge.dart';

void main() {
  Widget host({ThemeData? theme}) => MaterialApp(
        theme: theme ?? ThemeData.dark(),
        home: const Scaffold(
          body: Center(
            child: StackVersionBadge(count: 4, tooltip: '4 versions'),
          ),
        ),
      );

  ShapeDecoration decoration(WidgetTester tester) {
    final box = tester.widget<Container>(find.descendant(
      of: find.byType(StackVersionBadge),
      matching: find.byType(Container),
    ));
    return box.decoration! as ShapeDecoration;
  }

  testWidgets('shows the stack icon and the version count', (tester) async {
    await tester.pumpWidget(host());

    expect(find.byIcon(Icons.layers), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.byTooltip('4 versions'), findsOneWidget);
  });

  // The regression: the badge was primary at 15% alpha, so over a row's
  // cover-art bleed it showed mostly the picture and the number got lost.
  testWidgets('its background is opaque, so artwork cannot show through',
      (tester) async {
    await tester.pumpWidget(host());

    expect(decoration(tester).color!.a, 1.0);
  });

  testWidgets('is outlined, to separate it from a busy thumbnail',
      (tester) async {
    await tester.pumpWidget(host());

    final shape = decoration(tester).shape as StadiumBorder;
    expect(shape.side.style, BorderStyle.solid);
    expect(shape.side.color.a, greaterThan(0));
  });

  group('backgroundFor', () {
    test('is opaque even when the card colour is translucent', () {
      final theme = ThemeData.dark().copyWith(
        cardColor: const Color(0x66202020),
      );
      expect(StackVersionBadge.backgroundFor(theme).a, 1.0);
    });

    test('carries a tint of the theme colour, not plain card grey', () {
      final theme = ThemeData.dark().copyWith(
        cardColor: const Color(0xFF202020),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF)),
      );
      final bg = StackVersionBadge.backgroundFor(theme);

      expect(bg, isNot(const Color(0xFF202020)));
      expect(bg.b, greaterThan(bg.r),
          reason: 'pulled towards the cyan primary');
    });

    test('follows the active theme', () {
      final a = StackVersionBadge.backgroundFor(ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: Color(0xFFFF4081)),
      ));
      final b = StackVersionBadge.backgroundFor(ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00E676)),
      ));
      expect(a, isNot(b));
    });
  });
}
