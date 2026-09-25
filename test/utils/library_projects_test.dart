import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/models/scan_root.dart';
import 'package:daw_project_manager/utils/library_projects.dart';

import '../helpers/test_factories.dart';

void main() {
  // Built with the host separator so the prefix rules mean the same thing on
  // Windows as on macOS and Linux.
  final musicRoot = p.join('music', 'albums');
  final demosRoot = p.join('music', 'demos');
  String inRoot(String root, String file) => p.join(root, file);

  ScanRoot root(String path, {bool enabled = true, String? id}) => ScanRoot(
        id: id ?? path,
        path: path,
        addedAt: DateTime(2025, 1, 1),
        enabled: enabled,
      );

  MusicProject project(
    String id, {
    String? inFolder,
    bool hidden = false,
  }) =>
      TestFactories.makeProject(
        id: id,
        filePath: inRoot(inFolder ?? musicRoot, '$id.als'),
        hidden: hidden,
      );

  List<MusicProject> build(
    List<MusicProject> all, {
    List<ScanRoot>? roots,
    List<Release> releases = const [],
    bool isMobile = false,
    bool Function(String)? exists,
  }) =>
      buildLibraryProjects(
        allProjects: all,
        releases: releases,
        scanRoots: roots ?? [root(musicRoot), root(demosRoot)],
        isMobile: isMobile,
        fileExistsLocally: exists ?? (_) => true,
      );

  group('disabled folders', () {
    test('drop their projects from the library', () {
      final library = build(
        [project('a'), project('b', inFolder: demosRoot)],
        roots: [root(musicRoot), root(demosRoot, enabled: false)],
      );

      expect(library.map((p) => p.id), ['a']);
    });

    test('are ignored on mobile, which has no folders to relate to', () {
      final library = build(
        [project('a'), project('b', inFolder: demosRoot)],
        roots: [root(musicRoot), root(demosRoot, enabled: false)],
        isMobile: true,
      );

      expect(library, hasLength(2));
    });
  });

  group('version stacks', () {
    test('count once, not once per version', () {
      final stack = TestFactories.makeProject(
        id: 'stack',
        filePath: musicRoot,
        isVirtual: true,
        memberProjectIds: const ['v1', 'v2', 'v3'],
      );
      final versions = [
        for (final id in ['v1', 'v2', 'v3'])
          TestFactories.makeProject(
            id: id,
            filePath: inRoot(musicRoot, '$id.als'),
            stackId: 'stack',
          ),
      ];

      final library = build([stack, ...versions]);

      expect(library.map((p) => p.id), ['stack']);
    });
  });

  group('release-preserved projects', () {
    Release releaseWith(String projectId) => Release(
          id: 'r',
          title: 'EP',
          trackIds: [projectId],
        );

    test('stay when their folder is active', () {
      final library = build(
        [project('a')],
        releases: [releaseWith('a')],
      );

      expect(library.map((p) => p.id), ['a']);
    });

    test('drop out when their file is here but no folder covers it', () {
      final library = build(
        [project('a', inFolder: p.join('elsewhere'))],
        releases: [releaseWith('a')],
      );

      expect(library, isEmpty);
    });

    test('stay when their file is not on this machine at all', () {
      // A metadata-only entry restored from a backup or another machine.
      final library = build(
        [project('a', inFolder: p.join('elsewhere'))],
        releases: [releaseWith('a')],
        exists: (_) => false,
      );

      expect(library.map((p) => p.id), ['a']);
    });

    test('drop out when their folder is disabled', () {
      final library = build(
        [project('a', inFolder: demosRoot)],
        roots: [root(musicRoot), root(demosRoot, enabled: false)],
        releases: [releaseWith('a')],
      );

      expect(library, isEmpty);
    });
  });

  group('libraryProjectCounts', () {
    test('splits the library into visible and hidden', () {
      final counts = libraryProjectCounts([
        project('a'),
        project('b'),
        project('c', hidden: true),
      ]);

      expect(counts.visible, 2);
      expect(counts.hidden, 1);
    });

    test('a disabled folder lowers both figures, not just the list', () {
      // The reported bug: disabling a folder emptied the list but left
      // "Projects: N (M hidden)" untouched.
      final all = [
        project('a'),
        project('b', inFolder: demosRoot),
        project('c', inFolder: demosRoot, hidden: true),
      ];

      final before = libraryProjectCounts(build(all));
      final after = libraryProjectCounts(build(
        all,
        roots: [root(musicRoot), root(demosRoot, enabled: false)],
      ));

      expect((before.visible, before.hidden), (2, 1));
      expect((after.visible, after.hidden), (1, 0),
          reason: 'a project in a disabled folder is neither shown nor '
              '"hidden" — it is out of the library');
    });

    test('an empty library counts zero', () {
      final counts = libraryProjectCounts(const []);
      expect((counts.visible, counts.hidden), (0, 0));
    });
  });
}
