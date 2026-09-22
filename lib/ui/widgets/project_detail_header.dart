import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../utils/project_visuals.dart';
import 'project_cover_avatar.dart';

/// Compact header for the project detail page: the project's cover tile on the
/// left, then title + phase chip on top and a single muted meta line below
/// (age · last edited · time worked · live session). Secondary details stay
/// reachable without cluttering the header: the source file path lives in the
/// title's tooltip and the exact modified/created/completed-in dates in the
/// meta line's tooltip. BPM, key and DAW are intentionally absent — they are
/// editable fields directly below.
class ProjectDetailHeader extends StatelessWidget {
  final MusicProject project;
  final DateFormat dateFormat;
  final bool isSessionActive;
  final int liveSessionSeconds;
  final Set<String> finishedPhase;

  /// Tapping the cover tile opens the appearance editor (#110). Null leaves
  /// the tile inert — the header is also rendered in contexts with no page to
  /// push a dialog from.
  final VoidCallback? onEditAppearance;

  const ProjectDetailHeader({
    super.key,
    required this.project,
    required this.dateFormat,
    required this.isSessionActive,
    required this.liveSessionSeconds,
    required this.finishedPhase,
    this.onEditAppearance,
  });

  String _formatAge(AppLocalizations l10n, Duration duration) {
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = duration.inDays % 30;

    if (years > 0) {
      if (months > 0) {
        return l10n.ageYearsMonths(years, years > 1 ? 's' : '', months, months > 1 ? 's' : '');
      }
      return l10n.ageYears(years, years > 1 ? 's' : '');
    } else if (months > 0) {
      if (days > 0) {
        return l10n.ageMonthsDays(months, months > 1 ? 's' : '', days, days > 1 ? 's' : '');
      }
      return l10n.ageMonths(months, months > 1 ? 's' : '');
    } else if (days > 0) {
      return l10n.ageDays(days, days > 1 ? 's' : '');
    } else if (duration.inHours > 0) {
      return l10n.ageHours(duration.inHours, duration.inHours > 1 ? 's' : '');
    } else {
      return l10n.ageJustNow;
    }
  }

  String? _formatCompletion(AppLocalizations l10n, Duration? duration) {
    if (duration == null) return null;
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = duration.inDays % 30;

    if (years > 0) {
      if (months > 0) {
        return l10n.ageYearsMonths(years, years > 1 ? 's' : '', months, months > 1 ? 's' : '');
      }
      return l10n.ageYears(years, years > 1 ? 's' : '');
    } else if (months > 0) {
      if (days > 0) {
        return l10n.ageMonthsDays(months, months > 1 ? 's' : '', days, days > 1 ? 's' : '');
      }
      return l10n.ageMonths(months, months > 1 ? 's' : '');
    } else if (days > 0) {
      return l10n.ageDays(days, days > 1 ? 's' : '');
    } else if (duration.inHours > 0) {
      return l10n.ageHours(duration.inHours, duration.inHours > 1 ? 's' : '');
    } else {
      return l10n.ageLessThanHour;
    }
  }

  String _formatTotalWork(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  String _formatLiveSession(int seconds) {
    final h = seconds ~/ 3600;
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _relativeDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return l10n.dateToday;
    if (diff.inDays == 1) return l10n.dateYesterday;
    if (diff.inDays < 7) return l10n.dateDaysAgo(diff.inDays);
    if (diff.inDays < 30) return l10n.dateWeeksAgo(diff.inDays ~/ 7);
    if (diff.inDays < 365) return l10n.dateMonthsAgo(diff.inDays ~/ 30);
    return l10n.dateYearsAgo(diff.inDays ~/ 365, '');
  }

  Color _phaseColor(String status) {
    if (finishedPhase.contains(status)) return Colors.green;
    switch (status) {
      case 'Mastering': return Colors.purple;
      case 'Mixing': return Colors.blue;
      case 'Arranging': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final phaseColor = _phaseColor(project.status);
    final surfaceColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final mutedColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    final metaParts = <String>[
      l10n.headerAgeOld(_formatAge(l10n, project.projectAge)),
      l10n.headerEdited(_relativeDate(context, project.lastModifiedAt)),
      if (project.totalWorkSeconds > 0)
        l10n.headerWorked(_formatTotalWork(project.totalWorkSeconds)),
    ];

    final completion =
        _formatCompletion(l10n, project.timeToCompletion(finishedPhase));
    final detailLines = <String>[
      l10n.lastModified(dateFormat.format(project.lastModifiedAt)),
      if (project.fileCreatedAt != null)
        l10n.createdDate(dateFormat.format(project.fileCreatedAt!)),
      if (completion != null) l10n.completedIn(completion),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The one surface that shows a placeholder for an undecorated
          // project: here the tile is the way into the appearance editor, so
          // collapsing it to nothing would hide the feature entirely.
          ProjectCoverAvatar(
            project: project,
            size: 56,
            onTap: onEditAppearance,
            tooltip:
                onEditAppearance == null ? null : l10n.projectAppearanceTooltip,
            showEmptyPlaceholder: onEditAppearance != null,
          ),
          if (onEditAppearance != null || projectHasVisualIdentity(project))
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: project.filePath,
                        waitDuration: const Duration(milliseconds: 500),
                        child: Text(
                          project.displayName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: phaseColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        project.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: phaseColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Tooltip(
                  message: detailLines.join('\n'),
                  waitDuration: const Duration(milliseconds: 500),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 12, color: mutedColor),
                      children: [
                        TextSpan(text: metaParts.join(' · ')),
                        if (isSessionActive) ...[
                          const TextSpan(text: ' · '),
                          TextSpan(
                            text: l10n.sessionTime(_formatLiveSession(liveSessionSeconds)),
                            style: TextStyle(
                              color: Colors.green.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
