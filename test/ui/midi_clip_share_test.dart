import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:daw_project_manager/ui/midi_clip_share.dart';

void main() {
  test('the share sheet is tried everywhere but Linux', () {
    // Mobile, macOS and Windows have a file share sheet; share_plus on Linux
    // can only send text.
    expect(shareSheetWorthTrying(isLinux: false), isTrue);
    expect(shareSheetWorthTrying(isLinux: true), isFalse);
  });

  group('shareFollowUp', () {
    test('a share sheet that answered needs nothing more', () {
      expect(shareFollowUp(tried: true, status: ShareResultStatus.success),
          ShareFollowUp.none);
      expect(shareFollowUp(tried: true, status: ShareResultStatus.dismissed),
          ShareFollowUp.none);
    });

    // Regression: Windows reports `unavailable` even when its share window
    // did open, and opening the folder too put two windows up at once.
    test('an unknown outcome only offers the folder', () {
      expect(shareFollowUp(tried: true, status: ShareResultStatus.unavailable),
          ShareFollowUp.offerFolder);
    });

    test('opens the folder when there certainly was no share sheet', () {
      expect(shareFollowUp(tried: false), ShareFollowUp.openFolder,
          reason: 'Linux: never attempted');
      expect(shareFollowUp(tried: true, status: null), ShareFollowUp.openFolder,
          reason: 'the share call threw');
    });
  });
}
