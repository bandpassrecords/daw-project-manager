import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/services/project_inspector/project_copy.dart';
import 'package:daw_project_manager/services/project_inspector/safe_copy/safe_copy.dart';
import 'package:daw_project_manager/ui/dialogs/safe_copy_dialog.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

import '../helpers/semantics_orphans.dart';

PluginSwitch _sw(String plugin, String channel, int at, {bool off = false}) =>
    PluginSwitch(
      plugin: plugin,
      channel: channel,
      kind: PluginSlotKind.insert,
      at: at,
      off: off,
    );

/// What the dialog asked for, and what the fakes answer.
class _World {
  Set<String>? written;
  String? inspected;
  Object? loadError;
  Object? writeError;
  SafeCopy copy = const SafeCopy(
    path: r'D:\Song\Song (safe copy).cpr',
    switchedOff: {'Serum': 4},
  );

  SafeCopyActions get actions => SafeCopyActions(
    load: () async {
      if (loadError != null) throw loadError!;
      return [
        _sw('Serum', 'Bass', 1),
        _sw('Serum', 'Lead', 2),
        _sw('Serum', 'Pad', 3),
        _sw('Serum', 'Pad', 4),
        _sw('Serum', 'Keys', 5, off: true),
        _sw('OTT', 'Drums', 6, off: true),
        _sw('Pro-Q 3', 'Bass', 7),
      ];
    },
    write: (plugins) async {
      written = plugins;
      if (writeError != null) throw writeError!;
      return copy;
    },
    inspect: (path) => inspected = path,
  );
}

void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, _World world) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SafeCopyDialog(projectName: 'Song.cpr', actions: world.actions),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists each plug-in once, how often it is on and where', (
    tester,
  ) async {
    await pump(tester, _World());
    expect(
      find.text('4 instances · 1 already off\nBass, Lead, Pad, Keys'),
      findsOneWidget,
    );
    expect(find.text('Already off everywhere\nDrums'), findsOneWidget);
    expect(find.text('1 instance\nBass'), findsOneWidget);
    expect(find.text('Pick the plug-ins to switch off'), findsOneWidget);
    final write = find.widgetWithText(FilledButton, 'Write safe copy');
    expect(tester.widget<FilledButton>(write).onPressed, isNull);
    final ott = find.widgetWithText(CheckboxListTile, 'OTT');
    expect(
      tester.widget<CheckboxListTile>(ott).onChanged,
      isNull,
      reason: 'nothing of it to switch off',
    );
  });

  testWidgets('the filter narrows the list', (tester) async {
    await pump(tester, _World());
    await tester.enterText(find.byType(TextField), 'ser');
    await tester.pump();
    expect(find.widgetWithText(CheckboxListTile, 'Serum'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Pro-Q 3'), findsNothing);
  });

  testWidgets('writes the ticked plug-ins and says what it switched off', (
    tester,
  ) async {
    final world = _World();
    await pump(tester, world);
    await tester.tap(find.text('Serum'));
    await tester.pump();
    expect(find.text('4 instances will be switched off'), findsOneWidget);
    await tester.tap(find.text('Pro-Q 3'));
    await tester.pump();
    expect(find.text('5 instances will be switched off'), findsOneWidget);
    await tester.tap(find.text('Pro-Q 3'));
    await tester.pump();
    await tester.tap(find.text('Write safe copy'));
    await tester.pumpAndSettle();
    expect(world.written, {'Serum'});
    expect(find.text('Wrote Song (safe copy).cpr'), findsOneWidget);
    expect(find.text('4 instances switched off'), findsOneWidget);
    expect(find.text('  Serum ×4'), findsOneWidget);
    await tester.tap(find.text('Inspect the copy'));
    expect(world.inspected, r'D:\Song\Song (safe copy).cpr');
  });

  testWidgets('a copy that fails its check is reported, not kept', (
    tester,
  ) async {
    final world = _World()
      ..writeError = const CopyCheckFailed('the copy does not read as switched off');
    await pump(tester, world);
    await tester.tap(find.text('Serum'));
    await tester.pump();
    await tester.tap(find.text('Write safe copy'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "The copy didn't check out and was not kept: "
        'the copy does not read as switched off',
      ),
      findsOneWidget,
    );
    expect(find.text('Inspect the copy'), findsNothing);
  });

  testWidgets('a project whose plug-ins can not be read says so', (
    tester,
  ) async {
    final world = _World()..loadError = 'broken archive';
    await pump(tester, world);
    expect(
      find.text("The project's plug-ins couldn't be read: broken archive"),
      findsOneWidget,
    );
  });

  testWidgets('every tooltip shows with no node Windows rejects', (
    tester,
  ) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await pump(tester, _World());
    expect(binding.orphans, isEmpty);
    await expectNoOrphanSemanticsWhileHovering(tester);
    handle.dispose();
  });
}
