import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'relink_writer.dart';

/// A relinked copy as written, or why it wasn't.
class RelinkCopy {
  const RelinkCopy({this.path, required this.relinked, required this.refused});

  /// Where the copy was written; null when no move could be applied, and
  /// nothing was written.
  final String? path;
  final Set<String> relinked;
  final Map<String, RelinkRefusal> refused;
}

/// The written copy didn't read back as it should: nothing was kept.
class RelinkCheckFailed implements Exception {
  const RelinkCheckFailed(this.reason);
  final String reason;
  @override
  String toString() => 'RelinkCheckFailed: $reason';
}

/// Writes a copy of the project at [projectPath] with [moves] (stored path
/// → where the file is now) applied, beside it as
/// `<name> (relinked).<ext>` unless [targetPath] says otherwise. The
/// original is only read.
///
/// The copy is checked before it is kept: read back with the DAW's reader,
/// it must name every relinked file at its new place — which must exist —
/// and every other file exactly as the original does. It is written to a
/// `.part` first and renamed only then, so a failed or cancelled write
/// never leaves something that looks finished.
Future<RelinkCopy> writeRelinkedCopy({
  required String projectPath,
  required Map<String, String> moves,
  ProjectRelinkWriter? writer,
  String? targetPath,
}) async {
  final w = writer ?? relinkWriterFor(projectPath);
  if (w == null) {
    throw UnsupportedError('No relink writer for $projectPath');
  }
  final original = await File(projectPath).readAsBytes();
  final result = w.write(original, moves);
  if (result.relinked.isEmpty) {
    return RelinkCopy(relinked: const {}, refused: result.refused);
  }

  for (final stored in result.relinked) {
    if (!await File(moves[stored]!).exists()) {
      throw RelinkCheckFailed('${moves[stored]} does not exist');
    }
  }
  final expected = {
    for (final path in w.referencedPaths(original))
      (result.relinked.contains(path) ? moves[path]! : path).toLowerCase(),
  };
  final relinkedReads = {
    for (final path in w.referencedPaths(result.bytes)) path.toLowerCase(),
  };
  if (!setEquals(relinkedReads, expected)) {
    throw const RelinkCheckFailed('the copy does not read as relinked');
  }

  final target = targetPath ??
      relinkedCopyPath(projectPath, (path) => File(path).existsSync());
  final part = File('$target.part');
  try {
    await part.writeAsBytes(result.bytes, flush: true);
    final Uint8List written = await part.readAsBytes();
    if (!listEquals(written, result.bytes)) {
      throw const RelinkCheckFailed('the copy on disk differs');
    }
    await part.rename(target);
  } catch (_) {
    if (await part.exists()) await part.delete();
    rethrow;
  }
  return RelinkCopy(
    path: target,
    relinked: result.relinked,
    refused: result.refused,
  );
}

/// `<name> (relinked).<ext>` beside [projectPath], numbered past any that
/// [exists] already: `(relinked 2)`, `(relinked 3)`…
String relinkedCopyPath(String projectPath, bool Function(String) exists) {
  final dir = p.dirname(projectPath);
  final stem = p.basenameWithoutExtension(projectPath);
  final ext = p.extension(projectPath);
  for (var n = 1;; n++) {
    final label = n == 1 ? 'relinked' : 'relinked $n';
    final candidate = p.join(dir, '$stem ($label)$ext');
    if (!exists(candidate) && !exists('$candidate.part')) return candidate;
  }
}
