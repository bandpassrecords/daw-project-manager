import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/midi_file_writer.dart';

/// Just enough of a Standard MIDI File reader to check what the writer wrote.
class _Smf {
  _Smf(Uint8List bytes) : _d = ByteData.sublistView(bytes) {
    expect(ascii.decode(bytes.sublist(0, 4)), 'MThd');
    expect(_d.getUint32(4), 6);
    format = _d.getUint16(8);
    tracks = _d.getUint16(10);
    ppq = _d.getUint16(12);
    expect(ascii.decode(bytes.sublist(14, 18)), 'MTrk');
    final length = _d.getUint32(18);
    expect(bytes.length, 22 + length, reason: 'track length must be exact');
    var pos = 22;
    var tick = 0;
    while (pos < 22 + length) {
      var delta = 0;
      while (true) {
        final b = bytes[pos++];
        delta = (delta << 7) | (b & 0x7F);
        if (b & 0x80 == 0) break;
      }
      tick += delta;
      final status = bytes[pos++];
      if (status == 0xFF) {
        final type = bytes[pos++];
        final len = bytes[pos++];
        meta[type] = bytes.sublist(pos, pos + len);
        if (type == 0x2F) endTick = tick;
        pos += len;
      } else {
        events.add((tick, status, bytes[pos], bytes[pos + 1]));
        pos += 2;
      }
    }
  }

  final ByteData _d;
  late int format, tracks, ppq;
  int? endTick;
  final meta = <int, List<int>>{};
  final events = <(int, int, int, int)>[];
}

MidiClip _clip(List<MidiNote> notes, {int length = 1920, String name = 'Riff'}) =>
    MidiClip(
      name: name,
      trackName: 'Bass',
      ppq: 480,
      lengthTicks: length,
      notes: notes,
    );

void main() {
  test('writes a format-0 file at the clip PPQ with name, tempo and 4/4', () {
    final smf = _Smf(encodeMidiClip(
      _clip(const [MidiNote(startTick: 0, lengthTicks: 240, pitch: 36, velocity: 100)]),
      bpm: 145,
    ));
    expect(smf.format, 0);
    expect(smf.tracks, 1);
    expect(smf.ppq, 480);
    expect(utf8.decode(smf.meta[0x03]!), 'Riff');
    final us = smf.meta[0x51]!;
    expect((us[0] << 16) | (us[1] << 8) | us[2], (60000000 / 145).round());
    expect(smf.meta[0x58], [4, 2, 24, 8]);
  });

  test('omits the tempo when the project has none', () {
    final smf = _Smf(encodeMidiClip(_clip(const [
      MidiNote(startTick: 0, lengthTicks: 1, pitch: 60, velocity: 1),
    ])));
    expect(smf.meta.containsKey(0x51), isFalse);
  });

  test('note on/off pairs land at the right ticks, channel kept', () {
    final smf = _Smf(encodeMidiClip(_clip(const [
      MidiNote(startTick: 0, lengthTicks: 240, pitch: 36, velocity: 100, channel: 9),
      MidiNote(startTick: 480, lengthTicks: 480, pitch: 38, velocity: 64),
    ])));
    expect(smf.events, [
      (0, 0x99, 36, 100),
      (240, 0x89, 36, 0x40),
      (480, 0x90, 38, 64),
      (960, 0x80, 38, 0x40),
    ]);
  });

  test('a repeated note is released before it re-triggers', () {
    final smf = _Smf(encodeMidiClip(_clip(const [
      MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100),
      MidiNote(startTick: 240, lengthTicks: 240, pitch: 60, velocity: 100),
    ])));
    final at240 = smf.events.where((e) => e.$1 == 240).map((e) => e.$2);
    expect(at240, [0x80, 0x90]);
  });

  test('end of track sits at the clip length, keeping a trailing rest', () {
    final smf = _Smf(encodeMidiClip(_clip(const [
      MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100),
    ], length: 1920)));
    expect(smf.endTick, 1920);
  });

  test('long deltas use multi-byte variable-length quantities', () {
    final smf = _Smf(encodeMidiClip(_clip(const [
      MidiNote(startTick: 200000, lengthTicks: 10, pitch: 60, velocity: 100),
    ], length: 300000)));
    expect(smf.events.first.$1, 200000);
    expect(smf.endTick, 300000);
  });

  group('midiClipFileName', () {
    test('is "Track - Clip.mid"', () {
      expect(midiClipFileName(_clip(const [])), 'Bass - Riff.mid');
    });

    test('leaves out a track name the clip already carries', () {
      final c = MidiClip(name: 'Diva 01', trackName: 'Diva 01', ppq: 480, lengthTicks: 1, notes: const []);
      expect(midiClipFileName(c), 'Diva 01.mid');
    });

    test('replaces characters Windows rejects and trailing dots', () {
      final c = MidiClip(name: 'a/b:c*?"<>|.', ppq: 480, lengthTicks: 1, notes: const []);
      expect(midiClipFileName(c), 'a_b_c______.mid');
    });

    test('never produces an empty name', () {
      final c = MidiClip(name: '  ', ppq: 480, lengthTicks: 1, notes: const []);
      expect(midiClipFileName(c), 'MIDI clip.mid');
    });
  });

  test('uniqueFileNames numbers case-insensitive duplicates', () {
    expect(uniqueFileNames(['A.mid', 'a.mid', 'B.mid', 'A.mid']),
        ['A.mid', 'a (2).mid', 'B.mid', 'A (3).mid']);
  });
}
