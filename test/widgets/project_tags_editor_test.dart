import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/project_tags_editor.dart';

/// #109 — the tag editor on the project page. Plain values in, callbacks out,
/// so the saving itself is the page's business and not tested here.
void main() {
  late List<String> added;
  late List<String> removed;

  setUp(() {
    added = [];
    removed = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    List<String> tags = const [],
    List<String> suggestions = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ProjectTagsEditor(
              tags: tags,
              suggestions: suggestions,
              hintText: 'Add a tag…',
              removeTooltip: (tag) => 'Remove $tag',
              onAdd: added.add,
              onRemove: removed.add,
            ),
          ),
        ),
      ),
    );
  }

  Finder field() => find.byKey(const ValueKey('tag-input'));

  testWidgets('shows each tag as a chip', (tester) async {
    await pump(tester, tags: ['trap', '🔥🔥🔥']);

    expect(find.byType(InputChip), findsNWidgets(2));
    expect(find.text('trap'), findsOneWidget);
    expect(find.text('🔥🔥🔥'), findsOneWidget);
  });

  testWidgets('Enter adds exactly what was typed and clears the field', (
    tester,
  ) async {
    // "tr" must not be swapped for the "trap" suggestion: a user typing a
    // new, shorter tag would otherwise never be able to enter it.
    await pump(tester, suggestions: ['trap']);

    await tester.enterText(field(), 'tr');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(added, ['tr']);
    expect(tester.widget<TextField>(field()).controller!.text, isEmpty);
  });

  testWidgets('a blank entry adds nothing', (tester) async {
    await pump(tester);

    await tester.enterText(field(), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(added, isEmpty);
  });

  testWidgets('picking a suggestion adds it', (tester) async {
    await pump(tester, suggestions: ['for the Luna EP', 'trap']);

    await tester.enterText(field(), 'luna');
    await tester.pumpAndSettle();
    await tester.tap(find.text('for the Luna EP'));
    await tester.pumpAndSettle();

    expect(added, ['for the Luna EP']);
  });

  testWidgets('the delete icon on a chip removes that tag', (tester) async {
    await pump(tester, tags: ['trap', 'house']);

    await tester.tap(find.byTooltip('Remove house'));
    await tester.pump();

    expect(removed, ['house']);
  });

  group('suggestionsFor', () {
    test('offers nothing for an empty query', () {
      expect(
        ProjectTagsEditor.suggestionsFor(
          query: ' ',
          suggestions: ['trap'],
          current: const [],
        ),
        isEmpty,
      );
    });

    test('skips tags the project already has, ignoring case', () {
      expect(
        ProjectTagsEditor.suggestionsFor(
          query: 'tr',
          suggestions: ['Trap', 'trance'],
          current: ['trap'],
        ),
        ['trance'],
      );
    });

    test('puts prefix matches before inner matches', () {
      expect(
        ProjectTagsEditor.suggestionsFor(
          query: 'ap',
          suggestions: ['trap', 'apex'],
          current: const [],
        ),
        ['apex', 'trap'],
      );
    });

    test('offers at most maxSuggestions', () {
      final many = [for (var i = 0; i < 20; i++) 'tag$i'];

      expect(
        ProjectTagsEditor.suggestionsFor(
          query: 'tag',
          suggestions: many,
          current: const [],
        ),
        hasLength(ProjectTagsEditor.maxSuggestions),
      );
    });
  });
}
