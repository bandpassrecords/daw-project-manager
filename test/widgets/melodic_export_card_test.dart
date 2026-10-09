import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/melodic_export_card.dart';

void main() {
  Future<({List<bool> chords, List<bool> bass, List<int> exports})> pumpCard(
    WidgetTester tester, {
    bool busy = false,
  }) async {
    final chords = <bool>[];
    final bass = <bool>[];
    final exports = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 900,
              child: MelodicExportCard(
                busy: busy,
                includeChords: false,
                includeBass: false,
                onIncludeChordsChanged: chords.add,
                onIncludeBassChanged: bass.add,
                onExport: () => exports.add(1),
              ),
            ),
          ),
        ),
      ),
    );
    return (chords: chords, bass: bass, exports: exports);
  }

  testWidgets('lays out, and the button starts the export', (tester) async {
    final r = await pumpCard(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(FilledButton));
    expect(r.exports, hasLength(1));
  });

  testWidgets('each checkbox reports its own value', (tester) async {
    final r = await pumpCard(tester);
    final boxes = find.byType(CheckboxListTile);
    expect(boxes, findsNWidgets(2));
    await tester.tap(boxes.at(0));
    await tester.tap(boxes.at(1));
    expect(r.chords, [true]);
    expect(r.bass, [true]);
  });

  testWidgets('while busy nothing can be started or changed', (tester) async {
    final r = await pumpCard(tester, busy: true);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.tap(find.byType(CheckboxListTile).first, warnIfMissed: false);
    expect(r.exports, isEmpty);
    expect(r.chords, isEmpty);
  });
}
