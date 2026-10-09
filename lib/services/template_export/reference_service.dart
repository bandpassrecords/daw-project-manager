import 'dart:convert';
import 'dart:io';

import '../../models/music_project.dart';
import '../daw_parsers/cubase_project_parser.dart';
import 'reference_page.dart';
import 'template_export_service.dart';
import 'template_patterns.dart';

/// What was read from each Cubase project's tracks, kept between runs so the
/// reference page can be regenerated without opening every project again.
///
/// An entry is good for as long as the project file's size and modification
/// time are the ones it was read at. It holds the tracks as the parser gave
/// them, not their roles, so a better role dictionary applies without a
/// re-read. Device-local and derived from the files: it is neither synced nor
/// backed up.
class ReferenceCache {
  ReferenceCache(File file) : this._(file, {});

  ReferenceCache._(this.file, this._entries);

  final File file;
  final Map<String, _Entry> _entries;

  static Future<ReferenceCache> load(File file) async {
    try {
      if (!await file.exists()) return ReferenceCache(file);
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map || raw['version'] != 1) return ReferenceCache(file);
      final entries = <String, _Entry>{};
      for (final MapEntry(key: id, value: value)
          in (raw['projects'] as Map).entries) {
        final entry = _Entry.tryParse(value);
        if (entry != null && id is String) entries[id] = entry;
      }
      return ReferenceCache._(file, entries);
    } catch (_) {
      // A damaged cache costs a re-read, nothing more.
      return ReferenceCache(file);
    }
  }

  int get length => _entries.length;

  /// Whether [project]'s tracks were read from the file as it is now.
  bool isFresh(MusicProject project) {
    final entry = _entries[project.id];
    return entry != null &&
        entry.size == project.fileSizeBytes &&
        entry.modifiedMs == project.lastModifiedAt.millisecondsSinceEpoch;
  }

  /// The tracks read for [id], fresh or not; null when never read.
  List<CubaseTrack>? tracksOf(String id) => _entries[id]?.tracks;

  void put(MusicProject project, List<CubaseTrack> tracks) {
    _entries[project.id] = _Entry(
      size: project.fileSizeBytes,
      modifiedMs: project.lastModifiedAt.millisecondsSinceEpoch,
      tracks: tracks,
    );
  }

  /// Forgets projects that are no longer in the library.
  void retainOnly(Set<String> ids) =>
      _entries.removeWhere((id, _) => !ids.contains(id));

  Future<void> save() async {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({
      'version': 1,
      'projects': {
        for (final e in _entries.entries) e.key: e.value.toJson(),
      },
    }));
  }
}

class _Entry {
  const _Entry({
    required this.size,
    required this.modifiedMs,
    required this.tracks,
  });

  final int size;
  final int modifiedMs;
  final List<CubaseTrack> tracks;

  Map<String, Object?> toJson() => {
        's': size,
        'm': modifiedMs,
        't': [
          for (final t in tracks)
            {
              'i': t.index,
              'n': t.name,
              'y': t.type.name,
              if (t.parent != null) 'p': t.parent,
              if (t.output != null) 'o': t.output,
              if (t.inserts.isNotEmpty)
                'x': [
                  for (final i in t.inserts)
                    {
                      's': i.slot,
                      'p': i.plugin,
                      if (i.bypassed != null) 'b': i.bypassed,
                    },
                ],
            },
        ],
      };

  static _Entry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final size = raw['s'], modified = raw['m'], tracks = raw['t'];
    if (size is! int || modified is! int || tracks is! List) return null;
    final parsed = <CubaseTrack>[];
    for (final t in tracks) {
      if (t is! Map) return null;
      final type = CubaseTrackType.values
          .where((v) => v.name == t['y'])
          .firstOrNull;
      if (type == null || t['i'] is! int || t['n'] is! String) return null;
      parsed.add(CubaseTrack(
        index: t['i'] as int,
        name: t['n'] as String,
        type: type,
        parent: t['p'] as String?,
        output: t['o'] as String?,
        inserts: [
          for (final i in (t['x'] as List?) ?? const [])
            if (i is Map && i['s'] is int && i['p'] is String)
              CubaseInsert(
                slot: i['s'] as int,
                plugin: i['p'] as String,
                bypassed: i['b'] as bool?,
              ),
        ],
      ));
    }
    return _Entry(size: size, modifiedMs: modified, tracks: parsed);
  }
}

/// The projects the page is built from: Cubase files that are real rows.
List<MusicProject> referenceCandidates(List<MusicProject> projects) =>
    [for (final p in projects) if (TemplateExportService.isExportable(p)) p];

/// Candidates whose tracks are not in [cache] as the file is now, and whose
/// file still exists: what a run would have to read. Existence only; the
/// file is not opened.
List<MusicProject> projectsToReadForReference(
  List<MusicProject> projects,
  ReferenceCache cache, {
  bool Function(String path)? fileExists,
}) {
  final exists = fileExists ?? (path) => File(path).existsSync();
  return [
    for (final p in referenceCandidates(projects))
      if (!cache.isFresh(p) && exists(p.filePath)) p,
  ];
}

/// Reads [project]'s tracks into [cache]. A file that can't be read leaves
/// the cache as it was.
Future<void> readProjectIntoCache(
  MusicProject project,
  ReferenceCache cache, {
  Future<List<CubaseTrack>?> Function(String path) readTracks = readCubaseTracks,
}) async {
  final tracks = await readTracks(project.filePath);
  if (tracks != null && tracks.isNotEmpty) cache.put(project, tracks);
}

/// The corpus of every candidate with tracks in [cache] (fresh or from an
/// earlier read), by name so the page doesn't depend on the library's order.
List<CorpusProject> referenceCorpus(
  List<MusicProject> projects,
  ReferenceCache cache, {
  Map<String, String> aliases = const {},
}) {
  final corpus = <CorpusProject>[];
  for (final p in referenceCandidates(projects)) {
    final tracks = cache.tracksOf(p.id);
    if (tracks == null) continue;
    corpus.add(buildCorpusProject(
      projectId: p.id,
      name: p.displayName,
      modified: p.lastModifiedAt,
      cubaseVersion: p.dawVersion,
      tracks: tracks,
      aliases: aliases,
    ));
  }
  corpus.sort((a, b) {
    final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return c != 0 ? c : a.projectId.compareTo(b.projectId);
  });
  return corpus;
}

/// What a generated page was made from.
class ReferencePage {
  const ReferencePage({required this.html, required this.projects});
  final String html;
  final int projects;
}

/// The page for [projects] from what [cache] holds, using [template], with
/// its text from [stringsJson] (the shipped dictionary) in [languageCode].
ReferencePage buildReferencePage(
  List<MusicProject> projects,
  ReferenceCache cache, {
  required String template,
  required String stringsJson,
  String languageCode = 'en',
  DateTime? now,
}) {
  final corpus = referenceCorpus(projects, cache);
  final data = buildReferenceData(corpus, generated: now ?? DateTime.now());
  final strings = jsonDecode(stringsJson) as Map<String, Object?>;
  return ReferencePage(
    html: renderReferenceHtml(
      template,
      data,
      i18n: referenceStrings(strings, languageCode),
    ),
    projects: corpus.length,
  );
}
