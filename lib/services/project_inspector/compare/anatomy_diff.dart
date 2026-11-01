import '../../../models/project_anatomy.dart';

/// What a change is about: the Compare view's filter chips (#223).
enum AnatomyChangeArea { project, tracks, levels, sends, plugins }

/// One kind of change between two projects.
enum AnatomyChangeKind {
  // The project.
  tempo(AnatomyChangeArea.project),
  timeSignature(AnatomyChangeArea.project),
  sampleRate(AnatomyChangeArea.project),
  bitDepth(AnatomyChangeArea.project),
  key(AnatomyChangeArea.project),
  // Plug-ins in use, for a DAW whose channels aren't read.
  pluginAdded(AnatomyChangeArea.plugins),
  pluginRemoved(AnatomyChangeArea.plugins),
  // A channel.
  channelAdded(AnatomyChangeArea.tracks),
  channelRemoved(AnatomyChangeArea.tracks),
  renamed(AnatomyChangeArea.tracks),
  channelKind(AnatomyChangeArea.tracks),
  folder(AnatomyChangeArea.tracks),
  output(AnatomyChangeArea.tracks),
  volume(AnatomyChangeArea.levels),
  pan(AnatomyChangeArea.levels),
  muted(AnatomyChangeArea.levels),
  soloed(AnatomyChangeArea.levels),
  eqBands(AnatomyChangeArea.levels),
  instrument(AnatomyChangeArea.plugins),
  instrumentPreset(AnatomyChangeArea.plugins),
  insertAdded(AnatomyChangeArea.plugins),
  insertRemoved(AnatomyChangeArea.plugins),
  insertReplaced(AnatomyChangeArea.plugins),
  insertMoved(AnatomyChangeArea.plugins),
  insertSwitched(AnatomyChangeArea.plugins),
  insertPreset(AnatomyChangeArea.plugins),
  stripAdded(AnatomyChangeArea.plugins),
  stripRemoved(AnatomyChangeArea.plugins),
  stripReplaced(AnatomyChangeArea.plugins),
  stripSwitched(AnatomyChangeArea.plugins),
  stripBypassed(AnatomyChangeArea.plugins),
  sendAdded(AnatomyChangeArea.sends),
  sendRemoved(AnatomyChangeArea.sends),
  sendLevel(AnatomyChangeArea.sends),
  sendSwitched(AnatomyChangeArea.sends),
  sendPreFader(AnatomyChangeArea.sends);

  const AnatomyChangeKind(this.area);
  final AnatomyChangeArea area;
}

/// One change from project A to project B. [before] and [after] are the
/// values as read — a `double` dB, a `bool`, a name — for the view to put
/// into words; [subject] names what changed inside the channel (a plug-in,
/// a send's destination) and [slot] the insert slot, where there is one.
class AnatomyChange {
  const AnatomyChange(
    this.kind, {
    this.subject,
    this.slot,
    this.before,
    this.after,
    this.position = false,
  });

  final AnatomyChangeKind kind;
  final String? subject;
  final int? slot;
  final Object? before;
  final Object? after;

  /// A level as the fader's travel, 0 to 1, where the reader knows no dB.
  final bool position;

  AnatomyChangeArea get area => kind.area;

  @override
  String toString() =>
      '${kind.name}${subject == null ? '' : ' $subject'}'
      '${slot == null ? '' : ' #$slot'}: $before → $after';
}

/// A channel of A and the channel of B it is taken to be: one of them null
/// for a channel only in that project.
class ChannelComparison {
  const ChannelComparison({this.a, this.b, this.changes = const []});
  final AnatomyChannel? a;
  final AnatomyChannel? b;
  final List<AnatomyChange> changes;

  bool get onlyInA => b == null;
  bool get onlyInB => a == null;
  bool get changed => changes.isNotEmpty;

  /// B's name where there is a B: what the channel is called now.
  String get name => (b ?? a)!.name;
}

/// Everything that differs from project A to project B.
class AnatomyDiff {
  const AnatomyDiff({
    required this.projectChanges,
    required this.channels,
    required this.channelsCompared,
  });

  /// Tempo, sample rate… and, where channels aren't read, plug-ins in use.
  final List<AnatomyChange> projectChanges;

  /// Every channel of either project: B's order, a channel only in A just
  /// after the one it followed there.
  final List<ChannelComparison> channels;

  /// Whether both projects' channels were read.
  final bool channelsCompared;

  Iterable<AnatomyChange> get allChanges => [
    ...projectChanges,
    for (final c in channels) ...c.changes,
  ];

  int get changeCount => allChanges.length;
  int get onlyInA => channels.where((c) => c.onlyInA).length;
  int get onlyInB => channels.where((c) => c.onlyInB).length;

  /// Channels in both projects that changed.
  int get changedChannels =>
      channels.where((c) => c.a != null && c.b != null && c.changed).length;
  int get unchangedChannels => channels.where((c) => !c.changed).length;
  int get pluginChanges =>
      allChanges.where((c) => c.area == AnatomyChangeArea.plugins).length;
}

/// A fader or send level moved by less than this reads the same: the
/// Inspector shows one decimal.
const _dbTolerance = 0.05;

/// Everything that differs from [a] to [b] (#223), for any DAW with an
/// anatomy reader: what one reader leaves null is not compared.
///
/// Channels are matched by name first (in order, for names used twice), then
/// a renamed one by kind and place — between the same matched neighbours.
AnatomyDiff diffAnatomy(ProjectAnatomy a, ProjectAnatomy b) {
  final project = <AnatomyChange>[];
  void header(AnatomyChangeKind kind, Object? x, Object? y) {
    if (x != null && y != null && x != y) {
      project.add(AnatomyChange(kind, before: x, after: y));
    }
  }

  if (a.tempo != null &&
      b.tempo != null &&
      (a.tempo! - b.tempo!).abs() > 0.001) {
    project.add(
      AnatomyChange(AnatomyChangeKind.tempo, before: a.tempo, after: b.tempo),
    );
  }
  header(
    AnatomyChangeKind.timeSignature,
    a.timeSignature == null
        ? null
        : '${a.timeSignature!.$1}/${a.timeSignature!.$2}',
    b.timeSignature == null
        ? null
        : '${b.timeSignature!.$1}/${b.timeSignature!.$2}',
  );
  header(AnatomyChangeKind.sampleRate, a.sampleRate, b.sampleRate);
  header(AnatomyChangeKind.bitDepth, a.bitDepth, b.bitDepth);
  header(AnatomyChangeKind.key, a.key, b.key);

  final ca = a.channels;
  final cb = b.channels;
  if (ca == null || cb == null) {
    final before = {for (final pl in a.plugins) pl.name.toLowerCase(): pl.name};
    final after = {for (final pl in b.plugins) pl.name.toLowerCase(): pl.name};
    for (final MapEntry(:key, :value) in before.entries) {
      if (!after.containsKey(key)) {
        project.add(
          AnatomyChange(AnatomyChangeKind.pluginRemoved, subject: value),
        );
      }
    }
    for (final MapEntry(:key, :value) in after.entries) {
      if (!before.containsKey(key)) {
        project.add(
          AnatomyChange(AnatomyChangeKind.pluginAdded, subject: value),
        );
      }
    }
    return AnatomyDiff(
      projectChanges: project,
      channels: const [],
      channelsCompared: false,
    );
  }

  final pairOfB = matchChannels(ca, cb);
  final bOfA = {for (final MapEntry(:key, :value) in pairOfB.entries) value: key};
  final out = <ChannelComparison>[];
  // A's channels only in A go just after the A channel before them.
  final unmatchedAfter = <int, List<int>>{};
  var lastMatchedB = -1;
  for (var i = 0; i < ca.length; i++) {
    final j = bOfA[i];
    if (j != null) {
      lastMatchedB = j;
    } else {
      (unmatchedAfter[lastMatchedB] ??= []).add(i);
    }
  }
  void onlyA(int anchor) {
    for (final i in unmatchedAfter[anchor] ?? const <int>[]) {
      out.add(
        ChannelComparison(
          a: ca[i],
          changes: const [AnatomyChange(AnatomyChangeKind.channelRemoved)],
        ),
      );
    }
  }

  onlyA(-1);
  for (var j = 0; j < cb.length; j++) {
    final i = pairOfB[j];
    out.add(
      i == null
          ? ChannelComparison(
              b: cb[j],
              changes: const [AnatomyChange(AnatomyChangeKind.channelAdded)],
            )
          : ChannelComparison(
              a: ca[i],
              b: cb[j],
              changes: diffChannel(ca[i], cb[j]),
            ),
    );
    if (i != null) onlyA(j);
  }
  return AnatomyDiff(
    projectChanges: project,
    channels: out,
    channelsCompared: true,
  );
}

/// Which channel of [a] each channel of [b] is, by index: B's index → A's.
Map<int, int> matchChannels(List<AnatomyChannel> a, List<AnatomyChannel> b) {
  final pairs = <int, int>{};
  final usedA = <int>{};
  // By name, the n-th of a name with the n-th; then ignoring case.
  for (final exact in [true, false]) {
    String key(String name) => exact ? name : name.toLowerCase();
    final byName = <String, List<int>>{};
    for (var i = 0; i < a.length; i++) {
      if (!usedA.contains(i)) (byName[key(a[i].name)] ??= []).add(i);
    }
    for (var j = 0; j < b.length; j++) {
      if (pairs.containsKey(j)) continue;
      final list = byName[key(b[j].name)];
      if (list == null || list.isEmpty) continue;
      final i = list.removeAt(0);
      pairs[j] = i;
      usedA.add(i);
    }
  }
  // Renamed: same kind, between the same matched neighbours.
  final aOfB = Map.of(pairs);
  int anchorA(int i) {
    for (var k = i - 1; k >= 0; k--) {
      if (usedA.contains(k)) return k;
    }
    return -1;
  }

  int anchorB(int j) {
    for (var k = j - 1; k >= 0; k--) {
      if (aOfB.containsKey(k)) return aOfB[k]!;
    }
    return -1;
  }

  final openA = <(int, AnatomyChannelKind), List<int>>{};
  for (var i = 0; i < a.length; i++) {
    if (!usedA.contains(i)) (openA[(anchorA(i), a[i].kind)] ??= []).add(i);
  }
  for (var j = 0; j < b.length; j++) {
    if (pairs.containsKey(j)) continue;
    final list = openA[(anchorB(j), b[j].kind)];
    if (list == null || list.isEmpty) continue;
    pairs[j] = list.removeAt(0);
  }
  return pairs;
}

/// What changed on one channel from [a] to [b].
List<AnatomyChange> diffChannel(AnatomyChannel a, AnatomyChannel b) {
  final out = <AnatomyChange>[];
  void plain(AnatomyChangeKind kind, Object? x, Object? y) {
    if (x != null && y != null && x != y) {
      out.add(AnatomyChange(kind, before: x, after: y));
    }
  }

  plain(AnatomyChangeKind.renamed, a.name, b.name);
  plain(AnatomyChangeKind.channelKind, a.kind, b.kind);
  if (a.folder != b.folder) {
    out.add(
      AnatomyChange(AnatomyChangeKind.folder, before: a.folder, after: b.folder),
    );
  }
  if (a.output != b.output) {
    out.add(
      AnatomyChange(AnatomyChangeKind.output, before: a.output, after: b.output),
    );
  }

  if (a.volumeDb != null && b.volumeDb != null) {
    if (_dbDiffers(a.volumeDb!, b.volumeDb!)) {
      out.add(
        AnatomyChange(
          AnatomyChangeKind.volume,
          before: a.volumeDb,
          after: b.volumeDb,
        ),
      );
    }
  } else if (a.faderPosition != null &&
      b.faderPosition != null &&
      (a.faderPosition! - b.faderPosition!).abs() > 0.001) {
    // No dB scale: the fader's travel, 0 to 1.
    out.add(
      AnatomyChange(
        AnatomyChangeKind.volume,
        before: a.faderPosition,
        after: b.faderPosition,
        position: true,
      ),
    );
  }
  if (a.pan != null && b.pan != null && (a.pan! - b.pan!).abs() > 0.005) {
    out.add(AnatomyChange(AnatomyChangeKind.pan, before: a.pan, after: b.pan));
  }
  plain(AnatomyChangeKind.muted, a.muted, b.muted);
  plain(AnatomyChangeKind.soloed, a.soloed, b.soloed);
  plain(AnatomyChangeKind.eqBands, a.eqBandsOn, b.eqBandsOn);

  if (a.instrument != b.instrument) {
    out.add(
      AnatomyChange(
        AnatomyChangeKind.instrument,
        before: a.instrument,
        after: b.instrument,
      ),
    );
  } else if (a.instrumentPreset != null &&
      b.instrumentPreset != null &&
      a.instrumentPreset != b.instrumentPreset) {
    out.add(
      AnatomyChange(
        AnatomyChangeKind.instrumentPreset,
        subject: b.instrument,
        before: a.instrumentPreset,
        after: b.instrumentPreset,
      ),
    );
  }

  out.addAll(diffInserts(a.inserts, b.inserts));
  out.addAll(_diffStrip(a, b));
  out.addAll(diffSends(a.sends, b.sends));
  return out;
}

bool _dbDiffers(double x, double y) {
  if (x.isInfinite || y.isInfinite) return x != y;
  return (x - y).abs() >= _dbTolerance;
}

String _plugKey(String name) => name.toLowerCase();

/// Insert changes: the same plug-in in another slot moved, another plug-in
/// in the same slot a replacement, and the rest added or removed.
List<AnatomyChange> diffInserts(List<AnatomyInsert> a, List<AnatomyInsert> b) {
  final out = <AnatomyChange>[];
  final openA = List.of(a);
  final openB = <AnatomyInsert>[];
  // The same plug-in: in the same slot first, then wherever it went.
  final pairs = <(AnatomyInsert, AnatomyInsert)>[];
  for (final y in b) {
    final same = openA.indexWhere(
      (x) => x.slot == y.slot && _plugKey(x.plugin) == _plugKey(y.plugin),
    );
    if (same >= 0) {
      pairs.add((openA.removeAt(same), y));
    } else {
      openB.add(y);
    }
  }
  for (final y in List.of(openB)) {
    final moved = openA.indexWhere(
      (x) => _plugKey(x.plugin) == _plugKey(y.plugin),
    );
    if (moved < 0) continue;
    final x = openA.removeAt(moved);
    openB.remove(y);
    pairs.add((x, y));
  }
  for (final y in List.of(openB)) {
    final replaced = openA.indexWhere((x) => x.slot == y.slot);
    if (replaced < 0) continue;
    final x = openA.removeAt(replaced);
    openB.remove(y);
    out.add(
      AnatomyChange(
        AnatomyChangeKind.insertReplaced,
        slot: y.slot,
        before: x.plugin,
        after: y.plugin,
      ),
    );
  }
  for (final (x, y) in pairs) {
    if (x.slot != y.slot) {
      out.add(
        AnatomyChange(
          AnatomyChangeKind.insertMoved,
          subject: y.plugin,
          slot: y.slot,
          before: x.slot,
          after: y.slot,
        ),
      );
    }
    final wasOn = x.deactivated != true;
    final isOn = y.deactivated != true;
    if (x.deactivated != null && y.deactivated != null && wasOn != isOn) {
      out.add(
        AnatomyChange(
          AnatomyChangeKind.insertSwitched,
          subject: y.plugin,
          slot: y.slot,
          before: wasOn,
          after: isOn,
        ),
      );
    }
    if (x.preset != null && y.preset != null && x.preset != y.preset) {
      out.add(
        AnatomyChange(
          AnatomyChangeKind.insertPreset,
          subject: y.plugin,
          slot: y.slot,
          before: x.preset,
          after: y.preset,
        ),
      );
    }
  }
  for (final x in openA) {
    out.add(
      AnatomyChange(
        AnatomyChangeKind.insertRemoved,
        subject: x.plugin,
        slot: x.slot,
      ),
    );
  }
  for (final y in openB) {
    out.add(
      AnatomyChange(
        AnatomyChangeKind.insertAdded,
        subject: y.plugin,
        slot: y.slot,
      ),
    );
  }
  out.sort((p, q) => (p.slot ?? 0).compareTo(q.slot ?? 0));
  return out;
}

/// Strip changes, module by module kind; the EQ, which every channel has,
/// is left to [AnatomyChangeKind.eqBands].
List<AnatomyChange> _diffStrip(AnatomyChannel a, AnatomyChannel b) {
  final out = <AnatomyChange>[];
  if (a.stripBypassed != null &&
      b.stripBypassed != null &&
      a.stripBypassed != b.stripBypassed) {
    out.add(
      AnatomyChange(
        AnatomyChangeKind.stripBypassed,
        before: a.stripBypassed,
        after: b.stripBypassed,
      ),
    );
  }
  Object keyOf(AnatomyStripModule m) => m.kind ?? _plugKey(m.plugin);
  final openA = a.stripModules.toList();
  for (final y in b.stripModules) {
    final i = openA.indexWhere((x) => keyOf(x) == keyOf(y));
    if (i < 0) {
      out.add(AnatomyChange(AnatomyChangeKind.stripAdded, subject: y.plugin));
      continue;
    }
    final x = openA.removeAt(i);
    if (_plugKey(x.plugin) != _plugKey(y.plugin)) {
      out.add(
        AnatomyChange(
          AnatomyChangeKind.stripReplaced,
          before: x.plugin,
          after: y.plugin,
        ),
      );
    } else if (x.deactivated != null &&
        y.deactivated != null &&
        x.deactivated != y.deactivated) {
      out.add(
        AnatomyChange(
          AnatomyChangeKind.stripSwitched,
          subject: y.plugin,
          before: x.deactivated != true,
          after: y.deactivated != true,
        ),
      );
    }
  }
  for (final x in openA) {
    out.add(AnatomyChange(AnatomyChangeKind.stripRemoved, subject: x.plugin));
  }
  return out;
}

/// Send changes, a send matched by where it goes (and whose side-chain it
/// feeds).
List<AnatomyChange> diffSends(List<AnatomySend> a, List<AnatomySend> b) {
  final out = <AnatomyChange>[];
  String key(AnatomySend s) => '${s.destination}\u0000${s.sideChainOf}';
  String name(AnatomySend s) => s.destination ?? s.sideChainOf ?? '?';
  final openA = List.of(a);
  for (final y in b) {
    final i = openA.indexWhere((x) => key(x) == key(y));
    if (i < 0) {
      out.add(AnatomyChange(AnatomyChangeKind.sendAdded, subject: name(y)));
      continue;
    }
    final x = openA.removeAt(i);
    if (x.levelDb != null && y.levelDb != null) {
      if (_dbDiffers(x.levelDb!, y.levelDb!)) {
        out.add(
          AnatomyChange(
            AnatomyChangeKind.sendLevel,
            subject: name(y),
            before: x.levelDb,
            after: y.levelDb,
          ),
        );
      }
    } else if (x.levelPosition != null &&
        y.levelPosition != null &&
        (x.levelPosition! - y.levelPosition!).abs() > 0.001) {
      out.add(
        AnatomyChange(
          AnatomyChangeKind.sendLevel,
          subject: name(y),
          before: x.levelPosition,
          after: y.levelPosition,
          position: true,
        ),
      );
    }
    if (x.on != y.on) {
      out.add(
        AnatomyChange(
          AnatomyChangeKind.sendSwitched,
          subject: name(y),
          before: x.on,
          after: y.on,
        ),
      );
    }
    if (x.preFader != y.preFader) {
      out.add(
        AnatomyChange(
          AnatomyChangeKind.sendPreFader,
          subject: name(y),
          before: x.preFader,
          after: y.preFader,
        ),
      );
    }
  }
  for (final x in openA) {
    out.add(AnatomyChange(AnatomyChangeKind.sendRemoved, subject: name(x)));
  }
  return out;
}
