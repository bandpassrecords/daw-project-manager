/// How the desktop dashboard draws the project list.
///
/// A device-local preference, like [ProjectDetailLayout] and the waveform
/// style — it describes how this machine draws a page, not anything about the
/// projects — so it is deliberately neither synced to Drive nor backed up.
enum DashboardViewMode {
  /// The dense `TrinaGrid` table: sorting, smart-folder grouping, inline
  /// editing and the actions column. What the dashboard has always been.
  table,

  /// A cover-first card grid. Same projects, same filters, same sort — the
  /// table is for working through a library, the cards are for recognising
  /// something in it.
  cards,
}
