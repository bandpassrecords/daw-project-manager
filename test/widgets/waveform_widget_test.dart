import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/rendering.dart' show RenderClipRect;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/waveform_style.dart';
import 'package:daw_project_manager/services/audio_analysis_service.dart';
import 'package:daw_project_manager/ui/widgets/waveform_widget.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

WaveformPeaks peaksOf({
  required List<double> mins,
  required List<double> maxs,
  List<double> rms = const [],
  List<List<double>> channelMin = const [],
  List<List<double>> channelMax = const [],
  List<List<double>> channelRms = const [],
}) =>
    WaveformPeaks(
      minValues: mins,
      maxValues: maxs,
      rmsValues: rms,
      channelMin: channelMin,
      channelMax: channelMax,
      channelRms: channelRms,
      sampleRate: 44100,
      durationSeconds: 10,
    );

Widget host(Widget child, {double devicePixelRatio = 2.0}) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(devicePixelRatio: devicePixelRatio),
            child: Center(child: SizedBox(width: 400, child: child)),
          ),
        ),
      ),
    );

/// The menu's checkable entries are `CheckedPopupMenuItem<_WaveformMenuAction>`
/// and that type argument is private to the widget, so `find.byType` cannot
/// name it. Match on the widget shape and read the label off its child.
CheckedPopupMenuItem menuItem(WidgetTester tester, String label) => tester
    .widgetList(find.byWidgetPredicate((w) => w is CheckedPopupMenuItem))
    .cast<CheckedPopupMenuItem>()
    .firstWhere((w) => (w.child! as Text).data == label);

/// Right-clicks the middle of the waveform and settles the menu open.
Future<void> openMenu(WidgetTester tester) async {
  final box = tester.getRect(find.byType(WaveformWidget));
  final gesture = await tester.startGesture(box.center,
      kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('reduceToColumns', () {
    test('drawing narrower than the data keeps the extremes of every frame',
        () {
      // A lone transient in frame 5 must survive being squeezed into 2
      // columns — sampling one frame per column would drop it and make the
      // waveform shimmer differently at every width.
      final mins = List<double>.filled(8, -0.1);
      final maxs = List<double>.filled(8, 0.1);
      maxs[5] = 0.95;
      mins[5] = -0.85;

      final out = reduceToColumns(mins, maxs, 2);

      expect(out, hasLength(4));
      expect(out[0], closeTo(-0.1, 1e-6)); // columns 0–3: quiet
      expect(out[1], closeTo(0.1, 1e-6));
      expect(out[2], closeTo(-0.85, 1e-6)); // columns 4–7: holds the transient
      expect(out[3], closeTo(0.95, 1e-6));
    });

    test('drawing wider than the data repeats frames instead of interpolating',
        () {
      final out = reduceToColumns([-0.2, -0.6], [0.2, 0.6], 6);

      expect(out, hasLength(12));
      for (int c = 0; c < 3; c++) {
        expect(out[c * 2], closeTo(-0.2, 1e-6));
        expect(out[c * 2 + 1], closeTo(0.2, 1e-6));
      }
      for (int c = 3; c < 6; c++) {
        expect(out[c * 2], closeTo(-0.6, 1e-6));
        expect(out[c * 2 + 1], closeTo(0.6, 1e-6));
      }
    });

    test('emits exactly one min/max pair per requested column', () {
      expect(reduceToColumns(List.filled(37, -1), List.filled(37, 1), 100),
          hasLength(200));
      expect(reduceToColumns(List.filled(500, -1), List.filled(500, 1), 13),
          hasLength(26));
    });

    test('covers the final frame at any column count', () {
      // The last frame is the loudest; it must appear in the last column
      // whether the ratio divides evenly or not.
      for (final columns in [3, 7, 64, 999]) {
        final mins = List<double>.filled(50, 0.0);
        final maxs = List<double>.filled(50, 0.0);
        maxs[49] = 1.0;

        final out = reduceToColumns(mins, maxs, columns);
        expect(out[columns * 2 - 1], closeTo(1.0, 1e-6),
            reason: 'lost the last frame at $columns columns');
      }
    });

    test('returns zeros rather than throwing on empty or degenerate input', () {
      expect(reduceToColumns([], [], 4), hasLength(8));
      expect(reduceToColumns([], [], 4).every((v) => v == 0), isTrue);
      expect(reduceToColumns([-1], [1], 0), isEmpty);
      expect(reduceToColumns([-1], [1], -5), isEmpty);
    });

    test('reads no further than the shorter of the two arrays', () {
      // Defensive: a truncated cache entry must not index out of range.
      expect(() => reduceToColumns([-1, -1, -1], [1], 3), returnsNormally);
    });
  });

  group('reduceRmsToColumns', () {
    test('mirrors each magnitude into a symmetric extent', () {
      final out = reduceRmsToColumns([0.4, 0.7], 2);
      expect(out, hasLength(4));
      expect(out[0], closeTo(-0.4, 1e-6));
      expect(out[1], closeTo(0.4, 1e-6));
      expect(out[2], closeTo(-0.7, 1e-6));
      expect(out[3], closeTo(0.7, 1e-6));
    });

    test('takes the loudest RMS in a column, so the body stays inside the '
        'peak outline', () {
      // The peak layer reduces by extreme; averaging here instead would let a
      // column straddling a transient draw its body outside its own outline.
      final rms = [0.1, 0.1, 0.1, 0.9];
      final peakMax = [0.2, 0.2, 0.2, 1.0];

      final body = reduceRmsToColumns(rms, 1);
      final outline = reduceToColumns([for (final v in peakMax) -v], peakMax, 1);

      expect(body[1], closeTo(0.9, 1e-6));
      expect(body[1], lessThanOrEqualTo(outline[1]));
    });

    test('returns zeros rather than throwing on degenerate input', () {
      expect(reduceRmsToColumns([], 3), hasLength(6));
      expect(reduceRmsToColumns([], 3).every((v) => v == 0), isTrue);
      expect(reduceRmsToColumns([0.5], 0), isEmpty);
    });
  });

  group('waveformBandColors', () {
    const bg = Color(0xFF0F0F1E);

    test('flattens a translucent request so the bands cannot stack', () {
      // Regression: the bands overlap, so a translucent colour composited with
      // itself once per layer. The unplayed half of the waveform defaults to
      // 30% alpha while the played half is opaque, so only the unplayed side
      // smeared — it read as a doubled, out-of-focus edge next to a clean one.
      final colors = waveformBandColors(
        requested: const Color(0x4D00D4FF), // 30% alpha, the real default
        background: bg,
        bands: 4,
      );

      expect(colors, hasLength(5)); // outline + 4 bands
      for (final c in colors) {
        expect(c.a, 1.0, reason: '$c still carries alpha');
      }
    });

    test('an opaque request is passed through unchanged', () {
      const opaque = Color(0xFF00D4FF);
      final colors =
          waveformBandColors(requested: opaque, background: bg, bands: 3);
      expect(colors.first, opaque);
    });

    test('bands run from the outline toward the background, in order', () {
      final colors = waveformBandColors(
        requested: const Color(0xFF00D4FF),
        background: bg,
        bands: 4,
      );
      // Each step moves closer to the backdrop than the last.
      double distance(Color c) =>
          (c.r - bg.r).abs() + (c.g - bg.g).abs() + (c.b - bg.b).abs();
      for (int i = 1; i < colors.length; i++) {
        expect(distance(colors[i]), lessThan(distance(colors[i - 1])),
            reason: 'band $i did not step toward the backdrop');
      }
    });

    test('the played and unplayed halves blend the same way', () {
      // Both sides must produce the same *shape* of ramp; only the starting
      // colour differs. This is what makes the two halves look like one
      // waveform rather than two differently-rendered ones.
      final played = waveformBandColors(
          requested: const Color(0xFF00D4FF), background: bg, bands: 4);
      final unplayed = waveformBandColors(
          requested: const Color(0x4D00D4FF), background: bg, bands: 4);

      expect(unplayed, hasLength(played.length));
      for (int i = 0; i < played.length; i++) {
        expect(unplayed[i].a, played[i].a);
      }
    });

    test('a single band still yields an outline and a body', () {
      final colors = waveformBandColors(
          requested: const Color(0xFF00D4FF), background: bg, bands: 1);
      expect(colors, hasLength(2));
      expect(colors[0], isNot(colors[1]));
    });
  });

  group('lerpExtents', () {
    test('t=0 is the peak outline and t=1 the RMS core', () {
      final outer = Float32List.fromList([-1.0, 1.0, -0.5, 0.5]);
      final inner = Float32List.fromList([-0.2, 0.2, -0.1, 0.1]);

      expect(lerpExtents(outer, inner, 0).toList(), outer.toList());
      expect(lerpExtents(outer, inner, 1).toList(), inner.toList());
    });

    test('intermediate bands sit between the two, following both contours',
        () {
      // The point of stepping through real measured ends rather than a fixed
      // vertical gradient: a band still traces the audio's own shape.
      final outer = Float32List.fromList([-1.0, 1.0, -0.4, 0.4]);
      final inner = Float32List.fromList([-0.2, 0.2, -0.2, 0.2]);

      final mid = lerpExtents(outer, inner, 0.5);

      expect(mid[1], closeTo(0.6, 1e-6)); // between 1.0 and 0.2
      expect(mid[3], closeTo(0.3, 1e-6)); // between 0.4 and 0.2
      // Column 0 is louder than column 1 in the outline, and stays louder in
      // the band — a lane-anchored gradient would have flattened them equal.
      expect(mid[1], greaterThan(mid[3]));
    });

    test('every band stays inside the outline it was derived from', () {
      final outer = Float32List.fromList([-0.9, 0.7]);
      final inner = Float32List.fromList([-0.3, 0.1]);

      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final band = lerpExtents(outer, inner, t);
        expect(band[1], lessThanOrEqualTo(outer[1] + 1e-6));
        expect(band[0], greaterThanOrEqualTo(outer[0] - 1e-6));
      }
    });
  });

  group('waveformBarLayout', () {
    test('touching one-device-pixel bars fill the width', () {
      final l = waveformBarLayout(
          width: 300, pixelRatio: 2, barWidth: 1, barGap: 0);
      expect(l.stroke, closeTo(0.5, 1e-9)); // 1 device px at 2×
      expect(l.pitch, closeTo(0.5, 1e-9));
      expect(l.columns, 600);
    });

    test('a bar is the same physical thickness at any pixel ratio', () {
      // Sizing in logical pixels instead would make a bar three screen pixels
      // wide at 3× and one at 1× — a different design per display.
      for (final dpr in [1.0, 1.5, 2.0, 3.0]) {
        final l = waveformBarLayout(
            width: 100, pixelRatio: dpr, barWidth: 2, barGap: 0);
        expect(l.stroke * dpr, closeTo(2.0, 1e-9), reason: 'at ${dpr}x');
      }
    });

    test('a gap spaces the bars out and drops the column count', () {
      final solid = waveformBarLayout(
          width: 300, pixelRatio: 2, barWidth: 2, barGap: 0);
      final spaced = waveformBarLayout(
          width: 300, pixelRatio: 2, barWidth: 2, barGap: 2);

      expect(spaced.stroke, closeTo(solid.stroke, 1e-9)); // same bar…
      expect(spaced.pitch, closeTo(solid.pitch * 2, 1e-9)); // …twice the pitch
      expect(spaced.columns, lessThan(solid.columns));
    });

    test('every bar fits inside the widget', () {
      for (final (w, g) in [(1.0, 0.0), (2.0, 1.0), (3.0, 2.0), (7.0, 3.0)]) {
        const width = 257.0;
        final l = waveformBarLayout(
            width: width, pixelRatio: 2, barWidth: w, barGap: g);
        final rightEdge = (l.columns - 1) * l.pitch + l.stroke;
        expect(rightEdge, lessThanOrEqualTo(width + 1e-9),
            reason: 'bar $w/gap $g overflowed');
      }
    });

    test('clamps a degenerate width or ratio to one bar instead of zero', () {
      expect(
          waveformBarLayout(width: 1, pixelRatio: 2, barWidth: 8, barGap: 0)
              .columns,
          1);
      expect(
          waveformBarLayout(width: 300, pixelRatio: 0, barWidth: 1, barGap: 0)
              .stroke,
          closeTo(1.0, 1e-9));
      expect(
          waveformBarLayout(width: 300, pixelRatio: 2, barWidth: 0, barGap: -5)
              .stroke,
          closeTo(0.5, 1e-9));
    });
  });

  group('WaveformWidget', () {
    final stereoPeaks = peaksOf(
      mins: List.generate(200, (i) => -0.5),
      maxs: List.generate(200, (i) => 0.5),
      rms: List.filled(200, 0.3),
      channelMin: [List.filled(200, -0.9), List.filled(200, -0.2)],
      channelMax: [List.filled(200, 0.9), List.filled(200, 0.2)],
      channelRms: [List.filled(200, 0.55), List.filled(200, 0.1)],
    );
    final monoPeaks = peaksOf(
      mins: List.filled(200, -0.5),
      maxs: List.filled(200, 0.5),
      rms: List.filled(200, 0.3),
    );

    testWidgets('paints stereo peaks without error', (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
            peaks: stereoPeaks, progress: 0.4, height: 80, stereo: true),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('paints mono peaks without error', (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(peaks: monoPeaks, progress: 0.0, height: 64),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints peaks with no RMS body at all', (tester) async {
      // Pre-RMS cache entries and any source that could not supply one still
      // have to draw, as the peak outline alone.
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: peaksOf(
            mins: List.filled(200, -0.5),
            maxs: List.filled(200, 0.5),
          ),
          progress: 0.3,
          height: 64,
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints a lane whose RMS is the wrong length', (tester) async {
      // A truncated cache entry must be ignored, not indexed past its end.
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: peaksOf(
            mins: List.filled(200, -0.5),
            maxs: List.filled(200, 0.5),
            rms: List.filled(7, 0.3),
          ),
          progress: 0.3,
          height: 64,
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints at a height too short for two lanes', (tester) async {
      // Falls back to the mono mixdown rather than two unreadable slivers.
      await tester.pumpWidget(host(
        WaveformWidget(
            peaks: stereoPeaks, progress: 0.9, height: 20, stereo: true),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints with tip antialiasing off', (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
            peaks: monoPeaks, progress: 0.5, height: 64, antiAlias: false),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints with a single tonal band and with many', (tester) async {
      for (final bands in [1, 4, 12]) {
        await tester.pumpWidget(host(
          WaveformWidget(
              peaks: monoPeaks, progress: 0.5, height: 64, bodyBands: bands),
        ));
        expect(tester.takeException(), isNull, reason: '$bands bands');
      }
    });

    testWidgets('clamps a nonsensical band count instead of drawing nothing',
        (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
            peaks: monoPeaks, progress: 0.5, height: 64, bodyBands: 0),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints wide bars separated by a gap', (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: monoPeaks,
          progress: 0.5,
          height: 64,
          barWidth: 3,
          barGap: 2,
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints bars wider than the whole widget', (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
            peaks: monoPeaks, progress: 0.5, height: 64, barWidth: 4000),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints at a fractional device pixel ratio', (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
            peaks: stereoPeaks, progress: 0.5, height: 80, stereo: true),
        devicePixelRatio: 1.5,
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports a 0–1 position when tapped', (tester) async {
      double? seeked;
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: stereoPeaks,
          progress: 0,
          height: 80,
          onSeek: (p) => seeked = p,
        ),
      ));

      final box = tester.getRect(find.byType(WaveformWidget));
      await tester.tapAt(Offset(box.left + box.width * 0.25, box.center.dy));
      await tester.pump();

      expect(seeked, closeTo(0.25, 0.02));
    });

    testWidgets('paints the classic style without error', (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: stereoPeaks,
          progress: 0.5,
          height: 80,
          style: WaveformStyle.classic,
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the classic style ignores the detailed-render options',
        (tester) async {
      // It draws one filled envelope, so bars, bands and lanes have nothing to
      // act on — passing them must not throw or change the result.
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: stereoPeaks,
          progress: 0.5,
          height: 80,
          style: WaveformStyle.classic,
          stereo: true,
          bodyBands: 8,
          barWidth: 3,
          barGap: 2,
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the classic style survives empty peaks', (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: peaksOf(mins: const [], maxs: const []),
          progress: 0.5,
          height: 80,
          style: WaveformStyle.classic,
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('right-click opens a menu offering both renderings',
        (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(peaks: stereoPeaks, progress: 0, height: 80),
      ));

      await openMenu(tester);

      expect(find.text('Detailed'), findsOneWidget);
      expect(find.text('Classic'), findsOneWidget);
      expect(find.text('Single'), findsOneWidget);
      expect(find.text('Dual'), findsOneWidget);
    });

    testWidgets('long-press opens the same menu on touch', (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(peaks: stereoPeaks, progress: 0, height: 80),
      ));

      await tester.longPressAt(tester.getRect(find.byType(WaveformWidget)).center);
      await tester.pumpAndSettle();

      expect(find.text('Detailed'), findsOneWidget);
    });

    testWidgets('a mono file says so instead of offering channel lanes',
        (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(peaks: monoPeaks, progress: 0, height: 80),
      ));

      await openMenu(tester);

      expect(find.text('This file has only one channel'), findsOneWidget);
      // The options are still listed, so the menu keeps a stable shape — but
      // they cannot be chosen for a file that has nothing to split.
      expect(menuItem(tester, 'Single').enabled, isFalse);
    });

    testWidgets('channel lanes stay offered under Classic too', (tester) async {
      // A filled envelope can be drawn twice as easily as once, so the choice
      // belongs to the file's channel count, not to the rendering.
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: stereoPeaks,
          progress: 0,
          height: 80,
          style: WaveformStyle.classic,
        ),
      ));

      await openMenu(tester);

      expect(menuItem(tester, 'Dual').enabled, isTrue);
      expect(menuItem(tester, 'Single').enabled, isTrue);
    });

    testWidgets('Classic paints two lanes when dual channels are on',
        (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: stereoPeaks,
          progress: 0.5,
          height: 110,
          style: WaveformStyle.classic,
          stereo: true,
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Classic falls back to one lane when too short for two',
        (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: stereoPeaks,
          progress: 0.5,
          height: 20,
          style: WaveformStyle.classic,
          stereo: true,
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Classic dual survives peaks whose lanes differ in length',
        (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: peaksOf(
            mins: List.filled(200, -0.5),
            maxs: List.filled(200, 0.5),
            channelMin: [List.filled(200, -0.9), List.filled(3, -0.2)],
            channelMax: [List.filled(200, 0.9), List.filled(7, 0.2)],
          ),
          progress: 0.5,
          height: 110,
          style: WaveformStyle.classic,
          stereo: true,
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the menu checks whichever rendering is active',
        (tester) async {
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: stereoPeaks,
          progress: 0,
          height: 80,
          style: WaveformStyle.classic,
          stereo: true,
        ),
      ));

      await openMenu(tester);

      expect(menuItem(tester, 'Classic').checked, isTrue);
      expect(menuItem(tester, 'Detailed').checked, isFalse);
      expect(menuItem(tester, 'Dual').checked, isTrue);
      expect(menuItem(tester, 'Single').checked, isFalse);
    });

    testWidgets('still seekable while peaks are being extracted',
        (tester) async {
      double? seeked;
      await tester.pumpWidget(host(
        WaveformWidget(
          peaks: null,
          progress: 0,
          height: 80,
          onSeek: (p) => seeked = p,
        ),
      ));

      final box = tester.getRect(find.byType(WaveformWidget));
      await tester.tapAt(Offset(box.left + box.width * 0.5, box.center.dy));
      await tester.pump();

      expect(seeked, closeTo(0.5, 0.02));
    });

    // While a song played the whole page repainted with every position
    // update — the waveform recomputed and drew itself twice, and the
    // projects table above it was drawn again too: the main page felt
    // sluggish. A new position now only moves the played part's clip.
    for (final style in WaveformStyle.values) {
      testWidgets(
          'a new position paints neither the waveform nor what is around '
          'it (${style.name})', (tester) async {
        var around = 0;
        // Only the waveform is rebuilt, as in the player bar.
        final progress = ValueNotifier(0.1);
        addTearDown(progress.dispose);
        await tester.pumpWidget(host(Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(400, 10),
              painter: _CountingPainter(() => around++),
            ),
            ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (_, value, _) => WaveformWidget(
                peaks: stereoPeaks,
                progress: value,
                height: 80,
                style: style,
              ),
            ),
          ],
        )));
        final waveformPaints = debugWaveformPaintCount;
        final aroundPaints = around;

        for (final value in [0.2, 0.5, 0.9, 1.0]) {
          progress.value = value;
          await tester.pump();
        }

        expect(debugWaveformPaintCount, waveformPaints);
        expect(around, aroundPaints);
      });
    }

    testWidgets('the played part reaches exactly as far as the position',
        (tester) async {
      Future<double> playedWidth(double progress) async {
        await tester.pumpWidget(host(
          WaveformWidget(peaks: monoPeaks, progress: progress, height: 64),
        ));
        final clip = tester.renderObject<RenderClipRect>(find.descendant(
          of: find.byType(WaveformWidget),
          matching: find.byType(ClipRect),
        ));
        return clip.clipper!.getClip(clip.size).width;
      }

      expect(await playedWidth(0), 0);
      expect(await playedWidth(0.25), closeTo(100, 1e-9));
      expect(await playedWidth(1), closeTo(400, 1e-9));
      // A position reported a hair past the end draws no further.
      expect(await playedWidth(1.02), closeTo(400, 1e-9));
    });

    testWidgets('a new colour paints the waveform again', (tester) async {
      await tester.pumpWidget(host(WaveformWidget(
          peaks: monoPeaks, progress: 0.5, height: 64, playedColor: Colors.red)));
      final before = debugWaveformPaintCount;
      await tester.pumpWidget(host(WaveformWidget(
          peaks: monoPeaks, progress: 0.5, height: 64, playedColor: Colors.blue)));
      expect(debugWaveformPaintCount, greaterThan(before));
    });
  });
}

/// Counts its paints; never asks to repaint itself, so any paint is one the
/// widgets around it caused.
class _CountingPainter extends CustomPainter {
  _CountingPainter(this.onPaint);
  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) => onPaint();

  @override
  bool shouldRepaint(_CountingPainter old) => false;
}
