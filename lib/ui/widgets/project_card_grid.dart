import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/music_project.dart';
import '../../utils/daw_logo.dart';
import '../../utils/project_accent_color.dart';

/// The dashboard's card/gallery view: the same projects the table shows, drawn
/// cover-first (#111).
///
/// A plain view widget — every string, colour rule and action arrives as a
/// parameter, and it never touches a provider, Hive or a `Ref`. That is what
/// lets the layout be widget-tested directly, and it keeps the one filtering
/// and sorting path in `projectsProvider`: this widget renders exactly the
/// list it is handed, in the order it is handed, and has no opinion about it.
///
/// Selection deliberately behaves like a table row rather than like a phone's
/// photo grid: a plain click only moves the highlight, ctrl/cmd- and
/// shift-click go through the same [RowClickSelectionController] the grid
/// uses, and the per-card checkbox is the unmodified toggle. Anything else
/// would mean two different selection models for one selection.
class ProjectCardGrid extends StatefulWidget {
  const ProjectCardGrid({
    super.key,
    required this.projects,
    required this.selectedIds,
    required this.phaseColor,
    required this.phaseLabel,
    required this.dateFormat,
    required this.fileExists,
    required this.labels,
    required this.onOpen,
    required this.onToggleSelection,
    required this.onRowClick,
    required this.onHighlight,
    required this.onContextMenu,
    required this.onPrimaryAction,
    required this.onOpenFolder,
    required this.onPlayPreview,
    this.activeProjectId,
    this.sessionMode = false,
    this.selectionModifierHeld = _noModifier,
  });

  /// Filtered and sorted upstream — rendered verbatim.
  final List<MusicProject> projects;

  /// Ids currently checked, shared with the table's selection.
  final Set<String> selectedIds;

  /// Project whose work session is running, if any — drawn with the same
  /// emphasis the table gives its active row.
  final String? activeProjectId;

  final Color Function(String phase) phaseColor;
  final String Function(String phase) phaseLabel;
  final String Function(DateTime) dateFormat;

  /// Whether the project's file is still on this machine. Injected rather than
  /// stat'ed here so a widget test never touches the filesystem.
  final bool Function(MusicProject) fileExists;

  final ProjectCardLabels labels;

  /// Double-click / double-tap, and the context menu's "view details".
  final void Function(MusicProject) onOpen;

  /// The card's own checkbox: an unmodified toggle of one id.
  final void Function(String id) onToggleSelection;

  /// A modifier-held click anywhere on the card — ctrl/cmd or shift.
  final void Function(String id) onRowClick;

  /// A plain click: moves the highlight, leaves the checkboxes alone.
  final void Function(String id) onHighlight;

  final void Function(MusicProject, Offset globalPosition) onContextMenu;

  /// The card's first action icon: launch in the DAW, or — while work sessions
  /// are being tracked — start/end the session on it, exactly as the grid row
  /// and the context menu behave.
  final void Function(MusicProject) onPrimaryAction;

  final void Function(MusicProject) onOpenFolder;
  final void Function(MusicProject) onPlayPreview;

  /// Whether session tracking is on, which changes what the first icon means.
  final bool sessionMode;

  /// Whether a selection modifier key is down right now. Injected so tests can
  /// drive both click paths without synthesising hardware key events.
  final bool Function() selectionModifierHeld;

  static bool _noModifier() => false;

  @override
  State<ProjectCardGrid> createState() => _ProjectCardGridState();
}

/// Every user-visible string the card grid needs, resolved by the caller.
///
/// Same arrangement as `ProjectVersionsSection`: `AppLocalizations` lives in
/// the page, so the widget stays testable without a localisation delegate.
class ProjectCardLabels {
  const ProjectCardLabels({
    required this.emptyMessage,
    required this.selectTooltip,
    required this.missingFileTooltip,
    required this.bpmTooltip,
    required this.keyTooltip,
    required this.today,
    required this.daysLeft,
    required this.daysLate,
    required this.launchTooltip,
    required this.startSessionTooltip,
    required this.endSessionTooltip,
    required this.openFolderTooltip,
    required this.playPreviewTooltip,
  });

  final String emptyMessage;
  final String selectTooltip;
  final String missingFileTooltip;
  final String Function(String bpm) bpmTooltip;
  final String Function(String key) keyTooltip;
  final String today;
  final String Function(int days) daysLeft;
  final String Function(int days) daysLate;
  final String launchTooltip;
  final String startSessionTooltip;
  final String endSessionTooltip;
  final String openFolderTooltip;
  final String playPreviewTooltip;
}

class _ProjectCardGridState extends State<ProjectCardGrid> {
  /// The card the user is "on". Purely visual, and local for the same reason
  /// the table's highlight is: it is interaction state, not part of the
  /// selection the bulk actions run against.
  String? _highlightedId;

  void _handleTapDown(MusicProject project) {
    if (widget.selectionModifierHeld()) {
      widget.onRowClick(project.id);
      return;
    }
    setState(() => _highlightedId = project.id);
    widget.onHighlight(project.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.labels.emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // Cover square-ish on top, three short lines of metadata under it.
        childAspectRatio: 0.72,
      ),
      itemCount: widget.projects.length,
      itemBuilder: (context, index) {
        final project = widget.projects[index];
        return _ProjectCard(
          project: project,
          selected: widget.selectedIds.contains(project.id),
          highlighted: _highlightedId == project.id,
          active: widget.activeProjectId == project.id,
          phaseColor: widget.phaseColor(project.status),
          phaseLabel: widget.phaseLabel(project.status),
          modifiedLabel: widget.dateFormat(project.lastModifiedAt),
          fileExists: widget.fileExists(project),
          labels: widget.labels,
          onTapDown: () => _handleTapDown(project),
          onDoubleTap: () => widget.onOpen(project),
          onToggleSelection: () => widget.onToggleSelection(project.id),
          onContextMenu: (position) => widget.onContextMenu(project, position),
          sessionMode: widget.sessionMode,
          onPrimaryAction: () => widget.onPrimaryAction(project),
          onOpenFolder: () => widget.onOpenFolder(project),
          onPlayPreview: () => widget.onPlayPreview(project),
        );
      },
    );
  }
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    required this.project,
    required this.selected,
    required this.highlighted,
    required this.active,
    required this.phaseColor,
    required this.phaseLabel,
    required this.modifiedLabel,
    required this.fileExists,
    required this.labels,
    required this.onTapDown,
    required this.onDoubleTap,
    required this.onToggleSelection,
    required this.onContextMenu,
    required this.sessionMode,
    required this.onPrimaryAction,
    required this.onOpenFolder,
    required this.onPlayPreview,
  });

  final MusicProject project;
  final bool selected;
  final bool highlighted;
  final bool active;
  final Color phaseColor;
  final String phaseLabel;
  final String modifiedLabel;
  final bool fileExists;
  final ProjectCardLabels labels;
  final VoidCallback onTapDown;
  final VoidCallback onDoubleTap;
  final VoidCallback onToggleSelection;
  final void Function(Offset globalPosition) onContextMenu;
  final bool sessionMode;
  final VoidCallback onPrimaryAction;
  final VoidCallback onOpenFolder;
  final VoidCallback onPlayPreview;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = widget.project;
    final accent = projectAccentColor(project.id);
    final borderColor = widget.selected
        ? theme.colorScheme.primary
        : widget.active
        ? Colors.green.shade400
        : widget.highlighted
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Pointer-down, like the table: the click-selection controller needs
        // the anchor and the previous highlight as they were before this click.
        onTapDown: (_) => widget.onTapDown(),
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTapDown: (d) => widget.onContextMenu(d.globalPosition),
        // A long-press is the touch equivalent of a right-click; desktop
        // users never reach it, and it costs nothing to support.
        onLongPressStart: (d) => widget.onContextMenu(d.globalPosition),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: _hovered ? 6 : 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: borderColor,
              width: widget.selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildCover(context, accent)),
              _buildFooter(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, Color accent) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCoverArt(accent),
        // Checkbox top-left, always visible: multi-select has to be findable
        // without first discovering that ctrl-click does something.
        Positioned(
          top: 2,
          left: 2,
          child: Tooltip(
            message: widget.labels.selectTooltip,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Checkbox(
                value: widget.selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) => widget.onToggleSelection(),
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_deadlineDays != null) _buildDeadlineChip(_deadlineDays!),
              // isMissingFileCandidate keeps this off stacks: their path is a
              // folder, so "no file here" is normal, not a missing file.
              if (!widget.fileExists && widget.project.isMissingFileCandidate)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Tooltip(
                    message: widget.labels.missingFileTooltip,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.cloud_off,
                        size: 14,
                        color: Colors.orange.shade400,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildActionBar(context),
        ),
      ],
    );
  }

  /// Launch / reveal / play, small and always visible along the foot of the
  /// cover rather than in the footer: the metadata block under it has a fixed
  /// height, and dropping a row of buttons into it would either grow every
  /// card or squeeze the name.
  Widget _buildActionBar(BuildContext context) {
    final project = widget.project;
    final isActiveSession = widget.sessionMode && widget.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionIcon(
            icon: widget.sessionMode
                ? (isActiveSession
                      ? Icons.bookmark
                      : Icons.bookmark_add_outlined)
                : Icons.open_in_new,
            tooltip: widget.sessionMode
                ? (isActiveSession
                      ? widget.labels.endSessionTooltip
                      : widget.labels.startSessionTooltip)
                : widget.labels.launchTooltip,
            onPressed: widget.onPrimaryAction,
          ),
          _actionIcon(
            icon: Icons.folder_open,
            tooltip: widget.labels.openFolderTooltip,
            onPressed: widget.onOpenFolder,
          ),
          _actionIcon(
            icon: Icons.play_arrow,
            tooltip: widget.labels.playPreviewTooltip,
            onPressed: widget.onPlayPreview,
            // Same three-state colouring the mobile list uses: green for a
            // preview the user set, amber for an auto-detected mixdown, grey
            // when neither is known yet.
            color: project.previewSongPath?.isNotEmpty == true
                ? Colors.greenAccent.shade100
                : project.previewSongAutoPath != null
                ? Colors.amberAccent.shade100
                : Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(icon, size: 16, color: color ?? Colors.white),
        ),
      ),
    );
  }

  /// The cover art if the project has one, otherwise its generated identity:
  /// an accent wash with the name's initials and, when the DAW is known, its
  /// logo. Cover art wins over the generated colour, per #110.
  Widget _buildCoverArt(Color accent) {
    final thumbnail = widget.project.thumbnailPath;
    if (thumbnail != null &&
        thumbnail.isNotEmpty &&
        File(thumbnail).existsSync()) {
      return Image.file(
        File(thumbnail),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildGeneratedCover(accent),
      );
    }
    return _buildGeneratedCover(accent);
  }

  Widget _buildGeneratedCover(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.45)!],
        ),
      ),
      child: Center(
        child: Text(
          // A label the user typed wins over the one derived from the name.
          projectCardInitials(
            widget.project.cardInitials,
            widget.project.displayName,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  int? get _deadlineDays => widget.project.daysUntilDeadline;

  Widget _buildDeadlineChip(int days) {
    final color = days < 0
        ? Colors.red
        : days == 0
        ? Colors.red
        : days <= 7
        ? Colors.orange
        : Colors.blue;
    final label = days < 0
        ? widget.labels.daysLate(days.abs())
        : days == 0
        ? widget.labels.today
        : widget.labels.daysLeft(days);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            days < 0
                ? Icons.warning
                : days == 0
                ? Icons.today
                : Icons.schedule,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    final project = widget.project;
    final logoPath = getDawLogoPath(project.dawType);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Always two lines tall, whether the name needs one or two: the
          // cover above is what takes up the slack, so a long name can't make
          // one card taller than its neighbours.
          SizedBox(
            height: _nameBlockHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.isVirtual) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 4),
                    child: Icon(
                      Icons.layers,
                      size: 13,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    project.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: _nameLineHeight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.phaseColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.phaseLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.phaseColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (logoPath != null)
                Image.asset(
                  logoPath,
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.piano,
                    size: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (project.bpm != null)
                _badge(
                  theme,
                  _formatBpm(project.bpm!),
                  tooltip: widget.labels.bpmTooltip(_formatBpm(project.bpm!)),
                ),
              if (project.bpm != null && project.camelotCode != null)
                const SizedBox(width: 4),
              if (project.camelotCode != null)
                _badge(
                  theme,
                  project.camelotCode!,
                  tooltip: widget.labels.keyTooltip(project.musicalKey!),
                ),
              const Spacer(),
              Flexible(
                child: Text(
                  widget.modifiedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(ThemeData theme, String text, {required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// Two lines of the name style, so the block is the same height on every
  /// card. Scaled with the platform text size so a larger accessibility
  /// setting still fits two lines rather than clipping one.
  double get _nameBlockHeight {
    final fontSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? _nameFontFallback;
    final scaled = MediaQuery.textScalerOf(context).scale(fontSize);
    return scaled * _nameLineHeight * 2;
  }

  static const double _nameLineHeight = 1.25;
  static const double _nameFontFallback = 14.0;

  /// "128", not "128.0" — same rule the active-project chip uses.
  String _formatBpm(double bpm) =>
      bpm % 1 == 0 ? bpm.toInt().toString() : bpm.toStringAsFixed(1);
}
