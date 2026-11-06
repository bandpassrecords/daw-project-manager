import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:daw_project_manager/ui/widgets/plugin_filter_chip.dart';

import '../helpers/semantics_orphans.dart';

// The chip once sat only in a branch of the dashboard's action bar that never
// builds on desktop, so "Show these projects" filtered the list with nothing
// on screen to undo it. It now sits in the projects filter bar beside the MIDI
// toggle (which had been lost to the same branch); that placement is inside
// the dashboard, which needs Hive and can't be pumped here — what is tested
// is the chip itself.
void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();

  Future<List<String>> pump(WidgetTester tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              PluginFilterChip(
                label: 'Uses Serum',
                clearTooltip: 'Show all projects',
                onClear: () => calls.add('clear'),
              ),
            ],
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('says which plug-in the list is narrowed to', (tester) async {
    await pump(tester);
    expect(find.text('Uses Serum'), findsOneWidget);
    expect(find.byIcon(Icons.extension), findsOneWidget);
  });

  testWidgets('its × shows all projects again, and says so', (tester) async {
    final calls = await pump(tester);
    expect(find.byTooltip('Show all projects'), findsOneWidget);
    await tester.tap(find.byTooltip('Show all projects'));
    expect(calls, ['clear']);
  });

  testWidgets('a tap on the chip itself clears it too', (tester) async {
    final calls = await pump(tester);
    await tester.tap(find.text('Uses Serum'));
    expect(calls, ['clear']);
  });

  testWidgets('no node Windows rejects', (tester) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(await expectNoOrphanSemanticsWhileHovering(tester), 1);
    handle.dispose();
  });
}
