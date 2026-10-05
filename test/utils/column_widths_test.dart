import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:trina_grid/trina_grid.dart';

import 'package:daw_project_manager/utils/column_widths.dart';

/// Storage in a map, counting writes — widget tests must not write to Hive.
class _MapStorage implements ColumnWidthStorage {
  final Map<String, String> values = {};
  int writes = 0;

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) {
    writes++;
    values[key] = value;
  }

  @override
  void delete(String key) => values.remove(key);
}

List<TrinaColumn> _columns() => [
      for (final f in ['name', 'bpm', 'key', 'status'])
        TrinaColumn(
          title: f,
          field: f,
          type: TrinaColumnType.text(),
          width: 150,
          minWidth: 60,
        ),
    ];

List<TrinaRow> _rows() => [
      TrinaRow(cells: {
        'name': TrinaCell(value: 'Song'),
        'bpm': TrinaCell(value: '128'),
        'key': TrinaCell(value: 'Am'),
        'status': TrinaCell(value: 'Idea'),
      }),
    ];

void main() {
  group('encoding', () {
    test('round-trips widths', () {
      const widths = {'name': 312.5, 'bpm': 80.0};
      expect(decodeColumnWidths(encodeColumnWidths(widths)), widths);
    });

    test('anything unreadable reads as nothing saved', () {
      expect(decodeColumnWidths(null), isEmpty);
      expect(decodeColumnWidths(''), isEmpty);
      expect(decodeColumnWidths('not json'), isEmpty);
      expect(decodeColumnWidths('[1, 2]'), isEmpty);
      expect(decodeColumnWidths('{"name": "wide", "bpm": -3, "key": 90}'),
          {'key': 90.0});
    });
  });

  test('applyColumnWidths: saved widths go on, never below a minimum', () {
    final columns = applyColumnWidths(
        _columns(), {'name': 400, 'bpm': 10, 'gone': 99});
    expect(columns.map((c) => c.width), [400, 60, 150, 150]);
    expect(columnWidthsOf(columns),
        {'name': 400.0, 'bpm': 60.0, 'key': 150.0, 'status': 150.0});
  });

  group('ColumnWidthMemory with a grid', () {
    late _MapStorage storage;
    setUp(() => storage = _MapStorage());

    /// A grid configured like the app's tables: columns scaled to fit,
    /// push-and-pull resizing.
    Future<TrinaGridStateManager> pumpGrid(
        WidgetTester tester, ColumnWidthMemory memory) async {
      late TrinaGridStateManager sm;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 300,
            child: TrinaGrid(
              key: UniqueKey(),
              columns: memory.apply(_columns()),
              rows: _rows(),
              configuration: const TrinaGridConfiguration(
                columnSize: TrinaGridColumnSizeConfig(
                  autoSizeMode: TrinaAutoSizeMode.scale,
                  resizeMode: TrinaResizeMode.pushAndPull,
                ),
              ),
              onLoaded: (e) {
                sm = e.stateManager;
                memory.attach(e.stateManager);
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return sm;
    }

    double widthOf(TrinaGridStateManager sm, String field) =>
        sm.refColumns.originalList.firstWhere((c) => c.field == field).width;

    testWidgets('a resized column comes back at that width in a new grid',
        (tester) async {
      final memory = ColumnWidthMemory('t', storage: storage);
      final sm = await pumpGrid(tester, memory);
      final before = widthOf(sm, 'name');

      sm.resizeColumn(
          sm.refColumns.originalList.firstWhere((c) => c.field == 'name'), 80);
      await tester.pump();
      final resized = widthOf(sm, 'name');
      expect(resized, greaterThan(before));
      expect(storage.values, isEmpty, reason: 'nothing saved mid-drag');

      await tester.pump(const Duration(milliseconds: 600));
      final saved = decodeColumnWidths(storage.values['columnWidths.t']);
      expect(saved['name'], closeTo(resized, 0.1));
      memory.dispose();

      // A tab switch or a restart: a new memory, a new grid, default columns.
      final again = ColumnWidthMemory('t', storage: storage);
      final sm2 = await pumpGrid(tester, again);
      expect(widthOf(sm2, 'name'), closeTo(resized, 1));
      again.dispose();
    });

    testWidgets('widths of columns not on screen are kept', (tester) async {
      storage.values['columnWidths.t'] =
          encodeColumnWidths({'customField': 222});
      final memory = ColumnWidthMemory('t', storage: storage);
      final sm = await pumpGrid(tester, memory);
      sm.resizeColumn(sm.refColumns.originalList.first, 40);
      await tester.pump(const Duration(milliseconds: 600));
      final saved = decodeColumnWidths(storage.values['columnWidths.t']);
      expect(saved['customField'], 222);
      expect(saved.keys, containsAll(['name', 'bpm', 'key', 'status']));
      memory.dispose();
    });

    testWidgets('leaving before the save fires still saves', (tester) async {
      final memory = ColumnWidthMemory('t', storage: storage);
      final sm = await pumpGrid(tester, memory);
      final writesBefore = storage.writes;
      sm.resizeColumn(sm.refColumns.originalList.first, 50);
      await tester.pump();
      memory.dispose(); // e.g. switching tabs at once
      expect(storage.writes, writesBefore + 1);
      await tester.pump(const Duration(milliseconds: 600));
      expect(storage.writes, writesBefore + 1, reason: 'no second save');
    });

    testWidgets('nothing changed, nothing written', (tester) async {
      final memory = ColumnWidthMemory('t', storage: storage);
      await pumpGrid(tester, memory);
      await tester.pump(const Duration(milliseconds: 600));
      final writes = storage.writes;
      memory.flush();
      expect(storage.writes, writes);
      memory.dispose();
    });

    testWidgets('reset forgets the table\'s widths', (tester) async {
      storage.values['columnWidths.t'] = encodeColumnWidths({'name': 300});
      final memory = ColumnWidthMemory('t', storage: storage);
      expect(memory.saved, {'name': 300.0});
      memory.reset();
      expect(memory.saved, isEmpty);
      expect(storage.values, isEmpty);
    });
  });

  group('HiveColumnWidths', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('column_widths_');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('reads and writes the settings box once it is open', () async {
      const store = HiveColumnWidths();
      expect(store.read('k'), isNull, reason: 'box not open yet');
      store.write('k', 'ignored'); // nowhere to write: no crash

      final box = await Hive.openBox<String>('settings');
      store.write('columnWidths.projects', '{"name":300}');
      await Future<void>.delayed(Duration.zero);
      expect(box.get('columnWidths.projects'), '{"name":300}');
      expect(store.read('columnWidths.projects'), '{"name":300}');

      store.delete('columnWidths.projects');
      await Future<void>.delayed(Duration.zero);
      expect(store.read('columnWidths.projects'), isNull);
    });
  });
}
