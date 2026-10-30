/// Fake Cubase projects for tests, laid out the way real ones are: see
/// [CubaseArchive]. Shared by the parser's tests and the Inspector's.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Writes a Steinberg object archive the way Cubase does: the first object
/// of a class carries `FF FF FF FF` + name + version + size, every later one
/// a back-reference (`0x80000000 | offset of the definition`) + size.
class CubaseArchive {
  final _defs = <String, int>{};
  final _open = <int>[]; // positions of size placeholders
  final List<int> _bytes = [];

  int get _pos => _bytes.length;

  void _u32(int v) => _bytes.addAll([
    (v >> 24) & 255,
    (v >> 16) & 255,
    (v >> 8) & 255,
    v & 255,
  ]);
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

  /// Strings before Cubase 6: the text and a NUL, in the system's code page.
  void legacyString(String s) {
    final data = [...latin1.encode(s), 0];
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
  /// (f64), a `String`, a `Map` (folder), a `List<Map>` (list) or an [CubaseObject].
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
      case final CubaseBlobValue blob:
        _u16(2);
        _u16(7);
        _u32(blob.bytes.length);
        raw(blob.bytes);
      case final CubaseStrings list:
        _u16(2);
        _u16(4);
        _u32(list.items.length);
        list.items.forEach(string);
      case final CubaseObject o:
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
  /// side-chain input bus. [strip] is the channel strip's slots in the
  /// order stored, each its SlotType and module plug-in (null: empty) —
  /// by default Cubase's own order with only the EQ, as nearly every real
  /// channel has it; [stripOff] deactivates modules by name, and
  /// [stripSideChains] gives one a side-chain bus.
  void channel({
    required int ownBus,
    required int outBus,
    String ownName = 'Audio 1',
    int type = 1,
    Map<int, (String, bool)> inserts = const {},
    Map<int, int> sideChains = const {},
    List<(int, int, double, bool, bool)> sends = const [],
    double volume = 25856,
    bool muted = false,
    bool soloed = false,
    int eqBandsOn = 0,
    String? instrument,
    String? instrumentLabel,
    double pan = 0.5,
    List<(int, String?)> strip = const [
      (5, null),
      (6, null),
      (4, 'EQ'),
      (9, null),
      (8, null),
      (7, null),
    ],
    Set<String> stripOff = const {},
    Map<String, int> stripSideChains = const {},
    bool stripBypassed = false,
    bool stripBeforeInserts = false,
  }) {
    tree('VST Multitrack', {
      'RuntimeID': 1,
      'Name': {'String': ownName},
      'Type': type,
      'InputGain': {'Value': 16383.5},
      'InputPhase': 0,
      'Volume': {'Value': volume, 'AnchorValue': 0.0},
      'Panner': {
        'Plugin Name': 'Standard Panner',
        'audioComponent': cubasePannerState(pan),
        'Active': 1,
      },
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
                  'Sidechain Bus Id 0': ?sideChains[slot],
                },
                'WasEnableBeforeFreeze': 0,
                'State': 1,
                'SlotType': -1,
              }
            else
              {'RuntimeID': 4, 'State': 0, 'SlotType': -1},
        ],
      },
      'hasAudioStrips': 1,
      // The Psyform Stellardrone template's "Synth" channel, trimmed: a
      // loaded slot is its plug-in, then State 1 and its SlotType.
      'StripFolder': {
        'RuntimeID': 5,
        'Bypass': stripBypassed ? 1 : 0,
        'SeparationPosition': 6,
        'Slot': <Map<String, Object>>[
          for (final (type, name) in strip)
            if (name != null)
              {
                'RuntimeID': 6,
                'Plugin isA': type == 4 ? 'VstCtrlEQ' : 'VstCtrlInternalEffect',
                'Plugin': {
                  'Plugin UID': {'GUID': 'ID-$name'},
                  'Plugin Name': name,
                  'Sidechain Bus Id 0': ?stripSideChains[name],
                  'Active': stripOff.contains(name) ? 0 : 1,
                  'Bay Program': '',
                },
                'WasEnableBeforeFreeze': 0,
                'State': 1,
                'SlotType': type,
              }
            else
              {'RuntimeID': 7, 'State': 0, 'SlotType': type},
        ],
        'SummingMode': 1,
      },
      'ChannelStripsPreInserts': stripBeforeInserts ? 1 : 0,
      if (instrument != null)
        'Synth Slot': {
          'Plugin isA': 'VstCtrlInstrument',
          // A renamed instrument keeps the user's label as its name and the
          // plug-in's own as the original.
          'Plugin': {
            'Plugin UID': {'GUID': '565354$instrument'},
            'Plugin Name': instrumentLabel ?? instrument,
            if (instrumentLabel != null) 'Original Plugin Name': instrument,
            'Bay Program': 'Init Saw',
            'Active': 1,
          },
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
            switch ([
              for (final s in sends)
                if (s.$1 == slot) s,
            ]) {
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
      // Cubase calls mute "SoloFlag".
      if (muted) 'SoloFlag': 1,
      if (soloed) 'Solo': 1,
      'OwnInputBus': {'Name': ownName, 'Bus UID': ownBus, 'Bus Type': 13},
      'OutputBusValue': {'Value': outBus},
      'IDString': 'Audio',
    });
  }

  /// A slot of the VST Instruments rack: its plug-in, then its outputs —
  /// channels of type 3, which the arrangement shows as device tracks.
  void rackSlot(String plugin, List<String> outputs, {bool off = false}) {
    attr('Plugin isA', 'VstCtrlInstrument');
    attr('Plugin', {'Plugin Name': plugin, 'Active': off ? 0 : 1});
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

  void midiPart(
    String name,
    double lengthTicks,
    List<(double, int, int, double)> notes,
  ) {
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
  void legacyMidiPart(
    String name,
    double lengthTicks,
    List<(double, int, int, double)> notes,
  ) {
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
  /// With [folderRoom], the folder is written as a relink in place writes
  /// it: in a string that held a longer one, NUL-padded to that many bytes.
  /// Without [bom], strings are written as Cubase 5 wrote them.
  void poolFile(
    String name,
    String folder, {
    int? folderRoom,
    bool bom = true,
  }) {
    begin('FNPath');
    bom ? string(name) : legacyString(name);
    raw(ascii.encode('WAVE'));
    string('wav');
    string('wav');
    string('Wave File');
    raw([0, 0, 0, 1, 0, 0]);
    if (!bom) {
      legacyString(folder);
    } else if (folderRoom == null) {
      string(folder);
    } else {
      final text = utf8.encode(folder);
      _u32(folderRoom + 4);
      raw([...text, ...List.filled(folderRoom + 1 - text.length, 0)]);
      raw([0xEF, 0xBB, 0xBF]);
    }
    end();
  }

  /// With [version], a `PAppVersion` record saying which Cubase saved it.
  Uint8List toCpr({String? version}) {
    final arch = Uint8List.fromList(_bytes);
    final out = BytesBuilder();
    void u32(int v) =>
        out.add([(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]);
    final rootBody = [...ascii.encode('Arrangement1'), 0];
    final versionText = [
      if (version != null) ...ascii.encode('Version $version'),
      0,
    ];
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

/// A plug-in's state in an attribute tree.
class CubaseBlobValue {
  const CubaseBlobValue(this.bytes);
  final List<int> bytes;
}

/// The Standard Panner's state as Cubase 13 keeps it: the pan as a
/// little-endian float (0.5 the centre), then fields not read.
CubaseBlobValue cubasePannerState(double pan) => CubaseBlobValue([
  ...(ByteData(4)..setFloat32(0, pan, Endian.little)).buffer.asUint8List(),
  0,
  0,
  0,
  0x3F,
  4,
  0,
  0,
  0,
  2,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
]);

/// A string list in an attribute tree ("Connections").
class CubaseStrings {
  const CubaseStrings(this.items);
  final List<String> items;
}

/// An object in an attribute tree: its class and attributes.
class CubaseObject {
  const CubaseObject(this.cls, this.attrs);
  final String cls;
  final Map<String, Object> attrs;
}
