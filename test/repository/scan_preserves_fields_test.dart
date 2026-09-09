import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/repository/project_repository.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// A rescan must not destroy anything the user put on a project.
///
/// The scanner used to rebuild each project from scratch and re-list every
/// field worth keeping, so a field added to the model later was wiped by the
/// next scan unless someone remembered to add it to that list. Several were
/// missed: song parts, thumbnails, the source-template link, the
/// ignored-newer-song path, and every version-stacking link — which is how a
/// stacked project came apart on its own, leaving a stack row whose members
/// no longer pointed back at it.
void main() {
  late Directory tempDir;
  late Directory projectDir;
  late ProjectRepository repo;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    repo = await HiveTestHelper.createRepository();
    projectDir = await Directory.systemTemp.createTemp('scan_preserve_');
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
    if (await projectDir.exists()) await projectDir.delete(recursive: true);
  });

  /// Writes a real file and scans it, so the project has a path that resolves.
  Future<MusicProject> scanNewProject(String name) async {
    final file = File('${projectDir.path}/$name.als');
    await file.writeAsString('x');
    await repo.upsertFromFileSystemEntity(file);
    return repo.getByPath(file.path)!;
  }

  Future<MusicProject> rescan(MusicProject project) async {
    await repo.upsertFromFileSystemEntity(File(project.filePath));
    return repo.getById(project.id)!;
  }

  test('a rescan keeps song parts', () async {
    final project = await scanNewProject('parts');
    await repo.updateProject(
      project.copyWith(
        parts: [
          const ProjectPart(id: 'p1', name: 'Bass'),
        ],
      ),
    );

    final after = await rescan(project);

    expect(after.parts, hasLength(1));
    expect(after.parts.single.name, 'Bass');
  });

  test('a rescan keeps the thumbnail, template link and ignored song',
      () async {
    final project = await scanNewProject('misc');
    await repo.updateProject(
      project.copyWith(
        thumbnailPath: '/covers/art.png',
        sourceTemplateId: 'template-7',
        ignoredNewerSongPath: '/bounces/rejected.wav',
      ),
    );

    final after = await rescan(project);

    expect(after.thumbnailPath, '/covers/art.png');
    expect(after.sourceTemplateId, 'template-7');
    expect(after.ignoredNewerSongPath, '/bounces/rejected.wav');
  });

  test('a rescan keeps version stacking links intact', () async {
    // The bug behind a stack coming apart on its own: the scan dropped
    // stackId from each version, so nothing collapsed under the stack row.
    final v1 = await scanNewProject('v1');
    final v2 = await scanNewProject('v2');
    final stack = await repo.stackProjects(memberIds: [v1.id, v2.id]);

    final afterV1 = await rescan(v1);
    final afterV2 = await rescan(v2);

    expect(afterV1.stackId, stack.id);
    expect(afterV2.stackId, stack.id);
    expect(repo.projectsBox.get(stack.id)!.memberProjectIds, [v1.id, v2.id]);
    expect(repo.stackMembers(repo.projectsBox.get(stack.id)!), hasLength(2));
  });

  test('a rescan still updates what the filesystem knows', () async {
    final project = await scanNewProject('updated');
    await File(project.filePath).writeAsString('much longer contents');

    final after = await rescan(project);

    // Preserving must not mean ignoring the file.
    expect(after.fileSizeBytes, greaterThan(project.fileSizeBytes));
  });

  test('a rescan keeps user metadata, as it always did', () async {
    final project = await scanNewProject('meta');
    await repo.updateProject(
      project.copyWith(
        customDisplayName: 'Renamed',
        notes: 'chorus needs work',
        status: 'Mixing',
        deadline: DateTime(2026, 5, 1),
        totalWorkSeconds: 3600,
      ),
    );

    final after = await rescan(project);

    expect(after.customDisplayName, 'Renamed');
    expect(after.notes, 'chorus needs work');
    expect(after.status, 'Mixing');
    expect(after.deadline, DateTime(2026, 5, 1));
    expect(after.totalWorkSeconds, 3600);
  });

  test('a brand-new project is created with scanned values', () async {
    final project = await scanNewProject('fresh');

    expect(project.status, 'Idea');
    expect(project.isVirtual, isFalse);
    expect(project.stackId, isNull);
    expect(project.parts, isEmpty);
    expect(project.fileExtension, '.als');
  });

  group('cleanUpDanglingStackLinks repairs an already-broken library', () {
    test('re-links versions whose stackId was wiped by an old scan', () async {
      final v1 = await scanNewProject('r1');
      final v2 = await scanNewProject('r2');
      final stack = await repo.stackProjects(memberIds: [v1.id, v2.id]);
      // Reproduce the damage an older build left behind: the stack still
      // lists both versions, but neither points back at it.
      await repo.projectsBox.put(v1.id, v1.copyWith(clearStackId: true));
      await repo.projectsBox.put(v2.id, v2.copyWith(clearStackId: true));

      await repo.cleanUpDanglingStackLinks();

      expect(repo.projectsBox.get(v1.id)!.stackId, stack.id);
      expect(repo.projectsBox.get(v2.id)!.stackId, stack.id);
      expect(repo.projectsBox.get(stack.id), isNotNull);
    });

    test('does not steal a version that now belongs to another stack',
        () async {
      final v1 = await scanNewProject('s1');
      final v2 = await scanNewProject('s2');
      final w1 = await scanNewProject('s3');
      final w2 = await scanNewProject('s4');
      final first = await repo.stackProjects(memberIds: [v1.id, v2.id]);
      final second = await repo.stackProjects(memberIds: [w1.id, w2.id]);
      // The first stack still claims v1, but v1 has moved to the second.
      await repo.projectsBox.put(
        v1.id,
        repo.projectsBox.get(v1.id)!.copyWith(stackId: second.id),
      );

      await repo.cleanUpDanglingStackLinks();

      expect(repo.projectsBox.get(v1.id)!.stackId, second.id);
      // The first stack is left with one version, so it dissolves.
      expect(repo.projectsBox.get(first.id), isNull);
      expect(repo.projectsBox.get(v2.id)!.stackId, isNull);
    });

    test('leaves a healthy library untouched', () async {
      final v1 = await scanNewProject('h1');
      final v2 = await scanNewProject('h2');
      final stack = await repo.stackProjects(memberIds: [v1.id, v2.id]);
      final before = repo.projectsBox.get(stack.id)!.updatedAt;

      await repo.cleanUpDanglingStackLinks();

      final after = repo.projectsBox.get(stack.id)!;
      expect(after.memberProjectIds, [v1.id, v2.id]);
      expect(after.updatedAt, before);
      expect(repo.projectsBox.get(v1.id)!.stackId, stack.id);
    });
  });
}
