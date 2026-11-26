import 'dart:convert';
import 'dart:typed_data';

import '../../models/midi_clip.dart';
import '../../models/project_stats.dart';
import '../../models/sample_reference.dart';
import 'embedded_audio_paths.dart';

/// Reads channel counts, plug-ins and patterns out of an FL Studio `.flp`.
///
/// An `.flp` is an `FLhd` header (format, channel count, PPQ as little-endian
/// u16s) followed by an `FLdt` chunk holding a flat stream of TLV events whose
/// id range sets the payload size (see `MetadataExtractor._extractFromFlpFile`).
/// The events used here, from the PyFLP / FLPFiles event catalogues:
///
/// * 64 (word) starts a new channel; 21 (byte) is that channel's type —
///   0 sampler, 1 native generator, 2 plug-in generator, 4 audio clip
///   (3 layer and 5 automation aren't tracks).
/// * 201 (text) is a plug-in's internal name; 203 (text) its display name —
///   192 (text) before FL 12 (FL 7 and 10 write it after the plug-in's
///   state). Wrapped VST/VST3s report `Fruity Wrapper` as their internal
///   name; the wrapper's state (213) names the plug-in it hosts, and the
///   display name — often a preset's — stands in when it doesn't.
/// * 65 (word) starts a pattern, 193 (text) names it, and 224 (data) holds
///   its notes: position u32, flags u16, channel u16, length u32, then the
///   key. Since FL 9 a record is 24 bytes — key u16, group u16, fine pitch,
///   a byte, release, MIDI channel (+19), pan, velocity (+21), mod X/Y. FL 7
///   wrote 20 — key, fine pitch, release, MIDI channel (+15), pan, velocity
///   (+17), mod X/Y, a byte each (see [_noteRecordSize]).
///
/// Text payloads are UTF-16LE since FL 11.5 and ASCII before it.
class FlpProjectParser {
  FlpProjectParser(this.bytes) : _data = ByteData.sublistView(bytes);

  final Uint8List bytes;
  final ByteData _data;

  static const _wrapper = 'Fruity Wrapper';
  static final _instanceNumber = RegExp(r'\s+#\d+$');

  ProjectStats readStats({bool countMidiClips = true}) {
    final events = _events().toList();
    var sampler = 0, instrument = 0, audio = 0;
    final plugins = <String>[];
    // One plug-in slot at a time — a channel's generator or a mixer effect:
    // its internal name (201), display name (203, or 192 before FL 12) and,
    // for a wrapped VST, the name in its state (213). They come in either
    // order, so the slot is named when the next one starts.
    String? internal, display, wrapped;
    void endSlot() {
      final name = internal == _wrapper ? (wrapped ?? display) : internal;
      if (name != null && name.isNotEmpty) plugins.add(name);
      internal = display = wrapped = null;
    }

    for (final e in events) {
      switch (e.id) {
        case 64:
          endSlot();
        case 21:
          switch (e.value) {
            case 0:
              sampler++;
            case 1:
            case 2:
              instrument++;
            case 4:
              audio++;
          }
        case 201:
          endSlot();
          final name = _text(e);
          // FL 7 spells it "Fruity wrapper".
          internal = name.isEmpty
              ? null
              : name.toLowerCase() == _wrapper.toLowerCase()
                  ? _wrapper
                  : name;
        case 203 || 192:
          // FL numbers a second instance "Sylenth1 #2": the same plug-in.
          if (internal != null) display ??= _text(e).replaceFirst(_instanceNumber, '');
        case 213:
          if (internal == _wrapper) wrapped ??= _wrappedPluginName(e);
      }
    }
    endSlot();

    return ProjectStats(
      samplerTracks: sampler,
      instrumentTracks: instrument,
      audioTracks: audio,
      plugins: normalizePluginNames(plugins),
      midiClipCount: countMidiClips ? readMidiClips().length : null,
    );
  }

  /// One clip per pattern per channel: an FL pattern holds notes for many
  /// channels at once, and a drum pattern's kick line is what you'd reuse.
  List<MidiClip> readMidiClips() {
    final ppq = _ppq;
    final clips = <MidiClip>[];
    final channelNames = <int, String>{};
    var channel = -1;
    var pattern = 0;
    final patternNames = <int, String>{};
    final patternNotes = <int, List<(int, MidiNote)>>{};

    for (final e in _events()) {
      switch (e.id) {
        case 64:
          channel = e.value;
        case 203 || 192:
          if (channel >= 0) channelNames.putIfAbsent(channel, () => _text(e));
        case 65:
          pattern = e.value;
        case 193:
          patternNames[pattern] = _text(e);
        case 224:
          final list = patternNotes.putIfAbsent(pattern, () => []);
          final size = _noteRecordSize(e);
          for (var o = e.offset; o + size <= e.offset + e.length; o += size) {
            final position = _data.getUint32(o, Endian.little);
            final rackChannel = _data.getUint16(o + 6, Endian.little);
            final length = _data.getUint32(o + 8, Endian.little);
            final key = size == 20 ? bytes[o + 12] : _data.getUint16(o + 12, Endian.little);
            final velocity = bytes[o + (size == 20 ? 17 : 21)];
            // A note's own MIDI channel: a pattern imported from a MIDI file
            // keeps each of its parts on one, and two parts can double a
            // note — dropped, they collide on one channel in a .mid.
            final midiChannel = bytes[o + (size == 20 ? 15 : 19)];
            if (key > 127) continue;
            list.add((
              rackChannel,
              MidiNote(
                startTick: position,
                lengthTicks: length < 1 ? 1 : length,
                pitch: key,
                velocity: velocity.clamp(1, 127),
                channel: midiChannel & 0x0F,
              ),
            ));
          }
      }
    }

    final barTicks = ppq * 4;
    for (final entry in patternNotes.entries) {
      final byChannel = <int, List<MidiNote>>{};
      for (final (ch, note) in entry.value) {
        (byChannel[ch] ??= []).add(note);
      }
      for (final ch in byChannel.keys.toList()..sort()) {
        final notes = byChannel[ch]!
          ..sort((a, b) => a.startTick.compareTo(b.startTick));
        final end = notes.map((n) => n.endTick).reduce((a, b) => a > b ? a : b);
        // Patterns have no stored length; round up to whole bars.
        final length = ((end + barTicks - 1) ~/ barTicks) * barTicks;
        clips.add(MidiClip(
          name: patternNames[entry.key] ?? 'Pattern ${entry.key}',
          trackName: channelNames[ch],
          ppq: ppq,
          lengthTicks: length,
          notes: notes,
        ));
      }
    }
    return dedupeMidiClips(clips);
  }

  /// Every audio file the project references.
  ///
  /// * 196 (text) is a channel's sample: a Sampler channel's (type 0) or an
  ///   audio clip's (type 4). FL writes it absolute since FL 12 (or with a
  ///   `%FLStudioFactoryData%`-style placeholder for its own content) and
  ///   relative to its install's `Data` folder before (`\Patches\…`).
  /// * Plug-in state (data events 212/213 and the rest above 207) is
  ///   searched for absolute paths, which finds Fruity Slicer, Slicex,
  ///   DirectWave and any third-party sampler that keeps its path as text.
  List<SampleReference> readSampleReferences() {
    final refs = <SampleReference>[];
    var channelType = -1;
    for (final e in _events()) {
      switch (e.id) {
        case 64:
          channelType = -1;
        case 21:
          channelType = e.value;
        case 196:
          final path = _text(e);
          if (path.isEmpty || !isSampleAudioFile(path)) continue;
          refs.add(SampleReference(
            fileName: sampleFileNameOf(path),
            candidates: [path],
            use: channelType == 4 ? SampleUse.audio : SampleUse.sampler,
          ));
        default:
          if (e.id < 208) continue;
          final payload =
              Uint8List.sublistView(bytes, e.offset, e.offset + e.length);
          for (final path in findEmbeddedAudioPaths(payload)) {
            refs.add(SampleReference(
              fileName: sampleFileNameOf(path),
              candidates: [path],
              use: SampleUse.plugin,
            ));
          }
      }
    }
    return refs;
  }

  /// How long [notes]' records are: 24 bytes since FL 9, 20 in FL 7's
  /// files. A payload only one of them divides says which; one both divide
  /// (every multiple of 120 bytes) goes by which reads as notes — read with
  /// the wrong size, every record after the first starts mid-note, and
  /// positions, lengths and keys come out as flag bytes.
  int _noteRecordSize(_FlpEvent notes) {
    final fits = [
      for (final size in const [24, 20])
        if (notes.length % size == 0) size,
    ];
    if (fits.length == 1) return fits.single;
    if (fits.isEmpty) return 24;
    var best = 24, bestScore = -1.0;
    for (final size in fits) {
      final score = _plausibleNotes(notes, size);
      if (score > bestScore) (best, bestScore) = (size, score);
    }
    return best;
  }

  /// The share of [notes]' records that, read [size] bytes at a time, look
  /// like notes: a key in range, a position and length under a day of ticks.
  double _plausibleNotes(_FlpEvent notes, int size) {
    const sane = 1 << 24;
    var good = 0, all = 0;
    for (var o = notes.offset; o + size <= notes.offset + notes.length; o += size) {
      all++;
      final key = size == 20 ? bytes[o + 12] : _data.getUint16(o + 12, Endian.little);
      if (key <= 127 &&
          _data.getUint32(o, Endian.little) < sane &&
          _data.getUint32(o + 8, Endian.little) < sane) {
        good++;
      }
    }
    return all == 0 ? 0 : good / all;
  }

  /// The plug-in a Fruity Wrapper hosts, from its state (213): a u32, then
  /// records of id u32, size u64 and data, record 54 being the plug-in's own
  /// name — "Sylenth1" on a channel renamed after its preset. Null when the
  /// state is laid out otherwise.
  String? _wrappedPluginName(_FlpEvent state) {
    var pos = state.offset + 4;
    final end = state.offset + state.length;
    while (pos + 12 <= end) {
      final id = _data.getUint32(pos, Endian.little);
      final size = _data.getUint64(pos + 4, Endian.little);
      pos += 12;
      // A u64 past 2^63 reads negative: FL 7's state is laid out otherwise.
      if (size < 0 || size > end - pos) return null;
      if (id == 54) {
        final name = utf8.decode(bytes.sublist(pos, pos + size), allowMalformed: true)
            .replaceAll('\u0000', '')
            .trim();
        return name.isEmpty ? null : name;
      }
      pos += size;
    }
    return null;
  }

  int get _ppq {
    if (bytes.length >= 14 && _ascii(0, 4) == 'FLhd') {
      final ppq = _data.getUint16(12, Endian.little);
      if (ppq > 0) return ppq;
    }
    return 96;
  }

  Iterable<_FlpEvent> _events() sync* {
    if (bytes.length < 8 || _ascii(0, 4) != 'FLhd') return;
    final headerLength = _data.getUint32(4, Endian.little);
    var pos = 8 + headerLength;
    if (pos + 8 > bytes.length || _ascii(pos, 4) != 'FLdt') return;
    final dataLength = _data.getUint32(pos + 4, Endian.little);
    pos += 8;
    final end = pos + dataLength > bytes.length ? bytes.length : pos + dataLength;

    while (pos < end) {
      final id = bytes[pos++];
      if (id < 64) {
        if (pos + 1 > end) return;
        yield _FlpEvent(id, bytes[pos], pos, 1);
        pos += 1;
      } else if (id < 128) {
        if (pos + 2 > end) return;
        yield _FlpEvent(id, _data.getUint16(pos, Endian.little), pos, 2);
        pos += 2;
      } else if (id < 192) {
        if (pos + 4 > end) return;
        yield _FlpEvent(id, _data.getUint32(pos, Endian.little), pos, 4);
        pos += 4;
      } else {
        var length = 0, shift = 0;
        while (true) {
          if (pos >= end) return;
          final b = bytes[pos++];
          length |= (b & 0x7F) << shift;
          if (b & 0x80 == 0) break;
          shift += 7;
        }
        if (pos + length > end) return;
        yield _FlpEvent(id, 0, pos, length);
        pos += length;
      }
    }
  }

  /// Whether text is UTF-16LE, from the version FL wrote in 199 (ASCII in
  /// every version): since FL 11.5. Null when the file names none.
  late final bool? _utf16 = () {
    for (final e in _events()) {
      if (e.id != 199) continue;
      final version = String.fromCharCodes(
        bytes.sublist(e.offset, e.offset + e.length).takeWhile((b) => b != 0),
      );
      final m = RegExp(r'^(\d+)\.(\d+)').firstMatch(version);
      if (m == null) return null;
      final major = int.parse(m.group(1)!), minor = int.parse(m.group(2)!);
      return major > 11 || (major == 11 && minor >= 5);
    }
    return null;
  }();

  String _text(_FlpEvent e) {
    final raw = bytes.sublist(e.offset, e.offset + e.length);
    // The version says which, where the file has one. Guessing from the
    // bytes read FL 7's "Prato" — five letters and a NUL — as UTF-16.
    // Without one: UTF-16LE when enough odd bytes of the (even-length)
    // payload are zero — true of every name FL writes in Latin script.
    final looksUtf16 = _utf16 ?? raw.length >= 2 &&
        raw.length.isEven &&
        Iterable.generate(raw.length ~/ 2, (i) => raw[i * 2 + 1])
                .where((b) => b == 0)
                .length >=
            raw.length ~/ 4;
    String text;
    if (looksUtf16) {
      final units = <int>[];
      for (var i = 0; i + 1 < raw.length; i += 2) {
        units.add(raw[i] | (raw[i + 1] << 8));
      }
      text = String.fromCharCodes(units);
    } else {
      text = utf8.decode(raw, allowMalformed: true);
    }
    final nul = text.indexOf('\u0000');
    return (nul >= 0 ? text.substring(0, nul) : text).trim();
  }

  String _ascii(int offset, int length) =>
      String.fromCharCodes(bytes.sublist(offset, offset + length));
}

/// A plug-in in a mixer slot or on a generator channel.
class FlpPlugin {
  const FlpPlugin({
    required this.name,
    this.vendor,
    this.pluginId,
    this.format,
    this.native = true,
  });

  /// FL's own plug-ins by their name; a wrapped VST by the name its wrapper
  /// keeps.
  final String name;
  final String? vendor;

  /// A wrapped VST2's four-character unique id.
  final String? pluginId;

  /// `VST2` or `VST3` for a wrapped plug-in; null for FL's own.
  final String? format;

  /// One of Image-Line's: not in a Fruity Wrapper, and not hosted directly
  /// as FL 7 hosted VSTs (its slot header's third word 1, not 2).
  final bool native;
}

class FlpSlot {
  const FlpSlot({required this.slot, required this.plugin, this.enabled});
  final int slot;
  final FlpPlugin plugin;

  /// Switched on in its slot; null when the project doesn't say.
  final bool? enabled;
}

/// One mixer track ("insert"); index 0 is the master.
class FlpInsert {
  const FlpInsert({
    required this.index,
    required this.name,
    this.volume,
    this.pan,
    this.muted,
    this.soloed,
    this.effectsOn,
    this.slots = const [],
    this.routesTo = const [],
  });

  final int index;

  /// As the user named it, else "Master" or "Insert N" as FL shows it.
  final String name;

  /// The fader, 0 to 16000: 12800 is FL's 100% (its default).
  final int? volume;

  /// -6400 (left) to 6400 (right).
  final int? pan;
  final bool? muted;
  final bool? soloed;

  /// The track's effects switch; off bypasses every slot.
  final bool? effectsOn;
  final List<FlpSlot> slots;

  /// The mixer tracks it routes to, by index — the master among them.
  final List<int> routesTo;
}

/// A channel in the channel rack.
class FlpChannel {
  const FlpChannel({
    required this.index,
    required this.name,
    required this.type,
    this.plugin,
    this.target,
  });

  final int index;
  final String name;

  /// 0 Sampler, 1 or 2 a generator (FL's own or a plug-in), 4 an audio
  /// clip; 3 (layer) and 5 (automation) aren't sound sources.
  final int type;
  final FlpPlugin? plugin;

  /// The mixer track it plays into; 0 (or none) is the master.
  final int? target;
}

/// The channel rack and the mixer: what the Project Inspector shows (#229).
///
/// From the PyFLP event catalogue, checked against every project in the
/// collection (FL 7, 8, 10 and 20):
///
/// * A mixer track's events end with 147 (its output, a word of -1 when it
///   only routes). Before it: 149 colour and 204 name (when it has one),
///   236 flags (since FL 12 a u32 at 4: bit 3 on, 2 effects on, 12 solo),
///   its slots, and 235, a byte per mixer track it routes to.
/// * A slot is 201 (the plug-in's internal name), 212 (a header: u32 mixer
///   track, u32 slot) and 213 (its state, which for a Fruity Wrapper names
///   the plug-in — record 54 — its maker — 56 — its VST2 id — 51 — and its
///   path — 55); FL 12 adds 98 after each slot.
/// * 225 holds the mixer's parameters, 12 bytes each: u32, u8 id, u8, u16
///   (track << 6 | slot), i32 value — id 0 a slot's switch, 192 a track's
///   fader, 193 its pan.
/// * A channel starts at 64, 21 is its type, 192 (or 203 since FL 12) its
///   name, 201/213 its generator, 22 (a byte) the mixer track it plays into.
extension FlpProjectAnatomy on FlpProjectParser {
  /// The channel rack's sound sources, in order.
  List<FlpChannel> readChannels() {
    final out = <FlpChannel>[];
    int? index, type, target, hostKind;
    String? name, internal;
    _FlpEvent? state;

    void end() {
      if (index != null && type != null && const {0, 1, 2, 4}.contains(type)) {
        out.add(
          FlpChannel(
            index: index!,
            name: (name == null || name!.isEmpty)
                ? 'Channel ${index! + 1}'
                : name!,
            type: type!,
            plugin: type == 1 || type == 2
                ? _plugin(internal, state, fallback: name, hostKind: hostKind)
                : null,
            target: target,
          ),
        );
      }
      index = type = target = hostKind = null;
      name = internal = null;
      state = null;
    }

    for (final e in _events()) {
      if (_insertEvents.contains(e.id)) break; // The mixer follows.
      switch (e.id) {
        case 64:
          end();
          index = e.value;
        case 21:
          type ??= e.value;
        case 22:
          target ??= e.value;
        case 192 || 203:
          if (index != null) {
            name ??= _text(
              e,
            ).replaceFirst(FlpProjectParser._instanceNumber, '');
          }
        case 201:
          if (index != null) internal ??= _text(e);
        case 212:
          if (index != null && internal != null && e.length >= 12) {
            hostKind ??= _data.getUint32(e.offset + 8, Endian.little);
          }
        case 213:
          if (index != null) state ??= e;
      }
    }
    end();
    return out;
  }

  /// Every mixer track, the master first.
  List<FlpInsert> readMixer() {
    final params = _mixerParams();
    final out = <FlpInsert>[];
    var mixer = false;
    var index = 0;
    String? name;
    Uint8List? flags, routing;
    final slots = <FlpSlot>[];
    String? slotInternal;
    _FlpEvent? slotState;
    int? slotIndex, slotHostKind;

    void endSlot() {
      if (slotInternal != null && slotInternal!.isNotEmpty) {
        final plugin = _plugin(
          slotInternal,
          slotState,
          hostKind: slotHostKind,
        );
        final s = slotIndex ?? slots.length;
        if (plugin != null) {
          slots.add(
            FlpSlot(
              slot: s,
              plugin: plugin,
              enabled: switch (params[(index, s, 0)]) {
                final v? => v != 0,
                null => null,
              },
            ),
          );
        }
      }
      slotInternal = null;
      slotState = null;
      slotIndex = slotHostKind = null;
    }

    for (final e in _events()) {
      if (!mixer && !_insertEvents.contains(e.id)) continue;
      mixer = true;
      switch (e.id) {
        case 204:
          name = _text(e);
        case 236:
          flags = Uint8List.sublistView(bytes, e.offset, e.offset + e.length);
        case 201:
          endSlot();
          slotInternal = _text(e);
        case 212:
          if (e.length >= 12) {
            slotIndex = _data.getUint32(e.offset + 4, Endian.little);
            slotHostKind = _data.getUint32(e.offset + 8, Endian.little);
          }
        case 213:
          if (slotInternal != null) slotState ??= e;
        case 98:
          endSlot();
        case 235:
          endSlot();
          routing = Uint8List.sublistView(bytes, e.offset, e.offset + e.length);
        case 147:
          endSlot();
          final f = flags;
          final bits = f != null && f.length >= 8
              ? ByteData.sublistView(f).getUint32(4, Endian.little)
              : null;
          final named = name;
          out.add(
            FlpInsert(
              index: index,
              name: named != null && named.isNotEmpty
                  ? named
                  : index == 0
                  ? 'Master'
                  : 'Insert $index',
              volume: params[(index, -1, 192)],
              pan: params[(index, -1, 193)],
              muted: bits == null ? null : bits & 0x8 == 0,
              soloed: bits == null ? null : bits & 0x1000 != 0,
              effectsOn: bits == null ? null : bits & 0x4 != 0,
              slots: List.of(slots),
              routesTo: [
                for (final (k, r) in (routing ?? Uint8List(0)).indexed)
                  if (r != 0 && k != index) k,
              ],
            ),
          );
          index++;
          name = null;
          flags = routing = null;
          slots.clear();
      }
    }
    return out;
  }

  /// 17 and 18 (bytes): the project's time signature.
  (int, int)? readTimeSignature() {
    int? n, d;
    for (final e in _events()) {
      if (e.id == 17) n ??= e.value;
      if (e.id == 18) d ??= e.value;
      if (n != null && d != null) break;
    }
    if (n == null || d == null || n <= 0 || d <= 0) return null;
    return (n, d);
  }

  /// The events only a mixer track has; the first one ends the channels.
  static const _insertEvents = {149, 204, 236, 235, 154, 147};

  /// 225: (track, slot, id) → value; a track's own parameters have slot -1.
  Map<(int, int, int), int> _mixerParams() {
    final out = <(int, int, int), int>{};
    for (final e in _events()) {
      if (e.id != 225) continue;
      for (var o = e.offset; o + 12 <= e.offset + e.length; o += 12) {
        final id = bytes[o + 4];
        final channel = _data.getUint16(o + 6, Endian.little);
        final value = _data.getInt32(o + 8, Endian.little);
        final track = (channel >> 6) & 0x7F;
        final slot = id == 0 || id == 1 ? channel & 0x3F : -1;
        out[(track, slot, id)] = value;
      }
    }
    return out;
  }

  /// A plug-in from its internal name and state: a Fruity Wrapper by what
  /// its state says it hosts, falling back to [fallback] (a channel's own
  /// name); FL's own by its name.
  FlpPlugin? _plugin(
    String? internal,
    _FlpEvent? state, {
    String? fallback,
    int? hostKind,
  }) {
    if (internal == null || internal.isEmpty) return null;
    final isWrapper =
        internal.toLowerCase() == FlpProjectParser._wrapper.toLowerCase();
    if (!isWrapper) return FlpPlugin(name: internal, native: hostKind != 1);
    final records = state == null
        ? const <int, Uint8List>{}
        : _wrapperRecords(state);
    String? text(int id) {
      final raw = records[id];
      if (raw == null) return null;
      final s = utf8
          .decode(raw, allowMalformed: true)
          .replaceAll('\u0000', '')
          .trim();
      return s.isEmpty ? null : s;
    }

    final name =
        text(54) ??
        fallback?.replaceFirst(FlpProjectParser._instanceNumber, '');
    if (name == null || name.isEmpty) return null;
    final path = text(55);
    final idBytes = records[51];
    String? id;
    if (idBytes != null && idBytes.length == 4) {
      final code = String.fromCharCodes(idBytes.reversed);
      id = RegExp(r'^[\x20-\x7E]{4}$').hasMatch(code)
          ? code
          : '${ByteData.sublistView(idBytes).getUint32(0, Endian.little)}';
    }
    return FlpPlugin(
      name: name,
      vendor: text(56),
      pluginId: id,
      format: path == null
          ? null
          : path.toLowerCase().endsWith('.vst3')
          ? 'VST3'
          : 'VST2',
      native: false,
    );
  }

  /// A Fruity Wrapper's state: a u32, then records of id u32, size u64 and
  /// data. Empty when it is laid out otherwise (FL 7).
  Map<int, Uint8List> _wrapperRecords(_FlpEvent state) {
    final out = <int, Uint8List>{};
    var pos = state.offset + 4;
    final end = state.offset + state.length;
    while (pos + 12 <= end) {
      final id = _data.getUint32(pos, Endian.little);
      final size = _data.getUint64(pos + 4, Endian.little);
      pos += 12;
      if (size < 0 || size > end - pos) return out;
      out[id] = Uint8List.sublistView(bytes, pos, pos + size);
      pos += size;
    }
    return out;
  }
}

class _FlpEvent {
  const _FlpEvent(this.id, this.value, this.offset, this.length);
  final int id;

  /// The payload for fixed-size events; 0 for variable-length ones.
  final int value;
  final int offset;
  final int length;
}
