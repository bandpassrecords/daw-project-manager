import 'package:flutter/material.dart';

/// The repeat button next to a MIDI preview's volume: lit while previews
/// loop. One setting for every preview, so every copy of this button shows
/// the same state.
class MidiLoopToggle extends StatelessWidget {
  const MidiLoopToggle({
    super.key,
    required this.loop,
    required this.onChanged,
    required this.tooltip,
  });

  final bool loop;
  final ValueChanged<bool> onChanged;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        isSelected: loop,
        icon: const Icon(Icons.repeat),
        selectedIcon: const Icon(Icons.repeat_on),
        onPressed: () => onChanged(!loop),
      );
}
