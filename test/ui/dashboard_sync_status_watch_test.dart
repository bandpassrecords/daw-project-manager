import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The dashboard page is one huge build — the projects table included. It
/// watched the whole Drive sync status for one rail label, so every status
/// change (the refresh after each sync, the automatic sync at launch)
/// rebuilt the page and laid the table out again: 2,000 render objects
/// repainted at once, found by `integration_test/perf/player_repaint_test`.
/// It may only watch the parts it shows, through `select`.
///
/// What can't be automated here: the page itself can't be pumped in a
/// widget test (it opens Hive), so this reads its source.
void main() {
  test('the dashboard page watches the sync status only through select', () {
    final source = File('lib/ui/dashboard_page.dart').readAsStringSync();
    final whole = RegExp(r'watch\(\s*driveSyncStatusProvider\s*,?\s*\)');
    expect(
      whole.allMatches(source).map((m) {
        final line = source.substring(0, m.start).split('\n').length;
        return 'lib/ui/dashboard_page.dart:$line';
      }),
      isEmpty,
    );
  });
}
