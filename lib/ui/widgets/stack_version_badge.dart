import 'package:flutter/material.dart';

/// The "N versions" capsule after a version stack's name in the projects
/// grid, so a stacked song is distinguishable from an ordinary project at a
/// glance.
///
/// Its background is **opaque** — the theme's primary colour mixed into the
/// card colour rather than laid over whatever is behind it. The Name cell
/// bleeds cover art or an accent colour under the name, and a translucent
/// badge disappeared into a busy thumbnail. It is opaque on every row, with
/// or without a thumbnail, so the same badge never looks different from one
/// row to the next.
class StackVersionBadge extends StatelessWidget {
  const StackVersionBadge({
    super.key,
    required this.count,
    required this.tooltip,
  });

  final int count;
  final String tooltip;

  /// How much of the primary colour is mixed into the card colour.
  static const double tintStrength = 0.22;

  /// The badge's fill for [theme]: always fully opaque.
  static Color backgroundFor(ThemeData theme) {
    final base = theme.cardColor.withValues(alpha: 1);
    return Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: tintStrength),
      base,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: ShapeDecoration(
          color: backgroundFor(theme),
          shape: StadiumBorder(
            side: BorderSide(color: primary.withValues(alpha: 0.45)),
          ),
          shadows: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 3),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers, size: 11, color: primary),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
