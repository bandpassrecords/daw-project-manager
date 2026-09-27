import 'package:flutter/services.dart';

/// Keyboard shortcuts shared by every player in the app, so the preview
/// dialog, the desktop bar, the project page and the release rows answer the
/// same keys the same way.

/// Whether [key], pressed with these modifiers, means "toggle mono".
///
/// Bare M only (Shift is tolerated, since it changes nothing about the
/// logical key). Ctrl, ⌘ and Alt combinations are left alone: ⌘M minimises
/// the window on macOS, and a player that swallowed it would break a system
/// shortcut the user reaches for without thinking.
///
/// Pure, so it can be tested without a keyboard.
bool isMonoShortcut(
  LogicalKeyboardKey key, {
  required bool control,
  required bool meta,
  required bool alt,
}) =>
    key == LogicalKeyboardKey.keyM && !control && !meta && !alt;

/// [isMonoShortcut] against the live keyboard state, for use inside a key
/// handler.
bool isMonoShortcutEvent(KeyEvent event) {
  final keyboard = HardwareKeyboard.instance;
  return isMonoShortcut(
    event.logicalKey,
    control: keyboard.isControlPressed,
    meta: keyboard.isMetaPressed,
    alt: keyboard.isAltPressed,
  );
}
