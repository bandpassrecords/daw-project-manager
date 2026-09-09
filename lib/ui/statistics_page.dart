import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../utils/version_stacks.dart';
import '../models/project_event.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../utils/phase_colors.dart';
import 'project_detail_page.dart';
import 'widgets/project_event_chart.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _phaseColor(String phase) {
  switch (phase) {
    case 'Idea':
      return Colors.blue.shade300;
    case 'Arranging':
      return Colors.orange.shade300;
    case 'Mixing':
      return Colors.purple.shade300;
    case 'Mastering':
      return Colors.pink.shade300;
    case 'Finished':
      return Colors.green.shade300;
    default:
      return Colors.grey;
  }
}

String _formatDuration(Duration d) {
  final days = d.inDays;
  if (days < 1) return '< 1d';
  if (days < 30) return '${days}d';
  final months = (days / 30).round();
  return '${months}mo';
}

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  MusicProject? _selectedProject;
  double _historyPanelWidth = 340.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(globalStatsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _historyPanelWidth,
                child: _HistoryPanel(
                  selectedProject: _selectedProject,
                  onProjectSelected: (p) =>
                      setState(() => _selectedProject = p),
                  l10n: l10n,
                ),
              ),
              // Drag handle to resize the history panel, so long project
              // names don't have to stay truncated.
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => setState(() {
                    _historyPanelWidth = (_historyPanelWidth + details.delta.dx)
                        .clamp(260.0, constraints.maxWidth - 360.0);
                  }),
                  child: Container(
                    width: 6,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: _ChartsPanel(stats: stats, l10n: l10n),
              ),
            ],
          );
        }
        // Narrow: stacked
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChartsPanel(stats: stats, l10n: l10n, compact: true),
              const SizedBox(height: 24),
              _HistoryPanel(
                selectedProject: _selectedProject,
                onProjectSelected: (p) =>
                    setState(() => _selectedProject = p),
                l10n: l10n,
                compact: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Charts Panel (left / top)
// ---------------------------------------------------------------------------

class _ChartsPanel extends ConsumerWidget {
  final GlobalStats stats;
  final AppLocalizations l10n;
  final bool compact;

  const _ChartsPanel({
    required this.stats,
    required this.l10n,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideFinished = ref.watch(statsHideFinishedProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCards(stats: stats, l10n: l10n)),
            ],
          ),
          const SizedBox(height: 8),
          FilterChip(
            avatar: Icon(
              hideFinished ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: hideFinished ? Theme.of(context).colorScheme.primary : null,
            ),
            showCheckmark: false,
            label: Text(l10n.hideFinished,
                style: const TextStyle(fontSize: 12)),
            selected: hideFinished,
            onSelected: (_) =>
                ref.read(statsHideFinishedProvider.notifier).toggle(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 24),
          _SectionTitle(l10n.statsPhaseDistribution),
          const SizedBox(height: 8),
          _PhaseDistributionChart(stats: stats, l10n: l10n),
          const SizedBox(height: 24),
          _SectionTitle(l10n.statsAvgTimePerPhase),
          const SizedBox(height: 8),
          _AvgTimePerPhaseChart(stats: stats, l10n: l10n),
          const SizedBox(height: 24),
          _SectionTitle(l10n.statsProductivity),
          const SizedBox(height: 8),
          _ProductivityChart(stats: stats, l10n: l10n),
          const SizedBox(height: 24),
          _SectionTitle(l10n.statsProjectHealth),
          const SizedBox(height: 8),
          _ProjectHealthList(l10n: l10n),
          const SizedBox(height: 24),
          _SectionTitle(l10n.statsCatalogInsights),
          const SizedBox(height: 8),
          _CatalogInsights(l10n: l10n, compact: compact),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Cards
// ---------------------------------------------------------------------------

class _SummaryCards extends StatelessWidget {
  final GlobalStats stats;
  final AppLocalizations l10n;
  const _SummaryCards({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).cardColor;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          label: l10n.statsTotalProjects,
          value: '${stats.totalProjects}',
          color: cardColor,
          borderColor: primary.withValues(alpha: 0.4),
        ),
        _StatCard(
          label: l10n.statsInProgress,
          value: '${stats.inProgressCount}',
          color: cardColor,
          borderColor: Colors.orange.shade600,
          valueColor: Colors.orange.shade300,
        ),
        _StatCard(
          label: l10n.statsFinished,
          value: '${stats.finishedCount}',
          color: cardColor,
          borderColor: Colors.green.shade600,
          valueColor: Colors.green.shade300,
        ),
        _StatCard(
          label: l10n.statsAvgCompletion,
          value: stats.avgCompletionTime != null
              ? _formatDuration(stats.avgCompletionTime!)
              : '—',
          color: cardColor,
          borderColor: primary.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color borderColor;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.borderColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ??
                      Theme.of(context).textTheme.bodyLarge?.color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase Distribution Bar Chart
// ---------------------------------------------------------------------------

class _PhaseDistributionChart extends ConsumerWidget {
  final GlobalStats stats;
  final AppLocalizations l10n;
  const _PhaseDistributionChart({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phases = ref.watch(customPhasesProvider);
    final storedColors = ref.watch(phaseColorsProvider);
    final counts = stats.countPerPhase;
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return _NoDataPlaceholder(message: l10n.statsNoData);
    }

    final groups = phases.asMap().entries.map((e) {
      final idx = e.key;
      final phase = e.value;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: (counts[phase] ?? 0).toDouble(),
            color: resolvePhaseColor(phase, storedColors, phases),
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= phases.length) return const SizedBox();
                  final p = phases[idx];
                  final label = p.length > 5 ? '${p.substring(0, 4)}.' : p;
                  return Text(label,
                      style: Theme.of(context).textTheme.bodySmall);
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  Theme.of(context).cardColor.withValues(alpha: 0.95),
              getTooltipItem: (group, _, rod, __) {
                final idx = group.x;
                final phase = idx < phases.length ? phases[idx] : '';
                return BarTooltipItem(
                  '$phase\n${rod.toY.toInt()}',
                  Theme.of(context).textTheme.bodySmall!,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avg. Days per Phase Chart
// ---------------------------------------------------------------------------

class _AvgTimePerPhaseChart extends ConsumerWidget {
  final GlobalStats stats;
  final AppLocalizations l10n;
  const _AvgTimePerPhaseChart({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phases = ref.watch(customPhasesProvider);
    final storedColors = ref.watch(phaseColorsProvider);
    final avgDays = stats.avgDaysPerPhase;
    if (avgDays.isEmpty) {
      return _NoDataPlaceholder(message: l10n.statsNoPhaseData);
    }

    final groups = phases.asMap().entries.map((e) {
      final idx = e.key;
      final phase = e.value;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: avgDays[phase] ?? 0.0,
            color: resolvePhaseColor(phase, storedColors, phases).withValues(alpha: 0.7),
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}d',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= phases.length) return const SizedBox();
                  final p = phases[idx];
                  final label = p.length > 5 ? '${p.substring(0, 4)}.' : p;
                  return Text(label,
                      style: Theme.of(context).textTheme.bodySmall);
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  Theme.of(context).cardColor.withValues(alpha: 0.95),
              getTooltipItem: (group, _, rod, __) {
                final idx = group.x;
                final phase = idx < phases.length ? phases[idx] : '';
                return BarTooltipItem(
                  '$phase\n${rod.toY.toStringAsFixed(1)}d',
                  Theme.of(context).textTheme.bodySmall!,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Productivity Over Time (last 12 months)
// ---------------------------------------------------------------------------

class _ProductivityChart extends StatelessWidget {
  final GlobalStats stats;
  final AppLocalizations l10n;
  const _ProductivityChart({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final createdData = stats.createdPerMonth;
    final finishedData = stats.finishedPerMonth;
    if (createdData.isEmpty) {
      return _NoDataPlaceholder(message: l10n.statsNoData);
    }

    final keys = createdData.keys.toList();
    final maxY = [
      ...createdData.values,
      ...finishedData.values,
    ].fold(0, (a, b) => a > b ? a : b).toDouble();

    if (maxY == 0) {
      return _NoDataPlaceholder(message: l10n.statsNoData);
    }

    final primary = Theme.of(context).colorScheme.primary;

    final createdSpots = keys.asMap().entries
        .map((e) => FlSpot(
              e.key.toDouble(),
              (createdData[e.value] ?? 0).toDouble(),
            ))
        .toList();

    final finishedSpots = keys.asMap().entries
        .map((e) => FlSpot(
              e.key.toDouble(),
              (finishedData[e.value] ?? 0).toDouble(),
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: primary, label: l10n.statsCreatedSeries),
            const SizedBox(width: 16),
            _LegendDot(
                color: Colors.green.shade400, label: l10n.statsFinished),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY + 1,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      if (v == v.roundToDouble()) {
                        return Text('${v.toInt()}',
                            style: Theme.of(context).textTheme.bodySmall);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (keys.length / 4).ceilToDouble(),
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= keys.length) {
                        return const SizedBox();
                      }
                      final parts = keys[idx].split('-');
                      final label = parts.length == 2 ? parts[1] : keys[idx];
                      return Text(label,
                          style: Theme.of(context).textTheme.bodySmall);
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: createdSpots,
                  isCurved: true,
                  color: primary,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primary.withValues(alpha: 0.08),
                  ),
                ),
                LineChartBarData(
                  spots: finishedSpots,
                  isCurved: true,
                  color: Colors.green.shade400,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Project Age & Health
// ---------------------------------------------------------------------------

class _ProjectHealthList extends ConsumerWidget {
  final AppLocalizations l10n;
  const _ProjectHealthList({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsStreamProvider);
    final hideFinished = ref.watch(statsHideFinishedProvider);
    final finishedPhases = ref.watch(finishedPhaseProvider);
    // One row per stacked project, with its versions' work time rolled up.
    final allProjects = collapseVersionStacks(projectsAsync.asData?.value ?? []);
    final projects = hideFinished
        ? allProjects.where((p) => !finishedPhases.contains(p.status)).toList()
        : allProjects;

    final inProgress = projects
        .where((p) => !finishedPhases.contains(p.status) && !p.hidden)
        .toList()
      ..sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));

    if (inProgress.isEmpty) {
      return _NoDataPlaceholder(message: l10n.statsNoData);
    }

    final shown = inProgress.take(8).toList();

    return Card(
      color: Theme.of(context).cardColor,
      child: Column(
        children: shown.map((p) {
          final daysSince =
              DateTime.now().difference(p.lastModifiedAt).inDays;
          final isStale = daysSince > 30;
          return ListTile(
            dense: true,
            leading: Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: _phaseColor(p.status),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              p.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              l10n.statsNotTouchedDays(daysSince),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isStale
                        ? Colors.orange.shade300
                        : Theme.of(context).hintColor,
                  ),
            ),
            trailing: _PhaseBadge(phase: p.status),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailPage(projectId: p.id),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Catalog Insights (BPM histogram, top keys, DAW types)
// ---------------------------------------------------------------------------

class _CatalogInsights extends ConsumerWidget {
  final AppLocalizations l10n;
  final bool compact;
  const _CatalogInsights({required this.l10n, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsStreamProvider);
    final hideFinished = ref.watch(statsHideFinishedProvider);
    final finishedPhases = ref.watch(finishedPhaseProvider);
    // One row per stacked project, with its versions' work time rolled up.
    final allProjects = collapseVersionStacks(projectsAsync.asData?.value ?? []);
    final projects = hideFinished
        ? allProjects.where((p) => !finishedPhases.contains(p.status)).toList()
        : allProjects;

    // BPM buckets
    final bpmBuckets = {'<90': 0, '90–119': 0, '120–139': 0, '140+': 0};
    for (final p in projects) {
      final bpm = p.bpm;
      if (bpm == null) continue;
      if (bpm < 90) {
        bpmBuckets['<90'] = bpmBuckets['<90']! + 1;
      } else if (bpm < 120) {
        bpmBuckets['90–119'] = bpmBuckets['90–119']! + 1;
      } else if (bpm < 140) {
        bpmBuckets['120–139'] = bpmBuckets['120–139']! + 1;
      } else {
        bpmBuckets['140+'] = bpmBuckets['140+']! + 1;
      }
    }

    // Top keys
    final keyCount = <String, int>{};
    for (final p in projects) {
      if (p.musicalKey != null && p.musicalKey!.isNotEmpty) {
        keyCount[p.musicalKey!] = (keyCount[p.musicalKey!] ?? 0) + 1;
      }
    }
    final topKeys = keyCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shownKeys = topKeys.take(6).toList();

    // DAW types
    final dawCount = <String, int>{};
    for (final p in projects) {
      if (p.dawType != null && p.dawType!.isNotEmpty) {
        dawCount[p.dawType!] = (dawCount[p.dawType!] ?? 0) + 1;
      }
    }
    final dawEntries = dawCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final charts = [
      _SmallBarChart(
        title: l10n.statsBpmDistribution,
        labels: bpmBuckets.keys.toList(),
        values: bpmBuckets.values.map((v) => v.toDouble()).toList(),
        color: Colors.cyan.shade300,
        l10n: l10n,
      ),
      if (shownKeys.isNotEmpty)
        _SmallBarChart(
          title: l10n.statsTopKeys,
          labels: shownKeys.map((e) => e.key).toList(),
          values: shownKeys.map((e) => e.value.toDouble()).toList(),
          color: Colors.purple.shade300,
          l10n: l10n,
        ),
      if (dawEntries.isNotEmpty)
        _SmallBarChart(
          title: l10n.statsDawTypes,
          labels: dawEntries.map((e) => e.key).toList(),
          values: dawEntries.map((e) => e.value.toDouble()).toList(),
          color: Colors.teal.shade300,
          l10n: l10n,
        ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: charts
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: c,
                ))
            .toList(),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: charts,
    );
  }
}

class _SmallBarChart extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<double> values;
  final Color color;
  final AppLocalizations l10n;

  const _SmallBarChart({
    required this.title,
    required this.labels,
    required this.values,
    required this.color,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = values.fold(0.0, (a, b) => a > b ? a : b);

    if (maxY == 0) {
      return SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _NoDataPlaceholder(message: l10n.statsNoData),
          ],
        ),
      );
    }

    final groups = labels.asMap().entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: values[e.key],
                  color: color,
                  width: 16,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ))
        .toList();

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                barGroups: groups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox();
                        }
                        return Transform.rotate(
                          angle: labels[idx].length > 4 ? -0.5 : 0,
                          child: Text(
                            labels[idx],
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        Theme.of(context).cardColor.withValues(alpha: 0.95),
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${labels[group.x]}: ${rod.toY.toInt()}',
                      Theme.of(context).textTheme.bodySmall!,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Project History Panel (right / bottom)
// ---------------------------------------------------------------------------

class _HistoryPanel extends ConsumerStatefulWidget {
  final MusicProject? selectedProject;
  final void Function(MusicProject?) onProjectSelected;
  final AppLocalizations l10n;
  final bool compact;

  const _HistoryPanel({
    required this.selectedProject,
    required this.onProjectSelected,
    required this.l10n,
    this.compact = false,
  });

  @override
  ConsumerState<_HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends ConsumerState<_HistoryPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final selectedProject = widget.selectedProject;
    final onProjectSelected = widget.onProjectSelected;
    final projects = ref.watch(projectsWithRecentActivityProvider);
    final eventsAsync = ref.watch(allEventsStreamProvider);
    final allEvents = eventsAsync.asData?.value ?? [];
    final searchText = ref.watch(statisticsSearchProvider);

    // Build map of projectId → event count
    final eventCount = <String, int>{};
    for (final e in allEvents) {
      eventCount[e.projectId] = (eventCount[e.projectId] ?? 0) + 1;
    }

    // Build map of projectId → last event time
    final lastEvent = <String, DateTime>{};
    for (final e in allEvents) {
      final ex = lastEvent[e.projectId];
      if (ex == null || e.occurredAt.isAfter(ex)) {
        lastEvent[e.projectId] = e.occurredAt;
      }
    }

    // Filter by search
    final filtered = searchText.trim().isEmpty
        ? projects
        : projects.where((p) {
            final name = p.displayName.toLowerCase();
            final words = searchText.toLowerCase().trim().split(RegExp(r'\s+'));
            return words.every((w) => name.contains(w));
          }).toList();

    final selectedEvents = selectedProject != null
        ? (allEvents
            .where((e) => e.projectId == selectedProject!.id)
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)))
        : <ProjectEvent>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(l10n.statsProjectActivity,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        if (selectedProject != null) ...[
          _EventHistorySection(
            project: selectedProject!,
            events: selectedEvents,
            onClose: () => onProjectSelected(null),
            onClearHistory: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(ctx).cardColor,
                  title: Text(l10n.statsClearHistory),
                  content: Text(l10n.statsClearHistoryConfirm),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.statsClearHistory)),
                  ],
                ),
              );
              if (confirmed == true) {
                final repo =
                    await ref.read(repositoryProvider.future);
                await repo.clearEventsForProject(selectedProject!.id);
              }
            },
            l10n: l10n,
          ),
          const Divider(height: 1),
        ],
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
                child: Text(l10n.statsNoProjectsFound,
                    style: Theme.of(context).textTheme.bodySmall)),
          )
        else if (widget.compact)
          ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final project = filtered[index];
                    final count = eventCount[project.id] ?? 0;
                    final last = lastEvent[project.id];
                    final isSelected =
                        selectedProject?.id == project.id;

                    String subtitle;
                    if (last == null) {
                      subtitle = l10n.statsNoEvents;
                    } else {
                      final days =
                          DateTime.now().difference(last).inDays;
                      subtitle = days == 0
                          ? l10n.statsLastActivityToday
                          : l10n.statsLastActivityDaysAgo(days);
                    }

                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      onTap: () => onProjectSelected(
                          isSelected ? null : project),
                      title: Text(
                        project.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: count > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PhaseBadge(phase: project.status),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.statsEventCount(count),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            )
                          : _PhaseBadge(phase: project.status),
                    );
                  },
                )
        else
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final project = filtered[index];
                  final count = eventCount[project.id] ?? 0;
                  final last = lastEvent[project.id];

                  String subtitle;
                  if (last == null) {
                    subtitle = l10n.statsNoEvents;
                  } else {
                    final days = DateTime.now().difference(last).inDays;
                    subtitle = days == 0
                        ? l10n.statsLastActivityToday
                        : l10n.statsLastActivityDaysAgo(days);
                  }

                  final isSelected = selectedProject?.id == project.id;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    onTap: () => onProjectSelected(isSelected ? null : project),
                    title: Text(
                      project.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    subtitle: Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                    trailing: count > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PhaseBadge(phase: project.status),
                              const SizedBox(width: 6),
                              Text(
                                l10n.statsEventCount(count),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          )
                        : _PhaseBadge(phase: project.status),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Event History Section — visual vertical timeline
// ---------------------------------------------------------------------------

class _EventHistorySection extends StatelessWidget {
  final MusicProject project;
  final List<ProjectEvent> events;
  final VoidCallback onClose;
  final VoidCallback onClearHistory;
  final AppLocalizations l10n;

  const _EventHistorySection({
    required this.project,
    required this.events,
    required this.onClose,
    required this.onClearHistory,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // Chronological order for the visual timeline (oldest → newest, top → bottom)
    final chronological = [...events]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            title: Text(
              project.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              l10n.statsEventCount(events.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: l10n.statsClearHistory,
                  onPressed: onClearHistory,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l10n.statsNoEvents,
                  style: Theme.of(context).textTheme.bodySmall),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: ProjectEventChart(events: events),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                shrinkWrap: true,
                itemCount: chronological.length,
                itemBuilder: (context, index) => _TimelineEventTile(
                  event: chronological[index],
                  isFirst: index == 0,
                  isLast: index == chronological.length - 1,
                  l10n: l10n,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single timeline row
// ---------------------------------------------------------------------------

class _TimelineEventTile extends StatelessWidget {
  final ProjectEvent event;
  final bool isFirst;
  final bool isLast;
  final AppLocalizations l10n;

  const _TimelineEventTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.l10n,
  });

  static const double _dotSize = 10;
  static const double _lineWidth = 2;
  static const double _dateColWidth = 54;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hintColor = Theme.of(context).hintColor;
    final bodySmall = Theme.of(context).textTheme.bodySmall;

    IconData icon;
    String label;
    Color dotColor;

    try {
      final payload = event.payload != null
          ? jsonDecode(event.payload!) as Map<String, dynamic>
          : <String, dynamic>{};

      switch (event.eventType) {
        case ProjectEvent.statusChange:
          icon = Icons.swap_horiz;
          final toPhase = payload['to'] as String? ?? '';
          dotColor = _phaseColor(toPhase);
          label = l10n.statsEventPhaseChanged(
            payload['from'] as String? ?? '',
            toPhase,
          );
          break;
        case ProjectEvent.metadataEdit:
          icon = Icons.edit_outlined;
          dotColor = colorScheme.secondary;
          final fields =
              (payload['fields'] as List?)?.cast<String>().join(', ') ?? '';
          label = l10n.statsEventMetadataUpdated(fields);
          break;
        case ProjectEvent.todoCompleted:
          icon = Icons.check_circle_outline;
          dotColor = Colors.green;
          label =
              l10n.statsEventTodoCompleted(payload['todoText'] as String? ?? '');
          break;
        case ProjectEvent.fileChanged:
          icon = Icons.folder_outlined;
          dotColor = Colors.orange;
          label = l10n.statsEventFileModified;
          break;
        default:
          icon = Icons.circle_outlined;
          dotColor = hintColor;
          label = event.eventType;
      }
    } catch (_) {
      icon = Icons.circle_outlined;
      dotColor = hintColor;
      label = event.eventType;
    }

    final dt = event.occurredAt;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${dt.day}/${dt.month}\n${dt.year.toString().substring(2)}';
    final isToday = DateTime.now().difference(dt).inDays == 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: date label ──────────────────────────────────
          SizedBox(
            width: _dateColWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isToday)
                  Text(timeStr,
                      style: bodySmall?.copyWith(
                          fontSize: 9,
                          color: hintColor,
                          fontFeatures: const [FontFeature.tabularFigures()]))
                else ...[
                  Text(dateStr,
                      textAlign: TextAlign.right,
                      style: bodySmall?.copyWith(
                          fontSize: 9,
                          color: hintColor,
                          height: 1.3,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  Text(timeStr,
                      style: bodySmall?.copyWith(
                          fontSize: 9,
                          color: hintColor.withValues(alpha: 0.6),
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Center: line + dot ────────────────────────────────
          SizedBox(
            width: _dotSize + 8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top segment of the connecting line
                Expanded(
                  child: Center(
                    child: isFirst
                        ? const SizedBox.shrink()
                        : Container(
                            width: _lineWidth,
                            color: hintColor.withValues(alpha: 0.25),
                          ),
                  ),
                ),
                // The dot
                Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Bottom segment of the connecting line
                Expanded(
                  child: Center(
                    child: isLast
                        ? const SizedBox.shrink()
                        : Container(
                            width: _lineWidth,
                            color: hintColor.withValues(alpha: 0.25),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Right: event icon + description ──────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: dotColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: bodySmall?.copyWith(height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleSmall);
  }
}

class _NoDataPlaceholder extends StatelessWidget {
  final String message;
  const _NoDataPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  final String phase;
  const _PhaseBadge({required this.phase});

  @override
  Widget build(BuildContext context) {
    final color = _phaseColor(phase);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        phase,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}
