import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_marker.dart';
import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/utils/project_search.dart';
import 'package:daw_project_manager/utils/search_utils.dart';

import '../helpers/test_factories.dart';

void main() {
  bool matches(MusicProject project, String query, {bool tags = true}) =>
      fuzzyMatchAny(projectSearchFields(project, includeTags: tags), query);

  test('finds a project by a plug-in it loads', () {
    final p = TestFactories.makeProject(
      fileName: 'Night Drive.cpr',
      stats: const ProjectStats(plugins: ['Pro-Q 3', 'Serum']),
    );
    expect(matches(p, 'serum'), isTrue);
    expect(matches(p, 'pro-q'), isTrue);
    expect(matches(p, 'omnisphere'), isFalse);
  });

  test('a project never deep-scanned simply has no plug-ins to match', () {
    final p = TestFactories.makeProject(fileName: 'Night Drive.cpr');
    expect(matches(p, 'serum'), isFalse);
    expect(matches(p, 'night'), isTrue);
  });

  test('words must hit the same plug-in, not two different ones', () {
    final p = TestFactories.makeProject(
      fileName: 'x.cpr',
      stats: const ProjectStats(plugins: ['Pro-Q 3', 'Serum']),
    );
    expect(matches(p, 'serum pro'), isFalse);
  });

  test('still covers the fields it always did', () {
    final p = TestFactories.makeProject(
      fileName: 'x.rpp',
      notes: 'needs vocals',
      markers: const [ProjectMarker(index: 1, name: 'Bridge', positionSeconds: 1)],
      tags: ['trap'],
    );
    expect(matches(p, 'vocals'), isTrue);
    expect(matches(p, 'bridge'), isTrue);
    expect(matches(p, 'trap'), isTrue);
    expect(matches(p, 'trap', tags: false), isFalse,
        reason: 'hidden tags must not make a project match');
  });
}
