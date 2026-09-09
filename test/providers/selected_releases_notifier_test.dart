import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

/// The Releases table's selection runs on the same shared [SelectionNotifier]
/// as the projects and templates tables, so the set semantics themselves are
/// covered once in `selected_projects_notifier_test.dart`. What matters here is
/// that this provider really is that shared notifier — a separate hand-rolled
/// copy is exactly what the shared base exists to prevent — and that the
/// operations the releases table drives (its checkbox column, header
/// select-all, shift ranges and bulk delete) behave the same through it.
void main() {
  group('SelectedReleasesNotifier', () {
    test(
      'is the shared selection notifier, not a private reimplementation',
      () {
        final c = ProviderContainer();
        addTearDown(c.dispose);

        expect(
          c.read(selectedReleasesProvider.notifier),
          isA<SelectionNotifier>(),
        );
      },
    );

    test('defaults to an empty set', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(selectedReleasesProvider), isEmpty);
    });

    test('toggle adds an unselected id and removes a selected one', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedReleasesProvider.notifier);

      notifier.toggle('r1');
      expect(c.read(selectedReleasesProvider), {'r1'});

      notifier.toggle('r1');
      expect(c.read(selectedReleasesProvider), isEmpty);
    });

    test('selectAll replaces the selection with the rows in view', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedReleasesProvider.notifier);

      notifier.toggle('filtered-out');
      notifier.selectAll(['r1', 'r2']);

      expect(c.read(selectedReleasesProvider), {'r1', 'r2'});
    });

    test('selectRange covers the rows between anchor and target', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedReleasesProvider.notifier);

      notifier.selectRange(['r1', 'r2', 'r3', 'r4'], 'r2', 'r4');

      expect(c.read(selectedReleasesProvider), {'r2', 'r3', 'r4'});
    });

    test('removeAll drops a deleted release without touching the rest', () {
      // The row-level delete action prunes just the release it deleted, so the
      // bulk bar stops counting a row that is no longer there.
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedReleasesProvider.notifier);

      notifier.addAll(['r1', 'r2']);
      notifier.removeAll(['r1']);

      expect(c.read(selectedReleasesProvider), {'r2'});
    });

    test('clear empties the selection after a bulk delete', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedReleasesProvider.notifier);

      notifier.addAll(['r1', 'r2']);
      notifier.clear();

      expect(c.read(selectedReleasesProvider), isEmpty);
    });
  });
}
