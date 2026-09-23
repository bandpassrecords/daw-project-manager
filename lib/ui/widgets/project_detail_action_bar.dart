import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/project_detail_layout.dart';

/// The bar under the project detail page's title: the layout switch on the
/// left, the project's actions on the right.
///
/// The actions are grouped rather than laid out as a row of equal buttons:
/// launching (or the session buttons) is the one filled button, Open folder
/// stays visible because it is the other thing people reach for constantly,
/// and the rest sit behind two menus — **File** for what changes the files on
/// disk (rename, move, archive/restore) and **⋯** for everything about the
/// project record (stats, export, save as template).
///
/// Takes plain values and callbacks — no `Ref`, no Hive — so it can be
/// widget-tested; the page resolves session state and wires the callbacks.
/// Desktop only: on mobile the page does not build it at all.
class ProjectDetailActionBar extends StatelessWidget {
  const ProjectDetailActionBar({
    super.key,
    required this.layout,
    required this.onLayoutChanged,
    required this.sourceFileExists,
    required this.isVirtual,
    required this.isArchived,
    required this.sessionMode,
    required this.isSubscribed,
    required this.onStartSession,
    required this.onEndSession,
    required this.onOpenInDaw,
    required this.onOpenFolder,
    required this.onRename,
    required this.onMove,
    required this.onArchive,
    required this.onRestore,
    required this.onStats,
    required this.onExport,
    required this.onSaveAsTemplate,
  });

  final ProjectDetailLayout layout;
  final ValueChanged<ProjectDetailLayout> onLayoutChanged;

  /// False when the project's file does not resolve on this machine; every
  /// action that needs the file is then disabled with an explanation.
  final bool sourceFileExists;

  /// A version stack owns no file, so it cannot be moved or archived.
  final bool isVirtual;
  final bool isArchived;

  /// Session mode swaps "Launch in DAW" for Start/End session, exactly as the
  /// dashboard row and the context menu do.
  final bool sessionMode;

  /// Whether this project is the one with the running session.
  final bool isSubscribed;

  final VoidCallback onStartSession;
  final VoidCallback onEndSession;
  final VoidCallback onOpenInDaw;
  final VoidCallback onOpenFolder;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onStats;
  final VoidCallback onExport;
  final VoidCallback onSaveAsTemplate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notFound = l10n.sourceFileNotFoundOnThisMachine;

    // Wraps a control that needs the file, explaining why it is greyed out.
    Widget needsFile(Widget child) => sourceFileExists
        ? child
        : Tooltip(message: notFound, child: child);

    final launch = needsFile(FilledButton.icon(
      onPressed: sourceFileExists ? onOpenInDaw : null,
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(l10n.openInDaw),
    ));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Same preference as Settings > Appearance, reachable from the page
          // it actually changes.
          SegmentedButton<ProjectDetailLayout>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: [
              ButtonSegment(
                value: ProjectDetailLayout.classic,
                icon: const Icon(Icons.view_stream_outlined, size: 18),
                tooltip: l10n.projectDetailLayoutClassic,
              ),
              ButtonSegment(
                value: ProjectDetailLayout.sectioned,
                icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                tooltip: l10n.projectDetailLayoutSectioned,
              ),
            ],
            selected: {layout},
            onSelectionChanged: (s) => onLayoutChanged(s.first),
          ),
          const SizedBox(width: 12),
          Expanded(
            // Wrap, not Row: on a narrow window the buttons reflow instead of
            // overflowing.
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                if (sessionMode) ...[
                  OutlinedButton.icon(
                    onPressed: isSubscribed ? onEndSession : onStartSession,
                    icon: Icon(
                      isSubscribed
                          ? Icons.bookmark
                          : Icons.bookmark_add_outlined,
                      size: 16,
                      color: isSubscribed ? Colors.green.shade400 : null,
                    ),
                    label: Text(
                        isSubscribed ? l10n.endSession : l10n.startSession),
                  ),
                  // Once this project's session is running, still let the
                  // user launch the DAW from here.
                  if (isSubscribed) launch,
                ] else
                  launch,
                needsFile(OutlinedButton.icon(
                  onPressed: sourceFileExists ? onOpenFolder : null,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: Text(l10n.openFolder),
                )),
                _fileMenu(l10n, needsFile),
                _moreMenu(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileMenu(
    AppLocalizations l10n,
    Widget Function(Widget) needsFile,
  ) {
    return MenuAnchor(
      menuChildren: [
        needsFile(MenuItemButton(
          leadingIcon: const Icon(Icons.drive_file_rename_outline, size: 18),
          onPressed: sourceFileExists ? onRename : null,
          child: Text(l10n.renameFileButtonLabel),
        )),
        // A stack owns no file of its own, so there is nothing to move or
        // archive — its versions are handled from their own pages.
        if (!isVirtual) ...[
          needsFile(MenuItemButton(
            leadingIcon: const Icon(Icons.drive_file_move_outline, size: 18),
            onPressed: sourceFileExists ? onMove : null,
            child: Text(l10n.moveProjectButtonLabel),
          )),
          // Restoring reads the archive, not the original file, so it never
          // needs the source to exist — that is the whole point of it.
          if (isArchived)
            MenuItemButton(
              leadingIcon: const Icon(Icons.unarchive_outlined, size: 18),
              onPressed: onRestore,
              child: Text(l10n.restoreProjectButtonLabel),
            )
          else
            needsFile(MenuItemButton(
              leadingIcon: const Icon(Icons.archive_outlined, size: 18),
              onPressed: sourceFileExists ? onArchive : null,
              child: Text(l10n.archiveProjectButtonLabel),
            )),
        ],
      ],
      builder: (context, controller, _) => OutlinedButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.insert_drive_file_outlined, size: 16),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.projectFileMenu),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _moreMenu(AppLocalizations l10n) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.bar_chart, size: 18),
          onPressed: onStats,
          child: Text(l10n.statsSingleProjectActivity),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.description_outlined, size: 18),
          onPressed: onExport,
          child: Text(l10n.exportProjectInfo),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.bookmark_add_outlined, size: 18),
          onPressed: onSaveAsTemplate,
          child: Text(l10n.saveAsTemplate),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: l10n.moreActions,
        icon: const Icon(Icons.more_horiz),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
