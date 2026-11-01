import 'dart:math' as math;
import 'dart:ui';

/// The size the window opens at: [desired], but never larger than [visible]
/// (the screen minus the menu bar and Dock), and never below [minimum].
///
/// A fixed 1800×1040 opened wider than a 16" MacBook Pro's default 1728×1117
/// screen. A [margin] is left on each axis so the window's edges are not flush
/// with the screen's. With no screen known the desired size stands.
Size fitInitialWindowSize({
  required Size desired,
  required Size minimum,
  Size? visible,
  double margin = 24,
}) {
  if (visible == null) return desired;
  return Size(
    math.max(minimum.width, math.min(desired.width, visible.width - margin)),
    math.max(minimum.height, math.min(desired.height, visible.height - margin)),
  );
}
