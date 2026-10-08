import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:daw_project_manager/models/custom_field.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/services/custom_field_merge.dart';
import 'package:daw_project_manager/utils/custom_fields.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('custom_fields_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) await hiveDir.delete(recursive: true);
  });

  Future<List<CustomFieldDefinition>> stored() async {
    final box = await Hive.openBox<String>('app_settings');
    return decodeCustomFieldDefinitions(
        box.get(customFieldDefinitionsStorageKey));
  }

  group('customFieldDefinitionsProvider', () {
    test('adding a field stores it last and stamps it', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(customFieldDefinitionsProvider.notifier);

      await notifier
          .upsert(const CustomFieldDefinition(id: 'a', name: 'LUFS'));
      await notifier
          .upsert(const CustomFieldDefinition(id: 'b', name: 'ISRC'));

      final fields = await stored();
      expect(fields.map((f) => f.id), ['a', 'b']);
      expect(fields.map((f) => f.order), [0, 1]);
      expect(fields.every((f) => f.updatedAt != null), isTrue);
    });

    test('editing replaces in place and bumps updatedAt', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(customFieldDefinitionsProvider.notifier);
      await notifier
          .upsert(const CustomFieldDefinition(id: 'a', name: 'Loudness'));
      final before = (await stored()).single.updatedAt!;
      await Future<void>.delayed(const Duration(milliseconds: 2));

      await notifier.upsert(
          container.read(customFieldDefinitionsProvider).single.copyWith(name: 'LUFS'));

      final after = (await stored()).single;
      expect(after.name, 'LUFS');
      expect(after.updatedAt!.isAfter(before), isTrue);
    });

    test('deleting leaves a tombstone the active list hides', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(customFieldDefinitionsProvider.notifier);
      await notifier
          .upsert(const CustomFieldDefinition(id: 'a', name: 'LUFS'));

      await notifier.delete('a');

      expect((await stored()).single.isDeleted, isTrue);
      expect(container.read(activeCustomFieldsProvider), isEmpty);
    });

    test('reordering moves an active field and renumbers', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(customFieldDefinitionsProvider.notifier);
      for (final id in ['a', 'b', 'c']) {
        await notifier.upsert(CustomFieldDefinition(id: id, name: id));
      }

      await notifier.reorder(0, 3);

      expect(container.read(activeCustomFieldsProvider).map((f) => f.id),
          ['b', 'c', 'a']);
      expect(
        activeCustomFields(await stored()).map((f) => f.id),
        ['b', 'c', 'a'],
      );
    });

    test('loads what is stored, and follows a restore writing the box',
        () async {
      final box = await Hive.openBox<String>('app_settings');
      await box.put(
        customFieldDefinitionsStorageKey,
        encodeCustomFieldDefinitions(
            [const CustomFieldDefinition(id: 'a', name: 'LUFS')]),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(customFieldDefinitionsProvider.notifier).load();
      expect(container.read(activeCustomFieldsProvider).single.name, 'LUFS');

      // What a backup restore or a Drive sync does: write the key directly.
      await box.put(
        customFieldDefinitionsStorageKey,
        encodeCustomFieldDefinitions([
          const CustomFieldDefinition(id: 'a', name: 'LUFS'),
          const CustomFieldDefinition(id: 'b', name: 'ISRC', order: 1),
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(activeCustomFieldsProvider).map((f) => f.id),
          ['a', 'b']);
    });
  });

  group('projectsTableColumnsProvider', () {
    test('starts with every built-in, visible but the opt-in ones', () async {
      await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final layout = container.read(projectsTableColumnsProvider);
      expect(layout.map((s) => s.id), kProjectsTableBuiltInColumns);
      for (final s in layout) {
        expect(s.visible, !kProjectsTableHiddenByDefault.contains(s.id),
            reason: s.id);
      }
    });

    test('showing a column in release tracklists persists, separately',
        () async {
      final box = await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectsTableColumnsProvider.notifier);

      await notifier.setInReleaseTracks('tags', true);
      await notifier.setInReleaseTracks('bpm', false);
      final layout = container.read(projectsTableColumnsProvider);
      final tags = layout.firstWhere((s) => s.id == 'tags');
      final bpm = layout.firstWhere((s) => s.id == 'bpm');
      expect(tags.inReleaseTracks, isTrue);
      expect(bpm.inReleaseTracks, isFalse);
      expect(bpm.visible, isTrue, reason: 'the projects table is untouched');

      final stored = decodeColumnLayout(
          box.get(ProjectsTableColumnsNotifier.boxKey));
      expect(stored.firstWhere((s) => s.id == 'bpm').inReleaseTracks, isFalse);
    });

    test('hiding, reordering and resetting persist to the settings box',
        () async {
      final box = await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectsTableColumnsProvider.notifier);

      await notifier.setVisible('bpm', false);
      await notifier.reorder(6, 0); // deadline to the front

      final saved = decodeColumnLayout(
          box.get(ProjectsTableColumnsNotifier.boxKey));
      expect(saved.first.id, 'deadline');
      expect(saved.firstWhere((s) => s.id == 'bpm').visible, isFalse);

      // A fresh container reads it back — a later launch.
      final next = ProviderContainer();
      addTearDown(next.dispose);
      expect(next.read(projectsTableColumnsProvider), saved);

      await notifier.reset();
      expect(container.read(projectsTableColumnsProvider),
          normalizeColumnLayout(const []));
    });
  });

  group('release tracklist pane', () {
    test('the split is saved only when a drag ends, and resets', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(releaseTracksSplitProvider.notifier);

      notifier.preview(0.8);
      final box = await Hive.openBox<String>('settings');
      expect(box.get(ReleaseTracksSplitNotifier.boxKey), isNull);

      await notifier.commit();
      expect(box.get(ReleaseTracksSplitNotifier.boxKey), '0.800');

      final next = ProviderContainer();
      addTearDown(next.dispose);
      await next.read(releaseTracksSplitProvider.notifier).load();
      expect(next.read(releaseTracksSplitProvider), 0.8);

      await notifier.reset();
      expect(container.read(releaseTracksSplitProvider), isNull);
      expect(box.get(ReleaseTracksSplitNotifier.boxKey), isNull);
    });

    test('a saved split outside (0, 1) is ignored', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put(ReleaseTracksSplitNotifier.boxKey, '1.5');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(releaseTracksSplitProvider.notifier).load();

      expect(container.read(releaseTracksSplitProvider), isNull);
    });

    test('maximized is remembered', () async {
      final box = await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(releaseTracksMaximizedProvider), isFalse);
      await container.read(releaseTracksMaximizedProvider.notifier).set(true);

      expect(box.get(ReleaseTracksMaximizedNotifier.boxKey), 'true');
      final next = ProviderContainer();
      addTearDown(next.dispose);
      expect(next.read(releaseTracksMaximizedProvider), isTrue);
    });

    test('the table/list choice is remembered, starting on the list',
        () async {
      final box = await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(releaseTracksAsTableProvider), isFalse);
      await container.read(releaseTracksAsTableProvider.notifier).set(true);

      expect(box.get(ReleaseTracksAsTableNotifier.boxKey), 'true');
      // Leaving the release page and opening another one reads it afresh.
      final next = ProviderContainer();
      addTearDown(next.dispose);
      expect(next.read(releaseTracksAsTableProvider), isTrue);

      await next.read(releaseTracksAsTableProvider.notifier).set(false);
      final again = ProviderContainer();
      addTearDown(again.dispose);
      expect(again.read(releaseTracksAsTableProvider), isFalse);
    });

    test('the table/list choice is not synced or backed up', () {
      // Device-local, like the maximized pane: a key in the settings box,
      // which neither Drive sync nor local backup reads.
      for (final file in [
        'lib/services/google_drive_sync_service.dart',
        'lib/services/backup_service.dart',
      ]) {
        expect(
          File(file).readAsStringSync(),
          isNot(contains(ReleaseTracksAsTableNotifier.boxKey)),
          reason: file,
        );
      }
    });
  });
}
