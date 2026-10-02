import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/daw_parsers/reaper_project_parser.dart';

/// Shaped like a real .rpp: nested chunks, quoted names, base64 plug-in
/// state, and MIDI as tick-delta `E` lines.
const _rpp = '''
<REAPER_PROJECT 0.1 "7.27/win64" 1727000000
  TEMPO 120 4 4
  <TRACK {11111111-0000-0000-0000-000000000000}
    NAME "Keys"
    ISBUS 0 0
    <FXCHAIN
      SHOW 0
      <VST "VSTi: Serum (Xfer Records)" Serum_x64.dll 0 "" 1483109208<56535458> ""
        WFhmcwAAAAAAAAAAAAAAAAA=
      >
      BYPASS 0 0 0
    >
    <ITEM
      POSITION 4
      LENGTH 2
      LOOP 1
      SOFFS 0
      NAME "Chords"
      <SOURCE MIDI
        HASDATA 1 960 QN
        CCINTERP 32
        E 0 90 3c 64
        E 480 80 3c 00
        Em 0 90 3e 64
        E 480 80 3e 00
        E 960 b0 7b 00
      >
    >
  >
  <TRACK
    NAME "Drums"
    ISBUS 1 1
  >
  <TRACK
    NAME 'Kick "808"'
    ISBUS 2 -1
    <FXCHAIN
      <VST "VST3: Pro-Q 3 (FabFilter)" "Pro-Q 3.vst3" 0 "" 1234{ABC} ""
        AAAA
      >
      <JS "Utility/volume" ""
        0 - - -
      >
    >
    <ITEM
      POSITION 0
      LENGTH 1
      NAME kick.wav
      <SOURCE WAVE
        FILE "kick.wav"
      >
    >
  >
  <TRACK
    NAME "Plain MIDI"
    <ITEM
      LENGTH 0.5
      NAME "Hat"
      <SOURCE MIDI
        HASDATA 1 960 QN
        E 0 99 2a 50
        E 240 89 2a 00
        E 240 b0 7b 00
      >
    >
  >
  <TRACK
    NAME "Reverb"
    AUXRECV 0 0 1 0 0 0 0 0 0 -1:U 0 -1 ''
  >
  <MASTERFXLIST
    <AU "AU: Apple: AUPeakLimiter" "Apple: AUPeakLimiter" "" 1635083896<...> ""
      AAAA
    >
  >
>
''';

void main() {
  final parser = ReaperProjectParser(_rpp);

  group('readStats', () {
    test('classifies each track by what it is used for', () {
      final stats = parser.readStats();
      expect(stats.instrumentTracks, 1, reason: 'Keys hosts a VSTi');
      expect(stats.folderTracks, 1, reason: 'Drums is a folder parent');
      expect(stats.audioTracks, 1, reason: 'Kick holds audio');
      expect(stats.midiTracks, 1, reason: 'MIDI items, no instrument');
      expect(stats.busTracks, 1, reason: 'Reverb only receives');
    });

    test('names plug-ins without type prefix or vendor, master FX included',
        () {
      expect(parser.readStats().plugins,
          ['AUPeakLimiter', 'Pro-Q 3', 'Serum', 'volume']);
    });
  });

  group('readMidiClips', () {
    test('turns E lines into notes, skipping muted ones', () {
      final hat = parser.readMidiClips().firstWhere((c) => c.name == 'Hat');
      expect(hat.trackName, 'Plain MIDI');
      expect(hat.ppq, 960);
      final note = hat.notes.single;
      expect(note.pitch, 0x2a);
      expect(note.velocity, 0x50);
      expect(note.channel, 9);
      expect(note.lengthTicks, 240);
    });

    test('a looped item repeats its source for the item length', () {
      // 2 s at 120 BPM is 4 beats; the source (to the final CC) is 2 beats.
      final chords =
          parser.readMidiClips().firstWhere((c) => c.name == 'Chords');
      expect(chords.lengthTicks, 3840);
      expect(chords.notes.map((n) => (n.startTick, n.pitch)), [
        (0, 0x3c),
        (1920, 0x3c),
      ]);
    });

    test('an item without a MIDI source is not a clip', () {
      expect(parser.readMidiClips().map((c) => c.name),
          isNot(contains('kick.wav')));
    });

    test('SOFFS shifts the window into the source', () {
      const rpp = '''
<REAPER_PROJECT 0.1 "7.0/win64" 0
  TEMPO 60 4 4
  <TRACK
    <ITEM
      LENGTH 1
      SOFFS 1
      NAME "Late"
      <SOURCE MIDI
        HASDATA 1 960 QN
        E 0 90 3c 64
        E 480 80 3c 00
        E 480 90 40 64
        E 480 80 40 00
      >
    >
  >
>
''';
      // At 60 BPM one second is one beat, so the item shows beat 2 only.
      final clip = ReaperProjectParser(rpp).readMidiClips().single;
      expect(clip.notes.map((n) => (n.startTick, n.pitch)), [(0, 0x40)]);
    });
  });
}
