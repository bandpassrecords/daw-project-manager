import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/utils/project_sort.dart';

import '../helpers/test_factories.dart';

/// #111 — the ordering behind the card grid's sort control and the mobile
/// list's sort dropdown. One implementation, so "sort by phase" can't come to
/// mean two different things on two screens.
void main() {
  MusicProject p(
    String id, {
    String? name,
    String status = 'Mixing',
    DateTime? modified,
    DateTime? created,
    double? bpm,
    DateTime? deadline,
  }) => TestFactories.makeProject(
    id: id,
    customDisplayName: name ?? id,
    status: status,
    lastModifiedAt: modified ?? DateTime(2025, 1, 1),
    createdAt: created ?? DateTime(2024, 1, 1),
    bpm: bpm,
    deadline: deadline,
  );

  List<String> ids(List<MusicProject> projects) =>
      projects.map((p) => p.id).toList();

  test('never mutates the list it is given', () {
    final original = [p('b', name: 'B'), p('a', name: 'A')];
    final copy = List<MusicProject>.from(original);

    sortProjects(original, ProjectSortField.name);

    expect(ids(original), ids(copy));
  });

  group('by name', () {
    final projects = [
      p('b', name: 'beta'),
      p('c', name: 'Alpha'),
      p('a', name: 'gamma'),
    ];

    test('is case-insensitive A to Z', () {
      expect(ids(sortProjects(projects, ProjectSortField.name)), [
        'c',
        'b',
        'a',
      ]);
    });

    test('reverses on descending', () {
      expect(
        ids(sortProjects(projects, ProjectSortField.name, descending: true)),
        ['a', 'b', 'c'],
      );
    });
  });

  test('by last modified, newest first when descending', () {
    final projects = [
      p('old', modified: DateTime(2024, 1, 1)),
      p('new', modified: DateTime(2026, 1, 1)),
      p('mid', modified: DateTime(2025, 1, 1)),
    ];

    expect(
      ids(
        sortProjects(projects, ProjectSortField.lastModified, descending: true),
      ),
      ['new', 'mid', 'old'],
    );
  });

  test('by date added', () {
    final projects = [
      p('second', created: DateTime(2025, 6, 1)),
      p('first', created: DateTime(2024, 6, 1)),
    ];

    expect(ids(sortProjects(projects, ProjectSortField.createdAt)), [
      'first',
      'second',
    ]);
  });

  test('by phase, case-insensitively', () {
    final projects = [
      p('m', status: 'mixing'),
      p('a', status: 'Arranging'),
      p('i', status: 'Idea'),
    ];

    expect(ids(sortProjects(projects, ProjectSortField.phase)), [
      'a',
      'i',
      'm',
    ]);
  });

  group('by BPM', () {
    test('treats a missing BPM as the floor', () {
      final projects = [p('fast', bpm: 174), p('none'), p('slow', bpm: 90)];

      expect(ids(sortProjects(projects, ProjectSortField.bpm)), [
        'none',
        'slow',
        'fast',
      ]);
    });

    test('highest first when descending', () {
      final projects = [p('slow', bpm: 90), p('fast', bpm: 174)];

      expect(
        ids(sortProjects(projects, ProjectSortField.bpm, descending: true)),
        ['fast', 'slow'],
      );
    });
  });

  group('by deadline', () {
    final projects = [
      p('later', deadline: DateTime(2026, 3, 1)),
      p('none'),
      p('sooner', deadline: DateTime(2026, 1, 1)),
    ];

    test('soonest first', () {
      expect(ids(sortProjects(projects, ProjectSortField.deadline)), [
        'sooner',
        'later',
        'none',
      ]);
    });

    test('undated projects stay last even when the arrow flips', () {
      // Flipping the direction is a request to see the far deadlines first,
      // not to march every undated project to the top of the library.
      expect(
        ids(
          sortProjects(projects, ProjectSortField.deadline, descending: true),
        ),
        ['later', 'sooner', 'none'],
      );
    });
  });

  group('defaultDescendingFor', () {
    test('dates and BPM open on their high end', () {
      expect(defaultDescendingFor(ProjectSortField.lastModified), isTrue);
      expect(defaultDescendingFor(ProjectSortField.createdAt), isTrue);
      expect(defaultDescendingFor(ProjectSortField.bpm), isTrue);
    });

    test('names, phases and deadlines read forwards', () {
      expect(defaultDescendingFor(ProjectSortField.name), isFalse);
      expect(defaultDescendingFor(ProjectSortField.phase), isFalse);
      expect(defaultDescendingFor(ProjectSortField.deadline), isFalse);
    });

    test('covers every field', () {
      for (final field in ProjectSortField.values) {
        expect(() => defaultDescendingFor(field), returnsNormally);
      }
    });
  });
}
