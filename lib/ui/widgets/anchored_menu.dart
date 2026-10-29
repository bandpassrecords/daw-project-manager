import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Opens a [MenuAnchor] menu at [position] (global coordinates) and
/// completes with the value of the item chosen, or null when the menu closes
/// without one (a click outside, Esc).
///
/// `showMenu` draws one flat list. This is MenuAnchor's menu instead —
/// submenus that open on hover, arrow-key navigation, and the M3 open
/// animation Flutter 3.44 added — for callers that only have a point to open
/// it at, like a right-click on a grid row. [builder] gets the function an
/// item calls with its value.
Future<T?> showAnchoredMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<Widget> Function(void Function(T value) choose) builder,
  MenuStyle? style,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final box = overlay.context.findRenderObject()! as RenderBox;
  final at = box.globalToLocal(position);
  final controller = MenuController();
  final done = Completer<T?>();
  T? chosen;
  late final OverlayEntry entry;

  void finish() {
    if (done.isCompleted) return;
    entry.remove();
    done.complete(chosen);
  }

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: at.dx,
      top: at.dy,
      child: MenuAnchor(
        controller: controller,
        animated: true,
        style: style,
        // An item closes the menu before its onPressed runs; finishing a
        // frame later lets that onPressed record the choice first.
        onClose: () =>
            WidgetsBinding.instance.addPostFrameCallback((_) => finish()),
        menuChildren: builder((value) => chosen = value),
        // The menu's semantics hang under its anchor's node, and an anchor of
        // no size forms none: the menu would go to the engine with no parent,
        // which Windows' accessibility bridge rejects (see semantics_safe.dart).
        // One pixel, in a node of its own, is enough to hold it.
        child: Semantics(
          container: true,
          child: const SizedBox(width: 1, height: 1),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.open());
  return done.future;
}
