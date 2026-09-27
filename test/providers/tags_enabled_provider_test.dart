import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/providers/providers.dart';

/// Covers [TagsEnabledNotifier] — the Settings switch that turns project tags
/// (#109) on or off. Device-local, off unless the user turned it on.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tags_enabled_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('initial read', () {
    test('defaults to off when nothing has been saved yet', () async {
      await Hive.openBox<String>('settings');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(tagsEnabledProvider), isFalse);
    });

    test('reads a persisted "true" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('tagsEnabled', 'true');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // No await — the dashboard's first frame must already know whether to
      // draw the Tags column.
      expect(container.read(tagsEnabledProvider), isTrue);
    });

    test('falls back to off instead of throwing if the box was never opened', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(tagsEnabledProvider), isFalse);
    });
  });

  group('set()', () {
    test('updates state and Hive together', () async {
      final box = await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(tagsEnabledProvider.notifier).set(true);

      expect(container.read(tagsEnabledProvider), isTrue);
      expect(box.get('tagsEnabled'), 'true');
    });

    test('turning it back off is persisted too', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('tagsEnabled', 'true');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(tagsEnabledProvider);

      await container.read(tagsEnabledProvider.notifier).set(false);

      expect(container.read(tagsEnabledProvider), isFalse);
      expect(box.get('tagsEnabled'), 'false');
    });

    test('setting the value it already has writes nothing', () async {
      final box = await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(tagsEnabledProvider.notifier).set(false);

      expect(box.get('tagsEnabled'), isNull);
    });
  });
}
