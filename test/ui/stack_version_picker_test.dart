import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/dialogs/stack_version_picker_dialog.dart';

import '../helpers/test_factories.dart';

/// Searching the "Add a version" picker (#94).
///
/// The list there can be the whole library, so it needs a search field. Path
/// matching earns its place because versions of a project are named almost
/// identically — the folder is often the only thing telling two candidates
/// apart, and typing it finds every version of one project at once.
void main() {
  MusicProject project(String id, String name, String path) =>
      TestFactories.makeProject(
        id: id,
        customDisplayName: name,
        filePath: path,
      );

  final alphaV1 = project('a1', 'Alpha v1', '/Music/Alpha/Alpha v1.als');
  final alphaV2 = project('a2', 'Alpha v2', '/Music/Alpha/Alpha v2.als');
  final beta = project('b1', 'Beta rough', '/Music/Beta/Beta rough.als');

  final all = [alphaV1, alphaV2, beta];

  test('an empty query returns everything', () {
    expect(filterStackCandidates(all, ''), all);
  });

  test('a whitespace-only query returns everything', () {
    // Not "nothing" — a stray space should never blank the list.
    expect(filterStackCandidates(all, '   '), all);
  });

  test('matches on the project name', () {
    expect(
      filterStackCandidates(all, 'beta').map((p) => p.id).toList(),
      ['b1'],
    );
  });

  test('matches on the folder, finding every version of one project', () {
    expect(
      filterStackCandidates(all, 'Alpha').map((p) => p.id).toList(),
      ['a1', 'a2'],
    );
  });

  test('is case-insensitive', () {
    expect(
      filterStackCandidates(all, 'BETA').map((p) => p.id).toList(),
      ['b1'],
    );
  });

  test('returns nothing when nothing matches', () {
    expect(filterStackCandidates(all, 'gamma'), isEmpty);
  });

  test('preserves the incoming order', () {
    // The caller sorts alphabetically before opening the dialog; filtering
    // must not reshuffle that.
    expect(
      filterStackCandidates(all, 'v').map((p) => p.id).toList(),
      ['a1', 'a2'],
    );
  });

  group('multi-select', () {
    Future<void> openPicker(
      WidgetTester tester, {
      required void Function(List<MusicProject>) onResult,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  onResult(
                    await showStackVersionMultiPickerDialog(
                      context,
                      title: 'Add versions',
                      candidates: all,
                      emptyLabel: 'Nothing to add',
                    ),
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
    }

    testWidgets('returns every ticked project', (tester) async {
      List<MusicProject>? result;
      await openPicker(tester, onResult: (r) => result = r);

      await tester.tap(find.text('Alpha v1'));
      await tester.tap(find.text('Beta rough'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add 2'));
      await tester.pumpAndSettle();

      expect(result?.map((p) => p.id).toList(), ['a1', 'b1']);
    });

    testWidgets('returns them in list order, not tick order', (tester) async {
      List<MusicProject>? result;
      await openPicker(tester, onResult: (r) => result = r);

      // Ticked bottom-up; the caller sorted the list, and the versions should
      // land on the stack in the order they were shown.
      await tester.tap(find.text('Beta rough'));
      await tester.tap(find.text('Alpha v1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add 2'));
      await tester.pumpAndSettle();

      expect(result?.map((p) => p.id).toList(), ['a1', 'b1']);
    });

    testWidgets('cannot confirm with nothing ticked', (tester) async {
      await openPicker(tester, onResult: (_) {});

      // Closing on a no-op would look like the add silently failed.
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add 0'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('cancel returns nothing', (tester) async {
      List<MusicProject>? result;
      await openPicker(tester, onResult: (r) => result = r);

      await tester.tap(find.text('Alpha v1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isEmpty);
    });

    testWidgets('select all takes only what the search is showing',
        (tester) async {
      List<MusicProject>? result;
      await openPicker(tester, onResult: (r) => result = r);

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add 2'));
      await tester.pumpAndSettle();

      // Searching then selecting everything found is the point of pairing
      // the two — it must not reach past the filter to Beta.
      expect(result?.map((p) => p.id).toList(), ['a1', 'a2']);
    });

    testWidgets('clear empties the selection', (tester) async {
      await openPicker(tester, onResult: (_) {});

      await tester.tap(find.text('Alpha v1'));
      await tester.pumpAndSettle();
      expect(find.text('Add 1'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Add 0'), findsOneWidget);
    });
  });
}
