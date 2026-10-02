import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'ctrl_wheel_volume.dart';

/// Strings for [MidiVolumeControl], resolved by the caller.
class MidiVolumeLabels {
  const MidiVolumeLabels({
    required this.volume,
    required this.mute,
    required this.unmute,
  });

  final String volume;
  final String mute;
  final String unmute;
}

/// The MIDI preview volume: a speaker that mutes and unmutes, and a slider —
/// Ctrl/⌘+wheel over either rides it, the same as the main player bar.
///
/// A plain view: the caller owns the value (see `midiPreviewVolumeProvider`)
/// and applies it to the player.
class MidiVolumeControl extends StatefulWidget {
  const MidiVolumeControl({
    super.key,
    required this.volume,
    required this.onChanged,
    required this.labels,
    this.sliderWidth = 110,
  });

  final double volume;
  final ValueChanged<double> onChanged;
  final MidiVolumeLabels labels;
  final double sliderWidth;

  @override
  State<MidiVolumeControl> createState() => _MidiVolumeControlState();
}

class _MidiVolumeControlState extends State<MidiVolumeControl> {
  /// What unmuting goes back to: the level before the last mute.
  double _beforeMute = 1;

  void _toggleMute() {
    if (widget.volume > 0) {
      _beforeMute = widget.volume;
      widget.onChanged(0);
    } else {
      widget.onChanged(_beforeMute > 0 ? _beforeMute : 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = widget.volume <= 0;
    final icon = muted
        ? Icons.volume_off
        : widget.volume < 0.5
            ? Icons.volume_down
            : Icons.volume_up;
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent && isVolumeScrollModifierHeld()) {
          widget.onChanged(volumeAfterScroll(widget.volume, e.scrollDelta.dy));
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: muted ? widget.labels.unmute : widget.labels.mute,
            visualDensity: VisualDensity.compact,
            icon: Icon(icon, size: 20),
            onPressed: _toggleMute,
          ),
          SizedBox(
            width: widget.sliderWidth,
            child: Slider(
              value: widget.volume.clamp(0.0, 1.0),
              label: widget.labels.volume,
              semanticFormatterCallback: (v) =>
                  '${widget.labels.volume} ${(v * 100).round()}%',
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
