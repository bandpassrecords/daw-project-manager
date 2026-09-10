import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

/// The templates table's visibility mode, ported from the dashboard's
/// ShowHiddenProjectsNotifier — same 0/1/2 states and the same deliberate
/// session-only lifetime (a persisted "show only hidden" would empty the
/// table on next launch with no obvious cause).
void main() {
  group('ShowHiddenTemplatesNotifier', () {
    test('defaults to 0 (show only visible)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(showHiddenTemplatesProvider), 0);
    });

    test('setShowAll(true) sets state to 1', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(showHiddenTemplatesProvider.notifier).setShowAll(true);

      expect(c.read(showHiddenTemplatesProvider), 1);
    });

    test('setShowOnlyHidden(true) sets state to 2', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(showHiddenTemplatesProvider.notifier).setShowOnlyHidden(true);

      expect(c.read(showHiddenTemplatesProvider), 2);
    });

    test('setShowAll(false) returns to visible-only from show-all', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(showHiddenTemplatesProvider.notifier);

      notifier.setShowAll(true);
      notifier.setShowAll(false);

      expect(c.read(showHiddenTemplatesProvider), 0);
    });

    test('setShowOnlyHidden(false) returns to visible-only from hidden-only', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(showHiddenTemplatesProvider.notifier);

      notifier.setShowOnlyHidden(true);
      notifier.setShowOnlyHidden(false);

      expect(c.read(showHiddenTemplatesProvider), 0);
    });

    test('exposes the three states as readable flags', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(showHiddenTemplatesProvider.notifier);

      expect(notifier.isShowingVisible, isTrue);
      notifier.setShowAll(true);
      expect(notifier.isShowingAll, isTrue);
      notifier.setShowOnlyHidden(true);
      expect(notifier.isShowingOnlyHidden, isTrue);
    });
  });
}
