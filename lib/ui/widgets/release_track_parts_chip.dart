import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../models/project_part.dart';
import '../../utils/part_status_display.dart';
import '../project_parts_page.dart';

/// How far along a track's instrumentation is, as one compact chip: final
/// takes over total, plus a count of the parts still [PartTakeStatus.needed].
///
/// Shown against each track of a release, in both the tracklist and the table,
/// so the two views cannot disagree. Tapping it opens that project's parts
/// workspace — which is the point of putting it here: a release is where you
/// notice a song still owes you a bass take, and the way to act on it should
/// be the thing you just noticed.
///
/// Draws **nothing** for a project with no parts listed, following the same
/// rule as the cover art (#110): no generic placeholder on every row.
class ReleaseTrackPartsChip extends StatelessWidget {
  const ReleaseTrackPartsChip({
    super.key,
    required this.project,
    this.onTap,
    this.compact = false,
  });

  final MusicProject project;

  /// What tapping the chip does. Defaults to opening [ProjectPartsPage] for
  /// [project]; the table passes its own so the page owns navigation, matching
  /// how its other row actions work.
  final VoidCallback? onTap;

  /// Drops the padding and shrinks the gaps, for the tracklist's subtitle row
  /// where the chip sits among other inline facts rather than in its own cell.
  final bool compact;

  /// Parts of [project] that are called for but not yet recorded.
  static int neededCount(MusicProject project) => project.parts
      .where((part) => part.status == PartTakeStatus.needed)
      .length;

  @override
  Widget build(BuildContext context) {
    final parts = project.parts;
    if (parts.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final needed = neededCount(project);
    final done = ProjectPart.doneCount(parts);
    final allDone = ProjectPart.allDone(parts);

    final progress = l10n.partsProgress(done, parts.length);
    final tooltip =
        needed > 0 ? '$progress\n${l10n.partsNeededCount(needed)}' : progress;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          allDone ? PartTakeStatus.finalTake.icon : Icons.piano,
          size: compact ? 14 : 15,
          color: allDone
              ? PartTakeStatus.finalTake.color
              : theme.textTheme.bodySmall?.color,
        ),
        SizedBox(width: compact ? 4 : 5),
        Text(
          '$done/${parts.length}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: allDone ? PartTakeStatus.finalTake.color : null,
          ),
        ),
        if (needed > 0) ...[
          SizedBox(width: compact ? 6 : 8),
          Icon(
            PartTakeStatus.needed.icon,
            size: 13,
            color: PartTakeStatus.needed.color,
          ),
          const SizedBox(width: 3),
          Text(
            '$needed',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: PartTakeStatus.needed.color),
          ),
        ],
      ],
    );

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap ?? () => _openParts(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 2)
              : const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: row,
        ),
      ),
    );
  }

  void _openParts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectPartsPage(projectId: project.id),
      ),
    );
  }
}
