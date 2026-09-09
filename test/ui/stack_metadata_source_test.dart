import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/models/todo_item.dart';
import 'package:daw_project_manager/ui/dialogs/stack_metadata_source_dialog.dart';

import '../helpers/test_factories.dart';

/// Which project becomes the main project of a new stack (#94).
///
/// Stacking promotes exactly one member's fields and leaves every other
/// member's untouched, so two versions' details can never be merged into each
/// other. These pin the two decisions that follow from that: which member is
/// promoted when nobody is asked, and when the user has to be asked at all.
void main() {
  MusicProject project(
    String id, {
    DateTime? createdAt,
    double? bpm,
    String? musicalKey,
    String? notes,
    String? customDisplayName,
    DateTime? deadline,
    List<TodoItem>? todos,
    List<ProjectPart>? parts,
    int totalWorkSeconds = 0,
    String? projectNotes,
    String? dawType = 'Ableton Live',
  }) => TestFactories.makeProject(
    id: id,
    createdAt: createdAt,
    bpm: bpm,
    musicalKey: musicalKey,
    notes: notes,
    customDisplayName: customDisplayName,
    deadline: deadline,
    todos: todos,
    parts: parts,
    totalWorkSeconds: totalWorkSeconds,
    projectNotes: projectNotes,
    dawType: dawType,
  );

  group('hasUserMetadata', () {
    test('a freshly scanned project has none', () {
      expect(project('a').hasUserMetadata, isFalse);
    });

    test('any single user-entered field counts', () {
      expect(project('a', bpm: 128).hasUserMetadata, isTrue);
      expect(project('a', musicalKey: 'Am').hasUserMetadata, isTrue);
      expect(project('a', notes: 'chorus needs work').hasUserMetadata, isTrue);
      expect(project('a', customDisplayName: 'Renamed').hasUserMetadata, isTrue);
      expect(
        project('a', deadline: DateTime(2026, 1, 1)).hasUserMetadata,
        isTrue,
      );
      expect(project('a', totalWorkSeconds: 60).hasUserMetadata, isTrue);
      expect(
        project(
          'a',
          todos: [
            TodoItem(id: 't', text: 'mix', createdAt: DateTime(2025, 1, 1)),
          ],
        ).hasUserMetadata,
        isTrue,
      );
    });

    test('whitespace-only text does not count as metadata', () {
      expect(project('a', notes: '   ').hasUserMetadata, isFalse);
      expect(project('a', musicalKey: ' ').hasUserMetadata, isFalse);
    });

    test('scanned facts do not count', () {
      // Every version of a song carries the same DAW type and the same notes
      // read out of the project file. Counting those would make every single
      // stack look like a metadata conflict and prompt on every stack.
      expect(
        project('a', dawType: 'Cubase', projectNotes: 'from the DAW file')
            .hasUserMetadata,
        isFalse,
      );
    });
  });

  group('defaultStackMetadataSource', () {
    test('is the oldest member', () {
      // v1 → v2 → v3: the details the user has been maintaining sit on the
      // one they started from.
      final members = [
        project('v3', createdAt: DateTime(2025, 3, 1)),
        project('v1', createdAt: DateTime(2025, 1, 1)),
        project('v2', createdAt: DateTime(2025, 2, 1)),
      ];

      expect(defaultStackMetadataSource(members).id, 'v1');
    });

    test('does not reorder the caller list', () {
      final members = [
        project('v3', createdAt: DateTime(2025, 3, 1)),
        project('v1', createdAt: DateTime(2025, 1, 1)),
      ];

      defaultStackMetadataSource(members);

      // Member order is display order on the stack — sorting it in place here
      // would silently reshuffle the versions list.
      expect(members.map((m) => m.id).toList(), ['v3', 'v1']);
    });
  });

  group('stackMetadataSourceCandidates', () {
    test('asks nothing when no version has details', () {
      expect(
        stackMetadataSourceCandidates([project('a'), project('b')]),
        isEmpty,
      );
    });

    test('asks nothing when only one version has details', () {
      // The answer is forced, so a dialog would be pure friction.
      expect(
        stackMetadataSourceCandidates([project('a', bpm: 120), project('b')]),
        isEmpty,
      );
    });

    test('asks once two versions each have their own details', () {
      final candidates = stackMetadataSourceCandidates([
        project('a', bpm: 120),
        project('b', notes: 'take 2 is the good one'),
        project('c'),
      ]);

      // Only the ones with something to promote are offered — picking an
      // empty version would just blank the song.
      expect(candidates.map((p) => p.id).toList(), ['a', 'b']);
    });
  });
}
