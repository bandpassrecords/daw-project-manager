import 'package:material_ui/material_ui.dart';

import '../../services/midi/input/midi_input.dart';
import 'semantics_safe.dart';

/// The MIDI input button's strings.
class MidiInputLabels {
  const MidiInputLabels({
    required this.input,
    required this.off,
    required this.all,
    required this.noDevices,
    required this.listening,
    required this.busy,
    required this.record,
    required this.stopRecording,
    required this.latency,
    required this.latencyTitle,
    required this.latencyBody,
    required this.calibrate,
    required this.calibrating,
    required this.calibrated,
    required this.done,
    required this.cancel,
  });

  /// The button's tooltip while nothing is listened to: "MIDI input".
  final String input;

  /// The menu's choices: "No MIDI input", "All MIDI inputs".
  final String off, all;

  /// In the menu when nothing is plugged in.
  final String noDevices;

  /// The tooltip while listening: "MIDI input: KeyStep".
  final String Function(String names) listening;

  /// The tooltip when the input couldn't be opened.
  final String Function(String names) busy;

  /// The record button's tooltips, before and while recording.
  final String record, stopRecording;

  /// The menu item opening the recording latency: "Recording latency: 40 ms".
  final String Function(int ms) latency;

  /// The latency dialog: its title, what it is, and its buttons.
  final String latencyTitle, latencyBody, calibrate, done, cancel;

  /// Calibrating: "Play a key on each click (3 of 8)", then what it found.
  final String Function(int done, int total) calibrating;
  final String Function(int ms) calibrated;
}

/// The piano roll's MIDI input button: lit while a keyboard is listened
/// to, red when the one chosen couldn't be opened. Its menu offers none,
/// all, or each input plugged in now — asked for each time it opens, so
/// a keyboard plugged in since shows up. Choosing the same input again
/// opens it again (after it was unplugged and plugged back in, say).
class MidiInputButton extends StatelessWidget {
  const MidiInputButton({
    super.key,
    required this.choice,
    required this.listening,
    required this.failed,
    required this.devices,
    required this.onChanged,
    required this.labels,
    this.latency,
    this.onLatency,
  });

  final MidiInputChoice choice;

  /// The recording latency, and what opens it; the menu offers it when
  /// both are given (an editor: something to record into).
  final Duration? latency;
  final VoidCallback? onLatency;

  /// The names of the inputs listened to, and of those that wouldn't open.
  final List<String> listening, failed;

  /// The inputs plugged in now.
  final Future<List<MidiInputDevice>> Function() devices;
  final ValueChanged<MidiInputChoice> onChanged;
  final MidiInputLabels labels;

  String get _tooltip {
    if (listening.isNotEmpty) return labels.listening(listening.join(', '));
    if (failed.isNotEmpty) return labels.busy(failed.join(', '));
    return labels.input;
  }

  Future<void> _showMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    // Under the button.
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(box.size.bottomLeft(Offset.zero), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final available = await devices();
    if (!context.mounted) return;
    final latency = this.latency;
    final picked = await showMenu<Object>(
      context: context,
      position: position,
      items: [
        CheckedPopupMenuItem(
          value: MidiInputChoice.off,
          checked: choice.isOff,
          child: Text(labels.off),
        ),
        CheckedPopupMenuItem(
          value: MidiInputChoice.all,
          checked: choice.isAll,
          child: Text(labels.all),
        ),
        const PopupMenuDivider(),
        if (available.isEmpty)
          PopupMenuItem(enabled: false, child: Text(labels.noDevices))
        else
          for (final device in available)
            CheckedPopupMenuItem(
              value: MidiInputChoice.named(device.name),
              checked: choice.name == device.name,
              child: Text(device.name),
            ),
        if (latency != null && onLatency != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _latencyItem,
            child: Text(labels.latency(latency.inMilliseconds)),
          ),
        ],
      ],
    );
    if (picked == _latencyItem) {
      onLatency?.call();
    } else if (picked is MidiInputChoice) {
      onChanged(picked);
    }
  }

  static const _latencyItem = Object();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: const ValueKey('midi-piano-roll-midi-input'),
      tooltip: _tooltip,
      icon: const Icon(Icons.piano),
      color: listening.isNotEmpty
          ? scheme.primary
          : failed.isNotEmpty
              ? scheme.error
              : null,
      onPressed: () => _showMenu(context),
    );
  }
}

/// What the latency dialog was closed with: the latency set, and whether
/// to measure it now.
typedef MidiLatencyChoice = ({Duration latency, bool calibrate});

/// Sets how much earlier recorded notes go in (see `recordedTick`), from
/// 0 to [kMaxRecordLatencyMs] in steps of 5 ms — or closes to calibrate,
/// which measures it.
class MidiLatencyDialog extends StatefulWidget {
  const MidiLatencyDialog({
    super.key,
    required this.latency,
    required this.labels,
    this.maxMs = 250,
  });

  final Duration latency;
  final MidiInputLabels labels;
  final int maxMs;

  @override
  State<MidiLatencyDialog> createState() => _MidiLatencyDialogState();
}

class _MidiLatencyDialogState extends State<MidiLatencyDialog> {
  late double _ms =
      widget.latency.inMilliseconds.clamp(0, widget.maxMs).toDouble();

  MidiLatencyChoice _choice({required bool calibrate}) => (
        latency: Duration(milliseconds: _ms.round()),
        calibrate: calibrate,
      );

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return AlertDialog(
      title: Text(labels.latencyTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labels.latencyBody),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SliderOverlay(
                    child: Slider(
                      key: const ValueKey('midi-latency-slider'),
                      value: _ms,
                      max: widget.maxMs.toDouble(),
                      divisions: widget.maxMs ~/ 5,
                      onChanged: (v) => setState(() => _ms = v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${_ms.round()} ms',
                    key: const ValueKey('midi-latency-value'),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_choice(calibrate: true)),
          child: Text(labels.calibrate),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_choice(calibrate: false)),
          child: Text(labels.done),
        ),
      ],
    );
  }
}
