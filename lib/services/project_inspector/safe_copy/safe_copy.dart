import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../models/project_stats.dart';
import '../../daw_parsers/cubase_project_parser.dart';
import '../project_copy.dart';

/// Where a plug-in sits in a project.
enum PluginSlotKind { insert, strip, instrument, rack }

/// One plug-in instance a Safe Copy can switch off (#220).
class PluginSwitch {
  const PluginSwitch({
    required this.plugin,
    required this.channel,
    required this.kind,
    required this.at,
    required this.off,
  });

  /// The plug-in's name, as the Inspector lists it.
  final String plugin;

  /// The track, or the rack's output channel, it is on.
  final String channel;
  final PluginSlotKind kind;

  /// Where its on/off flag sits in the file: what tells instances apart.
  final int at;

  /// Already switched off in the project.
  final bool off;
}

/// Switches plug-ins off in a project's bytes, one DAW's format each. Pure:
/// bytes in, bytes out.
abstract interface class ProjectSafeCopyWriter {
  /// Every plug-in instance [bytes] holds that can be switched off.
  List<PluginSwitch> switches(Uint8List bytes);

  /// [bytes] with [which] switched off, and nothing else changed.
  Uint8List switchOff(Uint8List bytes, List<PluginSwitch> which);
}

/// The writer for [projectPath]'s format; null for a DAW with none yet.
ProjectSafeCopyWriter? safeCopyWriterFor(String projectPath) =>
    switch (p.extension(projectPath).toLowerCase()) {
      '.cpr' || '.npr' => const CubaseSafeCopyWriter(),
      _ => null,
    };

/// Every plug-in instance in the project at [projectPath], read on an
/// isolate of its own: a big project takes a moment to read.
Future<List<PluginSwitch>> readPluginSwitches(String projectPath) {
  final w = safeCopyWriterFor(projectPath);
  if (w == null) {
    throw UnsupportedError('No Safe Copy writer for $projectPath');
  }
  return Isolate.run(
    () async => w.switches(await File(projectPath).readAsBytes()),
  );
}

/// [writeSafeCopy] on an isolate of its own: it reads the project twice.
Future<SafeCopy> writeSafeCopyInBackground(
  String projectPath,
  Set<String> plugins,
) => Isolate.run(
  () => writeSafeCopy(projectPath: projectPath, plugins: plugins),
);

/// One plug-in a Safe Copy can switch off, all its instances together:
/// what the Safe Copy dialog lists.
class SafeCopyChoice {
  const SafeCopyChoice({
    required this.plugin,
    required this.on,
    required this.off,
    required this.channels,
  });

  final String plugin;

  /// Instances still on: what switching it off changes.
  final int on;

  /// Instances already off in the project.
  final int off;

  /// Where it is used, in the project's order, each once.
  final List<String> channels;
}

/// [switches] by plug-in, ignoring case as [writeSafeCopy] does, sorted by
/// name: the spelling of the first instance names it.
List<SafeCopyChoice> safeCopyChoices(List<PluginSwitch> switches) {
  final byName = <String, List<PluginSwitch>>{};
  for (final s in switches) {
    (byName[s.plugin.toLowerCase()] ??= []).add(s);
  }
  return [
    for (final group in byName.values)
      SafeCopyChoice(
        plugin: group.first.plugin,
        on: group.where((s) => !s.off).length,
        off: group.where((s) => s.off).length,
        channels: {for (final s in group) s.channel}.toList(),
      ),
  ]..sort((a, b) => a.plugin.toLowerCase().compareTo(b.plugin.toLowerCase()));
}

/// A Safe Copy as written.
class SafeCopy {
  const SafeCopy({this.path, required this.switchedOff});

  /// Where it was written; null when none of the plug-ins was on, and
  /// nothing was written.
  final String? path;

  /// The instances it switched off, by plug-in.
  final Map<String, int> switchedOff;

  int get total => switchedOff.values.fold(0, (a, b) => a + b);
}

/// Writes a copy of the project at [projectPath] that doesn't load
/// [plugins] (by name, ignoring case) — every instance switched off, as
/// Cubase's own "Deactivate" does — beside it as `<name> (safe copy).<ext>`
/// unless [targetPath] says otherwise. For a project a plug-in crashes on
/// open: the copy opens, and the plug-in can be switched back on, or
/// replaced, from inside the DAW. The original is only read.
///
/// The copy is checked before it is kept: read back, every one of those
/// instances must be off and every other plug-in as it was.
Future<SafeCopy> writeSafeCopy({
  required String projectPath,
  required Set<String> plugins,
  ProjectSafeCopyWriter? writer,
  String? targetPath,
}) async {
  final w = writer ?? safeCopyWriterFor(projectPath);
  if (w == null) {
    throw UnsupportedError('No Safe Copy writer for $projectPath');
  }
  final wanted = {for (final name in plugins) name.toLowerCase()};
  final original = await File(projectPath).readAsBytes();
  final before = w.switches(original);
  final chosen = [
    for (final s in before)
      if (!s.off && wanted.contains(s.plugin.toLowerCase())) s,
  ];
  if (chosen.isEmpty) return const SafeCopy(switchedOff: {});

  final bytes = w.switchOff(original, chosen);
  final after = w.switches(bytes);
  final chosenAt = {for (final s in chosen) s.at};
  final readsRight = after.length == before.length &&
      [
        for (var i = 0; i < after.length; i++)
          after[i].at == before[i].at &&
              after[i].plugin == before[i].plugin &&
              after[i].off == (before[i].off || chosenAt.contains(before[i].at)),
      ].every((ok) => ok);
  if (!readsRight) {
    throw const CopyCheckFailed('the copy does not read as switched off');
  }

  final target = targetPath ??
      copyPathBeside(projectPath, 'safe copy', (path) => File(path).existsSync());
  await writeCheckedFile(target, bytes);
  final counts = <String, int>{};
  for (final s in chosen) {
    counts[s.plugin] = (counts[s.plugin] ?? 0) + 1;
  }
  return SafeCopy(path: target, switchedOff: counts);
}

/// Cubase's on/off is the `Active` flag in each plug-in's attributes — an
/// `i64`, 0 for a plug-in deactivated in its slot, which Cubase doesn't
/// load. Switching one off rewrites those 8 bytes in place: not one other
/// byte of the project moves. Inserts, channel strip modules, instrument
/// tracks' instruments and the VST Instruments rack all have one.
class CubaseSafeCopyWriter implements ProjectSafeCopyWriter {
  const CubaseSafeCopyWriter();

  @override
  List<PluginSwitch> switches(Uint8List bytes) {
    final parser = CubaseProjectParser(bytes);
    final out = <PluginSwitch>[];
    void add(String name, String channel, PluginSlotKind kind, int? at,
        bool? off) {
      if (at == null) return;
      out.add(PluginSwitch(
        plugin: cleanPluginName(name),
        channel: channel,
        kind: kind,
        at: at,
        off: off ?? false,
      ));
    }

    for (final t in parser.readTracks()) {
      if (t.instrument case final name?) {
        add(name, t.name, PluginSlotKind.instrument, t.instrumentActiveAt,
            null);
      }
      for (final i in t.inserts) {
        add(i.plugin, t.name, PluginSlotKind.insert, i.activeAt, i.deactivated);
      }
      for (final m in t.strip) {
        // The channel EQ is part of every channel, not a plug-in.
        if (m.kind == CubaseStripKind.eq) continue;
        add(m.plugin.plugin, t.name, PluginSlotKind.strip, m.plugin.activeAt,
            m.plugin.deactivated);
      }
    }
    // An instrument with several outputs is one instance.
    final rackSeen = <int>{};
    for (final r in parser.readRackInstruments()) {
      final at = r.activeAt;
      if (r.plugin == null || at == null || !rackSeen.add(at)) continue;
      add(r.plugin!, r.channel, PluginSlotKind.rack, at, r.deactivated);
    }
    // An instrument track's flag isn't read as "off" above; read it here.
    final data = ByteData.sublistView(bytes);
    return [
      for (final s in out)
        s.kind == PluginSlotKind.instrument
            ? PluginSwitch(
                plugin: s.plugin,
                channel: s.channel,
                kind: s.kind,
                at: s.at,
                off: data.getInt64(s.at) == 0,
              )
            : s,
    ]..sort((a, b) => a.at.compareTo(b.at));
  }

  @override
  Uint8List switchOff(Uint8List bytes, List<PluginSwitch> which) {
    final out = Uint8List.fromList(bytes);
    final data = ByteData.sublistView(out);
    for (final s in which) {
      // Only ever a flag that reads "on": anything else isn't one.
      if (data.getInt64(s.at) != 1) {
        throw CopyCheckFailed('no on/off flag at ${s.at}');
      }
      data.setInt64(s.at, 0);
    }
    return out;
  }
}
