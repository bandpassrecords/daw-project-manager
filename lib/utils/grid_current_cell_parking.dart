import 'package:trina_grid/trina_grid.dart';

/// Hides TrinaGrid's "current cell" while the grid does not have focus, and
/// puts it back when focus returns.
///
/// TrinaGrid decorates the current cell differently depending on focus. With
/// focus it uses `activatedBorderColor` / `activatedColor`, which the
/// dashboard sets to transparent. Without focus it draws an
/// `inactivatedBorderColor` outline **and** fills the cell with
/// `gridBackgroundColor` — so clicking anywhere else (the preview player's
/// waveform, the search box) left the last-clicked cell boxed in, with a
/// patch of card colour punched through the row's highlight. Making the fill
/// transparent is not an option: the same colour backs the loading overlay
/// and the column-drag preview.
///
/// So while the grid is unfocused there is simply no current cell. Where it
/// was is remembered by row key (the project id) and column field rather
/// than by object, because the dashboard rebuilds its rows and a remembered
/// cell object would point at a row that no longer exists.
class GridCurrentCellParking {
  GridCurrentCellParking({required this.rowKey});

  /// Identifies a row across rebuilds — the project id on the dashboard.
  /// Rows it returns null for (group rows) are never parked.
  final String? Function(TrinaRow row) rowKey;

  String? _parkedKey;
  String? _parkedField;

  /// The key of the row whose cell is parked, or null.
  String? get parkedKey => _parkedKey;

  /// Whether [row] is the one whose cell is parked — so the page can keep
  /// highlighting it while the grid is unfocused.
  bool isParkedRow(TrinaRow row) =>
      _parkedKey != null && rowKey(row) == _parkedKey;

  /// Call when the grid loses focus: remembers the current cell and clears it.
  void park(TrinaGridStateManager sm) {
    final cell = sm.currentCell;
    if (cell == null) return;
    final key = rowKey(cell.row);
    if (key == null) return;
    _parkedKey = key;
    _parkedField = cell.column.field;
    sm.clearCurrentCell();
  }

  /// Call when the grid gets focus back (and before anything that falls back
  /// to "no current row → first row"): puts the parked cell back, if its row
  /// is still in the grid. Does nothing if something already set a current
  /// cell, e.g. the click that brought focus back landed on another row.
  void restore(TrinaGridStateManager sm) {
    final key = _parkedKey;
    final field = _parkedField;
    _parkedKey = null;
    _parkedField = null;
    if (key == null || sm.currentCell != null) return;

    final rows = sm.refRows;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (rowKey(row) != key) continue;
      final cell = row.cells[field] ??
          (row.cells.isEmpty ? null : row.cells.values.first);
      if (cell != null) sm.setCurrentCell(cell, i);
      return;
    }
  }

  /// Forgets the parked cell without restoring it.
  void clear() {
    _parkedKey = null;
    _parkedField = null;
  }
}
