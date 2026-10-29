import 'dart:io';

import 'package:daw_project_manager/ui/widgets/semantics_safe.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/semantics_orphans.dart';

/// Semantics nodes nobody holds — what Windows' accessibility bridge rejects
/// with "Failed to update ui::AXTree, error: N will not be in the tree"
/// (flutter/flutter#182444, #190357). The check has to see the framework's
/// bug to be worth anything, so each case is tried bare first.
void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();
  setUp(binding.resetSemanticsRecord);

  group('tooltips side by side', () {
    Widget box(String text) =>
        SizedBox(width: 100, height: 100, child: Text(text));

    Widget app(Widget Function(String message, Widget child) tooltip) =>
        MaterialApp(
          home: Scaffold(
            body: ListView(children: [
              Row(children: [
                tooltip('Tooltip A', box('A')),
                const SizedBox(width: 16),
                tooltip('Tooltip B', box('B')),
              ]),
            ]),
          ),
        );

    testWidgets('two bare tooltips in one list item leave an orphan',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
          app((message, child) => Tooltip(message: message, child: child)));

      await expectLater(
        expectNoOrphanSemanticsWhileHovering(tester),
        throwsA(isA<TestFailure>()),
      );
      handle.dispose();
    });

    testWidgets('StandaloneTooltip leaves none', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app((message, child) =>
          StandaloneTooltip(message: message, child: child)));

      expect(await expectNoOrphanSemanticsWhileHovering(tester), 2);
      handle.dispose();
    });
  });

  group('a slider in a dialog', () {
    Future<void> openWith(WidgetTester tester, Widget slider) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    Dialog(child: SizedBox(width: 300, child: slider)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // Dragged too, so the value indicator shows.
      final drag = await tester.startGesture(tester.getCenter(find.byType(Slider)));
      await tester.pump(const Duration(milliseconds: 100));
      await drag.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await drag.up();
      await tester.pumpAndSettle();
    }

    testWidgets('a bare one leaves an orphan', (tester) async {
      final handle = tester.ensureSemantics();
      await openWith(tester, Slider(value: 0.3, onChanged: (_) {}));
      expect(binding.orphans, isNotEmpty);
      handle.dispose();
    });

    testWidgets('one in a SliderOverlay leaves none, and still drags',
        (tester) async {
      final handle = tester.ensureSemantics();
      var value = 0.3;
      await openWith(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SliderOverlay(
            child: Slider(
                value: value, onChanged: (v) => setState(() => value = v)),
          ),
        ),
      );
      expect(binding.orphans, isEmpty);
      expect(tester.getSize(find.byType(Slider)).width, 300);
      expect(value, greaterThan(0.3), reason: 'it still drags');
      handle.dispose();
    });
  });

  // The rules above, held for all of lib/: a slider is in a SliderOverlay,
  // and a tooltip around plain content (no button forming a node of its own
  // under it) is a StandaloneTooltip.
  group('lib/', () {
    final helper = p.normalize(p.join('lib', 'ui', 'widgets', 'semantics_safe.dart'));
    final sources = {
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            p.normalize(entity.path) != helper)
          entity.path: entity.readAsStringSync(),
    };
    String where(String path, String source, int offset) =>
        '$path:${'\n'.allMatches(source.substring(0, offset)).length + 1}';

    test('every Slider is in a SliderOverlay', () {
      final bare = <String>[];
      for (final MapEntry(key: path, value: source) in sources.entries) {
        for (final m in RegExp(r'(?<![\w.])Slider\(').allMatches(source)) {
          final before = source.substring(0, m.start).trimRight();
          if (!RegExp(r'SliderOverlay\(\s*child:$').hasMatch(before)) {
            bare.add(where(path, source, m.start));
          }
        }
      }
      expect(bare, isEmpty, reason: 'wrap it in SliderOverlay (semantics_safe.dart)');
    });

    test('no plain Tooltip wraps content that forms no node', () {
      const plain = {
        'Text', 'Text.rich', 'Icon', 'Container', 'Padding', 'Row',
        'MouseRegion', 'OnArtMarker', 'ConstrainedBox', 'SizedBox',
        'DecoratedBox', 'Image', 'Chip',
      };
      final childOf = RegExp(r'child:\s*(?:const\s+)?([\w.]+)');
      final found = <String>[];
      for (final MapEntry(key: path, value: source) in sources.entries) {
        for (final m in RegExp(r'(?<![\w.])Tooltip\(').allMatches(source)) {
          final child = childOf.firstMatch(_topLevelArgs(source, m.end));
          if (child != null && plain.contains(child.group(1))) {
            found.add('${where(path, source, m.start)} (${child.group(1)})');
          }
        }
      }
      expect(found, isEmpty,
          reason: 'use StandaloneTooltip (semantics_safe.dart)');
    });
  });
}

/// The arguments of the call opened just before [start], with everything
/// nested inside them blanked out, so `child:` is the call's own.
String _topLevelArgs(String source, int start) {
  final out = StringBuffer();
  var depth = 0;
  for (var i = start; i < source.length; i++) {
    final c = source[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) break;
      depth--;
    } else if (depth == 0) {
      out.write(c);
    }
  }
  return out.toString();
}
