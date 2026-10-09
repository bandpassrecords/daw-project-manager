import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/services/midi/melodic_midi_reading.dart';

import '../../helpers/test_factories.dart';

MusicProject _p(String id, String file,
        {bool virtual = false, String? archive}) =>
    TestFactories.makeProject(
      id: id,
      filePath: p.join('songs', file),
      fileName: file,
      isVirtual: virtual,
      archivePath: archive,
    );

void main() {
  group('projectsNeedingMidiRead', () {
    bool everythingExists(String _) => true;

    test('picks readable projects with nothing stored', () {
      final needing = projectsNeedingMidiRead(
        [_p('a', 'A.cpr'), _p('b', 'B.als'), _p('c', 'C.rpp')],
        {'b'},
        fileExists: everythingExists,
      );
      expect(needing.map((x) => x.id), ['a', 'c']);
    });

    test('a project with an empty record is not asked about again', () {
      // Stored with no clips means it was read and held none.
      expect(
        projectsNeedingMidiRead([_p('a', 'A.cpr')], {'a'},
            fileExists: everythingExists),
        isEmpty,
      );
    });

    test('stacks, archives and DAWs whose contents are not read are left out',
        () {
      final needing = projectsNeedingMidiRead(
        [
          _p('stack', 'folder', virtual: true),
          _p('zip', 'Old.cpr', archive: 'old.zip'),
          _p('logic', 'Song.logicx'),
          _p('ok', 'Fine.cpr'),
        ],
        {},
        fileExists: everythingExists,
      );
      expect(needing.map((x) => x.id), ['ok']);
    });

    test('a file that is gone is left out; existence is all that is asked', () {
      final asked = <String>[];
      final needing = projectsNeedingMidiRead(
        [_p('a', 'A.cpr'), _p('b', 'B.cpr')],
        {},
        fileExists: (path) {
          asked.add(path);
          return p.basename(path) == 'A.cpr';
        },
      );
      expect(needing.map((x) => x.id), ['a']);
      expect(asked, hasLength(2));
    });

    test('existence is not asked of projects that are already out', () {
      final asked = <String>[];
      projectsNeedingMidiRead(
        [_p('s', 'S.cpr'), _p('x', 'X.logicx')],
        {'s'},
        fileExists: (path) {
          asked.add(path);
          return true;
        },
      );
      expect(asked, isEmpty);
    });
  });

  group('readMissingMidi', () {
    final projects = [for (var i = 0; i < 4; i++) _p('p$i', 'P$i.cpr')];

    test('reads one at a time, in order, reporting progress before each',
        () async {
      var running = 0, most = 0;
      final order = <String>[];
      final progress = <(int, int, String)>[];
      final outcome = await readMissingMidi(
        projects,
        read: (project) async {
          running++;
          most = running > most ? running : most;
          await Future<void>.delayed(Duration.zero);
          order.add(project.id);
          running--;
        },
        onProgress: (done, total, next) => progress.add((done, total, next.id)),
      );
      expect(most, 1, reason: 'a cloud drive is asked for one file at a time');
      expect(order, ['p0', 'p1', 'p2', 'p3']);
      expect(progress.first, (0, 4, 'p0'));
      expect(progress.last, (3, 4, 'p3'));
      expect(outcome.read, 4);
      expect(outcome.failed, 0);
      expect(outcome.stopped, isFalse);
    });

    test('stopping keeps what was read and reads no more', () async {
      final read = <String>[];
      final outcome = await readMissingMidi(
        projects,
        read: (project) async => read.add(project.id),
        shouldStop: () => read.length >= 2,
      );
      expect(read, ['p0', 'p1']);
      expect(outcome.read, 2);
      expect(outcome.stopped, isTrue);
    });

    test('one project that throws is counted and the rest still read',
        () async {
      final read = <String>[];
      final outcome = await readMissingMidi(
        projects,
        read: (project) async {
          if (project.id == 'p1') throw StateError('damaged');
          read.add(project.id);
        },
      );
      expect(read, ['p0', 'p2', 'p3']);
      expect(outcome.read, 3);
      expect(outcome.failed, 1);
    });

    test('nothing to read is an empty, unstopped outcome', () async {
      final outcome = await readMissingMidi(const [], read: (_) async {});
      expect(outcome.read, 0);
      expect(outcome.stopped, isFalse);
    });
  });

  test('formatDataSize reads as a person would', () {
    expect(formatDataSize(900), '900 B');
    expect(formatDataSize(12 * 1024), '12 KB');
    expect(formatDataSize(320 * 1024 * 1024), '320 MB');
    expect(formatDataSize((1.4 * 1024 * 1024 * 1024).round()), '1.4 GB');
  });
}
