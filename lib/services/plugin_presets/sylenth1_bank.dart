import 'dart:io';
import 'dart:typed_data';

import 'vst2_state.dart';

/// Sylenth1's plug-in ID, as in its `.fxb` header.
const sylenth1PluginId = 'syl1';

/// What Sylenth1 keeps in the chunk of its `FBCh` bank: every program it had
/// loaded, by name, and which one was selected.
///
/// The chunk is little-endian, whatever the file around it:
///
/// ```
/// "1lys"  version  programCount  fieldsPerProgram  currentProgram   20 bytes
/// programCount x { float fields[fieldsPerProgram]; char name[36]; }
/// ```
///
/// From version 3045 the chunk is `"1lys" version` followed by a zlib stream
/// holding those 20 bytes and the records; older versions are plain. Which of
/// the two it is comes from whether the plain reading fits, never from the
/// version number.
class SylenthBank {
  const SylenthBank({
    required this.version,
    required this.currentProgram,
    required this.names,
    this.fields = 0,
    this.records = const [],
    this.compressed = false,
    Uint8List? prefix,
  }) : _prefix = prefix;

  /// Floats per program.
  final int fields;

  /// Every program as stored (its floats, then its name), in slot order.
  final List<Uint8List> records;

  /// Whether the chunk was a zlib stream (version 3045 on).
  final bool compressed;

  /// The first eight bytes of the header (the magic and the version), kept as
  /// the plug-in wrote them.
  final Uint8List? _prefix;

  final int version;

  /// The selected program's index, as the plug-in stored it (it can be out of
  /// range in a damaged bank).
  final int currentProgram;

  /// Every program's name, in slot order. Unused slots are called "Init".
  final List<String> names;

  /// The selected program's name; null when [currentProgram] is out of range.
  String? get selectedName =>
      currentProgram >= 0 && currentProgram < names.length
      ? names[currentProgram]
      : null;

  /// Reads the chunk of a Sylenth1 `FBCh` bank. Null when it is not one, or
  /// is cut short or damaged.
  static SylenthBank? read(Uint8List chunk) {
    if (chunk.length < 20 || _tag(chunk) != '1lys') return null;
    final plain = _fromRecords(chunk, compressed: false);
    if (plain != null) return plain;
    try {
      final inflated = Uint8List.fromList(
        ZLibDecoder().convert(Uint8List.sublistView(chunk, 8)),
      );
      return _fromRecords(inflated, compressed: true);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static const _headerLength = 20;
  static const _nameLength = 36;
  static const _maxPrograms = 4096;
  static const _maxFields = 1024;

  /// [data] as the 20-byte header and the records.
  static SylenthBank? _fromRecords(Uint8List data, {required bool compressed}) {
    if (data.length < _headerLength) return null;
    final view = ByteData.sublistView(data);
    final version = view.getUint32(4, Endian.little);
    final count = view.getUint32(8, Endian.little);
    final fields = view.getUint32(12, Endian.little);
    final current = view.getUint32(16, Endian.little);
    if (count == 0 || count > _maxPrograms) return null;
    if (fields == 0 || fields > _maxFields) return null;
    final record = fields * 4 + _nameLength;
    if (_headerLength + count * record > data.length) return null;
    final records = [
      for (var i = 0; i < count; i++)
        Uint8List.fromList(
          data.sublist(
            _headerLength + i * record,
            _headerLength + (i + 1) * record,
          ),
        ),
    ];
    return SylenthBank(
      version: version,
      currentProgram: current,
      fields: fields,
      records: records,
      compressed: compressed,
      prefix: Uint8List.fromList(data.sublist(0, 8)),
      names: [
        for (var i = 0; i < count; i++)
          _name(data, _headerLength + i * record + fields * 4),
      ],
    );
  }

  /// The chunk of a bank like this one with only the selected program in it:
  /// that program in the first slot, every other slot an empty "Init" copied
  /// from this bank. Same slot count, field count, version and compression as
  /// the plug-in wrote, so it is a bank Sylenth1 has no reason to refuse.
  ///
  /// Null when there is no selected program, or the bank has no "Init" slot
  /// to fill the rest with — then nothing here says what an empty slot is,
  /// and guessing would write a bank the plug-in may not load.
  Uint8List? chunkWithOnlySelected() {
    final selected = currentProgram;
    final prefix = _prefix;
    if (prefix == null ||
        records.isEmpty ||
        selected < 0 ||
        selected >= records.length) {
      return null;
    }
    final init = names.indexWhere((n) => n.toLowerCase() == 'init');
    if (init < 0) return null;

    final inner = Uint8List.fromList([
      ...prefix,
      ..._le(records.length),
      ..._le(fields),
      ..._le(0),
      ...records[selected],
      for (var i = 1; i < records.length; i++) ...records[init],
    ]);
    if (!compressed) return inner;
    return Uint8List.fromList([
      ...inner.sublist(0, 8),
      ...ZLibEncoder().convert(inner),
    ]);
  }

  static List<int> _le(int v) =>
      (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

  /// A name in its 36-byte buffer: up to the first NUL. Sylenth1 does not
  /// clear the buffer, so what follows the NUL is the previous name's tail.
  static String _name(Uint8List data, int offset) {
    var end = offset;
    while (end < offset + _nameLength && data[end] != 0) {
      end++;
    }
    return String.fromCharCodes(data.sublist(offset, end)).trim();
  }

  static String _tag(Uint8List bytes) =>
      String.fromCharCodes(bytes.sublist(0, 4));
}

/// A Sylenth1 bank file holding only the program that was selected in [state],
/// in its first slot, or null when [state] is not a Sylenth1 bank or one can't
/// be made (see [SylenthBank.chunkWithOnlySelected]).
///
/// The `.fxb` around the chunk is the original's, with its selected program
/// set to the first slot and its sizes updated.
Uint8List? sylenthBankWithOnlySelected(Vst2State state) {
  if (state.pluginId != sylenth1PluginId ||
      state.kind != Vst2StateKind.opaqueBank) {
    return null;
  }
  final chunk = state.chunk;
  if (chunk == null) return null;
  final bank = SylenthBank.read(chunk);
  final replacement = bank?.chunkWithOnlySelected();
  if (replacement == null) return null;

  // The header runs to the chunk's size field (156) and the chunk follows;
  // anything after the chunk would not be accounted for, so it is refused.
  const chunkStart = 160;
  final file = state.file;
  if (file.length != chunkStart + chunk.length) return null;

  final out = Uint8List.fromList([
    ...file.sublist(0, chunkStart),
    ...replacement,
  ]);
  final view = ByteData.sublistView(out);
  view.setUint32(4, out.length - 8); // CcnK byteSize
  view.setUint32(28, 0); // the bank's selected program
  view.setUint32(156, replacement.length); // chunk size
  return out;
}
