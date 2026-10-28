import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A semantics node the framework sent that no node in the tree holds.
///
/// Windows' accessibility bridge refuses the whole update over one of these —
/// "Failed to update ui::AXTree, error: N will not be in the tree and is not
/// the new root" — and its tree then stays stale for the life of the window;
/// in a release build a later update can kill the process outright
/// (flutter/flutter#182444). Flutter 3.47 sends one when two `OverlayPortal`
/// anchors (two tooltips, or a tooltip and a menu) end up merged into one
/// semantics node: the second anchor's overlay is serialized with no parent.
class SemanticsOrphan {
  final int id;
  final String label;
  final String tooltip;
  final int traversalParent;

  const SemanticsOrphan(this.id, this.label, this.tooltip, this.traversalParent);

  @override
  String toString() => 'node $id (label: "$label", tooltip: "$tooltip", '
      'traversalParent: $traversalParent) is in no node\'s children';
}

/// A test binding that keeps the semantics tree the way the engine does —
/// every update applied on top of the last, unreachable nodes dropped — and
/// records every node an update sends that the tree, after it, doesn't reach.
///
/// Call `SemanticsOrphanBinding.ensureInitialized()` first thing in a test
/// file's `main`, then `tester.ensureSemantics()` in each test.
class SemanticsOrphanBinding extends AutomatedTestWidgetsFlutterBinding {
  static SemanticsOrphanBinding? _instance;

  SemanticsOrphanBinding._();

  static SemanticsOrphanBinding ensureInitialized() =>
      _instance ??= SemanticsOrphanBinding._();

  final Map<int, List<int>> _children = {};
  final List<SemanticsOrphan> orphans = [];

  /// Forgets the tree and what was found; each test starts from nothing.
  void resetSemanticsRecord() {
    _children.clear();
    orphans.clear();
  }

  @override
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() =>
      _RecordingSemanticsUpdateBuilder(this);

  void _apply(Map<int, _SentNode> sent) {
    for (final node in sent.values) {
      _children[node.id] = node.children;
    }
    final reached = <int>{};
    final pending = <int>[0];
    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      if (!reached.add(id)) continue;
      pending.addAll(_children[id] ?? const []);
    }
    for (final node in sent.values) {
      if (node.id != 0 && !reached.contains(node.id)) {
        orphans.add(SemanticsOrphan(
            node.id, node.label, node.tooltip, node.traversalParent));
      }
    }
    _children.removeWhere((id, _) => !reached.contains(id));
  }
}

class _SentNode {
  final int id;
  final List<int> children;
  final String label;
  final String tooltip;
  final int traversalParent;

  _SentNode(this.id, this.children, this.label, this.tooltip,
      this.traversalParent);
}

/// Records what is sent, by name, so it keeps working when the engine adds a
/// parameter to `updateNode`; the update it builds is empty.
class _RecordingSemanticsUpdateBuilder implements ui.SemanticsUpdateBuilder {
  final SemanticsOrphanBinding _binding;
  final Map<int, _SentNode> _sent = {};

  _RecordingSemanticsUpdateBuilder(this._binding);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.namedArguments;
    if (invocation.memberName == #updateNode) {
      final id = args[#id] as int;
      _sent[id] = _SentNode(
        id,
        List<int>.of(args[#childrenInTraversalOrder] as Int32List),
        args[#label] as String? ?? '',
        args[#tooltip] as String? ?? '',
        args[#traversalParent] as int? ?? -1,
      );
      return null;
    }
    if (invocation.memberName == #build) {
      _binding._apply(_sent);
      return ui.SemanticsUpdateBuilder().build();
    }
    return null;
  }
}

/// Every tooltip, from `material_ui` or from the SDK's own Material (which
/// trina_grid still builds with): the two are different classes of one name.
final Finder _tooltips = find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == 'Tooltip',
    description: 'Tooltip');

/// Hovers the mouse over every tooltip on screen, one after another — the
/// way a pointer crossing a toolbar shows each in turn — and fails with each
/// orphan any of it sent. A tooltip that orphans its overlay only does so
/// once shown. Returns how many tooltips it hovered, so a test can tell it
/// looked at something.
Future<int> expectNoOrphanSemanticsWhileHovering(
  WidgetTester tester, {
  Finder? within,
}) async {
  final binding = tester.binding as SemanticsOrphanBinding;
  final tooltips = within == null
      ? _tooltips
      : find.descendant(of: within, matching: _tooltips);
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  final found = <String>[];
  final count = tooltips.evaluate().length;
  var hovered = 0;
  for (var i = 0; i < count; i++) {
    final target = tooltips.at(i);
    final box = tester.renderObject(target) as RenderBox;
    if (!box.hasSize || box.size.isEmpty) continue;
    hovered++;
    await mouse.moveTo(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 1));
    if (binding.orphans.isNotEmpty) {
      final message = (tester.widget(target) as dynamic).message ?? '?';
      found.add('hovering tooltip "$message": ${binding.orphans.join('; ')}');
      binding.orphans.clear();
    }
  }
  await mouse.removePointer();
  await tester.pump(const Duration(seconds: 2));
  expect(found, isEmpty,
      reason: 'semantics nodes Windows\' accessibility bridge would reject');
  return hovered;
}
