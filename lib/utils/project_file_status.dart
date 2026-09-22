import 'dart:io';

import '../models/music_project.dart';

/// Whether [project]'s source file (or, for bundle-style DAWs like Logic
/// Pro's .logicx, directory) still exists on this machine.
///
/// A live filesystem check, not a stored field — "missing" is inherently
/// per-device (e.g. a project on an external drive that isn't currently
/// mounted, or one only backed up from another machine), so it can't be
/// synced and re-derives correctly on every device independently.
bool projectFileExists(MusicProject project) {
  return File(project.filePath).existsSync() ||
      Directory(project.filePath).existsSync();
}

/// Whether [project] has been archived *and* its files are no longer in the
/// working library — the state the archived filter hides by default.
///
/// Archiving without ticking "delete the originals" leaves a perfectly usable
/// project on disk; the zip beside it is a backup, not a departure. Hiding
/// those would make a project vanish from the list for taking a backup of it,
/// which is why "archived" alone is not the thing to filter on.
///
/// Derived from live disk state rather than stored, deliberately, and for the
/// same reason [projectFileExists] is: a stored "originals were deleted" flag
/// goes stale the moment someone clears the folder out in Finder afterwards,
/// and would then claim a vanished project is still present. This re-derives
/// correctly on every device, every launch.
///
/// [filesExistLocally] is passed in rather than checked here so callers on a
/// hot path can answer it from `fileExistenceCacheProvider`'s cache instead of
/// a syscall per project per rebuild.
bool isArchivedAway(
  MusicProject project, {
  required bool filesExistLocally,
}) =>
    project.isArchived && !filesExistLocally;

/// [isArchivedAway] against a live filesystem check, for callers not on a
/// hot path.
bool projectIsArchivedAway(MusicProject project) => isArchivedAway(
      project,
      filesExistLocally: projectFileExists(project),
    );
