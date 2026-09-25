import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../../utils/section_rail_width.dart';

/// One entry in a [SectionNavRail].
class SectionNavItem {
  final IconData icon;
  final String label;

  /// Draws a divider in the rail immediately above this item, so a flat list
  /// reads as a few loose categories without needing headers.
  final bool newGroup;

  const SectionNavItem({
    required this.icon,
    required this.label,
    this.newGroup = false,
  });
}

/// The left rail that picks which section of a page is showing.
///
/// Lifted out of the settings page so the project detail page can use the
/// same one rather than growing a second, subtly different copy — the two
/// pages solve the same problem (a long page with no way to jump around it)
/// and should not drift apart visually.
///
/// [searchController] is optional: the settings page flips its content pane
/// into cross-section search results, and pages with nothing to search simply
/// leave it out and get a rail with no search box.
class SectionNavRail extends StatelessWidget {
  final List<SectionNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final TextEditingController? searchController;
  final String? searchHint;

  const SectionNavRail({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTap,
    this.searchController,
    this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = searchController;
    // While a search is running nothing in the rail is "the current section":
    // the pane is showing results from all of them.
    final searching = controller != null && controller.text.trim().isNotEmpty;

    return Material(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          if (controller != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searching
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: controller.clear,
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = !searching && index == activeIndex;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (item.newGroup)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Divider(height: 1),
                      ),
                    InkWell(
                      onTap: () => onTap(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primaryContainer.withValues(alpha: 0.4)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color:
                                  selected ? cs.primary : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RailLabel(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color:
                                      selected ? cs.primary : cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A rail label kept to one line. A long translation is cut with an ellipsis
/// instead of wrapping (which made rows uneven heights), and only a label that
/// was actually cut gets a tooltip with the full text — a tooltip on every row
/// would pop up over labels that are already fully visible.
class _RailLabel extends StatelessWidget {
  const _RailLabel(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final label = Text(
        text,
        style: style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final truncated = painter.didExceedMaxLines;
      painter.dispose();
      return truncated ? Tooltip(message: text, child: label) : label;
    });
  }
}

/// A [SectionNavRail] (or any rail) beside its content, with a handle on the
/// divider between them that the user drags to resize the rail.
///
/// Plain values and callbacks — the page owns the width (see
/// `sectionRailWidthProvider`), this only draws it and reports drags:
/// [onResize] follows the pointer, [onResizeEnd] is where the page saves, and
/// double-clicking the handle calls [onReset]. The width always goes through
/// [clampSectionRailWidth] against the space actually available, so a width
/// saved on a large window still leaves room for the content.
class ResizableRailLayout extends StatefulWidget {
  const ResizableRailLayout({
    super.key,
    required this.rail,
    required this.child,
    required this.width,
    required this.defaultWidth,
    required this.onResize,
    required this.onResizeEnd,
    required this.onReset,
    this.handleTooltip,
  });

  final Widget rail;
  final Widget child;

  /// The width the user chose, or null to use [defaultWidth].
  final double? width;
  final double defaultWidth;
  final ValueChanged<double> onResize;
  final VoidCallback onResizeEnd;
  final VoidCallback onReset;
  final String? handleTooltip;

  /// How wide the grab area is. The visible divider inside it stays 1px.
  static const double handleWidth = 7;

  @override
  State<ResizableRailLayout> createState() => _ResizableRailLayoutState();
}

class _ResizableRailLayoutState extends State<ResizableRailLayout> {
  bool _hovering = false;
  bool _dragging = false;

  /// The unclamped width under the pointer. Tracked apart from the clamped
  /// width so that dragging past a limit and back does not leave the divider
  /// out of step with the pointer.
  double _dragWidth = 0;

  void _endDrag() {
    setState(() => _dragging = false);
    widget.onResizeEnd();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth;
      final width = clampSectionRailWidth(
        widget.width ?? widget.defaultWidth,
        available: available,
      );
      final active = _hovering || _dragging;

      Widget handle = MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Measure from where the pointer went down, not from where the
          // drag was recognised, so the divider stays under the pointer.
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: (_) => setState(() {
            _dragging = true;
            _dragWidth = width;
          }),
          onHorizontalDragUpdate: (details) {
            _dragWidth += details.delta.dx;
            widget.onResize(
              clampSectionRailWidth(_dragWidth, available: available),
            );
          },
          onHorizontalDragEnd: (_) => _endDrag(),
          onHorizontalDragCancel: _endDrag,
          onDoubleTap: widget.onReset,
          child: SizedBox(
            width: ResizableRailLayout.handleWidth,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: active ? 3 : 1,
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

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: width, child: widget.rail),
          handle,
          Expanded(child: widget.child),
        ],
      );
    });
  }
}
