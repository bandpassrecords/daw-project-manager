import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/project_copy.dart';
import 'package:daw_project_manager/services/project_inspector/safe_copy/safe_copy.dart';

import '../../../helpers/cubase_archive.dart';

/// Serum on an instrument track, with Pro-Q 3 and a deactivated LFOTool
/// inserted and a Standard Compressor in its strip; Pro-Q 3 again on a
/// group; HALion Sonic in the rack with two outputs.
Uint8List _project() {
  final a = CubaseArchive()..begin('MTrackList');
  a.track('MInstrumentTrackEvent', 'Bass', () {
    a.channel(
      ownBus: 10,
      outBus: 0,
      type: 4,
      instrument: 'Serum',
      inserts: {0: ('Pro-Q 3', false), 2: ('LFOTool_x64', true)},
      strip: const [(6, 'Standard Compressor'), (4, 'EQ')],
    );
  });
  a.track('MDeviceTrackEvent', 'Drums', () {
    a.channel(ownBus: 20, outBus: 0, type: 2, inserts: {0: ('Pro-Q 3', false)});
  });
  a.end();
  a.begin('PVSTInstrumentRack');
  a.rackSlot('HALion Sonic', ['HSSE Main', 'HSSE Out 2']);
  a.end();
  return a.toCpr();
}

void main() {
  const writer = CubaseSafeCopyWriter();

  test('every plug-in instance with its on/off flag, the EQ left out', () {
    final s = writer.switches(_project());
    expect(
      [for (final x in s) (x.plugin, x.channel, x.kind, x.off)],
      unorderedEquals([
        ('Serum', 'Bass', PluginSlotKind.instrument, false),
        ('Pro-Q 3', 'Bass', PluginSlotKind.insert, false),
        ('LFOTool', 'Bass', PluginSlotKind.insert, true),
        ('Standard Compressor', 'Bass', PluginSlotKind.strip, false),
        ('Pro-Q 3', 'Drums', PluginSlotKind.insert, false),
        ('HALion Sonic', 'HSSE Main', PluginSlotKind.rack, false),
      ]),
      reason: 'a rack instrument with two outputs is one instance',
    );
  });

  test('switching off rewrites only the flags, 1 to 0, in place', () {
    final original = _project();
    final before = writer.switches(original);
    final pro = [for (final s in before) if (s.plugin == 'Pro-Q 3') s];
    final out = writer.switchOff(original, pro);
    expect(out.length, original.length);
    final changed = [
      for (var i = 0; i < out.length; i++)
        if (out[i] != original[i]) i,
    ];
    expect(changed, [for (final s in pro) s.at + 7],
        reason: "a big-endian 1's last byte");
    final inserts = CubaseProjectParser(out)
        .readTracks()
        .expand((t) => t.inserts)
        .where((i) => i.plugin == 'Pro-Q 3');
    expect(inserts.every((i) => i.deactivated == true), isTrue);
  });

  test('a flag that does not read "on" is never written', () {
    final original = _project();
    final lfo = writer.switches(original).singleWhere((s) => s.plugin == 'LFOTool');
    expect(() => writer.switchOff(original, [lfo]),
        throwsA(isA<CopyCheckFailed>()));
  });

  group('writeSafeCopy', () {
    late Directory dir;
    late String project;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('dpm_safe_');
      project = p.join(dir.path, 'Song.cpr');
      await File(project).writeAsBytes(_project());
    });
    tearDown(() => dir.delete(recursive: true));

    test('"<name> (safe copy)" beside it, the chosen plug-ins all off',
        () async {
      final before = await File(project).readAsBytes();
      final copy = await writeSafeCopy(
        projectPath: project,
        plugins: {'pro-q 3', 'Serum', 'HALion Sonic'},
      );
      expect(p.basename(copy.path!), 'Song (safe copy).cpr');
      expect(copy.switchedOff, {'Serum': 1, 'Pro-Q 3': 2, 'HALion Sonic': 1});
      expect(copy.total, 4);
      expect(await File(project).readAsBytes(), before, reason: 'only read');

      final after = writer.switches(await File(copy.path!).readAsBytes());
      expect({for (final s in after) if (s.off) s.plugin},
          {'Serum', 'Pro-Q 3', 'HALion Sonic', 'LFOTool'});
      expect(after.singleWhere((s) => s.plugin == 'Standard Compressor').off,
          isFalse);
    });

    test('nothing to switch off writes nothing', () async {
      final copy = await writeSafeCopy(
        projectPath: project,
        plugins: {'LFOTool', 'Not In This Project'},
      );
      expect(copy.path, isNull, reason: 'LFOTool is already off');
      expect(dir.listSync(), hasLength(1));
    });

    test('a format with no writer is refused up front', () {
      expect(
        () => writeSafeCopy(projectPath: 'Song.als', plugins: const {'x'}),
        throwsUnsupportedError,
      );
    });
  });

  test('copyPathBeside numbers past copies already there', () {
    final taken = {p.join('x', 'Song (safe copy).cpr')};
    expect(copyPathBeside(p.join('x', 'Song.cpr'), 'safe copy', taken.contains),
        p.join('x', 'Song (safe copy 2).cpr'));
  });
}
