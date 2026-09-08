import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/custom_theme.dart';
import '../../providers/theme_provider.dart';
import '../../utils/color_contrast.dart';
import '../../utils/phase_colors.dart';
import '../widgets/theme_preview_card.dart';
import 'color_picker_dialog.dart';

/// Neutral backgrounds worth starting from. The phase palette is all
/// saturated mid-tones — fine for an accent, useless for a window
/// background — so the two surface rows get their own swatches.
const List<Color> kThemeSurfacePalette = [
  Color(0xFF0A0A14),
  Color(0xFF0F1014),
  Color(0xFF14161A),
  Color(0xFF1A1A2E),
  Color(0xFF1E1F22),
  Color(0xFF232529),
  Color(0xFF2B2D31),
  Color(0xFF33363C),
  Color(0xFF101A16),
  Color(0xFF1A1220),
  Color(0xFF201A12),
  Color(0xFF101A24),
];

/// Opens the theme editor on [draft] and returns the edited theme, or null if
/// the user cancelled.
Future<CustomTheme?> showThemeEditorDialog(
  BuildContext context, {
  required CustomTheme draft,
  required bool isNew,
}) {
  return showDialog<CustomTheme>(
    context: context,
    builder: (_) => ThemeEditorDialog(draft: draft, isNew: isNew),
  );
}

class ThemeEditorDialog extends StatefulWidget {
  final CustomTheme draft;
  final bool isNew;

  const ThemeEditorDialog({
    super.key,
    required this.draft,
    required this.isNew,
  });

  @override
  State<ThemeEditorDialog> createState() => _ThemeEditorDialogState();
}

class _ThemeEditorDialogState extends State<ThemeEditorDialog> {
  late CustomTheme _draft = widget.draft;
  late final TextEditingController _nameController =
      TextEditingController(text: widget.draft.name ?? '');
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pick(
    String title,
    Color current,
    List<Color> palette,
    CustomTheme Function(Color) apply,
  ) async {
    final picked = await showAppColorPicker(
      context,
      title: title,
      current: current,
      palette: palette,
    );
    if (picked != null) setState(() => _draft = apply(picked));
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.themeNameRequired);
      return;
    }
    Navigator.pop(context, _draft.copyWith(name: name));
  }

  /// Contrast problems worth warning about, as `"4.2"`-style ratio strings.
  ///
  /// A warning, never a block: an unreadable theme is the user's call to
  /// make, but it shouldn't happen by accident.
  List<String> get _contrastWarnings {
    final warnings = <String>[];
    final bodyOnCard =
        contrastRatio(_draft.resolvedOnSurface, _draft.card);
    if (bodyOnCard < 4.5) warnings.add(bodyOnCard.toStringAsFixed(1));
    final accentOnBackground =
        contrastRatio(_draft.primary, _draft.background);
    if (accentOnBackground < 3.0) {
      warnings.add(accentOnBackground.toStringAsFixed(1));
    }
    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final warnings = _contrastWarnings;

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          autofocus: widget.isNew,
          decoration: InputDecoration(
            labelText: l10n.themeNameLabel,
            hintText: l10n.themeNameHint,
            errorText: _nameError,
            isDense: true,
          ),
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: 16),
        _ColorRow(
          label: l10n.themeColorAccent,
          color: _draft.primary,
          onTap: () => _pick(
            l10n.themeColorAccent,
            _draft.primary,
            kPhaseColorPalette,
            (c) => _draft.copyWith(primary: c),
          ),
        ),
        _ColorRow(
          label: l10n.themeColorSecondaryAccent,
          color: _draft.secondary ?? _draft.primary,
          onTap: () => _pick(
            l10n.themeColorSecondaryAccent,
            _draft.secondary ?? _draft.primary,
            kPhaseColorPalette,
            (c) => _draft.copyWith(secondary: c),
          ),
        ),
        _ColorRow(
          label: l10n.themeColorBackground,
          color: _draft.background,
          onTap: () => _pick(
            l10n.themeColorBackground,
            _draft.background,
            kThemeSurfacePalette,
            (c) => _draft.copyWith(background: c),
          ),
        ),
        _ColorRow(
          label: l10n.themeColorCards,
          color: _draft.card,
          onTap: () => _pick(
            l10n.themeColorCards,
            _draft.card,
            kThemeSurfacePalette,
            (c) => _draft.copyWith(card: c),
          ),
        ),
        const SizedBox(height: 8),
        _RadiusSlider(
          label: l10n.themeCardRoundness,
          value: _draft.cardRadius,
          onChanged: (v) => setState(() => _draft = _draft.copyWith(cardRadius: v)),
        ),
        _RadiusSlider(
          label: l10n.themeButtonRoundness,
          value: _draft.controlRadius,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(controlRadius: v)),
        ),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final ratio in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.orange.shade400,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.themeLowContrastWarning(ratio),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );

    final preview = _LivePreview(spec: _draft);

    return AlertDialog(
      title: Text(widget.isNew ? l10n.newTheme : l10n.editTheme),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Side by side when there's room; stacked on a narrow window
              // or a phone.
              if (constraints.maxWidth < 520) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [fields, const SizedBox(height: 20), preview],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: fields),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: preview),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

/// A label, a swatch and the hex value, tappable to open the color picker.
class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorRow({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              colorToHex(color),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadiusSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _RadiusSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value.round().toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, 24),
          min: 0,
          max: 24,
          divisions: 24,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// The draft rendered for real: the mockup plus live Material widgets built
/// from the draft's own [ThemeData], so a bad button/text pairing shows up
/// here rather than after saving.
class _LivePreview extends StatelessWidget {
  final CustomTheme spec;

  const _LivePreview({required this.spec});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeData = AppThemes.buildFrom(spec);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ThemePreviewMockup(spec: spec),
        ),
        const SizedBox(height: 12),
        Theme(
          data: themeData,
          child: Builder(
            builder: (themedContext) => Container(
              color: themeData.scaffoldBackgroundColor,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.themeNameLabel,
                            style:
                                Theme.of(themedContext).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.themeSettingDescription,
                            style: Theme.of(themedContext).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                child: Text(l10n.save),
                              ),
                              OutlinedButton(
                                onPressed: () {},
                                child: Text(l10n.cancel),
                              ),
                              Chip(label: Text(l10n.bpm)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
