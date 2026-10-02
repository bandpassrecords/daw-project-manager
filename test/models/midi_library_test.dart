import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_library.dart';
import 'package:daw_project_manager/models/stored_midi_clips.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';

import '../helpers/test_factories.dart';

MidiClip _clip(String name, int pitch, {String? track, int occurrences = 1}) => MidiClip(
      name: name,
      trackName: track,
      ppq: 480,
      lengthTicks: 1920,
      occurrences: occurrences,
      notes: [MidiNote(startTick: 0, lengthTicks: 240, pitch: pitch, velocity: 100)],
    );

StoredMidiClips _stored(List<MidiClip> clips) =>
    StoredMidiClips(extractedAt: DateTime.utc(2026), clips: clips);

void main() {
  final songB = TestFactories.makeProject(id: 'b', fileName: 'B Song.als', bpm: 128);
  final songA = TestFactories.makeProject(id: 'a', fileName: 'A Song.als', bpm: 145);
  final songAv2 = TestFactories.makeProject(id: 'a2', fileName: 'A Song v2.als', bpm: 145);

  group('sortByTempo', () {
    test('slowest first, unknown tempo last, ties in their order', () {
      final items = [
        ('a', 140.0),
        ('b', null),
        ('c', 87.5),
        ('d', 140.0),
        ('e', null),
      ];
      expect(sortByTempo(items, (i) => i.$2).map((i) => i.$1),
          ['c', 'a', 'd', 'b', 'e']);
    });

    test('nothing to sort, nothing back', () {
      expect(sortByTempo(<double?>[], (b) => b), isEmpty);
    });
  });

  test('a library clip carries its project\'s key for export', () {
    final keyed = TestFactories.makeProject(
        id: 'k', fileName: 'Keyed.als', bpm: 120, musicalKey: ' A minor ');
    final blank = TestFactories.makeProject(
        id: 'z', fileName: 'Zed.als', bpm: 120, musicalKey: '');
    final lib = buildMidiLibrary(
      {
        'k': _stored([_clip('One', 40)]),
        'z': _stored([_clip('Two', 41)]),
      },
      {'k': keyed, 'z': blank},
    );
    expect(lib.map((l) => l.musicalKey), ['A minor', null]);
  });

  group('buildMidiLibrary', () {
    test('lists every project\'s clips, projects by name', () {
      final lib = buildMidiLibrary(
        {
          'b': _stored([_clip('Chords', 60)]),
          'a': _stored([_clip('Bassline', 36, track: 'Bass')]),
        },
        {'a': songA, 'b': songB},
      );
      expect(lib.map((l) => l.clip.name), ['Bassline', 'Chords']);
      expect(lib.first.projectName, 'A Song');
      expect(lib.first.bpm, 145);
    });

    test('the same notes in two projects are one clip, listed under the first',
        () {
      final lib = buildMidiLibrary(
        {
          'a': _stored([_clip('Bassline', 36, occurrences: 4)]),
          'a2': _stored([_clip('Bassline v2', 36, occurrences: 2)]),
        },
        {'a': songA, 'a2': songAv2},
      );
      final only = lib.single;
      expect(only.projectId, 'a');
      expect(only.otherProjectIds, ['a2']);
      expect(only.otherProjectNames, ['A Song v2']);
      expect(only.clip.occurrences, 6);
    });

    test('leaves out clips of projects that are gone, and of stacks', () {
      final stack = TestFactories.makeProject(id: 's', fileName: 'Stack', isVirtual: true);
      final lib = buildMidiLibrary(
        {
          'gone': _stored([_clip('Orphan', 50)]),
          's': _stored([_clip('Stacked', 51)]),
          'a': _stored([_clip('Kept', 52)]),
        },
        {'a': songA, 's': stack},
      );
      expect(lib.map((l) => l.clip.name), ['Kept']);
    });
  });

  group('filterMidiLibrary', () {
    final lib = buildMidiLibrary(
      {
        'a': _stored([
          _clip('Main riff', 36, track: 'Bassline'),
          _clip('Hats', 42, track: 'Hi Hats'),
        ]),
        'b': _stored([_clip('Chords', 60, track: 'Piano')]),
      },
      {'a': songA, 'b': songB},
    );

    test('matches clip, track and project names', () {
      expect(filterMidiLibrary(lib, query: 'riff').single.clip.name, 'Main riff');
      expect(filterMidiLibrary(lib, query: 'piano').single.clip.name, 'Chords');
      expect(filterMidiLibrary(lib, query: 'b song').single.clip.name, 'Chords');
      expect(filterMidiLibrary(lib, query: ''), hasLength(3));
    });

    test('filters by inferred instrument', () {
      expect(filterMidiLibrary(lib, voice: SynthVoice.bass).single.clip.name, 'Main riff');
      expect(filterMidiLibrary(lib, voice: SynthVoice.hiHat).single.clip.name, 'Hats');
      expect(filterMidiLibrary(lib, voice: SynthVoice.organ), isEmpty);
    });

    test('search and instrument combine', () {
      expect(filterMidiLibrary(lib, query: 'a song', voice: SynthVoice.keys), isEmpty);
    });
  });
}
