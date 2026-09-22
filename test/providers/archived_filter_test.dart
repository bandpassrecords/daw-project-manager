import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/utils/project_file_status.dart';

import '../helpers/test_factories.dart';

// Stub notifiers, mirroring projects_provider_test.dart: overriding build()
// avoids SchedulerBinding and Hive reads while keeping the mutation API.
class _FakeShowHiddenNotifier extends ShowHiddenProjectsNotifier {
  @override
  int build() => 0;
}

class _FakeShowFinishedNotifier extends ShowFinishedProjectsNotifier {
  @override
  int build() => 0;
}

class _FakeShowOnlyWithDeadlineNotifier extends ShowOnlyWithDeadlineNotifier {
  @override
  bool build() => false;
}

ProviderContainer _makeContainer(List<MusicProject> projects) {
  return ProviderContainer(overrides: [
    allProjectsStreamProvider.overrideWith((ref) => Stream.value(projects)),
    releasesProvider.overrideWith((ref) => Stream.value(const <Release>[])),
    scanRootsProvider.overrideWith((ref) => const []),
    finishedPhaseProvider.overrideWith((ref) => const <String>{'Finished'}),
    showHiddenProjectsProvider.overrideWith(_FakeShowHiddenNotifier.new),
    showFinishedProjectsProvider.overrideWith(_FakeShowFinishedNotifier.new),
    showOnlyWithDeadlineProvider.overrideWith(
      _FakeShowOnlyWithDeadlineNotifier.new,
    ),
  ]);
}

/// Riverpod 3 pauses stream subscriptions with no active listener, so hold one
/// open until both streams have emitted before reading the filtered list.
Future<List<MusicProject>> _readProjects(ProviderContainer c) async {
  final ready = Completer<void>();
  final sub = c.listen<AsyncValue<List<MusicProject>>>(
    allProjectsStreamProvider,
    (_, next) {
      if (next.hasValue && !ready.isCompleted) ready.complete();
    },
    fireImmediately: true,
  );
  final releasesReady = Completer<void>();
  final releasesSub = c.listen<AsyncValue<List<Release>>>(
    releasesProvider,
    (_, next) {
      if (next.hasValue && !releasesReady.isCompleted) releasesReady.complete();
    },
    fireImmediately: true,
  );
  await ready.future;
  await releasesReady.future;
  sub.close();
  releasesSub.close();
  return c.read(projectsProvider);
}

void main() {
  group('ShowArchivedProjectsNotifier', () {
    test('defaults to 0 (archived hidden)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(showArchivedProjectsProvider), 0);
    });

    test('setShowAll(true) sets state to 1', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(showArchivedProjectsProvider.notifier).setShowAll(true);

      expect(c.read(showArchivedProjectsProvider), 1);
    });

    test('setShowOnlyArchived(true) sets state to 2', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(showArchivedProjectsProvider.notifier).setShowOnlyArchived(true);

      expect(c.read(showArchivedProjectsProvider), 2);
    });

    test('a fresh container ("app restart") always starts at 0', () {
      // Deliberately session-only: a forgotten "only archived" from a previous
      // launch would empty the library on startup with no visible cause.
      final first = ProviderContainer();
      first.read(showArchivedProjectsProvider.notifier).setShowOnlyArchived(true);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);

      expect(second.read(showArchivedProjectsProvider), 0);
    });
  });

  group('isArchivedAway', () {
    test('an unarchived project is never archived-away', () {
      expect(
        isArchivedAway(TestFactories.makeProject(), filesExistLocally: false),
        isFalse,
      );
    });

    test('archived with the files still on disk is not archived-away', () {
      // Archiving without ticking "delete the originals" leaves a usable
      // project behind; the zip is a backup, not a departure.
      expect(
        isArchivedAway(
          TestFactories.makeProject(archivePath: '/a/Midnight.zip'),
          filesExistLocally: true,
        ),
        isFalse,
      );
    });

    test('archived with the files gone is archived-away', () {
      expect(
        isArchivedAway(
          TestFactories.makeProject(archivePath: '/a/Midnight.zip'),
          filesExistLocally: false,
        ),
        isTrue,
      );
    });
  });

  group('projectsProvider archived filtering', () {
    final working = TestFactories.makeProject(
      id: 'working',
      filePath: '/lib/Working/Working.als',
    );
    final archived = TestFactories.makeProject(
      id: 'archived',
      filePath: '/lib/Archived/Archived.als',
      archivePath: '/Volumes/Archive/Archived.zip',
      archivedAt: DateTime(2026, 3, 4),
      archiveEntryPath: 'Archived/Archived.als',
    );

    test('hides archived projects by default', () async {
      final c = _makeContainer([working, archived]);
      addTearDown(c.dispose);

      final result = await _readProjects(c);

      expect(result.map((p) => p.id), ['working']);
    });

    test('mode 1 shows working and archived together', () async {
      final c = _makeContainer([working, archived]);
      addTearDown(c.dispose);
      c.read(showArchivedProjectsProvider.notifier).setShowAll(true);

      final result = await _readProjects(c);

      expect(result.map((p) => p.id), containsAll(<String>['working', 'archived']));
    });

    test('mode 2 shows only archived projects', () async {
      final c = _makeContainer([working, archived]);
      addTearDown(c.dispose);
      c.read(showArchivedProjectsProvider.notifier).setShowOnlyArchived(true);

      final result = await _readProjects(c);

      expect(result.map((p) => p.id), ['archived']);
    });

    test('an archived project whose files are still here stays visible',
        () async {
      // The regression this guards: archiving with "delete the originals"
      // unticked leaves the project fully workable on disk, and hiding it
      // would make a project vanish from the list as a reward for backing
      // it up.
      final tempDir =
          await Directory.systemTemp.createTemp('archived_visible_test_');
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
      final onDisk = File(p.join(tempDir.path, 'Backed Up.als'));
      await onDisk.writeAsString('als');

      final backedUp = TestFactories.makeProject(
        id: 'backed-up',
        filePath: onDisk.path,
        archivePath: '/Volumes/Archive/Backed Up.zip',
        archivedAt: DateTime(2026, 3, 4),
        archiveEntryPath: 'Backed Up.als',
      );

      final c = _makeContainer([working, backedUp]);
      addTearDown(c.dispose);

      final result = await _readProjects(c);

      expect(result.map((p) => p.id), containsAll(<String>['working', 'backed-up']));
    });

    test('"only archived" still includes the ones with local copies', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('archived_only_test_');
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
      final onDisk = File(p.join(tempDir.path, 'Backed Up.als'));
      await onDisk.writeAsString('als');

      final backedUp = TestFactories.makeProject(
        id: 'backed-up',
        filePath: onDisk.path,
        archivePath: '/Volumes/Archive/Backed Up.zip',
        archiveEntryPath: 'Backed Up.als',
      );

      final c = _makeContainer([working, archived, backedUp]);
      addTearDown(c.dispose);
      c.read(showArchivedProjectsProvider.notifier).setShowOnlyArchived(true);

      final result = await _readProjects(c);

      // Both kinds are things the user archived, so both belong in the view
      // whose whole job is "show me what I archived".
      expect(
        result.map((p) => p.id),
        containsAll(<String>['archived', 'backed-up']),
      );
      expect(result.map((p) => p.id), isNot(contains('working')));
    });

    test('archived and hidden are independent axes', () async {
      // An archived project that is *not* hidden still disappears under the
      // default archived mode — which is the whole point of a separate axis.
      final archivedNotHidden = archived.copyWith(hidden: false);
      final c = _makeContainer([working, archivedNotHidden]);
      addTearDown(c.dispose);

      expect((await _readProjects(c)).map((p) => p.id), ['working']);

      // And "show only archived" reaches it without touching the hidden filter.
      c.read(showArchivedProjectsProvider.notifier).setShowOnlyArchived(true);
      expect((await _readProjects(c)).map((p) => p.id), ['archived']);
    });
  });
}
