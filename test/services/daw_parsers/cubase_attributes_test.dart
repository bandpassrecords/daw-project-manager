import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/daw_parsers/cubase_attributes.dart';

/// Writes attribute trees byte by byte, as Cubase does.
class _W {
  final b = BytesBuilder();
  void u16(int v) => b.add([(v >> 8) & 255, v & 255]);
  void u32(int v) =>
      b.add([(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]);
  void i64(int v) => b.add((ByteData(8)..setInt64(0, v)).buffer.asUint8List());
  void f64(double v) =>
      b.add((ByteData(8)..setFloat64(0, v)).buffer.asUint8List());
  void str(String s, {bool bom = false}) {
    final data = [...utf8.encode(s), 0, if (bom) ...[0xEF, 0xBB, 0xBF]];
    u32(data.length);
    b.add(data);
  }

  void key(String k) => str(k);
  Uint8List get bytes => b.toBytes();
}

void main() {
  test('a root: its key, eight bytes, a count, then every kind of value', () {
    final w = _W()
      ..key('VST Multitrack')
      ..b.add([0, 0, 0, 4, 0xFF, 0xFE, 0xA4, 0xC8])
      ..u32(9);
    w
      ..key('Int')
      ..u16(1)
      ..i64(-1);
    w
      ..key('Float')
      ..u16(4)
      ..f64(44100);
    w
      ..key('Name')
      ..u16(8)
      ..str('Main Lead Group', bom: true);
    // A folder of one attribute.
    w
      ..key('Volume')
      ..u16(2)
      ..u16(6)
      ..u32(1)
      ..key('Value')
      ..u16(4)
      ..f64(25856);
    // A list of two items: one with an attribute, one empty.
    w
      ..key('Slot')
      ..u16(2)
      ..u16(5)
      ..u32(2)
      ..u32(1)
      ..key('State')
      ..u16(1)
      ..i64(1)
      ..u32(0);
    w
      ..key('ClassIDs')
      ..u16(2)
      ..u16(4)
      ..u32(2)
      ..str('A', bom: true)
      ..str('B');
    w
      ..key('Type')
      ..u16(2)
      ..u16(2)
      ..u32(2)
      ..i64(1)
      ..i64(2);
    // An object, a reference to it, and a plug-in's state.
    w
      ..key('Object')
      ..u16(2)
      ..u16(0x14)
      ..str('CmRational')
      ..i64(0x7513)
      ..u32(1)
      ..key('Numerator')
      ..u16(1)
      ..i64(3);
    w
      ..key('state')
      ..u16(2)
      ..u16(7)
      ..u32(3);
    w.b.add([1, 2, 3]);
    final bytes = w.bytes;

    final tree = CubaseAttributeDecoder(bytes).rootAt(0)!;
    expect(tree.integer('Int'), -1);
    expect(tree.number('Float'), 44100);
    expect(tree.string('Name'), 'Main Lead Group', reason: 'BOM dropped');
    expect(tree.valueOf('Volume'), 25856);
    expect(tree.list('Slot'), hasLength(2));
    expect(tree.list('Slot').first.integer('State'), 1);
    expect(tree.list('Slot').last.entries, isEmpty);
    expect(tree['ClassIDs'], ['A', 'B']);
    expect(tree['Type'], [1, 2]);
    final object = tree.folder('Object')!;
    expect(object.className, 'CmRational');
    expect(object.integer('Numerator'), 3);
    final blob = tree['state'] as CubaseBlob;
    expect(blob.length, 3);
    expect(bytes.sublist(blob.offset, blob.offset + 3), [1, 2, 3]);
  });

  test('typed arrays and references', () {
    final w = _W()
      ..key('obj')
      ..u16(2)
      ..u16(0xc9)
      ..u32(2)
      ..u16(0x14)
      ..str('QCDestinationValue')
      ..i64(1)
      ..u32(0)
      ..u16(0x15)
      ..i64(42);
    final a = CubaseAttributeDecoder(w.bytes).attributeAt(0)!;
    expect(a.key, 'obj');
    final items = a.value as List<Object?>;
    expect((items[0] as CubaseAttributes).className, 'QCDestinationValue');
    expect((items[1] as CubaseReference).id, 42);
    expect(a.end, w.bytes.length);
  });

  test('a missing key reads as null, never as a wrong type', () {
    final w = _W()
      ..key('Name')
      ..u16(8)
      ..str('x');
    final tree = CubaseAttributes([('Name', 'x')]);
    expect(tree.integer('Name'), isNull);
    expect(tree.folder('Name'), isNull);
    expect(tree.list('Name'), isEmpty);
    expect(tree.valueOf('Missing'), isNull);
    expect(CubaseAttributeDecoder(w.bytes).attributeAt(0)!.value, 'x');
  });

  test('truncated, unknown or runaway input is null, not a throw', () {
    final good = (_W()
          ..key('Volume')
          ..u16(2)
          ..u16(6)
          ..u32(1)
          ..key('Value')
          ..u16(4)
          ..f64(1))
        .bytes;
    for (var cut = 0; cut < good.length; cut++) {
      expect(CubaseAttributeDecoder(good.sublist(0, cut)).attributeAt(0),
          isNull,
          reason: 'cut at $cut');
    }
    // A limit inside the value is honoured like the end of the file.
    expect(CubaseAttributeDecoder(good).attributeAt(0, limit: good.length - 1),
        isNull);

    final unknownType = (_W()
          ..key('x')
          ..u16(99))
        .bytes;
    expect(CubaseAttributeDecoder(unknownType).attributeAt(0), isNull);

    final unknownKind = (_W()
          ..key('x')
          ..u16(2)
          ..u16(0x33))
        .bytes;
    expect(CubaseAttributeDecoder(unknownKind).attributeAt(0), isNull);

    final hugeCount = (_W()
          ..key('x')
          ..u16(2)
          ..u16(6)
          ..u32(0x7FFFFFFF))
        .bytes;
    expect(CubaseAttributeDecoder(hugeCount).attributeAt(0), isNull);
  });

  test('keyBytes writes a key as Cubase does', () {
    expect(CubaseAttributeDecoder.keyBytes('ID'), [0, 0, 0, 3, 73, 68, 0]);
  });
}
