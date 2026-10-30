import 'package:path/path.dart' as p;

import '../../../models/sample_reference.dart';
import '../../sample_pack/sample_locator.dart';
import '../media_check.dart';
import 'relink_copy.dart';
import 'relink_plan.dart';
import 'relink_writer.dart';

/// What fixing a project from folders did.
class FolderRelinkResult {
  const FolderRelinkResult({required this.items, this.copy});

  /// Every file the project couldn't find where it says, as planned.
  final List<RelinkItem> items;

  /// The copy written; null when nothing could be relinked.
  final RelinkCopy? copy;

  int get relinked => copy?.relinked.length ?? 0;

  /// Found nowhere.
  List<RelinkItem> get notFound => [
        for (final i in items)
          if (i.choice == null && i.candidates.isEmpty) i,
      ];

  /// Found more than once, with nothing to tell them apart.
  List<RelinkItem> get ambiguous => [
        for (final i in items)
          if (i.ambiguous) i,
      ];

  /// Found, but the project can't be pointed there (see [RelinkRefusal]).
  Map<String, RelinkRefusal> get refused => copy?.refused ?? const {};
}

/// Finds the files [references] are missing in [folders] and writes a
/// relinked copy of the project at [projectPath] pointing at them (#214):
/// the one-step fix. Only what [planRelink] can tell for sure is relinked;
/// the rest is reported, for the user to pick. The original is never
/// written.
Future<FolderRelinkResult> relinkFromFolders({
  required String projectPath,
  required List<SampleReference> references,
  required List<String> folders,
  SampleLocator? locator,
  ProjectRelinkWriter? writer,
}) async {
  final finder = locator ?? SampleLocator();
  final projectDir = p.dirname(projectPath);
  final checks =
      await checkMedia(references, projectDir: projectDir, locator: finder);
  final items = await planRelink(
    checks,
    projectDir: projectDir,
    locator: finder,
    searchFolders: folders,
  );
  final moves = relinkMoves(items);
  if (moves.isEmpty) return FolderRelinkResult(items: items);
  final copy = await writeRelinkedCopy(
    projectPath: projectPath,
    moves: moves,
    writer: writer,
  );
  return FolderRelinkResult(items: items, copy: copy);
}
