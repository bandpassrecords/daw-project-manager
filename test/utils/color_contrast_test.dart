import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/color_contrast.dart';

/// Backs the theme editor's "low contrast" warning (#148). The known ratios
/// below are the WCAG reference values.
void main() {
  group('contrastRatio', () {
    test('black on white is the 21:1 maximum', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21.0, 0.01));
    });

    test('a color against itself is 1:1', () {
      expect(
        contrastRatio(const Color(0xFF1E1F22), const Color(0xFF1E1F22)),
        closeTo(1.0, 0.001),
      );
    });

    test('order does not matter', () {
      const a = Color(0xFF00D4FF);
      const b = Color(0xFF0A0A14);
      expect(contrastRatio(a, b), closeTo(contrastRatio(b, a), 0.0001));
    });

    test('mid grey on white is the reference 4.6:1', () {
      // #767676 is the canonical "just passes AA on white" grey.
      expect(
        contrastRatio(const Color(0xFF767676), Colors.white),
        closeTo(4.54, 0.05),
      );
    });
  });

  group('meetsWcagAa', () {
    test('white body text on Classic Dark cards passes', () {
      expect(meetsWcagAa(Colors.white, const Color(0xFF2B2D31)), isTrue);
    });

    test('white body text on Neon Dark cards passes', () {
      expect(meetsWcagAa(Colors.white, const Color(0xFF1A1A2E)), isTrue);
    });

    test('a dark accent on a dark background fails body text', () {
      // The shape of mistake the editor warns about.
      expect(
        meetsWcagAa(const Color(0xFF3A3A4A), const Color(0xFF1A1A2E)),
        isFalse,
      );
    });

    test('large text clears the lower 3:1 bar where body text would not', () {
      const fg = Color(0xFF8A8A8A);
      const bg = Colors.white;
      expect(meetsWcagAa(fg, bg), isFalse);
      expect(meetsWcagAa(fg, bg, largeText: true), isTrue);
    });
  });
}
