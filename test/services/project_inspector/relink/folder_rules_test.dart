import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/project_inspector/relink/folder_rules.dart';

void main() {
  group('FolderRule.apply', () {
    const rule = FolderRule(r'H:\STUDIO', '/Volumes/Archive/STUDIO');

    test('moves a path under from to the same place under to', () {
      expect(rule.apply(r'H:\STUDIO\Song\Audio\kick.wav'),
          '/Volumes/Archive/STUDIO/Song/Audio/kick.wav');
    });

    test('ignores case and either separator', () {
      expect(rule.apply('h:/studio/kick.wav'),
          '/Volumes/Archive/STUDIO/kick.wav');
    });

    test('only whole folders match: STUDIO2 is not inside STUDIO', () {
      expect(rule.apply(r'H:\STUDIO2\kick.wav'), isNull);
      expect(rule.apply(r'H:\STUDIO'), isNull, reason: 'the folder itself');
    });

    test('takes the separators of where the files are now', () {
      expect(const FolderRule('/Users/me/Samples', r'E:\Samples\')
              .apply('/Users/me/Samples/Kicks/k.wav'),
          r'E:\Samples\Kicks\k.wav');
    });

    test('a drive for a drive', () {
      expect(const FolderRule(r'D:\', r'E:\').apply(r'D:\Music\k.wav'),
          r'E:\Music\k.wav');
    });

    test('into the root of a disk', () {
      expect(const FolderRule(r'D:\Old', '/').apply(r'D:\Old\k.wav'), '/k.wav');
    });
  });

  test('applyFolderRules: the deepest rule containing the path wins', () {
    const rules = [
      FolderRule(r'D:\Music', r'E:\Music'),
      FolderRule(r'D:\Music\Samples', r'F:\Samples'),
    ];
    expect(applyFolderRules(r'D:\Music\Samples\k.wav', rules),
        r'F:\Samples\k.wav');
    expect(applyFolderRules(r'D:\Music\Song\a.wav', rules), r'E:\Music\Song\a.wav');
    expect(applyFolderRules(r'C:\a.wav', rules), isNull);
  });

  group('suggestFolderRule', () {
    test('the folders the two paths do not share, from the end', () {
      expect(
        suggestFolderRule(r'D:\Old\Song\Audio\kick.wav',
            r'E:\Backup\Song\Audio\kick.wav'),
        const FolderRule(r'D:\Old', r'E:\Backup'),
      );
    });

    test('a drive letter that changed', () {
      expect(
        suggestFolderRule(r'D:\Music\kick.wav', r'H:\Music\kick.wav'),
        const FolderRule(r'D:\', r'H:\'),
      );
    });

    test('from Windows to a Mac', () {
      expect(
        suggestFolderRule(
            r'D:\Projects\Song\Audio\a.wav', '/Volumes/Ext/Song/Audio/a.wav'),
        const FolderRule(r'D:\Projects', '/Volumes/Ext'),
      );
    });

    test('nothing to suggest for the same path or only a shared name', () {
      expect(suggestFolderRule(r'D:\a\k.wav', r'd:\A\K.wav'), isNull);
      expect(suggestFolderRule(r'D:\a\k.wav', r'E:\b\k.wav'), isNull);
    });

    test('the suggestion fixes the file it came from', () {
      const stored = r'D:\Old\Song\Audio\kick.wav';
      const found = r'E:\Backup\Song\Audio\kick.wav';
      expect(suggestFolderRule(stored, found)!.apply(stored), found);
    });
  });

  test('isWindowsStylePath', () {
    expect(isWindowsStylePath(r'D:\a'), isTrue);
    expect(isWindowsStylePath(r'\\nas\share\a'), isTrue);
    expect(isWindowsStylePath('/Volumes/a'), isFalse);
  });
}
