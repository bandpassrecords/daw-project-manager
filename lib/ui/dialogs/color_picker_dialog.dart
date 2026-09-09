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

/// Color picker offering three ways in: the preset swatches, a full HSL
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
  late HSLColor _hsl = HSLColor.fromColor(widget.currentColor);
  late final TextEditingController _hexController =
      TextEditingController(text: colorToHex(widget.currentColor));
  String? _error;

  Color get _color => _hsl.toColor();

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  /// Moves the wheel, and rewrites the hex field to match.
  ///
  /// Keeps [HSLColor] rather than round-tripping through [Color]: hue and
  /// saturation are undefined for black and white, so a round trip would
  /// snap the thumb back to the centre mid-drag.
  void _setFromWheel(HSLColor next) {
    final hex = colorToHex(next.toColor());
    setState(() {
      _hsl = next;
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
      if (parsed != null) _hsl = HSLColor.fromColor(parsed);
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
              Text(
                l10n.suggestedColorsLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
              const SizedBox(height: 8),
              // Preset swatches. Tapping one loads it into the wheel and the
              // hex field rather than picking it outright, so a preset can be
              // used as a starting point and nudged — the swatch, the wheel
              // and the hex are all just ways of editing the same pending
              // color, and only Apply commits it.
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in widget.palette)
                    _PresetSwatch(
                      color: color,
                      isSelected: color.toARGB32() == _color.toARGB32(),
                      onTap: () => _setFromWheel(HSLColor.fromColor(color)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // A 16-swatch palette is far too coarse for a whole theme, so
              // any color is reachable by wheel or by hex.
              Center(
                child: ColorWheel(
                  color: _hsl,
                  onChanged: _setFromWheel,
                ),
              ),
              // Breathing room below the wheel — without it the slider's
              // gradient bar sits flush against the disc's bottom edge.
              const SizedBox(height: 20),
              ColorLightnessSlider(color: _hsl, onChanged: _setFromWheel),
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

/// One preset swatch.
///
/// Stateful only to track hover: on desktop a bare colored circle gives no
/// hint that it does anything, so it lifts and grows a ring under the
/// pointer, takes the click cursor, and shows its hex in a tooltip.
class _PresetSwatch extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PresetSwatch> createState() => _PresetSwatchState();
}

class _PresetSwatchState extends State<_PresetSwatch> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final tickColor =
        ThemeData.estimateBrightnessForColor(widget.color) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Tooltip(
      message: colorToHex(widget.color),
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hovered ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected
                      ? onSurface
                      : _hovered
                          ? onSurface.withValues(alpha: 0.5)
                          : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: widget.isSelected || _hovered
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.5),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
              child: widget.isSelected
                  ? Icon(Icons.check, size: 18, color: tickColor)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
