import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The icon for a dashboard row's play button.
///
/// Idle it is simply [idleIcon]. While that row's preview is playing
/// ([isPlaying]) it becomes a "now playing" equaliser: the same filled circle
/// as the play/pause icons, with three bars bouncing at different rhythms
/// cut out of it where the triangle would be. Hovering it shows the pause
/// icon instead, so it is still obvious what a click does.
///
/// Meant as the `icon` of an [IconButton]: it takes its size and colour from
/// the ambient [IconTheme] like an [Icon] would, so the button's own `color`
/// and `iconSize` keep working and the button never changes size.
class NowPlayingIcon extends StatefulWidget {
  const NowPlayingIcon({
    super.key,
    required this.isPlaying,
    required this.idleIcon,
    this.pauseIcon = Icons.pause_circle,
  });

  final bool isPlaying;
  final IconData idleIcon;
  final IconData pauseIcon;

  /// One loop of the bars. Each bar moves at a whole-number multiple of this,
  /// so the loop is seamless.
  static const Duration period = Duration(milliseconds: 1600);

  @override
  State<NowPlayingIcon> createState() => _NowPlayingIconState();
}

class _NowPlayingIconState extends State<NowPlayingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: NowPlayingIcon.period);
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(NowPlayingIcon old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !old.isPlaying) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && old.isPlaying) {
      _ctrl.stop();
      _hovering = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) return Icon(widget.idleIcon);

    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    final color = theme.color ?? Theme.of(context).colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: _hovering
          ? Icon(widget.pauseIcon)
          : SizedBox.square(
              dimension: size,
              child: CustomPaint(
                key: const ValueKey('now-playing-bars'),
                painter: NowPlayingBarsPainter(
                  progress: _ctrl,
                  color: color,
                ),
              ),
            ),
    );
  }
}

/// Paints the filled circle with three bouncing bars knocked out of it.
///
/// Material's `*_circle` glyphs sit on a 24-unit grid with a 20-unit circle,
/// so the disc is drawn at the same proportions to line up with them.
class NowPlayingBarsPainter extends CustomPainter {
  NowPlayingBarsPainter({required this.progress, required this.color})
      : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  /// How many times each bar rises and falls per loop, and where it starts.
  static const List<int> _cycles = [2, 3, 1];
  static const List<double> _phases = [0.0, 0.35, 0.7];

  /// A bar's height as a fraction of the tallest it gets, for loop
  /// position [t] (0..1). Always between 0.3 and 1, so a bar never vanishes.
  static double barHeight(int bar, double t) {
    final wave =
        math.sin(2 * math.pi * (_cycles[bar] * t + _phases[bar]));
    return 0.3 + 0.7 * (0.5 + 0.5 * wave);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 24;
    final center = size.center(Offset.zero);
    final radius = 10 * unit;

    // A layer so the bars can punch real holes in the disc, like the
    // triangle in play_circle, and show the row colour behind.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(center, radius, Paint()..color = color);

    final clear = Paint()..blendMode = BlendMode.clear;
    final barWidth = 2.2 * unit;
    final gap = 1.6 * unit;
    final maxHeight = 9 * unit;
    final baseline = center.dy + maxHeight / 2;
    final t = progress.value;
    for (var i = 0; i < 3; i++) {
      final left = center.dx + (i - 1) * (barWidth + gap) - barWidth / 2;
      final height = maxHeight * barHeight(i, t);
      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          baseline - height,
          left + barWidth,
          baseline,
          Radius.circular(barWidth / 2),
        ),
        clear,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(NowPlayingBarsPainter old) =>
      old.color != color || old.progress != progress;
}
