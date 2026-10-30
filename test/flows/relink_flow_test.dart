// Relinking a real project (#214, #219): every audio file test-01.cpr
// uses is "moved" into a folder of the flow's own, and a relinked copy is
// written pointing there. The stored paths name the machine the project
// was made on, so the flow never asks whether they exist — it moves them
// all, as a folder rule would.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/sample_reference.dart';
import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_copy.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_writer.dart';

import 'flow_library.dart';

void main() {
  late FlowLibrary lib;

  setUp(() async =>
      lib = await FlowLibrary.open(only: ['cubase/Test 2025 (Cubase 13)']));
  tearDown(() async => lib.close());

  test('a Cubase 13 project relinked to a new folder reads the same, moved',
      () async {
    final project = lib.fixtures.single.projectFiles
        .singleWhere((f) => p.basename(f.path) == 'test-01.cpr');
    final original = await project.readAsBytes();
    final before = CubaseProjectParser(original);
    final refs = before.readSampleReferences();

    // Every file the project's own pool and events name moves; paths in
    // plug-in state aren't the project's to rewrite.
    final moved = p.join(lib.scratch.path, 'Moved');
    final moves = <String, String>{};
    for (final r in refs.where((r) => r.use != SampleUse.plugin)) {
      final target = p.join(moved, r.fileName);
      await File(target).create(recursive: true);
      moves[r.candidates.first] = target;
    }
    expect(moves, isNotEmpty);

    final copy = await writeRelinkedCopy(
      projectPath: project.path,
      moves: moves,
    );
    expect(p.basename(copy.path!), 'test-01 (relinked).cpr');
    // The temp folder is shorter than the project's own folders, so every
    // move fits; one that didn't would be refused, never half-written.
    expect(copy.refused.values.toSet(), isNot(contains(RelinkRefusal.notFound)));
    expect(copy.relinked.length + copy.refused.length, moves.length);
    expect(copy.relinked, isNotEmpty);

    expect(await project.readAsBytes(), original, reason: 'only read');
    final written = await File(copy.path!).readAsBytes();
    expect(written.length, original.length, reason: 'rewritten in place');
    final after = CubaseProjectParser(written);
    final paths = {
      for (final r in after.readSampleReferences())
        if (r.use != SampleUse.plugin) r.candidates.first,
    };
    for (final stored in copy.relinked) {
      expect(paths, contains(moves[stored]));
    }

    // Nothing else changed: tracks, mixer, plug-ins and MIDI read as before.
    String tracks(CubaseProjectParser parser) => [
          for (final t in parser.readTracks())
            '${t.name}|${t.type}|${t.output}|${t.volume}|'
                '${t.inserts.map((i) => i.plugin).join(',')}',
        ].join('\n');
    expect(tracks(after), tracks(before));
    expect(after.readStats().plugins, before.readStats().plugins);
    expect(after.readMidiClips().length, before.readMidiClips().length);

    // The copy is a project of its own on the next scan.
    await lib.scan();
    expect(lib.projectOf(File(copy.path!)).filePath, copy.path);
  });
}
