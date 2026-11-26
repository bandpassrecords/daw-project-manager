import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/todo_item.dart';
import 'package:daw_project_manager/repository/root_relocations.dart';
import 'package:daw_project_manager/services/same_file_rows.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_factories.dart';

/// One file, one row. A library once held 68 projects twice: the copy with
/// the user's details pointing at a folder emptied by "Relocate folder", and
/// a blank copy at the moved file. Both had been scanned from one file under
/// different ids; a merge brought the old ones back after the move.
void main() {
  final oldRoot = p.join(
    p.separator == r'\' ? r'C:\' : '/',
    'Proton Drive',
    'My files',
  );
  final newRoot = p.join(
    p.separator == r'\' ? r'F:\' : '/',
    'ProtonDrive',
    'My files',
  );
  String oldPath(String song) =>
      p.join(oldRoot, 'Audio Crawler', song, '$song.cpr');
  String newPath(String song) =>
      p.join(newRoot, 'Audio Crawler', song, '$song.cpr');
  final t0 = DateTime(2026, 5, 13, 12);
  final t1 = DateTime(2026, 5, 23, 13, 59);

  MusicProject row(
    String id,
    String path, {
    DateTime? updatedAt,
    DateTime? createdAt,
    String status = 'Idea',
    String? notes,
    List<TodoItem>? todos,
    List<SessionRecord>? sessions,
    String? previewSongPath,
    String? previewSongFileName,
    bool hidden = false,
    String? customDisplayName,
    List<String>? tags,
    bool isVirtual = false,
  }) {
    final s = sessions ?? const <SessionRecord>[];
    return TestFactories.makeProject(
      id: id,
      filePath: path,
      fileName: p.basename(path),
      status: status,
      notes: notes,
      todos: todos ?? const [],
      sessions: s,
      totalWorkSeconds: s.fold<int>(0, (a, x) => a + x.durationSeconds),
      previewSongPath: previewSongPath,
      previewSongFileName: previewSongFileName,
      hidden: hidden,
      customDisplayName: customDisplayName,
      tags: tags ?? const [],
      isVirtual: isVirtual,
      createdAt: createdAt ?? t0,
      updatedAt: updatedAt ?? t0,
    );
  }

  TodoItem todo(String id, String text) =>
      TodoItem(id: id, text: text, createdAt: t0);
  SessionRecord session(String id, int seconds) => SessionRecord(
    id: id,
    startedAt: t0,
    endedAt: t0.add(Duration(seconds: seconds)),
    durationSeconds: seconds,
  );

  Map<String, MusicProject> byFile(List<MusicProject> rows) => {
    for (final r in rows)
      if (matchesByFile(r)) sameFileKey(r.filePath): r,
  };

  group('relocatedRow', () {
    final move = RootRelocation(from: oldRoot, to: newRoot, at: t1);

    test('moves a row under the old place', () {
      final moved = relocatedRow(row('a', oldPath('Song')), [move]);
      expect(moved.filePath, newPath('Song'));
      expect(moved.fileName, 'Song.cpr');
    });

    test('leaves a row elsewhere alone', () {
      final other = p.join(newRoot, 'Elsewhere', 'X.als');
      expect(relocatedRow(row('a', other), [move]).filePath, other);
    });

    test('follows a folder relocated twice to where it ended up', () {
      final third = p.join(newRoot, 'Archive');
      final moved = relocatedRow(row('a', oldPath('Song')), [
        move,
        RootRelocation(
          from: p.join(newRoot, 'Audio Crawler'),
          to: third,
          at: t1,
        ),
      ]);
      expect(moved.filePath, p.join(third, 'Song', 'Song.cpr'));
    });
  });

  group('planIncomingRow', () {
    test('adds a row for a file this profile has no row for', () {
      final plan = planIncomingRow(
        row('remote', newPath('A')),
        localByFile: byFile([row('local', newPath('B'))]),
        relocations: const [],
      );
      expect(plan, isA<AddIncomingRow>());
    });

    test('folds a row for a file already here into the row here', () {
      final plan =
          planIncomingRow(
                row('remote', newPath('A'), notes: 'from the laptop'),
                localByFile: byFile([row('local', newPath('A'))]),
                relocations: const [],
              )
              as FoldIncomingRow;
      expect(plan.keptId, 'local');
      expect(plan.updated!.id, 'local');
      expect(plan.updated!.notes, 'from the laptop');
    });

    test('the case found in a real library: an old copy naming the place a '
        'folder was relocated from folds into the moved row', () {
      final plan =
          planIncomingRow(
                row(
                  'december',
                  oldPath('Meiko'),
                  status: 'Finished',
                  updatedAt: t0,
                ),
                localByFile: byFile([
                  row('may', newPath('Meiko'), updatedAt: t1),
                ]),
                relocations: [
                  RootRelocation(from: oldRoot, to: newRoot, at: t1),
                ],
              )
              as FoldIncomingRow;
      expect(plan.keptId, 'may');
      expect(plan.updated!.status, 'Finished');
      expect(plan.updated!.filePath, newPath('Meiko'));
    });

    test('adds an old copy at the new place when nothing is there yet', () {
      final plan =
          planIncomingRow(
                row('december', oldPath('Meiko')),
                localByFile: const {},
                relocations: [
                  RootRelocation(from: oldRoot, to: newRoot, at: t1),
                ],
              )
              as AddIncomingRow;
      expect(plan.row.filePath, newPath('Meiko'));
    });

    test('never folds a stack: its path is a folder its versions share', () {
      final folder = p.dirname(newPath('A'));
      final plan = planIncomingRow(
        row('remote-stack', folder, isVirtual: true),
        localByFile: {
          sameFileKey(folder): row('local-stack', folder, isVirtual: true),
        },
        relocations: const [],
      );
      expect(plan, isA<AddIncomingRow>());
    });
  });

  group('foldSameFileRow', () {
    test('adds nothing when the other row knows nothing more', () {
      final kept = row('k', newPath('A'), notes: 'n', status: 'Mixing');
      expect(foldSameFileRow(kept, row('o', newPath('A'))), isNull);
    });

    test('something set beats something unset, whichever row is newer', () {
      final kept = row('k', newPath('A'), updatedAt: t1);
      final other = row(
        'o',
        newPath('A'),
        updatedAt: t0,
        status: 'Finished',
        previewSongPath: '/previews/o_preview.wav',
        previewSongFileName: 'Mixdown.wav',
        customDisplayName: 'Leave the lights on',
        hidden: true,
      );
      final folded = foldSameFileRow(kept, other)!;
      expect(folded.id, 'k');
      expect(folded.status, 'Finished');
      expect(folded.previewSongPath, '/previews/o_preview.wav');
      expect(folded.previewSongFileName, 'Mixdown.wav');
      expect(folded.customDisplayName, 'Leave the lights on');
      expect(folded.hidden, isTrue);
    });

    test('where both set a value, the row changed more recently wins', () {
      final kept = row('k', newPath('A'), status: 'Mixing', updatedAt: t0);
      final newer = row('o', newPath('A'), status: 'Mastering', updatedAt: t1);
      expect(foldSameFileRow(kept, newer)!.status, 'Mastering');

      final keptNewer = row('k', newPath('A'), status: 'Mixing', updatedAt: t1);
      final older = row('o', newPath('A'), status: 'Mastering', updatedAt: t0);
      expect(foldSameFileRow(keptNewer, older), isNull);
    });

    test('unites to-dos, by id and by text', () {
      final kept = row(
        'k',
        newPath('A'),
        todos: [todo('1', 'render the bass')],
      );
      final other = row(
        'o',
        newPath('A'),
        todos: [
          todo('1', 'render the bass'),
          todo('2', ' render the bass '),
          todo('3', 'ta faltando o baixo filtrado no 0:53'),
        ],
      );
      expect(foldSameFileRow(kept, other)!.todos.map((t) => t.text), [
        'render the bass',
        'ta faltando o baixo filtrado no 0:53',
      ]);
    });

    test('unites work sessions, and the total follows', () {
      final kept = row('k', newPath('A'), sessions: [session('s1', 60)]);
      final other = row(
        'o',
        newPath('A'),
        sessions: [session('s1', 60), session('s2', 30)],
      );
      final folded = foldSameFileRow(kept, other)!;
      expect(folded.sessions.map((s) => s.id), ['s1', 's2']);
      expect(folded.totalWorkSeconds, 90);
    });

    test('keeps both notes when they differ, and only once', () {
      final kept = row('k', newPath('A'), notes: 'mine');
      final other = row('o', newPath('A'), notes: 'theirs');
      final folded = foldSameFileRow(kept, other)!;
      expect(folded.notes, contains('mine'));
      expect(folded.notes, contains('theirs'));
      // The next merge brings the same row: nothing more to write.
      expect(foldSameFileRow(folded, other), isNull);
    });

    test('takes notes that already contain the kept ones whole', () {
      final kept = row('k', newPath('A'), notes: 'intro');
      final other = row('o', newPath('A'), notes: 'intro\nthen the drop');
      expect(foldSameFileRow(kept, other)!.notes, 'intro\nthen the drop');
    });

    test('unites tags without a case-only twin', () {
      final kept = row('k', newPath('A'), tags: ['Trap']);
      final other = row('o', newPath('A'), tags: ['trap', 'Remix']);
      expect(foldSameFileRow(kept, other)!.tags, ['Trap', 'Remix']);
    });

    test('keeps the earlier of the two created times', () {
      final kept = row('k', newPath('A'), createdAt: t1);
      final other = row('o', newPath('A'), createdAt: t0);
      expect(foldSameFileRow(kept, other)!.createdAt, t0);
    });

    test('folding the result in again changes nothing', () {
      final kept = row('k', newPath('A'));
      final other = row(
        'o',
        newPath('A'),
        status: 'Finished',
        todos: [todo('1', 'master it')],
        sessions: [session('s1', 10)],
        notes: 'theirs',
      );
      final folded = foldSameFileRow(kept, other)!;
      expect(foldSameFileRow(folded, other), isNull);
    });
  });
}
