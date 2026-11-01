import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  // plugin-pin.yml rewrites this file with a release tag and compares it with
  // the newest release, and release.yml checks the plugin out at it.
  test('plugin_ref names one plugin release (a tag, or a full commit)', () {
    final text = File(p.join('test', 'plugin_integration', 'plugin_ref'))
        .readAsStringSync();
    final ref = text.trim();

    expect(ref, matches(RegExp(r'^(v\d+\.\d+\.\d+|[0-9a-f]{40})$')));
    expect(text, ref + '\n', reason: 'one line, nothing around it');
  });

  test('the workflow that moves the pin is there, and release.yml reads the file', () {
    final bump = File(p.join('.github', 'workflows', 'plugin-pin.yml')).readAsStringSync();
    final ci = File(p.join('.github', 'workflows', 'release.yml')).readAsStringSync();

    expect(bump, contains('test/plugin_integration/plugin_ref'));
    expect(ci, contains('test/plugin_integration/plugin_ref'));
  });
}
