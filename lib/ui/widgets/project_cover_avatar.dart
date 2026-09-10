import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/music_project.dart';
import '../../utils/project_visuals.dart';

/// The one place a project's visual identity is drawn (#110): its cover art if
/// it has one, otherwise a tile in its accent color carrying its icon.
///
/// Cover art wins over color/icon whenever it is set *and* loadable — a path
/// that no longer resolves (restored on another machine before the artwork
/// finished downloading, or the managed file deleted by hand) falls back to the
/// badge through `errorBuilder` rather than showing Flutter's broken-image box.
/// That fallback is also why nothing here stats the file: this is drawn once
/// per visible row, and a synchronous `existsSync` on every rebuild is a cost
/// the decoder already pays for us.
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

  const ProjectCoverAvatar({
    super.key,
    required this.project,
    this.size = 40,
    this.onTap,
    this.tooltip,
  });

  double get _radius => size <= 24 ? 4 : 8;

  Widget _buildBadge(BuildContext context) {
    final accent = resolveProjectAccentColor(project);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Icon(
        resolveProjectIcon(project),
        size: size * 0.55,
        color: accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coverPath = project.thumbnailPath;
    Widget child;
    if (projectHasCoverArt(project)) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Image.file(
          File(coverPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Keeps a big cover from being decoded at full resolution for a
          // 24px grid cell.
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          errorBuilder: (context, error, stackTrace) => _buildBadge(context),
        ),
      );
    } else {
      child = _buildBadge(context);
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
