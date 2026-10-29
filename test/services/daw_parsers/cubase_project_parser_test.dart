import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/sample_reference.dart';
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

  // --- attribute trees (see CubaseAttributeDecoder) ----------------------

  /// One attribute: its key, then its value — an `int` (i64), a `double`
  /// (f64), a `String`, a `Map` (folder), a `List<Map>` (list) or an [_Obj].
  void attr(String k, Object v) {
    key(k);
    value(v);
  }

  void value(Object v) {
    switch (v) {
      case final int i:
        intValue(i);
      case final double d:
        _u16(4);
        f64(d);
      case final String text:
        stringValue(text);
      case final _Obj o:
        _u16(2);
        _u16(0x14);
        string(o.cls);
        zeros(8);
        _u32(o.attrs.length);
        o.attrs.forEach(attr);
      case final Map<String, Object> folder:
        _u16(2);
        _u16(6);
        _u32(folder.length);
        folder.forEach(attr);
      case final List<Map<String, Object>> items:
        _u16(2);
        _u16(5);
        _u32(items.length);
        for (final item in items) {
          _u32(item.length);
          item.forEach(attr);
        }
      default:
        throw ArgumentError(v);
    }
  }

  /// A tree's root as Cubase writes one: key, eight bytes, count, attributes.
  void tree(String rootKey, Map<String, Object> attrs) {
    key(rootKey);
    raw([0, 0, 0, 4, 0xFF, 0xFE, 0xA4, 0xC8]);
    _u32(attrs.length);
    attrs.forEach(attr);
  }

  /// A mixer channel as Cubase writes it inside a track — the layout of a
  /// real Cubase 13 channel, trimmed. [type] is the channel's kind (1 audio,
  /// 2 group, 4 instrument track, 6 FX). [inserts] maps a slot to (plug-in,
  /// deactivated); other slots are empty, as Cubase writes them: a plug-in
  /// slot is its plug-in, *then* its State and SlotType. [sends] are (slot,
  /// bus, level, on, pre-fader); [sideChains] gives a slot's plug-in a
  /// side-chain input bus.
  void channel({
    required int ownBus,
    required int outBus,
    String ownName = 'Audio 1',
    int type = 1,
    Map<int, (String, bool)> inserts = const {},
    Map<int, int> sideChains = const {},
    List<(int, int, double, bool, bool)> sends = const [],
    double volume = 25856,
    bool soloed = false,
    int eqBandsOn = 0,
    String? instrument,
  }) {
    tree('VST Multitrack', {
      'RuntimeID': 1,
      'Name': {'String': ownName},
      'Type': type,
      'InputGain': {'Value': 16383.5},
      'InputPhase': 0,
      'Volume': {'Value': volume, 'AnchorValue': 0.0},
      'InsertFolder': {
        'RuntimeID': 2,
        'Bypass': 0,
        'Slot': <Map<String, Object>>[
          for (var slot = 0; slot < 16; slot++)
            if (inserts[slot] case (final name, final off))
              {
                'RuntimeID': 3,
                'Plugin isA': 'VstCtrlInternalEffect',
                'Plugin': {
                  'Plugin UID': {'GUID': 'ID-$name'},
                  'Plugin Name': name,
                  'Active': off ? 0 : 1,
                  if (sideChains[slot] case final bus?)
                    'Sidechain Bus Id 0': bus,
                },
                'WasEnableBeforeFreeze': 0,
                'State': 1,
                'SlotType': -1,
              }
            else
              {'RuntimeID': 4, 'State': 0, 'SlotType': -1},
        ],
      },
      if (instrument != null)
        'Synth Slot': {
          'Plugin isA': 'VstCtrlInstrument',
          'Plugin': {'Plugin Name': instrument},
          'State': 1,
        },
      'EQ': {
        'Bypass': 0,
        'Band': <Map<String, Object>>[
          for (var i = 0; i < 4; i++)
            {'Enable': i < eqBandsOn ? 1 : 0, 'Gain': 0.0, 'Freq': 100.0},
        ],
      },
      'SendFolder': {
        'Slot': <Map<String, Object>>[
          for (var slot = 0; slot < 8; slot++)
            switch ([for (final s in sends) if (s.$1 == slot) s]) {
              [(_, final bus, final level, final on, final pre)] => {
                  if (on) 'On': 1,
                  if (pre) 'Pre': 1,
                  'Volume': {'Value': level},
                  'Output': {'Value': bus},
                },
              _ => {
                  'Volume': {'Value': 25856.0},
                  'Output': {'Value': 0},
                  'OldOn': 0,
                },
            },
        ],
      },
      if (soloed) 'SoloFlag': 1,
      'OwnInputBus': {'Name': ownName, 'Bus UID': ownBus, 'Bus Type': 13},
      'OutputBusValue': {'Value': outBus},
      'IDString': 'Audio',
    });
  }

  /// A slot of the VST Instruments rack: its plug-in, then its outputs —
  /// channels of type 3, which the arrangement shows as device tracks.
  void rackSlot(String plugin, List<String> outputs) {
    attr('Plugin isA', 'VstCtrlInstrument');
    attr('Plugin', {'Plugin Name': plugin});
    attr('Output Channels', <Map<String, Object>>[
      for (final (i, name) in outputs.indexed)
        {
          'Output Index': i,
          'Output Channel': {
            'Name': {'String': name},
            'Type': 3,
            'Volume': {'Value': 25856.0},
          },
        },
    ]);
  }

  /// One of the project's media attributes: its ID, then Type, Flags and
  /// the value under a key naming its type ("Float", "Long", "Object").
  void mediaAttribute(String id, String valueKey, Object v) {
    key('ID');
    // Written with no BOM, unlike most Cubase 13 strings.
    _u16(8);
    key(id);
    attr('Type', 4);
    attr('Flags', 2);
    attr(valueKey, v);
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

  /// A part as Cubase SX, 4 and 5 write one: 43-byte notes — status, start,
  /// channel, pitch, velocity, flags (2), four zeros, no attributes, the
  /// length, 16 zeros and the note-off velocity.
  void legacyMidiPart(String name, double lengthTicks, List<(double, int, int, double)> notes) {
    begin('MMidiPartEvent', version: 2);
    zeros(2);
    f64(0);
    f64(lengthTicks);
    begin('MMidiPart', version: 2);
    string(name);
    zeros(9);
    for (final (start, pitch, velocity, length) in notes) {
      raw([0x90]);
      f64(start);
      raw([0, pitch, velocity, 2, 0, 0, 0, 0, 0]);
      f64(length);
      zeros(16);
      raw([0x40]);
    }
    end();
    end();
  }

  /// A pool file as Cubase writes it: an `FNPath` holding the name, the
  /// type ("WAVE", the extension twice, a description) and the folder.
  void poolFile(String name, String folder) {
    begin('FNPath');
    string(name);
    raw(ascii.encode('WAVE'));
    string('wav');
    string('wav');
    string('Wave File');
    raw([0, 0, 0, 1, 0, 0]);
    string(folder);
    end();
  }

  /// With [version], a `PAppVersion` record saying which Cubase saved it.
  Uint8List toCpr({String? version}) {
    final arch = Uint8List.fromList(_bytes);
    final out = BytesBuilder();
    void u32(int v) => out.add([(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]);
    final rootBody = [...ascii.encode('Arrangement1'), 0];
    final versionText = [if (version != null) ...ascii.encode('Version $version'), 0];
    final versionChunk = [
      if (version != null) ...[
        ...ascii.encode('ROOT'),
        ...[0, 0, 0, 4 + versionText.length],
        ...[0, 0, 0, versionText.length],
        ...versionText,
      ],
    ];
    out.add(ascii.encode('RIFF'));
    u32(4 + 8 + rootBody.length + 8 + arch.length + versionChunk.length);
    out.add(ascii.encode('NUND'));
    out.add(ascii.encode('ROOT'));
    u32(rootBody.length);
    out.add(rootBody);
    out.add(ascii.encode('ARCH'));
    u32(arch.length);
    out.add(arch);
    out.add(versionChunk);
    return out.toBytes();
  }
}

Uint8List _project() {
  final a = _Archive();
  a.begin('MTrackList');
  // The VST Instruments rack, as Cubase 13 shows it: a folder per
  // instrument, device tracks for its outputs, no channel inside them. It
  // comes first, and must not be taken for the I/O folder.
  a.track('MFolderTrack', 'VST Instruments', () {
    a.track('MFolderTrack', 'HALion Sonic', () {
      a.track('MDeviceTrackEvent', 'HALion Sonic');
      a.track('MDeviceTrackEvent', 'HSSE Main');
    });
  });
  // Cubase's hidden output folder: its device track is an output, not a group.
  a.track('MFolderTrack', 'Input/Output Channels', () {
    a.track('MDeviceTrackEvent', 'Stereo Out', () {
      a.channel(ownBus: 1, outBus: 0, ownName: 'Stereo Out');
    });
  });
  a.track('MAudioTrackEvent', 'Vocals', () {
    a.channel(
      ownBus: 10,
      outBus: 1,
      inserts: {
        0: ('Pro-Q 3', false),
        2: ('LFOTool_x64', true),
      },
      sends: [
        (0, 30, 15000, true, false), // to the reverb
        (1, 40, 25856, true, true), // into Guitar's compressor side-chain
        (3, 30, 12000, false, false), // routed but switched off
      ],
    );
  });
  a.track('MAudioTrackEvent', 'Guitar', () {
    a.channel(
      ownBus: 11,
      outBus: 20,
      inserts: {0: ('Compressor', false)},
      sideChains: {0: 40},
      volume: 20000,
      soloed: true,
      eqBandsOn: 2,
    );
  });
  a.track('MFolderTrack', 'Synths', () {
    a.track('MInstrumentTrackEvent', 'Serum 01', () {
      a.channel(ownBus: 12, outBus: 20, type: 4, instrument: 'Serum');
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
    a.channel(ownBus: 20, outBus: 1, type: 2, ownName: 'Drum Group');
    a.plugin('Standard Panner');
    a.plugin('Pro-Q 3');
    a.plugin('LFOTool_x64');
  });
  a.track('MDeviceTrackEvent', 'Reverb', () {
    a.channel(ownBus: 30, outBus: 1, type: 6, ownName: 'Reverb');
  });
  a.end();
  a.begin('PVSTInstrumentRack');
  a.rackSlot('HALion Sonic', ['HSSE Main']);
  a.end();
  a.begin('StMedia::PAttributes');
  a.mediaAttribute('AudioSampleRate', 'Float', 48000.0);
  a.mediaAttribute('AudioSampleSize', 'Long', 24);
  a.mediaAttribute(
    'MusicalSignature',
    'Object',
    const _Obj('CmRational', {'Numerator': 3, 'Denominator': 4}),
  );
  a.end();
  return a.toCpr();
}

/// An object in an attribute tree: its class and attributes.
class _Obj {
  const _Obj(this.cls, this.attrs);
  final String cls;
  final Map<String, Object> attrs;
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
      expect(stats.folderTracks, 1, reason: 'only "Synths", not the rack');
      expect(stats.busTracks, 2,
          reason: '"Drum Group" and "Reverb"; not Stereo Out or HSSE Main');
    });

    test('lists real plug-ins, by their original name when renamed', () {
      expect(parser.readStats().plugins,
          ['Compressor', 'HALion Sonic', 'LFOTool', 'Pro-Q 3', 'Serum']);
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
          ('Reverb', CubaseTrackType.fx, null),
        ],
      );
      expect([for (final t in tracks) t.index], [0, 1, 2, 3, 4, 5, 6, 7]);
    });

    test('a track\'s output is the channel that owns the bus it points at', () {
      final out = {for (final t in parser.readTracks()) t.name: t.output};
      expect(out['Vocals'], 'Stereo Out', reason: 'an output device');
      expect(out['Guitar'], 'Drum Group');
      expect(out['Serum 01'], 'Drum Group');
      expect(out['Drum Group'], 'Stereo Out');
      expect(out['MIDI 01'], isNull, reason: 'no channel, nothing to say');
    });

    test('reads inserts by slot, empty slots skipped, deactivated ones marked',
        () {
      // Cubase writes a slot's State and SlotType after its plug-in: read the
      // other way round, slot 0's plug-in was dropped and every plug-in got
      // the slot before's state. Bypass isn't stored readably: null.
      final vocals =
          parser.readTracks().firstWhere((t) => t.name == 'Vocals');
      expect(
        [
          for (final i in vocals.inserts)
            (i.slot, i.plugin, i.pluginId, i.deactivated, i.bypassed),
        ],
        [
          (0, 'Pro-Q 3', 'ID-Pro-Q 3', false, null),
          (2, 'LFOTool_x64', 'ID-LFOTool_x64', true, null),
        ],
      );
    });

    test("a plug-in alone in slot 0 is read", () {
      // Main Lead Group in a real Cubase 13 project had only slot 0 filled,
      // and was read with no inserts at all.
      final guitar =
          parser.readTracks().firstWhere((t) => t.name == 'Guitar');
      expect([for (final i in guitar.inserts) i.plugin], ['Compressor']);
    });

    test('device tracks are groups or FX channels by their channel', () {
      final types = {for (final t in parser.readTracks()) t.name: t.type};
      expect(types['Drum Group'], CubaseTrackType.group);
      expect(types['Reverb'], CubaseTrackType.fx);
    });

    test('the fader, solo and EQ as the channel stores them', () {
      final byName = {for (final t in parser.readTracks()) t.name: t};
      expect(byName['Guitar']!.volume, 20000);
      expect(byName['Guitar']!.soloed, isTrue);
      expect(byName['Guitar']!.eqBandsOn, 2);
      expect(byName['Vocals']!.volume, CubaseProjectParser.unityVolume);
      expect(byName['Vocals']!.soloed, isFalse);
      expect(byName['Vocals']!.phaseInverted, isFalse);
      expect(byName['MIDI 01']!.volume, isNull, reason: 'no channel');
    });

    test('sends: destination, level, on and pre-fader; side-chains named', () {
      final vocals =
          parser.readTracks().firstWhere((t) => t.name == 'Vocals');
      expect(
        [
          for (final s in vocals.sends)
            (s.slot, s.destination, s.sideChainOf, s.level, s.on, s.preFader),
        ],
        [
          (0, 'Reverb', null, 15000, true, false),
          (1, 'Guitar', 'Compressor', 25856, true, true),
          (3, 'Reverb', null, 12000, false, false),
        ],
      );
      final guitar =
          parser.readTracks().firstWhere((t) => t.name == 'Guitar');
      expect(guitar.sends, isEmpty, reason: 'unrouted slots are left out');
    });

    test('an instrument track names its instrument', () {
      final serum =
          parser.readTracks().firstWhere((t) => t.name == 'Serum 01');
      expect(serum.instrument, 'Serum');
    });

    test('the VST Instruments rack is not tracks; its outputs are listed', () {
      final names = parser.readTracks().map((t) => t.name);
      expect(names, isNot(contains('VST Instruments')));
      expect(names, isNot(contains('HALion Sonic')));
      expect(names, isNot(contains('HSSE Main')));
      expect(
        [
          for (final r in parser.readRackInstruments())
            (r.channel, r.plugin, r.volume),
        ],
        [('HSSE Main', 'HALion Sonic', 25856)],
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

  group('readProjectSetup', () {
    test('sample rate, bit depth and time signature from media attributes',
        () {
      final setup = parser.readProjectSetup();
      expect(setup.sampleRate, 48000);
      expect(setup.bitDepth, 24);
      expect(setup.timeSignature, (3, 4));
    });

    test('a project without them says nothing', () {
      final a = _Archive()..begin('MTrackList');
      a.end();
      final setup = CubaseProjectParser(a.toCpr()).readProjectSetup();
      expect(setup.sampleRate, isNull);
      expect(setup.bitDepth, isNull);
      expect(setup.timeSignature, isNull);
    });
  });

  test('volumeDb: the ends of the scale', () {
    expect(CubaseProjectParser.volumeDb(null), isNull);
    expect(CubaseProjectParser.volumeDb(0), double.negativeInfinity);
    expect(CubaseProjectParser.volumeDb(25856), 0);
    expect(CubaseProjectParser.volumeDb(32767), 6);
    // Below the faders read, it keeps falling, without a jump at the join.
    final atFloor = CubaseProjectParser.volumeDb(11770.669921875)!;
    expect(CubaseProjectParser.volumeDb(11770.6)!, closeTo(atFloor, 0.01));
    expect(CubaseProjectParser.volumeDb(5000)!, lessThan(-20));
    expect(CubaseProjectParser.volumeDb(1)!, lessThan(-100));
    // Above 0 dB it keeps rising to +6.
    final above = CubaseProjectParser.volumeDb(29000)!;
    expect(above, greaterThan(0));
    expect(above, lessThan(6));
  });

  group('faders in dB, as Cubase 13 showed them', () {
    // The test collection's Test 2025, opened in Cubase 13: each channel's
    // fader as Cubase displayed it. test-01_db_level.cpr was saved with two
    // channels set to exactly 0 and -2 dB.
    final dir = p.join('test', 'fixtures', 'projects', 'cubase',
        'Test 2025 (Cubase 13)');
    Map<String, double?> faders(String file) => {
          for (final t in CubaseProjectParser(
                  File(p.join(dir, file)).readAsBytesSync())
              .readTracks())
            t.name: CubaseProjectParser.volumeDb(t.volume),
        };

    test('test-01.cpr', () {
      final db = faders('test-01.cpr');
      for (final (name, shown) in [
        ('Kick 2 x64 01', -10.8),
        ('Bassline', -3.15),
        ('Serum 03', -9.56),
        ('Main Lead 01', -12.5),
        ('RTW_145_Drums_15_Tops', -14.1),
      ]) {
        expect(db[name], closeTo(shown, 0.05), reason: name);
      }
    });

    test('test-01_db_level.cpr', () {
      final db = faders('test-01_db_level.cpr');
      expect(db['ANA2 x64 01_db_0'], 0);
      expect(db['ANA2 x64 01_db_-2'], closeTo(-2, 0.05));
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

  group('Cubase SX, 4 and 5', () {
    Uint8List legacy(String version) {
      final a = _Archive();
      a.begin('MTrackList');
      a.track('MMidiTrackEvent', 'Nord rack');
      a.legacyMidiPart('Nord rack', 1920, [(0, 50, 100, 240), (480, 62, 90, 240), (960, 48, 80, 480)]);
      a.end();
      return a.toCpr(version: version);
    }

    test('their notes are read — 51 real projects read none', () {
      final clips = CubaseProjectParser(legacy('5.1.0')).readMidiClips();
      expect(clips.single.notes, const [
        MidiNote(startTick: 0, lengthTicks: 240, pitch: 50, velocity: 100),
        MidiNote(startTick: 480, lengthTicks: 240, pitch: 62, velocity: 90),
        MidiNote(startTick: 960, lengthTicks: 480, pitch: 48, velocity: 80),
      ]);
      expect(CubaseProjectParser(legacy('3.1.1')).readMidiClips().single.notes, hasLength(3));
    });

    test('the same bytes in a newer project are not notes', () {
      expect(CubaseProjectParser(legacy('13.0.41')).readMidiClips(), isEmpty);
    });

    test('appVersion reads the version record, whatever its length', () {
      expect(CubaseProjectParser.appVersion(legacy('5.1.0')), '5.1.0');
      expect(CubaseProjectParser.appVersion(legacy('13.0.41')), '13.0.41');
      expect(CubaseProjectParser.appVersion(_project()), isNull);
    });
  });

  group('plug-ins of older versions', () {
    test('Cubase 4 writes a value with no NUL — its plug-ins still read', () {
      final a = _Archive();
      a.begin('MTrackList');
      for (final name in ['QuadraFuzz', 'GEQ-30']) {
        a.raw([0, 0, 0, 12, ...ascii.encode('Plugin Name'), 0, 0, 8]);
        a.raw([0, 0, 0, name.length, ...ascii.encode(name)]);
        a.raw([0, 0, 0, 18, ...ascii.encode('Audio Input Count'), 0, 0, 1]);
        a.zeros(8);
      }
      a.end();
      expect(CubaseProjectParser(a.toCpr(version: '4.1.3')).readStats().plugins,
          ['GEQ-30', 'QuadraFuzz']);
    });

    test('Cubase SX 3 names them only in its device paths', () {
      // As a real SX 3 project writes them: a CONT string per step.
      void path(_Archive a, List<String> steps) {
        for (final step in steps) {
          a.raw(ascii.encode('CONT'));
          a.string(step);
        }
      }

      final a = _Archive();
      a.begin('MTrackList');
      path(a, ['Device Root', 'VST Mixer', 'VST Instruments', 'Slot', 'Vanguard']);
      path(a, ['Device Root', 'VST Mixer', 'VST Instruments', 'Slot 2', 'Vanguard 2']);
      path(a, ['Device Root', 'VST Mixer', 'Channels', 'Synth', 'Inserts', 'Slot 2', 'Sonalksis TBK Stereo 4']);
      path(a, ['Device Root', 'VST Mixer', 'Channels', 'Synth 2', 'Inserts', 'Slot', 'Sonalksis TBK Stereo 9']);
      path(a, ['Device Root', 'VST Mixer', 'Channels', 'Synth 3', 'Inserts', 'Slot', 'Pro-Q 3']);
      path(a, ['Device Root', 'VST Mixer', 'Channels', 'Audio 1']);
      a.end();
      expect(CubaseProjectParser(a.toCpr(version: '3.1.1')).readStats().plugins,
          ['Pro-Q 3', 'Sonalksis TBK Stereo', 'Vanguard'],
          reason: 'instance numbers dropped where a name comes numbered more than once; '
              'a lone "Pro-Q 3" keeps its 3');
    });
  });

  group('readSampleReferences', () {
    const projectAudio = r'C:\Music\Song\Audio\';
    const library = r'D:\Samples\Re-Twin\RTW_PERCS\';

    CubaseProjectParser parserWithPool() {
      final a = _Archive();
      a.begin('MTrackList');
      a.track('MAudioTrackEvent', 'Vocals', () {
        a.channel(ownBus: 10, outBus: 1);
      });
      a.end();
      a.begin('PPool');
      a.poolFile('RTW_Crash_3.wav', library);
      a.poolFile('gataka_kick.wav', projectAudio);
      a.poolFile('gataka_kick-01.wav', projectAudio);
      a.poolFile('lonely-01.wav', projectAudio);
      a.poolFile('Vocals_03.wav', projectAudio);
      a.poolFile('RTW_Crash_3.wav', library); // listed twice: kept once
      a.end();
      // A sampler plug-in's state, inline in the archive.
      a.raw([0, 0, 0, 0x30, ...ascii.encode(r'E:\Kits\Snare 7.wav'), 0]);
      return CubaseProjectParser(a.toCpr());
    }

    test('reads each pool file with its folder, once', () {
      final refs = parserWithPool().readSampleReferences();
      final pooled = refs.where((r) => r.use == SampleUse.audio).toList();
      expect([for (final r in pooled) r.fileName], [
        'RTW_Crash_3.wav',
        'gataka_kick.wav',
        'gataka_kick-01.wav',
        'lonely-01.wav',
        'Vocals_03.wav',
      ]);
      expect(pooled.first.candidates,
          ['${library}RTW_Crash_3.wav', 'Audio/RTW_Crash_3.wav']);
    });

    test('a take on a track is a recording; "-01" beside its original is '
        'processed', () {
      final refs = {
        for (final r in parserWithPool().readSampleReferences())
          r.fileName: r.kind,
      };
      expect(refs['Vocals_03.wav'], SampleKind.recorded);
      expect(refs['gataka_kick-01.wav'], SampleKind.processed);
      expect(refs['gataka_kick.wav'], isNull);
      expect(refs['lonely-01.wav'], isNull,
          reason: 'no original in the pool: nothing says it was processed');
      expect(refs['RTW_Crash_3.wav'], isNull);
    });

    test('finds sample paths kept in plug-in state', () {
      final plugin = parserWithPool()
          .readSampleReferences()
          .where((r) => r.use == SampleUse.plugin)
          .toList();
      expect(plugin, hasLength(1));
      expect(plugin.single.candidates, [r'E:\Kits\Snare 7.wav']);
    });

    test("the Sampler Track's sample is a sampler sample, never a "
        'processed copy, and listed once', () {
      final a = _Archive();
      a.track('MSamplerTrackEvent', 'kick');
      a.begin('PSamplerTrackAudioClip');
      a.poolFile('bizzare_kick-01.wav', projectAudio);
      a.end();
      a.begin('PPool');
      a.poolFile('bizzare_kick.wav', projectAudio);
      a.poolFile('bizzare_kick-01.wav', projectAudio); // the pool lists it too
      a.end();
      final refs = CubaseProjectParser(a.toCpr()).readSampleReferences();
      final played =
          refs.where((r) => r.fileName == 'bizzare_kick-01.wav').toList();
      expect(played, hasLength(1));
      expect(played.single.use, SampleUse.sampler);
      expect(played.single.kind, isNull,
          reason: 'its original being in the pool does not make it a bounce');
      expect(
        refs.firstWhere((r) => r.fileName == 'bizzare_kick.wav').use,
        SampleUse.audio,
      );
    });

    test('a pool path that is not audio (a preset) is skipped', () {
      final a = _Archive();
      a.poolFile('Bright Ballad Vocal.vstpreset', r'C:\Presets\');
      expect(CubaseProjectParser(a.toCpr()).readSampleReferences(), isEmpty);
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
