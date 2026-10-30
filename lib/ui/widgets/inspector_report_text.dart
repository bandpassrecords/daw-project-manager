import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../models/project_anatomy.dart';
import '../../services/project_inspector/media_check.dart';
import '../dialogs/archive_project_dialog.dart' show formatByteSize;
import 'project_inspector_view.dart';

/// A table cell: a `|` would end it, a line break the row.
String _cell(String text) =>
    text.replaceAll('|', r'\|').replaceAll(RegExp(r'[\r\n]+'), ' ');

/// "150 BPM", "4/4", "48 kHz · 24-bit", "A minor": the project's facts the
/// file holds, labelled.
List<String> _facts(AppLocalizations l10n, ProjectAnatomy a) => [
  if (a.tempo != null) '${l10n.inspectorTileTempo}: ${trimNumber(a.tempo!)} BPM',
  if (a.timeSignature case (final n, final d))
    '${l10n.inspectorTileTimeSignature}: $n/$d',
  if (a.sampleRate != null)
    '${l10n.inspectorTileSampleRate}: '
        '${[
          '${trimNumber(a.sampleRate! / 1000)} kHz',
          if (a.bitDepth != null) l10n.inspectorBitDepth(a.bitDepth!),
        ].join(' · ')}',
  if (a.key != null) '${l10n.inspectorTileKey}: ${a.key}',
];

/// Tracks by kind: "Audio 6, Instrument 4", from the channels where they
/// are read, else from the scan's counts.
String? _trackTypes(AppLocalizations l10n, ProjectAnatomy a) {
  final channels = a.channels;
  final rows = channels != null
      ? [
          for (final (kind, label) in channelKindLabels(l10n))
            if (channels.where((c) => c.kind == kind).length case final n
                when n > 0)
              (label, n),
        ]
      : a.stats == null
      ? const <(String, int)>[]
      : statsTrackRows(l10n, a.stats!);
  if (rows.isEmpty) return null;
  return [for (final (label, n) in rows) '$label $n'].join(', ');
}

/// The Inspector's report on one project as Markdown (#224), in the user's
/// language: the overview, plug-ins by kind, every channel, audio I/O, the
/// audio files' state and the project's notes — what this DAW's reader
/// gives. For archiving, for a client, or for reopening a project years on.
String inspectorReportMarkdown(
  AppLocalizations l10n,
  ProjectAnatomy a, {
  List<MediaCheck>? media,
  DateTime? now,
}) {
  final out = StringBuffer()
    ..writeln('# ${p.basenameWithoutExtension(a.filePath)}')
    ..writeln();
  if (a.dawType != null) {
    out.writeln(l10n.inspectorSavedWith(a.dawType!, a.savedWith ?? '').trim());
    out.writeln();
  }
  out
    ..writeln('`${a.filePath}` · ${formatByteSize(a.fileSize)}')
    ..writeln()
    ..writeln('## ${l10n.reportOverview}')
    ..writeln();
  for (final fact in _facts(l10n, a)) {
    out.writeln('- $fact');
  }
  if (_trackTypes(l10n, a) case final types?) {
    out.writeln('- ${l10n.inspectorStatTrackTypes}: $types');
  }
  final instances = a.plugins.fold<int>(0, (s, pl) => s + (pl.instances ?? 1));
  out.writeln(
    '- ${l10n.inspectorTabPlugins}: '
    '${l10n.inspectorPluginSummary(a.plugins.length, instances)}',
  );
  if (media != null) {
    final missing = media.where((m) => m.status == MediaStatus.missing).length;
    out.writeln(
      '- ${l10n.inspectorTabMedia}: '
      '${missing == 0 ? l10n.inspectorMediaAllFound(media.length) : l10n.inspectorMediaSummary(missing, media.length)}',
    );
  }

  if (a.plugins.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## ${l10n.inspectorTabPlugins}');
    final groups = a.pluginInstancesKnown
        ? [
            (
              l10n.inspectorGroupInstruments,
              a.plugins.where((pl) => pl.role == AnatomyPluginRole.instrument),
            ),
            (
              l10n.inspectorGroupStock,
              a.plugins.where(
                (pl) => pl.role == AnatomyPluginRole.effect && pl.stock == true,
              ),
            ),
            (
              l10n.inspectorGroupThirdParty,
              a.plugins.where(
                (pl) => pl.role == AnatomyPluginRole.effect && pl.stock != true,
              ),
            ),
          ]
        : [(l10n.inspectorPluginNamesOnly, a.plugins)];
    for (final (title, plugins) in groups) {
      if (plugins.isEmpty) continue;
      out
        ..writeln()
        ..writeln('### $title (${plugins.length})')
        ..writeln();
      for (final pl in plugins) {
        final maker = [?pl.vendor, ?pl.format].join(' · ');
        out.writeln(
          [
            '- **${pl.name}**',
            if (pl.instances != null) '×${pl.instances}',
            if (maker.isNotEmpty) '($maker)',
            if (pl.channels.isNotEmpty) '— ${pl.channels.join(', ')}',
          ].join(' '),
        );
      }
    }
  }

  final channels = a.channels;
  if (channels != null && channels.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## ${l10n.inspectorTabTracks}')
      ..writeln()
      ..writeln(
        '| ${l10n.reportColumnChannel} | ${l10n.reportColumnKind} | '
        '${l10n.inspectorOutput} | ${l10n.inspectorFader} | '
        '${l10n.inspectorInserts} | ${l10n.inspectorSends} |',
      )
      ..writeln('|---|---|---|---|---|---|');
    final kinds = {for (final (k, label) in channelKindLabels(l10n)) k: label};
    for (final c in channels) {
      final fader = c.volumeDb != null
          ? formatDb(c.volumeDb!)
          : c.faderPosition != null
          ? '${(c.faderPosition! * 100).round()}%'
          : '';
      final inserts = [
        if (c.instrument != null) c.instrument!,
        for (final i in c.inserts)
          '${i.slot + 1}. ${i.plugin}'
              '${i.deactivated == true ? ' (${l10n.inspectorDeactivated})' : ''}',
        for (final m in c.stripModules) stripModuleText(l10n, m),
      ].join(', ');
      final sends = [
        for (final s in c.sends)
          [
            s.sideChainOf != null
                ? l10n.inspectorSideChainInto(s.sideChainOf!)
                : s.destination ?? l10n.inspectorNotConnected,
            if (s.levelDb != null) formatDb(s.levelDb!),
          ].join(' '),
      ].join(', ');
      out.writeln(
        '| ${[c.name, kinds[c.kind] ?? c.kind.name, c.output ?? '', fader, inserts, sends].map(_cell).join(' | ')} |',
      );
    }
  }

  if (a.audioIo case final io?) {
    out
      ..writeln()
      ..writeln('## ${l10n.inspectorTabAudioIo}')
      ..writeln()
      ..writeln(
        '- ${l10n.inspectorAudioDriver}: ${io.driver ?? l10n.inspectorUnnamedDriver}',
      );
    if (io.platform != null) {
      out.writeln('- ${l10n.inspectorSavedOn(io.platform!)}');
    }
    for (final (label, buses) in [
      (l10n.inspectorInputBuses, io.inputBuses),
      (l10n.inspectorOutputBuses, io.outputBuses),
    ]) {
      if (buses.isEmpty) continue;
      out.writeln(
        '- $label: ${[for (final b in buses) b.ports.isEmpty ? b.name : '${b.name} (${b.ports.join(', ')})'].join('; ')}',
      );
    }
  }

  final missing = [
    for (final m in media ?? const <MediaCheck>[])
      if (m.status == MediaStatus.missing) m,
  ];
  if (missing.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## ${l10n.reportMissingFiles(missing.length)}')
      ..writeln();
    for (final m in missing) {
      final stored = m.reference.candidates.firstOrNull;
      out.writeln(
        '- ${m.reference.fileName}${stored == null ? '' : ' — `$stored`'}',
      );
    }
  }

  if (a.notes case final notes?) {
    out
      ..writeln()
      ..writeln('## ${l10n.inspectorNotesTitle}')
      ..writeln()
      ..writeln(notes);
  }

  final date = DateFormat.yMMMd(l10n.localeName).format(now ?? DateTime.now());
  out
    ..writeln()
    ..writeln('---')
    ..writeln()
    ..writeln(l10n.reportMadeBy(date));
  return out.toString();
}

/// The project in a few lines, short enough for an email or a chat: what
/// saved it, its facts, its tracks and plug-ins (the third-party ones by
/// name), and missing audio.
String inspectorSummaryText(
  AppLocalizations l10n,
  ProjectAnatomy a, {
  List<MediaCheck>? media,
}) {
  final lines = <String>[
    [
      p.basenameWithoutExtension(a.filePath),
      if (a.dawType != null)
        l10n.inspectorSavedWith(a.dawType!, a.savedWith ?? '').trim(),
    ].join(' — '),
  ];
  final facts = [
    if (a.tempo != null) '${trimNumber(a.tempo!)} BPM',
    if (a.timeSignature case (final n, final d)) '$n/$d',
    if (a.sampleRate != null) '${trimNumber(a.sampleRate! / 1000)} kHz',
    if (a.key != null) a.key!,
  ];
  if (facts.isNotEmpty) lines.add(facts.join(' · '));
  final instances = a.plugins.fold<int>(0, (s, pl) => s + (pl.instances ?? 1));
  final trackCount = a.channels
      ?.where((c) => c.kind != AnatomyChannelKind.folder)
      .length;
  lines.add(
    [
      if (trackCount != null)
        '$trackCount ${l10n.inspectorTileTracks(trackCount)}',
      '${l10n.inspectorTabPlugins}: '
          '${l10n.inspectorPluginSummary(a.plugins.length, instances)}',
    ].join(' · '),
  );
  String named(Iterable<AnatomyPlugin> plugins) => [
    for (final pl in plugins)
      pl.instances == null || pl.instances == 1
          ? pl.name
          : '${pl.name} ×${pl.instances}',
  ].join(', ');
  if (a.pluginInstancesKnown) {
    for (final (label, plugins) in [
      (
        l10n.inspectorGroupInstruments,
        a.plugins.where((pl) => pl.role == AnatomyPluginRole.instrument),
      ),
      (
        l10n.inspectorGroupThirdParty,
        a.plugins.where(
          (pl) => pl.role == AnatomyPluginRole.effect && pl.stock != true,
        ),
      ),
    ]) {
      if (plugins.isNotEmpty) lines.add('$label: ${named(plugins)}');
    }
  }
  final missing =
      media?.where((m) => m.status == MediaStatus.missing).length ?? 0;
  if (missing > 0) lines.add(l10n.reportMissingFiles(missing));
  return lines.join('\n');
}
