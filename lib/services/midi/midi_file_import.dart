import 'dart:typed_data';

import '../../models/midi_clip.dart';
import '../../utils/musical_key.dart';
import 'midi_file_reader.dart';

/// What importing one `.mid` file gives: its clips, and the tempo and key it
/// declares, so the clips play and export the way the file meant them.
class ImportedMidiFile {
  const ImportedMidiFile({
    required this.fileName,
    required this.clips,
    this.bpm,
    this.musicalKey,
  });

  final String fileName;

  /// Empty when the file holds no notes.
  final List<MidiClip> clips;
  final double? bpm;

  /// The file's key signature as a name ("A minor"), or null.
  final String? musicalKey;
}

/// Turns a `.mid` file from outside any project into clips for a
/// collection. Null when [bytes] isn't a readable MIDI file.
///
/// A file whose notes are on one track is one clip, named after the file
/// (the track's name, if it has one, as the clip's track). A file with
/// several tracks of notes — a whole arrangement exported from a DAW — is
/// one clip per track, named after the track and grouped under the file,
/// rather than every part mashed into one. Tracks without notes (a tempo
/// track, a conductor track) are left out.
///
/// Clips are taken as they are: every one keeps the whole file's length,
/// so the parts stay lined up, and nothing is shrunk to a repeating
/// pattern — what was imported is what comes back out.
ImportedMidiFile? importMidiFile(Uint8List bytes, String fileName) {
  final file = decodeMidiFileTracks(bytes);
  if (file == null) return null;
  final stem = _stem(fileName);
  final withNotes = [for (final t in file.tracks) if (t.notes.isNotEmpty) t];
  final length = file.lengthTicks;

  MidiClip clip(MidiFileTrack t, {required String name, String? track}) =>
      MidiClip(
        name: name,
        trackName: track == null || track.isEmpty || track == name ? null : track,
        ppq: file.ppq,
        lengthTicks: length > 0 ? length : t.lengthTicks,
        notes: t.notes,
        events: t.events,
      );

  final clips = withNotes.length == 1
      ? [clip(withNotes.single, name: stem, track: withNotes.single.name)]
      : [
          for (var i = 0; i < withNotes.length; i++)
            clip(
              withNotes[i],
              name: withNotes[i].name.isNotEmpty
                  ? withNotes[i].name
                  : '$stem ${i + 1}',
              track: stem,
            ),
        ];

  final signature = file.keySignature;
  return ImportedMidiFile(
    fileName: fileName,
    clips: clips,
    bpm: file.bpm,
    musicalKey: signature == null ? null : keyNameOf(signature),
  );
}

String _stem(String fileName) {
  final base = fileName.split(RegExp(r'[\\/]')).last;
  final dot = base.lastIndexOf('.');
  final stem = (dot > 0 ? base.substring(0, dot) : base).trim();
  return stem.isEmpty ? 'MIDI' : stem;
}
