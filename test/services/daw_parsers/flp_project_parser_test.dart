import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/daw_parsers/flp_project_parser.dart';

/// Builds an `.flp`: `FLhd` (format, channels, PPQ) then `FLdt` holding TLV
/// events whose id range sets the payload size.
class _Flp {
  final _events = BytesBuilder();

  void byte(int id, int v) => _events.add([id, v]);

  void word(int id, int v) => _events.add([id, v & 255, (v >> 8) & 255]);

  void data(int id, List<int> payload) {
    _events.addByte(id);
    var len = payload.length;
    do {
      var b = len & 0x7F;
      len >>= 7;
      if (len > 0) b |= 0x80;
      _events.addByte(b);
    } while (len > 0);
    _events.add(payload);
  }

  /// FL 11.5+ text: UTF-16LE, NUL-terminated.
  void text(int id, String s) {
    final out = <int>[];
    for (final unit in '$s\u0000'.codeUnits) {
      out..add(unit & 255)..add(unit >> 8);
    }
    data(id, out);
  }

  void note(List<int> into, {
    required int position,
    required int channel,
    required int length,
    required int key,
    required int velocity,
  }) {
    final d = ByteData(24)
      ..setUint32(0, position, Endian.little)
      ..setUint16(6, channel, Endian.little)
      ..setUint32(8, length, Endian.little)
      ..setUint16(12, key, Endian.little)
      ..setUint8(21, velocity);
    into.addAll(d.buffer.asUint8List());
  }

  Uint8List build({int ppq = 96}) {
    final body = _events.toBytes();
    final header = ByteData(14)
      ..setUint32(4, 6, Endian.little)
      ..setUint16(8, 0, Endian.little)
      ..setUint16(10, 3, Endian.little)
      ..setUint16(12, ppq, Endian.little);
    final h = header.buffer.asUint8List()..setAll(0, ascii.encode('FLhd'));
    final len = ByteData(4)..setUint32(0, body.length, Endian.little);
    return (BytesBuilder()
          ..add(h)
          ..add(ascii.encode('FLdt'))
          ..add(len.buffer.asUint8List())
          ..add(body))
        .toBytes();
  }
}

Uint8List _project() {
  final f = _Flp();
  f.data(199, ascii.encode('21.2.3.4004\u0000'));
  // Channel 0: a wrapped VST — internal name "Fruity Wrapper".
  f.word(64, 0);
  f.byte(21, 2);
  f.text(201, 'Fruity Wrapper');
  f.text(203, 'Serum');
  // Channel 1: a sampler, no plug-in.
  f.word(64, 1);
  f.byte(21, 0);
  f.text(203, 'Kick');
  // Channel 2: an audio clip.
  f.word(64, 2);
  f.byte(21, 4);
  // A native mixer effect, named by its internal name.
  f.text(201, 'Fruity Limiter');
  f.text(203, 'Master limiter');
  // Pattern 1: notes for two channels.
  f.word(65, 1);
  f.text(193, 'Intro beat');
  final notes = <int>[];
  f.note(notes, position: 0, channel: 1, length: 24, key: 60, velocity: 100);
  f.note(notes, position: 96, channel: 1, length: 24, key: 60, velocity: 100);
  f.note(notes, position: 0, channel: 0, length: 192, key: 48, velocity: 90);
  f.data(224, notes);
  return f.build();
}

void main() {
  final parser = FlpProjectParser(_project());

  group('readStats', () {
    test('counts channels by type', () {
      final stats = parser.readStats();
      expect(stats.instrumentTracks, 1);
      expect(stats.samplerTracks, 1);
      expect(stats.audioTracks, 1);
    });

    test('names wrapped plug-ins by display name, native ones by internal name',
        () {
      expect(parser.readStats().plugins, ['Fruity Limiter', 'Serum']);
    });

    test('counts one clip per pattern per channel', () {
      expect(parser.readStats().midiClipCount, 2);
    });
  });

  group('readMidiClips', () {
    test('splits a pattern by channel and names each after its channel', () {
      final clips = parser.readMidiClips();
      final kick = clips.firstWhere((c) => c.trackName == 'Kick');
      expect(kick.name, 'Intro beat');
      expect(kick.ppq, 96);
      expect(kick.notes.map((n) => (n.startTick, n.pitch)), [(0, 60), (96, 60)]);
      expect(kick.lengthTicks, 384, reason: 'rounded up to a whole 4/4 bar');

      final serum = clips.firstWhere((c) => c.trackName == 'Serum');
      expect(serum.notes.single.velocity, 90);
    });
  });

  test('a file that is not an FLP reads as empty, not as an error', () {
    final p = FlpProjectParser(Uint8List.fromList(utf8.encode('RIFF....')));
    expect(p.readStats().totalTracks, 0);
    expect(p.readMidiClips(), isEmpty);
  });
}
