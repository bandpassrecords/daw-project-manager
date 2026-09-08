import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/scan_mode.dart';
import 'package:daw_project_manager/models/scan_root.dart';
import 'package:daw_project_manager/repository/project_repository.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// Version stacking (#94), automatic folder grouping.
///
/// A root in [ScanMode.versionStack] turns every project folder into one song.
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
