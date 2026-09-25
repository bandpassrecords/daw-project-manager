import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/player_shortcuts.dart';

void main() {
  group('isMonoShortcut', () {
    bool mono(
      LogicalKeyboardKey key, {
      bool control = false,
      bool meta = false,
      bool alt = false,
    }) =>
        isMonoShortcut(key, control: control, meta: meta, alt: alt);

    test('bare M toggles mono', () {
      expect(mono(LogicalKeyboardKey.keyM), isTrue);
    });

    test('other keys do not', () {
      expect(mono(LogicalKeyboardKey.keyN), isFalse);
      expect(mono(LogicalKeyboardKey.space), isFalse);
    });

    test('⌘M is left to the system', () {
      // ⌘M minimises the window on macOS; a player that swallowed it would
      // break a shortcut people press without thinking.
      expect(mono(LogicalKeyboardKey.keyM, meta: true), isFalse);
    });

    test('Ctrl+M and Alt+M are left alone', () {
      expect(mono(LogicalKeyboardKey.keyM, control: true), isFalse);
      expect(mono(LogicalKeyboardKey.keyM, alt: true), isFalse);
    });
  });
}
