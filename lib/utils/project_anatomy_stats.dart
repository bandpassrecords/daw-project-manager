import '../models/project_anatomy.dart';

/// What the Project Inspector's tabs compute from a [ProjectAnatomy]:
/// counts, routing and the checks it offers as hints. Plain functions over
/// the model, so every DAW gets them and tests need no widgets.

/// Channels that hold material or mix it — everything but folders.
Iterable<AnatomyChannel> mixerChannels(List<AnatomyChannel> channels) =>
    channels.where((c) => c.kind != AnatomyChannelKind.folder);

/// How many channels there are of each kind; folders included.
Map<AnatomyChannelKind, int> channelCounts(List<AnatomyChannel> channels) {
  final counts = <AnatomyChannelKind, int>{};
  for (final c in channels) {
    counts[c.kind] = (counts[c.kind] ?? 0) + 1;
  }
  return counts;
}

/// Plug-in instances by what they are. A plug-in whose role or origin isn't
/// known counts as [unknown].
({int instruments, int stockEffects, int thirdPartyEffects, int unknown})
    pluginInstanceCounts(List<AnatomyPlugin> plugins) {
  var instruments = 0, stock = 0, thirdParty = 0, unknown = 0;
  for (final p in plugins) {
    final n = p.instances ?? 1;
    switch ((p.role, p.stock)) {
      case (AnatomyPluginRole.instrument, _):
        instruments += n;
      case (AnatomyPluginRole.effect, true):
        stock += n;
      case (AnatomyPluginRole.effect, false):
        thirdParty += n;
      default:
        unknown += n;
    }
  }
  return (
    instruments: instruments,
    stockEffects: stock,
    thirdPartyEffects: thirdParty,
    unknown: unknown,
  );
}

/// Plug-ins by how often they are loaded, most first; ties by name. Only
/// plug-ins whose instances are known.
List<AnatomyPlugin> mostUsedPlugins(List<AnatomyPlugin> plugins,
    {int limit = 10}) {
  final known = plugins.where((p) => p.instances != null).toList()
    ..sort((a, b) {
      final byCount = b.instances!.compareTo(a.instances!);
      return byCount != 0
          ? byCount
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return known.take(limit).toList();
}

/// Insert chains — plug-ins in consecutive slots, in slot order — that
/// recur on [minCount] channels or more, longest and most common first. A
/// shorter chain is left out when every channel using it uses a longer one
/// containing it, so "A → B → C" on three channels doesn't also list
/// "A → B". Deactivated inserts don't play, and break a chain.
List<(List<String>, int)> usualChains(
  List<AnatomyChannel> channels, {
  int minLength = 2,
  int maxLength = 4,
  int minCount = 2,
  int limit = 10,
}) {
  final counts = <String, (List<String>, int)>{};
  for (final c in channels) {
    final playing = [
      for (final i in c.inserts)
        if (i.deactivated != true) i.plugin,
    ];
    final seen = <String>{};
    for (var len = minLength; len <= maxLength; len++) {
      for (var start = 0; start + len <= playing.length; start++) {
        final chain = playing.sublist(start, start + len);
        final key = chain.join('\u0000');
        if (!seen.add(key)) continue;
        final (_, n) = counts[key] ?? (chain, 0);
        counts[key] = (chain, n + 1);
      }
    }
  }
  final common = [
    for (final e in counts.values)
      if (e.$2 >= minCount) e,
  ];
  bool contains(List<String> outer, List<String> inner) {
    for (var s = 0; s + inner.length <= outer.length; s++) {
      var ok = true;
      for (var i = 0; i < inner.length; i++) {
        if (outer[s + i] != inner[i]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  final kept = [
    for (final e in common)
      if (!common.any((o) =>
          o.$1.length > e.$1.length && o.$2 == e.$2 && contains(o.$1, e.$1)))
        e,
  ]..sort((a, b) {
      final byCount = b.$2.compareTo(a.$2);
      return byCount != 0 ? byCount : b.$1.length.compareTo(a.$1.length);
    });
  return kept.take(limit).toList();
}

/// How many mixer channels have each number of inserts (deactivated ones
/// counted: they still sit in the slot).
Map<int, int> insertsPerChannel(List<AnatomyChannel> channels) {
  final counts = <int, int>{};
  for (final c in mixerChannels(channels)) {
    if (c.kind == AnatomyChannelKind.midi) continue;
    counts[c.inserts.length] = (counts[c.inserts.length] ?? 0) + 1;
  }
  return counts;
}

/// How a channel reaches another.
enum RoutingVia { output, send, sideChain }

/// One channel feeding another.
class RoutingSource {
  const RoutingSource(this.channel, this.via, {this.send});
  final AnatomyChannel channel;
  final RoutingVia via;

  /// For [RoutingVia.send] and [RoutingVia.sideChain], the send itself.
  final AnatomySend? send;
}

/// Every channel feeding [destination], in project order: by its output,
/// by a send (switched off ones included — the hint says so), or into a
/// plug-in's side-chain.
List<RoutingSource> sourcesOf(List<AnatomyChannel> channels, String destination) {
  return [
    for (final c in channels) ...[
      if (c.output == destination) RoutingSource(c, RoutingVia.output),
      for (final s in c.sends)
        if (s.destination == destination)
          RoutingSource(
            c,
            s.sideChainOf == null ? RoutingVia.send : RoutingVia.sideChain,
            send: s,
          ),
    ],
  ];
}

/// Destinations — buses, FX channels and outputs — with what feeds them,
/// busiest first; ties in project order.
List<(String, List<RoutingSource>)> destinations(List<AnatomyChannel> channels) {
  final order = <String>[];
  final names = <String>{};
  void add(String? name) {
    if (name != null && names.add(name)) order.add(name);
  }

  for (final c in channels) {
    if (c.isBus) add(c.name);
  }
  for (final c in channels) {
    add(c.output);
    for (final s in c.sends) {
      add(s.destination);
    }
  }
  final all = [
    for (final name in order) (name, sourcesOf(channels, name)),
  ];
  final indexed = all.indexed.toList()
    ..sort((a, b) {
      final byCount = b.$2.$2.length.compareTo(a.$2.$2.length);
      return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
    });
  return [for (final (_, e) in indexed) e];
}

/// Where [channel]'s sound ends up: each hop of its output, ending at a
/// destination that isn't a channel (an output such as "Stereo Out") or at
/// one with no output. A loop ends where it would repeat.
List<String> signalPath(List<AnatomyChannel> channels, String channel) {
  final byName = {for (final c in channels) c.name: c};
  final path = [channel];
  var next = byName[channel]?.output;
  while (next != null && !path.contains(next)) {
    path.add(next);
    next = byName[next]?.output;
  }
  return path;
}

/// Mixer channels whose output was read as connected to nothing.
List<AnatomyChannel> channelsGoingNowhere(List<AnatomyChannel> channels) => [
      for (final c in mixerChannels(channels))
        if (c.kind != AnatomyChannelKind.midi &&
            c.faderPosition != null &&
            c.output == null)
          c,
    ];

/// Tracks that go straight to an output in a project that has buses — on
/// purpose, often, but worth a look when mixing in groups.
List<AnatomyChannel> channelsSkippingBuses(List<AnatomyChannel> channels) {
  final names = {for (final c in channels) c.name};
  if (!channels.any((c) => c.isBus)) return const [];
  return [
    for (final c in mixerChannels(channels))
      if (!c.isBus &&
          c.kind != AnatomyChannelKind.midi &&
          c.output != null &&
          !names.contains(c.output))
        c,
  ];
}

/// Whether [query] finds [channel]: its name, its instrument or a plug-in
/// in its slots, ignoring case.
bool channelMatches(AnatomyChannel channel, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return channel.name.toLowerCase().contains(q) ||
      (channel.instrument?.toLowerCase().contains(q) ?? false) ||
      channel.inserts.any((i) => i.plugin.toLowerCase().contains(q)) ||
      channel.stripModules.any((m) => m.plugin.toLowerCase().contains(q));
}

/// Whether [query] finds [plugin] by name.
bool pluginMatches(AnatomyPlugin plugin, String query) {
  final q = query.trim().toLowerCase();
  return q.isEmpty || plugin.name.toLowerCase().contains(q);
}
