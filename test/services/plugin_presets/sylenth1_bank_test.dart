import 'dart:io';
import 'dart:typed_data';

import 'package:daw_project_manager/services/plugin_presets/sylenth1_bank.dart';
import 'package:daw_project_manager/services/plugin_presets/vst2_state.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _le(int v) => (ByteData(4)..setUint32(0, v, Endian.little))
    .buffer
    .asUint8List()
    .toList();

List<int> _name(String s, {int fill = 0}) {
  final bytes = List<int>.filled(36, fill);
  bytes.setRange(0, s.length, s.codeUnits);
  bytes[s.length] = 0;
  return bytes;
}

/// The 20-byte header and the records, as Sylenth1 writes them.
Uint8List _records(
  List<String> names, {
  required int current,
  int fields = 3,
  int version = 3031,
  int junk = 0x58,
}) => Uint8List.fromList([
  ...'1lys'.codeUnits,
  ..._le(version),
  ..._le(names.length),
  ..._le(fields),
  ..._le(current),
  for (final n in names) ...[
    for (var i = 0; i < fields; i++) ..._le(0x3f800000),
    ..._name(n, fill: junk),
  ],
]);

void main() {
  group('SylenthBank.read', () {
    test('a plain chunk (older versions) gives names and the selection', () {
      final bank = SylenthBank.read(
        _records(['Init', 'LD Axe Lead', 'Warm Pad'], current: 1),
      )!;

      expect(bank.names, ['Init', 'LD Axe Lead', 'Warm Pad']);
      expect(bank.currentProgram, 1);
      expect(bank.selectedName, 'LD Axe Lead');
      expect(bank.version, 3031);
    });

    test('a zlib chunk (version 3045) reads the same', () {
      final inner = _records(
        ['Init', 'Pluck', 'Bass'],
        current: 2,
        version: 3045,
      );
      final chunk = Uint8List.fromList([
        ...'1lys'.codeUnits,
        ..._le(3045),
        ...ZLibEncoder().convert(inner),
      ]);

      final bank = SylenthBank.read(chunk)!;

      expect(bank.names, ['Init', 'Pluck', 'Bass']);
      expect(bank.selectedName, 'Bass');
    });

    test('whether it is compressed comes from the chunk, not the version', () {
      // A compressed chunk that claims an old version, and a plain one that
      // claims the new: both still read.
      final inner = _records(['A', 'B'], current: 0);
      final compressedOld = Uint8List.fromList([
        ...'1lys'.codeUnits,
        ..._le(2011),
        ...ZLibEncoder().convert(inner),
      ]);
      expect(SylenthBank.read(compressedOld)!.names, ['A', 'B']);
      expect(
        SylenthBank.read(_records(['A', 'B'], current: 0, version: 3045))!
            .names,
        ['A', 'B'],
      );
    });

    test('242, 243 and 244 fields per program all read', () {
      for (final fields in [242, 243, 244]) {
        final bank = SylenthBank.read(
          _records(['Init', 'Lead'], current: 1, fields: fields),
        )!;
        expect(bank.names, ['Init', 'Lead'], reason: '$fields fields');
      }
    });

    test('a name stops at its NUL, not at the stale bytes after it', () {
      final bank = SylenthBank.read(
        _records(['Lead', 'Pad'], current: 0, junk: 0x41),
      )!;

      expect(bank.names, ['Lead', 'Pad']);
    });

    test('a selection past the last program has no name', () {
      final bank = SylenthBank.read(_records(['Init', 'A'], current: 9))!;

      expect(bank.currentProgram, 9);
      expect(bank.selectedName, isNull);
    });

    test('anything else is refused, not guessed', () {
      expect(SylenthBank.read(Uint8List(0)), isNull);
      expect(SylenthBank.read(Uint8List(40)), isNull, reason: 'wrong magic');

      final whole = _records(['A', 'B', 'C'], current: 0);
      expect(
        SylenthBank.read(Uint8List.sublistView(whole, 0, whole.length - 10)),
        isNull,
        reason: 'cut short',
      );
      final badZlib = Uint8List.fromList([
        ...'1lys'.codeUnits,
        ..._le(3045),
        ...List.filled(30, 7),
      ]);
      expect(SylenthBank.read(badZlib), isNull, reason: 'not a zlib stream');
    });
  });

  test('inside an FBCh file the chunk is found where Vst2State says', () {
    final chunk = _records(['Init', 'Sub'], current: 1);
    final file = Uint8List.fromList([
      ...'CcnK'.codeUnits,
      ...[0, 0, 0, 0], // byteSize, filled in below
      ...'FBCh'.codeUnits,
      ...[0, 0, 0, 1],
      ...sylenth1PluginId.codeUnits,
      ...[0, 0, 0, 1],
      ...[0, 0, 2, 0], // numPrograms 512
      ...[0, 0, 0, 1], // currentProgram
      ...List.filled(124, 0),
      ...[0, 0, 0, chunk.length],
      ...chunk,
    ]);
    ByteData.sublistView(file).setUint32(4, file.length - 8);

    final state = Vst2State.parseFile(file)!;
    expect(state.pluginId, sylenth1PluginId);
    expect(SylenthBank.read(state.chunk!)!.selectedName, 'Sub');
  });
}
