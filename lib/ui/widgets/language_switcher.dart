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
      icon: const Icon(Icons.language, color: Colors.white70, size: 20),
      underline: const SizedBox.shrink(),
      dropdownColor: const Color(0xFF2B2D31),
      style: const TextStyle(color: Colors.white70, fontSize: 14),
      items: languageNames.entries.map((entry) {
        return DropdownMenuItem<Locale>(
          value: Locale(entry.key),
          child: Text(
            entry.value,
            style: const TextStyle(color: Colors.white70),
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


