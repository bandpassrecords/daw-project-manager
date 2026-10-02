import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/midi_file_reader.dart';
import 'package:daw_project_manager/services/midi/midi_file_writer.dart';

/// An SMF from raw track bodies, for shapes our own writer never produces.
Uint8List _smf(List<List<int>> tracks, {int format = 1, int division = 96}) {
  final out = BytesBuilder()
    ..add('MThd'.codeUnits)
    ..add([0, 0, 0, 6, 0, format, 0, tracks.length])
    ..add([(division >> 8) & 0xFF, division & 0xFF]);
  for (final t in tracks) {
    out
      ..add('MTrk'.codeUnits)
      ..add([
        (t.length >> 24) & 0xFF,
        (t.length >> 16) & 0xFF,
        (t.length >> 8) & 0xFF,
        t.length & 0xFF,
      ])
      ..add(t);
  }
  return out.toBytes();
}

void main() {
  test('reads back what the writer wrote: notes, events and length', () {
    const clip = MidiClip(
      name: 'Lead',
      ppq: 480,
      lengthTicks: 1920,
      notes: [
        MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: 100),
        MidiNote(
            startTick: 480, lengthTicks: 960, pitch: 64, velocity: 70, channel: 2),
      ],
      events: [
        MidiEvent(tick: 0, kind: MidiEventKind.program, value: 33),
        MidiEvent(tick: 240, kind: MidiEventKind.pitchBend, value: 12288),
        MidiEvent(
            tick: 600, kind: MidiEventKind.controller, number: 1, value: 64),
      ],
    );
    final read = decodeMidiFile(encodeMidiClip(clip, bpm: 128, musicalKey: 'Am'))!;
    expect(read.ppq, 480);
    expect(read.notes, clip.notes);
    expect(read.events, clip.events);
    expect(read.lengthTicks, 1920, reason: 'the end-of-track, rest included');
  });

  test('merges the tracks of a format-1 file, running status included', () {
    final bytes = _smf([
      // Track 0: tempo only.
      [0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20, 0x00, 0xFF, 0x2F, 0x00],
      // Track 1: two notes, the second note-on and both offs as running
      // status (note-on velocity 0 = off).
      [
        0x00, 0x90, 0x3C, 0x64, //
        0x30, 0x3C, 0x00, // off at 48
        0x00, 0x3E, 0x50, // on at 48
        0x30, 0x3E, 0x00, // off at 96
        0x00, 0xFF, 0x2F, 0x00,
      ],
      // Track 2: a sysex and a CC on channel 1.
      [
        0x00, 0xF0, 0x03, 0x7E, 0x7F, 0xF7, //
        0x10, 0xB1, 0x07, 0x50,
        0x50, 0xFF, 0x2F, 0x00,
      ],
    ]);
    final read = decodeMidiFile(bytes)!;
    expect(read.ppq, 96);
    expect(read.notes.map((n) => (n.startTick, n.lengthTicks, n.pitch)), [
      (0, 48, 0x3C),
      (48, 48, 0x3E),
    ]);
    expect(read.events, const [
      MidiEvent(
          tick: 16,
          kind: MidiEventKind.controller,
          number: 7,
          value: 0x50,
          channel: 1),
    ]);
    expect(read.lengthTicks, 96);
  });

  test('a note never released ends with its track', () {
    final read = decodeMidiFile(_smf([
      [0x00, 0x90, 0x40, 0x64, 0x60, 0xFF, 0x2F, 0x00],
    ], format: 0))!;
    expect(read.notes.single.lengthTicks, 0x60);
  });

  test('a truncated track keeps what came before the cut', () {
    final read = decodeMidiFile(_smf([
      [0x00, 0x90, 0x40, 0x64, 0x10, 0x80, 0x40, 0x00, 0x10, 0x90],
    ], format: 0))!;
    expect(read.notes.single.pitch, 0x40);
  });

  test('All Notes Off and friends are not kept as events', () {
    final read = decodeMidiFile(_smf([
      [0x00, 0xB0, 0x7B, 0x00, 0x00, 0xFF, 0x2F, 0x00],
    ], format: 0))!;
    expect(read.events, isEmpty);
  });

  test('not a MIDI file, or SMPTE-timed: null', () {
    expect(decodeMidiFile(Uint8List.fromList('hello there!!!'.codeUnits)), isNull);
    expect(decodeMidiFile(Uint8List(0)), isNull);
    expect(decodeMidiFile(_smf([[]], division: 0xE728)), isNull);
  });

  test('readBytesIfExists: the bytes, or null when there is no file', () {
    final dir = Directory.systemTemp.createTempSync('midi_read_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/a.mid')..writeAsBytesSync([1, 2, 3]);
    expect(readBytesIfExists(file.path), [1, 2, 3]);
    expect(readBytesIfExists('${dir.path}/missing.mid'), isNull);
  });
}
