import 'package:flutter/material.dart';

import '../utils/phase_colors.dart' show colorToHex, hexToColor;

/// How strongly a theme leans on its accent color for interactive surfaces.
///
/// This is the one structural difference between the built-in themes that
/// isn't expressible as a color: Neon Dark paints buttons in the accent and
/// squares off their corners, while Classic Dark keeps Material's default
/// button shapes and uses muted text for anything that isn't a filled button.
///
/// Not user-editable in v1 — every user theme is [vivid]. It exists so the
/// built-ins can round-trip through [CustomTheme] without losing their look.
enum ThemeAccentStyle {
  /// Accent-colored text/outlined buttons, elevation 0, explicit corner radius.
  vivid,

  /// Muted text/outlined buttons, Material's default elevation and shapes.
  muted,
}

/// A complete description of one theme, from which a [ThemeData] is built.
///
/// The first block of fields is what the theme editor exposes to users. Every
/// remaining field is an override that defaults to something derived from the
/// first block — they exist so the three built-in themes, which were
/// hand-written [ThemeData]s before this class existed, can be expressed as
/// specs without changing how they look.
@immutable
class CustomTheme {
  /// Stable identity. Built-ins use their `AppThemeType.name`; user themes
  /// use a uuid.
  final String id;

  /// User-supplied display name. Null for built-ins, whose names are
  /// localized (`l10n.neonDarkThemeName` and friends).
  final String? name;

  /// Built-in themes are read-only: they can be selected and duplicated, but
  /// not edited or deleted.
  final bool isBuiltIn;

  // ── User-editable ──────────────────────────────────────────────────────

  final Brightness brightness;
  final Color primary;

  /// Null lets [ColorScheme.fromSeed] derive one from [primary].
  final Color? secondary;

  /// Scaffold and canvas color.
  final Color background;

  /// Cards, dialogs, app bar, and input fills.
  final Color card;

  /// Corner radius for cards. Dialogs use this + 4.
  final double cardRadius;

  /// Corner radius for buttons, inputs and snackbars.
  final double controlRadius;

  // ── Structural overrides (built-ins in v1) ─────────────────────────────

  final ThemeAccentStyle accentStyle;

  /// [ColorScheme.surface]. Defaults to [card].
  final Color? surface;

  /// Strong text and [ColorScheme.onSurface]. Defaults by [brightness].
  final Color? onSurface;

  /// Text on top of [primary]. Defaults to whichever of black/white contrasts.
  final Color? onPrimary;

  /// Secondary text tone. Defaults to [onSurface] at 70% alpha.
  final Color? textSecondary;

  /// Faintest text tone. Defaults to [onSurface] at 60% alpha.
  final Color? textTertiary;

  /// Defaults to [onSurface] at 10% alpha.
  final Color? divider;

  /// Input field borders. Defaults to [onSurface] at 20% alpha.
  final Color? inputBorder;

  /// Card outline. Null means no outline at all — Classic Dark has none —
  /// so unlike the other border fields this one has no derived default.
  final Color? cardBorder;

  /// Defaults to [card].
  final Color? chipBackground;

  /// Defaults to [onSurface] at 10% alpha.
  final Color? chipBorder;

  /// Alpha of [primary] behind a selected chip.
  final double chipSelectedAlpha;

  /// Defaults to [card]. Snackbar text color is derived from whichever this
  /// resolves to, so a dark snackbar on a light theme still reads.
  final Color? snackBarBackground;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomTheme({
    required this.id,
    this.name,
    this.isBuiltIn = false,
    required this.brightness,
    required this.primary,
    this.secondary,
    required this.background,
    required this.card,
    this.cardRadius = 16,
    this.controlRadius = 12,
    this.accentStyle = ThemeAccentStyle.vivid,
    this.surface,
    this.onSurface,
    this.onPrimary,
    this.textSecondary,
    this.textTertiary,
    this.divider,
    this.inputBorder,
    this.cardBorder,
    this.chipBackground,
    this.chipBorder,
    this.chipSelectedAlpha = 0.2,
    this.snackBarBackground,
    this.createdAt,
    this.updatedAt,
  });

  // ── Resolved values ────────────────────────────────────────────────────

  bool get isDark => brightness == Brightness.dark;

  /// Strong text / [ColorScheme.onSurface].
  Color get resolvedOnSurface =>
      onSurface ?? (isDark ? Colors.white : const Color(0xFF1C1B1F));

  Color get resolvedOnPrimary =>
      onPrimary ??
      (ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
          ? Colors.white
          : Colors.black);

  Color get resolvedSurface => surface ?? card;

  Color get resolvedTextSecondary =>
      textSecondary ?? resolvedOnSurface.withValues(alpha: 0.70);

  Color get resolvedTextTertiary =>
      textTertiary ?? resolvedOnSurface.withValues(alpha: 0.60);

  Color get resolvedDivider =>
      divider ?? resolvedOnSurface.withValues(alpha: 0.10);

  Color get resolvedInputBorder =>
      inputBorder ?? resolvedOnSurface.withValues(alpha: 0.20);

  Color get resolvedChipBackground => chipBackground ?? card;

  Color get resolvedChipBorder =>
      chipBorder ?? resolvedOnSurface.withValues(alpha: 0.10);

  Color get resolvedSnackBarBackground => snackBarBackground ?? card;

  /// Snackbar label color, derived from whatever the snackbar sits on.
  Color get resolvedSnackBarForeground =>
      ThemeData.estimateBrightnessForColor(resolvedSnackBarBackground) ==
              Brightness.dark
          ? Colors.white
          : Colors.black;

  CustomTheme copyWith({
    String? id,
    String? name,
    Brightness? brightness,
    Color? primary,
    Color? secondary,
    Color? background,
    Color? card,
    double? cardRadius,
    double? controlRadius,
    DateTime? updatedAt,
  }) {
    return CustomTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      isBuiltIn: isBuiltIn,
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      card: card ?? this.card,
      cardRadius: cardRadius ?? this.cardRadius,
      controlRadius: controlRadius ?? this.controlRadius,
      accentStyle: accentStyle,
      surface: surface,
      onSurface: onSurface,
      onPrimary: onPrimary,
      textSecondary: textSecondary,
      textTertiary: textTertiary,
      divider: divider,
      inputBorder: inputBorder,
      cardBorder: cardBorder,
      chipBackground: chipBackground,
      chipBorder: chipBorder,
      chipSelectedAlpha: chipSelectedAlpha,
      snackBarBackground: snackBarBackground,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── JSON ───────────────────────────────────────────────────────────────
  //
  // Only user themes are ever serialized — built-ins are code constants, so
  // the structural override fields deliberately stay out of the wire format.
  // Unknown keys are ignored and missing keys fall back to the constructor
  // defaults, so a theme written by a newer build still imports here.

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brightness': brightness == Brightness.dark ? 'dark' : 'light',
        'primary': colorToHex(primary),
        if (secondary != null) 'secondary': colorToHex(secondary!),
        'background': colorToHex(background),
        'card': colorToHex(card),
        'cardRadius': cardRadius,
        'controlRadius': controlRadius,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  static CustomTheme fromJson(Map<String, dynamic> json) {
    Color? color(String key, {Color? fallback}) {
      final raw = json[key];
      if (raw is! String || raw.isEmpty) return fallback;
      try {
        return hexToColor(raw.startsWith('#') ? raw : '#$raw');
      } catch (_) {
        return fallback;
      }
    }

    double number(String key, double fallback) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      return fallback;
    }

    DateTime? date(String key) {
      final raw = json[key];
      return raw is String ? DateTime.tryParse(raw) : null;
    }

    return CustomTheme(
      id: json['id'] as String,
      name: json['name'] as String?,
      brightness:
          json['brightness'] == 'light' ? Brightness.light : Brightness.dark,
      primary: color('primary', fallback: const Color(0xFF00D4FF))!,
      secondary: color('secondary'),
      background: color('background', fallback: const Color(0xFF0A0A14))!,
      card: color('card', fallback: const Color(0xFF1A1A2E))!,
      cardRadius: number('cardRadius', 16),
      controlRadius: number('controlRadius', 12),
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CustomTheme &&
      other.id == id &&
      other.name == name &&
      other.isBuiltIn == isBuiltIn &&
      other.brightness == brightness &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.background == background &&
      other.card == card &&
      other.cardRadius == cardRadius &&
      other.controlRadius == controlRadius &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        isBuiltIn,
        brightness,
        primary,
        secondary,
        background,
        card,
        cardRadius,
        controlRadius,
        updatedAt,
      );
}
