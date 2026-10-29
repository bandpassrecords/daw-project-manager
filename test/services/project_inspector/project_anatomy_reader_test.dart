import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/services/project_inspector/cubase_stock_plugins.dart';
import 'package:daw_project_manager/services/project_inspector/project_anatomy_reader.dart';

/// The Cubase 13 project in the test collection: groups, a rack with two
/// HALion Sonic instances, instrument tracks, inserts from slot 0 on.
final _cubase13 = p.join('test', 'fixtures', 'projects', 'cubase',
    'Test 2025 (Cubase 13)', 'test-01.cpr');

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
          ]);
      expect(byName['Sylenth1 01']!.folder, 'Leads');
      expect(byName['RTW_Kick_12']!.kind, AnatomyChannelKind.sampler);
      expect(anatomy.channels!.map((c) => c.name),
          isNot(contains('VST Instruments')),
          reason: 'the rack is not a track');
    });

    test('a group\'s only insert, in slot 0, is read', () {
      final group = anatomy.channels!
          .firstWhere((c) => c.name == 'Main Lead Group');
      expect([for (final i in group.inserts) (i.slot, i.plugin)],
          [(0, 'Endless Smile 64')]);
      expect(group.output, 'Stereo Out');
      expect(group.volumeDb, 0, reason: 'a channel left at 0 dB');
    });

    test('plug-in names lose their architecture suffix', () {
      final bassline =
          anatomy.channels!.firstWhere((c) => c.name == 'Bassline');
      expect(bassline.inserts.map((i) => i.plugin), contains('LFOTool'));
      expect(bassline.instrument, isNotNull);
    });

    test('plug-ins: instruments from tracks and the rack, effects by origin',
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
      expect(ott.channels.toSet(), hasLength(ott.channels.length),
          reason: 'each channel once');
      expect(byName['Compressor']!.stock, isTrue);
    });

    test('the audio files it references are listed', () {
      expect(anatomy.media, isNotNull);
      expect(anatomy.media, isNotEmpty);
    });
  });

  test('another DAW: header and plug-in names, channels not read yet',
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
  });

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
}
