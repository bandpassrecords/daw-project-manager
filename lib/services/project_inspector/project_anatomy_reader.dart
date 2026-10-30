import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../models/project_anatomy.dart';
import '../../models/project_stats.dart';
import '../../models/sample_reference.dart';
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
    return Isolate.run(() => cubaseAnatomy(
          filePath: filePath,
          bytes: bytes,
          dawType: dawType,
          tempo: tempo,
          key: key,
        ));
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
    plugins: [
      for (final name in meta.stats?.plugins ?? const <String>[])
        AnatomyPlugin(name: name),
    ],
    media: media,
  );
}

/// A Cubase project's anatomy from its bytes. [tempo] and [key] are what
/// [MetadataExtractor] read; everything else is read here.
ProjectAnatomy cubaseAnatomy({
  required String filePath,
  required Uint8List bytes,
  String? dawType,
  double? tempo,
  String? key,
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
        instrument: t.instrument == null ? null : cleanPluginName(t.instrument!),
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
              sideChainOf:
                  s.sideChainOf == null ? null : cleanPluginName(s.sideChainOf!),
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
          if (i.vendor != null) cleanPluginName(i.plugin).toLowerCase(): i.vendor!,
    }),
    pluginInstancesKnown: channelsDecoded,
    media: parser.readSampleReferences(),
    audioIo: _audioIo(parser.readAudioConnections()),
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
      tally(instrument, AnatomyPluginRole.instrument, c.instrumentId)
          .add(c.name);
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
    final t = tally(cleanPluginName(plugin), AnatomyPluginRole.instrument, null);
    // An instrument with several outputs is one instance.
    if (rackSlots.add(r.slot)) t.instances++;
    if (!t.channels.contains(r.channel)) t.channels.add(r.channel);
  }

  final plugins = [
    for (final t in found.values)
      AnatomyPlugin(
        name: t.name,
        role: t.role,
        stock: isCubaseStockPlugin(t.name) ||
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
