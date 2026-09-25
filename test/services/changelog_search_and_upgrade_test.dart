import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/services/changelog_service.dart';

import '../helpers/hive_test_helper.dart';

ChangelogRelease _release(
  String version,
  List<String> en, {
  Map<String, List<String>> extra = const {},
}) =>
    ChangelogRelease(
      version: version,
      date: DateTime(2026, 1, 1),
      highlightsByLocale: {'en': en, ...extra},
    );

void main() {
  final changelog = [
    _release('2.9.0', ['Volume is remembered', 'Breadcrumbs in the title bar']),
    _release('2.8.0', ['Parts & performers', 'REAPER markers']),
    _release('2.7.4', ['Fixed sharing on Android']),
  ];

  group('filterChangelog', () {
    test('a blank query returns everything, untouched', () {
      expect(identical(filterChangelog(changelog, '  ', localeCode: 'en'),
          changelog), isTrue);
    });

    test('keeps only the lines that match, case-insensitively', () {
      final hits = filterChangelog(changelog, 'VOLUME', localeCode: 'en');

      expect(hits.map((r) => r.version), ['2.9.0']);
      expect(hits.single.highlightsFor('en'), ['Volume is remembered']);
    });

    test('finds matches across several releases', () {
      final hits = filterChangelog(changelog, 'r', localeCode: 'en');
      expect(hits, hasLength(3));
    });

    test('a version match keeps the whole release', () {
      final hits = filterChangelog(changelog, '2.8', localeCode: 'en');

      expect(hits.single.version, '2.8.0');
      expect(hits.single.highlightsFor('en'), hasLength(2));
    });

    test('matches the way the dashboard project search does', () {
      // Word-anchored fuzzy chunks, as in fuzzyMatchAll: bre|adcrumbs ti|tle.
      final hits = filterChangelog(changelog, 'bretit', localeCode: 'en');
      expect(hits.single.highlightsFor('en'), ['Breadcrumbs in the title bar']);
    });

    test('every word has to match, in any order', () {
      final hits =
          filterChangelog(changelog, 'bar breadcrumbs', localeCode: 'en');
      expect(hits.single.highlightsFor('en'), ['Breadcrumbs in the title bar']);
      expect(filterChangelog(changelog, 'volume reaper', localeCode: 'en'),
          isEmpty);
    });

    test('a version and a word narrow to that release line', () {
      final hits = filterChangelog(changelog, '2.8 reaper', localeCode: 'en');
      expect(hits.single.version, '2.8.0');
      expect(hits.single.highlightsFor('en'), ['REAPER markers']);
    });

    test('does not scavenge letters across unrelated words', () {
      // A plain subsequence test finds l-u-m in Volume and b-e-r in remembered.
      expect(filterChangelog(changelog, 'lumber', localeCode: 'en'), isEmpty);
    });

    test('nothing matching gives an empty list', () {
      expect(filterChangelog(changelog, 'zzz', localeCode: 'en'), isEmpty);
    });

    test('searches the text shown in the current language', () {
      final translated = [
        _release('2.9.0', ['Volume is remembered'], extra: {
          'pt': ['O volume fica salvo'],
        }),
      ];

      expect(filterChangelog(translated, 'salvo', localeCode: 'pt'),
          hasLength(1));
      expect(filterChangelog(translated, 'remembered', localeCode: 'pt'),
          isEmpty,
          reason: 'the English text is not what a Portuguese user sees');
    });
  });

  group('upgradeBaselineVersion', () {
    test('is the newest release older than the running one', () {
      expect(upgradeBaselineVersion('2.9.0', changelog: changelog), '2.8.0');
    });

    test('is null when nothing is older', () {
      expect(upgradeBaselineVersion('2.7.4', changelog: changelog), isNull);
    });

    test('ignores releases newer than the running one', () {
      expect(upgradeBaselineVersion('2.8.0', changelog: changelog), '2.7.4');
    });
  });

  group('first update after the changelog was introduced', () {
    // Every build before 2.9.0 ran without recording a last-seen version, so
    // an upgrade from one looked exactly like a fresh install and the What's
    // New dialog stayed silent on the very update that added it.
    late Directory tempDir;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      ChangelogService.cacheForTest = changelog;
    });

    tearDown(() async {
      ChangelogService.cacheForTest = null;
      await HiveTestHelper.tearDown(tempDir);
    });

    test('an install used before shows the version it updated to', () async {
      await ChangelogService.seedBaselineForUpgrade(
        hadPriorUse: true,
        currentVersion: '2.9.0',
      );

      final shown = await ChangelogService.takePendingChangelog('2.9.0');
      expect(shown.map((r) => r.version), ['2.9.0'],
          reason: 'the new version only — not all 74 older ones');
    });

    test('shows once, then never again for the same version', () async {
      await ChangelogService.seedBaselineForUpgrade(
        hadPriorUse: true,
        currentVersion: '2.9.0',
      );
      await ChangelogService.takePendingChangelog('2.9.0');

      expect(await ChangelogService.takePendingChangelog('2.9.0'), isEmpty);
    });

    test('a genuinely fresh install still shows nothing', () async {
      await ChangelogService.seedBaselineForUpgrade(
        hadPriorUse: false,
        currentVersion: '2.9.0',
      );

      expect(await ChangelogService.takePendingChangelog('2.9.0'), isEmpty);
    });

    test('never overwrites a last-seen version that already exists', () async {
      await ChangelogService.saveLastSeenVersion('2.7.4');
      await ChangelogService.seedBaselineForUpgrade(
        hadPriorUse: true,
        currentVersion: '2.9.0',
      );

      expect(await ChangelogService.loadLastSeenVersion(), '2.7.4');
      final shown = await ChangelogService.takePendingChangelog('2.9.0');
      expect(shown.map((r) => r.version), ['2.9.0', '2.8.0'],
          reason: 'someone who skipped 2.8.0 sees both');
    });

    test('the seed lives in the device-local settings box', () async {
      await ChangelogService.seedBaselineForUpgrade(
        hadPriorUse: true,
        currentVersion: '2.9.0',
      );
      final box = await Hive.openBox<String>('settings');
      expect(box.get(kLastSeenChangelogVersionKey), '2.8.0');
    });
  });
}
