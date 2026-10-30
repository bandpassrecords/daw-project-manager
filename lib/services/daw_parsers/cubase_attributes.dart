import 'dart:convert';
import 'dart:typed_data';

/// Reads the attribute trees Cubase writes for mixer channels, plug-ins and
/// project settings ("VST Multitrack", "OwnInputBus", media attributes…).
///
/// ## The format
///
/// An attribute is a key — `u32` length counting the NUL, the name, NUL —
/// then a `u16` type and the value, all big-endian:
///
/// | type | value |
/// |---|---|
/// | 1 | `i64` |
/// | 4 | `f64` |
/// | 8 | a string: `u32` length (counting a NUL, and on newer versions a UTF-8 BOM after it), the bytes |
/// | 2 | a container: a `u16` kind, then by kind |
///
/// | kind | container |
/// |---|---|
/// | 6 | folder: `u32` n, then n attributes |
/// | 5 | list: `u32` n items, each a `u32` m and m attributes (the 16 insert slots are one) |
/// | 4 | strings: `u32` n, n strings |
/// | 2 | integers: `u32` n, n `i64` |
/// | 0x14 | object: a class-name string, an 8-byte id, `u32` n, n attributes |
/// | 0x15 | a reference to an object written earlier: its 8-byte id |
/// | 0xc9 | array: `u32` n, n containers (kind + body) |
/// | 7 | binary: `u32` length, the bytes (a plug-in's state) |
///
/// A tree's root ("VST Multitrack") is its key, eight bytes, then `u32` n
/// attributes. Measured on 3,672 channels from Cubase 4 to 13: every one
/// decodes with these kinds.
class CubaseAttributeDecoder {
  CubaseAttributeDecoder(this.bytes) : _data = ByteData.sublistView(bytes);

  final Uint8List bytes;
  final ByteData _data;

  static const _maxDepth = 64;
  static const _maxCount = 1 << 20;

  /// The tree whose root key starts at [keyOffset], or null when the bytes
  /// there are not one (or run past [limit]).
  CubaseAttributes? rootAt(int keyOffset, {int? limit}) {
    final r = _Reader(this, keyOffset, limit ?? bytes.length);
    try {
      r.string();
      r.skip(8);
      return CubaseAttributes(r.attributes(r.count(), 0));
    } on _Malformed {
      return null;
    }
  }

  /// The value of the single attribute whose key starts at [keyOffset], with
  /// where it ends; null when malformed.
  ({String key, Object? value, int end})? attributeAt(int keyOffset,
      {int? limit}) {
    final r = _Reader(this, keyOffset, limit ?? bytes.length);
    try {
      final key = r.string();
      final value = r.value(0);
      return (key: key, value: value, end: r.offset);
    } on _Malformed {
      return null;
    }
  }

  /// `u32` length + name + NUL, the way keys are written.
  static List<int> keyBytes(String key) {
    final n = key.length + 1;
    return [
      (n >> 24) & 0xFF,
      (n >> 16) & 0xFF,
      (n >> 8) & 0xFF,
      n & 0xFF,
      ...ascii.encode(key),
      0,
    ];
  }
}

/// A folder or object: its attributes in the order they were written.
class CubaseAttributes {
  const CubaseAttributes(this.entries, {this.className});

  final List<(String, Object?)> entries;

  /// For an object, its class ("CmRational"); null for a folder.
  final String? className;

  Object? operator [](String key) {
    for (final (k, v) in entries) {
      if (k == key) return v;
    }
    return null;
  }

  int? integer(String key) => switch (this[key]) { final int v => v, _ => null };

  /// An `f64` or an `i64`, as a double.
  double? number(String key) => switch (this[key]) {
        final double v => v,
        final int v => v.toDouble(),
        _ => null,
      };

  String? string(String key) =>
      switch (this[key]) { final String v => v, _ => null };

  CubaseAttributes? folder(String key) =>
      switch (this[key]) { final CubaseAttributes v => v, _ => null };

  /// A list's items; empty when [key] is absent or not a list.
  List<CubaseAttributes> list(String key) => switch (this[key]) {
        final List<CubaseAttributes> v => v,
        _ => const [],
      };

  /// The `Value` inside the folder named [key] — how Cubase stores a
  /// parameter ("Volume", "OutputBusValue").
  double? valueOf(String key) => folder(key)?.number('Value');
}

/// A plug-in's state or other binary: where it is, not what it holds.
class CubaseBlob {
  const CubaseBlob(this.offset, this.length);
  final int offset;
  final int length;
}

/// A reference to an object written earlier, by its id.
class CubaseReference {
  const CubaseReference(this.id);
  final int id;
}

class _Malformed implements Exception {
  const _Malformed();
}

class _Reader {
  _Reader(this.d, this.offset, this.limit);

  final CubaseAttributeDecoder d;
  int offset;
  final int limit;

  void _need(int n) {
    if (offset < 0 || offset + n > limit) throw const _Malformed();
  }

  void skip(int n) {
    _need(n);
    offset += n;
  }

  int u16() {
    _need(2);
    final v = d._data.getUint16(offset);
    offset += 2;
    return v;
  }

  int u32() {
    _need(4);
    final v = d._data.getUint32(offset);
    offset += 4;
    return v;
  }

  int i64() {
    _need(8);
    final v = d._data.getInt64(offset);
    offset += 8;
    return v;
  }

  double f64() {
    _need(8);
    final v = d._data.getFloat64(offset);
    offset += 8;
    return v;
  }

  int count() {
    final n = u32();
    if (n > CubaseAttributeDecoder._maxCount) throw const _Malformed();
    return n;
  }

  String string() {
    final n = count();
    _need(n);
    var end = offset + n;
    final start = offset;
    offset = end;
    if (n >= 4 &&
        d.bytes[end - 3] == 0xEF &&
        d.bytes[end - 2] == 0xBB &&
        d.bytes[end - 1] == 0xBF) {
      end -= 3;
    }
    if (end > start && d.bytes[end - 1] == 0) end--;
    return utf8.decode(d.bytes.sublist(start, end), allowMalformed: true);
  }

  List<(String, Object?)> attributes(int n, int depth) {
    if (depth > CubaseAttributeDecoder._maxDepth) throw const _Malformed();
    return [for (var i = 0; i < n; i++) (string(), value(depth))];
  }

  Object? value(int depth) => switch (u16()) {
        1 => i64(),
        4 => f64(),
        8 => string(),
        2 => container(depth + 1),
        _ => throw const _Malformed(),
      };

  Object? container(int depth) {
    switch (u16()) {
      case 6:
        return CubaseAttributes(attributes(count(), depth));
      case 5:
        final n = count();
        return <CubaseAttributes>[
          for (var i = 0; i < n; i++)
            CubaseAttributes(attributes(count(), depth)),
        ];
      case 4:
        final n = count();
        return <String>[for (var i = 0; i < n; i++) string()];
      case 2:
        final n = count();
        return <int>[for (var i = 0; i < n; i++) i64()];
      case 0x14:
        final cls = string();
        skip(8);
        return CubaseAttributes(attributes(count(), depth), className: cls);
      case 0x15:
        return CubaseReference(i64());
      case 0xc9:
        final n = count();
        return <Object?>[for (var i = 0; i < n; i++) container(depth + 1)];
      case 7:
        final n = count();
        final at = offset;
        skip(n);
        return CubaseBlob(at, n);
      default:
        throw const _Malformed();
    }
  }
}
