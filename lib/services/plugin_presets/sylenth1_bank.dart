import 'dart:io';
import 'dart:typed_data';

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
  });

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
    final plain = _fromRecords(chunk);
    if (plain != null) return plain;
    try {
      final inflated = Uint8List.fromList(
        ZLibDecoder().convert(Uint8List.sublistView(chunk, 8)),
      );
      return _fromRecords(inflated);
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
  static SylenthBank? _fromRecords(Uint8List data) {
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
    return SylenthBank(
      version: version,
      currentProgram: current,
      names: [
        for (var i = 0; i < count; i++)
          _name(data, _headerLength + i * record + fields * 4),
      ],
    );
  }

  /// A name in its 36-byte buffer: up to the first NUL. Sylenth1 does not
  /// clear the buffer, so what follows the NUL is the previous name's tail.
  static String _name(Uint8List data, int offset) {
    var end = offset;
    while (end < offset + _nameLength && data[end] != 0) {
      end++;
    }
    return String.fromCharCodes(data.sublist(offset, end)).trim();
  }

  static String _tag(Uint8List bytes) => String.fromCharCodes(bytes.sublist(0, 4));
}
