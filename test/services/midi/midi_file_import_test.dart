import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/midi_file_import.dart';
import 'package:daw_project_manager/services/midi/midi_file_writer.dart';

/// A format-1 file from (track name, events) pairs, events as raw bytes.
Uint8List _format1(List<(String, List<int>)> tracks, {int division = 480}) {
  final out = BytesBuilder()
    ..add('MThd'.codeUnits)
    ..add([0, 0, 0, 6, 0, 1, 0, tracks.length])
    ..add([(division >> 8) & 0xFF, division & 0xFF]);
  for (final (name, events) in tracks) {
    final nameBytes = utf8.encode(name);
    final body = [
      if (name.isNotEmpty) ...[0x00, 0xFF, 0x03, nameBytes.length, ...nameBytes],
      ...events,
      0x00, 0xFF, 0x2F, 0x00,
    ];
    out
      ..add('MTrk'.codeUnits)
      ..add([0, 0, (body.length >> 8) & 0xFF, body.length & 0xFF])
      ..add(body);
  }
  return out.toBytes();
}

List<int> _note(int pitch, {int at = 0, int length = 0x60}) =>
    [at, 0x90, pitch, 0x64, length, 0x80, pitch, 0x00];

void main() {
  test('a one-track file is one clip named after the file, tempo and key kept',
      () {
    final bytes = encodeMidiClip(
      const MidiClip(
        name: 'Lead synth',
        ppq: 480,
        lengthTicks: 1920,
        notes: [
          MidiNote(startTick: 0, lengthTicks: 480, pitch: 64, velocity: 100),
        ],
        events: [
          MidiEvent(tick: 0, kind: MidiEventKind.pitchBend, value: 9000),
        ],
      ),
      bpm: 128,
      musicalKey: 'F# minor',
    );
    final imported = importMidiFile(bytes, r'C:\Loops\Hook idea.mid')!;
    final clip = imported.clips.single;
    expect(clip.name, 'Hook idea');
    expect(clip.trackName, 'Lead synth', reason: 'the file\'s own track name');
    expect(clip.lengthTicks, 1920, reason: 'trailing rest kept');
    expect(clip.notes.single.pitch, 64);
    expect(clip.events.single.value, 9000);
    expect(imported.bpm, closeTo(128, 0.01));
    expect(imported.musicalKey, 'F# minor');
    expect(imported.fileName, r'C:\Loops\Hook idea.mid');
  });

  test('a multi-track file is one clip per track with notes, kept aligned', () {
    final bytes = _format1([
      ('', [0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20]), // tempo track
      ('Bass', _note(36)),
      ('', _note(60, at: 0x40)),
      ('Empty', [0x00, 0xB0, 0x07, 0x64]),
    ]);
    final imported = importMidiFile(bytes, 'Arrangement.mid')!;
    expect(imported.clips.map((c) => (c.name, c.trackName)), [
      ('Bass', 'Arrangement'),
      ('Arrangement 2', 'Arrangement'),
    ]);
    expect(imported.clips.map((c) => c.lengthTicks).toSet().single,
        0x40 + 0x60, reason: 'every part spans the whole file');
    expect(imported.bpm, closeTo(120, 0.01));
    expect(imported.musicalKey, isNull);
  });

  test('a MIDI file with no notes imports nothing; not MIDI is null', () {
    final silent = _format1([('Conductor', [0x00, 0xB0, 0x07, 0x64])]);
    expect(importMidiFile(silent, 'x.mid')!.clips, isEmpty);
    expect(importMidiFile(Uint8List.fromList([1, 2, 3]), 'x.mid'), isNull);
  });

  test('a file named only an extension still gets a name', () {
    final bytes = _format1([('', _note(40))]);
    expect(importMidiFile(bytes, '.mid')!.clips.single.name, '.mid');
    expect(importMidiFile(bytes, 'loop.MIDI')!.clips.single.name, 'loop');
  });
}
