import 'package:path/path.dart' as p;

import '../models/music_project.dart';
import '../models/release.dart';
import '../models/scan_root.dart';
import 'scan_root_filters.dart';
import 'version_stacks.dart';

/// Which projects are *in the library* — before any display filter (hidden,
/// archived, phase, search) is applied.
///
/// This is the one definition of that set. `projectsProvider` builds the list
/// on it, and the dashboard's "Projects: N (M hidden)" line counts it.
/// Before, the dashboard counted from its own hand-copied version of these
/// rules, which drifted: it never learned about disabled folders, and it
/// counted a version stack and each of its versions separately — so the
/// numbers above the list disagreed with the list under them.
///
/// Three rules, in order:
/// 1. **Version stacks collapse** to their stack row (#94); a stacked song is
///    one entry, not one per version.
/// 2. **Disabled folders drop out** (see [ScanRoot.enabled]); their projects
///    are kept in storage, just not in the library.
/// 3. **Stale release-preserved projects drop out**: a project kept alive by a
///    release, whose file is on this machine but outside every active folder
///    (its folder was removed). One whose file isn't here at all stays — it is
///    a metadata-only entry restored from elsewhere.
///
/// Rules 2 and 3 are desktop-only: mobile has no local filesystem to relate a
/// project to a folder, so there every collapsed project is in the library.
///
/// [fileExistsLocally] is injected so this runs without touching the disk.
List<MusicProject> buildLibraryProjects({
  required List<MusicProject> allProjects,
  required List<Release> releases,
  required List<ScanRoot> scanRoots,
  required bool isMobile,
  required bool Function(String path) fileExistsLocally,
}) {
  var projects = collapseVersionStacks(allProjects);
  if (isMobile) return projects;

  if (scanRoots.any((r) => !r.enabled)) {
    projects = projects
        .where((project) => !isHiddenByDisabledRoot(project.filePath, scanRoots))
        .toList();
  }

  final protectedProjectIds = releaseProtectedProjectIds(releases);
  // Only enabled folders count as active: a release-preserved project in a
  // disabled one was already dropped above.
  final activeRootPaths = [
    for (final root in scanRoots)
      if (root.enabled) normalizedRootPrefix(root.path),
  ];

  return projects.where((project) {
    // Not on any release: always in the library.
    if (!protectedProjectIds.contains(project.id)) return true;

    // A stack has no scanned file of its own — its path is the folder its
    // versions sit in, possibly the scan root itself, which the prefix test
    // below would reject. Judged by its members, never by that path.
    if (!project.isMissingFileCandidate) return true;

    // File not on this machine: a metadata-only entry, always shown.
    if (!fileExistsLocally(project.filePath)) return true;

    // File here: only if it lives under an active folder.
    final projectPath = p.normalize(project.filePath);
    return activeRootPaths.any((rootPath) => projectPath.startsWith(rootPath));
  }).toList();
}

/// The dashboard's "Projects: N (M hidden)" figures for a library built by
/// [buildLibraryProjects].
///
/// "Hidden" means the per-project hidden flag and nothing else. A project in a
/// disabled folder is not hidden — it is out of the library altogether — so it
/// is counted in neither figure.
({int visible, int hidden}) libraryProjectCounts(
  Iterable<MusicProject> library,
) {
  var visible = 0;
  var hidden = 0;
  for (final project in library) {
    project.hidden ? hidden++ : visible++;
  }
  return (visible: visible, hidden: hidden);
}
