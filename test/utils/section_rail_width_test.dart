import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/section_rail_width.dart';

void main() {
  group('clampSectionRailWidth', () {
    test('keeps a width inside the range as it is', () {
      expect(clampSectionRailWidth(260, available: 1600), 260);
    });

    test('never goes below the minimum', () {
      expect(clampSectionRailWidth(40, available: 1600), kSectionRailMinWidth);
    });

    test('never goes above the maximum on a wide window', () {
      expect(clampSectionRailWidth(900, available: 3000), kSectionRailMaxWidth);
    });

    test('never takes more than half of a smaller window', () {
      // A width saved on a big monitor must still leave room for content.
      expect(clampSectionRailWidth(400, available: 600), 300);
    });

    test('on a very narrow window the minimum still wins', () {
      expect(clampSectionRailWidth(300, available: 200), kSectionRailMinWidth);
    });

    test('an unbounded width is limited by the maximum alone', () {
      expect(clampSectionRailWidth(500, available: double.infinity),
          kSectionRailMaxWidth);
    });

    test('NaN falls back to the minimum instead of breaking layout', () {
      expect(clampSectionRailWidth(double.nan, available: 1600),
          kSectionRailMinWidth);
    });
  });

  group('parseStoredSectionRailWidth', () {
    test('reads a saved width', () {
      expect(parseStoredSectionRailWidth('275.5'), 275.5);
    });

    test('nothing saved means never resized', () {
      expect(parseStoredSectionRailWidth(null), isNull);
      expect(parseStoredSectionRailWidth(''), isNull);
    });

    test('garbage, zero and infinity count as never resized', () {
      expect(parseStoredSectionRailWidth('wide'), isNull);
      expect(parseStoredSectionRailWidth('0'), isNull);
      expect(parseStoredSectionRailWidth('-20'), isNull);
      expect(parseStoredSectionRailWidth('Infinity'), isNull);
    });
  });
}
