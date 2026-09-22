import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../utils/track_duration.dart';

/// The release's total running time, as a footer under its tracklist — where
/// an album sleeve prints it.
///
/// Always shown once the release has tracks, including when none of them has
/// a length yet: an absent total reads as "this page doesn't do totals",
/// whereas a dash with a reason says what is missing and how to fix it. When
/// only some tracks are timed, the figure carries a "+" and the count of
/// untimed tracks is spelled out beside it rather than hidden in a tooltip —
/// the total is a floor, and presenting it as exact would be wrong.
///
/// Takes plain values and no providers, so it is widget-testable.
class ReleaseTotalLengthFooter extends StatelessWidget {
  const ReleaseTotalLengthFooter({super.key, required this.projects});

  final List<MusicProject> projects;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;
    final total = releaseTotalDuration(projects);
    final missing = tracksMissingDuration(projects);
    final noneTimed = total == Duration.zero;

    final figure = noneTimed
        ? '—'
        : missing > 0
            ? l10n.releaseLengthAtLeast(formatTrackDuration(total))
            : formatTrackDuration(total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: muted),
          const SizedBox(width: 8),
          Text(
            l10n.releaseTotalLengthLabel,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(width: 12),
          // Why the total is incomplete, in plain view.
          if (noneTimed || missing > 0)
            Expanded(
              child: Text(
                noneTimed
                    ? l10n.releaseLengthNone
                    : l10n.releaseLengthPartial(missing),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 12),
          Text(
            figure,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
