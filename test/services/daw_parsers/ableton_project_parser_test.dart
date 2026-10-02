import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/daw_parsers/ableton_project_parser.dart';

String _midiClip({
  required String name,
  required double currentStart,
  required double currentEnd,
  double loopStart = 0,
  double loopEnd = 4,
  double startRelative = 0,
  bool loopOn = false,
  String keyTracks = '',
  String envelopes = '',
}) =>
    '''
<MidiClip Id="0" Time="$currentStart">
  <CurrentStart Value="$currentStart" />
  <CurrentEnd Value="$currentEnd" />
  <Loop>
    <LoopStart Value="$loopStart" />
    <LoopEnd Value="$loopEnd" />
    <StartRelative Value="$startRelative" />
    <LoopOn Value="$loopOn" />
  </Loop>
  <Name Value="$name" />
  <Notes><KeyTracks>$keyTracks</KeyTracks></Notes>
  <Envelopes><Envelopes>$envelopes</Envelopes></Envelopes>
</MidiClip>''';

/// A clip envelope on pointee [id] with (beats, value) [points].
String _envelope(int id, List<(num, num)> points) => '''
<ClipEnvelope Id="0">
  <EnvelopeTarget><PointeeId Value="$id" /></EnvelopeTarget>
  <Automation><Events>
    ${[for (final (t, v) in points) '<FloatEvent Id="0" Time="$t" Value="$v" />'].join()}
  </Events></Automation>
</ClipEnvelope>''';

/// A track's MIDI controller targets, as Live writes all 131 of them: index
/// N gets pointee id 1000 + N.
final _controllers = '<MidiControllers>'
    '${[for (var n = 0; n <= 130; n++) '<ControllerTargets.$n Id="${1000 + n}"><LockEnvelope Value="0" /></ControllerTargets.$n>'].join()}'
    '</MidiControllers>';

String _keyTrack(int key, List<String> events) => '''
<KeyTrack Id="0">
  <Notes>${events.join()}</Notes>
  <MidiKey Value="$key" />
</KeyTrack>''';

String _note(double time, double duration, double velocity,
        {bool enabled = true}) =>
    '<MidiNoteEvent Time="$time" Duration="$duration" Velocity="$velocity" '
    'OffVelocity="64" IsEnabled="$enabled" />';

String _set({required String tracks}) => '''<?xml version="1.0" encoding="UTF-8"?>
<Ableton MajorVersion="5" MinorVersion="12.0_12300" Creator="Ableton Live 12.3">
  <LiveSet>
    <Tracks>$tracks</Tracks>
  </LiveSet>
</Ableton>''';

String _midiTrack(String name,
        {String devices = '', String clips = '', String controllers = ''}) =>
    '''
<MidiTrack Id="1">
  <Name><EffectiveName Value="$name" /><UserName Value="$name" /></Name>
  <DeviceChain>
    <DeviceChain><Devices>$devices</Devices></DeviceChain>
    <MainSequencer><ClipTimeable><ArrangerAutomation><Events>$clips</Events></ArrangerAutomation></ClipTimeable>$controllers</MainSequencer>
  </DeviceChain>
</MidiTrack>''';

const _serum = '''
<PluginDevice Id="0"><PluginDesc>
  <VstPluginInfo Id="0"><PlugName Value="Serum_x64" /></VstPluginInfo>
</PluginDesc></PluginDevice>''';

const _proQ = '''
<PluginDevice Id="1"><PluginDesc>
  <Vst3PluginInfo Id="0">
    <Preset><Vst3Preset><Name Value="" /></Vst3Preset></Preset>
    <Name Value="Pro-Q 3" />
  </Vst3PluginInfo>
</PluginDesc></PluginDevice>''';

AbletonProjectParser _parse(String xml) =>
    AbletonProjectParser(XmlDocument.parse(xml));

void main() {
  group('readStats', () {
    test('counts track kinds; groups and returns are buses', () {
      final stats = _parse(_set(tracks: '''
        <AudioTrack Id="1" /><AudioTrack Id="2" />
        ${_midiTrack('Bass')}
        <GroupTrack Id="4" /><ReturnTrack Id="5" /><ReturnTrack Id="6" />
      ''')).readStats();
      expect(stats.audioTracks, 2);
      expect(stats.midiTracks, 1);
      expect(stats.busTracks, 3);
      expect(stats.folderTracks, 0);
    });

    test('names VST2 by PlugName and VST3 by its own Name, not the preset',
        () {
      final stats = _parse(_set(
        tracks: _midiTrack('Bass', devices: '$_serum$_proQ'),
      )).readStats();
      expect(stats.plugins, ['Pro-Q 3', 'Serum']);
    });

    test('an empty set reads as zero everything, not as a failure', () {
      final stats = _parse(_set(tracks: '')).readStats();
      expect(stats.totalTracks, 0);
      expect(stats.midiClipCount, 0);
    });
  });

  group('readMidiClips', () {
    test('reads notes per key track, in beats converted to ticks', () {
      final clips = _parse(_set(
        tracks: _midiTrack('Bass', clips: _midiClip(
          name: 'Riff',
          currentStart: 16,
          currentEnd: 20,
          keyTracks: _keyTrack(36, [_note(0, 0.5, 100), _note(2, 1, 80.6)]) +
              _keyTrack(43, [_note(1, 0.25, 127)]),
        )),
      )).readMidiClips();

      expect(clips, hasLength(1));
      final c = clips.single;
      expect(c.name, 'Riff');
      expect(c.trackName, 'Bass');
      expect(c.ppq, 960);
      expect(c.lengthTicks, 4 * 960);
      expect([for (final n in c.notes) (n.startTick, n.pitch, n.velocity)], [
        (0, 36, 100),
        (960, 43, 127),
        (1920, 36, 81),
      ]);
    });

    test('skips deactivated notes', () {
      final clips = _parse(_set(
        tracks: _midiTrack('Bass', clips: _midiClip(
          name: 'Riff',
          currentStart: 0,
          currentEnd: 4,
          keyTracks: _keyTrack(36, [
            _note(0, 1, 100),
            _note(1, 1, 100, enabled: false),
          ]),
        )),
      )).readMidiClips();
      expect(clips.single.notes, hasLength(1));
    });

    test('a looped clip repeats its loop for its arrangement length', () {
      // A 1.5-bar loop played for 3 bars: the note comes back at beat 6,
      // which no whole-bar pattern reproduces, so the clip stays unrolled.
      final clips = _parse(_set(
        tracks: _midiTrack('Drums', clips: _midiClip(
          name: 'Beat',
          currentStart: 0,
          currentEnd: 12,
          loopEnd: 6,
          loopOn: true,
          keyTracks: _keyTrack(36, [_note(0, 0.5, 100)]),
        )),
      )).readMidiClips();
      expect(clips.single.lengthTicks, 12 * 960);
      expect(clips.single.notes.map((n) => n.startTick), [0, 6 * 960]);
    });

    test('a looped one-bar pattern comes back as that one bar', () {
      final clips = _parse(_set(
        tracks: _midiTrack('Drums', clips: _midiClip(
          name: 'Beat',
          currentStart: 0,
          currentEnd: 32,
          loopEnd: 4,
          loopOn: true,
          keyTracks: _keyTrack(36, [_note(0, 0.5, 100), _note(2, 0.5, 100)]),
        )),
      )).readMidiClips();
      expect(clips.single.lengthTicks, 4 * 960);
      expect(clips.single.notes.map((n) => n.startTick), [0, 2 * 960]);
    });

    test('plays from LoopStart + StartRelative', () {
      final clips = _parse(_set(
        tracks: _midiTrack('Drums', clips: _midiClip(
          name: 'Beat',
          currentStart: 0,
          currentEnd: 2,
          loopEnd: 8,
          startRelative: 4,
          keyTracks: _keyTrack(36, [_note(1, 0.5, 100), _note(5, 0.5, 90)]),
        )),
      )).readMidiClips();
      final note = clips.single.notes.single;
      expect(note.startTick, 960, reason: 'beat 5 of the source, 1 into the clip');
      expect(note.velocity, 90);
    });

    test('identical clips collapse into one with a use count', () {
      final clip = _midiClip(
        name: 'Kick',
        currentStart: 0,
        currentEnd: 4,
        keyTracks: _keyTrack(36, [_note(0, 1, 100)]),
      );
      final clips = _parse(_set(
        tracks: _midiTrack('Kick', clips: '$clip$clip$clip'),
      )).readMidiClips();
      expect(clips.single.occurrences, 3);
    });
  });

  group('clip envelopes', () {
    MidiClip read(String envelopes, {bool withControllers = true}) {
      final clip = _midiClip(
        name: 'Lead',
        currentStart: 0,
        currentEnd: 4,
        keyTracks: _keyTrack(60, [_note(0, 1, 100)]),
        envelopes: envelopes,
      );
      return _parse(_set(
        tracks: _midiTrack('Lead',
            clips: clip, controllers: withControllers ? _controllers : ''),
      )).readMidiClips().single;
    }

    test('target N is pitch bend, channel pressure, then CC N − 2', () {
      final clip = read([
        _envelope(1000, [(-63072000, 0), (1, 4096)]),
        _envelope(1001, [(-63072000, 0), (2, 90)]),
        _envelope(1003, [(-63072000, 0), (1, 0), (1, 127)]), // CC 1
        _envelope(1066, [(-63072000, 0), (3, 0), (3, 127)]), // CC 64
      ].join());
      expect(
        clip.events.map((e) => (e.tick, e.kind, e.number, e.value)),
        [
          (0, MidiEventKind.pitchBend, 0, 8192),
          (0, MidiEventKind.channelPressure, 0, 0),
          (0, MidiEventKind.controller, 1, 0),
          (0, MidiEventKind.controller, 64, 0),
          (960, MidiEventKind.pitchBend, 0, 12288),
          (960, MidiEventKind.controller, 1, 127),
          (1920, MidiEventKind.channelPressure, 0, 90),
          (2880, MidiEventKind.controller, 64, 127),
        ],
        reason: 'Live\'s start point holds until the first real one; two '
            'points at one time are a step',
      );
    });

    test('envelopes on anything but a MIDI controller are skipped', () {
      // 5000 is a device parameter, not one of the track's controllers;
      // 1127 would be CC 125, a channel-mode message.
      final clip = read([
        _envelope(5000, [(0, 0.5), (1, 0.7)]),
        _envelope(1127, [(0, 127)]),
      ].join());
      expect(clip.events, isEmpty);
    });

    test('without the track\'s controller list nothing can be resolved', () {
      final clip = read(_envelope(1003, [(0, 64)]), withControllers: false);
      expect(clip.events, isEmpty);
    });

    test('envelopeToEvents samples ramps and keeps steps sharp', () {
      final events = AbletonProjectParser.envelopeToEvents(
        [(0, 0), (1, 127), (1, 0)],
        kind: MidiEventKind.controller,
        number: 74,
      );
      final normalized = normalizeMidiEvents(events);
      expect(normalized.first.value, 0);
      expect(normalized.first.tick, 0);
      // Rising every 1/32 beat (30 ticks at 960 PPQ)…
      expect(normalized[1].tick, 30);
      expect(normalized[1].value, closeTo(127 / 32, 1));
      final values = [for (final e in normalized) e.value];
      for (var i = 1; i < values.length - 2; i++) {
        expect(values[i], greaterThan(values[i - 1]));
      }
      // …then the step down at beat 1 is one event, not a ramp.
      expect(normalized.last.tick, 960);
      expect(normalized.last.value, 0);
    });

    test('pitch bend is shifted from Live\'s ±8192 to MIDI\'s 0–16383', () {
      final events = AbletonProjectParser.envelopeToEvents(
        [(0, -8192), (0, 0), (0, 8191)],
        kind: MidiEventKind.pitchBend,
      );
      expect(events.map((e) => e.value), [0, 8192, 16383]);
    });
  });
}
