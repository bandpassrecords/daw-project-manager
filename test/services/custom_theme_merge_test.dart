import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/custom_theme.dart';
import 'package:daw_project_manager/services/custom_theme_merge.dart';

/// The merge rules both Google Drive sync and local backup restore run on
/// (#148). Getting these wrong loses hand-tuned themes, which is exactly the
/// failure the feature is meant to protect against.
void main() {
  CustomTheme theme(String id, {String? name, DateTime? updatedAt}) =>
      CustomTheme(
        id: id,
        name: name ?? 'Theme $id',
        brightness: Brightness.dark,
        primary: const Color(0xFF00D4FF),
        background: const Color(0xFF0A0A14),
        card: const Color(0xFF1A1A2E),
        updatedAt: updatedAt,
      );

  group('customThemesFromJson', () {
    test('null gives an empty list', () {
      expect(customThemesFromJson(null), isEmpty);
    });

    test('non-map entries are skipped', () {
      expect(
        customThemesFromJson(['nope', 42, theme('a').toJson()]).map((t) => t.id),
        ['a'],
      );
    });

    test('an entry missing its id is skipped, not fatal', () {
      expect(
        customThemesFromJson([
          {'name': 'no id here'},
          theme('a').toJson(),
        ]).map((t) => t.id),
        ['a'],
      );
    });
  });

  group('mergeCustomThemes', () {
    test('a local-only theme survives a merge that has never seen it', () {
      final merged = mergeCustomThemes([theme('local')], [theme('remote')]);
      expect(merged.map((t) => t.id), containsAll(['local', 'remote']));
    });

    test('a remote-only theme is added', () {
      final merged = mergeCustomThemes(const [], [theme('remote')]);
      expect(merged.single.id, 'remote');
    });

    test('absence is never a deletion', () {
      // Restoring an old backup must not remove a theme made since it.
      final merged = mergeCustomThemes([theme('made-later')], const []);
      expect(merged.single.id, 'made-later');
    });

    test('a same-id collision resolves to the newer updatedAt', () {
      final merged = mergeCustomThemes(
        [theme('a', name: 'Local', updatedAt: DateTime(2026, 1, 1))],
        [theme('a', name: 'Remote', updatedAt: DateTime(2026, 6, 1))],
      );
      expect(merged.single.name, 'Remote');
    });

    test('an older incoming copy cannot roll back a newer local edit', () {
      final merged = mergeCustomThemes(
        [theme('a', name: 'Edited here', updatedAt: DateTime(2026, 6, 1))],
        [theme('a', name: 'Stale backup', updatedAt: DateTime(2026, 1, 1))],
      );
      expect(merged.single.name, 'Edited here');
    });

    test('an untimestamped incoming theme never displaces a timestamped one',
        () {
      final merged = mergeCustomThemes(
        [theme('a', name: 'Has a date', updatedAt: DateTime(2026, 1, 1))],
        [theme('a', name: 'No date')],
      );
      expect(merged.single.name, 'Has a date');
    });

    test('an incoming theme does replace one with no timestamp at all', () {
      final merged = mergeCustomThemes(
        [theme('a', name: 'No date')],
        [theme('a', name: 'Has a date', updatedAt: DateTime(2026, 1, 1))],
      );
      expect(merged.single.name, 'Has a date');
    });

    test('local themes keep their order, new ones are appended', () {
      final merged = mergeCustomThemes(
        [theme('a'), theme('b')],
        [theme('c')],
      );
      expect(merged.map((t) => t.id), ['a', 'b', 'c']);
    });
  });
}
