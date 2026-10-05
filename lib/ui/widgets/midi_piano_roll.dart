import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../models/midi_clip.dart';
import '../../utils/midi_edit_hints.dart';
import '../../utils/musical_scale.dart';
import 'midi_clip_edit_controller.dart';

// --- pure helpers ------------------------------------------------------------

const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

/// A pitch's name the way Cubase and Ableton print it: middle C (60) is C3.
String midiNoteName(int pitch) =>
    '${_noteNames[pitch % 12]}${(pitch ~/ 12) - 2}';

bool isBlackKey(int pitch) => const {1, 3, 6, 8, 10}.contains(pitch % 12);

/// Row height from which every key on the keyboard is named, not just the
/// C's: the names need about that much room to stay legible.
const double kAllKeyNamesRowHeight = 18;

/// The smallest row height a note's own name fits inside it, at the size
/// the keyboard's labels use.
const double kNoteLabelMinRowHeight = 13;

/// Space kept between a note's edge and its name.
const double kNoteLabelPadding = 3;

/// Whether a note drawn [noteWidth] × [rowHeight] pixels has room for its
/// name ([labelWidth] wide) inside it — the user has zoomed in far enough,
/// across and down, for the name to be read rather than squeezed.
bool noteLabelFits({
  required double noteWidth,
  required double rowHeight,
  required double labelWidth,
}) =>
    rowHeight >= kNoteLabelMinRowHeight &&
    noteWidth >= labelWidth + 2 * kNoteLabelPadding;

/// The colour a note's name is written in on a note filled at [fillAlpha]
/// (its velocity): dark on a solid, loud note, light on a faded, quiet one
/// that lets the dark background through.
Color noteLabelColor(double fillAlpha) =>
    fillAlpha >= 0.6 ? const Color(0xFF14361E) : const Color(0xFFE8F5EC);

/// Whether the keyboard names [pitch] at [rowHeight]. The C's are named from
/// small rows up, so octaves can always be told apart; zoomed in vertically
/// far enough ([kAllKeyNamesRowHeight]) every key is.
bool showsKeyName(int pitch, double rowHeight) =>
    rowHeight >= kAllKeyNamesRowHeight || (pitch % 12 == 0 && rowHeight >= 8);

/// The rows a piano roll shows for [notes]: their range padded by a few
/// semitones, widened to at least two octaves so a one-note clip doesn't
/// fill the window with three fat rows.
({int low, int high}) pianoRollRange(List<MidiNote> notes, {int minSpan = 24}) {
  if (notes.isEmpty) return (low: 48, high: 48 + minSpan - 1);
  var low = notes.map((n) => n.pitch).reduce(math.min) - 3;
  var high = notes.map((n) => n.pitch).reduce(math.max) + 3;
  while (high - low + 1 < minSpan) {
    if (low > 0) low--;
    if (high - low + 1 < minSpan && high < 127) high++;
    if (low == 0 && high == 127) break;
  }
  return (low: low.clamp(0, 127), high: high.clamp(0, 127));
}

/// Where in the clip playback is, in ticks, [elapsed] into a preview played
/// at [bpm].
double ticksAt(Duration elapsed, double bpm, int ppq) =>
    elapsed.inMicroseconds / 1e6 * bpm / 60 * ppq;

/// How long a preview at [bpm] takes to reach [tick] — [ticksAt] reversed.
Duration durationAtTick(double tick, double bpm, int ppq) => Duration(
    microseconds: bpm <= 0 || ppq <= 0 ? 0 : (tick / ppq * 60 / bpm * 1e6).round());

/// Which edge of a note drawn from [left] to [right] the pointer at [x] is
/// on, if either: the outer quarter of the note, at most 8 px, and a few
/// pixels past it, so a thin note's edge can still be caught. The end wins
/// on a note too short to have two.
NoteEdge? noteEdgeAt({
  required double x,
  required double left,
  required double right,
}) {
  final zone = math.min(8.0, (right - left) / 4);
  if (x >= right - zone) return NoteEdge.end;
  if (x <= left + zone) return NoteEdge.start;
  return null;
}

/// Whether a tap at [at], [time], makes a double-click with the one before
/// it: soon enough after and close enough to it.
bool isDoubleTap({
  required Duration? previousTime,
  required Offset? previousAt,
  required Duration time,
  required Offset at,
}) =>
    previousTime != null &&
    previousAt != null &&
    time - previousTime <= kDoubleTapTimeout &&
    (at - previousAt).distance <= 12;

/// [value] as drawn into [lane]: a pitch bend near the middle is pulled
/// to it (8192, no bend) — a hand never lands there exactly, and a bend
/// that doesn't come back to zero leaves the notes after it out of tune.
int snapLaneValue(MidiLane lane, int value) {
  if (lane.kind != MidiEventKind.pitchBend) return value;
  return (value - 8192).abs() <= 16383 * 0.03 ? 8192 : value;
}

/// Whether [pitch] falls outside [scale] — drawn orange, note and velocity
/// stem alike. Nothing is, with no scale set.
bool noteOutOfScale(MusicalScale? scale, int pitch) =>
    scale != null && !scale.contains(pitch);

/// For each of [notes], whether it is out of [scale]; null with no scale.
List<bool>? outOfScaleFlags(List<MidiNote> notes, MusicalScale? scale) =>
    scale == null ? null : [for (final n in notes) !scale.contains(n.pitch)];

/// The spacing, in ticks, of the faint lines a snap grid of [stepTicks]
/// draws between the beats — null when there are none worth drawing: the
/// grid is a beat or coarser (the beat lines show it), or its lines would
/// sit under 5 px apart.
int? gridDivisionTicks({
  required int stepTicks,
  required int ppq,
  required double pxPerTick,
}) {
  if (stepTicks <= 0 || stepTicks >= ppq) return null;
  if (stepTicks * pxPerTick < 5) return null;
  return stepTicks;
}

/// How far across the keyboard a black key reaches, as on a piano.
const kBlackKeyWidthFraction = 0.6;

/// Whether a piano has a seam right under white key [pitch]: where two
/// white keys meet with no black key between — under C (above B) and under
/// F (above E). Every other white key is parted from the next under the
/// middle of the black key between them.
bool whiteKeySeamBelow(int pitch) {
  final pc = pitch % 12;
  return pc == 0 || pc == 5;
}

/// The vertical scroll that keeps the row at [anchorY] (pixels down from
/// the top of the view) still while rows go from [oldRow] to [newRow]
/// pixels tall — so zooming vertically closes in on the notes being looked
/// at instead of on the top of the keyboard.
double verticalZoomScroll({
  required double scrollY,
  required double oldRow,
  required double newRow,
  required double anchorY,
}) {
  final next = (scrollY + anchorY) / oldRow * newRow - anchorY;
  return next < 0 ? 0 : next;
}

/// The x a zoom keeps still (grid-relative pixels): the pointer's, when it
/// is over the grid, else the middle of the view.
double zoomAnchorX({required double? pointerX, required double viewWidth}) {
  final x = pointerX;
  if (x == null || x < 0 || x > viewWidth) return viewWidth / 2;
  return x;
}

/// The horizontal scroll that follows a playhead at [playheadX] (content
/// pixels) by keeping it in the middle of the view: the line walks right
/// until it reaches the centre, then the notes scroll smoothly under it,
/// and at the end of the clip the scrolling stops and the line walks on to
/// the right edge.
double followScroll({
  required double playheadX,
  required double viewWidth,
  required double maxScroll,
}) {
  if (viewWidth <= 0) return 0;
  return (playheadX - viewWidth / 2).clamp(0.0, math.max(0.0, maxScroll));
}

/// What the lane under a piano roll shows: note velocities, or one stream
/// of the clip's events — pitch bend, a controller, aftertouch, program
/// changes.
class MidiLane {
  const MidiLane.velocity()
      : kind = null,
        number = 0;

  /// [number] is the controller for [MidiEventKind.controller] and ignored
  /// otherwise: poly aftertouch shows every key's pressure in one lane.
  const MidiLane.of(MidiEventKind this.kind, [int number = 0])
      : number = kind == MidiEventKind.controller ? number : 0;

  /// Null for velocity.
  final MidiEventKind? kind;
  final int number;

  bool get isVelocity => kind == null;

  /// The highest value the lane draws, at the top of the lane.
  int get maxValue => kind?.maxValue ?? 127;

  bool shows(MidiEvent e) =>
      e.kind == kind &&
      (kind != MidiEventKind.controller || e.number == number);

  @override
  bool operator ==(Object other) =>
      other is MidiLane && other.kind == kind && other.number == number;

  @override
  int get hashCode => Object.hash(kind, number);

  @override
  String toString() => 'MidiLane(${kind?.name ?? 'velocity'} $number)';
}

/// The lanes worth offering for [clip]: velocity, pitch bend and the
/// modulation wheel (CC 1) always — the ones every keyboard has, offered
/// even when empty so they can be drawn in — then whatever else its events
/// hold: each other controller in number order, channel and poly
/// aftertouch, program changes.
List<MidiLane> availableMidiLanes(MidiClip clip) {
  final controllers = <int>{};
  final kinds = <MidiEventKind>{};
  for (final e in clip.events) {
    if (e.kind == MidiEventKind.controller) {
      controllers.add(e.number);
    } else {
      kinds.add(e.kind);
    }
  }
  controllers.remove(1);
  return [
    const MidiLane.velocity(),
    const MidiLane.of(MidiEventKind.pitchBend),
    const MidiLane.of(MidiEventKind.controller, 1),
    for (final n in controllers.toList()..sort())
      MidiLane.of(MidiEventKind.controller, n),
    if (kinds.contains(MidiEventKind.channelPressure))
      const MidiLane.of(MidiEventKind.channelPressure),
    if (kinds.contains(MidiEventKind.polyPressure))
      const MidiLane.of(MidiEventKind.polyPressure),
    if (kinds.contains(MidiEventKind.program))
      const MidiLane.of(MidiEventKind.program),
  ];
}

/// The (tick, value) points [lane] draws for [clip], in tick order: each
/// note's velocity at its start, or the lane's events.
List<(int, int)> midiLanePoints(MidiClip clip, MidiLane lane) => lane.isVelocity
    ? [for (final n in clip.notes) (n.startTick, n.velocity)]
    : [for (final e in clip.events) if (lane.shows(e)) (e.tick, e.value)];

// --- the view ----------------------------------------------------------------

/// Strings for [MidiPianoRoll], resolved by the caller.
class MidiPianoRollLabels {
  const MidiPianoRollLabels({
    required this.zoomIn,
    required this.zoomOut,
    required this.fit,
    required this.follow,
    required this.lane,
    required this.laneNone,
    required this.laneName,
    required this.scale,
    required this.scaleNone,
    required this.scaleRoot,
    required this.scaleType,
    required this.scaleTypeName,
    this.edit = '',
    this.undo = '',
    this.redo = '',
    this.deleteNote = '',
    this.snap = '',
    this.snapOff = '',
    this.toolSelect = '',
    this.toolPencil = '',
    this.hintText,
    this.hintDismiss = '',
    this.acousticFeedback = '',
  });

  /// The acoustic feedback toggle's tooltip: hear notes as they are edited.
  final String acousticFeedback;

  /// Editing tools' tooltips; only shown with an editor.
  final String edit, undo, redo, deleteNote, snap, snapOff;

  /// The two tools' tooltips: "Select (1)", "Pencil (8)".
  final String toolSelect, toolPencil;

  /// What each editing hint says; null shows no hints.
  final String Function(MidiEditHint hint)? hintText;

  /// The button that retires the hint on show.
  final String hintDismiss;

  final String zoomIn;
  final String zoomOut;
  final String fit;
  final String follow;

  /// Tooltip on the lane picker.
  final String lane;

  /// The picker's "show no lane" entry.
  final String laneNone;

  /// "Velocity", "Pitch bend", "CC 1 · Modulation"…
  final String Function(MidiLane lane) laneName;

  /// The scale button's label while no scale is set, and its chooser's
  /// title.
  final String scale;

  /// The chooser's "no scale" action.
  final String scaleNone;

  /// The chooser's two field labels.
  final String scaleRoot;
  final String scaleType;

  /// "Minor", "Dorian", "Minor pentatonic"…
  final String Function(ScaleType type) scaleTypeName;

  /// [scale] as the button shows it: "A Minor".
  String scaleName(MusicalScale scale) =>
      '${scaleRootNames[scale.root]} ${scaleTypeName(scale.type)}';
}

/// A full piano roll of one [MidiClip]: a keyboard down the left (C's
/// labelled, middle C = C3), a bar/beat ruler on top, every note as a bar
/// shaded by velocity, and — while [positionOf] returns a position — a
/// playhead line the view scrolls smoothly to keep centred (see
/// [followScroll]).
///
/// Under the notes, a lane like a DAW's controller lane shows note velocity
/// or one of the clip's event streams (see [availableMidiLanes]), picked
/// from a dropdown below — or nothing, to give the notes the room.
///
/// Zoom with the buttons, Ctrl+wheel or a pinch (horizontal, around the
/// pointer); scroll with the wheel (Shift+wheel sideways) or by dragging.
/// Dragging or scrolling sideways turns following off; the follow button, or
/// the next start of playback, turns it back on.
///
/// Clicking the bar ruler — or dragging along it and letting go — jumps
/// playback there through [onSeek], like a DAW's ruler.
///
/// With a scale set — [initialScale], usually the project's key, or one
/// picked from the toolbar — rows outside it are shaded and the root's rows
/// tinted, so the notes that belong stand out.
class MidiPianoRoll extends StatefulWidget {
  const MidiPianoRoll({
    super.key,
    required this.clip,
    required this.labels,
    this.bpm = 120,
    this.positionOf,
    this.playback,
    this.onSeek,
    this.initialScale,
    this.onScaleChanged,
    this.editor,
    this.hints,
    this.keyboardHints = true,
    this.onAudition,
    this.acousticFeedback = false,
    this.onAcousticFeedbackChanged,
  });

  /// Sounds one note: a key pressed on the keyboard, always, and — with
  /// [acousticFeedback] on — a note added, clicked or dragged to another
  /// key while editing. Null: silent.
  final void Function(int pitch, int velocity)? onAudition;

  /// Cubase's "acoustic feedback": notes sound as they are edited.
  final bool acousticFeedback;

  /// Shows the acoustic feedback toggle while editing.
  final ValueChanged<bool>? onAcousticFeedbackChanged;

  /// The editing hints learned so far; the roll shows the next one that
  /// fits (see [nextMidiEditHint]) while editing, and learns them as the
  /// user does what they say. Null shows none.
  final MidiEditHints? hints;

  /// Whether hints about keys (arrows, Alt, Ctrl) are worth showing — not
  /// on a phone.
  final bool keyboardHints;

  /// Makes the roll an editor: shows and edits [MidiClipEditController.clip]
  /// instead of [clip], with an edit toggle and its tools in the toolbar.
  /// In edit mode one finger (or the mouse) adds, selects, moves and resizes
  /// notes, sets velocities and draws controller lanes; two fingers or the
  /// wheel move the view. Null: a viewer only.
  final MidiClipEditController? editor;

  /// The scale shown when the roll opens; null shows none.
  final MusicalScale? initialScale;

  /// Told when the user picks another scale (or none).
  final ValueChanged<MusicalScale?>? onScaleChanged;

  final MidiClip clip;
  final MidiPianoRollLabels labels;

  /// The tempo the clip is playing at, to turn time into ticks.
  final double bpm;

  /// How far into the clip playback is, or null when it isn't playing.
  /// Polled every frame while playing.
  final Duration? Function()? positionOf;

  /// Notifies when playback starts or stops (the preview player). The view
  /// only ticks frames while [positionOf] says the clip is playing, so an
  /// open piano roll costs nothing while silent.
  final Listenable? playback;

  /// Called with a time into the clip when the ruler is clicked, or let go
  /// of after dragging along it. Null leaves the ruler inert.
  final ValueChanged<Duration>? onSeek;

  @override
  State<MidiPianoRoll> createState() => _MidiPianoRollState();
}

class _MidiPianoRollState extends State<MidiPianoRoll>
    with SingleTickerProviderStateMixin {
  static const _keyboardWidth = 48.0;
  static const _rulerHeight = 24.0;
  static const _maxZoom = 32.0;

  late final Ticker _ticker;
  final ValueNotifier<double?> _playhead = ValueNotifier(null);

  /// Pixels per tick; null until the first layout fits the clip.
  double? _pxPerTick;
  double _fitPxPerTick = 0.1;
  double _rowHeight = 14;
  double _scrollX = 0;
  double _scrollY = 0;
  bool _follow = true;
  bool _wasPlaying = false;
  Size _view = Size.zero;

  /// What is on screen: the editor's clip while editing is possible.
  MidiClip get _shown => widget.editor?.clip ?? widget.clip;

  bool get _editing => widget.editor?.editing ?? false;

  bool get _pencil =>
      _editing && widget.editor!.tool == MidiEditTool.pencil;

  /// Every key with an editor, so a note can go anywhere; otherwise the
  /// clip's range.
  ({int low, int high}) _rangeFor(MidiClip clip) => widget.editor != null
      ? (low: 0, high: 127)
      : pianoRollRange(clip.notes);

  late ({int low, int high}) _range = _rangeFor(_shown);

  late MusicalScale? _scale = widget.initialScale;

  Future<void> _pickScale() async {
    final choice = await showDialog<_ScaleChoice>(
      context: context,
      builder: (_) => _ScaleDialog(initial: _scale, labels: widget.labels),
    );
    if (choice == null || !mounted || choice.scale == _scale) return;
    setState(() => _scale = choice.scale);
    widget.onScaleChanged?.call(choice.scale);
  }

  /// The lane under the notes; null shows none.
  MidiLane? _lane = const MidiLane.velocity();
  late List<MidiLane> _lanes = availableMidiLanes(_shown);

  // What the lane draws, kept between frames: playback rebuilds every frame
  // while following, and the points only change with the clip or the lane.
  (MidiClip, MidiLane, List<(int, int)>)? _pointsCache;
  // The velocity stems' out-of-scale flags, kept like the points.
  (MidiClip, MusicalScale?, List<bool>?)? _offScaleCache;
  List<bool>? _laneOffScale(MidiLane lane) {
    if (!lane.isVelocity) return null;
    final cached = _offScaleCache;
    if (cached != null && identical(cached.$1, _shown) && cached.$2 == _scale) {
      return cached.$3;
    }
    final flags = outOfScaleFlags(_shown.notes, _scale);
    _offScaleCache = (_shown, _scale, flags);
    return flags;
  }

  List<(int, int)> _lanePoints(MidiLane lane) {
    final cached = _pointsCache;
    if (cached != null && identical(cached.$1, _shown) && cached.$2 == lane) {
      return cached.$3;
    }
    final points = midiLanePoints(_shown, lane);
    _pointsCache = (_shown, lane, points);
    return points;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.playback?.addListener(_syncTicker);
    widget.editor?.addListener(_onEdit);
    widget.hints?.addListener(_onHints);
    _syncTicker();
  }

  void _onEdit() {
    if (!mounted) return;
    setState(() => _lanes = availableMidiLanes(_shown));
    // Picking the pencil, by its button or its key, is what that hint asks.
    if (_pencil) _learn(MidiEditHint.pencil);
  }

  void _onHints() {
    if (mounted) setState(() {});
  }

  void _learn(MidiEditHint hint) => widget.hints?.learn(hint);

  /// The key held down on the keyboard, drawn pressed.
  int? _pressedKey;

  /// Sounds [pitch] when acoustic feedback is on.
  void _feedback(int pitch, [int? velocity]) {
    if (!widget.acousticFeedback) return;
    widget.onAudition
        ?.call(pitch.clamp(0, 127), velocity ?? widget.editor?.velocity ?? 100);
  }

  /// Runs the frame ticker exactly while the clip is playing.
  void _syncTicker() {
    final playing = widget.positionOf?.call() != null;
    if (playing && !_ticker.isActive) {
      _ticker.start();
    } else if (!playing && _ticker.isActive) {
      _ticker.stop();
      _wasPlaying = false;
      _playhead.value = null;
    }
  }

  @override
  void didUpdateWidget(MidiPianoRoll old) {
    super.didUpdateWidget(old);
    if (old.playback != widget.playback) {
      old.playback?.removeListener(_syncTicker);
      widget.playback?.addListener(_syncTicker);
      _syncTicker();
    }
    if (old.editor != widget.editor) {
      old.editor?.removeListener(_onEdit);
      widget.editor?.addListener(_onEdit);
    }
    if (old.hints != widget.hints) {
      old.hints?.removeListener(_onHints);
      widget.hints?.addListener(_onHints);
    }
    if (!identical(old.clip, widget.clip)) {
      _range = _rangeFor(_shown);
      _lanes = availableMidiLanes(_shown);
      if (_lane != null && !_lanes.contains(_lane)) {
        _lane = const MidiLane.velocity();
      }
      _pxPerTick = null;
      _scrollX = 0;
      _scrollY = 0;
    }
  }

  @override
  void dispose() {
    widget.playback?.removeListener(_syncTicker);
    widget.editor?.removeListener(_onEdit);
    widget.hints?.removeListener(_onHints);
    _ticker.dispose();
    _playhead.dispose();
    super.dispose();
  }

  int get _rows => _range.high - _range.low + 1;
  double get _px => _pxPerTick ?? _fitPxPerTick;
  /// Ticks the view spans: the clip, plus a bar beyond its end (or its last
  /// note) while editing, so a note can be added past the end.
  int get _contentTicks {
    final clip = _shown;
    if (widget.editor == null) return clip.lengthTicks;
    var end = clip.lengthTicks;
    for (final n in clip.notes) {
      if (n.endTick > end) end = n.endTick;
    }
    return end + clip.ppq * 4;
  }

  double get _contentWidth => _contentTicks * _px;
  double get _contentHeight => _rows * _rowHeight;
  double get _gridWidth => math.max(0, _view.width - _keyboardWidth);
  double get _gridHeight => math.max(0, _view.height - _rulerHeight);
  double get _maxScrollX => math.max(0, _contentWidth - _gridWidth);
  double get _maxScrollY => math.max(0, _contentHeight - _gridHeight);

  void _tick(Duration _) {
    final position = widget.positionOf?.call();
    final playing = position != null;
    if (playing && !_wasPlaying) _follow = true;
    _wasPlaying = playing;
    if (!playing) {
      // Finished or stopped between notifications: rest until the next play.
      _syncTicker();
      return;
    }
    // While the ruler is being dragged the line follows the pointer, not
    // the audio, until the drag lets go and the player jumps there.
    final tick = _scrubTick ??
        ticksAt(position, widget.bpm, _shown.ppq)
            .clamp(0.0, _shown.lengthTicks.toDouble());
    _playhead.value = tick;
    if (_follow) {
      final next = followScroll(
        playheadX: tick * _px,
        viewWidth: _gridWidth,
        maxScroll: _maxScrollX,
      );
      if (next != _scrollX) setState(() => _scrollX = next);
    }
  }

  /// The tick under the ruler at [x] (ruler-relative pixels), in the clip.
  double _tickAtRulerX(double x) =>
      ((_scrollX + x) / _px).clamp(0.0, _shown.lengthTicks.toDouble());

  double? _scrubTick;

  void _scrubTo(double x) {
    _scrubTick = _tickAtRulerX(x);
    _playhead.value = _scrubTick;
  }

  void _seekTo(double tick) {
    _scrubTick = null;
    _playhead.value = tick;
    widget.onSeek?.call(durationAtTick(tick, widget.bpm, _shown.ppq));
  }

  void _fit() => setState(() {
        _pxPerTick = _fitPxPerTick;
        _scrollX = 0;
        // Centre the notes vertically when they don't fill the height.
        _scrollY = _initialScrollY();
      });

  /// Zooms horizontally by [factor], keeping the tick under [anchorX] (view
  /// pixels, grid-relative) where it is.
  void _zoom(double factor, {double? anchorX}) {
    final old = _px;
    final next = (old * factor).clamp(_fitPxPerTick / 2, _fitPxPerTick * _maxZoom);
    if (next == old) return;
    // Around the pointer: where it is (wheel, pinch), or where it last was
    // over the notes (the buttons) — the middle when it hasn't been.
    final anchor = zoomAnchorX(
      pointerX: anchorX ?? _lastPointerX,
      viewWidth: _gridWidth,
    );
    final tickAtAnchor = (_scrollX + anchor) / old;
    setState(() {
      // A zoom is the user looking somewhere: following would snap the view
      // back to the playhead on the next frame and undo it.
      _follow = false;
      _pxPerTick = next;
      _scrollX = (tickAtAnchor * next - anchor).clamp(0.0, _maxScrollX);
    });
  }

  /// Where the pointer last was over the grid, grid-relative; null until it
  /// has been there.
  double? _lastPointerX;

  void _onHover(PointerHoverEvent e) {
    final x = e.localPosition.dx - _keyboardWidth;
    if (x >= 0 && x <= _gridWidth) _lastPointerX = x;
    _updateHover(e.localPosition);
  }

  /// Vertical zoom (the row height slider) that keeps the notes being
  /// looked at where they are, rather than closing in on the top row.
  void _setRowHeight(double next) {
    if (next == _rowHeight) return;
    final anchor = _verticalFocusY();
    setState(() {
      _scrollY = verticalZoomScroll(
        scrollY: _scrollY,
        oldRow: _rowHeight,
        newRow: next,
        anchorY: anchor,
      );
      _rowHeight = next;
      _scrollY = _scrollY.clamp(0.0, _maxScrollY);
    });
  }

  /// Where the notes in focus sit, in pixels down from the top of the
  /// note grid: the middle of the selection, or of the notes in view
  /// across — or the middle of the view when none of them are on it.
  double _verticalFocusY() {
    final centre = _gridHeight / 2;
    final notes = _shown.notes;
    final selection = _editing ? widget.editor!.selection : const <int>{};
    final firstTick = _scrollX / _px, lastTick = (_scrollX + _gridWidth) / _px;
    var low = 128, high = -1;
    for (var i = 0; i < notes.length; i++) {
      final n = notes[i];
      if (selection.isNotEmpty
          ? !selection.contains(i)
          : n.endTick < firstTick || n.startTick > lastTick) {
        continue;
      }
      if (n.pitch < low) low = n.pitch;
      if (n.pitch > high) high = n.pitch;
    }
    if (high < 0) return centre;
    final y =
        (_range.high - (low + high) / 2) * _rowHeight + _rowHeight / 2 - _scrollY;
    return y < 0 || y > _gridHeight ? centre : y;
  }

  void _scrollBy(double dx, double dy, {bool manual = true}) {
    if (manual && dx != 0) _follow = false;
    setState(() {
      _scrollX = (_scrollX + dx).clamp(0.0, _maxScrollX);
      _scrollY = (_scrollY + dy).clamp(0.0, _maxScrollY);
    });
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed) {
      _zoom(e.scrollDelta.dy < 0 ? 1.2 : 1 / 1.2,
          anchorX: e.localPosition.dx - _keyboardWidth);
    } else if (keys.isShiftPressed) {
      _scrollBy(e.scrollDelta.dy, 0);
    } else {
      _scrollBy(e.scrollDelta.dx, e.scrollDelta.dy);
    }
  }

  double _scaleStartPx = 0;

  /// Where the view opens vertically: centred on the notes. With every key
  /// on the roll (an editor), that is somewhere in the middle of 128 rows.
  double _initialScrollY() {
    final notes = _shown.notes;
    if (widget.editor == null || notes.isEmpty) {
      final centreOf = widget.editor == null ? null : 60;
      if (centreOf == null) return (_maxScrollY / 2).clamp(0, _maxScrollY);
      return ((_range.high - centreOf) * _rowHeight - _gridHeight / 2)
          .clamp(0.0, _maxScrollY);
    }
    var low = 127, high = 0;
    for (final n in notes) {
      if (n.pitch < low) low = n.pitch;
      if (n.pitch > high) high = n.pitch;
    }
    final centre = (low + high) / 2;
    return ((_range.high - centre) * _rowHeight + _rowHeight / 2 - _gridHeight / 2)
        .clamp(0.0, _maxScrollY);
  }

  // --- editing ---------------------------------------------------------------

  double _laneHeight = 0;
  final Set<int> _pointers = {};
  _EditDrag? _drag;

  double _tickAtX(double x) => (x - _keyboardWidth + _scrollX) / _px;

  int _pitchAtY(double y) =>
      (_range.high - ((y - _rulerHeight + _scrollY) / _rowHeight).floor())
          .clamp(0, 127);

  /// The note under [p] (the last drawn first, as it is on top) and the
  /// edge of it [p] is on, if either — where a drag resizes it.
  (int, NoteEdge?)? _noteAt(Offset p) {
    final notes = _shown.notes;
    final pitch = _pitchAtY(p.dy);
    for (var i = notes.length - 1; i >= 0; i--) {
      final n = notes[i];
      if (n.pitch != pitch) continue;
      final left = _keyboardWidth + n.startTick * _px - _scrollX;
      final right = left + math.max(2.0, n.lengthTicks * _px);
      if (p.dx < left - 4 || p.dx > right + 4) continue;
      return (i, noteEdgeAt(x: p.dx, left: left, right: right));
    }
    return null;
  }

  /// The note whose velocity stem is nearest [x], if one is within reach.
  int? _stemAt(double x) {
    int? best;
    var bestDistance = 12.0;
    final notes = _shown.notes;
    for (var i = 0; i < notes.length; i++) {
      final stem = _keyboardWidth + notes[i].startTick * _px - _scrollX;
      final d = (stem - x).abs();
      if (d <= bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    return best;
  }

  /// The lane value at height [y], as the lane draws it.
  int _laneValueAt(double y, MidiLane lane) {
    const pad = _LanePainter._pad;
    final top = _view.height + pad;
    final bottom = _view.height + _laneHeight - pad;
    if (bottom <= top) return 0;
    final f = ((bottom - y) / (bottom - top)).clamp(0.0, 1.0);
    return (f * lane.maxValue).round();
  }

  /// Lanes a drag can draw: one value per moment. Program changes and poly
  /// aftertouch (a value per key) aren't drawn.
  static bool _drawable(MidiLane lane) =>
      lane.kind == MidiEventKind.controller ||
      lane.kind == MidiEventKind.pitchBend ||
      lane.kind == MidiEventKind.channelPressure;

  static HardwareKeyboard get _keys => HardwareKeyboard.instance;

  /// Ctrl (Cmd on a Mac) held: drags ignore the grid, as in Cubase.
  static bool get _free => _keys.isControlPressed || _keys.isMetaPressed;

  /// The selection box being drawn, in the roll's own coordinates.
  Rect? _marquee;

  /// What a Shift-drawn selection box adds to.
  Set<int> _marqueeKeep = const {};

  // The last tap, to tell a double-click from two clicks.
  Duration? _lastTapTime;
  Offset? _lastTapAt;

  /// Whether this tap at [at] makes a double-click with the one before.
  bool _doubleTap(Duration time, Offset at) {
    final isDouble = isDoubleTap(
      previousTime: _lastTapTime,
      previousAt: _lastTapAt,
      time: time,
      at: at,
    );
    // A double-click is used up; a third click starts the next pair.
    _lastTapTime = isDouble ? null : time;
    _lastTapAt = isDouble ? null : at;
    return isDouble;
  }

  void _onEditDown(PointerDownEvent e) {
    _pointers.add(e.pointer);
    final k = e.localPosition;
    if (_pointers.length == 1 &&
        k.dx < _keyboardWidth &&
        k.dy >= _rulerHeight &&
        k.dy < _view.height) {
      // The keyboard plays the key pressed, editing or not.
      final pitch = _pitchAtY(k.dy);
      setState(() => _pressedKey = pitch);
      widget.onAudition?.call(pitch, 100);
      return;
    }
    final editor = widget.editor;
    if (editor == null || !editor.editing) return;
    if (_pointers.length > 1) {
      // A second finger: the gesture is a pinch or a pan, not an edit.
      _abandonDrag(editor);
      return;
    }
    final p = e.localPosition;
    if (p.dx < _keyboardWidth || p.dy < _rulerHeight) return;
    if (p.dy < _view.height) {
      final hit = _noteAt(p);
      if (hit == null && _pencil) {
        // The pencil draws a note here, as long as the drag makes it.
        editor.beginNote(_tickAtX(p.dx), _pitchAtY(p.dy));
        _drag = _EditDrag(_DragKind.draw, p, null);
        _feedback(_pitchAtY(p.dy));
        return;
      }
      if (hit == null) {
        // Empty space: a selection box from here (Shift adds to the
        // selection), or, on a double-click, a new note.
        _marqueeKeep = _keys.isShiftPressed ? editor.selection : const {};
        if (!_keys.isShiftPressed) editor.select(null);
        _drag = _EditDrag(_DragKind.marquee, p, null);
        return;
      }
      final (index, edge) = hit;
      final note = _shown.notes[index];
      // The pencil erases what it clicks; anything else plays the note.
      if (!_pencil) _feedback(note.pitch, note.velocity);
      if (_keys.isShiftPressed) {
        editor.toggleSelected(index);
        _drag = _EditDrag(_DragKind.tapNote, p, index);
        return;
      }
      // A note already in the selection drags the whole selection.
      if (!editor.isSelected(index)) editor.select(index);
      if (edge != null) {
        editor.beginGesture();
        _drag = _EditDrag(_DragKind.resize, p, index, edge: edge);
      } else {
        _drag = _EditDrag(_DragKind.move, p, index,
            duplicate: _keys.isAltPressed)
          ..pitch = note.pitch;
      }
      return;
    }
    final lane = _lane;
    if (lane == null) return;
    if (lane.isVelocity) {
      // A pencil across the stems: every note the drag passes takes the
      // value under it. A click lands on the nearest stem (and the chord
      // on it).
      final i = _stemAt(p.dx);
      final tick =
          i == null ? _tickAtX(p.dx) : _shown.notes[i].startTick.toDouble();
      final value = _laneValueAt(p.dy, lane);
      editor.beginGesture();
      _drag = _EditDrag(_DragKind.velocity, p, null)
        ..lastTick = tick
        ..lastValue = value;
      editor.drawVelocities(tick, value, tick, value);
    } else if (_drawable(lane)) {
      final tick = _tickAtX(p.dx);
      final value = snapLaneValue(lane, _laneValueAt(p.dy, lane));
      editor.beginGesture();
      _drag = _EditDrag(_DragKind.lane, p, null)
        ..lastTick = tick
        ..lastValue = value;
      editor.drawLane(lane.kind!, lane.number, tick, value);
    }
  }

  void _onEditMove(PointerMoveEvent e) {
    final drag = _drag;
    final editor = widget.editor;
    if (drag == null || editor == null || _pointers.length > 1) return;
    final p = e.localPosition;
    final d = p - drag.start;
    if (d.distance > 4) drag.moved = true;
    final lane = _lane;
    switch (drag.kind) {
      case _DragKind.move:
        if (!drag.moved) return;
        if (!drag.begun) {
          // Alt held when the drag starts: move copies, leave originals.
          editor.beginGesture(duplicate: drag.duplicate);
          drag.begun = true;
        }
        final dp = -(d.dy / _rowHeight).round();
        editor.moveSelection(d.dx / _px, dp, free: _free);
        if (dp != drag.lastPitchDelta) {
          // Dragged onto another key: hear where it landed.
          drag.lastPitchDelta = dp;
          _feedback(drag.pitch + dp);
        }
      case _DragKind.resize:
        editor.resizeSelection(drag.edge!, d.dx / _px, free: _free);
      case _DragKind.draw:
        if (drag.moved) {
          editor.resizeSelection(NoteEdge.end, d.dx / _px, free: _free);
        }
      case _DragKind.velocity:
        if (lane != null) {
          final tick = _tickAtX(p.dx);
          final value = _laneValueAt(p.dy, lane);
          editor.drawVelocities(drag.lastTick, drag.lastValue, tick, value);
          drag
            ..lastTick = tick
            ..lastValue = value;
        }
      case _DragKind.lane:
        if (lane != null && lane.kind != null) {
          final tick = _tickAtX(p.dx);
          final value = snapLaneValue(lane, _laneValueAt(p.dy, lane));
          editor.drawLane(lane.kind!, lane.number, tick, value,
              fromTick: drag.lastTick, fromValue: drag.lastValue);
          drag
            ..lastTick = tick
            ..lastValue = value;
        }
      case _DragKind.marquee:
        if (!drag.moved) return;
        final box = Rect.fromPoints(drag.start, p);
        setState(() => _marquee = box);
        editor.selectInBox(
          fromTick: _tickAtX(box.left),
          toTick: _tickAtX(box.right),
          lowPitch: _pitchAtY(box.bottom),
          highPitch: _pitchAtY(box.top),
          keep: _marqueeKeep,
        );
      case _DragKind.tapNote:
        break;
    }
  }

  void _onEditUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    if (_pressedKey != null) setState(() => _pressedKey = null);
    final drag = _drag;
    final editor = widget.editor;
    if (drag == null || editor == null) return;
    _drag = null;
    switch (drag.kind) {
      case _DragKind.marquee:
        if (_marquee != null) setState(() => _marquee = null);
        if (drag.moved) {
          _learn(MidiEditHint.boxSelect);
        } else if (_doubleTap(e.timeStamp, drag.start)) {
          // A double-click on an empty spot adds a note there.
          editor.addNoteAt(_tickAtX(drag.start.dx), _pitchAtY(drag.start.dy));
          _feedback(_pitchAtY(drag.start.dy));
          _learn(MidiEditHint.doubleClick);
        }
      case _DragKind.draw:
        editor.endGesture();
        _learn(MidiEditHint.pencilDraw);
      case _DragKind.move || _DragKind.tapNote || _DragKind.resize:
        if (drag.moved) {
          editor.endGesture();
          if (drag.kind == _DragKind.resize) _learn(MidiEditHint.resize);
          if (drag.duplicate) _learn(MidiEditHint.altCopy);
          if (_free) _learn(MidiEditHint.ctrlFree);
        } else {
          editor.cancelGesture();
          if (drag.kind == _DragKind.tapNote) break;
          if (_pencil) {
            // The pencil erases the note it clicks.
            editor.deleteNote(drag.index!);
            _learn(MidiEditHint.pencilErase);
          } else if (_doubleTap(e.timeStamp, drag.start)) {
            // A double-click on a note deletes it.
            editor.deleteNote(drag.index!);
            _learn(MidiEditHint.doubleClick);
          }
        }
      case _DragKind.velocity:
        editor.endGesture();
        _learn(MidiEditHint.velocity);
      case _DragKind.lane:
        editor.endGesture();
        _learn(_lane?.kind == MidiEventKind.pitchBend
            ? MidiEditHint.pitchBend
            : MidiEditHint.lane);
    }
  }

  void _onEditCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (_pressedKey != null) setState(() => _pressedKey = null);
    final editor = widget.editor;
    if (editor != null) _abandonDrag(editor);
  }

  void _abandonDrag(MidiClipEditController editor) {
    if (_drag == null) return;
    _drag = null;
    editor.cancelGesture();
    if (_marquee != null) setState(() => _marquee = null);
  }

  /// What the mouse pointer looks like while editing: a resize arrow on a
  /// note's edge, so that edge is easy to find, and cross-hairs where the
  /// pencil would draw.
  MouseCursor _cursor = MouseCursor.defer;

  /// What the mouse is over, for the cursor and the hint that fits.
  MidiHoverArea _hover = MidiHoverArea.none;

  void _updateHover(Offset local) {
    final area = _hoverAreaAt(local);
    final cursor = switch (area) {
      MidiHoverArea.noteEdge => SystemMouseCursors.resizeLeftRight,
      MidiHoverArea.note => SystemMouseCursors.click,
      MidiHoverArea.empty when _pencil => SystemMouseCursors.precise,
      _ => MouseCursor.defer,
    };
    if (cursor == _cursor && area == _hover) return;
    setState(() {
      _cursor = cursor;
      _hover = area;
    });
  }

  MidiHoverArea _hoverAreaAt(Offset p) {
    if (!_editing || p.dx < _keyboardWidth || p.dy < _rulerHeight) {
      return MidiHoverArea.none;
    }
    if (p.dy < _view.height) {
      final hit = _noteAt(p);
      if (hit == null) return MidiHoverArea.empty;
      return hit.$2 == null ? MidiHoverArea.note : MidiHoverArea.noteEdge;
    }
    final lane = _lane;
    if (lane == null) return MidiHoverArea.none;
    if (lane.isVelocity) return MidiHoverArea.velocityLane;
    if (lane.kind == MidiEventKind.pitchBend) return MidiHoverArea.pitchBendLane;
    return _drawable(lane) ? MidiHoverArea.controllerLane : MidiHoverArea.none;
  }

  /// The hint worth showing now, if any.
  MidiEditHint? get _hint {
    final hints = widget.hints;
    if (!_editing || hints == null || widget.labels.hintText == null) {
      return null;
    }
    return nextMidiEditHint(
      pencil: _pencil,
      hover: _hover,
      hasSelection: widget.editor!.selection.isNotEmpty,
      learned: hints.learned,
      keyboard: widget.keyboardHints,
    );
  }

  /// The row height slider, upright: drag up for taller rows.
  Widget _verticalZoom(ThemeData theme) {
    final color = theme.textTheme.bodySmall?.color;
    return SizedBox(
      key: const ValueKey('midi-piano-roll-vertical-zoom'),
      width: 32,
      child: Column(
        children: [
          Icon(Icons.unfold_more, size: 16, color: color),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: _rowHeight,
                min: 6,
                max: 28,
                onChanged: _setRowHeight,
              ),
            ),
          ),
          Icon(Icons.unfold_less, size: 16, color: color),
        ],
      ),
    );
  }

  /// One short hint at a time, over the bottom of the notes, with a button
  /// to retire it.
  Widget _hintPill(ThemeData theme, MidiEditHint hint) {
    final cs = theme.colorScheme;
    return Material(
      key: const ValueKey('midi-piano-roll-hint'),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.95),
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.labels.hintText!(hint),
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              key: const ValueKey('midi-piano-roll-hint-dismiss'),
              onPressed: () => _learn(hint),
              child: Text(widget.labels.hintDismiss),
            ),
          ],
        ),
      ),
    );
  }

  /// The edit toggle, and while editing: undo, redo, delete and snap.
  List<Widget> _editTools(MidiClipEditController editor) {
    final labels = widget.labels;
    return [
      IconButton(
        key: const ValueKey('midi-piano-roll-edit'),
        tooltip: labels.edit,
        isSelected: editor.editing,
        icon: const Icon(Icons.edit_note_outlined),
        selectedIcon: const Icon(Icons.edit_note),
        onPressed: () => editor.editing = !editor.editing,
      ),
      if (editor.editing) ...[
        IconButton(
          key: const ValueKey('midi-piano-roll-tool-select'),
          tooltip: labels.toolSelect,
          isSelected: editor.tool == MidiEditTool.select,
          icon: const Icon(Icons.highlight_alt),
          onPressed: () => editor.tool = MidiEditTool.select,
        ),
        IconButton(
          key: const ValueKey('midi-piano-roll-tool-pencil'),
          tooltip: labels.toolPencil,
          isSelected: editor.tool == MidiEditTool.pencil,
          icon: const Icon(Icons.edit_outlined),
          selectedIcon: const Icon(Icons.edit),
          onPressed: () => editor.tool = MidiEditTool.pencil,
        ),
        if (widget.onAcousticFeedbackChanged != null)
          IconButton(
            key: const ValueKey('midi-piano-roll-feedback'),
            tooltip: labels.acousticFeedback,
            isSelected: widget.acousticFeedback,
            icon: const Icon(Icons.hearing_disabled_outlined),
            selectedIcon: const Icon(Icons.hearing),
            onPressed: () => widget
                .onAcousticFeedbackChanged!(!widget.acousticFeedback),
          ),
        const SizedBox(height: 24, child: VerticalDivider(width: 12)),
        IconButton(
          tooltip: labels.undo,
          icon: const Icon(Icons.undo),
          onPressed: editor.canUndo ? editor.undo : null,
        ),
        IconButton(
          tooltip: labels.redo,
          icon: const Icon(Icons.redo),
          onPressed: editor.canRedo ? editor.redo : null,
        ),
        IconButton(
          tooltip: labels.deleteNote,
          icon: const Icon(Icons.delete_outline),
          onPressed:
              editor.selection.isNotEmpty ? editor.deleteSelected : null,
        ),
        Tooltip(
          message: labels.snap,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MidiSnap>(
              key: const ValueKey('midi-piano-roll-snap'),
              value: editor.snap,
              isDense: true,
              items: [
                for (final s in MidiSnap.values)
                  DropdownMenuItem(
                    value: s,
                    child: Text(s == MidiSnap.off ? labels.snapOff : s.fraction),
                  ),
              ],
              onChanged: (s) {
                if (s != null) editor.snap = s;
              },
            ),
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = widget.labels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Scrolls sideways rather than overflow on a phone.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: labels.zoomOut,
                      icon: const Icon(Icons.zoom_out),
                      onPressed: () => _zoom(1 / 1.5),
                    ),
                    IconButton(
                      tooltip: labels.zoomIn,
                      icon: const Icon(Icons.zoom_in),
                      onPressed: () => _zoom(1.5),
                    ),
                    IconButton(
                      tooltip: labels.fit,
                      icon: const Icon(Icons.fit_screen_outlined),
                      onPressed: _fit,
                    ),
                    Tooltip(
                      message: labels.scale,
                      child: TextButton.icon(
                        key: const ValueKey('midi-piano-roll-scale'),
                        onPressed: _pickScale,
                        icon: const Icon(Icons.linear_scale, size: 18),
                        label: Text(_scale == null
                            ? labels.scale
                            : labels.scaleName(_scale!)),
                      ),
                    ),
                    if (widget.editor != null) ..._editTools(widget.editor!),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: labels.follow,
              isSelected: _follow,
              icon: const Icon(Icons.my_location_outlined),
              selectedIcon: const Icon(Icons.my_location),
              onPressed: () => setState(() => _follow = !_follow),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final total = constraints.biggest;
            final laneHeight = _lane == null
                ? 0.0
                : (total.height * 0.22).clamp(48.0, 140.0).toDouble();
            _view = Size(total.width, math.max(0, total.height - laneHeight));
            _laneHeight = laneHeight;
            final fit = _shown.lengthTicks <= 0
                ? 0.1
                : _gridWidth / _shown.lengthTicks;
            if (fit > 0) _fitPxPerTick = fit;
            if (_pxPerTick == null && fit > 0) {
              _pxPerTick = fit;
              _scrollY = _initialScrollY();
            }
            _scrollX = _scrollX.clamp(0.0, _maxScrollX);
            _scrollY = _scrollY.clamp(0.0, _maxScrollY);

            final colors = _RollColors.of(theme);
            final hint = _hint;
            return Stack(
              children: [
                Positioned.fill(child: ClipRect(
              child: MouseRegion(
                cursor: _cursor,
                onExit: (_) {
                  if (_hover != MidiHoverArea.none) {
                    setState(() => _hover = MidiHoverArea.none);
                  }
                },
                child: Listener(
                onPointerSignal: _onPointerSignal,
                onPointerHover: _onHover,
                child: GestureDetector(
                  onScaleStart: (_) => _scaleStartPx = _px,
                  onScaleUpdate: (d) {
                    // Editing: one finger edits (see _onEditDown); two move.
                    if (_editing && d.pointerCount < 2) return;
                    if (d.pointerCount > 1 && d.horizontalScale != 1) {
                      final target = _scaleStartPx * d.horizontalScale;
                      _zoom(target / _px,
                          anchorX: d.localFocalPoint.dx - _keyboardWidth);
                    } else {
                      _scrollBy(-d.focalPointDelta.dx, -d.focalPointDelta.dy);
                    }
                  },
                  child: Listener(
                    onPointerDown: _onEditDown,
                    onPointerMove: _onEditMove,
                    onPointerUp: _onEditUp,
                    onPointerCancel: _onEditCancel,
                    child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        height: _view.height,
                        child: CustomPaint(
                          painter: _RollPainter(
                            clip: _shown,
                            selected: _editing
                                ? widget.editor!.selection
                                : const {},
                            marquee: _marquee,
                            pressedKey: _pressedKey,
                            gridStepTicks: _editing &&
                                    widget.editor!.snap != MidiSnap.off
                                ? widget.editor!.stepTicks
                                : null,
                            scale: _scale,
                            low: _range.low,
                            high: _range.high,
                            pxPerTick: _px,
                            rowHeight: _rowHeight,
                            scrollX: _scrollX,
                            scrollY: _scrollY,
                            keyboardWidth: _keyboardWidth,
                            rulerHeight: _rulerHeight,
                            colors: colors,
                            labelStyle: theme.textTheme.labelSmall ??
                                const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      if (_lane != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: laneHeight,
                          child: CustomPaint(
                            key: const ValueKey('midi-piano-roll-lane'),
                            painter: _LanePainter(
                              points: _lanePoints(_lane!),
                              offScale: _laneOffScale(_lane!),
                              lane: _lane!,
                              clipLength: _shown.lengthTicks,
                              ppq: _shown.ppq,
                              pxPerTick: _px,
                              scrollX: _scrollX,
                              keyboardWidth: _keyboardWidth,
                              colors: colors,
                              labelStyle: theme.textTheme.labelSmall ??
                                  const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PlayheadPainter(
                              tick: _playhead,
                              pxPerTick: _px,
                              scrollX: _scrollX,
                              keyboardWidth: _keyboardWidth,
                              color: colors.playhead,
                            ),
                          ),
                        ),
                      ),
                      if (widget.onSeek != null)
                        Positioned(
                          left: _keyboardWidth,
                          top: 0,
                          right: 0,
                          height: _rulerHeight,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              key: const ValueKey('midi-piano-roll-ruler'),
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (d) =>
                                  _seekTo(_tickAtRulerX(d.localPosition.dx)),
                              onHorizontalDragStart: (d) =>
                                  _scrubTo(d.localPosition.dx),
                              onHorizontalDragUpdate: (d) =>
                                  _scrubTo(d.localPosition.dx),
                              onHorizontalDragEnd: (_) {
                                final tick = _scrubTick;
                                if (tick != null) _seekTo(tick);
                              },
                              onHorizontalDragCancel: () => _scrubTick = null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  ),
                ),
                ),
              ),
                )),
                // Over the notes, outside the gesture listeners, so its
                // button never starts an edit.
                if (hint != null)
                  Positioned(
                    left: _keyboardWidth + 8,
                    right: 8,
                    bottom: laneHeight + 8,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: _hintPill(theme, hint),
                    ),
                  ),
              ],
            );
          }),
              ),
              // Vertical zoom stands up the right side, the way it zooms:
              // taller rows at the top.
              _verticalZoom(theme),
            ],
          ),
        ),
        // The lane picker, then vertical zoom (row height). The picker gives
        // way on a phone — long lane names are cut short — so the row never
        // runs off the screen; the slider keeps its width at the right.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Tooltip(
                  message: labels.lane,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MidiLane?>(
                      key: const ValueKey('midi-piano-roll-lane-picker'),
                      value: _lane,
                      isDense: true,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      style: theme.textTheme.bodySmall,
                      onChanged: (lane) => setState(() => _lane = lane),
                      items: [
                        for (final lane in _lanes)
                          DropdownMenuItem(
                            value: lane,
                            child: Text(labels.laneName(lane),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        DropdownMenuItem<MidiLane?>(
                          value: null,
                          child: Text(labels.laneNone,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// A real keyboard's colours, whatever the theme: it reads as a piano.
const _ivory = Color(0xFFF3EFE6);
const _ebony = Color(0xFF1B1A19);
const _keySeam = Color(0xFFA9A397);
const _keyLabel = Color(0xFF5B564C);

const _noteGreen = Color(0xFF8FE3A0);
const _noteOrange = Color(0xFFFFA24C);

/// Every note's outline, and a selected note's fill — selecting inverts a
/// note: black inside, its colour on the outline and the name.
const _noteBorder = Color(0xFF101010);

enum _DragKind { marquee, tapNote, move, resize, draw, velocity, lane }

/// One editing gesture under way: what it does, where it started, on which
/// note, and how.
class _EditDrag {
  _EditDrag(this.kind, this.start, this.index,
      {this.edge, this.duplicate = false});

  final _DragKind kind;
  final Offset start;
  final int? index;

  /// The edge a resize drags.
  final NoteEdge? edge;

  /// Alt was held: the move drags copies.
  final bool duplicate;

  /// Past the slop: a drag rather than a tap.
  bool moved = false;

  /// The editor's gesture has been started (a move starts it on moving).
  bool begun = false;

  /// Where a lane drag last drew, to draw on from there.
  double lastTick = 0;
  int lastValue = 0;

  /// A moved note's key when the drag began, and how many keys it has
  /// been moved since — to sound each new key once.
  int pitch = 0;
  int lastPitchDelta = 0;
}

/// What the scale chooser returns: the scale picked, or null for none.
/// (A null *choice* means the chooser was dismissed.)
class _ScaleChoice {
  const _ScaleChoice(this.scale);
  final MusicalScale? scale;
}

/// Picks a scale: its root and its type, or none at all.
class _ScaleDialog extends StatefulWidget {
  const _ScaleDialog({required this.initial, required this.labels});

  final MusicalScale? initial;
  final MidiPianoRollLabels labels;

  @override
  State<_ScaleDialog> createState() => _ScaleDialogState();
}

class _ScaleDialogState extends State<_ScaleDialog> {
  late int _root = widget.initial?.root ?? 0;
  late ScaleType _type = widget.initial?.type ?? ScaleType.major;

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(labels.scale),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            key: const ValueKey('midi-scale-root'),
            initialValue: _root,
            decoration: InputDecoration(labelText: labels.scaleRoot),
            items: [
              for (var r = 0; r < 12; r++)
                DropdownMenuItem(value: r, child: Text(scaleRootNames[r])),
            ],
            onChanged: (r) => setState(() => _root = r ?? _root),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ScaleType>(
            key: const ValueKey('midi-scale-type'),
            initialValue: _type,
            decoration: InputDecoration(labelText: labels.scaleType),
            items: [
              for (final t in ScaleType.values)
                DropdownMenuItem(value: t, child: Text(labels.scaleTypeName(t))),
            ],
            onChanged: (t) => setState(() => _type = t ?? _type),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(const _ScaleChoice(null)),
          child: Text(labels.scaleNone),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .pop(_ScaleChoice(MusicalScale(_root, _type))),
          child: Text(material.okButtonLabel),
        ),
      ],
    );
  }
}

class _RollColors {
  const _RollColors({
    required this.background,
    required this.blackRow,
    required this.outOfScaleRow,
    required this.scaleRootRow,
    required this.beatLine,
    required this.barLine,
    required this.note,
    required this.noteBorder,
    required this.offScaleNote,
    required this.whiteKey,
    required this.blackKey,
    required this.keyText,
    required this.ruler,
    required this.playhead,
  });

  final Color background, blackRow, beatLine, barLine, note, noteBorder;

  /// A note outside the scale, and its velocity stem.
  final Color offScaleNote;
  final Color outOfScaleRow, scaleRootRow;
  final Color whiteKey, blackKey, keyText, ruler, playhead;

  static _RollColors of(ThemeData theme) {
    final cs = theme.colorScheme;
    return _RollColors(
      background: cs.surfaceContainerLowest,
      blackRow: cs.onSurface.withValues(alpha: 0.04),
      // Out-of-scale rows a touch darker than a black key's, so the scale's
      // own rows read as the lit lanes.
      outOfScaleRow: cs.onSurface.withValues(alpha: 0.09),
      scaleRootRow: cs.primary.withValues(alpha: 0.12),
      beatLine: cs.onSurface.withValues(alpha: 0.08),
      barLine: cs.onSurface.withValues(alpha: 0.22),
      // FL Studio's light green — fixed, not themed: it is the colour people
      // read a piano roll in, and it stays legible on every dark theme.
      note: _noteGreen,
      noteBorder: _noteBorder,
      offScaleNote: _noteOrange,
      whiteKey: cs.surfaceContainerHighest,
      blackKey: cs.onSurface.withValues(alpha: 0.75),
      keyText: cs.onSurfaceVariant,
      ruler: cs.surfaceContainerHigh,
      // The app's own accent, so the line belongs to whichever theme is on.
      playhead: cs.primary,
    );
  }
}

class _RollPainter extends CustomPainter {
  _RollPainter({
    required this.clip,
    this.selected = const {},
    this.marquee,
    this.pressedKey,
    this.gridStepTicks,
    this.scale,
    required this.low,
    required this.high,
    required this.pxPerTick,
    required this.rowHeight,
    required this.scrollX,
    required this.scrollY,
    required this.keyboardWidth,
    required this.rulerHeight,
    required this.colors,
    required this.labelStyle,
  });

  final MidiClip clip;

  /// The selected notes' indices, drawn inverted.
  final Set<int> selected;

  /// The selection box being drawn, if one is.
  final Rect? marquee;

  /// The keyboard key held down, drawn pressed.
  final int? pressedKey;

  /// The snap grid's step, drawn as faint lines between the beats; null
  /// draws beats and bars only.
  final int? gridStepTicks;
  final MusicalScale? scale;
  final int low, high;
  final double pxPerTick, rowHeight, scrollX, scrollY;
  final double keyboardWidth, rulerHeight;
  final _RollColors colors;
  final TextStyle labelStyle;

  double _yOf(int pitch) => rulerHeight + (high - pitch) * rowHeight - scrollY;
  double _xOf(num tick) => keyboardWidth + tick * pxPerTick - scrollX;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Rect.fromLTRB(keyboardWidth, rulerHeight, size.width, size.height);
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.background);

    // Rows: with a scale, the rows outside it shaded and the root's rows
    // tinted; without one, the black keys' rows shaded, like a keyboard.
    canvas.save();
    canvas.clipRect(grid);
    final rowPaint = Paint()..color = colors.blackRow;
    final outPaint = Paint()..color = colors.outOfScaleRow;
    final rootPaint = Paint()..color = colors.scaleRootRow;
    final s = scale;
    for (var pitch = low; pitch <= high; pitch++) {
      final Paint? paint;
      if (s == null) {
        paint = isBlackKey(pitch) ? rowPaint : null;
      } else if (s.isRoot(pitch)) {
        paint = rootPaint;
      } else {
        paint = s.contains(pitch) ? null : outPaint;
      }
      if (paint == null) continue;
      final y = _yOf(pitch);
      if (y > size.height || y + rowHeight < rulerHeight) continue;
      canvas.drawRect(Rect.fromLTWH(keyboardWidth, y, size.width, rowHeight), paint);
    }

    // Beat and bar lines (4/4). Beats are skipped when they'd be under 6 px
    // apart; bars always draw.
    final ppq = clip.ppq;
    final beatPx = ppq * pxPerTick;
    final firstBeat = (scrollX / pxPerTick / ppq).floor();
    final lastBeat = ((scrollX + size.width) / pxPerTick / ppq).ceil();
    final beatPaint = Paint()
      ..color = colors.beatLine
      ..strokeWidth = 1;
    final barPaint = Paint()
      ..color = colors.barLine
      ..strokeWidth = 1;
    // The snap grid's own divisions, fainter, so the 1/16 or 1/32 a note
    // will land on can be seen.
    final division = gridStepTicks == null
        ? null
        : gridDivisionTicks(
            stepTicks: gridStepTicks!, ppq: ppq, pxPerTick: pxPerTick);
    if (division != null) {
      final divisionPaint = Paint()
        ..color = colors.beatLine.withValues(alpha: colors.beatLine.a * 0.55)
        ..strokeWidth = 1;
      final first = (scrollX / pxPerTick / division).floor();
      final last = ((scrollX + size.width) / pxPerTick / division).ceil();
      for (var d = first; d <= last; d++) {
        final tick = d * division;
        if (tick % ppq == 0) continue; // a beat line goes there
        final x = _xOf(tick);
        canvas.drawLine(
            Offset(x, rulerHeight), Offset(x, size.height), divisionPaint);
      }
    }
    for (var b = firstBeat; b <= lastBeat; b++) {
      final isBar = b % 4 == 0;
      if (!isBar && beatPx < 6) continue;
      final x = _xOf(b * ppq);
      canvas.drawLine(Offset(x, rulerHeight), Offset(x, size.height),
          isBar ? barPaint : beatPaint);
    }

    // Clip end.
    final endX = _xOf(clip.lengthTicks);
    canvas.drawLine(Offset(endX, rulerHeight), Offset(endX, size.height),
        Paint()
          ..color = colors.barLine
          ..strokeWidth = 2);

    // Notes, culled to the view.
    final notePaint = Paint();
    final border = Paint()
      ..color = colors.noteBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final firstTick = scrollX / pxPerTick;
    final lastTick = (scrollX + size.width) / pxPerTick;
    final selectedBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final selectedFill = Paint()..color = _noteBorder;
    // Note names, laid out once per pitch and colour for this frame.
    final labels = <(int, Color), TextPainter>{};
    for (var i = 0; i < clip.notes.length; i++) {
      final n = clip.notes[i];
      if (n.endTick < firstTick || n.startTick > lastTick) continue;
      final y = _yOf(n.pitch);
      if (y > size.height || y + rowHeight < rulerHeight) continue;
      final rect = Rect.fromLTWH(
        _xOf(n.startTick),
        y + 1,
        math.max(2.0, n.lengthTicks * pxPerTick),
        math.max(2.0, rowHeight - 2),
      );
      // Green in the scale (or with none), orange outside it.
      final hue =
          noteOutOfScale(scale, n.pitch) ? colors.offScaleNote : colors.note;
      // Quiet notes fade, loud ones are solid — the velocity at a glance.
      final fillAlpha = 0.35 + 0.65 * n.velocity / 127;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      final isSelected = selected.contains(i);
      final Color labelColor;
      if (isSelected) {
        // Inverted: black inside, the note's colour around it and on its
        // name.
        canvas.drawRRect(rrect, selectedFill);
        canvas.drawRRect(rrect, selectedBorder..color = hue);
        labelColor = hue;
      } else {
        notePaint.color = hue.withValues(alpha: fillAlpha);
        canvas.drawRRect(rrect, notePaint);
        if (rowHeight >= 8) canvas.drawRRect(rrect, border);
        labelColor = noteLabelColor(fillAlpha);
      }
      // Zoomed in far enough, the note says which it is.
      if (rowHeight >= kNoteLabelMinRowHeight) {
        final label = labels.putIfAbsent((n.pitch, labelColor),
            () => _noteLabel(midiNoteName(n.pitch), labelColor));
        if (noteLabelFits(
          noteWidth: rect.width,
          rowHeight: rowHeight,
          labelWidth: label.width,
        )) {
          canvas.save();
          canvas.clipRect(rect);
          label.paint(
            canvas,
            Offset(rect.left + kNoteLabelPadding,
                rect.center.dy - label.height / 2),
          );
          canvas.restore();
        }
      }
    }
    // The selection box being drawn, over the notes it catches.
    final box = marquee;
    if (box != null) {
      canvas.drawRect(box, Paint()..color = colors.playhead.withValues(alpha: 0.12));
      canvas.drawRect(
        box,
        Paint()
          ..color = colors.playhead
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.restore();

    // Keyboard, drawn like a piano's: ivory keys the full width, parted
    // where a real keyboard's are (between E and F, B and C, and under the
    // middle of each black key), shorter black keys on top, and the key
    // being played lit.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, rulerHeight, keyboardWidth, size.height));
    canvas.drawRect(Rect.fromLTRB(0, rulerHeight, keyboardWidth, size.height),
        Paint()..color = _ivory);
    final pressedPaint = Paint()..color = colors.playhead.withValues(alpha: 0.6);
    final seam = Paint()
      ..color = _keySeam
      ..strokeWidth = 1;
    final blackWidth = keyboardWidth * kBlackKeyWidthFraction;
    bool visible(double y) => y <= size.height && y + rowHeight >= rulerHeight;
    // The white keys' lit faces and the seams between them first…
    for (var pitch = low; pitch <= high; pitch++) {
      final y = _yOf(pitch);
      if (!visible(y)) continue;
      if (isBlackKey(pitch)) {
        final mid = y + rowHeight / 2;
        canvas.drawLine(Offset(blackWidth, mid), Offset(keyboardWidth, mid), seam);
        continue;
      }
      if (pitch == pressedKey) {
        canvas.drawRect(Rect.fromLTWH(0, y, keyboardWidth, rowHeight), pressedPaint);
      }
      if (whiteKeySeamBelow(pitch)) {
        final bottom = y + rowHeight;
        canvas.drawLine(Offset(0, bottom), Offset(keyboardWidth, bottom), seam);
      }
    }
    // …then the black keys over them, lit along the top like the real
    // thing, and rounded where they end.
    final blackPaint = Paint()..color = _ebony;
    final shine = Paint()..color = const Color(0x33FFFFFF);
    for (var pitch = low; pitch <= high; pitch++) {
      if (!isBlackKey(pitch)) continue;
      final y = _yOf(pitch);
      if (!visible(y)) continue;
      final key = RRect.fromRectAndCorners(
        Rect.fromLTWH(0, y + 0.5, blackWidth, rowHeight - 1),
        topRight: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );
      canvas.drawRRect(key, pitch == pressedKey ? pressedPaint : blackPaint);
      if (rowHeight >= 6) {
        canvas.drawRect(
            Rect.fromLTWH(0, y + 1, blackWidth - 2, rowHeight * 0.25), shine);
      }
    }
    // A shadow where the keys meet the notes.
    canvas.drawLine(Offset(keyboardWidth - 0.5, rulerHeight),
        Offset(keyboardWidth - 0.5, size.height), seam);
    for (var pitch = low; pitch <= high; pitch++) {
      final y = _yOf(pitch);
      if (!visible(y) || !showsKeyName(pitch, rowHeight)) continue;
      // With every key named, the C's stay bold so octaves still stand out.
      // Black keys are shorter, so every name sits on ivory.
      _text(canvas, midiNoteName(pitch),
          Offset(keyboardWidth - 4, y + rowHeight / 2),
          alignRight: true,
          bold: pitch % 12 == 0 && rowHeight >= kAllKeyNamesRowHeight,
          color: _keyLabel);
    }
    canvas.restore();

    // Ruler with bar numbers.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, rulerHeight),
        Paint()..color = colors.ruler);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(keyboardWidth, 0, size.width, rulerHeight));
    final barPx = 4 * beatPx;
    final barStep = barPx >= 40 ? 1 : (40 / barPx).ceil();
    for (var bar = (firstBeat ~/ 4); bar * 4 <= lastBeat; bar++) {
      if (bar % barStep != 0) continue;
      final x = _xOf(bar * 4 * ppq);
      canvas.drawLine(Offset(x, rulerHeight * 0.45), Offset(x, rulerHeight),
          Paint()..color = colors.barLine);
      _text(canvas, '${bar + 1}', Offset(x + 3, rulerHeight / 2));
    }
    canvas.restore();
  }

  /// A note's name, at the keyboard labels' size, in [color].
  TextPainter _noteLabel(String name, Color color) => TextPainter(
        text: TextSpan(
          text: name,
          style: labelStyle.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

  void _text(Canvas canvas, String text, Offset at,
      {bool alignRight = false, bool bold = false, Color? color}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: labelStyle.copyWith(
              color: color ?? colors.keyText,
              fontSize: 10,
              fontWeight: bold ? FontWeight.bold : null)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight ? at.dx - tp.width : at.dx;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_RollPainter old) =>
      !identical(old.clip, clip) ||
      old.pxPerTick != pxPerTick ||
      old.rowHeight != rowHeight ||
      old.scrollX != scrollX ||
      old.scrollY != scrollY ||
      old.low != low ||
      old.high != high ||
      old.scale != scale ||
      !setEquals(old.selected, selected) ||
      old.marquee != marquee ||
      old.pressedKey != pressedKey ||
      old.gridStepTicks != gridStepTicks ||
      old.colors.note != colors.note;
}

/// The lane under the notes: velocity stems, a step graph for controllers
/// and aftertouch (filled from the centre line for pitch bend), and marked
/// stems for program changes and poly aftertouch. Shares the roll's
/// horizontal zoom and scroll, so a point sits under its note.
class _LanePainter extends CustomPainter {
  _LanePainter({
    required this.points,
    this.offScale,
    required this.lane,
    required this.clipLength,
    required this.ppq,
    required this.pxPerTick,
    required this.scrollX,
    required this.keyboardWidth,
    required this.colors,
    required this.labelStyle,
  });

  final List<(int, int)> points;

  /// For velocity, which stems belong to notes out of the scale — drawn
  /// orange like their notes. Null: none.
  final List<bool>? offScale;
  final MidiLane lane;
  final int clipLength, ppq;
  final double pxPerTick, scrollX, keyboardWidth;
  final _RollColors colors;
  final TextStyle labelStyle;

  static const _pad = 4.0;

  double _xOf(num tick) => keyboardWidth + tick * pxPerTick - scrollX;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.ruler);
    final area = Rect.fromLTRB(keyboardWidth, 0, size.width, size.height);
    canvas.drawRect(area, Paint()..color = colors.background);
    canvas.drawLine(Offset.zero, Offset(size.width, 0),
        Paint()
          ..color = colors.barLine
          ..strokeWidth = 1);

    final top = _pad, bottom = size.height - _pad;
    final max = lane.maxValue;
    double yOf(int value) => bottom - (bottom - top) * value / max;

    // Scale down the keyboard column.
    final pitchBend = lane.kind == MidiEventKind.pitchBend;
    _text(canvas, pitchBend ? '+' : '$max', Offset(keyboardWidth - 4, top + 5));
    _text(canvas, pitchBend ? '−' : '0', Offset(keyboardWidth - 4, bottom - 5));

    canvas.save();
    canvas.clipRect(area);

    // Bar lines, like the grid above.
    final barPaint = Paint()..color = colors.beatLine;
    final firstBar = (scrollX / pxPerTick / ppq / 4).floor();
    final lastBar = ((scrollX + size.width) / pxPerTick / ppq / 4).ceil();
    for (var b = firstBar; b <= lastBar; b++) {
      final x = _xOf(b * 4 * ppq);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), barPaint);
    }
    final centre = yOf(8192);
    if (pitchBend) {
      canvas.drawLine(Offset(keyboardWidth, centre), Offset(size.width, centre),
          Paint()..color = colors.barLine);
    }

    final firstTick = scrollX / pxPerTick;
    final lastTick = (scrollX + size.width) / pxPerTick;
    final stroke = Paint()
      ..color = colors.note
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = colors.note.withValues(alpha: 0.25);

    final stems = lane.isVelocity ||
        lane.kind == MidiEventKind.polyPressure ||
        lane.kind == MidiEventKind.program;
    if (stems) {
      final dot = Paint()..color = colors.note;
      final offStroke = Paint()
        ..color = colors.offScaleNote
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final offDot = Paint()..color = colors.offScaleNote;
      final off = offScale;
      for (var i = 0; i < points.length; i++) {
        final (tick, value) = points[i];
        if (tick < firstTick - 1 || tick > lastTick) continue;
        final x = _xOf(tick);
        final y = yOf(value);
        final out = off != null && i < off.length && off[i];
        canvas.drawLine(Offset(x, bottom), Offset(x, y), out ? offStroke : stroke);
        canvas.drawCircle(Offset(x, y), 3, out ? offDot : dot);
        if (lane.kind == MidiEventKind.program && size.height >= 40) {
          // Programs are numbered from 1 in every DAW's patch list.
          _text(canvas, '${value + 1}', Offset(x + 4, y + 6),
              alignRight: false);
        }
      }
    } else if (points.isNotEmpty) {
      // A step graph: each value holds until the next, the last to the end.
      final base = pitchBend ? centre : bottom;
      final line = Path();
      final filled = Path();
      for (var i = 0; i < points.length; i++) {
        final (tick, value) = points[i];
        final end = i + 1 < points.length ? points[i + 1].$1 : clipLength;
        if (end < firstTick || tick > lastTick) continue;
        final x0 = _xOf(tick), x1 = _xOf(math.max(end, tick));
        final y = yOf(value);
        line
          ..moveTo(x0, y)
          ..lineTo(x1, y);
        if (i + 1 < points.length) {
          line.lineTo(x1, yOf(points[i + 1].$2));
        }
        filled.addRect(
            Rect.fromLTRB(x0, math.min(y, base), x1, math.max(y, base)));
      }
      canvas.drawPath(filled, fill);
      canvas.drawPath(line, stroke);
    }

    // Clip end.
    final endX = _xOf(clipLength);
    canvas.drawLine(Offset(endX, 0), Offset(endX, size.height),
        Paint()
          ..color = colors.barLine
          ..strokeWidth = 2);
    canvas.restore();
  }

  void _text(Canvas canvas, String text, Offset at, {bool alignRight = true}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: labelStyle.copyWith(color: colors.keyText, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight ? at.dx - tp.width : at.dx;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_LanePainter old) =>
      !identical(old.points, points) ||
      !identical(old.offScale, offScale) ||
      old.lane != lane ||
      old.pxPerTick != pxPerTick ||
      old.scrollX != scrollX ||
      old.colors.note != colors.note;
}

/// The playhead line, on its own layer so moving it every frame repaints a
/// line, not every note.
class _PlayheadPainter extends CustomPainter {
  _PlayheadPainter({
    required this.tick,
    required this.pxPerTick,
    required this.scrollX,
    required this.keyboardWidth,
    required this.color,
  }) : super(repaint: tick);

  final ValueNotifier<double?> tick;
  final double pxPerTick, scrollX, keyboardWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = tick.value;
    if (t == null) return;
    final x = keyboardWidth + t * pxPerTick - scrollX;
    if (x < keyboardWidth || x > size.width) return;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height),
        Paint()
          ..color = color
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_PlayheadPainter old) =>
      old.pxPerTick != pxPerTick || old.scrollX != scrollX || old.color != color;
}
