import 'dart:io';
import 'dart:typed_data';

import 'package:daw_project_manager/services/plugin_presets/vst2_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Uint8List _u32(int v) => (ByteData(4)..setUint32(0, v)).buffer.asUint8List();

Uint8List _cat(List<List<int>> parts) =>
    Uint8List.fromList([for (final part in parts) ...part]);

List<int> _ascii(String s) => s.codeUnits;

List<int> _name(String s, {int length = 28, int fill = 0}) {
  final bytes = List<int>.filled(length, fill);
  final codes = s.codeUnits;
  bytes.setRange(0, codes.length, codes);
  if (codes.length < length) bytes[codes.length] = 0;
  return bytes;
}

/// A `CcnK` file: `magic`, version 1, [id], then [rest].
Uint8List _file(String magic, String id, List<int> rest) {
  final body = _cat([
    _ascii(magic),
    _u32(1),
    _ascii(id),
    _u32(7), // fxVersion
    rest,
  ]);
  return _cat([_ascii('CcnK'), _u32(body.length), body]);
}

Uint8List _wrap(Uint8List file, {int bypass = 0}) =>
    _cat([_ascii('VstW'), _u32(8), _u32(1), _u32(bypass), file]);

Uint8List _program(String name, {int params = 2}) => _file('FxCk', 'abcd', [
  ..._u32(params),
  ..._name(name),
  for (var i = 0; i < params; i++) ..._u32(0x3f000000),
]);

Uint8List _plainBank(List<String> names, int current) {
  final programs = [for (final n in names) ..._program(n)];
  return _file('FxBk', 'abcd', [
    ..._u32(names.length),
    ..._u32(current),
    ...List<int>.filled(124, 0),
    ...programs,
  ]);
}

Uint8List _opaqueBank(
  List<int> chunk, {
  int programs = 512,
  int current = 35,
}) => _file('FBCh', 'syl1', [
  ..._u32(programs),
  ..._u32(current),
  ...List<int>.filled(124, 0),
  ..._u32(chunk.length),
  ...chunk,
]);

Uint8List _opaqueProgram(String name, List<int> chunk) => _file(
  'FPCh',
  'abcd',
  [..._u32(0), ..._name(name), ..._u32(chunk.length), ...chunk],
);

void main() {
  group('Vst2State.parse', () {
    test('an opaque bank (FBCh) keeps its chunk, ID and selected program', () {
      final file = _opaqueBank([1, 2, 3, 4]);
      final state = Vst2State.parse(_wrap(file))!;

      expect(state.kind, Vst2StateKind.opaqueBank);
      expect(state.pluginId, 'syl1');
      expect(state.count, 512);
      expect(state.currentProgram, 35);
      expect(state.fileExtension, '.fxb');
      expect(state.chunk, [1, 2, 3, 4]);
      expect(state.programName, isNull, reason: 'names live in the chunk');
      expect(state.file, file, reason: 'the file is stored as is');
    });

    test('an opaque program (FPCh) has its name and chunk', () {
      final state = Vst2State.parse(
        _wrap(_opaqueProgram('Warm Pad', [9, 8, 7])),
      )!;

      expect(state.kind, Vst2StateKind.opaqueProgram);
      expect(state.programName, 'Warm Pad');
      expect(state.fileExtension, '.fxp');
      expect(state.chunk, [9, 8, 7]);
      expect(state.currentProgram, isNull);
    });

    test('a plain program (FxCk) has its name and no chunk', () {
      final state = Vst2State.parse(_wrap(_program('Lead')))!;

      expect(state.kind, Vst2StateKind.program);
      expect(state.programName, 'Lead');
      expect(state.count, 2);
      expect(state.chunk, isNull);
    });

    test('a plain bank (FxBk) names the selected program from inside', () {
      final state = Vst2State.parse(
        _wrap(_plainBank(['Init', 'Bass', 'Pluck'], 1)),
      )!;

      expect(state.kind, Vst2StateKind.bank);
      expect(state.count, 3);
      expect(state.currentProgram, 1);
      expect(state.programName, 'Bass');
    });

    test('a selected program past the end of the bank has no name', () {
      final state = Vst2State.parse(_wrap(_plainBank(['Init', 'Bass'], 5)))!;

      expect(state.currentProgram, 5);
      expect(state.programName, isNull);
    });

    test('a name stops at its NUL, never reading the stale bytes after it', () {
      final file = _file('FxCk', 'abcd', [
        ..._u32(0),
        ..._name('Lead', fill: 0x58), // "Lead", NUL, then "XXXX…"
      ]);
      expect(Vst2State.parse(_wrap(file))!.programName, 'Lead');
    });

    test('an empty name is an empty string, not a failure', () {
      expect(Vst2State.parse(_wrap(_program('')))!.programName, '');
    });

    test('the wrapper\'s bypass flag is read', () {
      expect(
        Vst2State.parse(_wrap(_program('A'), bypass: 1))!.bypassed,
        isTrue,
      );
      expect(Vst2State.parse(_wrap(_program('A')))!.bypassed, isFalse);
    });

    test('bytes after the file are not part of it', () {
      final file = _program('A');
      final padded = _cat([
        _wrap(file),
        [0xAA, 0xBB, 0xCC],
      ]);

      expect(Vst2State.parse(padded)!.file, file);
    });

    test('a native VST3 state (no VstW) is not VST2', () {
      expect(
        Vst2State.parse(_cat([_ascii('VST3'), List.filled(60, 1)])),
        isNull,
      );
    });

    test('a truncated file is refused', () {
      final whole = _wrap(_opaqueBank(List.filled(100, 5)));

      expect(
        Vst2State.parse(Uint8List.sublistView(whole, 0, whole.length - 20)),
        isNull,
      );
      expect(Vst2State.parse(Uint8List.sublistView(whole, 0, 30)), isNull);
      expect(Vst2State.parse(Uint8List(0)), isNull);
    });

    test('a wrong wrapper size, container tag or file magic is refused', () {
      final good = _wrap(_program('A'));
      final badWrapper = Uint8List.fromList(good)..[7] = 9;
      final badContainer = Uint8List.fromList(good)..[16] = 0x58;
      final badMagic = Uint8List.fromList(good)..[24] = 0x58;

      expect(Vst2State.parse(badWrapper), isNull);
      expect(Vst2State.parse(badContainer), isNull);
      expect(Vst2State.parse(badMagic), isNull);
    });

    test(
      'an opaque chunk longer than its file gives no chunk, not a crash',
      () {
        final file = _opaqueBank([1, 2, 3, 4]);
        // Claim a chunk of a million bytes.
        final lying = Uint8List.fromList(file)
          ..buffer.asByteData().setUint32(156, 1000000);

        expect(Vst2State.parse(_wrap(lying))!.chunk, isNull);
      },
    );
  });

  group('on the real Cubase projects', () {
    // Every audioComponent blob in the corpus that starts with VstW is a state
    // the plan's survey found whole: length == 16 + byteSize + 8.
    final root = p.join('test', 'fixtures', 'projects', 'cubase');
    final projects = Directory(root).existsSync()
        ? Directory(root)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('.cpr'))
              .toList()
        : <File>[];

    final key = Uint8List.fromList([
      ...'audioComponent'.codeUnits,
      0,
      0,
      2,
      0,
      7,
    ]);

    List<Uint8List> blobs(Uint8List bytes) {
      final out = <Uint8List>[];
      final data = ByteData.sublistView(bytes);
      for (var i = 0; i + key.length + 4 <= bytes.length; i++) {
        var match = true;
        for (var k = 0; k < key.length; k++) {
          if (bytes[i + k] != key[k]) {
            match = false;
            break;
          }
        }
        if (!match) continue;
        final start = i + key.length + 4;
        final length = data.getUint32(i + key.length);
        if (start + length <= bytes.length) {
          out.add(Uint8List.sublistView(bytes, start, start + length));
        }
      }
      return out;
    }

    test('the corpus is there', () => expect(projects, isNotEmpty));

    test('every VstW blob parses, to the byte', () {
      var checked = 0;
      for (final project in projects) {
        for (final blob in blobs(project.readAsBytesSync())) {
          if (blob.length < 4 ||
              String.fromCharCodes(blob.sublist(0, 4)) != 'VstW') {
            continue;
          }
          final state = Vst2State.parse(blob);
          expect(state, isNotNull, reason: p.basename(project.path));
          expect(state!.file.length, blob.length - 16);
          checked++;
        }
      }
      expect(checked, greaterThan(100));
    });
  });
}
