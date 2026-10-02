import 'dart:convert';
import 'dart:typed_data';

import '../../models/midi_clip.dart';
import '../../models/project_stats.dart';

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
  static const _trackClasses = {
    _audio,
    _midi,
    _instrument,
    _sampler,
    _device,
    _folder,
  };

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
    final counts = <String, int>{};
    for (final index in _indices) {
      final tracks = <String, List<_Instance>>{};
      for (final cls in _trackClasses) {
        tracks[cls] = index
            .instancesOf(cls)
            .where((i) => _trackName(i) != null)
            .toList();
      }

      // The first folder holding output channels is Cubase's own hidden
      // "Input/Output Channels" folder, not one the user made, and the
      // devices inside it are outputs rather than groups/FX.
      final folders = tracks[_folder]!..sort((a, b) => a.start.compareTo(b.start));
      final devices = tracks[_device]!;
      _Instance? ioFolder;
      for (final f in folders) {
        if (devices.any((d) => f.contains(d.start))) {
          ioFolder = f;
          break;
        }
      }

      void add(String key, int n) => counts[key] = (counts[key] ?? 0) + n;
      add(_audio, tracks[_audio]!.length);
      add(_midi, tracks[_midi]!.length);
      add(_instrument, tracks[_instrument]!.length);
      add(_sampler, tracks[_sampler]!.length);
      add(_folder, folders.length - (ioFolder == null ? 0 : 1));
      add(
        _device,
        devices.where((d) => ioFolder == null || !ioFolder.contains(d.start)).length,
      );
    }

    return ProjectStats(
      audioTracks: counts[_audio] ?? 0,
      midiTracks: counts[_midi] ?? 0,
      instrumentTracks: counts[_instrument] ?? 0,
      samplerTracks: counts[_sampler] ?? 0,
      busTracks: counts[_device] ?? 0,
      folderTracks: counts[_folder] ?? 0,
      plugins: normalizePluginNames(readPluginNames()),
      midiClipCount: countMidiClips ? readMidiClips().length : null,
    );
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
      final value = _readString(from + 2);
      if (value == null) continue;
      var name = value.text;
      // A renamed instrument stores the user's label here and the real
      // plug-in in the very next attribute.
      if (_matchesAt(original, value.end) &&
          _has(value.end + original.length, 6) &&
          _data.getUint16(value.end + original.length) == 8) {
        final orig = _readString(value.end + original.length + 2);
        if (orig != null && orig.text.isNotEmpty) name = orig.text;
      }
      if (_internalPlugins.contains(name.trim())) continue;
      names.add(name);
    }
    return names;
  }

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

  // --- notes ---------------------------------------------------------------

  List<MidiNote> _readNotes(int start, int end) {
    final notes = <MidiNote>[];
    var o = start;
    while (o + 18 < end) {
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

  int _indexOf(List<int> pattern, int from) {
    final first = pattern[0];
    final last = bytes.length - pattern.length;
    outer:
    for (var i = from; i <= last; i++) {
      if (bytes[i] != first) continue;
      for (var j = 1; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) continue outer;
      }
      return i;
    }
    return -1;
  }
}

/// One object in an archive: its body spans `[body, end)`. [start] is where
/// its size field sits, used for ordering and containment.
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
