/// Width rules for the left section rail (Settings and the project detail
/// page's sections layout), which the user can drag to resize.
library;

/// Narrower than this and even short labels ellipsize.
const double kSectionRailMinWidth = 160;

/// Wider than this and the rail stops being a rail.
const double kSectionRailMaxWidth = 400;

/// The rail never takes more than this share of the space it sits in, so a
/// width chosen on a big monitor cannot swallow the content pane after the
/// window is made smaller.
const double kSectionRailMaxShare = 0.5;

/// Clamps a requested rail [width] to the allowed range for the [available]
/// width of the rail + content row.
///
/// The upper bound is the smaller of [kSectionRailMaxWidth] and
/// [kSectionRailMaxShare] of [available], but never below
/// [kSectionRailMinWidth] — on a very narrow window the minimum wins.
double clampSectionRailWidth(double width, {required double available}) {
  var upper = kSectionRailMaxWidth;
  if (available.isFinite) {
    final share = available * kSectionRailMaxShare;
    if (share < upper) upper = share;
  }
  if (upper < kSectionRailMinWidth) upper = kSectionRailMinWidth;
  if (width.isNaN) return kSectionRailMinWidth;
  return width.clamp(kSectionRailMinWidth, upper).toDouble();
}

/// Reads a stored width, or null for "never resized" — anything unreadable
/// counts as never resized, so each page falls back to its own default.
double? parseStoredSectionRailWidth(String? stored) {
  if (stored == null || stored.isEmpty) return null;
  final value = double.tryParse(stored);
  if (value == null || !value.isFinite || value <= 0) return null;
  return value;
}
