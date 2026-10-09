import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/template_export/reference_page.dart';
import 'package:daw_project_manager/services/template_export/reference_service.dart';
import 'package:daw_project_manager/services/template_export/template_patterns.dart';

import '../../helpers/test_factories.dart';

Map<String, Object?> _dictionary() => jsonDecode(
        File(p.join('assets', 'reference', 'strings.json')).readAsStringSync())
    as Map<String, Object?>;

CubaseTrackType _type(String name) =>
    CubaseTrackType.values.byName(name);

/// The fixture corpus, as the template export writes it.
List<CorpusProject> _fixtureCorpus() {
  final raw = jsonDecode(
          File(p.join('test', 'fixtures', 'reference_corpus.json'))
              .readAsStringSync())
      as Map;
  return [
    for (final project in raw['projects'] as List)
      CorpusProject(
        projectId: project['project_id'] as String,
        name: project['name'] as String,
        cubaseVersion: project['cubase_version'] as String,
        modified: DateTime.parse(project['modified'] as String),
        tracks: [
          for (final t in project['tracks'] as List)
            CorpusTrack(
              index: t['index'] as int,
              name: t['name'] as String,
              role: t['role'] as String,
              type: _type(t['type'] as String),
              parent: t['parent'] as String?,
              output: t['output'] as String?,
              inserts: [
                for (final i in (t['inserts'] ?? const []) as List)
                  CubaseInsert(
                    slot: i['slot'] as int,
                    plugin: i['plugin'] as String,
                    bypassed: i['bypassed'] as bool?,
                  ),
              ],
            ),
        ],
      ),
  ];
}

CorpusProject _project(String name, List<CorpusTrack> tracks,
        {String modified = '2025-01-01T00:00:00.000Z'}) =>
    CorpusProject(
      projectId: name,
      name: name,
      cubaseVersion: '13',
      modified: DateTime.parse(modified),
      tracks: tracks,
    );

CorpusTrack _track(String name, {List<CubaseInsert> inserts = const []}) =>
    CorpusTrack(
      index: 0,
      name: name,
      role: 'master',
      type: CubaseTrackType.audio,
      inserts: inserts,
    );

CubaseInsert _in(String plugin) => CubaseInsert(slot: 0, plugin: plugin);

void main() {
  group('the data matches the prototype script', () {
    test('byte for byte, on a corpus that reaches every branch', () {
      // reference_data.json is what the original build_data.py makes from
      // reference_corpus.json: masters of every generation, a song saved
      // twice, scratch and test projects, merged plug-in names, unknown
      // tracks with and without inserts, bypassed inserts, non-ASCII names.
      final expected = File(p.join('test', 'fixtures', 'reference_data.json'))
          .readAsStringSync();
      final data = buildReferenceData(_fixtureCorpus(),
          generated: DateTime.utc(2026, 10, 9));
      expect(jsonEncode(data), expected);
    });
  });

  group('plug-in names', () {
    test('aliases are merged and _x64 dropped', () {
      expect(canonPlugin('FabFilter Pro-Q 3'), 'Pro-Q 3');
      expect(canonPlugin('Redoptor 2'), 'Redoptor2');
      expect(canonPlugin('LFOTool_x64'), 'LFOTool');
      expect(canonPlugin('Invisible_Limiter'), 'Invisible Limiter');
      expect(canonPlugin('ValhallaRoom'), 'ValhallaRoom');
    });
  });

  group('project kind', () {
    test('masters are told by how the name ends', () {
      for (final name in [
        'Song (Master)',
        'Song (master)  ',
        'Song (M)',
        'Song (Audio Crawler Remix) M',
        'Song (x) M-2',
        'Song (Audio Crawler RemixM)',
        'Song (2026 master)',
        'Song (2025 M)',
      ]) {
        expect(isMasterName(name), isTrue, reason: name);
      }
      for (final name in ['Song', 'Master of puppets', 'Song (Mix)', 'M']) {
        expect(isMasterName(name), isFalse, reason: name);
      }
    });

    test('25 tracks or fewer, or a test name, is scratch', () {
      expect(projectKind('Song', 25), 's');
      expect(projectKind('Song', 26), 'p');
      expect(projectKind('Test of things', 80), 's');
      expect(projectKind('gravacoes 12', 80), 's');
      expect(projectKind('SunDose', 80), 's');
      expect(projectKind('A test', 80), 'p', reason: 'only at the start');
      expect(projectKind('Song (Master)', 3), 'm', reason: 'master first');
    });

    test('a song is its number, or else its name in letters and digits', () {
      expect(songKey('2024_008_Name (M)'), '2024_008');
      expect(songKey('2024_008_Name V2'), '2024_008');
      expect(songKey('My Song - v2!'), 'mysongv2');
    });
  });

  group('masterGeneration', () {
    CorpusProject withChain(List<String> plugins) => _project('m', [
          _track('a', inserts: [for (final n in plugins) _in(n)]),
        ]);

    test('no chain at all is generation 0', () {
      expect(masterGeneration(_project('m', [_track('a')])), 0);
    });

    test('Ozone 10 Match EQ marks generation 3', () {
      expect(masterGeneration(withChain(['Ozone 10 Match EQ', 'Vertigo VSM-3'])),
          3);
    });

    test('Vertigo alone is 1, with soothe2 or Pro-L 2 it is 2', () {
      expect(masterGeneration(withChain(['Vertigo VSM-3'])), 1);
      expect(masterGeneration(withChain(['Vertigo VSM-3', 'soothe2'])), 2);
      expect(masterGeneration(withChain(['Vertigo VSM-3', 'Pro-L 2'])), 2);
    });

    test('without markers a long chain is 3 and a short one 2', () {
      expect(masterGeneration(withChain(['a', 'b', 'c', 'd', 'e'])), 2);
      expect(masterGeneration(withChain(['a', 'b', 'c', 'd', 'e', 'f'])), 3);
    });

    test('the chain read is the longest on any track', () {
      final project = _project('m', [
        _track('a', inserts: [_in('x')]),
        _track('b', inserts: [_in('Vertigo VSM-3'), _in('y')]),
      ]);
      expect(masterGeneration(project), 1);
    });

    test('names merged by canonPlugin count as one', () {
      final project = _project('m', [
        _track('a', inserts: [
          _in('FabFilter Pro-Q 3'),
          _in('Pro-Q 3'),
          _in('c'),
          _in('d'),
          _in('e'),
          _in('f'),
        ]),
      ]);
      expect(masterGeneration(project), 2, reason: 'five distinct names');
    });
  });

  group('buildReferenceData', () {
    CorpusProject song(String name, String modified, {int tracks = 30}) =>
        _project(
          name,
          [
            for (var i = 0; i < tracks; i++)
              CorpusTrack(
                index: i,
                name: 'T$i',
                role: 'kick',
                type: CubaseTrackType.audio,
              ),
          ],
          modified: modified,
        );

    test('only the newest save of a song is flagged, per kind', () {
      final data = buildReferenceData([
        song('2024_001_A', '2024-01-01T00:00:00.000Z'),
        song('2024_001_A V2', '2024-03-01T00:00:00.000Z'),
        song('2024_002_B', '2024-02-01T00:00:00.000Z'),
      ], generated: DateTime.utc(2026, 1, 1));
      final flags = [for (final x in data['P'] as List) (x as Map)['l']];
      expect(flags, [0, 1, 1]);
    });

    test('equal times go to the later project', () {
      final data = buildReferenceData([
        song('Same', '2024-01-01T00:00:00.000Z'),
        song('Same', '2024-01-01T00:00:00.000Z'),
      ], generated: DateTime.utc(2026, 1, 1));
      expect([for (final x in data['P'] as List) (x as Map)['l']], [0, 1]);
    });

    test('the .cpr suffix is dropped from a name, "V2" kept', () {
      final data = buildReferenceData([
        song('Thing.cpr', '2024-01-01T00:00:00.000Z'),
        song('Thing.cpr V2', '2024-01-02T00:00:00.000Z'),
      ], generated: DateTime.utc(2026, 1, 1));
      expect([for (final x in data['P'] as List) (x as Map)['n']],
          ['Thing', 'Thing V2']);
    });

    test('Cubase "13.0" is version 13, a missing version is 0', () {
      final a = _project('a', const []);
      final withMinor = CorpusProject(
        projectId: 'b',
        name: 'b',
        cubaseVersion: '13.0',
        modified: DateTime.utc(2025),
        tracks: const [],
      );
      final none = CorpusProject(
        projectId: 'c',
        name: 'c',
        modified: DateTime.utc(2025),
        tracks: const [],
      );
      final data = buildReferenceData([a, withMinor, none],
          generated: DateTime.utc(2026));
      expect([for (final x in data['P'] as List) (x as Map)['v']],
          [13, 13, 0]);
    });

    test('an unknown track with no insert is left out, except in masters',
        () {
      final unknown = CorpusTrack(
          index: 0, name: 'x', role: 'unknown', type: CubaseTrackType.audio);
      final data = buildReferenceData([
        _project('Scratch', [unknown]),
        _project('Thing (Master)', [unknown]),
      ], generated: DateTime.utc(2026));
      final tracks = [
        for (final x in data['P'] as List) ((x as Map)['t'] as List).length,
      ];
      expect(tracks, [0, 1]);
      expect((data['meta'] as Map)['unknownTracks'], 2,
          reason: 'counted whether kept or not');
    });

    test('inserts are in slot order, active is 1 and bypassed 0', () {
      final data = buildReferenceData([
        _project('Thing (Master)', [
          CorpusTrack(
            index: 0,
            name: 'Master',
            role: 'master',
            type: CubaseTrackType.audio,
            inserts: const [
              CubaseInsert(slot: 5, plugin: 'B', bypassed: true),
              CubaseInsert(slot: 1, plugin: 'A', bypassed: false),
              CubaseInsert(slot: 3, plugin: 'C'),
            ],
          ),
        ]),
      ], generated: DateTime.utc(2026));
      final flat = (((data['P'] as List).single as Map)['t'] as List)
          .single[4] as List;
      expect(flat, [1, 0, 1, 3, 1, 1, 5, 2, 0]);
      expect(data['PL'], ['A', 'C', 'B']);
    });

    test('a project with no tracks is still a record', () {
      final data = buildReferenceData([_project('Empty', const [])],
          generated: DateTime.utc(2026));
      final record = (data['P'] as List).single as Map;
      expect(record['nt'], 0);
      expect(record['t'], isEmpty);
    });

    test('no projects at all is an empty but complete document', () {
      final data = buildReferenceData(const [], generated: DateTime.utc(2026));
      expect((data['meta'] as Map)['n'], 0);
      expect(data['P'], isEmpty);
      expect(() => jsonEncode(data), returnsNormally);
    });
  });

  group('renderReferenceHtml', () {
    final data = {
      'meta': {'n': 1},
      'P': [
        {'n': '</script><b>x</b>'},
      ],
    };

    test('puts the data where the placeholder is, and nowhere else', () {
      final html = renderReferenceHtml('<a>__DATA__</a>', data);
      expect(html.startsWith('<a>{'), isTrue);
      expect(html.endsWith('}</a>'), isTrue);
      expect(html, isNot(contains('__DATA__')));
    });

    test('a name cannot close the script tag', () {
      final html = renderReferenceHtml('<script>__DATA__</script>', data);
      expect('</script>'.allMatches(html), hasLength(1));
      // It is still the same data once the browser has parsed the JSON.
      final inner = html.substring(
          '<script>'.length, html.length - '</script>'.length);
      expect(jsonDecode(inner), data);
    });

    test('the text goes in where its placeholder is, escaped like the data',
        () {
      final html = renderReferenceHtml(
        '<i>__I18N__</i><d>__DATA__</d>',
        data,
        i18n: {
          'lang': 'en',
          's': {'k': '<b>bold</b>'},
        },
      );
      expect(html, contains(r'\u' '003cb>bold'));
      expect(html, isNot(contains('<b>bold')));
      expect(html, isNot(contains('__I18N__')));
    });

    test('data that looks like a placeholder is left alone', () {
      final html = renderReferenceHtml(
        '<i>__I18N__</i><d>__DATA__</d>',
        {'P': ['__I18N__ and __DATA__']},
        i18n: {'lang': 'en', 's': <String, Object?>{}},
      );
      expect(html, contains('__I18N__ and __DATA__'));
    });

    test('a template without the text placeholder still renders', () {
      expect(
        renderReferenceHtml('<d>__DATA__</d>', data,
            i18n: {'lang': 'en', 's': <String, Object?>{}}),
        startsWith('<d>{'),
      );
    });

    test('a template without the placeholder is an error, not a blank page',
        () {
      expect(() => renderReferenceHtml('<p>nothing</p>', data),
          throwsArgumentError);
    });
  });

  group('the shipped template', () {
    final template =
        File(p.join('assets', 'reference', 'index.template.html'))
            .readAsStringSync();

    test('has one placeholder for the data and one for the text', () {
      expect('__DATA__'.allMatches(template), hasLength(1));
      expect('__I18N__'.allMatches(template), hasLength(1));
      expect(template,
          contains('<script type="application/json" id="data">__DATA__</script>'));
      expect(template,
          contains('<script type="application/json" id="i18n">__I18N__</script>'));
    });

    test('is declared as an asset, with its text', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/reference/index.template.html'));
      expect(pubspec, contains('assets/reference/strings.json'));
    });

    test('carries no wording of its own: every word is in the dictionary', () {
      // An accented letter would be Portuguese, French… left in the page.
      // (× and ÷ sit in that range but are signs, not letters.)
      expect(RegExp('[À-ÖØ-öø-ÿ]').hasMatch(template), isFalse);
    });

    test('names no particular library in its notes', () {
      expect(template, isNot(contains('2024-07-21')));
      expect(template, isNot(contains('PsyScope')));
      expect(template, isNot(contains('Cubase 11 e 13')));
    });

    test('the page built from the fixture is complete and parseable', () {
      final data = buildReferenceData(_fixtureCorpus(),
          generated: DateTime.utc(2026, 10, 9));
      final html = renderReferenceHtml(template, data,
          i18n: referenceStrings(_dictionary(), 'pt'));
      String embedded(String id) {
        final open = '<script type="application/json" id="$id">';
        final from = html.indexOf(open) + open.length;
        return html.substring(from, html.indexOf('</script>', from));
      }

      expect(jsonDecode(embedded('data')), jsonDecode(jsonEncode(data)));
      expect((jsonDecode(embedded('i18n')) as Map)['lang'], 'pt');
    });
  });

  group('the dictionary', () {
    final dictionary = _dictionary();
    final english = dictionary['en'] as Map<String, Object?>;
    final template =
        File(p.join('assets', 'reference', 'index.template.html'))
            .readAsStringSync();

    Set<String> placeholders(Object? value) {
      final forms = value is Map ? value.values : [value];
      return {
        for (final form in forms)
          for (final m in RegExp(r'\{(\w+)\}').allMatches(form as String))
            m.group(1)!,
      };
    }

    test('has every language the app has', () {
      final arbs = Directory(p.join('lib', 'l10n'))
          .listSync()
          .map((f) => p.basenameWithoutExtension(f.path))
          .where((n) => n.startsWith('app_'))
          .map((n) => n.substring(4))
          .toSet();
      expect(dictionary.keys.toSet(), arbs);
    });

    for (final language in _dictionary().keys.where((k) => k != 'en')) {
      test('$language has exactly the keys English has, with the same blanks',
          () {
        final own = dictionary[language] as Map<String, Object?>;
        expect(own.keys.toSet(), english.keys.toSet());
        for (final key in english.keys) {
          expect(placeholders(own[key]), placeholders(english[key]),
              reason: '$language / $key');
        }
      });
    }

    test('no text is empty, and a plural always has "other"', () {
      for (final MapEntry(key: language, value: entries) in dictionary.entries) {
        for (final MapEntry(key: key, value: value)
            in (entries as Map<String, Object?>).entries) {
          if (value is Map) {
            expect(value['other'], isA<String>(), reason: '$language / $key');
            expect(
                value.keys.toSet().difference({'one', 'few', 'many', 'other'}),
                isEmpty,
                reason: '$language / $key');
          }
          final forms = value is Map ? value.values : [value];
          for (final form in forms) {
            expect((form as String).trim(), isNotEmpty,
                reason: '$language / $key');
          }
        }
      }
    });

    test('every key the page asks for exists', () {
      final asked = {
        for (final m in RegExp(r"\bt\('([^']+)'").allMatches(template))
          m.group(1)!,
        for (final m
            in RegExp(r"'((?:group|role)\.[A-Za-z]+)'").allMatches(template))
          m.group(1)!,
      };
      expect(asked, isNotEmpty);
      // The ones put together in code are checked in the next test.
      asked.removeAll({'tier.', 'genName', 'genDesc'});
      expect(asked.difference(english.keys.toSet()), isEmpty);
    });

    test('every key is used by the page, so none is left behind', () {
      // These are put together in code: 'tier.' + tier, 'genName' + number.
      const built = {
        'tier.core', 'tier.common', 'tier.rare', //
        'genName0', 'genName1', 'genName2', 'genName3',
        'genDesc0', 'genDesc1', 'genDesc2', 'genDesc3',
      };
      expect(template, contains("'tier.'"));
      expect(template, contains("'genName'"));
      expect(template, contains("'genDesc'"));
      final unused = [
        for (final key in english.keys)
          if (!built.contains(key) && !template.contains("'$key'")) key,
      ];
      expect(unused, isEmpty);
    });
  });

  group('referenceStrings', () {
    final dictionary = <String, Object?>{
      'en': {'a': 'Apple', 'b': 'Bread'},
      'pt': {'a': 'Maçã'},
    };

    test('gives the language its own text', () {
      final s = referenceStrings(dictionary, 'pt');
      expect(s['lang'], 'pt');
      expect((s['s'] as Map)['a'], 'Maçã');
    });

    test('what a language lacks shows in English, never as a key', () {
      expect(((referenceStrings(dictionary, 'pt')['s']) as Map)['b'], 'Bread');
    });

    test('a language the page does not have is English', () {
      final s = referenceStrings(dictionary, 'xx');
      expect(s['lang'], 'en');
      expect((s['s'] as Map)['a'], 'Apple');
    });

    test('with no dictionary at all there is still a usable structure', () {
      final s = referenceStrings(const {}, 'pt');
      expect(s['lang'], 'en');
      expect(s['s'], isEmpty);
    });
  });

  group('ReferenceCache', () {
    late Directory dir;
    late File file;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('reference_cache');
      file = File(p.join(dir.path, 'cache.json'));
    });
    tearDown(() => dir.deleteSync(recursive: true));

    MusicProject cpr(String id, {int size = 1000, DateTime? modified}) =>
        TestFactories.makeProject(
          id: id,
          filePath: p.join('songs', '$id.cpr'),
          fileName: '$id.cpr',
          fileSizeBytes: size,
          lastModifiedAt: modified ?? DateTime.utc(2025, 1, 1),
          dawVersion: '13',
        );

    final tracks = [
      const CubaseTrack(
        index: 0,
        name: 'Kick',
        type: CubaseTrackType.sampler,
        parent: 'DRUMS',
        output: 'Stereo Out',
        inserts: [
          CubaseInsert(slot: 2, plugin: 'Pro-Q 3', bypassed: true),
          CubaseInsert(slot: 4, plugin: 'Simplon'),
        ],
      ),
      const CubaseTrack(index: 1, name: 'Bare', type: CubaseTrackType.audio),
    ];

    test('keeps what was read through a save and a load', () async {
      final cache = ReferenceCache(file);
      final a = cpr('a');
      cache.put(a, tracks);
      await cache.save();

      final loaded = await ReferenceCache.load(file);
      expect(loaded.length, 1);
      final back = loaded.tracksOf('a')!;
      expect(back, hasLength(2));
      expect(back[0].name, 'Kick');
      expect(back[0].type, CubaseTrackType.sampler);
      expect(back[0].parent, 'DRUMS');
      expect(back[0].output, 'Stereo Out');
      expect(
        [for (final i in back[0].inserts) (i.slot, i.plugin, i.bypassed)],
        [(2, 'Pro-Q 3', true), (4, 'Simplon', null)],
      );
      expect(back[1].parent, isNull);
      expect(back[1].inserts, isEmpty);
    });

    test('an entry is fresh only for the file it was read from', () {
      final cache = ReferenceCache(file)..put(cpr('a'), tracks);
      expect(cache.isFresh(cpr('a')), isTrue);
      expect(cache.isFresh(cpr('a', size: 1001)), isFalse,
          reason: 'size changed');
      expect(cache.isFresh(cpr('a', modified: DateTime.utc(2025, 1, 2))),
          isFalse, reason: 'modified');
      expect(cache.isFresh(cpr('other')), isFalse);
    });

    test('a stale entry still gives its tracks, for "use what is read"', () {
      final cache = ReferenceCache(file)..put(cpr('a'), tracks);
      expect(cache.isFresh(cpr('a', size: 5)), isFalse);
      expect(cache.tracksOf('a'), isNotNull);
    });

    test('a missing, damaged or foreign file is an empty cache', () async {
      expect((await ReferenceCache.load(file)).length, 0);
      file.writeAsStringSync('{ not json');
      expect((await ReferenceCache.load(file)).length, 0);
      file.writeAsStringSync('{"version":99,"projects":{}}');
      expect((await ReferenceCache.load(file)).length, 0);
      file.writeAsStringSync(
          '{"version":1,"projects":{"a":{"s":1,"m":1,"t":[{"i":0}]}}}');
      expect((await ReferenceCache.load(file)).length, 0,
          reason: 'an entry that does not parse is dropped, not guessed');
    });

    test('projects that left the library are forgotten', () {
      final cache = ReferenceCache(file)
        ..put(cpr('a'), tracks)
        ..put(cpr('b'), tracks)
        ..retainOnly({'b'});
      expect(cache.tracksOf('a'), isNull);
      expect(cache.tracksOf('b'), isNotNull);
    });

    test('only new or changed Cubase files whose file exists are to be read',
        () {
      final cache = ReferenceCache(file)
        ..put(cpr('fresh'), tracks)
        ..put(cpr('changed'), tracks);
      final projects = [
        cpr('fresh'),
        cpr('changed', size: 2),
        cpr('brandnew'),
        cpr('gone'),
        TestFactories.makeProject(id: 'als', filePath: 'x.als'),
        TestFactories.makeProject(
            id: 'stack', filePath: 'folder', isVirtual: true),
        TestFactories.makeProject(
            id: 'zip',
            filePath: p.join('a', 'Old.cpr'),
            archivePath: 'old.zip'),
      ];
      final toRead = projectsToReadForReference(
        projects,
        cache,
        fileExists: (path) => p.basename(path) != 'gone.cpr',
      );
      expect(toRead.map((x) => x.id), ['changed', 'brandnew']);
    });

    test('reading a project stores its tracks; a failed read stores nothing',
        () async {
      final cache = ReferenceCache(file);
      await readProjectIntoCache(cpr('ok'), cache,
          readTracks: (_) async => tracks);
      await readProjectIntoCache(cpr('bad'), cache,
          readTracks: (_) async => null);
      await readProjectIntoCache(cpr('empty'), cache,
          readTracks: (_) async => const []);
      expect(cache.tracksOf('ok'), isNotNull);
      expect(cache.tracksOf('bad'), isNull);
      expect(cache.tracksOf('empty'), isNull);
    });

    test('a failed re-read keeps the earlier tracks', () async {
      final old = cpr('a');
      final cache = ReferenceCache(file)..put(old, tracks);
      await readProjectIntoCache(cpr('a', size: 9), cache,
          readTracks: (_) async => null);
      expect(cache.tracksOf('a'), hasLength(2));
    });

    test('the corpus is built fresh from the project, roles from the names',
        () {
      final named = TestFactories.makeProject(
        id: 'n',
        filePath: p.join('songs', 'n.cpr'),
        fileName: 'n.cpr',
        customDisplayName: 'My Song (Master)',
        dawVersion: '13',
        lastModifiedAt: DateTime.utc(2025, 5, 5),
      );
      final cache = ReferenceCache(file)
        ..put(named, tracks)
        ..put(cpr('z'), tracks);
      final corpus = referenceCorpus([cpr('z'), named], cache);
      expect(corpus.map((c) => c.name), ['My Song (Master)', 'z'],
          reason: 'sorted by name, not library order');
      expect(corpus.first.cubaseVersion, '13');
      expect(corpus.first.tracks.first.role, 'kick');
      expect(corpus.first.modified, DateTime.utc(2025, 5, 5));
    });

    test('a project never read is not in the corpus', () {
      final cache = ReferenceCache(file);
      expect(referenceCorpus([cpr('a')], cache), isEmpty);
    });

    test('the page is built from the cache, and says how many projects', () {
      final cache = ReferenceCache(file)
        ..put(cpr('a'), tracks)
        ..put(cpr('b'), tracks);
      final page = buildReferencePage(
        [cpr('a'), cpr('b'), cpr('never')],
        cache,
        template: '<i>__I18N__</i><script>__DATA__</script>',
        stringsJson: jsonEncode({
          'en': {'title': 'Insert reference'},
          'pt': {'title': 'Referência de inserts'},
        }),
        languageCode: 'pt',
        now: DateTime.utc(2026, 10, 9),
      );
      expect(page.projects, 2);
      expect(page.html, contains('"generated":"2026-10-09"'));
      expect(page.html, contains('"n":2'));
      expect(page.html, contains('"lang":"pt"'));
      expect(page.html, contains('Referência de inserts'));
    });
  });
}
