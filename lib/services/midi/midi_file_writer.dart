import 'dart:convert';
import 'dart:typed_data';

import '../../models/midi_clip.dart';
import '../../utils/musical_key.dart';

/// A clip on its way out to a `.mid` file, with what the file should say
/// about it: the tempo to write and the project's key. Each clip of a shared
/// collection carries its own, since they come from different projects.
class MidiExport {
  const MidiExport(this.clip, {this.bpm, this.musicalKey});

  final MidiClip clip;
  final double? bpm;

  /// The project's key as written there ("A minor", "F#m"…), or null.
  final String? musicalKey;

  String get fileName => midiClipFileName(clip, musicalKey: musicalKey);

  Uint8List encode() => encodeMidiClip(clip, bpm: bpm, musicalKey: musicalKey);
}

/// Encodes a [MidiClip] as a Standard MIDI File (format 0, one track) that
/// any DAW can import or have dropped onto it.
///
/// The file carries the clip's own PPQ, a track-name meta event, a 4/4 time
/// signature and — when [bpm] is given — the project's tempo, so dragging it
/// into an empty project lands at the right speed. The end-of-track event
/// sits at the clip's length rather than at the last note-off, so a clip
/// ending in a rest keeps its rest. The clip's events — controllers, pitch
/// bend, aftertouch, program changes — are written alongside the notes.
///
/// [musicalKey], the project's key, becomes a key-signature event when it
/// reads as one (see [keySignatureOf]), so a DAW that shows or uses the key
/// gets it with the notes.
Uint8List encodeMidiClip(MidiClip clip, {double? bpm, String? musicalKey}) {
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
  final signature = keySignatureOf(musicalKey);
  if (signature != null) {
    meta(0x59, [signature.sharps & 0xFF, signature.minor ? 1 : 0]);
  }

  // (tick, order, bytes). At one tick note-offs go first so a repeated note
  // re-triggers instead of being cut off, then controllers and program
  // changes so they apply to the notes starting there, then note-ons.
  final events = <(int, int, int, List<int>)>[];
  var seq = 0;
  for (final n in clip.notes) {
    final ch = n.channel & 0x0F;
    events.add((n.endTick, 0, seq++, [0x80 | ch, n.pitch & 0x7F, 0x40]));
    events.add((n.startTick, 2, seq++,
        [0x90 | ch, n.pitch & 0x7F, n.velocity.clamp(1, 127)]));
  }
  for (final e in clip.events) {
    events.add((e.tick, 1, seq++, midiEventBytes(e)));
  }
  events.sort((a, b) {
    var c = a.$1.compareTo(b.$1);
    if (c != 0) return c;
    c = a.$2.compareTo(b.$2);
    return c != 0 ? c : a.$3.compareTo(b.$3);
  });

  var last = 0;
  for (final (tick, _, _, bytes) in events) {
    final t = tick < 0 ? 0 : tick;
    track
      ..add(_varLen(t - last))
      ..add(bytes);
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

/// [event] as the bytes of a MIDI channel message: status, then one data
/// byte (program change, channel pressure) or two (the rest; pitch bend is
/// least significant 7 bits first).
List<int> midiEventBytes(MidiEvent event) {
  final status = event.kind.status | (event.channel & 0x0F);
  final value = event.value.clamp(0, event.kind.maxValue);
  return switch (event.kind) {
    MidiEventKind.pitchBend => [status, value & 0x7F, (value >> 7) & 0x7F],
    MidiEventKind.program || MidiEventKind.channelPressure => [status, value],
    _ => [status, event.number & 0x7F, value],
  };
}

/// A file name for [clip] that is safe on every desktop filesystem:
/// `Track - Clip.mid`, with characters Windows rejects replaced — and, when
/// the project has a key, `Track - Clip (A minor).mid`, so the key is there
/// at a glance in a folder or a sample browser.
String midiClipFileName(MidiClip clip, {String? musicalKey}) {
  final parts = <String>[
    if (clip.trackName != null &&
        clip.trackName!.trim().isNotEmpty &&
        clip.trackName!.trim() != clip.name.trim())
      clip.trackName!.trim(),
    if (clip.name.trim().isNotEmpty) clip.name.trim(),
  ];
  var base = _safe(parts.isEmpty ? 'MIDI clip' : parts.join(' - '));
  if (base.length > 120) base = base.substring(0, 120).trim();
  if (base.isEmpty) base = 'MIDI clip';
  var key = _safe(musicalKey?.trim() ?? '');
  if (key.length > 24) key = key.substring(0, 24).trim();
  return key.isEmpty ? '$base.mid' : '$base ($key).mid';
}

String _safe(String name) => name
    .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
    .trim()
    // Trailing dots and spaces are invalid on Windows.
    .replaceFirst(RegExp(r'[. ]+$'), '');

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
