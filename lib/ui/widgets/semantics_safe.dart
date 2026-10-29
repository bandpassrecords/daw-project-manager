import 'package:material_ui/material_ui.dart';

// Flutter 3.47 sends Windows' accessibility bridge semantics nodes that no
// node holds as a child. The bridge refuses the whole update over one — the
// console's "Failed to update ui::AXTree, error: N will not be in the tree
// and is not the new root" — and its tree then stays stale while the window
// is open; with a screen reader attached, a later update can end the process
// outright (flutter/flutter#182444, #190357). Both widgets here sidestep one
// way of making such a node, until the framework stops making them.
// `test/helpers/semantics_orphans.dart` finds them in a widget test.

/// A [Tooltip] in a semantics node of its own.
///
/// A tooltip shows its message through an `OverlayPortal`, whose overlay is
/// grafted under the semantics node its anchor belongs to. A tooltip around
/// plain content — an icon, a badge, a line of text — forms no node, so two
/// of them side by side (a row's markers, a card's badges) land in one, which
/// keeps only the first anchor: hovering the second sends its overlay with no
/// parent. A button forms a node of its own already, so `IconButton.tooltip`
/// and a [Tooltip] around a button need none of this.
class StandaloneTooltip extends StatelessWidget {
  final String message;
  final Duration? waitDuration;
  final Widget child;

  const StandaloneTooltip({
    super.key,
    required this.message,
    this.waitDuration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: Tooltip(
          message: message,
          waitDuration: waitDuration,
          child: child,
        ),
      );
}

/// A [Slider] in an overlay of its own.
///
/// A slider always wraps itself in an `OverlayPortal` for its value
/// indicator, and in a pushed route or a dialog that portal's node goes out
/// with no parent the moment the route appears. Hosting the slider in its own
/// [Overlay] keeps the portal's child inside the slider's subtree; the
/// slider, its keys and its value indicator are untouched.
class SliderOverlay extends StatelessWidget {
  final Widget child;

  const SliderOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Overlay.wrap(
        alwaysSizeToContent: true,
        clipBehavior: Clip.none,
        child: child,
      );
}
