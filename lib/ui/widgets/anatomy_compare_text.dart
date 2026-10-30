import '../../generated/l10n/app_localizations.dart';
import '../../models/project_anatomy.dart';
import '../../services/project_inspector/compare/anatomy_diff.dart';
import 'project_inspector_view.dart';

/// [change] as a sentence, in the user's language: "Fader −4.0 dB →
/// −11.4 dB", "Slot 2: OTT replaced by Saturn 2".
String changeText(AppLocalizations l10n, AnatomyChange change) {
  final c = change;
  String text(Object? v) => v == null ? l10n.compareNoneValue : '$v';
  String level(Object? v) => v is! double
      ? text(v)
      : c.position
      ? '${(v * 100).round()}%'
      : formatDb(v);
  String rate(Object? v) =>
      v is int ? '${trimNumber(v / 1000)} kHz' : text(v);
  String kind(Object? v) => v is AnatomyChannelKind
      ? channelKindLabels(l10n).firstWhere((e) => e.$1 == v).$2
      : text(v);
  // Slots are numbered from 1, as DAWs show them.
  final slot = (c.slot ?? 0) + 1;
  final plugin = c.subject ?? '';
  final b = c.before;
  final a = c.after;
  return switch (c.kind) {
    AnatomyChangeKind.tempo => l10n.changeTempo(
      trimNumber((b as num).toDouble()),
      trimNumber((a as num).toDouble()),
    ),
    AnatomyChangeKind.timeSignature => l10n.changeTimeSignature(text(b), text(a)),
    AnatomyChangeKind.sampleRate => l10n.changeSampleRate(rate(b), rate(a)),
    AnatomyChangeKind.bitDepth => l10n.changeBitDepth(
      l10n.inspectorBitDepth(b as int),
      l10n.inspectorBitDepth(a as int),
    ),
    AnatomyChangeKind.key => l10n.changeKey(text(b), text(a)),
    AnatomyChangeKind.pluginAdded => l10n.changePluginAdded(plugin),
    AnatomyChangeKind.pluginRemoved => l10n.changePluginRemoved(plugin),
    AnatomyChangeKind.channelAdded => l10n.changeChannelAdded,
    AnatomyChangeKind.channelRemoved => l10n.changeChannelRemoved,
    AnatomyChangeKind.renamed => l10n.changeRenamed(text(b)),
    AnatomyChangeKind.channelKind => l10n.changeKind(kind(b), kind(a)),
    AnatomyChangeKind.folder => l10n.changeFolder(text(b), text(a)),
    AnatomyChangeKind.output => l10n.changeOutput(text(b), text(a)),
    AnatomyChangeKind.volume => l10n.changeFader(level(b), level(a)),
    AnatomyChangeKind.pan => l10n.changePan(
      formatPan((b as num).toDouble()),
      formatPan((a as num).toDouble()),
    ),
    AnatomyChangeKind.muted =>
      a == true ? l10n.changeMuted : l10n.changeUnmuted,
    AnatomyChangeKind.soloed =>
      a == true ? l10n.changeSoloed : l10n.changeUnsoloed,
    AnatomyChangeKind.eqBands => l10n.changeEqBands(text(b), text(a)),
    AnatomyChangeKind.instrument => l10n.changeInstrument(text(b), text(a)),
    AnatomyChangeKind.instrumentPreset ||
    AnatomyChangeKind.insertPreset => l10n.changePreset(plugin, text(b), text(a)),
    AnatomyChangeKind.insertAdded => l10n.changeInsertAdded(plugin, slot),
    AnatomyChangeKind.insertRemoved => l10n.changeInsertRemoved(plugin, slot),
    AnatomyChangeKind.insertReplaced => l10n.changeInsertReplaced(
      slot,
      text(b),
      text(a),
    ),
    AnatomyChangeKind.insertMoved => l10n.changeInsertMoved(
      plugin,
      (b as int) + 1,
      (a as int) + 1,
    ),
    AnatomyChangeKind.insertSwitched || AnatomyChangeKind.stripSwitched =>
      a == true ? l10n.changePluginOn(plugin) : l10n.changePluginOff(plugin),
    AnatomyChangeKind.stripAdded => l10n.changeStripAdded(plugin),
    AnatomyChangeKind.stripRemoved => l10n.changeStripRemoved(plugin),
    AnatomyChangeKind.stripReplaced => l10n.changeStripReplaced(text(b), text(a)),
    AnatomyChangeKind.stripBypassed =>
      a == true ? l10n.changeStripBypassed : l10n.changeStripBack,
    AnatomyChangeKind.sendAdded => l10n.changeSendAdded(plugin),
    AnatomyChangeKind.sendRemoved => l10n.changeSendRemoved(plugin),
    AnatomyChangeKind.sendLevel => l10n.changeSendLevel(
      plugin,
      level(b),
      level(a),
    ),
    AnatomyChangeKind.sendSwitched =>
      a == true ? l10n.changeSendOn(plugin) : l10n.changeSendOff(plugin),
    AnatomyChangeKind.sendPreFader =>
      a == true ? l10n.changeSendPre(plugin) : l10n.changeSendPost(plugin),
  };
}

/// A channel's name in a comparison: "Audio 01 → Lead" when renamed.
String comparedChannelName(ChannelComparison c) {
  final a = c.a?.name;
  final b = c.b?.name;
  if (a == null || b == null || a == b) return (b ?? a)!;
  return '$a → $b';
}

/// The comparison in a few lines, for an email or a chat: A and B, the
/// totals, the project's changes, then each changed channel with its
/// changes — in the user's language.
String compareSummaryText(
  AppLocalizations l10n,
  AnatomyDiff diff, {
  required String aName,
  required String bName,
}) {
  final out = StringBuffer()
    ..writeln('${l10n.compareTitle}: A = $aName, B = $bName')
    ..writeln(
      [
        l10n.compareChangesCount(diff.changeCount),
        if (diff.channelsCompared) ...[
          l10n.compareChannelsChanged(diff.changedChannels),
          l10n.compareOnlyInA(diff.onlyInA),
          l10n.compareOnlyInB(diff.onlyInB),
        ],
      ].join(' · '),
    );
  if (diff.projectChanges.isNotEmpty) {
    out
      ..writeln()
      ..writeln(l10n.compareProject);
    for (final c in diff.projectChanges) {
      out.writeln('- ${changeText(l10n, c)}');
    }
  }
  for (final ch in diff.channels) {
    if (!ch.changed) continue;
    out
      ..writeln()
      ..writeln(comparedChannelName(ch));
    for (final c in ch.changes) {
      if (c.kind == AnatomyChangeKind.renamed) continue;
      out.writeln('- ${changeText(l10n, c)}');
    }
  }
  return out.toString().trimRight();
}
