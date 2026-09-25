import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:daw_project_manager/providers/providers.dart';

/// The dragged width of the section rail is a preference about this
/// machine's screen: it lives in the device-local `settings` box and must
/// never reach Drive sync or a backup file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('rail_width_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) await hiveDir.delete(recursive: true);
  });

  test('starts unset, so each page uses its own default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(sectionRailWidthProvider), isNull);
  });

  test('a drag follows the pointer without writing every frame', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(sectionRailWidthProvider.notifier);
    notifier.preview(250);
    notifier.preview(260);

    expect(container.read(sectionRailWidthProvider), 260);
    final box = await Hive.openBox<String>('settings');
    expect(box.get(SectionRailWidthNotifier.boxKey), isNull,
        reason: 'nothing is saved until the drag ends');
  });

  test('the end of a drag saves the width to the settings box', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(sectionRailWidthProvider.notifier);
    notifier.preview(275);
    await notifier.commit();

    final box = await Hive.openBox<String>('settings');
    expect(box.get(SectionRailWidthNotifier.boxKey), '275.0');
  });

  test('a saved width comes back on the next launch', () async {
    final box = await Hive.openBox<String>('settings');
    await box.put(SectionRailWidthNotifier.boxKey, '310.0');

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(sectionRailWidthProvider.notifier).load();

    expect(container.read(sectionRailWidthProvider), 310);
  });

  test('an unreadable saved width is ignored', () async {
    final box = await Hive.openBox<String>('settings');
    await box.put(SectionRailWidthNotifier.boxKey, 'wide');

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(sectionRailWidthProvider.notifier).load();

    expect(container.read(sectionRailWidthProvider), isNull);
  });

  test('reset forgets the width, in memory and on disk', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(sectionRailWidthProvider.notifier);
    notifier.preview(300);
    await notifier.commit();
    await notifier.reset();

    expect(container.read(sectionRailWidthProvider), isNull);
    final box = await Hive.openBox<String>('settings');
    expect(box.containsKey(SectionRailWidthNotifier.boxKey), isFalse);
  });

  test('uses its own key, so it does not clobber the detail layout', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final box = await Hive.openBox<String>('settings');
    await box.put('projectDetailLayout', 'sectioned');

    final notifier = container.read(sectionRailWidthProvider.notifier);
    notifier.preview(220);
    await notifier.commit();
    await notifier.reset();

    expect(box.get('projectDetailLayout'), 'sectioned');
  });
}
