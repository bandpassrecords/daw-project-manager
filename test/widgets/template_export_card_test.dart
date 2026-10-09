import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/template_export_card.dart';

void main() {
  Future<({List<bool> toggles, List<int> exports})> pumpCard(
    WidgetTester tester, {
    bool busy = false,
    bool anonymize = false,
  }) async {
    final toggles = <bool>[];
    final exports = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 900,
              child: TemplateExportCard(
                busy: busy,
                anonymize: anonymize,
                onAnonymizeChanged: toggles.add,
                onExport: () => exports.add(1),
              ),
            ),
          ),
        ),
      ),
    );
    return (toggles: toggles, exports: exports);
  }

  testWidgets('lays out, and the button starts the export', (tester) async {
    final r = await pumpCard(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(FilledButton));
    expect(r.exports, hasLength(1));
  });

  testWidgets('the checkbox reports the new value', (tester) async {
    final r = await pumpCard(tester);
    await tester.tap(find.byType(CheckboxListTile));
    expect(r.toggles, [true]);
  });

  testWidgets('while busy nothing can be started or changed', (tester) async {
    final r = await pumpCard(tester, busy: true);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.tap(find.byType(CheckboxListTile), warnIfMissed: false);
    expect(r.exports, isEmpty);
    expect(r.toggles, isEmpty);
  });
}
