import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../models/music_project.dart';
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

MusicProject? _projectOf(TrinaColumnRendererContext ctx) =>
    ctx.row.cells['data']?.value as MusicProject?;

/// The three cells for [project]'s row.
Map<String, TrinaCell> projectInfoCells(MusicProject project) => {
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

/// The three cells for a row that isn't a project's.
Map<String, TrinaCell> emptyProjectInfoCells() => {
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
