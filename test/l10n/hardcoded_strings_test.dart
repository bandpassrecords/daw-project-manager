import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Source-level guards for strings CLAUDE.md requires to go through
/// AppLocalizations, where the screen showing them is too tied to Hive and
/// Riverpod to render in a widget test. The profile page shipped its save
/// dialogs' titles and its file list's "Press kit file" / "File not found"
/// in English for every locale.
void main() {
  List<File> dartFilesUnder(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !p.split(f.path).contains('generated'))
      .toList();

  test("no file picker's dialogTitle is a string literal", () {
    // The OS shows this title on its save/open dialog, so it's UI text.
    final literal = RegExp(r'''dialogTitle:\s*['"]''');
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (literal.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Use AppLocalizations for dialogTitle:\n${offenders.join('\n')}');
  });

  test("the profile page's file list labels are localized", () {
    final source =
        File(p.join('lib', 'ui', 'profile_edit_page.dart')).readAsStringSync();
    expect(source, isNot(contains("'Press kit file'")));
    expect(source, isNot(contains("'File not found'")));
  });
}
