import 'dart:io';
import 'dart:typed_data';

import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/plugin_presets/preset_export.dart';
import 'package:daw_project_manager/services/plugin_presets/sylenth1_bank.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../helpers/vst2_builders.dart';

List<int> _le(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

/// A Sylenth1 chunk with the given programs and selection.
Uint8List _sylenthChunk(List<String> names, int current) {
  List<int> name(String s) {
    final b = List<int>.filled(36, 0);
    b.setRange(0, s.length, s.codeUnits);
    return b;
  }

  return Uint8List.fromList([
    ...'1lys'.codeUnits,
    ..._le(3031),
    ..._le(names.length),
    ..._le(2),
    ..._le(current),
    for (final n in names) ...[..._le(0), ..._le(0), ...name(n)],
  ]);
}

CubasePluginState _state(
  String plugin,
  Uint8List? file, {
  String track = 'Lead',
  CubasePluginPlace place = CubasePluginPlace.insert,
}) => CubasePluginState(
  track: track,
  place: place,
  plugin: plugin,
  state: file == null ? null : stateOf(file),
);

void main() {
  late Directory out;
  setUp(() => out = Directory.systemTemp.createTempSync('dpm_presets_'));
  tearDown(() => out.deleteSync(recursive: true));

  group('presetProgramName', () {
    test('Sylenth1 is named by the program selected inside its bank', () {
      final bank = stateOf(
        fxOpaqueBank(sylenth1PluginId, _sylenthChunk(['Init', 'LD Axe', 'Pad'], 1)),
      );
      expect(presetProgramName(bank), 'LD Axe');
    });

    test('a program says its own name', () {
      expect(presetProgramName(stateOf(fxProgram('abcd', 'Warm Pad'))), 'Warm Pad');
    });

    test('a bank no decoder knows has no name', () {
      expect(presetProgramName(stateOf(fxOpaqueBank('abcd', [1, 2, 3]))), isNull);
    });
  });

  group('planPresetFiles', () {
    test('names a file by project, track and program, in the plug-in\'s folder', () {
      final plan = planPresetFiles('My Song', [
        _state(
          'Sylenth1',
          fxOpaqueBank(sylenth1PluginId, _sylenthChunk(['Init', 'LD Axe'], 1)),
          track: 'Lead',
        ),
      ]);

      expect(plan.files.single.folder, 'Sylenth1');
      expect(plan.files.single.fileName, 'My Song - Lead - LD Axe.fxb');
    });

    test('a program is an .fxp, and a state with no name uses the plug-in ID', () {
      final plan = planPresetFiles('S', [
        _state('Thing', fxProgram('abcd', 'Warm'), track: 'T'),
        _state('Other', fxOpaqueBank('wxyz', [9]), track: 'T'),
      ]);

      expect(plan.files[0].fileName, 'S - T - Warm.fxp');
      expect(plan.files[1].fileName, 'S - T - wxyz.fxb');
    });

    test('a rack instrument with no track name is named without one', () {
      final plan = planPresetFiles('S', [
        _state('Syn', fxProgram('abcd', 'A'), track: '', place: CubasePluginPlace.rack),
      ]);

      expect(plan.files.single.fileName, 'S - A.fxp');
    });

    test('characters a file system rejects are replaced', () {
      final plan = planPresetFiles('A/B: C', [
        _state('Plug*in?', fxProgram('abcd', 'x'), track: 'Kick|1'),
      ]);

      expect(plan.files.single.folder, 'Plug_in_');
      expect(plan.files.single.fileName, 'A_B_ C - Kick_1 - x.fxp');
    });

    test('a very long name is shortened, keeping the extension', () {
      final plan = planPresetFiles('S', [
        _state('P', fxProgram('abcd', 'x'), track: 'T' * 400),
      ]);

      expect(plan.files.single.fileName.length, lessThan(150));
      expect(plan.files.single.fileName, endsWith('.fxp'));
    });

    test('plug-ins with no savable state are counted by name', () {
      final plan = planPresetFiles('S', [
        _state('PuigTec EQP1A', null),
        _state('PuigTec EQP1A', null, track: 'Other'),
        _state('Diva', null),
        _state('Good', fxProgram('abcd', 'x')),
      ]);

      expect(plan.files, hasLength(1));
      expect(plan.unsavable, {'PuigTec EQP1A': 2, 'Diva': 1});
    });
  });

  group('exportPresets', () {
    PresetProject project(String name) => PresetProject(name: name, path: name);

    test('writes each preset once, even across versions of a song', () async {
      final same = fxProgram('abcd', 'Warm');
      final result = await exportPresets(
        destination: out.path,
        projects: [project('Song v1'), project('Song v2')],
        readStates: (path) async => [_state('Thing', same)],
      );

      // The same bytes in one plug-in's folder, whatever the project's name.
      expect(result.written, 1);
      expect(result.alreadyThere, 1);
      expect(Directory(p.join(out.path, 'Thing')).listSync(), hasLength(1));
    });

    test('running again adds nothing and changes nothing', () async {
      final states = [_state('Thing', fxProgram('abcd', 'Warm'))];
      Future<PresetExportResult> run() => exportPresets(
            destination: out.path,
            projects: [project('Song')],
            readStates: (_) async => states,
          );

      await run();
      final again = await run();

      expect(again.written, 0);
      expect(again.alreadyThere, 1);
    });

    test('a different preset that would take a name gets a number', () async {
      await exportPresets(
        destination: out.path,
        projects: [project('S')],
        readStates: (_) async => [_state('P', fxProgram('abcd', 'x', value: 1))],
      );
      final second = await exportPresets(
        destination: out.path,
        projects: [project('S')],
        readStates: (_) async => [_state('P', fxProgram('abcd', 'x', value: 2))],
      );

      expect(second.written, 1);
      final names = Directory(p.join(out.path, 'P'))
          .listSync()
          .map((e) => p.basename(e.path))
          .toList()
        ..sort();
      expect(names, ['S - Lead - x (2).fxp', 'S - Lead - x.fxp']);
    });

    test('what is written is the state byte for byte, and no .part is left', () async {
      final file = fxProgram('abcd', 'Warm');
      await exportPresets(
        destination: out.path,
        projects: [project('S')],
        readStates: (_) async => [_state('P', file)],
      );

      final written = Directory(p.join(out.path, 'P')).listSync().single as File;
      expect(written.readAsBytesSync(), file);
      expect(
        Directory(out.path)
            .listSync(recursive: true)
            .where((e) => e.path.endsWith('.part')),
        isEmpty,
      );
    });

    test('a project that cannot be read is counted and the rest go on', () async {
      final result = await exportPresets(
        destination: out.path,
        projects: [project('Broken'), project('Good')],
        readStates: (path) async {
          if (path == 'Broken') throw const FormatException('bad');
          return [_state('P', fxProgram('abcd', 'x'))];
        },
      );

      expect(result.projectsFailed, 1);
      expect(result.projectsRead, 1);
      expect(result.written, 1);
    });

    test('unsavable plug-ins are summed over every project', () async {
      final result = await exportPresets(
        destination: out.path,
        projects: [project('A'), project('B')],
        readStates: (_) async => [_state('Waves', null), _state('Diva', null)],
      );

      expect(result.unsavable, {'Waves': 2, 'Diva': 2});
      expect(result.unsavableInstances, 4);
      expect(result.written, 0);
    });

    test('stopping keeps what is done and says so', () async {
      var stop = false;
      final result = await exportPresets(
        destination: out.path,
        projects: [project('A'), project('B'), project('C')],
        readStates: (path) async {
          if (path == 'A') stop = true;
          return [_state('P', fxProgram('abcd', path))];
        },
        shouldStop: () => stop,
      );

      expect(result.stopped, isTrue);
      expect(result.projectsRead, 1);
      expect(result.written, 1);
    });

    test('progress counts projects done', () async {
      final seen = <int>[];
      await exportPresets(
        destination: out.path,
        projects: [project('A'), project('B')],
        readStates: (_) async => [],
        onProgress: (done, total, name) => seen.add(done),
      );

      expect(seen, [0, 1, 2]);
    });
  });
}
