import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/dialogs/stack_version_picker_dialog.dart';

import '../helpers/test_factories.dart';

/// Searching the "Add a version" picker (#94).
///
/// The list there can be the whole library, so it needs a search field. Path
/// matching earns its place because versions of a song are named almost
/// identically — the folder is often the only thing telling two candidates
/// apart, and typing it finds every version of one song at once.
void main() {
  MusicProject project(String id, String name, String path) =>
      TestFactories.makeProject(
        id: id,
        customDisplayName: name,
        filePath: path,
      );

  final alphaV1 = project('a1', 'Alpha v1', '/Music/Alpha/Alpha v1.als');
  final alphaV2 = project('a2', 'Alpha v2', '/Music/Alpha/Alpha v2.als');
  final beta = project('b1', 'Beta rough', '/Music/Beta/Beta rough.als');

  final all = [alphaV1, alphaV2, beta];

  test('an empty query returns everything', () {
    expect(filterStackCandidates(all, ''), all);
  });

  test('a whitespace-only query returns everything', () {
    // Not "nothing" — a stray space should never blank the list.
    expect(filterStackCandidates(all, '   '), all);
  });

  test('matches on the project name', () {
    expect(
      filterStackCandidates(all, 'beta').map((p) => p.id).toList(),
      ['b1'],
    );
  });

  test('matches on the folder, finding every version of one song', () {
    expect(
      filterStackCandidates(all, 'Alpha').map((p) => p.id).toList(),
      ['a1', 'a2'],
    );
  });

  test('is case-insensitive', () {
    expect(
      filterStackCandidates(all, 'BETA').map((p) => p.id).toList(),
      ['b1'],
    );
  });

  test('returns nothing when nothing matches', () {
    expect(filterStackCandidates(all, 'gamma'), isEmpty);
  });

  test('preserves the incoming order', () {
    // The caller sorts alphabetically before opening the dialog; filtering
    // must not reshuffle that.
    expect(
      filterStackCandidates(all, 'v').map((p) => p.id).toList(),
      ['a1', 'a2'],
    );
  });
}
