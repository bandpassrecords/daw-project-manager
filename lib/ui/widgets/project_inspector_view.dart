import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../models/project_anatomy.dart';
import '../../models/project_stats.dart';
import '../../models/sample_reference.dart';
import '../../services/project_inspector/media_check.dart';
import '../../utils/project_anatomy_stats.dart';
import '../dialogs/archive_project_dialog.dart' show formatByteSize;
import 'project_markers_section.dart';
import 'semantics_safe.dart';

/// The Project Inspector's sections.
enum InspectorSection { tracks, plugins, routing, audioIo, media, statistics }

/// What the Inspector shows about one project: its header facts, then a
/// section at a time. Plain values in, callbacks out — no Riverpod, no
/// Hive — so it is tested as a widget.
/// What the Inspector header's report menu asks for (#224).
enum InspectorReportAction { copySummary, markdown, tracksCsv, pluginsCsv }

class ProjectInspectorView extends StatefulWidget {
  const ProjectInspectorView({
    super.key,
    required this.anatomy,
    required this.search,
    required this.onClose,
    required this.onReload,
    required this.onOpenOther,
    this.mediaChecks,
    this.mediaChecking = false,
    this.onRelink,
    this.onSafeCopy,
    this.onCompare,
    this.onReport,
    this.initialSection = InspectorSection.tracks,
  });

  final ProjectAnatomy anatomy;

  /// What the dashboard's search box holds: filters tracks and plug-ins.
  final String search;
  final VoidCallback onClose;
  final VoidCallback onReload;
  final VoidCallback onOpenOther;

  /// Where each audio file is; null while [mediaChecking] or when the
  /// project's audio files aren't read.
  final List<MediaCheck>? mediaChecks;
  final bool mediaChecking;

  /// Fixes the missing audio files in a relinked copy; null where this
  /// DAW's projects can't be relinked yet.
  final VoidCallback? onRelink;

  /// Writes a copy with chosen plug-ins switched off; null where this DAW's
  /// projects can't be written yet.
  final VoidCallback? onSafeCopy;

  /// Picks another project to compare this one with; null to offer none.
  final VoidCallback? onCompare;

  /// Copies or saves a report of the project; null to offer none.
  final void Function(InspectorReportAction action)? onReport;
  final InspectorSection initialSection;

  @override
  State<ProjectInspectorView> createState() => _ProjectInspectorViewState();
}

class _ProjectInspectorViewState extends State<ProjectInspectorView> {
  late InspectorSection _section = widget.initialSection;
  AnatomyChannelKind? _kind;
  int? _selected;
  bool _byDestination = false;

  @override
  void didUpdateWidget(ProjectInspectorView old) {
    super.didUpdateWidget(old);
    if (old.anatomy.filePath != widget.anatomy.filePath) {
      _selected = null;
      _kind = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = widget.anatomy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          anatomy: a,
          onClose: widget.onClose,
          onReload: widget.onReload,
          onOpenOther: widget.onOpenOther,
          onCompare: widget.onCompare,
          onReport: widget.onReport,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _Tiles(anatomy: a),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<InspectorSection>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: InspectorSection.tracks,
                  icon: const Icon(Icons.view_list),
                  label: Text(l10n.inspectorTabTracks),
                ),
                ButtonSegment(
                  value: InspectorSection.plugins,
                  icon: const Icon(Icons.extension),
                  label: Text(l10n.inspectorTabPlugins),
                ),
                ButtonSegment(
                  value: InspectorSection.routing,
                  icon: const Icon(Icons.account_tree),
                  label: Text(l10n.inspectorTabRouting),
                ),
                ButtonSegment(
                  value: InspectorSection.audioIo,
                  icon: const Icon(Icons.settings_input_component),
                  label: Text(l10n.inspectorTabAudioIo),
                ),
                ButtonSegment(
                  value: InspectorSection.media,
                  icon: const Icon(Icons.audio_file),
                  label: Text(l10n.inspectorTabMedia),
                ),
                ButtonSegment(
                  value: InspectorSection.statistics,
                  icon: const Icon(Icons.bar_chart),
                  label: Text(l10n.inspectorTabStatistics),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (s) => setState(() => _section = s.first),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _sectionBody(context)),
      ],
    );
  }

  Widget _sectionBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = widget.anatomy;
    final daw = a.dawType ?? '';
    final channels = a.channels;
    return switch (_section) {
      InspectorSection.tracks =>
        channels == null
            ? _Note(l10n.inspectorNotAvailable(daw))
            : _TracksSection(
                channels: channels,
                search: widget.search,
                kind: _kind,
                selected: _selected,
                onKind: (k) => setState(() => _kind = k),
                onSelect: (i) => setState(() => _selected = i),
              ),
      InspectorSection.plugins => _PluginsSection(
        anatomy: a,
        search: widget.search,
        onSafeCopy: widget.onSafeCopy,
      ),
      InspectorSection.routing =>
        channels == null
            ? _Note(l10n.inspectorNotAvailable(daw))
            : _RoutingSection(
                channels: channels,
                search: widget.search,
                selected: _selected,
                byDestination: _byDestination,
                onSelect: (i) => setState(() => _selected = i),
                onView: (v) => setState(() => _byDestination = v),
              ),
      InspectorSection.audioIo =>
        a.audioIo == null
            ? _Note(l10n.inspectorNotAvailable(daw))
            : _AudioIoSection(io: a.audioIo!),
      InspectorSection.media =>
        a.media == null
            ? _Note(l10n.inspectorNotAvailable(daw))
            : _MediaSection(
                checks: widget.mediaChecks,
                checking: widget.mediaChecking,
                onRelink: widget.onRelink,
              ),
      InspectorSection.statistics => _StatisticsSection(anatomy: a),
    };
  }
}

// --- header -----------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.anatomy,
    required this.onClose,
    required this.onReload,
    required this.onOpenOther,
    this.onCompare,
    this.onReport,
  });

  final ProjectAnatomy anatomy;
  final VoidCallback onClose;
  final VoidCallback onReload;
  final VoidCallback onOpenOther;
  final VoidCallback? onCompare;
  final void Function(InspectorReportAction action)? onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final a = anatomy;
    final saved = a.dawType == null
        ? null
        : l10n.inspectorSavedWith(a.dawType!, a.savedWith ?? '').trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.basenameWithoutExtension(a.filePath),
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (saved != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          saved,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    Text(
                      '${a.filePath} · ${formatByteSize(a.fileSize)}',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onCompare != null)
            TextButton.icon(
              onPressed: onCompare,
              icon: const Icon(Icons.compare_arrows),
              label: Text(l10n.compareWith),
            ),
          if (onReport != null)
            PopupMenuButton<InspectorReportAction>(
              tooltip: l10n.inspectorReport,
              icon: const Icon(Icons.description_outlined),
              onSelected: onReport,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: InspectorReportAction.copySummary,
                  child: Text(l10n.compareCopySummary),
                ),
                PopupMenuItem(
                  value: InspectorReportAction.markdown,
                  child: Text(l10n.reportSaveMarkdown),
                ),
                if (a.channels != null)
                  PopupMenuItem(
                    value: InspectorReportAction.tracksCsv,
                    child: Text(l10n.reportSaveTracksCsv),
                  ),
                if (a.plugins.isNotEmpty)
                  PopupMenuItem(
                    value: InspectorReportAction.pluginsCsv,
                    child: Text(l10n.reportSavePluginsCsv),
                  ),
              ],
            ),
          IconButton(
            tooltip: l10n.inspectorReload,
            icon: const Icon(Icons.refresh),
            onPressed: onReload,
          ),
          IconButton(
            tooltip: l10n.inspectorOpenProject,
            icon: const Icon(Icons.folder_open),
            onPressed: onOpenOther,
          ),
          IconButton(
            tooltip: l10n.inspectorClose,
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.anatomy});
  final ProjectAnatomy anatomy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = anatomy;
    final channels = a.channels;
    final counts = channels == null ? null : channelCounts(channels);
    final tracks = channels == null ? null : mixerChannels(channels).length;
    // A DAW whose mixer isn't read yet still has the scan's track counts.
    final statRows = channels == null && a.stats != null
        ? statsTrackRows(l10n, a.stats!)
        : null;
    final instances = pluginInstanceCounts(a.plugins);
    final rate = a.sampleRate;
    final markers = a.markers ?? const [];
    final clips = a.midiClipCount;
    final missingMidi = a.missingMidiFiles?.length ?? 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Tile(
          icon: Icons.speed,
          value: a.tempo == null ? '—' : trimNumber(a.tempo!),
          unit: 'BPM',
          caption: l10n.inspectorTileTempo,
        ),
        _Tile(
          icon: Icons.straighten,
          value: switch (a.timeSignature) {
            (final n, final d) => '$n/$d',
            null => '—',
          },
          caption: a.timeSignature == null
              ? l10n.inspectorNotInFile
              : l10n.inspectorTileTimeSignature,
        ),
        _Tile(
          icon: Icons.music_note,
          value: a.key ?? '—',
          caption: a.key == null
              ? l10n.inspectorNotInFile
              : l10n.inspectorTileKey,
        ),
        _Tile(
          icon: Icons.graphic_eq,
          value: rate == null ? '—' : trimNumber(rate / 1000),
          unit: rate == null ? null : 'kHz',
          caption: switch ((rate, a.bitDepth)) {
            (null, _) => l10n.inspectorNotInFile,
            (_, final bits?) => l10n.inspectorBitDepth(bits),
            _ => l10n.inspectorTileSampleRate,
          },
        ),
        if (tracks != null)
          _Tile(
            icon: Icons.view_list,
            value: '$tracks',
            unit: l10n.inspectorTileTracks(tracks),
            caption: [
              for (final (kind, label) in channelKindLabels(l10n))
                if ((counts![kind] ?? 0) > 0 &&
                    kind != AnatomyChannelKind.folder)
                  '${counts[kind]} ${label.toLowerCase()}',
            ].join(' · '),
          )
        else if (statRows != null)
          _Tile(
            icon: Icons.view_list,
            value: '${statRows.fold(0, (n, r) => n + r.$2)}',
            unit: l10n.inspectorTileTracks(
              statRows.fold(0, (n, r) => n + r.$2),
            ),
            caption: [
              for (final (label, n) in statRows) '$n ${label.toLowerCase()}',
            ].join(' · '),
          ),
        if (!a.pluginInstancesKnown && a.plugins.isNotEmpty)
          _Tile(
            icon: Icons.extension,
            value: '${a.plugins.length}',
            unit: l10n.inspectorTilePlugins(a.plugins.length),
            caption: l10n.inspectorPluginNamesOnly,
          ),
        if (clips != null)
          _Tile(
            icon: Icons.library_music,
            value: '$clips',
            unit: l10n.inspectorTileMidiClips(clips),
            caption: missingMidi == 0
                ? ''
                : l10n.inspectorMidiFilesMissing(missingMidi),
          ),
        if (markers.isNotEmpty)
          _Tile(
            icon: Icons.bookmark_border,
            value: '${markers.length}',
            unit: l10n.inspectorTileMarkers(markers.length),
            caption: l10n.inspectorMarkerRegions(
              markers.where((m) => m.isRegion).length,
            ),
          ),
        if (a.pluginInstancesKnown) ...[
          _Tile(
            icon: Icons.extension,
            value: '${instances.stockEffects + instances.thirdPartyEffects}',
            unit: l10n.inspectorTileEffects(
              instances.stockEffects + instances.thirdPartyEffects,
            ),
            caption: l10n.inspectorEffectsBreakdown(
              instances.stockEffects,
              instances.thirdPartyEffects,
            ),
          ),
          _Tile(
            icon: Icons.piano,
            value: '${instances.instruments}',
            unit: l10n.inspectorTileInstruments(instances.instruments),
            caption: '',
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.value,
    required this.caption,
    this.unit,
  });

  final IconData icon;
  final String value;
  final String? unit;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: value, style: theme.textTheme.headlineSmall),
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Text(
                caption,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- tracks -----------------------------------------------------------------

class _TracksSection extends StatelessWidget {
  const _TracksSection({
    required this.channels,
    required this.search,
    required this.kind,
    required this.selected,
    required this.onKind,
    required this.onSelect,
  });

  final List<AnatomyChannel> channels;
  final String search;
  final AnatomyChannelKind? kind;
  final int? selected;
  final ValueChanged<AnatomyChannelKind?> onKind;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counts = channelCounts(channels);
    final shown = [
      for (final (i, c) in channels.indexed)
        if ((kind == null || c.kind == kind) && channelMatches(c, search))
          (i, c),
    ];
    final detail = selected == null || selected! >= channels.length
        ? null
        : channels[selected!];
    return LayoutBuilder(
      builder: (context, constraints) {
        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(
                      '${l10n.inspectorFilterAll} ${channels.length}',
                    ),
                    selected: kind == null,
                    onSelected: (_) => onKind(null),
                  ),
                  for (final (k, label) in channelKindLabels(l10n))
                    if ((counts[k] ?? 0) > 0)
                      ChoiceChip(
                        avatar: Icon(channelKindIcon(k), size: 16),
                        label: Text('$label ${counts[k]}'),
                        selected: kind == k,
                        onSelected: (_) => onKind(kind == k ? null : k),
                      ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (context, i) {
                  final (index, c) = shown[i];
                  return _ChannelRow(
                    channel: c,
                    selected: index == selected,
                    onTap: () => onSelect(index),
                  );
                },
              ),
            ),
          ],
        );
        final panel = detail == null
            ? _Note(l10n.inspectorSelectChannel)
            : _ChannelDetail(channel: detail, channels: channels);
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              Expanded(flex: 3, child: list),
              const Divider(height: 1),
              Expanded(flex: 2, child: panel),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: list),
            const VerticalDivider(width: 1),
            Expanded(flex: 2, child: panel),
          ],
        );
      },
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  final AnatomyChannel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = channel;
    final theme = Theme.of(context);
    final subtitle = [
      if (c.folder != null) c.folder!,
      if (c.instrument != null) c.instrument!,
      if (c.inserts.isNotEmpty) l10n.inspectorInsertsCount(c.inserts.length),
    ].join(' · ');
    return ListTile(
      dense: true,
      selected: selected,
      leading: Icon(channelKindIcon(c.kind)),
      title: Text(c.name, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, overflow: TextOverflow.ellipsis),
      trailing: c.kind == AnatomyChannelKind.folder
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (c.muted == true)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      l10n.inspectorMuted,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                if (c.soloed == true)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      l10n.inspectorSoloed,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                _FaderReadout(db: c.volumeDb, position: c.faderPosition),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: Text(
                    '→ ${c.output ?? (c.faderPosition == null ? '—' : l10n.inspectorNotConnected)}',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
      onTap: onTap,
    );
  }
}

/// A fader: its dB value where the reader knows it, else where it sits.
class _FaderReadout extends StatelessWidget {
  const _FaderReadout({required this.db, required this.position});
  final double? db;
  final double? position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (db != null) {
      return SizedBox(
        width: 64,
        child: Text(
          formatDb(db!),
          textAlign: TextAlign.end,
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    final pos = position;
    if (pos == null) return const SizedBox(width: 64);
    return StandaloneTooltip(
      message: AppLocalizations.of(context)!.inspectorFaderPositionOnly,
      child: SizedBox(
        width: 64,
        height: 6,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pos,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}

class _ChannelDetail extends StatelessWidget {
  const _ChannelDetail({required this.channel, required this.channels});
  final AnatomyChannel channel;
  final List<AnatomyChannel> channels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = channel;
    final path = signalPath(channels, c.name);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(channelKindIcon(c.kind)),
            const SizedBox(width: 8),
            Expanded(child: Text(c.name, style: theme.textTheme.titleMedium)),
            _FaderReadout(db: c.volumeDb, position: c.faderPosition),
          ],
        ),
        if (path.length > 1) ...[
          const SizedBox(height: 12),
          _Label(l10n.inspectorSignalPath),
          _PathChips(path: path),
        ],
        if (c.pan != null) ...[
          const SizedBox(height: 12),
          _Label(l10n.inspectorPan),
          Text(formatPan(c.pan!)),
        ],
        if (c.instrument != null) ...[
          const SizedBox(height: 12),
          _Label(l10n.inspectorInstrument),
          Text(
            c.instrumentPreset == null
                ? c.instrument!
                : '${c.instrument!} — ${c.instrumentPreset}',
          ),
        ],
        if (c.eqBandsOn != null) ...[
          const SizedBox(height: 12),
          Text(l10n.inspectorEqBandsOn(c.eqBandsOn!)),
        ],
        if (c.stripBeforeInserts == true) _StripSection(channel: c),
        const SizedBox(height: 12),
        _Label(l10n.inspectorInserts),
        if (c.inserts.isEmpty)
          Text(l10n.inspectorNoInserts, style: theme.textTheme.bodySmall)
        else
          for (final i in c.inserts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${i.slot + 1}. ${i.plugin}'
                '${i.preset == null ? '' : ' — ${i.preset}'}'
                '${i.deactivated == true ? ' (${l10n.inspectorDeactivated})' : ''}',
                style: i.deactivated == true
                    ? TextStyle(color: theme.disabledColor)
                    : null,
              ),
            ),
        if (c.stripBeforeInserts != true) _StripSection(channel: c),
        const SizedBox(height: 12),
        _Label(l10n.inspectorSends),
        if (c.sends.isEmpty)
          Text(l10n.inspectorNoSends, style: theme.textTheme.bodySmall)
        else
          for (final s in c.sends) _SendLine(send: s),
      ],
    );
  }
}

/// A channel strip's modules in the order they run, the EQ's place among
/// them included; nothing for a channel with none loaded — every channel
/// has the EQ, and its bands are shown above.
class _StripSection extends StatelessWidget {
  const _StripSection({required this.channel});
  final AnatomyChannel channel;

  @override
  Widget build(BuildContext context) {
    final c = channel;
    if (c.stripModules.isEmpty && c.stripBypassed != true) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bypassed = c.stripBypassed == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _Label(l10n.inspectorChannelStrip),
        if (bypassed || c.stripBeforeInserts == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              [
                if (bypassed) l10n.inspectorStripBypassed,
                if (c.stripBeforeInserts == true)
                  l10n.inspectorStripBeforeInserts,
              ].join(' · '),
              style: theme.textTheme.labelSmall?.copyWith(
                color: bypassed ? theme.colorScheme.error : null,
              ),
            ),
          ),
        for (final m in c.strip)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              stripModuleText(l10n, m),
              style: bypassed || m.deactivated == true
                  ? TextStyle(color: theme.disabledColor)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// "Compressor: Standard Compressor — Vocal (off)"; the EQ is only its
/// place: "EQ".
String stripModuleText(AppLocalizations l10n, AnatomyStripModule m) {
  final kind = switch (m.kind) {
    AnatomyStripKind.gate => l10n.inspectorStripGate,
    AnatomyStripKind.compressor => l10n.inspectorStripCompressor,
    AnatomyStripKind.eq => l10n.inspectorStripEq,
    AnatomyStripKind.tools => l10n.inspectorStripTools,
    AnatomyStripKind.saturation => l10n.inspectorStripSaturation,
    AnatomyStripKind.limiter => l10n.inspectorStripLimiter,
    null => l10n.inspectorStripModule,
  };
  if (m.kind == AnatomyStripKind.eq) return kind;
  return '$kind: ${m.plugin}'
      '${m.preset == null ? '' : ' — ${m.preset}'}'
      '${m.deactivated == true ? ' (${l10n.inspectorDeactivated})' : ''}';
}

class _SendLine extends StatelessWidget {
  const _SendLine({required this.send});
  final AnatomySend send;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = send;
    final parts = [
      '→ ${s.destination ?? '—'}',
      if (s.sideChainOf != null) l10n.inspectorSideChainInto(s.sideChainOf!),
      if (s.levelDb != null) formatDb(s.levelDb!),
      if (s.preFader) l10n.inspectorPreFader,
      if (!s.on) l10n.inspectorSendSwitchedOff,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        parts.join(' · '),
        style: s.on ? null : TextStyle(color: Theme.of(context).disabledColor),
      ),
    );
  }
}

class _PathChips extends StatelessWidget {
  const _PathChips({required this.path});
  final List<String> path;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, name) in path.indexed) ...[
          if (i > 0) const Icon(Icons.arrow_forward, size: 14),
          Chip(label: Text(name), visualDensity: VisualDensity.compact),
        ],
      ],
    );
  }
}

// --- plug-ins ---------------------------------------------------------------

class _PluginsSection extends StatelessWidget {
  const _PluginsSection({
    required this.anatomy,
    required this.search,
    this.onSafeCopy,
  });
  final ProjectAnatomy anatomy;
  final String search;
  final VoidCallback? onSafeCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final plugins = anatomy.plugins
        .where((pl) => pluginMatches(pl, search))
        .toList();
    final total = anatomy.plugins.fold<int>(
      0,
      (sum, pl) => sum + (pl.instances ?? 1),
    );
    final groups = anatomy.pluginInstancesKnown
        ? [
            (
              l10n.inspectorGroupInstruments,
              [
                for (final pl in plugins)
                  if (pl.role == AnatomyPluginRole.instrument) pl,
              ],
            ),
            (
              l10n.inspectorGroupStock,
              [
                for (final pl in plugins)
                  if (pl.role == AnatomyPluginRole.effect && pl.stock == true)
                    pl,
              ],
            ),
            (
              l10n.inspectorGroupThirdParty,
              [
                for (final pl in plugins)
                  if (pl.role == AnatomyPluginRole.effect && pl.stock != true)
                    pl,
              ],
            ),
          ]
        : [(l10n.inspectorTabPlugins, plugins)];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                l10n.inspectorPluginSummary(anatomy.plugins.length, total),
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (onSafeCopy != null && anatomy.plugins.isNotEmpty)
              FilledButton.tonalIcon(
                onPressed: onSafeCopy,
                icon: const Icon(Icons.health_and_safety_outlined),
                label: Text(l10n.safeCopyButton),
              ),
          ],
        ),
        if (!anatomy.pluginInstancesKnown) ...[
          const SizedBox(height: 4),
          Text(
            l10n.inspectorPluginsNamesOnly(anatomy.dawType ?? ''),
            style: theme.textTheme.bodySmall,
          ),
        ],
        for (final (title, items) in groups)
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('$title (${items.length})', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final pl in items) _PluginCard(plugin: pl)],
            ),
          ],
      ],
    );
  }
}

class _PluginCard extends StatelessWidget {
  const _PluginCard({required this.plugin});
  final AnatomyPlugin plugin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pl = plugin;
    return SizedBox(
      width: 240,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      pl.name,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pl.instances != null)
                    Text(
                      '×${pl.instances}',
                      style: theme.textTheme.labelMedium,
                    ),
                ],
              ),
              if (pl.vendor != null || pl.format != null)
                Text(
                  [?pl.vendor, ?pl.format].join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              if (pl.channels.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  pl.channels.join(', '),
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- routing ----------------------------------------------------------------

class _RoutingSection extends StatelessWidget {
  const _RoutingSection({
    required this.channels,
    required this.search,
    required this.selected,
    required this.byDestination,
    required this.onSelect,
    required this.onView,
  });

  final List<AnatomyChannel> channels;
  final String search;
  final int? selected;
  final bool byDestination;
  final ValueChanged<int> onSelect;
  final ValueChanged<bool> onView;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nowhere = channelsGoingNowhere(channels);
    final skipping = channelsSkippingBuses(channels);
    final hints = [
      if (nowhere.isNotEmpty)
        (l10n.inspectorHintNowhere(nowhere.length), nowhere),
      if (skipping.isNotEmpty)
        (l10n.inspectorHintSkipBuses(skipping.length), skipping),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.inspectorSignalFlow),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.inspectorByDestination),
                  ),
                ],
                selected: {byDestination},
                onSelectionChanged: (s) => onView(s.first),
              ),
            ],
          ),
        ),
        for (final (text, list) in hints)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$text: ${list.map((c) => c.name).join(', ')}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: byDestination
              ? _Destinations(channels: channels, search: search)
              : _SignalFlow(
                  channels: channels,
                  search: search,
                  selected: selected,
                  onSelect: onSelect,
                ),
        ),
      ],
    );
  }
}

class _SignalFlow extends StatelessWidget {
  const _SignalFlow({
    required this.channels,
    required this.search,
    required this.selected,
    required this.onSelect,
  });

  final List<AnatomyChannel> channels;
  final String search;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shown = [
      for (final (i, c) in channels.indexed)
        if (c.kind != AnatomyChannelKind.folder &&
            c.kind != AnatomyChannelKind.midi &&
            channelMatches(c, search))
          (i, c),
    ];
    final current = selected == null || selected! >= channels.length
        ? null
        : channels[selected!];
    Widget flow() {
      if (current == null) return _Note(l10n.inspectorSelectChannel);
      final sources = sourcesOf(channels, current.name);
      final indexOf = {for (final (i, c) in channels.indexed) c.name: i};
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Label(l10n.inspectorSignalPath),
          _PathChips(path: signalPath(channels, current.name)),
          const SizedBox(height: 16),
          _FlowDiagram(
            channel: current,
            sources: sources,
            onOpen: (name) {
              final i = indexOf[name];
              if (i != null) onSelect(i);
            },
          ),
          if (sources.isEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.inspectorNothingFeeds, style: theme.textTheme.bodySmall),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 240,
          child: ListView.builder(
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final (index, c) = shown[i];
              return ListTile(
                dense: true,
                selected: index == selected,
                leading: Icon(channelKindIcon(c.kind), size: 18),
                title: Text(c.name, overflow: TextOverflow.ellipsis),
                onTap: () => onSelect(index),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: flow()),
      ],
    );
  }
}

/// Where a signal-flow diagram's boxes go: [sources] boxes feeding a
/// channel down the left, the channel in the middle ([centerLines] lines
/// tall), [destinations] boxes it feeds down the right, in a diagram
/// [width] wide. Columns stay centred on each other, so a channel fed by
/// one source draws a straight line.
class FlowLayout {
  const FlowLayout(this.sources, this.center, this.destinations, this.height);
  final List<Rect> sources;
  final Rect center;
  final List<Rect> destinations;
  final double height;

  static const nodeHeight = 40.0;
  static const gap = 8.0;
  static const lineHeight = 20.0;

  factory FlowLayout.of({
    required int sources,
    required int destinations,
    required int centerLines,
    required double width,
  }) {
    final column = width * 0.3;
    final middle = width * 0.3;
    double stack(int n) => n == 0 ? 0 : n * nodeHeight + (n - 1) * gap;
    final centerHeight = 64 + lineHeight * centerLines.clamp(0, 12);
    final height = [
      stack(sources),
      stack(destinations),
      centerHeight,
      120.0,
    ].reduce((a, b) => a > b ? a : b);
    List<Rect> column_(int n, double left) {
      final top = (height - stack(n)) / 2;
      return [
        for (var i = 0; i < n; i++)
          Rect.fromLTWH(left, top + i * (nodeHeight + gap), column, nodeHeight),
      ];
    }

    return FlowLayout(
      column_(sources, 0),
      Rect.fromLTWH(
        (width - middle) / 2,
        (height - centerHeight) / 2,
        middle,
        centerHeight,
      ),
      column_(destinations, width - column),
      height,
    );
  }
}

/// One box at either side of the diagram.
class _FlowNode {
  const _FlowNode(this.name, this.detail, this.icon, {this.dashed = false});
  final String name;
  final String? detail;
  final IconData icon;

  /// A send or side-chain, drawn dashed; an output is a solid line.
  final bool dashed;
}

/// A channel's signal flow drawn as CPR Inspector draws it: what feeds it
/// on the left, the channel and its inserts in the middle, where it goes
/// on the right — solid for outputs, dashed for sends and side-chains. A
/// box that is a channel opens it.
class _FlowDiagram extends StatelessWidget {
  const _FlowDiagram({
    required this.channel,
    required this.sources,
    required this.onOpen,
  });

  final AnatomyChannel channel;
  final List<RoutingSource> sources;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = channel;
    final left = [
      for (final s in sources)
        _FlowNode(
          s.channel.name,
          switch (s.via) {
            RoutingVia.output => null,
            RoutingVia.send => [
              l10n.inspectorViaSend,
              if (s.send?.levelDb != null) formatDb(s.send!.levelDb!),
            ].join(' · '),
            RoutingVia.sideChain => l10n.inspectorSideChainInto(
              s.send?.sideChainOf ?? '',
            ),
          },
          channelKindIcon(s.channel.kind),
          dashed: s.via != RoutingVia.output,
        ),
    ];
    final right = [
      _FlowNode(
        c.output ?? l10n.inspectorNotConnected,
        l10n.inspectorOutput,
        c.output == null ? Icons.link_off : Icons.speaker,
      ),
      for (final s in c.sends)
        _FlowNode(
          s.destination ?? '—',
          [
            if (s.sideChainOf != null)
              l10n.inspectorSideChainInto(s.sideChainOf!)
            else
              l10n.inspectorViaSend,
            if (s.levelDb != null) formatDb(s.levelDb!),
            if (!s.on) l10n.inspectorSendSwitchedOff,
          ].join(' · '),
          Icons.call_split,
          dashed: true,
        ),
    ];
    final strip = [
      if (c.stripBypassed != true)
        for (final m in c.stripModules) stripModuleText(l10n, m),
    ];
    final lines = [
      if (c.instrument != null) c.instrument!,
      if (c.stripBeforeInserts == true) ...strip,
      for (final i in c.inserts)
        '${i.slot + 1}. ${i.plugin}${i.deactivated == true ? ' (${l10n.inspectorDeactivated})' : ''}',
      if (c.stripBeforeInserts != true) ...strip,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = FlowLayout.of(
          sources: left.length,
          destinations: right.length,
          centerLines: lines.length,
          width: constraints.maxWidth,
        );
        Widget node(_FlowNode n, Rect r) => Positioned.fromRect(
          rect: r,
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onOpen(n.name),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(n.icon, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          if (n.detail != null)
                            Text(
                              n.detail!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        return SizedBox(
          height: layout.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _FlowPainter(
                    layout: layout,
                    leftDashed: [for (final n in left) n.dashed],
                    rightDashed: [for (final n in right) n.dashed],
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              for (final (i, n) in left.indexed) node(n, layout.sources[i]),
              for (final (i, n) in right.indexed)
                node(n, layout.destinations[i]),
              Positioned.fromRect(
                rect: layout.center,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.primary),
                  ),
                  // Clipped, never overflowing: a theme with taller text cuts
                  // the last line short rather than drawing stripes.
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxHeight: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(channelKindIcon(c.kind), size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              _FaderReadout(
                                db: c.volumeDb,
                                position: c.faderPosition,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          for (final line in lines.take(12))
                            Text(
                              line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlowPainter extends CustomPainter {
  _FlowPainter({
    required this.layout,
    required this.leftDashed,
    required this.rightDashed,
    required this.color,
  });

  final FlowLayout layout;
  final List<bool> leftDashed;
  final List<bool> rightDashed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = layout.center;
    for (final (i, r) in layout.sources.indexed) {
      _curve(canvas, paint, r.centerRight, center.centerLeft, leftDashed[i]);
    }
    for (final (i, r) in layout.destinations.indexed) {
      _curve(canvas, paint, center.centerRight, r.centerLeft, rightDashed[i]);
    }
  }

  void _curve(Canvas canvas, Paint paint, Offset a, Offset b, bool dashed) {
    final mid = (a.dx + b.dx) / 2;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) =>
      old.layout != layout || old.color != color;
}

class _Destinations extends StatelessWidget {
  const _Destinations({required this.channels, required this.search});
  final List<AnatomyChannel> channels;
  final String search;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final q = search.trim().toLowerCase();
    final all = [
      for (final d in destinations(channels))
        if (q.isEmpty ||
            d.$1.toLowerCase().contains(q) ||
            d.$2.any((s) => channelMatches(s.channel, q)))
          d,
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final (name, sources) in all)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(name, style: theme.textTheme.titleSmall),
                      ),
                      Text(
                        l10n.inspectorSourcesCount(sources.length),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (sources.isEmpty)
                    Text(
                      l10n.inspectorNothingFeeds,
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in sources)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(channelKindIcon(s.channel.kind), size: 14),
                            label: Text(switch (s.via) {
                              RoutingVia.output => s.channel.name,
                              RoutingVia.send =>
                                '${s.channel.name} (${l10n.inspectorViaSend})',
                              RoutingVia.sideChain =>
                                '${s.channel.name} (${l10n.inspectorViaSideChain})',
                            }),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// --- audio I/O --------------------------------------------------------------

class _AudioIoSection extends StatelessWidget {
  const _AudioIoSection({required this.io});
  final AnatomyAudioIo io;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    Widget chips(List<String> names) => names.isEmpty
        ? Text(l10n.inspectorNone, style: theme.textTheme.bodySmall)
        : Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final n in names)
                Chip(label: Text(n), visualDensity: VisualDensity.compact),
            ],
          );
    Widget buses(List<AnatomyBus> list) => list.isEmpty
        ? Text(l10n.inspectorNone, style: theme.textTheme.bodySmall)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final b in list)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(child: chips(b.ports)),
                    ],
                  ),
                ),
            ],
          );
    Widget card(String title, Widget body) => SizedBox(
      width: 520,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_Label(title), const SizedBox(height: 4), body],
          ),
        ),
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tile(
                icon: Icons.settings_input_component,
                value: io.driver ?? '—',
                caption: io.driver == null
                    ? l10n.inspectorUnnamedDriver
                    : l10n.inspectorAudioDriver,
              ),
              if (io.platform != null)
                _Tile(
                  icon: Icons.computer,
                  value: io.platform!,
                  caption: l10n.inspectorSavedOn(io.platform!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              card(l10n.inspectorInputBuses, buses(io.inputBuses)),
              card(l10n.inspectorOutputBuses, buses(io.outputBuses)),
              card(l10n.inspectorInterfaceInputs, chips(io.interfaceInputs)),
              card(l10n.inspectorInterfaceOutputs, chips(io.interfaceOutputs)),
              card(l10n.inspectorMidiInputs, chips(io.midiInputs)),
              card(l10n.inspectorMidiOutputs, chips(io.midiOutputs)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- media ------------------------------------------------------------------

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.checks,
    required this.checking,
    this.onRelink,
  });
  final List<MediaCheck>? checks;
  final bool checking;
  final VoidCallback? onRelink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final all = checks;
    if (all == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (checking) const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.inspectorMediaChecking),
          ],
        ),
      );
    }
    if (all.isEmpty) return _Note(l10n.inspectorMediaNone);
    final counts = mediaCounts(all);
    final missing = counts[MediaStatus.missing] ?? 0;
    // What a relink can point elsewhere: not a path in a plug-in's state.
    final fixable = all.any(
      (c) =>
          c.status != MediaStatus.found && c.reference.use != SampleUse.plugin,
    );
    // Missing first: they are what this list is for.
    final sorted = [
      ...all,
    ]..sort((a, b) => _statusOrder(a.status).compareTo(_statusOrder(b.status)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                missing == 0
                    ? l10n.inspectorMediaAllFound(all.length)
                    : l10n.inspectorMediaSummary(missing, all.length),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: missing == 0 ? null : theme.colorScheme.error,
                ),
              ),
            ),
            if (fixable && onRelink != null)
              FilledButton.tonalIcon(
                onPressed: onRelink,
                icon: const Icon(Icons.healing),
                label: Text(l10n.relinkFixButton),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final c in sorted)
          ListTile(
            dense: true,
            leading: Icon(
              switch (c.status) {
                MediaStatus.found => Icons.check_circle,
                MediaStatus.foundElsewhere => Icons.find_in_page,
                MediaStatus.missing => Icons.error,
              },
              color: switch (c.status) {
                MediaStatus.found => theme.colorScheme.primary,
                MediaStatus.foundElsewhere => theme.colorScheme.tertiary,
                MediaStatus.missing => theme.colorScheme.error,
              },
            ),
            title: Text(c.reference.fileName, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              [
                switch (c.status) {
                  MediaStatus.found => l10n.inspectorMediaFound,
                  MediaStatus.foundElsewhere => l10n.inspectorMediaElsewhere,
                  MediaStatus.missing => l10n.inspectorMediaMissing,
                },
                if (c.reference.candidates.isNotEmpty)
                  l10n.inspectorMediaStoredAt(c.reference.candidates.first),
                if (c.status == MediaStatus.foundElsewhere && c.path != null)
                  l10n.inspectorMediaFoundAt(c.path!),
              ].join('\n'),
            ),
            isThreeLine: c.status == MediaStatus.foundElsewhere,
          ),
      ],
    );
  }

  static int _statusOrder(MediaStatus s) => switch (s) {
    MediaStatus.missing => 0,
    MediaStatus.foundElsewhere => 1,
    MediaStatus.found => 2,
  };
}

// --- statistics -------------------------------------------------------------

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection({required this.anatomy});
  final ProjectAnatomy anatomy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = anatomy;
    final channels = a.channels;
    final cards = <Widget>[];
    if (channels == null && a.stats != null) {
      cards.add(
        _BarCard(
          title: l10n.inspectorStatTrackTypes,
          rows: statsTrackRows(l10n, a.stats!),
        ),
      );
    }
    if (channels != null) {
      final counts = channelCounts(channels);
      cards.add(
        _BarCard(
          title: l10n.inspectorStatTrackTypes,
          rows: [
            for (final (k, label) in channelKindLabels(l10n))
              if ((counts[k] ?? 0) > 0 && k != AnatomyChannelKind.folder)
                (label, counts[k]!),
          ],
        ),
      );
    }
    if (a.pluginInstancesKnown) {
      final i = pluginInstanceCounts(a.plugins);
      cards.add(
        _BarCard(
          title: l10n.inspectorStatPluginInstances,
          rows: [
            (l10n.inspectorGroupThirdParty, i.thirdPartyEffects),
            (l10n.inspectorGroupStock, i.stockEffects),
            (l10n.inspectorGroupInstruments, i.instruments),
            if (i.unknown > 0) (l10n.inspectorStatUnknown, i.unknown),
          ],
        ),
      );
      cards.add(
        _BarCard(
          title: l10n.inspectorStatMostUsed,
          rows: [
            for (final pl in mostUsedPlugins(a.plugins))
              (pl.name, pl.instances!),
          ],
        ),
      );
    }
    if (channels != null) {
      final chains = usualChains(channels);
      cards.add(
        _BarCard(
          title: l10n.inspectorStatUsualChains,
          empty: l10n.inspectorStatNoChains,
          rows: [for (final (chain, n) in chains) (chain.join(' → '), n)],
        ),
      );
      final perChannel = insertsPerChannel(channels).entries.toList()
        ..sort((x, y) => x.key.compareTo(y.key));
      cards.add(
        _BarCard(
          title: l10n.inspectorStatInsertsPerChannel,
          rows: [
            for (final e in perChannel)
              (l10n.inspectorInsertsCount(e.key), e.value),
          ],
          unit: l10n.inspectorChannelsCount,
        ),
      );
      cards.add(
        _BarCard(
          title: l10n.inspectorStatBusiest,
          rows: [
            for (final (name, sources) in destinations(channels).take(10))
              if (sources.isNotEmpty) (name, sources.length),
          ],
        ),
      );
    }
    final theme = Theme.of(context);
    final markers = a.markers ?? const [];
    final missingMidi = a.missingMidiFiles ?? const [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (a.notes case final notes?) ...[
            _Label(l10n.inspectorNotesTitle),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(notes),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (markers.isNotEmpty) ...[
            ProjectMarkersSection(
              markers: markers,
              title: l10n.projectMarkers,
              unnamedMarkerLabel: l10n.projectMarkerUnnamed,
              unnamedRegionLabel: l10n.projectRegionUnnamed,
              showAllLabel: l10n.showAll,
              collapseLabel: l10n.collapse,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
          ],
          if (missingMidi.isNotEmpty) ...[
            _Label(l10n.inspectorMissingMidiTitle),
            for (final f in missingMidi)
              Text(f, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
          ],
          Wrap(spacing: 12, runSpacing: 12, children: cards),
        ],
      ),
    );
  }
}

/// The scan's track counts by kind, for a DAW whose channels aren't read:
/// its readers count group and FX channels together.
List<(String, int)> statsTrackRows(AppLocalizations l10n, ProjectStats s) => [
  for (final (label, n) in [
    (l10n.inspectorKindAudio, s.audioTracks),
    (l10n.inspectorKindInstrument, s.instrumentTracks),
    (l10n.inspectorKindSampler, s.samplerTracks),
    (l10n.inspectorKindMidi, s.midiTracks),
    (l10n.inspectorKindBuses, s.busTracks),
  ])
    if (n > 0) (label, n),
];

class _BarCard extends StatelessWidget {
  const _BarCard({
    required this.title,
    required this.rows,
    this.empty,
    this.unit,
  });

  final String title;
  final List<(String, int)> rows;
  final String? empty;
  final String Function(int)? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = rows.fold<int>(0, (m, r) => r.$2 > m ? r.$2 : m);
    return SizedBox(
      width: 380,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (rows.isEmpty && empty != null)
                Text(empty!, style: theme.textTheme.bodySmall),
              for (final (label, n) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: max == 0 ? 0 : n / max,
                            minHeight: 6,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          unit == null ? '$n' : unit!(n),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- shared -----------------------------------------------------------------

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

List<(AnatomyChannelKind, String)> channelKindLabels(AppLocalizations l10n) => [
  (AnatomyChannelKind.audio, l10n.inspectorKindAudio),
  (AnatomyChannelKind.instrument, l10n.inspectorKindInstrument),
  (AnatomyChannelKind.sampler, l10n.inspectorKindSampler),
  (AnatomyChannelKind.midi, l10n.inspectorKindMidi),
  (AnatomyChannelKind.group, l10n.inspectorKindGroup),
  (AnatomyChannelKind.fx, l10n.inspectorKindFx),
  (AnatomyChannelKind.folder, l10n.inspectorKindFolder),
];

IconData channelKindIcon(AnatomyChannelKind kind) => switch (kind) {
  AnatomyChannelKind.audio => Icons.graphic_eq,
  AnatomyChannelKind.instrument => Icons.piano,
  AnatomyChannelKind.midi => Icons.music_note,
  AnatomyChannelKind.sampler => Icons.grain,
  AnatomyChannelKind.group => Icons.layers,
  AnatomyChannelKind.fx => Icons.blur_on,
  AnatomyChannelKind.folder => Icons.folder,
};

/// "C", "L30", "R100" — a pan from -1 to 1, as DAWs print it.
String formatPan(double pan) {
  final amount = (pan.abs() * 100).round();
  if (amount == 0) return 'C';
  return '${pan < 0 ? 'L' : 'R'}$amount';
}

/// "0.0 dB", "+6.0 dB", "−∞ dB".
String formatDb(double db) {
  if (db.isInfinite) return '−∞ dB';
  final sign = db > 0 ? '+' : (db < 0 ? '−' : '');
  return '$sign${db.abs().toStringAsFixed(1)} dB';
}

/// 150 → "150", 44.1 → "44.1", 120.5 → "120.5".
String trimNumber(double v) {
  final fixed = v.toStringAsFixed(2);
  return fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
      : fixed;
}
