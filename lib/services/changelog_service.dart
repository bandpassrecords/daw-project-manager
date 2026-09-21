import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_ce/hive.dart';

/// Where the changelog lives. A committed JSON asset rather than Dart
/// constants or a live fetch of the GitHub release notes:
///
/// - It has to work offline and inside Flatpak, whose manifest drops
///   `--share=network` entirely (see `flatpak/README.md`) — so anything that
///   reads github.com at runtime is not an option for every build.
/// - The list only grows. Keeping it as data means adding a release is a
///   scripted edit to one file (`scripts/new_changelog_entry.py`) run before
///   tagging, not a code change.
/// - Highlight text is *data*, so a long history can carry per-locale strings
///   without adding nine ARB keys per release. The UI chrome around it
///   (titles, buttons) is still localized the normal way.
const String kChangelogAssetPath = 'assets/changelog/changelog.json';

/// One shipped version and the handful of changes worth telling someone
/// about. Deliberately highlights, not a commit log — the GitHub release
/// notes stay the complete record.
@immutable
class ChangelogRelease {
  const ChangelogRelease({
    required this.version,
    required this.date,
    required this.highlightsByLocale,
  });

  /// Bare semver, no leading `v` — compared against `appVersion`, which is
  /// also bare.
  final String version;

  /// Release date as written in the asset (`YYYY-MM-DD`), or null when the
  /// entry omitted it.
  final DateTime? date;

  /// Locale code (`en`, `pt`, …) to that locale's highlight lines.
  final Map<String, List<String>> highlightsByLocale;

  /// The highlights to show for [localeCode], falling back to English.
  ///
  /// The fallback is what lets a release ship before its translations land:
  /// a missing locale shows English rather than an empty dialog.
  List<String> highlightsFor(String localeCode) {
    final exact = highlightsByLocale[localeCode];
    if (exact != null && exact.isNotEmpty) return exact;
    // `pt_BR` and the like resolve to their base language.
    final base = localeCode.split(RegExp(r'[_-]')).first;
    final baseMatch = highlightsByLocale[base];
    if (baseMatch != null && baseMatch.isNotEmpty) return baseMatch;
    return highlightsByLocale['en'] ?? const [];
  }

  @override
  bool operator ==(Object other) {
    if (other is! ChangelogRelease) return false;
    if (other.version != version || other.date != date) return false;
    if (other.highlightsByLocale.length != highlightsByLocale.length) {
      return false;
    }
    for (final entry in highlightsByLocale.entries) {
      if (!listEquals(other.highlightsByLocale[entry.key], entry.value)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(version, date, highlightsByLocale.length);
}

/// Parses the changelog asset's contents.
///
/// Tolerant by design — a malformed or truncated changelog must never stop
/// the app from starting, so anything unparseable yields an empty list and
/// the dialog simply doesn't appear. Entries missing a version or highlights
/// are skipped individually. The result is sorted newest-first regardless of
/// the file's own order.
List<ChangelogRelease> parseChangelog(String jsonSource) {
  try {
    final decoded = jsonDecode(jsonSource);
    if (decoded is! Map<String, dynamic>) return const [];
    final entries = decoded['releases'];
    if (entries is! List) return const [];

    final releases = <ChangelogRelease>[];
    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) continue;
      final version = (entry['version'] as String?)?.trim();
      if (version == null || version.isEmpty) continue;

      final rawHighlights = entry['highlights'];
      if (rawHighlights is! Map) continue;
      final highlights = <String, List<String>>{};
      rawHighlights.forEach((locale, lines) {
        if (locale is! String || lines is! List) return;
        final texts = [
          for (final line in lines)
            if (line is String && line.trim().isNotEmpty) line.trim(),
        ];
        if (texts.isNotEmpty) highlights[locale] = texts;
      });
      if (highlights.isEmpty) continue;

      releases.add(
        ChangelogRelease(
          version: version,
          date: DateTime.tryParse((entry['date'] as String?) ?? ''),
          highlightsByLocale: highlights,
        ),
      );
    }
    releases.sort((a, b) => compareVersions(b.version, a.version));
    return releases;
  } catch (e) {
    debugPrint('[Changelog] failed to parse changelog asset: $e');
    return const [];
  }
}

/// Compares two bare semver strings. Negative if [a] is older than [b], zero
/// if they are the same version, positive if [a] is newer.
///
/// Missing components count as zero (`2.9` == `2.9.0`), and anything
/// unparseable counts as zero too — a malformed version degrades into "the
/// oldest thing we know about" rather than throwing at startup.
int compareVersions(String a, String b) {
  final pa = _parseVersion(a);
  final pb = _parseVersion(b);
  for (var i = 0; i < 3; i++) {
    if (pa[i] != pb[i]) return pa[i] - pb[i];
  }
  return 0;
}

List<int> _parseVersion(String v) {
  final parts = v.split('.').map((s) => int.tryParse(s.trim()) ?? 0).toList();
  while (parts.length < 3) {
    parts.add(0);
  }
  return parts.sublist(0, 3);
}

/// The changelog entries to show on this launch, newest first.
///
/// Empty — nothing is shown — when:
/// - [lastSeenVersion] is null. That is a **fresh install**, where a list of
///   changes since a version the user never ran would be noise. The caller
///   still records [currentVersion] so the *next* update does show.
/// - The app is running the same version as last time, or an older one (a
///   downgrade, or a dev build whose `APP_VERSION` was not defined).
/// - The versions moved but no entry falls between them.
///
/// Entries newer than [currentVersion] are excluded as well: the asset ships
/// inside the app, so a build can only ever describe itself and what came
/// before it.
List<ChangelogRelease> changelogToShow({
  required String? lastSeenVersion,
  required String currentVersion,
  required List<ChangelogRelease> changelog,
}) {
  if (lastSeenVersion == null || lastSeenVersion.isEmpty) return const [];
  if (compareVersions(currentVersion, lastSeenVersion) <= 0) return const [];
  return [
    for (final release in changelog)
      if (compareVersions(release.version, lastSeenVersion) > 0 &&
          compareVersions(release.version, currentVersion) <= 0)
        release,
  ]..sort((a, b) => compareVersions(b.version, a.version));
}

/// The entry for [version], or an empty list when that version has none.
/// Used by the Settings entry point that re-opens the dialog for the running
/// build on demand.
List<ChangelogRelease> changelogFor(
  String version, {
  required List<ChangelogRelease> changelog,
}) {
  return [
    for (final release in changelog)
      if (compareVersions(release.version, version) == 0) release,
  ];
}

/// Where the last version whose changelog was shown is remembered.
///
/// Deliberately **device-local**: it records what this installation has
/// already displayed, not anything about the user's library, so it is in
/// neither Drive sync nor local backup. Restoring a backup onto a new machine
/// should not suppress that machine's first "What's New".
const String kLastSeenChangelogVersionKey = 'lastSeenChangelogVersion';

class ChangelogService {
  const ChangelogService._();

  /// Parsed once per run. The asset is a few KB and never changes while the
  /// app is open, so re-reading it for the Settings page would be pure work.
  static List<ChangelogRelease>? _cache;

  @visibleForTesting
  static set cacheForTest(List<ChangelogRelease>? value) => _cache = value;

  static Future<List<ChangelogRelease>> loadChangelog() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final source = await rootBundle.loadString(kChangelogAssetPath);
      return _cache = parseChangelog(source);
    } catch (e) {
      // A missing asset must not be fatal — the app just has no changelog.
      debugPrint('[Changelog] failed to load $kChangelogAssetPath: $e');
      return _cache = const [];
    }
  }

  static Future<Box<String>> _box() => Hive.openBox<String>('settings');

  static Future<String?> loadLastSeenVersion() async {
    final box = await _box();
    final stored = box.get(kLastSeenChangelogVersionKey);
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  static Future<void> saveLastSeenVersion(String version) async {
    final box = await _box();
    await box.put(kLastSeenChangelogVersionKey, version);
  }

  /// Resolves what to show for [currentVersion] and marks it seen in the same
  /// step, so the dialog can never appear twice for one update — even if the
  /// user quits before dismissing it.
  static Future<List<ChangelogRelease>> takePendingChangelog(
    String currentVersion,
  ) async {
    final lastSeen = await loadLastSeenVersion();
    final pending = changelogToShow(
      lastSeenVersion: lastSeen,
      currentVersion: currentVersion,
      changelog: await loadChangelog(),
    );
    if (lastSeen == null || compareVersions(currentVersion, lastSeen) > 0) {
      await saveLastSeenVersion(currentVersion);
    }
    return pending;
  }
}
