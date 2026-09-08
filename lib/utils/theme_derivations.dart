import 'package:flutter/material.dart';

import '../models/custom_theme.dart';

/// Values the app derives from a theme spec that aren't part of [ThemeData].
///
/// These used to be written as `themeType == AppThemeType.neonDark ? … : …`
/// at each call site, which silently treated every non-Neon theme — including
/// every user theme — as Classic Dark. Deriving them from the spec instead
/// means a user theme with a vivid accent gets the vivid treatment.
extension ThemeDerivations on CustomTheme {
  /// Whether [primary] is saturated enough to read as a highlight tint.
  ///
  /// Classic Dark's primary is a muted gray-blue (saturation ≈ 0.15), so
  /// tinting a selected row with it is barely visible against the dark card
  /// background — those themes lean on plain white/black instead. Neon Dark's
  /// cyan (saturation 1.0) already pops.
  bool get hasVividAccent => HSLColor.fromColor(primary).saturation >= 0.5;

  /// Fill behind the selected/activated grid row.
  Color get gridRowSelectColor => hasVividAccent
      ? primary.withValues(alpha: 0.18)
      : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.14);

  /// Odd grid rows.
  ///
  /// A vivid theme has a real separation between its background and card
  /// colors, so alternating between the two is legible. A muted theme's two
  /// are close enough that it stripes the card color against a slightly
  /// lifted version of itself instead.
  Color get gridRowOddColor => hasVividAccent ? background : card;

  /// Even grid rows.
  Color get gridRowEvenColor => hasVividAccent
      ? card
      : Color.alphaBlend(
          (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.05 : 0.04),
          card,
        );

  /// Outer border of a grid. Vivid themes can take the full divider color;
  /// muted ones would look boxed-in, so they get a faded one.
  Color gridBorderColor(Color dividerColor) =>
      hasVividAccent ? dividerColor : dividerColor.withValues(alpha: 0.25);

  /// Identity string for widgets that must be rebuilt from scratch when the
  /// theme changes — notably `TrinaGrid`, whose renderers cache their colors.
  ///
  /// Includes [updatedAt] because editing a user theme's colors in place
  /// keeps the same [id]; keying on the id alone would leave the old colors
  /// on screen until something else rebuilt the grid.
  String get identityKey =>
      '$id@${updatedAt?.microsecondsSinceEpoch ?? 0}';
}
