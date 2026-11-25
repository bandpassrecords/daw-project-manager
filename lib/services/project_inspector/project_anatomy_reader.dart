import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../models/project_anatomy.dart';
import '../../models/project_marker.dart';
import '../../models/project_stats.dart';
import '../../models/sample_reference.dart';
import '../daw_parsers/ableton_devices.dart';
import '../daw_parsers/ableton_project_parser.dart';
import '../daw_parsers/cubase_project_parser.dart';
import '../metadata_extractor.dart';
import '../sample_pack/project_sample_reader.dart';
import 'cubase_stock_plugins.dart';

/// Reads what the Project Inspector shows about the project at [filePath].
///
/// Only reads: the project is never written. Header facts (tempo, key, the
/// version) come from [MetadataExtractor]; the rest from the DAW's reader —
/// in full for Cubase, and for the other DAWs the plug-in names and audio
/// files they already read, until their own readers catch up (#226–#229).
/// Big projects are read in a background isolate.
Future<ProjectAnatomy> readProjectAnatomy(String filePath) async {
  final file = File(filePath);
  final size = await file.length();
  final meta = await MetadataExtractor.extractMetadata(filePath);
  final ext = p.extension(filePath).toLowerCase();

  if (ext == '.cpr' || ext == '.npr') {
    final bytes = await file.readAsBytes();
    final dawType = meta.dawType;
    final tempo = meta.bpm;
    final key = meta.key;
    final stats = meta.stats;
    final notes = meta.projectNotes;
    return Isolate.run(
      () => cubaseAnatomy(
        filePath: filePath,
        bytes: bytes,
        dawType: dawType,
        tempo: tempo,
        key: key,
        stats: stats,
        notes: notes,
      ),
    );
  }

  if (ext == '.als') {
    final bytes = await file.readAsBytes();
    final dawType = meta.dawType;
    final savedWith = meta.dawVersion;
    final tempo = meta.bpm;
    final key = meta.key;
    final stats = meta.stats;
    final markers = meta.markers;
    final missingMidi = meta.missingMidiFiles;
    try {
      return await Isolate.run(
        () => abletonAnatomy(
          filePath: filePath,
          bytes: bytes,
          dawType: dawType,
          savedWith: savedWith,
          tempo: tempo,
          key: key,
          stats: stats,
          markers: markers,
          missingMidiFiles: missingMidi,
        ),
      );
    } catch (_) {
      // A set the reader can't make sense of still shows what the scan
      // read, as the other DAWs do.
    }
  }

  List<SampleReference>? media;
  if (canReadSampleReferences(filePath)) {
    try {
      media = await readProjectSampleReferences(filePath);
    } catch (_) {
      // A reader that fails costs the media list, not the page.
    }
  }
  return ProjectAnatomy(
    filePath: filePath,
    fileSize: size,
    dawType: meta.dawType,
    savedWith: meta.dawVersion,
    tempo: meta.bpm,
    key: meta.key,
    sampleRate: meta.stats?.sampleRate,
    bitDepth: meta.stats?.bitDepth,
    plugins: [
      for (final name in meta.stats?.plugins ?? const <String>[])
        AnatomyPlugin(name: name),
    ],
    media: media,
    stats: meta.stats,
    notes: _notes(meta.projectNotes),
    markers: meta.markers,
    missingMidiFiles: meta.missingMidiFiles,
  );
}

/// Notes as the project keeps them; nothing for blank ones.
String? _notes(String? text) =>
    text == null || text.trim().isEmpty ? null : text.trim();

/// A Cubase project's anatomy from its bytes. [tempo], [key], [stats]
/// (for its MIDI clip count) and [notes] are what [MetadataExtractor]
/// read; everything else is read here.
ProjectAnatomy cubaseAnatomy({
  required String filePath,
  required Uint8List bytes,
  String? dawType,
  double? tempo,
  String? key,
  ProjectStats? stats,
  String? notes,
}) {
  final parser = CubaseProjectParser(bytes);
  final setup = parser.readProjectSetup();
  final tracks = parser.readTracks();
  final rack = parser.readRackInstruments();

  double? position(double? volume) => volume == null
      ? null
      : (volume / CubaseProjectParser.maxVolume).clamp(0.0, 1.0);

  final channels = [
    for (final t in tracks)
      AnatomyChannel(
        name: t.name,
        kind: switch (t.type) {
          CubaseTrackType.audio => AnatomyChannelKind.audio,
          CubaseTrackType.instrument => AnatomyChannelKind.instrument,
          CubaseTrackType.midi => AnatomyChannelKind.midi,
          CubaseTrackType.sampler => AnatomyChannelKind.sampler,
          CubaseTrackType.group => AnatomyChannelKind.group,
          CubaseTrackType.fx => AnatomyChannelKind.fx,
          CubaseTrackType.folder => AnatomyChannelKind.folder,
        },
        folder: t.parent,
        output: t.output,
        volumeDb: CubaseProjectParser.volumeDb(t.volume),
        faderPosition: position(t.volume),
        pan: t.pan == null ? null : t.pan! * 2 - 1,
        muted: t.muted,
        soloed: t.soloed,
        eqBandsOn: t.eqBandsOn,
        instrument: t.instrument == null
            ? null
            : cleanPluginName(t.instrument!),
        instrumentId: t.instrumentId,
        instrumentPreset: t.instrumentPreset,
        inserts: [
          for (final i in t.inserts)
            AnatomyInsert(
              slot: i.slot,
              plugin: cleanPluginName(i.plugin),
              pluginId: i.pluginId,
              deactivated: i.deactivated,
              format: i.format,
              preset: i.preset,
            ),
        ],
        strip: [
          for (final m in t.strip)
            AnatomyStripModule(
              kind: switch (m.kind) {
                null => null,
                CubaseStripKind.gate => AnatomyStripKind.gate,
                CubaseStripKind.compressor => AnatomyStripKind.compressor,
                CubaseStripKind.eq => AnatomyStripKind.eq,
                CubaseStripKind.tools => AnatomyStripKind.tools,
                CubaseStripKind.saturation => AnatomyStripKind.saturation,
                CubaseStripKind.limiter => AnatomyStripKind.limiter,
              },
              plugin: cleanPluginName(m.plugin.plugin),
              pluginId: m.plugin.pluginId,
              preset: m.plugin.preset,
              deactivated: m.plugin.deactivated,
            ),
        ],
        stripBypassed: t.stripBypassed,
        stripBeforeInserts: t.stripBeforeInserts,
        sends: [
          for (final s in t.sends)
            AnatomySend(
              destination: s.destination,
              sideChainOf: s.sideChainOf == null
                  ? null
                  : cleanPluginName(s.sideChainOf!),
              levelDb: CubaseProjectParser.volumeDb(s.level),
              levelPosition: position(s.level),
              on: s.on,
              preFader: s.preFader,
            ),
        ],
      ),
  ];

  // Cubase SX and some 4/5 projects keep no channel the decoder reads:
  // their plug-ins are known by name only, as the project stats know them.
  final channelsDecoded = channels.any((c) => c.faderPosition != null);
  return ProjectAnatomy(
    filePath: filePath,
    fileSize: bytes.length,
    dawType: dawType ?? 'Cubase',
    savedWith: CubaseProjectParser.appVersion(bytes),
    tempo: tempo,
    key: key,
    timeSignature: setup.timeSignature,
    sampleRate: setup.sampleRate,
    bitDepth: setup.bitDepth,
    channels: channels,
    plugins: !channelsDecoded
        ? [
            for (final name in normalizePluginNames(parser.readPluginNames()))
              AnatomyPlugin(name: name, stock: isCubaseStockPlugin(name)),
          ]
        : _cubasePlugins(channels, rack, {
            for (final t in tracks)
              for (final i in [...t.inserts, for (final m in t.strip) m.plugin])
                if (i.vendor != null)
                  cleanPluginName(i.plugin).toLowerCase(): i.vendor!,
          }),
    pluginInstancesKnown: channelsDecoded,
    media: parser.readSampleReferences(),
    audioIo: _audioIo(parser.readAudioConnections()),
    stats: stats,
    notes: _notes(notes),
  );
}

AnatomyAudioIo _audioIo(CubaseAudioConnections io) {
  List<String> names(bool input, bool midi) => [
    for (final p in io.ports)
      if (p.input == input && p.midi == midi) p.name,
  ];
  AnatomyBus bus(CubaseBus b) =>
      AnatomyBus(name: b.name, ports: [for (final p in b.ports) p.name]);
  return AnatomyAudioIo(
    driver: io.driver,
    platform: io.platform,
    inputBuses: [for (final b in io.inputBuses) bus(b)],
    outputBuses: [for (final b in io.outputBuses) bus(b)],
    interfaceInputs: names(true, false),
    interfaceOutputs: names(false, false),
    midiInputs: names(true, true),
    midiOutputs: names(false, true),
  );
}

/// Every plug-in by name, with its instances and channels: inserts and
/// channel strip modules are effects (the strip's EQ, on every channel, is
/// none); instrument tracks' instruments and the rack's are instruments.
/// [vendors] maps a lower-case name to the maker one of its instances
/// named: the maker of every instance. Steinberg's own count as stock even
/// where the name list doesn't know them.
List<AnatomyPlugin> _cubasePlugins(
  List<AnatomyChannel> channels,
  List<CubaseRackInstrument> rack,
  Map<String, String> vendors,
) {
  final found = <String, _Tally>{};
  _Tally tally(String name, AnatomyPluginRole role, String? id) =>
      found.putIfAbsent(name.toLowerCase(), () => _Tally(name, role, id))
        ..format ??= _formatOf(id);

  for (final c in channels) {
    if (c.instrument case final instrument?) {
      tally(
        instrument,
        AnatomyPluginRole.instrument,
        c.instrumentId,
      ).add(c.name);
    }
    for (final i in c.inserts) {
      tally(i.plugin, AnatomyPluginRole.effect, i.pluginId).add(c.name);
    }
    for (final m in c.stripModules) {
      tally(m.plugin, AnatomyPluginRole.effect, m.pluginId).add(c.name);
    }
  }
  final rackSlots = <int>{};
  for (final r in rack) {
    final plugin = r.plugin;
    if (plugin == null) continue;
    final t = tally(
      cleanPluginName(plugin),
      AnatomyPluginRole.instrument,
      null,
    );
    // An instrument with several outputs is one instance.
    if (rackSlots.add(r.slot)) t.instances++;
    if (!t.channels.contains(r.channel)) t.channels.add(r.channel);
  }

  final plugins = [
    for (final t in found.values)
      AnatomyPlugin(
        name: t.name,
        role: t.role,
        stock:
            isCubaseStockPlugin(t.name) ||
            (vendors[t.name.toLowerCase()]?.startsWith('Steinberg') ?? false),
        instances: t.instances,
        channels: List.unmodifiable(t.channels),
        pluginId: t.id,
        vendor: vendors[t.name.toLowerCase()],
        format: t.format,
      ),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return plugins;
}

String? _formatOf(String? id) => id == null
    ? null
    : (id.toUpperCase().startsWith('565354') ? 'VST2' : 'VST3');

class _Tally {
  _Tally(this.name, this.role, this.id);
  final String name;
  final AnatomyPluginRole role;
  final String? id;
  String? format;
  int instances = 0;
  final List<String> channels = [];

  void add(String channel) {
    instances++;
    if (!channels.contains(channel)) channels.add(channel);
  }
}

/// An Ableton Live set's anatomy from its bytes (`.als` is gzipped XML, or
/// plain XML in the oldest sets). [tempo], [key], [stats] and the rest are
/// what [MetadataExtractor] read from the same file; the tracks, devices,
/// sends and routing are read here.
///
/// Live doesn't store a sample rate in the set, so it stays null.
ProjectAnatomy abletonAnatomy({
  required String filePath,
  required Uint8List bytes,
  String? dawType,
  String? savedWith,
  double? tempo,
  String? key,
  ProjectStats? stats,
  String? notes,
  List<ProjectMarker>? markers,
  List<String>? missingMidiFiles,
}) {
  String text;
  try {
    text = utf8.decode(gzip.decode(bytes), allowMalformed: true);
  } catch (_) {
    text = utf8.decode(bytes, allowMalformed: true);
  }
  final parser = AbletonProjectParser(XmlDocument.parse(text));
  final tracks = parser.readTracks();
  final channels = [for (final t in tracks) _abletonChannel(t)];

  return ProjectAnatomy(
    filePath: filePath,
    fileSize: bytes.length,
    dawType: dawType ?? 'Ableton Live',
    savedWith: savedWith,
    tempo: tempo,
    key: key,
    timeSignature: parser.readTimeSignature(),
    channels: channels,
    plugins: _abletonPlugins(tracks),
    pluginInstancesKnown: true,
    media: parser.readSampleReferences(),
    stats: stats,
    notes: _notes(notes),
    markers: markers,
    missingMidiFiles: missingMidiFiles,
  );
}

/// The device that is a MIDI track's instrument: the first instrument, or
/// the rack that holds it (an instrument rack, a drum rack).
AbletonDevice? _abletonInstrument(AbletonTrack t) {
  if (t.kind != AbletonTrackKind.midi) return null;
  for (final d in t.devices) {
    if (d.kind == AbletonDeviceKind.instrument) return d;
    if (d.tag == 'InstrumentGroupDevice' || d.tag == 'DrumGroupDevice') {
      return d;
    }
  }
  return null;
}

/// A device as the Inspector names it: a rack by what it was called, a
/// plug-in without its format suffixes, a device of Live's by its title.
String _abletonDeviceLabel(AbletonDevice d) => d.kind == AbletonDeviceKind.rack
    ? (d.userName ?? d.name)
    : d.isPlugin
    ? cleanPluginName(d.name)
    : d.name;

AnatomyChannel _abletonChannel(AbletonTrack t) {
  final instrument = _abletonInstrument(t);
  final gain = t.volume;
  final db = gain == null ? null : abletonGainDb(gain);

  return AnatomyChannel(
    name: t.name,
    kind: switch (t.kind) {
      AbletonTrackKind.audio => AnatomyChannelKind.audio,
      AbletonTrackKind.midi =>
        instrument != null
            ? AnatomyChannelKind.instrument
            : AnatomyChannelKind.midi,
      AbletonTrackKind.group => AnatomyChannelKind.group,
      AbletonTrackKind.returnTrack => AnatomyChannelKind.fx,
      AbletonTrackKind.master => AnatomyChannelKind.master,
    },
    folder: t.group,
    output: _abletonOutput(t),
    volumeDb: db,
    faderPosition: db == null ? null : abletonFaderPosition(db),
    pan: t.pan,
    muted: t.active == null ? null : !t.active!,
    soloed: t.soloed,
    instrument: instrument == null ? null : _abletonDeviceLabel(instrument),
    instrumentId: instrument?.pluginId,
    inserts: [
      for (final (i, d) in t.devices.indexed)
        if (!identical(d, instrument))
          AnatomyInsert(
            slot: i,
            plugin: _abletonDeviceLabel(d),
            pluginId: d.pluginId,
            deactivated: d.on == null ? null : !d.on!,
            format: d.format,
          ),
    ],
    sends: [
      // Live has a send to every return on every track; one turned all the
      // way down sends nothing.
      for (final s in t.sends)
        if (s.level == null ||
            abletonGainDb(s.level!) > double.negativeInfinity)
          AnatomySend(
            destination: s.destination,
            levelDb: s.level == null ? null : abletonGainDb(s.level!),
            levelPosition: s.level == null
                ? null
                : abletonFaderPosition(abletonGainDb(s.level!)),
            on: s.active,
            preFader: s.preFader,
          ),
    ],
  );
}

/// The channel a track's audio goes to, named as the Inspector names
/// channels: "Master", the group's name, or the external output Live shows.
String? _abletonOutput(AbletonTrack t) {
  final target = t.outputTarget;
  if (target == null || target == 'AudioOut/None') return null;
  if (target == 'AudioOut/Master') return 'Master';
  if (target == 'AudioOut/GroupTrack') return t.group;
  final shown = [
    for (final line in [t.outputUpper, t.outputLower])
      if (line != null && line.trim().isNotEmpty) line.trim(),
  ].join(' ');
  return shown.isEmpty ? null : shown;
}

/// Live's lowest fader and send setting (−70 dB as a gain), which Live
/// shows as "-inf dB".
const double kAbletonMinGain = 0.0003162277571;

/// A fader's or send's gain in dB: at Live's lowest setting, minus
/// infinity, as Live shows it.
double abletonGainDb(double gain) => gain <= kAbletonMinGain * 1.0001
    ? double.negativeInfinity
    : (20 * math.log(gain) / math.ln10).clamp(-70.0, 6.0);

/// Where a fader at [db] sits from 0 (bottom) to 1 (top), for drawing it.
/// Live's travel isn't linear: 0 dB sits near the top, −70 at the bottom.
/// This is the shape, not Live's exact scale — the dB is the reading.
double abletonFaderPosition(double db) => db.isInfinite && db < 0
    ? 0
    : db >= 0
    ? (0.85 + 0.15 * (db / 6)).clamp(0.0, 1.0)
    : 0.85 * (1 - math.sqrt((-db / 70).clamp(0.0, 1.0)));

/// Every plug-in and device by name, with its instances and channels:
/// the ones Live makes are stock; racks are containers, so only what is
/// inside them is listed.
List<AnatomyPlugin> _abletonPlugins(List<AbletonTrack> tracks) {
  final found = <String, _AbletonTally>{};
  void visit(AbletonDevice d, String channel) {
    if (d.kind != AbletonDeviceKind.rack) {
      found
          .putIfAbsent(
            '${_abletonDeviceLabel(d).toLowerCase()}|${d.format ?? ''}',
            () => _AbletonTally(d),
          )
          .add(channel);
    }
    for (final n in d.nested) {
      visit(n, channel);
    }
  }

  for (final t in tracks) {
    for (final d in t.devices) {
      visit(d, t.name);
    }
  }
  return [
    for (final t in found.values)
      AnatomyPlugin(
        name: _abletonDeviceLabel(t.device),
        role: t.device.kind == AbletonDeviceKind.instrument
            ? AnatomyPluginRole.instrument
            : AnatomyPluginRole.effect,
        stock: !t.device.isPlugin,
        instances: t.instances,
        channels: List.unmodifiable(t.channels),
        pluginId: t.device.pluginId,
        vendor: t.device.vendor,
        format: t.device.format,
      ),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

class _AbletonTally {
  _AbletonTally(this.device);
  final AbletonDevice device;
  int instances = 0;
  final List<String> channels = [];

  void add(String channel) {
    instances++;
    if (!channels.contains(channel)) channels.add(channel);
  }
}
