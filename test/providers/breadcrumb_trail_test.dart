import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

void main() {
  group('breadcrumbPopCount', () {
    test('the last crumb is where the user already is, so nothing pops', () {
      expect(breadcrumbPopCount(index: 2, length: 3), 0);
    });

    test('the first crumb pops everything above it', () {
      expect(breadcrumbPopCount(index: 0, length: 3), 2);
    });

    test('a middle crumb pops only what is above it', () {
      expect(breadcrumbPopCount(index: 1, length: 4), 2);
    });

    test('a single-entry trail never pops', () {
      expect(breadcrumbPopCount(index: 0, length: 1), 0);
    });

    test('an out-of-range index is a no-op rather than a negative pop', () {
      expect(breadcrumbPopCount(index: -1, length: 3), 0);
      expect(breadcrumbPopCount(index: 5, length: 3), 0);
      expect(breadcrumbPopCount(index: 0, length: 0), 0);
    });
  });

  group('BreadcrumbTrailNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    List<Breadcrumb> trail() => container.read(breadcrumbTrailProvider);
    BreadcrumbTrailNotifier notifier() =>
        container.read(breadcrumbTrailProvider.notifier);
    List<String> labels() => trail().map((c) => c.label).toList();

    void push(String id, String label) =>
        notifier().push(Breadcrumb(id: id, label: label));

    test('starts empty', () {
      expect(trail(), isEmpty);
    });

    test('builds a trail in push order', () {
      push('a', 'Home');
      push('b', 'Summer EP');
      push('c', 'Parts');

      expect(labels(), ['Home', 'Summer EP', 'Parts']);
    });

    test('re-pushing the same id renames in place rather than duplicating', () {
      // A page can rename itself while open — a release being retitled.
      push('a', 'Home');
      push('b', 'Untitled');
      push('b', 'Summer EP');

      expect(labels(), ['Home', 'Summer EP']);
    });

    test('re-pushing an identical crumb changes nothing', () {
      push('a', 'Home');
      final before = trail();
      push('a', 'Home');

      expect(identical(trail(), before), isTrue,
          reason: 'no needless rebuild for an unchanged crumb');
    });

    test('removing the last crumb walks back one page', () {
      push('a', 'Home');
      push('b', 'Summer EP');
      notifier().remove('b');

      expect(labels(), ['Home']);
    });

    test('removing a crumb drops everything after it', () {
      // Title bars are disposed as routes pop; a page gone from the middle
      // means every page beyond it is gone too, and leaving orphans would
      // point at pages that no longer exist.
      push('a', 'Home');
      push('b', 'Summer EP');
      push('c', 'Parts');
      notifier().remove('b');

      expect(labels(), ['Home']);
    });

    test('removing an unknown id is harmless', () {
      push('a', 'Home');
      notifier().remove('nope');

      expect(labels(), ['Home']);
    });

    test('ids disambiguate pages that share a title', () {
      push('a', 'Parts');
      push('b', 'Parts');
      notifier().remove('b');

      expect(trail(), hasLength(1));
      expect(trail().single.id, 'a');
    });

    test('clear empties the trail', () {
      push('a', 'Home');
      push('b', 'Summer EP');
      notifier().clear();

      expect(trail(), isEmpty);
    });

    test('a full push/pop cycle returns to where it started', () {
      push('a', 'Home');
      push('b', 'Summer EP');
      push('c', 'Parts');
      notifier().remove('c');
      notifier().remove('b');

      expect(labels(), ['Home']);
    });
  });

  group('Breadcrumb', () {
    test('compares by id and label', () {
      const a = Breadcrumb(id: '1', label: 'Home');
      expect(a, const Breadcrumb(id: '1', label: 'Home'));
      expect(a, isNot(const Breadcrumb(id: '1', label: 'Other')));
      expect(a, isNot(const Breadcrumb(id: '2', label: 'Home')));
    });

    test('equal crumbs hash alike', () {
      expect(
        const Breadcrumb(id: '1', label: 'Home').hashCode,
        const Breadcrumb(id: '1', label: 'Home').hashCode,
      );
    });
  });
}
