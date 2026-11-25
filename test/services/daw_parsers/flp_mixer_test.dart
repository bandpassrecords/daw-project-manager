import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/services/daw_parsers/flp_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/project_anatomy_reader.dart';

/// The channel rack and the mixer as the Inspector reads them (#229), on
/// projects laid out as the real ones in test/fixtures/projects/flstudio/
/// are (FL 7, 8, 10 and 20).
class _Flp {
  _Flp({required this.version});

  /// "20.9.2.2907" or "7.0.0": since FL 11.5, text is UTF-16LE.
  final String version;
  final _events = BytesBuilder();

  bool get _utf16 {
    final m = RegExp(r'^(\d+)\.(\d+)').firstMatch(version)!;
    final major = int.parse(m.group(1)!), minor = int.parse(m.group(2)!);
    return major > 11 || (major == 11 && minor >= 5);
  }

  void byte(int id, int v) => _events.add([id, v & 255]);

  void word(int id, int v) => _events.add([id, v & 255, (v >> 8) & 255]);

  void dword(int id, int v) {
    final d = ByteData(4)..setUint32(0, v & 0xFFFFFFFF, Endian.little);
    _events
      ..addByte(id)
      ..add(d.buffer.asUint8List());
  }

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

  void text(int id, String s) {
    if (!_utf16) return data(id, [...ascii.encode(s), 0]);
    final out = <int>[];
    for (final unit in '$s\u0000'.codeUnits) {
      out
        ..add(unit & 255)
        ..add(unit >> 8);
    }
    data(id, out);
  }

  /// 212: a slot's header — mixer track, slot, and 2 for FL's own plug-ins
  /// (the Fruity Wrapper among them), 1 for one FL 7 hosted directly.
  void slotHeader(int track, int slot, {int host = 2}) {
    final d = ByteData(52)
      ..setUint32(0, track, Endian.little)
      ..setUint32(4, slot, Endian.little)
      ..setUint32(8, host, Endian.little);
    data(212, d.buffer.asUint8List());
  }

  /// 213 for a Fruity Wrapper: a u32, then records of id u32, size u64,
  /// data — 54 the plug-in's name, 56 its maker, 51 its VST2 id, 55 its path.
  void wrapperState({
    required String name,
    String? vendor,
    String? id,
    String? path,
  }) {
    final out = BytesBuilder()..add([1, 0, 0, 0]);
    void record(int rid, List<int> value) {
      final h = ByteData(12)
        ..setUint32(0, rid, Endian.little)
        ..setUint64(4, value.length, Endian.little);
      out
        ..add(h.buffer.asUint8List())
        ..add(value);
    }

    record(32, [1]);
    if (id != null) record(51, ascii.encode(id).reversed.toList());
    record(54, utf8.encode(name));
    if (path != null) record(55, utf8.encode(path));
    if (vendor != null) record(56, utf8.encode(vendor));
    data(213, out.toBytes());
  }

  /// 225, the mixer's parameters: (track, slot, id, value) each.
  void params(List<(int, int, int, int)> items) {
    final out = BytesBuilder();
    for (final (track, slot, id, value) in items) {
      final d = ByteData(12)
        ..setUint8(4, id)
        ..setUint16(6, (track << 6) | slot, Endian.little)
        ..setInt32(8, value, Endian.little);
      out.add(d.buffer.asUint8List());
    }
    data(225, out.toBytes());
  }

  /// One mixer track's own events, in the order FL writes them.
  void insert({
    String? name,
    List<int> flags = const [],
    List<int> routes = const [],
    int tracks = 8,
    void Function()? slots,
  }) {
    if (name != null) text(204, name);
    data(236, flags);
    slots?.call();
    final routing = List.filled(tracks, 0);
    for (final r in routes) {
      routing[r] = 1;
    }
    data(235, routing);
    dword(154, -1);
    dword(147, -1);
  }

  Uint8List build() {
    final body = (BytesBuilder()
          ..add(_header199())
          ..add(_events.toBytes()))
        .toBytes();
    final header = ByteData(14)
      ..setUint32(4, 6, Endian.little)
      ..setUint16(10, 3, Endian.little)
      ..setUint16(12, 96, Endian.little);
    final h = header.buffer.asUint8List()..setAll(0, ascii.encode('FLhd'));
    final len = ByteData(4)..setUint32(0, body.length, Endian.little);
    return (BytesBuilder()
          ..add(h)
          ..add(ascii.encode('FLdt'))
          ..add(len.buffer.asUint8List())
          ..add(body))
        .toBytes();
  }

  /// 199, the version FL saved with — ASCII in every version.
  List<int> _header199() {
    final v = [...ascii.encode(version), 0];
    return [199, v.length, ...v, 17, 3, 18, 4];
  }
}

/// FL 20: a Sytrus channel and a wrapped Sylenth1 into "Lead", a sampler
/// into the master; Lead routes to the master and to a named reverb bus.
Uint8List _fl20() {
  final f = _Flp(version: '20.9.2.2907');
  // The channel rack.
  f.word(64, 0);
  f.byte(21, 2);
  f.text(203, 'Pluck');
  f.text(201, 'Sytrus');
  f.slotHeader(0, 0);
  f.byte(22, 1);
  f.word(64, 1);
  f.byte(21, 2);
  f.text(203, 'Moon Pad');
  f.text(201, 'Fruity Wrapper');
  f.slotHeader(0, 0);
  f.wrapperState(
    name: 'Sylenth1',
    vendor: 'LennarDigital',
    id: 'syl1',
    path: r'C:\VST\Sylenth1.dll',
  );
  f.byte(22, 1);
  f.word(64, 2);
  f.byte(21, 0);
  f.text(203, 'Kick');
  f.byte(22, 0);
  f.word(64, 3);
  f.byte(21, 5); // automation: not a sound source
  f.text(203, 'Filter cutoff');

  // The mixer: master, Lead (1), Reverb (2), five unused.
  f.insert(
    flags: [0, 0, 0, 0, 0x0c, 0, 0, 0, 0, 0, 0, 0],
    slots: () {
      f.text(201, 'Fruity Limiter');
      f.slotHeader(0, 9);
      f.word(98, 9);
    },
  );
  f.insert(
    name: 'Lead',
    flags: [0, 0, 0, 0, 0x4c, 0x10, 0, 0, 0, 0, 0, 0], // solo
    routes: [0, 2],
    slots: () {
      f.text(201, 'Fruity Wrapper');
      f.slotHeader(1, 0);
      f.wrapperState(
        name: 'Pro-Q 3',
        vendor: 'FabFilter',
        path: r'C:\VST3\FabFilter Pro-Q 3.vst3',
      );
      f.word(98, 0);
      f.text(201, 'Fruity Delay 3');
      f.slotHeader(1, 1);
      f.word(98, 1);
    },
  );
  f.insert(
    name: 'Reverb',
    flags: [0, 0, 0, 0, 0x44, 0, 0, 0, 0, 0, 0, 0], // muted: bit 3 off
    routes: [0],
    slots: () {
      f.text(201, 'Fruity Reeverb 2');
      f.slotHeader(2, 0);
      f.word(98, 0);
    },
  );
  for (var i = 3; i < 8; i++) {
    f.insert(flags: [0, 0, 0, 0, 0x4c, 0, 0, 0, 0, 0, 0, 0], routes: [0]);
  }
  f.params([
    (0, -1 & 0x3F, 192, 12800),
    (1, 0, 192, 9600),
    (1, 0, 193, -3200),
    (1, 1, 0, 0), // Lead's delay switched off in its slot
    (1, 0, 0, 1),
    (2, 0, 192, 12800),
  ]);
  return f.build();
}

/// FL 7: ASCII text, a VST hosted directly, and the four send tracks every
/// mixer track routes to by design (here 5–8).
Uint8List _fl7() {
  final f = _Flp(version: '7.0.0');
  f.word(64, 0);
  f.byte(21, 0);
  f.text(192, 'Prato');
  f.byte(22, 1);
  f.insert(tracks: 10, routes: [0]); // master
  f.insert(
    name: 'Prato',
    tracks: 10,
    routes: [0, 5, 6, 7, 8],
    slots: () {
      f.text(201, 'Waves RBass');
      f.slotHeader(1, 0, host: 1);
    },
  );
  for (var i = 2; i < 5; i++) {
    f.insert(name: '', tracks: 10, routes: [0, 5, 6, 7, 8]);
  }
  for (var i = 5; i < 10; i++) {
    f.insert(name: '', tracks: 10, routes: [0]);
  }
  return f.build();
}

void main() {
  group('FL 20', () {
    final parser = FlpProjectParser(_fl20());

    test('the rack: its sound sources, each with the mixer track it plays '
        'into', () {
      final rack = parser.readChannels();
      expect([for (final c in rack) (c.name, c.type, c.target)], [
        ('Pluck', 2, 1),
        ('Moon Pad', 2, 1),
        ('Kick', 0, 0),
      ], reason: 'an automation channel is no sound source');
      expect(rack[0].plugin?.name, 'Sytrus');
      expect(rack[0].plugin?.native, isTrue);
    });

    test('a wrapped generator by what the wrapper hosts', () {
      final sylenth = parser.readChannels()[1].plugin!;
      expect(sylenth.name, 'Sylenth1');
      expect(sylenth.vendor, 'LennarDigital');
      expect(sylenth.pluginId, 'syl1');
      expect(sylenth.format, 'VST2');
      expect(sylenth.native, isFalse);
    });

    test('the mixer: every track, its slots, routes and parameters', () {
      final mixer = parser.readMixer();
      expect(mixer, hasLength(8));
      expect([for (final i in mixer.take(3)) i.name],
          ['Master', 'Lead', 'Reverb']);
      expect(mixer[3].name, 'Insert 3', reason: 'unnamed, as FL shows it');
      final lead = mixer[1];
      expect(lead.routesTo, [0, 2]);
      expect(lead.volume, 9600);
      expect(lead.pan, -3200);
      expect(lead.soloed, isTrue);
      expect(lead.muted, isFalse);
      expect([for (final s in lead.slots) (s.slot, s.plugin.name, s.enabled)], [
        (0, 'Pro-Q 3', true),
        (1, 'Fruity Delay 3', false),
      ]);
      expect(lead.slots[0].plugin.format, 'VST3');
      expect(mixer[2].muted, isTrue, reason: 'bit 3 of its flags is off');
      expect(mixer[0].slots.single.slot, 9);
    });

    test('the time signature', () {
      expect(parser.readTimeSignature(), (3, 4));
    });
  });

  group('FL 7', () {
    final parser = FlpProjectParser(_fl7());

    test('text is ASCII before FL 11.5, however it looks', () {
      // Guessed from the bytes, "Prato\0" read as UTF-16: "牐瑡o".
      expect(parser.readChannels().single.name, 'Prato');
      expect(parser.readMixer()[1].name, 'Prato');
    });

    test('a VST FL 7 hosted directly is not one of Image-Line\'s', () {
      final rbass = parser.readMixer()[1].slots.single.plugin;
      expect(rbass.name, 'Waves RBass');
      expect(rbass.native, isFalse);
    });

    test('flags FL 7 writes otherwise say nothing about mute', () {
      expect(parser.readMixer()[1].muted, isNull);
    });
  });

  group('flAnatomy', () {
    final a = flAnatomy(filePath: 'Song.flp', bytes: _fl20());
    AnatomyChannel channel(String name) =>
        a.channels!.firstWhere((c) => c.name == name);

    test('the rack, then the mixer tracks in use, the master last', () {
      expect([for (final c in a.channels!) (c.name, c.kind)], [
        ('Pluck', AnatomyChannelKind.instrument),
        ('Moon Pad', AnatomyChannelKind.instrument),
        ('Kick', AnatomyChannelKind.sampler),
        ('Lead', AnatomyChannelKind.group),
        ('Reverb', AnatomyChannelKind.group),
        ('Master', AnatomyChannelKind.master),
      ], reason: 'Insert 3–7: unnamed, empty, nothing plays into them');
    });

    test('a channel plays into its mixer track', () {
      expect(channel('Pluck').output, 'Lead');
      expect(channel('Pluck').instrument, 'Sytrus');
      expect(channel('Kick').output, 'Master');
      expect(channel('Moon Pad').instrumentId, 'syl1');
    });

    test('a mixer track: output to the master, every other route a send', () {
      final lead = channel('Lead');
      expect(lead.output, 'Master');
      expect([for (final s in lead.sends) s.destination], ['Reverb']);
      expect(lead.sends.single.levelDb, isNull,
          reason: 'the level isn\'t read');
      expect(lead.faderPosition, closeTo(0.6, 1e-9));
      expect(lead.volumeDb, isNull, reason: 'FL\'s fader law isn\'t known');
      expect(lead.pan, closeTo(-0.5, 1e-9));
      expect([for (final i in lead.inserts) i.deactivated], [false, true]);
      expect(channel('Reverb').muted, isTrue);
    });

    test('plug-ins: Image-Line\'s are stock, wrapped ones by their maker', () {
      final names = {for (final p in a.plugins) p.name: p};
      expect(names['Sytrus']?.stock, isTrue);
      expect(names['Sytrus']?.vendor, 'Image-Line');
      expect(names['Sytrus']?.role, AnatomyPluginRole.instrument);
      expect(names['Pro-Q 3']?.stock, isFalse);
      expect(names['Pro-Q 3']?.vendor, 'FabFilter');
      expect(names['Pro-Q 3']?.format, 'VST3');
      expect(names['Pro-Q 3']?.channels, ['Lead']);
      expect(names['Fruity Limiter']?.channels, ['Master']);
    });

    test('FL keeps no sample rate; the time signature it does', () {
      expect(a.sampleRate, isNull);
      expect(a.timeSignature, (3, 4));
      expect(a.pluginInstancesKnown, isTrue);
    });

    test('old FL\'s send tracks, which every track routes to, are not sends',
        () {
      final old = flAnatomy(filePath: 'Old.flp', bytes: _fl7());
      final prato = old.channels!.firstWhere(
        (c) => c.name == 'Prato' && c.kind == AnatomyChannelKind.group,
      );
      expect(prato.sends, isEmpty);
      expect(prato.output, 'Master');
      expect(
        old.channels!.where((c) => c.name.startsWith('Insert ')),
        isEmpty,
        reason: 'unused and empty: not listed',
      );
    });
  });
}
