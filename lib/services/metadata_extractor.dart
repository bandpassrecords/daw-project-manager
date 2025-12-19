import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

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

class ProjectMetadata {
  final double? bpm;
  final String? key;
  final String? dawType;
  final String? dawVersion;

  ProjectMetadata({
    this.bpm,
    this.key,
    this.dawType,
    this.dawVersion,
  });
}

class MetadataExtractor {
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

    // Try to extract from project file first
    if (ext == '.als' || ext == '.alp') {
      final metadata = await _extractFromAbletonFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
    } else if (ext == '.cpr' || ext == '.npr') {
      // Nuendo uses similar format to Cubase
      final metadata = await _extractFromCubaseFile(filePath);
      dawVersion = metadata.dawVersion ?? dawVersion;
    }

    // Also search for bpm and key files in the project directory
    final bpmFromFile = await _searchForBpmFile(projectDir.path);
    if (bpmFromFile != null) {
      bpm = bpmFromFile;
    }

    final keyFromFile = await _searchForKeyFile(projectDir.path);
    if (keyFromFile != null) {
      key = keyFromFile;
    }

    return ProjectMetadata(
      bpm: bpm,
      key: key,
      dawType: dawType,
      dawVersion: dawVersion,
    );
  }

  /// Determines DAW type from file extension
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
      default:
        return null;
    }
  }

  /// Extracts BPM and key from Ableton Live .als file
  /// .als files are gzipped XML files (or uncompressed XML in older versions)
  static Future<ProjectMetadata> _extractFromAbletonFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProjectMetadata();
      }

      // Read the file as bytes
      final bytes = await file.readAsBytes();
      
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

      // Extract version from MinorVersion attribute
      final minorVersion = root.getAttribute('MinorVersion');
      if (minorVersion != null && minorVersion.isNotEmpty) {
        // Extract major version (e.g., "12.0_12300" -> "12")
        final parts = minorVersion.split('.');
        if (parts.isNotEmpty) {
          dawVersion = parts[0];
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

      return ProjectMetadata(
        bpm: bpm,
        key: key?.trim().isEmpty == true ? null : key?.trim(),
        dawVersion: dawVersion,
      );
    } catch (e) {
      // If parsing fails, return empty metadata
      return ProjectMetadata();
    }
  }

  /// Extracts version from Cubase .cpr file
  /// Looks for hex pattern: 00 10 56 65 72 73 69 6F 6E (which is "00 10 Version")
  /// Then extracts the version string that follows (e.g., " 13.0.4" -> "13")
  static Future<ProjectMetadata> _extractFromCubaseFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProjectMetadata();
      }

      // Read file as bytes
      final bytes = await file.readAsBytes();
      
      // Hex pattern: 00 10 56 65 72 73 69 6F 6E (which is "00 10 Version" in ASCII)
      final pattern = [0x00, 0x10, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E];
      
      // Find the pattern in the file
      int? patternIndex;
      for (int i = 0; i <= bytes.length - pattern.length; i++) {
        bool found = true;
        for (int j = 0; j < pattern.length; j++) {
          if (bytes[i + j] != pattern[j]) {
            found = false;
            break;
          }
        }
        if (found) {
          patternIndex = i;
          break;
        }
      }
      
      if (patternIndex == null) {
        return ProjectMetadata();
      }
      
      // Skip the pattern (9 bytes) and look for version string
      // Version typically starts with a space (0x20) followed by digits and dots
      int versionStart = patternIndex + pattern.length;
      
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
      
      if (versionBytes.isEmpty) {
        return ProjectMetadata();
      }
      
      // Convert to string and extract major version
      final versionString = utf8.decode(versionBytes).trim();
      // Extract major version (e.g., "13.0.4" -> "13")
      final parts = versionString.split('.');
      String? dawVersion;
      if (parts.isNotEmpty) {
        dawVersion = parts[0].trim();
      }
      
      return ProjectMetadata(dawVersion: dawVersion);
    } catch (e) {
      // If parsing fails, return empty metadata
      return ProjectMetadata();
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

