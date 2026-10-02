import 'dart:convert';
import 'dart:typed_data';

import '../../models/midi_clip.dart';
import '../../models/project_stats.dart';

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
/// * 201 (text) is a plug-in's internal name; 203 (text) its display name.
///   Wrapped VST/VST3s report `Fruity Wrapper` as their internal name, so the
///   display name stands in for those.
/// * 65 (word) starts a pattern, 193 (text) names it, and 224 (data) holds
///   its notes as 24-byte records: position u32, flags u16, channel u16,
///   length u32, key u16, then pitch/pan/velocity bytes (velocity at +21).
///
/// Text payloads are UTF-16LE since FL 11.5 and ASCII before it.
class FlpProjectParser {
  FlpProjectParser(this.bytes) : _data = ByteData.sublistView(bytes);

  final Uint8List bytes;
  final ByteData _data;

  static const _wrapper = 'Fruity Wrapper';

  ProjectStats readStats({bool countMidiClips = true}) {
    final events = _events().toList();
    var sampler = 0, instrument = 0, audio = 0;
    final plugins = <String>[];
    String? pendingInternal;

    for (final e in events) {
      switch (e.id) {
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
          final name = _text(e);
          if (pendingInternal != null && pendingInternal != _wrapper) {
            plugins.add(pendingInternal);
          }
          pendingInternal = name.isEmpty ? null : name;
        case 203:
          final name = _text(e);
          if (pendingInternal == _wrapper && name.isNotEmpty) {
            plugins.add(name);
            pendingInternal = null;
          } else if (pendingInternal != null) {
            plugins.add(pendingInternal);
            pendingInternal = null;
          }
      }
    }
    if (pendingInternal != null && pendingInternal != _wrapper) {
      plugins.add(pendingInternal);
    }

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
        case 203:
          if (channel >= 0) channelNames.putIfAbsent(channel, () => _text(e));
        case 65:
          pattern = e.value;
        case 193:
          patternNames[pattern] = _text(e);
        case 224:
          final list = patternNotes.putIfAbsent(pattern, () => []);
          for (var o = e.offset; o + 24 <= e.offset + e.length; o += 24) {
            final position = _data.getUint32(o, Endian.little);
            final rackChannel = _data.getUint16(o + 6, Endian.little);
            final length = _data.getUint32(o + 8, Endian.little);
            final key = _data.getUint16(o + 12, Endian.little);
            final velocity = bytes[o + 21];
            if (key > 127) continue;
            list.add((
              rackChannel,
              MidiNote(
                startTick: position,
                lengthTicks: length < 1 ? 1 : length,
                pitch: key,
                velocity: velocity.clamp(1, 127),
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

  String _text(_FlpEvent e) {
    final raw = bytes.sublist(e.offset, e.offset + e.length);
    // UTF-16LE when every odd byte of the (even-length) payload is zero —
    // true of every name FL writes in Latin script, which is all ASCII-era
    // files could hold anyway.
    final looksUtf16 = raw.length >= 2 &&
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

class _FlpEvent {
  const _FlpEvent(this.id, this.value, this.offset, this.length);
  final int id;

  /// The payload for fixed-size events; 0 for variable-length ones.
  final int value;
  final int offset;
  final int length;
}
