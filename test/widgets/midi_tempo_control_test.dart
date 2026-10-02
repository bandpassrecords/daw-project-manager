import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/midi_tempo_control.dart';

void main() {
  group('parsePreviewBpm', () {
    test('reads whole and decimal tempos, with a dot or a comma', () {
      expect(parsePreviewBpm('145'), 145);
      expect(parsePreviewBpm(' 128.5 '), 128.5);
      expect(parsePreviewBpm('128,5'), 128.5);
    });

    test('rejects text and tempos outside the usable range', () {
      expect(parsePreviewBpm(''), isNull);
      expect(parsePreviewBpm('fast'), isNull);
      expect(parsePreviewBpm('19.9'), isNull);
      expect(parsePreviewBpm('400.1'), isNull);
      expect(parsePreviewBpm('20'), 20);
      expect(parsePreviewBpm('400'), 400);
    });
  });

  test('formatPreviewBpm drops a needless decimal part', () {
    expect(formatPreviewBpm(145), '145');
    expect(formatPreviewBpm(128.5), '128.5');
    expect(formatPreviewBpm(99.75), '99.75');
    expect(formatPreviewBpm(120.004), '120');
  });

  group('MidiTempoControl', () {
    late List<double> changes;
    late int resets;

    setUp(() {
      changes = [];
      resets = 0;
    });

    Widget wrap({double? bpm, bool resettable = false, double nudgeFrom = 120}) =>
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MidiTempoControl(
                  bpm: bpm,
                  nudgeFrom: nudgeFrom,
                  onChanged: changes.add,
                  onReset: resettable ? () => resets++ : null,
                  resetTooltip: 'Reset',
                  labels: const MidiTempoLabels(
                    unit: 'BPM',
                    tooltip: 'Tempo',
                    slower: 'Slower',
                    faster: 'Faster',
                    auto: 'Auto',
                  ),
                ),
                const TextField(key: ValueKey('elsewhere')),
              ],
            ),
          ),
        );

    testWidgets('shows the tempo in effect', (tester) async {
      await tester.pumpWidget(wrap(bpm: 145));
      expect(find.widgetWithText(TextField, '145'), findsOneWidget);
    });

    testWidgets('nudges by one BPM either way', (tester) async {
      await tester.pumpWidget(wrap(bpm: 145));
      await tester.tap(find.byTooltip('Faster'));
      await tester.tap(find.byTooltip('Slower'));
      expect(changes, [146, 144]);
    });

    testWidgets('a typed tempo is applied once on submit', (tester) async {
      await tester.pumpWidget(wrap(bpm: 145));
      await tester.enterText(find.byType(TextField).first, '170');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(changes, [170], reason: 'Enter then losing focus must not apply it twice');
    });

    testWidgets('a typed tempo is applied when the field loses focus',
        (tester) async {
      await tester.pumpWidget(wrap(bpm: 145));
      await tester.enterText(find.byType(TextField).first, '90,5');
      await tester.tap(find.byKey(const ValueKey('elsewhere')));
      await tester.pump();
      expect(changes, [90.5]);
    });

    testWidgets('an unusable entry snaps back instead of changing anything',
        (tester) async {
      await tester.pumpWidget(wrap(bpm: 145));
      await tester.enterText(find.byType(TextField).first, '9000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(changes, isEmpty);
      expect(find.widgetWithText(TextField, '145'), findsOneWidget);
    });

    testWidgets("the reset button is the caller's to offer", (tester) async {
      await tester.pumpWidget(wrap(bpm: 145));
      expect(find.byTooltip('Reset'), findsNothing);

      await tester.pumpWidget(wrap(bpm: 160, resettable: true));
      await tester.tap(find.byTooltip('Reset'));
      expect(resets, 1);
    });

    testWidgets('automatic: an empty field with a hint, nudges start from nudgeFrom',
        (tester) async {
      await tester.pumpWidget(wrap(nudgeFrom: 140));
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, isEmpty);
      expect(field.decoration!.hintText, 'Auto');

      await tester.tap(find.byTooltip('Faster'));
      expect(changes, [141]);
    });

    testWidgets('clearing the field while automatic stays automatic',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.enterText(find.byType(TextField).first, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(changes, isEmpty);
    });

    testWidgets('follows a tempo changed from outside', (tester) async {
      await tester.pumpWidget(wrap(bpm: 145));
      await tester.pumpWidget(wrap(bpm: 132));
      expect(find.widgetWithText(TextField, '132'), findsOneWidget);
    });

    testWidgets('the nudges stop at the ends of the range', (tester) async {
      await tester.pumpWidget(wrap(bpm: kMaxPreviewBpm));
      await tester.tap(find.byTooltip('Faster'));
      expect(changes, isEmpty);
    });
  });
}
