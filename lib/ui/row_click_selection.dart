import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:trina_grid/trina_grid.dart';

import '../providers/providers.dart' show SelectionNotifier;

/// Ctrl/cmd- and shift-click multi-selection for the app's tables.
///
/// Every table with checkboxes (projects, project templates) already tracks
/// its checked rows in a [SelectionNotifier] and drives them from a checkbox
/// column. This file adds the mouse half of that — the modifier clicks a
/// desktop user expects to work anywhere on a row, not only on the 50px
/// checkbox — and holds it in one place so the tables can't drift apart on the
/// fiddly details: which modifier wins, where the shift anchor comes from, and
/// whether the highlighted row counts as selected.
///
/// An unmodified click keeps its existing meaning in every table: it moves the
/// row highlight (which the single-key shortcuts navigate from) and leaves the
/// checkbox selection alone.

/// True while a key that turns a plain click into a selection click is held:
/// shift for a range, ctrl or cmd for one row at a time.
///
/// Both the row-level click handler and the checkbox cell read this, so the
/// two never act on the same click — see [rowClickSelectionWrapper].
bool selectionModifierHeld() {
  final keyboard = HardwareKeyboard.instance;
  return keyboard.isShiftPressed ||
      keyboard.isControlPressed ||
      keyboard.isMetaPressed;
}

/// What a primary-button click on a table row does to the checkbox selection,
/// given which modifier keys were held.
enum RowClickSelection {
  /// No modifier: the checkbox selection is left exactly as it was.
  none,

  /// Shift: extend from the anchor to the clicked row — the same range
  /// selection a shift-click on the checkbox column performs.
  extendRange,

  /// Ctrl/cmd on a row that is already selected: drop just that row.
  removeTarget,

  /// Ctrl/cmd on a row that isn't selected yet: add it, together with the
  /// highlighted row.
  addTargetWithHighlight,
}

@visibleForTesting
RowClickSelection resolveRowClickSelection({
  required bool shiftPressed,
  required bool multiSelectPressed,
  required bool targetAlreadySelected,
}) {
  // Shift wins when both are held: ctrl+shift has no separate meaning here,
  // and a range is the less surprising of the two to end up with.
  if (shiftPressed) return RowClickSelection.extendRange;
  if (!multiSelectPressed) return RowClickSelection.none;
  return targetAlreadySelected
      ? RowClickSelection.removeTarget
      : RowClickSelection.addTargetWithHighlight;
}

/// The ids a ctrl/cmd-click adds to the selection: the clicked row, plus the
/// highlighted row when the highlight is still standing in for a row the user
/// hasn't explicitly selected yet ([highlightedId]) and that row is still on
/// screen ([visibleIds]).
///
/// Bringing the highlighted row along is what makes "click a row, then
/// ctrl-click a second one" select both: an unmodified click deliberately
/// doesn't touch the checkbox selection, so the first row would otherwise be
/// silently left out of the very selection the user is building.
@visibleForTesting
List<String> multiSelectClickAdditions({
  required String targetId,
  required String? highlightedId,
  required Set<String> visibleIds,
}) {
  return [
    if (highlightedId != null &&
        highlightedId != targetId &&
        visibleIds.contains(highlightedId))
      highlightedId,
    targetId,
  ];
}

/// One table's click-selection state: the shift-click anchor, the highlighted
/// row a ctrl/cmd-click brings along, and the rules that turn a click into a
/// change on that table's [SelectionNotifier].
///
/// Created once per table state. The notifier and the visible row order are
/// read through callbacks rather than passed by value, so the controller
/// always acts on the current provider instance and on the row order as
/// filtered and sorted right now.
class RowClickSelectionController {
  RowClickSelectionController({
    required SelectionNotifier Function() notifier,
    required Set<String> Function() selectedIds,
    required List<String> Function() orderedIds,
  }) : _notifier = notifier,
       _selectedIds = selectedIds,
       _orderedIds = orderedIds;

  final SelectionNotifier Function() _notifier;
  final Set<String> Function() _selectedIds;
  final List<String> Function() _orderedIds;

  /// The last row the user acted on without shift held — what a shift-click
  /// range-selects from. Deliberately transient interaction state, not part of
  /// the persisted selection.
  String? get anchorId => _anchorId;
  String? _anchorId;

  /// The highlighted row a ctrl/cmd-click should pull into the selection
  /// alongside the row being clicked.
  ///
  /// Set while the highlight is the only thing pointing at a row — the user
  /// clicked (or arrow-keyed onto) it without touching any checkbox — and
  /// cleared by every explicit selection change, so a ctrl-click can never
  /// bring back a row the user just unchecked.
  String? get highlightedCandidateId => _highlightedCandidateId;
  String? _highlightedCandidateId;

  /// A primary-button click anywhere on a row; the modifier keys decide
  /// whether it touches the selection at all.
  ///
  /// Called on pointer *down*, before the grid moves the highlight to the
  /// clicked row, so the anchor and the highlighted-row candidate still point
  /// at the row the user came from.
  void handleRowClick(String id) {
    final keyboard = HardwareKeyboard.instance;
    final effect = resolveRowClickSelection(
      shiftPressed: keyboard.isShiftPressed,
      // Cmd on macOS, Ctrl elsewhere — either works on either platform, so
      // muscle memory from another OS still does the right thing.
      multiSelectPressed: keyboard.isControlPressed || keyboard.isMetaPressed,
      targetAlreadySelected: _selectedIds().contains(id),
    );
    switch (effect) {
      case RowClickSelection.none:
        return;
      case RowClickSelection.extendRange:
        extendRange(id);
      case RowClickSelection.removeTarget:
        _notifier().removeAll([id]);
        _anchorId = id;
        _highlightedCandidateId = null;
      case RowClickSelection.addTargetWithHighlight:
        _notifier().addAll(
          multiSelectClickAdditions(
            targetId: id,
            highlightedId: _highlightedCandidateId,
            visibleIds: _orderedIds().toSet(),
          ),
        );
        _anchorId = id;
        _highlightedCandidateId = null;
    }
  }

  /// The row highlight moved with no selection modifier held — a plain click
  /// on a row, or an arrow-key move. The highlighted row is what the user
  /// reads as "the row I'm on", so it becomes both the shift-click anchor and
  /// the row a following ctrl/cmd-click brings along.
  void handleRowHighlight(String id) {
    _anchorId = id;
    _highlightedCandidateId = id;
  }

  /// An unmodified click on one row's checkbox.
  void toggle(String id) {
    _notifier().toggle(id);
    _anchorId = id;
    _highlightedCandidateId = null;
  }

  /// Extends the selection from [anchorId] to [targetId]. The anchor stays
  /// where it is, so a second shift-click re-ranges from the same row instead
  /// of chaining off the previous one.
  void extendRange(String targetId) {
    _highlightedCandidateId = null;
    final anchor = _anchorId;
    if (anchor == null) {
      toggle(targetId);
      return;
    }
    _notifier().selectRange(_orderedIds(), anchor, targetId);
  }

  /// Selects every row currently in view — the header checkbox.
  void selectAll() {
    _notifier().selectAll(_orderedIds());
    _highlightedCandidateId = null;
  }

  void clear() {
    _notifier().clear();
    _anchorId = null;
    _highlightedCandidateId = null;
  }

  /// Adds [ids] wholesale — a group/folder checkbox covering many rows.
  void addAll(List<String> ids) {
    _notifier().addAll(ids);
    _highlightedCandidateId = null;
  }

  /// Removes [ids] wholesale — the same group checkbox, clearing its rows.
  void removeAll(List<String> ids) {
    _notifier().removeAll(ids);
    _highlightedCandidateId = null;
  }
}

/// Wraps one grid row so a ctrl/cmd- or shift-click anywhere in it extends the
/// checkbox selection, for use as `TrinaGrid.rowWrapper`.
///
/// [rowId] returns the id of the row's item, or null for a row that can't be
/// selected (a smart-folder group header, say), which is then left unwrapped.
///
/// A [Listener] (rather than a GestureDetector) never enters the gesture
/// arena, so the grid's own handling of the same click — moving the row
/// highlight, double-tap to open a detail page, the checkbox itself — is left
/// alone. Pointer *down* is deliberate: it runs before that click moves the
/// highlight, while the anchor still points at the row the user came from.
///
/// Because this wraps the whole row, a cell with its own click handling must
/// bow out of modifier clicks (`if (selectionModifierHeld()) return;`) — the
/// checkbox column especially, where acting on the same click twice would
/// toggle the row twice and appear to do nothing at all.
///
/// Rows keep their fixed height through this wrapper, so the grid it belongs to
/// should also set `rowWrapperIsConstantHeight: true` — TrinaGrid otherwise
/// drops its ListView itemExtent fast path for every row in the table.
Widget rowClickSelectionWrapper({
  required TrinaRow row,
  required Widget rowWidget,
  required String? Function(TrinaRow row) rowId,
  required void Function(String id) onRowClick,
}) {
  final id = rowId(row);
  if (id == null) return rowWidget;
  return Listener(
    onPointerDown: (event) {
      // Right-click opens the context menu instead; it must never quietly
      // change the selection on the way there.
      if (event.buttons != kPrimaryButton) return;
      onRowClick(id);
    },
    child: rowWidget,
  );
}
