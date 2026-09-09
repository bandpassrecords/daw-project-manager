import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme_derivations.dart';
import '../theme_labels.dart';

class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(activeThemeProvider);
    final selectable = ref.watch(selectableThemesProvider);

    final themeName = themeDisplayName(active, l10n);
    final tooltip = l10n.switchToTheme(
      nextThemeDisplayName(active.id, selectable, l10n),
    );
    // A vivid accent gets the filled palette icon, a muted one the outline —
    // the same split Neon Dark and Classic Dark used to be hardcoded to.
    final icon = active.hasVividAccent ? Icons.palette : Icons.palette_outlined;

    void cycle() => ref.read(selectedThemeIdProvider.notifier).cycle();

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                key: ValueKey(active.id),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            onPressed: cycle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: tooltip,
          ),
          TextButton(
            onPressed: cycle,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              themeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
