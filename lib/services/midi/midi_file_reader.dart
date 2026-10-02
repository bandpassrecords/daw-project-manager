import 'dart:io';
import 'dart:typed_data';

import '../../models/midi_clip.dart';

/// What a Standard MIDI File holds, flattened to one stream: its resolution,
/// every note and channel event of every track, and its length — the end of
/// its longest track.
class MidiFileContent {
  const MidiFileContent({
    required this.ppq,
    required this.notes,
    required this.events,
    required this.lengthTicks,
  });

  final int ppq;
  final List<MidiNote> notes;
  final List<MidiEvent> events;
  final int lengthTicks;
}

/// Reads a Standard MIDI File (format 0 or 1; the tracks of a format-1 file
/// are merged, as a DAW importing it onto one track would). Tempo, time
/// signatures and other meta events are skipped — the notes stay in ticks,
/// which is what a clip is measured in. Null for anything that isn't a
/// readable SMF, and for SMPTE-timed files, which have no PPQ.
///
/// Like the project readers it is forgiving: a truncated track keeps the
/// notes read before the cut, and a note never released ends with its
/// track.
MidiFileContent? decodeMidiFile(Uint8List bytes) {
  if (bytes.length < 14 || !_tagAt(bytes, 0, 'MThd')) return null;
  final d = ByteData.sublistView(bytes);
  final headerLength = d.getUint32(4);
  final division = d.getUint16(12);
  if (division & 0x8000 != 0 || division == 0) return null;

  final notes = <MidiNote>[];
  final events = <MidiEvent>[];
  var length = 0;
  var pos = 8 + headerLength;
  while (pos + 8 <= bytes.length) {
    final chunkLength = d.getUint32(pos + 4);
    final start = pos + 8;
    final end = (start + chunkLength).clamp(start, bytes.length);
    if (_tagAt(bytes, pos, 'MTrk')) {
      final trackEnd = _readTrack(bytes, start, end, notes, events);
      if (trackEnd > length) length = trackEnd;
    }
    pos = start + chunkLength;
  }

  notes.sort((a, b) {
    final c = a.startTick.compareTo(b.startTick);
    return c != 0 ? c : a.pitch.compareTo(b.pitch);
  });
  return MidiFileContent(
    ppq: division,
    notes: notes,
    events: normalizeMidiEvents(events.where((e) => !e.isChannelMode)),
    lengthTicks: length,
  );
}

bool _tagAt(Uint8List bytes, int at, String tag) {
  if (at + 4 > bytes.length) return false;
  for (var i = 0; i < 4; i++) {
    if (bytes[at + i] != tag.codeUnitAt(i)) return false;
  }
  return true;
}

/// Reads one track's events into [notes] and [events]; returns the tick the
/// track ends at.
int _readTrack(Uint8List b, int pos, int end, List<MidiNote> notes,
    List<MidiEvent> events) {
  var tick = 0;
  var running = 0;
  final open = <int, (int, int)>{}; // channel<<8|pitch -> (start, velocity)

  int? varLen() {
    var value = 0;
    for (var i = 0; i < 4; i++) {
      if (pos >= end) return null;
      final c = b[pos++];
      value = (value << 7) | (c & 0x7F);
      if (c & 0x80 == 0) return value;
    }
    return null;
  }

  void close(int key, int at) {
    final on = open.remove(key);
    if (on == null) return;
    notes.add(MidiNote(
      startTick: on.$1,
      lengthTicks: at - on.$1 < 1 ? 1 : at - on.$1,
      pitch: key & 0x7F,
      velocity: on.$2.clamp(1, 127),
      channel: key >> 8,
    ));
  }

  while (pos < end) {
    final delta = varLen();
    if (delta == null || pos >= end) break;
    tick += delta;
    var status = b[pos];
    if (status & 0x80 != 0) {
      pos++;
    } else {
      // Running status: the data byte belongs to the previous status.
      if (running == 0) break;
      status = running;
    }

    if (status == 0xFF) {
      if (pos >= end) break;
      final type = b[pos++];
      final len = varLen();
      if (len == null) break;
      pos += len;
      if (type == 0x2F) break; // end of track
      continue;
    }
    if (status == 0xF0 || status == 0xF7) {
      final len = varLen();
      if (len == null) break;
      pos += len;
      continue;
    }
    if (status >= 0xF0) break; // no other system message belongs in a file

    running = status;
    final type = status & 0xF0;
    final channel = status & 0x0F;
    final oneByte = type == 0xC0 || type == 0xD0;
    if (pos + (oneByte ? 1 : 2) > end) break;
    final d1 = b[pos] & 0x7F;
    final d2 = oneByte ? 0 : b[pos + 1] & 0x7F;
    pos += oneByte ? 1 : 2;

    final key = (channel << 8) | d1;
    if (type == 0x90 && d2 > 0) {
      close(key, tick); // a re-strike ends the note still sounding
      open[key] = (tick, d2);
    } else if (type == 0x80 || type == 0x90) {
      close(key, tick);
    } else if (MidiEventKind.ofStatus(status) case final kind?) {
      events.add(MidiEvent(
        tick: tick,
        kind: kind,
        number: kind == MidiEventKind.controller ||
                kind == MidiEventKind.polyPressure
            ? d1
            : 0,
        value: switch (kind) {
          MidiEventKind.pitchBend => (d2 << 7) | d1,
          MidiEventKind.program || MidiEventKind.channelPressure => d1,
          _ => d2,
        },
        channel: channel,
      ));
    }
  }
  for (final key in [...open.keys]) {
    close(key, tick);
  }
  return tick;
}

/// A file's bytes, or null when it doesn't exist or can't be read — the
/// reader handed to project parsers for the `.mid` files projects reference.
Uint8List? readBytesIfExists(String path) {
  try {
    final file = File(path);
    return file.existsSync() ? file.readAsBytesSync() : null;
  } catch (_) {
    return null;
  }
}
