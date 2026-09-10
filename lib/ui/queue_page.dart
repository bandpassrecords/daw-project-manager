import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/music_project.dart';
import '../models/release.dart';
import '../models/todo_item.dart';
import '../providers/providers.dart';
import '../utils/queue_sections.dart';
import '../utils/todo_due_utils.dart';
import '../generated/l10n/app_localizations.dart';
import 'project_detail_page.dart';
import 'release_detail_page.dart';
import 'widgets/todo_due_chip.dart';

Color _phaseColor(String status) {
  switch (status) {
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

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projectsAsync = ref.watch(allProjectsStreamProvider);
    final releasesAsync = ref.watch(releasesProvider);
    final searchText = ref.watch(queueSearchProvider).toLowerCase().trim();
    final dueFilter = ref.watch(queueDueFilterProvider);
    final now = DateTime.now();

    final releases = releasesAsync.value ?? [];

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.errorLoadingProjects)),
      data: (allProjects) {
        // What to show, and in what order, is decided by the pure
        // buildQueueSections — this page only renders it.
        final sections = buildQueueSections(
          projects: allProjects,
          releases: releases,
          searchText: searchText,
          dueFilter: dueFilter,
          now: now,
        );

        final totalPending = queuePendingCount(sections);

        if (sections.isEmpty) {
          final filtered = dueFilter != QueueDueFilter.all;
          return Column(
            children: [
              _QueueFilterBar(
                summary: null,
                dueFilter: dueFilter,
              ),
              const Divider(height: 1),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        searchText.isEmpty && !filtered
                            ? Icons.check_circle_outline
                            : Icons.search_off,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchText.isNotEmpty
                            ? l10n.queueNoMatchingTasks
                            : filtered
                                ? l10n.queueNoTasksForDueFilter
                                : l10n.queueNoPendingTasks,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (searchText.isEmpty && !filtered)
                        Text(
                          l10n.queueNoPendingTasksHint,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QueueFilterBar(
              summary: l10n.queuePendingSummary(totalPending, sections.length),
              dueFilter: dueFilter,
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final section in sections)
                    switch (section.kind) {
                      QueueOwnerKind.project => _ProjectTodoSection(
                          project: section.project,
                          pendingTodos: section.todos,
                        ),
                      QueueOwnerKind.release => _ReleaseTodoSection(
                          release: section.release,
                          pendingTodos: section.todos,
                        ),
                    },
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Summary line plus the due-date filter, above the queue list.
class _QueueFilterBar extends ConsumerWidget {
  /// Null while the queue is empty — the filter stays reachable so a filter
  /// that hides everything can be undone.
  final String? summary;
  final QueueDueFilter dueFilter;

  const _QueueFilterBar({required this.summary, required this.dueFilter});

  String _labelFor(AppLocalizations l10n, QueueDueFilter filter) {
    switch (filter) {
      case QueueDueFilter.all:
        return l10n.queueDueFilterAll;
      case QueueDueFilter.overdue:
        return l10n.queueDueFilterOverdue;
      case QueueDueFilter.dueToday:
        return l10n.queueDueFilterToday;
      case QueueDueFilter.dueThisWeek:
        return l10n.queueDueFilterThisWeek;
      case QueueDueFilter.noDueDate:
        return l10n.queueDueFilterNoDate;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isFiltered = dueFilter != QueueDueFilter.all;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.checklist, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary ?? '',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<QueueDueFilter>(
            tooltip: l10n.queueDueFilterLabel,
            initialValue: dueFilter,
            onSelected: (filter) =>
                ref.read(queueDueFilterProvider.notifier).set(filter),
            itemBuilder: (_) => [
              for (final filter in QueueDueFilter.values)
                PopupMenuItem(
                  value: filter,
                  child: Text(_labelFor(l10n, filter)),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isFiltered
                    ? accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accent.withValues(alpha: isFiltered ? 0.6 : 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event, size: 14, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    _labelFor(l10n, dueFilter),
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 16, color: accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTodoSection extends ConsumerStatefulWidget {
  final MusicProject project;
  final List<TodoItem> pendingTodos;

  const _ProjectTodoSection({
    required this.project,
    required this.pendingTodos,
  });

  @override
  ConsumerState<_ProjectTodoSection> createState() =>
      _ProjectTodoSectionState();
}

class _ProjectTodoSectionState extends ConsumerState<_ProjectTodoSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final pendingTodos = widget.pendingTodos;
    final phaseColor = _phaseColor(project.status);
    final earliestDue = earliestDueDate(pendingTodos);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Project header — tapping navigates to detail page
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailPage(projectId: project.id),
              ),
            ),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _expanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Phase dot
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: phaseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Project name
                  Expanded(
                    child: Text(
                      project.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Soonest due date in this section — the thing the queue is
                  // ordered by, so it belongs on the header, not just the rows.
                  if (earliestDue != null) ...[
                    TodoDueChip(dueAt: earliestDue),
                    const SizedBox(width: 6),
                  ],
                  // Phase badge
                  _Badge(
                    label: project.status,
                    color: phaseColor,
                  ),
                  const SizedBox(width: 6),
                  // Pending count badge
                  _Badge(
                    label: '${pendingTodos.length}',
                    color: Theme.of(context).colorScheme.primary,
                    filled: true,
                  ),
                  const SizedBox(width: 2),
                  // Expand toggle
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...pendingTodos.map(
              (todo) => _TodoCheckItem(
                project: project,
                todo: todo,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _Badge({
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TodoCheckItem extends ConsumerWidget {
  final MusicProject project;
  final TodoItem todo;
  final VoidCallback? onTap;

  const _TodoCheckItem({
    required this.project,
    required this.todo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: false,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        todo.text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: todo.dueAt == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: TodoDueChip(dueAt: todo.dueAt!),
            ),
      // Due dates are settable from the queue itself — planning them
      // shouldn't mean opening every project in turn.
      secondary: TodoDueButton(
        todo: todo,
        onDueDateChanged: (dueAt) async {
          final repo = await ref.read(repositoryProvider.future);
          final updated = dueAt == null
              ? todo.copyWith(clearDueAt: true)
              : todo.copyWith(dueAt: dueAt);
          final updatedTodos = project.todos
              .map((t) => t.id == todo.id ? updated : t)
              .toList();
          await repo.updateProject(project.copyWith(todos: updatedTodos));
          ref.invalidate(allProjectsStreamProvider);
        },
      ),
      onChanged: (_) async {
        final repo = await ref.read(repositoryProvider.future);
        final updatedTodos = project.todos
            .map((t) => t.id == todo.id ? t.copyWith(completed: true) : t)
            .toList();
        await repo.updateProject(project.copyWith(todos: updatedTodos));
        ref.invalidate(allProjectsStreamProvider);
      },
    );
  }
}


// ─── Release sections ────────────────────────────────────────────────────────

class _ReleaseTodoSection extends ConsumerStatefulWidget {
  final Release release;
  final List<TodoItem> pendingTodos;

  const _ReleaseTodoSection({
    required this.release,
    required this.pendingTodos,
  });

  @override
  ConsumerState<_ReleaseTodoSection> createState() => _ReleaseTodoSectionState();
}

class _ReleaseTodoSectionState extends ConsumerState<_ReleaseTodoSection> {
  bool _expanded = true;

  static const _accentColor = Colors.teal;

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final pendingTodos = widget.pendingTodos;
    final earliestDue = earliestDueDate(pendingTodos);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReleaseDetailPage(releaseId: release.id),
              ),
            ),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _expanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.album, size: 13, color: _accentColor.shade300),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      release.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (earliestDue != null) ...[
                    TodoDueChip(dueAt: earliestDue),
                    const SizedBox(width: 6),
                  ],
                  _Badge(
                    label: 'Release',
                    color: _accentColor.shade300,
                  ),
                  const SizedBox(width: 6),
                  _Badge(
                    label: '${pendingTodos.length}',
                    color: Theme.of(context).colorScheme.primary,
                    filled: true,
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...pendingTodos.map(
              (todo) => _ReleaseTodoCheckItem(release: release, todo: todo),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReleaseTodoCheckItem extends ConsumerWidget {
  final Release release;
  final TodoItem todo;

  const _ReleaseTodoCheckItem({
    required this.release,
    required this.todo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: false,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        todo.text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: todo.dueAt == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: TodoDueChip(dueAt: todo.dueAt!),
            ),
      secondary: TodoDueButton(
        todo: todo,
        onDueDateChanged: (dueAt) async {
          final repo = await ref.read(repositoryProvider.future);
          final updated = dueAt == null
              ? todo.copyWith(clearDueAt: true)
              : todo.copyWith(dueAt: dueAt);
          final updatedTodos = release.todos
              .map((t) => t.id == todo.id ? updated : t)
              .toList();
          await repo.updateRelease(release.copyWith(todos: updatedTodos));
          ref.invalidate(releasesProvider);
        },
      ),
      onChanged: (_) async {
        final repo = await ref.read(repositoryProvider.future);
        final updatedTodos = release.todos
            .map((t) => t.id == todo.id ? t.copyWith(completed: true) : t)
            .toList();
        await repo.updateRelease(release.copyWith(todos: updatedTodos));
        ref.invalidate(releasesProvider);
      },
    );
  }
}
