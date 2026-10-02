import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:daw_project_manager/ui/midi_clip_share.dart';

void main() {
  test('the share sheet is tried everywhere but Linux', () {
    // Mobile, macOS and MSIX-packaged Windows have a file share sheet;
    // share_plus on Linux can only send text.
    expect(shareSheetWorthTrying(isLinux: false), isTrue);
    expect(shareSheetWorthTrying(isLinux: true), isFalse);
  });

  test('falls back to the folder when there was no share sheet', () {
    expect(shareFellThrough(null), isTrue);
    expect(shareFellThrough(ShareResultStatus.unavailable), isTrue);
    expect(shareFellThrough(ShareResultStatus.success), isFalse);
    expect(shareFellThrough(ShareResultStatus.dismissed), isFalse,
        reason: 'the user closed the sheet; nothing to fall back to');
  });
}
