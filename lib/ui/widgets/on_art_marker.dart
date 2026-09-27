import 'package:flutter/material.dart';

/// Small markers drawn in the projects grid's Name cell, where a row's cover
/// art or accent colour bleeds in underneath (see `ProjectCoverBleed`).
///
/// Anything translucent there — a tinted badge, a bare icon — disappears into
/// a busy cover. These give it an **opaque** backing instead: [tint] mixed into
/// the card colour, so it follows the active theme and never lets the artwork
/// through.

/// How much of a marker's own colour is mixed into its opaque fill.
const double kOnArtTintStrength = 0.22;

/// The opaque fill for a marker coloured [tint] under [theme].
Color onArtFill(
  ThemeData theme,
  Color tint, {
  double strength = kOnArtTintStrength,
}) =>
    Color.alphaBlend(
      tint.withValues(alpha: strength),
      theme.cardColor.withValues(alpha: 1),
    );

/// The soft shadow that lifts a marker off the artwork behind it.
const List<BoxShadow> kOnArtShadow = [
  BoxShadow(color: Color(0x40000000), blurRadius: 3),
];

/// A capsule for a text badge over artwork: opaque [onArtFill] with a thin
/// outline in [tint].
ShapeDecoration onArtCapsule(ThemeData theme, Color tint) => ShapeDecoration(
      color: onArtFill(theme, tint),
      shape: StadiumBorder(
        side: BorderSide(color: tint.withValues(alpha: 0.45)),
      ),
      shadows: kOnArtShadow,
    );

/// A status icon in the Name cell — missing file, archived, matched in notes.
///
/// On a row with artwork behind it ([onArt]) the icon sits in a small opaque
/// disc, so a warning like "file not found" can't be lost in a cover. On a
/// plain row it stays a bare icon, as it always was: a disc on every row would
/// only add clutter where nothing competes with it.
class OnArtMarker extends StatelessWidget {
  const OnArtMarker({
    super.key,
    required this.icon,
    required this.color,
    required this.onArt,
    this.size = 14,
  });

  final IconData icon;
  final Color color;
  final bool onArt;
  final double size;

  /// The disc's diameter relative to the icon.
  static const double discPadding = 3;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: size, color: color);
    if (!onArt) return glyph;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(discPadding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onArtFill(theme, color),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: kOnArtShadow,
      ),
      child: glyph,
    );
  }
}

/// Text shadows that put a halo of the card colour round a project name
/// running over the faded end of its cover, so a light cover can't wash the
/// name out. Only for rows with artwork; a plain row needs none.
List<Shadow> onArtTextHalo(ThemeData theme) {
  final halo = theme.cardColor.withValues(alpha: 1);
  return [
    Shadow(color: halo, blurRadius: 3),
    Shadow(color: halo, blurRadius: 6),
  ];
}
