import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/custom_theme.dart';
import 'package:daw_project_manager/providers/theme_provider.dart';

/// Covers theme selection and the custom-theme store (#148).
///
/// The cycling tests replace the old `ThemeTypeNotifier.nextVisibleTheme`
/// ones: the switcher used to rotate between exactly two built-ins, and now
/// has to walk a list that grows with the user's own themes while still never
/// landing on the hidden `studioLight`.
void main() {
  // Both notifiers schedule their Hive load from a post-frame callback, which
  // needs the test binding up before build() runs.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('theme_provider_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  CustomTheme userTheme(String id, {String? name, Color? primary}) =>
      CustomTheme(
        id: id,
        name: name ?? 'Theme $id',
        brightness: Brightness.dark,
        primary: primary ?? const Color(0xFFEC407A),
        background: const Color(0xFF14161A),
        card: const Color(0xFF232529),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  group('SelectedThemeNotifier.nextThemeId', () {
    final builtIns = AppThemes.visibleBuiltIns.map((t) => t.id).toList();

    test('rotates through the visible built-ins and wraps', () {
      expect(SelectedThemeNotifier.nextThemeId('classicDark', builtIns),
          'neonDark');
      expect(SelectedThemeNotifier.nextThemeId('neonDark', builtIns),
          'classicDark');
    });

    test('never lands on the hidden studioLight, even starting from it', () {
      expect(SelectedThemeNotifier.nextThemeId('studioLight', builtIns),
          isNot('studioLight'));
    });

    test('includes user themes in the rotation', () {
      final ids = [...builtIns, 'uuid-a', 'uuid-b'];
      expect(SelectedThemeNotifier.nextThemeId('neonDark', ids), 'uuid-a');
      expect(SelectedThemeNotifier.nextThemeId('uuid-a', ids), 'uuid-b');
      expect(SelectedThemeNotifier.nextThemeId('uuid-b', ids), 'classicDark');
    });

    test('a theme deleted on another device cycles to the first, not stuck',
        () {
      expect(SelectedThemeNotifier.nextThemeId('gone-uuid', builtIns),
          builtIns.first);
    });

    test('falls back when there is nothing to cycle through', () {
      expect(SelectedThemeNotifier.nextThemeId('neonDark', const []),
          AppThemes.fallbackSpec.id);
    });
  });

  group('resolveTheme', () {
    test('a built-in name resolves to that built-in', () {
      expect(resolveTheme('neonDark', const []), AppThemes.neonDarkSpec);
      expect(resolveTheme('classicDark', const []), AppThemes.classicDarkSpec);
    });

    test('the hidden studioLight still resolves if it was stored', () {
      // An older build could persist it, and falling back would silently
      // change the theme out from under that user.
      expect(resolveTheme('studioLight', const []), AppThemes.studioLightSpec);
    });

    test('a uuid resolves to the matching user theme', () {
      final mine = userTheme('uuid-a');
      expect(resolveTheme('uuid-a', [mine]), mine);
    });

    test('an unknown id falls back to Classic Dark without throwing', () {
      expect(resolveTheme('uuid-that-is-gone', [userTheme('uuid-a')]),
          AppThemes.classicDarkSpec);
    });

    test('an empty id falls back to Classic Dark', () {
      expect(resolveTheme('', const []), AppThemes.classicDarkSpec);
    });
  });

  group('CustomThemesNotifier.decode', () {
    test('round-trips through encode', () {
      final themes = [userTheme('a'), userTheme('b')];
      final decoded = CustomThemesNotifier.decode(
        CustomThemesNotifier.encode(themes),
      );
      expect(decoded.map((t) => t.id), ['a', 'b']);
      expect(decoded.first.primary, themes.first.primary);
      expect(decoded.first.updatedAt, themes.first.updatedAt);
    });

    test('null and empty storage give an empty list', () {
      expect(CustomThemesNotifier.decode(null), isEmpty);
      expect(CustomThemesNotifier.decode(''), isEmpty);
    });

    test('malformed JSON gives an empty list rather than throwing', () {
      expect(CustomThemesNotifier.decode('{not json'), isEmpty);
      expect(CustomThemesNotifier.decode('{"not":"a list"}'), isEmpty);
    });

    test('one unreadable entry does not lose the rest', () {
      final raw = jsonEncode([
        userTheme('good-1').toJson(),
        {'no': 'id'},
        userTheme('good-2').toJson(),
      ]);
      expect(CustomThemesNotifier.decode(raw).map((t) => t.id),
          ['good-1', 'good-2']);
    });
  });

  group('CustomTheme JSON', () {
    test('keeps unknown fields from breaking a newer file', () {
      final json = userTheme('a').toJson()..['somethingNew'] = 42;
      expect(CustomTheme.fromJson(json).id, 'a');
    });

    test('missing optional fields fall back to the constructor defaults', () {
      final theme = CustomTheme.fromJson({'id': 'a', 'name': 'Bare'});
      expect(theme.cardRadius, 16);
      expect(theme.controlRadius, 12);
      expect(theme.brightness, Brightness.dark);
      expect(theme.secondary, isNull);
    });

    test('brightness survives the round trip', () {
      final light = userTheme('a').copyWith(brightness: Brightness.light);
      expect(CustomTheme.fromJson(light.toJson()).brightness,
          Brightness.light);
    });
  });

  group('CustomThemesNotifier persistence', () {
    test('upsert adds, then replaces by id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(customThemesProvider.notifier);

      await notifier.upsert(userTheme('a', name: 'First'));
      expect(container.read(customThemesProvider).single.name, 'First');

      await notifier.upsert(userTheme('a', name: 'Renamed'));
      final themes = container.read(customThemesProvider);
      expect(themes, hasLength(1));
      expect(themes.single.name, 'Renamed');
    });

    test('upsert stamps updatedAt so the grid key changes on an edit',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(customThemesProvider.notifier);

      await notifier.upsert(userTheme('a'));
      final first = container.read(customThemesProvider).single.updatedAt;
      await notifier.upsert(
        userTheme('a').copyWith(primary: const Color(0xFF00FF00)),
      );
      final second = container.read(customThemesProvider).single.updatedAt;

      expect(second, isNot(first));
    });

    test('themes are written to the app_settings box', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(customThemesProvider.notifier)
          .upsert(userTheme('a'));

      final box = await Hive.openBox<String>(CustomThemesNotifier.boxName);
      final stored =
          CustomThemesNotifier.decode(box.get(CustomThemesNotifier.storageKey));
      expect(stored.single.id, 'a');
    });

    test('adding a theme never changes which one is active', () async {
      // What lets Settings duplicate a theme without yanking the whole app
      // over to the copy — you can duplicate a theme you are not wearing.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(selectedThemeIdProvider.notifier)
          .selectBuiltIn(AppThemeType.neonDark);

      await container
          .read(customThemesProvider.notifier)
          .upsert(userTheme('a copy'));

      expect(container.read(selectedThemeIdProvider), 'neonDark');
      expect(container.read(activeThemeProvider), AppThemes.neonDarkSpec);
      expect(container.read(customThemesProvider).single.id, 'a copy');
    });

    test('editing the active theme keeps it active', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(customThemesProvider.notifier);

      await notifier.upsert(userTheme('a'));
      await container.read(selectedThemeIdProvider.notifier).select('a');

      await notifier.upsert(
        userTheme('a').copyWith(primary: const Color(0xFF00FF00)),
      );

      expect(container.read(selectedThemeIdProvider), 'a');
      expect(container.read(activeThemeProvider).primary,
          const Color(0xFF00FF00));
    });

    test('deleting the active theme moves the selection off it', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(customThemesProvider.notifier)
          .upsert(userTheme('a'));
      await container.read(selectedThemeIdProvider.notifier).select('a');
      expect(container.read(activeThemeProvider).id, 'a');

      await container.read(customThemesProvider.notifier).delete('a');

      expect(container.read(selectedThemeIdProvider),
          AppThemes.fallbackSpec.id);
      expect(container.read(activeThemeProvider), AppThemes.fallbackSpec);
    });

    test('deleting a theme that is not selected leaves the selection alone',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(customThemesProvider.notifier);

      await notifier.upsert(userTheme('a'));
      await notifier.upsert(userTheme('b'));
      await container.read(selectedThemeIdProvider.notifier).select('b');

      await notifier.delete('a');

      expect(container.read(selectedThemeIdProvider), 'b');
      expect(container.read(customThemesProvider).single.id, 'b');
    });
  });

  group('selectableThemesProvider', () {
    test('lists the visible built-ins first, then user themes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(customThemesProvider.notifier)
          .upsert(userTheme('mine'));

      expect(
        container.read(selectableThemesProvider).map((t) => t.id),
        ['classicDark', 'neonDark', 'mine'],
      );
    });
  });

  group('themeDataProvider', () {
    test('a user theme drives the built ThemeData', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mine = userTheme('mine', primary: const Color(0xFFEC407A));
      await container.read(customThemesProvider.notifier).upsert(mine);
      await container.read(selectedThemeIdProvider.notifier).select('mine');

      final theme = container.read(themeDataProvider);
      expect(theme.colorScheme.primary, const Color(0xFFEC407A));
      expect(theme.scaffoldBackgroundColor, mine.background);
      expect(theme.cardColor, mine.card);
    });
  });
}
