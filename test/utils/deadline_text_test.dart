import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/utils/deadline_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A deadline and a project's age, in the user's language. The model used to
/// word them itself, in English — "3 days left", "1 month, 15 days" — and the
/// projects table, both players and the text export showed that in every
/// language.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));

  group('deadlineText', () {
    test('late, today, left', () {
      expect(deadlineText(en, -2), '2d late');
      expect(deadlineText(en, 0), 'Due today');
      expect(deadlineText(en, 5), '5d left');
      expect(deadlineText(en, 45), '45d left');
    });

    test('in the user\'s language', () {
      expect(deadlineText(de, 5), '5T übrig');
      expect(deadlineText(de, -2), '2T verspätet');
    });
  });

  group('ageText', () {
    String age(Duration d) => ageText(en, d, underAnHour: en.ageJustNow);

    test('under an hour says what the caller asks', () {
      expect(age(const Duration(minutes: 20)), en.ageJustNow);
      expect(ageText(en, const Duration(minutes: 20), underAnHour: en.ageLessThanHour), en.ageLessThanHour);
    });

    test('hours, days, months and years, singular and plural', () {
      expect(age(const Duration(hours: 1)), '1 hour');
      expect(age(const Duration(hours: 5)), '5 hours');
      expect(age(const Duration(days: 5)), '5 days');
      expect(age(const Duration(days: 30)), '1 month');
      expect(age(const Duration(days: 45)), '1 month, 15 days');
      expect(age(const Duration(days: 365)), '1 year');
      expect(age(const Duration(days: 400)), '1 year, 1 month');
    });

    test('in the user\'s language', () {
      expect(ageText(de, const Duration(days: 45), underAnHour: de.ageJustNow), '1 Monat, 15 Tage');
    });
  });
}
