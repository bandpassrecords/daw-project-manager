import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/todo_item.dart';
import '../../utils/todo_due_utils.dart';

/// Colour a [TodoDueStatus] reads in. Overdue and due-today are deliberately
/// the two loud ones — everything further out stays quiet so they stand out.
///
/// Derived from the active theme, never from theme identity, so user themes
/// get sensible colours too.
Color todoDueColor(BuildContext context, TodoDueStatus status) {
  switch (status) {
    case TodoDueStatus.overdue:
      return Colors.red.shade300;
    case TodoDueStatus.dueToday:
      return Colors.orange.shade300;
    case TodoDueStatus.dueSoon:
      return Theme.of(context).colorScheme.primary;
    case TodoDueStatus.upcoming:
    case TodoDueStatus.none:
      return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
  }
}

/// Human-readable label for a due date: "2 days overdue", "Due today",
/// "Due tomorrow", or the formatted date.
String todoDueLabel(BuildContext context, DateTime dueAt, {DateTime? now}) {
  final l10n = AppLocalizations.of(context)!;
  final days = daysUntilDue(dueAt, now ?? DateTime.now())!;
  if (days < 0) return l10n.todoOverdueByDays(days.abs());
  if (days == 0) return l10n.todoDueToday;
  if (days == 1) return l10n.todoDueTomorrow;
  final locale = Localizations.localeOf(context).toString();
  return l10n.todoDueOn(DateFormat.MMMd(locale).format(dueAt));
}

/// Compact due-date badge shown next to a todo's text.
class TodoDueChip extends StatelessWidget {
  final DateTime dueAt;

  /// Completed todos show their due date greyed out — a finished task isn't
  /// overdue, however long ago it was due.
  final bool muted;

  /// Injectable clock, so widget tests don't depend on the wall clock.
  final DateTime? now;

  const TodoDueChip({
    super.key,
    required this.dueAt,
    this.muted = false,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final status =
        muted ? TodoDueStatus.upcoming : todoDueStatus(dueAt, now ?? DateTime.now());
    final color = todoDueColor(context, status);
    final isUrgent =
        status == TodoDueStatus.overdue || status == TodoDueStatus.dueToday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isUrgent ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: isUrgent ? 0.6 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == TodoDueStatus.overdue
                ? Icons.event_busy
                : status == TodoDueStatus.dueToday
                    ? Icons.today
                    : Icons.event,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            todoDueLabel(context, dueAt, now: now),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Entries of the due-date menu on a todo that already has a due date.
enum _DueDateAction { change, clear }

/// The due-date control on a todo row: a plain "set" button while the todo has
/// no due date, a change/clear menu once it has one.
///
/// Shared by the project/release todo list and the Task Queue so a due date
/// can be set from wherever the task is in front of you, the same way.
class TodoDueButton extends StatelessWidget {
  final TodoItem todo;

  /// Called with the new due date, or null when it was cleared.
  final void Function(DateTime? dueAt) onDueDateChanged;

  /// Injectable clock, so widget tests don't depend on the wall clock.
  final DateTime? now;

  const TodoDueButton({
    super.key,
    required this.todo,
    required this.onDueDateChanged,
    this.now,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await pickTodoDueDate(context, todo.dueAt);
    if (picked == null) return;
    // Store at midnight: due dates are date-only, and a stray time component
    // would make "due today" depend on the hour it was set.
    onDueDateChanged(DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (todo.dueAt == null) {
      return IconButton(
        icon: const Icon(Icons.event_outlined, size: 18),
        color: Theme.of(context).textTheme.bodyMedium?.color,
        onPressed: () => _pick(context),
        tooltip: l10n.todoSetDueDate,
      );
    }

    final status = todo.completed
        ? TodoDueStatus.upcoming
        : todoDueStatus(todo.dueAt, now ?? DateTime.now());

    return PopupMenuButton<_DueDateAction>(
      tooltip: l10n.todoDueDate,
      icon: Icon(
        Icons.event_available,
        size: 18,
        color: todoDueColor(context, status),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _DueDateAction.change,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event, size: 18),
              const SizedBox(width: 8),
              Text(l10n.todoSetDueDate),
            ],
          ),
        ),
        PopupMenuItem(
          value: _DueDateAction.clear,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy, size: 18),
              const SizedBox(width: 8),
              Text(l10n.todoClearDueDate),
            ],
          ),
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case _DueDateAction.change:
            _pick(context);
          case _DueDateAction.clear:
            onDueDateChanged(null);
        }
      },
    );
  }
}

/// Opens the date picker for a todo's due date.
///
/// [firstDate] reaches back past an existing overdue date on purpose: the
/// picker asserts `initialDate >= firstDate`, so anchoring at today would
/// crash the moment someone reopens the picker on an overdue todo.
Future<DateTime?> pickTodoDueDate(BuildContext context, DateTime? current) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final initial = current ?? today;
  final firstDate = initial.isBefore(today) ? initial : today;
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate.subtract(const Duration(days: 1)),
    lastDate: today.add(const Duration(days: 365 * 5)),
  );
}
