import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/services/project_inspector/cubase_stock_plugins.dart';
import 'package:daw_project_manager/services/project_inspector/project_anatomy_reader.dart';

import '../../helpers/cubase_archive.dart';

/// The Cubase 13 project in the test collection: groups, a rack with two
/// HALion Sonic instances, instrument tracks, inserts from slot 0 on.
final _cubase13 = p.join(
  'test',
  'fixtures',
  'projects',
  'cubase',
  'Test 2025 (Cubase 13)',
  'test-01.cpr',
);

void main() {
  group('cubaseAnatomy, on a real Cubase 13 project', () {
    late ProjectAnatomy anatomy;
    setUpAll(() {
      anatomy = cubaseAnatomy(
        filePath: _cubase13,
        bytes: File(_cubase13).readAsBytesSync(),
        tempo: 150,
      );
    });

    test('the header: version in full, sample rate, bit depth, signature', () {
      expect(anatomy.dawType, 'Cubase');
      expect(anatomy.savedWith, startsWith('13.'));
      expect(anatomy.savedWith!.split('.'), hasLength(greaterThan(2)));
      expect(anatomy.sampleRate, 44100);
      expect(anatomy.bitDepth, 24);
      expect(anatomy.timeSignature, (4, 4));
      expect(anatomy.tempo, 150);
      expect(anatomy.fileSize, File(_cubase13).lengthSync());
    });

    test('channels in project order, with kinds and folders', () {
      final byName = {for (final c in anatomy.channels!) c.name: c};
      expect(byName['Main Lead Group']!.kind, AnatomyChannelKind.group);
      // "Leads" is both a folder and the group inside it.
      expect(
        anatomy.channels!
            .where((c) => c.name == 'Leads')
            .map((c) => (c.kind, c.folder)),
        [
          (AnatomyChannelKind.folder, null),
          (AnatomyChannelKind.group, 'Leads'),
        ],
      );
      expect(byName['Sylenth1 01']!.folder, 'Leads');
      expect(byName['RTW_Kick_12']!.kind, AnatomyChannelKind.sampler);
      expect(
        anatomy.channels!.map((c) => c.name),
        isNot(contains('VST Instruments')),
        reason: 'the rack is not a track',
      );
    });

    test('a group\'s only insert, in slot 0, is read', () {
      final group = anatomy.channels!.firstWhere(
        (c) => c.name == 'Main Lead Group',
      );
      expect(
        [for (final i in group.inserts) (i.slot, i.plugin)],
        [(0, 'Endless Smile 64')],
      );
      expect(group.output, 'Stereo Out');
      expect(group.volumeDb, 0, reason: 'a channel left at 0 dB');
      expect(group.pan, 0, reason: 'left in the centre');
    });

    test('plug-in names lose their architecture suffix', () {
      final bassline = anatomy.channels!.firstWhere(
        (c) => c.name == 'Bassline',
      );
      expect(bassline.inserts.map((i) => i.plugin), contains('LFOTool'));
      expect(
        bassline.instrument,
        'Diva',
        reason: 'the track is named Bassline',
      );
    });

    test(
      'plug-ins: instruments from tracks and the rack, effects by origin',
      () {
        expect(anatomy.pluginInstancesKnown, isTrue);
        final byName = {for (final pl in anatomy.plugins) pl.name: pl};
        final halion = byName['HALion Sonic']!;
        expect(halion.role, AnatomyPluginRole.instrument);
        expect(halion.instances, 2, reason: 'two rack slots');
        expect(halion.stock, isTrue);
        final ott = byName['OTT']!;
        expect(ott.role, AnatomyPluginRole.effect);
        expect(ott.stock, isFalse);
        expect(ott.instances, greaterThan(1));
        expect(
          ott.channels.toSet(),
          hasLength(ott.channels.length),
          reason: 'each channel once',
        );
        expect(byName['Compressor']!.stock, isTrue);
        expect(byName['Sylenth1']!.role, AnatomyPluginRole.instrument);
        expect(byName['Sylenth1']!.instances, 6);
        expect(
          byName.keys,
          isNot(contains('Bassline')),
          reason: "a track's label is not a plug-in",
        );
      },
    );

    test('formats from class ids; makers where the project names them', () {
      final byName = {for (final pl in anatomy.plugins) pl.name: pl};
      expect(byName['OTT']!.format, 'VST2');
      expect(byName['Pro-Q 3']!.format, 'VST3');
      expect(byName['LFOTool']!.vendor, 'Xfer Records');
      expect(byName['Volcano 2']!.vendor, 'FabFilter');
      expect(byName['PingPongDelay']!.vendor, 'Steinberg Media Technologies');
      expect(byName['PingPongDelay']!.stock, isTrue);
    });

    test('the studio it was saved in', () {
      final io = anatomy.audioIo!;
      expect(io.driver, 'Studio USB ASIO Driver');
      expect(io.platform, 'Windows');
      expect(io.inputBuses.single.name, 'Stereo In');
      expect(io.inputBuses.single.ports, ['Input 1', 'Input 2']);
      expect(io.outputBuses.single.name, 'Stereo Out');
      expect(io.midiInputs, contains('Studio 24c MIDI In'));
    });

    test('the audio files it references are listed', () {
      expect(anatomy.media, isNotNull);
      expect(anatomy.media, isNotEmpty);
    });
  });

  group('cubaseAnatomy, a channel strip', () {
    late ProjectAnatomy anatomy;
    setUpAll(() {
      final a = CubaseArchive()..begin('MTrackList');
      a.track('MAudioTrackEvent', 'Vox', () {
        a.channel(
          ownBus: 10,
          outBus: 0,
          inserts: {0: ('Pro-Q 3', false)},
          strip: const [
            (5, 'Noise Gate'),
            (6, 'Standard Compressor'),
            (4, 'EQ'),
          ],
          stripBypassed: true,
        );
      });
      a.track('MAudioTrackEvent', 'Bass', () {
        a.channel(
          ownBus: 11,
          outBus: 0,
          strip: const [(6, 'Standard Compressor'), (4, 'EQ')],
        );
      });
      a.end();
      final bytes = a.toCpr();
      anatomy = cubaseAnatomy(filePath: 'strip.cpr', bytes: bytes);
    });

    AnatomyChannel channel(String name) =>
        anatomy.channels!.firstWhere((c) => c.name == name);

    test('modules in order, by kind; the EQ marks its place', () {
      final vox = channel('Vox');
      expect(
        [for (final m in vox.strip) (m.kind, m.plugin)],
        [
          (AnatomyStripKind.gate, 'Noise Gate'),
          (AnatomyStripKind.compressor, 'Standard Compressor'),
          (AnatomyStripKind.eq, 'EQ'),
        ],
      );
      expect(
        [for (final m in vox.stripModules) m.plugin],
        ['Noise Gate', 'Standard Compressor'],
      );
      expect(vox.stripBypassed, isTrue);
      expect(channel('Bass').stripBypassed, isFalse);
      expect([for (final i in vox.inserts) i.plugin], ['Pro-Q 3']);
    });

    test('modules count as effects; the EQ every channel has does not', () {
      final byName = {for (final pl in anatomy.plugins) pl.name: pl};
      expect(byName.keys, isNot(contains('EQ')));
      final comp = byName['Standard Compressor']!;
      expect((comp.role, comp.stock, comp.instances), (
        AnatomyPluginRole.effect,
        true,
        2,
      ));
      expect(comp.channels, ['Vox', 'Bass']);
      expect(byName['Noise Gate']!.channels, ['Vox']);
    });
  });

  test('Cubase SX 3: channels not decodable, plug-ins by name', () {
    final path = p.join(
      'test',
      'fixtures',
      'projects',
      'cubase',
      'Another Dance (Cubase SX 3)',
      'Another Dance.cpr',
    );
    final anatomy = cubaseAnatomy(
      filePath: path,
      bytes: File(path).readAsBytesSync(),
    );
    expect(anatomy.pluginInstancesKnown, isFalse);
    expect(
      anatomy.plugins,
      isNotEmpty,
      reason: 'the stats know them; the Inspector must too',
    );
    expect(anatomy.plugins.every((pl) => pl.instances == null), isTrue);
    expect(
      anatomy.plugins.firstWhere((pl) => pl.name == 'RoomWorks').stock,
      isTrue,
      reason: 'stock is known by name',
    );
  });

  test(
    'another DAW: header and plug-in names, channels not read yet',
    () async {
      final rpp = Directory(p.join('test', 'fixtures', 'projects', 'reaper'))
          .listSync(recursive: true)
          .whereType<File>()
          .firstWhere((f) => f.path.endsWith('.rpp'));
      final anatomy = await readProjectAnatomy(rpp.path);
      expect(anatomy.dawType, isNotNull);
      expect(anatomy.channels, isNull, reason: 'null is "not available"');
      expect(anatomy.pluginInstancesKnown, isFalse);
      expect(anatomy.media, isNotNull);
      expect(anatomy.plugins.every((pl) => pl.instances == null), isTrue);
    },
  );

  test('readProjectAnatomy reads a Cubase project in full', () async {
    final anatomy = await readProjectAnatomy(_cubase13);
    expect(anatomy.channels, isNotEmpty);
    expect(anatomy.tempo, 150, reason: 'from MetadataExtractor');
  });

  test('stock plug-ins are matched by name, ignoring case and spaces', () {
    expect(isCubaseStockPlugin(' StereoDelay '), isTrue);
    expect(isCubaseStockPlugin('halion sonic'), isTrue);
    expect(isCubaseStockPlugin('Pro-Q 3'), isFalse);
  });

  test("every module Cubase's channel strip offers is stock", () {
    const modules = [
      'Noise Gate',
      'Standard Compressor',
      'Tube Compressor',
      'Vintage Compressor',
      'DeEsser',
      'EnvelopeShaper',
      'Magneto II',
      'Tape Saturation',
      'Tube Saturation',
      'Brickwall Limiter',
      'Maximizer',
      'Standard Limiter',
    ];
    expect([
      for (final m in modules)
        if (!isCubaseStockPlugin(m)) m,
    ], isEmpty);
  });
}
