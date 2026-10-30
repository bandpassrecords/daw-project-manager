import 'dart:io';

import 'package:path/path.dart' as p;

import '../../models/sample_reference.dart';

/// Finds the file a [SampleReference] names on this computer.
///
/// What a project says is often out of date — the project was moved, a
/// drive letter changed, a library was reorganised, FL Studio 7 stored paths
/// relative to an install that no longer exists — so the stored paths are
/// only the first try:
///
/// 1. each of the reference's candidates, a relative one taken from the
///    project's folder and `%VARIABLES%` expanded;
/// 2. files of the same name in the project's folder tree, which is the
///    project's own;
/// 3. files of the same name in the [libraryFolders] the user listed — only
///    those that agree with the project: the size it recorded, or else the
///    folder the file was in (`…\Kick\kick 15.wav` is not just any
///    `kick 15.wav`).
///
/// Among several, one of the size the project recorded wins, then the one
/// sharing the most trailing folders with a stored path, then the first
/// found.
///
/// Folder listings are made once per folder and kept for the locator's
/// lifetime, so one export lists each library once.
class SampleLocator {
  SampleLocator({
    this.libraryFolders = const [],
    Map<String, String>? environment,
    this.projectTreeDepth = 6,
  }) : _environment = environment ?? Platform.environment;

  final List<String> libraryFolders;
  final Map<String, String> _environment;

  /// How deep a project's folder is searched — a project saved at the top
  /// of a drive must not have the whole drive listed.
  final int projectTreeDepth;

  final _indices = <String, Future<Map<String, List<String>>>>{};

  /// The file [ref] names, or null when none can be found.
  Future<String?> locate(SampleReference ref, {required String projectDir}) async {
    for (final candidate in ref.candidates) {
      final path = _expand(candidate, projectDir);
      if (path != null && await File(path).exists()) return p.normalize(path);
    }

    final inProject = await _inProject(ref, projectDir);
    if (inProject.isNotEmpty) return _best(inProject, ref);
    final trusted = await _inLibraries(ref);
    return trusted.isEmpty ? null : _best(trusted, ref);
  }

  /// Every file that could be the one [ref] names, besides its stored
  /// places: same-named files in the project's tree, then those in the
  /// [libraryFolders] that agree with the project, best first by the rules
  /// [locate] picks with. What a relink offers to choose from.
  Future<List<String>> candidatesFor(
    SampleReference ref, {
    required String projectDir,
  }) async {
    final hits = <String>[];
    final seen = <String>{};
    for (final hit in [
      ...await _inProject(ref, projectDir),
      ...await _inLibraries(ref),
    ]) {
      if (seen.add(p.normalize(hit).toLowerCase())) hits.add(hit);
    }
    final scores = {for (final h in hits) h: await _score(h, ref)};
    // A stable sort: the project's own files stay ahead of a library's on
    // a tie.
    final ordered = [...hits.indexed]
      ..sort((a, b) {
        final byScore = scores[b.$2]!.compareTo(scores[a.$2]!);
        return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
      });
    return [for (final (_, h) in ordered) h];
  }

  /// Every file named like [ref]'s anywhere under [folder], however deep.
  Future<List<String>> namedIn(String folder, SampleReference ref) async =>
      (await _index(folder, null))[ref.fileName.toLowerCase()] ??
      const <String>[];

  /// The one of [hits] that agrees with [ref] better than every other — by
  /// the size the project recorded, then the folders it shares with a
  /// stored path — or null when two agree as well (or none is given).
  Future<String?> clearBest(List<String> hits, SampleReference ref) async {
    if (hits.length <= 1) return hits.firstOrNull;
    final scored = [for (final h in hits) (h, await _score(h, ref))]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return scored[0].$2 > scored[1].$2 ? scored[0].$1 : null;
  }

  Future<List<String>> _inProject(SampleReference ref, String projectDir) async =>
      (await _index(projectDir, projectTreeDepth))[ref.fileName.toLowerCase()] ??
      const <String>[];

  /// A library holds many "Kick 15.wav"s, so one is only taken when it
  /// agrees with what the project recorded: the size, where the format
  /// keeps it, or else the folder the file was in.
  Future<List<String>> _inLibraries(SampleReference ref) async {
    final key = ref.fileName.toLowerCase();
    final size = ref.sizeBytes;
    final needsFolder = ref.candidates.any((c) => _segments(c).length > 1);
    final trusted = <String>[];
    for (final folder in libraryFolders) {
      for (final hit in (await _index(folder, null))[key] ?? const <String>[]) {
        final ok = size != null
            ? await _sizeOf(hit) == size
            : !needsFolder || _trailingMatch(hit, ref.candidates) >= 2;
        if (ok) trusted.add(hit);
      }
    }
    return trusted;
  }

  Future<int> _score(String hit, SampleReference ref) async {
    var score = _trailingMatch(hit, ref.candidates) * 2;
    if (ref.sizeBytes != null && await _sizeOf(hit) == ref.sizeBytes) {
      score += 1000;
    }
    return score;
  }

  /// The hit sharing the most trailing folders with a stored path, then the
  /// one of the recorded size; the first found on a tie.
  Future<String> _best(List<String> hits, SampleReference ref) async {
    if (hits.length == 1) return hits.single;
    var best = hits.first;
    var bestScore = -1;
    for (final hit in hits) {
      final score = await _score(hit, ref);
      if (score > bestScore) {
        best = hit;
        bestScore = score;
      }
    }
    return best;
  }

  static Future<int?> _sizeOf(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return null;
    }
  }

  /// [candidate] as a path to try here, or null when it can't be one.
  String? _expand(String candidate, String projectDir) {
    var path = candidate.replaceAllMapped(
      RegExp(r'%([A-Za-z0-9_]+)%'),
      (m) => _environment[m[1]!] ?? m[0]!,
    );
    if (path.contains('%')) return null; // A variable this machine lacks.
    if (_isAbsoluteAnywhere(path)) {
      // A Windows path read on macOS/Linux, or the reverse, isn't a path
      // here; the search by name may still find the file.
      if (Platform.isWindows != _isWindowsPath(path)) return null;
      return path;
    }
    // FL Studio's "\Patches\…" is relative to an install, not the project.
    if (path.startsWith(r'\') || path.startsWith('/')) return null;
    return p.join(projectDir, p.joinAll(path.split(RegExp(r'[\\/]'))));
  }

  static bool _isWindowsPath(String path) =>
      RegExp(r'^([A-Za-z]:[\\/]|\\\\)').hasMatch(path);

  static bool _isAbsoluteAnywhere(String path) =>
      _isWindowsPath(path) || path.startsWith('/') && !path.startsWith('//');

  /// How many path segments [hit] shares, from the end, with the closest of
  /// [candidates], compared case-insensitively.
  static int _trailingMatch(String hit, List<String> candidates) {
    final hitParts = _segments(hit);
    var best = 0;
    for (final c in candidates) {
      final parts = _segments(c);
      var n = 0;
      while (n < hitParts.length &&
          n < parts.length &&
          hitParts[hitParts.length - 1 - n] == parts[parts.length - 1 - n]) {
        n++;
      }
      if (n > best) best = n;
    }
    return best;
  }

  static List<String> _segments(String path) => path
      .toLowerCase()
      .split(RegExp(r'[\\/]'))
      .where((s) => s.isNotEmpty)
      .toList();

  /// Audio files under [root] by lower-case name, [maxDepth] folders deep
  /// (unbounded when null).
  Future<Map<String, List<String>>> _index(String root, int? maxDepth) {
    final key = '${p.normalize(root).toLowerCase()}|$maxDepth';
    return _indices[key] ??= _list(root, maxDepth);
  }

  static Future<Map<String, List<String>>> _list(
    String root,
    int? maxDepth,
  ) async {
    final out = <String, List<String>>{};
    Future<void> walk(Directory dir, int depth) async {
      final List<FileSystemEntity> entries;
      try {
        entries = await dir.list(followLinks: false).toList();
      } catch (_) {
        return; // An unreadable folder costs that folder.
      }
      for (final entity in entries) {
        if (entity is File) {
          if (!isSampleAudioFile(entity.path)) continue;
          out
              .putIfAbsent(p.basename(entity.path).toLowerCase(), () => [])
              .add(entity.path);
        } else if (entity is Directory &&
            (maxDepth == null || depth < maxDepth)) {
          await walk(entity, depth + 1);
        }
      }
    }

    final dir = Directory(root);
    if (await dir.exists()) await walk(dir, 0);
    return out;
  }
}
