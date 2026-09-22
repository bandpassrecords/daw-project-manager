import 'dart:io';

import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

void showShortcutsHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const ShortcutsHelpDialog(),
  );
}

class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMac = Platform.isMacOS;
    final mod = isMac ? '⌘' : 'Ctrl';
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.keyboard_outlined, size: 20),
          const SizedBox(width: 8),
          Text(l10n.keyboardShortcuts),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShortcutGroup(
                label: l10n.shortcutGroupGlobal,
                entries: [
                  ShortcutEntry(keys: [mod, 'F'], description: l10n.shortcutFocusSearch),
                  ShortcutEntry(keys: [mod, 'R'], description: l10n.shortcutRescan),
                  ShortcutEntry(keys: [mod, 'T'], description: l10n.shortcutFocusTable),
                ],
              ),
              ShortcutGroup(
                label: l10n.shortcutGroupProjectsTable,
                entries: [
                  ShortcutEntry(keys: ['P'], description: l10n.shortcutPlayPause),
                  ShortcutEntry(keys: ['D'], description: l10n.shortcutViewDetails),
                  ShortcutEntry(keys: ['F'], description: l10n.shortcutOpenFolder),
                  ShortcutEntry(keys: ['↑ / ↓'], description: l10n.shortcutNavigateRows),
                  ShortcutEntry(keys: ['Enter'], description: l10n.shortcutEditCell),
                ],
              ),
              ShortcutGroup(
                label: '↳ ${l10n.shortcutGroupProjectsTableStandardMode}',
                entries: [
                  ShortcutEntry(keys: ['O'], description: l10n.shortcutOpenInDaw),
                ],
              ),
              ShortcutGroup(
                label: '↳ ${l10n.shortcutGroupProjectsTableSessionMode}',
                entries: [
                  ShortcutEntry(keys: ['S'], description: l10n.shortcutToggleSession),
                ],
              ),
              ShortcutGroup(
                label: l10n.shortcutGroupReleasesTable,
                entries: [
                  ShortcutEntry(keys: ['D'], description: l10n.shortcutViewRelease),
                  ShortcutEntry(keys: ['Enter'], description: l10n.shortcutViewRelease),
                ],
              ),
              ShortcutGroup(
                label: l10n.shortcutGroupPreviewPlayer,
                entries: [
                  ShortcutEntry(keys: ['Space'], description: l10n.shortcutPlayerPlayPause),
                  ShortcutEntry(keys: ['←  /  →'], description: l10n.shortcutPlayerSeek5),
                  ShortcutEntry(keys: [isMac ? '⌃' : 'Ctrl', '←  /  →'], description: l10n.shortcutPlayerSeek30),
                  ShortcutEntry(keys: ['M'], description: l10n.shortcutPlayerMono),
                  ShortcutEntry(
                    keys: [isMac ? '⌘' : 'Ctrl', l10n.shortcutMouseWheel],
                    description: l10n.shortcutPlayerVolume,
                  ),
                ],
              ),
              ShortcutGroup(
                label: l10n.shortcutGroupNavigation,
                entries: [
                  if (isMac)
                    ShortcutEntry(keys: ['⌘', '←'], description: l10n.shortcutGoBack),
                  ShortcutEntry(
                    keys: [isMac ? '⌥' : 'Alt', '←'],
                    description: l10n.shortcutGoBack,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.close,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

class ShortcutGroup extends StatelessWidget {
  final String label;
  final List<ShortcutEntry> entries;

  const ShortcutGroup({super.key, required this.label, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ...entries.map((e) => e.build(context)),
        ],
      ),
    );
  }
}

class ShortcutEntry extends StatelessWidget {
  final List<String> keys;
  final String description;

  const ShortcutEntry({super.key, required this.keys, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int i = 0; i < keys.length; i++) ...[
                  KeyCap(label: keys[i]),
                  if (i < keys.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(description, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class KeyCap extends StatelessWidget {
  final String label;
  const KeyCap({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark ? const Color(0xFF5A5A5E) : const Color(0xFFCCCCCC),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          color: theme.textTheme.bodyMedium?.color,
          height: 1,
        ),
      ),
    );
  }
}
