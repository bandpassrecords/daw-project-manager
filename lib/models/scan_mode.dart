/// How a scan root turns the files it finds into rows in the projects list.
enum ScanMode {
  /// Every project file is its own row, wherever it sits under the root.
  flat,

  /// Files are grouped visually by the top-level folder under the root. The
  /// rows are still separate projects — the folder is only a display grouping.
  smartFolder,

  /// Every project file sharing an immediate parent folder is treated as one
  /// song: the folder becomes a *stack* (a virtual project) owning the shared
  /// metadata, todos and work time, and the files inside it become its
  /// versions.
  ///
  /// Unlike [smartFolder] this is not a display-only grouping — it creates and
  /// maintains real rows in the database, so it is off by default and scans
  /// only ever *add* to stacks (see `ProjectRepository.autoStackFolders`).
  /// Nothing here ever unstacks something the user stacked by hand.
  versionStack,
}
