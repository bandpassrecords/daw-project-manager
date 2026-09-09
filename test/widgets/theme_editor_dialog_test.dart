import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/custom_theme.dart';
import 'package:daw_project_manager/providers/theme_provider.dart';
import 'package:daw_project_manager/ui/dialogs/color_picker_dialog.dart';
import 'package:daw_project_manager/ui/dialogs/theme_editor_dialog.dart';

/// Widget coverage for the theme editor (#148).
void main() {
  final draft = CustomTheme(
    id: 'draft-1',
    name: 'Studio Amber',
    brightness: Brightness.dark,
    primary: const Color(0xFFFFCA28),
    secondary: const Color(0xFFFF7043),
    background: const Color(0xFF14161A),
    card: const Color(0xFF232529),
    updatedAt: DateTime(2026, 1, 1),
  );

  Future<CustomTheme?> openEditor(
    WidgetTester tester, {
    required CustomTheme initial,
    bool isNew = false,
  }) async {
    CustomTheme? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showThemeEditorDialog(
                  context,
                  draft: initial,
                  isNew: isNew,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('shows the theme name and its colors', (tester) async {
    await openEditor(tester, initial: draft);

    expect(find.text('Studio Amber'), findsOneWidget);
    // Colors are shown as hex next to each swatch.
    expect(find.text('#FFCA28'), findsOneWidget);
    expect(find.text('#FF7043'), findsOneWidget);
    expect(find.text('#14161A'), findsOneWidget);
    expect(find.text('#232529'), findsOneWidget);
  });

  testWidgets('an unset secondary accent shows the primary as its fallback',
      (tester) async {
    await openEditor(
      tester,
      initial: CustomTheme(
        id: 'no-secondary',
        name: 'No secondary',
        brightness: Brightness.dark,
        primary: const Color(0xFFFFCA28),
        background: const Color(0xFF14161A),
        card: const Color(0xFF232529),
      ),
    );

    // Accent and Secondary accent rows both read the primary hex, matching
    // what ColorScheme.fromSeed would derive from.
    expect(find.text('#FFCA28'), findsNWidgets(2));
  });

  testWidgets('saving returns the edited theme', (tester) async {
    CustomTheme? saved;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                saved = await showThemeEditorDialog(
                  context,
                  draft: draft,
                  isNew: false,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Renamed');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.name, 'Renamed');
    expect(saved!.id, 'draft-1');
  });

  testWidgets('cancelling returns nothing', (tester) async {
    CustomTheme? saved;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                saved = await showThemeEditorDialog(
                  context,
                  draft: draft,
                  isNew: false,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(saved, isNull);
  });

  testWidgets('an empty name blocks saving and shows why', (tester) async {
    await openEditor(
      tester,
      initial: draft.copyWith(name: ''),
      isNew: true,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Give the theme a name.'), findsOneWidget);
    // Still open — the dialog didn't pop.
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
  });

  testWidgets('a low-contrast pairing warns without blocking', (tester) async {
    // Body text on a card this close to white is unreadable.
    await openEditor(
      tester,
      initial: draft.copyWith(card: const Color(0xFFEEEEEE)),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
    // Warning only: Save is still there and still enabled.
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNotNull);
  });

  testWidgets('a readable theme shows no warning', (tester) async {
    await openEditor(tester, initial: draft);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('the live preview is built from the draft, not the app theme',
      (tester) async {
    await openEditor(tester, initial: draft);

    // The preview wraps its sample widgets in the draft's own ThemeData.
    final themes = tester.widgetList<Theme>(find.byType(Theme));
    expect(
      themes.any((t) => t.data.cardColor == draft.card),
      isTrue,
      reason: 'expected a Theme carrying the draft card color',
    );
  });

  group('parseHexColor', () {
    test('accepts #RRGGBB with and without the hash', () {
      expect(parseHexColor('#1E1F22'), const Color(0xFF1E1F22));
      expect(parseHexColor('1e1f22'), const Color(0xFF1E1F22));
    });

    test('expands the 3-digit shorthand', () {
      expect(parseHexColor('#0AF'), const Color(0xFF00AAFF));
    });

    test('rejects anything else instead of throwing', () {
      expect(parseHexColor(''), isNull);
      expect(parseHexColor('#12345'), isNull);
      expect(parseHexColor('#GGGGGG'), isNull);
      expect(parseHexColor('rebeccapurple'), isNull);
    });
  });

  test('AppThemes.buildFrom drives the preview from the draft', () {
    final built = AppThemes.buildFrom(draft);
    expect(built.cardColor, draft.card);
    expect(built.scaffoldBackgroundColor, draft.background);
    expect(built.colorScheme.primary, draft.primary);
  });
}
