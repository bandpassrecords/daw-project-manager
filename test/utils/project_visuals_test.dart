import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/project_accent_color.dart';
import 'package:daw_project_manager/utils/project_visuals.dart';

import '../helpers/test_factories.dart';

/// #110 — cover art, accent colour and icon are all opt-in. A project nobody
/// has decorated must resolve to *nothing*: no stand-in colour, no fallback
/// icon, no placeholder. Anything that quietly invents one puts generic
/// decoration on every row in the library, which is exactly what this feature
/// is not supposed to do.
void main() {
  group('projectAccentColor', () {
    test('null when the user has chosen no colour', () {
      expect(projectAccentColor(TestFactories.makeProject()), isNull);
    });

    test('is the stored colour once one is chosen', () {
      final project = TestFactories.makeProject(accentColor: 0xFF123456);
      expect(projectAccentColor(project), const Color(0xFF123456));
    });

    test('round-trips a palette entry through the stored int', () {
      for (final color in kProjectAccentPalette) {
        final project =
            TestFactories.makeProject(accentColor: color.toARGB32());
        expect(projectAccentColor(project), color);
      }
    });
  });

  group('projectIcon', () {
    test('null when the user has chosen no icon', () {
      expect(projectIcon(TestFactories.makeProject()), isNull);
    });

    test('is the stored icon once one is chosen', () {
      final project = TestFactories.makeProject(iconKey: 'mic');
      expect(projectIcon(project), kProjectIconChoices['mic']);
    });

    test('every offered key resolves', () {
      for (final key in kProjectIconChoices.keys) {
        expect(projectIcon(TestFactories.makeProject(iconKey: key)), isNotNull);
      }
    });

    test('a key this build no longer ships reads as no icon, not a crash', () {
      // Retiring an icon must degrade to "undecorated", never throw on a
      // project someone set it on two releases ago.
      final project = TestFactories.makeProject(iconKey: 'theremin');
      expect(projectIcon(project), isNull);
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
        reason: 'a chosen colour must not suppress the cover',
      );
    });

    test('stays true for a path that no longer resolves', () {
      // Deliberate: the widgets decide on stored state and let the decoder's
      // errorBuilder handle a stale path, rather than stat-ing every row.
      expect(
        projectHasCoverArt(
          TestFactories.makeProject(thumbnailPath: '/gone/missing.png'),
        ),
        isTrue,
      );
    });
  });

  group('projectHasVisualIdentity', () {
    test('false for an untouched project — the case that keeps rows quiet', () {
      expect(
        projectHasVisualIdentity(TestFactories.makeProject()),
        isFalse,
        reason: 'nothing is assigned by default',
      );
    });

    test('true on a cover alone', () {
      expect(
        projectHasVisualIdentity(
          TestFactories.makeProject(thumbnailPath: '/covers/x.png'),
        ),
        isTrue,
      );
    });

    test('true on a colour alone', () {
      expect(
        projectHasVisualIdentity(
          TestFactories.makeProject(accentColor: 0xFF112233),
        ),
        isTrue,
      );
    });

    test('true on an icon alone', () {
      expect(
        projectHasVisualIdentity(TestFactories.makeProject(iconKey: 'mic')),
        isTrue,
      );
    });

    test('false again once a retired icon is all that is left', () {
      expect(
        projectHasVisualIdentity(
          TestFactories.makeProject(iconKey: 'theremin'),
        ),
        isFalse,
      );
    });
  });

  // #110 (cover art) and #111 (card view) each landed a `projectAccentColor`
  // on its own branch, with opposite meanings: nullable-and-user-set, versus
  // always-derived-from-the-id. Both are right for their own surface, so the
  // derived one is now `derivedAccentColor` and this layers them.
  group('resolvedAccentColor', () {
    test('prefers the colour the user chose', () {
      final project = TestFactories.makeProject(accentColor: 0xFF123456);

      expect(resolvedAccentColor(project), const Color(0xFF123456));
    });

    test('falls back to the derived colour when none was chosen', () {
      final project = TestFactories.makeProject(id: 'uuid-1');

      expect(resolvedAccentColor(project), derivedAccentColor('uuid-1'));
    });

    test('never returns null, unlike the override accessor', () {
      // A card is mostly artwork; it has to be filled with something. That is
      // the whole reason this exists next to the nullable one.
      final undecorated = TestFactories.makeProject();

      expect(projectAccentColor(undecorated), isNull);
      expect(resolvedAccentColor(undecorated), isA<Color>());
    });

    test('two undecorated projects still differ from each other', () {
      expect(
        resolvedAccentColor(TestFactories.makeProject(id: 'a')),
        isNot(resolvedAccentColor(TestFactories.makeProject(id: 'b'))),
      );
    });
  });
}
