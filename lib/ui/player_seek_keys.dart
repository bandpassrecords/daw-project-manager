import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trina_grid/trina_grid.dart';

import '../utils/text_input_focus.dart';

/// Left and Right seek the desktop player bar, without the bar having to be
/// clicked first.
///
/// The usual way to get here is from the projects table — P on a row, or its
/// play button — and the table keeps the keyboard, so Up, Down and P still
/// walk the list while a song plays. Left and Right mean nothing to a table
/// whose columns all fit and whose current cell is never drawn, so they go to
/// the player.

/// How far Left or Right jumps, in seconds; null for any other key.
int? playerSeekSeconds(LogicalKeyboardKey key, {required bool longJump}) {
  final seconds = longJump ? 30 : 5;
  if (key == LogicalKeyboardKey.arrowLeft) return -seconds;
  if (key == LogicalKeyboardKey.arrowRight) return seconds;
  return null;
}

/// Whether Left/Right belong to the player bar right now.
///
/// In the bar they always do. Elsewhere only on the page the bar is part of
/// (a dialog or a pushed page has its own use for them), with focus somewhere
/// that has none, and bare: Shift+arrow selects in a table and Alt+Left goes
/// back.
///
/// Pure, so it can be tested without a keyboard.
bool playerBarTakesSeekKeys({
  required bool barHasFocus,
  required bool pageInFront,
  required bool focusHasNoUseForArrows,
  required bool shift,
  required bool alt,
}) {
  if (barHasFocus) return true;
  return pageInFront && focusHasNoUseForArrows && !shift && !alt;
}

/// Whether what holds the keyboard has no use for Left/Right: a table, or
/// nothing in particular (a scope, as after clicking a card's play button).
/// An open menu's items, a slider or a button are not that.
bool focusHasNoUseForArrows() {
  final focused = FocusManager.instance.primaryFocus;
  if (focused == null || focused is FocusScopeNode) return true;
  return focused.context?.findAncestorWidgetOfExactType<TrinaGrid>() != null;
}

/// The handler the player bar registers with
/// [FocusManager.addEarlyKeyEventHandler].
///
/// Early, because a [HardwareKeyboard] handler's answer does not stop the
/// focus tree from getting the key too: the table would move its current cell
/// on every seek, and with nothing focused Flutter's directional traversal
/// would hand the keyboard to whichever button is nearest.
OnKeyEventCallback playerSeekKeyHandler({
  required bool Function() barHasFocus,
  required bool Function() pageInFront,
  required void Function(int seconds) onSeek,
}) {
  return (event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final seconds = playerSeekSeconds(
      event.logicalKey,
      longJump: keyboard.isControlPressed || keyboard.isMetaPressed,
    );
    // Never steal keys from text inputs.
    if (seconds == null || isTextInputFocused()) return KeyEventResult.ignored;
    final takes = playerBarTakesSeekKeys(
      barHasFocus: barHasFocus(),
      pageInFront: pageInFront(),
      focusHasNoUseForArrows: focusHasNoUseForArrows(),
      shift: keyboard.isShiftPressed,
      alt: keyboard.isAltPressed,
    );
    if (!takes) return KeyEventResult.ignored;
    onSeek(seconds);
    return KeyEventResult.handled;
  };
}
