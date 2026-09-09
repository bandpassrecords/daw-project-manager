import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/row_click_selection.dart';

/// A controller wired to a real [SelectionNotifier], the same way a table's
/// state class wires one up.
///
/// Uses `selectedProjectsProvider`, but nothing here is projects-specific:
/// every table's selection is the same [SelectionNotifier], which is the point
/// of sharing this controller between the projects and templates grids (there
/// is a templates-provider test at the end to prove it).
class _Harness {
  _Harness({List<String> orderedIds = const ['a', 'b', 'c', 'd', 'e']})
    : _orderedIds = orderedIds {
    controller = RowClickSelectionController(
      notifier: () => container.read(selectedProjectsProvider.notifier),
      selectedIds: () => container.read(selectedProjectsProvider),
      orderedIds: () => _orderedIds,
    );
  }

  List<String> _orderedIds;
  final container = ProviderContainer();
  late final RowClickSelectionController controller;

  Set<String> get selected => container.read(selectedProjectsProvider);

  /// Narrows the visible rows, as a search or filter would.
  void filterTo(List<String> ids) => _orderedIds = ids;

  void dispose() => container.dispose();
}

/// Runs [action] while [key] is held down, so the controller sees the same
/// `HardwareKeyboard` state a real modifier click would produce.
Future<void> _holding(LogicalKeyboardKey key, void Function() action) async {
  await simulateKeyDownEvent(key);
  try {
    action();
  } finally {
    await simulateKeyUpEvent(key);
  }
}

void main() {
  group('resolveRowClickSelection', () {
    // Ctrl/cmd- and shift-clicking a row anywhere (not just on its checkbox)
    // builds a multi-selection. These are the rules every table follows; the
    // two modifiers have to keep matching what the checkbox column already
    // does, or the same click would mean two different things depending on
    // where in the row it landed.

    test('an unmodified click leaves the selection alone', () {
      // A plain click only moves the row highlight — it deliberately does not
      // check or uncheck anything, so a selection survives clicking around.
      expect(
        resolveRowClickSelection(
          shiftPressed: false,
          multiSelectPressed: false,
          targetAlreadySelected: false,
        ),
        RowClickSelection.none,
      );
      expect(
        resolveRowClickSelection(
          shiftPressed: false,
          multiSelectPressed: false,
          targetAlreadySelected: true,
        ),
        RowClickSelection.none,
      );
    });

    test('ctrl/cmd on an unselected row adds it, with the highlighted row', () {
      expect(
        resolveRowClickSelection(
          shiftPressed: false,
          multiSelectPressed: true,
          targetAlreadySelected: false,
        ),
        RowClickSelection.addTargetWithHighlight,
      );
    });

    test('ctrl/cmd on an already selected row removes just that row', () {
      expect(
        resolveRowClickSelection(
          shiftPressed: false,
          multiSelectPressed: true,
          targetAlreadySelected: true,
        ),
        RowClickSelection.removeTarget,
      );
    });

    test('shift extends the range whether or not the row is selected', () {
      for (final alreadySelected in [false, true]) {
        expect(
          resolveRowClickSelection(
            shiftPressed: true,
            multiSelectPressed: false,
            targetAlreadySelected: alreadySelected,
          ),
          RowClickSelection.extendRange,
        );
      }
    });

    test('shift wins over ctrl/cmd when both are held', () {
      expect(
        resolveRowClickSelection(
          shiftPressed: true,
          multiSelectPressed: true,
          targetAlreadySelected: false,
        ),
        RowClickSelection.extendRange,
      );
    });
  });

  group('multiSelectClickAdditions', () {
    test('brings the highlighted row along with the clicked one', () {
      // The whole point of the feature: click one row, ctrl-click a second,
      // end up with both — even though the first click never touched a
      // checkbox.
      expect(
        multiSelectClickAdditions(
          targetId: 'b',
          highlightedId: 'a',
          visibleIds: {'a', 'b', 'c'},
        ),
        ['a', 'b'],
      );
    });

    test('adds only the clicked row when nothing is highlighted', () {
      expect(
        multiSelectClickAdditions(
          targetId: 'b',
          highlightedId: null,
          visibleIds: {'a', 'b', 'c'},
        ),
        ['b'],
      );
    });

    test(
      'does not list the clicked row twice when it is the highlighted one',
      () {
        expect(
          multiSelectClickAdditions(
            targetId: 'a',
            highlightedId: 'a',
            visibleIds: {'a', 'b'},
          ),
          ['a'],
        );
      },
    );

    test('skips a highlighted row that is no longer on screen', () {
      // The highlight can outlive the row: a search or filter can narrow the
      // table after the user clicked. Selecting a row they can no longer see
      // would quietly hand it to the next bulk action.
      expect(
        multiSelectClickAdditions(
          targetId: 'b',
          highlightedId: 'filtered-out',
          visibleIds: {'a', 'b', 'c'},
        ),
        ['b'],
      );
    });
  });

  group('selectionModifierHeld', () {
    // The checkbox cell bows out of modifier-held clicks because the row
    // around it already handles them — if this ever stopped reporting a held
    // modifier, a ctrl-click on the checkbox would toggle the same row twice
    // and appear to do nothing at all.

    testWidgets('is false with no modifier held', (tester) async {
      expect(selectionModifierHeld(), isFalse);
    });

    for (final key in [
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.metaLeft,
    ]) {
      testWidgets('is true while ${key.keyLabel} is held', (tester) async {
        await simulateKeyDownEvent(key);
        addTearDown(() => simulateKeyUpEvent(key));

        expect(selectionModifierHeld(), isTrue);
      });
    }
  });

  group('RowClickSelectionController', () {
    testWidgets('an unmodified row click selects nothing', (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.handleRowClick('a');

      expect(h.selected, isEmpty);
    });

    testWidgets('ctrl-clicking a second row selects the highlighted one too', (
      tester,
    ) async {
      // The behavior this whole file exists for: click a row (which only
      // highlights it), then ctrl-click another, and both end up checked.
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.handleRowHighlight('a');
      await _holding(
        LogicalKeyboardKey.controlLeft,
        () => h.controller.handleRowClick('c'),
      );

      expect(h.selected, {'a', 'c'});
    });

    testWidgets('cmd-clicking works the same as ctrl-clicking', (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.handleRowHighlight('a');
      await _holding(
        LogicalKeyboardKey.metaLeft,
        () => h.controller.handleRowClick('c'),
      );

      expect(h.selected, {'a', 'c'});
    });

    testWidgets('further ctrl-clicks keep adding one row at a time', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.handleRowHighlight('a');
      await _holding(LogicalKeyboardKey.controlLeft, () {
        h.controller.handleRowClick('c');
        h.controller.handleRowClick('e');
      });

      expect(h.selected, {'a', 'c', 'e'});
    });

    testWidgets('ctrl-clicking a selected row unchecks just that row', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.toggle('a');
      h.controller.toggle('b');
      await _holding(
        LogicalKeyboardKey.controlLeft,
        () => h.controller.handleRowClick('a'),
      );

      expect(h.selected, {'b'});
    });

    testWidgets('a ctrl-click never brings back the row it just unchecked', (
      tester,
    ) async {
      // Regression: the "bring the highlighted row along" rule must not undo
      // the user's own uncheck. Unchecking a row leaves it highlighted, so a
      // naive implementation re-selects it on the very next ctrl-click.
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.toggle('a');
      await _holding(LogicalKeyboardKey.controlLeft, () {
        h.controller.handleRowClick('a'); // unchecks a
        h.controller.handleRowClick('c');
      });

      expect(h.selected, {'c'});
    });

    testWidgets('checking a checkbox first does not pull the highlight in', (
      tester,
    ) async {
      // An explicit checkbox click means the user is building the selection
      // deliberately, so only what they click gets added.
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.handleRowHighlight('a');
      h.controller.toggle('b');
      await _holding(
        LogicalKeyboardKey.controlLeft,
        () => h.controller.handleRowClick('d'),
      );

      expect(h.selected, {'b', 'd'});
    });

    testWidgets('a highlighted row filtered off screen is not selected', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.handleRowHighlight('a');
      h.filterTo(['c', 'd', 'e']);
      await _holding(
        LogicalKeyboardKey.controlLeft,
        () => h.controller.handleRowClick('d'),
      );

      expect(h.selected, {'d'});
    });

    testWidgets('shift-clicking extends from the highlighted row', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.handleRowHighlight('b');
      await _holding(
        LogicalKeyboardKey.shiftLeft,
        () => h.controller.handleRowClick('d'),
      );

      expect(h.selected, {'b', 'c', 'd'});
    });

    testWidgets('shift-clicking extends backwards just the same', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.handleRowHighlight('d');
      await _holding(
        LogicalKeyboardKey.shiftLeft,
        () => h.controller.handleRowClick('b'),
      );

      expect(h.selected, {'b', 'c', 'd'});
    });

    testWidgets('a second shift-click re-ranges from the same anchor', (
      tester,
    ) async {
      // Standard file-manager behavior: shift-clicking does not move the
      // anchor, so shrinking a range by shift-clicking closer to the anchor
      // never chains off the previous target.
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.handleRowHighlight('a');
      await _holding(LogicalKeyboardKey.shiftLeft, () {
        h.controller.handleRowClick('e');
        h.controller.handleRowClick('b');
      });

      expect(h.controller.anchorId, 'a');
      expect(h.selected, {'a', 'b', 'c', 'd', 'e'});
    });

    testWidgets('a shift-click with nothing highlighted just checks the row', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.dispose);

      await _holding(
        LogicalKeyboardKey.shiftLeft,
        () => h.controller.handleRowClick('c'),
      );

      expect(h.selected, {'c'});
    });

    testWidgets('shift-clicking extends from the last checkbox click', (
      tester,
    ) async {
      // Clicking a checkbox is an anchor too — the shift range starts from
      // whichever row the user last acted on, checkbox or not.
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.toggle('b');
      await _holding(
        LogicalKeyboardKey.shiftLeft,
        () => h.controller.handleRowClick('d'),
      );

      expect(h.selected, {'b', 'c', 'd'});
    });

    testWidgets('an arrow-key move re-anchors the range', (tester) async {
      // handleRowHighlight covers keyboard navigation as well as clicks, so
      // arrowing to a row and shift-clicking elsewhere ranges from the row
      // the user can see highlighted.
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.toggle('a');
      h.controller.handleRowHighlight('b');
      h.controller.handleRowHighlight('c');
      await _holding(
        LogicalKeyboardKey.shiftLeft,
        () => h.controller.handleRowClick('e'),
      );

      expect(h.selected, {'a', 'c', 'd', 'e'});
    });

    testWidgets('select-all takes the rows currently in view', (tester) async {
      final h = _Harness();
      addTearDown(h.dispose);
      h.filterTo(['b', 'c']);

      h.controller.selectAll();

      expect(h.selected, {'b', 'c'});
    });

    testWidgets('clear drops the selection and the anchor with it', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.toggle('b');
      h.controller.clear();

      expect(h.selected, isEmpty);
      expect(h.controller.anchorId, isNull);
    });

    testWidgets('a group checkbox adds and removes its rows wholesale', (
      tester,
    ) async {
      final h = _Harness();
      addTearDown(h.dispose);

      h.controller.addAll(['a', 'b']);
      expect(h.selected, {'a', 'b'});

      h.controller.removeAll(['a']);
      expect(h.selected, {'b'});
    });

    testWidgets(
      'a group checkbox click also stops the highlight tagging along',
      (tester) async {
        final h = _Harness();
        addTearDown(h.dispose);

        h.controller.handleRowHighlight('a');
        h.controller.addAll(['b', 'c']);
        await _holding(
          LogicalKeyboardKey.controlLeft,
          () => h.controller.handleRowClick('e'),
        );

        expect(h.selected, {'b', 'c', 'e'});
      },
    );

    testWidgets('drives a templates selection exactly the same way', (
      tester,
    ) async {
      // Same controller, different table: the projects grid and the
      // project-templates grid share both the notifier behavior and these
      // click rules.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = RowClickSelectionController(
        notifier: () => container.read(selectedTemplatesProvider.notifier),
        selectedIds: () => container.read(selectedTemplatesProvider),
        orderedIds: () => ['t1', 't2', 't3'],
      );

      controller.handleRowHighlight('t1');
      await _holding(
        LogicalKeyboardKey.shiftLeft,
        () => controller.handleRowClick('t3'),
      );

      expect(container.read(selectedTemplatesProvider), {'t1', 't2', 't3'});
    });

    testWidgets('drives a releases selection exactly the same way', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = RowClickSelectionController(
        notifier: () => container.read(selectedReleasesProvider.notifier),
        selectedIds: () => container.read(selectedReleasesProvider),
        orderedIds: () => ['r1', 'r2', 'r3'],
      );

      controller.handleRowHighlight('r1');
      await _holding(
        LogicalKeyboardKey.controlLeft,
        () => controller.handleRowClick('r3'),
      );

      expect(container.read(selectedReleasesProvider), {'r1', 'r3'});
    });
  });
}
