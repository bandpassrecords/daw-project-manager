import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/on_art_marker.dart';

/// Markers in the projects grid's Name cell sit over a row's cover-art bleed.
/// Translucent or bare, they disappeared into a busy cover — including the
/// orange "file not found" warning.
void main() {
  final theme = ThemeData.dark().copyWith(
    cardColor: const Color(0xFF1E1E1E),
  );

  Widget host(Widget child) => MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: child)),
      );

  BoxDecoration? discOf(WidgetTester tester) {
    final boxes = tester.widgetList<Container>(find.descendant(
      of: find.byType(OnArtMarker),
      matching: find.byType(Container),
    ));
    return boxes.isEmpty ? null : boxes.single.decoration as BoxDecoration?;
  }

  group('OnArtMarker', () {
    testWidgets('over artwork the icon sits in an opaque disc',
        (tester) async {
      await tester.pumpWidget(host(OnArtMarker(
        icon: Icons.cloud_off,
        color: Colors.orange.shade400,
        onArt: true,
      )));

      final disc = discOf(tester)!;
      expect(disc.shape, BoxShape.circle);
      expect(disc.color!.a, 1.0, reason: 'the cover must not show through');
      expect(disc.border, isNotNull);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('on a plain row it stays a bare icon', (tester) async {
      await tester.pumpWidget(host(const OnArtMarker(
        icon: Icons.archive_outlined,
        color: Colors.blueGrey,
        onArt: false,
      )));

      expect(discOf(tester), isNull);
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    });

    testWidgets('keeps the icon its own colour and size', (tester) async {
      await tester.pumpWidget(host(OnArtMarker(
        icon: Icons.notes,
        color: Colors.amber.shade600,
        onArt: true,
      )));

      final icon = tester.widget<Icon>(find.byIcon(Icons.notes));
      expect(icon.color, Colors.amber.shade600);
      expect(icon.size, 14);
    });
  });

  group('onArtFill', () {
    test('is opaque even over a translucent card colour', () {
      final seeThrough = theme.copyWith(cardColor: const Color(0x55202020));
      expect(onArtFill(seeThrough, Colors.green).a, 1.0);
    });

    test('carries the marker colour', () {
      final fill = onArtFill(theme, const Color(0xFF00FF00));
      expect(fill.g, greaterThan(fill.r));
    });
  });

  group('onArtCapsule', () {
    test('an opaque capsule with an outline in the marker colour', () {
      final capsule = onArtCapsule(theme, Colors.green);
      expect(capsule.color!.a, 1.0);
      final side = (capsule.shape as StadiumBorder).side;
      expect(side.color.g, greaterThan(side.color.r));
    });
  });

  group('onArtTextHalo', () {
    test('is an opaque halo in the card colour', () {
      final halo = onArtTextHalo(theme);
      expect(halo, isNotEmpty);
      for (final shadow in halo) {
        expect(shadow.offset, Offset.zero);
        expect(shadow.color, theme.cardColor.withValues(alpha: 1));
      }
    });
  });
}
