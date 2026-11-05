import 'dart:typed_data';

/// What a VST2 state file holds, by its magic.
enum Vst2StateKind {
  /// `FxBk`: a bank of programs, each stored as parameters.
  bank,

  /// `FxCk`: one program, stored as parameters.
  program,

  /// `FBCh`: a bank whose content is the plug-in's own chunk.
  opaqueBank,

  /// `FPCh`: one program whose content is the plug-in's own chunk.
  opaqueProgram;

  bool get isBank => this == bank || this == opaqueBank;
}

/// A VST2 plug-in's saved state, as Cubase keeps it inside a project.
///
/// Cubase wraps a VST2 plug-in's state in a 16-byte `VstW` header followed by
/// a **complete `.fxb` or `.fxp` file** (`CcnK`…). [file] is exactly that
/// file, so writing it to disk gives something the plug-in loads directly:
/// nothing is decoded and re-encoded. A native VST3 state is also an
/// `audioComponent` blob but does not start with `VstW`, and [parse] returns
/// null for it.
///
/// Layouts are big-endian, from the VST 2.4 SDK's `fxProgram`/`fxBank`.
class Vst2State {
  Vst2State._({
    required this.file,
    required this.kind,
    required this.pluginId,
    required this.fxVersion,
    required this.bypassed,
    required this.count,
    required this.currentProgram,
    required this.programName,
  });

  /// The `.fxb` (banks) or `.fxp` (programs) file, byte for byte.
  final Uint8List file;
  final Vst2StateKind kind;

  /// The plug-in's four-character ID ("syl1" for Sylenth1).
  final String pluginId;
  final int fxVersion;

  /// Whether Cubase had the instance bypassed (the wrapper's own flag).
  final bool bypassed;

  /// A bank's number of programs, a program's number of parameters.
  final int count;

  /// A bank's selected program, when its header says (bank version 2).
  final int? currentProgram;

  /// A program's name; for a plain bank (`FxBk`), the selected program's.
  /// Null when the file doesn't say, which is the case for every `FBCh`:
  /// the plug-in keeps its own names inside the chunk.
  final String? programName;

  String get fileExtension => kind.isBank ? '.fxb' : '.fxp';

  /// The plug-in's own chunk, for the two opaque kinds.
  Uint8List? get chunk {
    switch (kind) {
      case Vst2StateKind.opaqueBank:
        return _chunkAt(_bankChunkSizeOffset);
      case Vst2StateKind.opaqueProgram:
        return _chunkAt(_programChunkSizeOffset);
      case Vst2StateKind.bank:
      case Vst2StateKind.program:
        return null;
    }
  }

  Uint8List? _chunkAt(int sizeOffset) {
    if (file.length < sizeOffset + 4) return null;
    final size = ByteData.sublistView(file).getUint32(sizeOffset);
    final start = sizeOffset + 4;
    if (start + size > file.length) return null;
    return Uint8List.sublistView(file, start, start + size);
  }

  static const _wrapperHeader = 16;
  // `CcnK`, byteSize, magic, version, fxID, fxVersion, numPrograms|numParams.
  static const _commonHeader = 28;
  // …then `currentProgram` and 124 reserved bytes, before an opaque bank's
  // chunk size.
  static const _bankChunkSizeOffset = 156;
  // …then a 28-byte name, before an opaque program's chunk size.
  static const _programNameLength = 28;
  static const _programChunkSizeOffset = _commonHeader + _programNameLength;

  /// Reads an `audioComponent` blob. Null when it is not a VST2 state (a VST3
  /// plug-in's, or anything else) or when it is cut short or inconsistent.
  static Vst2State? parse(Uint8List blob) {
    if (blob.length < _wrapperHeader + _commonHeader) return null;
    if (_tag(blob, 0) != 'VstW') return null;
    final wrapper = ByteData.sublistView(blob);
    if (wrapper.getUint32(4) != 8) return null;
    final bypassed = wrapper.getUint32(12) != 0;

    return _fromFile(
      Uint8List.sublistView(blob, _wrapperHeader),
      bypassed: bypassed,
    );
  }

  /// Reads a `.fxb`/`.fxp` file as it is on disk, with no Cubase wrapper.
  /// Bytes past the file's own end are ignored.
  static Vst2State? parseFile(Uint8List inner) =>
      inner.length < _commonHeader ? null : _fromFile(inner, bypassed: false);

  static Vst2State? _fromFile(Uint8List inner, {required bool bypassed}) {
    final data = ByteData.sublistView(inner);
    if (_tag(inner, 0) != 'CcnK') return null;
    // `byteSize` counts everything after itself.
    final fileLength = data.getUint32(4) + 8;
    if (fileLength > inner.length || fileLength < _commonHeader) return null;
    final file = Uint8List.sublistView(inner, 0, fileLength);
    final fileData = ByteData.sublistView(file);

    final Vst2StateKind kind;
    switch (_tag(file, 8)) {
      case 'FxBk':
        kind = Vst2StateKind.bank;
      case 'FxCk':
        kind = Vst2StateKind.program;
      case 'FBCh':
        kind = Vst2StateKind.opaqueBank;
      case 'FPCh':
        kind = Vst2StateKind.opaqueProgram;
      default:
        return null;
    }

    final count = fileData.getUint32(24);
    int? currentProgram;
    String? programName;
    if (kind.isBank) {
      if (fileLength < _bankChunkSizeOffset) return null;
      currentProgram = fileData.getUint32(28);
      if (kind == Vst2StateKind.bank && currentProgram < count) {
        programName = _bankProgramName(file, count, currentProgram);
      }
    } else {
      if (fileLength < _programChunkSizeOffset) return null;
      programName = _name(file, _commonHeader, _programNameLength);
    }

    return Vst2State._(
      file: file,
      kind: kind,
      pluginId: _tag(file, 16),
      fxVersion: fileData.getUint32(20),
      bypassed: bypassed,
      count: count,
      currentProgram: currentProgram,
      programName: programName,
    );
  }

  /// The name of program [index] in a plain bank: its programs follow the
  /// 156-byte header, each a whole `CcnK…FxCk` of its own length.
  static String? _bankProgramName(Uint8List file, int count, int index) {
    final data = ByteData.sublistView(file);
    var offset = _bankChunkSizeOffset;
    for (var i = 0; i <= index && i < count; i++) {
      if (offset + _commonHeader + _programNameLength > file.length) {
        return null;
      }
      if (_tag(file, offset) != 'CcnK' || _tag(file, offset + 8) != 'FxCk') {
        return null;
      }
      if (i == index) {
        return _name(file, offset + _commonHeader, _programNameLength);
      }
      offset += data.getUint32(offset + 4) + 8;
    }
    return null;
  }

  static String _tag(Uint8List bytes, int offset) =>
      String.fromCharCodes(bytes.sublist(offset, offset + 4));

  /// A NUL-terminated name in a fixed buffer. Anything after the first NUL is
  /// stale bytes (plug-ins don't always clear their buffers), never part of it.
  static String _name(Uint8List bytes, int offset, int length) {
    var end = offset;
    final limit = offset + length;
    while (end < limit && bytes[end] != 0) {
      end++;
    }
    return String.fromCharCodes(bytes.sublist(offset, end)).trim();
  }
}
