import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/utils/playback_todo_utils.dart';

void main() {
  group('formatPlaybackTimestamp', () {
    test('formats zero duration as 00:00', () {
      expect(formatPlaybackTimestamp(Duration.zero), '00:00');
    });

    test('formats sub-minute duration', () {
      expect(formatPlaybackTimestamp(const Duration(seconds: 7)), '00:07');
    });

    test('formats minutes and seconds without hours', () {
      expect(formatPlaybackTimestamp(const Duration(minutes: 1, seconds: 23)), '01:23');
    });

    test('omits hour component under one hour', () {
      expect(formatPlaybackTimestamp(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('includes hour component once duration reaches an hour', () {
      expect(
        formatPlaybackTimestamp(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });

    test('withHours shows hours under an hour too', () {
      expect(
        formatPlaybackTimestamp(const Duration(minutes: 12), withHours: true),
        '00:12:00',
      );
    });
  });

  group('formatPlaybackProgress', () {
    test('under an hour is mm:ss on both sides', () {
      expect(
        formatPlaybackProgress(
            const Duration(minutes: 1, seconds: 5), const Duration(minutes: 4)),
        '01:05 / 04:00',
      );
    });

    // Regression: players formatting with minutes and seconds only showed
    // 1:12:00 of a 90-minute file as "12:00 / 30:00".
    test('past an hour keeps the hours', () {
      expect(
        formatPlaybackProgress(const Duration(hours: 1, minutes: 12),
            const Duration(hours: 1, minutes: 30)),
        '01:12:00 / 01:30:00',
      );
    });

    test('an hour-long file shows hours from the start, so its width holds',
        () {
      final early = formatPlaybackProgress(
          const Duration(minutes: 12), const Duration(hours: 1, minutes: 30));
      final late = formatPlaybackProgress(const Duration(hours: 1, minutes: 12),
          const Duration(hours: 1, minutes: 30));
      expect(early, '00:12:00 / 01:30:00');
      expect(early.length, late.length);
    });
  });

  group('buildTimestampedTodoText', () {
    test('prefixes note with formatted timestamp', () {
      expect(
        buildTimestampedTodoText(const Duration(minutes: 1, seconds: 23), 'Fix the kick drum'),
        '[01:23] Fix the kick drum',
      );
    });

    test('trims surrounding whitespace from the note', () {
      expect(
        buildTimestampedTodoText(Duration.zero, '  needs reverb  '),
        '[00:00] needs reverb',
      );
    });

    test('handles timestamps past one hour', () {
      expect(
        buildTimestampedTodoText(const Duration(hours: 1, minutes: 5), 'long jam section'),
        '[01:05:00] long jam section',
      );
    });
  });

  group('buildTaskTextForProject', () {
    test('stamps a timestamp when the project is currently playing', () {
      expect(
        buildTaskTextForProject(
          isCurrentlyPlaying: true,
          position: const Duration(minutes: 1, seconds: 23),
          text: 'fix vocal reverb',
        ),
        '[01:23] fix vocal reverb',
      );
    });

    test('leaves plain text untouched when the project is not playing', () {
      expect(
        buildTaskTextForProject(
          isCurrentlyPlaying: false,
          position: const Duration(minutes: 1, seconds: 23),
          text: 'fix vocal reverb',
        ),
        'fix vocal reverb',
      );
    });

    test('trims whitespace whether or not it stamps a timestamp', () {
      expect(
        buildTaskTextForProject(
          isCurrentlyPlaying: false,
          position: Duration.zero,
          text: '  needs reverb  ',
        ),
        'needs reverb',
      );
      expect(
        buildTaskTextForProject(
          isCurrentlyPlaying: true,
          position: Duration.zero,
          text: '  needs reverb  ',
        ),
        '[00:00] needs reverb',
      );
    });
  });
}
