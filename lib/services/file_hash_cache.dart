import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// Remembers each file's content hash (MD5, as Drive sync compares them) by
/// path, with the size and modification time it had when it was read, so an
/// unchanged file is never read again.
///
/// Every Drive sync used to hash every preview song, cover and photo it
/// backs up, reading each file whole — tens of WAVs on every launch, and on
/// a cloud drive a download of each. A file whose size and time are the same
/// as when it was hashed is taken to be the same file; the size catches a
/// copy that carried the old time over to new contents (the waveform cache's
/// rule, `WaveformSourceStamp`).
///
/// Device-local: paths and times of this machine's files. In neither Drive
/// sync nor local backup.
class FileHashCache {
  FileHashCache(this._box);

  static const boxName = 'file_hash_cache';

  final Box<String> _box;

  static Future<FileHashCache> open() async => FileHashCache(await Hive.openBox<String>(boxName));

  /// The hash of the file at [path]: the remembered one while its size and
  /// time are unchanged, else [compute]'s (which reads the file), then kept.
  /// A failure to read or write the cache only costs the read it would have
  /// saved.
  Future<String> hashOf(String path, Future<String> Function() compute) async {
    final FileStat stat;
    try {
      stat = await FileStat.stat(path);
    } catch (_) {
      return compute();
    }
    if (stat.type == FileSystemEntityType.notFound) return compute();
    final stamp = (size: stat.size, modified: stat.modified.microsecondsSinceEpoch);
    final known = cachedHash(_box.get(path), size: stamp.size, modified: stamp.modified);
    if (known != null) return known;
    final hash = await compute();
    try {
      await _box.put(path, encodeHashEntry(hash, size: stamp.size, modified: stamp.modified));
    } catch (e) {
      debugPrint('[FileHashCache] could not remember $path: $e');
    }
    return hash;
  }
}

/// A cache entry: the hash with the size and time the file had.
@visibleForTesting
String encodeHashEntry(String hash, {required int size, required int modified}) =>
    jsonEncode({'hash': hash, 'size': size, 'modified': modified});

/// The hash in [stored] when it was taken of a file of this [size] and
/// [modified] time; null for any other file, or an entry that can't be read.
@visibleForTesting
String? cachedHash(String? stored, {required int size, required int modified}) {
  if (stored == null) return null;
  try {
    final entry = jsonDecode(stored);
    if (entry is! Map) return null;
    if (entry['size'] != size || entry['modified'] != modified) return null;
    final hash = entry['hash'];
    return hash is String && hash.isNotEmpty ? hash : null;
  } catch (_) {
    return null;
  }
}
