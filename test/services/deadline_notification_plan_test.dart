import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/notification_preferences.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/services/deadline_notification_plan.dart';

import '../helpers/test_factories.dart';

void main() {
  // 09:00 is the default notification time, so "now" sits before it to keep
  // same-day reminders in play.
  final now = DateTime(2025, 6, 10, 7, 0);

  NotificationPreferences prefs({
    bool enabled = true,
    List<int> reminderDays = const [1, 3],
    bool notifyOnDeadlineDay = true,
    int hour = 9,
    int minute = 0,
  }) =>
      NotificationPreferences(
        enabled: enabled,
        reminderDays: reminderDays,
        notifyOnDeadlineDay: notifyOnDeadlineDay,
        notificationHour: hour,
        notificationMinute: minute,
      );

  List<DeadlineNotificationOccurrence> todoOccurrences(
    List<DeadlineNotificationOccurrence> all,
  ) =>
      all
          .where((o) => o.kind == DeadlineNotificationKind.todoDue)
          .toList();

  group('planDeadlineNotifications — todo due dates (#113)', () {
    test('schedules a reminder per configured day plus the due day itself', () {
      final project = TestFactories.makeProject(
        id: 'p1',
        deadline: null,
        todos: [
          TestFactories.makeTodo(
            id: 't1',
            text: 'Vocals',
            dueAt: DateTime(2025, 6, 20),
          ),
        ],
      );

      final occurrences = planDeadlineNotifications(
        preferences: prefs(),
        now: now,
        projects: [project],
      );

      expect(occurrences.length, 3);
      expect(
        occurrences.map((o) => o.scheduledDate),
        containsAll([
          DateTime(2025, 6, 19, 9), // 1 day before
          DateTime(2025, 6, 17, 9), // 3 days before
          DateTime(2025, 6, 20, 9), // the due day
        ]),
      );
      expect(occurrences.every((o) => o.kind == DeadlineNotificationKind.todoDue),
          isTrue);
      expect(occurrences.first.todo!.text, 'Vocals');
      expect(occurrences.first.ownerId, 'p1');
    });

    test('honours the notification time rather than the date stored on the todo', () {
      final occurrences = planDeadlineNotifications(
        preferences: prefs(reminderDays: const [], hour: 18, minute: 30),
        now: now,
        projects: [
          TestFactories.makeProject(
            deadline: null,
            todos: [
              TestFactories.makeTodo(
                dueAt: DateTime(2025, 6, 20, 3, 15),
              ),
            ],
          ),
        ],
      );

      expect(occurrences.single.scheduledDate, DateTime(2025, 6, 20, 18, 30));
    });

    test('a todo due today still fires while the reminder time is ahead', () {
      final occurrences = planDeadlineNotifications(
        preferences: prefs(reminderDays: const []),
        now: now,
        projects: [
          TestFactories.makeProject(
            deadline: null,
            todos: [TestFactories.makeTodo(dueAt: DateTime(2025, 6, 10))],
          ),
        ],
      );

      expect(occurrences.single.scheduledDate, DateTime(2025, 6, 10, 9));
      expect(occurrences.single.daysRemaining, 0);
    });

    test('drops reminder days that already passed', () {
      final occurrences = planDeadlineNotifications(
        preferences: prefs(reminderDays: const [1, 3, 7]),
        now: now,
        projects: [
          TestFactories.makeProject(
            deadline: null,
            // Due in two days: the 3- and 7-day reminders are already behind us.
            todos: [TestFactories.makeTodo(dueAt: DateTime(2025, 6, 12))],
          ),
        ],
      );

      expect(occurrences.map((o) => o.daysRemaining), unorderedEquals([1, 0]));
    });

    test('skips completed, undated and past-due todos', () {
      final project = TestFactories.makeProject(
        deadline: null,
        todos: [
          TestFactories.makeTodo(
              id: 'done', completed: true, dueAt: DateTime(2025, 6, 20)),
          TestFactories.makeTodo(id: 'undated'),
          TestFactories.makeTodo(id: 'past', dueAt: DateTime(2025, 6, 1)),
        ],
      );

      expect(
        planDeadlineNotifications(
          preferences: prefs(),
          now: now,
          projects: [project],
        ),
        isEmpty,
      );
    });

    test('skips todos on a finished project', () {
      final project = TestFactories.makeProject(
        status: 'Finished',
        deadline: null,
        todos: [TestFactories.makeTodo(dueAt: DateTime(2025, 6, 20))],
      );

      expect(
        planDeadlineNotifications(
          preferences: prefs(),
          now: now,
          projects: [project],
        ),
        isEmpty,
      );
    });

    test('covers release todos too — the queue lists them alongside projects', () {
      final release = Release(
        id: 'r1',
        title: 'Summer EP',
        trackIds: const [],
        todos: [
          TestFactories.makeTodo(id: 'art', text: 'Cover art', dueAt: DateTime(2025, 6, 20)),
        ],
      );

      final occurrences = planDeadlineNotifications(
        preferences: prefs(reminderDays: const []),
        now: now,
        releases: [release],
      );

      expect(occurrences.single.ownerId, 'r1');
      expect(occurrences.single.ownerName, 'Summer EP');
      expect(occurrences.single.todo!.text, 'Cover art');
    });

    test('every todo of a project gets its own notification id', () {
      // A shared id would mean each todo silently replacing the last, leaving
      // one notification for a project with five dated tasks.
      final project = TestFactories.makeProject(
        id: 'p1',
        deadline: DateTime(2025, 6, 20),
        todos: [
          TestFactories.makeTodo(id: 't1', dueAt: DateTime(2025, 6, 20)),
          TestFactories.makeTodo(id: 't2', dueAt: DateTime(2025, 6, 20)),
        ],
      );

      final occurrences = planDeadlineNotifications(
        preferences: prefs(reminderDays: const []),
        now: now,
        projects: [project],
      );

      expect(occurrences.length, 3);
      expect(occurrences.map((o) => o.notificationId).toSet().length, 3);
    });

    test('reminder days for one todo do not collide with each other', () {
      final occurrences = planDeadlineNotifications(
        preferences: prefs(reminderDays: const [1, 3]),
        now: now,
        projects: [
          TestFactories.makeProject(
            deadline: null,
            todos: [TestFactories.makeTodo(dueAt: DateTime(2025, 6, 20))],
          ),
        ],
      );

      expect(occurrences.map((o) => o.notificationId).toSet().length,
          occurrences.length);
    });

    test('respects the shared enable switch — no second opt-in', () {
      expect(
        planDeadlineNotifications(
          preferences: prefs(enabled: false),
          now: now,
          projects: [
            TestFactories.makeProject(
              deadline: DateTime(2025, 6, 20),
              todos: [TestFactories.makeTodo(dueAt: DateTime(2025, 6, 20))],
            ),
          ],
        ),
        isEmpty,
      );
    });

    test('notifyOnDeadlineDay off drops the due-day reminder for todos too', () {
      final occurrences = planDeadlineNotifications(
        preferences: prefs(reminderDays: const [1], notifyOnDeadlineDay: false),
        now: now,
        projects: [
          TestFactories.makeProject(
            deadline: null,
            todos: [TestFactories.makeTodo(dueAt: DateTime(2025, 6, 20))],
          ),
        ],
      );

      expect(occurrences.map((o) => o.daysRemaining), [1]);
    });
  });

  group('planDeadlineNotifications — project deadlines still work', () {
    test('plans the same reminders it always did', () {
      final occurrences = planDeadlineNotifications(
        preferences: prefs(reminderDays: const [1, 3]),
        now: now,
        projects: [
          TestFactories.makeProject(id: 'p1', deadline: DateTime(2025, 6, 20)),
        ],
      );

      expect(occurrences.length, 3);
      expect(
        occurrences.every(
            (o) => o.kind == DeadlineNotificationKind.projectDeadline),
        isTrue,
      );
      expect(occurrences.first.notificationId, '${'p1'}_1'.hashCode);
    });

    test('a project with both a deadline and dated todos plans both', () {
      final occurrences = planDeadlineNotifications(
        preferences: prefs(reminderDays: const []),
        now: now,
        projects: [
          TestFactories.makeProject(
            deadline: DateTime(2025, 6, 25),
            todos: [TestFactories.makeTodo(dueAt: DateTime(2025, 6, 20))],
          ),
        ],
      );

      expect(occurrences.length, 2);
      expect(todoOccurrences(occurrences).single.scheduledDate,
          DateTime(2025, 6, 20, 9));
    });
  });

  group('notification text', () {
    DeadlineNotificationOccurrence occurrence({
      required DeadlineNotificationKind kind,
      required int daysRemaining,
    }) =>
        DeadlineNotificationOccurrence(
          ownerId: 'p1',
          ownerName: 'Midnight Drive',
          kind: kind,
          todo: TestFactories.makeTodo(text: 'Record vocals'),
          scheduledDate: DateTime(2025, 6, 20, 9),
          daysRemaining: daysRemaining,
        );

    test('a todo reads as a task, not as the project deadline', () {
      final today =
          occurrence(kind: DeadlineNotificationKind.todoDue, daysRemaining: 0);
      expect(notificationTitleFor(today), 'Task Due Today!');
      expect(notificationBodyFor(today),
          'Due today: "Record vocals" (Midnight Drive)');

      final soon =
          occurrence(kind: DeadlineNotificationKind.todoDue, daysRemaining: 3);
      expect(notificationTitleFor(soon), 'Upcoming Task');
      expect(notificationBodyFor(soon),
          '3 days left for "Record vocals" (Midnight Drive)');
    });

    test('project deadline wording is unchanged', () {
      final today = occurrence(
          kind: DeadlineNotificationKind.projectDeadline, daysRemaining: 0);
      expect(notificationTitleFor(today), 'Deadline Today!');
      expect(notificationBodyFor(today),
          'Today is the deadline for "Midnight Drive"');

      final tomorrow = occurrence(
          kind: DeadlineNotificationKind.projectDeadline, daysRemaining: 1);
      expect(notificationTitleFor(tomorrow), 'Deadline Tomorrow!');
      expect(notificationBodyFor(tomorrow), '1 day left for "Midnight Drive"');
    });
  });
}
