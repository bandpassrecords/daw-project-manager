import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/music_project.dart';
import '../../utils/project_visuals.dart';

/// Draws a project's visual identity as a square tile: its cover art if it has
/// one, otherwise a badge in its accent color carrying its icon.
///
/// Renders nothing at all — zero size — for a project nobody has decorated,
/// unless [showEmptyPlaceholder] asks for the "add one" affordance. That is the
/// rule the whole feature hangs on: no auto-assigned colors, no stand-in icons,
/// no generic placeholder image in the list.
///
/// A cover path that no longer resolves (restored on another machine before the
/// artwork finished downloading, or the managed file deleted by hand) falls back
/// through `errorBuilder` rather than showing Flutter's broken-image box. That
/// fallback is also why nothing here stats the file: this is drawn once per
/// visible row, and a synchronous `existsSync` on every rebuild is a cost the
/// decoder already pays for us.
class ProjectCoverAvatar extends StatelessWidget {
  final MusicProject project;

  /// Side length of the (square) tile.
  final double size;

  /// Optional tap handler — the detail page's header uses it to open the
  /// appearance dialog. Grid and list rows leave it null so the row's own tap
  /// still selects/opens the project.
  final VoidCallback? onTap;

  /// Tooltip shown on hover. Null for no tooltip.
  final String? tooltip;

  /// Draw a muted "add an image" outline when the project has no identity yet,
  /// instead of collapsing to nothing.
  ///
  /// For editing surfaces only — the detail header and the appearance dialog,
  /// where the tile is the way in. A list row must never use it: an outline on
  /// every undecorated project is exactly the generic default this feature is
  /// meant not to have.
  final bool showEmptyPlaceholder;

  const ProjectCoverAvatar({
    super.key,
    required this.project,
    this.size = 40,
    this.onTap,
    this.tooltip,
    this.showEmptyPlaceholder = false,
  });

  double get _radius => size <= 24 ? 4 : 8;

  Widget? _buildBadge(BuildContext context) {
    final accent = projectAccentColor(project);
    final icon = projectIcon(project);
    if (accent == null && icon == null) return null;

    // Either half of the pair stands on its own: a colour with no icon is a
    // plain swatch, an icon with no colour rides the theme's accent.
    final tint = accent ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: tint.withValues(alpha: 0.55)),
      ),
      child: icon == null ? null : Icon(icon, size: size * 0.55, color: tint),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: size * 0.45,
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coverPath = project.thumbnailPath;
    Widget? child;

    if (projectHasCoverArt(project)) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Image.file(
          File(coverPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Keeps a big cover from being decoded at full resolution for a
          // small tile.
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          errorBuilder: (context, error, stackTrace) =>
              _buildBadge(context) ??
              (showEmptyPlaceholder
                  ? _buildPlaceholder(context)
                  : SizedBox(width: size, height: size)),
        ),
      );
    } else {
      child = _buildBadge(context);
    }

    if (child == null) {
      if (!showEmptyPlaceholder) return const SizedBox.shrink();
      child = _buildPlaceholder(context);
    }

    if (onTap != null) {
      child = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius),
          onTap: onTap,
          child: child,
        ),
      );
    }

    if (tooltip != null) {
      child = Tooltip(message: tooltip!, child: child);
    }

    return SizedBox(width: size, height: size, child: child);
  }
}

/// A project's cover art bled into the left edge of a grid row: full row
/// height, flush against the cell's left border, fading out to the right so it
/// dissolves into the row instead of ending on a hard edge.
///
/// Wider than it is tall on purpose — the fade tail runs on past the square,
/// under the start of the row's text, which is what makes the artwork read as
/// larger than the strip a thumbnail would occupy.
///
/// Draws nothing for a project without cover art. The accent colour and icon
/// are deliberately *not* drawn at this size: a bare colour block bleeding into
/// every decorated row would be a stripe down the list rather than a cover.
class ProjectCoverBleed extends StatelessWidget {
  final MusicProject project;

  /// Height of the strip — the grid's row height, so it reaches both borders.
  final double height;

  /// How far the artwork extends before it has faded away entirely.
  final double width;

  /// Fraction of [width] the artwork holds at full strength before the fade
  /// begins: the square at the left edge, in practice.
  final double solidFraction;

  const ProjectCoverBleed({
    super.key,
    required this.project,
    required this.height,
    required this.width,
    this.solidFraction = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    if (!projectHasCoverArt(project)) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, solidFraction, 1.0],
          ).createShader(bounds),
          child: Image.file(
            File(project.thumbnailPath!),
            width: width,
            height: height,
            // Cover art is usually square; showing the middle of it across a
            // strip twice as wide beats letterboxing it against the row colour.
            fit: BoxFit.cover,
            cacheWidth:
                (width * MediaQuery.devicePixelRatioOf(context)).round(),
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
