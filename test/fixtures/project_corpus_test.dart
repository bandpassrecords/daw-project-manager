// The DAW project collection: real projects, one folder each under
// test/fixtures/projects/<daw>/<name>/ (a project, or one song's versions),
// read with the app's own readers and compared with what was recorded for
// them in <name>.expected.json, by project file.
//
// Adding one:
//   1. scripts/add_test_fixture.ps1 -Daw cubase -Project "D:\...\Song\Song.cpr"
//      (copies the project's folder, leaving out backups, bounces and big audio)
//   2. UPDATE_FIXTURES=1 flutter test test/fixtures/project_corpus_test.dart
//      writes its .expected.json
//   3. Read the .expected.json — tempo, key, clips, samples — and commit both.
// From then on any change to a reader that alters what it reads fails here,
// on every platform CI runs.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/services/metadata_extractor.dart';
import 'package:daw_project_manager/services/project_inspector/project_anatomy_reader.dart';
import 'package:daw_project_manager/services/sample_pack/project_sample_reader.dart';

import 'fixture_collection.dart';

final _update = Platform.environment['UPDATE_FIXTURES'] == '1';

/// What the readers make of [project], in a form that is the same on every
/// machine: no absolute paths, notes and events summarised by a hash.
Future<Map<String, Object?>> readFixture(File project) async {
  final meta = await MetadataExtractor.extractMetadata(project.path);
  final refs = await readProjectSampleReferences(project.path);
  final clips = meta.midiClips ?? const <MidiClip>[];
  final anatomy = await readProjectAnatomy(project.path);
  return {
    'dawType': meta.dawType,
    'dawVersion': meta.dawVersion,
    'bpm': meta.bpm,
    'key': meta.key,
    'markers': [for (final m in meta.markers ?? const []) m.name],
    'stats': meta.stats?.toMap(),
    'midiClips': [
      for (final c in clips)
        {
          'name': c.name,
          'track': c.trackName,
          'ppq': c.ppq,
          'lengthTicks': c.lengthTicks,
          'notes': c.notes.length,
          'events': c.events.length,
          'content': clipContentHash(c),
        },
    ],
    'sampleReferences': [
      for (final r in refs)
        {
          'file': r.fileName,
          'use': r.use.name,
          if (r.kind != null) 'kind': r.kind!.name,
        },
    ],
    // What the Inspector shows (#199), for the DAWs whose channels it
    // reads; the rest would only repeat the stats and references above.
    if (anatomy.channels != null) 'inspector': inspectorSummary(anatomy),
  };
}

/// The Inspector's reading, a line per channel and per plug-in so a change
/// to a reader shows as a readable diff.
Map<String, Object?> inspectorSummary(ProjectAnatomy a) {
  String db(double? v) => v == null
      ? '-'
      : v.isInfinite
          ? '-inf dB'
          : '${v.toStringAsFixed(1)} dB';
  String pan(double? v) =>
      v == null ? '-' : (v.abs() < 0.005 ? 'C' : '${v < 0 ? 'L' : 'R'}${(v.abs() * 100).round()}');
  final io = a.audioIo;
  return {
    'savedWith': a.savedWith,
    'sampleRate': a.sampleRate,
    'bitDepth': a.bitDepth,
    'timeSignature':
        a.timeSignature == null ? null : '${a.timeSignature!.$1}/${a.timeSignature!.$2}',
    'channels': [
      for (final c in a.channels!)
        [
          '${c.name} [${c.kind.name}]',
          if (c.folder != null) 'in ${c.folder}',
          if (c.kind != AnatomyChannelKind.folder) ...[
            '-> ${c.output ?? '-'}',
            '${db(c.volumeDb)} ${pan(c.pan)}${c.muted == true ? ' mute' : ''}'
                '${c.soloed == true ? ' solo' : ''}',
            if (c.instrument != null)
              'instrument ${c.instrument}'
                  '${c.instrumentPreset == null ? '' : ' (${c.instrumentPreset})'}',
            if (c.inserts.isNotEmpty)
              'inserts ${[
                for (final i in c.inserts)
                  '${i.slot}:${i.plugin}${i.deactivated == true ? ' (off)' : ''}'
                      '${i.preset == null ? '' : ' (${i.preset})'}',
              ].join(', ')}',
            if (c.sends.isNotEmpty)
              'sends ${[
                for (final s in c.sends)
                  '${s.destination ?? '?'}${s.sideChainOf == null ? '' : ' sc:${s.sideChainOf}'}'
                      ' ${db(s.levelDb)}${s.on ? '' : ' off'}${s.preFader ? ' pre' : ''}',
              ].join(', ')}',
          ],
        ].join(' | '),
    ],
    'plugins': [
      for (final pl in a.plugins)
        [
          pl.name,
          pl.role?.name ?? '-',
          switch (pl.stock) {
            true => 'stock',
            false => 'third-party',
            null => '-',
          },
          if (pl.instances != null) 'x${pl.instances}',
          if (pl.vendor != null) pl.vendor!,
          if (pl.format != null) pl.format!,
        ].join(' | '),
    ],
    if (io != null)
      'audioIo': {
        'driver': io.driver,
        'platform': io.platform,
        'inputBuses': [
          for (final b in io.inputBuses) '${b.name} <- ${b.ports.join(', ')}',
        ],
        'outputBuses': [
          for (final b in io.outputBuses) '${b.name} -> ${b.ports.join(', ')}',
        ],
        'midiInputs': io.midiInputs,
        'midiOutputs': io.midiOutputs,
      },
  };
}

const _json = JsonEncoder.withIndent('  ');

void main() {
  final fixtures = allFixtures();

  test('the collection has projects in it', () {
    expect(fixtures, isNotEmpty, reason: 'nothing under ${fixtureRoot.path}');
  });

  for (final f in fixtures) {
    test('${f.daw} / ${f.name} reads as recorded', () async {
      final projects = f.projectFiles;
      expect(projects, isNotEmpty, reason: '${f.folder} holds no project file');

      final read = {
        for (final project in projects) p.basename(project.path): await readFixture(project),
      };
      final expectedFile = f.expectedFile;
      final actual = '${_json.convert(read)}\n';
      if (_update) {
        await expectedFile.writeAsString(actual);
        return;
      }
      expect(
        expectedFile.existsSync(),
        isTrue,
        reason: 'no ${expectedFile.path} — run with UPDATE_FIXTURES=1 and review it',
      );
      final expected = await expectedFile.readAsString();
      expect(
        jsonDecode(actual),
        jsonDecode(expected),
        reason: 'what the readers make of $f changed; if that is intended, '
            'rerun with UPDATE_FIXTURES=1 and review the diff',
      );
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
