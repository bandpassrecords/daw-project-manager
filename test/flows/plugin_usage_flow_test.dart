// Plug-in usage across a library (#225), on a real one: deep scan a
// folder of Cubase 13 versions, then count what the scan stored
// — no project file read for it — and add instances from the Cubase
// tracks read for the insert reference page.

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/library/plugin_usage.dart';
import 'package:daw_project_manager/services/template_export/template_export_service.dart';

import 'flow_library.dart';

void main() {
  late FlowLibrary lib;
  setUp(
    () async => lib = await FlowLibrary.open(
      only: ['cubase/Test 2025 (Cubase 13)'],
    ),
  );
  tearDown(() async => lib.close());

  test('a scan counts nothing; a deep scan counts every version', () async {
    await lib.scan();
    expect(buildPluginUsage(lib.projects).plugins, isEmpty,
        reason: 'a lightweight scan reads no plug-ins');

    await lib.deepScan();
    final report = buildPluginUsage(lib.projects);
    final files = lib.projects.where((p) => !p.isVirtual).length;
    expect(report.projectsRead, files);
    expect(report.projectsUnread, 0);
    expect(report.songs, files, reason: 'not stacked: each its own song');
    final serum = report.plugins.firstWhere((u) => u.name == 'Serum');
    expect(serum.projects.length, greaterThan(1));
    expect(serum.instances, isNull, reason: 'no tracks read for it yet');

    // Stacked, the versions are one song.
    final stack = await lib.repo.stackProjects(
      memberIds: [for (final p in lib.projects) p.id],
    );
    final stacked = buildPluginUsage(lib.projects);
    expect(stacked.songs, 1);
    expect(stacked.plugins.every((u) => u.rare), isTrue);
    expect(stacked.plugins.firstWhere((u) => u.name == 'Serum').projects,
        hasLength(serum.projects.length));
    expect(projectUsesPlugin(stack, 'serum', lib.projects), isTrue);
  });

  test('instances come from the Cubase tracks read for it', () async {
    await lib.deepScan();
    final tracks = <String, List<CubaseTrack>>{};
    for (final p in lib.projects.where((p) => !p.isVirtual)) {
      final read = await readCubaseTracks(p.filePath);
      if (read != null) tracks[p.id] = read;
    }
    final report = buildPluginUsage(
      lib.projects,
      tracksOf: (p) => tracks[p.id],
    );
    expect(report.projectsWithInstances, tracks.length);
    final ott = report.plugins.firstWhere((u) => u.name == 'OTT');
    expect(ott.instances, greaterThanOrEqualTo(11),
        reason: 'test-01 alone has 11');
    expect(report.chains, isNotEmpty);
  });
}
