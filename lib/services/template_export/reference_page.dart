import 'dart:convert';

import 'template_patterns.dart';
import 'track_roles.dart';

/// The insert reference page: one HTML file, built from the corpus the
/// template export reads, with the data embedded as compact JSON.
///
/// This is a port of the prototype that produced the page (`build_data.py`),
/// and it keeps its behaviour exactly: the same plug-in names merged, the same
/// project kinds, the same "latest save of a song" flag, the same generations
/// of master chain. The page itself (`assets/reference/index.template.html`)
/// reads the compact format described by [buildReferenceData].

/// Plug-ins that go by two names across Cubase versions.
const Map<String, String> kPluginAliases = {
  'FabFilter Pro-Q 3': 'Pro-Q 3',
  'FabFilter Saturn 2': 'Saturn 2',
  'FabFilter Simplon': 'Simplon',
  'FabFilter Pro-C 2': 'Pro-C 2',
  'Redoptor 2': 'Redoptor2',
  'Invisible_Limiter': 'Invisible Limiter',
};

/// A plug-in's name as the page lists it: aliases merged, `_x64` dropped.
String canonPlugin(String name) {
  final aliased = kPluginAliases[name] ?? name;
  return aliased.replaceFirst(RegExp(r'_x64$'), '');
}

final _masterEndings = [
  RegExp(r'\((master|m)\)\s*$', caseSensitive: false),
  RegExp(r'\)\s*M(-\d+)?$'),
  RegExp(r'RemixM\)$'),
  RegExp(r'2026 master\)$', caseSensitive: false),
  RegExp(r'2025 M\)$'),
];

/// Whether a project's name marks it as a master: "(Master)", "(M)" or a
/// bare "M" closing the name.
bool isMasterName(String name) {
  final n = name.trim();
  return _masterEndings.any((re) => re.hasMatch(n));
}

/// `m` master, `s` scratch or test (25 tracks or fewer, or a test name),
/// `p` an ordinary production project.
String projectKind(String name, int trackCount) {
  if (isMasterName(name)) return 'm';
  if (trackCount <= 25 ||
      RegExp(r'^(test|gravacoes|sundose)', caseSensitive: false)
          .hasMatch(name)) {
    return 's';
  }
  return 'p';
}

/// What a project is a version of: its `2024_008` number, or else its name
/// with everything but letters and digits dropped.
String songKey(String name) {
  final m = RegExp(r'^(\d{4})_(\d{3})').firstMatch(name);
  if (m != null) return '${m.group(1)}_${m.group(2)}';
  return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

/// Which generation of master chain a project has, by the plug-ins that
/// mark each phase, read from the track with the longest chain.
int masterGeneration(CorpusProject project) {
  CorpusTrack? best;
  for (final t in project.tracks) {
    if (t.inserts.isEmpty) continue;
    if (best == null || t.inserts.length > best.inserts.length) best = t;
  }
  if (best == null) return 0;
  final names = {for (final i in best.inserts) canonPlugin(i.plugin)};
  if (names.contains('Ozone 10 Match EQ')) return 3;
  if (names.contains('Vertigo VSM-3')) {
    return names.contains('soothe2') || names.contains('Pro-L 2') ? 2 : 1;
  }
  return names.length >= 6 ? 3 : 2;
}

/// A list that hands out an index per distinct value, in first-seen order.
class _Dictionary {
  final List<String> values = [];
  final Map<String, int> _index = {};

  int of(String value) =>
      _index.putIfAbsent(value, () {
        values.add(value);
        return values.length - 1;
      });

  int? find(String value) => _index[value];
}

/// The data the page reads, in its compact form:
///
/// * `R`, `T`, `S`, `PL` — dictionaries of roles, track types, strings
///   (folders, outputs, master track names) and plug-ins; everything below
///   refers to them by index.
/// * `AL` — plug-in index → the names merged into it.
/// * `P` — one record per project: `n` name, `d` date, `v` Cubase major version,
///   `k` kind, `l` 1 when it is the latest save of its song, `nt` track
///   count, `t` tracks, and for masters `g` generation. A track is
///   `[role, type, folder, output, [slot, plugin, active]*]` (the last list
///   flat), plus the track's name for masters.
Map<String, Object?> buildReferenceData(
  List<CorpusProject> projects, {
  required DateTime generated,
}) {
  final roles = _Dictionary(),
      types = _Dictionary(),
      plugs = _Dictionary(),
      strings = _Dictionary();
  final aliases = <String, Set<String>>{};

  final kinds = [
    for (final p in projects) projectKind(p.name, p.tracks.length),
  ];

  // The latest save, by modified time then position, of each song in each
  // kind: that is what "only the newest version" keeps.
  final latest = <String, int>{};
  for (var i = 0; i < projects.length; i++) {
    final key = '${kinds[i]}|${songKey(projects[i].name)}';
    final current = latest[key];
    if (current == null) {
      latest[key] = i;
      continue;
    }
    final a = _modifiedText(projects[i]);
    final b = _modifiedText(projects[current]);
    final c = a.compareTo(b);
    if (c > 0 || (c == 0 && i > current)) latest[key] = i;
  }
  final latestSet = latest.values.toSet();

  final out = <Map<String, Object?>>[];
  for (var i = 0; i < projects.length; i++) {
    final p = projects[i];
    final kind = kinds[i];
    final tracks = <List<Object?>>[];
    for (final t in p.tracks) {
      if (t.role == kUnknownRole && t.inserts.isEmpty && kind != 'm') continue;
      final flat = <int>[];
      final sorted = [...t.inserts]..sort((a, b) => a.slot.compareTo(b.slot));
      for (final x in sorted) {
        final canon = canonPlugin(x.plugin);
        if (x.plugin != canon) (aliases[canon] ??= {}).add(x.plugin);
        flat
          ..add(x.slot)
          ..add(plugs.of(canon))
          ..add(x.bypassed == true ? 0 : 1);
      }
      final row = <Object?>[
        roles.of(t.role),
        types.of(t.type.name),
        t.parent != null && t.parent!.isNotEmpty ? strings.of(t.parent!) : -1,
        t.output != null && t.output!.isNotEmpty ? strings.of(t.output!) : -1,
        flat,
      ];
      if (kind == 'm') row.add(strings.of(t.name));
      tracks.add(row);
    }
    final record = <String, Object?>{
      'n': p.name
          .replaceAllMapped(
              RegExp(r'\.cpr( V2)?$'), (m) => m.group(1) ?? '')
          .trim(),
      'd': _modifiedText(p).substring(0, 10),
      'v': int.tryParse((p.cubaseVersion ?? '').split('.').first) ?? 0,
      'k': kind,
      'l': latestSet.contains(i) ? 1 : 0,
      'nt': p.tracks.length,
      't': tracks,
    };
    if (kind == 'm') record['g'] = masterGeneration(p);
    out.add(record);
  }

  final al = <String, Object?>{};
  aliases.forEach((canon, names) {
    final at = plugs.find(canon);
    if (at != null) al['$at'] = names.toList()..sort();
  });

  final kindCounts = <String, int>{};
  for (final k in kinds) {
    kindCounts[k] = (kindCounts[k] ?? 0) + 1;
  }
  return {
    'meta': {
      'generated': generated.toIso8601String().substring(0, 10),
      'n': projects.length,
      'kinds': kindCounts,
      'unknownTracks': projects.fold<int>(
          0,
          (sum, p) =>
              sum + p.tracks.where((t) => t.role == kUnknownRole).length),
    },
    'R': roles.values,
    'T': types.values,
    'S': strings.values,
    'PL': plugs.values,
    'AL': al,
    'P': out,
  };
}

String _modifiedText(CorpusProject p) => p.modified.toUtc().toIso8601String();

/// The page: [template] with its one placeholder replaced by [data] as JSON.
/// `<` is escaped so no project or plug-in name can close the script tag.
String renderReferenceHtml(String template, Map<String, Object?> data) {
  const placeholder = '__DATA__';
  final at = template.indexOf(placeholder);
  if (at < 0) throw ArgumentError('The template has no $placeholder.');
  final json = jsonEncode(data).replaceAll('<', r'\u' '003c');
  return template.substring(0, at) +
      json +
      template.substring(at + placeholder.length);
}
