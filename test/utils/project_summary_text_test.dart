import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/project_summary_text.dart';

import '../helpers/test_factories.dart';

void main() {
  group('projectNoteExcerpt', () {
    test('returns the user\'s own notes', () {
      final project = TestFactories.makeProject(notes: 'Needs a re-amp');
      expect(projectNoteExcerpt(project), 'Needs a re-amp');
    });

    test("uses the user's notes when there are DAW notes too", () {
      final project = TestFactories.makeProject(
        notes: 'Mine',
        projectNotes: 'From the DAW',
      );
      expect(projectNoteExcerpt(project), 'Mine');
    });

    test('never shows the DAW-extracted notes', () {
      // The project file's embedded text is session scratch, not the user's
      // word on the song; it used to be the fallback and was taken out.
      final project = TestFactories.makeProject(
        notes: null,
        projectNotes: 'From the DAW',
      );
      expect(projectNoteExcerpt(project), isNull);
      expect(projectNoteFullText(project), isNull);
    });

    test('blank user notes do not fall through to the DAW ones', () {
      final project = TestFactories.makeProject(
        notes: '   \n  ',
        projectNotes: 'From the DAW',
      );
      expect(projectNoteExcerpt(project), isNull);
    });

    test('returns null when there is nothing at all', () {
      final project = TestFactories.makeProject(notes: null, projectNotes: null);
      expect(projectNoteExcerpt(project), isNull);
    });

    test('returns null when everything is whitespace', () {
      final project =
          TestFactories.makeProject(notes: '  ', projectNotes: '\n\t ');
      expect(projectNoteExcerpt(project), isNull);
    });

    test('collapses newlines and runs of whitespace to single spaces', () {
      // A two-paragraph note must not blow up a table row's height.
      final project = TestFactories.makeProject(
        notes: 'First line\n\nSecond   line\twith tabs',
      );
      expect(projectNoteExcerpt(project), 'First line Second line with tabs');
    });

    test('truncates past the limit and marks it with an ellipsis', () {
      final project = TestFactories.makeProject(notes: 'a' * 200);
      final excerpt = projectNoteExcerpt(project, maxChars: 20)!;
      expect(excerpt.length, lessThanOrEqualTo(21));
      expect(excerpt, endsWith('…'));
    });

    test('backs up to a word boundary when cutting', () {
      final project = TestFactories.makeProject(
        notes: 'the quick brown fox jumps over the lazy dog',
      );
      final excerpt = projectNoteExcerpt(project, maxChars: 20)!;
      expect(excerpt, 'the quick brown fox…');
    });

    test('cuts at the limit when there is no usable word boundary', () {
      // Scripts that do not space their words have no boundary to find — a
      // hard cut is correct there rather than collapsing to almost nothing.
      final project = TestFactories.makeProject(notes: '日本語のとても長いメモです' * 5);
      final excerpt = projectNoteExcerpt(project, maxChars: 10)!;
      expect(excerpt.length, 11);
      expect(excerpt, endsWith('…'));
    });

    test('leaves a note that already fits untouched', () {
      final project = TestFactories.makeProject(notes: 'short');
      expect(projectNoteExcerpt(project, maxChars: 50), 'short');
    });

    test('a zero limit yields an empty string rather than throwing', () {
      final project = TestFactories.makeProject(notes: 'anything');
      expect(projectNoteExcerpt(project, maxChars: 0), '');
    });
  });

  group('projectNoteFullText', () {
    test('flattens but does not truncate', () {
      final long = 'word ' * 100;
      final project = TestFactories.makeProject(notes: long);
      final full = projectNoteFullText(project)!;

      expect(full, isNot(contains('\n')));
      expect(full, isNot(endsWith('…')));
      expect(full.length, greaterThan(kNoteExcerptMaxChars));
    });

    test('returns null when there is nothing to show', () {
      final project = TestFactories.makeProject(notes: null, projectNotes: null);
      expect(projectNoteFullText(project), isNull);
    });

    test('agrees with the excerpt when the note is short', () {
      final project = TestFactories.makeProject(notes: 'Needs a re-amp');
      expect(projectNoteFullText(project), projectNoteExcerpt(project));
    });
  });
}
