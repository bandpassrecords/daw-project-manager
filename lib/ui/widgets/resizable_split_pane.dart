import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The smallest height either pane of a [ResizableVerticalSplit] may shrink
/// to — enough for a section header and a row or two.
const double kSplitPaneMinHeight = 120;

/// Clamps the top pane's share of the height to what leaves both panes at
/// least [minPane] tall in [available] height.
///
/// When [available] cannot fit two minimum panes, an even split is the only
/// fair answer. NaN (a drag computed against a zero height) also falls back
/// to an even split.
double clampSplitFraction(
  double fraction, {
  required double available,
  double minPane = kSplitPaneMinHeight,
}) {
  if (fraction.isNaN || !available.isFinite || available <= 2 * minPane) {
    return 0.5;
  }
  final lower = minPane / available;
  return fraction.clamp(lower, 1 - lower).toDouble();
}

/// Two panes stacked vertically, with a handle on the divider between them
/// that the user drags to give one more height than the other.
///
/// The vertical sibling of `ResizableRailLayout`, with the same contract:
/// plain values and callbacks, the page owns the [fraction] (see
/// `releaseTracksSplitProvider`). [onResize] follows the pointer,
/// [onResizeEnd] is where the page saves, double-clicking the handle calls
/// [onReset]. The fraction always goes through [clampSplitFraction] against
/// the height actually available.
class ResizableVerticalSplit extends StatefulWidget {
  const ResizableVerticalSplit({
    super.key,
    required this.top,
    required this.bottom,
    required this.fraction,
    required this.defaultFraction,
    required this.onResize,
    required this.onResizeEnd,
    required this.onReset,
    this.handleTooltip,
  });

  final Widget top;
  final Widget bottom;

  /// The top pane's share of the height, or null for [defaultFraction].
  final double? fraction;
  final double defaultFraction;
  final ValueChanged<double> onResize;
  final VoidCallback onResizeEnd;
  final VoidCallback onReset;
  final String? handleTooltip;

  /// How tall the grab area is. The visible divider inside it stays 1px.
  static const double handleHeight = 7;

  @override
  State<ResizableVerticalSplit> createState() => _ResizableVerticalSplitState();
}

class _ResizableVerticalSplitState extends State<ResizableVerticalSplit> {
  bool _hovering = false;
  bool _dragging = false;

  /// The unclamped top height under the pointer, so dragging past a limit
  /// and back keeps the divider in step with the pointer.
  double _dragHeight = 0;

  void _endDrag() {
    setState(() => _dragging = false);
    widget.onResizeEnd();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final available =
          constraints.maxHeight - ResizableVerticalSplit.handleHeight;
      final fraction = clampSplitFraction(
        widget.fraction ?? widget.defaultFraction,
        available: available,
      );
      final topHeight = available * fraction;
      final active = _hovering || _dragging;

      Widget handle = MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onVerticalDragStart: (_) => setState(() {
            _dragging = true;
            _dragHeight = topHeight;
          }),
          onVerticalDragUpdate: (details) {
            _dragHeight += details.delta.dy;
            widget.onResize(
              clampSplitFraction(_dragHeight / available, available: available),
            );
          },
          onVerticalDragEnd: (_) => _endDrag(),
          onVerticalDragCancel: _endDrag,
          onDoubleTap: widget.onReset,
          child: SizedBox(
            height: ResizableVerticalSplit.handleHeight,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: active ? 3 : 1,
                color: active ? cs.primary : Theme.of(context).dividerColor,
              ),
            ),
          ),
        ),
      );
      final tooltip = widget.handleTooltip;
      if (tooltip != null && !_dragging) {
        handle = Tooltip(
          message: tooltip,
          waitDuration: const Duration(milliseconds: 800),
          child: handle,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topHeight, child: widget.top),
          handle,
          Expanded(child: widget.bottom),
        ],
      );
    });
  }
}
