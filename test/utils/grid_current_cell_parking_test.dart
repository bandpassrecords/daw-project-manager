import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';

import 'package:daw_project_manager/utils/grid_current_cell_parking.dart';

/// Clicking the preview player's waveform while a dashboard row was selected
/// left the last-clicked cell outlined: TrinaGrid draws an "inactivated"
/// border and a background fill round the current cell once the grid loses
/// focus. The dashboard now parks the current cell while unfocused.
void main() {
  late TrinaGridStateManager sm;
  late GridCurrentCellParking parking;
  late FocusNode elsewhere;

  List<TrinaColumn> columns() => [
        TrinaColumn(title: 'Id', field: 'id', type: TrinaColumnType.text()),
        TrinaColumn(
            title: 'Name', field: 'name', type: TrinaColumnType.text()),
      ];

  TrinaRow row(String id, String name) => TrinaRow(cells: {
        'id': TrinaCell(value: id),
        'name': TrinaCell(value: name),
      });

  Future<void> pumpGrid(WidgetTester tester) async {
    parking = GridCurrentCellParking(
      rowKey: (r) => r.cells['id']?.value as String?,
    );
    elsewhere = FocusNode();
    addTearDown(elsewhere.dispose);
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          // Stands in for the preview player: something else to focus.
          Focus(focusNode: elsewhere, child: const SizedBox(height: 40)),
          Expanded(
            child: TrinaGrid(
              columns: columns(),
              rows: [row('a', 'Alpha'), row('b', 'Bravo'), row('c', 'Charlie')],
              mode: TrinaGridMode.readOnly,
              onLoaded: (e) {
                sm = e.stateManager;
                sm.gridFocusNode.addListener(() {
                  if (sm.gridFocusNode.hasFocus) {
                    parking.restore(sm);
                  } else {
                    parking.park(sm);
                  }
                });
              },
            ),
          ),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> selectBravoName(WidgetTester tester) async {
    await tester.tap(find.text('Bravo'));
    await tester.pumpAndSettle();
    expect(sm.currentCell?.value, 'Bravo');
    expect(sm.hasFocus, isTrue);
  }

  testWidgets('clicking elsewhere leaves no current cell to outline',
      (tester) async {
    await pumpGrid(tester);
    await selectBravoName(tester);

    elsewhere.requestFocus();
    await tester.pumpAndSettle();

    expect(sm.currentCell, isNull);
  });

  testWidgets('the parked row is still known, so it can stay highlighted',
      (tester) async {
    await pumpGrid(tester);
    await selectBravoName(tester);

    elsewhere.requestFocus();
    await tester.pumpAndSettle();

    expect(parking.parkedKey, 'b');
    expect(parking.isParkedRow(sm.refRows[1]), isTrue);
    expect(parking.isParkedRow(sm.refRows[0]), isFalse);
  });

  testWidgets('focus coming back restores the same cell', (tester) async {
    await pumpGrid(tester);
    await selectBravoName(tester);
    elsewhere.requestFocus();
    await tester.pumpAndSettle();

    sm.gridFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(sm.currentCell?.value, 'Bravo');
    expect(sm.currentCell?.column.field, 'name');
    expect(parking.parkedKey, isNull);
  });

  testWidgets('clicking a different row on the way back selects that row',
      (tester) async {
    await pumpGrid(tester);
    await selectBravoName(tester);
    elsewhere.requestFocus();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Charlie'));
    await tester.pumpAndSettle();

    expect(sm.currentCell?.value, 'Charlie');
  });

  testWidgets('finds its row again after the rows are rebuilt',
      (tester) async {
    // The dashboard replaces every row object on a rebuild; the parked cell
    // is remembered by key, not by object.
    await pumpGrid(tester);
    await selectBravoName(tester);
    elsewhere.requestFocus();
    await tester.pumpAndSettle();

    sm.removeRows(sm.rows, notify: false);
    sm.insertRows(0, [row('c', 'Charlie'), row('b', 'Bravo 2')]);
    await tester.pumpAndSettle();

    sm.gridFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(sm.currentCell?.value, 'Bravo 2');
    expect(sm.currentRowIdx, 1);
  });

  testWidgets('a row that has gone is simply not restored', (tester) async {
    await pumpGrid(tester);
    await selectBravoName(tester);
    elsewhere.requestFocus();
    await tester.pumpAndSettle();

    sm.removeRows([sm.refRows[1]]);
    await tester.pumpAndSettle();
    sm.gridFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(sm.currentCell, isNull);
    expect(parking.parkedKey, isNull);
  });

  testWidgets('with nothing selected there is nothing to park',
      (tester) async {
    await pumpGrid(tester);

    sm.gridFocusNode.requestFocus();
    await tester.pumpAndSettle();
    elsewhere.requestFocus();
    await tester.pumpAndSettle();

    expect(parking.parkedKey, isNull);
  });

  testWidgets('clear forgets the parked cell', (tester) async {
    await pumpGrid(tester);
    await selectBravoName(tester);
    elsewhere.requestFocus();
    await tester.pumpAndSettle();

    parking.clear();
    sm.gridFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(sm.currentCell, isNull);
  });
}
