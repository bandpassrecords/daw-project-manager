import '../models/music_project.dart';
import '../models/notification_preferences.dart';
import '../models/release.dart';
import '../models/todo_item.dart';
import '../utils/todo_due_utils.dart';

/// What a scheduled notification is about.
enum DeadlineNotificationKind {
  /// The project's single delivery deadline (`MusicProject.deadline`).
  projectDeadline,

  /// A per-todo due date (`TodoItem.dueAt`), on a project or a release.
  todoDue,
}

/// One notification the service should schedule.
///
/// Wall-clock only — the planner never touches the `timezone` package, which
/// is what makes it testable off-device. The service turns [scheduledDate]
/// into a `tz.TZDateTime` in the local zone using the same components.
class DeadlineNotificationOccurrence {
  /// Id of the project or release the notification belongs to. Doubles as the
  /// notification payload, so tapping still opens the owning item.
  final String ownerId;

  /// Display name of the project or release, for the notification body.
  final String ownerName;

  final DeadlineNotificationKind kind;

  /// Set only when [kind] is [DeadlineNotificationKind.todoDue].
  final TodoItem? todo;

  /// Local wall-clock instant to fire at (due date shifted back by
  /// [daysRemaining] days, at the configured notification hour/minute).
  final DateTime scheduledDate;

  /// Days between the notification and the date it is about. 0 is the due day
  /// itself.
  final int daysRemaining;

  const DeadlineNotificationOccurrence({
    required this.ownerId,
    required this.ownerName,
    required this.kind,
    required this.scheduledDate,
    required this.daysRemaining,
    this.todo,
  });

  /// Stable, collision-resistant id so re-planning replaces rather than
  /// duplicates. Todo notifications key on the todo id, otherwise every todo
  /// of a project would share the project's id and overwrite each other.
  int get notificationId => kind == DeadlineNotificationKind.todoDue
      ? '${ownerId}_todo_${todo!.id}_$daysRemaining'.hashCode
      : '${ownerId}_$daysRemaining'.hashCode;
}

/// Notification title for [occurrence].
///
/// Deliberately English: notifications are scheduled days in advance and fire
/// with no `BuildContext` to localise against, so the strings can't come from
/// `AppLocalizations` the way UI text does. This matches how project deadline
/// notifications have always read.
String notificationTitleFor(DeadlineNotificationOccurrence occurrence) {
  final isTodo = occurrence.kind == DeadlineNotificationKind.todoDue;
  switch (occurrence.daysRemaining) {
    case 0:
      return isTodo ? 'Task Due Today!' : 'Deadline Today!';
    case 1:
      return isTodo ? 'Task Due Tomorrow!' : 'Deadline Tomorrow!';
    default:
      return isTodo ? 'Upcoming Task' : 'Upcoming Deadline';
  }
}

/// Notification body for [occurrence]. See [notificationTitleFor] on language.
String notificationBodyFor(DeadlineNotificationOccurrence occurrence) {
  final days = occurrence.daysRemaining;
  if (occurrence.kind == DeadlineNotificationKind.todoDue) {
    final task = '"${occurrence.todo!.text}" (${occurrence.ownerName})';
    if (days == 0) return 'Due today: $task';
    if (days == 1) return '1 day left for $task';
    return '$days days left for $task';
  }
  if (days == 0) return 'Today is the deadline for "${occurrence.ownerName}"';
  if (days == 1) return '1 day left for "${occurrence.ownerName}"';
  return '$days days left for "${occurrence.ownerName}"';
}

bool _isFinished(String status) {
  final s = status.toLowerCase();
  return s == 'finished' || s == 'finalizado';
}

/// Every notification that should be pending for [projects] and [releases],
/// given [preferences] and the current time [now].
///
/// Pure: same inputs, same output, no I/O. Both project deadlines and todo
/// due dates run through the one set of preferences — reminder days, the
/// notification time, and the notify-on-the-day toggle — rather than todo due
/// dates getting a second, separate opt-in.
///
/// A due date whose *day* is today still plans: the reminder time may not
/// have passed yet, and any occurrence that is genuinely in the past is
/// dropped by the `isAfter(now)` check below.
List<DeadlineNotificationOccurrence> planDeadlineNotifications({
  required NotificationPreferences preferences,
  required DateTime now,
  List<MusicProject> projects = const [],
  List<Release> releases = const [],
}) {
  if (!preferences.enabled) return const [];

  final occurrences = <DeadlineNotificationOccurrence>[];

  void planFor({
    required String ownerId,
    required String ownerName,
    required DeadlineNotificationKind kind,
    required DateTime dueDate,
    TodoItem? todo,
  }) {
    // Already past — nothing left to remind about.
    final days = daysUntilDue(dueDate, now);
    if (days == null || days < 0) return;

    void add(int daysRemaining) {
      final notifyDate = dueDate.subtract(Duration(days: daysRemaining));
      final scheduledDate = DateTime(
        notifyDate.year,
        notifyDate.month,
        notifyDate.day,
        preferences.notificationHour,
        preferences.notificationMinute,
      );
      if (!scheduledDate.isAfter(now)) return;
      occurrences.add(DeadlineNotificationOccurrence(
        ownerId: ownerId,
        ownerName: ownerName,
        kind: kind,
        todo: todo,
        scheduledDate: scheduledDate,
        daysRemaining: daysRemaining,
      ));
    }

    for (final reminderDays in preferences.reminderDays) {
      add(reminderDays);
    }
    if (preferences.notifyOnDeadlineDay) add(0);
  }

  for (final project in projects) {
    if (_isFinished(project.status)) continue;

    final deadline = project.deadline;
    if (deadline != null) {
      planFor(
        ownerId: project.id,
        ownerName: project.displayName,
        kind: DeadlineNotificationKind.projectDeadline,
        dueDate: deadline,
      );
    }

    for (final todo in project.todos) {
      if (todo.completed || todo.dueAt == null) continue;
      planFor(
        ownerId: project.id,
        ownerName: project.displayName,
        kind: DeadlineNotificationKind.todoDue,
        dueDate: todo.dueAt!,
        todo: todo,
      );
    }
  }

  for (final release in releases) {
    for (final todo in release.todos) {
      if (todo.completed || todo.dueAt == null) continue;
      planFor(
        ownerId: release.id,
        ownerName: release.title,
        kind: DeadlineNotificationKind.todoDue,
        dueDate: todo.dueAt!,
        todo: todo,
      );
    }
  }

  return occurrences;
}
