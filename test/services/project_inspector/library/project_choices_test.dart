import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/services/project_inspector/library/project_choices.dart';

import '../../../helpers/test_factories.dart';

void main() {
  final song = p.join(p.separator, 'music', 'Song');
  final other = p.join(p.separator, 'music', 'Other');

  MusicProject project(
    String id,
    String path, {
    int day = 1,
    String? stackId,
    bool isVirtual = false,
    String? archivePath,
  }) => TestFactories.makeProject(
    id: id,
    filePath: path,
    fileName: p.basename(path),
    lastModifiedAt: DateTime(2026, 1, day),
    stackId: stackId,
    isVirtual: isVirtual,
    archivePath: archivePath,
    archivedAt: archivePath == null ? null : DateTime(2026),
  );

  String names(List<MusicProject> list) => list.map((pr) => pr.id).join(',');

  group('inspectorProjectChoices', () {
    test('only files the Inspector reads, the newest first', () {
      final c = inspectorProjectChoices([
        project('old', p.join(song, 'Song-01.cpr'), day: 1),
        project('new', p.join(song, 'Song-02.cpr'), day: 9),
        project('stack', song, isVirtual: true),
        project(
          'zipped',
          p.join(other, 'Other.als'),
          archivePath: p.join(other, 'Other.zip'),
        ),
        project('text', p.join(other, 'notes.txt')),
      ]);
      expect(c.versions, isEmpty);
      expect(names(c.others), 'new,old');
    });

    test('comparing: the open project left out, its folder first', () {
      final open = p.join(song, 'Song-02.cpr');
      final c = inspectorProjectChoices([
        project('a', p.join(song, 'Song-01.cpr'), day: 1),
        project('open', open, day: 9),
        project('b', p.join(other, 'Other.cpr'), day: 5),
      ], comparingWith: open);
      expect(names(c.versions), 'a');
      expect(names(c.others), 'b');
    });

    test('comparing a stacked version: its stack\'s members, wherever', () {
      final open = p.join(song, 'Song-02.cpr');
      final c = inspectorProjectChoices([
        project('open', open, stackId: 's'),
        project('moved', p.join(other, 'Song-old.cpr'), stackId: 's'),
        // Beside it, but another song's: not a version.
        project('neighbour', p.join(song, 'Jam.cpr')),
      ], comparingWith: open);
      expect(names(c.versions), 'moved');
      expect(names(c.others), 'neighbour');
    });
  });

  group('matchesInspectorSearch', () {
    final pr = project('x', p.join(song, 'Song-02.cpr'));

    test('name, folder or DAW, any case', () {
      expect(matchesInspectorSearch(pr, 'song-02'), isTrue);
      expect(matchesInspectorSearch(pr, 'MUSIC'), isTrue);
      expect(matchesInspectorSearch(pr, 'ableton'), isTrue);
      expect(matchesInspectorSearch(pr, '  '), isTrue);
      expect(matchesInspectorSearch(pr, 'reaper'), isFalse);
    });
  });
}
