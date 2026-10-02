import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../models/midi_clip.dart';
import '../models/project_marker.dart';
import '../models/project_stats.dart';
import 'daw_parsers/ableton_project_parser.dart';
import 'daw_parsers/cubase_project_parser.dart';
import 'daw_parsers/flp_project_parser.dart';
import 'daw_parsers/reaper_project_parser.dart';
import 'daw_parsers/studio_one_project_parser.dart';

/// Represents a scale pair (root note and scale type)
class _ScalePair {
  final int root;
  final int name;

  _ScalePair(this.root, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ScalePair &&
          runtimeType == other.runtimeType &&
          root == other.root &&
          name == other.name;

  @override
  int get hashCode => root.hashCode ^ name.hashCode;
}

/// One parsed `MARKER` line, before region halves are paired up.
class _RawMarker {
  const _RawMarker({
    required this.index,
    required this.position,
    required this.name,
    required this.isRegion,
    required this.hidden,
  });

  final int index;
  final double position;
  final String name;
  final bool isRegion;
  final bool hidden;
}

class ProjectMetadata {
  final double? bpm;
  final String? key;
  final String? dawType;
  final String? dawVersion;
  final String? projectNotes;

  /// Timeline markers and regions read out of the project file.
  ///
  /// Null and empty mean different things on purpose. Null is "this extractor
  /// didn't look" — a lightweight scan, a DAW with no marker support, or a
  /// parse that threw — and callers must keep whatever they already had. An
  /// empty list is "we parsed the file and it has none", which must overwrite,
  /// or markers deleted in the DAW would live on in the app forever.
  final List<ProjectMarker>? markers;

  /// Track counts, plug-ins and MIDI clip count. Same null contract as
  /// [markers]: null means "didn't look", and callers keep what they had.
  final ProjectStats? stats;

  /// The project's unique MIDI clips, read in the same pass as [stats]. Null
  /// when this extraction didn't read clips (lightweight scan, a DAW without
  /// a clip reader, a parse failure); empty when it read them and found none.
  final List<MidiClip>? midiClips;

  ProjectMetadata({
    this.bpm,
    this.key,
    this.dawType,
    this.dawVersion,
    this.projectNotes,
    this.markers,
    this.stats,
    this.midiClips,
  });
}

class MetadataExtractor {
  /// Extensions for which [extractMetadata] actually parses the project
  /// file for BPM/key/version instead of just returning nulls.
  static const _fullExtractionExtensions = {
    '.als',
    '.alp',
    '.cpr',
    '.npr',
    '.bwproject',
    '.rpp',
    '.mgd',
    '.flp',
    '.logicx',
    '.song',
  };

  /// Whether [extractMetadata] has a real implementation for this project's
  /// DAW, as opposed to just returning nulls. Used to disable "Extract
  /// Metadata" UI for DAWs we can't yet parse.
  static bool supportsFullExtraction(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return _fullExtractionExtensions.contains(ext);
  }

  /// Extracts lightweight metadata (DAW type only) - fast, no file parsing
  static Future<ProjectMetadata> extractLightweightMetadata(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    final dawType = _getDawTypeFromExtension(ext);
    
    return ProjectMetadata(
      bpm: null,
      key: null,
      dawType: dawType,
      dawVersion: null,
    );
  }

  /// Extracts full metadata from a project file (BPM, key, DAW version)
  static Future<ProjectMetadata> extractMetadata(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    final projectDir = File(filePath).parent;
    
    // Determine DAW type from extension
    final dawType = _getDawTypeFromExtension(ext);
    
    double? bpm;
    String? key;
    String? dawVersion;
    String? projectNotes;
    List<ProjectMarker>? markers;
    ProjectStats? stats;
    List<MidiClip>? midiClips;

    // Try to extract from project file first
    if (ext == '.als' || ext == '.alp') {
      final metadata = await _extractFromAbletonFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
      stats = metadata.stats;
      midiClips = metadata.midiClips;
    } else if (ext == '.cpr' || ext == '.npr') {
      // Nuendo uses similar format to Cubase
      final metadata = await _extractFromCubaseFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
      projectNotes = metadata.projectNotes;
      stats = metadata.stats;
      midiClips = metadata.midiClips;
    } else if (ext == '.song') {
      final metadata = await _extractFromStudioOneFile(filePath);
      bpm = metadata.bpm ?? bpm;
      dawVersion = metadata.dawVersion ?? dawVersion;
      stats = metadata.stats;
    } else if (ext == '.bwproject') {
      final metadata = await _extractFromBitwigFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
    } else if (ext == '.rpp') {
      final metadata = await _extractFromReaperFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
      projectNotes = metadata.projectNotes;
      markers = metadata.markers;
      stats = metadata.stats;
      midiClips = metadata.midiClips;
    } else if (ext == '.mgd') {
      final metadata = await _extractFromMagdaFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
    } else if (ext == '.flp') {
      final metadata = await _extractFromFlpFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
      stats = metadata.stats;
      midiClips = metadata.midiClips;
    } else if (ext == '.logicx') {
      final metadata = await _extractFromLogicFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
    }

    // Also search for bpm and key files in the project directory, but only
    // use them as a last resort when the project file itself did not supply a value.
    if (bpm == null) {
      final bpmFromFile = await _searchForBpmFile(projectDir.path);
      if (bpmFromFile != null) {
        bpm = bpmFromFile;
      }
    }

    if (key == null) {
      final keyFromFile = await _searchForKeyFile(projectDir.path);
      if (keyFromFile != null) {
        key = keyFromFile;
      }
    }

    return ProjectMetadata(
      bpm: bpm,
      key: key,
      dawType: dawType,
      dawVersion: dawVersion,
      projectNotes: projectNotes,
      markers: markers,
      stats: stats,
      midiClips: midiClips,
    );
  }

  /// Determines DAW type from a file extension (e.g. `.rpp` -> `'Reaper'`),
  /// without touching the filesystem — useful anywhere a DAW icon/name is
  /// needed for a path that may not exist yet or isn't worth a full extract.
  static String? getDawTypeFromExtension(String ext) => _getDawTypeFromExtension(ext);

  static String? _getDawTypeFromExtension(String ext) {
    switch (ext) {
      case '.als':
      case '.alp':
        return 'Ableton Live';
      case '.bwproject':
        return 'Bitwig Studio';
      case '.cpr':
        return 'Cubase';
      case '.flp':
        return 'FL Studio';
      case '.logicx':
        return 'Logic Pro';
      case '.maschine':
      case '.maschine2':
        return 'Maschine';
      case '.npr':
        return 'Nuendo';
      case '.ptx':
      case '.pts':
        return 'Pro Tools';
      case '.rpp':
        return 'Reaper';
      case '.song':
        return 'Studio One';
      case '.tracktionedit':
      case '.tracktion':
        return 'Waveform';
      case '.cwp':
      case '.wrk':
      case '.bun':
        return 'Sonar';
      case '.luna':
        return 'LUNA';
      case '.mgd':
        return 'MAGDA';
      case '.ardour':
        return 'Ardour';
      case '.band':
        return 'GarageBand';
      case '.xrns':
        return 'Renoise';
      case '.mmp':
      case '.mmpz':
        return 'LMMS';
      case '.aup3':
        return 'Audacity';
      case '.qtr':
        return 'Qtractor';
      case '.rg':
        return 'Rosegarden';
      case '.reason':
      case '.rns':
        return 'Reason';
      case '.dpproj':
        return 'Digital Performer';
      case '.sesx':
        return 'Adobe Audition';
      case '.vip':
        return 'Samplitude / Sequoia';
      case '.acd':
        return 'ACID Pro';
      case '.mx8':
      case '.mx9':
      case '.mx10':
        return 'Mixcraft';
      case '.zpj':
        return 'Zrythm';
      default:
        return null;
    }
  }

  /// Extracts BPM and key from Ableton Live .als file
  /// .als files are gzipped XML files (or uncompressed XML in older versions)
  static Future<ProjectMetadata> _extractFromAbletonFile(String filePath) async {
    if (!await File(filePath).exists()) return ProjectMetadata();
    // A large set decompresses to tens of MB of XML; parsing that on the UI
    // isolate froze the app for over a second per project during a scan.
    try {
      return await Isolate.run(() => _extractFromAbletonFileSync(filePath));
    } catch (_) {
      return ProjectMetadata();
    }
  }

  static ProjectMetadata _extractFromAbletonFileSync(String filePath) {
    try {
      final bytes = File(filePath).readAsBytesSync();
      
      // Try to decompress as gzip first, fallback to direct UTF-8 if it fails
      String xmlString;
      try {
        final decompressed = gzip.decode(bytes);
        xmlString = utf8.decode(decompressed);
      } catch (_) {
        // If gzip decode fails, try reading as plain UTF-8 (older .als files)
        xmlString = utf8.decode(bytes);
      }
      
      // Parse XML
      final document = XmlDocument.parse(xmlString);
      final root = document.rootElement;

      double? bpm;
      String? key;
      String? dawVersion;

      // Extract version from the Creator attribute (e.g., "Ableton Live 12.3")
      // which carries the real major.minor version. MinorVersion (e.g.
      // "12.0_12300") does not reflect the minor release shown in the UI.
      final creator = root.getAttribute('Creator');
      if (creator != null && creator.isNotEmpty) {
        final match = RegExp(r'Live\s+(\d+(?:\.\d+)*)').firstMatch(creator);
        if (match != null) {
          final versionParts = match.group(1)!.split('.');
          dawVersion = versionParts.length >= 2
              ? '${versionParts[0]}.${versionParts[1]}'
              : versionParts[0];
        }
      }

      // Fallback: major version only, from MinorVersion attribute
      if (dawVersion == null) {
        final minorVersion = root.getAttribute('MinorVersion');
        if (minorVersion != null && minorVersion.isNotEmpty) {
          final parts = minorVersion.split('.');
          if (parts.isNotEmpty) {
            dawVersion = parts[0];
          }
        }
      }

      // Extract BPM - look for Tempo element with Manual child
      final tempoElements = root.findAllElements('Tempo');
      if (tempoElements.isNotEmpty) {
        final tempoElement = tempoElements.first;
        // Look for Manual element inside Tempo
        final manualElements = tempoElement.findElements('Manual');
        if (manualElements.isNotEmpty) {
          final manualElement = manualElements.first;
          final tempoValue = manualElement.getAttribute('Value');
          if (tempoValue != null) {
            bpm = double.tryParse(tempoValue);
          }
        }
        // Fallback: try direct Value attribute on Tempo element
        if (bpm == null) {
          final tempoValue = tempoElement.getAttribute('Value');
          if (tempoValue != null) {
            bpm = double.tryParse(tempoValue);
          }
        }
      }

      // Also try ManualTimeSignature element which might have BPM
      if (bpm == null) {
        final timeSigElements = root.findAllElements('ManualTimeSignature');
        for (final element in timeSigElements) {
          final tempoValue = element.getAttribute('Tempo');
          if (tempoValue != null) {
            final parsed = double.tryParse(tempoValue);
            if (parsed != null) {
              bpm = parsed;
              break;
            }
          }
        }
      }

      // Extract key from ScaleInformation elements (iterate over all instances)
      final scaleInfoElements = root.findAllElements('ScaleInformation').toList();
      
      if (scaleInfoElements.isNotEmpty) {
        final scalePairs = <_ScalePair>[];
        
        // Extract Root and Name from each ScaleInformation instance
        for (final scaleInfoElement in scaleInfoElements) {
          // Extract Root note (0-11)
          final rootElements = scaleInfoElement.findElements('Root');
          int? rootValue;
          if (rootElements.isNotEmpty) {
            final rootElement = rootElements.first;
            // Try Value attribute first, then text content
            final rootValueStr = rootElement.getAttribute('Value') ?? rootElement.innerText.trim();
            if (rootValueStr.isNotEmpty) {
              rootValue = int.tryParse(rootValueStr);
            }
          }
          
          // Extract Scale type/Name (0-34)
          final nameElements = scaleInfoElement.findElements('Name');
          int? nameValue;
          if (nameElements.isNotEmpty) {
            final nameElement = nameElements.first;
            // Try Value attribute first, then text content
            final nameValueStr = nameElement.getAttribute('Value') ?? nameElement.innerText.trim();
            if (nameValueStr.isNotEmpty) {
              nameValue = int.tryParse(nameValueStr);
            }
          }
          
          // Only add non-zero pairs (0,0 means C Major default/unset)
          if (rootValue != null && nameValue != null) {
            if (rootValue != 0 || nameValue != 0) {
              scalePairs.add(_ScalePair(rootValue, nameValue));
            }
          }
        }
        
        // Process the collected scale pairs
        if (scalePairs.isNotEmpty) {
          // Get unique pairs
          final uniquePairs = scalePairs.toSet();
          
          if (uniquePairs.length == 1) {
            // All non-zero instances have the same value
            final pair = uniquePairs.first;
            final rootNote = _getRootNote(pair.root);
            final scaleType = _getScaleType(pair.name);
            if (rootNote != null && scaleType != null) {
              key = '$rootNote $scaleType';
            }
          } else {
            // Multiple different values - combine them with commas
            final keyParts = <String>[];
            for (final pair in uniquePairs) {
              final rootNote = _getRootNote(pair.root);
              final scaleType = _getScaleType(pair.name);
              if (rootNote != null && scaleType != null) {
                keyParts.add('$rootNote $scaleType');
              }
            }
            if (keyParts.isNotEmpty) {
              key = keyParts.join(', ');
            }
          }
        }
      }

      // Fallback: look for MusicalKey or KeySignature elements
      if (key == null || key.isEmpty) {
        final keyElements = root.findAllElements('MusicalKey');
        if (keyElements.isNotEmpty) {
          final keyElement = keyElements.first;
          key = keyElement.getAttribute('Value') ?? keyElement.innerText;
        }
      }

      // Try alternative key element names
      if (key == null || key.isEmpty) {
        final keySigElements = root.findAllElements('KeySignature');
        if (keySigElements.isNotEmpty) {
          final keySigElement = keySigElements.first;
          key = keySigElement.getAttribute('Value') ?? keySigElement.innerText;
        }
      }

      // Try to find key in MasterTrack or other common locations
      if (key == null || key.isEmpty) {
        final masterTrack = root.findAllElements('MasterTrack');
        for (final track in masterTrack) {
          final keyAttr = track.getAttribute('MusicalKey') ?? track.getAttribute('Key');
          if (keyAttr != null && keyAttr.isNotEmpty) {
            key = keyAttr;
            break;
          }
        }
      }

      ProjectStats? stats;
      List<MidiClip>? clips;
      try {
        final parser = AbletonProjectParser(document);
        clips = parser.readMidiClips();
        stats = parser
            .readStats(countMidiClips: false)
            .withMidiClipCount(clips.length);
      } catch (_) {
        // Stats are a bonus; never let them cost the tempo and key.
      }

      return ProjectMetadata(
        bpm: bpm,
        key: key?.trim().isEmpty == true ? null : key?.trim(),
        dawVersion: dawVersion,
        stats: stats,
        midiClips: clips,
      );
    } catch (e) {
      // If parsing fails, return empty metadata
      return ProjectMetadata();
    }
  }

  /// Extracts tempo, version and track counts from a Studio One `.song`.
  /// See [StudioOneProjectParser].
  static Future<ProjectMetadata> _extractFromStudioOneFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return ProjectMetadata();
      final bytes = await file.readAsBytes();
      final info = await Isolate.run(() => StudioOneProjectParser(bytes).read());
      return ProjectMetadata(
        bpm: info.bpm,
        dawVersion: info.dawVersion,
        stats: info.stats,
      );
    } catch (_) {
      return ProjectMetadata();
    }
  }

  /// Extracts BPM and version from an FL Studio .flp project file.
  /// .flp files use FL's native "FLhd"/"FLdt" chunk format: a fixed header
  /// chunk followed by a stream of TLV events, keyed by ID range:
  ///   0-63    1-byte value
  ///   64-127  2-byte (word) value
  ///   128-191 4-byte (dword) value
  ///   192-255 variable-length value, prefixed by a base-128 varint length
  /// Verified against real project files spanning FL 7 through FL 20:
  /// event 199 (Version) is the plain-ASCII version string; event 66
  /// (Tempo, word) is the whole-BPM value used before fine tempo existed;
  /// event 156 (FineTempo, dword) is BPM*1000 and is used by newer files
  /// instead. See github.com/jdstmporter/FLPFiles for the wider event ID
  /// catalogue this was cross-checked against.
  static Future<ProjectMetadata> _extractFromFlpFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProjectMetadata();
      }

      final bytes = await file.readAsBytes();
      if (bytes.length < 8 || utf8.decode(bytes.sublist(0, 4)) != 'FLhd') {
        return ProjectMetadata();
      }
      final data = ByteData.sublistView(bytes);
      final headerLength = data.getUint32(4, Endian.little);
      var pos = 8 + headerLength;

      if (pos + 8 > bytes.length || utf8.decode(bytes.sublist(pos, pos + 4)) != 'FLdt') {
        return ProjectMetadata();
      }
      final dataLength = data.getUint32(pos + 4, Endian.little);
      pos += 8;
      final end = (pos + dataLength) > bytes.length ? bytes.length : pos + dataLength;

      String? dawVersion;
      int? tempoWord;
      int? fineTempo;

      while (pos < end) {
        final eventId = bytes[pos];
        pos++;
        if (eventId < 64) {
          if (pos >= end) break;
          pos += 1;
        } else if (eventId < 128) {
          if (pos + 2 > end) break;
          final value = data.getUint16(pos, Endian.little);
          if (eventId == 66) tempoWord = value;
          pos += 2;
        } else if (eventId < 192) {
          if (pos + 4 > end) break;
          final value = data.getUint32(pos, Endian.little);
          if (eventId == 156) fineTempo = value;
          pos += 4;
        } else {
          var length = 0;
          var shift = 0;
          while (true) {
            if (pos >= end) {
              length = -1;
              break;
            }
            final b = bytes[pos];
            pos++;
            length |= (b & 0x7F) << shift;
            if (b & 0x80 == 0) break;
            shift += 7;
          }
          if (length < 0 || pos + length > end) break;
          if (eventId == 199) {
            final raw = bytes.sublist(pos, pos + length);
            final nullIdx = raw.indexOf(0);
            final versionStr = utf8.decode(nullIdx >= 0 ? raw.sublist(0, nullIdx) : raw);
            if (versionStr.isNotEmpty) {
              final parts = versionStr.split('.');
              dawVersion = parts.length >= 2 ? '${parts[0]}.${parts[1]}' : parts[0];
            }
          }
          pos += length;
        }
      }

      final bpm = fineTempo != null ? fineTempo / 1000.0 : tempoWord?.toDouble();

      ProjectStats? stats;
      List<MidiClip>? clips;
      try {
        final parser = FlpProjectParser(bytes);
        clips = parser.readMidiClips();
        stats = parser
            .readStats(countMidiClips: false)
            .withMidiClipCount(clips.length);
      } catch (_) {
        // Stats are a bonus; never let them cost the tempo and version.
      }

      return ProjectMetadata(
        bpm: bpm,
        dawVersion: dawVersion,
        stats: stats,
        midiClips: clips,
      );
    } catch (e) {
      return ProjectMetadata();
    }
  }

  /// Note names indexed by an integer [SongKey], for the rare Logic project
  /// that stores the key as a number rather than the usual `"C"` string.
  static const _logicKeyNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Extracts BPM, key and the app version from a Logic Pro `.logicx`
  /// project. `.logicx` is a macOS package *bundle* (a directory), so
  /// [logicxPath] points at the folder, not a file:
  ///
  /// - `Alternatives/000/MetaData.plist` → `BeatsPerMinute`, `SongKey` +
  ///   `SongGenderKey` ("major"/"minor").
  /// - `Resources/ProjectInformation.plist` → `LastSavedFrom`, e.g.
  ///   `"Logic Pro Creator Studio 12.3.1 (6682)"`.
  ///
  /// Both are Apple property lists (normally binary), read via `plutil`.
  /// Logic Pro is macOS-only, so that tool is always present there; a
  /// `.logicx` synced to another OS just yields nothing, like any DAW we
  /// can't parse yet.
  static Future<ProjectMetadata> _extractFromLogicFile(String logicxPath) async {
    if (!Platform.isMacOS) return ProjectMetadata();
    try {
      double? bpm;
      String? key;
      String? dawVersion;

      final meta = await _readApplePlist(
        p.join(logicxPath, 'Alternatives', '000', 'MetaData.plist'),
      );
      if (meta != null) {
        final rawBpm = meta['BeatsPerMinute'];
        if (rawBpm is num && rawBpm > 0) bpm = rawBpm.toDouble();

        final rawKey = meta['SongKey'];
        String? note;
        if (rawKey is String && rawKey.trim().isNotEmpty) {
          note = rawKey.trim();
        } else if (rawKey is int &&
            rawKey >= 0 &&
            rawKey < _logicKeyNotes.length) {
          note = _logicKeyNotes[rawKey];
        }
        if (note != null) {
          final minor =
              (meta['SongGenderKey'] as String?)?.toLowerCase() == 'minor';
          key = '$note ${minor ? 'minor' : 'major'}';
        }
      }

      final info = await _readApplePlist(
        p.join(logicxPath, 'Resources', 'ProjectInformation.plist'),
      );
      final lastSavedFrom = info?['LastSavedFrom'];
      if (lastSavedFrom is String && lastSavedFrom.isNotEmpty) {
        // "Logic Pro Creator Studio 12.3.1 (6682)" -> "12.3.1"
        final m = RegExp(r'\d+(?:\.\d+){1,2}').firstMatch(lastSavedFrom);
        dawVersion = m?.group(0) ?? lastSavedFrom.trim();
      }

      return ProjectMetadata(bpm: bpm, key: key, dawVersion: dawVersion);
    } catch (e) {
      return ProjectMetadata();
    }
  }

  /// Reads an Apple property list at [path] into a map by shelling out to
  /// `plutil -convert json`. Returns null if the file is missing, `plutil`
  /// is unavailable (non-macOS), or the result isn't a JSON object.
  static Future<Map<String, dynamic>?> _readApplePlist(String path) async {
    try {
      if (!File(path).existsSync()) return null;
      final result = await Process.run(
        'plutil',
        ['-convert', 'json', '-o', '-', path],
      );
      if (result.exitCode != 0) return null;
      final decoded = jsonDecode(result.stdout as String);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Extracts version, BPM, and key signature from a Reaper .rpp project file.
  /// Reaper stores these values in plain-text XML-like tags:
  /// - header: <REAPER_PROJECT 0.1 "7.78/win64" ...>
  /// - tempo: TEMPO 120 4 4 0
  /// - key signature: <KEYSIG 0 11 1 0x4E9>
  static Future<ProjectMetadata> _extractFromReaperFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProjectMetadata();
      }

      final content = await file.readAsString(encoding: utf8);

      String? dawVersion;
      final headerLine = content
          .split(RegExp(r'\r?\n'))
          .firstWhere((line) => line.trim().startsWith('<REAPER_PROJECT'), orElse: () => '');
      if (headerLine.isNotEmpty) {
        final headerMatch = RegExp(r'"([^\"]+)\/').firstMatch(headerLine);
        if (headerMatch != null) {
          final versionString = headerMatch.group(1)?.trim();
          if (versionString != null && versionString.isNotEmpty) {
            dawVersion = versionString;
          }
        }
      }

      double? bpm;
      for (final line in content.split(RegExp(r'\r?\n'))) {
        final trimmed = line.trim();
        final tempoMatch = RegExp(r'^TEMPO\s+([0-9]+(?:\.[0-9]+)?)\b').firstMatch(trimmed);
        if (tempoMatch != null) {
          final valueToken = tempoMatch.group(1);
          if (valueToken != null) {
            final parsed = double.tryParse(valueToken);
            if (parsed != null && parsed > 0 && parsed < 1000) {
              bpm = parsed;
              break;
            }
          }
        }
      }

      String? key;
      final keyStart = content.indexOf('<KEYSIG');
      if (keyStart >= 0) {
        final keyEnd = content.indexOf('>', keyStart);
        if (keyEnd > keyStart) {
          final keyBlock = content.substring(keyStart, keyEnd + 1);
          final keyTokens = keyBlock
              .split(RegExp(r'\s+'))
              .where((token) => token.isNotEmpty)
              .toList();

          if (keyTokens.length >= 5) {
            final rootIndex = int.tryParse(keyTokens[2]);
            final accidental = int.tryParse(keyTokens[3]);
            final scaleValue = int.tryParse(keyTokens[4].replaceFirst('0x', ''), radix: 16);
            final scaleName = scaleValue != null ? _scaleMasks[scaleValue] : null;
            if (rootIndex != null && accidental != null && scaleName != null) {
              final rootNote = _getReaperRootNote(rootIndex, accidental: accidental);
              if (rootNote != null) {
                key = '$rootNote $scaleName';
              }
            }
          }
        }
      }

      final projectNotes = _extractReaperNotes(content);
      final markers = extractReaperMarkers(content);
      ProjectStats? stats;
      List<MidiClip>? clips;
      try {
        (stats, clips) = await Isolate.run(() {
          final parser = ReaperProjectParser(content);
          final clips = parser.readMidiClips();
          return (
            parser.readStats(countMidiClips: false).withMidiClipCount(clips.length),
            clips,
          );
        });
      } catch (_) {
        // Stats are a bonus; never let them cost the rest.
      }

      return ProjectMetadata(
        bpm: bpm,
        key: key,
        dawVersion: dawVersion,
        projectNotes: projectNotes,
        markers: markers,
        stats: stats,
        midiClips: clips,
      );
    } catch (_) {
      return ProjectMetadata();
    }
  }

  /// Extracts Reaper's project notes tab (Title/Author/Notes) into a single
  /// display string. Reaper stores these as:
  ///   TITLE "Notes 1"
  ///   AUTHOR "Audio Crawler"
  ///   NOTES 0 2
  ///     |This is notes of the project
  ///     |
  ///     |Multiple lines
  ///   (closing tag)
  /// Each notes line is prefixed with '|' (possibly after leading
  /// whitespace) — everything after that first '|' is the literal line
  /// content, including blank lines (a bare '|' with nothing after it).
  static String? _extractReaperNotes(String content) {
    String? tagValue(String tag) {
      final match = RegExp('^\\s*$tag\\s+"([^"]*)"', multiLine: true).firstMatch(content);
      final value = match?.group(1)?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    final title = tagValue('TITLE');
    final author = tagValue('AUTHOR');

    String? notesBody;
    final notesStart = content.indexOf('<NOTES');
    if (notesStart >= 0) {
      final lines = const LineSplitter().convert(content.substring(notesStart));
      final noteLines = <String>[];
      for (final line in lines.skip(1)) {
        final pipeIndex = line.indexOf('|');
        if (pipeIndex == -1 || line.substring(0, pipeIndex).trim().isNotEmpty) {
          break;
        }
        noteLines.add(line.substring(pipeIndex + 1));
      }
      if (noteLines.isNotEmpty) {
        final joined = noteLines.join('\n');
        notesBody = joined.trim().isEmpty ? null : joined;
      }
    }

    if (title == null && author == null && notesBody == null) return null;

    // No "by "-style connector word here: this string is written straight
    // into projectNotes, which is persisted to Hive and synced to Drive —
    // baking in an English joining word would leak into every locale's
    // stored data. Extraction runs headlessly during scans (no BuildContext
    // available), so localizing the word isn't an option. An em dash is
    // punctuation, not a word, so it joins title and author on one line
    // without needing translation.
    final buffer = StringBuffer();
    if (title != null && author != null) {
      buffer.writeln('$title — $author');
    } else if (title != null) {
      buffer.writeln(title);
    } else if (author != null) {
      buffer.writeln(author);
    }
    if ((title != null || author != null) && notesBody != null) buffer.writeln();
    if (notesBody != null) buffer.write(notesBody);

    final result = buffer.toString();
    return result.trim().isEmpty ? null : result;
  }

  /// Upper bound on how many markers are kept per project.
  ///
  /// The list is persisted to Hive, written into the local backup file and
  /// uploaded as part of the single Drive sync document, so it is not free —
  /// a post-production session can carry thousands of markers. A thousand is
  /// far past any musical use of the feature while keeping the worst case to
  /// tens of kilobytes per project.
  static const int maxMarkersPerProject = 1000;

  /// Matches one token of a Reaper `MARKER` line: the quoted forms Reaper
  /// picks between (it uses the first of `"`, `'`, `` ` `` the value itself
  /// doesn't contain) plus the bare form it writes for single words.
  static final RegExp _rppToken =
      RegExp('^\\s*(?:"([^"]*)"|\'([^\']*)\'|`([^`]*)`|(\\S+))');

  static final RegExp _rppMarkerLine =
      RegExp(r'^MARKER\s+(\d+)\s+(-?[0-9]+(?:\.[0-9]+)?)\s*(.*)$');

  /// Reads Reaper's project markers and regions out of an `.rpp` state chunk.
  ///
  /// Line syntax (ReaTeam's State Chunk Definitions):
  ///
  ///     MARKER 1 2 "Edit Marker" 8 23514367 1 B {8C98...E6B} 0
  ///             |  |      |      |
  ///             |  |      |      +-- flags: &1 region, &8 selected, &16 hidden
  ///             |  |      +--------- name
  ///             |  +---------------- position, in seconds
  ///             +------------------- index (markers and regions are numbered
  ///                                  in separate sequences)
  ///
  /// A region is a *pair* of lines sharing one index, both with `&1` set; the
  /// second carries the end position and an empty name:
  ///
  ///     MARKER 1 2 "Edit Region" 9 0 1 B {AFD8C34F-4325-2..} 0
  ///     MARKER 1 4 "" 9
  ///
  /// Returns them sorted by position — file order is Reaper's own and is
  /// usually but not reliably chronological.
  ///
  /// Public because it is a pure function of the chunk text: it lets the
  /// parser be tested against fixture strings without writing project files
  /// to disk.
  static List<ProjectMarker> extractReaperMarkers(String content) {
    final points = <ProjectMarker>[];
    // Region halves, keyed by index and held until their partner shows up.
    final openRegions = <int, _RawMarker>{};
    final regions = <ProjectMarker>[];

    for (final rawLine in const LineSplitter().convert(content)) {
      final line = rawLine.trim();
      if (!line.startsWith('MARKER')) continue;

      final raw = _parseReaperMarkerLine(line);
      // A marker hidden in Reaper's ruler was deliberately taken out of view;
      // repeating it here would contradict what the user sees in the DAW.
      if (raw == null || raw.hidden) continue;

      if (!raw.isRegion) {
        points.add(ProjectMarker(
          index: raw.index,
          name: raw.name,
          positionSeconds: raw.position,
        ));
        continue;
      }

      final open = openRegions.remove(raw.index);
      if (open == null) {
        openRegions[raw.index] = raw;
        continue;
      }

      // Don't trust which half came first: take the span they describe, and
      // the name from whichever half actually carries one (Reaper writes it
      // on the opening line and leaves the closing one empty).
      final start = open.position <= raw.position ? open : raw;
      final end = identical(start, open) ? raw : open;
      regions.add(ProjectMarker(
        index: raw.index,
        name: open.name.isNotEmpty ? open.name : raw.name,
        positionSeconds: start.position,
        endSeconds: end.position,
      ));
    }

    // A region whose partner line never appeared — a truncated or hand-edited
    // file. Keeping it as a point marker loses the length but not the place.
    for (final orphan in openRegions.values) {
      points.add(ProjectMarker(
        index: orphan.index,
        name: orphan.name,
        positionSeconds: orphan.position,
      ));
    }

    final all = [...points, ...regions]..sort((a, b) {
        final byPosition = a.positionSeconds.compareTo(b.positionSeconds);
        if (byPosition != 0) return byPosition;
        return a.index.compareTo(b.index);
      });

    return all.length > maxMarkersPerProject
        ? all.sublist(0, maxMarkersPerProject)
        : all;
  }

  /// Parses a single `MARKER` line, or null if it isn't one.
  ///
  /// Reaper always writes the name field, as `""` when empty, so the token
  /// after the position is read as the name unconditionally.
  static _RawMarker? _parseReaperMarkerLine(String line) {
    final match = _rppMarkerLine.firstMatch(line);
    if (match == null) return null;

    final index = int.tryParse(match.group(1)!);
    final position = double.tryParse(match.group(2)!);
    if (index == null || position == null) return null;

    var rest = match.group(3)!;

    var name = '';
    final nameMatch = _rppToken.firstMatch(rest);
    if (nameMatch != null) {
      name = nameMatch.group(1) ??
          nameMatch.group(2) ??
          nameMatch.group(3) ??
          nameMatch.group(4) ??
          '';
      rest = rest.substring(nameMatch.end);
    }

    var flags = 0;
    final flagsMatch = RegExp(r'^\s*(-?\d+)').firstMatch(rest);
    if (flagsMatch != null) {
      flags = int.tryParse(flagsMatch.group(1)!) ?? 0;
    }

    return _RawMarker(
      index: index,
      position: position,
      name: name.trim(),
      isRegion: flags & 1 != 0,
      hidden: flags & 16 != 0,
    );
  }

  /// Extracts version, BPM, and key signature from Bitwig Studio .bwproject file.
  /// The format is a custom binary format with a "BtWg" magic header.
  /// Meta section: key-value pairs where version is under "application_version_name".
  /// BPM: stored as a big-endian IEEE 754 double (type byte 0x07) near the "TEMPO" label.
  /// Key signature: available in Bitwig 6+ via node 0x0001c9:
  ///   - sub-type 0x01 = root note (0=C, 1=Db, ..., 11=B)
  ///   - sub-type 0x02 = scale type as uint16 BE bitmask (bit N = semitone N included),
  ///     looked up in _scaleMasks to identify one of Bitwig's 23 scale types.
  static Future<ProjectMetadata> _extractFromBitwigFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProjectMetadata();
      }

      final bytes = await file.readAsBytes();

      // Validate BtWg magic header
      if (bytes.length < 4 ||
          bytes[0] != 0x42 || bytes[1] != 0x74 ||
          bytes[2] != 0x57 || bytes[3] != 0x67) {
        return ProjectMetadata();
      }

      String? dawVersion;
      double? bpm;
      String? key;

      // === Extract version from meta section ===
      // The key "application_version_name" is followed by: 0x08 [4-byte BE length] [string]
      final versionKey = utf8.encode('application_version_name');
      final versionKeyPos = _findPattern(bytes, versionKey);
      if (versionKeyPos != null) {
        final valueStart = versionKeyPos + versionKey.length;
        if (valueStart + 5 < bytes.length && bytes[valueStart] == 0x08) {
          final strLen = ByteData.sublistView(bytes, valueStart + 1, valueStart + 5)
              .getUint32(0, Endian.big);
          if (strLen > 0 && strLen < 32 && valueStart + 5 + strLen <= bytes.length) {
            final versionStr = utf8.decode(
              bytes.sublist(valueStart + 5, valueStart + 5 + strLen),
            );
            // Store major version only (e.g., "5.3.8" -> "5")
            final parts = versionStr.split('.');
            dawVersion = parts.isNotEmpty ? parts[0].trim() : versionStr;
          }
        }
      }

      // === Extract BPM from TEMPO parameter ===
      // The project structure contains a "TEMPO" label followed within ~200 bytes by
      // a type-0x07 byte and an 8-byte big-endian double holding the BPM value.
      final tempoLabel = utf8.encode('TEMPO');
      final tempoPos = _findPattern(bytes, tempoLabel);
      if (tempoPos != null) {
        final searchEnd = (tempoPos + 200).clamp(0, bytes.length - 8);
        for (int i = tempoPos + tempoLabel.length; i < searchEnd; i++) {
          if (bytes[i] == 0x07 && i + 9 <= bytes.length) {
            final value = ByteData.sublistView(bytes, i + 1, i + 9)
                .getFloat64(0, Endian.big);
            if (value >= 20.0 && value <= 999.0) {
              bpm = double.parse(value.toStringAsFixed(2));
              break;
            }
          }
        }
      }

      // === Extract key signature (Bitwig 6+ only) ===
      // Node 0x0001c9 with sub-type 0x02 holds the scale type as a signed int16 BE.
      // The same node with sub-type 0x01, found just before, holds the root note (0-11).
      // Validated against 13 project files covering all root notes and Major/Minor.
      final scaleNodePattern = <int>[0x00, 0x01, 0xc9, 0x02];
      final rootNodePattern  = <int>[0x00, 0x01, 0xc9, 0x01];
      final scaleNodePos = _findPattern(bytes, scaleNodePattern);
      if (scaleNodePos != null && scaleNodePos + 6 <= bytes.length) {
        // Decode scale type: uint16 BE bitmask, looked up in _scaleMasks
        final rawScale = ByteData.sublistView(bytes, scaleNodePos + 4, scaleNodePos + 6)
            .getUint16(0, Endian.big);
        final scaleName = _scaleMasks[rawScale];

        // Search backward (up to 150 bytes) for the root note node
        int? rootNote;
        for (int i = scaleNodePos - 1; i >= (scaleNodePos - 150).clamp(0, scaleNodePos); i--) {
          if (i + 5 <= bytes.length &&
              bytes[i] == rootNodePattern[0] &&
              bytes[i + 1] == rootNodePattern[1] &&
              bytes[i + 2] == rootNodePattern[2] &&
              bytes[i + 3] == rootNodePattern[3]) {
            final val = bytes[i + 4];
            if (val <= 11) {
              rootNote = val;
              break;
            }
          }
        }

        if (rootNote != null && scaleName != null) {
          final rootNotes = _bitwigMinorSideScales.contains(rawScale)
              ? _bitwigRootNotesMinor
              : _bitwigRootNotesMajor;
          key = '${rootNotes[rootNote]} $scaleName';
        }
      }

      return ProjectMetadata(bpm: bpm, key: key, dawVersion: dawVersion);
    } catch (e) {
      return ProjectMetadata();
    }
  }

  /// Extracts version, BPM, and key signature from a MAGDA .mgd project file.
  /// The file is a single zlib-compressed (RFC 1950) JSON document — the
  /// project's own ProjectSerializer.hpp saves via a gzip/zlib-wrapped
  /// juce::var tree — with top-level `magdaVersion` and a `project` object
  /// holding `tempo`, `keyRoot` (0=C..11=B, -1=none) and `keyQuality`
  /// (0=major, 1=minor). See github.com/Conceptual-Machines/magda-core.
  static Future<ProjectMetadata> _extractFromMagdaFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProjectMetadata();
      }

      final bytes = await file.readAsBytes();
      final decompressed = zlib.decode(bytes);
      final json = jsonDecode(utf8.decode(decompressed)) as Map<String, dynamic>;

      String? dawVersion;
      final magdaVersion = json['magdaVersion'];
      if (magdaVersion is String && magdaVersion.isNotEmpty) {
        // MAGDA is still pre-1.0, so the major version alone ("0") is
        // meaningless — use "major.minor" (e.g. "0.15.0" -> "0.15") instead.
        final parts = magdaVersion.split('.');
        dawVersion = parts.length >= 2 ? '${parts[0]}.${parts[1]}' : parts[0];
      }

      double? bpm;
      String? key;
      final project = json['project'];
      if (project is Map<String, dynamic>) {
        final tempo = project['tempo'];
        if (tempo is num) bpm = tempo.toDouble();

        final keyRoot = project['keyRoot'];
        final keyQuality = project['keyQuality'];
        if (keyRoot is int && keyRoot >= 0) {
          final rootNote = _getRootNote(keyRoot);
          if (rootNote != null) {
            final quality = keyQuality == 1 ? 'Minor' : 'Major';
            key = '$rootNote $quality';
          }
        }
      }

      return ProjectMetadata(bpm: bpm, key: key, dawVersion: dawVersion);
    } catch (e) {
      return ProjectMetadata();
    }
  }

  // Major-side scales use Db and Ab (e.g. "Ab Major", "Db Lydian").
  static const _bitwigRootNotesMajor = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B',
  ];

  // Minor-side scales use C# and G# (e.g. "G# Minor", "C# Dorian").
  // Only indices 1 and 8 differ from the major-side array.
  static const _bitwigRootNotesMinor = [
    'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B',
  ];

  // Scales whose root notes follow the minor-side (C#, G#) spelling convention.
  static const _bitwigMinorSideScales = {
    0x05ad, // Minor
    0x06ad, // Dorian
    0x05ab, // Phrygian
    0x056b, // Locrian
    0x09ad, // Harmonic Minor
    0x0aad, // Jazz Minor
    0x029d, // Blues Major
    0x04e9, // Blues Minor
    0x09b3, // Double Harmonic Major
    0x09cd, // Double Harmonic Minor
    0x056d, // Half-diminished
    0x06db, // Diminished HW
    0x0b6d, // Diminished WH
    0x04a9, // Minor Pentatonic
    0x0089, // Minor Triad
  };

  // Reaper `.reascale` files define scale shapes as a 12-slot pattern where any non-zero
  // position means that semitone slot is active. When those 12 active/inactive slots are
  // converted into a 12-bit binary value, the resulting integer is the same hex mask used
  // by Bitwig and by Reaper's `KEYSIG` block. In other words, the `.reascale` file gives
  // us the same semantic source of truth as Bitwig's scale mask table.
  //
  // Each key is a 12-bit semitone bitmask (bit N = semitone N above C is present). Bitwig
  // only ever sends one of its own 23 scale types (stored as uint16 BE in the .bwproject
  // binary format), but Reaper's `KEYSIG` block can carry any of its ~450 scale/chord
  // patterns, so this table is generated from every "type 0" (scale) entry in
  // ZD-complete.reascale to resolve as many of those as possible.
  //
  // Regenerate by re-running the parser described in that file's header against an updated
  // .reascale, then re-apply the pre-existing curated names below as overrides — several
  // scale/mode names collide on the exact same bitmask (they're the same pitch set under a
  // different name), so first-occurrence-in-file order picks arbitrarily among them; these
  // 23 have been validated against real Bitwig/Reaper project files and take priority.
  static const _scaleMasks = <int, String>{
    0x0007: 'Chromatic TriMirror',
    0x000b: 'Phrygian TriChord',
    0x000d: 'Minor TriChord',
    0x000f: 'Chromatic TetraMirror 1',
    0x0015: 'Do Re Mi',
    0x001b: 'Alternating TetraMirror 1',
    0x001f: 'Chromatic PentaMirror',
    0x002b: 'Phrygian TetraChord',
    0x002d: 'Dorian TetraChord',
    0x002f: 'Blues PentaCluster 3',
    0x0035: 'Major TetraChord 11',
    0x003b: 'Spanish Pentacluster 1',
    0x003f: 'Chromatic HexaMirror all #',
    0x004d: 'Har Minor TetraChord 1',
    0x004f: 'Blues Pentacluster 1',
    0x0055: 'Whole-Tone Tetramirror',
    0x0067: 'Oriental Pentacluster 1',
    0x006b: 'Locrian PentaMirror',
    0x007f: 'Chromatic HeptaMirror',
    0x0089: 'Minor Triad',
    0x0091: 'Major Triad',
    0x0095: 'Eskimo Tetratonic',
    0x00a5: 'Major TetraChord 10',
    0x00ad: 'Minor Pentachord Chad G',
    0x00b5: 'Major Pentachord',
    0x00cb: 'Japanese Pentachord 1',
    0x00d3: 'Balinese Pentachord 1',
    0x00d5: 'Lydian Pentachord',
    0x00ff: 'Chromatic OctaMirror',
    0x0109: 'Major Triad 1',
    0x0111: 'Major Flat 6',
    0x0121: 'Minor Triad 3',
    0x0139: 'Center-Cluster PentaMirror',
    0x0149: 'Major TetraChord 9',
    0x018b: 'Pelog',
    0x018d: 'Hirajoshi',
    0x01a3: 'In',
    0x01a5: 'Han - kumoi',
    0x01c3: 'Indonesian 2 Pentatonic',
    0x01ff: 'Chromatic NonaMirror',
    0x0211: 'Minor Triad 1',
    0x0221: 'Major Triad 3',
    0x0225: 'Sixth TetraChord 2',
    0x0229: 'Major TetraChord 7',
    0x0245: 'Major TetraChord 6',
    0x0249: 'Diminished 7th Chord',
    0x0255: 'Kung',
    0x026b: 'Double-Phrygian Hexatonic',
    0x026d: 'Pyramid Hexatonic',
    0x028d: 'Kumoi Scale',
    0x0291: 'Sixth TetraChord 1',
    0x0293: 'No Name',
    0x0295: 'Major Pentatonic',
    0x029b: 'Blues Dorian Hexatonic 2',
    0x029d: 'Blues Major',
    0x02a1: 'Major TetraChord 4',
    0x02a3: 'Altered Pentatonic',
    0x02a5: 'Yo',
    0x02a9: 'Minor 6th Added',
    0x02b5: 'Scottish Hexatonic Arezzo',
    0x02bd: 'Houseini 1',
    0x02e7: 'Chromatic Hypophrygian',
    0x0333: 'Sixtone Mode 2',
    0x033b: 'Alt Dominant bb7',
    0x0355: 'Eskimo Hexatonic 1',
    0x0357: 'Neapolitan Minor Mode',
    0x035b: 'Ultra Locrian 1',
    0x036b: 'Locrian bb7',
    0x0395: 'Major Bebop Hexatonic',
    0x0397: 'Chromatic Phrygian Inverse',
    0x039d: 'Chromatic Hypodorian 1',
    0x03a7: 'Chromatic Dorian',
    0x03b3: 'Gypsy Hexatonic 5',
    0x03b5: 'Major Bebop Heptatonic',
    0x03ef: 'untitled Nonatonic 1',
    0x03ff: 'Chromatic DecaMirror 1',
    0x0409: 'Ute Tritone 1',
    0x040d: 'Warao Minor TriChord',
    0x0421: 'Sanagari 1',
    0x0425: 'Major  TetraChord 3',
    0x0463: 'Iwato',
    0x046b: 'Honchoshi Plagal Form',
    0x0489: 'Bi Yu',
    0x0491: 'Major TetraChord 1',
    0x0495: 'Dominant Pentatonic',
    0x04a1: 'Genus Primum Inverse',
    0x04a3: 'Kokin-Joshi',
    0x04a5: 'Sus 4 Pentatonic',
    0x04a9: 'Minor Pentatonic',
    0x04ad: 'Minor Hexatonic',
    0x04b1: 'Mixolydian Pentatonic 1',
    0x04d7: 'Chromatic Mixolydian 1',
    0x04e7: 'Chromatic Mixolydian 2',
    0x04e9: 'Blues Minor',
    0x04eb: 'Blues Phrygian 1',
    0x04ed: 'Blues Modified',
    0x04f9: 'Composite Blues',
    0x0509: 'Major  TetraChord 2',
    0x0525: 'Chaio 1',
    0x0529: 'M3 Mj Pentatonic',
    0x052b: 'Ritsu',
    0x054d: 'Takemitsu Tree Line Mod 1',
    0x0553: 'Prometheus Neopolitan',
    0x0555: 'Whole Tone',
    0x055b: 'Alt Dominant',
    0x056b: 'Locrian',
    0x056d: 'Half-diminished',
    0x0573: 'Oriental No1',
    0x0575: 'Major Locrian',
    0x0579: 'Spanish Heptatonic 1',
    0x057b: 'Spanish 8 Tones 1',
    0x059b: 'Phrygian dim 4th',
    0x059d: 'Saba',
    0x05a9: 'Phrygian Hexatonic',
    0x05ab: 'Phrygian',
    0x05ad: 'Minor',
    0x05af: 'Phrygian Aeolian 1',
    0x05b3: 'Mixolydian b9b13',
    0x05b5: 'Mixolydian b13',
    0x05bb: 'Phrygian Major 1',
    0x05cb: 'Spanish Dominant',
    0x05cd: 'Hungarian Gypsy 1',
    0x05d5: 'Lydian Minor',
    0x05eb: 'Phrygian Locrian 1',
    0x0625: 'Oriental Raga Guhamano',
    0x0653: 'Prometheus Neapolitan 2',
    0x0655: 'Prometheus 2',
    0x066b: 'Locrian Nat 6',
    0x066d: 'Dorian b5',
    0x0673: 'Oriental No2',
    0x0675: 'Mixolydian b5',
    0x067b: 'Maqam Shadd\'araban 1',
    0x069d: 'Minor Bebop 1',
    0x06a5: 'Sus 4',
    0x06ab: 'Dorian b2',
    0x06ad: 'Dorian',
    0x06af: 'Adonai Malakh 1',
    0x06b3: 'Mixolydian b9',
    0x06b5: 'Mixolydian',
    0x06b9: 'Rock \'n Roll 1',
    0x06bb: 'JG Octatonic',
    0x06bd: 'Minor Bebop 1',
    0x06cb: 'Todi b7 1',
    0x06cd: 'Dorian #4',
    0x06d3: 'Romanian Major',
    0x06d5: 'Overtone Scale',
    0x06d9: 'Hungarian Major',
    0x06db: 'Diminished HW',
    0x06dd: 'Lydian Dim b7',
    0x06e9: 'Blues Heptatonic',
    0x06ed: 'Blues Octatonic',
    0x06f5: 'Mixolydian Bebop 2',
    0x06f7: 'Youlan 1',
    0x06fb: 'untitled Nonatonic 2',
    0x06fd: 'Blues Enneatonic',
    0x0735: 'Mixolydian Augmented',
    0x0739: 'Chromatic Hypodorian Inv',
    0x0763: 'Gipsy Hexatonic 1',
    0x07ad: 'Dorian Aeolian 1',
    0x07af: 'Chromatic Diatonic Dorian 1',
    0x07bd: 'Houseini 2',
    0x07bf: 'Untitled Decatonic 9',
    0x07ed: 'Kiourdi',
    0x07ef: 'Untitled Decatonic 5',
    0x0869: 'Blues #V',
    0x0891: 'Major TetraChord 2',
    0x08b1: 'Indonesian 3 Pentatonic',
    0x08d1: 'Chinese 6 Pentatonic',
    0x08e9: 'Blues Minor Maj7',
    0x0931: 'Romanian Bacovia 1',
    0x094d: 'Takemitsu Tree Line Mod 2',
    0x0955: 'Eskimo Hexatonic 2',
    0x096d: 'Locrian 2',
    0x0973: 'Persian',
    0x0999: 'Augmented, Messiaen',
    0x09ab: 'Neopolitan Minor',
    0x09ad: 'Harmonic Minor',
    0x09af: 'Harmonic Neapolitan Minor 1',
    0x09b3: 'Double Harmonic Major',
    0x09b5: 'Harmonic Major',
    0x09cb: 'Todi',
    0x09cd: 'Double Harmonic Minor',
    0x09cf: 'Hungarian Minor b2',
    0x09d1: 'Pelog alternate',
    0x09d3: 'Purvi',
    0x09eb: 'Half-Dimiished Bebop',
    0x09ed: 'Algerian',
    0x0a73: 'Chromatic Lydian',
    0x0a8d: 'Hawaiian',
    0x0a95: 'Lydian Hexatonic',
    0x0a99: 'Lydian #2 Hexatonic',
    0x0aab: 'Neopolitan Major',
    0x0aad: 'Jazz Minor',
    0x0ab1: 'Genus Secundum',
    0x0ab3: 'Bhairubahar Thaat',
    0x0ab5: 'Major',
    0x0ab9: 'Houzam',
    0x0abd: 'Dorian Bebop',
    0x0acd: 'Smyrneiko',
    0x0ad3: 'Marva or Marvi',
    0x0ad5: 'Lydian',
    0x0ad9: 'Lydian #9',
    0x0adb: 'Shostakovich 1',
    0x0add: 'Lydian b3',
    0x0af5: 'Japanese',
    0x0b35: 'Ionian Augmented',
    0x0b55: 'Lydian Aug',
    0x0b59: 'Aeolian 2# 4# #5',
    0x0b5b: 'Magen Abot',
    0x0b65: 'Nohkan 1',
    0x0b6d: 'Diminished WH',
    0x0bad: 'Zirafkend',
    0x0bb5: 'Major Bebop',
    0x0bb7: 'Chromatic Permuted Diatonic',
    0x0bbb: 'Genus Chromaticum 1',
    0x0bdf: 'Untitled Decatonic 8',
    0x0bf7: 'Untitled Decatonic 7',
    0x0bfd: 'Pan Lydian',
    0x0c01: 'Flat 6 and 7',
    0x0c49: 'Half Diminished plus b8',
    0x0cb9: 'Chromatic Dorian Inverse',
    0x0ce5: 'Chromatic Mixolydian Inv',
    0x0ce9: 'Blues with Leading Tone',
    0x0d33: 'Enigmatic Descending 1',
    0x0d39: 'Chromatic Phrygian',
    0x0d4b: 'Enigmatic Minor',
    0x0d53: 'Enigmatic Ascending 1',
    0x0d55: 'Leading Wholetone',
    0x0d6b: 'Prokofiev 1',
    0x0d73: 'Enigmatic alternate 1',
    0x0dad: 'Utility Minor 1',
    0x0db3: 'Maqam Hijaz',
    0x0dbb: 'Moorish Phrygian 2',
    0x0dcb: 'Neveseri 1',
    0x0dcd: 'Minor Gypsy',
    0x0dd7: 'Symmetrical Nonatonic 1',
    0x0def: 'Untitled Decatonic 4',
    0x0df7: 'Symmetrical Decatonic',
    0x0dfb: 'Untitled Decatonic 3',
    0x0e73: 'Oriental 2',
    0x0eb5: 'Mixolydian Bebop 1',
    0x0eb7: 'Chromatic Bebop 1',
    0x0ed5: 'Lydian Dominant alternate',
    0x0edf: 'Pan Diminished Blues',
    0x0ef5: 'Lydian Mixolydian 1',
    0x0ef7: 'Untitled Decatonic 6',
    0x0efd: 'Untitled Decatonic 2',
    0x0f7b: 'Untitled Decatonic 3',
    0x0fad: 'Full Minor',
    0x0fbd: 'Untitled Decatonic 1',
  };

  /// Extracts version and BPM from Cubase .cpr file
  /// Version: Looks for hex pattern: 00 10 56 65 72 73 69 6F 6E (which is "00 10 Version")
  /// BPM: Looks for "MusicalTempo" tag followed by "Float" type, then reads 8 bytes as IEEE 754 double
  static Future<ProjectMetadata> _extractFromCubaseFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProjectMetadata();
      }

      // Read file as bytes
      final bytes = await file.readAsBytes();
      
      String? dawVersion;
      double? bpm;
      
      // === Extract DAW Version ===
      // Hex pattern: 00 10 56 65 72 73 69 6F 6E (which is "00 10 Version" in ASCII)
      final versionPattern = [0x00, 0x10, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E];
      
      // Find the pattern in the file
      int? patternIndex;
      for (int i = 0; i <= bytes.length - versionPattern.length; i++) {
        bool found = true;
        for (int j = 0; j < versionPattern.length; j++) {
          if (bytes[i + j] != versionPattern[j]) {
            found = false;
            break;
          }
        }
        if (found) {
          patternIndex = i;
          break;
        }
      }
      
      if (patternIndex != null) {
        // Skip the pattern (9 bytes) and look for version string
        // Version typically starts with a space (0x20) followed by digits and dots
        int versionStart = patternIndex + versionPattern.length;
        
        // Find the start of the version (skip whitespace if any)
        while (versionStart < bytes.length && bytes[versionStart] == 0x20) {
          versionStart++;
        }
        
        // Extract version string until we hit a null byte or non-printable character
        final versionBytes = <int>[];
        for (int i = versionStart; i < bytes.length; i++) {
          final byte = bytes[i];
          // Stop at null byte or non-printable characters (except space, dot, digits)
          if (byte == 0x00 || (byte < 0x20 && byte != 0x09 && byte != 0x0A && byte != 0x0D)) {
            break;
          }
          // Include space, dot, digits, and letters
          if ((byte >= 0x20 && byte <= 0x7E) || byte == 0x09 || byte == 0x0A || byte == 0x0D) {
            versionBytes.add(byte);
          } else {
            break;
          }
        }
        
        if (versionBytes.isNotEmpty) {
          // Convert to string and extract major version
          final versionString = utf8.decode(versionBytes).trim();
          // Extract major version (e.g., "13.0.4" -> "13")
          final parts = versionString.split('.');
          if (parts.isNotEmpty) {
            dawVersion = parts[0].trim();
          }
        }
      }
      
      // === Extract BPM from MusicalTempo metadata ===
      // Cubase stores tempo as a 64-bit double-precision float (IEEE 754, big-endian)
      // The format is: "MusicalTempo" ... "Float" ... [8 bytes of tempo value]
      bpm = _extractCubaseBpm(bytes);
      
      // === Extract Key/Scale from ScaleHelper fields ===
      // Uses "ScaleHelper Root Key" and "ScaleHelper Scale Type" fields
      // which store direct indices for root note and scale type
      String? key = _extractCubaseKey(bytes);
      
      // If pattern matching failed, try to extract from embedded filename
      if (key == null || key.startsWith('Unknown') || key.startsWith('?')) {
        final filenameKey = _extractKeyFromEmbeddedFilename(bytes);
        if (filenameKey != null) {
          key = filenameKey;
        }
      }

      // === Extract Project Notes from the Notepad panel ===
      final projectNotes = _extractCubaseNotes(bytes);

      ProjectStats? stats;
      List<MidiClip>? clips;
      try {
        (stats, clips) = await Isolate.run(() {
          final parser = CubaseProjectParser(bytes);
          if (!parser.isCubaseFile) return (null, null);
          final clips = parser.readMidiClips();
          return (
            parser.readStats(countMidiClips: false).withMidiClipCount(clips.length),
            clips,
          );
        });
      } catch (_) {
        // Stats are a bonus; never let them cost the tempo, key and notes.
      }

      return ProjectMetadata(
        bpm: bpm,
        key: key,
        dawVersion: dawVersion,
        projectNotes: projectNotes,
        stats: stats,
        midiClips: clips,
      );
    } catch (e) {
      // If parsing fails, return empty metadata
      return ProjectMetadata();
    }
  }

  /// Extracts the Project Notes (Notepad) panel text from a Cubase/Nuendo
  /// project file.
  ///
  /// Cubase serializes named attributes as length-prefixed "Pascal strings":
  /// a 4-byte big-endian length (counting the trailing null terminator),
  /// the ASCII name, then a null terminator. The Notepad panel always
  /// writes a `Cursor` attribute (10 bytes: a 2-byte type code plus an
  /// 8-byte cursor-position int) — but only writes the following `Text`
  /// attribute when the notes are non-empty; an empty notepad has no `Text`
  /// key at all, so its absence right after `Cursor` means "no notes", not
  /// a parse failure. When present, `Text` is followed by a 2-byte type
  /// code (0x0008) and a 4-byte big-endian byte length, then that many raw
  /// bytes of the note text (CRLF line breaks; Cubase sometimes pads the
  /// end of the declared length with a stray null byte and a UTF-8 BOM).
  ///
  /// A project can contain many unrelated `Cursor`-bearing panels (per-part
  /// editor state, etc.) that never have a `Text` field, so every `Cursor`
  /// occurrence is checked in turn rather than assuming the first one is
  /// the Notepad. Reverse-engineered against 40+ real Cubase/Nuendo project
  /// files.
  static String? _extractCubaseNotes(Uint8List bytes) {
    try {
      const cursorKey = <int>[
        0x00, 0x00, 0x00, 0x07, // pstring length, incl. null terminator
        0x43, 0x75, 0x72, 0x73, 0x6F, 0x72, // "Cursor"
        0x00,
      ];
      const textKey = <int>[
        0x00, 0x00, 0x00, 0x05, // pstring length, incl. null terminator
        0x54, 0x65, 0x78, 0x74, // "Text"
        0x00,
      ];
      const cursorValueLength = 10;

      var searchStart = 0;
      while (true) {
        final cursorPos = _findPattern(bytes, cursorKey, start: searchStart);
        if (cursorPos == null) return null;

        final textKeyStart = cursorPos + cursorKey.length + cursorValueLength;
        if (_matchesAt(bytes, textKeyStart, textKey)) {
          final headerStart = textKeyStart + textKey.length;
          if (headerStart + 6 > bytes.length) return null;

          final length = ByteData.sublistView(bytes, headerStart + 2, headerStart + 6)
              .getUint32(0, Endian.big);
          final textStart = headerStart + 6;
          if (length <= 0 || textStart + length > bytes.length) return null;

          var text = utf8.decode(
            bytes.sublist(textStart, textStart + length),
            allowMalformed: true,
          );
          text = text
              .replaceAll('﻿', '')
              .replaceAll('\x00', '')
              .replaceAll('\r\n', '\n')
              .trim();
          return text.isEmpty ? null : text;
        }

        searchStart = cursorPos + 1;
      }
    } catch (e) {
      return null;
    }
  }

  /// Extracts BPM from Cubase file by searching for MusicalTempo metadata
  /// The tempo is stored as IEEE 754 64-bit double (big-endian) after the "Float" type indicator
  static double? _extractCubaseBpm(Uint8List bytes) {
    try {
      // Search for "MusicalTempo" string in the binary file
      final musicalTempoTag = utf8.encode('MusicalTempo');
      final floatTag = utf8.encode('Float');
      
      int? musicalTempoIndex;
      for (int i = 0; i <= bytes.length - musicalTempoTag.length; i++) {
        bool found = true;
        for (int j = 0; j < musicalTempoTag.length; j++) {
          if (bytes[i + j] != musicalTempoTag[j]) {
            found = false;
            break;
          }
        }
        if (found) {
          musicalTempoIndex = i;
          break;
        }
      }
      
      if (musicalTempoIndex == null) {
        return null;
      }
      
      // Search for "Float" type indicator after MusicalTempo
      // Limit search to a reasonable range (e.g., 100 bytes after the tag)
      final searchEnd = (musicalTempoIndex + musicalTempoTag.length + 100).clamp(0, bytes.length);
      int? floatIndex;
      
      for (int i = musicalTempoIndex + musicalTempoTag.length; i <= searchEnd - floatTag.length; i++) {
        bool found = true;
        for (int j = 0; j < floatTag.length; j++) {
          if (bytes[i + j] != floatTag[j]) {
            found = false;
            break;
          }
        }
        if (found) {
          floatIndex = i;
          break;
        }
      }
      
      if (floatIndex == null) {
        return null;
      }
      
      // After "Float", skip padding bytes (typically 2-4 bytes) and read the 8-byte double value
      // The exact offset may vary, so we'll try a few common offsets
      final possibleOffsets = [2, 3, 4, 5, 6];
      
      for (final offset in possibleOffsets) {
        final valueStart = floatIndex + floatTag.length + offset;
        
        if (valueStart + 8 > bytes.length) {
          continue;
        }
        
        // Read 8 bytes as big-endian IEEE 754 double
        final byteData = ByteData.sublistView(bytes, valueStart, valueStart + 8);
        final tempoValue = byteData.getFloat64(0, Endian.big);
        
        // Validate: BPM should be in a reasonable range (e.g., 20-999)
        if (tempoValue >= 20.0 && tempoValue <= 999.0) {
          // Round to 2 decimal places for cleaner display
          return double.parse(tempoValue.toStringAsFixed(2));
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Extracts key/scale from Cubase file using ScaleHelper fields
  /// These fields store direct indices for root note and scale type
  static String? _extractCubaseKey(Uint8List bytes) {
    return _extractCubaseKeyFromScaleHelper(bytes);
  }
  
  /// Extracts key/scale from Cubase "ScaleHelper Root Key" and "ScaleHelper Scale Type" fields
  /// These fields store direct indices: RootKey (0-11 chromatic) and ScaleType (list index)
  static String? _extractCubaseKeyFromScaleHelper(Uint8List bytes) {
    try {
      // Search for "ScaleHelper Root Key" tag
      final rootKeyTag = utf8.encode('ScaleHelper Root Key');
      final scaleTypeTag = utf8.encode('ScaleHelper Scale Type');
      
      int? rootKeyIndex = _findPattern(bytes, rootKeyTag);
      int? scaleTypeIndex = _findPattern(bytes, scaleTypeTag);
      
      if (rootKeyIndex == null || scaleTypeIndex == null) {
        return null;
      }
      
      // Extract root key value (4-byte little-endian int at offset +10 after tag)
      final rootKeyValueStart = rootKeyIndex + rootKeyTag.length + 10;
      if (rootKeyValueStart + 4 > bytes.length) return null;
      
      final rootKeyBytes = bytes.sublist(rootKeyValueStart, rootKeyValueStart + 4);
      final rootKeyValue = ByteData.sublistView(Uint8List.fromList(rootKeyBytes))
          .getInt32(0, Endian.little);
      
      // Extract scale type value (4-byte little-endian int at offset +10 after tag)
      final scaleTypeValueStart = scaleTypeIndex + scaleTypeTag.length + 10;
      if (scaleTypeValueStart + 4 > bytes.length) return null;
      
      final scaleTypeBytes = bytes.sublist(scaleTypeValueStart, scaleTypeValueStart + 4);
      final scaleTypeValue = ByteData.sublistView(Uint8List.fromList(scaleTypeBytes))
          .getInt32(0, Endian.little);
      
      // Map root key to note name (chromatic scale from C)
      final rootNote = _getCubaseRootNote(rootKeyValue);
      final scaleName = _getCubaseScaleName(scaleTypeValue);
      
      if (rootNote != null && scaleName != null) {
        return '$rootNote $scaleName';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Helper to find a byte pattern in data, optionally starting the search
  /// partway through (e.g. to resume after a non-matching candidate).
  static int? _findPattern(Uint8List bytes, List<int> pattern, {int start = 0}) {
    for (int i = start; i <= bytes.length - pattern.length; i++) {
      if (_matchesAt(bytes, i, pattern)) return i;
    }
    return null;
  }

  /// Whether `pattern` occurs in `bytes` starting at `offset`. Safe to call
  /// with an out-of-range or negative `offset` — returns false rather than
  /// throwing, so callers don't need a separate bounds check first.
  static bool _matchesAt(Uint8List bytes, int offset, List<int> pattern) {
    if (offset < 0 || offset + pattern.length > bytes.length) return false;
    for (int j = 0; j < pattern.length; j++) {
      if (bytes[offset + j] != pattern[j]) return false;
    }
    return true;
  }
  
  /// Maps Cubase root key index to note name
  /// Index 0-11 represents chromatic scale from C
  /// Uses enharmonic notation (sharp/flat) for black keys
  static String? _getCubaseRootNote(int index) {
    const rootNotes = [
      'C', 'C#/Db', 'D', 'D#/Eb', 'E', 'F', 
      'F#/Gb', 'G', 'G#/Ab', 'A', 'A#/Bb', 'B'
    ];
    if (index >= 0 && index < rootNotes.length) {
      return rootNotes[index];
    }
    return null;
  }
  
  /// Maps Cubase scale type index to scale name
  /// Based on the order scales appear in Cubase's ScaleSetSaver XML
  static String? _getCubaseScaleName(int index) {
    const scaleNames = {
      0: 'Major',
      1: 'Minor',                  // Aeolian (natural minor)
      2: 'Harmonic Minor',
      3: 'Melodic Minor',
      4: 'Blues',
      5: 'Pentatonic',
      6: 'Mixolydic 9/11',
      7: 'Lydic Diminished',
      8: 'Blues 2',
      9: 'Major Augmented',
      10: 'Arabian',
      11: 'Balinese',
      12: 'Hungarian',
      13: 'Oriental',
      14: 'Raga Todi',
      15: 'Chinese',
      16: 'Hungarian 2',
      17: 'Japanese 1',
      18: 'Japanese 2',
      19: 'Persian',
      20: 'Diminished',
      21: 'Whole Tone',
      22: 'Blues 3',
      23: 'Dorian',
      24: 'Phrygian',
      25: 'Lydian',
      26: 'Mixolydian',
      27: 'Aeolian',               // Duplicate of Minor
      28: 'Locrian',
      29: 'No Scale',
    };
    return scaleNames[index];
  }
  
  
  /// Extracts key signature from the embedded filename in the .cpr file
  /// Cubase embeds the filename path which often contains the key in the name
  /// e.g., "g_minor.cpr" or "C#_Major_Project.cpr"
  static String? _extractKeyFromEmbeddedFilename(Uint8List bytes) {
    try {
      // Search for .cpr extension to find embedded filename
      final cprTag = utf8.encode('.cpr');
      
      int? cprPos;
      for (int i = bytes.length - 1; i >= 0; i--) {
        if (i + cprTag.length <= bytes.length) {
          bool found = true;
          for (int j = 0; j < cprTag.length; j++) {
            if (bytes[i + j] != cprTag[j]) {
              found = false;
              break;
            }
          }
          if (found) {
            cprPos = i;
            break;
          }
        }
      }
      
      if (cprPos == null) return null;
      
      // Extract filename (go backwards to find start)
      int filenameStart = cprPos;
      while (filenameStart > 0 && bytes[filenameStart - 1] >= 0x20 && bytes[filenameStart - 1] < 0x7F) {
        filenameStart--;
        // Stop at path separator or if we've gone too far
        if (bytes[filenameStart] == 0x2F || bytes[filenameStart] == 0x5C || cprPos - filenameStart > 100) {
          filenameStart++;
          break;
        }
      }
      
      final filenameBytes = bytes.sublist(filenameStart, cprPos);
      final filename = utf8.decode(filenameBytes, allowMalformed: true).toLowerCase();
      
      // Parse key from filename patterns like "g_minor", "c#_major", "d_phrygian"
      final notePatterns = {
        'c#': 'C#', 'c_sharp': 'C#', 'csharp': 'C#', 'db': 'C#',
        'd#': 'D#', 'd_sharp': 'D#', 'dsharp': 'D#', 'eb': 'D#',
        'f#': 'F#', 'f_sharp': 'F#', 'fsharp': 'F#', 'gb': 'F#',
        'g#': 'G#', 'g_sharp': 'G#', 'gsharp': 'G#', 'ab': 'G#',
        'a#': 'A#', 'a_sharp': 'A#', 'asharp': 'A#', 'bb': 'A#',
        'c': 'C', 'd': 'D', 'e': 'E', 'f': 'F', 'g': 'G', 'a': 'A', 'b': 'B',
      };
      
      final scalePatterns = {
        'major': 'Major', 'maj': 'Major',
        'minor': 'Minor', 'min': 'Minor',
        'dorian': 'Dorian', 'dor': 'Dorian',
        'phrygian': 'Phrygian', 'phryg': 'Phrygian',
        'lydian': 'Lydian', 'lyd': 'Lydian',
        'mixolydian': 'Mixolydian', 'mixo': 'Mixolydian',
        'aeolian': 'Minor', 'aeol': 'Minor',
        'locrian': 'Locrian', 'loc': 'Locrian',
      };
      
      String? foundNote;
      String? foundScale;
      
      // Look for scale first (to avoid matching single letters in scale names)
      for (final entry in scalePatterns.entries) {
        if (filename.contains(entry.key)) {
          foundScale = entry.value;
          break;
        }
      }
      
      // Then look for note (prioritize sharps/flats)
      for (final entry in notePatterns.entries) {
        if (filename.contains(entry.key)) {
          // For single letters, require underscore or start of string
          if (entry.key.length == 1) {
            final idx = filename.indexOf(entry.key);
            if (idx == 0 || filename[idx - 1] == '_' || filename[idx - 1] == '-') {
              foundNote = entry.value;
              break;
            }
          } else {
            foundNote = entry.value;
            break;
          }
        }
      }
      
      if (foundNote != null && foundScale != null) {
        return '$foundNote $foundScale';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Searches for BPM information in text files
  static Future<double?> _searchForBpmFile(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return null;
    }

    final patterns = ['bpm', 'bpm.txt', 'bpm.log', 'tempo', 'tempo.txt'];
    
    for (final pattern in patterns) {
      try {
        final file = File(p.join(directoryPath, pattern));
        if (await file.exists()) {
          final content = await file.readAsString();
          final trimmed = content.trim();
          final bpm = double.tryParse(trimmed);
          if (bpm != null && bpm > 0 && bpm < 1000) {
            return bpm;
          }
        }
      } catch (_) {
        // Continue searching
      }
    }

    // Also search in subdirectories (limited depth)
    try {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File) {
          final fileName = p.basename(entity.path).toLowerCase();
          if (patterns.any((p) => fileName.contains(p))) {
            try {
              final content = await entity.readAsString();
              final trimmed = content.trim();
              final bpm = double.tryParse(trimmed);
              if (bpm != null && bpm > 0 && bpm < 1000) {
                return bpm;
              }
            } catch (_) {
              // Continue
            }
          }
        }
      }
    } catch (_) {
      // Ignore errors
    }

    return null;
  }

  /// Searches for key information in text files
  static Future<String?> _searchForKeyFile(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return null;
    }

    final patterns = ['key', 'key.txt', 'key.log', 'musicalkey', 'musicalkey.txt'];
    
    for (final pattern in patterns) {
      try {
        final file = File(p.join(directoryPath, pattern));
        if (await file.exists()) {
          final content = await file.readAsString();
          final trimmed = content.trim();
          if (trimmed.isNotEmpty) {
            return trimmed;
          }
        }
      } catch (_) {
        // Continue searching
      }
    }

    // Also search in subdirectories (limited depth)
    try {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File) {
          final fileName = p.basename(entity.path).toLowerCase();
          if (patterns.any((p) => fileName.contains(p))) {
            try {
              final content = await entity.readAsString();
              final trimmed = content.trim();
              if (trimmed.isNotEmpty) {
                return trimmed;
              }
            } catch (_) {
              // Continue
            }
          }
        }
      }
    } catch (_) {
      // Ignore errors
    }

    return null;
  }

  /// Maps root note integer (0-11) to note name
  static String? _getRootNote(int value) {
    const rootNotes = [
      "C",
      "C#/Db",
      "D",
      "D#/Eb",
      "E",
      "F",
      "F#/Gb",
      "G",
      "G#/Ab",
      "A",
      "A#/Bb",
      "B"
    ];
    if (value >= 0 && value < rootNotes.length) {
      return rootNotes[value];
    }
    return null;
  }

  /// Maps a Reaper key-signature root index to note name, respecting the
  /// accidental direction stored in the signature.
  static String? _getReaperRootNote(int value, {int? accidental}) {
    const sharpNotes = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
    ];
    const flatNotes = [
      'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'Cb',
    ];

    if (value < 0 || value >= sharpNotes.length) {
      return null;
    }

    if (accidental == -1) {
      return flatNotes[value];
    }

    if (accidental == 1) {
      return sharpNotes[value];
    }

    return _getRootNote(value);
  }

  /// Maps scale type integer (0-34) to scale name
  static String? _getScaleType(int value) {
    const scaleTypes = [
      "Major",
      "Minor",
      "Dorian",
      "Mixolydian",
      "Lydian",
      "Phrygian",
      "Locrian",
      "Whole Tone",
      "Half-whole Dim.",
      "Whole-half Dim.",
      "Minor Blues",
      "Minor Pentatonic",
      "Major Pentatonic",
      "Harmonic Minor",
      "Harmonic Major",
      "Dorian ♯4",
      "Phrygian Dominant",
      "Melodic Minor",
      "Lydian Augmented",
      "Lydian Dominant",
      "Super Locrian",
      "8-Tone Spanish",
      "Bhairav",
      "Hungarian Minor",
      "Hirajoshi",
      "In-Sen",
      "Iwato",
      "Kumoi",
      "Pelog Selisir",
      "Pelog Tembung",
      "Messiaen 3",
      "Messiaen 4",
      "Messiaen 5",
      "Messiaen 6",
      "Messiaen 7"
    ];
    if (value >= 0 && value < scaleTypes.length) {
      return scaleTypes[value];
    }
    return null;
  }
}

