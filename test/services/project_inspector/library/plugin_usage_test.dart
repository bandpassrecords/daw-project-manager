import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/library/plugin_usage.dart';

import '../../../helpers/test_factories.dart';

MusicProject _project(
  String id, {
  List<String>? plugins,
  String daw = 'Cubase',
  String? stackId,
  bool virtual = false,
  DateTime? at,
}) => TestFactories.makeProject(
  id: id,
  dawType: daw,
  stackId: stackId,
  isVirtual: virtual,
  lastModifiedAt: at ?? DateTime(2026, 1, 1),
  stats: plugins == null ? null : ProjectStats(plugins: plugins),
);

void main() {
  test('counts songs, not versions; newest first; read and unread', () {
    final report = buildPluginUsage([
      _project('stack', virtual: true),
      _project('v1', stackId: 'stack', plugins: ['Serum', 'OTT'], at: DateTime(2026, 1, 1)),
      _project('v2', stackId: 'stack', plugins: ['Serum'], at: DateTime(2026, 3, 1)),
      _project('other', plugins: ['serum', 'Pro-Q 3'], daw: 'REAPER', at: DateTime(2026, 2, 1)),
      _project('unread'),
    ]);
    expect(report.projectsRead, 3);
    expect(report.projectsUnread, 1, reason: 'the stack owns no file');
    expect(report.songs, 2);
    final serum = report.plugins.first;
    expect(
      (serum.name, serum.songs, serum.projects.length, serum.lastUsed),
      ('Serum', 2, 3, DateTime(2026, 3, 1)),
    );
    expect([for (final p in serum.projects) p.id], ['v2', 'other', 'v1']);
    expect(serum.daws, {'Cubase', 'REAPER'});
    expect(serum.stock, isNull, reason: 'used outside Cubase');
    expect(report.rare, 2, reason: 'OTT and Pro-Q 3, one song each');
    expect([for (final p in report.plugins) p.name], ['Serum', 'OTT', 'Pro-Q 3']);
  });

  test("stock is known for Cubase's own plug-ins", () {
    final report = buildPluginUsage([
      _project('a', plugins: ['Frequency 2', 'Pro-Q 3']),
    ]);
    final stock = {for (final p in report.plugins) p.name: p.stock};
    expect(stock, {'Frequency 2': true, 'Pro-Q 3': false});
  });

  test('instances and chains from the Cubase tracks already read', () {
    final a = _project('a', plugins: ['Serum', 'Pro-Q 3', 'OTT']);
    final b = _project('b', plugins: ['Pro-Q 3', 'OTT']);
    CubaseTrack track(String name, List<String> inserts, {String? instrument}) =>
        CubaseTrack(
          index: 0,
          name: name,
          type: CubaseTrackType.audio,
          instrument: instrument,
          inserts: [
            for (final (i, plugin) in inserts.indexed)
              CubaseInsert(slot: i, plugin: plugin),
          ],
        );
    final tracks = {
      'a': [
        track('Lead', ['Pro-Q 3', 'OTT_x64'], instrument: 'Serum'),
        track('Pad', ['Pro-Q 3', 'OTT']),
      ],
      'b': [
        track('Vox', ['Pro-Q 3', 'OTT']),
      ],
    };
    final report = buildPluginUsage([a, b], tracksOf: (p) => tracks[p.id]);
    expect(report.projectsWithInstances, 2);
    final count = {for (final p in report.plugins) p.name: p.instances};
    expect(count, {'Serum': 1, 'Pro-Q 3': 3, 'OTT': 3});
    expect(
      [for (final (chain, n) in report.chains) '${chain.join(' > ')} ×$n'],
      ['Pro-Q 3 > OTT ×3'],
    );
  });

  test('with no tracks read, instances are unknown, not zero', () {
    final report = buildPluginUsage([_project('a', plugins: ['OTT'])]);
    expect(report.plugins.single.instances, isNull);
    expect(report.chains, isEmpty);
  });

  test('projectUsesPlugin: a stack uses what a version uses', () {
    final stack = _project('s', virtual: true);
    final v1 = _project('v1', stackId: 's', plugins: ['Serum']);
    final other = _project('o', plugins: ['OTT']);
    final all = [stack, v1, other];
    expect(projectUsesPlugin(stack, 'serum', all), isTrue);
    expect(projectUsesPlugin(other, 'Serum', all), isFalse);
    expect(projectUsesPlugin(_project('n'), 'Serum', all), isFalse,
        reason: 'never read');
  });
}
