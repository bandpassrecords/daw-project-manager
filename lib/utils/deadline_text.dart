import '../generated/l10n/app_localizations.dart';

/// A deadline [daysUntil] days away, in words: "3d late", "Due today",
/// "12d left" — what the projects table's Deadline badge says, so the table,
/// the players and the text export can't disagree. The model used to carry
/// an English "3 days left" of its own, shown untranslated in every language.
String deadlineText(AppLocalizations l10n, int daysUntil) {
  if (daysUntil < 0) return l10n.daysLate(-daysUntil);
  if (daysUntil == 0) return l10n.dueToday;
  return l10n.daysLeft(daysUntil);
}

/// How long [duration] is, in the largest units that fit ("1 year, 2
/// months", "5 days", "3 hours"); [underAnHour] when it is less than an
/// hour, which reads differently for an age ("Just now") and for a time to
/// finish ("Less than an hour").
String ageText(AppLocalizations l10n, Duration duration, {required String underAnHour}) {
  final years = duration.inDays ~/ 365;
  final months = (duration.inDays % 365) ~/ 30;
  final days = duration.inDays % 30;

  if (years > 0) {
    return months > 0 ? l10n.ageYearsMonths(years, months) : l10n.ageYears(years);
  }
  if (months > 0) {
    return days > 0 ? l10n.ageMonthsDays(months, days) : l10n.ageMonths(months);
  }
  if (days > 0) return l10n.ageDays(days);
  if (duration.inHours > 0) return l10n.ageHours(duration.inHours);
  return underAnHour;
}
