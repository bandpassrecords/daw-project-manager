import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../models/midi_clip.dart';
import '../daw_parsers/ableton_project_parser.dart';
import '../daw_parsers/cubase_project_parser.dart';
import '../daw_parsers/flp_project_parser.dart';
import '../daw_parsers/reaper_project_parser.dart';
import 'midi_clip_synth.dart';
import 'midi_file_writer.dart';
import 'synth_voice.dart';

/// Reads MIDI clips out of project files on demand, and turns them into
/// things the rest of the app can use: `.mid` files and audible previews.
///
/// Clips are never stored on the project — they are re-read from the file
/// each time, off the UI isolate. The project file is the source of truth,
/// and note data for a big session runs to megabytes.
class MidiClipService {
  const MidiClipService._();

  static const _extensions = {'.cpr', '.npr', '.als', '.alp', '.rpp', '.flp'};

  /// Whether clips can be read from this project's DAW format.
  static bool supports(String filePath) =>
      _extensions.contains(p.extension(filePath).toLowerCase());

  static Future<List<MidiClip>> readClips(String filePath) =>
      Isolate.run(() => readClipsSync(filePath));

  /// The synchronous body of [readClips], public for tests.
  static List<MidiClip> readClipsSync(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return const [];
    switch (p.extension(filePath).toLowerCase()) {
      case '.cpr':
      case '.npr':
        final parser = CubaseProjectParser(file.readAsBytesSync());
        return parser.isCubaseFile ? parser.readMidiClips() : const [];
      case '.als':
      case '.alp':
        final bytes = file.readAsBytesSync();
        List<int> xml;
        try {
          xml = gzip.decode(bytes);
        } catch (_) {
          xml = bytes; // very old sets are plain XML
        }
        final doc = XmlDocument.parse(utf8.decode(xml, allowMalformed: true));
        return AbletonProjectParser(doc).readMidiClips();
      case '.rpp':
        return ReaperProjectParser(file.readAsStringSync()).readMidiClips();
      case '.flp':
        return FlpProjectParser(file.readAsBytesSync()).readMidiClips();
    }
    return const [];
  }

  /// Renders [clip] with [voice] to a WAV in [directory] and returns its
  /// path. Reuses an earlier render of the same clip, tempo and voice.
  static Future<String> renderPreview(
    MidiClip clip, {
    double? bpm,
    SynthVoice voice = SynthVoice.synth,
    required Directory directory,
  }) async {
    final name = 'preview_${_fnv1a(clip.contentKey)}'
        '_${(bpm ?? 120).toStringAsFixed(2)}_${voice.name}.wav';
    final out = File(p.join(directory.path, name));
    if (await out.exists()) return out.path;
    final bytes = await Isolate.run(
        () => const MidiClipSynth().renderWav(clip, bpm: bpm, voice: voice));
    await directory.create(recursive: true);
    await out.writeAsBytes(bytes, flush: true);
    return out.path;
  }

  /// Writes [clip] as a `.mid` file at [path].
  static Future<File> writeMidiFile(MidiClip clip, String path, {double? bpm}) =>
      File(path).writeAsBytes(encodeMidiClip(clip, bpm: bpm), flush: true);

  /// Writes every clip into [directory] with unique, filesystem-safe names.
  /// Returns the files written.
  static Future<List<File>> exportAll(
    List<MidiClip> clips,
    Directory directory, {
    double? bpm,
  }) async {
    await directory.create(recursive: true);
    final names = uniqueFileNames(clips.map(midiClipFileName).toList());
    final written = <File>[];
    for (var i = 0; i < clips.length; i++) {
      written.add(await writeMidiFile(
        clips[i],
        p.join(directory.path, names[i]),
        bpm: bpm,
      ));
    }
    return written;
  }

  /// Stable across runs, unlike `String.hashCode`, so the preview cache
  /// survives a restart.
  static String _fnv1a(String s) {
    var hash = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
