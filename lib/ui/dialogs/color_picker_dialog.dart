import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/phase_colors.dart';
import '../widgets/color_wheel.dart';

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

/// Color picker offering three ways in: the preset swatches, a full HSV
/// wheel, and a hex field. All three stay in sync — dragging the wheel
/// rewrites the hex, and typing a hex moves the wheel thumb.
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
  late HSVColor _hsv = HSVColor.fromColor(widget.currentColor);
  late final TextEditingController _hexController =
      TextEditingController(text: colorToHex(widget.currentColor));
  String? _error;

  Color get _color => _hsv.toColor();

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  /// Moves the wheel, and rewrites the hex field to match.
  ///
  /// Keeps [HSVColor] rather than round-tripping through [Color]: hue and
  /// saturation are undefined for black and greys, so a round trip would
  /// snap the thumb back to the centre mid-drag.
  void _setFromWheel(HSVColor next) {
    final hex = colorToHex(next.toColor());
    setState(() {
      _hsv = next;
      _error = null;
      _hexController.value = TextEditingValue(
        text: hex,
        selection: TextSelection.collapsed(offset: hex.length),
      );
    });
  }

  /// Reacts to typing in the hex field. Deliberately does *not* rewrite the
  /// field — doing so would fight the cursor on every keystroke.
  void _setFromHexField(String text) {
    final parsed = parseHexColor(text);
    setState(() {
      _error = null;
      if (parsed != null) _hsv = HSVColor.fromColor(parsed);
    });
  }

  void _confirmHex() {
    final parsed = parseHexColor(_hexController.text);
    if (parsed == null) {
      setState(() => _error = AppLocalizations.of(context)!.themeHexInvalid);
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
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preset swatches. Tapping one picks it outright — this is the
              // fast path, and the one the phase picker has always had.
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.palette.map((color) {
                  final isSelected =
                      color.toARGB32() == _color.toARGB32();
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
              const Divider(height: 1),
              const SizedBox(height: 16),
              // A 16-swatch palette is far too coarse for a whole theme, so
              // any color is reachable by wheel or by hex.
              Center(
                child: ColorWheel(
                  color: _hsv,
                  onChanged: _setFromWheel,
                ),
              ),
              ColorValueSlider(color: _hsv, onChanged: _setFromWheel),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Live preview of whatever the wheel and hex currently
                  // agree on.
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      autocorrect: false,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(7),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.themeHexLabel,
                        hintText: '#1E1F22',
                        errorText: _error,
                        isDense: true,
                      ),
                      onChanged: _setFromHexField,
                      onSubmitted: (_) => _confirmHex(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _confirmHex, child: Text(l10n.apply)),
      ],
    );
  }
}
