import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeTypeProvider);
    final isFuturistic = themeType == AppThemeType.futuristicDark;

    return Tooltip(
      message: isFuturistic ? 'Switch to Classic Theme' : 'Switch to Futuristic Theme',
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isFuturistic ? Icons.palette : Icons.palette_outlined,
            key: ValueKey(isFuturistic),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onPressed: () {
          ref.read(themeTypeProvider.notifier).cycle();
        },
      ),
    );
  }
}

