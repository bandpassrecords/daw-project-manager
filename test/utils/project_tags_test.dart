import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/project_tags.dart';

import '../helpers/test_factories.dart';

/// #109 — the rules every tag screen shares. The point of all of them is that
/// one idea never splits into two filters.
void main() {
  group('normalizeTag', () {
    test('trims and collapses inner whitespace', () {
      expect(normalizeTag('  for   the\tLuna  EP '), 'for the Luna EP');
    });

    test('is null for blank input', () {
      expect(normalizeTag(''), isNull);
      expect(normalizeTag('   \t '), isNull);
    });

    test('keeps emoji and case as typed', () {
      expect(normalizeTag('🔥🔥🔥'), '🔥🔥🔥');
      expect(normalizeTag('Trap'), 'Trap');
    });

    test('clips to the maximum length without splitting an emoji', () {
      final long = '🔥' * (kMaxTagLength + 5);
      final clipped = normalizeTag(long)!;

      expect(clipped.runes.length, kMaxTagLength);
      expect(clipped, '🔥' * kMaxTagLength);
    });
  });

  group('canonicalTag', () {
    test("reuses the library's spelling for a case-only difference", () {
      expect(canonicalTag('trap', ['Lo-fi', 'Trap']), 'Trap');
    });

    test('keeps a genuinely new tag as typed, normalized', () {
      expect(canonicalTag('  needs  vocals ', ['Trap']), 'needs vocals');
    });

    test('is null for blank input', () {
      expect(canonicalTag('  ', ['Trap']), isNull);
    });
  });

  group('addTag / removeTag', () {
    test('adds to the end', () {
      expect(addTag(['a'], 'b'), ['a', 'b']);
    });

    test('refuses a case-only duplicate and returns the same list', () {
      final tags = ['Trap'];

      expect(identical(addTag(tags, 'trap'), tags), isTrue);
    });

    test('refuses a blank tag and returns the same list', () {
      final tags = ['Trap'];

      expect(identical(addTag(tags, '   '), tags), isTrue);
    });

    test('removes ignoring case', () {
      expect(removeTag(['Trap', 'Lo-fi'], 'trap'), ['Lo-fi']);
    });

    test('returns the same list when the tag is not there', () {
      final tags = ['Trap'];

      expect(identical(removeTag(tags, 'house'), tags), isTrue);
    });
  });

  group('collectTags', () {
    test('is every distinct tag, sorted ignoring case, first spelling wins', () {
      final projects = [
        TestFactories.makeProject(id: 'a', tags: ['trap', 'Zeta']),
        TestFactories.makeProject(id: 'b', tags: ['TRAP', 'alpha']),
        TestFactories.makeProject(id: 'c'),
      ];

      expect(collectTags(projects), ['alpha', 'trap', 'Zeta']);
    });

    test('is empty for an untagged library', () {
      expect(collectTags([TestFactories.makeProject()]), isEmpty);
    });
  });

  group('projectHasTag', () {
    test('matches ignoring case', () {
      final p = TestFactories.makeProject(tags: ['Trap']);

      expect(projectHasTag(p, 'trap'), isTrue);
      expect(projectHasTag(p, 'house'), isFalse);
    });
  });

  group('effectiveTagFilter', () {
    test('is null when nothing is selected', () {
      expect(effectiveTagFilter(null, ['trap']), isNull);
    });

    test('resolves to the spelling in use', () {
      expect(effectiveTagFilter('trap', ['Trap']), 'Trap');
    });

    test('drops a filter on a tag no project has any more', () {
      // Otherwise the list goes empty while the dropdown, which only offers
      // tags in use, shows no filter at all.
      expect(effectiveTagFilter('gone', ['trap']), isNull);
    });
  });

  group('compareByTags', () {
    test('orders by the sorted tag lists, ignoring case', () {
      final a = TestFactories.makeProject(id: 'a', tags: ['zeta', 'Alpha']);
      final b = TestFactories.makeProject(id: 'b', tags: ['beta']);

      expect(compareByTags(a, b), lessThan(0));
      expect(compareByTags(b, a), greaterThan(0));
    });

    test('a shorter list that is a prefix sorts first', () {
      final a = TestFactories.makeProject(id: 'a', tags: ['alpha']);
      final b = TestFactories.makeProject(id: 'b', tags: ['alpha', 'beta']);

      expect(compareByTags(a, b), lessThan(0));
    });

    test('is null when either side is untagged', () {
      final tagged = TestFactories.makeProject(id: 'a', tags: ['x']);
      final untagged = TestFactories.makeProject(id: 'b');

      expect(compareByTags(tagged, untagged), isNull);
      expect(compareByTags(untagged, tagged), isNull);
    });
  });

  group('planBulkTagChange', () {
    final projects = [
      TestFactories.makeProject(id: 'has', tags: ['Trap']),
      TestFactories.makeProject(id: 'lacks', tags: ['house']),
      TestFactories.makeProject(id: 'none'),
    ];

    test('adding skips projects that already have the tag', () {
      final plan = planBulkTagChange(projects, 'Trap', add: true);

      expect(plan.map((c) => c.$1.id), ['lacks', 'none']);
      expect(plan.first.$2, ['house', 'Trap']);
      expect(plan.last.$2, ['Trap']);
    });

    test('removing touches only projects that have it, ignoring case', () {
      final plan = planBulkTagChange(projects, 'trap', add: false);

      expect(plan.map((c) => c.$1.id), ['has']);
      expect(plan.single.$2, isEmpty);
    });

    test('plans nothing when nothing would change', () {
      expect(planBulkTagChange(projects, 'jazz', add: false), isEmpty);
    });
  });
}
