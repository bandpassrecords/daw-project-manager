import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/session_actions.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

import '../helpers/test_factories.dart';

// Avoids WorkTimerNotifier's real build(), which listens to
// activeProjectProvider and reaches into repositoryProvider/Hive and starts a
// periodic Timer — none of which are needed to exercise the dialog logic in
// session_actions.dart, and all of which would require a full Hive test
// harness to run safely.
class _FakeWorkTimerNotifier extends WorkTimerNotifier {
  @override
  int build() => 0;
}

// The real one reads the mode from Hive.
class _FakeSessionModeNotifier extends SessionModeNotifier {
  _FakeSessionModeNotifier(this.initial);
  final bool initial;

  @override
  bool build() => initial;
}

Future<void> _pumpHost(WidgetTester tester, {bool sessionMode = false}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allProjectsStreamProvider.overrideWith((ref) => Stream.value(const <MusicProject>[])),
        workTimerProvider.overrideWith(_FakeWorkTimerNotifier.new),
        sessionModeProvider.overrideWith(
          () => _FakeSessionModeNotifier(sessionMode),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final active = ref.watch(activeProjectProvider);
              return Column(
                children: [
                  Text('active: ${active?.id ?? 'none'}'),
                  TextButton(
                    onPressed: () => confirmStartSession(
                        context, ref, TestFactories.makeProject(id: 'p1')),
                    child: const Text('start p1'),
                  ),
                  TextButton(
                    onPressed: () => confirmStartSession(
                        context, ref, TestFactories.makeProject(id: 'p2')),
                    child: const Text('start p2'),
                  ),
                  TextButton(
                    onPressed: () => confirmEndSession(context, ref),
                    child: const Text('end'),
                  ),
                  TextButton(
                    onPressed: () => launchProjectInDaw(
                      context,
                      ref,
                      TestFactories.makeProject(id: 'missing'),
                    ),
                    child: const Text('launch missing'),
                  ),
                  TextButton(
                    onPressed: () => launchProjectAfterConfirming(
                      context,
                      ref,
                      TestFactories.makeProject(
                        id: 'missing',
                        customDisplayName: 'My Song',
                      ),
                    ),
                    child: const Text('press O'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('confirmStartSession', () {
    testWidgets('no active project — confirming sets the active project',
        (tester) async {
      await _pumpHost(tester);
      expect(find.text('active: none'), findsOneWidget);

      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();

      // Simple start dialog, not the switch dialog.
      expect(find.text('Switch session'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();

      expect(find.text('active: p1'), findsOneWidget);
    });

    testWidgets('no active project — cancelling leaves no active project',
        (tester) async {
      await _pumpHost(tester);

      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('active: none'), findsOneWidget);
    });

    testWidgets(
        'another session already active — shows switch dialog and confirming switches',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();
      expect(find.text('active: p1'), findsOneWidget);

      await tester.tap(find.text('start p2'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Switch session'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Switch session'));
      await tester.pumpAndSettle();

      expect(find.text('active: p2'), findsOneWidget);
    });

    testWidgets(
        'another session already active — cancelling the switch keeps the original project',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('start p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('active: p1'), findsOneWidget);
    });
  });

  group('launchProjectInDaw', () {
    testWidgets(
      'project file does not exist — shows "File missing" and never touches the DAW-launch path',
      (tester) async {
        await _pumpHost(tester);

        await tester.tap(find.text('launch missing'));
        await tester.pumpAndSettle();

        expect(find.text('File missing.'), findsOneWidget);
      },
    );
  });

  group('launchProjectAfterConfirming', () {
    testWidgets('nothing launches until the dialog is answered', (tester) async {
      await _pumpHost(tester);

      await tester.tap(find.text('press O'));
      await tester.pumpAndSettle();

      expect(find.text('Open this project?'), findsOneWidget);
      expect(find.text('"My Song" will open in its DAW.'), findsOneWidget);
      expect(find.text('File missing.'), findsNothing);
    });

    testWidgets('confirming launches', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('press O'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Launch in DAW'));
      await tester.pumpAndSettle();

      expect(find.text('File missing.'), findsOneWidget);
    });

    testWidgets('Enter confirms, the launch button having the keyboard', (
      tester,
    ) async {
      await _pumpHost(tester);
      await tester.tap(find.text('press O'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('File missing.'), findsOneWidget);
    });

    testWidgets('cancelling does not launch', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('press O'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Open this project?'), findsNothing);
      expect(find.text('File missing.'), findsNothing);
    });

    testWidgets('Esc does not launch', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('press O'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Open this project?'), findsNothing);
      expect(find.text('File missing.'), findsNothing);
    });

    testWidgets('in session mode there is nothing to ask', (tester) async {
      await _pumpHost(tester, sessionMode: true);

      await tester.tap(find.text('press O'));
      await tester.pumpAndSettle();

      expect(find.text('Open this project?'), findsNothing);
      expect(find.text('File missing.'), findsNothing);
    });
  });

  group('resolveDawLaunchAction', () {
    test('no DAW type → always the OS default handler', () {
      for (final linux in [true, false]) {
        expect(
          resolveDawLaunchAction(
            dawType: null,
            configuredPaths: const ['/opt/whatever'],
            existingPaths: const ['/opt/whatever'],
            isLinux: linux,
          ),
          DawLaunchAction.systemDefault,
        );
      }
    });

    test('one override configured and present → run it (every platform)', () {
      for (final linux in [true, false]) {
        expect(
          resolveDawLaunchAction(
            dawType: 'Ableton Live',
            configuredPaths: const ['/Applications/Ableton Live.app'],
            existingPaths: const ['/Applications/Ableton Live.app'],
            isLinux: linux,
          ),
          DawLaunchAction.useOverride,
        );
      }
    });

    test('two or more overrides resolve → ask which one', () {
      expect(
        resolveDawLaunchAction(
          dawType: 'Ableton Live',
          configuredPaths: const ['/a/Live 11.app', '/a/Live 12.app'],
          existingPaths: const ['/a/Live 11.app', '/a/Live 12.app'],
          isLinux: false,
        ),
        DawLaunchAction.chooseOverride,
      );
    });

    test('several configured but only one resolves → run that one', () {
      expect(
        resolveDawLaunchAction(
          dawType: 'Ableton Live',
          configuredPaths: const ['/a/Live 11.app', '/gone/Live 12.app'],
          existingPaths: const ['/a/Live 11.app'],
          isLinux: false,
        ),
        DawLaunchAction.useOverride,
      );
    });

    test('overrides configured but none resolve → open the "missing" dialog', () {
      for (final linux in [true, false]) {
        expect(
          resolveDawLaunchAction(
            dawType: 'Ableton Live',
            configuredPaths: const ['/gone/a.exe', '/gone/b.exe'],
            existingPaths: const [],
            isLinux: linux,
          ),
          DawLaunchAction.overrideMissing,
        );
      }
    });

    test('no override on Linux → prompt to configure one up front', () {
      expect(
        resolveDawLaunchAction(
          dawType: 'Bitwig Studio',
          configuredPaths: const [],
          existingPaths: const [],
          isLinux: true,
        ),
        DawLaunchAction.promptConfigure,
      );
    });

    test('no override on Windows/macOS → try the OS default first', () {
      expect(
        resolveDawLaunchAction(
          dawType: 'Logic Pro',
          configuredPaths: const [],
          existingPaths: const [],
          isLinux: false,
        ),
        DawLaunchAction.systemDefault,
      );
    });
  });

  group('shouldPromptDawLocationAfterFailedLaunch', () {
    test('offered on Windows/macOS when the DAW type is known', () {
      expect(
        shouldPromptDawLocationAfterFailedLaunch(
          dawType: 'Logic Pro',
          isMacOS: true,
          isWindows: false,
        ),
        isTrue,
      );
      expect(
        shouldPromptDawLocationAfterFailedLaunch(
          dawType: 'Cubase',
          isMacOS: false,
          isWindows: true,
        ),
        isTrue,
      );
    });

    test('not offered without a DAW type', () {
      expect(
        shouldPromptDawLocationAfterFailedLaunch(
          dawType: null,
          isMacOS: true,
          isWindows: false,
        ),
        isFalse,
      );
    });

    test('not offered on Linux (it already prompts before launching) or mobile',
        () {
      expect(
        shouldPromptDawLocationAfterFailedLaunch(
          dawType: 'Bitwig Studio',
          isMacOS: false,
          isWindows: false,
        ),
        isFalse,
      );
    });
  });

  group('confirmEndSession', () {
    testWidgets('no active project — does nothing (no dialog)',
        (tester) async {
      await _pumpHost(tester);

      await tester.tap(find.text('end'));
      await tester.pumpAndSettle();

      expect(find.text('End session'), findsNothing);
      expect(find.text('active: none'), findsOneWidget);
    });

    testWidgets('active project — confirming clears the active project',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();
      expect(find.text('active: p1'), findsOneWidget);

      await tester.tap(find.text('end'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'End session'));
      await tester.pumpAndSettle();

      expect(find.text('active: none'), findsOneWidget);
    });

    testWidgets('active project — cancelling leaves the session active',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('end'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('active: p1'), findsOneWidget);
    });
  });
}
