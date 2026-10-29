import 'dart:convert';
import 'dart:typed_data';

import '../../models/midi_clip.dart';
import '../../models/project_stats.dart';
import '../../models/sample_reference.dart';
import 'cubase_attributes.dart';
import 'embedded_audio_paths.dart';

/// Reads tracks, plug-ins and MIDI parts out of a Cubase/Nuendo `.cpr`/`.npr`.
///
/// ## The format, as far as we need it
///
/// A `.cpr` is a RIFF-like container (`RIFF` + size + `NUND`, then big-endian
/// chunks with no padding). The project lives in `ARCH` chunks, each one a
/// Steinberg object archive:
///
/// * An object is written as a class tag, a version, a size and a body. The
///   first time a class appears the tag is `FF FF FF FF` followed by the
///   class name (u32 length incl. NUL, then the name), a u16 version, a u32
///   body size. `FF FF FF FE` + name + u16 declares a base class without an
///   instance.
/// * Every later object of an already-named class is written as
///   `0x80000000 | (offset of that class's definition − ARCH body start)`
///   followed by a u32 body size — no name and no version. So counting class
///   *names* undercounts wildly; the back-references have to be followed.
/// * Strings are a u32 length (counting a trailing NUL, and on newer versions
///   a UTF-8 BOM after it) then the bytes.
///
/// Every track object (`MAudioTrackEvent`, `MInstrumentTrackEvent`, …) has
/// the same prefix: 26 bytes of position/flags, then a node object whose body
/// starts with the track name — which is what lets each candidate be
/// validated, rather than trusting a 4-byte tag match on its own.
///
/// MIDI notes are not objects: an `MMidiPart` body packs them as fixed
/// records — status byte (`0x9n`), start as a big-endian double in 480-PPQ
/// ticks, channel, pitch, velocity, five zero bytes, an attribute count, the
/// attributes (4-char tag, u16 type, 8-byte value), then the length as a
/// double. Parts keep notes from outside their visible window when trimmed,
/// so notes are clipped to `[0, part length)` from the enclosing
/// `MMidiPartEvent` (start/length doubles at body+2 / body+10).
///
/// Reverse-engineered against Cubase 13 projects; tolerant of anything it
/// doesn't recognise (unknown classes are just never counted).
class CubaseProjectParser {
  CubaseProjectParser(this.bytes) : _data = ByteData.sublistView(bytes);

  final Uint8List bytes;
  final ByteData _data;

  /// Cubase's internal resolution.
  static const int ppq = 480;

  static const _audio = 'MAudioTrackEvent';
  static const _midi = 'MMidiTrackEvent';
  static const _instrument = 'MInstrumentTrackEvent';
  static const _sampler = 'MSamplerTrackEvent';
  static const _device = 'MDeviceTrackEvent';
  static const _folder = 'MFolderTrack';
  /// Plug-in "names" that are really parts of every channel strip, or the
  /// sampler track's own engine. Only ever matched exactly.
  static const _internalPlugins = {
    'Standard Panner',
    'Stereo Combined Panner',
    'Stereo Panner',
    'Mono Panner',
    'VST MultiPanner',
    'Input Filter',
    'EQ',
    'Channel Strip',
    'Sampler Track',
  };

  bool get isCubaseFile =>
      bytes.length > 12 &&
      _ascii(0, 4) == 'RIFF' &&
      _ascii(8, 4) == 'NUND';

  ProjectStats readStats({bool countMidiClips = true}) {
    final counts = <CubaseTrackType, int>{};
    for (final index in _indices) {
      for (final t in _arrangedOf(index).tracks) {
        counts[t.type] = (counts[t.type] ?? 0) + 1;
      }
    }

    return ProjectStats(
      audioTracks: counts[CubaseTrackType.audio] ?? 0,
      midiTracks: counts[CubaseTrackType.midi] ?? 0,
      instrumentTracks: counts[CubaseTrackType.instrument] ?? 0,
      samplerTracks: counts[CubaseTrackType.sampler] ?? 0,
      busTracks: (counts[CubaseTrackType.group] ?? 0) +
          (counts[CubaseTrackType.fx] ?? 0),
      folderTracks: counts[CubaseTrackType.folder] ?? 0,
      plugins: normalizePluginNames(readPluginNames()),
      midiClipCount: countMidiClips ? readMidiClips().length : null,
    );
  }

  /// Every track in project order, with the folder it sits in, and what its
  /// mixer channel says: output, inserts, fader, sends.
  ///
  /// Cubase's hidden "Input/Output Channels" folder and the output devices in
  /// it are left out, as is the VST Instruments rack — its folders and the
  /// output channels of rack instruments ([readRackInstruments] lists those).
  /// [readStats] counts the same tracks.
  List<CubaseTrack> readTracks() {
    final tracks = <CubaseTrack>[];
    final busNames = _busOwnerNames();
    for (final index in _indices) {
      final arranged = _arrangedOf(index);
      // A channel's own input bus is what other channels' outputs name, so
      // a track's output is the track that owns the bus it points at. A
      // plug-in's side-chain input is a bus of its own.
      final byBus = <int, String>{...busNames};
      final sideChains = <int, (String, String)>{};
      final channels = [
        for (final t in arranged.tracks)
          // A folder has no channel of its own; the first one inside it
          // belongs to a track within.
          if (t.type != CubaseTrackType.folder)
            if (_channelOf(t.instance) case final c?) (t, c),
      ];
      final channelOf = {for (final (t, c) in channels) t.instance: c};
      for (final (track, channel) in channels) {
        if (channel.ownBus != null) byBus[channel.ownBus!] = track.name;
        for (final insert in channel.inserts) {
          for (final bus in insert.sideChainBuses) {
            sideChains[bus] = (track.name, insert.plugin);
          }
        }
      }

      for (final t in arranged.tracks) {
        final channel = channelOf[t.instance];
        CubaseSend send(_Send s) {
          final chain = sideChains[s.bus];
          final destination = chain?.$1 ?? byBus[s.bus];
          return CubaseSend(
            slot: s.slot,
            destination: destination,
            sideChainOf: chain?.$2,
            level: s.level,
            on: s.on,
            preFader: s.pre,
          );
        }

        tracks.add(CubaseTrack(
          index: tracks.length,
          name: t.name,
          type: t.type,
          parent: t.parent,
          output: channel?.outBus == null ? null : byBus[channel!.outBus],
          inserts: [
            for (final i in channel?.inserts ?? const <_Insert>[]) i.insert,
          ],
          volume: channel?.volume,
          inputGain: channel?.inputGain,
          phaseInverted: channel?.phaseInverted,
          soloed: channel?.soloed,
          eqBandsOn: channel?.eqBandsOn,
          instrument: channel?.instrument,
          sends: [
            for (final s in channel?.sends ?? const <_Send>[]) send(s),
          ],
        ));
      }
    }
    return tracks;
  }

  /// The instruments in the VST Instruments rack, in rack order: each one's
  /// plug-in and the output channels it adds to the mixer. Instrument tracks
  /// host their own instrument and are not listed here.
  List<CubaseRackInstrument> readRackInstruments() => _rack;

  /// Sample rate, record bit depth and time signature, from the media
  /// attributes Cubase writes into every project it saves (Cubase 5 on; the
  /// time signature from 8 on). Measured on 160 projects from Cubase 5 to 13:
  /// the sample rate agreed with the project's recordings in every one.
  CubaseProjectSetup readProjectSetup() {
    CubaseAttributes? attribute(String id) {
      final at = _indexOf(_keyBytes(id), 0);
      if (at < 0) return null;
      // The ID string is followed by the attribute's own fields: Type,
      // Flags, then the value under a key naming its type.
      final keyEnd = at + id.length + 5;
      final entries = <(String, Object?)>[];
      var offset = keyEnd;
      for (var i = 0; i < 3; i++) {
        final a = _decoder.attributeAt(offset, limit: keyEnd + 400);
        if (a == null) break;
        entries.add((a.key, a.value));
        offset = a.end;
      }
      return CubaseAttributes(entries);
    }

    final rate = attribute('AudioSampleRate')?.number('Float');
    final depth = attribute('AudioSampleSize')?.integer('Long');
    final signature = switch (attribute('MusicalSignature')?['Object']) {
      final CubaseAttributes o
          when o.integer('Numerator') != null &&
              o.integer('Denominator') != null =>
        (o.integer('Numerator')!, o.integer('Denominator')!),
      _ => null,
    };
    return CubaseProjectSetup(
      sampleRate: rate != null && rate >= 8000 && rate <= 768000
          ? rate.round()
          : null,
      bitDepth: depth != null && depth >= 8 && depth <= 64 ? depth : null,
      timeSignature: signature,
    );
  }

  /// Where 0 dB sits on the fader's scale: 1,251 of 3,672 channels measured
  /// sat exactly here, the default for a new channel.
  static const double unityVolume = 25856;

  /// The top of the fader's scale, +6 dB.
  static const double maxVolume = 32767;

  /// The fader in dB, for the points of the scale that are known: −∞, 0 dB
  /// and +6 dB. The curve between them hasn't been measured against Cubase,
  /// so anything else is null rather than a guess.
  static double? volumeDb(double? volume) => switch (volume) {
        null => null,
        <= 0 => double.negativeInfinity,
        unityVolume => 0,
        >= maxVolume => 6,
        _ => null,
      };

  late final Map<_ArchiveIndex, _Arranged> _arranged = {};
  final Map<_Instance, _Channel?> _channels = {};
  _Channel? _channelOf(_Instance track) => _channels.containsKey(track)
      ? _channels[track]
      : (_channels[track] = _readChannel(track));
  _Arranged _arrangedOf(_ArchiveIndex index) =>
      _arranged[index] ??= _arrange(index);

  static const _trackTypes = [
    (_audio, CubaseTrackType.audio),
    (_midi, CubaseTrackType.midi),
    (_instrument, CubaseTrackType.instrument),
    (_sampler, CubaseTrackType.sampler),
    (_device, CubaseTrackType.group),
    (_folder, CubaseTrackType.folder),
  ];

  /// Which tracks of one archive are the user's, sorted, with their folder
  /// and decoded channel. Device tracks are groups or FX channels by what
  /// their channel says; outputs (in Cubase's hidden I/O folder) and the
  /// VST Instruments rack are set apart.
  _Arranged _arrange(_ArchiveIndex index) {
    final found = <(_Instance, String, CubaseTrackType)>[];
    for (final (cls, type) in _trackTypes) {
      for (final i in index.instancesOf(cls)) {
        final name = _trackName(i);
        if (name != null) found.add((i, name, type));
      }
    }
    found.sort((a, b) => a.$1.start.compareTo(b.$1.start));

    final folders = [
      for (final t in found)
        if (t.$3 == CubaseTrackType.folder) t.$1,
    ];
    // Only device tracks' channels decide anything here; the rest are read
    // when [readTracks] asks (a 300 MB project's stats read 30% slower when
    // every channel was decoded for them).
    final devices = [
      for (final (instance, _, type) in found)
        if (type == CubaseTrackType.group) instance,
    ];

    // A rack instrument's outputs show as device tracks named after them,
    // with no channel of their own; the outermost folder holding one is the
    // rack.
    final orphans = [
      for (final d in devices)
        if (_channelOf(d) == null) d,
    ];
    final rackNames =
        orphans.isEmpty ? const <String>{} : {for (final r in _rack) r.channel};
    final names = {for (final t in found) t.$1: t.$2};
    final rackDevices = [
      for (final d in orphans)
        if (rackNames.contains(names[d])) d,
    ];
    final racks = <_Instance>{
      for (final d in rackDevices)
        ...folders.where((f) => f.contains(d.start)).take(1),
    };
    bool inRack(_Instance i) =>
        racks.any((r) => identical(r, i) || r.contains(i.start));

    // The first other folder holding device tracks is Cubase's own hidden
    // "Input/Output Channels" folder, and the devices in it are outputs.
    final mixDevices = [
      for (final d in devices)
        if (!inRack(d)) d,
    ];
    _Instance? ioFolder;
    for (final f in folders) {
      if (inRack(f)) continue;
      if (mixDevices.any((d) => f.contains(d.start))) {
        ioFolder = f;
        break;
      }
    }
    bool hidden(_Instance i) =>
        inRack(i) ||
        identical(i, ioFolder) ||
        (ioFolder != null && ioFolder.contains(i.start));

    final tracks = <_Track>[];
    for (final (instance, name, type) in found) {
      if (hidden(instance)) continue;
      final parent = _innermost(folders, instance.start);
      tracks.add(_Track(
        instance,
        name,
        type == CubaseTrackType.group &&
                _channelOf(instance)?.kind == _ChannelKind.fx
            ? CubaseTrackType.fx
            : type,
        parent == null || hidden(parent) ? null : names[parent],
      ));
    }
    return _Arranged(tracks);
  }

  /// Raw plug-in names, one per inserted instance, internals removed.
  List<String> readPluginNames() {
    final key = _keyBytes('Plugin Name');
    final original = _keyBytes('Original Plugin Name');
    final names = <String>[];
    var from = 0;
    while (true) {
      final at = _indexOf(key, from);
      if (at < 0) break;
      from = at + key.length;
      // Type 0x0008 = string.
      if (!_has(from, 6) || _data.getUint16(from) != 8) continue;
      final value = _readValueString(from + 2);
      if (value == null) continue;
      var name = value.text;
      // A renamed instrument stores the user's label here and the real
      // plug-in in the very next attribute.
      if (_matchesAt(original, value.end) &&
          _has(value.end + original.length, 6) &&
          _data.getUint16(value.end + original.length) == 8) {
        final orig = _readValueString(value.end + original.length + 2);
        if (orig != null && orig.text.isNotEmpty) name = orig.text;
      }
      if (_internalPlugins.contains(name.trim())) continue;
      names.add(name);
    }
    return names.isEmpty ? _devicePathPlugins() : names;
  }

  /// An attribute's string value: as [_readString] reads it, or as Cubase 4
  /// writes it — the length, then exactly that many bytes, no NUL. Read the
  /// other way, every Cubase 4 plug-in was rejected.
  ({String text, int end})? _readValueString(int offset) {
    final terminated = _readString(offset);
    if (terminated != null) return terminated;
    if (!_has(offset, 4)) return null;
    final len = _data.getUint32(offset);
    if (len < 1 || len > 256 || !_has(offset + 4, len)) return null;
    final raw = bytes.sublist(offset + 4, offset + 4 + len);
    if (raw.any((b) => b < 0x20)) return null;
    return (text: utf8.decode(raw, allowMalformed: true), end: offset + 4 + len);
  }

  /// Plug-ins as Cubase SX 3 names them, with no `Plugin Name` attributes:
  /// the devices' paths, a `CONT` string per step — "VST Instruments",
  /// "Slot 3", "Vanguard 2"; "Inserts", "Slot 2", "Sonalksis TBK Stereo 4".
  /// The step after a slot is the plug-in, numbered after its first
  /// instance; the number is dropped when the name also appears without it
  /// or with another — "Pro-Q 3" alone keeps its 3.
  List<String> _devicePathPlugins() {
    final steps = <String>[];
    final tag = ascii.encode('CONT');
    var from = 0;
    while (true) {
      final at = _indexOf(tag, from);
      if (at < 0) break;
      from = at + tag.length;
      final step = _readString(from);
      if (step != null && step.text.isNotEmpty) steps.add(step.text);
    }
    final raw = <String>[];
    for (var i = 1; i + 1 < steps.length; i++) {
      if (_slot.hasMatch(steps[i]) &&
          (steps[i - 1] == 'VST Instruments' || steps[i - 1] == 'Inserts')) {
        raw.add(steps[i + 1]);
      }
    }
    final numbers = <String, Set<String>>{};
    for (final name in raw) {
      final m = _instance.firstMatch(name);
      (numbers[m == null ? name : m[1]!] ??= {}).add(m == null ? '' : m[2]!);
    }
    return [
      for (final name in raw)
        switch (_instance.firstMatch(name)) {
          final m? when numbers[m[1]!]!.length > 1 => m[1]!,
          _ => name,
        },
    ].where((n) => !_internalPlugins.contains(n.trim())).toList();
  }

  static final _slot = RegExp(r'^Slot( \d+)?$');
  static final _instance = RegExp(r'^(.+?) (\d+)$');

  /// Every distinct MIDI part in the project, trimmed to what it plays.
  List<MidiClip> readMidiClips() {
    final clips = <MidiClip>[];
    for (final index in _indices) {
      final parts = index.instancesOf('MMidiPart');
      if (parts.isEmpty) continue;
      final events = index.instancesOf('MMidiPartEvent')
        ..sort((a, b) => a.start.compareTo(b.start));
      final noteTracks = [
        for (final cls in [_instrument, _midi, _sampler])
          ...index.instancesOf(cls).where((i) => _trackName(i) != null),
      ]..sort((a, b) => a.start.compareTo(b.start));

      for (final part in parts) {
        final name = _readString(part.body);
        if (name == null) continue;
        final event = _innermost(events, part.start);
        // A part outside any part event can't be windowed — skip it rather
        // than guess at its length.
        if (event == null) continue;
        final length = _f64(event.body + 10);
        if (length == null || !(length > 0) || length > 1e9) continue;
        final lengthTicks = length.round();

        final raw = _readNotes(part.body, part.end);
        final notes = windowMidiNotes(raw,
            windowStart: 0, windowLength: lengthTicks);
        final track = _innermost(noteTracks, part.start);
        clips.add(MidiClip(
          name: name.text,
          trackName: track == null ? null : _trackName(track),
          ppq: ppq,
          lengthTicks: lengthTicks,
          notes: notes,
        ));
      }
    }
    return dedupeMidiClips(clips);
  }

  /// Every audio file the project references.
  ///
  /// * The pool: each file is an `FNPath` object whose body starts with the
  ///   file name as a string, then the type ("WAVE", the extension twice, a
  ///   description) and the folder it is in, absolute and ending in a
  ///   separator.
  /// * The Sampler Track's sample: a `PSamplerTrackAudioClip` holding an
  ///   `FNPath` of its own, read the same way and marked [SampleUse.sampler].
  /// * Plug-in state, inline in the archive, searched for absolute paths.
  ///
  /// A pool file named after a track and a take number ("Vocals_03.wav") is
  /// a recording; "kick-01.wav" beside "kick.wav" is what Cubase writes when
  /// it processes or bounces a file.
  List<SampleReference> readSampleReferences() {
    final pool = <({String name, String dir, bool sampler})>[];
    for (final index in _indices) {
      final samplerClips = index.instancesOf('PSamplerTrackAudioClip');
      for (final fn in index.instancesOf('FNPath')) {
        final name = _readString(fn.body);
        if (name == null || name.end > fn.end) continue;
        if (!isSampleAudioFile(name.text)) continue;
        String? dir;
        for (var o = name.end; o + 4 < fn.end; o++) {
          final s = _readString(o);
          if (s == null || s.end > fn.end || s.text.length < 2) continue;
          if (s.text.endsWith(r'\') || s.text.endsWith('/')) {
            dir = s.text;
            break;
          }
        }
        if (dir == null) continue;
        pool.add((
          name: name.text,
          dir: dir,
          sampler: samplerClips.any((c) => c.contains(fn.start)),
        ));
      }
    }

    final names = {for (final f in pool) _stem(f.name).toLowerCase()};
    final trackNames = [for (final t in readTracks()) t.name];
    // A file the Sampler Track plays is listed once, as a sampler sample,
    // even when the pool lists it too.
    final inSampler = {
      for (final f in pool)
        if (f.sampler) '${f.dir}${f.name}'.toLowerCase(),
    };
    final refs = <SampleReference>[];
    final seen = <String>{};
    for (final f in pool) {
      final path = '${f.dir}${f.name}';
      if (!seen.add(path.toLowerCase())) continue;
      if (inSampler.contains(path.toLowerCase())) {
        // Loaded into a sampler to be played: a sample, whatever its name
        // says ("kick-01.wav" beside "kick.wav" is a trimmed or tuned copy
        // of a sample, not a bounce of the song).
        refs.add(SampleReference(
          fileName: f.name,
          candidates: [path, 'Audio/${f.name}'],
          use: SampleUse.sampler,
        ));
        continue;
      }
      final copyOf = _processedCopy.firstMatch(_stem(f.name));
      final SampleKind? kind =
          looksLikeRecording(f.name, trackNames, r'_\d{2,3}(-\d{2})?')
              ? SampleKind.recorded
              : copyOf != null && names.contains(copyOf[1]!.toLowerCase())
                  ? SampleKind.processed
                  : null;
      refs.add(SampleReference(
        fileName: f.name,
        candidates: [path, 'Audio/${f.name}'],
        kind: kind,
      ));
    }
    for (final path in findEmbeddedAudioPaths(bytes)) {
      if (!seen.add(path.toLowerCase())) continue;
      refs.add(SampleReference(
        fileName: sampleFileNameOf(path),
        candidates: [path],
        use: SampleUse.plugin,
      ));
    }
    return refs;
  }

  static final _processedCopy = RegExp(r'^(.+)-\d{2}$');

  static String _stem(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? name : name.substring(0, dot);
  }

  // --- notes ---------------------------------------------------------------

  /// The version of Cubase/Nuendo that saved [bytes] ("11.0.41"), from the
  /// `PAppVersion` record: a big-endian u32 length, "Version 11.0.41" and a
  /// NUL. Cubase 6 and later write it first, SX, 4 and 5 last. Null when
  /// there is none.
  static String? appVersion(Uint8List bytes) {
    const tag = [0x56, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x20]; // "Version "
    final data = ByteData.sublistView(bytes);
    outer:
    for (var i = 4; i + tag.length < bytes.length; i++) {
      for (var j = 0; j < tag.length; j++) {
        if (bytes[i + j] != tag[j]) continue outer;
      }
      final length = data.getUint32(i - 4, Endian.big);
      final end = i + length - 1; // the NUL
      if (length < tag.length + 2 || length > 32 || end >= bytes.length || bytes[end] != 0) {
        continue;
      }
      final text = String.fromCharCodes(bytes.sublist(i + tag.length, end));
      if (_versionText.hasMatch(text)) return text;
    }
    return null;
  }

  static final _versionText = RegExp(r'^\d+(\.\d+)*$');

  /// Whether Cubase SX, 4 or 5 saved this — they write notes as
  /// [_legacyNote]s.
  late final bool _legacy = switch (appVersion(bytes)) {
    final v? => (int.tryParse(v.split('.').first) ?? 99) <= 5,
    null => false,
  };

  /// A note as Cubase SX, 4 and 5 write it, at [o]: status, start (f64),
  /// channel, pitch, velocity, a flags byte (2 on nearly every note), four
  /// zero bytes, no attributes, the length (f64), 16 zero bytes and the
  /// note-off velocity — 43 bytes. Measured across 115,000 notes of 51 real
  /// projects; null where [o] holds no such record.
  MidiNote? _legacyNote(int o, int end) {
    if (o + 43 > end) return null;
    final status = bytes[o];
    if (status < 0x90 || status > 0x9F) return null;
    if (bytes[o + 9] > 0x0F || bytes[o + 10] > 0x7F || bytes[o + 11] > 0x7F) return null;
    for (var i = 13; i <= 17; i++) {
      if (bytes[o + i] != 0) return null;
    }
    for (var i = 26; i < 42; i++) {
      if (bytes[o + i] != 0) return null;
    }
    final startTick = _f64(o + 1), length = _f64(o + 18);
    if (startTick == null ||
        length == null ||
        !(length >= 0 && length < 1e8) ||
        !(startTick > -1e9 && startTick < 1e9)) {
      return null;
    }
    final velocity = bytes[o + 11];
    return MidiNote(
      startTick: startTick.round(),
      lengthTicks: length.round() < 1 ? 1 : length.round(),
      pitch: bytes[o + 10],
      velocity: velocity == 0 ? 1 : velocity,
      channel: status & 0x0F,
    );
  }

  List<MidiNote> _readNotes(int start, int end) {
    final notes = <MidiNote>[];
    var o = start;
    while (o + 18 < end) {
      if (_legacy) {
        final note = _legacyNote(o, end);
        if (note != null) {
          notes.add(note);
          o += 43;
        } else {
          o++;
        }
        continue;
      }
      final status = bytes[o];
      if (status < 0x90 ||
          status > 0x9F ||
          bytes[o + 9] > 0x0F ||
          bytes[o + 10] > 0x7F ||
          bytes[o + 11] > 0x7F ||
          bytes[o + 12] != 0 ||
          bytes[o + 13] != 0 ||
          bytes[o + 14] != 0 ||
          bytes[o + 15] != 0 ||
          bytes[o + 16] != 0) {
        o++;
        continue;
      }
      final attrCount = bytes[o + 17];
      if (attrCount < 1 || attrCount > 16) {
        o++;
        continue;
      }
      var q = o + 18;
      var ok = true;
      for (var i = 0; i < attrCount; i++) {
        if (q + 14 > end) {
          ok = false;
          break;
        }
        final type = _data.getUint16(q + 4);
        if (type != 1 && type != 4) {
          ok = false;
          break;
        }
        q += 14; // tag(4) + type(2) + 8-byte value
      }
      if (!ok || q + 24 > end) {
        o++;
        continue;
      }
      final startTick = _f64(o + 1);
      final length = _f64(q);
      if (startTick == null ||
          length == null ||
          !(length >= 0 && length < 1e8) ||
          !(startTick > -1e9 && startTick < 1e9)) {
        o++;
        continue;
      }
      final velocity = bytes[o + 11];
      notes.add(MidiNote(
        startTick: startTick.round(),
        lengthTicks: length.round() < 1 ? 1 : length.round(),
        pitch: bytes[o + 10],
        velocity: velocity == 0 ? 1 : velocity,
        channel: status & 0x0F,
      ));
      o = q + 24;
    }
    return notes;
  }

  // --- mixer channel ---------------------------------------------------

  static final _channelKey = _keyBytes('VST Multitrack');
  static final _ownInputBusKey = _keyBytes('OwnInputBus');

  late final _decoder = CubaseAttributeDecoder(bytes);

  /// A track's mixer channel, which sits inside the track's own object, read
  /// as the attribute tree it is (see [CubaseAttributeDecoder]). Null when
  /// the track holds no channel, or it doesn't decode.
  _Channel? _readChannel(_Instance track) {
    final start = _indexOfIn(_channelKey, track.body, track.end);
    if (start < 0) return null;
    final tree = _decoder.rootAt(start, limit: track.end);
    if (tree == null) return null;

    final inserts = <_Insert>[];
    final slots = tree.folder('InsertFolder')?.list('Slot') ?? const [];
    for (var slot = 0; slot < slots.length; slot++) {
      final plugin = slots[slot].folder('Plugin');
      final name = plugin?.string('Plugin Name');
      if (plugin == null || name == null || name.isEmpty) continue;
      inserts.add(_Insert(
        CubaseInsert(
          slot: slot,
          plugin: name,
          pluginId: plugin.folder('Plugin UID')?.string('GUID'),
          deactivated: switch (plugin.integer('Active')) {
            null => null,
            final a => a == 0,
          },
        ),
        [
          for (final (key, value) in plugin.entries)
            if (key.startsWith('Sidechain Bus Id') && value is int && value != 0)
              value,
        ],
      ));
    }

    final sendSlots = tree.folder('SendFolder')?.list('Slot') ?? const [];
    final sends = <_Send>[];
    for (var slot = 0; slot < sendSlots.length; slot++) {
      final s = sendSlots[slot];
      final bus = s.valueOf('Output')?.toInt();
      // An unrouted slot is an empty one, whatever its level says.
      if (bus == null || bus == 0) continue;
      sends.add(_Send(
        slot: slot,
        bus: bus,
        level: s.valueOf('Volume'),
        // Both are written only when set.
        on: s.integer('On') == 1,
        pre: s.integer('Pre') == 1,
      ));
    }

    final bands = tree.folder('EQ')?.list('Band') ?? const [];
    return _Channel(
      kind: _channelKind(tree.integer('Type')),
      ownBus: tree.folder('OwnInputBus')?.integer('Bus UID'),
      outBus: tree.valueOf('OutputBusValue')?.toInt(),
      inserts: inserts,
      sends: sends,
      volume: tree.valueOf('Volume'),
      inputGain: tree.valueOf('InputGain'),
      phaseInverted: switch (tree.integer('InputPhase')) {
        null => null,
        final p => p != 0,
      },
      soloed: tree.integer('SoloFlag') == 1 || tree.integer('Solo') == 1,
      eqBandsOn: bands.isEmpty
          ? null
          : bands.where((b) => b.integer('Enable') == 1).length,
      instrument: _firstPluginName(tree.folder('Synth Slot')),
    );
  }

  /// A channel's `Type`, measured on 3,672 channels from Cubase 4 to 13.
  static _ChannelKind? _channelKind(int? type) => switch (type) {
        1 => _ChannelKind.audio,
        2 => _ChannelKind.group,
        3 => _ChannelKind.rack,
        4 => _ChannelKind.instrument,
        6 => _ChannelKind.fx,
        20 => _ChannelKind.sampler,
        _ => null,
      };

  static final _rackOutputsKey = _keyBytes('Output Channels');
  static final _pluginIsAKey = _keyBytes('Plugin isA');

  /// The VST Instruments rack: each instrument's plug-in and its output
  /// channels. The rack keeps them in its slots, away from the device
  /// tracks the arrangement shows for them; a slot is its plug-in, then its
  /// "Output Channels" (each a channel of type 3).
  late final List<CubaseRackInstrument> _rack = () {
    final rack = <CubaseRackInstrument>[];
    var from = 0;
    var slot = -1;
    while (true) {
      final at = _indexOf(_rackOutputsKey, from);
      if (at < 0) break;
      from = at + _rackOutputsKey.length;
      // A list: one item per output, its index and its channel.
      final outputs = switch (_decoder.attributeAt(at)?.value) {
        final List<CubaseAttributes> items => items,
        _ => null,
      };
      if (outputs == null) continue;
      slot++;
      // The slot's plug-in comes just before: "Plugin isA", then "Plugin".
      String? plugin;
      final isA = _lastIndexOf(_pluginIsAKey, at);
      if (isA >= 0) {
        final kind = _decoder.attributeAt(isA, limit: at);
        final folder = kind == null
            ? null
            : _decoder.attributeAt(kind.end, limit: at);
        if (folder?.key == 'Plugin' && folder?.value is CubaseAttributes) {
          plugin = (folder!.value as CubaseAttributes).string('Plugin Name');
        }
      }
      for (final item in outputs) {
        final channel = item.folder('Output Channel');
        if (channel == null) continue;
        if (_channelKind(channel.integer('Type')) != _ChannelKind.rack) continue;
        final name = channel.folder('Name')?.string('String');
        if (name == null) continue;
        rack.add(CubaseRackInstrument(
          slot: slot,
          channel: name,
          plugin: plugin,
          volume: channel.valueOf('Volume'),
        ));
      }
    }
    return rack;
  }();

  static String? _firstPluginName(CubaseAttributes? tree) {
    if (tree == null) return null;
    for (final (key, value) in tree.entries) {
      if (key == 'Plugin Name' && value is String && value.isNotEmpty) {
        return value;
      }
      final inner = switch (value) {
        final CubaseAttributes a => _firstPluginName(a),
        final List<CubaseAttributes> items =>
          items.map(_firstPluginName).nonNulls.firstOrNull,
        _ => null,
      };
      if (inner != null) return inner;
    }
    return null;
  }

  /// Bus UID → bus name for every channel's own input bus. Output devices
  /// ("Stereo Out") are only named here; tracks are named by their track.
  Map<int, String> _busOwnerNames() {
    final names = <int, String>{};
    var from = 0;
    while (true) {
      final at = _indexOf(_ownInputBusKey, from);
      if (at < 0) break;
      from = at + _ownInputBusKey.length;
      final bus = switch (_decoder.attributeAt(at)?.value) {
        final CubaseAttributes a => a,
        _ => null,
      };
      final uid = bus?.integer('Bus UID');
      final name = bus?.string('Name');
      if (uid != null && name != null) names[uid] = name;
    }
    return names;
  }

  int _indexOfIn(List<int> pattern, int from, int to) =>
      _find(pattern, from, to < bytes.length ? to : bytes.length);

  /// The first [pattern] in `[from, to)`. Keys start with their length's
  /// zero high bytes, which match nearly anywhere in binary; the scan keys
  /// on the first character instead (index 4) — on a 300 MB project the
  /// difference was seconds.
  int _find(List<int> pattern, int from, int to) {
    final anchor = pattern.length > 4 ? 4 : 0;
    final want = pattern[anchor];
    final last = to - pattern.length;
    outer:
    for (var i = from + anchor; i <= last + anchor; i++) {
      if (bytes[i] != want) continue;
      final start = i - anchor;
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[start + j] != pattern[j]) continue outer;
      }
      return start;
    }
    return -1;
  }

  // --- archive helpers -----------------------------------------------------

  /// Built once per parser: indexing walks the whole file twice.
  late final List<_ArchiveIndex> _indices = [
    for (final chunk in _archChunks()) _ArchiveIndex.build(this, chunk),
  ];

  List<(int, int)> _archChunks() {
    final chunks = <(int, int)>[];
    var off = 12;
    while (off + 8 <= bytes.length) {
      final id = _ascii(off, 4);
      final size = _data.getUint32(off + 4);
      final start = off + 8;
      final end = start + size;
      if (end > bytes.length) break;
      if (id == 'ARCH') chunks.add((start, end));
      off = end;
    }
    return chunks;
  }

  /// The name every track object carries in its node, or null when the
  /// candidate isn't really a track (a stray 4-byte match).
  String? _trackName(_Instance track) {
    final node = track.body + 26;
    if (!_has(node, 12)) return null;
    int namePos;
    if (_data.getUint32(node) == 0xFFFFFFFF) {
      final len = _data.getUint32(node + 4);
      if (len > 128) return null;
      namePos = node + 8 + len + 2 + 4;
    } else if (bytes[node] == 0x80) {
      namePos = node + 8;
    } else {
      return null;
    }
    if (namePos >= track.end) return null;
    return _readString(namePos)?.text;
  }

  _Instance? _innermost(List<_Instance> sorted, int offset) {
    // Instances are nested, never partially overlapping, so the last one
    // starting before [offset] that also contains it is the innermost.
    _Instance? found;
    var lo = 0, hi = sorted.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (sorted[mid].start < offset) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    for (var i = lo - 1; i >= 0; i--) {
      if (sorted[i].contains(offset)) {
        found = sorted[i];
        break;
      }
    }
    return found;
  }

  ({String text, int end})? _readString(int offset) {
    if (!_has(offset, 4)) return null;
    final len = _data.getUint32(offset);
    if (len < 1 || len > 4096 || !_has(offset + 4, len)) return null;
    var stop = offset + 4 + len;
    // Newer versions append a UTF-8 BOM after the NUL.
    if (len >= 4 &&
        bytes[stop - 3] == 0xEF &&
        bytes[stop - 2] == 0xBB &&
        bytes[stop - 1] == 0xBF) {
      stop -= 3;
    }
    if (bytes[stop - 1] != 0) return null;
    final text = utf8.decode(
      bytes.sublist(offset + 4, stop - 1),
      allowMalformed: true,
    );
    return (text: text, end: offset + 4 + len);
  }

  double? _f64(int offset) {
    if (!_has(offset, 8)) return null;
    final v = _data.getFloat64(offset);
    return v.isFinite ? v : null;
  }

  bool _has(int offset, int length) =>
      offset >= 0 && offset + length <= bytes.length;

  String _ascii(int offset, int length) =>
      String.fromCharCodes(bytes.sublist(offset, offset + length));

  /// `u32 length` + name + NUL, the way attribute keys are written.
  static List<int> _keyBytes(String key) {
    final n = key.length + 1;
    return [
      (n >> 24) & 0xFF,
      (n >> 16) & 0xFF,
      (n >> 8) & 0xFF,
      n & 0xFF,
      ...ascii.encode(key),
      0,
    ];
  }

  bool _matchesAt(List<int> pattern, int offset) {
    if (!_has(offset, pattern.length)) return false;
    for (var i = 0; i < pattern.length; i++) {
      if (bytes[offset + i] != pattern[i]) return false;
    }
    return true;
  }

  int _lastIndexOf(List<int> pattern, int before) {
    final anchor = pattern.length > 4 ? 4 : 0;
    final want = pattern[anchor];
    outer:
    for (var i = before - pattern.length; i >= 0; i--) {
      if (bytes[i + anchor] != want) continue;
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  int _indexOf(List<int> pattern, int from) =>
      _find(pattern, from, bytes.length);
}

/// What a Cubase track is, in the words the template export uses.
/// [group] and [fx] are both device tracks; their channel tells them apart
/// (a device whose channel can't be read stays a [group]).
enum CubaseTrackType { audio, instrument, midi, sampler, group, fx, folder }

/// One track as [CubaseProjectParser.readTracks] finds it.
class CubaseTrack {
  const CubaseTrack({
    required this.index,
    required this.name,
    required this.type,
    this.parent,
    this.output,
    this.inserts = const [],
    this.volume,
    this.inputGain,
    this.phaseInverted,
    this.soloed,
    this.eqBandsOn,
    this.instrument,
    this.sends = const [],
  });

  final int index;
  final String name;
  final CubaseTrackType type;

  /// Name of the folder holding the track, or null at the top level.
  final String? parent;

  /// Where the channel's output goes: the name of the group or bus channel,
  /// or of an output such as "Stereo Out". Null when it could not be read.
  final String? output;

  /// Plug-ins in the channel's insert slots, in slot order.
  final List<CubaseInsert> inserts;

  /// The fader as Cubase stores it, from 0 (−∞) to 32767 (+6 dB), 0 dB at
  /// [CubaseProjectParser.unityVolume]. See [CubaseProjectParser.volumeDb].
  /// Null when the track has no channel.
  final double? volume;

  /// The pre-section's input gain on the same 0–32767 scale, 0 dB in the
  /// middle (16383.5).
  final double? inputGain;

  final bool? phaseInverted;
  final bool? soloed;

  /// How many of the channel EQ's bands are switched on; null when the
  /// channel has no EQ to read.
  final int? eqBandsOn;

  /// An instrument track's own instrument plug-in.
  final String? instrument;

  /// Routed send slots; empty slots are left out.
  final List<CubaseSend> sends;
}

/// One plug-in in an insert slot, counted from 0 as Cubase lists them.
class CubaseInsert {
  const CubaseInsert({
    required this.slot,
    required this.plugin,
    this.bypassed,
    this.pluginId,
    this.deactivated,
  });
  final int slot;
  final String plugin;

  /// Whether the slot was bypassed when saved. Cubase keeps bypass with the
  /// plug-in's automation state, which isn't read: null from the reader.
  final bool? bypassed;

  /// The plug-in's class id (a VST3 class id, or Cubase's id for a VST2).
  final String? pluginId;

  /// Switched off in the slot (not loaded) when saved.
  final bool? deactivated;
}

/// A routed send: where it goes, how loud, and whether it is on.
class CubaseSend {
  const CubaseSend({
    required this.slot,
    this.destination,
    this.sideChainOf,
    this.level,
    this.on = false,
    this.preFader = false,
  });

  final int slot;

  /// The channel it sends to (an FX or group channel, or the track whose
  /// plug-in takes it as a side-chain); null when the bus isn't found.
  final String? destination;

  /// The plug-in on [destination] whose side-chain input this feeds, or null
  /// for an ordinary send.
  final String? sideChainOf;

  /// On the fader's scale ([CubaseTrack.volume]).
  final double? level;
  final bool on;
  final bool preFader;
}

/// An output channel of an instrument in the VST Instruments rack. An
/// instrument with several outputs gives several, with the same [slot].
class CubaseRackInstrument {
  const CubaseRackInstrument({
    required this.slot,
    required this.channel,
    this.plugin,
    this.volume,
  });

  /// Which rack slot, counted from 0 in the order the project stores them.
  final int slot;
  final String channel;

  /// The instrument plug-in, when its slot can be read.
  final String? plugin;
  final double? volume;
}

/// The project's own settings, as the project's media attributes record
/// them when it is saved.
class CubaseProjectSetup {
  const CubaseProjectSetup({this.sampleRate, this.bitDepth, this.timeSignature});
  final int? sampleRate;

  /// The record format's bit depth (16, 24, 32).
  final int? bitDepth;
  final (int, int)? timeSignature;
}

enum _ChannelKind { audio, group, rack, instrument, fx, sampler }

/// What a track's mixer channel says: the bus it owns for others to send to,
/// the bus its output goes to, its inserts and sends, its fader.
class _Channel {
  const _Channel({
    this.kind,
    this.ownBus,
    this.outBus,
    this.inserts = const [],
    this.sends = const [],
    this.volume,
    this.inputGain,
    this.phaseInverted,
    this.soloed,
    this.eqBandsOn,
    this.instrument,
  });
  final _ChannelKind? kind;
  final int? ownBus;
  final int? outBus;
  final List<_Insert> inserts;
  final List<_Send> sends;
  final double? volume;
  final double? inputGain;
  final bool? phaseInverted;
  final bool? soloed;
  final int? eqBandsOn;
  final String? instrument;
}

/// An insert and the side-chain buses its plug-in offers.
class _Insert {
  const _Insert(this.insert, this.sideChainBuses);
  final CubaseInsert insert;
  final List<int> sideChainBuses;
  String get plugin => insert.plugin;
}

class _Send {
  const _Send({
    required this.slot,
    required this.bus,
    this.level,
    this.on = false,
    this.pre = false,
  });
  final int slot;
  final int bus;
  final double? level;
  final bool on;
  final bool pre;
}

class _Track {
  const _Track(this.instance, this.name, this.type, this.parent);
  final _Instance instance;
  final String name;
  final CubaseTrackType type;
  final String? parent;
}

/// One archive's tracks as [CubaseProjectParser._arrange] sorts them out.
class _Arranged {
  const _Arranged(this.tracks);

  /// The user's tracks, in project order.
  final List<_Track> tracks;
}

class _Instance {
  const _Instance(this.start, this.body, this.end);
  final int start;
  final int body;
  final int end;
  bool contains(int offset) => offset > start && offset < end;
}

/// Class definitions of one ARCH chunk and every instance of each.
class _ArchiveIndex {
  _ArchiveIndex._(this._instances);

  final Map<String, List<_Instance>> _instances;

  List<_Instance> instancesOf(String cls) =>
      List.of(_instances[cls] ?? const <_Instance>[]);

  static final _validName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  static _ArchiveIndex build(CubaseProjectParser p, (int, int) chunk) {
    final (start, end) = chunk;
    final bytes = p.bytes;
    final data = p._data;
    final instances = <String, List<_Instance>>{};
    // ref tag -> class name, for every class defined in this chunk.
    final refs = <int, String>{};

    void addInstance(String cls, int sizePos) {
      if (sizePos + 4 > end) return;
      final size = data.getUint32(sizePos);
      final body = sizePos + 4;
      if (size == 0 || body + size > end) return;
      (instances[cls] ??= []).add(_Instance(sizePos, body, body + size));
    }

    // Pass 1: class definitions.
    for (var o = start; o + 8 <= end; o++) {
      if (bytes[o] != 0xFF ||
          bytes[o + 1] != 0xFF ||
          bytes[o + 2] != 0xFF ||
          (bytes[o + 3] != 0xFF && bytes[o + 3] != 0xFE)) {
        continue;
      }
      final n = data.getUint32(o + 4);
      if (n < 2 || n > 64 || o + 8 + n + 2 > end) continue;
      if (bytes[o + 8 + n - 1] != 0) continue;
      final name = String.fromCharCodes(bytes.sublist(o + 8, o + 8 + n - 1));
      if (!_validName.hasMatch(name)) continue;
      refs[0x80000000 | (o - start)] = name;
      // FF..FF defines a class *and* an instance of it; FF..FE only a class.
      if (bytes[o + 3] == 0xFF) addInstance(name, o + 8 + n + 2);
    }

    // Pass 2: back-references. Only classes we were asked about matter, but
    // filtering here would cost more than it saves.
    final maxTop = 0x80 + ((end - start) >> 24);
    for (var o = start; o + 8 <= end; o++) {
      final b0 = bytes[o];
      if (b0 < 0x80 || b0 > maxTop) continue;
      final cls = refs[data.getUint32(o)];
      if (cls == null) continue;
      addInstance(cls, o + 4);
    }
    return _ArchiveIndex._(instances);
  }
}
