import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/custom_theme.dart';

/// A miniature of the projects table painted in [spec]'s colors.
///
/// Every color comes off the spec — the onboarding wizard used to hardcode
/// each built-in's swatches as literals, which meant the preview and the
/// theme could drift apart and user themes had nothing to show at all.
class ThemePreviewMockup extends StatelessWidget {
  final CustomTheme spec;

  const ThemePreviewMockup({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = spec.resolvedOnSurface;
    final dimText = spec.resolvedTextTertiary;
    final accent = spec.secondary ?? spec.primary;

    final rows = [
      ('Song Alpha', 'In Progress', '120'),
      ('Dark Ambient', 'Done', '90'),
      ('Remix Final', 'In Progress', '128'),
    ];

    // Height is deliberately left to the content: pinning it clips the last
    // fake row at some text scales and overflows the Column at others.
    return Container(
      color: spec.background,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fake sidebar + header bar
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: spec.card,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: spec.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 40,
                  height: 5,
                  color: textColor.withValues(alpha: 0.3),
                ),
                const Spacer(),
                Container(
                  width: 24,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                _previewText(l10n.name, dimText, flex: 3),
                _previewText(l10n.status, dimText, flex: 2),
                _previewText(l10n.bpm, dimText, flex: 1),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // Fake project rows
          ...rows.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: spec.card,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      // "Done" keeps its semantic green in every theme, the
                      // same way phase colors are theme-independent.
                      color: r.$2 == 'Done'
                          ? Colors.greenAccent.shade400
                          : spec.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _previewText(r.$1, textColor, flex: 3),
                  _previewText(r.$2, dimText, flex: 2),
                  _previewText(r.$3, dimText, flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewText(String text, Color color, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// A selectable theme tile: preview on top, name and radio below, with an
/// optional trailing action (the "…" menu on user themes).
class ThemeChoiceCard extends StatelessWidget {
  final CustomTheme spec;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final double width;

  const ThemeChoiceCard({
    super.key,
    required this.spec,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.width = 180,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: ThemePreviewMockup(spec: spec),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 4),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color: selected ? cs.primary : cs.outline,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: selected ? cs.primary : null,
                                  ),
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
