import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/services/daw_parsers/reaper_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/project_anatomy_reader.dart';

/// What the Inspector reads from a REAPER project (#226), on projects laid
/// out the way the real ones in test/fixtures/projects/reaper/ are — for
/// what none of them has: AU, CLAP and LV2 plug-ins, input FX, a soloed
/// track, hardware outputs on a track, a project that sets its rate.
///
/// Line by line: `ISBUS 1 1` opens a folder and `ISBUS 2 -n` on its last
/// track closes n of them; `VOLPAN gain pan`; `MUTESOLO mute solo`; a send
/// is an `AUXRECV source mode gain pan mute mono phase srcChan dstChan` on
/// the track that receives it; each plug-in in an FX chain follows its
/// `BYPASS bypass offline` and precedes its `PRESETNAME`.
const _rpp = '''
<REAPER_PROJECT 0.1 "7.27/win64" 1727000000
  SAMPLERATE 48000 1 0
  <RECORD_CFG
    ZXZhdxgIAA==
  >
  TEMPO 128 7 8
  MASTER_VOLUME 0.5 0.25 -1 -1 1
  MASTERMUTESOLO 1
  MASTERHWOUT 2 0 1 0 0 0 0 -1
  <MASTERFXLIST
    SHOW 0
    BYPASS 0 0 0
    <VST "VST3: Pro-L 2 (FabFilter)" "FabFilter Pro-L 2.vst3" 0 "" 1179013234{72C4DB717A4D459AB97E51745D84B39D} ""
      cHJvbA==
    >
    PRESETNAME "Mastering"
  >
  <TRACK {1}
    NAME Drums
    ISBUS 1 1
    VOLPAN 0.5 0 -1 -1 1
    MUTESOLO 0 0 0
    MAINSEND 1 0
  >
  <TRACK {2}
    NAME "Kick In"
    ISBUS 0 0
    VOLPAN 1 -0.5 -1 -1 1
    MUTESOLO 0 2 0
    MAINSEND 1 0
    <FXCHAIN
      BYPASS 1 0 0
      <AU "AU: AUDelay (Apple)" "Apple: AUDelay" "" 1635083896<...>
      >
      BYPASS 0 1 0
      <CLAP "CLAP: Surge XT Effects (Surge Synth Team)" org.surge-synth-team.surge-xt-fx ""
      >
      BYPASS 0 0 0
      <LV2 "LV2: Dragonfly Room Reverb (Michael Willis)" urn:dragonfly:room ""
      >
    >
  >
  <TRACK {3}
    NAME Toms
    ISBUS 1 1
    MAINSEND 1 0
  >
  <TRACK {4}
    NAME "Tom 1"
    ISBUS 2 -2
    MAINSEND 1 0
    <ITEM
      <TAKEFX
        BYPASS 0 0 0
        <VST "VST: ReaPitch (Cockos)" reapitch.dll 0 "" 1919250531<5653547270746372656170697463>
        >
      >
    >
  >
  <TRACK {5}
    NAME Bass
    ISBUS 0 0
    MAINSEND 0 0
    HWOUT 4 0 1 0 0 0 0 -1:U -1
    AUXRECV 1 3 0.5 0 1 0 0 0 2 -1:U 0 -1 ''
    AUXRECV 0 1 0 0 0 0 0 -1 0 -1:U 0 -1 ''
    <FXCHAIN_REC
      BYPASS 0 0 0
      <JS "ReaTeam JSFX/Utility/zenomod_VU Meter (ZenoMOD).jsfx" ""
      >
    >
    <FXCHAIN
      BYPASS 0 0 0
      <VST "VST3i: MODO BASS 2 (IK Multimedia) (32 out)" "MODO BASS 2.vst3" 0 "" 284572272{5653544D4253326D6F646F2062617373} ""
      >
      PRESETNAME "Fingered"
      BYPASS 0 0 0
      <VST "VST: BigRock (x86) (ArtsAcoustic)" BigRock.dll 0 "" 1112098667<56535442>
      >
      BYPASS 0 0 0
      <VST "VST3: UADx Empirical Labs Distressor (Universal Audio (UADx))" "UADx Distressor.vst3" 0 "" 12{ABCDEF0123456789ABCDEF0123456789} ""
      >
    >
  >
  <TRACK {6}
  >
>
''';

void main() {
  final parser = ReaperProjectParser(_rpp);
  final tracks = parser.readTracks();
  ReaperTrack track(String name) => tracks.firstWhere((t) => t.name == name);

  group('readTracks', () {
    test(
      'every track in order, an unnamed one by its number, the master last',
      () {
        expect(
          [for (final t in tracks) t.name],
          ['Drums', 'Kick In', 'Toms', 'Tom 1', 'Bass', 'Track 6', 'Master'],
        );
        expect(tracks.last.kind, ReaperTrackKind.master);
      },
    );

    test('folders open with ISBUS 1 and close as many as ISBUS 2 -n says', () {
      expect(track('Drums').kind, ReaperTrackKind.folder);
      expect(track('Drums').folder, isNull);
      expect(track('Kick In').folder, 'Drums');
      expect(track('Toms').folder, 'Drums');
      expect(track('Tom 1').folder, 'Toms');
      expect(track('Bass').folder, isNull, reason: 'ISBUS 2 -2 closed both');
    });

    test('the fader, the pan, mute and solo', () {
      expect(track('Drums').volume, 0.5);
      expect(track('Kick In').pan, -0.5);
      expect(
        track('Kick In').soloed,
        isTrue,
        reason: 'solo 2 is solo in place',
      );
      expect(track('Kick In').muted, isFalse);
      expect(track('Toms').volume, isNull, reason: 'no VOLPAN: not known');
    });

    test('each plug-in takes the BYPASS line before it', () {
      final fx = track('Kick In').fx;
      expect(
        [for (final f in fx) (f.name, f.bypassed, f.offline)],
        [
          ('AUDelay', true, false),
          ('Surge XT Effects', false, true),
          ('Dragonfly Room Reverb', false, false),
        ],
      );
    });

    test('formats, makers and ids, AU naming its maker first', () {
      final fx = track('Kick In').fx;
      expect(
        [for (final f in fx) (f.format, f.vendor, f.pluginId)],
        [
          ('AU', 'Apple', 'Apple: AUDelay'),
          ('CLAP', 'Surge Synth Team', 'org.surge-synth-team.surge-xt-fx'),
          ('LV2', 'Michael Willis', null),
        ],
      );
    });

    test('names lose channel layouts and the 32-bit bridge, keep a maker '
        'in brackets of its own', () {
      final fx = track('Bass').fx;
      expect(
        [for (final f in fx) (f.name, f.vendor)],
        [
          ('MODO BASS 2', 'IK Multimedia'),
          ('BigRock', 'ArtsAcoustic'),
          ('UADx Empirical Labs Distressor', 'Universal Audio (UADx)'),
        ],
      );
    });

    test('a VST3 by its class id, a VST2 by its unique id', () {
      final fx = track('Bass').fx;
      expect(fx[0].pluginId, '5653544D4253326D6F646F2062617373');
      expect(fx[0].format, 'VST3');
      expect(fx[1].pluginId, '1112098667');
      expect(fx[1].format, 'VST2');
    });

    test('the instrument is the first VSTi, with the preset after it', () {
      final bass = track('Bass');
      expect(bass.kind, ReaperTrackKind.instrument);
      expect(bass.instrument?.name, 'MODO BASS 2');
      expect(bass.instrument?.preset, 'Fingered');
    });

    test('item FX and input FX are kept apart from the channel', () {
      expect(track('Tom 1').fx, isEmpty);
      expect([for (final f in track('Tom 1').itemFx) f.name], ['ReaPitch']);
      expect(
        [for (final f in track('Bass').inputFx) f.name],
        ['zenomod_VU Meter (ZenoMOD)'],
      );
      expect(track('Bass').inputFx.single.format, 'JS');
    });

    test('sends are read on the track that receives them', () {
      final r = track('Bass').receives;
      expect(r, hasLength(2));
      expect(r[0].sourceIndex, 1);
      expect(r[0].preFader, isTrue, reason: 'mode 3 is pre-fader, post-FX');
      expect(r[0].muted, isTrue);
      expect(r[0].destinationChannel, 2);
      expect(r[1].midiOnly, isTrue, reason: 'source channel -1');
      expect(r[1].preFader, isTrue, reason: 'mode 1 is pre-FX');
    });

    test('not to the parent: a hardware output instead', () {
      expect(track('Bass').sendsToParent, isFalse);
      expect(track('Bass').hardwareOutputs, [4]);
      expect(track('Drums').sendsToParent, isTrue);
    });

    test('the master: fader, pan, mute flags, FX, output', () {
      final m = tracks.last;
      expect(m.volume, 0.5);
      expect(m.pan, 0.25);
      expect(m.muted, isTrue);
      expect(m.soloed, isFalse);
      expect(m.hardwareOutputs, [2]);
      expect(m.fx.single.name, 'Pro-L 2');
      expect(m.fx.single.preset, 'Mastering');
    });
  });

  group('the project', () {
    test('a sample rate the project sets', () {
      expect(parser.readSampleRate(), 48000);
    });

    test('a sample rate it only follows from the device is not its own', () {
      expect(
        ReaperProjectParser(
          _rpp.replaceFirst('SAMPLERATE 48000 1 0', 'SAMPLERATE 44100 0 0'),
        ).readSampleRate(),
        isNull,
      );
    });

    test('the recording format: WAV at its bits per sample', () {
      expect(parser.readRecordBitDepth(), 24);
      final flac = base64.encode('calf'.codeUnits + [24, 0]);
      expect(
        ReaperProjectParser(
          _rpp.replaceFirst('ZXZhdxgIAA==', flac),
        ).readRecordBitDepth(),
        isNull,
        reason: 'only WAV says where its bits are',
      );
    });

    test('the time signature, from TEMPO', () {
      expect(parser.readTimeSignature(), (7, 8));
    });
  });

  group('reaperAnatomy', () {
    final a = reaperAnatomy(
      filePath: 'Song.rpp',
      content: _rpp,
      fileSize: _rpp.length,
    );
    AnatomyChannel channel(String name) =>
        a.channels!.firstWhere((c) => c.name == name);

    test('channel kinds: a folder track mixes, so it is a group', () {
      expect(channel('Drums').kind, AnatomyChannelKind.group);
      expect(channel('Bass').kind, AnatomyChannelKind.instrument);
      expect(channel('Master').kind, AnatomyChannelKind.master);
    });

    test('outputs: the folder, the master, or the hardware', () {
      expect(channel('Kick In').output, 'Drums');
      expect(channel('Drums').output, 'Master');
      expect(channel('Bass').output, 'Out 5/6');
      expect(channel('Master').output, 'Out 3/4');
    });

    test(
      'sends on the sender, naming a side-chain and MIDI by what they are',
      () {
        final kick = channel('Kick In').sends.single;
        expect(kick.destination, 'Bass (3/4)');
        expect(kick.on, isFalse);
        expect(kick.preFader, isTrue);
        expect(kick.levelDb, closeTo(-6.02, 0.01));
        expect(channel('Drums').sends.single.destination, 'Bass (MIDI)');
        expect(channel('Drums').sends.single.levelDb, double.negativeInfinity);
      },
    );

    test('inserts: the instrument left out, slots kept, offline is off', () {
      final bass = channel('Bass');
      expect(bass.instrument, 'MODO BASS 2');
      expect(bass.instrumentPreset, 'Fingered');
      expect(
        [for (final i in bass.inserts) (i.slot, i.plugin)],
        [(1, 'BigRock'), (2, 'UADx Empirical Labs Distressor')],
      );
      expect(
        [for (final i in channel('Kick In').inserts) i.deactivated],
        [true, true, false],
      );
    });

    test('the project facts', () {
      expect(a.sampleRate, 48000);
      expect(a.bitDepth, 24);
      expect(a.timeSignature, (7, 8));
      expect(a.pluginInstancesKnown, isTrue);
    });

    test('plug-ins: item and input FX count, each with its tracks', () {
      final names = {for (final pl in a.plugins) pl.name: pl};
      expect(names['ReaPitch']?.channels, ['Tom 1']);
      expect(names['ReaPitch']?.stock, isTrue);
      expect(names['zenomod_VU Meter (ZenoMOD)']?.stock, isTrue);
      expect(names['Pro-L 2']?.stock, isFalse);
      expect(names['MODO BASS 2']?.role, AnatomyPluginRole.instrument);
      expect(names['Pro-L 2']?.channels, ['Master']);
    });
  });

  group('reaperGainDb', () {
    test('a gain in dB, silence as minus infinity', () {
      expect(reaperGainDb(1), 0);
      expect(reaperGainDb(2), closeTo(6.02, 0.01));
      expect(reaperGainDb(0), double.negativeInfinity);
    });

    test('the fader drawn bottom to top', () {
      expect(reaperFaderPosition(double.negativeInfinity), 0);
      expect(reaperFaderPosition(0), 0.8);
      expect(reaperFaderPosition(12), 1);
      expect(reaperFaderPosition(-6), lessThan(0.8));
    });
  });
}
