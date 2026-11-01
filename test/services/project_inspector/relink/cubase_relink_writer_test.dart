import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/relink/cubase_relink_writer.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_writer.dart';

import '../../../helpers/cubase_archive.dart';

const _old = r'D:\MusicProduction\Projects\Song\Audio\';
const _kick = '${_old}kick.wav';
const _snare = '${_old}snare.wav';

/// A project naming kick.wav twice — on an event and in the pool, as
/// test-01.cpr does — and snare.wav once.
Uint8List _project({bool bom = true}) {
  final a = CubaseArchive()..begin('MTrackList');
  a.track('MAudioTrackEvent', 'Drums', () {
    a.channel(ownBus: 10, outBus: 0);
    a.begin('PAudioClip');
    a.poolFile('kick.wav', _old, bom: bom);
    a.end();
  });
  a.end();
  a.begin('PPool');
  a.poolFile('kick.wav', _old, bom: bom);
  a.poolFile('snare.wav', _old, bom: bom);
  a.end();
  return a.toCpr();
}

List<String> _paths(Uint8List bytes) =>
    [for (final f in CubaseProjectParser(bytes).readPoolPaths()) f.path];

void main() {
  const writer = CubaseRelinkWriter();

  test('a shorter folder is written in place, everywhere the file is named',
      () {
    final original = _project();
    final result = writer.write(original, {_kick: r'E:\Audio\kick.wav'});
    expect(result.relinked, {_kick});
    expect(result.refused, isEmpty);
    expect(result.bytes.length, original.length, reason: 'nothing moves');
    expect(_paths(result.bytes),
        [r'E:\Audio\kick.wav', r'E:\Audio\kick.wav', _snare]);
    expect(writer.referencedPaths(result.bytes),
        unorderedEquals([r'E:\Audio\kick.wav', _snare]));
  });

  test('only the folder strings change, padded inside their old room', () {
    final original = _project();
    final result = writer.write(original, {_kick: r'E:\Audio\kick.wav'});
    final slots = CubaseProjectParser(original)
        .readPoolPaths()
        .where((f) => f.name.text == 'kick.wav')
        .map((f) => f.folder)
        .toList();
    for (var i = 0; i < original.length; i++) {
      if (original[i] == result.bytes[i]) continue;
      expect(
          slots.any((s) => i >= s.offset + 4 && i < s.offset + 4 + s.length),
          isTrue,
          reason: 'byte $i is outside the kick\'s folder strings');
    }
    // The string keeps its length and still ends NUL + BOM, as Cubase
    // writes it.
    final slot = slots.first;
    final end = slot.offset + 4 + slot.length;
    expect(result.bytes.sublist(end - 4, end), [0, 0xEF, 0xBB, 0xBF]);
  });

  test('the same length fits: a drive letter that changed', () {
    final result = writer.write(
        _project(), {_kick: _kick.replaceFirst('D:', 'H:')});
    expect(result.relinked, {_kick});
    expect(_paths(result.bytes).first, startsWith(r'H:\MusicProduction'));
  });

  test('a longer folder is refused, and nothing is written', () {
    final original = _project();
    final result = writer.write(original, {
      _kick: r'D:\MusicProduction\Projects\Archive 2024\Song\Audio\kick.wav',
    });
    expect(result.relinked, isEmpty);
    expect(result.refused, {_kick: RelinkRefusal.doesNotFit});
    expect(result.bytes, original);
  });

  test('a new name is written too when it fits; macOS separators kept', () {
    final result =
        writer.write(_project(), {_snare: '/Volumes/S/snr.wav'});
    expect(result.relinked, {_snare});
    expect(_paths(result.bytes).last, '/Volumes/S/snr.wav');
  });

  test('a file the project does not name is refused as not found', () {
    final result = writer.write(_project(), {r'C:\Other\hat.wav': r'E:\h.wav'});
    expect(result.refused, {r'C:\Other\hat.wav': RelinkRefusal.notFound});
  });

  test('stored paths are matched ignoring case', () {
    final result =
        writer.write(_project(), {_kick.toUpperCase(): r'E:\A\kick.wav'});
    expect(result.relinked, {_kick.toUpperCase()});
  });

  test('old Cubase strings take ASCII only: their code page is unknown', () {
    final original = _project(bom: false);
    expect(writer.write(original, {_kick: r'E:\Música\kick.wav'}).refused,
        {_kick: RelinkRefusal.encoding});
    final ascii = writer.write(original, {_kick: r'E:\Audio\kick.wav'});
    expect(ascii.relinked, {_kick});
    expect(_paths(ascii.bytes).first, r'E:\Audio\kick.wav');
  });

  test('the writer for a project is chosen by its extension', () {
    expect(relinkWriterFor('/a/Song.cpr'), isA<CubaseRelinkWriter>());
    expect(relinkWriterFor('/a/Song.NPR'), isA<CubaseRelinkWriter>());
    expect(relinkWriterFor('/a/Song.als'), isNull);
  });
}
