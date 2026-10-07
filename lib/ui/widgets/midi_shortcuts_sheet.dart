import 'package:flutter/material.dart';

/// One line of the piano roll's shortcut sheet: what to press or do, and
/// what it does.
class MidiShortcut {
  const MidiShortcut(this.keys, this.action);

  /// Pressed or done together, drawn as keycaps joined by "+": "Ctrl",
  /// "Drag".
  final List<String> keys;
  final String action;
}

/// A titled group of [MidiShortcut]s: tools, notes, selecting…
class MidiShortcutSection {
  const MidiShortcutSection(this.title, this.shortcuts);

  final String title;
  final List<MidiShortcut> shortcuts;
}

/// Every shortcut and gesture of the piano roll on one sheet, opened when
/// wanted (its button, `?` or F1) — rather than a hint popping up while
/// editing.
///
/// Takes resolved strings only, like the piano roll itself, so it can be
/// tested without localizations.
class MidiShortcutsSheet extends StatelessWidget {
  const MidiShortcutsSheet({
    super.key,
    required this.title,
    required this.sections,
    required this.close,
  });

  final String title;
  final List<MidiShortcutSection> sections;

  /// The close button's label.
  final String close;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.keyboard_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final section in sections) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(
                    section.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
                for (final shortcut in section.shortcuts)
                  _ShortcutRow(shortcut: shortcut),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(close),
        ),
      ],
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.shortcut});

  final MidiShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < shortcut.keys.length; i++) ...[
                  if (i > 0) Text('+', style: theme.textTheme.bodySmall),
                  MidiKeycap(shortcut.keys[i]),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(shortcut.action, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// A key (or a gesture) drawn as a keycap.
class MidiKeycap extends StatelessWidget {
  const MidiKeycap(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: cs.outlineVariant),
        // A deeper bottom edge, like a key standing up from the board. (A
        // rounded border can't take a different colour on one side.)
        boxShadow: [
          BoxShadow(color: cs.outline, offset: const Offset(0, 1.5)),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
