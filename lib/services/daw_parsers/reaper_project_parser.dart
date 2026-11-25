import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../models/midi_clip.dart';
import '../../models/project_stats.dart';
import '../../models/sample_reference.dart';
import '../midi/midi_file_reader.dart';
import 'embedded_audio_paths.dart';

/// Reads tracks, plug-ins and MIDI items out of a REAPER `.rpp`.
///
/// RPP is a nested text format: a line starting with `<NAME …` opens a chunk,
/// a line holding just `>` closes it, and everything else is a `KEY values…`
/// line belonging to the innermost open chunk. See
/// github.com/ReaTeam/Doc "State Chunk Definitions".
///
/// * Every `<TRACK` is a track. `ISBUS 1 …` makes it a folder parent. A track
///   with an instrument (`VSTi`, `VST3i`, `AUi`, `CLAPi`, `LV2i`) counts as
///   an instrument track; one with MIDI items but no instrument as MIDI; one
///   without items that receives from other tracks (`AUXRECV`) as a bus;
///   everything else as audio — REAPER tracks are all the same kind, so this
///   is a reading of what each one is used for.
/// * Plug-ins are the `<VST`, `<AU`, `<CLAP`, `<LV2`, `<JS` and `<DX` chunks
///   in a track's or the master's FX chain, named by their first quoted
///   argument (`"VST3: Pro-Q 3 (FabFilter)"` → `Pro-Q 3`). Take FX count too.
/// * A MIDI item's events are the `E`/`e` lines of its `<SOURCE MIDI`, each a
///   tick delta (at the `HASDATA 1 <ppq>` resolution) and three hex bytes.
///   Controller, pitch-bend, aftertouch and program-change lines become the
///   clip's events; `Em`/`em` lines are muted and skipped, and so is the
///   All Notes Off (CC 123) REAPER closes every source with.
/// * An item can instead reference a `.mid` file (`FILE "…"` and no
///   `HASDATA`), relative to the project folder unless absolute; it is read
///   through [ReaperProjectParser.readFile] and windowed the same way. One
///   that can't be found or read is reported in `missingFiles`.
///   The item plays `LENGTH` seconds from `SOFFS` into the source, looping
///   the source when `LOOP 1` is set. Seconds are converted with the
///   project's `TEMPO`, so items in projects with tempo changes are
///   approximate.
class ReaperProjectParser {
  ReaperProjectParser(this.content, {this.projectDir, this.readFile});

  final String content;

  /// The folder the project file is in, which relative `FILE` paths of
  /// referenced `.mid` files start from.
  final String? projectDir;

  /// Reads a referenced `.mid` file's bytes, or null when it isn't there.
  /// Injected so the parser itself never touches the filesystem.
  final Uint8List? Function(String path)? readFile;

  late final _RppChunk _root = _RppChunk.parse(content);

  double get _bpm {
    for (final line in _root.lines) {
      if (line.key == 'TEMPO') {
        final v = double.tryParse(line.arg(0) ?? '');
        if (v != null && v > 0 && v < 1000) return v;
      }
    }
    return 120;
  }

  ProjectStats readStats({bool countMidiClips = true}) {
    var audio = 0, midi = 0, instrument = 0, bus = 0, folder = 0;
    final plugins = <String>[];

    for (final fx in _root.descendants(_isPluginChunk)) {
      final name = _pluginDisplayName(fx);
      if (name != null) plugins.add(name);
    }

    for (final track in _root.children.where((c) => c.name == 'TRACK')) {
      final isFolder = track.lines.any(
        (l) => l.key == 'ISBUS' && l.arg(0) == '1',
      );
      final items = track.children.where((c) => c.name == 'ITEM').toList();
      final hasMidi = items.any((i) => i.descendants(_isMidiSource).isNotEmpty);
      final hasInstrument = track
          .descendants(_isPluginChunk)
          .any((fx) => _isInstrument(fx.header.arg(0) ?? ''));
      final receives = track.lines.any((l) => l.key == 'AUXRECV');

      if (isFolder && items.isEmpty) {
        folder++;
      } else if (hasInstrument) {
        instrument++;
      } else if (hasMidi) {
        midi++;
      } else if (items.isEmpty && receives) {
        bus++;
      } else {
        audio++;
      }
    }

    return ProjectStats(
      audioTracks: audio,
      midiTracks: midi,
      instrumentTracks: instrument,
      busTracks: bus,
      folderTracks: folder,
      plugins: normalizePluginNames(plugins),
      midiClipCount: countMidiClips ? readMidiClips().length : null,
    );
  }

  List<MidiClip> readMidiClips() => readMidi().clips;

  /// The project's unique MIDI clips — from MIDI stored in the project and
  /// from `.mid` files its items reference — and the referenced files that
  /// couldn't be found or read, as the project names them.
  ///
  /// Referenced files are only looked for when the parser was given a
  /// [readFile] (and a [projectDir] for relative paths); without them those
  /// items are skipped, not reported.
  ({List<MidiClip> clips, List<String> missingFiles}) readMidi() {
    final bpm = _bpm;
    final clips = <MidiClip>[];
    final missing = <String>[];
    for (final track in _root.children.where((c) => c.name == 'TRACK')) {
      final trackName = track.value('NAME');
      for (final item in track.children.where((c) => c.name == 'ITEM')) {
        final source = item.children.firstWhere(
          _isMidiSource,
          orElse: () => _RppChunk.empty,
        );
        if (identical(source, _RppChunk.empty)) continue;
        final content = _sourceContent(source, missing);
        if (content == null) continue;
        final clip = _windowItem(item, content, bpm, trackName);
        if (clip != null) clips.add(clip);
      }
    }
    return (clips: dedupeMidiClips(clips), missingFiles: missing);
  }

  /// Every audio file the project references: the `FILE` of each audio
  /// `<SOURCE` (WAVE, MP3, FLAC, VORBIS… — a `SECTION` source nests the real
  /// one, found the same way), relative to the project folder unless
  /// absolute, and paths in plug-in state — ReaSamplOmatic5000's sample
  /// among them. A plug-in's state is base64 lines inside its chunk.
  ///
  /// A file named after its track plus REAPER's take suffix ("Vox-001.wav",
  /// "Vox-240802_1532.wav") is a recording.
  List<SampleReference> readSampleReferences() {
    final refs = <SampleReference>[];
    final trackNames = [
      for (final t in _root.descendants((c) => c.name == 'TRACK'))
        ?t.value('NAME'),
    ];
    for (final source in _root.descendants((c) => c.name == 'SOURCE')) {
      if (_isMidiSource(source)) continue;
      final file = source.value('FILE')?.trim() ?? '';
      if (file.isEmpty || !isSampleAudioFile(file)) continue;
      final name = sampleFileNameOf(file);
      refs.add(
        SampleReference(
          fileName: name,
          candidates: [file],
          kind: looksLikeRecording(name, trackNames, _takeSuffix)
              ? SampleKind.recorded
              : null,
        ),
      );
    }
    for (final fx in _root.descendants(_isPluginChunk)) {
      final bytes = BytesBuilder(copy: false);
      for (final line in fx.lines) {
        if (line.args.isNotEmpty || !_base64Line.hasMatch(line.key)) continue;
        try {
          bytes.add(base64.decode(line.key));
        } on FormatException {
          // Not base64 after all (a JS slider line, say).
        }
      }
      final isSampler = (fx.header.arg(0) ?? '').contains('ReaSamplOmatic5000');
      for (final path in findEmbeddedAudioPaths(bytes.takeBytes())) {
        refs.add(
          SampleReference(
            fileName: sampleFileNameOf(path),
            candidates: [path],
            use: isSampler ? SampleUse.sampler : SampleUse.plugin,
          ),
        );
      }
    }
    return refs;
  }

  static final _base64Line = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');

  /// What REAPER appends to a track's name for a recorded take.
  static const _takeSuffix = r'-(\d{2,4}|\d{6}_\d{4,6}(_\d+)?)';

  /// `<SOURCE MIDI` holds MIDI in the project or names a `.mid` file;
  /// `<SOURCE MIDIPOOL` is pooled MIDI, stored the same way.
  static bool _isMidiSource(_RppChunk c) =>
      c.name == 'SOURCE' &&
      (c.header.arg(0) == 'MIDI' || c.header.arg(0) == 'MIDIPOOL');

  MidiFileContent? _sourceContent(_RppChunk source, List<String> missing) {
    final file = source.value('FILE')?.trim() ?? '';
    final embedded = source.lines.any((l) => l.key == 'HASDATA');
    if (embedded || file.isEmpty) return _embedded(source);
    final read = readFile;
    if (read == null) return null;
    final path = p.isAbsolute(file) || projectDir == null
        ? file
        : p.join(projectDir!, file);
    final bytes = read(path);
    final content = bytes == null ? null : decodeMidiFile(bytes);
    if (content == null && !missing.contains(file)) missing.add(file);
    return content;
  }

  MidiFileContent? _embedded(_RppChunk source) {
    final hasData = source.lines.firstWhere(
      (l) => l.key == 'HASDATA',
      orElse: () => const _RppLine('', []),
    );
    final ppq = int.tryParse(hasData.arg(1) ?? '') ?? 960;
    if (ppq <= 0) return null;

    final notes = <MidiNote>[];
    final events = <MidiEvent>[];
    final open = <int, (int, int)>{}; // channel<<8|pitch -> (start, velocity)
    var tick = 0;
    for (final line in source.lines) {
      final k = line.key;
      if (k != 'E' && k != 'e' && k != 'Em' && k != 'em') {
        continue;
      }
      final delta = int.tryParse(line.arg(0) ?? '');
      final status = int.tryParse(line.arg(1) ?? '', radix: 16);
      final d1 = int.tryParse(line.arg(2) ?? '', radix: 16);
      final d2 = int.tryParse(line.arg(3) ?? '', radix: 16);
      if (delta == null || status == null || d1 == null || d2 == null) {
        continue;
      }
      tick += delta;
      if (k.endsWith('m')) continue; // muted event
      final type = status & 0xF0;
      final channel = status & 0x0F;
      final key = (channel << 8) | (d1 & 0x7F);
      if (type == 0x90 && d2 > 0) {
        open[key] = (tick, d2);
      } else if (type == 0x80 || (type == 0x90 && d2 == 0)) {
        final on = open.remove(key);
        if (on != null) {
          notes.add(
            MidiNote(
              startTick: on.$1,
              lengthTicks: tick - on.$1 < 1 ? 1 : tick - on.$1,
              pitch: d1 & 0x7F,
              velocity: on.$2.clamp(1, 127),
              channel: channel,
            ),
          );
        }
      } else if (MidiEventKind.ofStatus(status) case final kind?) {
        final event = MidiEvent(
          tick: tick,
          kind: kind,
          // Pitch bend is LSB then MSB; program and channel pressure carry
          // their value in the first data byte.
          number:
              kind == MidiEventKind.controller ||
                  kind == MidiEventKind.polyPressure
              ? d1 & 0x7F
              : 0,
          value: switch (kind) {
            MidiEventKind.pitchBend => ((d2 & 0x7F) << 7) | (d1 & 0x7F),
            MidiEventKind.program || MidiEventKind.channelPressure => d1 & 0x7F,
            _ => d2 & 0x7F,
          },
          channel: channel,
        );
        if (!event.isChannelMode) events.add(event);
      }
    }
    return MidiFileContent(
      ppq: ppq,
      notes: notes,
      events: events,
      lengthTicks: tick,
    );
  }

  MidiClip? _windowItem(
    _RppChunk item,
    MidiFileContent source,
    double bpm,
    String? trackName,
  ) {
    final ppq = source.ppq;
    final sourceLength = source.lengthTicks;
    final notes = source.notes;
    final events = source.events;
    final ticksPerSecond = bpm / 60 * ppq;
    final itemLength = double.tryParse(item.value('LENGTH') ?? '');
    final offset = double.tryParse(item.value('SOFFS') ?? '') ?? 0;
    final loop = item.value('LOOP') == '1';
    final windowLength = itemLength == null
        ? sourceLength
        : (itemLength * ticksPerSecond).round();
    final windowStart = (offset * ticksPerSecond).round();

    final windowed = windowMidiNotes(
      notes,
      windowStart: windowStart,
      windowLength: windowLength,
      loop: loop && sourceLength > 0,
      loopStart: 0,
      loopEnd: sourceLength,
    );
    final windowedEvents = windowMidiEvents(
      events,
      windowStart: windowStart,
      windowLength: windowLength,
      loop: loop && sourceLength > 0,
      loopStart: 0,
      loopEnd: sourceLength,
    );
    // An item's NAME is its first take's name; the item chunk itself may also
    // carry one in older files.
    final name = item.value('NAME') ?? '';
    return MidiClip(
      name: name,
      trackName: trackName,
      ppq: ppq,
      lengthTicks: windowLength,
      notes: windowed,
      events: windowedEvents,
    );
  }

  static const _pluginChunks = {'VST', 'AU', 'CLAP', 'LV2', 'JS', 'DX'};

  static bool _isPluginChunk(_RppChunk c) => _pluginChunks.contains(c.name);

  static final _typePrefix = RegExp(
    r'^(VST3?i?|AUi?|CLAPi?|LV2i?|DXi?|JS):\s*',
  );

  static bool _isInstrument(String descriptor) =>
      RegExp(r'^(VST3?i|AUi|CLAPi|LV2i|DXi):').hasMatch(descriptor);

  /// `"VST3: Pro-Q 3 (FabFilter)"` → `Pro-Q 3`; `"AU: Apple: AUDelay"` →
  /// `AUDelay`; a JS effect is named by its script path's last segment.
  static String? _pluginDisplayName(_RppChunk fx) {
    final raw = fx.header.arg(0);
    if (raw == null || raw.isEmpty) return null;
    if (fx.name == 'JS') {
      final parts = raw.split('/');
      return parts.last.trim();
    }
    // Trailing "(Vendor)", but only one — "Kick (2) (Sonic Academy)" — after
    // any channel layout ("(32 out)"); AU descriptors put the vendor first:
    // "Apple: AUDelay".
    final (name, _) = reaperNameAndVendor(
      raw.replaceFirst(_typePrefix, ''),
      vendorFirst: fx.name == 'AU',
    );
    return name.isEmpty ? null : name;
  }
}

/// How a REAPER track is used, read the way [ReaperProjectParser.readStats]
/// reads it: REAPER tracks are all one kind.
enum ReaperTrackKind { audio, midi, instrument, folder, bus, master }

/// One plug-in in an FX chain.
class ReaperFx {
  const ReaperFx({
    required this.name,
    required this.format,
    this.vendor,
    this.pluginId,
    this.isInstrument = false,
    this.bypassed = false,
    this.offline = false,
    this.preset,
  });

  /// As REAPER lists it, without the format, vendor or channel suffixes:
  /// `"VST3i: MODO DRUM (IK Multimedia) (32 out)"` → `MODO DRUM`; a JS effect
  /// by its script's name.
  final String name;

  /// `VST2`, `VST3`, `AU`, `CLAP`, `LV2`, `JS` or `DX`.
  final String format;
  final String? vendor;

  /// A VST2's unique id, a VST3's class id, an AU's or CLAP's identifier, a
  /// JS effect's script path.
  final String? pluginId;
  final bool isInstrument;
  final bool bypassed;
  final bool offline;
  final String? preset;

  /// Built into REAPER: Cockos' own plug-ins and the JS effects.
  bool get stock => format == 'JS' || vendor == 'Cockos';

  ReaperFx withPreset(String preset) => ReaperFx(
    name: name,
    format: format,
    vendor: vendor,
    pluginId: pluginId,
    isInstrument: isInstrument,
    bypassed: bypassed,
    offline: offline,
    preset: preset,
  );
}

/// A send into a track, as REAPER keeps it: on the track that receives it.
class ReaperReceive {
  const ReaperReceive({
    required this.sourceIndex,
    required this.mode,
    required this.volume,
    required this.pan,
    required this.muted,
    required this.sourceChannel,
    required this.destinationChannel,
  });

  /// The sending track's index among the project's tracks.
  final int sourceIndex;

  /// 0 post-fader, 1 pre-FX, 3 pre-fader (post-FX).
  final int mode;

  /// As a gain: 1 is 0 dB.
  final double volume;
  final double pan;
  final bool muted;

  /// The first channel of the pair sent, from 0; -1 sends MIDI only.
  final int sourceChannel;

  /// The first channel of the pair it lands on, from 0: 2 is 3/4, where a
  /// side-chain input usually listens.
  final int destinationChannel;

  bool get preFader => mode == 1 || mode == 3;
  bool get midiOnly => sourceChannel < 0;
}

class ReaperTrack {
  const ReaperTrack({
    required this.name,
    required this.kind,
    this.folder,
    this.volume,
    this.pan,
    this.muted,
    this.soloed,
    this.sendsToParent = true,
    this.hardwareOutputs = const [],
    this.fx = const [],
    this.itemFx = const [],
    this.inputFx = const [],
    this.receives = const [],
  });

  final String name;
  final ReaperTrackKind kind;

  /// The folder track holding it; null at the top level.
  final String? folder;

  /// The fader as a gain (1 is 0 dB).
  final double? volume;

  /// -1 left to 1 right.
  final double? pan;
  final bool? muted;
  final bool? soloed;

  /// `MAINSEND 1`: its audio goes to its folder, or to the master.
  final bool sendsToParent;

  /// The first channel of each hardware output pair it plays to, from 0.
  final List<int> hardwareOutputs;

  /// The track's FX chain, in order.
  final List<ReaperFx> fx;

  /// FX on its items' takes — not on the channel.
  final List<ReaperFx> itemFx;

  /// The input FX chain, applied while recording.
  final List<ReaperFx> inputFx;
  final List<ReaperReceive> receives;

  /// The track's instrument: the first in its chain.
  ReaperFx? get instrument {
    for (final f in fx) {
      if (f.isInstrument) return f;
    }
    return null;
  }
}

/// Tracks, the master, sends and FX chains: what the Project Inspector
/// shows (#226).
///
/// * `ISBUS 1 1` opens a folder; `ISBUS 2 -n` on its last track closes n.
/// * `VOLPAN` is the fader as a gain and the pan; `MUTESOLO` mute and solo.
/// * A send is an `AUXRECV` line on the track that **receives** it: source
///   track index, mode, volume, pan, mute, mono, phase, source channel (-1:
///   MIDI only), destination channel.
/// * An FX chain is a list of plug-in chunks, each after its `BYPASS bypass
///   offline` line and before its `PRESETNAME`.
extension ReaperProjectAnatomy on ReaperProjectParser {
  /// Every track in project order, then the master.
  List<ReaperTrack> readTracks() {
    final tracks = _root.children.where((c) => c.name == 'TRACK').toList();
    final names = <String>[
      for (final (i, t) in tracks.indexed)
        switch (t.value('NAME')?.trim()) {
          final n? when n.isNotEmpty => n,
          _ => 'Track ${i + 1}',
        },
    ];

    final out = <ReaperTrack>[];
    final openFolders = <String>[];
    for (final (i, t) in tracks.indexed) {
      final isbus = t.line('ISBUS');
      final folderFlag = int.tryParse(isbus?.arg(0) ?? '') ?? 0;
      final depthChange = int.tryParse(isbus?.arg(1) ?? '') ?? 0;
      final volpan = t.line('VOLPAN');
      final mutesolo = t.line('MUTESOLO');
      final items = t.children.where((c) => c.name == 'ITEM').toList();
      final chain = _fxChain(t.children.where((c) => c.name == 'FXCHAIN'));
      final hasMidi = items.any(
        (it) => it.descendants(ReaperProjectParser._isMidiSource).isNotEmpty,
      );
      final receives = [
        for (final l in t.lines.where((l) => l.key == 'AUXRECV'))
          if (int.tryParse(l.arg(0) ?? '') case final src?)
            ReaperReceive(
              sourceIndex: src,
              mode: int.tryParse(l.arg(1) ?? '') ?? 0,
              volume: double.tryParse(l.arg(2) ?? '') ?? 1,
              pan: double.tryParse(l.arg(3) ?? '') ?? 0,
              muted: l.arg(4) == '1',
              sourceChannel: int.tryParse(l.arg(7) ?? '') ?? 0,
              destinationChannel: (int.tryParse(l.arg(8) ?? '') ?? 0) & 0x3FF,
            ),
      ];

      final isFolder = folderFlag == 1;
      final kind = isFolder
          ? ReaperTrackKind.folder
          : chain.any((f) => f.isInstrument)
          ? ReaperTrackKind.instrument
          : hasMidi
          ? ReaperTrackKind.midi
          : items.isEmpty && receives.isNotEmpty
          ? ReaperTrackKind.bus
          : ReaperTrackKind.audio;

      out.add(
        ReaperTrack(
          name: names[i],
          kind: kind,
          folder: openFolders.isEmpty ? null : openFolders.last,
          volume: double.tryParse(volpan?.arg(0) ?? ''),
          pan: double.tryParse(volpan?.arg(1) ?? ''),
          muted: mutesolo == null ? null : mutesolo.arg(0) == '1',
          soloed: mutesolo == null
              ? null
              : (int.tryParse(mutesolo.arg(1) ?? '') ?? 0) != 0,
          sendsToParent: t.line('MAINSEND')?.arg(0) != '0',
          hardwareOutputs: [
            for (final l in t.lines.where((l) => l.key == 'HWOUT'))
              if (int.tryParse(l.arg(0) ?? '') case final o?) o & 0x3FF,
          ],
          fx: chain,
          itemFx: [
            for (final item in items)
              ..._fxChain(item.descendants((c) => c.name == 'TAKEFX')),
          ],
          inputFx: _fxChain(t.children.where((c) => c.name == 'FXCHAIN_REC')),
          receives: receives,
        ),
      );

      if (isFolder) openFolders.add(names[i]);
      if (folderFlag == 2 && depthChange < 0) {
        for (var k = 0; k < -depthChange && openFolders.isNotEmpty; k++) {
          openFolders.removeLast();
        }
      }
    }

    final masterVolume = _root.line('MASTER_VOLUME');
    final masterFlags = int.tryParse(_root.value('MASTERMUTESOLO') ?? '');
    out.add(
      ReaperTrack(
        name: 'Master',
        kind: ReaperTrackKind.master,
        volume: double.tryParse(masterVolume?.arg(0) ?? ''),
        pan: double.tryParse(masterVolume?.arg(1) ?? ''),
        muted: masterFlags == null ? null : masterFlags & 1 != 0,
        soloed: masterFlags == null ? null : masterFlags & 2 != 0,
        sendsToParent: false,
        hardwareOutputs: [
          for (final l in _root.lines.where((l) => l.key == 'MASTERHWOUT'))
            if (int.tryParse(l.arg(0) ?? '') case final o?) o & 0x3FF,
        ],
        fx: _fxChain(_root.children.where((c) => c.name == 'MASTERFXLIST')),
      ),
    );
    return out;
  }

  /// `SAMPLERATE 48000 1 0`: the rate, when the project sets it (the 1).
  /// With 0 the project follows the audio device, and the number is only a
  /// default.
  int? readSampleRate() {
    final l = _root.line('SAMPLERATE');
    final rate = int.tryParse(l?.arg(0) ?? '');
    if (rate == null || rate <= 0 || l?.arg(1) != '1') return null;
    return rate;
  }

  /// The bit depth recordings are made at, when they are WAV: `RECORD_CFG`
  /// holds the format's settings in base64, starting with its tag reversed
  /// (`evaw`) and then the bits per sample.
  int? readRecordBitDepth() {
    final cfg = _root.children.where((c) => c.name == 'RECORD_CFG').firstOrNull;
    if (cfg == null || cfg.lines.isEmpty) return null;
    try {
      final bytes = base64.decode(cfg.lines.map((l) => l.key).join());
      if (bytes.length < 5 ||
          String.fromCharCodes(bytes.sublist(0, 4)) != 'evaw') {
        return null;
      }
      final bits = bytes[4];
      return const {8, 16, 24, 32, 64}.contains(bits) ? bits : null;
    } catch (_) {
      return null;
    }
  }

  /// `TEMPO 120 4 4`: the project's time signature, its first.
  (int, int)? readTimeSignature() {
    final l = _root.line('TEMPO');
    final n = int.tryParse(l?.arg(1) ?? '');
    final d = int.tryParse(l?.arg(2) ?? '');
    if (n == null || d == null || n <= 0 || d <= 0) return null;
    return (n, d);
  }

  /// The plug-ins in [chains], in order, each with the `BYPASS` line before
  /// it and the `PRESETNAME` after it.
  List<ReaperFx> _fxChain(Iterable<_RppChunk> chains) {
    final out = <ReaperFx>[];
    for (final chain in chains) {
      var bypassed = false, offline = false;
      for (final e in chain.entries) {
        if (e is _RppLine) {
          if (e.key == 'BYPASS') {
            bypassed = e.arg(0) == '1';
            offline = e.arg(1) == '1';
          } else if (e.key == 'PRESETNAME' && out.isNotEmpty) {
            final preset = e.args.join(' ').trim();
            if (preset.isNotEmpty) out.last = out.last.withPreset(preset);
          }
        } else if (e is _RppChunk && ReaperProjectParser._isPluginChunk(e)) {
          final fx = _fx(e, bypassed: bypassed, offline: offline);
          if (fx != null) out.add(fx);
          bypassed = offline = false;
        }
      }
    }
    return out;
  }

  ReaperFx? _fx(_RppChunk c, {required bool bypassed, required bool offline}) {
    final raw = c.header.arg(0);
    if (raw == null || raw.isEmpty) return null;
    if (c.name == 'JS') {
      final name = raw
          .split('/')
          .last
          .replaceFirst(RegExp(r'\.jsfx$', caseSensitive: false), '')
          .trim();
      if (name.isEmpty) return null;
      return ReaperFx(
        name: name,
        format: 'JS',
        pluginId: raw,
        bypassed: bypassed,
        offline: offline,
      );
    }
    final prefix = ReaperProjectParser._typePrefix.firstMatch(raw);
    final type = prefix?.group(1) ?? c.name;
    final (name, vendor) = reaperNameAndVendor(
      raw.substring(prefix?.end ?? 0),
      vendorFirst: c.name == 'AU',
    );
    if (name.isEmpty) return null;

    final format = switch (type.endsWith('i')
        ? type.substring(0, type.length - 1)
        : type) {
      'VST3' => 'VST3',
      'VST' => 'VST2',
      final other => other,
    };
    // VST: `0 "" 1919247729<5653…>` — the unique id, then for a VST3 its
    // class id in braces. AU and CLAP name themselves in the next argument.
    String? id;
    final idArg = c.header.arg(4);
    if (c.name == 'VST' && idArg != null) {
      id = format == 'VST3'
          ? RegExp(r'\{([0-9A-Fa-f]{32})\}').firstMatch(idArg)?.group(1)
          : RegExp(r'^-?\d+').firstMatch(idArg)?.group(0);
    } else if (c.name == 'CLAP' || c.name == 'AU') {
      id = c.header.arg(1);
    }
    return ReaperFx(
      name: name,
      format: format,
      vendor: vendor,
      pluginId: id == null || id.isEmpty ? null : id,
      isInstrument: ReaperProjectParser._isInstrument(raw),
      bypassed: bypassed,
      offline: offline,
    );
  }
}

/// A channel layout REAPER appends to a plug-in's name: "(32 out)",
/// "(mono)", "(8ch)".
final _channelSuffix = RegExp(
  r'\s*\((\d+\s*out|\d+\s*ch|mono|stereo|\d+\s*->\s*\d+\s*ch)\)\s*$',
  caseSensitive: false,
);

/// What REAPER appends to a 32-bit plug-in it runs bridged: "(x86)".
final _bridgeSuffix = RegExp(
  r'\s*\((x86|x64|32-bit|bridged)\)\s*$',
  caseSensitive: false,
);

/// A plug-in's name and maker from REAPER's listing without the format
/// prefix: `"MODO DRUM (IK Multimedia) (32 out)"` → `MODO DRUM`, `IK
/// Multimedia`; `"BigRock (x86) (ArtsAcoustic)"` → `BigRock`; a maker in
/// brackets of its own, `"Distressor (Universal Audio (UADx))"`, whole. An
/// AU names its maker first: `"Apple: AUDelay"`.
(String, String?) reaperNameAndVendor(
  String listed, {
  bool vendorFirst = false,
}) {
  var rest = listed.trim();
  while (_channelSuffix.hasMatch(rest)) {
    rest = rest.replaceFirst(_channelSuffix, '').trim();
  }
  String? vendor;
  if (rest.endsWith(')')) {
    // The last bracket, matched from the end so a maker's own brackets stay.
    var depth = 0;
    for (var i = rest.length - 1; i >= 0; i--) {
      if (rest[i] == ')') depth++;
      if (rest[i] == '(' && --depth == 0) {
        if (i > 0) {
          vendor = rest.substring(i + 1, rest.length - 1).trim();
          rest = rest.substring(0, i).trim();
        }
        break;
      }
    }
  }
  while (_bridgeSuffix.hasMatch(rest)) {
    rest = rest.replaceFirst(_bridgeSuffix, '').trim();
  }
  if (vendorFirst && rest.contains(': ')) {
    vendor ??= rest.substring(0, rest.indexOf(': ')).trim();
    rest = rest.substring(rest.indexOf(': ') + 2);
  }
  return (rest.trim(), vendor == null || vendor.isEmpty ? null : vendor);
}

class _RppLine {
  const _RppLine(this.key, this.args);
  final String key;
  final List<String> args;
  String? arg(int i) => i < args.length ? args[i] : null;
}

class _RppChunk {
  _RppChunk(this.name, this.header);

  final String name;

  /// The opening line's arguments, e.g. `MIDI` for `<SOURCE MIDI`.
  final _RppLine header;
  final List<_RppLine> lines = [];
  final List<_RppChunk> children = [];

  /// Lines and chunks in file order — an FX chain's `BYPASS` line belongs to
  /// the plug-in chunk after it, its `PRESETNAME` to the one before.
  final List<Object> entries = [];

  static final empty = _RppChunk('', const _RppLine('', []));

  _RppLine? line(String key) {
    for (final l in lines) {
      if (l.key == key) return l;
    }
    return null;
  }

  String? value(String key) {
    for (final l in lines) {
      if (l.key == key) return l.args.isEmpty ? '' : l.args.first;
    }
    return null;
  }

  Iterable<_RppChunk> descendants(bool Function(_RppChunk) test) sync* {
    for (final c in children) {
      if (test(c)) yield c;
      yield* c.descendants(test);
    }
  }

  static _RppChunk parse(String content) {
    final root = _RppChunk('ROOT', const _RppLine('', []));
    final stack = <_RppChunk>[root];
    var first = true;
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line == '>') {
        if (stack.length > 1) stack.removeLast();
        continue;
      }
      if (line.startsWith('<')) {
        final tokens = _tokenize(line.substring(1));
        if (tokens.isEmpty) continue;
        final chunk = _RppChunk(
          tokens.first,
          _RppLine(tokens.first, tokens.sublist(1)),
        );
        // The file's own outer <REAPER_PROJECT …> chunk becomes the root, so
        // top-level TRACKs are the root's direct children.
        if (first && tokens.first == 'REAPER_PROJECT') {
          first = false;
          continue;
        }
        first = false;
        stack.last.children.add(chunk);
        stack.last.entries.add(chunk);
        stack.add(chunk);
        continue;
      }
      first = false;
      // MIDI event lines are hot and never quoted — skip the tokenizer.
      final c = line.codeUnitAt(0);
      final tokens =
          (c == 0x45 || c == 0x65) // 'E' / 'e'
          ? line.split(RegExp(r'\s+'))
          : _tokenize(line);
      if (tokens.isEmpty) continue;
      final parsed = _RppLine(tokens.first, tokens.sublist(1));
      stack.last.lines.add(parsed);
      // MIDI events are never needed in order with the chunks around them.
      if (c != 0x45 && c != 0x65) stack.last.entries.add(parsed);
    }
    return root;
  }

  /// Splits on whitespace, honouring "double", 'single' and `backtick`
  /// quoted arguments (REAPER picks whichever quote the value doesn't
  /// contain).
  static List<String> _tokenize(String line) {
    final out = <String>[];
    var i = 0;
    while (i < line.length) {
      while (i < line.length && (line[i] == ' ' || line[i] == '\t')) {
        i++;
      }
      if (i >= line.length) break;
      final q = line[i];
      if (q == '"' || q == "'" || q == '`') {
        final end = line.indexOf(q, i + 1);
        if (end < 0) {
          out.add(line.substring(i + 1));
          break;
        }
        out.add(line.substring(i + 1, end));
        i = end + 1;
      } else {
        var end = i;
        while (end < line.length && line[end] != ' ' && line[end] != '\t') {
          end++;
        }
        out.add(line.substring(i, end));
        i = end;
      }
    }
    return out;
  }
}
