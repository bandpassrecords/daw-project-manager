import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An HSL hue/saturation wheel: hue around the circumference, saturation
/// from the centre outward. Lightness is a separate control — see
/// [ColorLightnessSlider] — and never changes how the disc itself is
/// painted, so dragging the lightness slider doesn't redraw the disc out
/// from under a thumb the user is still looking at.
///
/// HSL rather than HSV: the lightness slider needs to run black → the pure
/// hue → white, and lightness 1.0 in HSL is exactly white regardless of hue
/// or saturation. The HSV "value" axis has no such property — value 1.0 is
/// just the fully-saturated hue, never white.
///
/// Hand-rolled rather than pulled from a package because the Flathub build
/// runs offline (see `flatpak/README.md`), so every dependency has to be
/// vendored; a disc and a hit test are not worth that.
class ColorWheel extends StatelessWidget {
  /// The currently selected color. Its hue and saturation place the thumb.
  /// Its lightness is irrelevant to the disc — only [ColorLightnessSlider]
  /// reads it — but is preserved across drags on the wheel.
  final HSLColor color;

  /// Fired continuously while dragging, so the hex field can track the thumb.
  final ValueChanged<HSLColor> onChanged;

  final double size;

  const ColorWheel({
    super.key,
    required this.color,
    required this.onChanged,
    this.size = 168,
  });

  /// Maps a point in the widget's box to a hue/saturation pair.
  ///
  /// Points outside the disc clamp to its rim rather than doing nothing —
  /// dragging past the edge should keep tracking the hue, not stall.
  @visibleForTesting
  static HSLColor colorAt(Offset position, double size, HSLColor current) {
    final radius = size / 2;
    final dx = position.dx - radius;
    final dy = position.dy - radius;

    final hue = (math.atan2(dy, dx) * 180 / math.pi + 360) % 360;
    final distance = math.sqrt(dx * dx + dy * dy);
    final saturation = (distance / radius).clamp(0.0, 1.0);

    return current.withHue(hue).withSaturation(saturation);
  }

  @override
  Widget build(BuildContext context) {
    void handle(Offset localPosition) =>
        onChanged(colorAt(localPosition, size, color));

    return GestureDetector(
      onPanDown: (d) => handle(d.localPosition),
      onPanUpdate: (d) => handle(d.localPosition),
      onTapDown: (d) => handle(d.localPosition),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ColorWheelPainter(
            color: color,
            thumbBorder: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final HSLColor color;
  final Color thumbBorder;

  const _ColorWheelPainter({required this.color, required this.thumbBorder});

  /// Full hue sweep, closing back on red so there is no seam.
  static const List<Color> _hues = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Hue around the circumference. SweepGradient starts at the positive x
    // axis and runs clockwise, which is the same convention as the atan2 in
    // ColorWheel.colorAt — keep the two in step.
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = const SweepGradient(colors: _hues).createShader(rect),
    );

    // Saturation: white at the centre fading to fully saturated at the rim.
    // Deliberately static — the disc always shows this one slice regardless
    // of the current lightness, so it never changes while the lightness
    // slider is being dragged.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, Colors.white.withValues(alpha: 0)],
        ).createShader(rect),
    );

    // Thumb, outlined in both the surface color and whichever of black/white
    // contrasts with the selected color, so it stays visible over every part
    // of the disc and at every lightness.
    final thumb = center +
        Offset(
          math.cos(color.hue * math.pi / 180),
          math.sin(color.hue * math.pi / 180),
        ) *
            (color.saturation * radius);

    canvas.drawCircle(
      thumb,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = thumbBorder,
    );
    canvas.drawCircle(
      thumb,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ThemeData.estimateBrightnessForColor(color.toColor()) ==
                Brightness.dark
            ? Colors.white
            : Colors.black,
    );
  }

  @override
  bool shouldRepaint(_ColorWheelPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.thumbBorder != thumbBorder;
}

/// Lightness slider for the wheel: black at one end, white at the other,
/// the current hue and saturation at full strength in between.
///
/// This is what makes "drag to the end for white" work — an HSV "value"
/// slider can't do that, since its top end is just the saturated hue.
class ColorLightnessSlider extends StatelessWidget {
  final HSLColor color;
  final ValueChanged<HSLColor> onChanged;

  const ColorLightnessSlider({
    super.key,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pureHue = color.withLightness(0.5).toColor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              colors: [Colors.black, pureHue, Colors.white],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: color.toColor(),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: color.lightness,
            onChanged: (v) => onChanged(color.withLightness(v)),
          ),
        ),
      ],
    );
  }
}
