import 'package:flutter/material.dart';

import '../../models/project_stats.dart';

/// Localized strings for [ProjectStatsSection], resolved by the page so the
/// widget itself needs no `AppLocalizations` (and stays widget-testable).
class ProjectStatsLabels {
  const ProjectStatsLabels({
    required this.tracks,
    required this.audio,
    required this.midi,
    required this.instrument,
    required this.sampler,
    required this.bus,
    required this.folder,
    required this.plugins,
    required this.showAll,
    required this.collapse,
  });

  final String tracks;
  final String audio;
  final String midi;
  final String instrument;
  final String sampler;
  final String bus;
  final String folder;
  final String plugins;
  final String showAll;
  final String collapse;
}

/// Track counts by kind and the plug-in list read out of a project file.
///
/// A plain view, like `ProjectMarkersSection`: it takes the stats and the
/// strings and draws them. Kinds with a count of zero are left out, so a
/// REAPER project doesn't show "Sampler 0" for a concept it doesn't have.
class ProjectStatsSection extends StatefulWidget {
  const ProjectStatsSection({
    super.key,
    required this.stats,
    required this.labels,
    this.collapsedPluginCount = 16,
    this.padding = EdgeInsets.zero,
  });

  final ProjectStats stats;
  final ProjectStatsLabels labels;
  final int collapsedPluginCount;
  final EdgeInsets padding;

  @override
  State<ProjectStatsSection> createState() => _ProjectStatsSectionState();
}

class _ProjectStatsSectionState extends State<ProjectStatsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final labels = widget.labels;
    final theme = Theme.of(context);

    final kinds = <(IconData, String, int)>[
      (Icons.graphic_eq, labels.audio, stats.audioTracks),
      (Icons.piano, labels.instrument, stats.instrumentTracks),
      (Icons.piano_outlined, labels.midi, stats.midiTracks),
      (Icons.grid_view, labels.sampler, stats.samplerTracks),
      (Icons.call_merge, labels.bus, stats.busTracks),
      (Icons.folder_outlined, labels.folder, stats.folderTracks),
    ].where((k) => k.$3 > 0).toList();

    final plugins = stats.plugins;
    final overflows = plugins.length > widget.collapsedPluginCount;
    final visiblePlugins = (overflows && !_expanded)
        ? plugins.take(widget.collapsedPluginCount).toList()
        : plugins;

    final headingStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    );
    final countStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.textTheme.bodySmall?.color,
    );

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stats.totalTracks > 0) ...[
            Row(
              children: [
                Text(labels.tracks, style: headingStyle),
                const SizedBox(width: 6),
                Text('${stats.totalTracks}', style: countStyle),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (icon, label, count) in kinds)
                  _StatPill(icon: icon, label: label, count: count),
              ],
            ),
          ],
          if (plugins.isNotEmpty) ...[
            if (stats.totalTracks > 0) const SizedBox(height: 16),
            Row(
              children: [
                Text(labels.plugins, style: headingStyle),
                const SizedBox(width: 6),
                Text('${plugins.length}', style: countStyle),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final name in visiblePlugins)
                  Chip(
                    label: Text(name),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            if (overflows)
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    _expanded ? labels.collapse : labels.showAll,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, required this.count});

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
