import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_clip_naming.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/stored_midi_clips.dart';
import 'package:daw_project_manager/services/midi/melodic_midi_export.dart';

import '../../helpers/test_factories.dart';

/// [pitches] one after another, a quarter note each, over [bars] bars.
MidiClip _line(
  List<int> pitches, {
  String name = 'MIDI 01',
  String? track,
  int channel = 0,
  int bars = 2,
  int occurrences = 1,
}) {
  return MidiClip(
    name: name,
    trackName: track,
    ppq: 480,
    lengthTicks: bars * 4 * 480,
    occurrences: occurrences,
    notes: [
      for (var i = 0; i < pitches.length; i++)
        MidiNote(
          startTick: i * 240,
          lengthTicks: 240,
          pitch: pitches[i],
          velocity: 90,
          channel: channel,
        ),
    ],
  );
}

final _tune = [60, 62, 64, 65, 67, 65, 64, 62, 60, 62, 64, 67, 69, 67, 65, 64];

StoredMidiClips _stored(List<MidiClip> clips) =>
    StoredMidiClips(extractedAt: DateTime.utc(2026, 1, 1), clips: clips);

MusicProject _project(String id, String name,
        {double? bpm, String? key, List<String>? tags}) =>
    TestFactories.makeProject(
      id: id,
      filePath: p.join('songs', '$name.cpr'),
      fileName: '$name.cpr',
      dawType: 'Cubase',
      customDisplayName: name,
      bpm: bpm,
      musicalKey: key,
      tags: tags,
    );

void main() {
  group('melodicRoleOf', () {
    test('keeps a lead, an arp and a melody', () {
      expect(melodicRoleOf(_line(_tune, track: 'Lead 01')), MidiClipRole.lead);
      expect(melodicRoleOf(_line(_tune, name: 'Arp 3')), MidiClipRole.arp);
      expect(melodicRoleOf(_line(_tune)), MidiClipRole.melody,
          reason: 'nothing says what it is, but it moves like a melody');
    });

    test('leaves out drums, however they are called or channelled', () {
      expect(melodicRoleOf(_line(_tune, track: 'Drums')), isNull);
      expect(melodicRoleOf(_line(_tune, channel: 9)), isNull,
          reason: 'channel 10 is the drum channel');
    });

    test('leaves out basslines and chords unless asked', () {
      final bass = _line([36, 38, 40, 41, 43, 41, 40, 38], track: 'Bass');
      final chords = _line(_tune, track: 'Chords');
      expect(melodicRoleOf(bass), isNull);
      expect(melodicRoleOf(chords), isNull);
      const wider = MelodicExportOptions(
          roles: {MidiClipRole.lead, MidiClipRole.bass, MidiClipRole.chords});
      expect(melodicRoleOf(bass, options: wider), MidiClipRole.bass);
      expect(melodicRoleOf(chords, options: wider), MidiClipRole.chords);
    });

    test('leaves out fragments: few notes, one pitch, under a bar', () {
      expect(melodicRoleOf(_line(_tune.take(5).toList())), isNull,
          reason: 'fewer than 8 notes');
      expect(melodicRoleOf(_line(List.filled(16, 72))), isNull,
          reason: 'a pulse on one pitch');
      expect(melodicRoleOf(_line([60, 62, 64, 65, 67, 69, 71, 72], bars: 1)),
          MidiClipRole.melody,
          reason: 'one bar is the shortest phrase');
      final short = MidiClip(
        name: 'Hook',
        ppq: 480,
        lengthTicks: 480,
        notes: [
          for (var i = 0; i < 8; i++)
            MidiNote(
                startTick: i * 60,
                lengthTicks: 60,
                pitch: 60 + i,
                velocity: 90),
        ],
      );
      expect(melodicRoleOf(short), isNull, reason: 'under a bar');
    });

    test('a clip with no notes has no role', () {
      expect(
        melodicRoleOf(const MidiClip(
            name: 'Empty', ppq: 480, lengthTicks: 1920, notes: [])),
        isNull,
      );
    });
  });

  group('melodicStatsOf', () {
    test('counts notes, pitches, range, bars and velocity', () {
      final s = melodicStatsOf(_line(_tune))!;
      expect(s.noteCount, 16);
      expect(s.distinctPitches, 6);
      expect(s.lowestPitch, 60);
      expect(s.highestPitch, 69);
      expect(s.span, 9);
      expect(s.bars, 2);
      expect(s.notesPerBar, 8);
      expect(s.averageVelocity, 90);
      expect(s.maxPolyphony, 1, reason: 'one note at a time');
      expect(s.grid, '1-8');
    });

    test('polyphony is the most notes sounding together', () {
      final chord = MidiClip(
        name: 'c',
        ppq: 480,
        lengthTicks: 1920,
        notes: [
          for (final pitch in [60, 64, 67])
            MidiNote(startTick: 0, lengthTicks: 480, pitch: pitch, velocity: 80),
          const MidiNote(
              startTick: 480, lengthTicks: 480, pitch: 62, velocity: 80),
        ],
      );
      expect(melodicStatsOf(chord)!.maxPolyphony, 3);
    });

    test('a note ending as the next starts does not overlap it', () {
      expect(melodicStatsOf(_line(_tune))!.maxPolyphony, 1);
    });

    test('noteNameOf follows the Cubase convention: 60 is C3', () {
      expect(noteNameOf(60), 'C3');
      expect(noteNameOf(69), 'A3');
      expect(noteNameOf(0), 'C-2');
    });
  });

  group('selectMelodicClips', () {
    test('only melodic clips, projects by name, stacks and strays left out', () {
      final a = _project('a', 'Alpha');
      final b = _project('b', 'Beta');
      final stack = TestFactories.makeProject(
          id: 's', filePath: 'folder', isVirtual: true);
      final entries = selectMelodicClips(
        {
          'b': _stored([_line(_tune, track: 'Lead')]),
          'a': _stored([
            _line(_tune, track: 'Lead'),
            _line(_tune, track: 'Drums'),
          ]),
          's': _stored([_line(_tune)]),
          'gone': _stored([_line(_tune)]),
        },
        {'a': a, 'b': b, 's': stack},
      );
      expect(entries.map((e) => e.project.id), ['a', 'b']);
      expect(entries.every((e) => e.role == MidiClipRole.lead), isTrue);
    });

    test('a riff that is also in another project says so', () {
      final entries = selectMelodicClips(
        {
          'a': _stored([_line(_tune, track: 'Lead')]),
          'b': _stored([_line(_tune, track: 'Lead')]),
          'c': _stored([_line(_tune.reversed.toList(), track: 'Lead')]),
        },
        {
          'a': _project('a', 'Song v1'),
          'b': _project('b', 'Song v2'),
          'c': _project('c', 'Other'),
        },
      );
      final byProject = {for (final e in entries) e.project.id: e.alsoIn};
      expect(byProject['a'], ['Song v2']);
      expect(byProject['b'], ['Song v1']);
      expect(byProject['c'], isEmpty);
    });
  });

  group('planMelodicFiles', () {
    test('a folder per project, files numbered and described', () {
      final a = _project('a', 'Alpha', bpm: 140, key: 'A minor');
      final entries = selectMelodicClips(
        {
          'a': _stored([
            _line(_tune, track: 'Lead'),
            _line(_tune.reversed.toList(), track: 'Lead', name: 'Lead 2'),
          ]),
        },
        {'a': a},
      );
      planMelodicFiles(entries);
      expect(entries[0].relativePath,
          'Alpha/01 Lead – MIDI 01 - Lead - 140BPM - A minor - 2 bars.mid');
      expect(entries[1].relativePath.startsWith('Alpha/02 '), isTrue);
    });

    test('two projects with one name get two folders', () {
      final entries = selectMelodicClips(
        {
          'a': _stored([_line(_tune, track: 'Lead')]),
          'b': _stored([_line(_tune.reversed.toList(), track: 'Lead')]),
        },
        {'a': _project('a', 'Same'), 'b': _project('b', 'Same')},
      );
      planMelodicFiles(entries);
      expect(entries.map((e) => e.relativePath.split('/').first).toSet(),
          {'Same', 'Same (2)'});
    });

    test('names unsafe on a filesystem are made safe', () {
      final entries = selectMelodicClips(
        {
          'a': _stored([_line(_tune, track: 'Lead')]),
        },
        {'a': _project('a', 'AC/DC: Live?')},
      );
      planMelodicFiles(entries);
      expect(entries.single.relativePath, isNot(contains('?')));
      expect(entries.single.relativePath.split('/'), hasLength(2),
          reason: 'a slash in the name must not make another folder');
    });
  });

  group('catalog', () {
    List<CatalogEntry> entries() {
      final e = selectMelodicClips(
        {
          'a': _stored([_line(_tune, track: 'Lead, "main"', occurrences: 3)]),
        },
        {
          'a': _project('a', 'Alpha',
              bpm: 128, key: 'C major', tags: ['trance', 'remix']),
        },
      );
      planMelodicFiles(e);
      return e;
    }

    test('csv has a header, escapes commas and quotes, one row per clip', () {
      final lines = const LineSplitter().convert(melodicCatalogCsv(entries()));
      expect(lines, hasLength(2));
      expect(lines.first, startsWith('project,daw,project_modified,'));
      expect(lines[1], contains('"Lead, ""main"""'));
      expect(lines[1], contains('trance; remix'));
      expect(lines[1], contains(',C3,'));
      expect(lines[1], contains(',128.0,C major,'));
    });

    test('json carries every column by name', () {
      final json =
          melodicCatalogJson(entries(), generated: DateTime.utc(2026, 5, 1));
      expect((json['meta'] as Map)['files'], 1);
      final clip = (json['clips'] as List).single as Map;
      expect(clip['role'], 'lead');
      expect(clip['notes'], 16);
      expect(clip['copies_in_project'], 3);
      expect(clip['lowest'], 'C3');
      expect(clip['highest'], 'A3');
    });

    test('markdown has a section per project with its facts', () {
      final md = melodicCatalogMarkdown(entries(),
          generated: DateTime.utc(2026, 5, 1));
      expect(md, contains('## Alpha'));
      expect(md, contains('Cubase · 128 BPM · C major'));
      expect(md, contains('trance, remix'));
      expect(md, contains('| Lead |'));
      expect(md, contains('C3–A3'));
    });
  });

  group('exportMelodicClips', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('melodic_export'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('writes .mid files with tempo and key, and the three catalogs',
        () async {
      final a = _project('a', 'Alpha', bpm: 140, key: 'A minor');
      final result = await exportMelodicClips(
        {
          'a': _stored([
            _line(_tune, track: 'Lead'),
            _line(_tune, track: 'Drums'),
          ]),
        },
        [a],
        directory: dir,
      );
      expect(result.clips, 1);
      expect(result.projects, 1);
      expect(result.projectsWithoutMidi, 0);

      final mid = Directory(p.join(dir.path, 'Alpha'))
          .listSync()
          .whereType<File>()
          .single;
      final bytes = mid.readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(4)), 'MThd');
      // Tempo meta: FF 51 03 + 60,000,000 / 140 = 428,571 = 0x068A1B µs.
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, contains('ff5103068a1b'));

      for (final f in ['catalog.csv', 'catalog.json', 'catalog.md']) {
        expect(File(p.join(dir.path, f)).existsSync(), isTrue, reason: f);
      }
    });

    test('counts the projects that were never read for MIDI', () async {
      final result = await exportMelodicClips(
        {
          'a': _stored([_line(_tune, track: 'Lead')]),
        },
        [_project('a', 'Alpha'), _project('b', 'Beta'), _project('c', 'Gamma')],
        directory: dir,
      );
      expect(result.projectsWithoutMidi, 2);
    });

    test('nothing melodic still writes an empty catalog, no crash', () async {
      final result = await exportMelodicClips(
        {
          'a': _stored([_line(_tune, track: 'Drums')]),
        },
        [_project('a', 'Alpha')],
        directory: dir,
      );
      expect(result.clips, 0);
      expect(File(p.join(dir.path, 'catalog.csv')).readAsStringSync().trim(),
          startsWith('project,'));
    });
  });
}
