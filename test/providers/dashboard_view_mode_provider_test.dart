import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:daw_project_manager/models/dashboard_view_mode.dart';
import 'package:daw_project_manager/models/project_detail_layout.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/utils/project_sort.dart';

/// #111 — table or cards is a preference about how this machine shows a
/// library, not anything about the library, so it lives in the same
/// device-local `settings` box as the theme and the detail-page layout and
/// must never reach Drive sync or a backup file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('dashboard_view_mode_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) await hiveDir.delete(recursive: true);
  });

  test('defaults to the table everyone already has', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(dashboardViewModeProvider), DashboardViewMode.table);
  });

  test('persists the choice to the device-local settings box', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(dashboardViewModeProvider.notifier)
        .set(DashboardViewMode.cards);

    expect(container.read(dashboardViewModeProvider), DashboardViewMode.cards);
    final box = await Hive.openBox<String>('settings');
    expect(box.get('dashboardViewMode'), 'cards');
  });

  test('switching back to the table is written, not just left unset', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(dashboardViewModeProvider.notifier);
    await notifier.set(DashboardViewMode.cards);
    await notifier.set(DashboardViewMode.table);

    final box = await Hive.openBox<String>('settings');
    expect(box.get('dashboardViewMode'), 'table');
  });

  test('a value written by a newer build falls back to the default', () async {
    final box = await Hive.openBox<String>('settings');
    await box.put('dashboardViewMode', 'somethingFromTheFuture');

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(dashboardViewModeProvider), DashboardViewMode.table);
  });

  test('uses its own key, so it does not clobber the detail layout', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(projectDetailLayoutProvider.notifier)
        .set(ProjectDetailLayout.sectioned);
    await container
        .read(dashboardViewModeProvider.notifier)
        .set(DashboardViewMode.cards);

    final box = await Hive.openBox<String>('settings');
    expect(box.get('projectDetailLayout'), 'sectioned');
    expect(box.get('dashboardViewMode'), 'cards');
  });

  test('every mode has a distinct name to persist', () {
    final names = DashboardViewMode.values.map((e) => e.name).toSet();
    expect(names, hasLength(DashboardViewMode.values.length));
  });

  group('card sort', () {
    test('opens on newest work first', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardCardSortProvider),
        DashboardCardSort.initial,
      );
    });

    test('round-trips through the settings box', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(dashboardCardSortProvider.notifier)
          .set(const DashboardCardSort(ProjectSortField.name, false));

      final box = await Hive.openBox<String>('settings');
      expect(box.get('dashboardCardSort'), 'name:asc');
      expect(
        DashboardCardSort.decode('name:asc'),
        const DashboardCardSort(ProjectSortField.name, false),
      );
    });

    test('a new field starts in the direction it reads best in', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(dashboardCardSortProvider.notifier);

      await notifier.selectField(ProjectSortField.name);
      expect(
        container.read(dashboardCardSortProvider),
        const DashboardCardSort(ProjectSortField.name, false),
      );

      await notifier.selectField(ProjectSortField.bpm);
      expect(
        container.read(dashboardCardSortProvider),
        const DashboardCardSort(ProjectSortField.bpm, true),
      );
    });

    test('picking the field already in use flips the arrow', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(dashboardCardSortProvider.notifier);

      await notifier.selectField(ProjectSortField.name);
      await notifier.selectField(ProjectSortField.name);

      expect(
        container.read(dashboardCardSortProvider),
        const DashboardCardSort(ProjectSortField.name, true),
      );
    });

    test('junk in the box falls back to the default', () async {
      expect(DashboardCardSort.decode(null), isNull);
      expect(DashboardCardSort.decode(''), isNull);
      expect(DashboardCardSort.decode('name'), isNull);
      expect(DashboardCardSort.decode('somethingNew:asc'), isNull);

      final box = await Hive.openBox<String>('settings');
      await box.put('dashboardCardSort', 'somethingNew:asc');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardCardSortProvider),
        DashboardCardSort.initial,
      );
    });
  });
}
