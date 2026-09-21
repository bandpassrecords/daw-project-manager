import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/changelog_service.dart';

void main() {
  ChangelogRelease release(
    String version,
    List<String> en, {
    Map<String, List<String>> extra = const {},
    DateTime? date,
  }) =>
      ChangelogRelease(
        version: version,
        date: date,
        highlightsByLocale: {'en': en, ...extra},
      );

  group('compareVersions', () {
    test('orders by major, then minor, then patch', () {
      expect(compareVersions('3.0.0', '2.9.9'), greaterThan(0));
      expect(compareVersions('2.9.0', '2.10.0'), lessThan(0));
      expect(compareVersions('2.9.1', '2.9.0'), greaterThan(0));
    });

    test('treats missing components as zero', () {
      expect(compareVersions('2.9', '2.9.0'), 0);
      expect(compareVersions('2', '2.0.0'), 0);
    });

    test('treats an unparseable component as zero rather than throwing', () {
      expect(compareVersions('2.x.0', '2.0.0'), 0);
      expect(compareVersions('', '0.0.0'), 0);
    });
  });

  group('parseChangelog', () {
    test('reads versions, dates and per-locale highlights', () {
      final releases = parseChangelog(jsonEncode({
        'releases': [
          {
            'version': '2.9.0',
            'date': '2026-09-22',
            'highlights': {
              'en': ['English line'],
              'pt': ['Linha em português'],
            },
          },
        ],
      }));

      expect(releases, hasLength(1));
      expect(releases.single.version, '2.9.0');
      expect(releases.single.date, DateTime(2026, 9, 22));
      expect(releases.single.highlightsFor('en'), ['English line']);
      expect(releases.single.highlightsFor('pt'), ['Linha em português']);
    });

    test('sorts newest first regardless of the file\'s order', () {
      final releases = parseChangelog(jsonEncode({
        'releases': [
          {'version': '2.8.0', 'highlights': {'en': ['old']}},
          {'version': '2.10.0', 'highlights': {'en': ['newest']}},
          {'version': '2.9.0', 'highlights': {'en': ['middle']}},
        ],
      }));

      expect(
        releases.map((r) => r.version).toList(),
        ['2.10.0', '2.9.0', '2.8.0'],
      );
    });

    test('skips entries with no version or no highlights', () {
      final releases = parseChangelog(jsonEncode({
        'releases': [
          {'version': '', 'highlights': {'en': ['x']}},
          {'version': '2.9.0'},
          {'version': '2.8.0', 'highlights': {'en': []}},
          {'version': '2.7.0', 'highlights': {'en': ['kept']}},
        ],
      }));

      expect(releases.map((r) => r.version).toList(), ['2.7.0']);
    });

    test('drops blank highlight lines and trims the rest', () {
      final releases = parseChangelog(jsonEncode({
        'releases': [
          {
            'version': '2.9.0',
            'highlights': {
              'en': ['  padded  ', '   ', 'kept'],
            },
          },
        ],
      }));

      expect(releases.single.highlightsFor('en'), ['padded', 'kept']);
    });

    test('returns empty rather than throwing on malformed JSON', () {
      expect(parseChangelog('not json at all'), isEmpty);
      expect(parseChangelog('[]'), isEmpty);
      expect(parseChangelog('{}'), isEmpty);
      expect(parseChangelog(jsonEncode({'releases': 'nope'})), isEmpty);
    });
  });

  group('ChangelogRelease.highlightsFor', () {
    test('falls back to English for a locale with no translation', () {
      final r = release('2.9.0', ['English']);
      expect(r.highlightsFor('ja'), ['English']);
    });

    test('resolves a regional locale to its base language', () {
      final r = release('2.9.0', ['English'], extra: {
        'pt': ['Português'],
      });
      expect(r.highlightsFor('pt-BR'), ['Português']);
      expect(r.highlightsFor('pt_BR'), ['Português']);
    });

    test('returns empty when even English is missing', () {
      const r = ChangelogRelease(
        version: '2.9.0',
        date: null,
        highlightsByLocale: {'ja': []},
      );
      expect(r.highlightsFor('en'), isEmpty);
    });
  });

  group('changelogToShow', () {
    final changelog = [
      release('2.9.0', ['newest']),
      release('2.8.0', ['middle']),
      release('2.7.0', ['oldest']),
    ];

    test('shows every entry between the last seen version and this one', () {
      final shown = changelogToShow(
        lastSeenVersion: '2.7.0',
        currentVersion: '2.9.0',
        changelog: changelog,
      );
      expect(shown.map((r) => r.version).toList(), ['2.9.0', '2.8.0']);
    });

    test('shows nothing on a fresh install (no last seen version)', () {
      // A list of changes since a version the user never ran is noise — the
      // caller still records the current version so the NEXT update shows.
      expect(
        changelogToShow(
          lastSeenVersion: null,
          currentVersion: '2.9.0',
          changelog: changelog,
        ),
        isEmpty,
      );
      expect(
        changelogToShow(
          lastSeenVersion: '',
          currentVersion: '2.9.0',
          changelog: changelog,
        ),
        isEmpty,
      );
    });

    test('shows nothing when the version has not moved', () {
      expect(
        changelogToShow(
          lastSeenVersion: '2.9.0',
          currentVersion: '2.9.0',
          changelog: changelog,
        ),
        isEmpty,
      );
    });

    test('shows nothing on a downgrade', () {
      expect(
        changelogToShow(
          lastSeenVersion: '2.9.0',
          currentVersion: '2.8.0',
          changelog: changelog,
        ),
        isEmpty,
      );
    });

    test('never shows an entry newer than the running build', () {
      final shown = changelogToShow(
        lastSeenVersion: '2.7.0',
        currentVersion: '2.8.0',
        changelog: changelog,
      );
      expect(shown.map((r) => r.version).toList(), ['2.8.0']);
    });

    test('shows nothing when no entry falls between the two versions', () {
      final shown = changelogToShow(
        lastSeenVersion: '2.9.0',
        currentVersion: '2.9.5',
        changelog: changelog,
      );
      expect(shown, isEmpty);
    });
  });

  group('changelogFor', () {
    test('finds the entry for an exact version', () {
      final changelog = [release('2.9.0', ['a']), release('2.8.0', ['b'])];
      expect(
        changelogFor('2.9.0', changelog: changelog).single.version,
        '2.9.0',
      );
    });

    test('matches versions that differ only in omitted components', () {
      final changelog = [release('2.9.0', ['a'])];
      expect(changelogFor('2.9', changelog: changelog), hasLength(1));
    });

    test('returns empty for a version with no entry', () {
      final changelog = [release('2.9.0', ['a'])];
      expect(changelogFor('1.0.0', changelog: changelog), isEmpty);
    });
  });

  group('the shipped changelog asset', () {
    // Read off disk rather than through rootBundle: this asserts the
    // committed file is well-formed, which is what the release workflow's
    // "Verify changelog has an entry for the tag" step also depends on.
    late List<ChangelogRelease> shipped;

    setUpAll(() {
      shipped = parseChangelog(
        File('assets/changelog/changelog.json').readAsStringSync(),
      );
    });

    test('parses and is not empty', () {
      expect(shipped, isNotEmpty);
    });

    test('every entry has English highlights and a date', () {
      for (final release in shipped) {
        expect(
          release.highlightsByLocale['en'],
          isNotEmpty,
          reason: '${release.version} is missing English highlights',
        );
        expect(
          release.date,
          isNotNull,
          reason: '${release.version} is missing a date',
        );
      }
    });

    test('has no duplicate versions', () {
      final versions = shipped.map((r) => r.version).toList();
      expect(versions.toSet(), hasLength(versions.length));
    });

    test('every locale lists the same number of highlights as English', () {
      // A locale that fell behind should be *absent* (it then falls back to
      // English wholesale) rather than present with half the lines, which
      // would silently drop a highlight for those users.
      for (final release in shipped) {
        final expected = release.highlightsByLocale['en']!.length;
        release.highlightsByLocale.forEach((locale, lines) {
          expect(
            lines,
            hasLength(expected),
            reason: '${release.version}/$locale has ${lines.length} '
                'highlights, English has $expected',
          );
        });
      }
    });
  });
}
