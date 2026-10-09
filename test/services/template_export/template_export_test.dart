import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/template_export/template_export_service.dart';
import 'package:daw_project_manager/services/template_export/template_patterns.dart';
import 'package:daw_project_manager/services/template_export/template_spec.dart';
import 'package:daw_project_manager/services/template_export/track_roles.dart';

import '../../helpers/test_factories.dart';

CubaseTrack _t(int i, String name, CubaseTrackType type, [String? parent,
        String? output, List<CubaseInsert> inserts = const []]) =>
    CubaseTrack(
        index: i,
        name: name,
        type: type,
        parent: parent,
        output: output,
        inserts: inserts);

CubaseInsert _in(int slot, String plugin, {bool? bypassed}) =>
    CubaseInsert(slot: slot, plugin: plugin, bypassed: bypassed);

CorpusProject _project(String id, List<CubaseTrack> tracks,
        {List<String> plugins = const [], String? version}) =>
    buildCorpusProject(
      projectId: id,
      name: id,
      modified: DateTime.utc(2026, 1, 1),
      tracks: tracks,
      plugins: plugins,
      cubaseVersion: version,
    );

/// A drums folder, a kick and a bass; `extra` adds a lead.
List<CubaseTrack> _song({bool lead = false, String kick = 'Kick'}) => [
      _t(0, 'Drums', CubaseTrackType.folder),
      _t(1, kick, CubaseTrackType.audio, 'Drums'),
      _t(2, 'Bass', CubaseTrackType.audio),
      if (lead) _t(3, 'Lead', CubaseTrackType.instrument),
    ];

void main() {
  group('roleOf', () {
    test('folds case, numbers, separators and accents into one role', () {
      for (final name in ['Kick 1', 'KICK', 'kick_02', 'Kick-03', 'bumbo']) {
        expect(roleOf(name), 'kick', reason: name);
      }
      expect(roleOf('Percussão 2'), 'percs');
    });

    test('anything unmatched is unknown, and an empty name too', () {
      expect(roleOf('Wobbly Thing'), kUnknownRole);
      expect(roleOf('   '), kUnknownRole);
    });

    test('"FOLDER - item 01" names match on the item, then the folder', () {
      expect(roleOf('DRUMS - Closed Hi Hat 01'), 'hats');
      expect(roleOf('DRUMS - Bongo Loop 01 (x)'), 'loops');
      expect(roleOf('STABS - STAB 07 REVERSE'), 'stabs');
      expect(roleOf('LEADS - Something Odd'), 'lead');
    });

    test('inside a name the longest alias wins, then the later word', () {
      expect(roleOf('Snare Sweep Up'), 'sweeps');
      expect(roleOf('KICK IMPACT 01'), 'fx_impact');
      expect(roleOf('Main Vocal 01'), 'vocals');
    });

    test('an alias is matched as whole words, never inside a word', () {
      expect(roleOf('Subtle thing'), kUnknownRole);
      expect(roleOf('Padded'), kUnknownRole);
    });

    test('custom aliases win over the defaults', () {
      expect(roleOf('Bumbo', aliases: {'bumbo': 'low_drum'}), 'low_drum');
      expect(roleOf('Zap', aliases: {'zap': 'fx'}), 'fx');
    });
  });

  group('buildPatterns', () {
    test('presence, tiers and counts follow the thresholds', () {
      final corpus = [
        for (var i = 0; i < 10; i++)
          _project('p$i', _song(lead: i < 5)), // lead in 5 of 10 projects
        _project('twoBass', [
          ..._song(),
          _t(9, 'Bass 2', CubaseTrackType.audio),
        ]),
      ];
      final patterns = buildPatterns(corpus);
      RolePattern role(String r) => patterns.roles.firstWhere((x) => x.role == r);

      expect(patterns.projectCount, 11);
      expect(role('kick').presence, 1.0);
      expect(role('kick').tier, RoleTier.core);
      expect(role('lead').presence, closeTo(5 / 11, 1e-9));
      expect(role('lead').tier, RoleTier.common);
      expect(role('bass').countMax, 2);
      expect(role('bass').countMedian, 1);
      expect(role('bass').copies, 1);
    });

    test('a rare role stays out of the template but in the statistics', () {
      final corpus = [
        for (var i = 0; i < 10; i++)
          _project('p$i', [
            ..._song(),
            if (i == 0) _t(9, 'Riser', CubaseTrackType.audio),
          ]),
      ];
      final patterns = buildPatterns(corpus);
      expect(patterns.roles.map((r) => r.role), contains('fx_riser'));
      expect(patterns.inTemplate(TemplateKind.track).map((r) => r.role),
          isNot(contains('fx_riser')));
    });

    test('folder, bus and track of the same name are different roles', () {
      final patterns = buildPatterns([
        _project('a', [
          _t(0, 'Drums', CubaseTrackType.folder),
          _t(1, 'Drums', CubaseTrackType.audio, 'Drums'),
          _t(2, 'Drums', CubaseTrackType.group),
        ]),
      ]);
      expect(
        {for (final r in patterns.roles) r.kind},
        {TemplateKind.folder, TemplateKind.bus, TemplateKind.track},
      );
    });

    test('the usual folder wins only when enough of the tracks sit in it', () {
      final inFolder = [
        for (var i = 0; i < 3; i++) _project('f$i', _song()),
        _project('top', [
          _t(0, 'Drums', CubaseTrackType.folder),
          _t(1, 'Kick', CubaseTrackType.audio),
        ]),
      ];
      expect(
        buildPatterns(inFolder).roles.firstWhere((r) => r.role == 'kick').parent,
        'Drums',
      );

      final mostlyTop = [
        _project('f', _song()),
        for (var i = 0; i < 3; i++)
          _project('t$i', [
            _t(0, 'Drums', CubaseTrackType.folder),
            _t(1, 'Kick', CubaseTrackType.audio),
          ]),
      ];
      expect(
        buildPatterns(mostlyTop).roles.firstWhere((r) => r.role == 'kick').parent,
        isNull,
      );
    });

    test('unknown tracks are counted and listed, never part of a statistic', () {
      final patterns = buildPatterns([
        _project('a', [
          ..._song(),
          _t(5, 'Wobbly', CubaseTrackType.audio),
          _t(6, 'Wobbly', CubaseTrackType.audio),
        ]),
      ]);
      expect(patterns.unknownTrackCount, 2);
      expect(patterns.unknownNames.single, (name: 'Wobbly', count: 2));
      expect(patterns.roles.map((r) => r.role), isNot(contains(kUnknownRole)));
    });

    test('plug-ins count projects, not instances', () {
      final patterns = buildPatterns([
        _project('a', _song(), plugins: ['Pro-Q 3', 'Pro-Q 3']),
        _project('b', _song(), plugins: ['Serum']),
      ]);
      final byName = {for (final x in patterns.plugins) x.plugin: x.presence};
      expect(byName, {'Pro-Q 3': 0.5, 'Serum': 0.5});
    });

    test('projects with no tracks are not counted, and nothing divides by zero',
        () {
      final empty = buildPatterns([_project('e', const [])]);
      expect(empty.projectCount, 0);
      expect(empty.roles, isEmpty);
    });

    test('a small corpus carries a warning in meta', () {
      final json = buildPatterns([_project('a', _song())]).toJson();
      expect((json['meta'] as Map)['warning'], isNotNull);
      final big = buildPatterns([
        for (var i = 0; i < kSmallCorpus; i++) _project('p$i', _song()),
      ]).toJson();
      expect((big['meta'] as Map).containsKey('warning'), isFalse);
    });

    test('the most common Cubase version is reported', () {
      final patterns = buildPatterns([
        _project('a', _song(), version: '13.0'),
        _project('b', _song(), version: '14.0'),
        _project('c', _song(), version: '14.0'),
      ]);
      expect(patterns.cubaseVersion, '14.0');
    });
  });

  group('inserts and outputs', () {
    /// [n] projects each with a snare carrying [inserts], and a drums bus.
    TemplatePatterns snares(List<List<CubaseInsert>> perProject,
        {TemplateThresholds thresholds = const TemplateThresholds()}) {
      return buildPatterns([
        for (var i = 0; i < perProject.length; i++)
          _project('p$i', [
            _t(0, 'Drums', CubaseTrackType.group, null, 'Stereo Out'),
            _t(1, 'Snare', CubaseTrackType.audio, null, 'Drums',
                perProject[i]),
          ]),
      ], thresholds: thresholds);
    }

    RolePattern snare(TemplatePatterns p) =>
        p.roles.firstWhere((r) => r.role == 'snare');

    test('a plug-in on a quarter of the tracks is offered, one on fewer is not',
        () {
      final p = snares([
        [_in(0, 'Pro-Q 3')],
        [_in(0, 'Pro-Q 3')],
        [_in(0, 'Pro-Q 3')],
        [_in(1, 'Decapitator')], // 1 of 4: exactly the threshold
      ]);
      expect(snare(p).inserts.map((i) => i.plugin), ['Pro-Q 3', 'Decapitator']);
      final strict = snares([
        for (var i = 0; i < 8; i++) i == 0 ? [_in(0, 'Rare')] : <CubaseInsert>[],
      ]);
      expect(snare(strict).inserts, isEmpty);
    });

    test('a bypassed plug-in still counts as used', () {
      final p = snares([
        [_in(0, 'Pro-Q 3', bypassed: true)],
        [_in(0, 'Pro-Q 3', bypassed: true)],
      ]);
      expect(snare(p).inserts.single.plugin, 'Pro-Q 3');
      expect(snare(p).inserts.single.rate, 1.0);
    });

    test('the chain follows slot order, not popularity', () {
      final p = snares([
        for (var i = 0; i < 4; i++)
          [_in(0, 'EQ A'), _in(1, 'Comp B'), _in(2, 'Sat C')],
        [_in(1, 'Comp B')],
      ]);
      expect(snare(p).inserts.map((i) => i.plugin), ['EQ A', 'Comp B', 'Sat C']);
    });

    test('a chain is cut to the most used plug-ins at the per-track cap', () {
      final all = [for (var s = 0; s < 8; s++) _in(s, 'Plug $s')];
      final p = snares([all, all, all],
          thresholds: const TemplateThresholds(maxInserts: 6));
      expect(snare(p).inserts, hasLength(6));
      final wide = snares([all, all, all],
          thresholds: const TemplateThresholds(maxInserts: 3));
      expect(snare(wide).inserts, hasLength(3));
    });

    test('"FabFilter Pro-Q 3" and "Pro-Q 3" are the same plug-in', () {
      final p = snares([
        [_in(0, 'Pro-Q 3')],
        [_in(0, 'FabFilter Pro-Q 3')],
      ]);
      expect(snare(p).inserts, hasLength(1));
      expect(snare(p).inserts.single.rate, 1.0);
    });

    test('the usual output is told by the role of the channel it feeds', () {
      final p = snares([[], []]);
      expect(snare(p).output, 'Drums');
      expect(snare(p).outputRole, 'drums');
      final bus = p.roles.firstWhere((r) => r.kind == TemplateKind.bus);
      expect(bus.output, 'Stereo Out');
      expect(bus.outputRole, isNull, reason: 'an output device, not a role');
    });

    test('Stage D routes into a bus of the template, Stage E lists inserts '
        'bypassed', () {
      final spec = buildTemplateSpec(snares([
        [_in(0, 'Pro-Q 3'), _in(2, 'Decapitator')],
        [_in(0, 'Pro-Q 3'), _in(2, 'Decapitator')],
        [_in(0, 'Pro-Q 3'), _in(2, 'Decapitator')],
      ]));
      expect(spec, contains('## Etapa D: roteamento de saída'));
      expect(spec, contains('| Snare | Drums |'));
      expect(spec, isNot(contains('| Drums | Stereo Out |')),
          reason: 'the default output needs no action');
      expect(spec, contains('| Snare | 0 | Pro-Q 3 | bypassed |'));
      expect(spec, contains('| Snare | 1 | Decapitator | bypassed |'),
          reason: 'slots are packed, not copied from the projects');
    });

    test('the spec says inserts are bypassed and asks to check it', () {
      final spec = buildTemplateSpec(snares([
        [_in(0, 'Pro-Q 3')],
      ]));
      expect(spec, contains('insert_state: bypassed'));
      expect(spec, contains('- [ ] Todos os inserts em bypass'));
      expect(spec, contains('Total de inserts: 1'));
      expect(spec, contains('Pendências'));
    });

    test('meta and patterns.json carry insert_state and the chain', () {
      final json = snares([
        [_in(0, 'Pro-Q 3')],
      ]).toJson();
      expect((json['meta'] as Map)['insert_state'], 'bypassed');
      final role = (json['roles'] as List)
          .cast<Map>()
          .firstWhere((r) => r['role'] == 'snare');
      expect(role['insert_chain'], hasLength(1));
      expect((role['output_mode'] as Map)['name'], 'Drums');
    });

    test('corpus.json keeps each insert with its slot and bypass state', () {
      final json = _project('a', [
        _t(0, 'Snare', CubaseTrackType.audio, null, 'Drums', [
          _in(3, 'Pro-Q 3', bypassed: true),
        ]),
      ]).toJson();
      final track = ((json['tracks'] as List).single as Map);
      expect(track['output'], 'Drums');
      expect(track['inserts'], [
        {'slot': 3, 'plugin': 'Pro-Q 3', 'bypassed': true},
      ]);
    });
  });

  group('buildTemplateSpec', () {
    TemplatePatterns patterns() => buildPatterns([
          for (var i = 0; i < 10; i++)
            _project('p$i', [
              ..._song(lead: i < 5),
              if (i < 8) _t(7, 'FX Bus', CubaseTrackType.group),
            ]),
        ], now: DateTime.utc(2026, 10, 9));

    test('orders the stages so a parent exists before what sits in it', () {
      final spec = buildTemplateSpec(patterns());
      final a = spec.indexOf('## Etapa A: pastas');
      final b = spec.indexOf('## Etapa B: grupos e buses');
      final c = spec.indexOf('## Etapa C: trilhas');
      expect(a, greaterThan(-1));
      expect(b, greaterThan(a));
      expect(c, greaterThan(b));
    });

    test('core rows are plain, common rows are marked optional', () {
      final spec = buildTemplateSpec(patterns());
      expect(spec, contains('| Kick | audio | Drums |  |'));
      expect(spec, contains('| Lead | instrument |  | opcional |'));
    });

    test('a folder is created before the tracks that name it', () {
      final spec = buildTemplateSpec(patterns());
      expect(spec, contains('| 1 | Drums |  |  |'));
    });

    test('a parent that did not make the template leaves the cell empty', () {
      // "Stuff" has no role, so it never becomes a folder row.
      final spec = buildTemplateSpec(buildPatterns([
        for (var i = 0; i < 3; i++)
          _project('p$i', [
            _t(0, 'Stuff', CubaseTrackType.folder),
            _t(1, 'Kick', CubaseTrackType.audio, 'Stuff'),
          ]),
      ]));
      expect(spec, contains('| 1 | Kick | audio |  |  |'));
    });

    test('copies are numbered when a role has several tracks', () {
      final spec = buildTemplateSpec(buildPatterns([
        for (var i = 0; i < 3; i++)
          _project('p$i', [
            _t(0, 'Lead 1', CubaseTrackType.instrument),
            _t(1, 'Lead 2', CubaseTrackType.instrument),
          ]),
      ]));
      expect(spec, contains('| Lead 1 |'));
      expect(spec, contains('| Lead 2 |'));
    });

    test('folders and buses are made once, however many share a role', () {
      final spec = buildTemplateSpec(buildPatterns([
        for (var i = 0; i < 3; i++)
          _project('p$i', [
            _t(0, 'LEAD INTRO', CubaseTrackType.folder),
            _t(1, 'FINAL LEAD', CubaseTrackType.folder),
            _t(2, 'LEAD INTRO GROUP', CubaseTrackType.group),
            _t(3, 'LEAD INTRO GROUP', CubaseTrackType.group),
          ]),
      ]));
      expect(spec, contains('| Lead |'));
      expect(spec, isNot(contains('Lead 1')));
      expect(spec, contains('Total de pastas: 1'));
      expect(spec, contains('Total de grupos e buses: 1'));
    });

    test('a long name is replaced by its role, a plain alias is kept', () {
      final spec = buildTemplateSpec(buildPatterns([
        for (var i = 0; i < 3; i++)
          _project('p$i', [
            _t(0, 'DRUMS - TOM 01 Right Panned', CubaseTrackType.audio),
            _t(1, 'SNARE 01', CubaseTrackType.audio),
          ]),
      ]));
      expect(spec, contains('| Toms |'));
      expect(spec, contains('| SNARE |'));
      expect(spec, isNot(contains('Right Panned')));
    });

    test('a track goes in the folder whose role its usual folder has', () {
      // The folder is spelled "DRUMS" in one project and "Drums" in another;
      // the template's folder is whichever spelling is commonest.
      final spec = buildTemplateSpec(buildPatterns([
        _project('a', [
          _t(0, 'DRUMS', CubaseTrackType.folder),
          _t(1, 'Snare', CubaseTrackType.audio, 'DRUMS'),
        ]),
        _project('b', [
          _t(0, 'Drums', CubaseTrackType.folder),
          _t(1, 'Snare', CubaseTrackType.audio, 'Drums'),
        ]),
      ]));
      expect(spec, contains('| 1 | Snare | audio | DRUMS |  |'));
    });

    test('the outline nests what sits in a folder, with route and inserts', () {
      final outline = buildTemplateOutline(buildPatterns([
        for (var i = 0; i < 3; i++)
          _project('p$i', [
            _t(0, 'DRUMS', CubaseTrackType.folder),
            _t(1, 'DRUMS GROUP', CubaseTrackType.group, 'DRUMS',
                'Stereo Out', [_in(0, 'L1 limiter')]),
            _t(2, 'Snare', CubaseTrackType.audio, 'DRUMS', 'DRUMS GROUP',
                [_in(0, 'Pro-Q 3'), _in(3, 'Decapitator')]),
            _t(3, 'Bass', CubaseTrackType.audio),
          ]),
      ]));
      final lines = outline.split('\n');
      int at(String text) => lines.indexWhere((l) => l.contains(text));
      expect(lines[at('**DRUMS**')], startsWith('- '));
      expect(lines[at('**Snare**')], startsWith('    - '),
          reason: 'indented under its folder');
      expect(lines[at('**Snare**')], contains('→ Drums'));
      expect(lines[at('Pro-Q 3')], contains('Pro-Q 3 → Decapitator'));
      expect(lines[at('Pro-Q 3')], startsWith('        - inserts'));
      expect(lines[at('**Bass**')], startsWith('- '),
          reason: 'no folder, so at the top');
      expect(at('**Snare**'), greaterThan(at('**DRUMS**')));
    });

    test('the outline marks optional items and says inserts are bypassed',
        () {
      final outline = buildTemplateOutline(buildPatterns([
        for (var i = 0; i < 10; i++)
          _project('p$i', [
            _t(0, 'Kick', CubaseTrackType.audio),
            if (i < 5) _t(1, 'Lead', CubaseTrackType.instrument),
          ]),
      ]));
      expect(outline, contains('**Lead** · instrument · _opcional_'));
      expect(outline, isNot(contains('**Kick** · audio · _opcional_')));
      expect(outline, contains('bypass'));
    });

    test('says what it did not read instead of guessing', () {
      final spec = buildTemplateSpec(patterns());
      expect(spec, contains('## Ajuste manual'));
      expect(spec, contains('Sends, cores e presets'));
    });

    test('pipes in a name cannot break the table', () {
      final spec = buildTemplateSpec(buildPatterns([
        _project('a', [_t(0, 'Kick', CubaseTrackType.audio, 'A|B')]),
      ]));
      expect(spec.split('\n').where((l) => l.contains('Kick')).single,
          isNot(contains('A|B')));
    });

    test('totals in the checklist match the rows', () {
      final spec = buildTemplateSpec(patterns());
      expect(spec, contains('Total de pastas: 1'));
      expect(spec, contains('Total de grupos e buses: 1'));
      expect(spec, contains('Total de trilhas: 3'));
    });
  });

  group('TemplateExportService', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('tmpl_export'));
    tearDown(() => dir.deleteSync(recursive: true));

    final cubase = TestFactories.makeProject(
      id: 'c1',
      filePath: p.join('songs', 'Song.cpr'),
      fileName: 'Song.cpr',
      dawType: 'Cubase',
      customDisplayName: 'My Secret Song',
    );

    test('writes the three files and no path', () async {
      final result = await TemplateExportService.export(
        [cubase],
        directory: dir,
        readTracks: (_) async => _song(),
      );
      expect(result.projectsAnalysed, 1);
      for (final f in [
        'corpus.json',
        'patterns.json',
        'template-spec.md',
        'template.md',
      ]) {
        expect(File(p.join(dir.path, f)).existsSync(), isTrue, reason: f);
      }
      final corpus = File(p.join(dir.path, 'corpus.json')).readAsStringSync();
      expect(corpus, contains('My Secret Song'));
      expect(corpus, isNot(contains('songs')));
      expect(jsonDecode(corpus)['projects'], hasLength(1));
    });

    test('anonymising hides project names', () async {
      await TemplateExportService.export(
        [cubase],
        directory: dir,
        anonymize: true,
        readTracks: (_) async => _song(),
      );
      final corpus = File(p.join(dir.path, 'corpus.json')).readAsStringSync();
      expect(corpus, isNot(contains('My Secret Song')));
      expect(corpus, contains('Project 1'));
    });

    test('other DAWs, stacks and archived projects are not read', () async {
      var reads = 0;
      final als = TestFactories.makeProject(id: 'a', filePath: 'x.als');
      final stack = TestFactories.makeProject(
          id: 's', filePath: 'folder', isVirtual: true);
      final archived = TestFactories.makeProject(
          id: 'z', filePath: p.join('a', 'Old.cpr'), archivePath: 'old.zip');
      final result = await TemplateExportService.export(
        [als, stack, archived],
        directory: dir,
        readTracks: (_) async {
          reads++;
          return _song();
        },
      );
      expect(reads, 0);
      expect(result.projectsAnalysed, 0);
    });

    test('a project that cannot be read is counted as skipped', () async {
      final result = await TemplateExportService.export(
        [cubase],
        directory: dir,
        readTracks: (_) async => null,
      );
      expect(result.projectsSkipped, 1);
      expect(result.projectsAnalysed, 0);
    });

    test('readCubaseTracks gives null for a missing file', () async {
      expect(await readCubaseTracks(p.join(dir.path, 'nope.cpr')), isNull);
    });
  });
}
