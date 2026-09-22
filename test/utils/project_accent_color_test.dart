import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/project_accent_color.dart';

/// #111/#110 — a project with no cover art still has to be recognisable, and
/// the colour it gets has to be the same one tomorrow, on the other machine,
/// and after a Drive restore. Nothing is stored, so these properties are the
/// only thing holding that promise up.
void main() {
  group('stableStringHash', () {
    test('is deterministic for the same input', () {
      expect(stableStringHash('abc'), stableStringHash('abc'));
    });

    test('pins known values so the hash cannot be swapped out silently', () {
      // FNV-1a over UTF-16 code units. If these change, every existing
      // project's colour changes with them.
      expect(stableStringHash(''), 0x811c9dc5);
      expect(stableStringHash('a'), 0x2b24d044);
    });

    test('separates ids that differ by one character', () {
      expect(
        stableStringHash('project-1'),
        isNot(stableStringHash('project-2')),
      );
    });

    test('stays inside 32 bits', () {
      for (final s in ['', 'a', 'a-longer-project-id', '日本語のプロジェクト']) {
        expect(stableStringHash(s), inInclusiveRange(0, 0xffffffff));
      }
    });
  });

  group('projectAccentColor', () {
    test('is stable across calls', () {
      expect(derivedAccentColor('uuid-1'), derivedAccentColor('uuid-1'));
    });

    test('gives different ids different colours', () {
      final colors = {
        for (final id in ['a', 'b', 'c', 'd', 'e', 'f']) derivedAccentColor(id),
      };
      expect(colors.length, greaterThan(1));
    });

    test('every colour is opaque and dark enough for white text', () {
      for (var i = 0; i < 200; i++) {
        final color = derivedAccentColor('project-$i');
        expect(color.a, 1.0);
        final hsl = HSLColor.fromColor(color);
        expect(hsl.lightness, closeTo(0.42, 0.01));
        expect(hsl.saturation, closeTo(0.45, 0.01));
      }
    });
  });

  group('projectCardInitials', () {
    test('uses the label the user typed', () {
      expect(projectCardInitials('X7', 'Night Drive'), 'X7');
    });

    test('derives from the name when nothing was typed', () {
      expect(projectCardInitials(null, 'Night Drive'), 'ND');
      expect(projectCardInitials('', 'Night Drive'), 'ND');
    });

    test('treats a whitespace-only label as nothing typed', () {
      // Clearing the field in the editor is how a user goes back to the
      // derived label; a card must never come out blank.
      expect(projectCardInitials('   ', 'Night Drive'), 'ND');
    });

    test('trims what the user typed', () {
      expect(projectCardInitials(' X7 ', 'Night Drive'), 'X7');
    });
  });

  group('projectInitials', () {
    test('takes one letter from each of the first two words', () {
      expect(projectInitials('Night Drive'), 'ND');
      expect(projectInitials('Night Drive Reprise'), 'ND');
    });

    test('takes two letters from a single word', () {
      expect(projectInitials('bassline'), 'BA');
    });

    test('splits on the separators file names actually use', () {
      expect(projectInitials('night_drive'), 'ND');
      expect(projectInitials('night-drive'), 'ND');
      expect(projectInitials('night.drive'), 'ND');
    });

    test('handles a one-character name', () {
      expect(projectInitials('x'), 'X');
    });

    test('never returns an empty label', () {
      expect(projectInitials(''), '?');
      expect(projectInitials('   '), '?');
    });
  });
}
