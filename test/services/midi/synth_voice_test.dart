import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';

MidiClip _clip({String name = '', String? track, int pitch = 60}) => MidiClip(
      name: name,
      trackName: track,
      ppq: 480,
      lengthTicks: 1920,
      notes: [MidiNote(startTick: 0, lengthTicks: 240, pitch: pitch, velocity: 100)],
    );

void main() {
  group('voiceFromName', () {
    final cases = <String, SynthVoice>{
      'Main Lead Dry 1': SynthVoice.lead,
      'MainLead2': SynthVoice.lead,
      'Bassline Serum': SynthVoice.bass,
      'Sub 808': SynthVoice.bass,
      'Kick 3 01': SynthVoice.kick,
      'kick bass': SynthVoice.kick, // drums win over bass
      'Snare Roll': SynthVoice.snare,
      'Claps': SynthVoice.clap,
      'Open Hat': SynthVoice.hiHat,
      'RTW_145_Psy_Hats': SynthVoice.hiHat,
      'Perc Loop': SynthVoice.percussion,
      'Drums': SynthVoice.drumKit,
      'Warm Pad': SynthVoice.pad,
      'Pluck Arp': SynthVoice.pluck,
      'Rhodes': SynthVoice.keys,
      'Grand Piano': SynthVoice.keys,
      'EP chords': SynthVoice.keys,
      'Hammond Organ': SynthVoice.organ,
      'Violins': SynthVoice.strings,
      'Marimba': SynthVoice.bell,
    };
    // Names two families; rule order (pluck before brass) decides.
    cases['Brass Stabs'] = SynthVoice.pluck;

    for (final e in cases.entries) {
      test('"${e.key}" → ${e.value.name}', () {
        expect(voiceFromName(e.key), e.value);
      });
    }

    test('names that say nothing about the sound', () {
      for (final name in ['Serum 01', 'Diva 01', 'MIDI 01', 'Audio 3', '', null]) {
        expect(voiceFromName(name), isNull, reason: '$name');
      }
    });

    test('short fragments only match as whole words', () {
      expect(voiceFromName('Subtle Texture'), SynthVoice.pad,
          reason: '"sub" inside "Subtle" is not a bass');
      expect(voiceFromName('Sharp Synth'), isNull,
          reason: '"arp" inside "Sharp" is not an arpeggio');
      expect(voiceFromName('Ch 1'), isNull);
      expect(voiceFromName('Breakdown Lead'), SynthVoice.lead);
    });
  });

  group('inferSynthVoice', () {
    test('the track name wins over the clip name', () {
      expect(inferSynthVoice(_clip(name: 'Lead riff', track: 'Bass')),
          SynthVoice.bass);
    });

    test('falls back to the clip name when the track says nothing', () {
      expect(inferSynthVoice(_clip(name: 'Intro Lead Dry_midi', track: 'Diva 01')),
          SynthVoice.lead);
    });

    test('a clip that sits entirely low is a bass', () {
      expect(inferSynthVoice(_clip(track: 'Serum 01', pitch: 36)), SynthVoice.bass);
    });

    test('anything else gets the default synth', () {
      expect(inferSynthVoice(_clip(track: 'Serum 01')), SynthVoice.keys);
    });
  });

  test('drum voices are the ones from the drum kit on', () {
    expect(SynthVoice.kick.isDrum, isTrue);
    expect(SynthVoice.drumKit.isDrum, isTrue);
    expect(SynthVoice.bell.isDrum, isFalse);
  });

  test('synth is retired: it sounded the same as bass', () {
    expect(SynthVoice.values.map((v) => v.name), isNot(contains('synth')));
    expect(SynthVoice.values.where((v) => v.name == 'synth').firstOrNull,
        isNull,
        reason: 'a stored pick of it names no voice, so it is inferred again');
  });
}
