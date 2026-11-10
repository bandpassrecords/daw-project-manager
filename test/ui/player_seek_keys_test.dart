import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trina_grid/trina_grid.dart';

import 'package:daw_project_manager/ui/player_seek_keys.dart';

void main() {
  group('playerSeekSeconds', () {
    test('Left and Right jump 5 seconds, 30 with the long jump', () {
      expect(
        playerSeekSeconds(LogicalKeyboardKey.arrowLeft, longJump: false),
        -5,
      );
      expect(
        playerSeekSeconds(LogicalKeyboardKey.arrowRight, longJump: false),
        5,
      );
      expect(
        playerSeekSeconds(LogicalKeyboardKey.arrowLeft, longJump: true),
        -30,
      );
      expect(
        playerSeekSeconds(LogicalKeyboardKey.arrowRight, longJump: true),
        30,
      );
    });

    test('Up, Down and other keys are not seeks', () {
      expect(
        playerSeekSeconds(LogicalKeyboardKey.arrowUp, longJump: false),
        isNull,
      );
      expect(
        playerSeekSeconds(LogicalKeyboardKey.arrowDown, longJump: false),
        isNull,
      );
      expect(playerSeekSeconds(LogicalKeyboardKey.keyP, longJump: false), isNull);
    });
  });

  group('playerBarTakesSeekKeys', () {
    bool takes({
      bool barHasFocus = false,
      bool pageInFront = true,
      bool focusFree = true,
      bool shift = false,
      bool alt = false,
    }) => playerBarTakesSeekKeys(
      barHasFocus: barHasFocus,
      pageInFront: pageInFront,
      focusHasNoUseForArrows: focusFree,
      shift: shift,
      alt: alt,
    );

    test('from the table, with the bar never clicked', () {
      expect(takes(), isTrue);
    });

    test('not under a dialog or a pushed page', () {
      expect(takes(pageInFront: false), isFalse);
    });

    test('not when what has focus uses the arrows', () {
      expect(takes(focusFree: false), isFalse);
    });

    test('Shift and Alt combinations stay with the table and the app', () {
      expect(takes(shift: true), isFalse);
      expect(takes(alt: true), isFalse);
    });

    test('the bar itself always takes them', () {
      expect(
        takes(barHasFocus: true, pageInFront: false, focusFree: false),
        isTrue,
      );
    });
  });

  group('the handler, on real focus', () {
    late List<int> seeks;
    late bool pageInFront;
    late OnKeyEventCallback handler;

    setUp(() {
      seeks = [];
      pageInFront = true;
      handler = playerSeekKeyHandler(
        barHasFocus: () => false,
        pageInFront: () => pageInFront,
        onSeek: seeks.add,
      );
      FocusManager.instance.addEarlyKeyEventHandler(handler);
    });

    tearDown(() {
      FocusManager.instance.removeEarlyKeyEventHandler(handler);
    });

    testWidgets('the table keeps its row and cell while Left/Right seek', (
      tester,
    ) async {
      final sm = await _pumpTable(tester);
      sm.setCurrentCell(sm.rows[0].cells['b'], 0);
      sm.gridFocusNode.requestFocus();
      await tester.pump();
      expect(sm.gridFocusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(seeks, [5, -5]);
      expect(sm.currentCell, same(sm.rows[0].cells['b']));
    });

    testWidgets('Up and Down still walk the table', (tester) async {
      final sm = await _pumpTable(tester);
      sm.setCurrentCell(sm.rows[0].cells['a'], 0);
      sm.gridFocusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(seeks, isEmpty);
      expect(sm.currentRowIdx, 1);
    });

    testWidgets('Ctrl jumps 30 seconds from the table', (tester) async {
      final sm = await _pumpTable(tester);
      sm.setCurrentCell(sm.rows[0].cells['a'], 0);
      sm.gridFocusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(seeks, [30]);
    });

    testWidgets('with nothing focused the keyboard stays where it is', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                TextButton(onPressed: () {}, child: const Text('one')),
                TextButton(onPressed: () {}, child: const Text('two')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      final before = FocusManager.instance.primaryFocus;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(seeks, [5]);
      expect(FocusManager.instance.primaryFocus, same(before));
    });

    testWidgets('a text field keeps its arrows', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(focusNode: node)),
        ),
      );
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);

      expect(seeks, isEmpty);
    });

    testWidgets('a focused button keeps its arrows', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              focusNode: node,
              onPressed: () {},
              child: const Text('button'),
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);

      expect(seeks, isEmpty);
    });

    testWidgets('behind a dialog nothing seeks', (tester) async {
      final sm = await _pumpTable(tester);
      sm.gridFocusNode.requestFocus();
      await tester.pump();
      pageInFront = false;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);

      expect(seeks, isEmpty);
    });
  });
}

Future<TrinaGridStateManager> _pumpTable(WidgetTester tester) async {
  late TrinaGridStateManager manager;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TrinaGrid(
          mode: TrinaGridMode.readOnly,
          columns: [
            for (final field in ['a', 'b'])
              TrinaColumn(
                title: field,
                field: field,
                type: TrinaColumnType.text(),
              ),
          ],
          rows: [
            for (var i = 0; i < 3; i++)
              TrinaRow(
                cells: {
                  'a': TrinaCell(value: 'a$i'),
                  'b': TrinaCell(value: 'b$i'),
                },
              ),
          ],
          onLoaded: (event) => manager = event.stateManager,
        ),
      ),
    ),
  );
  await tester.pump();
  return manager;
}
