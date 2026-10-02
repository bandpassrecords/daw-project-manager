import 'package:flutter/material.dart';

/// Tempos the preview accepts. Below 20 a bar lasts longer than most
/// previews; above 400 notes smear into each other.
const double kMinPreviewBpm = 20;
const double kMaxPreviewBpm = 400;

/// Reads a typed tempo: "145", "128.5", or "128,5" with a decimal comma.
/// Null for anything that isn't a number in [kMinPreviewBpm, kMaxPreviewBpm].
double? parsePreviewBpm(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite) return null;
  if (value < kMinPreviewBpm || value > kMaxPreviewBpm) return null;
  return value;
}

/// "145" for whole tempos, "128.5" / "99.75" otherwise.
String formatPreviewBpm(double bpm) {
  if (bpm == bpm.roundToDouble()) return bpm.round().toString();
  return bpm
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Localized strings for [MidiTempoControl], resolved by the page.
class MidiTempoLabels {
  const MidiTempoLabels({
    required this.unit,
    required this.tooltip,
    required this.slower,
    required this.faster,
    this.auto = '',
  });

  /// "BPM".
  final String unit;
  final String tooltip;
  final String slower;
  final String faster;

  /// Placeholder shown while no tempo is set (see [MidiTempoControl.bpm]).
  final String auto;
}

/// The tempo MIDI clips are previewed and saved at: a small BPM field with
/// −/+ nudges and, when the page offers one, a reset.
///
/// A plain view: the page owns the value and decides what a change or a
/// reset means — back to the project's tempo on a project page, back to
/// "each clip at its own project's tempo" in the library.
class MidiTempoControl extends StatefulWidget {
  const MidiTempoControl({
    super.key,
    required this.bpm,
    required this.onChanged,
    required this.labels,
    this.onReset,
    this.resetTooltip,
    this.nudgeFrom = 120,
  });

  /// The tempo in effect, or null for "automatic": the field then shows
  /// [MidiTempoLabels.auto], and a nudge starts from [nudgeFrom].
  final double? bpm;
  final ValueChanged<double> onChanged;
  final MidiTempoLabels labels;

  /// Shown as a reset button when non-null.
  final VoidCallback? onReset;
  final String? resetTooltip;
  final double nudgeFrom;

  @override
  State<MidiTempoControl> createState() => _MidiTempoControlState();
}

class _MidiTempoControlState extends State<MidiTempoControl> {
  late final TextEditingController _controller =
      TextEditingController(text: _text(widget.bpm));
  final FocusNode _focus = FocusNode();

  /// What the field last reported, so Enter followed by the focus leaving
  /// doesn't report the same entry twice.
  double? _lastSent;

  static String _text(double? bpm) => bpm == null ? '' : formatPreviewBpm(bpm);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(MidiTempoControl old) {
    super.didUpdateWidget(old);
    // Follow outside changes (nudges, reset) unless the user is mid-edit.
    if (old.bpm != widget.bpm) {
      _lastSent = null;
      if (!_focus.hasFocus) _controller.text = _text(widget.bpm);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final value = parsePreviewBpm(_controller.text);
    if (value == null) {
      // Not a usable tempo (or emptied): put back the one in effect rather
      // than guessing.
      _controller.text = _text(widget.bpm);
      return;
    }
    _controller.text = formatPreviewBpm(value);
    if (value != widget.bpm && value != _lastSent) {
      _lastSent = value;
      widget.onChanged(value);
    }
  }

  void _nudge(double delta) {
    final from = widget.bpm ?? widget.nudgeFrom;
    final next = (from + delta).clamp(kMinPreviewBpm, kMaxPreviewBpm).toDouble();
    if (next != widget.bpm) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = widget.labels;
    final current = widget.bpm ?? widget.nudgeFrom;

    // One tooltip per control, never one around the row: a tooltip wrapping
    // the buttons' own tooltips nests overlay entries.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Tooltip(
          message: labels.tooltip,
          child: Icon(
            Icons.speed,
            size: 18,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: labels.slower,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove, size: 18),
          onPressed: current > kMinPreviewBpm ? () => _nudge(-1) : null,
        ),
        SizedBox(
          width: 64,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              hintText: labels.auto,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            ),
            onSubmitted: (_) => _commit(),
          ),
        ),
        IconButton(
          tooltip: labels.faster,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add, size: 18),
          onPressed: current < kMaxPreviewBpm ? () => _nudge(1) : null,
        ),
        Text(labels.unit, style: theme.textTheme.bodySmall),
        if (widget.onReset != null)
          IconButton(
            tooltip: widget.resetTooltip,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.restart_alt, size: 18),
            onPressed: widget.onReset,
          ),
      ],
    );
  }
}
