import 'dart:io';

import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/plugin_presets/vst2_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

List<CubasePluginState> _statesOf(String folder, String file) {
  final path = p.join('test', 'fixtures', 'projects', 'cubase', folder, file);
  return CubaseProjectParser(File(path).readAsBytesSync()).readPluginStates();
}

void main() {
  group('readPluginStates', () {
    test('a Cubase 5 project: inserts with a VST2 bank name their program', () {
      final states = _statesOf('Klone - NN (Cubase 5)', 'NN.cpr');
      final kick = states.firstWhere(
        (s) =>
            s.place == CubasePluginPlace.insert &&
            s.track == 'Kick' &&
            s.slot == 0,
      );

      expect(kick.plugin, 'Sonalksis TBK Stereo');
      expect(kick.format, 'VST2');
      expect(kick.state!.pluginId, 'TBKN');
      expect(kick.state!.kind, Vst2StateKind.bank);
      expect(kick.state!.programName, 'Smooth LPF');
      expect(kick.state!.fileExtension, '.fxb');
    });

    test('a VST2 plug-in whose state is not a .fxb is listed without one', () {
      // Waves plug-ins keep their own chunk, with no CcnK file in it.
      final states = _statesOf('Test 2025 (Cubase 13)', 'test.cpr');
      final waves = states.firstWhere(
        (s) => s.plugin == 'PuigTec EQP1A Stereo',
      );

      expect(waves.format, 'VST2');
      expect(waves.state, isNull);
    });

    test('a VST3 plug-in is never reported as a VST2 state', () {
      final states = _statesOf('Test 2025 (Cubase 13)', 'test.cpr');

      for (final s in states.where((s) => s.format == 'VST3')) {
        expect(s.state, isNull, reason: s.plugin);
      }
    });

    test('the VST Instruments rack is read, once per slot', () {
      final states = _statesOf('Klone - NN (Cubase 5)', 'NN.cpr');
      final rack = states.where((s) => s.place == CubasePluginPlace.rack);

      expect(rack, isNotEmpty);
      final slots = rack.map((s) => s.slot).toList();
      expect(slots.toSet().length, slots.length, reason: 'no slot twice');
    });

    test('a state no track claims is listed by its ID, once', () {
      final states = _statesOf(
        'Master Project (Cubase 11)',
        'master project.cpr',
      );

      expect(states, hasLength(1));
      expect(states.single.place, CubasePluginPlace.unplaced);
      expect(states.single.state!.pluginId, 'rstr');
      expect(states.single.track, isEmpty);
    });

    test(
      'a project from before audioComponent has none, and does not fail',
      () {
        expect(
          _statesOf('Another Dance (Cubase SX 3)', 'Another Dance.cpr'),
          isEmpty,
        );
      },
    );

    test('every VST2 state read is a whole file of its own kind', () {
      for (final entry in [
        ('Test 2025 (Cubase 13)', 'test.cpr'),
        ('Klone - NN (Cubase 5)', 'NN.cpr'),
      ]) {
        for (final s in _statesOf(
          entry.$1,
          entry.$2,
        ).where((s) => s.state != null)) {
          final state = s.state!;
          expect(String.fromCharCodes(state.file.sublist(0, 4)), 'CcnK');
          expect(
            state.file.length,
            ByteDataLength.of(state.file) + 8,
            reason: '${s.plugin} in ${entry.$2}',
          );
        }
      }
    });
  });
}

/// The `byteSize` field of a `CcnK` file.
class ByteDataLength {
  static int of(List<int> file) =>
      (file[4] << 24) | (file[5] << 16) | (file[6] << 8) | file[7];
}
