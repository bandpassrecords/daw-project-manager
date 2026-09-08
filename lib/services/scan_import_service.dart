import 'dart:io';

import '../repository/project_repository.dart';
import 'scanner_service.dart';

/// Scans a single scan-root directory and imports every DAW project it finds
/// into [repo], then stamps the root's last-scan time. Returns how many
/// project files / package bundles were found.
///
/// This is the shared core behind every "I just added a projects folder"
/// entry point *except* the dashboard (which runs the heavier full [_scanAll]
/// over every root). Before it existed, the startup dialog and the onboarding
/// wizard added the root but never scanned it, and the background folder
/// watcher only reacts to *later* filesystem activity — so a folder that
/// already contained projects stayed empty in the UI until the user hit
/// "Rescan" or relaunched the app.
///
/// It intentionally does not touch `recentlyDiscoveredProjectsProvider`: a
/// freshly-added root has no "seen last time" baseline, so everything found
/// is initial population, not a new-since-last-time discovery.
Future<int> importProjectsFromRoot(
  ProjectRepository repo,
  String rootId,
  String rootPath, {
  ScannerService? scanner,
}) async {
  final s = scanner ?? ScannerService();
  final ignoredPaths =
      repo.getIgnoredPaths().map((e) => e.path).toList(growable: false);

  final entities = <FileSystemEntity>[];
  await for (final entity
      in s.scanDirectory(rootPath, ignoredPaths: ignoredPaths)) {
    entities.add(entity);
  }
  if (entities.isNotEmpty) {
    await repo.upsertManyFromFileSystemEntities(entities);
  }
  await repo.updateRootLastScanAt(rootId, DateTime.now());
  // No-op unless some root is in Version Stack mode.
  await repo.autoStackFolders();
  return entities.length;
}
