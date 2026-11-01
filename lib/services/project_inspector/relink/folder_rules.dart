/// "Everything under `H:\STUDIO\` is now under `/Volumes/Archive/STUDIO/`":
/// one rule a relink applies to every missing file it covers (#214).
///
/// Paths are compared segment by segment, ignoring case and separators — a
/// project saved on Windows names `D:\Samples\kick.wav`, and the files may
/// now be on a Mac. The new path takes [to]'s separators.
class FolderRule {
  const FolderRule(this.from, this.to);

  final String from;
  final String to;

  /// [path] under [to] instead of [from]; null when [path] isn't inside
  /// [from].
  String? apply(String path) {
    final f = pathSegments(from);
    final s = pathSegments(path);
    if (f.isEmpty || s.length <= f.length) return null;
    for (var i = 0; i < f.length; i++) {
      if (f[i].toLowerCase() != s[i].toLowerCase()) return null;
    }
    return joinUnder(to, s.sublist(f.length));
  }

  @override
  bool operator ==(Object other) =>
      other is FolderRule && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => '$from → $to';
}

/// Where [rules] put [path]: the rule with the deepest [FolderRule.from]
/// that contains it, or null when none does.
String? applyFolderRules(String path, List<FolderRule> rules) {
  FolderRule? best;
  var depth = -1;
  for (final r in rules) {
    final d = pathSegments(r.from).length;
    if (d > depth && r.apply(path) != null) {
      best = r;
      depth = d;
    }
  }
  return best?.apply(path);
}

/// The rule that would have taken [stored] to [found], for offering to fix
/// every other file the same way: the folders the two paths don't share,
/// from the end. `D:\Old\Song\Audio\kick.wav` found at
/// `E:\Backup\Song\Audio\kick.wav` gives `D:\Old` → `E:\Backup`. Null when
/// the paths are the same, or share nothing but the file name — that is a
/// file found elsewhere, not a folder that moved.
FolderRule? suggestFolderRule(String stored, String found) {
  final s = pathSegments(stored);
  final f = pathSegments(found);
  var common = 0;
  while (common < s.length &&
      common < f.length &&
      s[s.length - 1 - common].toLowerCase() ==
          f[f.length - 1 - common].toLowerCase()) {
    common++;
  }
  if (common == s.length && common == f.length) return null;
  // Only the name in common: no folder carried over.
  if (common < 2 || common >= s.length || common >= f.length) return null;
  return FolderRule(
    _rooted(stored, s.sublist(0, s.length - common)),
    _rooted(found, f.sublist(0, f.length - common)),
  );
}

/// [path]'s folders and name, without separators: `D:\a\b.wav` gives
/// `[D:, a, b.wav]`, `/Volumes/x` gives `[Volumes, x]`.
List<String> pathSegments(String path) =>
    path.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).toList();

/// Whether [path] is written the Windows way (a drive, a UNC share or
/// backslashes).
bool isWindowsStylePath(String path) =>
    RegExp(r'^([A-Za-z]:|\\\\)').hasMatch(path) ||
    (path.contains(r'\') && !path.contains('/'));

/// [segments] under the folder [base], in [base]'s style.
String joinUnder(String base, List<String> segments) {
  final sep = isWindowsStylePath(base) ? r'\' : '/';
  var b = base;
  while (b.length > 1 && (b.endsWith(r'\') || b.endsWith('/'))) {
    b = b.substring(0, b.length - 1);
  }
  if (segments.isEmpty) return b;
  if (b == '/' || b == r'\') return '$b${segments.join(sep)}';
  return '$b$sep${segments.join(sep)}';
}

/// [segments] of [original], rooted the way [original] is: a leading `/`
/// or `\\` kept, a lone drive written `D:\`.
String _rooted(String original, List<String> segments) {
  final windows = isWindowsStylePath(original);
  final sep = windows ? r'\' : '/';
  final joined = segments.join(sep);
  if (original.startsWith(r'\\')) return '\\\\$joined';
  if (!windows && original.startsWith('/')) return '/$joined';
  if (segments.length == 1 && joined.endsWith(':')) return '$joined$sep';
  return joined;
}
