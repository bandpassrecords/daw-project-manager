import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../models/midi_clip.dart';
import '../../utils/musical_key.dart';

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

/// One track of a Standard MIDI File: its name (the track-name meta event,
/// empty when it has none) and what it plays.
class MidiFileTrack {
  const MidiFileTrack({
    required this.name,
    required this.notes,
    required this.events,
    required this.lengthTicks,
  });

  final String name;
  final List<MidiNote> notes;
  final List<MidiEvent> events;
  final int lengthTicks;
}

/// A Standard MIDI File track by track, with the tempo and key it opens
/// with.
class MidiFileTracks {
  const MidiFileTracks({
    required this.ppq,
    required this.tracks,
    this.bpm,
    this.keySignature,
  });

  final int ppq;
  final List<MidiFileTrack> tracks;

  /// From the first tempo event; null when the file sets none.
  final double? bpm;

  /// From the first key-signature event; null when the file sets none.
  final MidiKeySignature? keySignature;

  /// The end of the longest track.
  int get lengthTicks =>
      tracks.fold(0, (m, t) => t.lengthTicks > m ? t.lengthTicks : m);
}

/// Reads a Standard MIDI File (format 0 or 1) track by track. Notes stay in
/// ticks, which is what a clip is measured in; of the meta events only the
/// track names and the first tempo and key signature are kept. Null for
/// anything that isn't a readable SMF, and for SMPTE-timed files, which
/// have no PPQ.
///
/// Like the project readers it is forgiving: a truncated track keeps the
/// notes read before the cut, and a note never released ends with its
/// track. Channel-mode messages (All Notes Off…) are dropped.
MidiFileTracks? decodeMidiFileTracks(Uint8List bytes) {
  if (bytes.length < 14 || !_tagAt(bytes, 0, 'MThd')) return null;
  final d = ByteData.sublistView(bytes);
  final headerLength = d.getUint32(4);
  final division = d.getUint16(12);
  if (division & 0x8000 != 0 || division == 0) return null;

  final tracks = <MidiFileTrack>[];
  final meta = _FileMeta();
  var pos = 8 + headerLength;
  while (pos + 8 <= bytes.length) {
    final chunkLength = d.getUint32(pos + 4);
    final start = pos + 8;
    final end = (start + chunkLength).clamp(start, bytes.length);
    if (_tagAt(bytes, pos, 'MTrk')) {
      final notes = <MidiNote>[];
      final events = <MidiEvent>[];
      final trackMeta = _TrackMeta();
      final trackEnd =
          _readTrack(bytes, start, end, notes, events, trackMeta, meta);
      notes.sort((a, b) {
        final c = a.startTick.compareTo(b.startTick);
        return c != 0 ? c : a.pitch.compareTo(b.pitch);
      });
      tracks.add(MidiFileTrack(
        name: trackMeta.name,
        notes: notes,
        events: normalizeMidiEvents(events.where((e) => !e.isChannelMode)),
        lengthTicks: trackEnd,
      ));
    }
    pos = start + chunkLength;
  }

  final micros = meta.microsPerQuarter;
  return MidiFileTracks(
    ppq: division,
    tracks: tracks,
    bpm: micros == null || micros <= 0 ? null : 60000000 / micros,
    keySignature: meta.keySignature,
  );
}

/// Reads a Standard MIDI File as one stream: the tracks of a format-1 file
/// merged, as a DAW importing it onto one track would. See
/// [decodeMidiFileTracks].
MidiFileContent? decodeMidiFile(Uint8List bytes) {
  final file = decodeMidiFileTracks(bytes);
  if (file == null) return null;
  final notes = [for (final t in file.tracks) ...t.notes]..sort((a, b) {
      final c = a.startTick.compareTo(b.startTick);
      return c != 0 ? c : a.pitch.compareTo(b.pitch);
    });
  return MidiFileContent(
    ppq: file.ppq,
    notes: notes,
    events: normalizeMidiEvents([for (final t in file.tracks) ...t.events]),
    lengthTicks: file.lengthTicks,
  );
}

class _TrackMeta {
  String name = '';
}

class _FileMeta {
  int? microsPerQuarter;
  MidiKeySignature? keySignature;
}

bool _tagAt(Uint8List bytes, int at, String tag) {
  if (at + 4 > bytes.length) return false;
  for (var i = 0; i < 4; i++) {
    if (bytes[at + i] != tag.codeUnitAt(i)) return false;
  }
  return true;
}

/// Reads one track's events into [notes] and [events], its name into
/// [track], and the file's first tempo and key into [file]; returns the tick
/// the track ends at.
int _readTrack(Uint8List b, int pos, int end, List<MidiNote> notes,
    List<MidiEvent> events, _TrackMeta track, _FileMeta file) {
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
      if (len == null || pos + len > end) break;
      if (type == 0x03 && track.name.isEmpty) {
        track.name = utf8
            .decode(b.sublist(pos, pos + len), allowMalformed: true)
            .replaceAll('\u0000', '')
            .trim();
      } else if (type == 0x51 && len == 3 && file.microsPerQuarter == null) {
        file.microsPerQuarter = (b[pos] << 16) | (b[pos + 1] << 8) | b[pos + 2];
      } else if (type == 0x59 && len == 2 && file.keySignature == null) {
        final sharps = b[pos] >= 128 ? b[pos] - 256 : b[pos];
        if (sharps >= -7 && sharps <= 7) {
          file.keySignature = MidiKeySignature(sharps, minor: b[pos + 1] == 1);
        }
      }
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
