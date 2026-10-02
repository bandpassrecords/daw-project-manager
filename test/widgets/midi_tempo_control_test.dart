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

    setUp(() => changes = []);

    Widget wrap({required double bpm, double? project = 145}) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MidiTempoControl(
                  bpm: bpm,
                  projectBpm: project,
                  onChanged: changes.add,
                  labels: MidiTempoLabels(
                    unit: 'BPM',
                    tooltip: 'Tempo',
                    slower: 'Slower',
                    faster: 'Faster',
                    resetTo: (bpm) => 'Reset to $bpm',
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

    testWidgets('a typed tempo is applied on submit', (tester) async {
      await tester.pumpWidget(wrap(bpm: 145));
      await tester.enterText(find.byType(TextField).first, '170');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(changes, [170]);
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

    testWidgets('offers a reset only once the tempo differs from the project',
        (tester) async {
      await tester.pumpWidget(wrap(bpm: 145));
      expect(find.byTooltip('Reset to 145'), findsNothing);

      await tester.pumpWidget(wrap(bpm: 160));
      await tester.tap(find.byTooltip('Reset to 145'));
      expect(changes, [145]);
    });

    testWidgets('no reset when the project tempo is unknown', (tester) async {
      await tester.pumpWidget(wrap(bpm: 120, project: null));
      expect(find.byIcon(Icons.restart_alt), findsNothing);
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
