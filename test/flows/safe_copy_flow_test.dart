// Safe Copy on a real project (#220): test-01.cpr with Serum (instrument
// tracks), OTT (inserts) and HALion Sonic (the rack) switched off — the
// copy Cubase 13 was asked to open.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/safe_copy/safe_copy.dart';

import 'flow_library.dart';

void main() {
  late FlowLibrary lib;

  setUp(() async =>
      lib = await FlowLibrary.open(only: ['cubase/Test 2025 (Cubase 13)']));
  tearDown(() async => lib.close());

  test('a Cubase 13 Safe Copy reads the same, its chosen plug-ins off',
      () async {
    final project = lib.fixtures.single.projectFiles
        .singleWhere((f) => p.basename(f.path) == 'test-01.cpr');
    final original = await project.readAsBytes();

    final copy = await writeSafeCopy(
      projectPath: project.path,
      plugins: {'Serum', 'OTT', 'HALion Sonic'},
    );
    expect(p.basename(copy.path!), 'test-01 (safe copy).cpr');
    expect(copy.switchedOff, {'Serum': 4, 'OTT': 11, 'HALion Sonic': 2});
    expect(await project.readAsBytes(), original, reason: 'only read');

    final written = await File(copy.path!).readAsBytes();
    expect(written.length, original.length);
    var changed = 0;
    for (var i = 0; i < written.length; i++) {
      if (written[i] != original[i]) changed++;
    }
    expect(changed, copy.total, reason: 'one byte per instance');

    final before = CubaseProjectParser(original);
    final after = CubaseProjectParser(written);
    String mixer(CubaseProjectParser parser) => [
          for (final t in parser.readTracks())
            '${t.name}|${t.type}|${t.output}|${t.volume}|${t.instrument}|'
                '${t.inserts.map((i) => i.plugin).join(',')}',
        ].join('\n');
    expect(mixer(after), mixer(before));
    expect(after.readStats().plugins, before.readStats().plugins);
    expect(after.readSampleReferences().length,
        before.readSampleReferences().length);
    final ott = after
        .readTracks()
        .expand((t) => t.inserts)
        .where((i) => cleanPluginName(i.plugin) == 'OTT');
    expect(ott, hasLength(11));
    expect(ott.every((i) => i.deactivated == true), isTrue);
  });
}
