import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/providers/providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('show_menu_bar_icon_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('is shown by default', () async {
    await Hive.openBox<String>('settings');
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(showMenuBarIconProvider), isTrue);
  });

  test('a persisted "false" is read on the very first read', () async {
    final box = await Hive.openBox<String>('settings');
    await box.put('showMenuBarIcon', 'false');
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(showMenuBarIconProvider), isFalse);
  });

  test('set stores the choice for the next launch', () async {
    final box = await Hive.openBox<String>('settings');
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(showMenuBarIconProvider.notifier).set(false);

    expect(container.read(showMenuBarIconProvider), isFalse);
    expect(box.get('showMenuBarIcon'), 'false');
  });
}
