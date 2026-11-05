import 'dart:typed_data';

import 'package:daw_project_manager/services/plugin_presets/vst2_state.dart';

/// Small `.fxb`/`.fxp` files for tests, laid out as the VST 2.4 SDK says.

Uint8List _u32(int v) => (ByteData(4)..setUint32(0, v)).buffer.asUint8List();

List<int> _padded(String s, int length) {
  final bytes = List<int>.filled(length, 0);
  bytes.setRange(0, s.length, s.codeUnits);
  return bytes;
}

Uint8List _file(String magic, String id, List<int> rest) {
  final body = [...magic.codeUnits, ..._u32(1), ...id.codeUnits, ..._u32(1), ...rest];
  return Uint8List.fromList(['CcnK'.codeUnits, _u32(body.length), body].expand((e) => e).toList());
}

/// A plain program (`FxCk`) named [name].
Uint8List fxProgram(String id, String name, {int params = 2, int value = 0x3f000000}) =>
    _file('FxCk', id, [
      ..._u32(params),
      ..._padded(name, 28),
      for (var i = 0; i < params; i++) ..._u32(value),
    ]);

/// An opaque bank (`FBCh`) around [chunk].
Uint8List fxOpaqueBank(String id, List<int> chunk, {int programs = 512, int current = 0}) =>
    _file('FBCh', id, [
      ..._u32(programs),
      ..._u32(current),
      ...List<int>.filled(124, 0),
      ..._u32(chunk.length),
      ...chunk,
    ]);

Vst2State stateOf(Uint8List file) => Vst2State.parseFile(file)!;
