import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../models/music_project.dart';
import '../daw_parsers/cubase_project_parser.dart';
import 'template_patterns.dart';
import 'template_spec.dart';

/// What an export wrote.
class TemplateExportResult {
  const TemplateExportResult({
    required this.directory,
    required this.projectsAnalysed,
    required this.projectsSkipped,
  });

  final String directory;
  final int projectsAnalysed;

  /// Cubase projects that could not be read (missing, cloud-only, damaged).
  final int projectsSkipped;
}

/// Exports what a Cubase library has in common as the four files the
/// template builder needs: `corpus.json` (every project's tracks, for
/// auditing), `patterns.json` (statistics per role), `template-spec.md`
/// (the steps Claude executes) and `template.md` (the same template as a tree
/// a person can read and build by hand).
class TemplateExportService {
  const TemplateExportService._();

  /// Projects the parser can read: Cubase/Nuendo files that are real rows
  /// with a file of their own.
  static bool isExportable(MusicProject project) {
    if (project.isVirtual || project.isArchived) return false;
    final ext = p.extension(project.filePath).toLowerCase();
    return ext == '.cpr' || ext == '.npr';
  }

  /// Reads the tracks of every exportable project in [projects] and writes
  /// the export into [directory]. With [anonymize] the corpus carries
  /// "Project 1", "Project 2"… instead of project names. Paths are never
  /// written.
  static Future<TemplateExportResult> export(
    List<MusicProject> projects, {
    required Directory directory,
    bool anonymize = false,
    Map<String, String> aliases = const {},
    TemplateThresholds thresholds = const TemplateThresholds(),
    Future<List<CubaseTrack>?> Function(String path) readTracks = readCubaseTracks,
  }) async {
    final corpus = <CorpusProject>[];
    var skipped = 0;
    for (final project in projects.where(isExportable)) {
      final tracks = await readTracks(project.filePath);
      if (tracks == null || tracks.isEmpty) {
        skipped++;
        continue;
      }
      corpus.add(buildCorpusProject(
        projectId: project.id,
        name: anonymize ? 'Project ${corpus.length + 1}' : project.displayName,
        modified: project.lastModifiedAt,
        cubaseVersion: project.dawVersion,
        tags: project.tags,
        plugins: project.stats?.plugins ?? const [],
        tracks: tracks,
        aliases: aliases,
      ));
    }

    final patterns = buildPatterns(corpus, thresholds: thresholds);
    await directory.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await File(p.join(directory.path, 'corpus.json')).writeAsString(
      encoder.convert({
        'meta': {
          'schema_version': TemplatePatterns.schemaVersion,
          'generated': patterns.generated.toUtc().toIso8601String(),
          'projects': corpus.length,
          'anonymized': anonymize,
        },
        'projects': [for (final c in corpus) c.toJson()],
      }),
    );
    await File(p.join(directory.path, 'patterns.json'))
        .writeAsString(encoder.convert(patterns.toJson()));
    await File(p.join(directory.path, 'template-spec.md'))
        .writeAsString(buildTemplateSpec(patterns));
    await File(p.join(directory.path, 'template.md'))
        .writeAsString(buildTemplateOutline(patterns));

    return TemplateExportResult(
      directory: directory.path,
      projectsAnalysed: corpus.length,
      projectsSkipped: skipped,
    );
  }
}

/// The tracks of the Cubase file at [path], read off the UI thread; null when
/// the file can't be read or isn't a Cubase project.
Future<List<CubaseTrack>?> readCubaseTracks(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    final Uint8List bytes = await file.readAsBytes();
    return await Isolate.run(() {
      final parser = CubaseProjectParser(bytes);
      return parser.isCubaseFile ? parser.readTracks() : null;
    });
  } catch (_) {
    return null;
  }
}
