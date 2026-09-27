import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/scan_root.dart';
import 'package:daw_project_manager/utils/scan_root_filters.dart';

void main() {
  ScanRoot root(String path, {bool enabled = true, String id = 'r'}) => ScanRoot(
    id: id,
    path: path,
    addedAt: DateTime(2025, 1, 1),
    enabled: enabled,
  );

  /// Built with the host's separator so these assertions mean the same thing
  /// on Windows (where `p.separator` is `\`) as on macOS and Linux.
  String path(List<String> parts) => p.joinAll(parts);

  group('normalizedRootPrefix', () {
    test('appends a trailing separator', () {
      expect(
        normalizedRootPrefix(path(['music', 'albums'])),
        endsWith(p.separator),
      );
    });

    test('does not double up an existing trailing separator', () {
      final withSep = path(['music', 'albums']) + p.separator;
      expect(
        normalizedRootPrefix(withSep),
        normalizedRootPrefix(path(['music', 'albums'])),
      );
    });
  });

  group('isUnderRootPath', () {
    test('matches a file inside the folder', () {
      expect(
        isUnderRootPath(
          path(['music', 'albums', 'song.als']),
          path(['music', 'albums']),
        ),
        isTrue,
      );
    });

    test('matches a file nested several levels down', () {
      expect(
        isUnderRootPath(
          path(['music', 'albums', '2025', 'ep', 'song.als']),
          path(['music', 'albums']),
        ),
        isTrue,
      );
    });

    test('matches the root folder itself (a version stack\'s own path)', () {
      // A stack's filePath is the folder its versions live in, which can be
      // the scan root — it must not be treated as outside its own root.
      expect(
        isUnderRootPath(path(['music', 'albums']), path(['music', 'albums'])),
        isTrue,
      );
    });

    test('does not match a sibling folder sharing a name prefix', () {
      expect(
        isUnderRootPath(
          path(['music', 'albums-old', 'song.als']),
          path(['music', 'albums']),
        ),
        isFalse,
      );
    });

    test('does not match an unrelated folder', () {
      expect(
        isUnderRootPath(
          path(['other', 'song.als']),
          path(['music', 'albums']),
        ),
        isFalse,
      );
    });
  });

  group('isHiddenByDisabledRoot', () {
    test('hides a project under a disabled root', () {
      expect(
        isHiddenByDisabledRoot(
          path(['music', 'albums', 'song.als']),
          [root(path(['music', 'albums']), enabled: false)],
        ),
        isTrue,
      );
    });

    test('keeps a project under an enabled root', () {
      expect(
        isHiddenByDisabledRoot(
          path(['music', 'albums', 'song.als']),
          [root(path(['music', 'albums']))],
        ),
        isFalse,
      );
    });

    test('keeps a project that belongs to no root at all', () {
      // Metadata-only entries restored from a backup or another machine have
      // no folder to be silenced by, so a disabled root elsewhere must not
      // take them down with it.
      expect(
        isHiddenByDisabledRoot(
          path(['elsewhere', 'song.als']),
          [root(path(['music', 'albums']), enabled: false)],
        ),
        isFalse,
      );
    });

    test('an enabled nested root wins over a disabled ancestor', () {
      expect(
        isHiddenByDisabledRoot(
          path(['music', 'albums', 'keep', 'song.als']),
          [
            root(path(['music', 'albums']), enabled: false, id: 'outer'),
            root(path(['music', 'albums', 'keep']), id: 'inner'),
          ],
        ),
        isFalse,
      );
    });

    test('a disabled nested root does not hide its enabled ancestor\'s files',
        () {
      expect(
        isHiddenByDisabledRoot(
          path(['music', 'albums', 'song.als']),
          [
            root(path(['music', 'albums']), id: 'outer'),
            root(path(['music', 'albums', 'archive']),
                enabled: false, id: 'inner'),
          ],
        ),
        isFalse,
      );
    });

    test('hides nothing when every root is enabled', () {
      expect(
        isHiddenByDisabledRoot(
          path(['music', 'albums', 'song.als']),
          [root(path(['music', 'albums'])), root(path(['music', 'demos']))],
        ),
        isFalse,
      );
    });

    test('hides nothing when there are no roots', () {
      expect(
        isHiddenByDisabledRoot(path(['music', 'song.als']), const []),
        isFalse,
      );
    });
  });
}
