import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/providers.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  static const Map<String, String> languageNames = {
    'en': 'English',
    'pt': 'Português',
    'es': 'Español',
    'fr': 'Français',
    'it': 'Italiano',
    'de': 'Deutsch',
    'ru': 'Русский',
    'ja': '日本語',
    'zh': '中文',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return DropdownButton<Locale>(
      value: currentLocale,
      icon: Icon(Icons.language, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
      underline: const SizedBox.shrink(),
      dropdownColor: Theme.of(context).cardColor,
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
      items: languageNames.entries.map((entry) {
        return DropdownMenuItem<Locale>(
          value: Locale(entry.key),
          child: Text(
            entry.value,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        );
      }).toList(),
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          ref.read(localeProvider.notifier).setLocale(newLocale);
        }
      },
    );
  }
}


