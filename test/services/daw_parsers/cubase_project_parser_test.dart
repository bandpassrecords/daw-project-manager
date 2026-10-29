import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/sample_reference.dart';
import 'package:daw_project_manager/services/daw_parsers/cubase_attributes.dart';
import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';

import '../../helpers/cubase_archive.dart';

Uint8List _project() {
  final a = CubaseArchive();
  a.begin('MTrackList');
  // The VST Instruments rack, as Cubase 13 shows it: a folder per
  // instrument, device tracks for its outputs, no channel inside them. It
  // comes first, and must not be taken for the I/O folder.
  a.track('MFolderTrack', 'VST Instruments', () {
    a.track('MFolderTrack', 'HALion Sonic', () {
      a.track('MDeviceTrackEvent', 'HALion Sonic');
      a.track('MDeviceTrackEvent', 'HSSE Main');
    });
  });
  // Cubase's hidden output folder: its device track is an output, not a group.
  a.track('MFolderTrack', 'Input/Output Channels', () {
    a.track('MDeviceTrackEvent', 'Stereo Out', () {
      a.channel(ownBus: 1, outBus: 0, ownName: 'Stereo Out');
    });
  });
  a.track('MAudioTrackEvent', 'Vocals', () {
    a.channel(
      ownBus: 10,
      outBus: 1,
      inserts: {0: ('Pro-Q 3', false), 2: ('LFOTool_x64', true)},
      sends: [
        (0, 30, 15000, true, false), // to the reverb
        (1, 40, 25856, true, true), // into Guitar's compressor side-chain
        (3, 30, 12000, false, false), // routed but switched off
      ],
    );
  });
  a.track('MAudioTrackEvent', 'Guitar', () {
    a.channel(
      ownBus: 11,
      outBus: 20,
      inserts: {0: ('Compressor', false)},
      sideChains: {0: 40},
      volume: 20000,
      pan: 0.25,
      muted: true,
      eqBandsOn: 2,
    );
  });
  a.track('MFolderTrack', 'Synths', () {
    a.track('MInstrumentTrackEvent', 'Serum 01', () {
      a.channel(
        ownBus: 12,
        outBus: 20,
        type: 4,
        instrument: 'Serum',
        instrumentLabel: 'Bass Serum',
      );
      a.plugin('Bass Serum', original: 'Serum');
      a.midiPart('Bassline', 1920, [
        (-960, 30, 90, 120), // trimmed away before the part start
        (0, 36, 100, 240),
        (480, 38, 0, 240), // velocity 0 must not become a note-off
        (1800, 40, 80, 480), // runs past the end: shortened to 120
      ]);
      // A copy of the same part elsewhere on the track.
      a.midiPart('Bassline', 1920, [
        (0, 36, 100, 240),
        (480, 38, 0, 240),
        (1800, 40, 80, 480),
      ]);
    });
    a.track('MMidiTrackEvent', 'MIDI 01');
  });
  a.track('MSamplerTrackEvent', 'Kick sample', () {
    a.plugin('Kick sample', original: 'Sampler Track');
  });
  a.track('MDeviceTrackEvent', 'Drum Group', () {
    a.channel(ownBus: 20, outBus: 1, type: 2, ownName: 'Drum Group');
    a.plugin('Standard Panner');
    a.plugin('Pro-Q 3');
    a.plugin('LFOTool_x64');
  });
  a.track('MDeviceTrackEvent', 'Reverb', () {
    a.channel(ownBus: 30, outBus: 1, type: 6, ownName: 'Reverb');
  });
  a.end();
  a.begin('PVSTInstrumentRack');
  a.rackSlot('HALion Sonic', ['HSSE Main']);
  a.end();
  // The studio: ports as PortDescriptors names them, then an input and an
  // output channel naming their bus's ports, as Cubase 13 writes them.
  a.begin('PVSTConnections');
  a.attr('PortDescriptors', <Map<String, Object>>[
    {
      'ID': 'I|Windows MIDI|Studio 24c MIDI In',
      'Type': 'midi',
      'Subtype': 'system',
    },
    {
      'ID': 'I|Studio USB ASIO Driver|Input 1',
      'Type': 'audio',
      'Subtype': 'system',
      'Role': 'left',
    },
    {
      'ID': 'I|Studio USB ASIO Driver|Input 2',
      'Type': 'audio',
      'Subtype': 'system',
      'Role': 'right',
    },
    {
      'ID': 'O|Studio USB ASIO Driver|Main Out Left',
      'Type': 'audio',
      'Subtype': 'system',
      'Role': 'left',
    },
    {
      'ID': 'O|Studio USB ASIO Driver|Main Out Right',
      'Type': 'audio',
      'Subtype': 'system',
      'Role': 'right',
    },
    // An instrument's own MIDI input: not the studio's.
    {
      'ID': 'O|5B6D6402C5F74C35B3BE88ADF7FC7D27-1|Input 1',
      'Type': 'midi',
      'Subtype': 'side',
      'UserName': 'HALion',
    },
  ]);
  a.attr(
    'Connections',
    const CubaseStrings([
      'I|Studio USB ASIO Driver|Input 1',
      'I|Studio USB ASIO Driver|Input 2',
    ]),
  );
  a.attr('InputBusValue', {'Value': 0});
  a.attr('OutputBusValue', {'Value': 0});
  a.attr('OutputBus', {'Name': 'Stereo In', 'Bus UID': 50, 'Bus Type': 12});
  a.attr('OwnInputBus', {'Name': 'Stereo Out', 'Bus UID': 1, 'Bus Type': 18});
  a.attr(
    'Connections',
    const CubaseStrings([
      'O|Studio USB ASIO Driver|Main Out Left',
      'O|Studio USB ASIO Driver|Main Out Right',
    ]),
  );
  a.end();
  a.begin('StMedia::PAttributes');
  a.mediaAttribute('AudioSampleRate', 'Float', 48000.0);
  a.mediaAttribute('AudioSampleSize', 'Long', 24);
  a.mediaAttribute(
    'MusicalSignature',
    'Object',
    const CubaseObject('CmRational', {'Numerator': 3, 'Denominator': 4}),
  );
  a.end();
  return a.toCpr();
}

void main() {
  late CubaseProjectParser parser;

  setUp(() => parser = CubaseProjectParser(_project()));

  test('recognises the RIFF/NUND container and nothing else', () {
    expect(parser.isCubaseFile, isTrue);
    expect(
      CubaseProjectParser(
        Uint8List.fromList(utf8.encode('not a cpr at all')),
      ).isCubaseFile,
      isFalse,
    );
  });

  group('readStats', () {
    test('carries the sample rate and bit depth', () {
      final stats = parser.readStats();
      expect((stats.sampleRate, stats.bitDepth), (48000, 24));
    });

    test('counts every track kind, following back-references', () {
      // Two audio tracks: the second is written as a reference, not a name —
      // counting class names alone would find one.
      final stats = parser.readStats();
      expect(stats.audioTracks, 2);
      expect(stats.instrumentTracks, 1);
      expect(stats.midiTracks, 1);
      expect(stats.samplerTracks, 1);
    });

    test(
      'the output folder and its outputs are not counted as user tracks',
      () {
        final stats = parser.readStats();
        expect(stats.folderTracks, 1, reason: 'only "Synths", not the rack');
        expect(
          stats.busTracks,
          2,
          reason: '"Drum Group" and "Reverb"; not Stereo Out or HSSE Main',
        );
      },
    );

    test('lists real plug-ins, by their original name when renamed', () {
      expect(parser.readStats().plugins, [
        'Compressor',
        'HALion Sonic',
        'LFOTool',
        'Pro-Q 3',
        'Serum',
      ]);
    });

    test('counts distinct MIDI clips', () {
      expect(parser.readStats().midiClipCount, 1);
      expect(parser.readStats(countMidiClips: false).midiClipCount, isNull);
    });
  });

  group('readTracks', () {
    test('lists tracks in project order, each with the folder holding it', () {
      final tracks = parser.readTracks();
      expect(
        [for (final t in tracks) (t.name, t.type, t.parent)],
        [
          ('Vocals', CubaseTrackType.audio, null),
          ('Guitar', CubaseTrackType.audio, null),
          ('Synths', CubaseTrackType.folder, null),
          ('Serum 01', CubaseTrackType.instrument, 'Synths'),
          ('MIDI 01', CubaseTrackType.midi, 'Synths'),
          ('Kick sample', CubaseTrackType.sampler, null),
          ('Drum Group', CubaseTrackType.group, null),
          ('Reverb', CubaseTrackType.fx, null),
        ],
      );
      expect([for (final t in tracks) t.index], [0, 1, 2, 3, 4, 5, 6, 7]);
    });

    test('a track\'s output is the channel that owns the bus it points at', () {
      final out = {for (final t in parser.readTracks()) t.name: t.output};
      expect(out['Vocals'], 'Stereo Out', reason: 'an output device');
      expect(out['Guitar'], 'Drum Group');
      expect(out['Serum 01'], 'Drum Group');
      expect(out['Drum Group'], 'Stereo Out');
      expect(out['MIDI 01'], isNull, reason: 'no channel, nothing to say');
    });

    test(
      'reads inserts by slot, empty slots skipped, deactivated ones marked',
      () {
        // Cubase writes a slot's State and SlotType after its plug-in: read the
        // other way round, slot 0's plug-in was dropped and every plug-in got
        // the slot before's state. Bypass isn't stored readably: null.
        final vocals = parser.readTracks().firstWhere(
          (t) => t.name == 'Vocals',
        );
        expect(
          [
            for (final i in vocals.inserts)
              (i.slot, i.plugin, i.pluginId, i.deactivated, i.bypassed),
          ],
          [
            (0, 'Pro-Q 3', 'ID-Pro-Q 3', false, null),
            (2, 'LFOTool_x64', 'ID-LFOTool_x64', true, null),
          ],
        );
      },
    );

    test("a plug-in alone in slot 0 is read", () {
      // Main Lead Group in a real Cubase 13 project had only slot 0 filled,
      // and was read with no inserts at all.
      final guitar = parser.readTracks().firstWhere((t) => t.name == 'Guitar');
      expect([for (final i in guitar.inserts) i.plugin], ['Compressor']);
    });

    test('device tracks are groups or FX channels by their channel', () {
      final types = {for (final t in parser.readTracks()) t.name: t.type};
      expect(types['Drum Group'], CubaseTrackType.group);
      expect(types['Reverb'], CubaseTrackType.fx);
    });

    test('the fader, solo and EQ as the channel stores them', () {
      final byName = {for (final t in parser.readTracks()) t.name: t};
      expect(byName['Guitar']!.volume, 20000);
      expect(byName['Guitar']!.muted, isTrue);
      expect(byName['Guitar']!.soloed, isFalse);
      expect(byName['Guitar']!.eqBandsOn, 2);
      expect(byName['Guitar']!.pan, 0.25);
      expect(byName['Vocals']!.pan, 0.5, reason: 'the centre');
      expect(byName['Vocals']!.volume, CubaseProjectParser.unityVolume);
      expect(byName['Vocals']!.soloed, isFalse);
      expect(byName['Vocals']!.muted, isFalse);
      expect(byName['Vocals']!.phaseInverted, isFalse);
      expect(byName['MIDI 01']!.volume, isNull, reason: 'no channel');
    });

    test('sends: destination, level, on and pre-fader; side-chains named', () {
      final vocals = parser.readTracks().firstWhere((t) => t.name == 'Vocals');
      expect(
        [
          for (final s in vocals.sends)
            (s.slot, s.destination, s.sideChainOf, s.level, s.on, s.preFader),
        ],
        [
          (0, 'Reverb', null, 15000, true, false),
          (1, 'Guitar', 'Compressor', 25856, true, true),
          (3, 'Reverb', null, 12000, false, false),
        ],
      );
      final guitar = parser.readTracks().firstWhere((t) => t.name == 'Guitar');
      expect(guitar.sends, isEmpty, reason: 'unrouted slots are left out');
    });

    test('an instrument track names its instrument, not its label', () {
      final serum = parser.readTracks().firstWhere((t) => t.name == 'Serum 01');
      expect(serum.instrument, 'Serum', reason: 'renamed "Bass Serum"');
      expect(serum.instrumentPreset, 'Init Saw');
      expect(serum.instrumentId, startsWith('565354'));
    });

    group('channel strip', () {
      List<CubaseTrack> read(void Function(CubaseArchive a) channels) {
        final a = CubaseArchive()..begin('MTrackList');
        channels(a);
        a.end();
        return CubaseProjectParser(a.toCpr()).readTracks();
      }

      test(
        'an untouched strip is only its EQ, not bypassed, after inserts',
        () {
          final t = read(
            (a) => a.track('MAudioTrackEvent', 'Audio 1', () {
              a.channel(ownBus: 10, outBus: 0);
            }),
          ).single;
          expect(
            [for (final m in t.strip) (m.kind, m.plugin.plugin)],
            [(CubaseStripKind.eq, 'EQ')],
          );
          expect(t.stripBypassed, isFalse);
          expect(t.stripBeforeInserts, isFalse);
        },
      );

      test('modules in the order the user arranged them, each by its kind', () {
        // The order one real Cubase 11 project kept on every channel —
        // compressor first — with a module of every kind loaded.
        final t = read(
          (a) => a.track('MAudioTrackEvent', 'Vox', () {
            a.channel(
              ownBus: 10,
              outBus: 0,
              strip: const [
                (6, 'Tube Compressor'),
                (4, 'EQ'),
                (5, 'Noise Gate'),
                (9, 'DeEsser'),
                (8, 'Magneto II'),
                (7, 'Brickwall Limiter'),
              ],
              stripOff: const {'Magneto II'},
            );
          }),
        ).single;
        expect(
          [
            for (final m in t.strip)
              (m.plugin.slot, m.kind, m.plugin.plugin, m.plugin.deactivated),
          ],
          [
            (0, CubaseStripKind.compressor, 'Tube Compressor', false),
            (1, CubaseStripKind.eq, 'EQ', false),
            (2, CubaseStripKind.gate, 'Noise Gate', false),
            (3, CubaseStripKind.tools, 'DeEsser', false),
            (4, CubaseStripKind.saturation, 'Magneto II', true),
            (5, CubaseStripKind.limiter, 'Brickwall Limiter', false),
          ],
        );
        expect(t.strip.first.plugin.pluginId, 'ID-Tube Compressor');
        expect(t.inserts, isEmpty, reason: 'strip modules are not inserts');
      });

      test('a slot type this reader does not know keeps its plug-in', () {
        final t = read(
          (a) => a.track('MAudioTrackEvent', 'Audio 1', () {
            a.channel(
              ownBus: 10,
              outBus: 0,
              strip: const [(4, 'EQ'), (12, 'New')],
            );
          }),
        ).single;
        expect(
          [for (final m in t.strip) (m.kind, m.plugin.plugin)],
          [(CubaseStripKind.eq, 'EQ'), (null, 'New')],
        );
      });

      test('the strip bypassed, and placed before the inserts', () {
        final t = read(
          (a) => a.track('MAudioTrackEvent', 'Audio 1', () {
            a.channel(
              ownBus: 10,
              outBus: 0,
              stripBypassed: true,
              stripBeforeInserts: true,
            );
          }),
        ).single;
        expect((t.stripBypassed, t.stripBeforeInserts), (true, true));
      });

      test("a send into a strip module's side-chain names the module", () {
        // The Psyform template's strip compressor takes a side-chain.
        final tracks = read((a) {
          a.track('MAudioTrackEvent', 'Kick', () {
            a.channel(
              ownBus: 10,
              outBus: 0,
              sends: [(0, 41, 25856, true, false)],
            );
          });
          a.track('MInstrumentTrackEvent', 'Synth', () {
            a.channel(
              ownBus: 11,
              outBus: 0,
              type: 4,
              strip: const [(5, null), (6, 'Standard Compressor'), (4, 'EQ')],
              stripSideChains: const {'Standard Compressor': 41},
            );
          });
        });
        final send = tracks.first.sends.single;
        expect(
          (send.destination, send.sideChainOf),
          ('Synth', 'Standard Compressor'),
        );
      });
    });

    test("a sampler track's own engine is no instrument", () {
      final a = CubaseArchive()..begin('MTrackList');
      a.track('MSamplerTrackEvent', 'Kick', () {
        a.channel(ownBus: 5, outBus: 0, type: 20, instrument: 'Sampler Track');
      });
      a.end();
      final kick = CubaseProjectParser(a.toCpr()).readTracks().single;
      expect(kick.instrument, isNull);
    });

    group('pluginIdentity', () {
      CubaseAttributes plugin(Map<String, Object?> fields) =>
          CubaseAttributes([for (final e in fields.entries) (e.key, e.value)]);

      test('a class id starting "VST" is a wrapped VST 2', () {
        expect(
          CubaseProjectParser.pluginIdentity(
            plugin({
              'Plugin UID': CubaseAttributes([
                ('GUID', '565354454E4453656E646C6573732073'),
              ]),
            }),
          ).format,
          'VST2',
        );
        expect(
          CubaseProjectParser.pluginIdentity(
            plugin({
              'Plugin UID': CubaseAttributes([
                ('GUID', '297BA567D83144E1AE921DEF07B41156'),
              ]),
            }),
          ).format,
          'VST3',
        );
        expect(CubaseProjectParser.pluginIdentity(plugin({})).format, isNull);
      });

      test("the maker from the MediaBay defaults, after the plug-in's name", () {
        final id = CubaseProjectParser.pluginIdentity(
          plugin({
            'Plugin Name': 'Volcano 2',
            'MediaBay Config V2': CubaseAttributes([
              ('defaultsId', 'LoadVSTEffectInternalState_FabFilterVolcano 2'),
            ]),
          }),
        );
        expect(id.vendor, 'FabFilter');
        // A renamed plug-in is matched by its own name.
        final renamed = CubaseProjectParser.pluginIdentity(
          plugin({
            'Plugin Name': 'Big Comp',
            'Original Plugin Name': 'Compressor',
            'MediaBay Config V2': CubaseAttributes([
              (
                'defaultsId',
                'LoadVSTEffectInternalState_Steinberg Media TechnologiesCompressor',
              ),
            ]),
          }),
        );
        expect(renamed.vendor, 'Steinberg Media Technologies');
        // Anything that doesn't end in the name says no maker.
        expect(
          CubaseProjectParser.pluginIdentity(
            plugin({
              'Plugin Name': 'X',
              'MediaBay Config V2': CubaseAttributes([
                ('defaultsId', 'something else'),
              ]),
            }),
          ).vendor,
          isNull,
        );
      });

      test('the preset, unless it is "Default"', () {
        expect(
          CubaseProjectParser.pluginIdentity(
            plugin({'Bay Program': 'AM Kick Drum 2'}),
          ).preset,
          'AM Kick Drum 2',
        );
        expect(
          CubaseProjectParser.pluginIdentity(
            plugin({'Bay Program': 'Default'}),
          ).preset,
          isNull,
        );
        expect(
          CubaseProjectParser.pluginIdentity(
            plugin({'Bay Program': ''}),
          ).preset,
          isNull,
        );
      });
    });

    test('the VST Instruments rack is not tracks; its outputs are listed', () {
      final names = parser.readTracks().map((t) => t.name);
      expect(names, isNot(contains('VST Instruments')));
      expect(names, isNot(contains('HALion Sonic')));
      expect(names, isNot(contains('HSSE Main')));
      expect(
        [
          for (final r in parser.readRackInstruments())
            (r.channel, r.plugin, r.volume),
        ],
        [('HSSE Main', 'HALion Sonic', 25856)],
      );
    });

    test('a folder has no channel; the one inside it is not its own', () {
      final synths = parser.readTracks().firstWhere((t) => t.name == 'Synths');
      expect(synths.output, isNull);
      expect(synths.inserts, isEmpty);
    });

    test('leaves out the hidden output folder and its outputs', () {
      final names = parser.readTracks().map((t) => t.name);
      expect(names, isNot(contains('Input/Output Channels')));
      expect(names, isNot(contains('Stereo Out')));
    });

    test('agrees with readStats on how many tracks there are', () {
      expect(parser.readTracks(), hasLength(parser.readStats().totalTracks));
    });
  });

  group('readAudioConnections', () {
    test("driver, platform, the studio's ports and each bus's", () {
      final io = parser.readAudioConnections();
      expect(io.driver, 'Studio USB ASIO Driver');
      expect(io.platform, 'Windows');
      expect(
        [for (final p in io.ports) (p.input, p.midi, p.name)],
        [
          (true, true, 'Studio 24c MIDI In'),
          (true, false, 'Input 1'),
          (true, false, 'Input 2'),
          (false, false, 'Main Out Left'),
          (false, false, 'Main Out Right'),
        ],
        reason: "an instrument's own MIDI input is not the studio's",
      );
      expect(
        [for (final b in io.inputBuses) (b.name, b.ports.length)],
        [('Stereo In', 2)],
      );
      expect(io.outputBuses.single.name, 'Stereo Out');
      expect(
        [for (final p in io.outputBuses.single.ports) p.name],
        ['Main Out Left', 'Main Out Right'],
      );
    });

    test('a project without them says nothing', () {
      final a = CubaseArchive()..begin('MTrackList');
      a.end();
      final io = CubaseProjectParser(a.toCpr()).readAudioConnections();
      expect(io.driver, isNull);
      expect(io.platform, isNull);
      expect(io.ports, isEmpty);
    });

    test('CubasePort.parse reads direction, driver and name', () {
      final p = CubasePort.parse(
        'O|ASIO Fireface USB|Analog 3 (1)',
        midi: false,
      )!;
      expect(
        (p.input, p.driver, p.name),
        (false, 'ASIO Fireface USB', 'Analog 3 (1)'),
      );
      expect(CubasePort.parse('', midi: false), isNull, reason: 'unconnected');
      expect(CubasePort.parse('X|a|b', midi: false), isNull);
      expect(
        CubasePort.parse(
          'O|017481B5316F40C4AB7B730E5AD9715E|Fireface UFX 1',
          midi: false,
        )!.driver,
        isNull,
        reason: 'a driver named only by its id',
      );
      expect(CubasePort.parse('I|Windows MIDI|A|B', midi: true)!.name, 'A|B');
    });

    test('Core Audio says macOS', () {
      final a = CubaseArchive()..begin('X');
      a.attr('PortDescriptors', <Map<String, Object>>[
        {
          'ID': 'I|Core Audio|Built-in Input 1',
          'Type': 'audio',
          'Subtype': 'system',
        },
      ]);
      a.end();
      expect(
        CubaseProjectParser(a.toCpr()).readAudioConnections().platform,
        'macOS',
      );
    });
  });

  group('readProjectSetup', () {
    test('sample rate, bit depth and time signature from media attributes', () {
      final setup = parser.readProjectSetup();
      expect(setup.sampleRate, 48000);
      expect(setup.bitDepth, 24);
      expect(setup.timeSignature, (3, 4));
    });

    test('a project without them says nothing', () {
      final a = CubaseArchive()..begin('MTrackList');
      a.end();
      final setup = CubaseProjectParser(a.toCpr()).readProjectSetup();
      expect(setup.sampleRate, isNull);
      expect(setup.bitDepth, isNull);
      expect(setup.timeSignature, isNull);
    });
  });

  test('volumeDb: the ends of the scale', () {
    expect(CubaseProjectParser.volumeDb(null), isNull);
    expect(CubaseProjectParser.volumeDb(0), double.negativeInfinity);
    expect(CubaseProjectParser.volumeDb(25856), 0);
    expect(CubaseProjectParser.volumeDb(32767), closeTo(6.02, 0.001));
    // Below the faders read, it keeps falling, without a jump at the join.
    final atFloor = CubaseProjectParser.volumeDb(11770.669921875)!;
    expect(CubaseProjectParser.volumeDb(11770.6)!, closeTo(atFloor, 0.01));
    expect(CubaseProjectParser.volumeDb(5000)!, lessThan(-20));
    expect(CubaseProjectParser.volumeDb(1)!, lessThan(-100));
    // Above 0 dB it keeps rising to +6.02.
    final above = CubaseProjectParser.volumeDb(29000)!;
    expect(above, greaterThan(0));
    expect(above, lessThan(6));
  });

  group('faders in dB, as Cubase 13 showed them', () {
    // The test collection's Test 2025, opened in Cubase 13: each channel's
    // fader as Cubase displayed it. test-01_db_level.cpr was saved with two
    // channels set to exactly 0 and -2 dB.
    final dir = p.join(
      'test',
      'fixtures',
      'projects',
      'cubase',
      'Test 2025 (Cubase 13)',
    );
    Map<String, double?> faders(String file) => {
      for (final t in CubaseProjectParser(
        File(p.join(dir, file)).readAsBytesSync(),
      ).readTracks())
        t.name: CubaseProjectParser.volumeDb(t.volume),
    };

    test('test-01.cpr', () {
      final db = faders('test-01.cpr');
      for (final (name, shown) in [
        ('Kick 2 x64 01', -10.8),
        ('Bassline', -3.15),
        ('Serum 03', -9.56),
        ('Main Lead 01', -12.5),
        ('RTW_145_Drums_15_Tops', -14.1),
      ]) {
        expect(db[name], closeTo(shown, 0.05), reason: name);
      }
    });

    test('test-01_db_level.cpr', () {
      final db = faders('test-01_db_level.cpr');
      expect(db['ANA2 x64 01_db_0'], 0);
      expect(db['ANA2 x64 01_db_-2'], closeTo(-2, 0.05));
      expect(
        db['ANA2 x64 01_db_6'],
        closeTo(6.02, 0.01),
        reason: 'the fader at the top',
      );
    });

    test('mute is the channel\'s "SoloFlag"; flags bit 0 is the selection', () {
      CubaseTrack kick(String file) => CubaseProjectParser(
        File(p.join(dir, file)).readAsBytesSync(),
      ).readTracks().firstWhere((t) => t.name == 'RTW_Kick_12');
      // Muted in Cubase 13 for test-01_db_level.cpr, then unmuted for
      // test-01_db_level-01.cpr. Clicking it selected it, and it stayed
      // selected: an earlier reading took the selection for mute.
      expect(kick('test-01_db_level.cpr').muted, isTrue);
      expect(kick('test-01_db_level-01.cpr').muted, isFalse);
      // Then soloed for -02: "Solo", and nothing else changed.
      expect(kick('test-01_db_level-01.cpr').soloed, isFalse);
      expect(kick('test-01_db_level-02.cpr').soloed, isTrue);
      expect(kick('test-01_db_level-02.cpr').muted, isFalse);
      expect(kick('test-01_db_level.cpr').selected, isTrue);
      expect(kick('test-01_db_level-01.cpr').selected, isTrue);
    });
  });

  group('readMidiClips', () {
    test('reads notes trimmed to the part, with the track name', () {
      final clips = parser.readMidiClips();
      expect(clips, hasLength(1));
      final c = clips.single;
      expect(c.name, 'Bassline');
      expect(c.trackName, 'Serum 01');
      expect(c.ppq, 480);
      expect(c.lengthTicks, 1920);
      expect(c.occurrences, 2, reason: 'the copy collapses into one entry');
      expect(c.notes, const [
        MidiNote(startTick: 0, lengthTicks: 240, pitch: 36, velocity: 100),
        MidiNote(startTick: 480, lengthTicks: 240, pitch: 38, velocity: 1),
        MidiNote(startTick: 1800, lengthTicks: 120, pitch: 40, velocity: 80),
      ]);
    });
  });

  group('Cubase SX, 4 and 5', () {
    Uint8List legacy(String version) {
      final a = CubaseArchive();
      a.begin('MTrackList');
      a.track('MMidiTrackEvent', 'Nord rack');
      a.legacyMidiPart('Nord rack', 1920, [
        (0, 50, 100, 240),
        (480, 62, 90, 240),
        (960, 48, 80, 480),
      ]);
      a.end();
      return a.toCpr(version: version);
    }

    test('their notes are read — 51 real projects read none', () {
      final clips = CubaseProjectParser(legacy('5.1.0')).readMidiClips();
      expect(clips.single.notes, const [
        MidiNote(startTick: 0, lengthTicks: 240, pitch: 50, velocity: 100),
        MidiNote(startTick: 480, lengthTicks: 240, pitch: 62, velocity: 90),
        MidiNote(startTick: 960, lengthTicks: 480, pitch: 48, velocity: 80),
      ]);
      expect(
        CubaseProjectParser(legacy('3.1.1')).readMidiClips().single.notes,
        hasLength(3),
      );
    });

    test('the same bytes in a newer project are not notes', () {
      expect(CubaseProjectParser(legacy('13.0.41')).readMidiClips(), isEmpty);
    });

    test('appVersion reads the version record, whatever its length', () {
      expect(CubaseProjectParser.appVersion(legacy('5.1.0')), '5.1.0');
      expect(CubaseProjectParser.appVersion(legacy('13.0.41')), '13.0.41');
      expect(CubaseProjectParser.appVersion(_project()), isNull);
    });
  });

  group('plug-ins of older versions', () {
    test('Cubase 4 writes a value with no NUL — its plug-ins still read', () {
      final a = CubaseArchive();
      a.begin('MTrackList');
      for (final name in ['QuadraFuzz', 'GEQ-30']) {
        a.raw([0, 0, 0, 12, ...ascii.encode('Plugin Name'), 0, 0, 8]);
        a.raw([0, 0, 0, name.length, ...ascii.encode(name)]);
        a.raw([0, 0, 0, 18, ...ascii.encode('Audio Input Count'), 0, 0, 1]);
        a.zeros(8);
      }
      a.end();
      expect(
        CubaseProjectParser(a.toCpr(version: '4.1.3')).readStats().plugins,
        ['GEQ-30', 'QuadraFuzz'],
      );
    });

    test('Cubase SX 3 names them only in its device paths', () {
      // As a real SX 3 project writes them: a CONT string per step.
      void path(CubaseArchive a, List<String> steps) {
        for (final step in steps) {
          a.raw(ascii.encode('CONT'));
          a.string(step);
        }
      }

      final a = CubaseArchive();
      a.begin('MTrackList');
      path(a, [
        'Device Root',
        'VST Mixer',
        'VST Instruments',
        'Slot',
        'Vanguard',
      ]);
      path(a, [
        'Device Root',
        'VST Mixer',
        'VST Instruments',
        'Slot 2',
        'Vanguard 2',
      ]);
      path(a, [
        'Device Root',
        'VST Mixer',
        'Channels',
        'Synth',
        'Inserts',
        'Slot 2',
        'Sonalksis TBK Stereo 4',
      ]);
      path(a, [
        'Device Root',
        'VST Mixer',
        'Channels',
        'Synth 2',
        'Inserts',
        'Slot',
        'Sonalksis TBK Stereo 9',
      ]);
      path(a, [
        'Device Root',
        'VST Mixer',
        'Channels',
        'Synth 3',
        'Inserts',
        'Slot',
        'Pro-Q 3',
      ]);
      path(a, ['Device Root', 'VST Mixer', 'Channels', 'Audio 1']);
      a.end();
      expect(
        CubaseProjectParser(a.toCpr(version: '3.1.1')).readStats().plugins,
        ['Pro-Q 3', 'Sonalksis TBK Stereo', 'Vanguard'],
        reason:
            'instance numbers dropped where a name comes numbered more than once; '
            'a lone "Pro-Q 3" keeps its 3',
      );
    });
  });

  group('readSampleReferences', () {
    const projectAudio = r'C:\Music\Song\Audio\';
    const library = r'D:\Samples\Re-Twin\RTW_PERCS\';

    CubaseProjectParser parserWithPool() {
      final a = CubaseArchive();
      a.begin('MTrackList');
      a.track('MAudioTrackEvent', 'Vocals', () {
        a.channel(ownBus: 10, outBus: 1);
      });
      a.end();
      a.begin('PPool');
      a.poolFile('RTW_Crash_3.wav', library);
      a.poolFile('gataka_kick.wav', projectAudio);
      a.poolFile('gataka_kick-01.wav', projectAudio);
      a.poolFile('lonely-01.wav', projectAudio);
      a.poolFile('Vocals_03.wav', projectAudio);
      a.poolFile('RTW_Crash_3.wav', library); // listed twice: kept once
      a.end();
      // A sampler plug-in's state, inline in the archive.
      a.raw([0, 0, 0, 0x30, ...ascii.encode(r'E:\Kits\Snare 7.wav'), 0]);
      return CubaseProjectParser(a.toCpr());
    }

    test('reads each pool file with its folder, once', () {
      final refs = parserWithPool().readSampleReferences();
      final pooled = refs.where((r) => r.use == SampleUse.audio).toList();
      expect(
        [for (final r in pooled) r.fileName],
        [
          'RTW_Crash_3.wav',
          'gataka_kick.wav',
          'gataka_kick-01.wav',
          'lonely-01.wav',
          'Vocals_03.wav',
        ],
      );
      expect(pooled.first.candidates, [
        '${library}RTW_Crash_3.wav',
        'Audio/RTW_Crash_3.wav',
      ]);
    });

    test('a take on a track is a recording; "-01" beside its original is '
        'processed', () {
      final refs = {
        for (final r in parserWithPool().readSampleReferences())
          r.fileName: r.kind,
      };
      expect(refs['Vocals_03.wav'], SampleKind.recorded);
      expect(refs['gataka_kick-01.wav'], SampleKind.processed);
      expect(refs['gataka_kick.wav'], isNull);
      expect(
        refs['lonely-01.wav'],
        isNull,
        reason: 'no original in the pool: nothing says it was processed',
      );
      expect(refs['RTW_Crash_3.wav'], isNull);
    });

    test('finds sample paths kept in plug-in state', () {
      final plugin = parserWithPool()
          .readSampleReferences()
          .where((r) => r.use == SampleUse.plugin)
          .toList();
      expect(plugin, hasLength(1));
      expect(plugin.single.candidates, [r'E:\Kits\Snare 7.wav']);
    });

    test("the Sampler Track's sample is a sampler sample, never a "
        'processed copy, and listed once', () {
      final a = CubaseArchive();
      a.track('MSamplerTrackEvent', 'kick');
      a.begin('PSamplerTrackAudioClip');
      a.poolFile('bizzare_kick-01.wav', projectAudio);
      a.end();
      a.begin('PPool');
      a.poolFile('bizzare_kick.wav', projectAudio);
      a.poolFile('bizzare_kick-01.wav', projectAudio); // the pool lists it too
      a.end();
      final refs = CubaseProjectParser(a.toCpr()).readSampleReferences();
      final played = refs
          .where((r) => r.fileName == 'bizzare_kick-01.wav')
          .toList();
      expect(played, hasLength(1));
      expect(played.single.use, SampleUse.sampler);
      expect(
        played.single.kind,
        isNull,
        reason: 'its original being in the pool does not make it a bounce',
      );
      expect(
        refs.firstWhere((r) => r.fileName == 'bizzare_kick.wav').use,
        SampleUse.audio,
      );
    });

    test('a pool path that is not audio (a preset) is skipped', () {
      final a = CubaseArchive();
      a.poolFile('Bright Ballad Vocal.vstpreset', r'C:\Presets\');
      expect(CubaseProjectParser(a.toCpr()).readSampleReferences(), isEmpty);
    });
  });

  test('garbage after the header is survived, not thrown on', () {
    final bytes = BytesBuilder()
      ..add(ascii.encode('RIFF'))
      ..add([0, 0, 0, 40])
      ..add(ascii.encode('NUND'))
      ..add(ascii.encode('ARCH'))
      ..add([0, 0, 0, 16])
      ..add(List.filled(16, 0xFF));
    final p = CubaseProjectParser(bytes.toBytes());
    expect(p.readStats().totalTracks, 0);
    expect(p.readMidiClips(), isEmpty);
  });
}
