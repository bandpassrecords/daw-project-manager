import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/utils/version_stacks.dart';

import '../helpers/test_factories.dart';

/// Collapsing version stacks for counts and totals (#94).
///
/// A stacked library holds N+1 rows for one piece of work. Statistics, the DAW
/// filter and the projects list all have to see one row per project, with the
/// work time its versions actually logged.
void main() {
  MusicProject stack(String id, List<String> members) =>
      TestFactories.makeProject(
        id: id,
        isVirtual: true,
        memberProjectIds: members,
      );

  MusicProject member(
    String id,
    String stackId, {
    int work = 0,
    List<SessionRecord> sessions = const [],
  }) => TestFactories.makeProject(
    id: id,
    stackId: stackId,
    totalWorkSeconds: work,
    sessions: sessions,
  );

  SessionRecord session(DateTime at, int seconds) => SessionRecord(
    id: at.toIso8601String(),
    startedAt: at,
    endedAt: at.add(Duration(seconds: seconds)),
    durationSeconds: seconds,
  );

  test('drops members and keeps the stack', () {
    final collapsed = collapseVersionStacks([
      stack('s1', ['v1', 'v2']),
      member('v1', 's1'),
      member('v2', 's1'),
    ]);

    expect(collapsed.map((p) => p.id).toList(), ['s1']);
  });

  test('rolls member work time up onto the stack', () {
    final collapsed = collapseVersionStacks([
      stack('s1', ['v1', 'v2']),
      member('v1', 's1', work: 3600),
      member('v2', 's1', work: 1800),
    ]);

    // Work time is stored on the members and derived on read, so a stack row
    // taken at face value reports zero — dropping the members without this
    // would erase the library's work history from every total.
    expect(collapsed.single.totalWorkSeconds, 5400);
  });

  test('merges member sessions in chronological order', () {
    final collapsed = collapseVersionStacks([
      stack('s1', ['v1', 'v2']),
      member('v2', 's1', sessions: [session(DateTime(2025, 3, 1), 60)]),
      member('v1', 's1', sessions: [session(DateTime(2025, 1, 1), 30)]),
    ]);

    expect(
      collapsed.single.sessions.map((s) => s.startedAt).toList(),
      [DateTime(2025, 1, 1), DateTime(2025, 3, 1)],
    );
  });

  test('leaves standalone projects untouched', () {
    final plain = TestFactories.makeProject(id: 'p1', totalWorkSeconds: 900);

    final collapsed = collapseVersionStacks([plain]);

    expect(collapsed.single.id, 'p1');
    expect(collapsed.single.totalWorkSeconds, 900);
  });

  test('preserves input order', () {
    final collapsed = collapseVersionStacks([
      TestFactories.makeProject(id: 'a'),
      stack('s1', ['v1', 'v2']),
      member('v1', 's1'),
      TestFactories.makeProject(id: 'z'),
      member('v2', 's1'),
    ]);

    expect(collapsed.map((p) => p.id).toList(), ['a', 's1', 'z']);
  });

  test('an empty stack reports no work rather than throwing', () {
    // Every member deleted, stack not yet cleaned up.
    final collapsed = collapseVersionStacks([stack('s1', ['gone'])]);

    expect(collapsed.single.totalWorkSeconds, 0);
    expect(collapsed.single.sessions, isEmpty);
  });

  test('keeps stacks apart', () {
    final collapsed = collapseVersionStacks([
      stack('s1', ['v1']),
      stack('s2', ['v2']),
      member('v1', 's1', work: 100),
      member('v2', 's2', work: 200),
    ]);

    expect(collapsed.firstWhere((p) => p.id == 's1').totalWorkSeconds, 100);
    expect(collapsed.firstWhere((p) => p.id == 's2').totalWorkSeconds, 200);
  });

  test('null passes through as null', () {
    // "Not loaded yet" has to stay distinct from "loaded and empty".
    expect(collapseVersionStacksOrNull(null), isNull);
    expect(collapseVersionStacksOrNull([]), isEmpty);
  });
}
