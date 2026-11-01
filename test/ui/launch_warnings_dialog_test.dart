import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/services/project_inspector/launch_check.dart';
import 'package:daw_project_manager/ui/dialogs/launch_warnings_dialog.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

import '../helpers/semantics_orphans.dart';

void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();

  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  /// Opens the dialog and returns what the button tapped chose.
  Future<LaunchChoice?> choose(
    WidgetTester tester,
    LaunchWarnings warnings, {
    String? tap,
    bool canRelink = true,
    bool canSafeCopy = true,
  }) async {
    LaunchChoice? chosen;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => chosen = await showDialog<LaunchChoice>(
              context: context,
              builder: (_) => LaunchWarningsDialog(
                projectName: 'Song',
                warnings: warnings,
                canRelink: canRelink,
                canSafeCopy: canSafeCopy,
              ),
            ),
            child: const Text('launch'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();
    if (tap != null) {
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
    }
    return chosen;
  }

  const both = LaunchWarnings(
    missingAudio: 2,
    totalAudio: 14,
    projectRate: 44100,
    studioRate: 48000,
  );

  testWidgets('says what it found, and every way on', (tester) async {
    await choose(tester, both);
    expect(find.text('Before opening Song'), findsOneWidget);
    expect(find.text('2 of its 14 audio files are missing'), findsOneWidget);
    expect(find.text('Saved at 44.1 kHz; your studio runs at 48 kHz'),
        findsOneWidget);
    for (final label in [
      'Cancel',
      'Inspect',
      'Safe copy…',
      'Fix missing files…',
      'Open anyway',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('each button says what was chosen', (tester) async {
    for (final (label, choice) in [
      ('Open anyway', LaunchChoice.open),
      ('Fix missing files…', LaunchChoice.relink),
      ('Safe copy…', LaunchChoice.safeCopy),
      ('Inspect', LaunchChoice.inspect),
      ('Cancel', LaunchChoice.cancel),
    ]) {
      expect(await choose(tester, both, tap: label), choice, reason: label);
    }
  });

  testWidgets('no fix offered with nothing missing, or a format not written', (
    tester,
  ) async {
    await choose(
      tester,
      const LaunchWarnings(projectRate: 44100, studioRate: 48000),
    );
    expect(find.text('Fix missing files…'), findsNothing);
    expect(find.textContaining('audio files'), findsNothing);

    await choose(tester, both, canRelink: false, canSafeCopy: false);
    expect(find.text('Fix missing files…'), findsNothing);
    expect(find.text('Safe copy…'), findsNothing);
  });

  testWidgets('the settings card: the switch and the studio rate', (
    tester,
  ) async {
    final calls = <Object?>[];
    await tester.pumpWidget(
      app(
        LaunchCheckSettingsCard(
          enabled: false,
          studioRate: null,
          onEnabled: calls.add,
          onStudioRate: calls.add,
        ),
      ),
    );
    expect(find.text('Check a project before opening it'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Not set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('48 kHz').last);
    await tester.pumpAndSettle();
    expect(calls, [true, 48000]);
  });

  testWidgets('no node Windows rejects', (tester) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await choose(tester, both);
    expect(binding.orphans, isEmpty);
    handle.dispose();
  });
}
