import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An HSV color wheel: hue around the circumference, saturation from the
/// centre outwards. Brightness is a separate control — see [ColorValueSlider].
///
/// Hand-rolled rather than pulled from a package because the Flathub build
/// runs offline (see `flatpak/README.md`), so every dependency has to be
/// vendored; a disc and a hit test are not worth that.
class ColorWheel extends StatelessWidget {
  /// The currently selected color. Its hue and saturation place the thumb;
  /// its value shades the whole disc so the wheel matches what is selected.
  final HSVColor color;

  /// Fired continuously while dragging, so the hex field can track the thumb.
  final ValueChanged<HSVColor> onChanged;

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
  static HSVColor colorAt(Offset position, double size, HSVColor current) {
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
  final HSVColor color;
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
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, Colors.white.withValues(alpha: 0)],
        ).createShader(rect),
    );

    // Brightness, so the disc reflects the value slider instead of always
    // showing the fully-lit version of the selected hue.
    if (color.value < 1) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.black.withValues(alpha: 1 - color.value),
      );
    }

    // Thumb, outlined in both black and the surface color so it stays
    // visible over every part of the disc.
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

/// Brightness slider for the wheel, painted as a black-to-full-color ramp.
class ColorValueSlider extends StatelessWidget {
  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  const ColorValueSlider({
    super.key,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fullBright = color.withValue(1).toColor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(colors: [Colors.black, fullBright]),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: fullBright,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: color.value,
            onChanged: (v) => onChanged(color.withValue(v)),
          ),
        ),
      ],
    );
  }
}
