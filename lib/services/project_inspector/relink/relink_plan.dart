import '../../../models/sample_reference.dart';
import '../../sample_pack/sample_locator.dart';
import '../media_check.dart';
import 'folder_rules.dart';

/// One audio file a relink can point somewhere else: where the project
/// says it is, the files that could be it, and the one chosen.
class RelinkItem {
  const RelinkItem({
    required this.reference,
    required this.stored,
    this.candidates = const [],
    this.choice,
    this.manual = false,
  });

  final SampleReference reference;

  /// The path the project stores, which the writer rewrites.
  final String stored;

  /// Files on this computer that could be it, best first.
  final List<String> candidates;

  /// Where the copy will point; null leaves it as it is.
  final String? choice;

  /// Chosen by hand: a folder rule added later doesn't override it.
  final bool manual;

  /// Several files could be it and none was chosen: the user picks.
  bool get ambiguous => choice == null && candidates.length > 1;

  RelinkItem copyWith({
    List<String>? candidates,
    String? Function()? choice,
    bool? manual,
  }) =>
      RelinkItem(
        reference: reference,
        stored: stored,
        candidates: candidates ?? this.candidates,
        choice: choice == null ? this.choice : choice(),
        manual: manual ?? this.manual,
      );
}

/// The files of [checks] a relink is for — missing ones, and ones the
/// project points to where they aren't, though a file of that name is in
/// its folder — each with what could be it and, when one can be told, a
/// first choice:
///
/// 1. the file of that name in the project's folder;
/// 2. the best of [SampleLocator.candidatesFor]: the project's tree, and
///    library files that agree with the project;
/// 3. a file of that name in one of [searchFolders] — folders the user
///    pointed at to find these very files, so a name found once there is
///    taken; found several times, the one agreeing best
///    ([SampleLocator.clearBest]), or none when two agree as well, for the
///    user to pick.
///
/// A path kept in a plug-in's state isn't the project's to rewrite and is
/// left out.
Future<List<RelinkItem>> planRelink(
  List<MediaCheck> checks, {
  required String projectDir,
  required SampleLocator locator,
  List<String> searchFolders = const [],
}) async {
  final items = <RelinkItem>[];
  for (final c in checks) {
    if (c.status == MediaStatus.found) continue;
    if (c.reference.use == SampleUse.plugin) continue;
    final stored = c.reference.candidates.firstOrNull;
    if (stored == null) continue;
    final trusted =
        await locator.candidatesFor(c.reference, projectDir: projectDir);
    final inFolders = <String>[];
    for (final folder in searchFolders) {
      inFolders.addAll(await locator.namedIn(folder, c.reference));
    }
    final seen = <String>{};
    final candidates = [
      for (final h in [...trusted, ...inFolders])
        if (seen.add(h.toLowerCase())) h,
    ];
    final fromFolders = [
      for (final h in inFolders)
        if (!trusted.any((t) => t.toLowerCase() == h.toLowerCase())) h,
    ];
    items.add(RelinkItem(
      reference: c.reference,
      stored: stored,
      candidates: candidates,
      choice: c.path ??
          trusted.firstOrNull ??
          await locator.clearBest(fromFolders, c.reference),
    ));
  }
  return items;
}

/// [items] with [rules] applied: an item not chosen by hand points where
/// the rules put it, when a file is there. [exists] is asked once per
/// path.
Future<List<RelinkItem>> applyRules(
  List<RelinkItem> items,
  List<FolderRule> rules,
  Future<bool> Function(String path) exists,
) async {
  final out = <RelinkItem>[];
  for (final item in items) {
    final moved = item.manual ? null : applyFolderRules(item.stored, rules);
    out.add(moved != null && await exists(moved)
        ? item.copyWith(choice: () => moved)
        : item);
  }
  return out;
}

/// How many of [items] [rule] would point to a file that exists.
Future<int> filesFixedBy(
  FolderRule rule,
  List<RelinkItem> items,
  Future<bool> Function(String path) exists,
) async {
  var n = 0;
  for (final item in items) {
    final moved = rule.apply(item.stored);
    if (moved != null && await exists(moved)) n++;
  }
  return n;
}

/// The moves a writer is asked for: each chosen item, stored path → new.
Map<String, String> relinkMoves(List<RelinkItem> items) => {
      for (final item in items)
        if (item.choice != null && item.choice != item.stored)
          item.stored: item.choice!,
    };
