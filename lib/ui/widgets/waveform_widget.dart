import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/waveform_style.dart';
import '../../providers/providers.dart';
import '../../services/audio_analysis_service.dart';

/// Renders a min/max envelope waveform with playback progress coloring.
/// Tap or drag anywhere to seek (calls [onSeek] with a 0–1 position).
///
/// Drawn the way a DAW draws one, which is three things at once:
///  - One vertical bar per *device* pixel, never a filled polygon through the
///    peak tips — a polygon connects neighbouring peaks and smears dense
///    material into a soft blob instead of the per-column spikes real audio
///    has. Bars land on whole device pixels, so they stay crisp sideways
///    while [antiAlias] resolves their *tips* to sub-pixel amplitudes.
///  - A dimmer RMS body inset inside the peak outline, stepped through
///    [bodyBands] shades. Peaks alone give a flat silhouette whose loud
///    sections are all one shape; the gap between body and outline is the
///    crest factor, and it is what makes a compressed chorus and an open
///    verse look different at a glance.
///  - Optionally, left and right as separate lanes ([stereo]) — off by
///    default, since one taller lane reads better at the heights this is
///    embedded at.
///
/// [height] can be a fixed pixel value or null to fill the available height
/// from the parent (use inside an [Expanded] or constrained box).
class WaveformWidget extends ConsumerWidget {
  final WaveformPeaks? peaks;
  final double progress; // 0..1
  final ValueChanged<double>? onSeek;
  final Color? playedColor;
  final Color? unplayedColor;
  /// Fixed height in pixels. Pass null to fill the parent's available height.
  final double? height;
  /// Overrides the user's single/dual channel setting the same way [style]
  /// does. Applies to both renderings. Either way it is ignored when the peaks
  /// carry no channel data, or when the widget is too short for two lanes to
  /// read (see [_WaveformPainter.minStereoHeight]).
  final bool? stereo;
  /// Width of one drawn bar, in *device* pixels. 1 is the DAW look — bars
  /// touch, so dense audio reads as a solid mass.
  final double barWidth;
  /// Blank space after each bar, in *device* pixels. 0 keeps them touching;
  /// raise it for the separated-bar look, at the cost of resolution — the
  /// pitch is [barWidth] + [barGap], and every bar still summarises all the
  /// audio in its slot, so nothing is skipped, only merged.
  final double barGap;
  /// What the waveform is drawn against. Only used to tint the RMS body away
  /// from the peak outline, which is why it has to be the real backdrop rather
  /// than a fixed dark grey — on a light theme the body must go lighter, not
  /// darker. Defaults to the surrounding surface colour.
  final Color? backgroundColor;
  /// Antialias the bar *tips*. Bars sit on whole device pixels horizontally,
  /// so this cannot blur their sides — it only lets a bar end partway down a
  /// pixel, which is the difference between an envelope quantised to whole
  /// pixel steps and one that resolves the amplitude between them.
  final bool antiAlias;
  /// How many shades to step the fill through between the peak envelope and
  /// the RMS core. 1 is a plain two-tone peak/body pair; higher resolves the
  /// space between them, which is where a dense mix's internal shape lives.
  final int bodyBands;
  /// Overrides the user's Waveform Style setting. Null — what every in-app
  /// use passes — follows the setting, so the context menu and the Settings
  /// page stay in agreement. Tests and previews pass an explicit value.
  final WaveformStyle? style;

  const WaveformWidget({
    super.key,
    required this.peaks,
    required this.progress,
    this.onSeek,
    this.playedColor,
    this.unplayedColor,
    this.height = 64,
    this.stereo,
    this.backgroundColor,
    this.barWidth = 1,
    this.barGap = 0,
    this.antiAlias = true,
    this.bodyBands = 4,
    this.style,
  });

  void _handleSeek(double dx, double width) {
    onSeek?.call((dx / width).clamp(0.0, 1.0));
  }

  /// Right-click (or long-press on touch) menu for switching the rendering
  /// without leaving the player.
  ///
  /// Both entries write the same device-local settings the Settings page
  /// edits, so the two never disagree. Channel choice is a per-listener
  /// preference rather than a per-file one, which is why it lives here next
  /// to the style rather than being decided automatically from the audio.
  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;

    final WaveformStyle currentStyle = style ?? ref.read(waveformStyleProvider);
    final bool currentDual = stereo ?? ref.read(waveformStereoProvider);
    // Both renderings can split into lanes, so the only thing that stops it
    // is the file itself having a single channel.
    final hasChannels = peaks?.hasChannelData ?? false;
    final canSplit = hasChannels;

    final choice = await showMenu<_WaveformMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<_WaveformMenuAction>(
          enabled: false,
          height: 32,
          child: Text(l10n.waveformStyle,
              style: Theme.of(context).textTheme.labelSmall),
        ),
        CheckedPopupMenuItem(
          value: _WaveformMenuAction.styleDetailed,
          checked: currentStyle == WaveformStyle.detailed,
          child: Text(l10n.waveformStyleDetailed),
        ),
        CheckedPopupMenuItem(
          value: _WaveformMenuAction.styleClassic,
          checked: currentStyle == WaveformStyle.classic,
          child: Text(l10n.waveformStyleClassic),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_WaveformMenuAction>(
          enabled: false,
          height: 32,
          child: Text(
            hasChannels ? l10n.waveformChannels : l10n.waveformChannelsUnavailable,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        CheckedPopupMenuItem(
          value: _WaveformMenuAction.channelsSingle,
          enabled: canSplit,
          checked: !currentDual,
          child: Text(l10n.waveformChannelsSingle),
        ),
        CheckedPopupMenuItem(
          value: _WaveformMenuAction.channelsDual,
          enabled: canSplit,
          checked: currentDual,
          child: Text(l10n.waveformChannelsDual),
        ),
      ],
    );
    if (choice == null) return;

    switch (choice) {
      case _WaveformMenuAction.styleDetailed:
        await ref.read(waveformStyleProvider.notifier).set(WaveformStyle.detailed);
      case _WaveformMenuAction.styleClassic:
        await ref.read(waveformStyleProvider.notifier).set(WaveformStyle.classic);
      case _WaveformMenuAction.channelsSingle:
        await ref.read(waveformStereoProvider.notifier).set(false);
      case _WaveformMenuAction.channelsDual:
        await ref.read(waveformStereoProvider.notifier).set(true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final played = playedColor ?? Theme.of(context).colorScheme.primary;
    final unplayed = unplayedColor ?? played.withValues(alpha: 0.3);
    final WaveformStyle effectiveStyle = style ?? ref.watch(waveformStyleProvider);
    final bool effectiveStereo = stereo ?? ref.watch(waveformStereoProvider);

    if (peaks == null) {
      // No peaks yet — show a seekable thin progress bar so the user can
      // still seek while the waveform is being extracted in the background.
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = height ?? constraints.maxHeight;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onSeek != null ? (d) => _handleSeek(d.localPosition.dx, w) : null,
            onHorizontalDragUpdate: onSeek != null ? (d) => _handleSeek(d.localPosition.dx, w) : null,
            onSecondaryTapDown: (d) => _showMenu(context, ref, d.globalPosition),
            onLongPressStart: (d) => _showMenu(context, ref, d.globalPosition),
            child: SizedBox(
              height: h,
              child: Center(
                child: SizedBox(
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1.5),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: unplayed,
                      color: played,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    final background =
        backgroundColor ?? Theme.of(context).colorScheme.surface;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    _WaveformPainter layer(Color color) => _WaveformPainter(
      peaks: peaks!,
      color: color,
      backgroundColor: background,
      pixelRatio: pixelRatio,
      stereo: effectiveStereo,
      barWidth: barWidth,
      barGap: barGap,
      antiAlias: antiAlias,
      bodyBands: bodyBands,
      style: effectiveStyle,
    );

    // No LayoutBuilder here: one is rebuilt, so laid out again, with every
    // new position, and a layout marks everything up to the page for
    // repaint. The width a seek needs is read from the box when it happens.
    void seek(BuildContext context, Offset local) {
      final box = context.findRenderObject();
      if (box is RenderBox && box.hasSize && box.size.width > 0) {
        _handleSeek(local.dx, box.size.width);
      }
    }

    return Builder(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => seek(context, d.localPosition),
        onHorizontalDragUpdate: (d) => seek(context, d.localPosition),
        onSecondaryTapDown: (d) => _showMenu(context, ref, d.globalPosition),
        onLongPressStart: (d) => _showMenu(context, ref, d.globalPosition),
        // Its own repaint boundary, and the played part only a clip over a
        // second copy: as a song plays, the clip moves and nothing is
        // painted — neither the waveform nor the page around it, which used
        // to repaint with every position update.
        child: RepaintBoundary(
          child: SizedBox(
            // Null fills the height the parent gives, as the width always
            // does.
            height: height ?? double.infinity,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(child: CustomPaint(painter: layer(unplayed))),
                ClipRect(
                  clipper: _ProgressClipper(progress),
                  child: RepaintBoundary(
                    child: CustomPaint(painter: layer(played)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How many times a waveform layer has been painted, for tests: playing
/// must not paint it again.
@visibleForTesting
int debugWaveformPaintCount = 0;

/// The played part of the waveform: everything left of [progress].
class _ProgressClipper extends CustomClipper<Rect> {
  const _ProgressClipper(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
    0,
    0,
    size.width * progress.clamp(0.0, 1.0),
    size.height,
  );

  @override
  bool shouldReclip(_ProgressClipper old) => old.progress != progress;
}

/// What the waveform's context menu can change.
enum _WaveformMenuAction {
  styleDetailed,
  styleClassic,
  channelsSingle,
  channelsDual,
}

/// Reduces per-frame min/max peaks to exactly [columns] column extents,
/// interleaved as `[min0, max0, min1, max1, …]` in −1…+1 units.
///
/// Each column takes the extreme of *every* source frame that falls inside it,
/// so drawing narrower than the data drops no transients (picking one frame
/// per column and skipping the rest is what makes a downscaled waveform
/// shimmer as it resizes). Drawing wider than the data repeats frames instead,
/// which stays crisp rather than interpolating to a smooth curve.
@visibleForTesting
Float32List reduceToColumns(
  List<double> mins,
  List<double> maxs,
  int columns,
) {
  final out = Float32List(max(0, columns) * 2);
  final n = min(mins.length, maxs.length);
  if (n == 0 || columns <= 0) return out;

  for (int c = 0; c < columns; c++) {
    final start = c * n ~/ columns;
    final end = max(start + 1, (c + 1) * n ~/ columns);
    double lo = 0, hi = 0;
    for (int i = start; i < end && i < n; i++) {
      if (mins[i] < lo) lo = mins[i];
      if (maxs[i] > hi) hi = maxs[i];
    }
    out[c * 2] = lo;
    out[c * 2 + 1] = hi;
  }
  return out;
}

/// Reduces per-frame RMS magnitudes to [columns] symmetric extents, in the
/// same `[min0, max0, …]` shape [reduceToColumns] produces so both layers of a
/// lane can be drawn by one routine.
///
/// Takes the loudest RMS in each column, matching how the peak layer above it
/// reduces — averaging instead would let the body creep outside the outline
/// wherever a column straddles a transient.
@visibleForTesting
Float32List reduceRmsToColumns(List<double> rms, int columns) {
  final out = Float32List(max(0, columns) * 2);
  final n = rms.length;
  if (n == 0 || columns <= 0) return out;

  for (int c = 0; c < columns; c++) {
    final start = c * n ~/ columns;
    final end = max(start + 1, (c + 1) * n ~/ columns);
    double v = 0;
    for (int i = start; i < end && i < n; i++) {
      final a = rms[i].abs();
      if (a > v) v = a;
    }
    out[c * 2] = -v;
    out[c * 2 + 1] = v;
  }
  return out;
}

/// Bar layout across a [width]-wide widget, in logical pixels: how wide to
/// stroke a bar, how far apart to space them, and how many fit.
///
/// [barWidth] and [barGap] are given in *device* pixels so a bar means the
/// same physical thickness on every display — a 1-logical-pixel bar is three
/// screen pixels wide at 3× and looks nothing like the same design.
@visibleForTesting
({double pitch, double stroke, int columns}) waveformBarLayout({
  required double width,
  required double pixelRatio,
  required double barWidth,
  required double barGap,
}) {
  final unit = 1.0 / (pixelRatio > 0 ? pixelRatio : 1.0);
  final stroke = max(1.0, barWidth) * unit;
  final pitch = stroke + max(0.0, barGap) * unit;
  // The last bar only needs its own width to fit, not a full pitch.
  final columns = max(1, ((width - stroke) / pitch).floor() + 1);
  return (pitch: pitch, stroke: stroke, columns: columns);
}

typedef _Geometry = ({double pitch, double stroke, int columns});

/// The opaque colour for each drawn band, outermost first: index 0 is the peak
/// outline, the last is the innermost RMS core.
///
/// Every colour is flattened against [background] before use. The bands
/// overlap, so a translucent one composites with itself once per layer and the
/// stack blurs into a doubled, out-of-focus edge — which is what the unplayed
/// half of the waveform used to do, since it defaults to 30% alpha while the
/// played half is opaque.
@visibleForTesting
List<Color> waveformBandColors({
  required Color requested,
  required Color background,
  required int bands,
  double bodyTint = 0.5,
}) {
  final outline = Color.alphaBlend(requested, background);
  final body = Color.lerp(outline, background, bodyTint)!;
  final count = max(1, bands);
  return [
    outline,
    for (int b = 1; b <= count; b++) Color.lerp(outline, body, b / count)!,
  ];
}

/// One drawn pass: the bar endpoints, and which band colour paints them —
/// index 0 is the peak outline, the last index the innermost RMS core.
class _Layer {
  final Float32List points;
  final int band;

  const _Layer(this.points, this.band);
}

/// Interpolates between two column-extent arrays, `t` = 0 giving [outer] and
/// `t` = 1 giving [inner].
///
/// Used to step the fill from the peak envelope down to the RMS core. Both
/// ends are real measured data, so every intermediate band still follows the
/// audio's own contour — unlike a fixed vertical gradient, which washes into a
/// flat wash the moment the body fills the lane.
@visibleForTesting
Float32List lerpExtents(Float32List outer, Float32List inner, double t) {
  final out = Float32List(outer.length);
  for (int i = 0; i < outer.length; i++) {
    out[i] = outer[i] + (inner[i] - outer[i]) * t;
  }
  return out;
}

class _WaveformPainter extends CustomPainter {
  final WaveformPeaks peaks;

  /// The one colour this layer is drawn in: the widget stacks an unplayed
  /// layer and a played one, and the playback position only moves the clip
  /// between them — neither is painted again as a song plays.
  final Color color;
  final Color backgroundColor;
  final double pixelRatio;
  final bool stereo;
  final double barWidth;
  final double barGap;
  final bool antiAlias;
  final int bodyBands;
  final WaveformStyle style;

  /// Gap between the two stereo lanes, in logical pixels.
  static const double laneGap = 3.0;

  /// Under this height two lanes are too short to tell anything apart, so the
  /// mono mixdown is drawn full-height instead. Sized for the smallest embed
  /// (the dashboard's mini player) still getting a usable single lane.
  static const double minStereoHeight = 44.0;

  /// How far the RMS body is pulled toward the backdrop, away from the peak
  /// outline drawn behind it. Enough separation to read as a distinct mass,
  /// not so much that the body disappears into the background.
  static const double bodyTint = 0.5;

  const _WaveformPainter({
    required this.peaks,
    required this.color,
    required this.backgroundColor,
    required this.pixelRatio,
    required this.stereo,
    required this.barWidth,
    required this.barGap,
    required this.antiAlias,
    required this.bodyBands,
    required this.style,
  });

  /// Turns per-column `[min, max]` extents into vertical line endpoints for
  /// [ui.PointMode.lines], as `[x0,y0, x1,y1, …]`.
  Float32List _points(
    Float32List extents,
    Rect band,
    _Geometry geo, {
    required bool hairlineWhenEmpty,
  }) {
    final mid = band.top + band.height / 2;
    final half = band.height / 2;
    final points = Float32List(geo.columns * 4);

    for (int c = 0; c < geo.columns; c++) {
      // Centring the stroke in its slot puts an unantialiased bar on whole
      // device pixels instead of straddling two.
      final x = band.left + c * geo.pitch + geo.stroke / 2;
      var top = mid - extents[c * 2 + 1] * half;
      var bottom = mid - extents[c * 2] * half;
      if (bottom - top < geo.stroke) {
        if (hairlineWhenEmpty) {
          // Silence still gets a hairline: the track reads as one continuous
          // strip thinning out, rather than vanishing mid-song.
          top = mid - geo.stroke / 2;
          bottom = mid + geo.stroke / 2;
        } else {
          // The body, though, must not draw a centre line through silence —
          // that would paint a solid rule across every quiet passage.
          top = bottom = mid;
        }
      }
      points[c * 4] = x;
      points[c * 4 + 1] = top;
      points[c * 4 + 2] = x;
      points[c * 4 + 3] = bottom;
    }
    return points;
  }

  /// The peak outline and, when the source supplied one, the RMS body to inset
  /// inside it — in back-to-front draw order.
  List<_Layer> _lane(
    List<double> mins,
    List<double> maxs,
    List<double>? rms,
    Rect band,
    _Geometry geo,
  ) {
    final outer = reduceToColumns(mins, maxs, geo.columns);
    final layers = [
      _Layer(_points(outer, band, geo, hairlineWhenEmpty: true), 0),
    ];
    if (rms == null) return layers;

    // Step the fill inward from the peak envelope to the RMS core in
    // [bodyBands] shades. One band is the plain two-tone peak/body pair; more
    // bands resolve the space between them, which is where a dense mix's
    // internal shape lives — with a single hard step it collapses into two
    // flat slabs meeting at a line.
    final inner = reduceRmsToColumns(rms, geo.columns);
    final bands = max(1, bodyBands);
    for (int b = 1; b <= bands; b++) {
      final t = b / bands;
      layers.add(_Layer(
        _points(lerpExtents(outer, inner, t), band, geo,
            hairlineWhenEmpty: false),
        b,
      ));
    }
    return layers;
  }

  /// The original rendering: one antialiased polygon traced across the peak
  /// tips and back along the troughs, filled solid. Kept selectable because
  /// its plainer silhouette is a legitimate preference, not a bug.
  /// One filled envelope traced across the peak tips of [maxs] and back along
  /// the troughs of [mins], inside [band].
  Path _classicPath(Rect band, List<double> mins, List<double> maxs) {
    final count = min(mins.length, maxs.length);
    final path = Path();
    if (count == 0) return path;

    final middle = band.top + band.height / 2;
    final half = band.height / 2;
    final dx = band.width / count;

    path.moveTo(band.left, middle);
    for (int i = 0; i < count; i++) {
      path.lineTo(band.left + dx * i, middle - half * maxs[i]);
    }
    path.lineTo(band.right, middle);
    for (int i = count - 1; i >= 0; i--) {
      path.lineTo(band.left + dx * i, middle - half * mins[i]);
    }
    path.close();
    return path;
  }

  /// The original rendering: filled polygons rather than per-pixel bars. Kept
  /// selectable because its plainer silhouette is a legitimate preference.
  ///
  /// It honours [stereo] exactly as the detailed renderer does — two filled
  /// envelopes in two bands. Nothing about a filled outline prevents that; it
  /// simply drew one shape because that is all the original ever needed to.
  void _paintClassic(Canvas canvas, Size size) {
    if (peaks.frameCount == 0) return;

    final paths = <Path>[];
    if (stereo && peaks.hasChannelData && size.height >= minStereoHeight) {
      final laneHeight = (size.height - laneGap) / 2;
      for (int ch = 0; ch < 2; ch++) {
        paths.add(_classicPath(
          Rect.fromLTWH(0, ch * (laneHeight + laneGap), size.width, laneHeight),
          peaks.channelMin[ch],
          peaks.channelMax[ch],
        ));
      }
    } else {
      paths.add(
          _classicPath(Offset.zero & size, peaks.minValues, peaks.maxValues));
    }

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = color;
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    debugWaveformPaintCount++;

    if (style == WaveformStyle.classic) {
      _paintClassic(canvas, size);
      return;
    }

    final geo = waveformBarLayout(
      width: size.width,
      pixelRatio: pixelRatio,
      barWidth: barWidth,
      barGap: barGap,
    );

    final twoLanes =
        stereo && peaks.hasChannelData && size.height >= minStereoHeight;

    // Outline then body, per lane, in back-to-front draw order.
    final layers = <_Layer>[];
    if (twoLanes) {
      final laneHeight = (size.height - laneGap) / 2;
      for (int ch = 0; ch < 2; ch++) {
        layers.addAll(_lane(
          peaks.channelMin[ch],
          peaks.channelMax[ch],
          peaks.hasChannelRms(ch) ? peaks.channelRms[ch] : null,
          Rect.fromLTWH(0, ch * (laneHeight + laneGap), size.width, laneHeight),
          geo,
        ));
      }
    } else {
      layers.addAll(_lane(
        peaks.minValues,
        peaks.maxValues,
        peaks.hasRms ? peaks.rmsValues : null,
        Offset.zero & size,
        geo,
      ));
    }

    void drawAll(Color requested) {
      // Opaque, pre-flattened band colours — see [waveformBandColors] for why
      // they must not carry alpha of their own.
      final colors = waveformBandColors(
        requested: requested,
        background: backgroundColor,
        bands: max(1, bodyBands),
        bodyTint: bodyTint,
      );
      final paint = Paint()
        // Bars sit on exact device-pixel bounds horizontally, so antialiasing
        // cannot soften their sides — it only resolves the *tips*, letting a
        // bar end partway down a pixel instead of snapping to a whole one.
        // That is sub-pixel amplitude precision: the envelope contour stops
        // being quantised to ~1/lane-height steps.
        ..isAntiAlias = antiAlias
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = geo.stroke;

      for (final layer in layers) {
        paint.color = colors[min(layer.band, colors.length - 1)];
        canvas.drawRawPoints(ui.PointMode.lines, layer.points, paint);
      }
    }

    drawAll(color);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.peaks != peaks ||
      old.color != color ||
      old.backgroundColor != backgroundColor ||
      old.pixelRatio != pixelRatio ||
      old.stereo != stereo ||
      old.barWidth != barWidth ||
      old.barGap != barGap ||
      old.antiAlias != antiAlias ||
      old.bodyBands != bodyBands ||
      old.style != style;
}
