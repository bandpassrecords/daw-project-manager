import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import '../../models/midi_clip.dart';
import '../../models/midi_clip_naming.dart';
import '../../models/music_project.dart';
import '../../models/stored_midi_clips.dart';
import '../../utils/time_signature.dart';
import 'midi_file_writer.dart';

/// What counts as a melodic clip worth keeping, and what leaves out the rest.
///
/// A drum pattern, a one-note bass pulse and a two-note stab say nothing on
/// their own; a lead, an arp or a melody does. Defaults keep those and
/// nothing else, [roles] widens or narrows the net.
class MelodicExportOptions {
  const MelodicExportOptions({
    this.roles = const {
      MidiClipRole.melody,
      MidiClipRole.lead,
      MidiClipRole.arp,
    },
    this.minNotes = 8,
    this.minDistinctPitches = 3,
    this.minBeats = 4,
  });

  /// The roles (see [suggestMidiClipRole]) that are exported.
  final Set<MidiClipRole> roles;

  /// Fewer notes than this is a fragment.
  final int minNotes;

  /// A line that stays on one or two pitches is a pulse, not a melody.
  final int minDistinctPitches;

  /// Shorter than this (a bar of 4/4) is a hit, not a phrase.
  final double minBeats;

  MelodicExportOptions copyWith({Set<MidiClipRole>? roles}) =>
      MelodicExportOptions(
        roles: roles ?? this.roles,
        minNotes: minNotes,
        minDistinctPitches: minDistinctPitches,
        minBeats: minBeats,
      );
}

/// What a clip looks like, in numbers a catalog can sort and filter by.
class MelodicStats {
  const MelodicStats({
    required this.noteCount,
    required this.distinctPitches,
    required this.lowestPitch,
    required this.highestPitch,
    required this.maxPolyphony,
    required this.bars,
    required this.notesPerBar,
    required this.averageVelocity,
    this.grid,
  });

  final int noteCount;
  final int distinctPitches;
  final int lowestPitch;
  final int highestPitch;

  /// Most notes sounding at once: 1 for a single line, more for chords.
  final int maxPolyphony;
  final int bars;
  final double notesPerBar;
  final int averageVelocity;

  /// The finest grid the notes keep to ("1-16"), or null for none.
  final String? grid;

  int get span => highestPitch - lowestPitch;
}

const _noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
];

/// A pitch's name the way Cubase and Ableton print it: middle C (60) is C3.
String noteNameOf(int pitch) => '${_noteNames[pitch % 12]}${(pitch ~/ 12) - 2}';

/// The numbers of [clip]; null when it has no notes.
MelodicStats? melodicStatsOf(
  MidiClip clip, {
  TimeSignature signature = TimeSignature.common,
}) {
  final notes = clip.notes;
  if (notes.isEmpty) return null;
  final pitches = notes.map((n) => n.pitch).toSet();
  final bars = midiClipBars(clip, signature);

  // Sweep the note edges for the most that sound together.
  final edges = <(int, int)>[
    for (final n in notes) ...[(n.startTick, 1), (n.endTick, -1)],
  ]..sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2); // ends before starts
    });
  var sounding = 0, most = 0;
  for (final (_, delta) in edges) {
    sounding += delta;
    most = math.max(most, sounding);
  }

  return MelodicStats(
    noteCount: notes.length,
    distinctPitches: pitches.length,
    lowestPitch: pitches.reduce(math.min),
    highestPitch: pitches.reduce(math.max),
    maxPolyphony: most,
    bars: bars,
    notesPerBar: notes.length / bars,
    averageVelocity:
        (notes.fold<int>(0, (sum, n) => sum + n.velocity) / notes.length)
            .round(),
    grid: midiClipGrid(clip),
  );
}

/// The role [clip] has when it is worth exporting under [options], or null.
///
/// Clips mostly on MIDI channel 10 are drums whatever they are called, and
/// are never kept.
MidiClipRole? melodicRoleOf(
  MidiClip clip, {
  MelodicExportOptions options = const MelodicExportOptions(),
}) {
  final stats = melodicStatsOf(clip);
  if (stats == null) return null;
  if (stats.noteCount < options.minNotes ||
      stats.distinctPitches < options.minDistinctPitches ||
      clip.lengthBeats < options.minBeats) {
    return null;
  }
  final onDrumChannel = clip.notes.where((n) => n.channel == 9).length;
  if (onDrumChannel * 2 > clip.notes.length) return null;

  final role = suggestMidiClipRole(clip);
  return options.roles.contains(role) ? role : null;
}

/// One clip chosen for the catalog, with where it came from.
class CatalogEntry {
  CatalogEntry({
    required this.project,
    required this.clip,
    required this.role,
    required this.stats,
    this.alsoIn = const [],
  });

  final MusicProject project;
  final MidiClip clip;
  final MidiClipRole role;
  final MelodicStats stats;

  /// Other projects holding exactly these notes — usually versions of the
  /// same song.
  final List<String> alsoIn;

  /// Set once the files are planned: the path inside the export.
  String relativePath = '';
}

/// Every clip worth keeping across [projects], projects by name and clips in
/// the order the DAW holds them. Projects without stored clips (never read
/// for MIDI) and stacks, which own no file, contribute nothing.
List<CatalogEntry> selectMelodicClips(
  Map<String, StoredMidiClips> stored,
  Map<String, MusicProject> projects, {
  MelodicExportOptions options = const MelodicExportOptions(),
}) {
  final ids = stored.keys
      .where((id) => projects[id] != null && !projects[id]!.isVirtual)
      .toList()
    ..sort((a, b) => projects[a]!
        .displayName
        .toLowerCase()
        .compareTo(projects[b]!.displayName.toLowerCase()));

  final entries = <CatalogEntry>[];
  final holders = <String, Set<String>>{}; // content key → project names
  for (final id in ids) {
    final project = projects[id]!;
    for (final clip in stored[id]!.clips) {
      final role = melodicRoleOf(clip, options: options);
      if (role == null) continue;
      holders.putIfAbsent(clip.contentKey, () => {}).add(project.displayName);
      entries.add(CatalogEntry(
        project: project,
        clip: clip,
        role: role,
        stats: melodicStatsOf(clip)!,
      ));
    }
  }
  return [
    for (final e in entries)
      CatalogEntry(
        project: e.project,
        clip: e.clip,
        role: e.role,
        stats: e.stats,
        alsoIn: [
          for (final name in holders[e.clip.contentKey]!)
            if (name != e.project.displayName) name,
        ]..sort(),
      ),
  ];
}

/// "Lead", "Arp"… the way the catalog writes a role.
String roleLabel(MidiClipRole role) =>
    role.name[0].toUpperCase() + role.name.substring(1);

String _bpmText(double bpm) => bpm == bpm.roundToDouble()
    ? bpm.round().toString()
    : bpm.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

/// Gives every entry its place in the export: a folder per project, named
/// after it (made unique), and a numbered file name that says role, tempo,
/// key and length — "01 Lead - 140BPM - A minor - 4 bars.mid".
void planMelodicFiles(List<CatalogEntry> entries) {
  final folderOf = <String, String>{}; // project id → folder
  final usedFolders = <String>{};
  final counts = <String, int>{};
  for (final e in entries) {
    counts[e.project.id] = (counts[e.project.id] ?? 0) + 1;
  }
  final numbers = <String, int>{};
  final usedNames = <String, Set<String>>{};
  const template = MidiNamingTemplate(
    fields: [
      MidiNameField.name,
      MidiNameField.role,
      MidiNameField.bpm,
      MidiNameField.key,
      MidiNameField.bars,
    ],
  );

  for (final e in entries) {
    final folder = folderOf.putIfAbsent(e.project.id, () {
      var base = safeFileNamePart(e.project.displayName);
      if (base.isEmpty) base = 'Project';
      var name = base, n = 2;
      while (!usedFolders.add(name.toLowerCase())) {
        name = '$base ($n)';
        n++;
      }
      return name;
    });
    final number = numbers[e.project.id] = (numbers[e.project.id] ?? 0) + 1;
    final bpm = e.project.bpm;
    final key = e.project.musicalKey?.trim();
    var file = midiTemplateFileName(
      template,
      {
        MidiNameField.name: e.clip.label,
        MidiNameField.role: roleLabel(e.role),
        MidiNameField.bpm: bpm == null || bpm <= 0 ? null : '${_bpmText(bpm)}BPM',
        MidiNameField.key: key == null || key.isEmpty ? null : key,
        MidiNameField.bars: '${e.stats.bars} bar${e.stats.bars == 1 ? '' : 's'}',
      },
      number: number,
      width: math.max(2, counts[e.project.id].toString().length),
    );
    final used = usedNames.putIfAbsent(e.project.id, () => {});
    final stem = file.substring(0, file.length - 4);
    var n = 2;
    while (!used.add(file.toLowerCase())) {
      file = '$stem ($n).mid';
      n++;
    }
    e.relativePath = '$folder/$file';
  }
}

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  return RegExp(r'[",\n\r]').hasMatch(text)
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

const _columns = [
  'project',
  'daw',
  'project_modified',
  'status',
  'tags',
  'file',
  'track',
  'clip',
  'role',
  'bars',
  'beats',
  'tempo_bpm',
  'key',
  'notes',
  'distinct_pitches',
  'lowest',
  'highest',
  'max_polyphony',
  'notes_per_bar',
  'avg_velocity',
  'grid',
  'copies_in_project',
  'also_in_projects',
  'project_file',
];

List<Object?> _row(CatalogEntry e) => [
      e.project.displayName,
      e.project.dawType,
      e.project.lastModifiedAt.toIso8601String().substring(0, 10),
      e.project.status,
      e.project.tags.join('; '),
      e.relativePath,
      e.clip.trackName,
      e.clip.name,
      e.role.name,
      e.stats.bars,
      double.parse(e.clip.lengthBeats.toStringAsFixed(2)),
      e.project.bpm,
      e.project.musicalKey,
      e.stats.noteCount,
      e.stats.distinctPitches,
      noteNameOf(e.stats.lowestPitch),
      noteNameOf(e.stats.highestPitch),
      e.stats.maxPolyphony,
      double.parse(e.stats.notesPerBar.toStringAsFixed(1)),
      e.stats.averageVelocity,
      e.stats.grid,
      e.clip.occurrences,
      e.alsoIn.join('; '),
      e.project.filePath,
    ];

/// `catalog.csv`: one row per exported file, for a spreadsheet.
String melodicCatalogCsv(List<CatalogEntry> entries) {
  final out = StringBuffer('${_columns.join(',')}\n');
  for (final e in entries) {
    out.writeln(_row(e).map(_csvCell).join(','));
  }
  return out.toString();
}

/// `catalog.json`: the same rows as objects, with a header, for scripts.
Map<String, dynamic> melodicCatalogJson(
  List<CatalogEntry> entries, {
  required DateTime generated,
}) =>
    {
      'meta': {
        'generated': generated.toUtc().toIso8601String(),
        'files': entries.length,
        'projects': entries.map((e) => e.project.id).toSet().length,
      },
      'clips': [
        for (final e in entries)
          {
            for (var i = 0; i < _columns.length; i++)
              _columns[i]: _row(e)[i],
          },
      ],
    };

/// `catalog.md`: the catalog a person reads, a section per project.
String melodicCatalogMarkdown(
  List<CatalogEntry> entries, {
  required DateTime generated,
}) {
  final out = StringBuffer()
    ..writeln('# Melodic MIDI catalog')
    ..writeln()
    ..writeln('${entries.length} clips from '
        '${entries.map((e) => e.project.id).toSet().length} projects, '
        '${generated.toIso8601String().substring(0, 10)}. '
        'Leads, arps and melodies only; drums and short fragments are left '
        'out.')
    ..writeln();

  final byProject = <String, List<CatalogEntry>>{};
  for (final e in entries) {
    (byProject[e.project.id] ??= []).add(e);
  }
  for (final group in byProject.values) {
    final project = group.first.project;
    final facts = [
      if (project.dawType != null) project.dawType!,
      if (project.bpm != null) '${_bpmText(project.bpm!)} BPM',
      if (project.musicalKey != null && project.musicalKey!.trim().isNotEmpty)
        project.musicalKey!.trim(),
      project.lastModifiedAt.toIso8601String().substring(0, 10),
      project.status,
      if (project.tags.isNotEmpty) project.tags.join(', '),
    ];
    out
      ..writeln('## ${project.displayName}')
      ..writeln()
      ..writeln(facts.join(' · '))
      ..writeln()
      ..writeln('| File | Role | Bars | Notes | Range | Per bar | Also in |')
      ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
    for (final e in group) {
      final file = e.relativePath.split('/').last;
      out.writeln('| ${file.replaceAll('|', r'\|')} '
          '| ${roleLabel(e.role)} '
          '| ${e.stats.bars} '
          '| ${e.stats.noteCount} '
          '| ${noteNameOf(e.stats.lowestPitch)}–${noteNameOf(e.stats.highestPitch)} '
          '| ${e.stats.notesPerBar.toStringAsFixed(1)} '
          '| ${e.alsoIn.join(', ').replaceAll('|', r'\|')} |');
    }
    out.writeln();
  }
  return out.toString();
}

/// What an export wrote.
class MelodicExportResult {
  const MelodicExportResult({
    required this.directory,
    required this.clips,
    required this.projects,
    required this.projectsWithoutMidi,
  });

  final String directory;
  final int clips;
  final int projects;

  /// Projects that have no stored MIDI at all: never read for it, so
  /// nothing could be said about them.
  final int projectsWithoutMidi;
}

/// Writes the melodic clips of [projects] into [directory]: a folder per
/// project holding the `.mid` files (each with its project's tempo and key),
/// and `catalog.csv`, `catalog.json` and `catalog.md` at the top.
///
/// Reads nothing from the projects themselves: it uses the clips stored by
/// each project's last full read, so it is quick and works offline, but only
/// covers projects that have been read ([MelodicExportResult
/// .projectsWithoutMidi] counts the others).
Future<MelodicExportResult> exportMelodicClips(
  Map<String, StoredMidiClips> stored,
  List<MusicProject> projects, {
  required Directory directory,
  MelodicExportOptions options = const MelodicExportOptions(),
  DateTime? now,
}) async {
  final byId = {for (final project in projects) project.id: project};
  final entries = selectMelodicClips(stored, byId, options: options);
  planMelodicFiles(entries);
  final generated = now ?? DateTime.now();

  for (final e in entries) {
    final export = MidiExport(
      e.clip,
      bpm: e.project.bpm,
      musicalKey: e.project.musicalKey,
    );
    final file = File(p.joinAll([directory.path, ...e.relativePath.split('/')]));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(export.encode());
  }
  await directory.create(recursive: true);
  await File(p.join(directory.path, 'catalog.csv'))
      .writeAsString(melodicCatalogCsv(entries));
  await File(p.join(directory.path, 'catalog.json')).writeAsString(
    const JsonEncoder.withIndent('  ')
        .convert(melodicCatalogJson(entries, generated: generated)),
  );
  await File(p.join(directory.path, 'catalog.md')).writeAsString(
    melodicCatalogMarkdown(entries, generated: generated),
  );

  final withMidi = stored.keys
      .where((id) => byId[id] != null && !byId[id]!.isVirtual)
      .length;
  final readable = projects.where((x) => !x.isVirtual).length;
  return MelodicExportResult(
    directory: directory.path,
    clips: entries.length,
    projects: entries.map((e) => e.project.id).toSet().length,
    projectsWithoutMidi: math.max(0, readable - withMidi),
  );
}
