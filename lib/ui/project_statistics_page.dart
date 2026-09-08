import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../utils/version_stacks.dart';
import '../models/music_project.dart';
import '../models/project_event.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/project_event_chart.dart';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ProjectStatisticsPage extends ConsumerWidget {
  final String projectId;
  const ProjectStatisticsPage({required this.projectId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MobileUtils.isMobile();
    final projectsAsync = ref.watch(allProjectsStreamProvider);
    final events = ref.watch(eventsForProjectProvider(projectId));

    // Collapsed so opening the history of a stacked project shows the work
    // time of every version, not the stack row's stored zero.
    final project = collapseVersionStacks(projectsAsync.asData?.value ?? [])
        .where((p) => p.id == projectId)
        .firstOrNull;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(l10n.statsViewHistory),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(
            title: project != null
                ? '${project.displayName} — ${l10n.statsViewHistory}'
                : l10n.statsViewHistory,
            showBack: true,
          ),
          if (project == null)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: _ProjectStatsBody(
                project: project,
                events: events,
                l10n: l10n,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _ProjectStatsBody extends StatelessWidget {
  final MusicProject project;
  final List<ProjectEvent> events;
  final AppLocalizations l10n;

  const _ProjectStatsBody({
    required this.project,
    required this.events,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final chronological = [...events]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick stats ─────────────────────────────────────────────────
          _QuickStatsRow(project: project, events: events, l10n: l10n),
          const SizedBox(height: 24),

          // ── Event scatter chart ─────────────────────────────────────────
          if (events.isNotEmpty) ...[
            _SectionTitle(l10n.statsSingleProjectActivity),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: ProjectEventChart(events: events),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Phase history ───────────────────────────────────────────────
          _SectionTitle(l10n.statsPhaseHistory),
          const SizedBox(height: 8),
          _PhaseHistorySection(
              project: project, events: chronological, l10n: l10n),
          const SizedBox(height: 24),

          // ── Event breakdown ─────────────────────────────────────────────
          _SectionTitle(l10n.statsEventBreakdown),
          const SizedBox(height: 8),
          _EventBreakdownRow(events: events, l10n: l10n),
          const SizedBox(height: 24),

          // ── Full timeline ───────────────────────────────────────────────
          _SectionTitle(l10n.statsSingleProjectActivity),
          const SizedBox(height: 8),
          if (chronological.isEmpty)
            _Placeholder(l10n.statsNoEvents)
          else
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < chronological.length; i++)
                    _TimelineRow(
                      event: chronological[i],
                      isFirst: i == 0,
                      isLast: i == chronological.length - 1,
                      l10n: l10n,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick stats row
// ---------------------------------------------------------------------------

class _QuickStatsRow extends StatelessWidget {
  final MusicProject project;
  final List<ProjectEvent> events;
  final AppLocalizations l10n;
  const _QuickStatsRow(
      {required this.project, required this.events, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(project.createdAt).inDays;
    final lastActivity = events.isEmpty
        ? null
        : (events..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)))
            .first
            .occurredAt;
    final daysSinceActivity =
        lastActivity == null ? null : DateTime.now().difference(lastActivity).inDays;

    final cards = [
      _StatCard(
        icon: Icons.calendar_today_outlined,
        label: l10n.statsTotalProjects, // reuse "Total" label slot with age
        value: '${age}d',
        color: Colors.blue,
      ),
      _StatCard(
        icon: Icons.flag_outlined,
        label: l10n.statsProjectHealth,
        value: project.status,
        color: _phaseColor(project.status),
      ),
      _StatCard(
        icon: Icons.history,
        label: l10n.statsSingleProjectActivity,
        value: daysSinceActivity == null
            ? '—'
            : daysSinceActivity == 0
                ? l10n.statsLastActivityToday
                : l10n.statsLastActivityDaysAgo(daysSinceActivity),
        color: Colors.teal,
      ),
      _StatCard(
        icon: Icons.event_note_outlined,
        label: l10n.statsEventBreakdown,
        value: l10n.statsEventCount(events.length),
        color: Colors.purple,
      ),
    ];

    return Wrap(spacing: 12, runSpacing: 12, children: cards);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 150,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 8),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase history
// ---------------------------------------------------------------------------

class _PhaseHistorySection extends StatelessWidget {
  final MusicProject project;
  final List<ProjectEvent> events; // already sorted chronologically
  final AppLocalizations l10n;
  const _PhaseHistorySection(
      {required this.project, required this.events, required this.l10n});

  @override
  Widget build(BuildContext context) {
    // Build list of (phase, enteredAt, exitedAt?) from status_change events
    final statusEvents = events
        .where((e) => e.eventType == ProjectEvent.statusChange)
        .toList();

    if (statusEvents.isEmpty) {
      return _Placeholder(l10n.statsNoPhaseData);
    }

    final segments = <_PhaseSegment>[];
    for (int i = 0; i < statusEvents.length; i++) {
      try {
        final payload =
            jsonDecode(statusEvents[i].payload ?? '{}') as Map<String, dynamic>;
        final phase = payload['to'] as String? ?? '';
        final entered = statusEvents[i].occurredAt;
        final exited = i + 1 < statusEvents.length
            ? statusEvents[i + 1].occurredAt
            : null; // current phase
        segments.add(_PhaseSegment(phase: phase, entered: entered, exited: exited));
      } catch (_) {}
    }

    if (segments.isEmpty) return _Placeholder(l10n.statsNoPhaseData);

    // Max days for bar scaling
    final now = DateTime.now();
    final maxDays = segments
        .map((s) => (s.exited ?? now).difference(s.entered).inDays)
        .fold(1, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: segments.map((seg) {
            final days = (seg.exited ?? now).difference(seg.entered).inDays;
            final isCurrent = seg.exited == null;
            final color = _phaseColor(seg.phase);
            final fraction = maxDays == 0 ? 0.0 : days / maxDays;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      seg.phase,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 14,
                            width: constraints.maxWidth * fraction.clamp(0.02, 1.0),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: isCurrent ? 0.5 : 0.8),
                              borderRadius: BorderRadius.circular(4),
                              border: isCurrent
                                  ? Border.all(
                                      color: color, width: 1.5,
                                      strokeAlign: BorderSide.strokeAlignInside)
                                  : null,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Text(
                      isCurrent
                          ? l10n.statsDaysSoFar(days)
                          : '${days}d',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCurrent ? color : Theme.of(context).hintColor,
                          fontStyle: isCurrent ? FontStyle.italic : FontStyle.normal),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PhaseSegment {
  final String phase;
  final DateTime entered;
  final DateTime? exited;
  const _PhaseSegment(
      {required this.phase, required this.entered, this.exited});
}

// ---------------------------------------------------------------------------
// Event breakdown chips
// ---------------------------------------------------------------------------

class _EventBreakdownRow extends StatelessWidget {
  final List<ProjectEvent> events;
  final AppLocalizations l10n;
  const _EventBreakdownRow({required this.events, required this.l10n});

  @override
  Widget build(BuildContext context) {
    int phases = 0, meta = 0, todos = 0, files = 0;
    for (final e in events) {
      switch (e.eventType) {
        case ProjectEvent.statusChange:
          phases++;
          break;
        case ProjectEvent.metadataEdit:
          meta++;
          break;
        case ProjectEvent.todoCompleted:
          todos++;
          break;
        case ProjectEvent.fileChanged:
          files++;
          break;
      }
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _BreakdownChip(
            icon: Icons.swap_horiz,
            count: phases,
            label: l10n.statsEventPhaseChanged('', '').split(':').first.trim(),
            color: Colors.purple),
        _BreakdownChip(
            icon: Icons.edit_outlined,
            count: meta,
            label: l10n.statsEventMetadataUpdated('').split(':').first.trim(),
            color: Colors.blueAccent),
        _BreakdownChip(
            icon: Icons.check_circle_outline,
            count: todos,
            label: l10n.statsEventTodoCompleted('').split(':').first.trim(),
            color: Colors.green),
        _BreakdownChip(
            icon: Icons.folder_outlined,
            count: files,
            label: l10n.statsEventFileModified.split(' ').first,
            color: Colors.orange),
      ],
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  const _BreakdownChip(
      {required this.icon,
      required this.count,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline row (vertical timeline)
// ---------------------------------------------------------------------------

class _TimelineRow extends StatelessWidget {
  final ProjectEvent event;
  final bool isFirst;
  final bool isLast;
  final AppLocalizations l10n;
  const _TimelineRow(
      {required this.event,
      required this.isFirst,
      required this.isLast,
      required this.l10n});

  static const double _dotSize = 10;
  static const double _lineW = 2;
  static const double _dateColW = 60;

  @override
  Widget build(BuildContext context) {
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
          final to = payload['to'] as String? ?? '';
          dotColor = _phaseColor(to);
          label = l10n.statsEventPhaseChanged(payload['from'] as String? ?? '', to);
          break;
        case ProjectEvent.metadataEdit:
          icon = Icons.edit_outlined;
          dotColor = Colors.blueAccent;
          label = l10n.statsEventMetadataUpdated(
              (payload['fields'] as List?)?.cast<String>().join(', ') ?? '');
          break;
        case ProjectEvent.todoCompleted:
          icon = Icons.check_circle_outline;
          dotColor = Colors.green;
          label = l10n.statsEventTodoCompleted(payload['todoText'] as String? ?? '');
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
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}';
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date column
          SizedBox(
            width: _dateColW,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style:
                          bodySmall?.copyWith(fontSize: 9, color: hintColor, height: 1.3)),
                  Text(timeStr,
                      style: bodySmall?.copyWith(
                          fontSize: 9,
                          color: hintColor.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ),
          // Line + dot
          SizedBox(
            width: _dotSize + 12,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: isFirst
                        ? const SizedBox.shrink()
                        : Container(
                            width: _lineW,
                            color: hintColor.withValues(alpha: 0.2)),
                  ),
                ),
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
                          spreadRadius: 1)
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: isLast
                        ? const SizedBox.shrink()
                        : Container(
                            width: _lineW,
                            color: hintColor.withValues(alpha: 0.2)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: dotColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(label,
                        style: bodySmall?.copyWith(height: 1.3),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
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
// Shared helpers
// ---------------------------------------------------------------------------

Color _phaseColor(String phase) {
  switch (phase) {
    case 'Idea':
      return Colors.purple;
    case 'Composing':
      return Colors.blue;
    case 'Arranging':
      return Colors.teal;
    case 'Mixing':
      return Colors.orange;
    case 'Mastering':
      return Colors.deepOrange;
    case 'Finished':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleSmall);
}

class _Placeholder extends StatelessWidget {
  final String message;
  const _Placeholder(this.message);
  @override
  Widget build(BuildContext context) => Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor)),
        ),
      );
}
