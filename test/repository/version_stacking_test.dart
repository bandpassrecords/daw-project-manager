import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/utils/cover_art_refs.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// Version stacking (#94), foundation layer.
///
/// A stack is a *virtual* project: a row owning the shared metadata for several
/// version files of one song, with no file of its own. These cover the parts
/// that lose user data when they are wrong — member links surviving deletion,
/// work time aggregating instead of being stored, and unstacking handing back
/// metadata rather than dropping it.
void main() {
  late Directory tempDir;
  late ProjectRepository repo;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    repo = await HiveTestHelper.createRepository();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  Future<MusicProject> addProject({
    required String id,
    required String filePath,
    DateTime? createdAt,
    int totalWorkSeconds = 0,
    List<SessionRecord> sessions = const [],
    String? notes,
    String? thumbnailPath,
  }) async {
    final project = TestFactories.makeProject(
      id: id,
      filePath: filePath,
      fileName: filePath.split(Platform.pathSeparator).last,
      createdAt: createdAt,
      totalWorkSeconds: totalWorkSeconds,
      sessions: sessions,
      notes: notes,
      thumbnailPath: thumbnailPath,
    );
    await repo.projectsBox.put(id, project);
    return project;
  }

  String path(List<String> parts) => parts.join(Platform.pathSeparator);

  group('stackProjects', () {
    test('creates a virtual project holding the members', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'SongA', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'SongA', 'A v2.als']));

      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      expect(stack.isVirtual, isTrue);
      expect(stack.memberProjectIds, ['v1', 'v2']);
      expect(stack.versionCount, 2);
      expect(repo.projectsBox.get('v1')!.stackId, stack.id);
      expect(repo.projectsBox.get('v2')!.stackId, stack.id);
    });

    test('promotes the oldest member metadata by default', () async {
      await addProject(
        id: 'older',
        filePath: path(['Music', 'SongA', 'A v1.als']),
        createdAt: DateTime(2024, 1, 1),
        notes: 'the notes worth keeping',
      );
      await addProject(
        id: 'newer',
        filePath: path(['Music', 'SongA', 'A v2.als']),
        createdAt: DateTime(2025, 1, 1),
        notes: 'scratch',
      );

      final stack = await repo.stackProjects(memberIds: ['newer', 'older']);

      expect(stack.notes, 'the notes worth keeping');
    });

    test('promotes an explicitly chosen member instead', () async {
      await addProject(
        id: 'a',
        filePath: path(['Music', 'SongA', 'A v1.als']),
        createdAt: DateTime(2024, 1, 1),
        notes: 'old',
      );
      await addProject(
        id: 'b',
        filePath: path(['Music', 'SongA', 'A v2.als']),
        createdAt: DateTime(2025, 1, 1),
        notes: 'chosen',
      );

      final stack = await repo.stackProjects(
        memberIds: ['a', 'b'],
        metadataSourceId: 'b',
      );

      expect(stack.notes, 'chosen');
    });

    test('leaves member metadata intact so unstacking can restore it', () async {
      await addProject(
        id: 'v1',
        filePath: path(['Music', 'SongA', 'A v1.als']),
        notes: 'v1 notes',
      );
      await addProject(
        id: 'v2',
        filePath: path(['Music', 'SongA', 'A v2.als']),
        notes: 'v2 notes',
      );

      await repo.stackProjects(memberIds: ['v1', 'v2']);

      expect(repo.projectsBox.get('v1')!.notes, 'v1 notes');
      expect(repo.projectsBox.get('v2')!.notes, 'v2 notes');
    });

    test('refuses fewer than two versions', () async {
      await addProject(id: 'only', filePath: path(['Music', 'A.als']));
      expect(
        () => repo.stackProjects(memberIds: ['only']),
        throwsArgumentError,
      );
    });

    test('refuses a project that is already stacked', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      await addProject(id: 'v3', filePath: path(['Music', 'A v3.als']));
      await repo.stackProjects(memberIds: ['v1', 'v2']);

      expect(
        () => repo.stackProjects(memberIds: ['v2', 'v3']),
        throwsArgumentError,
      );
    });
  });

  group('work time aggregation', () {
    test('sums the members rather than storing a total', () async {
      await addProject(
        id: 'v1',
        filePath: path(['Music', 'A v1.als']),
        totalWorkSeconds: 600,
      );
      await addProject(
        id: 'v2',
        filePath: path(['Music', 'A v2.als']),
        totalWorkSeconds: 1800,
      );

      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      expect(repo.stackTotalWorkSeconds(stack), 2400);
      // Nothing is cached on the stack itself — a stored copy would drift.
      expect(repo.projectsBox.get(stack.id)!.totalWorkSeconds, 0);
    });

    test('picks up later member time without touching the stack', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      await repo.projectsBox.put(
        'v1',
        repo.projectsBox.get('v1')!.copyWith(totalWorkSeconds: 900),
      );

      expect(repo.stackTotalWorkSeconds(stack), 900);
    });

    test('merges member sessions in chronological order', () async {
      SessionRecord session(DateTime at) => SessionRecord(
        id: at.toIso8601String(),
        startedAt: at,
        endedAt: at.add(const Duration(minutes: 10)),
        durationSeconds: 600,
      );

      await addProject(
        id: 'v1',
        filePath: path(['Music', 'A v1.als']),
        sessions: [session(DateTime(2025, 3, 1))],
      );
      await addProject(
        id: 'v2',
        filePath: path(['Music', 'A v2.als']),
        sessions: [session(DateTime(2025, 1, 1))],
      );

      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);
      final merged = repo.stackSessions(stack);

      expect(merged, hasLength(2));
      expect(merged.first.startedAt, DateTime(2025, 1, 1));
    });
  });

  group('unstack', () {
    test('returns members to standalone projects with metadata intact', () async {
      await addProject(
        id: 'v1',
        filePath: path(['Music', 'A v1.als']),
        notes: 'v1 notes',
      );
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      await repo.unstack(stack.id);

      expect(repo.projectsBox.get(stack.id), isNull);
      expect(repo.projectsBox.get('v1')!.stackId, isNull);
      expect(repo.projectsBox.get('v1')!.notes, 'v1 notes');
      expect(repo.projectsBox.get('v2')!.stackId, isNull);
    });
  });

  group('membership changes', () {
    test('a newly scanned version joins an existing stack', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      await addProject(id: 'v3', filePath: path(['Music', 'A v3.als']));
      await repo.addToStack(stackId: stack.id, projectId: 'v3');

      expect(
        repo.projectsBox.get(stack.id)!.memberProjectIds,
        ['v1', 'v2', 'v3'],
      );
      expect(repo.projectsBox.get('v3')!.stackId, stack.id);
    });

    test('removing down to one version dissolves the stack', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      await repo.removeFromStack('v2');

      expect(repo.projectsBox.get(stack.id), isNull);
      expect(repo.projectsBox.get('v1')!.stackId, isNull);
    });

    test('removing the default launch member renominates another', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      await addProject(id: 'v3', filePath: path(['Music', 'A v3.als']));
      final stack = await repo.stackProjects(
        memberIds: ['v1', 'v2', 'v3'],
        metadataSourceId: 'v1',
      );
      expect(stack.defaultLaunchMemberId, 'v1');

      await repo.removeFromStack('v1');

      final updated = repo.projectsBox.get(stack.id)!;
      expect(updated.memberProjectIds, ['v2', 'v3']);
      expect(updated.defaultLaunchMemberId, 'v2');
    });
  });

  group('deletion safety', () {
    test('a stack is not a candidate for the missing-file check', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      // Its synthesized path is a folder that need not exist, so without this
      // guard "Delete Missing" would delete the row holding the song's notes,
      // todos and work history.
      expect(stack.isMissingFileCandidate, isFalse);
      expect(repo.projectsBox.get('v1')!.isMissingFileCandidate, isTrue);
    });

    test('deleting members prunes the stack', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      await addProject(id: 'v3', filePath: path(['Music', 'A v3.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2', 'v3']);

      await repo.deleteProjectsPermanently(['v3']);

      expect(repo.projectsBox.get(stack.id)!.memberProjectIds, ['v1', 'v2']);
    });

    test('deleting down to one version dissolves the stack', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      await repo.deleteProjectsPermanently(['v2']);

      expect(repo.projectsBox.get(stack.id), isNull);
      expect(repo.projectsBox.get('v1')!.stackId, isNull);
    });

    test('deleting a stack clears its members stackId', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      await repo.deleteProjectsPermanently([stack.id]);

      expect(repo.projectsBox.get('v1')!.stackId, isNull);
      expect(repo.projectsBox.get('v2')!.stackId, isNull);
    });
  });

  group('groupByImmediateFolder', () {
    test('groups by the parent directory, not the smart-folder root', () async {
      // Root/1-Active/SongA/... and Root/1-Active/SongB/... share a
      // smart-folder key ("1-Active") but are different songs. Grouping on
      // that key would stack every song in the folder into one entry.
      final a1 = TestFactories.makeProject(
        id: 'a1',
        filePath: path(['Root', '1-Active', 'SongA', 'A v1.als']),
      );
      final a2 = TestFactories.makeProject(
        id: 'a2',
        filePath: path(['Root', '1-Active', 'SongA', 'A v2.als']),
      );
      final b1 = TestFactories.makeProject(
        id: 'b1',
        filePath: path(['Root', '1-Active', 'SongB', 'B v1.als']),
      );

      final groups = ProjectRepository.groupByImmediateFolder([a1, a2, b1]);

      expect(groups, hasLength(2));
      expect(
        groups[path(['Root', '1-Active', 'SongA'])]!.map((p) => p.id),
        ['a1', 'a2'],
      );
      expect(
        groups[path(['Root', '1-Active', 'SongB'])]!.map((p) => p.id),
        ['b1'],
      );
    });

    test('skips projects that are already stacked', () async {
      final loose = TestFactories.makeProject(
        id: 'loose',
        filePath: path(['Root', 'SongA', 'A v1.als']),
      );
      final stacked = TestFactories.makeProject(
        id: 'stacked',
        filePath: path(['Root', 'SongA', 'A v2.als']),
        stackId: 'some-stack',
      );
      final stack = TestFactories.makeProject(
        id: 'some-stack',
        filePath: path(['Root', 'SongA']),
        isVirtual: true,
        memberProjectIds: const ['stacked'],
      );

      final groups = ProjectRepository.groupByImmediateFolder([
        loose,
        stacked,
        stack,
      ]);

      expect(groups[path(['Root', 'SongA'])]!.map((p) => p.id), ['loose']);
    });
  });

  group('persistence', () {
    test('stack fields survive an adapter round-trip', () async {
      await addProject(id: 'v1', filePath: path(['Music', 'A v1.als']));
      await addProject(id: 'v2', filePath: path(['Music', 'A v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      // Re-read through the box, which goes through MusicProjectAdapter.
      final reloaded = repo.projectsBox.get(stack.id)!;

      expect(reloaded.isVirtual, isTrue);
      expect(reloaded.memberProjectIds, ['v1', 'v2']);
      expect(reloaded.defaultLaunchMemberId, isNotNull);
      expect(repo.projectsBox.get('v1')!.stackId, stack.id);
    });

    test('projects written before stacking existed read back unstacked', () {
      // Boxes predating #94 have no field 33-36 at all; the adapter defaults
      // must not turn every existing project into a stack.
      final legacy = TestFactories.makeProject(id: 'legacy');

      expect(legacy.isVirtual, isFalse);
      expect(legacy.memberProjectIds, isEmpty);
      expect(legacy.stackId, isNull);
      expect(legacy.isStackMember, isFalse);
    });
  });

  group('cover art', () {
    test('automatic stacking promotes the version that has a cover', () async {
      // No metadataSourceId, as for folder auto-stacking: a blank older
      // version must not win and bury the newer one's cover.
      await addProject(
        id: 'v1',
        filePath: path(['Music', 'SongA', 'A v1.als']),
        createdAt: DateTime(2025, 1, 1),
      );
      await addProject(
        id: 'v2',
        filePath: path(['Music', 'SongA', 'A v2.als']),
        createdAt: DateTime(2025, 2, 1),
        thumbnailPath: path(['art', 'v2.png']),
      );

      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      expect(stack.thumbnailPath, path(['art', 'v2.png']));
    });

    test('a stack shares its main version\'s cover file, so changing the '
        "stack's cover must not delete it", () async {
      final shared = path(['art', 'shared.png']);
      await addProject(
        id: 'v1',
        filePath: path(['Music', 'SongA', 'A v1.als']),
        thumbnailPath: shared,
      );
      await addProject(id: 'v2', filePath: path(['Music', 'SongA', 'A v2.als']));
      final stack = await repo.stackProjects(
        memberIds: ['v1', 'v2'],
        metadataSourceId: 'v1',
      );
      expect(stack.thumbnailPath, shared);

      // What the appearance editor does when the stack gets a new cover:
      // save the stack, then ask whether the old file may be deleted.
      await repo.updateProject(
        stack.copyWith(thumbnailPath: path(['art', 'new.png'])),
      );

      expect(
        isImageInUse(
          shared,
          projects: repo.projectsBox.values,
          releases: repo.releasesBox.values,
        ),
        isTrue,
        reason: 'v1 still points at it and gets it back on unstack',
      );
    });
  });
}
