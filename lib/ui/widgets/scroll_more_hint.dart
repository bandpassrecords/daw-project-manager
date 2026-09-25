import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

/// Makes a height-capped scrolling area *look* scrollable.
///
/// A list inside a `ConstrainedBox` that happens to cut off mid-row gives no
/// sign there is more below: the scrollbar is transient on desktop, and a row
/// clipped flush against the border reads as the end of the list. The release
/// page's file box hit exactly that — a third file sat just past the fold with
/// nothing to suggest scrolling.
///
/// Adds three signals, all of which disappear once the end is reached:
/// an always-visible scrollbar, a fade over the bottom edge, and a chevron
/// badge. The fade is the one that does the real work — it makes the cut-off
/// row obviously cut off rather than merely short.
class ScrollMoreHint extends StatefulWidget {
  const ScrollMoreHint({super.key, required this.builder});

  /// Builds the scrolling child, which **must** attach the given controller to
  /// its scroll view — the hints are driven entirely by its metrics.
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<ScrollMoreHint> createState() => _ScrollMoreHintState();
}

class _ScrollMoreHintState extends State<ScrollMoreHint> {
  final ScrollController _controller = ScrollController();
  bool _hasMoreBelow = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Recomputes from [metrics], deferring the setState past the current frame.
  ///
  /// Scroll notifications arrive *during* layout, and calling setState there
  /// throws; the first one arrives on the very first layout, which is exactly
  /// when the hint most needs to appear.
  void _update(ScrollMetrics metrics) {
    final more = metrics.hasContentDimensions &&
        metrics.extentAfter > 1.0;
    if (more == _hasMoreBelow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _hasMoreBelow = more);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Fades to the surface the list sits on, so the gradient reads as the
    // content dissolving rather than as a grey band drawn over it.
    final fadeColor = theme.cardColor;

    return NotificationListener<ScrollMetricsNotification>(
      // Fires on the first layout and whenever the content resizes, which a
      // plain ScrollNotification does not — without it the hint would only
      // appear after the user already scrolled.
      onNotification: (notification) {
        _update(notification.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _update(notification.metrics);
          return false;
        },
        child: Stack(
          children: [
            Scrollbar(
              controller: _controller,
              thumbVisibility: true,
              child: widget.builder(context, _controller),
            ),
            if (_hasMoreBelow)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          fadeColor.withValues(alpha: 0),
                          fadeColor.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Tooltip(
                      message: AppLocalizations.of(context)!.scrollForMore,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
