import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/providers/theme_provider.dart';

/// Exercises the exact calls the Settings page's new Language row (General
/// section) and Theme selector (Appearance section) make —
/// `localeProvider.notifier.setLocale` and `themeTypeProvider.notifier.setThemeType`.
void main() {
  // LocaleNotifier.build()/ThemeTypeNotifier.build() both call
  // SchedulerBinding.instance.addPostFrameCallback(...) to schedule their
  // deferred Hive load, which needs the test binding initialized first —
  // without this, reading either provider throws "Binding has not yet been
  // initialized" the moment build() runs.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('locale_theme_provider_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('localeProvider', () {
    test('defaults to English before any preference is saved', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(localeProvider), const Locale('en'));
    });

    test('setLocale updates state immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('ja'));

      expect(container.read(localeProvider), const Locale('ja'));
    });

    test('setLocale persists languageCode_countryCode to the settings box', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('pt', 'BR'));

      final box = await Hive.openBox<String>('settings');
      expect(box.get('locale'), 'pt_BR');
    });

    test('setLocale persists an empty country code when the locale has none', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('de'));

      final box = await Hive.openBox<String>('settings');
      expect(box.get('locale'), 'de_');
    });
  });

  group('selectedThemeIdProvider', () {
    test('defaults to classicDark before any preference is saved', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedThemeIdProvider),
          AppThemeType.classicDark.name);
    });

    test('selectBuiltIn updates state immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(selectedThemeIdProvider.notifier)
          .selectBuiltIn(AppThemeType.neonDark);

      expect(container.read(selectedThemeIdProvider),
          AppThemeType.neonDark.name);
    });

    test('selectBuiltIn persists the enum name to the settings box', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(selectedThemeIdProvider.notifier)
          .selectBuiltIn(AppThemeType.neonDark);

      final box = await Hive.openBox<String>('settings');
      expect(box.get('theme'), 'neonDark');
    });

    // The storage key and value format are unchanged from when this was
    // themeTypeProvider, so an existing install keeps its theme rather than
    // silently resetting to Classic Dark on upgrade.
    test('a stored built-in name still resolves to that theme', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(selectedThemeIdProvider.notifier).select('neonDark');

      expect(container.read(activeThemeProvider), AppThemes.neonDarkSpec);
    });
  });
}
