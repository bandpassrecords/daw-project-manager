// Compare (#223) on real versions of a song: what the Inspector says
// changed between two saves, against what was changed in Cubase.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/project_inspector/compare/anatomy_diff.dart';
import 'package:daw_project_manager/services/project_inspector/project_anatomy_reader.dart';
import 'package:daw_project_manager/services/project_inspector/safe_copy/safe_copy.dart';

import 'flow_library.dart';

void main() {
  late FlowLibrary lib;
  tearDown(() async => lib.close());

  Future<AnatomyDiff> compare(String a, String b) async {
    File file(String name) => lib.fixtures.single.projectFiles.singleWhere(
      (f) => p.basename(f.path) == name,
    );
    return diffAnatomy(
      await readProjectAnatomy(file(a).path),
      await readProjectAnatomy(file(b).path),
    );
  }

  List<String> changes(AnatomyDiff d) => [
    for (final c in d.projectChanges) 'project: $c',
    for (final ch in d.channels)
      for (final c in ch.changes) '${ch.name}: $c',
  ];

  group('Cubase 13 (Test 2025)', () {
    setUp(
      () async => lib = await FlowLibrary.open(
        only: ['cubase/Test 2025 (Cubase 13)'],
      ),
    );

    test('saves a mute and a solo apart: exactly that changed', () async {
      expect(
        changes(await compare('test-01_db_level.cpr', 'test-01_db_level-01.cpr')),
        ['RTW_Kick_12: muted: true → false'],
      );
      final solo = await compare(
        'test-01_db_level-01.cpr',
        'test-01_db_level-02.cpr',
      );
      expect(changes(solo), ['RTW_Kick_12: soloed: false → true']);
      expect(solo.unchangedChannels, 80);
    });

    test('a later version: inserts added and moved, a fader, a mute', () async {
      final d = await compare('test-01.cpr', 'test-02.cpr');
      expect(d.changeCount, 10);
      expect(d.changedChannels, 5);
      expect((d.onlyInA, d.onlyInB), (0, 0));
      final bass = d.channels.singleWhere((c) => c.name == 'Bassline');
      expect([for (final c in bass.changes) c.kind], [
        AnatomyChangeKind.volume,
        AnatomyChangeKind.insertAdded,
        AnatomyChangeKind.insertAdded,
        AnatomyChangeKind.insertMoved,
      ]);
      final moved = bass.changes.last;
      expect((moved.subject, moved.before, moved.after), ('LFOTool', 11, 12));
    });

    test('the first sketch: the project, and the channels added since', () async {
      final d = await compare('test.cpr', 'test-01.cpr');
      expect(changes(d).take(2), [
        'project: tempo: 145.0 → 150.0',
        'project: key: E Minor → A Major',
      ]);
      expect(d.onlyInB, 61);
      expect(d.onlyInA, 0);
    });

    test('a Safe Copy differs only in the plug-ins it switched off', () async {
      final project = lib.fixtures.single.projectFiles.singleWhere(
        (f) => p.basename(f.path) == 'test-01.cpr',
      );
      final copy = await writeSafeCopy(
        projectPath: project.path,
        plugins: {'OTT'},
      );
      final d = diffAnatomy(
        await readProjectAnatomy(project.path),
        await readProjectAnatomy(copy.path!),
      );
      final all = d.allChanges.toList();
      expect(all, hasLength(11));
      expect(
        all.every(
          (c) =>
              c.kind == AnatomyChangeKind.insertSwitched &&
              c.subject == 'OTT' &&
              c.after == false,
        ),
        isTrue,
      );
    });
  });

  test('Cubase 5 to 11: an instrument swapped, channels gone', () async {
    lib = await FlowLibrary.open(
      only: ['cubase/Fuck The System - Files RMX (Cubase 4, 5, 11)'],
    );
    final d = await compare(
      'fuck the system rmx-6.cpr',
      'fuck the system rmx-35.cpr',
    );
    expect(d.changeCount, 13);
    expect(d.onlyInA, 3);
    expect(
      changes(d),
      contains('CronoX 01: instrument: Sylenth1 → CronoX'),
    );
    expect(changes(d), contains('Lead: insertRemoved PingPongDelay #1: null → null'));
  });
}
