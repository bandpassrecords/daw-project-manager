import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';

/// Writes a Steinberg object archive the way Cubase does: the first object
/// of a class carries `FF FF FF FF` + name + version + size, every later one
/// a back-reference (`0x80000000 | offset of the definition`) + size.
class _Archive {
  final _defs = <String, int>{};
  final _open = <int>[]; // positions of size placeholders
  final List<int> _bytes = [];

  int get _pos => _bytes.length;

  void _u32(int v) => _bytes.addAll([(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]);
  void _u16(int v) => _bytes.addAll([(v >> 8) & 255, v & 255]);
  void raw(List<int> data) => _bytes.addAll(data);
  void zeros(int n) => _bytes.addAll(List.filled(n, 0));

  void f64(double v) {
    final d = ByteData(8)..setFloat64(0, v);
    raw(d.buffer.asUint8List());
  }

  /// Cubase 13 strings: length counts the NUL and a trailing UTF-8 BOM.
  void string(String s) {
    final data = [...utf8.encode(s), 0, 0xEF, 0xBB, 0xBF];
    _u32(data.length);
    raw(data);
  }

  void begin(String cls, {int version = 0}) {
    final def = _defs[cls];
    if (def == null) {
      _defs[cls] = _pos;
      _u32(0xFFFFFFFF);
      final name = [...ascii.encode(cls), 0];
      _u32(name.length);
      raw(name);
      _u16(version);
    } else {
      _u32(0x80000000 | def);
    }
    _open.add(_pos);
    _u32(0); // size, patched by end()
  }

  void end() {
    final sizePos = _open.removeLast();
    final size = _pos - sizePos - 4;
    _bytes[sizePos] = (size >> 24) & 255;
    _bytes[sizePos + 1] = (size >> 16) & 255;
    _bytes[sizePos + 2] = (size >> 8) & 255;
    _bytes[sizePos + 3] = size & 255;
  }

  /// A track object: 26 bytes of position/flags, then a node holding the name.
  void track(String cls, String name, [void Function()? contents]) {
    begin(cls);
    zeros(26);
    begin('MListNode');
    string(name);
    contents?.call();
    end();
    end();
  }

  void key(String k) {
    _u32(k.length + 1);
    raw([...ascii.encode(k), 0]);
  }

  void intValue(int v) {
    _u16(1);
    raw((ByteData(8)..setInt64(0, v)).buffer.asUint8List());
  }

  void stringValue(String s) {
    _u16(8);
    string(s);
  }

  /// A mixer channel as Cubase writes it inside a track: the bus it owns
  /// (what other channels' outputs name), its insert slots, and its output.
  /// [inserts] maps a slot to (plug-in, bypassed); other slots are empty.
  void channel({
    required int ownBus,
    required int outBus,
    String ownName = 'Audio 1',
    Map<int, (String, bool)> inserts = const {},
  }) {
    key('VST Multitrack');
    key('OwnInputBus');
    key('Name');
    stringValue(ownName);
    key('Bus UID');
    intValue(ownBus);
    key('InsertFolder');
    for (var slot = 0; slot < 16; slot++) {
      final insert = inserts[slot];
      key('State');
      intValue(insert != null && insert.$2 ? 0 : 1);
      key('SlotType');
      intValue(-1);
      if (insert != null) {
        key('Plugin Name');
        stringValue(insert.$1);
      }
    }
    key('hasAudioStrips');
    key('OutputBusValue');
    key('Value');
    intValue(outBus);
  }

  void plugin(String name, {String? original}) {
    _u32(12);
    raw([...ascii.encode('Plugin Name'), 0]);
    _u16(8);
    string(name);
    if (original != null) {
      _u32(21);
      raw([...ascii.encode('Original Plugin Name'), 0]);
      _u16(8);
      string(original);
    }
  }

  void midiPart(String name, double lengthTicks, List<(double, int, int, double)> notes) {
    begin('MMidiPartEvent', version: 2);
    zeros(2);
    f64(0); // start on the timeline
    f64(lengthTicks);
    begin('MMidiPart', version: 2);
    string(name);
    zeros(9);
    for (final (start, pitch, velocity, length) in notes) {
      raw([0x40, 0x90]);
      f64(start);
      raw([0, pitch, velocity, 0, 0, 0, 0, 0, 2]);
      raw([...ascii.encode('GLFX'), 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]);
      raw([...ascii.encode('VffO'), 0, 4, 0x3F, 0xE0, 0, 0, 0, 0, 0, 0]);
      f64(length);
      f64(0);
      f64(0);
    }
    end();
    end();
  }

  Uint8List toCpr() {
    final arch = Uint8List.fromList(_bytes);
    final out = BytesBuilder();
    void u32(int v) => out.add([(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]);
    final rootBody = [...ascii.encode('Arrangement1'), 0];
    out.add(ascii.encode('RIFF'));
    u32(4 + 8 + rootBody.length + 8 + arch.length);
    out.add(ascii.encode('NUND'));
    out.add(ascii.encode('ROOT'));
    u32(rootBody.length);
    out.add(rootBody);
    out.add(ascii.encode('ARCH'));
    u32(arch.length);
    out.add(arch);
    return out.toBytes();
  }
}

Uint8List _project() {
  final a = _Archive();
  a.begin('MTrackList');
  // Cubase's hidden output folder: its device track is an output, not a group.
  a.track('MFolderTrack', 'Input/Output Channels', () {
    a.track('MDeviceTrackEvent', 'Stereo Out', () {
      a.channel(ownBus: 1, outBus: 0, ownName: 'Stereo Out');
    });
  });
  a.track('MAudioTrackEvent', 'Vocals', () {
    a.channel(ownBus: 10, outBus: 1, inserts: {
      0: ('Pro-Q 3', false),
      2: ('LFOTool_x64', true),
    });
  });
  a.track('MAudioTrackEvent', 'Guitar', () {
    a.channel(ownBus: 11, outBus: 20);
  });
  a.track('MFolderTrack', 'Synths', () {
    a.track('MInstrumentTrackEvent', 'Serum 01', () {
      a.channel(ownBus: 12, outBus: 20);
      a.plugin('Bass Serum', original: 'Serum');
      a.midiPart('Bassline', 1920, [
        (-960, 30, 90, 120), // trimmed away before the part start
        (0, 36, 100, 240),
        (480, 38, 0, 240), // velocity 0 must not become a note-off
        (1800, 40, 80, 480), // runs past the end: shortened to 120
      ]);
      // A copy of the same part elsewhere on the track.
      a.midiPart('Bassline', 1920, [
        (0, 36, 100, 240),
        (480, 38, 0, 240),
        (1800, 40, 80, 480),
      ]);
    });
    a.track('MMidiTrackEvent', 'MIDI 01');
  });
  a.track('MSamplerTrackEvent', 'Kick sample', () {
    a.plugin('Kick sample', original: 'Sampler Track');
  });
  a.track('MDeviceTrackEvent', 'Drum Group', () {
    a.channel(ownBus: 20, outBus: 1);
    a.plugin('Standard Panner');
    a.plugin('Pro-Q 3');
    a.plugin('LFOTool_x64');
  });
  a.end();
  return a.toCpr();
}

void main() {
  late CubaseProjectParser parser;

  setUp(() => parser = CubaseProjectParser(_project()));

  test('recognises the RIFF/NUND container and nothing else', () {
    expect(parser.isCubaseFile, isTrue);
    expect(CubaseProjectParser(Uint8List.fromList(utf8.encode('not a cpr at all')))
        .isCubaseFile, isFalse);
  });

  group('readStats', () {
    test('counts every track kind, following back-references', () {
      // Two audio tracks: the second is written as a reference, not a name —
      // counting class names alone would find one.
      final stats = parser.readStats();
      expect(stats.audioTracks, 2);
      expect(stats.instrumentTracks, 1);
      expect(stats.midiTracks, 1);
      expect(stats.samplerTracks, 1);
    });

    test('the output folder and its outputs are not counted as user tracks',
        () {
      final stats = parser.readStats();
      expect(stats.folderTracks, 1, reason: 'only "Synths"');
      expect(stats.busTracks, 1, reason: 'only "Drum Group", not Stereo Out');
    });

    test('lists real plug-ins, by their original name when renamed', () {
      expect(parser.readStats().plugins, ['LFOTool', 'Pro-Q 3', 'Serum']);
    });

    test('counts distinct MIDI clips', () {
      expect(parser.readStats().midiClipCount, 1);
      expect(parser.readStats(countMidiClips: false).midiClipCount, isNull);
    });
  });

  group('readTracks', () {
    test('lists tracks in project order, each with the folder holding it', () {
      final tracks = parser.readTracks();
      expect(
        [for (final t in tracks) (t.name, t.type, t.parent)],
        [
          ('Vocals', CubaseTrackType.audio, null),
          ('Guitar', CubaseTrackType.audio, null),
          ('Synths', CubaseTrackType.folder, null),
          ('Serum 01', CubaseTrackType.instrument, 'Synths'),
          ('MIDI 01', CubaseTrackType.midi, 'Synths'),
          ('Kick sample', CubaseTrackType.sampler, null),
          ('Drum Group', CubaseTrackType.group, null),
        ],
      );
      expect([for (final t in tracks) t.index], [0, 1, 2, 3, 4, 5, 6]);
    });

    test('a track\'s output is the channel that owns the bus it points at', () {
      final out = {for (final t in parser.readTracks()) t.name: t.output};
      expect(out['Vocals'], 'Stereo Out', reason: 'an output device');
      expect(out['Guitar'], 'Drum Group');
      expect(out['Serum 01'], 'Drum Group');
      expect(out['Drum Group'], 'Stereo Out');
      expect(out['MIDI 01'], isNull, reason: 'no channel, nothing to say');
    });

    test('reads inserts by slot, empty slots skipped, with bypass', () {
      final vocals =
          parser.readTracks().firstWhere((t) => t.name == 'Vocals');
      expect(
        [for (final i in vocals.inserts) (i.slot, i.plugin, i.bypassed)],
        [(0, 'Pro-Q 3', false), (2, 'LFOTool_x64', true)],
      );
    });

    test('a folder has no channel; the one inside it is not its own', () {
      final synths =
          parser.readTracks().firstWhere((t) => t.name == 'Synths');
      expect(synths.output, isNull);
      expect(synths.inserts, isEmpty);
    });

    test('leaves out the hidden output folder and its outputs', () {
      final names = parser.readTracks().map((t) => t.name);
      expect(names, isNot(contains('Input/Output Channels')));
      expect(names, isNot(contains('Stereo Out')));
    });

    test('agrees with readStats on how many tracks there are', () {
      expect(parser.readTracks(), hasLength(parser.readStats().totalTracks));
    });
  });

  group('readMidiClips', () {
    test('reads notes trimmed to the part, with the track name', () {
      final clips = parser.readMidiClips();
      expect(clips, hasLength(1));
      final c = clips.single;
      expect(c.name, 'Bassline');
      expect(c.trackName, 'Serum 01');
      expect(c.ppq, 480);
      expect(c.lengthTicks, 1920);
      expect(c.occurrences, 2, reason: 'the copy collapses into one entry');
      expect(c.notes, const [
        MidiNote(startTick: 0, lengthTicks: 240, pitch: 36, velocity: 100),
        MidiNote(startTick: 480, lengthTicks: 240, pitch: 38, velocity: 1),
        MidiNote(startTick: 1800, lengthTicks: 120, pitch: 40, velocity: 80),
      ]);
    });
  });

  test('garbage after the header is survived, not thrown on', () {
    final bytes = BytesBuilder()
      ..add(ascii.encode('RIFF'))
      ..add([0, 0, 0, 40])
      ..add(ascii.encode('NUND'))
      ..add(ascii.encode('ARCH'))
      ..add([0, 0, 0, 16])
      ..add(List.filled(16, 0xFF));
    final p = CubaseProjectParser(bytes.toBytes());
    expect(p.readStats().totalTracks, 0);
    expect(p.readMidiClips(), isEmpty);
  });
}
