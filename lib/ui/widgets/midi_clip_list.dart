import 'package:flutter/material.dart';

import '../../models/midi_clip.dart';
import '../../services/midi/synth_voice.dart';

/// Localized strings for [MidiClipList], resolved by the page.
class MidiClipListLabels {
  const MidiClipListLabels({
    required this.play,
    required this.stop,
    required this.save,
    required this.share,
    required this.instrument,
    required this.voiceName,
    required this.dragTooltip,
    required this.bars,
    required this.notes,
    required this.usedTimes,
    required this.alsoAs,
    required this.noTrack,
    required this.expandTrack,
    required this.collapseTrack,
    this.addToCollection = '',
    this.removeFromCollection = '',
    this.more = '',
    this.openPianoRoll = '',
    this.openProject = '',
  });

  final String play;
  final String stop;
  final String save;
  final String share;

  /// Tooltip on the instrument picker, given the current voice's name.
  final String Function(String name) instrument;
  final String Function(SynthVoice voice) voiceName;
  final String dragTooltip;
  final String Function(int count) bars;
  final String Function(int count) notes;
  final String Function(int count) usedTimes;

  /// Tooltip listing the other clips merged into this one.
  final String Function(String names) alsoAs;

  /// Heading for the clips no group label could be found for.
  final String noTrack;
  final String expandTrack;
  final String collapseTrack;
  final String addToCollection;
  final String removeFromCollection;

  /// Tooltip on the compact layout's overflow menu.
  final String more;

  /// Tooltip on the thumbnail when tapping it opens the piano roll.
  final String openPianoRoll;
  final String openProject;
}

/// A list of MIDI clips: per clip a piano-roll thumbnail, its name, length
/// and note count, and play / instrument / share / save / drag.
///
/// Grouped under collapsible headers by [groupLabelOf] — the track on a
/// project page (the default), the project in the MIDI library — or not at
/// all when [grouped] is false, as in a collection. When grouped, every group
/// starts open while the whole list is short; past [expandAllUpTo] clips they
/// start collapsed, so the headers read as an overview.
///
/// [compact] is for phones: a smaller thumbnail, and everything but play in
/// one overflow menu, so a row keeps room for its name.
///
/// A plain view: it owns no player and touches no files. [dragHandleBuilder]
/// wraps the drag handle in whatever makes it draggable (the page passes a
/// `DragItemWidget`, which needs a native plugin and so can't run in widget
/// tests); null hides the handle, as on mobile.
/// One more thing a row can do — a collection's rename, role, move… —
/// listed in the row's menu.
class MidiClipRowAction {
  const MidiClipRowAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.id,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;

  /// Names the menu entry for tests (`midi-row-action-<id>`).
  final String? id;
}

class MidiClipList extends StatefulWidget {
  const MidiClipList({
    super.key,
    required this.clips,
    required this.labels,
    required this.onPlay,
    required this.onShare,
    required this.voiceOf,
    required this.onVoiceChanged,
    this.onSave,
    this.onAddToCollection,
    this.onRemove,
    this.onOpen,
    this.onOpenProject,
    this.canOpenProjectOf,
    this.playingIndex,
    this.preparingIndex,
    this.dragHandleBuilder,
    this.groupLabelOf,
    this.grouped = true,
    this.detailPrefixOf,
    this.compact = false,
    this.expandAllUpTo = 12,
    this.titleOf,
    this.fileNameOf,
    this.actionsOf,
    this.grabWrapper,
    this.rowWrapper,
    this.groupOpen,
    this.onGroupToggled,
  });

  final List<MidiClip> clips;
  final MidiClipListLabels labels;

  /// Starts — or, for the playing clip, stops — the preview of clip [index].
  final void Function(int index) onPlay;

  /// [origin] is the share button's on-screen rect, for anchoring the share
  /// popover on macOS and iPad.
  final void Function(int index, Rect? origin) onShare;

  /// Null hides Save — on a phone the share sheet already offers "Save to
  /// Files", and the row needs the room.
  final void Function(int index)? onSave;

  /// Null hides "Add to collection". [origin] anchors the collection menu.
  final void Function(int index, Rect? origin)? onAddToCollection;

  /// Null hides "Remove from collection".
  final void Function(int index)? onRemove;

  /// Opens clip [index] in a large piano roll; the thumbnail becomes the way
  /// in. Null leaves the thumbnail inert.
  final void Function(int index)? onOpen;

  /// Opens the project clip [index] came from. Null hides it — on that
  /// project's own page there is nowhere to go.
  final void Function(int index)? onOpenProject;

  /// Whether clip [index] has a project to open — false for a clip imported
  /// from a file. Null means every clip has one.
  final bool Function(int index)? canOpenProjectOf;

  /// Whether row [index] offers "Open project".
  bool canOpenProject(int index) =>
      onOpenProject != null && (canOpenProjectOf?.call(index) ?? true);

  /// The voice clip [index] plays with (inferred or picked).
  final SynthVoice Function(int index) voiceOf;
  final void Function(int index, SynthVoice voice) onVoiceChanged;

  /// The clip whose preview is playing, if any.
  final int? playingIndex;

  /// The clip whose preview is being rendered, if any.
  final int? preparingIndex;

  final Widget Function(BuildContext context, int index, Widget handle)?
  dragHandleBuilder;

  /// The heading clip [index] is listed under; defaults to its track.
  final String? Function(int index)? groupLabelOf;
  final bool grouped;

  /// Shown first in a row's details line — the track in the library, where
  /// the group heading is the project.
  final String? Function(int index)? detailPrefixOf;

  final bool compact;
  final int expandAllUpTo;

  /// The row's name in place of the clip's (a collection item's own).
  final String Function(int index)? titleOf;

  /// The file the clip exports as, shown under its details.
  final String? Function(int index)? fileNameOf;

  /// More things the row can do, in its menu (desktop: a menu button of
  /// its own; phone: after the rest of the overflow menu).
  final List<MidiClipRowAction> Function(int index)? actionsOf;

  /// Wraps the part of a row that drags — its thumbnail and names — in
  /// what makes it draggable (moving it into a folder or collection). The
  /// handle, when there is one, still drags the file out of the app.
  final Widget Function(BuildContext context, int index, Widget child)?
  grabWrapper;

  /// Wraps a whole row — a drop target that puts what is dropped before it.
  final Widget Function(BuildContext context, int index, Widget row)?
  rowWrapper;

  /// Whether the caller keeps group [label] open or closed — null: the
  /// list's default. With [onGroupToggled], the caller keeps the groups'
  /// state (between runs, say) instead of the list.
  final bool? Function(String? label)? groupOpen;
  final void Function(String? label, bool open)? onGroupToggled;

  @override
  State<MidiClipList> createState() => _MidiClipListState();
}

/// Whether [a] and [b] hold the same clips in the same order — the same
/// objects, which is what a page rebuilding its list from the same data
/// hands over. Cheap: no content keys are computed.
@visibleForTesting
bool sameClips(List<MidiClip> a, List<MidiClip> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}

class _MidiClipListState extends State<MidiClipList> {
  /// Groups the user toggled away from the default state.
  final Set<String?> _toggled = {};

  bool _isOpen(String? label) {
    final byDefault = widget.clips.length <= widget.expandAllUpTo;
    if (widget.onGroupToggled != null) {
      return widget.groupOpen?.call(label) ?? byDefault;
    }
    return _toggled.contains(label) ? !byDefault : byDefault;
  }

  @override
  void didUpdateWidget(MidiClipList old) {
    super.didUpdateWidget(old);
    // A different set of clips (another collection, a new read) starts from
    // the defaults again. The same clips in a new list do not: pages build
    // the list afresh on every rebuild — starting playback is one — and
    // resetting then folded up the group the user had just opened.
    if (!sameClips(old.clips, widget.clips)) _toggled.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.grouped) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.clips.length; i++) _row(context, i),
        ],
      );
    }
    final labelOf = widget.groupLabelOf ?? (int i) => widget.clips[i].trackName;
    final groups = groupMidiClips(widget.clips.length, labelOf);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final group in groups) ...[
          _header(context, group),
          if (_isOpen(group.label))
            Padding(
              padding: EdgeInsets.only(left: widget.compact ? 4 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [for (final i in group.clipIndices) _row(context, i)],
              ),
            ),
        ],
      ],
    );
  }

  Widget _header(BuildContext context, MidiClipGroup group) {
    final theme = Theme.of(context);
    final open = _isOpen(group.label);
    final name = group.label ?? widget.labels.noTrack;
    return Tooltip(
      message: open ? widget.labels.collapseTrack : widget.labels.expandTrack,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          final kept = widget.onGroupToggled;
          if (kept != null) {
            kept(group.label, !open);
            return;
          }
          setState(() {
            if (!_toggled.remove(group.label)) _toggled.add(group.label);
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                open ? Icons.expand_more : Icons.chevron_right,
                size: 18,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Icon(Icons.piano, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontStyle: group.label == null ? FontStyle.italic : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Just the number — no string to translate.
              Text(
                '${group.clipIndices.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int index) {
    final theme = Theme.of(context);
    final clip = widget.clips[index];
    final labels = widget.labels;
    final playing = widget.playingIndex == index;
    final preparing = widget.preparingIndex == index;
    final compact = widget.compact;

    // Rounded up: a 4-bar clip trimmed by a tick is still "4 bars".
    final bars = (clip.lengthBeats / 4).ceil().clamp(1, 1 << 20);
    final prefix = widget.detailPrefixOf?.call(index);
    final details = <String>[
      if (prefix != null && prefix.isNotEmpty) prefix,
      labels.bars(bars),
      labels.notes(clip.notes.length),
      if (clip.occurrences > 1) labels.usedTimes(clip.occurrences),
    ];
    final title =
        widget.titleOf?.call(index) ??
        (clip.name.isNotEmpty ? clip.name : (clip.trackName ?? ''));
    final fileName = widget.fileNameOf?.call(index);
    final actions =
        widget.actionsOf?.call(index) ?? const <MidiClipRowAction>[];

    final handle = widget.dragHandleBuilder;
    final playButton = preparing
        ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : IconButton(
            tooltip: playing ? labels.stop : labels.play,
            icon: Icon(
              playing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            ),
            onPressed: () => widget.onPlay(index),
          );

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (handle != null)
            handle(
              context,
              index,
              Tooltip(
                message: labels.dragTooltip,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _grab(
              context,
              index,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _openable(
                    index,
                    MidiClipThumbnail(
                      clip: clip,
                      width: compact ? 44 : 72,
                      height: compact ? 28 : 32,
                      color: playing
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _maybeTooltip(
                          clip.otherNames.isEmpty
                              ? null
                              : labels.alsoAs(clip.otherNames.join(', ')),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          details.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (fileName != null)
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          playButton,
          if (compact)
            _overflowMenu(context, index)
          else ...[
            MidiVoicePicker(
              voice: widget.voiceOf(index),
              voiceName: labels.voiceName,
              tooltip: labels.instrument,
              onChanged: (v) => widget.onVoiceChanged(index, v),
            ),
            if (widget.onAddToCollection != null)
              Builder(
                builder: (buttonContext) => IconButton(
                  tooltip: labels.addToCollection,
                  icon: const Icon(Icons.playlist_add),
                  onPressed: () =>
                      widget.onAddToCollection!(index, _rectOf(buttonContext)),
                ),
              ),
            if (widget.onRemove != null)
              IconButton(
                tooltip: labels.removeFromCollection,
                icon: const Icon(Icons.playlist_remove),
                onPressed: () => widget.onRemove!(index),
              ),
            Builder(
              builder: (buttonContext) => IconButton(
                tooltip: labels.share,
                icon: const Icon(Icons.share_outlined),
                onPressed: () => widget.onShare(index, _rectOf(buttonContext)),
              ),
            ),
            if (widget.canOpenProject(index))
              IconButton(
                tooltip: labels.openProject,
                icon: const Icon(Icons.assignment),
                onPressed: () => widget.onOpenProject!(index),
              ),
            if (widget.onSave != null)
              IconButton(
                tooltip: labels.save,
                icon: const Icon(Icons.save_alt),
                onPressed: () => widget.onSave!(index),
              ),
            if (actions.isNotEmpty)
              PopupMenuButton<MidiClipRowAction>(
                key: ValueKey('midi-row-actions-$index'),
                tooltip: labels.more,
                icon: const Icon(Icons.more_vert),
                onSelected: (a) => a.onSelected(),
                itemBuilder: (_) => [for (final a in actions) _actionItem(a)],
              ),
          ],
        ],
      ),
    );
    return widget.rowWrapper?.call(context, index, row) ?? row;
  }

  Widget _grab(BuildContext context, int index, Widget child) =>
      widget.grabWrapper?.call(context, index, child) ?? child;

  Widget _openable(int index, Widget thumbnail) {
    final onOpen = widget.onOpen;
    if (onOpen == null) return thumbnail;
    return Tooltip(
      message: widget.labels.openPianoRoll,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => onOpen(index),
        child: thumbnail,
      ),
    );
  }

  /// Phones: instrument, collection, share and save behind one button.
  Widget _overflowMenu(BuildContext context, int index) {
    final labels = widget.labels;
    final actions =
        widget.actionsOf?.call(index) ?? const <MidiClipRowAction>[];
    return Builder(
      builder: (menuContext) => PopupMenuButton<Object>(
        key: ValueKey('midi-row-actions-$index'),
        tooltip: labels.more,
        icon: const Icon(Icons.more_vert),
        onSelected: (selected) async {
          final origin = _rectOf(menuContext);
          if (selected is MidiClipRowAction) {
            selected.onSelected();
            return;
          }
          switch (selected as _RowAction) {
            case _RowAction.instrument:
              final voice = await showDialog<SynthVoice>(
                context: context,
                builder: (_) => _VoiceDialog(
                  current: widget.voiceOf(index),
                  labels: labels,
                ),
              );
              if (voice != null) widget.onVoiceChanged(index, voice);
            case _RowAction.share:
              widget.onShare(index, origin);
            case _RowAction.add:
              widget.onAddToCollection?.call(index, origin);
            case _RowAction.remove:
              widget.onRemove?.call(index);
            case _RowAction.save:
              widget.onSave?.call(index);
            case _RowAction.open:
              widget.onOpen?.call(index);
            case _RowAction.openProject:
              widget.onOpenProject?.call(index);
          }
        },
        itemBuilder: (context) => [
          if (widget.onOpen != null)
            PopupMenuItem(
              value: _RowAction.open,
              child: Text(labels.openPianoRoll),
            ),
          PopupMenuItem(
            value: _RowAction.instrument,
            child: Text(
              labels.instrument(labels.voiceName(widget.voiceOf(index))),
            ),
          ),
          PopupMenuItem(value: _RowAction.share, child: Text(labels.share)),
          if (widget.canOpenProject(index))
            PopupMenuItem(
              value: _RowAction.openProject,
              child: Text(labels.openProject),
            ),
          if (widget.onAddToCollection != null)
            PopupMenuItem(
              value: _RowAction.add,
              child: Text(labels.addToCollection),
            ),
          if (widget.onRemove != null)
            PopupMenuItem(
              value: _RowAction.remove,
              child: Text(labels.removeFromCollection),
            ),
          if (widget.onSave != null)
            PopupMenuItem(value: _RowAction.save, child: Text(labels.save)),
          if (actions.isNotEmpty) const PopupMenuDivider(),
          for (final a in actions) _actionItem(a),
        ],
      ),
    );
  }

  PopupMenuItem<T> _actionItem<T>(MidiClipRowAction a) => PopupMenuItem<T>(
    key: a.id == null ? null : ValueKey('midi-row-action-${a.id}'),
    value: a as T,
    child: Row(
      children: [
        Icon(a.icon, size: 18),
        const SizedBox(width: 12),
        Flexible(child: Text(a.label)),
      ],
    ),
  );
}

enum _RowAction { open, instrument, share, openProject, add, remove, save }

Rect? _rectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

IconData _voiceIcon(SynthVoice voice) => switch (voice) {
  SynthVoice.keys || SynthVoice.organ => Icons.piano,
  SynthVoice.bass => Icons.graphic_eq,
  SynthVoice.pad || SynthVoice.strings => Icons.waves,
  SynthVoice.bell || SynthVoice.pluck => Icons.notifications_none,
  SynthVoice.lead || SynthVoice.brass => Icons.campaign_outlined,
  _ when voice.isDrum => Icons.album_outlined,
  _ => Icons.tune,
};

/// The instrument a clip previews with: an icon for its family, and a menu
/// of every voice with the current one checked. The clip list's rows and
/// the piano roll window both use it.
class MidiVoicePicker extends StatelessWidget {
  const MidiVoicePicker({
    super.key,
    required this.voice,
    required this.voiceName,
    required this.tooltip,
    required this.onChanged,
    this.showName = false,
  });

  final SynthVoice voice;

  /// Shows the instrument's name ("Keys ▾") rather than its family's icon —
  /// where there is room for it, as in the piano roll window.
  final bool showName;

  /// "Bass", "Pad"…
  final String Function(SynthVoice voice) voiceName;

  /// "Instrument: Bass", given the voice's name.
  final String Function(String name) tooltip;
  final ValueChanged<SynthVoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SynthVoice>(
      tooltip: tooltip(voiceName(voice)),
      icon: showName ? null : Icon(_voiceIcon(voice)),
      child: showName
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    voiceName(voice),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            )
          : null,
      initialValue: voice,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final v in SynthVoice.values) ...[
          if (v == SynthVoice.drumKit) const PopupMenuDivider(),
          CheckedPopupMenuItem<SynthVoice>(
            value: v,
            checked: v == voice,
            child: Text(voiceName(v)),
          ),
        ],
      ],
    );
  }
}

/// The phone layout's instrument chooser: the same voices as [MidiVoicePicker],
/// as a dialog (a 16-item popup out of an overflow menu is unwieldy).
class _VoiceDialog extends StatelessWidget {
  const _VoiceDialog({required this.current, required this.labels});

  final SynthVoice current;
  final MidiClipListLabels labels;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        for (final v in SynthVoice.values)
          ListTile(
            dense: true,
            leading: Icon(_voiceIcon(v), size: 20),
            title: Text(labels.voiceName(v)),
            trailing: v == current ? const Icon(Icons.check, size: 18) : null,
            onTap: () => Navigator.of(context).pop(v),
          ),
      ],
    );
  }
}

Widget _maybeTooltip(String? message, Widget child) =>
    message == null ? child : Tooltip(message: message, child: child);

/// A tiny piano roll: every note as a bar, pitch on the vertical axis
/// (scaled to the clip's own range), time on the horizontal.
class MidiClipThumbnail extends StatelessWidget {
  const MidiClipThumbnail({
    super.key,
    required this.clip,
    required this.width,
    required this.height,
    required this.color,
  });

  final MidiClip clip;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(painter: _PianoRollPainter(clip, color)),
      ),
    );
  }
}

class _PianoRollPainter extends CustomPainter {
  _PianoRollPainter(this.clip, this.color);

  final MidiClip clip;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final notes = clip.notes;
    if (notes.isEmpty || clip.lengthTicks <= 0) return;
    var lo = 127, hi = 0;
    for (final n in notes) {
      if (n.pitch < lo) lo = n.pitch;
      if (n.pitch > hi) hi = n.pitch;
    }
    // Pad the range so a one-note line sits mid-height instead of on an edge.
    lo = (lo - 2).clamp(0, 127);
    hi = (hi + 2).clamp(0, 127);
    final rows = (hi - lo + 1).toDouble();
    final rowHeight = (size.height - 4) / rows;
    final barHeight = rowHeight.clamp(1.5, 4.0);
    final paint = Paint()..color = color;
    final length = clip.lengthTicks.toDouble();
    for (final n in notes) {
      final x = 2 + (size.width - 4) * n.startTick / length;
      final w = ((size.width - 4) * n.lengthTicks / length).clamp(
        1.5,
        size.width,
      );
      final y = 2 + (hi - n.pitch) * rowHeight + (rowHeight - barHeight) / 2;
      canvas.drawRect(Rect.fromLTWH(x, y, w, barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(_PianoRollPainter old) =>
      !identical(old.clip, clip) || old.color != color;
}
