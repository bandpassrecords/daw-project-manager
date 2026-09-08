import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/theme_provider.dart';

/// Phase-1 regression guard for the custom-themes refactor (#148).
///
/// The three built-in themes used to be three hand-written [ThemeData]
/// getters. They are now specs fed through [AppThemes.buildFrom]. This file
/// keeps a verbatim copy of the originals and asserts the new builder still
/// produces the same thing, so the refactor cannot quietly restyle the app.
///
/// Known, deliberate deviation: `studioLight.textTheme.bodySmall` moves from
/// 0xFF5C5470 to 0xFF3C3643. The original light theme was the only one of the
/// three that dropped bodySmall a tone below titleSmall; the shared builder
/// keeps bodySmall on the secondary tone like both dark themes do.
/// studioLight is hidden from every menu and switcher (see CLAUDE.md), so
/// nothing user-reachable changes. Asserted explicitly below so it stays a
/// decision rather than a surprise.
/// Compares the pieces of [ThemeData] the app actually sets, one at a time,
/// so a failure names the component that drifted instead of just saying two
/// ThemeData objects differ.
void expectSameStyling(ThemeData built, ThemeData original) {
  expect(built.colorScheme, original.colorScheme, reason: 'colorScheme');
  expect(built.scaffoldBackgroundColor, original.scaffoldBackgroundColor,
      reason: 'scaffoldBackgroundColor');
  expect(built.canvasColor, original.canvasColor, reason: 'canvasColor');
  expect(built.cardColor, original.cardColor, reason: 'cardColor');
  expect(built.cardTheme, original.cardTheme, reason: 'cardTheme');
  expect(built.appBarTheme, original.appBarTheme, reason: 'appBarTheme');
  expect(built.dividerColor, original.dividerColor, reason: 'dividerColor');
  expect(built.textButtonTheme, original.textButtonTheme,
      reason: 'textButtonTheme');
  expect(built.elevatedButtonTheme, original.elevatedButtonTheme,
      reason: 'elevatedButtonTheme');
  expect(built.outlinedButtonTheme, original.outlinedButtonTheme,
      reason: 'outlinedButtonTheme');
  expect(built.inputDecorationTheme, original.inputDecorationTheme,
      reason: 'inputDecorationTheme');
  expect(built.chipTheme, original.chipTheme, reason: 'chipTheme');
  expect(built.dialogTheme, original.dialogTheme, reason: 'dialogTheme');
  expect(built.snackBarTheme, original.snackBarTheme, reason: 'snackBarTheme');
  expect(built.useMaterial3, original.useMaterial3, reason: 'useMaterial3');
  expect(built.brightness, original.brightness, reason: 'brightness');
}

void main() {
  group('AppThemes.buildFrom reproduces the original built-in themes', () {
    test('neonDark is unchanged', () {
      expectSameStyling(AppThemes.neonDarkTheme, _OriginalThemes.neonDarkTheme);
      expect(
        AppThemes.neonDarkTheme.textTheme,
        _OriginalThemes.neonDarkTheme.textTheme,
      );
    });

    test('classicDark is unchanged', () {
      expectSameStyling(
          AppThemes.classicDarkTheme, _OriginalThemes.classicDarkTheme);
      expect(
        AppThemes.classicDarkTheme.textTheme,
        _OriginalThemes.classicDarkTheme.textTheme,
      );
    });

    test('studioLight is unchanged apart from the documented bodySmall tone',
        () {
      final built = AppThemes.studioLightTheme;
      final original = _OriginalThemes.studioLightTheme;

      expectSameStyling(built, original);

      expect(
        built.textTheme.copyWith(bodySmall: original.textTheme.bodySmall),
        original.textTheme,
      );
      expect(built.textTheme.bodySmall?.color, const Color(0xFF3C3643));
    });
  });

  group('built-in specs carry the colors the originals hardcoded', () {
    test('neonDark', () {
      expect(AppThemes.neonDarkSpec.primary, const Color(0xFF00D4FF));
      expect(AppThemes.neonDarkSpec.background, const Color(0xFF0A0A14));
      expect(AppThemes.neonDarkSpec.card, const Color(0xFF1A1A2E));
      expect(AppThemes.neonDarkSpec.isBuiltIn, isTrue);
    });

    test('classicDark', () {
      expect(AppThemes.classicDarkSpec.primary, const Color(0xFF5A6B7A));
      expect(AppThemes.classicDarkSpec.background, const Color(0xFF1E1F22));
      expect(AppThemes.classicDarkSpec.card, const Color(0xFF2B2D31));
      expect(AppThemes.classicDarkSpec.isBuiltIn, isTrue);
    });

    test('studioLight is a built-in but never offered in the UI', () {
      expect(
        AppThemes.allBuiltIns.map((t) => t.id),
        containsAll(<String>['neonDark', 'classicDark', 'studioLight']),
      );
      expect(
        AppThemes.visibleBuiltIns.map((t) => t.id),
        isNot(contains('studioLight')),
      );
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Verbatim copy of the pre-refactor themes. Do not "clean this up" — its
// only job is to be the code that shipped.
// ─────────────────────────────────────────────────────────────────────────

class _OriginalThemes {
  // Dark Theme - Neon Dark (Current Modern Theme)
  static ThemeData get neonDarkTheme {
    const primaryColor = Color(0xFF00D4FF); // Cyan accent
    const secondaryColor = Color(0xFF7B2CBF); // Purple accent
    const surfaceColor = Color(0xFF0F0F1E);
    const cardColor = Color(0xFF1A1A2E);
    const backgroundColor = Color(0xFF0A0A14);

    final darkScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      onSurface: Colors.white,
      onPrimary: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: cardColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: Colors.white.withValues(alpha: 0.1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white70),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white70),
        labelSmall: TextStyle(color: Colors.white60),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Studio Light Theme - Warm light theme
  static ThemeData get studioLightTheme {
    const primaryColor = Color(0xFF6D28D9);   // deep violet
    const secondaryColor = Color(0xFFD97706); // warm amber
    const surfaceColor = Color(0xFFFAF7F2);   // warm off-white surface
    const cardColor = Color(0xFFFFFFFF);      // white cards
    const backgroundColor = Color(0xFFF8F4EE); // warm cream background

    final lightScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      onSurface: const Color(0xFF1C1B1F),
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: cardColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: Color(0xFF1C1B1F),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: Colors.black.withValues(alpha: 0.1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF1C1B1F), fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFF1C1B1F), fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFF1C1B1F), fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Color(0xFF1C1B1F), fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Color(0xFF1C1B1F), fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Color(0xFF1C1B1F), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Color(0xFF1C1B1F)),
        titleSmall: TextStyle(color: Color(0xFF3C3643)),
        bodyLarge: TextStyle(color: Color(0xFF1C1B1F)),
        bodyMedium: TextStyle(color: Color(0xFF1C1B1F)),
        bodySmall: TextStyle(color: Color(0xFF5C5470)),
        labelLarge: TextStyle(color: Color(0xFF1C1B1F)),
        labelMedium: TextStyle(color: Color(0xFF3C3643)),
        labelSmall: TextStyle(color: Color(0xFF5C5470)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: Color(0xFF1C1B1F)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C1B1F),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Classic Dark Theme - Original Theme
  static ThemeData get classicDarkTheme {
    const primaryColor = Color(0xFF5A6B7A); // Original gray-blue
    const backgroundColor = Color(0xFF1E1F22);
    const cardColor = Color(0xFF2B2D31);
    const dividerColor = Color(0xFF3C3F43);

    final darkScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      surface: cardColor,
      onSurface: Colors.white,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: cardColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: dividerColor,
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white70),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white70),
        labelSmall: TextStyle(color: Colors.white60),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: dividerColor, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor.withValues(alpha: 0.3),
        labelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: dividerColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
