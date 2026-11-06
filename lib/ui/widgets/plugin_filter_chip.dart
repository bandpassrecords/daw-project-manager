import 'package:material_ui/material_ui.dart';

/// The dashboard filter bar's "Uses {plug-in}" chip (#225), shown while
/// "Show these projects" in the Inspector's plug-in usage narrows the list.
/// Its × clears the filter — and says so, since the list it leaves behind
/// doesn't look filtered otherwise.
class PluginFilterChip extends StatelessWidget {
  final String label;
  final String clearTooltip;
  final VoidCallback onClear;

  const PluginFilterChip({
    super.key,
    required this.label,
    required this.clearTooltip,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputChip(
      avatar: Icon(Icons.extension, size: 16, color: cs.onSecondaryContainer),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: cs.onSecondaryContainer),
      ),
      backgroundColor: cs.secondaryContainer,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      deleteIconColor: cs.onSecondaryContainer,
      deleteButtonTooltipMessage: clearTooltip,
      // A tap on the chip itself clears it too: it is the one thing on the
      // bar that hides projects without a control saying so.
      onPressed: onClear,
      onDeleted: onClear,
    );
  }
}
