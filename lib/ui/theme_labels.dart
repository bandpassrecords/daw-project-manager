import '../generated/l10n/app_localizations.dart';
import '../models/custom_theme.dart';
import '../providers/theme_provider.dart';

/// The name to show for [spec].
///
/// Built-in themes ship in nine languages and are named from the ARB files;
/// a user theme is named by its author and shown verbatim. A user theme whose
/// name was left blank falls back to a localized placeholder rather than
/// rendering an empty row.
String themeDisplayName(CustomTheme spec, AppLocalizations l10n) {
  switch (spec.id) {
    case 'neonDark':
      return l10n.neonDarkThemeName;
    case 'classicDark':
      return l10n.classicDarkThemeName;
    case 'studioLight':
      return l10n.studioLightThemeName;
  }
  final name = spec.name?.trim() ?? '';
  return name.isEmpty ? l10n.untitledTheme : name;
}

/// The name of the theme [current] cycles to next, for the switcher tooltip.
String nextThemeDisplayName(
  String currentId,
  List<CustomTheme> selectable,
  AppLocalizations l10n,
) {
  if (selectable.isEmpty) return themeDisplayName(AppThemes.fallbackSpec, l10n);
  final nextId = SelectedThemeNotifier.nextThemeId(
    currentId,
    selectable.map((t) => t.id).toList(),
  );
  final next = selectable.firstWhere(
    (t) => t.id == nextId,
    orElse: () => selectable.first,
  );
  return themeDisplayName(next, l10n);
}
