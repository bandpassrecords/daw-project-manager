import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../providers/providers.dart' show finishedPhaseProvider;
import '../../utils/project_summary_text.dart';
import '../../utils/track_duration.dart';
import 'release_track_parts_chip.dart';

/// Columns about a project that the projects table and a release's
/// tracklist both offer: one definition each, so the two tables show the
/// same thing the same way.
///
/// They used to live in the tracklist only, and a user who saw their song
/// notes there could not get them into the projects table — the nearest
/// thing was a custom field called "Notes", which is other data altogether.
///
/// Every row a column is in must carry its cell: [projectInfoCells] for a
/// project's row, [emptyProjectInfoCells] for anything else (a folder group
/// row). The renderers find the project in the row's `data` cell.

const kNotesColumnField = 'notes';
const kLengthColumnField = 'length';
const kPartsColumnField = 'parts';
const kTagsColumnField = 'tags';
const kDeadlineColumnField = 'deadline';

MusicProject? _projectOf(TrinaColumnRendererContext ctx) =>
    ctx.row.cells['data']?.value as MusicProject?;

/// The shared columns' cells for [project]'s row.
Map<String, TrinaCell> projectInfoCells(MusicProject project) => {
      kTagsColumnField: TrinaCell(value: project.tags.join(', ')),
      kDeadlineColumnField: TrinaCell(value: project.deadlineStatus ?? ''),
      // Milliseconds so the column sorts by real length rather than by the
      // "3:45" string; the renderer formats it.
      kLengthColumnField: TrinaCell(
        value: effectiveTrackDuration(project)?.inMilliseconds ?? 0,
      ),
      // The user's own notes, flattened to a line — the same text the
      // project page shows.
      kNotesColumnField: TrinaCell(value: projectNoteExcerpt(project) ?? ''),
      // Sorted by how many parts are still *needed*, not by progress: "what
      // does this still owe me" is the question the column gets read for. A
      // project with no parts listed sorts alongside a finished one.
      kPartsColumnField:
          TrinaCell(value: ReleaseTrackPartsChip.neededCount(project)),
    };

/// The shared columns' cells for a row that isn't a project's.
Map<String, TrinaCell> emptyProjectInfoCells() => {
      kTagsColumnField: TrinaCell(value: ''),
      kDeadlineColumnField: TrinaCell(value: ''),
      kLengthColumnField: TrinaCell(value: 0),
      kNotesColumnField: TrinaCell(value: ''),
      kPartsColumnField: TrinaCell(value: 0),
    };

/// The song's length — measured from its audio, or typed in.
TrinaColumn projectLengthColumn({required String title}) => TrinaColumn(
      title: title,
      field: kLengthColumnField,
      type: TrinaColumnType.number(),
      enableEditingMode: false,
      width: 90,
      minWidth: 70,
      renderer: (ctx) {
        final ms = (ctx.cell.value as num?)?.toInt() ?? 0;
        // 0 is the "no length yet" sentinel the cell value uses so the column
        // can sort numerically — never shown as a time.
        if (ms <= 0) return const SizedBox.shrink();
        return Text(formatTrackDuration(Duration(milliseconds: ms)));
      },
    );

/// The project's notes on one line, the full text in a tooltip.
TrinaColumn projectNotesColumn({
  required String title,
  TextStyle? textStyle,
}) =>
    TrinaColumn(
      title: title,
      field: kNotesColumnField,
      type: TrinaColumnType.text(),
      enableEditingMode: false,
      width: 260,
      minWidth: 140,
      renderer: (ctx) {
        final text = '${ctx.cell.value}';
        if (text.isEmpty) return const SizedBox.shrink();
        final project = _projectOf(ctx);
        // The excerpt is already one line and already capped; the tooltip
        // carries the rest so a long note is readable without leaving the
        // table.
        final full =
            project == null ? text : (projectNoteFullText(project) ?? text);
        return Tooltip(
          message: full,
          waitDuration: const Duration(milliseconds: 400),
          child: Text(text, overflow: TextOverflow.ellipsis, style: textStyle),
        );
      },
    );

/// The project's tags as chips. [hide] while the tags feature is off (the
/// column stays, so every row's cells still match the column set).
/// [onTagTap], when given, makes a chip filter by its tag.
TrinaColumn projectTagsColumn({
  required String title,
  bool hide = false,
  String Function(String tag)? tagTooltip,
  void Function(String tag)? onTagTap,
}) =>
    TrinaColumn(
      title: title,
      field: kTagsColumnField,
      type: TrinaColumnType.text(),
      hide: hide,
      enableEditingMode: false,
      width: 180,
      minWidth: 100,
      renderer: (ctx) {
        final project = _projectOf(ctx);
        if (project == null || project.tags.isEmpty) {
          return const SizedBox.shrink();
        }
        // A scroll view that never scrolls: it clips chips past the cell's
        // edge without the overflow error a bare Row would raise. Widening
        // the column shows the rest.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              for (final tag in project.tags)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TagCellChip(
                    tag: tag,
                    tooltip: tagTooltip?.call(tag),
                    onTap: onTagTap == null ? null : () => onTagTap(tag),
                  ),
                ),
            ],
          ),
        );
      },
    );

/// How long until the project's deadline, as a coloured badge: late, due
/// today, due within the week, or later. Nothing once the project is in a
/// finished phase.
TrinaColumn projectDeadlineColumn({required String title}) => TrinaColumn(
      title: title,
      field: kDeadlineColumnField,
      type: TrinaColumnType.text(),
      enableEditingMode: false,
      width: 120,
      minWidth: 100,
      renderer: (ctx) {
        final project = _projectOf(ctx);
        if (project == null || project.deadline == null) {
          return const SizedBox.shrink();
        }
        return Consumer(
          builder: (context, ref, _) {
            final finishedPhases = ref.watch(finishedPhaseProvider);
            if (finishedPhases.contains(project.status)) {
              return const SizedBox.shrink();
            }
            final l10n = AppLocalizations.of(context)!;
            final badge = deadlineBadgeOf(project.daysUntilDeadline ?? 0);
            final text = switch (badge.kind) {
              DeadlineBadgeKind.late => l10n.daysLate(badge.days),
              DeadlineBadgeKind.today => l10n.dueToday,
              DeadlineBadgeKind.soon || DeadlineBadgeKind.later =>
                l10n.daysLeft(badge.days),
            };
            final color = badge.color;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badge.icon, size: 12, color: color),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

enum DeadlineBadgeKind { late, today, soon, later }

/// How a deadline [daysUntil] days away is shown: late (red), today (red),
/// within a week (orange) or later (blue), with the number of days to say.
({DeadlineBadgeKind kind, int days, Color color, IconData icon})
    deadlineBadgeOf(int daysUntil) {
  if (daysUntil < 0) {
    return (
      kind: DeadlineBadgeKind.late,
      days: daysUntil.abs(),
      color: Colors.red,
      icon: Icons.warning,
    );
  }
  if (daysUntil == 0) {
    return (
      kind: DeadlineBadgeKind.today,
      days: 0,
      color: Colors.red,
      icon: Icons.today,
    );
  }
  if (daysUntil <= 7) {
    return (
      kind: DeadlineBadgeKind.soon,
      days: daysUntil,
      color: Colors.orange,
      icon: Icons.schedule,
    );
  }
  return (
    kind: DeadlineBadgeKind.later,
    days: daysUntil,
    color: Colors.blue,
    icon: Icons.calendar_today,
  );
}

/// One tag in a table cell.
class TagCellChip extends StatelessWidget {
  const TagCellChip({super.key, required this.tag, this.tooltip, this.onTap});

  final String tag;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chip = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          tag,
          maxLines: 1,
          style: TextStyle(fontSize: 11, color: scheme.onSecondaryContainer),
        ),
      ),
    );
    final message = tooltip;
    if (message == null) return chip;
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 400),
      child: chip,
    );
  }
}

/// How the project's parts stand, as the tracklist's chip.
TrinaColumn projectPartsColumn({
  required String title,
  void Function(MusicProject project)? onOpenParts,
}) =>
    TrinaColumn(
      title: title,
      field: kPartsColumnField,
      type: TrinaColumnType.number(),
      enableEditingMode: false,
      width: 120,
      minWidth: 100,
      renderer: (ctx) {
        final project = _projectOf(ctx);
        if (project == null) return const SizedBox.shrink();
        // Shrinks rather than overflows when the column is narrow or the
        // label long in a translation.
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ReleaseTrackPartsChip(
            project: project,
            onTap: onOpenParts == null ? null : () => onOpenParts(project),
          ),
        );
      },
    );
