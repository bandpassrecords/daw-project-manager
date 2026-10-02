import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../models/midi_clip.dart';

// --- pure helpers ------------------------------------------------------------

const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

/// A pitch's name the way Cubase and Ableton print it: middle C (60) is C3.
String midiNoteName(int pitch) =>
    '${_noteNames[pitch % 12]}${(pitch ~/ 12) - 2}';

bool isBlackKey(int pitch) => const {1, 3, 6, 8, 10}.contains(pitch % 12);

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

// --- the view ----------------------------------------------------------------

/// Strings for [MidiPianoRoll], resolved by the caller.
class MidiPianoRollLabels {
  const MidiPianoRollLabels({
    required this.zoomIn,
    required this.zoomOut,
    required this.fit,
    required this.follow,
  });

  final String zoomIn;
  final String zoomOut;
  final String fit;
  final String follow;
}

/// A full piano roll of one [MidiClip]: a keyboard down the left (C's
/// labelled, middle C = C3), a bar/beat ruler on top, every note as a bar
/// shaded by velocity, and — while [positionOf] returns a position — a
/// playhead line the view scrolls smoothly to keep centred (see
/// [followScroll]).
///
/// Zoom with the buttons, Ctrl+wheel or a pinch (horizontal, around the
/// pointer); scroll with the wheel (Shift+wheel sideways) or by dragging.
/// Dragging or scrolling sideways turns following off; the follow button, or
/// the next start of playback, turns it back on.
class MidiPianoRoll extends StatefulWidget {
  const MidiPianoRoll({
    super.key,
    required this.clip,
    required this.labels,
    this.bpm = 120,
    this.positionOf,
    this.playback,
  });

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

  late ({int low, int high}) _range = pianoRollRange(widget.clip.notes);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.playback?.addListener(_syncTicker);
    _syncTicker();
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
    if (!identical(old.clip, widget.clip)) {
      _range = pianoRollRange(widget.clip.notes);
      _pxPerTick = null;
      _scrollX = 0;
      _scrollY = 0;
    }
  }

  @override
  void dispose() {
    widget.playback?.removeListener(_syncTicker);
    _ticker.dispose();
    _playhead.dispose();
    super.dispose();
  }

  int get _rows => _range.high - _range.low + 1;
  double get _px => _pxPerTick ?? _fitPxPerTick;
  double get _contentWidth => widget.clip.lengthTicks * _px;
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
    final tick = ticksAt(position, widget.bpm, widget.clip.ppq)
        .clamp(0.0, widget.clip.lengthTicks.toDouble());
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

  void _fit() => setState(() {
        _pxPerTick = _fitPxPerTick;
        _scrollX = 0;
        // Centre the notes vertically when they don't fill the height.
        _scrollY = (_maxScrollY / 2).clamp(0, _maxScrollY);
      });

  /// Zooms horizontally by [factor], keeping the tick under [anchorX] (view
  /// pixels, grid-relative) where it is.
  void _zoom(double factor, {double? anchorX}) {
    final old = _px;
    final next = (old * factor).clamp(_fitPxPerTick / 2, _fitPxPerTick * _maxZoom);
    if (next == old) return;
    final anchor = anchorX ?? _gridWidth / 2;
    final tickAtAnchor = (_scrollX + anchor) / old;
    setState(() {
      _pxPerTick = next;
      _scrollX = (tickAtAnchor * next - anchor).clamp(0.0, _maxScrollX);
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = widget.labels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
            const Spacer(),
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
          child: LayoutBuilder(builder: (context, constraints) {
            _view = constraints.biggest;
            final fit = widget.clip.lengthTicks <= 0
                ? 0.1
                : _gridWidth / widget.clip.lengthTicks;
            if (fit > 0) _fitPxPerTick = fit;
            if (_pxPerTick == null && fit > 0) {
              _pxPerTick = fit;
              _scrollY = (_maxScrollY / 2).clamp(0, _maxScrollY);
            }
            _scrollX = _scrollX.clamp(0.0, _maxScrollX);
            _scrollY = _scrollY.clamp(0.0, _maxScrollY);

            final colors = _RollColors.of(theme);
            return ClipRect(
              child: Listener(
                onPointerSignal: _onPointerSignal,
                child: GestureDetector(
                  onScaleStart: (_) => _scaleStartPx = _px,
                  onScaleUpdate: (d) {
                    if (d.pointerCount > 1 && d.horizontalScale != 1) {
                      final target = _scaleStartPx * d.horizontalScale;
                      _zoom(target / _px,
                          anchorX: d.localFocalPoint.dx - _keyboardWidth);
                    } else {
                      _scrollBy(-d.focalPointDelta.dx, -d.focalPointDelta.dy);
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RollPainter(
                            clip: widget.clip,
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
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        // Vertical zoom: row height.
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.unfold_less, size: 16, color: theme.textTheme.bodySmall?.color),
            SizedBox(
              width: 140,
              child: Slider(
                value: _rowHeight,
                min: 6,
                max: 28,
                onChanged: (v) => setState(() => _rowHeight = v),
              ),
            ),
            Icon(Icons.unfold_more, size: 16, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ],
    );
  }
}

const _noteGreen = Color(0xFF8FE3A0);
const _noteGreenBorder = Color(0xFF3F8F55);

class _RollColors {
  const _RollColors({
    required this.background,
    required this.blackRow,
    required this.beatLine,
    required this.barLine,
    required this.note,
    required this.noteBorder,
    required this.whiteKey,
    required this.blackKey,
    required this.keyText,
    required this.ruler,
    required this.playhead,
  });

  final Color background, blackRow, beatLine, barLine, note, noteBorder;
  final Color whiteKey, blackKey, keyText, ruler, playhead;

  static _RollColors of(ThemeData theme) {
    final cs = theme.colorScheme;
    return _RollColors(
      background: cs.surfaceContainerLowest,
      blackRow: cs.onSurface.withValues(alpha: 0.04),
      beatLine: cs.onSurface.withValues(alpha: 0.08),
      barLine: cs.onSurface.withValues(alpha: 0.22),
      // FL Studio's light green — fixed, not themed: it is the colour people
      // read a piano roll in, and it stays legible on every dark theme.
      note: _noteGreen,
      noteBorder: _noteGreenBorder,
      whiteKey: cs.surfaceContainerHighest,
      blackKey: cs.onSurface.withValues(alpha: 0.75),
      keyText: cs.onSurfaceVariant,
      ruler: cs.surfaceContainerHigh,
      playhead: cs.error,
    );
  }
}

class _RollPainter extends CustomPainter {
  _RollPainter({
    required this.clip,
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

    // Rows: black-key rows shaded.
    canvas.save();
    canvas.clipRect(grid);
    final rowPaint = Paint()..color = colors.blackRow;
    for (var pitch = low; pitch <= high; pitch++) {
      if (!isBlackKey(pitch)) continue;
      final y = _yOf(pitch);
      if (y > size.height || y + rowHeight < rulerHeight) continue;
      canvas.drawRect(Rect.fromLTWH(keyboardWidth, y, size.width, rowHeight), rowPaint);
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
    for (final n in clip.notes) {
      if (n.endTick < firstTick || n.startTick > lastTick) continue;
      final y = _yOf(n.pitch);
      if (y > size.height || y + rowHeight < rulerHeight) continue;
      final rect = Rect.fromLTWH(
        _xOf(n.startTick),
        y + 1,
        math.max(2.0, n.lengthTicks * pxPerTick),
        math.max(2.0, rowHeight - 2),
      );
      // Quiet notes fade, loud ones are solid — the velocity at a glance.
      notePaint.color = colors.note.withValues(alpha: 0.35 + 0.65 * n.velocity / 127);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(rrect, notePaint);
      if (rowHeight >= 8) canvas.drawRRect(rrect, border);
    }
    canvas.restore();

    // Keyboard.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, rulerHeight, keyboardWidth, size.height));
    for (var pitch = low; pitch <= high; pitch++) {
      final y = _yOf(pitch);
      if (y > size.height || y + rowHeight < rulerHeight) continue;
      final black = isBlackKey(pitch);
      canvas.drawRect(
        Rect.fromLTWH(0, y, black ? keyboardWidth * 0.62 : keyboardWidth, rowHeight),
        Paint()..color = black ? colors.blackKey : colors.whiteKey,
      );
      canvas.drawLine(Offset(0, y + rowHeight), Offset(keyboardWidth, y + rowHeight),
          Paint()..color = colors.beatLine);
      if (pitch % 12 == 0 && rowHeight >= 8) {
        _text(canvas, midiNoteName(pitch),
            Offset(keyboardWidth - 4, y + rowHeight / 2), alignRight: true);
      }
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

  void _text(Canvas canvas, String text, Offset at, {bool alignRight = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle.copyWith(color: colors.keyText, fontSize: 10)),
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
