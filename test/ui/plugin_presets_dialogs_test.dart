import 'dart:async';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/services/plugin_presets/preset_export.dart';
import 'package:daw_project_manager/ui/dialogs/plugin_presets_dialogs.dart';
import 'package:daw_project_manager/ui/widgets/plugin_presets_card.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  group('PluginPresetsCard', () {
    testWidgets('exports on tap, and not while another task runs', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        PluginPresetsCard(busy: false, onExport: () => taps++),
      );
      expect(
        find.text('Plug-in presets from your Cubase projects'),
        findsOneWidget,
      );

      await tester.tap(find.byType(FilledButton));
      expect(taps, 1);

      await _pump(
        tester,
        PluginPresetsCard(busy: true, onExport: () => taps++),
      );
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(taps, 1);
    });
  });

  group('PluginPresetsResultDialog', () {
    Future<void> show(
      WidgetTester tester,
      PresetExportResult result, {
      VoidCallback? onOpen,
    }) => _pump(
      tester,
      PluginPresetsResultDialog(result: result, onOpenFolder: onOpen ?? () {}),
    );

    testWidgets('says what was saved, what was repeated and what cannot be', (
      tester,
    ) async {
      await show(
        tester,
        const PresetExportResult(
          written: 12,
          alreadyThere: 3,
          unsavable: {'Diva': 2, 'PuigTec': 5},
          projectsFailed: 1,
        ),
      );

      expect(find.text('Presets saved'), findsOneWidget);
      expect(find.textContaining('12 new presets saved'), findsOneWidget);
      expect(
        find.textContaining('3 were already in the folder'),
        findsOneWidget,
      );
      expect(
        find.textContaining('7 plug-ins keep their state'),
        findsOneWidget,
      );
      expect(
        find.textContaining('PuigTec, Diva'),
        findsOneWidget,
        reason: 'the most numerous first',
      );
      expect(
        find.textContaining('1 project could not be read'),
        findsOneWidget,
      );
    });

    testWidgets('a stopped run says so', (tester) async {
      await show(tester, const PresetExportResult(written: 1, stopped: true));
      expect(find.textContaining('Stopped'), findsOneWidget);
    });

    testWidgets('offers the folder only when there is something in it', (
      tester,
    ) async {
      var opened = 0;
      await show(
        tester,
        const PresetExportResult(written: 2),
        onOpen: () => opened++,
      );
      await tester.tap(find.text('Open Folder'));
      expect(opened, 1);

      await show(tester, const PresetExportResult());
      expect(find.text('Open Folder'), findsNothing);
    });

    test('unsavable names stop at five, ending in an ellipsis', () {
      final names = PluginPresetsResultDialog.unsavableNames({
        for (var i = 0; i < 7; i++) 'P$i': 10 - i,
      });
      expect(names, 'P0, P1, P2, P3, P4…');
    });
  });

  group('PluginPresetsProgressDialog', () {
    testWidgets('shows which project, stops on request and pops the result', (
      tester,
    ) async {
      Object? popped;
      bool Function()? stopped;
      void Function(int, int, String)? report;
      final done = Completer<PresetExportResult>();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => popped = await showDialog<Object?>(
                context: context,
                builder: (_) => PluginPresetsProgressDialog(
                  run: (onProgress, shouldStop) {
                    report = onProgress;
                    stopped = shouldStop;
                    return done.future;
                  },
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();

      report!(1, 4, 'My Song');
      await tester.pump();
      expect(find.text('Reading project 2 of 4: My Song'), findsOneWidget);

      expect(stopped!(), isFalse);
      await tester.tap(find.text('Stop'));
      await tester.pump();
      expect(stopped!(), isTrue);

      done.complete(const PresetExportResult(written: 1, stopped: true));
      await tester.pumpAndSettle();
      expect(popped, isA<PresetExportResult>());
    });
  });
}
