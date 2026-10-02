import 'dart:convert';
import 'dart:typed_data';

import 'midi_clip.dart';

/// A project's unique MIDI clips as the last extraction read them, kept so
/// they can be listed, played and shared without the project file — on a
/// phone, after the project was archived, or from a Drive restore.
///
/// Stored per project in its own box (see `MidiClipStore`), never on
/// `MusicProject`: the projects box is loaded whole and rewritten on every
/// edit, and note data has no business riding along with a todo tick.
class StoredMidiClips {
  const StoredMidiClips({
    required this.extractedAt,
    required this.clips,
    this.sourceModifiedAt,
  });

  /// When the clips were read. A Drive or backup merge keeps the newer read.
  final DateTime extractedAt;

  /// The project file's modification time at that read, so the page can tell
  /// when the file has changed since and the clips may be stale.
  final DateTime? sourceModifiedAt;

  final List<MidiClip> clips;

  /// For Hive: notes as raw bytes.
  Map<String, dynamic> toMap() => _toMap((bytes) => bytes);

  /// For Drive sync and local backup JSON: notes as base64.
  Map<String, dynamic> toJson() => _toMap(base64Encode);

  Map<String, dynamic> _toMap(Object Function(Uint8List) bytes) => {
        'extractedAt': extractedAt.toIso8601String(),
        if (sourceModifiedAt != null)
          'sourceModifiedAt': sourceModifiedAt!.toIso8601String(),
        'clips': [
          for (final c in clips)
            {
              'name': c.name,
              if (c.trackName != null) 'track': c.trackName,
              'ppq': c.ppq,
              'length': c.lengthTicks,
              'occurrences': c.occurrences,
              if (c.otherNames.isNotEmpty) 'otherNames': c.otherNames,
              'notes': bytes(packMidiNotes(c.notes)),
            },
        ],
      };

  /// Reads either form ([toMap] or [toJson]). Null when [value] isn't a
  /// readable record at all; a single bad clip is skipped, never the rest.
  static StoredMidiClips? tryParse(Object? value) {
    if (value is! Map) return null;
    final extractedAt = DateTime.tryParse(value['extractedAt'] as String? ?? '');
    if (extractedAt == null) return null;
    final clips = <MidiClip>[];
    for (final raw in (value['clips'] as List?) ?? const []) {
      if (raw is! Map) continue;
      try {
        final notesRaw = raw['notes'];
        final Uint8List notesBytes = notesRaw is String
            ? base64Decode(notesRaw)
            : notesRaw is Uint8List
                ? notesRaw
                : Uint8List.fromList((notesRaw as List).cast<int>());
        final ppq = (raw['ppq'] as num).toInt();
        final length = (raw['length'] as num).toInt();
        if (ppq <= 0 || length < 0) continue;
        clips.add(MidiClip(
          name: raw['name'] as String? ?? '',
          trackName: raw['track'] as String?,
          ppq: ppq,
          lengthTicks: length,
          occurrences: (raw['occurrences'] as num?)?.toInt() ?? 1,
          otherNames: [
            for (final n in (raw['otherNames'] as List?) ?? const [])
              if (n is String) n,
          ],
          notes: unpackMidiNotes(notesBytes),
        ));
      } catch (_) {
        continue;
      }
    }
    return StoredMidiClips(
      extractedAt: extractedAt,
      sourceModifiedAt:
          DateTime.tryParse(value['sourceModifiedAt'] as String? ?? ''),
      clips: clips,
    );
  }

  /// Whether the project file has been modified since these clips were read.
  /// False when either time is unknown — nothing to warn about then.
  bool isStaleFor(DateTime? fileModifiedAt) =>
      sourceModifiedAt != null &&
      fileModifiedAt != null &&
      fileModifiedAt.isAfter(sourceModifiedAt!);
}

const _packVersion = 1;

/// Notes as compact bytes: a version byte, then per note — sorted by start —
/// unsigned LEB128 varints for the start delta from the previous note and the
/// length, then pitch, velocity and channel bytes. Typically 6–8 bytes a
/// note, a fraction of the JSON it replaces.
Uint8List packMidiNotes(List<MidiNote> notes) {
  final sorted = [...notes]..sort((a, b) {
      final c = a.startTick.compareTo(b.startTick);
      return c != 0 ? c : a.pitch.compareTo(b.pitch);
    });
  final out = BytesBuilder()..addByte(_packVersion);
  void varint(int v) {
    var x = v < 0 ? 0 : v;
    while (x >= 0x80) {
      out.addByte((x & 0x7F) | 0x80);
      x >>= 7;
    }
    out.addByte(x);
  }

  var previous = 0;
  for (final n in sorted) {
    final start = n.startTick < 0 ? 0 : n.startTick;
    varint(start - previous);
    varint(n.lengthTicks);
    out
      ..addByte(n.pitch & 0x7F)
      ..addByte(n.velocity & 0x7F)
      ..addByte(n.channel & 0x0F);
    previous = start;
  }
  return out.toBytes();
}

/// Reverses [packMidiNotes]. Stops at the first truncated note rather than
/// throwing, so a damaged record still yields what it can.
List<MidiNote> unpackMidiNotes(Uint8List bytes) {
  if (bytes.isEmpty || bytes[0] != _packVersion) return const [];
  final notes = <MidiNote>[];
  var pos = 1;
  int? varint() {
    var result = 0, shift = 0;
    while (pos < bytes.length) {
      final b = bytes[pos++];
      result |= (b & 0x7F) << shift;
      if (b & 0x80 == 0) return result;
      shift += 7;
      if (shift > 35) return null;
    }
    return null;
  }

  var start = 0;
  while (pos < bytes.length) {
    final delta = varint();
    final length = varint();
    if (delta == null || length == null || pos + 3 > bytes.length) break;
    start += delta;
    notes.add(MidiNote(
      startTick: start,
      lengthTicks: length,
      pitch: bytes[pos],
      velocity: bytes[pos + 1],
      channel: bytes[pos + 2],
    ));
    pos += 3;
  }
  return notes;
}
