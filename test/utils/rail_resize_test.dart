import 'package:daw_project_manager/utils/rail_resize.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an open rail shows the resize cursor', () {
    expect(
      railResizeCursor(collapsed: false),
      SystemMouseCursors.resizeColumn,
    );
  });

  test('a collapsed rail shows none, since its handle cannot be dragged', () {
    expect(railResizeCursor(collapsed: true), MouseCursor.defer);
  });
}
