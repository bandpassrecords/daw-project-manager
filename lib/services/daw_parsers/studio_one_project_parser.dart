import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../../models/project_stats.dart';

/// What [StudioOneProjectParser] can read from a `.song`.
class StudioOneProjectInfo {
  const StudioOneProjectInfo({this.bpm, this.dawVersion, this.stats});
  final double? bpm;
  final String? dawVersion;
  final ProjectStats? stats;
}

/// Reads tempo, version and track counts out of a Studio One `.song`.
///
/// A `.song` is a zip of XML documents:
/// * `metainfo.xml` — `<Attribute id="Media:Tempo" value="…"/>` and
///   `id="Document:Generator"` (`"Studio One/6.5.1.96553"`).
/// * `Song/song.xml` — the track list: `MediaTrack` elements whose
///   `mediaType` is `Audio` or `Music` (instrument tracks), and
///   `FolderTrack`s.
/// * `Devices/audiomixer.xml` — bus and FX channels (`AudioBusChannel`,
///   `AudioEffectChannel`).
///
/// Implemented from the format's public descriptions, without a real file
/// to check against, so every read is defensive: a missing entry or an
/// unexpected shape costs that one value, never the others. Plug-ins and
/// MIDI clips aren't read yet.
class StudioOneProjectParser {
  StudioOneProjectParser(this.bytes);

  final Uint8List bytes;

  StudioOneProjectInfo read() {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return const StudioOneProjectInfo();
    }

    XmlDocument? doc(String path) {
      final file = archive.findFile(path);
      if (file == null) return null;
      try {
        return XmlDocument.parse(utf8.decode(file.content, allowMalformed: true));
      } catch (_) {
        return null;
      }
    }

    double? bpm;
    String? version;
    final meta = doc('metainfo.xml');
    if (meta != null) {
      for (final a in meta.findAllElements('Attribute')) {
        final id = a.getAttribute('id');
        final value = a.getAttribute('value');
        if (value == null) continue;
        if (id == 'Media:Tempo') {
          final v = double.tryParse(value);
          if (v != null && v > 0 && v < 1000) bpm = v;
        } else if (id == 'Document:Generator') {
          final m = RegExp(r'(\d+)\.(\d+)').firstMatch(value);
          if (m != null) version = '${m.group(1)}.${m.group(2)}';
        }
      }
    }

    ProjectStats? stats;
    final song = doc('Song/song.xml');
    if (song != null) {
      var audio = 0, instrument = 0, folder = 0, bus = 0;
      for (final e in song.descendantElements) {
        switch (e.name.local) {
          case 'MediaTrack':
            switch (e.getAttribute('mediaType')) {
              case 'Audio':
                audio++;
              case 'Music':
                instrument++;
            }
          case 'FolderTrack':
            folder++;
        }
      }
      final mixer = doc('Devices/audiomixer.xml');
      if (mixer != null) {
        for (final e in mixer.descendantElements) {
          final n = e.name.local;
          if (n == 'AudioBusChannel' || n == 'AudioEffectChannel') bus++;
        }
      }
      stats = ProjectStats(
        audioTracks: audio,
        instrumentTracks: instrument,
        folderTracks: folder,
        busTracks: bus,
      );
    }

    return StudioOneProjectInfo(bpm: bpm, dawVersion: version, stats: stats);
  }
}
