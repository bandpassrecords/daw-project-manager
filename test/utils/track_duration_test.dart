import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/utils/track_duration.dart';

import '../helpers/test_factories.dart';

void main() {
  MusicProject project({int? manual, int? auto}) =>
      TestFactories.makeProject(durationMs: manual, autoDurationMs: auto);

  group('effectiveTrackDuration', () {
    test('uses the measured length when nothing was typed', () {
      expect(
        effectiveTrackDuration(project(auto: 225000)),
        const Duration(minutes: 3, seconds: 45),
      );
    });

    test('a typed length wins over a measured one', () {
      // Correcting a length has to stick even while the preview song keeps
      // reporting its own.
      expect(
        effectiveTrackDuration(project(manual: 200000, auto: 225000)),
        const Duration(milliseconds: 200000),
      );
    });

    test('is null when neither exists', () {
      expect(effectiveTrackDuration(project()), isNull);
    });

    test('treats a zero or negative stored value as absent', () {
      expect(effectiveTrackDuration(project(auto: 0)), isNull);
      expect(effectiveTrackDuration(project(manual: -5)), isNull);
    });

    test('falls back to the measured length when the typed one is cleared', () {
      // copyWith(clearDurationMs:) is what the detail page calls when the
      // field is emptied — the measured value must survive it.
      final typed = project(manual: 200000, auto: 225000);
      final cleared = typed.copyWith(clearDurationMs: true);
      expect(
        effectiveTrackDuration(cleared),
        const Duration(milliseconds: 225000),
      );
    });
  });

  group('hasManualTrackDuration', () {
    test('is true only for a real typed value', () {
      expect(hasManualTrackDuration(project(manual: 1000)), isTrue);
      expect(hasManualTrackDuration(project(auto: 1000)), isFalse);
      expect(hasManualTrackDuration(project(manual: 0)), isFalse);
      expect(hasManualTrackDuration(project()), isFalse);
    });
  });

  group('formatTrackDuration', () {
    test('writes minutes unpadded and seconds padded', () {
      expect(
        formatTrackDuration(const Duration(minutes: 3, seconds: 7)),
        '3:07',
      );
    });

    test('shows hours only once one is reached', () {
      expect(
        formatTrackDuration(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
      expect(
        formatTrackDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });

    test('handles zero', () {
      expect(formatTrackDuration(Duration.zero), '0:00');
    });

    test('truncates sub-second remainders rather than rounding up', () {
      expect(formatTrackDuration(const Duration(milliseconds: 3999)), '0:03');
    });
  });

  group('parseTrackDuration', () {
    test('reads m:ss', () {
      expect(
        parseTrackDuration('3:45'),
        const Duration(minutes: 3, seconds: 45),
      );
    });

    test('reads h:mm:ss', () {
      expect(
        parseTrackDuration('1:02:03'),
        const Duration(hours: 1, minutes: 2, seconds: 3),
      );
    });

    test('reads a bare number as seconds', () {
      expect(parseTrackDuration('225'), const Duration(seconds: 225));
    });

    test('tolerates surrounding and internal whitespace', () {
      expect(
        parseTrackDuration('  3 : 45 '),
        const Duration(minutes: 3, seconds: 45),
      );
    });

    test('refuses out-of-range seconds rather than silently carrying', () {
      // Reading 3:75 as 4:15 would hide a typo instead of showing it.
      expect(parseTrackDuration('3:75'), isNull);
      expect(parseTrackDuration('1:75:00'), isNull);
    });

    test('refuses non-numeric and malformed input', () {
      expect(parseTrackDuration('abc'), isNull);
      expect(parseTrackDuration('3:xx'), isNull);
      expect(parseTrackDuration('1:2:3:4'), isNull);
      expect(parseTrackDuration('-30'), isNull);
    });

    test('refuses an empty or blank string', () {
      expect(parseTrackDuration(''), isNull);
      expect(parseTrackDuration('   '), isNull);
    });

    test('round-trips through formatTrackDuration', () {
      for (final d in [
        const Duration(seconds: 9),
        const Duration(minutes: 3, seconds: 45),
        const Duration(hours: 1, minutes: 2, seconds: 3),
      ]) {
        expect(parseTrackDuration(formatTrackDuration(d)), d);
      }
    });
  });

  group('shouldUpdateAutoDuration', () {
    test('stores the first real measurement', () {
      expect(
        shouldUpdateAutoDuration(
          storedMs: null,
          measured: const Duration(minutes: 3),
        ),
        isTrue,
      );
    });

    test('never stores a zero reading', () {
      // A player that has not resolved the file yet reports Duration.zero.
      expect(
        shouldUpdateAutoDuration(storedMs: null, measured: Duration.zero),
        isFalse,
      );
      expect(
        shouldUpdateAutoDuration(
          storedMs: 225000,
          measured: Duration.zero,
        ),
        isFalse,
      );
    });

    test('ignores a difference inside the tolerance', () {
      expect(
        shouldUpdateAutoDuration(
          storedMs: 225000,
          measured: const Duration(milliseconds: 225003),
        ),
        isFalse,
      );
    });

    test('accepts a difference at or beyond the tolerance', () {
      expect(
        shouldUpdateAutoDuration(
          storedMs: 225000,
          measured: const Duration(milliseconds: 226000),
        ),
        isTrue,
      );
    });

    test('replaces a zero or negative stored value', () {
      expect(
        shouldUpdateAutoDuration(
          storedMs: 0,
          measured: const Duration(minutes: 3),
        ),
        isTrue,
      );
    });
  });

  group('recordMeasuredDuration', () {
    test('saves the measured length and reports the updated project', () async {
      MusicProject? saved;
      final result = await recordMeasuredDuration(
        project(),
        const Duration(minutes: 3, seconds: 45),
        (p) async => saved = p,
      );

      expect(result, isNotNull);
      expect(saved?.autoDurationMs, 225000);
    });

    test('does not save when nothing changed', () async {
      var saves = 0;
      final result = await recordMeasuredDuration(
        project(auto: 225000),
        const Duration(minutes: 3, seconds: 45),
        (_) async => saves++,
      );

      expect(result, isNull);
      expect(saves, 0);
    });

    test('leaves a typed length alone while updating the measured one',
        () async {
      MusicProject? saved;
      await recordMeasuredDuration(
        project(manual: 200000, auto: 100000),
        const Duration(minutes: 3, seconds: 45),
        (p) async => saved = p,
      );

      expect(saved?.autoDurationMs, 225000);
      expect(saved?.durationMs, 200000, reason: 'typed length must survive');
      expect(
        effectiveTrackDuration(saved!),
        const Duration(milliseconds: 200000),
      );
    });
  });

  group('releaseTotalDuration', () {
    test('sums every track that has a length', () {
      final total = releaseTotalDuration([
        project(auto: 180000),
        project(manual: 240000),
      ]);
      expect(total, const Duration(seconds: 420));
    });

    test('skips untimed tracks rather than refusing to total', () {
      final total = releaseTotalDuration([
        project(auto: 180000),
        project(),
      ]);
      expect(total, const Duration(seconds: 180));
    });

    test('is zero for an empty release', () {
      expect(releaseTotalDuration(const []), Duration.zero);
    });

    test('is zero when no track has been timed', () {
      expect(releaseTotalDuration([project(), project()]), Duration.zero);
    });

    test('crosses the hour mark correctly', () {
      final total = releaseTotalDuration(
        List.generate(20, (_) => project(auto: 225000)),
      );
      expect(formatTrackDuration(total), '1:15:00');
    });
  });

  group('tracksMissingDuration', () {
    test('counts only the tracks with no length at all', () {
      expect(
        tracksMissingDuration([
          project(auto: 1000),
          project(manual: 1000),
          project(),
          project(auto: 0),
        ]),
        2,
      );
    });

    test('is zero for an empty release', () {
      expect(tracksMissingDuration(const []), 0);
    });
  });

  group('songLengthSourceMessage', () {
    String pick({required bool manual, required bool measured}) =>
        songLengthSourceMessage(
          manual: manual,
          measured: measured,
          typedByHand: 'typed',
          fromPreview: 'measured',
          howItWorks: 'how',
        );

    test('a typed length says so, even when a measured one exists', () {
      // The typed value is what the field shows, so that is what to explain.
      expect(pick(manual: true, measured: true), 'typed');
      expect(pick(manual: true, measured: false), 'typed');
    });

    test('a measured length says where it came from', () {
      expect(pick(manual: false, measured: true), 'measured');
    });

    test('an empty field explains how a length arrives', () {
      expect(pick(manual: false, measured: false), 'how');
    });
  });
}
