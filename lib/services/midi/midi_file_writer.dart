import 'dart:convert';
import 'dart:typed_data';

import '../../models/midi_clip.dart';

/// Encodes a [MidiClip] as a Standard MIDI File (format 0, one track) that
/// any DAW can import or have dropped onto it.
///
/// The file carries the clip's own PPQ, a track-name meta event, a 4/4 time
/// signature and — when [bpm] is given — the project's tempo, so dragging it
/// into an empty project lands at the right speed. The end-of-track event
/// sits at the clip's length rather than at the last note-off, so a clip
/// ending in a rest keeps its rest.
Uint8List encodeMidiClip(MidiClip clip, {double? bpm}) {
  final track = BytesBuilder();

  void meta(int type, List<int> data) {
    track
      ..add(_varLen(0))
      ..addByte(0xFF)
      ..addByte(type)
      ..add(_varLen(data.length))
      ..add(data);
  }

  final name = clip.name.isNotEmpty ? clip.name : (clip.trackName ?? '');
  if (name.isNotEmpty) meta(0x03, utf8.encode(name));
  if (bpm != null && bpm > 0) {
    final microsPerQuarter = (60000000 / bpm).round().clamp(1, 0xFFFFFF);
    meta(0x51, [
      (microsPerQuarter >> 16) & 0xFF,
      (microsPerQuarter >> 8) & 0xFF,
      microsPerQuarter & 0xFF,
    ]);
  }
  // 4/4, 24 MIDI clocks per click, 8 32nds per quarter.
  meta(0x58, [4, 2, 24, 8]);

  // (tick, isOn, pitch, channel, velocity). Offs sort before ons at the same
  // tick so a repeated note re-triggers instead of being cut off.
  final events = <(int, bool, int, int, int)>[];
  for (final n in clip.notes) {
    events.add((n.startTick, true, n.pitch, n.channel, n.velocity));
    events.add((n.endTick, false, n.pitch, n.channel, 0));
  }
  events.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    if (c != 0) return c;
    if (a.$2 != b.$2) return a.$2 ? 1 : -1;
    return a.$3.compareTo(b.$3);
  });

  var last = 0;
  for (final (tick, isOn, pitch, channel, velocity) in events) {
    final t = tick < 0 ? 0 : tick;
    track
      ..add(_varLen(t - last))
      ..addByte((isOn ? 0x90 : 0x80) | (channel & 0x0F))
      ..addByte(pitch & 0x7F)
      ..addByte(isOn ? velocity.clamp(1, 127) : 0x40);
    last = t;
  }
  final end = clip.lengthTicks > last ? clip.lengthTicks : last;
  track
    ..add(_varLen(end - last))
    ..add(const [0xFF, 0x2F, 0x00]);

  final body = track.toBytes();
  final out = BytesBuilder()
    ..add(ascii.encode('MThd'))
    ..add(_u32(6))
    ..add(_u16(0)) // format 0
    ..add(_u16(1)) // one track
    ..add(_u16(clip.ppq.clamp(1, 0x7FFF)))
    ..add(ascii.encode('MTrk'))
    ..add(_u32(body.length))
    ..add(body);
  return out.toBytes();
}

/// A file name for [clip] that is safe on every desktop filesystem:
/// `Track - Clip.mid`, with characters Windows rejects replaced.
String midiClipFileName(MidiClip clip) {
  final parts = <String>[
    if (clip.trackName != null &&
        clip.trackName!.trim().isNotEmpty &&
        clip.trackName!.trim() != clip.name.trim())
      clip.trackName!.trim(),
    if (clip.name.trim().isNotEmpty) clip.name.trim(),
  ];
  var base = parts.isEmpty ? 'MIDI clip' : parts.join(' - ');
  base = base.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
  // Trailing dots and spaces are invalid on Windows.
  base = base.replaceFirst(RegExp(r'[. ]+$'), '');
  if (base.length > 120) base = base.substring(0, 120).trim();
  if (base.isEmpty) base = 'MIDI clip';
  return '$base.mid';
}

/// Makes [names] unique by appending ` (2)`, ` (3)`… before the extension,
/// comparing case-insensitively (Windows and macOS filesystems do).
List<String> uniqueFileNames(List<String> names) {
  final used = <String>{};
  final out = <String>[];
  for (final name in names) {
    final dot = name.lastIndexOf('.');
    final stem = dot > 0 ? name.substring(0, dot) : name;
    final ext = dot > 0 ? name.substring(dot) : '';
    var candidate = name;
    var i = 2;
    while (!used.add(candidate.toLowerCase())) {
      candidate = '$stem ($i)$ext';
      i++;
    }
    out.add(candidate);
  }
  return out;
}

List<int> _varLen(int value) {
  var v = value < 0 ? 0 : value;
  final bytes = <int>[v & 0x7F];
  v >>= 7;
  while (v > 0) {
    bytes.insert(0, (v & 0x7F) | 0x80);
    v >>= 7;
  }
  return bytes;
}

List<int> _u32(int v) =>
    [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

List<int> _u16(int v) => [(v >> 8) & 0xFF, v & 0xFF];
