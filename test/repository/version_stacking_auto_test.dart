import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/models/scan_mode.dart';
import 'package:daw_project_manager/models/scan_root.dart';
import 'package:daw_project_manager/repository/project_repository.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// Version stacking (#94), automatic folder grouping.
///
/// A root in [ScanMode.versionStack] turns every project folder into one
/// main project.
/// The rules that matter here are the destructive ones: auto-stacking may only
/// ever *add*, and must never undo, re-parent or dissolve something the user
/// arranged by hand.
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

  String path(List<String> parts) => parts.join(Platform.pathSeparator);

  final rootPath = path(['Music', 'Projects']);

  Future<void> addRoot({required ScanMode mode}) async {
    await repo.rootsBox.put(
      'root-1',
      ScanRoot(
        id: 'root-1',
        path: rootPath,
        addedAt: DateTime(2025, 1, 1),
        scanDepth: mode == ScanMode.smartFolder ? 1 : 0,
        autoStackVersions: mode == ScanMode.versionStack,
      ),
    );
  }

  Future<MusicProject> addProject({
    required String id,
    required String filePath,
    DateTime? createdAt,
    bool hidden = false,
  }) async {
    final project = TestFactories.makeProject(
      id: id,
      filePath: filePath,
      fileName: filePath.split(Platform.pathSeparator).last,
      createdAt: createdAt,
      hidden: hidden,
    );
    await repo.projectsBox.put(id, project);
    return project;
  }

  group('ScanRoot.scanMode', () {
    test('derives all three modes from the stored fields', () {
      ScanRoot root({int depth = 0, bool stack = false}) => ScanRoot(
        id: 'r',
        path: rootPath,
        addedAt: DateTime(2025, 1, 1),
        scanDepth: depth,
        autoStackVersions: stack,
      );

      expect(root().scanMode, ScanMode.flat);
      expect(root(depth: 1).scanMode, ScanMode.smartFolder);
      expect(root(stack: true).scanMode, ScanMode.versionStack);
    });

    test('a root stored at the retired depth 2 still reads as Smart Folder',
        () {
      // Depth 2 was a real stored value before Smart Folder replaced it.
      // Auto-stacking rewrites the library, so it must not be something an
      // old stored depth can switch on by itself.
      final legacy = ScanRoot(
        id: 'r',
        path: rootPath,
        addedAt: DateTime(2025, 1, 1),
        scanDepth: 2,
      );

      expect(legacy.autoStackVersions, isFalse);
      expect(legacy.scanMode, ScanMode.smartFolder);
    });

    test('survives an adapter round-trip', () async {
      await addRoot(mode: ScanMode.versionStack);
      await repo.rootsBox.close();
      repo = await HiveTestHelper.createRepository();

      expect(repo.rootsBox.get('root-1')!.scanMode, ScanMode.versionStack);
    });
  });

  group('updateRootScanMode', () {
    test('writes both fields so the derived mode cannot disagree', () async {
      await addRoot(mode: ScanMode.smartFolder);

      await repo.updateRootScanMode('root-1', ScanMode.versionStack);
      var root = repo.rootsBox.get('root-1')!;
      expect(root.scanMode, ScanMode.versionStack);
      expect(root.autoStackVersions, isTrue);
      // Version stacking groups by immediate parent, so it wants the
      // recursive walk depth 0 gives — not Smart Folder's depth 1.
      expect(root.scanDepth, 0);

      await repo.updateRootScanMode('root-1', ScanMode.smartFolder);
      root = repo.rootsBox.get('root-1')!;
      expect(root.scanMode, ScanMode.smartFolder);
      expect(root.autoStackVersions, isFalse);
      expect(root.scanDepth, 1);
    });

    test('turning the mode off leaves existing stacks alone', () async {
      await addRoot(mode: ScanMode.versionStack);
      await addProject(id: 'v1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'SongA', 'A2.als']));
      await repo.autoStackFolders();

      await repo.updateRootScanMode('root-1', ScanMode.flat);

      // The stack holds notes, todos and work time the user accumulated.
      // Dissolving it because a display setting flipped would throw that away.
      expect(repo.projectsBox.values.where((p) => p.isVirtual), hasLength(1));
      expect(repo.projectsBox.get('v1')!.isStackMember, isTrue);
    });
  });

  group('planAutoStack', () {
    test('describes each folder it would group, without writing', () async {
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'a2', filePath: path([rootPath, 'SongA', 'A2.als']));
      await addProject(id: 'b1', filePath: path([rootPath, 'SongB', 'B1.als']));
      await addProject(id: 'b2', filePath: path([rootPath, 'SongB', 'B2.als']));

      final plan = repo.planAutoStack([rootPath]);

      expect(plan, hasLength(2));
      expect(plan.every((e) => e.createsNewStack), isTrue);
      expect(plan.map((e) => e.resultingVersionCount).toList(), [2, 2]);
      // Nothing written: the point is to show the user first.
      expect(repo.projectsBox.values.where((p) => p.isVirtual), isEmpty);
      expect(repo.projectsBox.get('a1')!.isStackMember, isFalse);
    });

    test('is empty when there is nothing to group', () async {
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'loose', filePath: path([rootPath, 'Loose.als']));

      // The settings switch skips the confirmation entirely in this case.
      expect(repo.planAutoStack([rootPath]), isEmpty);
    });

    test('marks a folder that would join an existing main project', () async {
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'a2', filePath: path([rootPath, 'SongA', 'A2.als']));
      await repo.stackProjects(memberIds: ['a1', 'a2']);
      await addProject(id: 'a3', filePath: path([rootPath, 'SongA', 'A3.als']));

      final plan = repo.planAutoStack([rootPath]);

      expect(plan, hasLength(1));
      expect(plan.single.createsNewStack, isFalse);
      expect(plan.single.projects.map((p) => p.id).toList(), ['a3']);
      // Two already stacked plus the newcomer.
      expect(plan.single.resultingVersionCount, 3);
    });

    test('matches what applying it actually does', () async {
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'a2', filePath: path([rootPath, 'SongA', 'A2.als']));
      await addProject(id: 'b1', filePath: path([rootPath, 'SongB', 'B1.als']));
      await addProject(id: 'b2', filePath: path([rootPath, 'SongB', 'B2.als']));

      final plan = repo.planAutoStack([rootPath]);
      final created = await repo.applyAutoStackPlan(plan);

      // What the dialog promised is what happened.
      expect(created, plan.where((e) => e.createsNewStack).length);
      expect(
        repo.projectsBox.values.where((p) => p.isVirtual).length,
        plan.length,
      );
    });

    test('excludes root-level files and hidden projects', () async {
      await addProject(id: 'loose', filePath: path([rootPath, 'Loose.als']));
      await addProject(id: 'x', filePath: path([rootPath, 'Other.als']));
      await addProject(id: 'h1', filePath: path([rootPath, 'H', 'H1.als']));
      await addProject(
        id: 'h2',
        filePath: path([rootPath, 'H', 'H2.als']),
        hidden: true,
      );

      expect(repo.planAutoStack([rootPath]), isEmpty);
    });
  });

  group('releases', () {
    Future<void> addRelease(String id, List<String> trackIds) =>
        repo.releasesBox.put(
          id,
          Release(id: id, title: 'EP $id', trackIds: trackIds),
        );

    test('unstacking hands the release slot to the chosen version', () async {
      await addProject(id: 'v1', filePath: path([rootPath, 'A', 'v1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'A', 'v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);
      await addRelease('r1', ['other', stack.id, 'another']);

      await repo.unstack(stack.id, releaseSuccessorId: 'v2');

      // The release page skips ids it can't resolve, so leaving the dead stack
      // id here would drop the track silently and strand the id forever.
      expect(repo.releasesBox.get('r1')!.trackIds, ['other', 'v2', 'another']);
    });

    test('falls back to the default-launch version when not told', () async {
      await addProject(id: 'v1', filePath: path([rootPath, 'A', 'v1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'A', 'v2.als']));
      final stack = await repo.stackProjects(
        memberIds: ['v1', 'v2'],
        metadataSourceId: 'v2',
      );
      await addRelease('r1', [stack.id]);

      // The automatic path (removeFromStack dissolving a stack) passes no
      // successor, and must still not lose the track.
      await repo.unstack(stack.id);

      expect(repo.releasesBox.get('r1')!.trackIds, ['v2']);
    });

    test('dissolving via removeFromStack keeps the release track', () async {
      await addProject(id: 'v1', filePath: path([rootPath, 'A', 'v1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'A', 'v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);
      await addRelease('r1', [stack.id]);

      await repo.removeFromStack('v2');

      final trackIds = repo.releasesBox.get('r1')!.trackIds;
      expect(trackIds, hasLength(1));
      expect(trackIds.single, isNot(stack.id));
      expect(repo.projectsBox.get(trackIds.single), isNotNull);
    });

    test('does not duplicate a version already on the release', () async {
      await addProject(id: 'v1', filePath: path([rootPath, 'A', 'v1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'A', 'v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);
      await addRelease('r1', ['v2', stack.id]);

      await repo.unstack(stack.id, releaseSuccessorId: 'v2');

      expect(repo.releasesBox.get('r1')!.trackIds, ['v2']);
    });

    test('updates every release the stack appears on', () async {
      await addProject(id: 'v1', filePath: path([rootPath, 'A', 'v1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'A', 'v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);
      await addRelease('r1', [stack.id]);
      await addRelease('r2', ['x', stack.id]);

      await repo.unstack(stack.id, releaseSuccessorId: 'v1');

      expect(repo.releasesBox.get('r1')!.trackIds, ['v1']);
      expect(repo.releasesBox.get('r2')!.trackIds, ['x', 'v1']);
    });

    test('a stack on no release unstacks without touching any', () async {
      await addProject(id: 'v1', filePath: path([rootPath, 'A', 'v1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'A', 'v2.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);
      await addRelease('r1', ['unrelated']);

      await repo.unstack(stack.id);

      expect(repo.releasesBox.get('r1')!.trackIds, ['unrelated']);
    });

    test('releasesContaining finds the releases holding a project', () async {
      await addRelease('r1', ['p1']);
      await addRelease('r2', ['p2']);
      await addRelease('r3', ['p1', 'p2']);

      expect(
        repo.releasesContaining('p1').map((r) => r.id).toList(),
        ['r1', 'r3'],
      );
      expect(repo.releasesContaining('nobody'), isEmpty);
    });
  });

  group('addToStack', () {
    test('refuses a project that already belongs to another stack', () async {
      await addProject(id: 'v1', filePath: path([rootPath, 'A', 'v1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'A', 'v2.als']));
      await addProject(id: 'w1', filePath: path([rootPath, 'B', 'w1.als']));
      await addProject(id: 'w2', filePath: path([rootPath, 'B', 'w2.als']));
      final first = await repo.stackProjects(memberIds: ['v1', 'v2']);
      final second = await repo.stackProjects(memberIds: ['w1', 'w2']);

      await repo.addToStack(stackId: second.id, projectId: 'v1');

      // Re-parenting silently would flip v1's stackId while leaving it listed
      // on the first stack, so its work time would be counted by both.
      expect(repo.projectsBox.get('v1')!.stackId, first.id);
      expect(
        repo.projectsBox.get(second.id)!.memberProjectIds,
        isNot(contains('v1')),
      );
      expect(
        repo.projectsBox.get(first.id)!.memberProjectIds,
        contains('v1'),
      );
    });

    test('still accepts a standalone project', () async {
      await addProject(id: 'v1', filePath: path([rootPath, 'A', 'v1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'A', 'v2.als']));
      await addProject(id: 'v3', filePath: path([rootPath, 'A', 'v3.als']));
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      await repo.addToStack(stackId: stack.id, projectId: 'v3');

      expect(repo.projectsBox.get('v3')!.stackId, stack.id);
    });
  });

  group('stack naming', () {
    test('the stack takes the promoted project name, not the folder name',
        () async {
      await addProject(
        id: 'v1',
        filePath: path([rootPath, 'Bounces', 'Midnight Drive v1.als']),
      );
      await addProject(
        id: 'v2',
        filePath: path([rootPath, 'Bounces', 'Midnight Drive v2.als']),
      );

      final stack = await repo.stackProjects(
        memberIds: ['v1', 'v2'],
        metadataSourceId: 'v1',
      );

      // Naming it for the folder put the main project under a name the user
      // never chose — and "Bounces" is a folder name shared by every song.
      expect(stack.displayName, 'Midnight Drive v1');
    });

    test('a renamed project keeps its custom name on the stack', () async {
      await repo.projectsBox.put(
        'v1',
        TestFactories.makeProject(
          id: 'v1',
          filePath: path([rootPath, 'SongA', 'A1.als']),
          customDisplayName: 'Midnight Drive',
        ),
      );
      await addProject(id: 'v2', filePath: path([rootPath, 'SongA', 'A2.als']));

      final stack = await repo.stackProjects(
        memberIds: ['v1', 'v2'],
        metadataSourceId: 'v1',
      );

      expect(stack.displayName, 'Midnight Drive');
    });

    test('the name follows whichever project is promoted', () async {
      await addProject(
        id: 'v1',
        filePath: path([rootPath, 'SongA', 'Rough take.als']),
      );
      await addProject(
        id: 'v2',
        filePath: path([rootPath, 'SongA', 'Final master.als']),
      );

      final stack = await repo.stackProjects(
        memberIds: ['v1', 'v2'],
        metadataSourceId: 'v2',
      );

      expect(stack.displayName, 'Final master');
    });

    test('the stack still points at the folder for grouping', () async {
      await addProject(id: 'v1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'v2', filePath: path([rootPath, 'SongA', 'A2.als']));

      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      // Naming comes off the project; the path still has to be the folder, or
      // anything grouping by directory puts the stack in the wrong bucket.
      expect(stack.filePath, path([rootPath, 'SongA']));
    });
  });

  group('autoStackFolders', () {
    test('makes one stack per folder holding several project files', () async {
      await addRoot(mode: ScanMode.versionStack);
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'a2', filePath: path([rootPath, 'SongA', 'A2.als']));
      await addProject(id: 'b1', filePath: path([rootPath, 'SongB', 'B1.als']));
      await addProject(id: 'b2', filePath: path([rootPath, 'SongB', 'B2.als']));

      expect(await repo.autoStackFolders(), 2);

      final stacks = repo.projectsBox.values.where((p) => p.isVirtual).toList();
      expect(stacks, hasLength(2));
      expect(
        stacks.map((s) => s.memberProjectIds.length).toList(),
        everyElement(2),
      );
    });

    test('a folder with a single project file is left alone', () async {
      await addRoot(mode: ScanMode.versionStack);
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));

      expect(await repo.autoStackFolders(), 0);
      expect(repo.projectsBox.get('a1')!.isStackMember, isFalse);
    });

    test('does nothing for roots in the other two modes', () async {
      await addRoot(mode: ScanMode.smartFolder);
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'a2', filePath: path([rootPath, 'SongA', 'A2.als']));

      expect(await repo.autoStackFolders(), 0);
      expect(repo.projectsBox.values.where((p) => p.isVirtual), isEmpty);
    });

    test('a newly scanned file joins the folder stack instead of starting '
        'a rival one', () async {
      await addRoot(mode: ScanMode.versionStack);
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'a2', filePath: path([rootPath, 'SongA', 'A2.als']));
      await repo.autoStackFolders();
      final stackId =
          repo.projectsBox.values.firstWhere((p) => p.isVirtual).id;

      // The user saves a v3 and rescans.
      await addProject(id: 'a3', filePath: path([rootPath, 'SongA', 'A3.als']));
      expect(await repo.autoStackFolders(), 0);

      expect(repo.projectsBox.values.where((p) => p.isVirtual), hasLength(1));
      expect(repo.projectsBox.get('a3')!.stackId, stackId);
      expect(
        repo.projectsBox.get(stackId)!.memberProjectIds,
        containsAll(['a1', 'a2', 'a3']),
      );
    });

    test('a rerun is a no-op rather than restacking everything', () async {
      await addRoot(mode: ScanMode.versionStack);
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'a2', filePath: path([rootPath, 'SongA', 'A2.als']));

      expect(await repo.autoStackFolders(), 1);
      expect(await repo.autoStackFolders(), 0);
      expect(repo.projectsBox.values.where((p) => p.isVirtual), hasLength(1));
    });

    test('a hand-made stack spanning two folders survives a rescan', () async {
      await addRoot(mode: ScanMode.versionStack);
      // The user stacked two files that live in different folders — something
      // folder grouping would never produce on its own.
      await addProject(id: 'x1', filePath: path([rootPath, 'Alt', 'X1.als']));
      await addProject(id: 'x2', filePath: path([rootPath, 'Takes', 'X2.als']));
      final manual = await repo.stackProjects(memberIds: ['x1', 'x2']);

      await repo.autoStackFolders();

      final reloaded = repo.projectsBox.get(manual.id)!;
      expect(reloaded.memberProjectIds, ['x1', 'x2']);
      expect(repo.projectsBox.get('x1')!.stackId, manual.id);
      expect(repo.projectsBox.get('x2')!.stackId, manual.id);
    });

    test('projects outside every stacking root are untouched', () async {
      await addRoot(mode: ScanMode.versionStack);
      await addProject(
        id: 'o1',
        filePath: path(['Elsewhere', 'SongZ', 'Z1.als']),
      );
      await addProject(
        id: 'o2',
        filePath: path(['Elsewhere', 'SongZ', 'Z2.als']),
      );

      expect(await repo.autoStackFolders(), 0);
      expect(repo.projectsBox.get('o1')!.isStackMember, isFalse);
    });

    test('files sitting directly in the scan root are left alone', () async {
      await addRoot(mode: ScanMode.versionStack);
      // Unfiled projects share the root as their "folder". Stacking them
      // would fuse every loose project in the library into one row.
      await addProject(id: 'a', filePath: path([rootPath, 'SongA.als']));
      await addProject(id: 'b', filePath: path([rootPath, 'SongB.als']));
      await addProject(id: 'c', filePath: path([rootPath, 'SongC.als']));

      expect(await repo.autoStackFolders(), 0);
      expect(repo.projectsBox.values.where((p) => p.isVirtual), isEmpty);
      expect(repo.projectsBox.get('a')!.isStackMember, isFalse);
    });

    test('root-level files stay loose while subfolders still stack', () async {
      await addRoot(mode: ScanMode.versionStack);
      await addProject(id: 'loose', filePath: path([rootPath, 'Loose.als']));
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'a2', filePath: path([rootPath, 'SongA', 'A2.als']));

      expect(await repo.autoStackFolders(), 1);
      expect(repo.projectsBox.get('loose')!.isStackMember, isFalse);
      expect(repo.projectsBox.get('a1')!.isStackMember, isTrue);
    });

    test('hidden projects are not pulled into a stack', () async {
      await addRoot(mode: ScanMode.versionStack);
      await addProject(id: 'a1', filePath: path([rootPath, 'SongA', 'A1.als']));
      await addProject(id: 'a2', filePath: path([rootPath, 'SongA', 'A2.als']));
      await addProject(
        id: 'a3',
        filePath: path([rootPath, 'SongA', 'A3.als']),
        hidden: true,
      );

      await repo.autoStackFolders();

      expect(repo.projectsBox.get('a3')!.isStackMember, isFalse);
    });
  });
}
