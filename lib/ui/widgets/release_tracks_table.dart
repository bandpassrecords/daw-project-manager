import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../providers/theme_provider.dart';
import '../../utils/project_summary_text.dart';
import '../../utils/track_duration.dart';
import '../../utils/theme_derivations.dart';
import '../../utils/trina_grid_locale.dart';
import 'release_track_parts_chip.dart';
import 'trina_grid_menu_delegate.dart';

/// A release's tracks as a sortable table, mirroring the main dashboard's
/// projects grid.
///
/// The release detail page's own list stays available and is still the only
/// place the running order can be dragged — a sortable grid and a hand-ordered
/// list are different jobs, and sorting by BPM must not silently rewrite the
/// tracklist. This view is for *reading* a release the way the dashboard is
/// read: scan the columns, compare keys and tempos, sort by whatever matters.
///
/// Stateless with respect to the release: every callback hands the project
/// back to the page, which owns the repository writes.
class ReleaseTracksTable extends ConsumerStatefulWidget {
  const ReleaseTracksTable({
    super.key,
    required this.projects,
    required this.dateFormat,
    required this.onViewDetails,
    required this.onLaunch,
    required this.onRemoveFromRelease,
    required this.onOpenParts,
    required this.translateStatus,
    required this.statusColor,
  });

  /// In release order — the grid's initial, unsorted order is the tracklist.
  final List<MusicProject> projects;
  final DateFormat dateFormat;

  final void Function(MusicProject project) onViewDetails;

  /// Null disables the launch action for a project whose file isn't there.
  final void Function(MusicProject project)? onLaunch;

  final void Function(MusicProject project) onRemoveFromRelease;

  /// Opens the project's parts workspace. The parts cell is the only way into
  /// it from here, which is the point: a release is where you notice a song
  /// still needs a bass take.
  final void Function(MusicProject project) onOpenParts;

  /// Phase name → localized label, and → the colour the rest of the release
  /// page paints it. Injected rather than re-derived here so this table can't
  /// drift from the list view sitting right above it.
  final String Function(String status) translateStatus;
  final Color Function(String status) statusColor;

  @override
  ConsumerState<ReleaseTracksTable> createState() => _ReleaseTracksTableState();
}

class _ReleaseTracksTableState extends ConsumerState<ReleaseTracksTable> {
  TrinaGridStateManager? _stateManager;

  @override
  void didUpdateWidget(ReleaseTracksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projects != oldWidget.projects && _stateManager != null) {
      _stateManager!.removeAllRows();
      _stateManager!.appendRows(_mapToRows(widget.projects));
    }
  }

  List<TrinaRow> _mapToRows(List<MusicProject> projects) {
    return [
      for (var i = 0; i < projects.length; i++)
        TrinaRow(
          cells: {
            'position': TrinaCell(value: i + 1),
            'title': TrinaCell(value: projects[i].displayName),
            'daw': TrinaCell(value: _dawLabel(projects[i])),
            // Stored as a number so the column sorts numerically rather than
            // as "100" < "90"; the renderer formats it.
            'bpm': TrinaCell(value: projects[i].bpm ?? 0),
            'key': TrinaCell(value: projects[i].musicalKey ?? ''),
            // Milliseconds so the column sorts by real length rather than by
            // the "3:45" string; the renderer formats it.
            'length': TrinaCell(
              value: effectiveTrackDuration(projects[i])?.inMilliseconds ?? 0,
            ),
            'status': TrinaCell(value: projects[i].status),
            'notes': TrinaCell(value: projectNoteExcerpt(projects[i]) ?? ''),
            // Sorted by how many parts are still *needed*, not by progress:
            // "what does this release still owe me" is the question a
            // tracklist gets read for. A project with no parts listed sorts
            // alongside a finished one, both being zero.
            'parts': TrinaCell(value: ReleaseTrackPartsChip.neededCount(projects[i])),
            'modified': TrinaCell(value: projects[i].lastModifiedAt),
            'actions': TrinaCell(value: ''),
            'data': TrinaCell(value: projects[i]),
          },
        ),
    ];
  }

  static String _dawLabel(MusicProject project) {
    final daw = project.dawType;
    if (daw == null || daw.isEmpty) return '';
    final version = project.dawVersion;
    return (version == null || version.isEmpty) ? daw : '$daw $version';
  }

  MusicProject? _projectOf(TrinaColumnRendererContext ctx) =>
      ctx.row.cells['data']?.value as MusicProject?;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final themeSpec = ref.watch(activeThemeProvider);

    // Same derivation the releases grid uses: card-colored odd rows, because
    // this grid sits inside a card rather than filling the page.
    final rowSelectColor = themeSpec.gridRowSelectColor;
    final oddColor = theme.cardColor;
    final evenColor = theme.brightness == Brightness.dark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            theme.cardColor,
          )
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.04),
            theme.cardColor,
          );

    final columns = <TrinaColumn>[
      TrinaColumn(
        title: '#',
        field: 'position',
        type: TrinaColumnType.number(),
        enableEditingMode: false,
        width: 56,
        minWidth: 48,
        frozen: TrinaColumnFrozen.start,
        renderer: (ctx) => Text(
          '${ctx.cell.value}',
          style: theme.textTheme.bodySmall,
        ),
      ),
      TrinaColumn(
        title: l10n.title,
        field: 'title',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 280,
        minWidth: 160,
        frozen: TrinaColumnFrozen.start,
        renderer: (ctx) {
          final project = _projectOf(ctx);
          // A project whose file is gone is worth flagging here for the same
          // reason the dashboard flags it — but a version stack has no file of
          // its own, so it is never a candidate (see MusicProject).
          final missing = project != null &&
              project.isMissingFileCandidate &&
              !File(project.filePath).existsSync() &&
              !Directory(project.filePath).existsSync();
          return Row(
            children: [
              if (missing)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.cloud_off,
                    size: 15,
                    color: theme.colorScheme.error,
                  ),
                ),
              Expanded(
                child: Text(
                  '${ctx.cell.value}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      TrinaColumn(
        title: l10n.daw,
        field: 'daw',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 160,
        minWidth: 110,
      ),
      TrinaColumn(
        title: l10n.bpm,
        field: 'bpm',
        type: TrinaColumnType.number(),
        enableEditingMode: false,
        width: 90,
        minWidth: 70,
        renderer: (ctx) {
          final bpm = (ctx.cell.value as num?)?.toDouble() ?? 0;
          // 0 is the "no BPM" sentinel the cell value uses so the column can
          // sort numerically — never shown as a tempo.
          if (bpm <= 0) return const Text('');
          return Text(bpm.toStringAsFixed(bpm % 1 == 0 ? 0 : 1));
        },
      ),
      TrinaColumn(
        // "Key" out of "Key (e.g., C#m, F major)" — the same trim the
        // dashboard grid does for this column.
        title: l10n.key.split(' ').first,
        field: 'key',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 90,
        minWidth: 70,
      ),
      TrinaColumn(
        title: l10n.songLengthColumn,
        field: 'length',
        type: TrinaColumnType.number(),
        enableEditingMode: false,
        width: 90,
        minWidth: 70,
        renderer: (ctx) {
          final ms = (ctx.cell.value as num?)?.toInt() ?? 0;
          // 0 is the "no length yet" sentinel the cell value uses so the
          // column can sort numerically — never shown as a time.
          if (ms <= 0) return const SizedBox.shrink();
          return Text(formatTrackDuration(Duration(milliseconds: ms)));
        },
      ),
      TrinaColumn(
        title: l10n.phase,
        field: 'status',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 130,
        minWidth: 100,
        renderer: (ctx) {
          final status = '${ctx.cell.value}';
          if (status.isEmpty) return const Text('');
          return Text(
            widget.translateStatus(status),
            style: TextStyle(
              color: widget.statusColor(status),
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
      TrinaColumn(
        title: l10n.notes,
        field: 'notes',
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
          final full = project == null ? text : (projectNoteFullText(project) ?? text);
          return Tooltip(
            message: full,
            waitDuration: const Duration(milliseconds: 400),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          );
        },
      ),
      TrinaColumn(
        title: l10n.partsColumn,
        field: 'parts',
        type: TrinaColumnType.number(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
        renderer: (ctx) {
          final project = _projectOf(ctx);
          if (project == null) return const SizedBox.shrink();
          // Same widget the tracklist's subtitle uses, so the two views of a
          // release can't disagree about a song's instrumentation.
          return Align(
            alignment: Alignment.centerLeft,
            child: ReleaseTrackPartsChip(
              project: project,
              onTap: () => widget.onOpenParts(project),
            ),
          );
        },
      ),
      TrinaColumn(
        title: l10n.lastModifiedColumn,
        field: 'modified',
        type: TrinaColumnType.date(),
        enableEditingMode: false,
        width: 150,
        minWidth: 110,
        renderer: (ctx) {
          final value = ctx.cell.value;
          if (value is! DateTime) return const Text('');
          return Text(widget.dateFormat.format(value));
        },
      ),
      TrinaColumn(
        title: '',
        field: 'actions',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        enableSorting: false,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableFilterMenuItem: false,
        width: 150,
        minWidth: 150,
        frozen: TrinaColumnFrozen.end,
        renderer: (ctx) {
          final project = _projectOf(ctx);
          if (project == null) return const SizedBox.shrink();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: l10n.tooltipLaunchInDaw,
                visualDensity: VisualDensity.compact,
                onPressed: widget.onLaunch == null
                    ? null
                    : () => widget.onLaunch!(project),
              ),
              IconButton(
                icon: const Icon(Icons.assignment, size: 18),
                tooltip: l10n.tooltipViewDetails,
                visualDensity: VisualDensity.compact,
                onPressed: () => widget.onViewDetails(project),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                color: Colors.red.shade300,
                tooltip: l10n.tooltipRemoveFromRelease,
                visualDensity: VisualDensity.compact,
                onPressed: () => widget.onRemoveFromRelease(project),
              ),
            ],
          );
        },
      ),
    ];

    return TrinaGrid(
      columns: columns,
      rows: _mapToRows(widget.projects),
      columnMenuDelegate: const FitAllColumnsMenuDelegate(),
      onLoaded: (event) {
        _stateManager = event.stateManager;
        // Nothing here acts on a cell range, so TrinaGrid's own selection is
        // off — same as every other grid in the app.
        _stateManager!.setSelectingMode(TrinaGridSelectingMode.none);
      },
      onRowDoubleTap: (event) {
        final project = event.row.cells['data']?.value as MusicProject?;
        if (project != null) widget.onViewDetails(project);
      },
      rowColorCallback: (ctx) {
        if (_stateManager?.currentRow == ctx.row) return rowSelectColor;
        return ctx.rowIdx.isOdd ? oddColor : evenColor;
      },
      configuration: TrinaGridConfiguration(
        localeText: trinaGridLocaleTextFor(context),
        style: TrinaGridStyleConfig(
          gridBackgroundColor: theme.cardColor,
          gridBorderColor: theme.dividerColor.withValues(alpha: 0.4),
          borderColor: themeSpec.gridBorderColor(theme.dividerColor),
          gridBorderRadius: BorderRadius.zero,
          rowColor: theme.cardColor,
          cellColorInEditState: theme.cardColor,
          cellColorInReadOnlyState: theme.cardColor,
          columnTextStyle: TextStyle(
            color: theme.textTheme.titleMedium?.color,
            fontWeight: FontWeight.w600,
          ),
          cellTextStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
          columnHeight: 40,
          rowHeight: 42,
          // Transparent so rowColorCallback owns every row background.
          activatedBorderColor: Colors.transparent,
          activatedColor: Colors.transparent,
          inactivatedBorderColor: Colors.transparent,
          iconColor: theme.textTheme.bodyMedium?.color ?? Colors.grey,
          menuBackgroundColor: theme.cardColor,
          oddRowColor: oddColor,
          evenRowColor: evenColor,
        ),
        scrollbar: const TrinaGridScrollbarConfig(showHorizontal: false),
        columnSize: const TrinaGridColumnSizeConfig(
          autoSizeMode: TrinaAutoSizeMode.scale,
          resizeMode: TrinaResizeMode.pushAndPull,
        ),
      ),
    );
  }
}
