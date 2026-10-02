import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/midi_clip_service.dart';

const _rpp = '''
<REAPER_PROJECT 0.1 "7.0/win64" 0
  TEMPO 120 4 4
  <TRACK
    NAME "Bass"
    <ITEM
      LENGTH 1
      NAME "Line"
      <SOURCE MIDI
        HASDATA 1 960 QN
        E 0 90 24 64
        E 480 80 24 00
        E 1440 b0 7b 00
      >
    >
  >
>
''';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('midi_clip_service_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('supports the formats it has a clip reader for', () {
    for (final ext in ['.cpr', '.npr', '.als', '.alp', '.rpp', '.flp', '.RPP']) {
      expect(MidiClipService.supports('/x/song$ext'), isTrue, reason: ext);
    }
    for (final ext in ['.song', '.bwproject', '.logicx', '.ptx']) {
      expect(MidiClipService.supports('/x/song$ext'), isFalse, reason: ext);
    }
  });

  test('reads clips from a project file by its extension', () async {
    final file = File(p.join(tempDir.path, 'song.rpp'))..writeAsStringSync(_rpp);
    final clips = await MidiClipService.readClips(file.path);
    expect(clips.single.name, 'Line');
    expect(clips.single.notes.single.pitch, 0x24);
  });

  test('a missing file reads as no clips rather than throwing', () {
    expect(MidiClipService.readClipsSync(p.join(tempDir.path, 'gone.cpr')),
        isEmpty);
  });

  test('a file that is not really a Cubase project reads as no clips', () {
    final file = File(p.join(tempDir.path, 'fake.cpr'))
      ..writeAsStringSync('hello');
    expect(MidiClipService.readClipsSync(file.path), isEmpty);
  });

  test('exportAll writes one file per clip with unique names', () async {
    const clip = MidiClip(
      name: 'Riff',
      trackName: 'Synth',
      ppq: 480,
      lengthTicks: 480,
      notes: [MidiNote(startTick: 0, lengthTicks: 10, pitch: 60, velocity: 100)],
    );
    final out = Directory(p.join(tempDir.path, 'export'));
    final written = await MidiClipService.exportAll(
      [clip, clip.copyWith(), clip],
      out,
      bpm: 128,
    );
    expect(written.map((f) => p.basename(f.path)),
        ['Synth - Riff.mid', 'Synth - Riff (2).mid', 'Synth - Riff (3).mid']);
    for (final f in written) {
      expect(f.readAsBytesSync().sublist(0, 4), 'MThd'.codeUnits);
    }
  });

  test('renderPreview writes a WAV once and reuses it for the same clip',
      () async {
    const clip = MidiClip(
      name: 'Riff',
      ppq: 480,
      lengthTicks: 480,
      notes: [MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100)],
    );
    final first = await MidiClipService.renderPreview(clip,
        bpm: 120, directory: tempDir);
    final stamp = File(first).lastModifiedSync();
    final second = await MidiClipService.renderPreview(clip,
        bpm: 120, directory: tempDir);
    expect(second, first);
    expect(File(second).lastModifiedSync(), stamp);

    final faster = await MidiClipService.renderPreview(clip,
        bpm: 140, directory: tempDir);
    expect(faster, isNot(first), reason: 'tempo is part of the cache key');
  });
}
