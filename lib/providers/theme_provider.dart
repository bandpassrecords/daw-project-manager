import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/custom_theme.dart';
import '../utils/app_paths.dart';

/// The themes that ship with the app.
///
/// Kept as an enum because their ids are persisted (`settings['theme']` stores
/// `AppThemeType.name`) and because several call sites still want to talk
/// about a specific built-in. User themes are identified by uuid instead —
/// see [selectedThemeIdProvider].
enum AppThemeType {
  neonDark, // Current modern dark theme
  classicDark, // Original dark theme
  studioLight, // Warm light theme
}

/// Theme definitions and the single [ThemeData] builder they all go through.
class AppThemes {
  AppThemes._();

  // ── Built-in specs ─────────────────────────────────────────────────────
  //
  // These were three hand-written ThemeData getters before custom themes
  // existed. They are now specs fed through [buildFrom], which is what makes
  // a user theme style every widget the built-ins do instead of falling back
  // to raw Material defaults for whatever a second builder forgot.
  //
  // `final` rather than `const` because Color.withValues() isn't const, and
  // the exact alpha matters: Color(0x1AFFFFFF) and
  // Colors.white.withValues(alpha: 0.1) are *not* equal under Flutter's
  // floating-point Color.

  static final CustomTheme neonDarkSpec = CustomTheme(
    id: 'neonDark',
    isBuiltIn: true,
    brightness: Brightness.dark,
    primary: const Color(0xFF00D4FF), // Cyan accent
    secondary: const Color(0xFF7B2CBF), // Purple accent
    background: const Color(0xFF0A0A14),
    card: const Color(0xFF1A1A2E),
    surface: const Color(0xFF0F0F1E),
    onSurface: Colors.white,
    onPrimary: Colors.black,
    textSecondary: Colors.white70,
    textTertiary: Colors.white60,
    cardRadius: 16,
    controlRadius: 12,
    // inputBorder and chipBorder fall out of the white-on-dark defaults at
    // exactly the alphas this theme used. divider and cardBorder don't:
    // null cardBorder means "no outline", and the divider default is now an
    // opaque blend (see CustomTheme.resolvedDivider), so Neon Dark's
    // translucent white one has to be spelled out to stay as it shipped.
    divider: Colors.white.withValues(alpha: 0.1),
    cardBorder: Colors.white.withValues(alpha: 0.1),
  );

  static final CustomTheme classicDarkSpec = CustomTheme(
    id: 'classicDark',
    isBuiltIn: true,
    brightness: Brightness.dark,
    primary: const Color(0xFF5A6B7A), // Original gray-blue
    background: const Color(0xFF1E1F22),
    card: const Color(0xFF2B2D31),
    onSurface: Colors.white,
    onPrimary: Colors.white,
    textSecondary: Colors.white70,
    textTertiary: Colors.white60,
    cardRadius: 8,
    controlRadius: 8,
    accentStyle: ThemeAccentStyle.muted,
    divider: const Color(0xFF3C3F43),
    inputBorder: const Color(0xFF3C3F43),
    // No card outline in Classic Dark.
    cardBorder: null,
    chipBorder: const Color(0xFF3C3F43),
    chipSelectedAlpha: 0.3,
  );

  static final CustomTheme studioLightSpec = CustomTheme(
    id: 'studioLight',
    isBuiltIn: true,
    brightness: Brightness.light,
    primary: const Color(0xFF6D28D9), // deep violet
    secondary: const Color(0xFFD97706), // warm amber
    background: const Color(0xFFF8F4EE), // warm cream background
    card: const Color(0xFFFFFFFF), // white cards
    surface: const Color(0xFFFAF7F2), // warm off-white surface
    onSurface: const Color(0xFF1C1B1F),
    onPrimary: Colors.white,
    textSecondary: const Color(0xFF3C3643),
    textTertiary: const Color(0xFF5C5470),
    cardRadius: 16,
    controlRadius: 12,
    divider: Colors.black.withValues(alpha: 0.1),
    inputBorder: Colors.black.withValues(alpha: 0.15),
    cardBorder: Colors.black.withValues(alpha: 0.08),
    chipBackground: const Color(0xFFF8F4EE),
    chipBorder: Colors.black.withValues(alpha: 0.12),
    chipSelectedAlpha: 0.15,
    snackBarBackground: const Color(0xFF1C1B1F),
  );

  static CustomTheme specFor(AppThemeType type) => switch (type) {
        AppThemeType.neonDark => neonDarkSpec,
        AppThemeType.classicDark => classicDarkSpec,
        AppThemeType.studioLight => studioLightSpec,
      };

  /// Every built-in, including hidden ones. Used for id resolution, so a
  /// `settings['theme']` of `studioLight` persisted by an older build still
  /// resolves instead of silently falling back.
  static List<CustomTheme> get allBuiltIns =>
      [classicDarkSpec, neonDarkSpec, studioLightSpec];

  /// Built-ins offered in the UI.
  ///
  /// `studioLight` is deliberately excluded — it stays out of every menu,
  /// switcher and picker until it is ready (see CLAUDE.md).
  static List<CustomTheme> get visibleBuiltIns =>
      [classicDarkSpec, neonDarkSpec];

  /// The theme used whenever a stored id names nothing we know about.
  static CustomTheme get fallbackSpec => classicDarkSpec;

  // ── The one ThemeData builder ──────────────────────────────────────────

  /// Builds the [ThemeData] for [spec].
  ///
  /// Every visual decision the app makes lives here. Adding a component theme
  /// here gives it to the built-ins and to every user theme at once.
  static ThemeData buildFrom(CustomTheme spec) {
    final strong = spec.resolvedOnSurface;
    final secondary = spec.resolvedTextSecondary;
    final tertiary = spec.resolvedTextTertiary;
    final vivid = spec.accentStyle == ThemeAccentStyle.vivid;

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(spec.controlRadius),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: spec.primary,
      brightness: spec.brightness,
      primary: spec.primary,
      secondary: spec.secondary,
      surface: spec.resolvedSurface,
      onSurface: strong,
      onPrimary: spec.resolvedOnPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: spec.background,
      canvasColor: spec.background,
      cardColor: spec.card,
      cardTheme: CardThemeData(
        color: spec.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spec.cardRadius),
          side: spec.cardBorder == null
              ? BorderSide.none
              : BorderSide(color: spec.cardBorder!, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: spec.card,
        foregroundColor: strong,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: spec.resolvedDivider,
      // bodySmall intentionally shares the `secondary` tone with titleSmall
      // and labelMedium; only labelSmall drops to `tertiary`.
      textTheme: TextTheme(
        displayLarge: TextStyle(color: strong, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: strong, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: strong, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: strong, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: strong, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: strong, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: strong),
        titleSmall: TextStyle(color: secondary),
        bodyLarge: TextStyle(color: strong),
        bodyMedium: TextStyle(color: strong),
        bodySmall: TextStyle(color: secondary),
        labelLarge: TextStyle(color: strong),
        labelMedium: TextStyle(color: secondary),
        labelSmall: TextStyle(color: tertiary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: vivid ? spec.primary : secondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: vivid ? controlShape : null,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: spec.primary,
          foregroundColor: spec.resolvedOnPrimary,
          elevation: vivid ? 0 : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: vivid ? controlShape : null,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: vivid ? spec.primary : secondary,
          side: vivid
              ? BorderSide(color: spec.primary, width: 1.5)
              : BorderSide(color: spec.resolvedDivider, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: vivid ? controlShape : null,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: spec.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spec.controlRadius),
          borderSide: BorderSide(color: spec.resolvedInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spec.controlRadius),
          borderSide: BorderSide(color: spec.resolvedInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spec.controlRadius),
          borderSide: BorderSide(color: spec.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: spec.resolvedChipBackground,
        selectedColor: spec.primary.withValues(alpha: spec.chipSelectedAlpha),
        labelStyle: TextStyle(color: strong),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: spec.resolvedChipBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: spec.card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spec.cardRadius + 4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: spec.resolvedSnackBarBackground,
        contentTextStyle: TextStyle(color: spec.resolvedSnackBarForeground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spec.controlRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get neonDarkTheme => buildFrom(neonDarkSpec);
  static ThemeData get classicDarkTheme => buildFrom(classicDarkSpec);
  static ThemeData get studioLightTheme => buildFrom(studioLightSpec);
}

/// Resolves a stored theme id against the built-ins and [custom].
///
/// Falls back to Classic Dark for anything unrecognised. That is not just
/// defensive: Drive sync deliberately does not sync the *selected* theme, so
/// a library restored onto a second device can easily carry a `customThemes`
/// list that doesn't contain whatever this device had selected.
CustomTheme resolveTheme(String id, List<CustomTheme> custom) {
  for (final builtIn in AppThemes.allBuiltIns) {
    if (builtIn.id == id) return builtIn;
  }
  for (final theme in custom) {
    if (theme.id == id) return theme;
  }
  return AppThemes.fallbackSpec;
}

// ── User themes ──────────────────────────────────────────────────────────

/// User-defined themes, persisted as a JSON array in the `app_settings` box.
///
/// Stored the same way as `phaseColors` and `customMixdownFolders`: a global
/// (non-per-profile) JSON string, which is what lets `BackupService` and
/// `GoogleDriveSyncService` pick them up alongside those.
class CustomThemesNotifier extends Notifier<List<CustomTheme>> {
  static const String boxName = 'app_settings';
  static const String storageKey = 'customThemes';

  @override
  List<CustomTheme> build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return const [];
  }

  /// Parses the stored JSON array, skipping any entry that can't be read
  /// rather than losing the whole list to one bad theme.
  @visibleForTesting
  static List<CustomTheme> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final themes = <CustomTheme>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        try {
          themes.add(CustomTheme.fromJson(Map<String, dynamic>.from(entry)));
        } catch (_) {
          // Skip an unreadable theme, keep the rest.
        }
      }
      return themes;
    } catch (_) {
      return const [];
    }
  }

  @visibleForTesting
  static String encode(List<CustomTheme> themes) =>
      jsonEncode(themes.map((t) => t.toJson()).toList());

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>(boxName);
      final loaded = decode(box.get(storageKey));
      if (loaded.isNotEmpty) state = loaded;
    } catch (_) {
      // Keep the empty list if loading fails.
    }
  }

  Future<void> _persist(List<CustomTheme> themes) async {
    state = themes;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>(boxName);
      await box.put(storageKey, encode(themes));
    } catch (e) {
      if (kDebugMode) print('Failed to save custom themes: $e');
    }
  }

  /// Adds [theme], or replaces the existing one with the same id.
  Future<void> upsert(CustomTheme theme) async {
    final stamped = theme.copyWith(updatedAt: DateTime.now());
    final next = [...state];
    final index = next.indexWhere((t) => t.id == theme.id);
    if (index >= 0) {
      next[index] = stamped;
    } else {
      next.add(stamped);
    }
    await _persist(next);
  }

  /// Removes the theme with [id], and moves the selection off it if it was
  /// the active one.
  ///
  /// `resolveTheme` would already fall back for a dangling id, but leaving it
  /// stored means the *next* imported theme could reuse it and silently
  /// become the active theme.
  Future<void> delete(String id) async {
    await _persist(state.where((t) => t.id != id).toList());
    if (ref.read(selectedThemeIdProvider) == id) {
      await ref
          .read(selectedThemeIdProvider.notifier)
          .select(AppThemes.fallbackSpec.id);
    }
  }

  /// Replaces the whole list. Used by backup restore and Drive sync.
  Future<void> replaceAll(List<CustomTheme> themes) => _persist(themes);
}

final customThemesProvider =
    NotifierProvider<CustomThemesNotifier, List<CustomTheme>>(
  CustomThemesNotifier.new,
);

// ── Theme selection ──────────────────────────────────────────────────────

/// The id of the active theme — an [AppThemeType] name for a built-in, or a
/// uuid for a user theme.
///
/// Device-local on purpose: it is not synced to Drive and not included in
/// local backups, so a laptop and a desktop can sit on different themes. The
/// theme *definitions* are synced; only the choice is per-device.
class SelectedThemeNotifier extends Notifier<String> {
  static const String boxName = 'settings';
  static const String storageKey = 'theme';

  @override
  String build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return AppThemes.fallbackSpec.id;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>(boxName);
      final saved = box.get(storageKey);
      if (saved != null && saved.isNotEmpty) state = saved;
    } catch (_) {
      // Use the default theme if loading fails.
    }
  }

  Future<void> select(String id) async {
    // Update state synchronously to trigger an immediate rebuild.
    state = id;
    if (kDebugMode) print('Theme changed to: $id');
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>(boxName);
      await box.put(storageKey, id);
    } catch (e) {
      if (kDebugMode) print('Failed to save theme: $e');
    }
  }

  Future<void> selectBuiltIn(AppThemeType type) => select(type.name);

  /// Advances to the next selectable theme, wrapping around.
  Future<void> cycle() async {
    final ids = [
      ...AppThemes.visibleBuiltIns.map((t) => t.id),
      ...ref.read(customThemesProvider).map((t) => t.id),
    ];
    await select(nextThemeId(state, ids));
  }

  /// The theme [current] cycles to within [available].
  ///
  /// Anything not in [available] — a hidden built-in like `studioLight`, or a
  /// theme deleted on another device — cycles to the first entry rather than
  /// getting stuck.
  ///
  /// Pure and public: the switcher's tooltip has to name the theme a click
  /// would land on, so it calls this too.
  static String nextThemeId(String current, List<String> available) {
    if (available.isEmpty) return AppThemes.fallbackSpec.id;
    final index = available.indexOf(current);
    if (index < 0) return available.first;
    return available[(index + 1) % available.length];
  }
}

final selectedThemeIdProvider =
    NotifierProvider<SelectedThemeNotifier, String>(SelectedThemeNotifier.new);

/// Every theme the user can pick, in display order: visible built-ins first,
/// then their own.
final selectableThemesProvider = Provider<List<CustomTheme>>((ref) {
  return [
    ...AppThemes.visibleBuiltIns,
    ...ref.watch(customThemesProvider),
  ];
});

/// The resolved spec behind the active theme.
final activeThemeProvider = Provider<CustomTheme>((ref) {
  return resolveTheme(
    ref.watch(selectedThemeIdProvider),
    ref.watch(customThemesProvider),
  );
});

/// The active [ThemeData]. Watch this for colors; watch [activeThemeProvider]
/// when you need the spec itself (e.g. to derive a grid row color).
final themeDataProvider = Provider<ThemeData>((ref) {
  return AppThemes.buildFrom(ref.watch(activeThemeProvider));
});
