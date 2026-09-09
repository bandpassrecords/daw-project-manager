import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/ui/project_detail_page.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// Regression coverage for the crash on unstacking (#94).
///
/// Unstacking deletes the stack row while its detail page is still mounted.
/// The projects stream rebuilds that page before the pop that follows has run,
/// so the page looked itself up in a list it was no longer in and threw
/// `Bad state: No element` mid-frame. The lookup now returns null and the page
/// renders a placeholder until the pop lands.
void main() {
  group('findProjectById', () {
    final a = TestFactories.makeProject(id: 'a');
    final b = TestFactories.makeProject(id: 'b');

    test('finds the project it is asked for', () {
      expect(findProjectById([a, b], 'b')?.id, 'b');
    });

    test('returns null instead of throwing when the project is gone', () {
      // This is the exact shape of the unstack crash: the id the page was
      // opened with is no longer in the list it is rebuilt against.
      expect(findProjectById([a, b], 'deleted-stack'), isNull);
    });

    test('returns null for an empty list', () {
      expect(findProjectById([], 'a'), isNull);
    });
  });

  group('unstack leaves the detail page with nothing to find', () {
    late Directory tempDir;
    late ProjectRepository repo;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      repo = await HiveTestHelper.createRepository();
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('the stack id no longer resolves after unstacking', () async {
      await repo.projectsBox.put(
        'v1',
        TestFactories.makeProject(id: 'v1', filePath: '/Music/SongA/v1.als'),
      );
      await repo.projectsBox.put(
        'v2',
        TestFactories.makeProject(id: 'v2', filePath: '/Music/SongA/v2.als'),
      );
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      await repo.unstack(stack.id);

      // The precondition the page has to survive: a rebuild keyed on an id
      // that is no longer in the box.
      expect(
        findProjectById(repo.getAllProjects(), stack.id),
        isNull,
      );
      // ...while the versions it held are back as standalone projects.
      expect(repo.projectsBox.get('v1')!.isStackMember, isFalse);
      expect(repo.projectsBox.get('v2')!.isStackMember, isFalse);
    });

    test('removing the second-to-last version dissolves the stack too',
        () async {
      // The same crash path from a different button: removing a version can
      // drop the stack to one member, which dissolves it while its page is
      // still open.
      await repo.projectsBox.put(
        'v1',
        TestFactories.makeProject(id: 'v1', filePath: '/Music/SongA/v1.als'),
      );
      await repo.projectsBox.put(
        'v2',
        TestFactories.makeProject(id: 'v2', filePath: '/Music/SongA/v2.als'),
      );
      final stack = await repo.stackProjects(memberIds: ['v1', 'v2']);

      await repo.removeFromStack('v2');

      expect(findProjectById(repo.getAllProjects(), stack.id), isNull);
    });
  });
}
