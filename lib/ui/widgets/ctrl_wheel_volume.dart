import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// How much one wheel notch moves the volume. A notch is 100 scroll units on
/// every desktop platform Flutter reports, so this is one twentieth of the
/// range per click — twenty clicks end to end, which is fine-grained enough to
/// ride a level without being tedious.
const double kCtrlWheelVolumeStep = 0.05;

/// The volume [current] becomes after a wheel scroll of [scrollDelta].
///
/// [scrollDelta] is `PointerScrollEvent.scrollDelta.dy`, which is **negative
/// when scrolling up** — up raises the volume, so the delta is subtracted.
/// The result is always clamped to 0…1, so holding the wheel at either end
/// parks there instead of drifting out of range.
double volumeAfterScroll(
  double current,
  double scrollDelta, {
  double step = kCtrlWheelVolumeStep,
}) {
  if (scrollDelta == 0) return current.clamp(0.0, 1.0);
  final notches = scrollDelta / 100.0;
  return (current - notches * step).clamp(0.0, 1.0);
}

/// Whether a ctrl/cmd-modified wheel event should be read as a volume change.
///
/// Ctrl on Windows/Linux, and ⌘ on macOS as well, matching how the rest of the
/// app treats the two as one "the platform's modifier" (see
/// `row_click_selection.dart`). Plain scrolling is left alone so a wheel over
/// a player still scrolls the page it sits in.
bool isVolumeScrollModifierHeld() {
  final keys = HardwareKeyboard.instance.logicalKeysPressed;
  return keys.contains(LogicalKeyboardKey.controlLeft) ||
      keys.contains(LogicalKeyboardKey.controlRight) ||
      keys.contains(LogicalKeyboardKey.metaLeft) ||
      keys.contains(LogicalKeyboardKey.metaRight);
}

/// Wraps a player's UI so ctrl+wheel anywhere over it nudges the volume.
///
/// [volume] is the player's current level and [onVolumeChanged] is handed the
/// new one — this widget stores nothing itself, so the slider, the mute
/// button and the wheel all read and write the same single source of truth in
/// the player's own state.
///
/// Uses a [Listener] rather than a [GestureDetector]: pointer signals are not
/// gestures, and a Listener sees them without entering the arena, so it never
/// competes with the sliders and buttons inside [child].
class CtrlWheelVolume extends StatelessWidget {
  const CtrlWheelVolume({
    super.key,
    required this.volume,
    required this.onVolumeChanged,
    required this.child,
    this.enabled = true,
  });

  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final Widget child;

  /// Set false on mobile, where there is no wheel and no ctrl key.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Listener(
      // Translucent, not the default deferToChild: a player is mostly gaps
      // between controls, and those gaps don't hit-test on their own — the
      // wheel has to work over the whole bar, not just where a button
      // happens to be. Translucent rather than opaque so nothing painted
      // behind the player stops receiving pointers.
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        if (!isVolumeScrollModifierHeld()) return;
        // Claimed through the resolver rather than handled directly: a
        // Listener sees the event but does not stop an enclosing scroll
        // view acting on it too, so on a scrolling page (the project page,
        // the release page) ctrl+wheel changed the volume *and* scrolled
        // the player out from under the cursor. The first registrant wins,
        // and this sits deeper in the tree than any scroll view around it,
        // so it registers first. Plain scrolling is never claimed.
        GestureBinding.instance.pointerSignalResolver.register(event, (e) {
          final scroll = e as PointerScrollEvent;
          final next = volumeAfterScroll(volume, scroll.scrollDelta.dy);
          if (next != volume) onVolumeChanged(next);
        });
      },
      child: child,
    );
  }
}
