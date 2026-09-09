import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/models/scan_root.dart';
import 'package:daw_project_manager/providers/providers.dart';

import '../helpers/test_factories.dart';

// ---------------------------------------------------------------------------
// Stub notifiers — override build() to avoid SchedulerBinding.instance calls
// and Hive reads, while preserving the public state-mutation API.
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(
  List<MusicProject> projects, {
  List<Release> releases = const [],
  List<ScanRoot> roots = const [],
}) {
  return ProviderContainer(overrides: [
    allProjectsStreamProvider.overrideWith(
        (ref) => Stream.value(projects)),
    releasesProvider.overrideWith(
        (ref) => Stream.value(releases)),
    scanRootsProvider.overrideWith(
        (ref) => roots),
    finishedPhaseProvider.overrideWith(
        (ref) => const <String>{'Finished'}),
    showHiddenProjectsProvider.overrideWith(_FakeShowHiddenNotifier.new),
    showFinishedProjectsProvider.overrideWith(_FakeShowFinishedNotifier.new),
    showOnlyWithDeadlineProvider.overrideWith(
        _FakeShowOnlyWithDeadlineNotifier.new),
  ]);
}

/// Riverpod 3 pauses stream subscriptions when a provider has no active
/// listener (a bare `read()` call doesn't count). We must hold an active
/// subscription open until the stream emits, then release it.
Future<List<MusicProject>> _readProjects(ProviderContainer c) async {
  final completer = Completer<void>();
  final sub = c.listen<AsyncValue<List<MusicProject>>>(
    allProjectsStreamProvider,
    (_, next) {
      if (next.hasValue && !completer.isCompleted) completer.complete();
    },
    fireImmediately: true,
  );
  // releasesProvider is a stream too, and projectsProvider reads it to decide
  // which release-attached projects to hide. Without waiting for it to emit,
  // that filter sees an empty release list and never runs — so a test about
  // release-attached projects would pass no matter what the filter does.
  final releasesReady = Completer<void>();
  final releasesSub = c.listen<AsyncValue<List<Release>>>(
    releasesProvider,
    (_, next) {
      if (next.hasValue && !releasesReady.isCompleted) releasesReady.complete();
    },
    fireImmediately: true,
  );
  await completer.future;
  await releasesReady.future;
  sub.close();
  releasesSub.close();
  return c.read(projectsProvider);
}

/// Same active-subscription requirement as [_readProjects], but for
/// [availableDawsProvider] instead of the filtered [projectsProvider].
Future<List<String>> _readAvailableDaws(ProviderContainer c) async {
  final completer = Completer<void>();
  final sub = c.listen<AsyncValue<List<MusicProject>>>(
    allProjectsStreamProvider,
    (_, next) {
      if (next.hasValue && !completer.isCompleted) completer.complete();
    },
    fireImmediately: true,
  );
  await completer.future;
  sub.close();
  return c.read(availableDawsProvider);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('projectsProvider — default behaviour', () {
    test('hides hidden projects by default', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'visible', hidden: false),
        TestFactories.makeProject(id: 'hidden', hidden: true),
      ]);
      addTearDown(c.dispose);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['visible']);
    });

    test('sorts by lastModifiedAt descending — newest first', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
            id: 'old', lastModifiedAt: DateTime(2024, 1, 1)),
        TestFactories.makeProject(
            id: 'new', lastModifiedAt: DateTime(2025, 1, 1)),
      ]);
      addTearDown(c.dispose);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['new', 'old']);
    });
  });

  group('projectsProvider — phase filter', () {
    test('null phase filter shows all non-hidden projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'a', status: 'Idea'),
        TestFactories.makeProject(id: 'b', status: 'Mixing'),
      ]);
      addTearDown(c.dispose);

      expect((await _readProjects(c)).length, 2);
    });

    test('setting phase filter = Idea returns only Idea projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'idea1', status: 'Idea'),
        TestFactories.makeProject(id: 'mixing', status: 'Mixing'),
        TestFactories.makeProject(id: 'idea2', status: 'Idea'),
      ]);
      addTearDown(c.dispose);
      c.read(phaseFilterProvider.notifier).setPhase('Idea');

      final ids = (await _readProjects(c)).map((p) => p.id).toSet();
      expect(ids, {'idea1', 'idea2'});
    });

    test('phase filter with no matching projects returns empty list', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: '1', status: 'Mixing'),
      ]);
      addTearDown(c.dispose);
      c.read(phaseFilterProvider.notifier).setPhase('Mastering');

      expect(await _readProjects(c), isEmpty);
    });
  });

  group('projectsProvider — hidden project filter', () {
    test('mode=1 (show all) includes hidden projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'v', hidden: false),
        TestFactories.makeProject(id: 'h', hidden: true),
      ]);
      addTearDown(c.dispose);
      c.read(showHiddenProjectsProvider.notifier).setShowAll(true);

      expect((await _readProjects(c)).length, 2);
    });

    test('mode=2 (only hidden) returns only hidden projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'v', hidden: false),
        TestFactories.makeProject(id: 'h', hidden: true),
      ]);
      addTearDown(c.dispose);
      c.read(showHiddenProjectsProvider.notifier).setShowOnlyHidden(true);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['h']);
    });
  });

  group('projectsProvider — deadline filter', () {
    test('overdue filter returns only projects with past deadline', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
          id: 'overdue',
          deadline: DateTime.now().subtract(const Duration(days: 3)),
        ),
        TestFactories.makeProject(
          id: 'future',
          deadline: DateTime.now().add(const Duration(days: 10)),
        ),
        TestFactories.makeProject(id: 'none'),
      ]);
      addTearDown(c.dispose);
      c.read(deadlineFilterProvider.notifier).setFilter(DeadlineFilter.overdue);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['overdue']);
    });

    test('dueSoon filter returns projects due within 7 days', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
          id: 'soon',
          deadline: DateTime.now().add(const Duration(days: 3)),
        ),
        TestFactories.makeProject(
          id: 'far',
          deadline: DateTime.now().add(const Duration(days: 30)),
        ),
      ]);
      addTearDown(c.dispose);
      c
          .read(deadlineFilterProvider.notifier)
          .setFilter(DeadlineFilter.dueSoon);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['soon']);
    });

    test('dueToday filter returns projects with deadline today', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
          id: 'today',
          deadline: DateTime.now(),
        ),
        TestFactories.makeProject(
          id: 'tomorrow',
          deadline: DateTime.now().add(const Duration(days: 1)),
        ),
      ]);
      addTearDown(c.dispose);
      c
          .read(deadlineFilterProvider.notifier)
          .setFilter(DeadlineFilter.dueToday);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['today']);
    });
  });

  group('projectsProvider — text search', () {
    test('search filters by project displayName', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'bass', fileName: 'BassTrack.als'),
        TestFactories.makeProject(id: 'drum', fileName: 'DrumLoop.als'),
      ]);
      addTearDown(c.dispose);
      c.read(projectsSearchProvider.notifier).setSearchText('Bass');

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['bass']);
    });

    test('empty search text returns all visible projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: '1', fileName: 'A.als'),
        TestFactories.makeProject(id: '2', fileName: 'B.als'),
      ]);
      addTearDown(c.dispose);

      expect((await _readProjects(c)).length, 2);
    });

    test('search filters by user notes', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
            id: 'withnotes', fileName: 'A.als', notes: 'needs more reverb'),
        TestFactories.makeProject(id: 'plain', fileName: 'B.als'),
      ]);
      addTearDown(c.dispose);
      c.read(projectsSearchProvider.notifier).setSearchText('reverb');

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['withnotes']);
    });

    test('search filters by DAW-extracted projectNotes', () async {
      // Issue #102 part 2: projectNotes is real user content pulled out of the
      // DAW file (REAPER's Notes tab, Cubase's Notepad) and used to be
      // invisible to search.
      final c = _makeContainer([
        TestFactories.makeProject(
            id: 'dawnotes',
            fileName: 'A.als',
            projectNotes: 'mixed on the shared monitors'),
        TestFactories.makeProject(id: 'plain', fileName: 'B.als'),
      ]);
      addTearDown(c.dispose);
      c.read(projectsSearchProvider.notifier).setSearchText('shared');

      expect((await _readProjects(c)).map((p) => p.id).toList(), ['dawnotes']);
    });

    test('search does not match unrelated projects by scavenged letters',
        () async {
      // Issue #102 part 1: "shared" used to match this filename because
      // s-h-a-r-e-d appear in order across six unrelated words.
      final c = _makeContainer([
        TestFactories.makeProject(
            id: 'royksopp',
            fileName:
                '2026_022_01 - Royksopp - What Else is There (Audio Crawler Remix).cpr'),
        TestFactories.makeProject(
            id: 'shortnotes', fileName: 'B.als', notes: 'sh'),
      ]);
      addTearDown(c.dispose);
      c.read(projectsSearchProvider.notifier).setSearchText('shared');

      expect((await _readProjects(c)).map((p) => p.id).toList(), isEmpty);
    });

    test('search matches a performer credited on a part', () async {
      // "Which songs did Nina sing on?" has to be answerable from the list.
      final c = _makeContainer([
        TestFactories.makeProject(id: 'withNina', fileName: 'A.als', parts: [
          TestFactories.makePart(id: 'p1', name: 'Lead Vocals', performer: 'Nina'),
        ]),
        TestFactories.makeProject(id: 'without', fileName: 'B.als', parts: [
          TestFactories.makePart(id: 'p2', name: 'Drums', performer: 'Alex'),
        ]),
      ]);
      addTearDown(c.dispose);
      c.read(projectsSearchProvider.notifier).setSearchText('Nina');

      expect((await _readProjects(c)).map((p) => p.id).toList(), ['withNina']);
    });

    test('search matches an instrument name in the parts list', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'hasRhodes', fileName: 'A.als', parts: [
          TestFactories.makePart(id: 'p1', name: 'Rhodes', performer: null),
        ]),
        TestFactories.makeProject(id: 'noRhodes', fileName: 'B.als'),
      ]);
      addTearDown(c.dispose);
      c.read(projectsSearchProvider.notifier).setSearchText('Rhodes');

      expect((await _readProjects(c)).map((p) => p.id).toList(), ['hasRhodes']);
    });
  });

  group('projectsProvider — sort order', () {
    test('sortDesc=false gives oldest-first order', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
            id: 'old', lastModifiedAt: DateTime(2024, 1, 1)),
        TestFactories.makeProject(
            id: 'new', lastModifiedAt: DateTime(2025, 6, 1)),
      ]);
      addTearDown(c.dispose);
      // toggleSortDesc flips from default true → false (ascending)
      c.read(queryParamsNotifierProvider.notifier).toggleSortDesc();

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['old', 'new']);
    });
  });

  group('projectsProvider — finished phase filter', () {
    test('hide finished removes projects in finished phases', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'mixing', status: 'Mixing'),
        TestFactories.makeProject(id: 'done', status: 'Finished'),
      ]);
      addTearDown(c.dispose);
      unawaited(c
          .read(showFinishedProjectsProvider.notifier)
          .setHideFinished(true));

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['mixing']);
    });
  });

  group('projectsProvider — DAW filter', () {
    test('null DAW filter shows all non-hidden projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'a', dawType: 'Ableton Live'),
        TestFactories.makeProject(id: 'b', dawType: 'FL Studio'),
      ]);
      addTearDown(c.dispose);

      expect((await _readProjects(c)).length, 2);
    });

    test('setting DAW filter = FL Studio returns only FL Studio projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'a', dawType: 'Ableton Live'),
        TestFactories.makeProject(id: 'b', dawType: 'FL Studio'),
        TestFactories.makeProject(id: 'c', dawType: 'FL Studio'),
      ]);
      addTearDown(c.dispose);
      c.read(dawFilterProvider.notifier).setDaw('FL Studio');

      final ids = (await _readProjects(c)).map((p) => p.id).toSet();
      expect(ids, {'b', 'c'});
    });

    test('DAW filter with no matching projects returns empty list', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: '1', dawType: 'Ableton Live'),
      ]);
      addTearDown(c.dispose);
      c.read(dawFilterProvider.notifier).setDaw('Logic Pro');

      expect(await _readProjects(c), isEmpty);
    });

    test('clear() resets the filter back to showing all', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'a', dawType: 'Ableton Live'),
        TestFactories.makeProject(id: 'b', dawType: 'FL Studio'),
      ]);
      addTearDown(c.dispose);
      c.read(dawFilterProvider.notifier).setDaw('FL Studio');
      expect((await _readProjects(c)).length, 1);

      c.read(dawFilterProvider.notifier).clear();
      expect((await _readProjects(c)).length, 2);
    });
  });

  group('availableDawsProvider', () {
    test('returns distinct, alphabetically sorted DAW types', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'a', dawType: 'FL Studio'),
        TestFactories.makeProject(id: 'b', dawType: 'Ableton Live'),
        TestFactories.makeProject(id: 'c', dawType: 'FL Studio'),
      ]);
      addTearDown(c.dispose);

      expect(await _readAvailableDaws(c), ['Ableton Live', 'FL Studio']);
    });

    test('includes DAWs from hidden projects — reflects the whole profile, not the filtered view', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'visible', dawType: 'Ableton Live', hidden: false),
        TestFactories.makeProject(id: 'hidden', dawType: 'Logic Pro', hidden: true),
      ]);
      addTearDown(c.dispose);

      expect(await _readAvailableDaws(c), ['Ableton Live', 'Logic Pro']);
    });

    test('ignores null and empty dawType values', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'a', dawType: 'Ableton Live'),
        TestFactories.makeProject(id: 'b', dawType: null),
        TestFactories.makeProject(id: 'c', dawType: ''),
      ]);
      addTearDown(c.dispose);

      expect(await _readAvailableDaws(c), ['Ableton Live']);
    });

    test('empty project list returns an empty DAW list', () async {
      final c = _makeContainer([]);
      addTearDown(c.dispose);

      expect(await _readAvailableDaws(c), isEmpty);
    });
  });

  group('version stacks (#94)', () {
    // Reproduces a real library that lost rows: a stack formed from a version
    // sitting directly in the scan root gets that root as its own path, and
    // the stack was on a release.
    // A real directory on disk: the bug only bites when the stack's folder
    // *exists*, since a non-existent path takes the metadata-only branch above
    // the scan-root check and is shown regardless.
    late Directory rootDir;
    late String root;

    setUp(() async {
      rootDir = await Directory.systemTemp.createTemp('stack_root_');
      root = rootDir.path;
    });

    tearDown(() async {
      if (await rootDir.exists()) await rootDir.delete(recursive: true);
    });

    ScanRoot scanRoot() => ScanRoot(
          id: 'r1',
          path: root,
          addedAt: DateTime(2025, 1, 1),
        );

    List<MusicProject> stackAtRoot() => [
          TestFactories.makeProject(
            id: 'stack',
            isVirtual: true,
            memberProjectIds: const ['v1', 'v2'],
            // dirname of a version living directly in the root *is* the root.
            filePath: root,
          ),
          TestFactories.makeProject(
            id: 'v1',
            stackId: 'stack',
            filePath: '$root/A.logicx',
          ),
          TestFactories.makeProject(
            id: 'v2',
            stackId: 'stack',
            filePath: '$root/Sub/B.logicx',
          ),
        ];

    test('shows the stack and hides its versions', () async {
      final c = _makeContainer(stackAtRoot(), roots: [scanRoot()]);
      addTearDown(c.dispose);

      expect((await _readProjects(c)).map((p) => p.id).toList(), ['stack']);
    });

    test('a stack on a release is not dropped by the scan-root check',
        () async {
      // The stack's path is the root itself, which is not *inside* the root by
      // a prefix test — so the release-protection filter used to drop it, and
      // with its versions already collapsed away the whole project vanished
      // from the dashboard.
      final c = _makeContainer(
        stackAtRoot(),
        roots: [scanRoot()],
        releases: [Release(id: 'rel', title: 'EP', trackIds: const ['stack'])],
      );
      addTearDown(c.dispose);

      expect((await _readProjects(c)).map((p) => p.id).toList(), ['stack']);
    });

    test('a real project on a release outside every root is still hidden',
        () async {
      // The exemption is for stacks only; the original rule still applies to
      // scanned files.
      final c = _makeContainer(
        [
          TestFactories.makeProject(
            id: 'outside',
            filePath: '/Elsewhere/Gone.als',
          ),
        ],
        roots: [scanRoot()],
        releases: [
          Release(id: 'rel', title: 'EP', trackIds: const ['outside']),
        ],
      );
      addTearDown(c.dispose);

      // Its file does not exist locally, so it stays visible as a
      // metadata-only entry — the branch above the root check.
      expect((await _readProjects(c)).map((p) => p.id).toList(), ['outside']);
    });

    test('work time is rolled up from the versions onto the stack', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
          id: 'stack',
          isVirtual: true,
          memberProjectIds: const ['v1', 'v2'],
          filePath: root,
        ),
        TestFactories.makeProject(
          id: 'v1',
          stackId: 'stack',
          totalWorkSeconds: 3600,
          filePath: '$root/A.logicx',
        ),
        TestFactories.makeProject(
          id: 'v2',
          stackId: 'stack',
          totalWorkSeconds: 1800,
          filePath: '$root/B.logicx',
        ),
      ], roots: [scanRoot()]);
      addTearDown(c.dispose);

      final projects = await _readProjects(c);
      expect(projects.single.totalWorkSeconds, 5400);
    });
  });
}
