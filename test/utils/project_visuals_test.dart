import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/project_visuals.dart';

import '../helpers/test_factories.dart';

/// #110 — every project gets an accent colour and an icon with no user effort,
/// derived from its id. The derivation being *stable* is the whole feature: if
/// it moved between runs, machines or restores, the visual identity would be
/// worse than none at all.
void main() {
  group('stableProjectHash', () {
    test('is stable for the same input', () {
      expect(stableProjectHash('abc'), stableProjectHash('abc'));
    });

    test('differs for different inputs', () {
      expect(stableProjectHash('abc'), isNot(stableProjectHash('abd')));
    });

    test('is a fixed value, not a run-dependent one', () {
      // Pinning the FNV-1a output guards the reason this exists at all: swap
      // it for String.hashCode and this number changes, taking every user's
      // automatic colours with it.
      expect(stableProjectHash(''), 0x811c9dc5);
      expect(stableProjectHash('a'), 0x2b24d044);
    });

    test('handles non-ASCII ids without collapsing them', () {
      expect(stableProjectHash('café'), isNot(stableProjectHash('cafe')));
    });
  });

  group('deterministic assignment', () {
    test('the same id always yields the same colour and icon', () {
      const id = '7f1c0d5a-1111-4222-8333-444455556666';
      expect(deterministicAccentColor(id), deterministicAccentColor(id));
      expect(deterministicIconKey(id), deterministicIconKey(id));
    });

    test('the colour always comes from the curated palette', () {
      for (var i = 0; i < 200; i++) {
        expect(
          kProjectAccentPalette,
          contains(deterministicAccentColor('project-$i')),
        );
      }
    });

    test('the icon key always names a shipped icon', () {
      for (var i = 0; i < 200; i++) {
        expect(
          kProjectIconChoices.keys,
          contains(deterministicIconKey('project-$i')),
        );
      }
    });

    test('spreads a realistic library across most of the palette', () {
      // The point of the feature is that neighbouring rows look different, so
      // a derivation that funnelled everything into two colours would be a
      // silent failure. Not asserting a perfect distribution — just that it is
      // not degenerate.
      final colors = <Color>{};
      final icons = <String>{};
      for (var i = 0; i < 120; i++) {
        final id = 'song-$i-${i * 7}';
        colors.add(deterministicAccentColor(id));
        icons.add(deterministicIconKey(id));
      }
      expect(colors.length, greaterThanOrEqualTo(kProjectAccentPalette.length - 2));
      expect(icons.length, greaterThanOrEqualTo(kProjectIconChoices.length - 2));
    });

    test('colour and icon are seeded independently', () {
      // Two ids that land on the same colour should not be forced onto the
      // same icon as well.
      final pairs = <String, String>{};
      for (var i = 0; i < 300; i++) {
        final id = 'p$i';
        final key =
            '${deterministicAccentColor(id).toARGB32()}|${deterministicIconKey(id)}';
        pairs[key] = id;
      }
      expect(
        pairs.length,
        greaterThan(kProjectAccentPalette.length),
        reason: 'colour and icon must not move in lockstep',
      );
    });
  });

  group('resolveProjectAccentColor', () {
    test('falls back to the derived colour when nothing is stored', () {
      final project = TestFactories.makeProject(id: 'auto-1');
      expect(
        resolveProjectAccentColor(project),
        deterministicAccentColor('auto-1'),
      );
    });

    test('a stored override wins', () {
      final project = TestFactories.makeProject(
        id: 'auto-1',
        accentColor: 0xFF123456,
      );
      expect(resolveProjectAccentColor(project), const Color(0xFF123456));
    });
  });

  group('projectHasCoverArt', () {
    test('false when no cover is stored', () {
      expect(projectHasCoverArt(TestFactories.makeProject()), isFalse);
    });

    test('false for an empty path, not just null', () {
      expect(
        projectHasCoverArt(TestFactories.makeProject(thumbnailPath: '')),
        isFalse,
      );
    });

    test('true once a cover is stored — this is the "cover art wins" rule', () {
      expect(
        projectHasCoverArt(
          TestFactories.makeProject(
            thumbnailPath: '/covers/x.png',
            accentColor: 0xFF112233,
            iconKey: 'mic',
          ),
        ),
        isTrue,
        reason: 'an accent override must not suppress the cover',
      );
    });

    test('stays true for a path that no longer resolves', () {
      // Deliberate: the avatar decides on stored state and lets the decoder's
      // errorBuilder handle a stale path, rather than stat-ing every row.
      expect(
        projectHasCoverArt(
          TestFactories.makeProject(thumbnailPath: '/gone/missing.png'),
        ),
        isTrue,
      );
    });
  });

  group('resolveProjectIconKey', () {
    test('falls back to the derived key when nothing is stored', () {
      final project = TestFactories.makeProject(id: 'auto-2');
      expect(resolveProjectIconKey(project), deterministicIconKey('auto-2'));
    });

    test('a stored override wins', () {
      final project = TestFactories.makeProject(id: 'auto-2', iconKey: 'mic');
      expect(resolveProjectIconKey(project), 'mic');
      expect(resolveProjectIcon(project), kProjectIconChoices['mic']);
    });

    test('a key this build no longer ships falls back rather than blanking', () {
      // Retiring an icon must never leave a project without one.
      final project =
          TestFactories.makeProject(id: 'auto-2', iconKey: 'theremin');
      expect(resolveProjectIconKey(project), deterministicIconKey('auto-2'));
      expect(resolveProjectIcon(project), isNotNull);
    });
  });
}
