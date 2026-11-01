import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// The written copy didn't read back as it should: nothing was kept.
class CopyCheckFailed implements Exception {
  const CopyCheckFailed(this.reason);
  final String reason;
  @override
  String toString() => 'CopyCheckFailed: $reason';
}

/// `<name> (<label>).<ext>` beside [projectPath], numbered past any that
/// [exists] already: `(<label> 2)`, `(<label> 3)`… A half-written copy
/// (`.part`) counts as taken.
String copyPathBeside(
  String projectPath,
  String label,
  bool Function(String) exists,
) {
  final dir = p.dirname(projectPath);
  final stem = p.basenameWithoutExtension(projectPath);
  final ext = p.extension(projectPath);
  for (var n = 1;; n++) {
    final suffix = n == 1 ? label : '$label $n';
    final candidate = p.join(dir, '$stem ($suffix)$ext');
    if (!exists(candidate) && !exists('$candidate.part')) return candidate;
  }
}

/// Writes [bytes] to [target] the safe way: to `<target>.part` first, read
/// back and compared, then renamed — so a failed or cancelled write never
/// leaves something that looks finished, and never a copy with other bytes
/// than these.
Future<void> writeCheckedFile(String target, Uint8List bytes) async {
  final part = File('$target.part');
  try {
    await part.writeAsBytes(bytes, flush: true);
    final Uint8List written = await part.readAsBytes();
    if (!listEquals(written, bytes)) {
      throw const CopyCheckFailed('the copy on disk differs');
    }
    await part.rename(target);
  } catch (_) {
    if (await part.exists()) await part.delete();
    rethrow;
  }
}
