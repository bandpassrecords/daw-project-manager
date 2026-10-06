import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_clip_naming.dart';
import 'package:daw_project_manager/models/midi_collection.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';
import 'package:daw_project_manager/utils/time_signature.dart';

MidiNote _n(int start, int pitch, {int length = 120}) => MidiNote(
  startTick: start,
  lengthTicks: length,
  pitch: pitch,
  velocity: 100,
);

MidiClip _clip({
  String name = 'Clip',
  String? track,
  int length = 1920,
  List<MidiNote>? notes,
}) => MidiClip(
  name: name,
  trackName: track,
  ppq: 480,
  lengthTicks: length,
  notes: notes ?? [_n(0, 60)],
);

MidiCollectionItem _item(
  String id, {
  MidiClip? clip,
  String? folder,
  String? title,
  String? role,
  double? bpm,
  String? key,
  String? timeSig,
}) => MidiCollectionItem(
  id: id,
  clip: clip ?? _clip(name: id),
  addedAt: DateTime.utc(2026, 10, 6),
  folderId: folder,
  title: title,
  role: role,
  bpm: bpm,
  musicalKey: key,
  timeSignature: timeSig,
);

final _labels = MidiNamingLabels(
  roleName: (r) => switch (r) {
    MidiClipRole.bass => 'Bass',
    MidiClipRole.chords => 'Chords',
    MidiClipRole.melody => 'Melody',
    _ => r.name,
  },
  instrumentName: (v) => 'Inst:${v.name}',
  bars: (n) => n == 1 ? '1 bar' : '$n bars',
  free: 'free',
);

void main() {
  group('suggestMidiClipRole', () {
    test('names say it first, drums before bass', () {
      expect(suggestMidiClipRole(_clip(name: 'Bass drum')), MidiClipRole.drums);
      expect(suggestMidiClipRole(_clip(track: 'Sub Bass')), MidiClipRole.bass);
      expect(
        suggestMidiClipRole(_clip(name: 'MainArp')),
        MidiClipRole.arp,
        reason: 'camelCase splits into words',
      );
      expect(suggestMidiClipRole(_clip(name: 'Lead hook')), MidiClipRole.lead);
      expect(suggestMidiClipRole(_clip(name: 'Riser')), MidiClipRole.fx);
    });

    test('then the instrument', () {
      expect(
        suggestMidiClipRole(_clip(name: 'Idea 1'), voice: SynthVoice.pad),
        MidiClipRole.pad,
      );
      expect(
        suggestMidiClipRole(_clip(name: 'Idea 1'), voice: SynthVoice.hiHat),
        MidiClipRole.drums,
      );
    });

    test('then the notes: stacked is chords, all low is bass, else melody', () {
      expect(
        suggestMidiClipRole(
          _clip(name: 'x', notes: [_n(0, 60), _n(0, 64), _n(0, 67)]),
        ),
        MidiClipRole.chords,
      );
      expect(
        suggestMidiClipRole(_clip(name: 'x', notes: [_n(0, 36), _n(240, 38)])),
        MidiClipRole.bass,
      );
      expect(
        suggestMidiClipRole(_clip(name: 'x', notes: [_n(0, 72), _n(240, 74)])),
        MidiClipRole.melody,
      );
      expect(
        suggestMidiClipRole(_clip(name: 'x', notes: [])),
        MidiClipRole.other,
      );
    });
  });

  group('midiClipGrid', () {
    test('the finest grid every note starts on', () {
      expect(midiClipGrid(_clip(notes: [_n(0, 60), _n(480, 60)])), '1-4');
      expect(midiClipGrid(_clip(notes: [_n(0, 60), _n(240, 60)])), '1-8');
      expect(midiClipGrid(_clip(notes: [_n(120, 60), _n(360, 60)])), '1-16');
      expect(
        midiClipGrid(_clip(notes: [_n(0, 60), _n(160, 60), _n(320, 60)])),
        '1-8T',
      );
      expect(midiClipGrid(_clip(notes: [_n(60, 60)])), '1-32');
    });

    test('played in off any grid, or empty: none', () {
      expect(midiClipGrid(_clip(notes: [_n(0, 60), _n(17, 60)])), isNull);
      expect(midiClipGrid(_clip(notes: [])), isNull);
    });
  });

  test('bars count in the time signature, rounded up, at least one', () {
    expect(midiClipBars(_clip(length: 1920 * 4), TimeSignature.common), 4);
    expect(midiClipBars(_clip(length: 1920 * 4), const TimeSignature(3, 4)), 6);
    expect(midiClipBars(_clip(length: 1921), TimeSignature.common), 2);
    expect(midiClipBars(_clip(length: 0), TimeSignature.common), 1);
  });

  group('MidiNamingTemplate', () {
    test('round-trips; unknown fields are skipped', () {
      const t = MidiNamingTemplate(
        numbered: false,
        fields: [MidiNameField.bpm, MidiNameField.name, MidiNameField.grid],
        separator: '_',
      );
      expect(MidiNamingTemplate.fromJson(t.toJson()), t);
      expect(
        MidiNamingTemplate.fromJson({
          'fields': ['name', 'mood', 'bpm'],
        }).fields,
        [MidiNameField.name, MidiNameField.bpm],
      );
      expect(MidiNamingTemplate.fromJson(null), MidiNamingTemplate.standard);
    });
  });

  group('midiNameParts', () {
    test('writes each piece, leaving out what has nothing to say', () {
      final parts = midiNameParts(
        _item('Line', bpm: 140, key: 'A minor'),
        labels: _labels,
        voice: SynthVoice.bass,
      );
      expect(parts[MidiNameField.name], 'Line');
      expect(parts[MidiNameField.role], 'Bass');
      expect(parts[MidiNameField.bpm], '140BPM');
      expect(parts[MidiNameField.key], 'A minor');
      expect(parts[MidiNameField.bars], '1 bar');
      expect(
        parts[MidiNameField.timeSignature],
        isNull,
        reason: '4/4 goes unsaid',
      );
      expect(parts[MidiNameField.grid], '1-4');
      expect(parts[MidiNameField.instrument], 'Inst:bass');
    });

    test('a time signature other than 4/4, a fractional tempo, no key', () {
      final parts = midiNameParts(
        _item('Waltz', bpm: 92.5, timeSig: '3/4'),
        labels: _labels,
        voice: SynthVoice.keys,
      );
      expect(parts[MidiNameField.timeSignature], '3-4');
      expect(parts[MidiNameField.bpm], '92.5BPM');
      expect(parts[MidiNameField.key], isNull);
      expect(
        parts[MidiNameField.bars],
        '2 bars',
        reason: '1920 ticks in 3/4 is a bar and a third, rounded up',
      );
    });

    test('the given name and the chosen role win; a set tempo wins', () {
      final parts = midiNameParts(
        _item('Line', title: 'Big riff', role: 'chords', bpm: 140),
        labels: _labels,
        voice: SynthVoice.bass,
        bpm: 128,
      );
      expect(parts[MidiNameField.name], 'Big riff');
      expect(parts[MidiNameField.role], 'Chords');
      expect(parts[MidiNameField.bpm], '128BPM');
    });

    test('unquantized notes are "free"', () {
      final parts = midiNameParts(
        _item('x', clip: _clip(notes: [_n(13, 60)])),
        labels: _labels,
        voice: SynthVoice.lead,
      );
      expect(parts[MidiNameField.grid], 'free');
    });
  });

  group('midiTemplateFileName', () {
    final parts = {
      MidiNameField.name: 'Line',
      MidiNameField.role: 'Bass',
      MidiNameField.bpm: '140BPM',
      MidiNameField.key: null,
      MidiNameField.bars: '4 bars',
    };

    test('numbered and in the template order, skipping empty pieces', () {
      expect(
        midiTemplateFileName(MidiNamingTemplate.standard, parts, number: 3),
        '03 Line - Bass - 140BPM - 4 bars.mid',
      );
      expect(
        midiTemplateFileName(
          MidiNamingTemplate.standard,
          parts,
          number: 7,
          width: 3,
        ),
        '007 Line - Bass - 140BPM - 4 bars.mid',
      );
    });

    test('unnumbered, reordered, another separator', () {
      const t = MidiNamingTemplate(
        numbered: false,
        fields: [MidiNameField.bpm, MidiNameField.role, MidiNameField.name],
        separator: '_',
      );
      expect(midiTemplateFileName(t, parts, number: 1), '140BPM_Bass_Line.mid');
    });

    test('safe on every filesystem; nothing to say is still a name', () {
      expect(
        midiTemplateFileName(
          const MidiNamingTemplate(
            numbered: false,
            fields: [MidiNameField.name],
          ),
          {MidiNameField.name: 'A/B: what? '},
        ),
        'A_B_ what_.mid',
      );
      expect(
        midiTemplateFileName(
          const MidiNamingTemplate(
            numbered: false,
            fields: [MidiNameField.key],
          ),
          const {},
        ),
        'MIDI clip.mid',
      );
    });
  });

  group('names from the scheme', () {
    const template = MidiNamingTemplate(numbered: false);
    final parts = {
      MidiNameField.name: 'MIDI 01',
      MidiNameField.role: 'Bass',
      MidiNameField.bpm: '140BPM',
      MidiNameField.key: 'Am',
      MidiNameField.bars: '4 bars',
    };

    test('a scheme name is every piece but the name, unnumbered', () {
      expect(
        midiSchemeName(MidiNamingTemplate.standard, parts),
        'Bass - 140BPM - Am - 4 bars',
      );
      expect(
        midiSchemeName(
          const MidiNamingTemplate(fields: [MidiNameField.name]),
          parts,
        ),
        'Bass',
        reason: 'a template of the name alone falls back to the role',
      );
    });

    test('a clip named by the scheme does not say it twice in its file', () {
      final named = {
        ...parts,
        MidiNameField.name: 'Bass - 140BPM - Am - 4 bars',
      };
      expect(
        midiTemplateFileName(template, named),
        'Bass - 140BPM - Am - 4 bars.mid',
      );
      final retempo = {...named, MidiNameField.bpm: '128BPM'};
      expect(
        midiTemplateFileName(template, retempo),
        'Bass - 140BPM - Am - 4 bars - 128BPM.mid',
        reason: 'only what the name already says is left out',
      );
      final own = {...parts, MidiNameField.name: 'Acid bass'};
      expect(
        midiTemplateFileName(template, own),
        'Acid bass - Bass - 140BPM - Am - 4 bars.mid',
        reason: 'a word inside a name is not a piece of it',
      );
    });

    test('repeated proposals are numbered, ignoring case', () {
      expect(uniqueClipNames(['Bass', 'bass', 'Pad', 'Bass']), [
        'Bass',
        'bass 2',
        'Pad',
        'Bass 3',
      ]);
    });
  });

  group('planCollectionExport', () {
    String name(MidiCollectionItem i, int n, int w) =>
        '${n.toString().padLeft(w, '0')} ${i.clip.name}.mid';

    test('each folder numbers its own clips, in the collection order', () {
      final c = MidiCollection(
        id: 'c',
        name: 'Pack',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        folders: const [
          MidiCollectionFolder(id: 'f1', name: 'Bass'),
          MidiCollectionFolder(id: 'f2', name: 'Sub: deep', parentId: 'f1'),
        ],
        items: [
          _item('a', folder: 'f1'),
          _item('b'),
          _item('c', folder: 'f2'),
          _item('d', folder: 'f1'),
          _item('e', folder: 'gone'),
        ],
      );
      final plan = planCollectionExport(c, fileNameOf: name);
      expect(
        {for (final f in plan) f.item.id: f.relativePath},
        {
          'a': 'Bass/01 a.mid',
          'b': '01 b.mid',
          'c': 'Bass/Sub_ deep/01 c.mid',
          'd': 'Bass/02 d.mid',
          'e': '02 e.mid',
        },
      );
    });

    test('a hundred clips number to three digits; same names made unique', () {
      final c = MidiCollection(
        id: 'c',
        name: 'Pack',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        items: [
          for (var i = 0; i < 100; i++) _item('x$i', clip: _clip(name: 'x')),
        ],
      );
      final plan = planCollectionExport(
        c,
        fileNameOf: (i, n, w) => n.toString().padLeft(w, '0'),
      );
      expect(plan.first.fileName, '001');
      final same = planCollectionExport(c, fileNameOf: (i, n, w) => 'Same.mid');
      expect(same.take(3).map((f) => f.fileName), [
        'Same.mid',
        'Same (2).mid',
        'Same (3).mid',
      ]);
    });
  });

  group('ideaItemToSave', () {
    final draft = _item('idea', clip: _clip(name: 'Idea 1'), bpm: 120);

    test('the first save takes the name, role and folder chosen', () {
      final item = ideaItemToSave(
        draft,
        name: ' Acid line ',
        role: MidiClipRole.bass,
        folderId: 'f1',
      );
      expect(item.clip.name, 'Acid line');
      expect(item.role, 'bass');
      expect(item.folderId, 'f1');
      expect(item.bpm, 120);
    });

    test('later saves keep what the saved copy was given since', () {
      final saved = _item(
        'idea',
        clip: _clip(name: 'Acid line'),
        title: 'Renamed',
        role: 'lead',
        folder: 'f2',
      );
      final edited = _item(
        'idea',
        clip: _clip(name: 'Idea 1', notes: [_n(0, 40)]),
        bpm: 128,
      );
      final item = ideaItemToSave(edited, saved: saved, name: 'ignored');
      expect(item.clip.name, 'Acid line');
      expect(item.clip.notes.single.pitch, 40, reason: 'the new notes');
      expect(item.title, 'Renamed');
      expect(item.role, 'lead');
      expect(item.folderId, 'f2');
      expect(item.bpm, 128);
    });
  });
}
