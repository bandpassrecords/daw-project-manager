import 'package:path/path.dart' as p;

/// The folder that directly contains a project's file or bundle.
///
/// Deliberately *not* `ScannerService.projectContainingFolder`, which answers a
/// different question — "what should Finder reveal?" — and for a `.logicx` /
/// `.luna` / `.band` bundle returns the bundle's parent because revealing the
/// bundle itself would just launch the DAW. Here we want the folder the project
/// entity sits in, whether that entity is a loose `.als` file or a bundle
/// directory, because that is the thing a move or an archive would sweep up.
String containingFolderOf(String projectPath) => p.dirname(projectPath);

/// Whether [projectPath]'s containing folder holds no *other* indexed project.
///
/// This is the test behind both "can we offer to move the whole folder?" and
/// the archive scope default. A dedicated folder is the project — its samples,
/// bounces and freeze files live there, so taking the folder takes the work. A
/// shared folder (twenty `.flp`s dropped in one directory, which is what a flat
/// scan root usually looks like) is not: taking it would move or zip nineteen
/// projects the user never selected.
///
/// [allProjectPaths] is every indexed project's `filePath`; [projectPath]'s own
/// entry is ignored, so callers can pass the whole library without filtering.
/// Comparison is on normalized paths, since stored paths and derived ones can
/// disagree about separators and `.` segments.
bool folderIsDedicatedTo(String projectPath, Iterable<String> allProjectPaths) {
  final self = p.normalize(projectPath);
  final folder = p.normalize(containingFolderOf(self));

  for (final other in allProjectPaths) {
    final norm = p.normalize(other);
    if (norm == self) continue;
    if (p.normalize(containingFolderOf(norm)) == folder) return false;
  }
  return true;
}
