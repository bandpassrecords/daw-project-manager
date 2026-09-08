import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/phase_colors.dart';

/// Parses `#RRGGBB`, `RRGGBB`, `#RGB` or `RGB` into a color.
///
/// Returns null for anything else rather than throwing — this is fed straight
/// from a text field the user is still typing into.
Color? parseHexColor(String input) {
  var hex = input.trim().replaceFirst('#', '').toUpperCase();
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length != 6 || !RegExp(r'^[0-9A-F]{6}$').hasMatch(hex)) return null;
  return Color(int.parse('FF$hex', radix: 16));
}

/// Swatch-plus-hex color picker.
///
/// Returns the chosen color, or null if dismissed. [palette] defaults to the
/// phase color palette; the theme editor passes its own sets, because the
/// hues that suit a project phase are not the ones that suit a window
/// background.
Future<Color?> showAppColorPicker(
  BuildContext context, {
  required String title,
  required Color current,
  List<Color>? palette,
}) {
  return showDialog<Color>(
    context: context,
    builder: (ctx) => AppColorPickerDialog(
      title: title,
      currentColor: current,
      palette: palette ?? kPhaseColorPalette,
    ),
  );
}

class AppColorPickerDialog extends StatefulWidget {
  final String title;
  final Color currentColor;
  final List<Color> palette;

  const AppColorPickerDialog({
    super.key,
    required this.title,
    required this.currentColor,
    required this.palette,
  });

  @override
  State<AppColorPickerDialog> createState() => _AppColorPickerDialogState();
}

class _AppColorPickerDialogState extends State<AppColorPickerDialog> {
  late final TextEditingController _hexController =
      TextEditingController(text: colorToHex(widget.currentColor));
  String? _error;

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _applyHex() {
    final l10n = AppLocalizations.of(context)!;
    final parsed = parseHexColor(_hexController.text);
    if (parsed == null) {
      setState(() => _error = l10n.themeHexInvalid);
      return;
    }
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.palette.map((color) {
                final isSelected =
                    color.toARGB32() == widget.currentColor.toARGB32();
                return GestureDetector(
                  onTap: () => Navigator.pop(context, color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: ThemeData.estimateBrightnessForColor(
                                        color) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // A 16-swatch palette is fine for phases but far too narrow for a
            // whole theme, so any color is reachable by hex.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    autocorrect: false,
                    inputFormatters: [LengthLimitingTextInputFormatter(7)],
                    decoration: InputDecoration(
                      labelText: l10n.themeHexLabel,
                      hintText: '#1E1F22',
                      errorText: _error,
                      isDense: true,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _applyHex(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _applyHex,
                  child: Text(l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
