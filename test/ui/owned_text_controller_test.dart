import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/ui/widgets/owned_text_controller.dart';

Widget _app(Future<void> Function(BuildContext) onOpen) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => onOpen(context),
        child: const Text('open'),
      ),
    ),
  ),
);

Widget _dialog(BuildContext ctx, TextEditingController controller) =>
    AlertDialog(
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('Save'),
        ),
      ],
    );

void main() {
  for (final button in ['Cancel', 'Save']) {
    testWidgets('a dialog owning its controller closes cleanly ($button)',
        (tester) async {
      String? result = 'unset';
      await tester.pumpWidget(_app((context) async {
        result = await showDialog<String>(
          context: context,
          builder: (ctx) => OwnedTextController(
            text: 'Kick',
            builder: (_, controller) => _dialog(ctx, controller),
          ),
        );
      }));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Kick'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Kick too loud');
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(result, button == 'Save' ? 'Kick too loud' : isNull);
    });
  }

  // The add-todo dialog on the player bar (and three more) made the
  // controller before showDialog and disposed it as soon as it returned:
  // the closing animation still drew the field, and every close threw "A
  // TextEditingController was used after being disposed" — seen in the real
  // app by integration_test/perf/player_repaint_test.dart.
  test('no dialog in lib/ disposes its controller as soon as it returns', () {
    final offenders = <String>[];
    final call = RegExp(r'await show(Dialog|ModalBottomSheet|GeneralDialog)\b');
    for (final file
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final m in call.allMatches(source)) {
        final open = source.indexOf('(', m.end);
        if (open < 0) continue;
        var depth = 0, i = open;
        for (; i < source.length; i++) {
          if (source[i] == '(') depth++;
          if (source[i] == ')' && --depth == 0) break;
        }
        final after = source.substring(i + 1, (i + 200).clamp(0, source.length));
        if (RegExp(r'^\s*;\s*\w+\.dispose\(\);').hasMatch(after)) {
          final line = '\n'.allMatches(source.substring(0, m.start)).length + 1;
          offenders.add('${p.normalize(file.path)}:$line');
        }
      }
    }
    expect(offenders, isEmpty);
  });

}
