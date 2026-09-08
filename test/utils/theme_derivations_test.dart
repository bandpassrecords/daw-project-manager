import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/custom_theme.dart';
import 'package:daw_project_manager/providers/theme_provider.dart';
import 'package:daw_project_manager/utils/theme_derivations.dart';

/// The grid chrome used to be chosen with `themeType == AppThemeType.neonDark`
/// at four call sites, which lumped every user theme in with Classic Dark.
/// These pin the replacement (#148): the built-ins must land on exactly the
/// colors they had, and a user theme must be judged on its own accent.
void main() {
  CustomTheme userTheme({required Color primary}) => CustomTheme(
        id: 'mine',
        name: 'Mine',
        brightness: Brightness.dark,
        primary: primary,
        background: const Color(0xFF0B0B10),
        card: const Color(0xFF181820),
        updatedAt: DateTime(2026, 1, 1),
      );

  group('hasVividAccent', () {
    test('Neon Dark is vivid', () {
      expect(AppThemes.neonDarkSpec.hasVividAccent, isTrue);
    });

    test('Classic Dark is not — its primary is a muted gray-blue', () {
      expect(AppThemes.classicDarkSpec.hasVividAccent, isFalse);
    });

    test('a user theme with a saturated accent is treated as vivid', () {
      expect(userTheme(primary: const Color(0xFFEC407A)).hasVividAccent,
          isTrue);
    });

    test('a user theme with a washed-out accent is not', () {
      expect(userTheme(primary: const Color(0xFF6B7078)).hasVividAccent,
          isFalse);
    });
  });

  group('built-in grid colors are unchanged by the refactor', () {
    test('Neon Dark tints the selected row with its accent', () {
      expect(
        AppThemes.neonDarkSpec.gridRowSelectColor,
        AppThemes.neonDarkSpec.primary.withValues(alpha: 0.18),
      );
    });

    test('Classic Dark falls back to white, which actually contrasts', () {
      expect(
        AppThemes.classicDarkSpec.gridRowSelectColor,
        Colors.white.withValues(alpha: 0.14),
      );
    });

    test('Neon Dark stripes background against card', () {
      expect(AppThemes.neonDarkSpec.gridRowOddColor,
          AppThemes.neonDarkSpec.background);
      expect(AppThemes.neonDarkSpec.gridRowEvenColor,
          AppThemes.neonDarkSpec.card);
    });

    test('Classic Dark stripes card against a slightly lifted card', () {
      expect(AppThemes.classicDarkSpec.gridRowOddColor,
          AppThemes.classicDarkSpec.card);
      expect(
        AppThemes.classicDarkSpec.gridRowEvenColor,
        Color.alphaBlend(
          Colors.white.withValues(alpha: 0.05),
          AppThemes.classicDarkSpec.card,
        ),
      );
    });

    test('a muted theme gets a faded grid border, a vivid one the full one',
        () {
      const divider = Color(0xFF3C3F43);
      expect(AppThemes.neonDarkSpec.gridBorderColor(divider), divider);
      expect(
        AppThemes.classicDarkSpec.gridBorderColor(divider),
        divider.withValues(alpha: 0.25),
      );
    });
  });

  group('identityKey', () {
    test('changes when a theme is edited in place', () {
      // TrinaGrid caches renderer colors, so keying only on the id would
      // leave the old palette on screen after an edit.
      final before = userTheme(primary: const Color(0xFFEC407A));
      final after = before.copyWith(updatedAt: DateTime(2026, 2, 1));

      expect(before.id, after.id);
      expect(before.identityKey, isNot(after.identityKey));
    });

    test('is stable for a built-in, which never changes', () {
      expect(AppThemes.neonDarkSpec.identityKey,
          AppThemes.neonDarkSpec.identityKey);
      expect(AppThemes.neonDarkSpec.identityKey,
          isNot(AppThemes.classicDarkSpec.identityKey));
    });
  });
}
