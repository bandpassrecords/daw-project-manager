import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  String _getThemeName(AppThemeType themeType) {
    switch (themeType) {
      case AppThemeType.neonDark:
        return 'Neon Dark';
      case AppThemeType.classicDark:
        return 'Classic Dark';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeTypeProvider);
    final isNeon = themeType == AppThemeType.neonDark;
    final themeName = _getThemeName(themeType);

    return Tooltip(
      message: isNeon ? 'Switch to Classic Theme' : 'Switch to Neon Theme',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isNeon ? Icons.palette : Icons.palette_outlined,
                key: ValueKey(isNeon),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            onPressed: () {
              ref.read(themeTypeProvider.notifier).cycle();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: isNeon ? 'Switch to Classic Theme' : 'Switch to Neon Theme',
          ),
          TextButton(
            onPressed: () {
              ref.read(themeTypeProvider.notifier).cycle();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              themeName,
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

