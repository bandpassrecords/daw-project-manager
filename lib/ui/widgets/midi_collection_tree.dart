import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/midi_collection.dart';
import '../../models/midi_collection_drag.dart';
import 'midi_clip_list.dart' show MidiClipRowAction;

typedef MidiCanDrop = bool Function(MidiDragData data, MidiDropTarget target);
typedef MidiOnDrop = void Function(MidiDragData data, MidiDropTarget target);

/// Makes [child] draggable as [data]: at once with a mouse, after a long
/// press on a phone ([longPress]), where a plain drag scrolls the list.
Widget midiDragSource({
  required MidiDragData data,
  required Widget child,
  bool longPress = false,
}) {
  final icon = switch (data) {
    MidiFolderDragData() => Icons.folder_outlined,
    _ => Icons.piano,
  };
  final feedback = Builder(
    builder: (context) {
      final theme = Theme.of(context);
      return Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  final dimmed = Opacity(opacity: 0.4, child: child);
  return longPress
      ? LongPressDraggable<MidiDragData>(
          data: data,
          feedback: feedback,
          childWhenDragging: dimmed,
          hitTestBehavior: HitTestBehavior.opaque,
          child: child,
        )
      : Draggable<MidiDragData>(
          data: data,
          feedback: feedback,
          childWhenDragging: dimmed,
          hitTestBehavior: HitTestBehavior.opaque,
          child: child,
        );
}

/// Where a drag can be dropped: lit while something it takes hovers over
/// it — filled, or, with [lineAbove] (a drop between clips), a line along
/// its top. [onHoverHold] runs when a drag rests on it a moment: a folder
/// opens to let it go further in.
class MidiDropZone extends StatefulWidget {
  const MidiDropZone({
    super.key,
    required this.target,
    required this.canDrop,
    required this.onDrop,
    required this.child,
    this.lineAbove = false,
    this.onHoverHold,
  });

  final MidiDropTarget target;
  final MidiCanDrop canDrop;
  final MidiOnDrop onDrop;
  final Widget child;
  final bool lineAbove;
  final VoidCallback? onHoverHold;

  static const holdDelay = Duration(milliseconds: 700);

  @override
  State<MidiDropZone> createState() => _MidiDropZoneState();
}

class _MidiDropZoneState extends State<MidiDropZone> {
  Timer? _hold;

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return DragTarget<MidiDragData>(
      onWillAcceptWithDetails: (details) {
        final ok = widget.canDrop(details.data, widget.target);
        final hold = widget.onHoverHold;
        if (ok && hold != null) {
          _hold?.cancel();
          _hold = Timer(MidiDropZone.holdDelay, hold);
        }
        return ok;
      },
      onLeave: (_) => _hold?.cancel(),
      onAcceptWithDetails: (details) {
        _hold?.cancel();
        widget.onDrop(details.data, widget.target);
      },
      builder: (context, candidates, _) {
        final active = candidates.isNotEmpty;
        if (widget.lineAbove) {
          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: active ? color : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: widget.child,
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.id,
    required this.open,
    required this.visible,
    required this.expandLabel,
    required this.collapseLabel,
    required this.onToggle,
  });

  final String id;
  final bool open;
  final bool visible;
  final String expandLabel;
  final String collapseLabel;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(width: 28);
    return IconButton(
      key: ValueKey('midi-toggle-$id'),
      tooltip: open ? collapseLabel : expandLabel,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      icon: Icon(open ? Icons.expand_more : Icons.chevron_right),
      onPressed: () => onToggle(id),
    );
  }
}

/// A collection's folders and clips as a tree: each folder a row that
/// opens and closes ([expanded], [onToggle]) on its subfolders and clips,
/// indented by depth; the clips of a level ([clipsIn]) after its folders.
/// Starts inside folder [rootFolderId] (null: the whole collection).
///
/// Folders drag (into another folder) and take drops — clips, folders —
/// opening when a drag rests on them. A plain view: the clip rows, the
/// folder menus and what a drop does come from the caller.
class MidiCollectionTree extends StatelessWidget {
  const MidiCollectionTree({
    super.key,
    required this.collection,
    required this.rootFolderId,
    required this.expanded,
    required this.onToggle,
    required this.clipsIn,
    required this.folderActions,
    required this.canDrop,
    required this.onDrop,
    required this.expandLabel,
    required this.collapseLabel,
    required this.moreLabel,
    this.longPressDrag = false,
    this.indent = 20,
  });

  final MidiCollection collection;
  final String? rootFolderId;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;

  /// The clips directly in a folder (null: the top level), or null when
  /// there are none to show.
  final Widget? Function(BuildContext context, String? folderId) clipsIn;
  final List<MidiClipRowAction> Function(MidiCollectionFolder folder)
  folderActions;
  final MidiCanDrop canDrop;
  final MidiOnDrop onDrop;
  final String expandLabel;
  final String collapseLabel;
  final String moreLabel;
  final bool longPressDrag;
  final double indent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: _level(context, collection.folderById(rootFolderId)?.id, 0),
  );

  List<Widget> _level(BuildContext context, String? folderId, int depth) {
    final clips = clipsIn(context, folderId);
    return [
      for (final f in collection.foldersIn(folderId)) ...[
        _folderRow(context, f, depth),
        if (expanded.contains(f.id)) ..._level(context, f.id, depth + 1),
      ],
      if (clips != null)
        Padding(
          padding: EdgeInsets.only(left: depth * indent),
          child: clips,
        ),
    ];
  }

  Widget _folderRow(BuildContext context, MidiCollectionFolder f, int depth) {
    final theme = Theme.of(context);
    final open = expanded.contains(f.id);
    final hasContents =
        collection.foldersIn(f.id).isNotEmpty ||
        collection.itemsIn(f.id).isNotEmpty;
    final count =
        collection.itemsIn(f.id).length + collection.foldersIn(f.id).length;
    final actions = folderActions(f);
    return MidiDropZone(
      key: ValueKey('midi-folder-${f.id}'),
      target: MidiDropTarget(collection.id, folderId: f.id),
      canDrop: canDrop,
      onDrop: onDrop,
      onHoverHold: open ? null : () => onToggle(f.id),
      child: midiDragSource(
        data: MidiFolderDragData(
          collectionId: collection.id,
          folderId: f.id,
          label: f.name,
        ),
        longPress: longPressDrag,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => onToggle(f.id),
          child: Padding(
            padding: EdgeInsets.only(left: depth * indent, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Toggle(
                  id: f.id,
                  open: open,
                  visible: hasContents,
                  expandLabel: expandLabel,
                  collapseLabel: collapseLabel,
                  onToggle: onToggle,
                ),
                Icon(
                  open ? Icons.folder_open_outlined : Icons.folder_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text('$count', style: theme.textTheme.bodySmall),
                if (actions.isNotEmpty)
                  PopupMenuButton<MidiClipRowAction>(
                    key: ValueKey('midi-folder-menu-${f.id}'),
                    tooltip: moreLabel,
                    icon: const Icon(Icons.more_vert),
                    onSelected: (a) => a.onSelected(),
                    itemBuilder: (_) => [
                      for (final a in actions)
                        PopupMenuItem(
                          key: a.id == null
                              ? null
                              : ValueKey('midi-folder-action-${a.id}'),
                          value: a,
                          child: Row(
                            children: [
                              Icon(a.icon, size: 18),
                              const SizedBox(width: 12),
                              Flexible(child: Text(a.label)),
                            ],
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "All clips" plus every collection, and a way to make a new one — a side
/// list on desktop, a row of chips on a phone ([horizontal]).
///
/// On desktop each collection opens ([expanded], [onToggle]) on its
/// folders, as deep as they go; a folder selects that folder of its
/// collection. Collections and folders take drops when [canDrop] and
/// [onDrop] are given — clips dragged from the list beside it — and open
/// when a drag rests on them.
///
/// A plain view: collections, callbacks, no Hive.
class MidiCollectionNavigator extends StatelessWidget {
  const MidiCollectionNavigator({
    super.key,
    required this.allClipsLabel,
    required this.allClipsCount,
    required this.collectionsLabel,
    required this.newCollectionLabel,
    required this.collections,
    required this.selectedId,
    required this.onSelect,
    required this.onNew,
    this.selectedFolderId,
    this.onSelectFolder,
    this.expanded = const {},
    this.onToggle,
    this.canDrop,
    this.onDrop,
    this.expandLabel = '',
    this.collapseLabel = '',
    this.longPressDrag = false,
    this.horizontal = false,
    this.onExpandAll,
    this.onCollapseAll,
    this.expandAllLabel = '',
    this.collapseAllLabel = '',
  });

  final String allClipsLabel;
  final int allClipsCount;
  final String collectionsLabel;
  final String newCollectionLabel;
  final List<MidiCollection> collections;

  /// The collection on show, or null for all clips.
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onNew;

  /// The folder of [selectedId] on show, if one is.
  final String? selectedFolderId;
  final void Function(String collectionId, String folderId)? onSelectFolder;

  /// Open collections and folders, by id.
  final Set<String> expanded;
  final ValueChanged<String>? onToggle;
  final MidiCanDrop? canDrop;
  final MidiOnDrop? onDrop;
  final String expandLabel;
  final String collapseLabel;
  final bool longPressDrag;
  final bool horizontal;

  /// Open or close every collection and folder in the list.
  final VoidCallback? onExpandAll;
  final VoidCallback? onCollapseAll;
  final String expandAllLabel;
  final String collapseAllLabel;

  Widget _dropZone(MidiDropTarget target, Widget child, {VoidCallback? hold}) {
    final can = canDrop;
    final drop = onDrop;
    if (can == null || drop == null) return child;
    return MidiDropZone(
      target: target,
      canDrop: can,
      onDrop: drop,
      onHoverHold: hold,
      child: child,
    );
  }

  Widget _toggle(String id, bool visible) => _Toggle(
    id: id,
    open: expanded.contains(id),
    visible: visible && onToggle != null,
    expandLabel: expandLabel,
    collapseLabel: collapseLabel,
    onToggle: (id) => onToggle?.call(id),
  );

  VoidCallback? _openOnHold(String id) =>
      onToggle == null || expanded.contains(id) ? null : () => onToggle!(id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ChoiceChip(
              label: Text('$allClipsLabel ($allClipsCount)'),
              selected: selectedId == null,
              onSelected: (_) => onSelect(null),
            ),
            for (final c in collections) ...[
              const SizedBox(width: 8),
              _dropZone(
                MidiDropTarget(c.id),
                ChoiceChip(
                  avatar: const Icon(Icons.library_music_outlined, size: 16),
                  label: Text('${c.name} (${c.items.length})'),
                  selected: selectedId == c.id,
                  onSelected: (_) => onSelect(c.id),
                ),
              ),
            ],
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text(newCollectionLabel),
              onPressed: onNew,
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.piano),
          title: Text(allClipsLabel),
          trailing: Text('$allClipsCount', style: theme.textTheme.bodySmall),
          selected: selectedId == null,
          onTap: () => onSelect(null),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  collectionsLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (onExpandAll != null &&
                  collections.any((c) => c.folders.isNotEmpty)) ...[
                IconButton(
                  key: const ValueKey('midi-nav-expand-all'),
                  tooltip: expandAllLabel,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.unfold_more, size: 20),
                  onPressed: onExpandAll,
                ),
                IconButton(
                  key: const ValueKey('midi-nav-collapse-all'),
                  tooltip: collapseAllLabel,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.unfold_less, size: 20),
                  onPressed: onCollapseAll,
                ),
              ],
              IconButton(
                tooltip: newCollectionLabel,
                icon: const Icon(Icons.add, size: 20),
                onPressed: onNew,
              ),
            ],
          ),
        ),
        for (final c in collections) ...[
          _dropZone(
            MidiDropTarget(c.id),
            hold: c.folders.isEmpty ? null : _openOnHold(c.id),
            ListTile(
              key: ValueKey('midi-nav-${c.id}'),
              dense: true,
              contentPadding: const EdgeInsets.only(left: 4, right: 16),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toggle(c.id, c.folders.isNotEmpty),
                  const Icon(Icons.library_music_outlined),
                ],
              ),
              title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(
                '${c.items.length}',
                style: theme.textTheme.bodySmall,
              ),
              selected: selectedId == c.id && selectedFolderId == null,
              onTap: () => onSelect(c.id),
            ),
          ),
          if (expanded.contains(c.id)) ..._folders(context, c, null, 1),
        ],
      ],
    );
  }

  List<Widget> _folders(
    BuildContext context,
    MidiCollection c,
    String? parentId,
    int depth,
  ) {
    final theme = Theme.of(context);
    return [
      for (final f in c.foldersIn(parentId)) ...[
        _dropZone(
          MidiDropTarget(c.id, folderId: f.id),
          hold: c.foldersIn(f.id).isEmpty ? null : _openOnHold(f.id),
          ListTile(
            key: ValueKey('midi-nav-folder-${f.id}'),
            dense: true,
            contentPadding: EdgeInsets.only(left: 4.0 + 16 * depth, right: 16),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toggle(f.id, c.foldersIn(f.id).isNotEmpty),
                Icon(
                  expanded.contains(f.id)
                      ? Icons.folder_open_outlined
                      : Icons.folder_outlined,
                  size: 20,
                ),
              ],
            ),
            title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(
              '${c.itemsIn(f.id).length}',
              style: theme.textTheme.bodySmall,
            ),
            selected: selectedId == c.id && selectedFolderId == f.id,
            onTap: () => onSelectFolder?.call(c.id, f.id),
          ),
        ),
        if (expanded.contains(f.id)) ..._folders(context, c, f.id, depth + 1),
      ],
    ];
  }
}
