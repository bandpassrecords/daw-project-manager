import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:trina_grid/trina_grid.dart';

/// Column widths as the user left them, by column field — read from JSON
/// written by [encodeColumnWidths]. Anything unreadable reads as nothing
/// saved, never as a broken table.
Map<String, double> decodeColumnWidths(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return {
      for (final e in decoded.entries)
        if (e.key is String && e.value is num && (e.value as num) > 0)
          e.key as String: (e.value as num).toDouble(),
    };
  } catch (_) {
    return const {};
  }
}

String encodeColumnWidths(Map<String, double> widths) => jsonEncode({
      for (final e in widths.entries)
        // Whole pixels are plenty, and keep the stored text short.
        e.key: double.parse(e.value.toStringAsFixed(1)),
    });

/// Gives each of [columns] its saved width, when there is one. Never below
/// a column's own minimum. Returns [columns] for chaining.
///
/// With the grids' scale auto-size mode the widths are proportions: the
/// grid stretches them to its width, so a layout saved in a wide window
/// keeps its shape in a narrow one.
List<TrinaColumn> applyColumnWidths(
  List<TrinaColumn> columns,
  Map<String, double> saved,
) {
  for (final column in columns) {
    final width = saved[column.field];
    if (width == null) continue;
    column.width = width < column.minWidth ? column.minWidth : width;
  }
  return columns;
}

/// The widths of [columns] by field.
Map<String, double> columnWidthsOf(Iterable<TrinaColumn> columns) => {
      for (final c in columns) c.field: c.width,
    };

/// Where [ColumnWidthMemory] keeps widths, by storage key. [HiveColumnWidths]
/// in the app; tests hand in a map.
abstract class ColumnWidthStorage {
  String? read(String key);
  void write(String key, String value);
  void delete(String key);
}

/// The app's `settings` box — device-local, beside the table column
/// layout. Reads nothing (and writes nowhere) until the box is open, which
/// `main` does before the first table is built.
class HiveColumnWidths implements ColumnWidthStorage {
  const HiveColumnWidths();

  static const boxName = 'settings';

  Box<String>? get _box =>
      Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null;

  @override
  String? read(String key) => _box?.get(key);

  @override
  void write(String key, String value) {
    final box = _box;
    if (box != null) unawaited(box.put(key, value));
  }

  @override
  void delete(String key) {
    final box = _box;
    if (box != null) unawaited(box.delete(key));
  }
}

/// Remembers one table's column widths on this device, across tab switches
/// and restarts.
///
/// A table builds its columns through [apply] and hands its state manager
/// to [attach] once loaded. After the user resizes a column the widths are
/// saved — when the drag has settled ([saveDelay]), and only if something
/// changed — to the `settings` box, beside the table's column layout:
/// widths are a preference of this machine, neither synced nor backed up.
///
/// Saving merges: a column hidden right now keeps the width it was given
/// for when it is shown again.
class ColumnWidthMemory {
  ColumnWidthMemory(
    this.table, {
    this.saveDelay = const Duration(milliseconds: 500),
    this.storage = const HiveColumnWidths(),
  });

  /// Which table: the key the widths are stored under (`columnWidths.<table>`).
  final String table;
  final Duration saveDelay;
  final ColumnWidthStorage storage;

  String get storageKey => 'columnWidths.$table';

  Map<String, double>? _saved;
  TrinaGridStateManager? _attached;
  Timer? _pending;

  /// A resize happened since the last save. Only then is there anything to
  /// save: a table nobody resized keeps following the columns' defaults.
  bool _dirty = false;

  /// The widths saved for this table (read once, then kept in memory).
  Map<String, double> get saved => _saved ??= _read();

  Map<String, double> _read() {
    try {
      return decodeColumnWidths(storage.read(storageKey));
    } catch (_) {
      return const {};
    }
  }

  /// [columns] with their saved widths — see [applyColumnWidths].
  List<TrinaColumn> apply(List<TrinaColumn> columns) =>
      applyColumnWidths(columns, saved);

  /// Starts saving [stateManager]'s widths after each resize. Re-attaching
  /// (the grid was rebuilt) moves over to the new state manager.
  void attach(TrinaGridStateManager stateManager) {
    if (identical(stateManager, _attached)) return;
    _detach();
    _attached = stateManager;
    stateManager.resizingChangeNotifier.addListener(_onResized);
  }

  void _detach() {
    _attached?.resizingChangeNotifier.removeListener(_onResized);
    _attached = null;
  }

  void _onResized() {
    _dirty = true;
    _pending?.cancel();
    _pending = Timer(saveDelay, flush);
  }

  /// Saves now, if a column was resized and the widths differ from what is
  /// stored — what a pending save does when its delay runs out, and
  /// [dispose] does on the way out.
  void flush() {
    _pending?.cancel();
    _pending = null;
    final stateManager = _attached;
    if (stateManager == null || !_dirty) return;
    _dirty = false;
    final Map<String, double> current;
    try {
      current = columnWidthsOf(stateManager.refColumns.originalList);
    } catch (_) {
      return; // the grid is already gone
    }
    final merged = {...saved, ...current};
    if (mapEquals(merged, saved)) return;
    _saved = merged;
    _write(merged);
  }

  void _write(Map<String, double> widths) {
    try {
      storage.write(storageKey, encodeColumnWidths(widths));
    } catch (e) {
      debugPrint('[ColumnWidthMemory] failed to save $storageKey: $e');
    }
  }

  /// Forgets this table's widths — back to the columns' own.
  void reset() {
    _pending?.cancel();
    _pending = null;
    _dirty = false;
    _saved = const {};
    try {
      storage.delete(storageKey);
    } catch (_) {}
  }

  /// Saves anything pending and lets go of the grid. Call from the owning
  /// widget's `dispose`.
  void dispose() {
    if (_pending != null) flush();
    _detach();
  }
}
