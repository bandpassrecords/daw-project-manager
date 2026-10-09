import '../daw_parsers/cubase_project_parser.dart';
import 'track_roles.dart';

/// Where a role sits in the template: folders come first, then the buses
/// that mix other tracks, then ordinary tracks.
enum TemplateKind { folder, bus, track }

TemplateKind kindOfTrack(CubaseTrackType type) => switch (type) {
      CubaseTrackType.folder => TemplateKind.folder,
      CubaseTrackType.group => TemplateKind.bus,
      _ => TemplateKind.track,
    };

/// One track of a project, as written to `corpus.json`.
class CorpusTrack {
  const CorpusTrack({
    required this.index,
    required this.name,
    required this.role,
    required this.type,
    this.parent,
    this.output,
    this.inserts = const [],
  });

  final int index;
  final String name;
  final String role;
  final CubaseTrackType type;
  final String? parent;

  /// Name of the channel or output this one feeds; null when not read.
  final String? output;
  final List<CubaseInsert> inserts;

  Map<String, dynamic> toJson() => {
        'index': index,
        'name': name,
        'role': role,
        'type': type.name,
        'parent': parent,
        if (output != null) 'output': output,
        if (inserts.isNotEmpty)
          'inserts': [
            for (final i in inserts)
              {
                'slot': i.slot,
                'plugin': i.plugin,
                if (i.bypassed != null) 'bypassed': i.bypassed,
              },
          ],
      };
}

/// One project of the corpus. [projectId] is the app's own id, never a path.
class CorpusProject {
  const CorpusProject({
    required this.projectId,
    required this.name,
    required this.modified,
    required this.tracks,
    this.cubaseVersion,
    this.tags = const [],
    this.plugins = const [],
  });

  final String projectId;
  final String name;
  final String? cubaseVersion;
  final DateTime modified;
  final List<String> tags;

  /// Distinct plug-in names the project uses.
  final List<String> plugins;
  final List<CorpusTrack> tracks;

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'name': name,
        if (cubaseVersion != null) 'cubase_version': cubaseVersion,
        'modified': modified.toUtc().toIso8601String(),
        if (tags.isNotEmpty) 'tags': tags,
        if (plugins.isNotEmpty) 'plugins': plugins,
        'tracks': [for (final t in tracks) t.toJson()],
      };
}

/// Builds a corpus project from what the parser read.
CorpusProject buildCorpusProject({
  required String projectId,
  required String name,
  required DateTime modified,
  required List<CubaseTrack> tracks,
  String? cubaseVersion,
  List<String> tags = const [],
  List<String> plugins = const [],
  Map<String, String> aliases = const {},
}) {
  return CorpusProject(
    projectId: projectId,
    name: name,
    modified: modified,
    cubaseVersion: cubaseVersion,
    tags: tags,
    plugins: plugins,
    tracks: [
      for (final t in tracks)
        CorpusTrack(
          index: t.index,
          name: t.name,
          role: roleOf(t.name, aliases: aliases),
          type: t.type,
          parent: t.parent,
          output: t.output,
          inserts: t.inserts,
        ),
    ],
  );
}

/// Presence cut-offs. The defaults are a first suggestion.
class TemplateThresholds {
  const TemplateThresholds({
    this.core = 0.7,
    this.common = 0.4,
    this.parentRate = 0.5,
    this.insert = 0.25,
    this.maxInserts = 6,
  });

  /// At or above this a role always goes in the template.
  final double core;

  /// At or above this (and below [core]) it goes in, marked optional.
  final double common;

  /// Share of a role's tracks that must sit in the same folder for the
  /// template to put them there.
  final double parentRate;

  /// Share of a role's tracks that must use a plug-in for it to be offered.
  /// Low on purpose: the template only reminds, every insert is bypassed.
  final double insert;

  /// Most plug-ins in one track's chain (Cubase has 16 slots).
  final int maxInserts;
}

enum RoleTier { core, common, rare }

/// A plug-in the tracks of a role often carry, and where in the chain.
class InsertPattern {
  const InsertPattern(this.plugin, this.rate, this.slotMedian);
  final String plugin;

  /// Tracks of the role carrying it ÷ tracks of the role. A bypassed one
  /// counts: the plug-in was in use once.
  final double rate;
  final double slotMedian;

  Map<String, dynamic> toJson() => {
        'plugin': plugin,
        'rate': _round(rate),
        'slot_median': slotMedian,
      };
}

/// What the corpus says about one role of one [kind].
class RolePattern {
  const RolePattern({
    required this.kind,
    required this.role,
    required this.name,
    required this.tier,
    required this.presence,
    required this.countMedian,
    required this.countMax,
    required this.positionMedian,
    required this.typeMode,
    this.parent,
    this.parentRole,
    this.parentRate = 0,
    this.output,
    this.outputRole,
    this.outputRate = 0,
    this.inserts = const [],
  });

  final TemplateKind kind;
  final String role;

  /// Most common spelling of the track name, without its trailing number.
  final String name;
  final RoleTier tier;

  /// Projects with at least one such track ÷ projects analysed.
  final double presence;

  /// Median and maximum number of such tracks, over projects that have any.
  final double countMedian;
  final int countMax;

  /// Median of index ÷ track count, 0 (first) to 1 (last).
  final double positionMedian;
  final CubaseTrackType typeMode;

  /// Most common folder, and the share of the role's tracks inside it.
  /// Null: most of them sit at the top level.
  final String? parent;

  /// The role of that folder, or null when it has none (then no folder of
  /// the template can be it).
  final String? parentRole;
  final double parentRate;

  /// Where the role's channels usually send their output, and the role of
  /// that channel (null for an output such as "Stereo Out").
  final String? output;
  final String? outputRole;
  final double outputRate;

  /// The chain a template offers, in slot order, at most
  /// [TemplateThresholds.maxInserts] long.
  final List<InsertPattern> inserts;

  /// How many copies the template makes. Folders and buses are made once:
  /// several of one role are sub-folders of different things, not copies.
  int get copies =>
      kind == TemplateKind.track ? countMedian.ceil().clamp(1, countMax) : 1;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'role': role,
        'name': name,
        'tier': tier.name,
        'presence': _round(presence),
        'count_median': countMedian,
        'count_max': countMax,
        'position_median': _round(positionMedian),
        'type_mode': typeMode.name,
        'parent_mode': parent == null
            ? null
            : {
                'name': parent,
                if (parentRole != null) 'role': parentRole,
                'rate': _round(parentRate),
              },
        'output_mode': output == null
            ? null
            : {
                'name': output,
                if (outputRole != null) 'role': outputRole,
                'rate': _round(outputRate),
              },
        'insert_chain': [for (final i in inserts) i.toJson()],
      };
}

class PluginPattern {
  const PluginPattern(this.plugin, this.presence);
  final String plugin;

  /// Projects using it ÷ projects analysed.
  final double presence;

  Map<String, dynamic> toJson() =>
      {'plugin': plugin, 'projects': _round(presence)};
}

/// `patterns.json`: the corpus boiled down to what a template needs.
class TemplatePatterns {
  const TemplatePatterns({
    required this.generated,
    required this.projectCount,
    required this.thresholds,
    required this.roles,
    required this.plugins,
    required this.unknownTrackCount,
    required this.unknownNames,
    required this.cubaseVersion,
  });

  static const schemaVersion = 1;

  final DateTime generated;
  final int projectCount;
  final TemplateThresholds thresholds;
  final List<RolePattern> roles;
  final List<PluginPattern> plugins;

  /// Tracks whose name matched no role: left out of every statistic.
  final int unknownTrackCount;

  /// The most common of those names, for classifying once.
  final List<({String name, int count})> unknownNames;

  /// Most common major.minor among the projects, if any recorded one.
  final String? cubaseVersion;

  /// Roles that make the template, in build order (position, then name).
  List<RolePattern> inTemplate(TemplateKind kind) => [
        for (final r in roles)
          if (r.kind == kind && r.tier != RoleTier.rare) r,
      ];

  Map<String, dynamic> toJson() => {
        'meta': {
          'schema_version': schemaVersion,
          'generated': generated.toUtc().toIso8601String(),
          'projects': projectCount,
          'unknown_tracks': unknownTrackCount,
          'insert_state': kInsertState,
          'thresholds': {
            'core': thresholds.core,
            'common': thresholds.common,
            'parent_rate': thresholds.parentRate,
          },
          if (projectCount < kSmallCorpus)
            'warning': 'Fewer than $kSmallCorpus projects: the statistics '
                'are weak.',
        },
        'roles': [for (final r in roles) r.toJson()],
        'plugins': [for (final p in plugins) p.toJson()],
        'unknown_names': [
          for (final u in unknownNames) {'name': u.name, 'count': u.count},
        ],
      };
}

/// Every insert of the template is created bypassed: it is a reminder of what
/// is usually used, switched on only where wanted.
const String kInsertState = 'bypassed';

/// Below this many projects the statistics say little.
const int kSmallCorpus = 5;

double _round(double v) => (v * 100).round() / 100;

double _median(List<num> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid].toDouble();
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

/// The most frequent value; ties go to the one seen first.
T? _mode<T>(Iterable<T> values) {
  final counts = <T, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  T? best;
  var bestCount = 0;
  counts.forEach((v, n) {
    if (n > bestCount) {
      best = v;
      bestCount = n;
    }
  });
  return best;
}

/// A plug-in's identity: "FabFilter Pro-Q 3" and "Pro-Q 3" are one.
String pluginKey(String name) =>
    name.toLowerCase().replaceFirst(RegExp(r'^fabfilter\s+'), '').trim();

/// Trailing number and separators off a track name: "Lead 02" → "Lead".
String baseName(String name) {
  final base = name.replaceFirst(RegExp(r'[\s_\-.#]*\d+$'), '').trim();
  return base.isEmpty ? name.trim() : base;
}

/// Aggregates [projects]. Projects without a single track are not counted.
TemplatePatterns buildPatterns(
  List<CorpusProject> projects, {
  TemplateThresholds thresholds = const TemplateThresholds(),
  Map<String, String> aliases = const {},
  DateTime? now,
}) {
  final analysed = [for (final p in projects) if (p.tracks.isNotEmpty) p];
  final total = analysed.length;

  // (kind, role) → every track of that role, with the project it came from.
  final groups = <(TemplateKind, String), List<(CorpusProject, CorpusTrack)>>{};
  final unknown = <String, int>{};
  var unknownTracks = 0;
  for (final p in analysed) {
    for (final t in p.tracks) {
      if (t.role == kUnknownRole) {
        unknownTracks++;
        unknown[t.name] = (unknown[t.name] ?? 0) + 1;
        continue;
      }
      (groups[(kindOfTrack(t.type), t.role)] ??= []).add((p, t));
    }
  }

  final roles = <RolePattern>[];
  groups.forEach((key, members) {
    final (kind, role) = key;
    final perProject = <String, int>{};
    for (final (p, _) in members) {
      perProject[p.projectId] = (perProject[p.projectId] ?? 0) + 1;
    }
    final presence = total == 0 ? 0.0 : perProject.length / total;

    // A parent folder is told apart by its role; one with no role by its
    // name, which no folder of the template can match.
    String? parentKeyOf(String? parent) {
      if (parent == null) return null;
      final r = roleOf(parent, aliases: aliases);
      return r == kUnknownRole ? 'name:${roleKey(parent)}' : r;
    }

    final parents = [for (final (_, t) in members) parentKeyOf(t.parent)];
    final parentKey = _mode(parents);
    final parentShare = parentKey == null
        ? 0.0
        : parents.where((k) => k == parentKey).length / parents.length;
    final parentName = parentKey == null
        ? null
        : baseName(members
            .map((m) => m.$2.parent)
            .whereType<String>()
            .firstWhere((n) => parentKeyOf(n) == parentKey));

    // Output: by the role of the channel it feeds, or by name for an output.
    String? outputKeyOf(String? out) {
      if (out == null) return null;
      final r = roleOf(out, aliases: aliases);
      return r == kUnknownRole ? 'name:${roleKey(out)}' : r;
    }

    final outputs = [
      for (final (_, t) in members)
        if (t.output != null) outputKeyOf(t.output),
    ];
    final outputKey = _mode(outputs);
    final outputShare = outputKey == null
        ? 0.0
        : outputs.where((k) => k == outputKey).length / outputs.length;
    final outputName = outputKey == null
        ? null
        : baseName(members
            .map((m) => m.$2.output)
            .whereType<String>()
            .firstWhere((n) => outputKeyOf(n) == outputKey));

    // Insert chain: a plug-in many of the role's tracks carry, in the order
    // it usually sits in the chain.
    final carriers = <String, int>{};
    final slots = <String, List<int>>{};
    final spellings = <String, List<String>>{};
    for (final (_, t) in members) {
      for (final key in {for (final i in t.inserts) pluginKey(i.plugin)}) {
        carriers[key] = (carriers[key] ?? 0) + 1;
      }
      for (final i in t.inserts) {
        (slots[pluginKey(i.plugin)] ??= []).add(i.slot);
        (spellings[pluginKey(i.plugin)] ??= []).add(i.plugin);
      }
    }
    final candidates = [
      for (final e in carriers.entries)
        if (e.value / members.length >= thresholds.insert)
          InsertPattern(_mode(spellings[e.key]!)!, e.value / members.length,
              _median(slots[e.key]!)),
    ]..sort((a, b) {
        final byRate = b.rate.compareTo(a.rate);
        return byRate != 0 ? byRate : a.plugin.compareTo(b.plugin);
      });
    final chain = candidates.take(thresholds.maxInserts).toList()
      ..sort((a, b) {
        final bySlot = a.slotMedian.compareTo(b.slotMedian);
        return bySlot != 0 ? bySlot : b.rate.compareTo(a.rate);
      });

    // The commonest spelling, if it is a plain alias; otherwise the role's
    // own name, since "DRUMS - TOM 01 Right Panned" is nobody's template.
    final spelling = baseName(_mode(members.map((m) => m.$2.name))!);
    final name =
        isCleanAlias(spelling, aliases: aliases) ? spelling : roleTitle(role);

    roles.add(RolePattern(
      kind: kind,
      role: role,
      name: name,
      tier: presence >= thresholds.core
          ? RoleTier.core
          : presence >= thresholds.common
              ? RoleTier.common
              : RoleTier.rare,
      presence: presence,
      countMedian: _median(perProject.values.toList()),
      countMax: perProject.values.reduce((a, b) => a > b ? a : b),
      positionMedian: _median([
        for (final (p, t) in members) t.index / p.tracks.length,
      ]),
      typeMode: _mode(members.map((m) => m.$2.type))!,
      parent: parentName != null && parentShare >= thresholds.parentRate
          ? parentName
          : null,
      parentRole: parentName != null &&
              parentShare >= thresholds.parentRate &&
              !parentKey!.startsWith('name:')
          ? parentKey
          : null,
      parentRate: parentShare,
      output: outputName != null && outputShare >= thresholds.parentRate
          ? outputName
          : null,
      outputRole: outputName != null &&
              outputShare >= thresholds.parentRate &&
              !outputKey!.startsWith('name:')
          ? outputKey
          : null,
      outputRate: outputShare,
      inserts: chain,
    ));
  });
  roles.sort((a, b) {
    final byPosition = a.positionMedian.compareTo(b.positionMedian);
    return byPosition != 0 ? byPosition : a.role.compareTo(b.role);
  });

  final pluginProjects = <String, int>{};
  for (final p in analysed) {
    for (final name in p.plugins.toSet()) {
      pluginProjects[name] = (pluginProjects[name] ?? 0) + 1;
    }
  }
  final plugins = [
    for (final e in pluginProjects.entries)
      PluginPattern(e.key, total == 0 ? 0 : e.value / total),
  ]..sort((a, b) {
      final byUse = b.presence.compareTo(a.presence);
      return byUse != 0 ? byUse : a.plugin.compareTo(b.plugin);
    });

  final unknownNames = [
    for (final e in unknown.entries) (name: e.key, count: e.value),
  ]..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });

  return TemplatePatterns(
    generated: now ?? DateTime.now(),
    projectCount: total,
    thresholds: thresholds,
    roles: roles,
    plugins: plugins,
    unknownTrackCount: unknownTracks,
    unknownNames: unknownNames.take(50).toList(),
    cubaseVersion: _mode([
      for (final p in analysed)
        if (p.cubaseVersion != null && p.cubaseVersion!.isNotEmpty)
          p.cubaseVersion!,
    ]),
  );
}
