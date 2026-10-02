import 'package:flutter/material.dart';

import '../../models/midi_clip.dart';

/// Localized strings for [MidiClipList], resolved by the page.
class MidiClipListLabels {
  const MidiClipListLabels({
    required this.play,
    required this.stop,
    required this.save,
    required this.dragTooltip,
    required this.bars,
    required this.notes,
    required this.usedTimes,
    required this.alsoAs,
    required this.noTrack,
    required this.expandTrack,
    required this.collapseTrack,
  });

  final String play;
  final String stop;
  final String save;
  final String dragTooltip;
  final String Function(int count) bars;
  final String Function(int count) notes;
  final String Function(int count) usedTimes;

  /// Tooltip listing the other clips merged into this one.
  final String Function(String names) alsoAs;

  /// Heading for clips whose format didn't say which track they're on.
  final String noTrack;
  final String expandTrack;
  final String collapseTrack;
}

/// The MIDI clips read out of a project, grouped under the track each sits
/// on (see [groupMidiClipsByTrack]): a collapsible header per track, then per
/// clip a piano-roll thumbnail, its name, length and note count, and
/// play / save / drag.
///
/// Every track starts expanded when the whole list is short; past
/// [expandAllUpTo] clips they start collapsed, so the headers read as an
/// overview of which tracks have MIDI.
///
/// A plain view: it owns no player and touches no files. [dragHandleBuilder]
/// wraps the drag handle in whatever makes it draggable (the page passes a
/// `DragItemWidget`, which needs a native plugin and so can't run in widget
/// tests); null hides the handle, as on mobile.
class MidiClipList extends StatefulWidget {
  const MidiClipList({
    super.key,
    required this.clips,
    required this.labels,
    required this.onPlay,
    required this.onSave,
    this.playingIndex,
    this.preparingIndex,
    this.dragHandleBuilder,
    this.expandAllUpTo = 12,
  });

  final List<MidiClip> clips;
  final MidiClipListLabels labels;

  /// Starts — or, for the playing clip, stops — the preview of clip [index].
  final void Function(int index) onPlay;
  final void Function(int index) onSave;

  /// The clip whose preview is playing, if any.
  final int? playingIndex;

  /// The clip whose preview is being rendered, if any.
  final int? preparingIndex;

  final Widget Function(BuildContext context, int index, Widget handle)?
      dragHandleBuilder;

  final int expandAllUpTo;

  @override
  State<MidiClipList> createState() => _MidiClipListState();
}

class _MidiClipListState extends State<MidiClipList> {
  /// Tracks the user toggled away from the default state.
  final Set<String?> _toggled = {};

  bool _isOpen(String? track) {
    final byDefault = widget.clips.length <= widget.expandAllUpTo;
    return _toggled.contains(track) ? !byDefault : byDefault;
  }

  @override
  void didUpdateWidget(MidiClipList old) {
    super.didUpdateWidget(old);
    if (!identical(old.clips, widget.clips)) _toggled.clear();
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupMidiClipsByTrack(widget.clips);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final group in groups) ...[
          _header(context, group),
          if (_isOpen(group.trackName))
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final i in group.clipIndices) _row(context, i),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _header(BuildContext context, MidiClipTrackGroup group) {
    final theme = Theme.of(context);
    final open = _isOpen(group.trackName);
    final name = group.trackName ?? widget.labels.noTrack;
    return Tooltip(
      message: open ? widget.labels.collapseTrack : widget.labels.expandTrack,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => setState(() {
          if (!_toggled.remove(group.trackName)) _toggled.add(group.trackName);
        }),
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
                    fontStyle:
                        group.trackName == null ? FontStyle.italic : null,
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

    // Rounded up: a 4-bar clip trimmed by a tick is still "4 bars".
    final bars = (clip.lengthBeats / 4).ceil().clamp(1, 1 << 20);
    // The track is the group header, so it isn't repeated per row.
    final details = <String>[
      labels.bars(bars),
      labels.notes(clip.notes.length),
      if (clip.occurrences > 1) labels.usedTimes(clip.occurrences),
    ];
    final title = clip.name.isNotEmpty ? clip.name : (clip.trackName ?? '');

    final handle = widget.dragHandleBuilder;
    return Padding(
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
          MidiClipThumbnail(
            clip: clip,
            width: 72,
            height: 32,
            color: playing ? theme.colorScheme.secondary : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
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
              ],
            ),
          ),
          if (preparing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: playing ? labels.stop : labels.play,
              icon: Icon(playing ? Icons.stop_circle_outlined : Icons.play_circle_outline),
              onPressed: () => widget.onPlay(index),
            ),
          IconButton(
            tooltip: labels.save,
            icon: const Icon(Icons.save_alt),
            onPressed: () => widget.onSave(index),
          ),
        ],
      ),
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
      final w = ((size.width - 4) * n.lengthTicks / length).clamp(1.5, size.width);
      final y = 2 + (hi - n.pitch) * rowHeight + (rowHeight - barHeight) / 2;
      canvas.drawRect(Rect.fromLTWH(x, y, w, barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(_PianoRollPainter old) =>
      !identical(old.clip, clip) || old.color != color;
}
