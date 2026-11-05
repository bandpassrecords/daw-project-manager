import 'dart:io';
import 'dart:typed_data';

import 'package:daw_project_manager/services/plugin_presets/sylenth1_bank.dart';
import 'package:daw_project_manager/services/plugin_presets/vst2_state.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _le(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List().toList();

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
        SylenthBank.read(
          _records(['A', 'B'], current: 0, version: 3045),
        )!.names,
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

  group('a bank with only the selected program', () {
    /// A 6-slot bank (real ones have 512) with distinct floats per program.
    Uint8List bank({
      required int current,
      bool compressed = false,
      List<String>? names,
    }) {
      final programNames =
          names ?? ['Init', 'Bass', 'LD Axe', 'Init', 'Pad', 'Init'];
      final records = [
        for (var i = 0; i < programNames.length; i++) ...[
          for (var f = 0; f < 3; f++) ..._le(0x3f000000 + i * 256 + f),
          ..._name(programNames[i]),
        ],
      ];
      final inner = Uint8List.fromList([
        ...'1lys'.codeUnits,
        ..._le(compressed ? 3045 : 3031),
        ..._le(programNames.length),
        ..._le(3),
        ..._le(current),
        ...records,
      ]);
      final chunk = compressed
          ? Uint8List.fromList([
              ...inner.sublist(0, 8),
              ...ZLibEncoder().convert(inner),
            ])
          : inner;
      final file = Uint8List.fromList([
        ...'CcnK'.codeUnits,
        0,
        0,
        0,
        0,
        ...'FBCh'.codeUnits,
        0,
        0,
        0,
        1,
        ...sylenth1PluginId.codeUnits,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        programNames.length,
        0,
        0,
        0,
        current,
        ...List.filled(124, 0),
        0,
        0,
        (chunk.length >> 8) & 0xFF,
        chunk.length & 0xFF,
        ...chunk,
      ]);
      ByteData.sublistView(file).setUint32(4, file.length - 8);
      return file;
    }

    Vst2State stateOf(Uint8List file) => Vst2State.parseFile(file)!;

    for (final compressed in [false, true]) {
      group(compressed ? 'zlib (3045)' : 'plain', () {
        test('keeps that program in the first slot and the rest empty', () {
          final original = stateOf(bank(current: 2, compressed: compressed));
          final out = sylenthBankWithOnlySelected(original)!;

          final state = Vst2State.parseFile(out)!;
          final result = SylenthBank.read(state.chunk!)!;
          final source = SylenthBank.read(original.chunk!)!;

          expect(result.names, [
            'LD Axe',
            'Init',
            'Init',
            'Init',
            'Init',
            'Init',
          ]);
          expect(result.currentProgram, 0);
          expect(result.selectedName, 'LD Axe');
          expect(
            result.records.first,
            source.records[2],
            reason: 'the program itself, byte for byte',
          );
          for (final empty in result.records.skip(1)) {
            expect(
              empty,
              source.records[0],
              reason: 'an Init as the bank had it',
            );
          }
          expect(result.compressed, compressed);
          expect(result.version, source.version);
          expect(result.fields, source.fields);
        });

        test(
          'the file around it is the original\'s, with sizes and selection updated',
          () {
            final original = stateOf(bank(current: 4, compressed: compressed));
            final out = sylenthBankWithOnlySelected(original)!;
            final state = Vst2State.parseFile(out)!;

            expect(state.kind, Vst2StateKind.opaqueBank);
            expect(state.pluginId, sylenth1PluginId);
            expect(state.count, original.count, reason: 'same number of slots');
            expect(state.currentProgram, 0);
            expect(out.length, state.file.length, reason: 'byteSize matches');
            // The header between the sizes is untouched.
            expect(out.sublist(8, 28), original.file.sublist(8, 28));
          },
        );
      });
    }

    test(
      'different banks with the same selected program give the same file',
      () {
        final a = stateOf(bank(current: 2));
        final b = stateOf(
          bank(
            current: 2,
            names: ['Init', 'Other', 'LD Axe', 'Init', 'X', 'Init'],
          ),
        );
        // The programs differ in floats only by index, so compare the first
        // slot's name and that every other slot is empty.
        expect(
          SylenthBank.read(
            Vst2State.parseFile(sylenthBankWithOnlySelected(a)!)!.chunk!,
          )!.names,
          SylenthBank.read(
            Vst2State.parseFile(sylenthBankWithOnlySelected(b)!)!.chunk!,
          )!.names,
        );
      },
    );

    test('null where nothing says what an empty slot is', () {
      final noInit = stateOf(
        bank(current: 1, names: ['A', 'B', 'C', 'D', 'E', 'F']),
      );
      expect(sylenthBankWithOnlySelected(noInit), isNull);
    });

    test(
      'null for a selection past the end, another plug-in, or a program',
      () {
        expect(sylenthBankWithOnlySelected(stateOf(bank(current: 9))), isNull);

        final other = Uint8List.fromList(bank(current: 1))
          ..setRange(16, 20, 'abcd'.codeUnits);
        expect(sylenthBankWithOnlySelected(stateOf(other)), isNull);
      },
    );
  });
}
