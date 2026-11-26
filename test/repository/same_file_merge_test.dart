import 'dart:io';

import 'package:daw_project_manager/models/playlist.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/repository/root_relocations.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// One file, one row, where rows arrive in bulk: a local backup import, and
/// what names a folded-away row afterwards.
void main() {
  late Directory tempDir;
  late ProfileRepository profiles;
  late ProjectRepository repo;
  const profileId = 'test-profile';

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    profiles = await HiveTestHelper.createProfileRepository();
    repo = await HiveTestHelper.createRepository(profileId: profileId);
  });

  tearDown(() async => HiveTestHelper.tearDown(tempDir));

  String song(String root, String name) =>
      p.join(tempDir.path, root, name, '$name.cpr');

  group('relocateRoot', () {
    test(
      'remembers where the folder was, for rows that arrive later',
      () async {
        final from = p.join(tempDir.path, 'C');
        final to = p.join(tempDir.path, 'F');
        final root = await repo.addRoot(from);
        await repo.relocateRoot(root.id, to);

        final moves = await RootRelocationStore.of(profileId);
        expect(moves.single.from, from);
        expect(moves.single.to, p.normalize(to));
      },
    );
  });

  group('absorbIncomingProjects', () {
    test('a row for a file already here is folded in, not added', () async {
      await repo.projectsBox.put(
        'here',
        TestFactories.makeProject(
          id: 'here',
          filePath: song('F', 'Meiko'),
          status: 'Idea',
        ),
      );
      final aliases = await repo.absorbIncomingProjects([
        TestFactories.makeProject(
          id: 'arriving',
          filePath: song('F', 'Meiko'),
          status: 'Finished',
          notes: 'done',
        ),
      ]);
      expect(aliases, {'arriving': 'here'});
      expect(repo.getAllProjects().map((r) => r.id), ['here']);
      expect(repo.projectsBox.get('here')!.status, 'Finished');
      expect(repo.projectsBox.get('here')!.notes, 'done');
    });

    test('a row naming a relocated folder lands at the new place', () async {
      final root = await repo.addRoot(p.join(tempDir.path, 'C'));
      await repo.relocateRoot(root.id, p.join(tempDir.path, 'F'));
      await repo.projectsBox.put(
        'moved',
        TestFactories.makeProject(id: 'moved', filePath: song('F', 'Relax')),
      );

      await repo.absorbIncomingProjects([
        TestFactories.makeProject(
          id: 'from-before-the-move',
          filePath: song('C', 'Relax'),
          notes: 'from before',
        ),
        TestFactories.makeProject(
          id: 'new-to-us',
          filePath: song('C', 'Teardrop'),
        ),
      ]);

      expect(repo.getAllProjects().map((r) => r.id).toSet(), {
        'moved',
        'new-to-us',
      });
      expect(repo.projectsBox.get('moved')!.notes, 'from before');
      expect(
        repo.projectsBox.get('new-to-us')!.filePath,
        song('F', 'Teardrop'),
      );
    });

    test('a row whose id is here still replaces it', () async {
      await repo.projectsBox.put(
        'same',
        TestFactories.makeProject(
          id: 'same',
          filePath: song('F', 'A'),
          notes: 'old',
        ),
      );
      await repo.absorbIncomingProjects([
        TestFactories.makeProject(
          id: 'same',
          filePath: song('F', 'A'),
          notes: 'restored',
        ),
      ]);
      expect(repo.projectsBox.get('same')!.notes, 'restored');
    });

    test('two arriving rows for one file become one row', () async {
      await repo.absorbIncomingProjects([
        TestFactories.makeProject(id: 'first', filePath: song('F', 'A')),
        TestFactories.makeProject(
          id: 'second',
          filePath: song('F', 'A'),
          notes: 'n',
        ),
      ]);
      expect(repo.getAllProjects().map((r) => r.id), ['first']);
      expect(repo.projectsBox.get('first')!.notes, 'n');
    });
  });

  group('repointFoldedRows', () {
    test('a release and a playlist name the kept row instead', () async {
      final now = DateTime(2026, 11, 26);
      await repo.releasesBox.put(
        'ep',
        Release(id: 'ep', title: 'EP', trackIds: ['here', 'arriving', 'other']),
      );
      await repo.playlistsBox.put(
        'pl',
        Playlist(
          id: 'pl',
          name: 'Set',
          projectIds: ['arriving'],
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.repointFoldedRows({'arriving': 'here'});
      expect(repo.releasesBox.get('ep')!.trackIds, ['here', 'other']);
      expect(repo.playlistsBox.get('pl')!.projectIds, ['here']);
    });

    test(
      'a stack takes the kept row in when it is in no other stack',
      () async {
        await repo.projectsBox.putAll({
          'stack': TestFactories.makeProject(
            id: 'stack',
            filePath: p.join(tempDir.path, 'F', 'Song'),
            isVirtual: true,
            memberProjectIds: ['arriving', 'v2'],
            defaultLaunchMemberId: 'arriving',
          ),
          'here': TestFactories.makeProject(
            id: 'here',
            filePath: song('F', 'Song'),
          ),
          'v2': TestFactories.makeProject(id: 'v2', stackId: 'stack'),
        });
        await repo.repointFoldedRows({'arriving': 'here'});
        final stack = repo.projectsBox.get('stack')!;
        expect(stack.memberProjectIds, ['here', 'v2']);
        expect(stack.defaultLaunchMemberId, 'here');
        expect(repo.projectsBox.get('here')!.stackId, 'stack');
      },
    );

    test('a kept row in another stack is never put in a second one', () async {
      await repo.projectsBox.putAll({
        'stack': TestFactories.makeProject(
          id: 'stack',
          isVirtual: true,
          memberProjectIds: ['arriving', 'v2'],
        ),
        'here': TestFactories.makeProject(id: 'here', stackId: 'mine'),
      });
      await repo.repointFoldedRows({'arriving': 'here'});
      expect(repo.projectsBox.get('stack')!.memberProjectIds, ['v2']);
      expect(repo.projectsBox.get('here')!.stackId, 'mine');
    });
  });

  test(
    'importing a backup from before a rescan leaves one row per file',
    () async {
      // What the library showed: a row deleted, its file scanned again under
      // a new id, then an older copy of the library brought the first back.
      await repo.projectsBox.put(
        'before',
        TestFactories.makeProject(
          id: 'before',
          filePath: song('F', 'Seek More'),
          status: 'Finished',
          todos: const [],
        ),
      );
      final backup = await BackupService.buildBackupJson(
        projectRepo: repo,
        profileRepo: profiles,
        profileId: profileId,
      );
      await repo.projectsBox.delete('before');
      await repo.projectsBox.put(
        'rescanned',
        TestFactories.makeProject(
          id: 'rescanned',
          filePath: song('F', 'Seek More'),
          status: 'Idea',
        ),
      );

      await BackupService.importBackupJson(
        backup,
        projectRepo: repo,
        profileRepo: profiles,
        currentProfileId: profileId,
        importMode: ImportMode.merge,
      );

      expect(repo.getAllProjects().map((r) => r.id), ['rescanned']);
      expect(repo.projectsBox.get('rescanned')!.status, 'Finished');
    },
  );
}
