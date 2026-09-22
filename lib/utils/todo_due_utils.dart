import '../models/todo_item.dart';

/// How a todo's due date relates to "now", for colouring and filtering.
///
/// Deliberately date-only: a todo due "today" stays `dueToday` all day rather
/// than flipping to `overdue` at 00:00 of the date it carries.
enum TodoDueStatus {
  /// No due date set.
  none,

  /// Due date is before today.
  overdue,

  /// Due date is today.
  dueToday,

  /// Due within the next week (tomorrow through +7 days).
  dueSoon,

  /// Due later than a week from now.
  upcoming,
}

/// Whole days from [now]'s date to [dueAt]'s date — negative when overdue,
/// 0 when due today. Null when [dueAt] is null.
int? daysUntilDue(DateTime? dueAt, DateTime now) {
  if (dueAt == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
  return dueDay.difference(today).inDays;
}

TodoDueStatus todoDueStatus(DateTime? dueAt, DateTime now) {
  final days = daysUntilDue(dueAt, now);
  if (days == null) return TodoDueStatus.none;
  if (days < 0) return TodoDueStatus.overdue;
  if (days == 0) return TodoDueStatus.dueToday;
  if (days <= 7) return TodoDueStatus.dueSoon;
  return TodoDueStatus.upcoming;
}

/// Which todos the Task Queue shows.
enum QueueDueFilter {
  all,
  overdue,
  dueToday,

  /// Overdue, due today, or due within the next 7 days.
  dueThisWeek,

  /// Todos with no due date at all.
  noDueDate,
}

bool matchesDueFilter(TodoItem todo, QueueDueFilter filter, DateTime now) {
  final status = todoDueStatus(todo.dueAt, now);
  switch (filter) {
    case QueueDueFilter.all:
      return true;
    case QueueDueFilter.overdue:
      return status == TodoDueStatus.overdue;
    case QueueDueFilter.dueToday:
      return status == TodoDueStatus.dueToday;
    case QueueDueFilter.dueThisWeek:
      return status == TodoDueStatus.overdue ||
          status == TodoDueStatus.dueToday ||
          status == TodoDueStatus.dueSoon;
    case QueueDueFilter.noDueDate:
      return status == TodoDueStatus.none;
  }
}

/// Orders todos by what is actually due next: earliest due date first, then
/// undated todos (oldest first, so long-ignored ones surface), ties broken by
/// text so the order is stable across rebuilds.
int compareTodosByDue(TodoItem a, TodoItem b) {
  final aDue = a.dueAt;
  final bDue = b.dueAt;
  if (aDue != null && bDue != null) {
    final cmp = aDue.compareTo(bDue);
    if (cmp != 0) return cmp;
  } else if (aDue != null) {
    return -1;
  } else if (bDue != null) {
    return 1;
  } else {
    final cmp = a.createdAt.compareTo(b.createdAt);
    if (cmp != 0) return cmp;
  }
  return a.text.toLowerCase().compareTo(b.text.toLowerCase());
}

List<TodoItem> sortTodosByDue(Iterable<TodoItem> todos) =>
    todos.toList()..sort(compareTodosByDue);

/// The earliest due date among [todos], or null when none of them is dated.
/// Used to order Task Queue sections by what is due soonest.
DateTime? earliestDueDate(Iterable<TodoItem> todos) {
  DateTime? earliest;
  for (final todo in todos) {
    final due = todo.dueAt;
    if (due == null) continue;
    if (earliest == null || due.isBefore(earliest)) earliest = due;
  }
  return earliest;
}

/// Compares two Task Queue sections: the one holding the soonest due todo
/// comes first, sections with no dated todo sink below all dated ones, and
/// among equals the bigger backlog wins.
int compareSectionsByDue(
  Iterable<TodoItem> a,
  Iterable<TodoItem> b, {
  required String aName,
  required String bName,
}) {
  final aDue = earliestDueDate(a);
  final bDue = earliestDueDate(b);
  if (aDue != null && bDue != null) {
    final cmp = aDue.compareTo(bDue);
    if (cmp != 0) return cmp;
  } else if (aDue != null) {
    return -1;
  } else if (bDue != null) {
    return 1;
  }
  final cmp = b.length.compareTo(a.length);
  if (cmp != 0) return cmp;
  return aName.toLowerCase().compareTo(bName.toLowerCase());
}
