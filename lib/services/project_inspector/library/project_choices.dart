import 'package:path/path.dart' as p;

import '../../../models/music_project.dart';
import '../../scanner_service.dart';

/// The library's projects as the Inspector's Open project… and Compare with…
/// offer them: picked from the list the dashboard shows, a file dialog only
/// for a file outside it.
typedef InspectorProjectChoices = ({
  /// When comparing: the open project's other versions — its stack's
  /// members, else the projects in its folder. The likeliest pick, so first.
  List<MusicProject> versions,

  /// Everything else, the most recently changed first.
  List<MusicProject> others,
});

/// Every project of [all] the Inspector could read: a file of a supported
/// format — never a stack (a folder) or an archived project (its file is in a
/// zip). [comparingWith] is the open project's path, left out of both lists,
/// whose versions go in `versions`.
InspectorProjectChoices inspectorProjectChoices(
  List<MusicProject> all, {
  String? comparingWith,
}) {
  final seen = <String>{};
  final readable = [
    for (final pr in all)
      if (!pr.isVirtual &&
          !pr.isArchived &&
          ScannerService.supportedExtensions.contains(
            p.extension(pr.filePath).toLowerCase(),
          ) &&
          (comparingWith == null || !p.equals(pr.filePath, comparingWith)) &&
          seen.add(p.normalize(pr.filePath)))
        pr,
  ]..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));

  if (comparingWith == null) return (versions: const [], others: readable);

  final open = all
      .where((pr) => p.equals(pr.filePath, comparingWith))
      .firstOrNull;
  final stackId = open?.stackId;
  final folder = p.dirname(comparingWith);
  bool isVersion(MusicProject pr) => stackId != null
      ? pr.stackId == stackId
      : p.equals(p.dirname(pr.filePath), folder);
  return (
    versions: [
      for (final pr in readable)
        if (isVersion(pr)) pr,
    ],
    others: [
      for (final pr in readable)
        if (!isVersion(pr)) pr,
    ],
  );
}

/// Whether [project] matches the picker's search: its name, file name,
/// folder or DAW, ignoring case.
bool matchesInspectorSearch(MusicProject project, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return [
    project.displayName,
    project.fileName,
    p.dirname(project.filePath),
    project.dawType ?? '',
  ].any((s) => s.toLowerCase().contains(q));
}
