import 'dart:io';

import 'package:path/path.dart' as p;

import '../../models/music_project.dart';
import '../metadata_extractor.dart';

/// Projects whose MIDI has never been read but could be: real files, not
/// stacks or archives, in a DAW whose contents the app reads, with nothing
/// stored in [storedIds] (the projects that have clips on record, even none).
///
/// [fileExists] is only asked for projects that pass everything else, and
/// only looks at the file's existence — it does not open it, so a file on a
/// cloud drive is not downloaded.
List<MusicProject> projectsNeedingMidiRead(
  List<MusicProject> projects,
  Set<String> storedIds, {
  bool Function(String path)? fileExists,
}) {
  final exists = fileExists ?? (path) => File(path).existsSync();
  return [
    for (final project in projects)
      if (!project.isVirtual &&
          !project.isArchived &&
          !storedIds.contains(project.id) &&
          MetadataExtractor.readsProjectContents(project.filePath) &&
          exists(project.filePath))
        project,
  ];
}

/// What a batch of reads came to.
class MidiReadOutcome {
  const MidiReadOutcome({
    required this.read,
    required this.failed,
    required this.stopped,
  });

  /// Projects read without error.
  final int read;

  /// Projects whose read threw.
  final int failed;

  /// Whether the batch was cut short on request.
  final bool stopped;
}

/// Reads [projects] one after another through [read] — one at a time, so a
/// cloud drive is asked for a single file at once — telling [onProgress]
/// before each. [shouldStop] is checked between projects: what was read
/// stays read.
Future<MidiReadOutcome> readMissingMidi(
  List<MusicProject> projects, {
  required Future<void> Function(MusicProject project) read,
  void Function(int done, int total, MusicProject next)? onProgress,
  bool Function()? shouldStop,
}) async {
  var done = 0, failed = 0;
  var stopped = false;
  for (final project in projects) {
    if (shouldStop?.call() ?? false) {
      stopped = true;
      break;
    }
    onProgress?.call(done, projects.length, project);
    try {
      await read(project);
    } catch (_) {
      failed++;
    }
    done++;
  }
  return MidiReadOutcome(read: done - failed, failed: failed, stopped: stopped);
}

/// 1.4 GB, 320 MB, 12 KB: a size as a person reads it.
String formatDataSize(int bytes) {
  const kb = 1024, mb = kb * 1024, gb = mb * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  if (bytes >= mb) return '${(bytes / mb).round()} MB';
  if (bytes >= kb) return '${(bytes / kb).round()} KB';
  return '$bytes B';
}

/// The file name of [project], for a progress line.
String projectFileLabel(MusicProject project) => p.basename(project.filePath);
