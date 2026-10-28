/// What the phone's project list shows when it has no rows to show.
enum EmptyProjectsView {
  /// The library hasn't been read yet: a spinner, not a verdict.
  loading,

  /// There are projects, and the filters or search hide them all.
  filteredOut,

  /// There are none: the first-run screen, with its Drive sync offer.
  noProjects,
}

/// Which [EmptyProjectsView] an empty list is. Until the library has loaded
/// it is too early to say there are no projects — reading it as none put the
/// first-run "Sync with Google Drive" screen up on every launch, for the
/// moment before the projects appeared.
EmptyProjectsView emptyProjectsView({
  required bool libraryLoaded,
  required int totalProjects,
}) {
  if (!libraryLoaded) return EmptyProjectsView.loading;
  return totalProjects > 0
      ? EmptyProjectsView.filteredOut
      : EmptyProjectsView.noProjects;
}
