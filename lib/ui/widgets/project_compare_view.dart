import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../models/project_anatomy.dart';
import '../../services/project_inspector/compare/anatomy_diff.dart';
import 'anatomy_compare_text.dart';
import 'project_inspector_view.dart';

/// Two projects side by side (#223): what changed from A to B — the
/// project, each channel's levels, sends and plug-ins — with totals, filter
/// chips and, per channel, A and B next to each other.
///
/// Plain values and callbacks: the page reads the files, copies and saves.
class ProjectCompareView extends StatefulWidget {
  const ProjectCompareView({
    super.key,
    required this.a,
    required this.b,
    required this.search,
    required this.onSwap,
    required this.onClose,
    required this.onCopySummary,
    required this.onExportCsv,
  });

  final ProjectAnatomy a;
  final ProjectAnatomy b;

  /// What the dashboard's search box holds: filters channels by name and by
  /// what changed on them.
  final String search;
  final VoidCallback onSwap;
  final VoidCallback onClose;
  final void Function(AnatomyDiff diff) onCopySummary;
  final void Function(AnatomyDiff diff) onExportCsv;

  @override
  State<ProjectCompareView> createState() => _ProjectCompareViewState();
}

class _ProjectCompareViewState extends State<ProjectCompareView> {
  late AnatomyDiff _diff = diffAnatomy(widget.a, widget.b);
  AnatomyChangeArea? _area;

  @override
  void didUpdateWidget(ProjectCompareView old) {
    super.didUpdateWidget(old);
    if (!identical(old.a, widget.a) || !identical(old.b, widget.b)) {
      _diff = diffAnatomy(widget.a, widget.b);
    }
  }

  bool _shows(AnatomyChange c) => _area == null || c.area == _area;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final d = _diff;
    final needle = widget.search.trim().toLowerCase();
    bool matches(ChannelComparison ch) =>
        needle.isEmpty ||
        [?ch.a?.name, ?ch.b?.name].any(
          (n) => n.toLowerCase().contains(needle),
        ) ||
        ch.changes.any(
          (c) => changeText(l10n, c).toLowerCase().contains(needle),
        );
    final channels = [
      for (final ch in d.channels)
        if (ch.changes.any(_shows) && matches(ch)) ch,
    ];
    final project = [
      for (final c in d.projectChanges)
        if (_area == null || c.area == _area) c,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.compareTitle, style: theme.textTheme.titleLarge),
                    _Side(label: 'A', anatomy: widget.a),
                    _Side(label: 'B', anatomy: widget.b),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.compareSwap,
                icon: const Icon(Icons.swap_vert),
                onPressed: widget.onSwap,
              ),
              IconButton(
                tooltip: l10n.compareCopySummary,
                icon: const Icon(Icons.content_copy),
                onPressed: () => widget.onCopySummary(d),
              ),
              IconButton(
                tooltip: l10n.compareExportCsv,
                icon: const Icon(Icons.table_view),
                onPressed: () => widget.onExportCsv(d),
              ),
              IconButton(
                tooltip: l10n.compareClose,
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                l10n.compareChangesCount(d.changeCount),
                style: theme.textTheme.titleSmall,
              ),
              if (d.channelsCompared) ...[
                Text(l10n.compareChannelsChanged(d.changedChannels)),
                Text(l10n.compareUnchanged(d.unchangedChannels)),
                Text(l10n.compareOnlyInA(d.onlyInA)),
                Text(l10n.compareOnlyInB(d.onlyInB)),
              ],
              Text(l10n.comparePluginChanges(d.pluginChanges)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final (area, label) in [
                (null, l10n.inspectorFilterAll),
                (AnatomyChangeArea.tracks, l10n.inspectorTabTracks),
                (AnatomyChangeArea.levels, l10n.compareFilterLevels),
                (AnatomyChangeArea.sends, l10n.inspectorSends),
                (AnatomyChangeArea.plugins, l10n.inspectorTabPlugins),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _area == area,
                  onSelected: (_) => setState(() => _area = area),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!d.channelsCompared)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.compareChannelsNotRead(
                      widget.a.dawType ?? widget.b.dawType ?? '',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              if (d.changeCount == 0)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.compareNoDifferences)),
                ),
              if (project.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.compareProject,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        for (final c in project) Text(changeText(l10n, c)),
                      ],
                    ),
                  ),
                ),
              for (final ch in channels)
                _ChannelCard(
                  key: ValueKey(
                    '${ch.a?.name}\u0000${ch.b?.name}\u0000'
                    '${identityHashCode(ch.a ?? ch.b)}',
                  ),
                  comparison: ch,
                  changes: [
                    for (final c in ch.changes)
                      if (_shows(c) &&
                          c.kind != AnatomyChangeKind.renamed &&
                          c.kind != AnatomyChangeKind.channelAdded &&
                          c.kind != AnatomyChangeKind.channelRemoved)
                        c,
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.label, required this.anatomy});
  final String label;
  final ProjectAnatomy anatomy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Badge(label),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            p.basename(anatomy.filePath),
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: theme.textTheme.labelSmall?.copyWith(color: c)),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    super.key,
    required this.comparison,
    required this.changes,
  });
  final ChannelComparison comparison;
  final List<AnatomyChange> changes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ch = comparison;
    final channel = (ch.b ?? ch.a)!;
    final Widget? badge = ch.onlyInA
        ? _Badge(l10n.compareBadgeOnlyInA, color: theme.colorScheme.error)
        : ch.onlyInB
        ? _Badge(l10n.compareBadgeOnlyInB, color: theme.colorScheme.tertiary)
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(channelKindIcon(channel.kind)),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                comparedChannelName(ch),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[const SizedBox(width: 8), badge],
          ],
        ),
        subtitle: changes.isEmpty
            ? null
            : Text(
                [for (final c in changes) changeText(l10n, c)].join('\n'),
                style: theme.textTheme.bodySmall,
              ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ChannelSide(label: 'A', channel: ch.a),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ChannelSide(label: 'B', channel: ch.b),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One side of a channel's comparison: what it is in that project.
class _ChannelSide extends StatelessWidget {
  const _ChannelSide({required this.label, required this.channel});
  final String label;
  final AnatomyChannel? channel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = channel;
    final small = theme.textTheme.bodySmall;
    if (c == null) {
      return Row(
        children: [_Badge(label), const SizedBox(width: 8), const Text('—')],
      );
    }
    final level = c.volumeDb != null
        ? formatDb(c.volumeDb!)
        : c.faderPosition != null
        ? '${(c.faderPosition! * 100).round()}%'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Badge(label),
            const SizedBox(width: 8),
            Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.inspectorOutput}: ${c.output ?? l10n.inspectorNotConnected}',
          style: small,
        ),
        if (level != null || c.pan != null)
          Text(
            [
              if (level != null) '${l10n.inspectorFader}: $level',
              if (c.pan != null) '${l10n.inspectorPan}: ${formatPan(c.pan!)}',
              if (c.muted == true) l10n.inspectorMuted,
            ].join(' · '),
            style: small,
          ),
        if (c.instrument != null)
          Text('${l10n.inspectorInstrument}: ${c.instrument}', style: small),
        const SizedBox(height: 4),
        Text(l10n.inspectorInserts, style: theme.textTheme.labelMedium),
        if (c.inserts.isEmpty)
          Text(l10n.inspectorNoInserts, style: small)
        else
          for (final i in c.inserts)
            Text(
              '${i.slot + 1}. ${i.plugin}'
              '${i.deactivated == true ? ' (${l10n.inspectorDeactivated})' : ''}',
              style: small,
            ),
        if (c.stripModules.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(l10n.inspectorChannelStrip, style: theme.textTheme.labelMedium),
          for (final m in c.stripModules)
            Text(stripModuleText(l10n, m), style: small),
        ],
        const SizedBox(height: 4),
        Text(l10n.inspectorSends, style: theme.textTheme.labelMedium),
        if (c.sends.isEmpty)
          Text(l10n.inspectorNoSends, style: small)
        else
          for (final s in c.sends)
            Text(
              [
                s.sideChainOf != null
                    ? l10n.inspectorSideChainInto(s.sideChainOf!)
                    : s.destination ?? l10n.inspectorNotConnected,
                if (s.levelDb != null) formatDb(s.levelDb!),
                if (s.preFader) l10n.inspectorPreFader,
                if (!s.on) l10n.inspectorSendSwitchedOff,
              ].join(' · '),
              style: small,
            ),
      ],
    );
  }
}
