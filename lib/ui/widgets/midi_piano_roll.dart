import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../models/midi_clip.dart';
import '../../utils/musical_scale.dart';
import '../../utils/time_signature.dart';
import 'midi_clip_edit_controller.dart';
import 'midi_tool_icons.dart';

// --- pure helpers ------------------------------------------------------------

const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

/// A pitch's name the way Cubase and Ableton print it: middle C (60) is C3.
String midiNoteName(int pitch) =>
    '${_noteNames[pitch % 12]}${(pitch ~/ 12) - 2}';

bool isBlackKey(int pitch) => const {1, 3, 6, 8, 10}.contains(pitch % 12);

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

/// Whether the keyboard names [pitch] at [rowHeight]: only the C's, as on a
/// DAW's keyboard, so the octaves can be told apart — once rows are tall
/// enough for a name. Zoomed in, the notes themselves carry every name.
bool showsKeyName(int pitch, double rowHeight) =>
    pitch % 12 == 0 && rowHeight >= 8;

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
/// draws between beats [beatTicks] long — null when there are none worth
/// drawing: the grid is a beat or coarser (the beat lines show it), or its
/// lines would sit under 5 px apart.
int? gridDivisionTicks({
  required int stepTicks,
  required int beatTicks,
  required double pxPerTick,
}) {
  if (stepTicks <= 0 || stepTicks >= beatTicks) return null;
  if (stepTicks * pxPerTick < 5) return null;
  return stepTicks;
}

/// How fast a drag at [at] scrolls the view, in pixels per frame: toward
/// whichever edges of [area] it is within [zone] of — faster the closer it
/// gets, at full speed past them — and not at all away from the edges. What
/// lets a drag carry notes, a box or a range on beyond what is on screen.
Offset autoScrollVelocity({
  required Offset at,
  required Rect area,
  double zone = 28,
  double maxSpeed = 18,
}) {
  double axis(double v, double lo, double hi) {
    if (v < lo + zone) return -maxSpeed * ((lo + zone - v) / zone).clamp(0.0, 1.0);
    if (v > hi - zone) return maxSpeed * ((v - (hi - zone)) / zone).clamp(0.0, 1.0);
    return 0;
  }

  return Offset(axis(at.dx, area.left, area.right), axis(at.dy, area.top, area.bottom));
}

/// [clip] cut to [region] — the notes and controller values in it (each
/// lane's value chased in at its start), as long as the region — what a
/// loop region plays, over and over.
MidiClip loopRegionClip(MidiClip clip, MidiTickRange region) {
  final length = region.end - region.start;
  return clip.copyWith(
    notes: windowMidiNotes(clip.notes,
        windowStart: region.start, windowLength: length),
    events: windowMidiEvents(clip.events,
        windowStart: region.start, windowLength: length),
    lengthTicks: length,
  );
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
    this.snap = '',
    this.snapOff = '',
    this.toolSelect = '',
    this.toolRange = '',
    this.toolEraser = '',
    this.toolPencil = '',
    this.duplicate = '',
    this.quantize = '',
    this.transpose = '',
    this.transposeUpSemitone = '',
    this.transposeDownSemitone = '',
    this.transposeUpOctave = '',
    this.transposeDownOctave = '',
    this.acousticFeedback = '',
  });

  /// The acoustic feedback toggle's tooltip: hear notes as they are edited.
  final String acousticFeedback;

  /// Editing tools' tooltips; only shown with an editor.
  final String edit, undo, redo, snap, snapOff;

  /// The tools' tooltips: "Select (1)", "Range (2)", "Eraser (5)",
  /// "Pencil (8)".
  final String toolSelect, toolRange, toolEraser, toolPencil;

  /// The duplicate button's tooltip, and the transpose menu's: buttons for
  /// what a keyboard does with Ctrl/Cmd+D and the arrows, so a phone can.
  final String duplicate, quantize, transpose;
  final String transposeUpSemitone, transposeDownSemitone;
  final String transposeUpOctave, transposeDownOctave;


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
    this.onAudition,
    this.timeSignature = TimeSignature.common,
    this.loopRegion,
    this.onLoopRegionChanged,
    this.acousticFeedback = false,
    this.onAcousticFeedbackChanged,
  });

  /// Sounds one note: a key pressed on the keyboard, always, and — with
  /// [acousticFeedback] on — a note added, clicked or dragged to another
  /// key while editing. Null: silent.
  final void Function(int pitch, int velocity)? onAudition;

  /// The bars and beats the grid and ruler are drawn in.
  final TimeSignature timeSignature;

  /// The loop region (Cubase's locators), drawn purple over the ruler.
  final MidiTickRange? loopRegion;

  /// Lets the ruler set the loop region as Cubase does: Ctrl/Cmd-click sets
  /// its start, Alt-click its end, and its ends can be dragged. Null: no
  /// loop region.
  final ValueChanged<MidiTickRange>? onLoopRegionChanged;

  /// Cubase's "acoustic feedback": notes sound as they are edited.
  final bool acousticFeedback;

  /// Shows the acoustic feedback toggle while editing.
  final ValueChanged<bool>? onAcousticFeedbackChanged;

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
  // A touch wider than it needs to be, so the keys read as a piano.
  static const _keyboardWidth = 55.0;
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
    _syncTicker();
  }

  void _onEdit() {
    if (!mounted) return;
    setState(() => _lanes = availableMidiLanes(_shown));
  }

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
    _ticker.dispose();
    _playhead.dispose();
    _toolCursorAt.dispose();
    _stopAutoScroll();
    super.dispose();
  }

  int get _rows => _range.high - _range.low + 1;
  double get _px => _pxPerTick ?? _fitPxPerTick;
  /// Ticks the view spans: the clip — or, with an editor, an endless
  /// canvas: four bars past the clip's end (or its last note), and always
  /// another view's width past wherever it has been scrolled to, so a clip
  /// can be drawn on and grown as far as wanted.
  int get _contentTicks {
    final clip = _shown;
    if (widget.editor == null) return clip.lengthTicks;
    var end = clip.lengthTicks;
    for (final n in clip.notes) {
      if (n.endTick > end) end = n.endTick;
    }
    final room = end + widget.timeSignature.barTicks(clip.ppq) * 4;
    final beyond = ((_scrollX + 2 * _gridWidth) / _px).ceil();
    return math.max(room, beyond);
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

  /// The ruler was clicked: Ctrl/Cmd-click sets the loop region's start,
  /// Alt-click its end (as in Cubase); a plain click jumps there.
  void _rulerTap(double x) {
    final tick = _tickAtRulerX(x);
    if (widget.onLoopRegionChanged != null) {
      if (_keys.isControlPressed || _keys.isMetaPressed) {
        _setLoopEdge(NoteEdge.start, tick);
        return;
      }
      if (_keys.isAltPressed) {
        _setLoopEdge(NoteEdge.end, tick);
        return;
      }
    }
    _seekTo(tick);
  }

  /// The loop region's end being dragged on the ruler, if one is.
  NoteEdge? _loopEdge;

  /// Which end of the loop region the ruler at [x] grabs, if either.
  NoteEdge? _loopEdgeAt(double x) {
    final r = widget.loopRegion;
    if (r == null || widget.onLoopRegionChanged == null) return null;
    double xOf(int tick) => tick * _px - _scrollX;
    if ((x - xOf(r.end)).abs() <= 8) return NoteEdge.end;
    if ((x - xOf(r.start)).abs() <= 8) return NoteEdge.start;
    return null;
  }

  void _moveLoopEdge(NoteEdge edge, double x) =>
      _setLoopEdge(edge, _tickAtRulerX(x), dragging: true);

  /// Puts one end of the loop region at [tick], on the grid (the snap, or
  /// the beat). The other end stays — a bar away when there is none yet —
  /// unless that would leave nothing between them.
  void _setLoopEdge(NoteEdge edge, double tick, {bool dragging = false}) {
    final ppq = _shown.ppq;
    final editor = widget.editor;
    final step = editor != null && editor.snap != MidiSnap.off
        ? editor.stepTicks
        : widget.timeSignature.beatTicks(ppq);
    final bar = widget.timeSignature.barTicks(ppq);
    final at = math.max(0, (tick / step).round() * step);
    final r = widget.loopRegion;
    MidiTickRange next;
    if (edge == NoteEdge.start) {
      var end = r?.end ?? at + bar;
      if (end <= at) end = dragging ? at + step : at + bar;
      next = (start: at, end: end);
    } else {
      var start = r?.start ?? math.max(0, at - bar);
      if (at <= start) start = dragging ? math.max(0, at - step) : math.max(0, at - bar);
      next = (start: start, end: at <= start ? start + step : at);
    }
    if (next != r) widget.onLoopRegionChanged!(next);
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
    // With an editor, far out: the canvas is endless, and a long draft
    // should fit on screen.
    final widest = _fitPxPerTick / (widget.editor == null ? 2 : 16);
    final next = (old * factor).clamp(widest, _fitPxPerTick * _maxZoom);
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

  /// The middle mouse button is held: the canvas moves with the mouse.
  bool _panning = false;

  void _onEditDown(PointerDownEvent e) {
    _startDrag(e);
    // Where the view was when the drag began: a drag that scrolls the view
    // (near an edge) measures from the notes, not from the screen.
    _drag?.scrollStart = Offset(_scrollX, _scrollY);
  }

  void _startDrag(PointerDownEvent e) {
    _pointers.add(e.pointer);
    if (e.buttons & kMiddleMouseButton != 0) {
      // The middle button grabs the canvas and moves it, as in a DAW.
      setState(() {
        _panning = true;
        _cursor = SystemMouseCursors.grabbing;
      });
      return;
    }
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
    final tool = editor.tool;
    if (p.dy < _view.height) {
      if (tool == MidiEditTool.range) {
        // On an end of the range: that end moves. Elsewhere: a new stretch
        // of time, across every key, from here to the release.
        final edge = _rangeEdgeAt(editor, p.dx);
        _drag = edge == null
            ? _EditDrag(_DragKind.range, p, null)
            : _EditDrag(_DragKind.rangeEdge, p, null, edge: edge);
        return;
      }
      if (tool == MidiEditTool.eraser) {
        // Whatever the eraser touches, from here to the release, goes —
        // as one undo step.
        editor.beginGesture();
        _drag = _EditDrag(_DragKind.erase, p, null)..lastAt = p;
        _eraseAt(editor, p);
        return;
      }
      final hit = _noteAt(p);
      if (hit == null && _pencil) {
        // The pencil draws a note here, as long as the drag makes it.
        editor.beginNote(_tickAtX(p.dx), _pitchAtY(p.dy));
        _drag = _EditDrag(_DragKind.draw, p, null)..lastValue = editor.velocity;
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
      _feedback(note.pitch, note.velocity);
      if (_keys.isShiftPressed) {
        editor.toggleSelected(index);
        _drag = _EditDrag(_DragKind.tapNote, p, index);
        return;
      }
      // Ctrl (Cmd): the note joins the selection — or, clicked without a
      // drag, an already selected one leaves it — and a drag moves the lot
      // off the grid. Otherwise a note already in the selection drags the
      // whole selection, and any other is selected alone.
      final adding = _free;
      final wasSelected = editor.isSelected(index);
      if (!wasSelected) {
        adding ? editor.toggleSelected(index) : editor.select(index);
      }
      if (edge != null) {
        editor.beginGesture();
        _drag = _EditDrag(_DragKind.resize, p, index, edge: edge);
      } else {
        _drag = _EditDrag(_DragKind.move, p, index,
            duplicate: _keys.isAltPressed)
          ..pitch = note.pitch;
      }
      _drag!.deselectOnTap = adding && wasSelected;
      return;
    }
    final lane = _lane;
    if (lane == null || tool == MidiEditTool.range) return;
    if (tool == MidiEditTool.eraser) {
      // Over a controller lane the eraser takes the points it passes.
      if (lane.isVelocity || !_drawable(lane)) return;
      final tick = _tickAtX(p.dx);
      editor.beginGesture();
      _drag = _EditDrag(_DragKind.eraseLane, p, null)..lastTick = tick;
      editor.eraseLane(lane.kind!, lane.number, tick, tick);
      return;
    }
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
    if (_panning) {
      _scrollBy(-e.delta.dx, -e.delta.dy);
      return;
    }
    if (_pressedKey != null) {
      // Dragging along the keyboard plays each key it passes over.
      final y = e.localPosition.dy.clamp(_rulerHeight, _view.height - 1);
      final pitch = _pitchAtY(y);
      if (pitch != _pressedKey) {
        setState(() => _pressedKey = pitch);
        widget.onAudition?.call(pitch, 100);
      }
      return;
    }
    if (_toolCursorAt.value != null) _toolCursorAt.value = e.localPosition;
    _lastDragAt = e.localPosition;
    _dragTo(e.localPosition);
    _updateAutoScroll(e.localPosition);
  }

  /// The drag under way, with the pointer at [p]. Measured from where it
  /// started on the notes, so a view scrolled since (near an edge) carries
  /// the drag along with it.
  void _dragTo(Offset p) {
    final drag = _drag;
    final editor = widget.editor;
    if (drag == null || editor == null || _pointers.length > 1) return;
    final scrolled = Offset(_scrollX, _scrollY) - drag.scrollStart;
    final d = p - drag.start + scrolled;
    if ((p - drag.start).distance > 4 || scrolled != Offset.zero) {
      drag.moved = true;
    }
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
          // Up or down while drawing sets how hard it plays, as in Cubase;
          // across, how long it is.
          if (d.dy.abs() > 4) {
            editor.setDrawnVelocity(drag.lastValue - (d.dy / 2).round());
          }
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
        final box = Rect.fromPoints(drag.start - scrolled, p);
        setState(() => _marquee = box);
        editor.selectInBox(
          fromTick: _tickAtX(box.left),
          toTick: _tickAtX(box.right),
          lowPitch: _pitchAtY(box.bottom),
          highPitch: _pitchAtY(box.top),
          keep: _marqueeKeep,
        );
      case _DragKind.range:
        if (drag.moved) {
          editor.selectRange(
              _tickAtX(drag.start.dx - scrolled.dx), _tickAtX(p.dx));
        }
      case _DragKind.rangeEdge:
        editor.adjustRange(drag.edge!, _tickAtX(p.dx));
      case _DragKind.erase:
        _eraseAlong(editor, drag.lastAt!, p);
        drag.lastAt = p;
      case _DragKind.eraseLane:
        if (lane != null && lane.kind != null) {
          final tick = _tickAtX(p.dx);
          editor.eraseLane(lane.kind!, lane.number, drag.lastTick, tick);
          drag.lastTick = tick;
        }
      case _DragKind.tapNote:
        break;
    }
  }

  /// Where the pointer last was mid-drag, to carry on from as the view
  /// scrolls under it.
  Offset? _lastDragAt;

  Timer? _autoScroll;
  Offset _autoScrollStep = Offset.zero;

  /// Scrolls the view while a drag sits near an edge of the notes — on
  /// either axis for things that move between keys (notes, the box, the
  /// eraser), sideways only for the rest.
  void _updateAutoScroll(Offset p) {
    final drag = _drag;
    var step = Offset.zero;
    if (drag != null && drag.moved && _pointers.length == 1) {
      step = autoScrollVelocity(
        at: p,
        area: Rect.fromLTRB(
            _keyboardWidth, _rulerHeight, _view.width, _view.height),
      );
      final upAndDown = drag.kind == _DragKind.move ||
          drag.kind == _DragKind.marquee ||
          drag.kind == _DragKind.erase;
      if (!upAndDown) step = Offset(step.dx, 0);
    }
    _autoScrollStep = step;
    if (step == Offset.zero) {
      _stopAutoScroll();
    } else {
      _autoScroll ??= Timer.periodic(
          const Duration(milliseconds: 16), (_) => _autoScrollTick());
    }
  }

  void _autoScrollTick() {
    final at = _lastDragAt;
    if (!mounted || _drag == null || at == null) {
      _stopAutoScroll();
      return;
    }
    final before = Offset(_scrollX, _scrollY);
    _scrollBy(_autoScrollStep.dx, _autoScrollStep.dy);
    if (Offset(_scrollX, _scrollY) != before) _dragTo(at);
  }

  void _stopAutoScroll() {
    _autoScroll?.cancel();
    _autoScroll = null;
  }

  /// Which end of the range the pointer at [x] is on, if either.
  NoteEdge? _rangeEdgeAt(MidiClipEditController editor, double x) {
    final r = editor.range;
    if (r == null) return null;
    double xOf(int tick) => _keyboardWidth + tick * _px - _scrollX;
    if ((x - xOf(r.end)).abs() <= 6) return NoteEdge.end;
    if ((x - xOf(r.start)).abs() <= 6) return NoteEdge.start;
    return null;
  }

  void _eraseAt(MidiClipEditController editor, Offset p) {
    final hit = _noteAt(p);
    if (hit != null) editor.eraseNote(hit.$1);
  }

  /// Erases every note between [from] and [to], so a quick swipe misses
  /// none.
  void _eraseAlong(MidiClipEditController editor, Offset from, Offset to) {
    final steps = math.max(1, ((to - from).distance / 3).ceil());
    for (var i = 1; i <= steps; i++) {
      _eraseAt(editor, Offset.lerp(from, to, i / steps)!);
    }
  }

  /// The transpose menu: the selection up or down, sounding it with
  /// acoustic feedback on — what the arrow keys do, for a phone.
  void _transposeBy(MidiClipEditController editor, int semitones) {
    editor.transposeSelection(semitones);
    for (final i in editor.selection.take(4)) {
      final n = editor.clip.notes[i];
      _feedback(n.pitch, n.velocity);
    }
  }

  void _onEditUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    _stopAutoScroll();
    if (_panning) {
      setState(() {
        _panning = false;
        _cursor = MouseCursor.defer;
      });
      return;
    }
    if (_pressedKey != null) setState(() => _pressedKey = null);
    final drag = _drag;
    final editor = widget.editor;
    if (drag == null || editor == null) return;
    _drag = null;
    switch (drag.kind) {
      case _DragKind.marquee:
        if (_marquee != null) setState(() => _marquee = null);
        if (!drag.moved && _doubleTap(e.timeStamp, drag.start)) {
          // A double-click on an empty spot adds a note there.
          editor.addNoteAt(_tickAtX(drag.start.dx), _pitchAtY(drag.start.dy));
          _feedback(_pitchAtY(drag.start.dy));
        }
      case _DragKind.draw:
        editor.endGesture();
      case _DragKind.move || _DragKind.tapNote || _DragKind.resize:
        if (drag.moved) {
          editor.endGesture();
        } else {
          editor.cancelGesture();
          if (drag.kind == _DragKind.tapNote) break;
          if (drag.deselectOnTap) {
            // Ctrl-clicked an already selected note: it leaves the selection.
            editor.toggleSelected(drag.index!);
            break;
          }
          // A double-click on a note deletes it — with the select tool
          // only: the pencil never deletes, a click with it just selects.
          if (!_pencil && _doubleTap(e.timeStamp, drag.start)) {
            editor.deleteNote(drag.index!);
          }
        }
      case _DragKind.range:
        // A click without a drag lets the range go.
        if (!drag.moved) editor.select(null);
      case _DragKind.rangeEdge:
        break;
      case _DragKind.velocity ||
            _DragKind.lane ||
            _DragKind.erase ||
            _DragKind.eraseLane:
        editor.endGesture();
    }
  }

  void _onEditCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _stopAutoScroll();
    _panning = false;
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
  /// note's edge, so that edge is easy to find, a text caret for the range
  /// tool, and — for the pencil and the eraser — the tool itself, drawn
  /// ([_toolCursorAt]) with the system pointer hidden.
  MouseCursor _cursor = MouseCursor.defer;

  /// Where a drawn tool cursor is; null shows none.
  final ValueNotifier<Offset?> _toolCursorAt = ValueNotifier(null);

  void _updateHover(Offset local) {
    if (_panning) return;
    final editor = widget.editor;
    var cursor = MouseCursor.defer;
    Offset? drawn;
    final overNotes = local.dx >= _keyboardWidth &&
        local.dy >= _rulerHeight &&
        local.dy < _view.height;
    if (_editing && overNotes) {
      final hit = _noteAt(local);
      switch (editor!.tool) {
        case MidiEditTool.range:
          cursor = _rangeEdgeAt(editor, local.dx) != null
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.text;
        case MidiEditTool.eraser:
          cursor = SystemMouseCursors.none;
          drawn = local;
        case MidiEditTool.pencil when hit?.$2 != null:
          cursor = SystemMouseCursors.resizeLeftRight;
        case MidiEditTool.pencil:
          cursor = SystemMouseCursors.none;
          drawn = local;
        case MidiEditTool.select:
          cursor = hit == null
              ? MouseCursor.defer
              : hit.$2 != null
                  ? SystemMouseCursors.resizeLeftRight
                  : SystemMouseCursors.click;
      }
    } else if (_editing &&
        editor!.tool == MidiEditTool.eraser &&
        local.dx >= _keyboardWidth &&
        local.dy >= _view.height &&
        _lane != null &&
        !_lane!.isVelocity &&
        _drawable(_lane!)) {
      cursor = SystemMouseCursors.none;
      drawn = local;
    }
    _toolCursorAt.value = drawn;
    if (cursor != _cursor) setState(() => _cursor = cursor);
  }

  /// The pencil or the eraser, drawn where the mouse is: Flutter has no
  /// cursor images, and a tool should look like itself in the hand. Its
  /// point is the icon's bottom-left corner, where the tip is.
  Widget _toolCursorOverlay() => ValueListenableBuilder<Offset?>(
        valueListenable: _toolCursorAt,
        builder: (context, at, _) {
          if (at == null || !_editing) return const SizedBox.shrink();
          const size = 22.0;
          final eraser = widget.editor!.tool == MidiEditTool.eraser;
          Widget glyph(Color color) => eraser
              ? MidiToolIcon(MidiToolGlyph.eraser, size: size, color: color)
              : Icon(Icons.edit, size: size, color: color);
          return Positioned(
            left: at.dx - 3,
            top: at.dy - size + 3,
            child: IgnorePointer(
              key: const ValueKey('midi-piano-roll-tool-cursor'),
              child: Stack(
                children: [
                  // A dark copy behind, so it shows on light notes too.
                  Transform.translate(
                    offset: const Offset(1, 1),
                    child: glyph(Colors.black87),
                  ),
                  glyph(Colors.white),
                ],
              ),
            ),
          );
        },
      );

  /// The row height slider, upright at the top of the right edge: drag up
  /// for taller rows.
  Widget _verticalZoom(ThemeData theme, double laneHeight) {
    final color = theme.textTheme.bodySmall?.color;
    return SizedBox(
      width: 32,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: laneHeight + 4),
          child: Column(
        key: const ValueKey('midi-piano-roll-vertical-zoom'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.unfold_more, size: 16, color: color),
          SizedBox(
            height: 140,
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
        ),
      ),
    );
  }

  /// The lane's height as the user dragged it, if they did.
  double? _lanePreferred;

  /// Where a drag of the lane's edge was pressed, and the lane's height
  /// then: it follows the pointer from there.
  (double, double)? _laneDragFrom;

  /// How tall the lane under the notes is in [total] pixels of roll: what
  /// it was dragged to, or about a fifth — never so small it can't be
  /// drawn on, nor so big the notes vanish.
  double _laneHeightFor(double total) {
    if (_lane == null) return 0;
    final most = math.max(40.0, total * 0.75);
    return (_lanePreferred ?? (total * 0.22).clamp(48.0, 140.0))
        .clamp(40.0, most)
        .toDouble();
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
          icon: const MidiToolIcon(MidiToolGlyph.pointer),
          onPressed: () => editor.tool = MidiEditTool.select,
        ),
        IconButton(
          key: const ValueKey('midi-piano-roll-tool-range'),
          tooltip: labels.toolRange,
          isSelected: editor.tool == MidiEditTool.range,
          icon: const MidiToolIcon(MidiToolGlyph.caret),
          onPressed: () => editor.tool = MidiEditTool.range,
        ),
        IconButton(
          key: const ValueKey('midi-piano-roll-tool-eraser'),
          tooltip: labels.toolEraser,
          isSelected: editor.tool == MidiEditTool.eraser,
          icon: const MidiToolIcon(MidiToolGlyph.eraser),
          onPressed: () => editor.tool = MidiEditTool.eraser,
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
          key: const ValueKey('midi-piano-roll-duplicate'),
          tooltip: labels.duplicate,
          icon: const Icon(Icons.control_point_duplicate),
          onPressed: editor.range != null || editor.selection.isNotEmpty
              ? editor.duplicate
              : null,
        ),
        IconButton(
          key: const ValueKey('midi-piano-roll-quantize'),
          tooltip: labels.quantize,
          icon: const Icon(Icons.grid_on),
          onPressed: editor.clip.notes.isEmpty ? null : editor.quantize,
        ),
        PopupMenuButton<int>(
          key: const ValueKey('midi-piano-roll-transpose'),
          tooltip: labels.transpose,
          enabled: editor.selection.isNotEmpty,
          icon: const Icon(Icons.swap_vert),
          onSelected: (semitones) => _transposeBy(editor, semitones),
          itemBuilder: (_) => [
            PopupMenuItem(value: 12, child: Text(labels.transposeUpOctave)),
            PopupMenuItem(value: 1, child: Text(labels.transposeUpSemitone)),
            PopupMenuItem(value: -1, child: Text(labels.transposeDownSemitone)),
            PopupMenuItem(value: -12, child: Text(labels.transposeDownOctave)),
          ],
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
            final laneHeight = _laneHeightFor(total.height);
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
            return Stack(
              children: [
                Positioned.fill(child: ClipRect(
              child: MouseRegion(
                cursor: _cursor,
                onExit: (_) => _toolCursorAt.value = null,
                child: Listener(
                onPointerSignal: _onPointerSignal,
                onPointerHover: _onHover,
                child: GestureDetector(
                  onScaleStart: (_) => _scaleStartPx = _px,
                  onScaleUpdate: (d) {
                    // Editing: one finger edits (see _onEditDown); two move.
                    // A finger on the keyboard plays it rather than scroll.
                    if ((_editing || _pressedKey != null) &&
                        d.pointerCount < 2) {
                      return;
                    }
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
                            timeSignature: widget.timeSignature,
                            loopRegion: widget.loopRegion,
                            showClipEnd: !_editing,
                            range: _editing ? widget.editor!.range : null,
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
                              timeSignature: widget.timeSignature,
                              showClipEnd: !_editing,
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
                              // From where the press went down, not where
                              // it became a drag: grabbing a loop end means
                              // pressing on it.
                              dragStartBehavior: DragStartBehavior.down,
                              onTapUp: (d) => _rulerTap(d.localPosition.dx),
                              onHorizontalDragStart: (d) {
                                _loopEdge = _loopEdgeAt(d.localPosition.dx);
                                if (_loopEdge == null) {
                                  _scrubTo(d.localPosition.dx);
                                }
                              },
                              onHorizontalDragUpdate: (d) {
                                final edge = _loopEdge;
                                if (edge != null) {
                                  _moveLoopEdge(edge, d.localPosition.dx);
                                } else {
                                  _scrubTo(d.localPosition.dx);
                                }
                              },
                              onHorizontalDragEnd: (_) {
                                if (_loopEdge != null) {
                                  _loopEdge = null;
                                  return;
                                }
                                final tick = _scrubTick;
                                if (tick != null) _seekTo(tick);
                              },
                              onHorizontalDragCancel: () {
                                _loopEdge = null;
                                _scrubTick = null;
                              },
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
                _toolCursorOverlay(),
                // The lane's top edge, dragged up or down to give it more or
                // less room. Outside the gesture listeners, so it never
                // starts an edit.
                if (_lane != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _view.height - 4,
                    height: 8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: GestureDetector(
                        key: const ValueKey('midi-piano-roll-lane-resize'),
                        behavior: HitTestBehavior.opaque,
                        // The edge stays under the pointer from the press.
                        dragStartBehavior: DragStartBehavior.down,
                        onVerticalDragStart: (d) => _laneDragFrom =
                            (d.globalPosition.dy, laneHeight),
                        onVerticalDragUpdate: (d) {
                          final from = _laneDragFrom;
                          if (from == null) return;
                          setState(() => _lanePreferred =
                              from.$2 - (d.globalPosition.dy - from.$1));
                        },
                        onVerticalDragEnd: (_) => _laneDragFrom = null,
                      ),
                    ),
                  ),
              ],
            );
          }),
              ),
              // Vertical zoom stands up the right side, the way it zooms —
              // taller rows at the top — at the foot of the notes, just
              // above the lane.
              LayoutBuilder(
                builder: (context, constraints) => _verticalZoom(
                    theme, _laneHeightFor(constraints.maxHeight)),
              ),
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

/// The loop region's colour, as Cubase draws its locators.
const _loopPurple = Color(0xFFA56CFF);
const _noteOrange = Color(0xFFFFA24C);

/// Every note's outline, and a selected note's fill — selecting inverts a
/// note: black inside, its colour on the outline and the name.
const _noteBorder = Color(0xFF101010);

enum _DragKind {
  marquee,
  tapNote,
  move,
  resize,
  draw,
  velocity,
  lane,
  range,
  rangeEdge,
  erase,
  eraseLane,
}

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

  /// Where the eraser last was, to erase on from there.
  Offset? lastAt;

  /// The view's scroll when the drag began.
  Offset scrollStart = Offset.zero;

  /// Ctrl-pressed on a note already selected: a click without a drag takes
  /// it out of the selection.
  bool deselectOnTap = false;

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
      // A step up from the darkest surface, so the grid reads clearly.
      background: cs.surfaceContainer,
      blackRow: cs.onSurface.withValues(alpha: 0.04),
      // Out-of-scale rows a touch darker than a black key's, so the scale's
      // own rows read as the lit lanes.
      outOfScaleRow: cs.onSurface.withValues(alpha: 0.09),
      scaleRootRow: cs.primary.withValues(alpha: 0.12),
      beatLine: cs.onSurface.withValues(alpha: 0.13),
      barLine: cs.onSurface.withValues(alpha: 0.34),
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
    this.showClipEnd = true,
    this.timeSignature = TimeSignature.common,
    this.loopRegion,
    this.range,
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

  /// The range tool's stretch of time, shaded across every key.
  final MidiTickRange? range;

  final TimeSignature timeSignature;

  /// The loop region, purple over the ruler.
  final MidiTickRange? loopRegion;

  /// Whether the clip's end is marked (not while editing).
  final bool showClipEnd;

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

    // Beat and bar lines, in the clip's time signature. Beats are skipped
    // when they'd be under 6 px apart; bars always draw.
    final ppq = clip.ppq;
    final beatTicks = timeSignature.beatTicks(ppq);
    final beatsPerBar = timeSignature.beats;
    final beatPx = beatTicks * pxPerTick;
    final firstBeat = (scrollX / pxPerTick / beatTicks).floor();
    final lastBeat = ((scrollX + size.width) / pxPerTick / beatTicks).ceil();
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
            stepTicks: gridStepTicks!,
            beatTicks: beatTicks,
            pxPerTick: pxPerTick);
    if (division != null) {
      final divisionPaint = Paint()
        ..color = colors.beatLine.withValues(alpha: colors.beatLine.a * 0.55)
        ..strokeWidth = 1;
      final first = (scrollX / pxPerTick / division).floor();
      final last = ((scrollX + size.width) / pxPerTick / division).ceil();
      for (var d = first; d <= last; d++) {
        final tick = d * division;
        if (tick % beatTicks == 0) continue; // a beat line goes there
        final x = _xOf(tick);
        canvas.drawLine(
            Offset(x, rulerHeight), Offset(x, size.height), divisionPaint);
      }
    }
    for (var b = firstBeat; b <= lastBeat; b++) {
      final isBar = b % beatsPerBar == 0;
      if (!isBar && beatPx < 6) continue;
      final x = _xOf(b * beatTicks);
      canvas.drawLine(Offset(x, rulerHeight), Offset(x, size.height),
          isBar ? barPaint : beatPaint);
    }

    // Clip end — not while editing: there the clip has no edge to work
    // up against (it grows with its notes), and what plays is bounded by
    // the loop region instead.
    if (showClipEnd) {
      final endX = _xOf(clip.lengthTicks);
      canvas.drawLine(Offset(endX, rulerHeight), Offset(endX, size.height),
          Paint()
            ..color = colors.barLine
            ..strokeWidth = 2);
    }

    // The loop region's ends, carried down over the notes.
    final loopAt = loopRegion;
    if (loopAt != null) {
      final line = Paint()
        ..color = _loopPurple.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      for (final tick in [loopAt.start, loopAt.end]) {
        final x = _xOf(tick);
        canvas.drawLine(Offset(x, rulerHeight), Offset(x, size.height), line);
      }
    }

    // The range tool's stretch, shaded under the notes.
    final r = range;
    if (r != null) {
      final area = Rect.fromLTRB(
          _xOf(r.start), rulerHeight, _xOf(r.end), size.height);
      canvas.drawRect(
          area, Paint()..color = colors.playhead.withValues(alpha: 0.14));
      final edge = Paint()
        ..color = colors.playhead.withValues(alpha: 0.75)
        ..strokeWidth = 1.5;
      canvas.drawLine(area.topLeft, area.bottomLeft, edge);
      canvas.drawLine(area.topRight, area.bottomRight, edge);
    }

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
      // Black keys are shorter, so a name always sits on ivory.
      _text(canvas, midiNoteName(pitch),
          Offset(keyboardWidth - 4, y + rowHeight / 2),
          alignRight: true,
          color: _keyLabel);
    }
    canvas.restore();

    // Ruler with bar numbers.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, rulerHeight),
        Paint()..color = colors.ruler);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(keyboardWidth, 0, size.width, rulerHeight));
    final barPx = beatsPerBar * beatPx;
    final barStep = barPx >= 40 ? 1 : (40 / barPx).ceil();
    for (var bar = (firstBeat ~/ beatsPerBar);
        bar * beatsPerBar <= lastBeat;
        bar++) {
      if (bar % barStep != 0) continue;
      final x = _xOf(bar * beatsPerBar * beatTicks);
      canvas.drawLine(Offset(x, rulerHeight * 0.45), Offset(x, rulerHeight),
          Paint()..color = colors.barLine);
      _text(canvas, '${bar + 1}', Offset(x + 3, rulerHeight / 2));
    }
    // The loop region, over the bar numbers as in Cubase: a purple band
    // with a handle at each end to drag.
    final loop = loopRegion;
    if (loop != null) {
      final band = Rect.fromLTRB(
          _xOf(loop.start), 2, _xOf(loop.end), rulerHeight - 2);
      canvas.drawRect(band, Paint()..color = _loopPurple.withValues(alpha: 0.45));
      final handle = Paint()..color = _loopPurple;
      for (final x in [band.left, band.right]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(x, rulerHeight / 2),
                  width: 5,
                  height: rulerHeight - 4),
              const Radius.circular(2)),
          handle,
        );
      }
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
      old.range != range ||
      old.timeSignature != timeSignature ||
      old.loopRegion != loopRegion ||
      old.showClipEnd != showClipEnd ||
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
    this.showClipEnd = true,
    this.timeSignature = TimeSignature.common,
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
  final TimeSignature timeSignature;
  final bool showClipEnd;

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
    final barTicks = timeSignature.barTicks(ppq);
    final firstBar = (scrollX / pxPerTick / barTicks).floor();
    final lastBar = ((scrollX + size.width) / pxPerTick / barTicks).ceil();
    for (var b = firstBar; b <= lastBar; b++) {
      final x = _xOf(b * barTicks);
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

    if (showClipEnd) {
      final endX = _xOf(clipLength);
      canvas.drawLine(Offset(endX, 0), Offset(endX, size.height),
          Paint()
            ..color = colors.barLine
            ..strokeWidth = 2);
    }
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
      old.timeSignature != timeSignature ||
      old.showClipEnd != showClipEnd ||
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
