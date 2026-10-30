import '../../../models/music_project.dart';
import '../../../models/project_anatomy.dart';
import '../../../models/project_stats.dart';
import '../../../utils/csv.dart';
import '../../../utils/project_anatomy_stats.dart';
import '../../daw_parsers/cubase_project_parser.dart';
import '../cubase_stock_plugins.dart';

/// One plug-in across the library (#225).
class PluginUsage {
  const PluginUsage({
    required this.name,
    required this.projects,
    required this.songs,
    required this.lastUsed,
    required this.daws,
    this.stock,
    this.instances,
  });

  /// As the deep scan names it.
  final String name;

  /// The project files using it, newest first.
  final List<MusicProject> projects;

  /// Songs using it: a version stack's versions are one song.
  final int songs;

  /// When the newest project using it was saved.
  final DateTime lastUsed;

  /// The DAWs of the projects using it.
  final Set<String> daws;

  /// Built into the DAW: known only where every project using it is in a
  /// DAW whose stock plug-ins the app knows (Cubase); null otherwise.
  final bool? stock;

  /// Times it is loaded across the Cubase projects whose tracks have been
  /// read; null when none of them has.
  final int? instances;

  bool get rare => songs == 1;
}

/// Plug-in usage across the library.
class PluginUsageReport {
  const PluginUsageReport({
    required this.plugins,
    required this.projectsRead,
    required this.projectsUnread,
    required this.songs,
    required this.chains,
    required this.projectsWithInstances,
  });

  /// Most used first: by songs, then projects, then name.
  final List<PluginUsage> plugins;

  /// Project files whose plug-ins the deep scan has read.
  final int projectsRead;

  /// Project files it hasn't: their plug-ins aren't counted.
  final int projectsUnread;

  /// Songs among [projectsRead].
  final int songs;

  /// Insert chains that repeat across the library's channels, from the
  /// Cubase projects whose tracks have been read.
  final List<(List<String>, int)> chains;

  /// Cubase projects whose tracks have been read, for [PluginUsage.instances]
  /// and [chains].
  final int projectsWithInstances;

  int get rare => plugins.where((p) => p.rare).length;
}

/// Plug-in usage over [projects] (#225), from what the deep scan stored on
/// each — the plug-ins' names, synced, so a phone can show it too. No
/// project file is read. [tracksOf] gives a Cubase project's tracks where
/// they have been read before (the insert reference page's cache): that is
/// what instances and chains are counted from.
PluginUsageReport buildPluginUsage(
  List<MusicProject> projects, {
  List<CubaseTrack>? Function(MusicProject project)? tracksOf,
}) {
  final files = [
    for (final p in projects)
      if (!p.isVirtual) p,
  ];
  final read = [
    for (final p in files)
      if (p.stats != null) p,
  ];

  final byName = <String, List<MusicProject>>{};
  final spelling = <String, String>{};
  for (final p in read) {
    for (final name in {for (final n in p.stats!.plugins) n.toLowerCase(): n}
        .entries) {
      (byName[name.key] ??= []).add(p);
      spelling.putIfAbsent(name.key, () => name.value);
    }
  }

  // Instances and chains from the Cubase projects already read.
  final instances = <String, int>{};
  final channels = <AnatomyChannel>[];
  var withInstances = 0;
  if (tracksOf != null) {
    for (final p in read) {
      final tracks = tracksOf(p);
      if (tracks == null) continue;
      withInstances++;
      for (final t in tracks) {
        if (t.instrument case final name?) {
          final key = cleanPluginName(name).toLowerCase();
          instances[key] = (instances[key] ?? 0) + 1;
        }
        for (final i in t.inserts) {
          final key = cleanPluginName(i.plugin).toLowerCase();
          instances[key] = (instances[key] ?? 0) + 1;
        }
        if (t.inserts.length >= 2) {
          channels.add(
            AnatomyChannel(
              name: t.name,
              kind: AnatomyChannelKind.audio,
              inserts: [
                for (final i in t.inserts)
                  AnatomyInsert(
                    slot: i.slot,
                    plugin: cleanPluginName(i.plugin),
                    deactivated: i.bypassed,
                  ),
              ],
            ),
          );
        }
      }
    }
  }

  String songOf(MusicProject p) => p.stackId ?? p.id;
  final usage = [
    for (final MapEntry(key: key, value: using) in byName.entries)
      () {
        final sorted = [...using]
          ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
        final daws = {for (final p in sorted) ?p.dawType};
        final name = spelling[key]!;
        return PluginUsage(
          name: name,
          projects: sorted,
          songs: {for (final p in sorted) songOf(p)}.length,
          lastUsed: sorted.first.lastModifiedAt,
          daws: daws,
          stock: daws.length == 1 && daws.single == 'Cubase'
              ? isCubaseStockPlugin(name)
              : null,
          instances: withInstances == 0 ? null : instances[key] ?? 0,
        );
      }(),
  ]..sort((a, b) {
      final bySongs = b.songs.compareTo(a.songs);
      if (bySongs != 0) return bySongs;
      final byProjects = b.projects.length.compareTo(a.projects.length);
      if (byProjects != 0) return byProjects;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  return PluginUsageReport(
    plugins: usage,
    projectsRead: read.length,
    projectsUnread: files.length - read.length,
    songs: {for (final p in read) songOf(p)}.length,
    chains: usualChains(channels, minCount: 3),
    projectsWithInstances: withInstances,
  );
}

/// Whether [project] uses [plugin] (ignoring case), as the deep scan read
/// it: the dashboard's "projects using …" filter. A version stack owns no
/// file, so it uses a plug-in when one of its versions does; [all] is where
/// those versions are looked up.
bool projectUsesPlugin(
  MusicProject project,
  String plugin,
  Iterable<MusicProject> all,
) {
  final wanted = plugin.toLowerCase();
  bool own(MusicProject p) =>
      p.stats?.plugins.any((n) => n.toLowerCase() == wanted) ?? false;
  if (!project.isVirtual) return own(project);
  return all.any((m) => m.stackId == project.id && own(m));
}

/// [report] as CSV, a row per plug-in, most used first: songs, project
/// files, instances where counted, when last used, the DAWs and whether it
/// is stock. English, like every CSV the app writes.
String pluginUsageCsv(PluginUsageReport report) => csvTable(
  const [
    'plugin',
    'songs',
    'projects',
    'instances',
    'last_used',
    'daws',
    'stock',
    'project_names',
  ],
  [
    for (final u in report.plugins)
      [
        u.name,
        u.songs,
        u.projects.length,
        u.instances,
        u.lastUsed.toIso8601String().substring(0, 10),
        (u.daws.toList()..sort()).join('; '),
        u.stock,
        [for (final p in u.projects) p.displayName].join('; '),
      ],
  ],
);
