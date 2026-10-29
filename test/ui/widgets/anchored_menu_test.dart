import 'package:daw_project_manager/ui/widgets/anchored_menu.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/semantics_orphans.dart';

void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();
  late BuildContext host;
  Future<String?>? pending;

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          host = context;
          return const SizedBox.expand();
        }),
      ),
    ));
  }

  void open({Offset at = const Offset(120, 80)}) {
    pending = showAnchoredMenu<String>(
      context: host,
      position: at,
      builder: (choose) => [
        MenuItemButton(onPressed: () => choose('one'), child: const Text('One')),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
                onPressed: () => choose('deep'), child: const Text('Deep')),
          ],
          child: const Text('More'),
        ),
      ],
    );
  }

  testWidgets('opens where it was asked and returns the item chosen',
      (tester) async {
    await pumpHost(tester);
    open();
    await tester.pumpAndSettle();

    final one = tester.getTopLeft(find.text('One'));
    expect(one.dx, greaterThanOrEqualTo(120));
    expect(one.dy, greaterThanOrEqualTo(80));

    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    expect(await pending, 'one');
    expect(find.text('One'), findsNothing, reason: 'the menu is gone');
  });

  testWidgets('an item in a submenu is chosen the same way', (tester) async {
    await pumpHost(tester);
    open();
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deep'));
    await tester.pumpAndSettle();
    expect(await pending, 'deep');
  });

  testWidgets('closing without a choice returns null', (tester) async {
    await pumpHost(tester);
    open();
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(await pending, isNull);
    expect(find.text('One'), findsNothing);
  });

  // Its anchor once had no size, so it formed no semantics node and the menu
  // went to the engine with no parent: Windows' accessibility bridge rejected
  // every update while a project's right-click menu was open.
  testWidgets('the open menu hangs from a node, as Windows needs',
      (tester) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await pumpHost(tester);
    open();
    await tester.pumpAndSettle();

    expect(find.text('One'), findsOneWidget);
    expect(binding.orphans, isEmpty);
    handle.dispose();
  });
}

