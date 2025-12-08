import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  ProjectMetadata({
    this.bpm,
    this.key,
    this.dawType,
  });
}

class MetadataExtractor {
  /// Extracts metadata from a project file
  static Future<ProjectMetadata> extractMetadata(String filePath) async {
    debugPrint('[MetadataExtractor] Extracting metadata from: $filePath');
    final ext = p.extension(filePath).toLowerCase();
    final projectDir = File(filePath).parent;
    
    // Determine DAW type from extension
    final dawType = _getDawTypeFromExtension(ext);
    debugPrint('[MetadataExtractor] DAW Type: $dawType (extension: $ext)');
    
    double? bpm;
    String? key;

    // Try to extract from project file first
    if (ext == '.als') {
      debugPrint('[MetadataExtractor] Extracting from Ableton Live file...');
      final metadata = await _extractFromAbletonFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      debugPrint('[MetadataExtractor] Extracted from .als: BPM=$bpm, Key=$key');
    }

    // Also search for bpm and key files in the project directory
    debugPrint('[MetadataExtractor] Searching for BPM/key text files in: ${projectDir.path}');
    final bpmFromFile = await _searchForBpmFile(projectDir.path);
    if (bpmFromFile != null) {
      debugPrint('[MetadataExtractor] Found BPM from text file: $bpmFromFile');
      bpm = bpmFromFile;
    }

    final keyFromFile = await _searchForKeyFile(projectDir.path);
    if (keyFromFile != null) {
      debugPrint('[MetadataExtractor] Found Key from text file: $keyFromFile');
      key = keyFromFile;
    }

    debugPrint('[MetadataExtractor] Final metadata: BPM=$bpm, Key=$key, DAW=$dawType');
    return ProjectMetadata(
      bpm: bpm,
      key: key,
      dawType: dawType,
    );
  }

  /// Determines DAW type from file extension
  static String? _getDawTypeFromExtension(String ext) {
    switch (ext) {
      case '.als':
        return 'Ableton';
      case '.cpr':
        return 'Cubase';
      case '.flp':
        return 'FL Studio';
      case '.logicx':
        return 'Logic Pro';
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
      debugPrint('[MetadataExtractor] Parsing XML (length: ${xmlString.length} chars)');
      final document = XmlDocument.parse(xmlString);
      final root = document.rootElement;
      debugPrint('[MetadataExtractor] XML root element: ${root.name}');

      double? bpm;
      String? key;

      // Extract BPM - look for Tempo element with Manual child
      final tempoElements = root.findAllElements('Tempo');
      debugPrint('[MetadataExtractor] Found ${tempoElements.length} Tempo element(s)');
      if (tempoElements.isNotEmpty) {
        final tempoElement = tempoElements.first;
        // Look for Manual element inside Tempo
        final manualElements = tempoElement.findElements('Manual');
        if (manualElements.isNotEmpty) {
          final manualElement = manualElements.first;
          final tempoValue = manualElement.getAttribute('Value');
          debugPrint('[MetadataExtractor] Tempo Manual Value attribute: $tempoValue');
          if (tempoValue != null) {
            bpm = double.tryParse(tempoValue);
            debugPrint('[MetadataExtractor] Extracted BPM from Manual: $bpm');
          }
        }
        // Fallback: try direct Value attribute on Tempo element
        if (bpm == null) {
          final tempoValue = tempoElement.getAttribute('Value');
          debugPrint('[MetadataExtractor] Tempo direct Value attribute: $tempoValue');
          if (tempoValue != null) {
            bpm = double.tryParse(tempoValue);
            debugPrint('[MetadataExtractor] Extracted BPM from Tempo Value: $bpm');
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
      debugPrint('[MetadataExtractor] Found ${scaleInfoElements.length} ScaleInformation element(s)');
      
      if (scaleInfoElements.isNotEmpty) {
        final scalePairs = <_ScalePair>[];
        int filteredCount = 0;
        
        // Extract Root and Name from each ScaleInformation instance
        for (int i = 0; i < scaleInfoElements.length; i++) {
          final scaleInfoElement = scaleInfoElements[i];
          
          // Extract Root note (0-11)
          final rootElements = scaleInfoElement.findElements('Root');
          int? rootValue;
          if (rootElements.isNotEmpty) {
            final rootElement = rootElements.first;
            // Try Value attribute first, then text content
            final rootValueStr = rootElement.getAttribute('Value') ?? rootElement.text.trim();
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
            final nameValueStr = nameElement.getAttribute('Value') ?? nameElement.text.trim();
            if (nameValueStr.isNotEmpty) {
              nameValue = int.tryParse(nameValueStr);
            }
          }
          
          debugPrint('[MetadataExtractor] ScaleInformation[$i]: Root=$rootValue, Name=$nameValue');
          
          // Only add non-zero pairs (0,0 means C Major default/unset)
          if (rootValue != null && nameValue != null) {
            if (rootValue != 0 || nameValue != 0) {
              final rootNote = _getRootNote(rootValue);
              final scaleType = _getScaleType(nameValue);
              debugPrint('[MetadataExtractor]   -> Adding: ${rootNote ?? "?"} ${scaleType ?? "?"} (Root=$rootValue, Name=$nameValue)');
              scalePairs.add(_ScalePair(rootValue, nameValue));
            } else {
              filteredCount++;
              debugPrint('[MetadataExtractor]   -> Filtered out (0,0 default): C Major');
            }
          } else {
            debugPrint('[MetadataExtractor]   -> Skipped (null values)');
          }
        }
        
        debugPrint('[MetadataExtractor] Collected ${scalePairs.length} non-zero scale pair(s), filtered $filteredCount (0,0) pair(s)');
        
        // Process the collected scale pairs
        if (scalePairs.isNotEmpty) {
          // Get unique pairs
          final uniquePairs = scalePairs.toSet();
          debugPrint('[MetadataExtractor] Unique scale pairs: ${uniquePairs.length}');
          
          for (final pair in uniquePairs) {
            final rootNote = _getRootNote(pair.root);
            final scaleType = _getScaleType(pair.name);
            debugPrint('[MetadataExtractor]   - ${rootNote ?? "?"} ${scaleType ?? "?"} (Root=${pair.root}, Name=${pair.name})');
          }
          
          if (uniquePairs.length == 1) {
            // All non-zero instances have the same value
            final pair = uniquePairs.first;
            final rootNote = _getRootNote(pair.root);
            final scaleType = _getScaleType(pair.name);
            if (rootNote != null && scaleType != null) {
              key = '$rootNote $scaleType';
              debugPrint('[MetadataExtractor] Result: Single scale -> "$key"');
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
              debugPrint('[MetadataExtractor] Result: Multiple scales -> "$key"');
            }
          }
        } else {
          debugPrint('[MetadataExtractor] Result: No non-zero scale pairs found (all were 0,0 defaults)');
        }
      } else {
        debugPrint('[MetadataExtractor] No ScaleInformation elements found');
      }

      // Fallback: look for MusicalKey or KeySignature elements
      if (key == null || key.isEmpty) {
        final keyElements = root.findAllElements('MusicalKey');
        if (keyElements.isNotEmpty) {
          final keyElement = keyElements.first;
          key = keyElement.getAttribute('Value') ?? keyElement.text;
        }
      }

      // Try alternative key element names
      if (key == null || key.isEmpty) {
        final keySigElements = root.findAllElements('KeySignature');
        if (keySigElements.isNotEmpty) {
          final keySigElement = keySigElements.first;
          key = keySigElement.getAttribute('Value') ?? keySigElement.text;
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

      final result = ProjectMetadata(bpm: bpm, key: key?.trim().isEmpty == true ? null : key?.trim());
      debugPrint('[MetadataExtractor] Ableton extraction complete: BPM=$bpm, Key=$key');
      return result;
    } catch (e) {
      // If parsing fails, return empty metadata
      debugPrint('[MetadataExtractor] Error extracting from Ableton file: $e');
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
              final content = await (entity as File).readAsString();
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
              final content = await (entity as File).readAsString();
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

