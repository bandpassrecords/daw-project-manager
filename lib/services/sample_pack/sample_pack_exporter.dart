import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../models/sample_reference.dart';
import '../../utils/audio_file_info.dart';
import '../../utils/folder_tree.dart';
import '../midi/midi_clip_service.dart';
import '../midi/midi_file_writer.dart';
import 'master_project.dart';
import 'project_sample_reader.dart';
import 'sample_classifier.dart';
import 'sample_locator.dart';
import 'sample_naming.dart';
import '../../utils/csv.dart';

/// One project to collect samples from.
class SamplePackProject {
  const SamplePackProject({
    this.id = '',
    required this.filePath,
    required this.name,
    required this.profileName,
    required this.songKey,
    this.bpm,
  });

  /// The project's tempo, which a loop cut to whole bars at it was made at.
  final double? bpm;

  /// The project's id in its profile, for picking it.
  final String id;
  final String filePath;

  /// What the report calls the song this project is.
  final String name;
  final String profileName;

  /// Projects with the same key are one song — the versions in a version
  /// stack — and count as one use of a sample.
  final String songKey;
}

/// A folder of `.mid` files to write under the pack's `MIDI` folder.
class SamplePackMidiFolder {
  const SamplePackMidiFolder(this.name, this.exports);
  final String name;
  final List<MidiExport> exports;
}

/// What the export is doing within a project, for its progress line.
enum SamplePackPhase { reading, locating, measuring, copying, midi, finishing }

/// Where the export has got to: project [project] (from 0) of [projects],
/// and within it [phase], at [done] of [total], on [current].
class SamplePackProgressUpdate {
  const SamplePackProgressUpdate({
    required this.project,
    required this.projects,
    required this.projectName,
    required this.phase,
    this.done = 0,
    this.total = 0,
    this.current = '',
  });

  final int project;
  final int projects;
  final String projectName;
  final SamplePackPhase phase;
  final int done;
  final int total;
  final String current;

  /// How far the whole export is, 0 to 1.
  double get fraction {
    if (projects == 0) return 1;
    final within = total == 0 ? 0 : done / total;
    return ((project + within) / projects).clamp(0, 1).toDouble();
  }
}

typedef SamplePackProgress = void Function(SamplePackProgressUpdate update);

/// One distinct sound, however many projects and folders hold a copy.
class PackSample {
  PackSample();

  /// Every located copy, the one copied into the pack first.
  final List<String> paths = [];
  int sizeBytes = 0;
  Duration? duration;

  /// The tempo and key its name, its folders or its project gave away
  /// (see `sampleTraitsOf`); null when nothing did.
  double? bpm;
  String? key;
  SampleCategory category = SampleCategory.other;
  SampleOrigin origin = SampleOrigin.project;
  final List<SampleOrigin> _origins = [];

  /// Songs using it, by [SamplePackProject.songKey], with their names.
  final Map<String, String> songs = {};
  final Set<String> profiles = {};

  /// Where it is in the pack (forward slashes), or null when left out.
  String? packPath;

  /// Whether this export copied it in (false: it was there already, or it
  /// was left out).
  bool added = false;

  /// Whether it has been compared with the pack and the other samples. A
  /// sample that is left out never is: comparing means reading it.
  bool _indexed = false;
  bool _copyFailed = false;

  void _addOrigin(SampleOrigin o) {
    _origins.add(o);
    origin = combinedOrigin(_origins);
  }
}

/// A reference that couldn't be followed, or a project that couldn't be
/// read, for the report.
class SamplePackProblem {
  const SamplePackProblem({
    required this.project,
    required this.profile,
    required this.problem,
    this.sample = '',
    this.where = '',
  });

  final String project;
  final String profile;
  final SamplePackProblemKind problem;
  final String sample;
  final String where;
}

enum SamplePackProblemKind {
  sampleNotFound('sample_not_found'),
  projectNotFound('project_not_found'),
  projectUnreadable('project_unreadable'),
  formatNotSupported('format_not_supported');

  const SamplePackProblemKind(this.code);

  /// How the report writes it.
  final String code;
}

class SamplePackResult {
  const SamplePackResult({
    required this.samples,
    required this.problems,
    required this.projectsRead,
    required this.midiFiles,
    required this.stopped,
    this.masterProjectsLeftOut = 0,
  });

  final List<PackSample> samples;
  final List<SamplePackProblem> problems;
  final int projectsRead;

  /// Master projects not read (see [isMasterProject]).
  final int masterProjectsLeftOut;
  final int midiFiles;
  final bool stopped;

  int get added => samples.where((s) => s.added).length;
  int get alreadyInPack =>
      samples.where((s) => s.packPath != null && !s.added).length;

  /// Own audio left out because the export wasn't asked to include it.
  int get leftOut => samples.where((s) => s.packPath == null).length;
  int get missing => problems
      .where((x) => x.problem == SamplePackProblemKind.sampleNotFound)
      .length;
  int get projectsNotRead => problems
      .where((x) => x.problem != SamplePackProblemKind.sampleNotFound)
      .length;
}

/// The files the export writes beside the samples.
const kSamplePackManifest = 'sample_pack_manifest.json';
const kSamplePackReport = 'sample_pack_report.csv';
const kSamplePackProblems = 'sample_pack_missing.csv';

/// Every file in the pack, drawn as a tree (see [folderTreeText]).
const kSamplePackTree = 'sample_pack_tree.txt';

/// The folder own audio goes in when it is included, so it stays apart from
/// the samples.
const kOwnAudioFolder = 'Recordings, Bounces & Stems';
const kMidiFolder = 'MIDI';

/// Collects the samples a set of projects use into one folder, sorted into
/// category folders, with a report of how often each is used.
///
/// Works one project at a time and copies as it goes, so the folder fills
/// while it runs and stopping keeps everything done so far (the report and
/// manifest are written then too).
///
/// It only opens a file it is going to copy. Own audio that is left out is
/// recognised from what the project says, the folders and the file's size
/// (`sampleOriginOf`), none of which means reading the file — which, on a
/// cloud drive, means downloading it.
///
/// Running it again on the same folder only adds what isn't there yet: every
/// sample is compared by content with what the folder holds — wherever the
/// user has moved or renamed it since — so nothing is copied twice. Files
/// are told apart by size and only hashed when sizes match;
/// `sample_pack_manifest.json` remembers each pack file's size, date and
/// hash so the pack isn't re-read every time.
class SamplePackExporter {
  SamplePackExporter({
    required this.destination,
    this.includeOwnAudio = false,
    this.excludeMasterProjects = false,
    this.naming,
    SampleLocator? locator,
    this.readReferences = readProjectSampleReferences,
    this.canRead = canReadSampleReferences,
    this.readDuration = readAudioDuration,
    this.hashFile = sha1OfFile,
  }) : locator = locator ?? SampleLocator();

  final String destination;

  /// Whether recordings, bounces and stems go into the pack too.
  final bool includeOwnAudio;

  /// Whether master projects are left unread: they hold a song's stems and
  /// mixdowns, not samples.
  final bool excludeMasterProjects;

  /// How copied samples are renamed; null keeps their names (with the
  /// category in front when the name doesn't say it, see `packFileName`).
  /// Only samples copied in by this run are named: what is in the folder
  /// already — renamed by the user, perhaps — is left alone.
  final SampleNaming? naming;
  final SampleLocator locator;

  final Future<List<SampleReference>> Function(String filePath) readReferences;
  final bool Function(String filePath) canRead;
  final Future<Duration?> Function(String path) readDuration;
  final Future<String> Function(String path) hashFile;

  Future<SamplePackResult> export(
    List<SamplePackProject> projects, {
    List<SamplePackMidiFolder> midi = const [],
    SamplePackProgress? onProgress,
    bool Function()? shouldStop,
  }) =>
      _Run(this, onProgress, shouldStop).go(projects, midi);
}

/// One export's state.
class _Run {
  _Run(this.x, this.onProgress, this.shouldStop);

  final SamplePackExporter x;
  final SamplePackProgress? onProgress;
  final bool Function()? shouldStop;

  final problems = <SamplePackProblem>[];
  final samples = <PackSample>[];
  final _byPath = <String, PackSample>{};
  final _bySize = <int, List<_Entry>>{};
  final _hashes = <String, String>{};
  final _taken = <String>{};

  /// The next file number per pack folder (lower case), once looked up.
  final _nextNumber = <String, int>{};
  final _written = <_PackFile>[];

  /// Each file copied in, by the source it was copied from — a source
  /// hashed after its copy was made (when a same-sized file turned up
  /// later) still gives the copy its hash.
  final _copiedFrom = <String, String>{};
  var projectsRead = 0;
  var mastersLeftOut = 0;
  var stopped = false;

  int _project = 0;
  int _projects = 0;
  String _projectName = '';

  bool get _stop {
    if (!stopped && (shouldStop?.call() ?? false)) stopped = true;
    return stopped;
  }

  void _progress(SamplePackPhase phase,
          [int done = 0, int total = 0, String current = '']) =>
      onProgress?.call(SamplePackProgressUpdate(
        project: _project,
        projects: _projects,
        projectName: _projectName,
        phase: phase,
        done: done,
        total: total,
        current: current,
      ));

  Future<SamplePackResult> go(
    List<SamplePackProject> projects,
    List<SamplePackMidiFolder> midi,
  ) async {
    // One project file in two profiles is read once and belongs to both.
    final byFile = <String, (SamplePackProject, Set<String>)>{};
    for (final project in projects) {
      byFile
          .putIfAbsent(_pathKey(project.filePath), () => (project, <String>{}))
          .$2
          .add(project.profileName);
    }
    _projects = byFile.length;

    await _loadPack();

    for (final (project, profiles) in byFile.values) {
      if (_stop) break;
      _projectName = project.name;
      await _read(project, profiles);
      _project++;
    }

    var midiFiles = 0;
    if (!_stop) {
      for (var i = 0; i < midi.length; i++) {
        _progress(SamplePackPhase.midi, i, midi.length, midi[i].name);
        final files = await MidiClipService.exportAll(
          midi[i].exports,
          Directory(p.join(x.destination, kMidiFolder, _safeName(midi[i].name))),
        );
        midiFiles += files.length;
      }
    }

    _progress(SamplePackPhase.finishing);
    samples.sort((a, b) => b.songs.length.compareTo(a.songs.length));
    final result = SamplePackResult(
      samples: samples,
      problems: problems,
      projectsRead: projectsRead,
      midiFiles: midiFiles,
      stopped: stopped,
      masterProjectsLeftOut: mastersLeftOut,
    );
    await Directory(x.destination).create(recursive: true);
    await _Manifest.write(x.destination, _written, {
      for (final f in _written)
        f.path: ?(_hashes[f.path] ?? _hashes[_copiedFrom[f.path]]),
    });
    await File(p.join(x.destination, kSamplePackReport))
        .writeAsString(samplePackReportCsv(samples), flush: true);
    await File(p.join(x.destination, kSamplePackProblems))
        .writeAsString(samplePackProblemsCsv(problems), flush: true);
    await _writeTree();
    return result;
  }

  /// [kSamplePackTree]: everything in the pack folder, samples, MIDI and the
  /// export's own files alike — not just what this run added.
  Future<void> _writeTree() async {
    final root = x.destination;
    final paths = <String>[];
    await for (final entity in Directory(root)
        .list(recursive: true, followLinks: false)
        .handleError((_) {})) {
      if (entity is! File) continue;
      final relative =
          p.relative(entity.path, from: root).replaceAll(r'\', '/');
      if (relative == kSamplePackTree || relative.endsWith('.part')) continue;
      paths.add(relative);
    }
    // UTF-8 with a BOM, so Notepad shows the tree's lines and accents.
    await File(p.join(root, kSamplePackTree)).writeAsString(
      '$_bom${folderTreeText(p.basename(p.normalize(root)), paths)}',
      flush: true,
    );
  }

  /// What the pack folder already holds, with the hashes the manifest kept.
  Future<void> _loadPack() async {
    final manifest = await _Manifest.read(x.destination);
    for (final f in await _packAudioFiles(x.destination)) {
      _written.add(f);
      _taken.add(f.relative.toLowerCase());
      if (manifest.hashFor(f) case final h?) _hashes[f.path] = h;
      _bySize.putIfAbsent(f.size, () => []).add(_Entry(f.path, packPath: f.relative));
    }
  }

  Future<void> _read(SamplePackProject project, Set<String> profiles) async {
    _progress(SamplePackPhase.reading);
    SamplePackProblem problem(SamplePackProblemKind kind,
            {String sample = '', String? where}) =>
        SamplePackProblem(
          project: project.name,
          profile: profiles.join(', '),
          problem: kind,
          sample: sample,
          where: where ?? project.filePath,
        );

    if (x.excludeMasterProjects && isMasterProject(project.filePath)) {
      mastersLeftOut++;
      return;
    }
    if (!x.canRead(project.filePath)) {
      problems.add(problem(SamplePackProblemKind.formatNotSupported));
      return;
    }
    if (!await File(project.filePath).exists()) {
      problems.add(problem(SamplePackProblemKind.projectNotFound));
      return;
    }
    final List<SampleReference> refs;
    try {
      refs = await x.readReferences(project.filePath);
    } catch (_) {
      problems.add(problem(SamplePackProblemKind.projectUnreadable));
      return;
    }
    projectsRead++;

    final projectDir = p.dirname(project.filePath);
    final reported = <String>{};
    for (var i = 0; i < refs.length; i++) {
      if (_stop) return;
      final ref = refs[i];
      _progress(SamplePackPhase.locating, i, refs.length, ref.fileName);
      final path = await x.locator.locate(ref, projectDir: projectDir);
      if (path == null) {
        if (reported.add(ref.fileName.toLowerCase())) {
          problems.add(problem(
            SamplePackProblemKind.sampleNotFound,
            sample: ref.fileName,
            where: ref.candidates.firstOrNull ?? '',
          ));
        }
        continue;
      }
      await _use(project, profiles, projectDir, ref, path, i, refs.length);
    }
  }

  /// One reference, found at [path]: counted for its song, and copied in
  /// if it is wanted and not in the pack yet.
  Future<void> _use(
    SamplePackProject project,
    Set<String> profiles,
    String projectDir,
    SampleReference ref,
    String path,
    int index,
    int total,
  ) async {
    final key = _pathKey(path);
    var sample = _byPath[key];
    if (sample == null) {
      final int size;
      try {
        size = await File(path).length();
      } catch (_) {
        return; // Gone since it was found.
      }
      sample = PackSample()
        ..sizeBytes = size
        ..category = sampleCategoryOf(path, projectDir: _inside(projectDir, path));
      sample.paths.add(path);
      samples.add(sample);
      _byPath[key] = sample;
    }
    sample.songs.putIfAbsent(project.songKey, () => project.name);
    sample.profiles.addAll(profiles);

    final origin = sampleOriginOf(
      path: path,
      projectDir: projectDir,
      kind: ref.kind,
      use: ref.use,
      duration: sample.duration,
      sizeBytes: sample.sizeBytes,
    );
    sample._addOrigin(origin);
    if (sample.packPath != null || sample._copyFailed) return;
    if (origin.isOwnAudio && !x.includeOwnAudio) return;

    // Wanted: from here on the file is read.
    _progress(SamplePackPhase.measuring, index, total, p.basename(path));
    if (!sample._indexed) {
      sample = await _index(sample, path);
      if (sample.packPath != null) {
        // Already in the pack: its length is read from the pack's copy.
        sample.duration ??= await x.readDuration(
          p.joinAll([x.destination, ...sample.packPath!.split('/')]),
        );
        return;
      }
      if (sample._copyFailed) return;
    }
    sample.duration ??= await x.readDuration(path);
    final measured = sampleOriginOf(
      path: path,
      projectDir: projectDir,
      kind: ref.kind,
      use: ref.use,
      duration: sample.duration,
      sizeBytes: sample.sizeBytes,
    );
    if (measured != origin) sample._addOrigin(measured);
    if (measured.isOwnAudio && !x.includeOwnAudio) return;

    sample.category = sampleCategoryOf(
      path,
      duration: sample.duration,
      projectDir: _inside(projectDir, path),
    );
    _readTraits(sample, path, projectDir, project.bpm);
    final folder = [
      if (sample.origin.isOwnAudio) kOwnAudioFolder,
      sample.category.folder,
    ].join('/');
    final naming = x.naming;
    final String name;
    if (naming == null) {
      name = packFileName(p.basename(path), sample.category);
    } else {
      final folderKey = folder.toLowerCase();
      final number = _nextNumber[folderKey] ??= naming.nextNumber(
        sample.category,
        [
          for (final t in _taken)
            if (p.posix.dirname(t) == folderKey) p.posix.basename(t),
        ],
      );
      _nextNumber[folderKey] = number + 1;
      name = naming.fileName(
        category: sample.category,
        number: number,
        original: p.basename(path),
        bpm: sample.bpm,
        key: sample.key,
      );
    }
    final relative = _unique('$folder/$name', _taken);
    _progress(SamplePackPhase.copying, index, total, relative);
    final target = p.joinAll([x.destination, ...relative.split('/')]);
    try {
      await Directory(p.dirname(target)).create(recursive: true);
      final part = '$target.part';
      await File(path).copy(part);
      await File(part).rename(target);
      final stat = await File(target).stat();
      _written.add(_PackFile(target, relative, stat.size, stat.modified));
      _copiedFrom[target] = path;
      sample
        ..packPath = relative
        ..added = true;
    } catch (_) {
      sample._copyFailed = true;
    }
  }

  /// What [sample]'s name, then its folders, say about its tempo and key —
  /// inside a project only its own subfolders, never the song's folder —
  /// and, for a loop that fits whole bars at it, its project's tempo. A
  /// one-shot has no tempo, whatever the kit it came from was made at.
  void _readTraits(
    PackSample sample,
    String path,
    String projectDir,
    double? projectBpm,
  ) {
    final name = sampleTraitsOf(p.basenameWithoutExtension(path));
    var bpm = name.bpm;
    var key = name.key;
    final folders = p.isWithin(projectDir, path)
        ? p.split(p.relative(p.dirname(path), from: projectDir))
            .where((f) => f != '.')
        : p.split(p.dirname(path)).skip(1);
    for (final folder in folders.toList().reversed.take(3)) {
      final t = sampleTraitsOf(folder);
      bpm ??= t.bpm;
      key ??= t.key;
    }
    final length = sample.duration;
    if (bpm == null && length != null && projectBpm != null) {
      bpm = bpmFromLoopLength(length, projectBpm);
    }
    if (length != null && length.inMilliseconds <= 1500) bpm = null;
    sample
      ..bpm = bpm
      ..key = key;
  }

  /// Compares [sample] (whose first copy is [path]) with the pack and the
  /// samples compared so far. Returns the sample it is: [sample] itself —
  /// now linked to its copy in the pack, if the pack has one — or the
  /// earlier sample with the same content, which [sample] is merged into.
  Future<PackSample> _index(PackSample sample, String path) async {
    sample._indexed = true;
    final size = sample.sizeBytes;
    final same = _bySize[size] ?? const <_Entry>[];
    String? hash;
    for (final other in same) {
      hash ??= await _hash(path);
      if (await _hash(other.path) != hash) continue;
      final earlier = other.sample;
      if (earlier != null && !identical(earlier, sample)) {
        _merge(sample, into: earlier);
        return earlier;
      }
      if (other.packPath != null) {
        sample.packPath = other.packPath;
        other.sample = sample;
        return sample;
      }
    }
    _bySize.putIfAbsent(size, () => []).add(_Entry(path, sample: sample));
    return sample;
  }

  void _merge(PackSample from, {required PackSample into}) {
    for (final path in from.paths) {
      if (!into.paths.contains(path)) into.paths.add(path);
      _byPath[_pathKey(path)] = into;
    }
    into.songs.addAll(from.songs);
    into.profiles.addAll(from.profiles);
    for (final o in from._origins) {
      into._addOrigin(o);
    }
    into.duration ??= from.duration;
    samples.remove(from);
  }

  Future<String> _hash(String path) async =>
      _hashes[path] ??= await x.hashFile(path);

  static String? _inside(String projectDir, String path) =>
      p.isWithin(projectDir, path) ? projectDir : null;

  /// `Kick/x.wav`, or `Kick/x (2).wav` when that is taken (case-insensitive:
  /// Windows and macOS would see the same file).
  static String _unique(String relative, Set<String> taken) {
    var candidate = relative;
    final dot = relative.lastIndexOf('.');
    final stem = dot < 0 ? relative : relative.substring(0, dot);
    final ext = dot < 0 ? '' : relative.substring(dot);
    for (var n = 2; !taken.add(candidate.toLowerCase()); n++) {
      candidate = '$stem ($n)$ext';
    }
    return candidate;
  }

  static String _safeName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceFirst(RegExp(r'[. ]+$'), '')
        .trim();
    return cleaned.isEmpty ? 'MIDI' : cleaned;
  }

  /// Every audio file in the pack folder, outside its MIDI folder.
  static Future<List<_PackFile>> _packAudioFiles(String root) async {
    final dir = Directory(root);
    if (!await dir.exists()) return const [];
    final out = <_PackFile>[];
    await for (final entity
        in dir.list(recursive: true, followLinks: false).handleError((_) {})) {
      if (entity is! File || !isSampleAudioFile(entity.path)) continue;
      final relative = p.relative(entity.path, from: root).replaceAll(r'\', '/');
      if (relative.startsWith('$kMidiFolder/')) continue;
      try {
        final stat = await entity.stat();
        out.add(_PackFile(entity.path, relative, stat.size, stat.modified));
      } catch (_) {
        // Gone while listing.
      }
    }
    return out;
  }
}

/// A path as a map key: normalised, and case-blind where the file system is.
String _pathKey(String path) {
  final n = p.normalize(path);
  return Platform.isLinux ? n : n.toLowerCase();
}

/// A file compared by content: a sample's copy, or a file in the pack.
class _Entry {
  _Entry(this.path, {this.sample, this.packPath});
  final String path;
  PackSample? sample;
  final String? packPath;
}

class _PackFile {
  const _PackFile(this.path, this.relative, this.size, this.modified);
  final String path;
  final String relative;
  final int size;
  final DateTime modified;
}

/// The SHA-1 of the file at [path], streamed in a background isolate so
/// neither a large file nor the hashing sits in the UI's memory or time.
Future<String> sha1OfFile(String path) => Isolate.run(
      () async => (await sha1.bind(File(path).openRead()).first).toString(),
    );

/// `sample_pack_manifest.json`: each pack file's size, modification time and
/// (once one was needed) hash, by path relative to the pack.
class _Manifest {
  _Manifest(this._entries);

  final Map<String, Map<String, dynamic>> _entries;

  static Future<_Manifest> read(String root) async {
    try {
      final json = jsonDecode(
        await File(p.join(root, kSamplePackManifest)).readAsString(),
      );
      final files = (json as Map)['files'] as Map;
      return _Manifest({
        for (final e in files.entries)
          if (e.value is Map) e.key as String: Map<String, dynamic>.from(e.value),
      });
    } catch (_) {
      return _Manifest({});
    }
  }

  /// The stored hash of [f], if the file is unchanged since it was taken.
  String? hashFor(_PackFile f) {
    final entry = _entries[f.relative];
    if (entry == null) return null;
    if (entry['size'] != f.size ||
        entry['modified'] != f.modified.millisecondsSinceEpoch) {
      return null;
    }
    return entry['sha1'] as String?;
  }

  static Future<void> write(
    String root,
    List<_PackFile> files,
    Map<String, String> hashes,
  ) async {
    final json = {
      'version': 1,
      'files': {
        for (final f in files)
          f.relative: {
            'size': f.size,
            'modified': f.modified.millisecondsSinceEpoch,
            'sha1': ?hashes[f.path],
          },
      },
    };
    await File(p.join(root, kSamplePackManifest)).writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
      flush: true,
    );
  }
}

/// UTF-8's byte order mark, so Excel reads accented names correctly.
const _bom = '\uFEFF';

/// `sample_pack_report.csv`: one row per distinct sample, most used first —
/// where it is in the pack (empty when left out), its category, how many
/// songs use it and which, its origin, length and the file it was copied
/// from.
String samplePackReportCsv(List<PackSample> samples) {
  final out = StringBuffer(_bom)
    ..writeln([
      'pack_file',
      'category',
      'songs',
      'song_names',
      'profiles',
      'origin',
      'seconds',
      'bpm',
      'key',
      'source_file',
      'other_copies',
    ].join(','));
  for (final s in samples) {
    out.writeln([
      s.packPath,
      s.category.folder,
      s.songs.length,
      (s.songs.values.toSet().toList()..sort()).join('; '),
      (s.profiles.toList()..sort()).join('; '),
      s.origin.name,
      s.duration == null
          ? null
          : (s.duration!.inMilliseconds / 1000).toStringAsFixed(2),
      s.bpm == null ? null : formatBpm(s.bpm!),
      s.key,
      s.paths.first,
      s.paths.skip(1).join('; '),
    ].map(csvCell).join(','));
  }
  return out.toString();
}

/// `sample_pack_missing.csv`: samples that couldn't be found and projects
/// that couldn't be read.
String samplePackProblemsCsv(List<SamplePackProblem> problems) {
  final out = StringBuffer(_bom)
    ..writeln(['problem', 'project', 'profile', 'sample', 'where'].join(','));
  for (final x in problems) {
    out.writeln([x.problem.code, x.project, x.profile, x.sample, x.where]
        .map(csvCell)
        .join(','));
  }
  return out.toString();
}
