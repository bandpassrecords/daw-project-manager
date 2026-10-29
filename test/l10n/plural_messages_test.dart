import 'dart:convert';
import 'dart:io';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Counts are worded by each language's own plural rules (ICU `plural`),
/// never by an English "s" handed in from the code: that read "3 Dateis" in
/// German, "3 ファイルs" in Japanese and "не удалосьs" in Russian.
void main() {
  const locales = ['en', 'pt', 'es', 'fr', 'it', 'de', 'ru', 'ja', 'zh'];

  test('no message takes a plural suffix from the code', () {
    final suffix = RegExp(r'plural', caseSensitive: false);
    for (final locale in locales) {
      final arb = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;
      for (final MapEntry(:key, :value) in arb.entries) {
        if (key.startsWith('@') && value is Map && value['placeholders'] is Map) {
          final names = (value['placeholders'] as Map).keys.where((p) => suffix.hasMatch(p as String));
          expect(names, isEmpty, reason: 'app_$locale.arb $key has a suffix placeholder: $names');
        }
        if (!key.startsWith('@') && value is String) {
          // A {plural} with no ICU around it is a suffix the code fills in.
          expect(value.contains('{plural}'), isFalse, reason: 'app_$locale.arb $key: $value');
        }
      }
    }
  });

  test('no English plural ending is built in the code', () {
    // File names are English on purpose (they are read in a DAW's browser,
    // like the MIDI exports' names): the only place an "s" may be added.
    const allowed = {'lib/services/midi/melodic_midi_export.dart'};
    final suffix = RegExp(r"\?\s*'s'\s*:\s*''|\?\s*''\s*:\s*'s'");
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || path.startsWith('lib/generated/') || allowed.contains(path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (suffix.hasMatch(lines[i])) offenders.add('$path:${i + 1}: ${lines[i].trim()}');
      }
    }
    expect(offenders, isEmpty,
        reason: 'word counts with an ICU plural in the ARB files, never an English "s"');
  });

  group('counts read right', () {
    AppLocalizations l(String locale) => lookupAppLocalizations(Locale(locale));

    test('English', () {
      expect(l('en').projectsSelected(1), '1 project selected');
      expect(l('en').projectsSelected(3), '3 projects selected');
      expect(l('en').ageYearsMonths(1, 2), '1 year, 2 months');
      expect(l('en').statusChangedForProjectsWithErrors(1, 2, 'Mixing'),
          'Phase changed to "Mixing" for 1 project, 2 failed');
    });

    test('German', () {
      expect(l('de').addedFilesToRelease(3), '3 Dateien zur Veröffentlichung hinzugefügt.');
      expect(l('de').addedFilesToRelease(1), '1 Datei zur Veröffentlichung hinzugefügt.');
      expect(l('de').ageDays(2), '2 Tage');
    });

    test('Portuguese (Brazil)', () {
      expect(l('pt').nFilesSavedTo(2, 'x.zip'), '2 arquivos salvos em x.zip');
      expect(l('pt').ageMonths(1), '1 mês');
      expect(l('pt').extractionFailures(2), '2 falharam.');
      // Was "há {count} ano{plural}" with the suffix always empty: "há 3 ano".
      expect(l('pt').dateYearsAgo(3), 'há 3 anos');
      expect(l('pt').dateYearsAgo(1), 'há 1 ano');
    });

    test('Russian, with its three forms', () {
      expect(l('ru').projectsSelected(1), 'Выбран 1 проект');
      expect(l('ru').projectsSelected(3), 'Выбрано 3 проекта');
      expect(l('ru').projectsSelected(5), 'Выбрано 5 проектов');
      expect(l('ru').projectsSelected(21), 'Выбран 21 проект');
    });

    test('Japanese and Chinese have no plural ending', () {
      expect(l('ja').downloadNFiles(3), '3個のファイルをダウンロード');
      expect(l('zh').releasesDeleted(3), '已删除3个发布');
    });

    test('French counts zero as singular', () {
      expect(l('fr').templatesDeleted(0), '0 modèle supprimé');
      expect(l('fr').templatesDeleted(2), '2 modèles supprimés');
    });
  });
}
