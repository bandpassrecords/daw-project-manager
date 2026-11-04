import 'package:flutter/services.dart';

/// The pointer over the left rail's drag handle.
///
/// Only a rail that can be resized shows the resize cursor: collapsed, the
/// handle does nothing, and a cursor promising a drag that never comes is
/// worse than none. `defer` leaves the choice to whatever is underneath.
MouseCursor railResizeCursor({required bool collapsed}) =>
    collapsed ? MouseCursor.defer : SystemMouseCursors.resizeColumn;
