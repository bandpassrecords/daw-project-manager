import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/utils/app_paths.dart';

/// Regression coverage for a real incident during this project's own test
/// suite: ensureHiveInitialized() only tracked its own private
/// `_hiveInitialized` flag, not Hive's actual state. The first call to it
/// anywhere in a `flutter test` process — reached via many providers'
/// fire-and-forget _load() methods — would silently call
/// `Hive.init(realAppDataPath)`, overwriting the developer's actual
/// settings.hive, even when an earlier test file in the same process had
/// already called `Hive.init(tempDir)` itself. It must never fall back to
/// the real app-data directory while running under `flutter test`.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_paths_test_');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('runs under FLUTTER_TEST=true (precondition for the next test)', () {
    expect(Platform.environment['FLUTTER_TEST'], 'true');
  });

  test(
    'never falls back to the real app-data directory while running under '
    'flutter test, even with no prior Hive.init() in this process',
    () async {
      // Deliberately does NOT call Hive.init() first — this is the exact
      // shape of the bug: some provider reaches ensureHiveInitialized() as
      // the very first Hive-related call in the process.
      await ensureHiveInitialized();

      // If it had fallen back to the real path, this would silently create
      // a box file under the developer's actual LOCALAPPDATA directory.
      // Instead, Hive still has no initialized directory, so opening a box
      // must fail loudly rather than writing anywhere real.
      await expectLater(
        () => Hive.openBox<String>('regression_probe'),
        throwsA(anything),
      );
    },
  );

  // A build that writes a Hive type the installed release does not know about
  // leaves that release unable to read its own boxes ("Cannot read, unknown
  // typeId"). Pull-request builds are shipped to testers as real installers,
  // so build mode alone cannot keep them off the stable app's library — CI
  // passes an explicit directory name instead.
  group('resolveAppDataDirName', () {
    test('a release build with no override uses the real library', () {
      expect(
        resolveAppDataDirName(override: '', isRelease: true),
        defaultAppDataDirName,
      );
    });

    test('a non-release build with no override is isolated', () {
      expect(
        resolveAppDataDirName(override: '', isRelease: false),
        '${defaultAppDataDirName}_dev',
      );
    });

    test('an override wins even in a release build', () {
      // This is the pull-request case: --release, but must not touch the
      // tester's real library.
      expect(
        resolveAppDataDirName(
          override: 'daw_project_manager_pr123',
          isRelease: true,
        ),
        'daw_project_manager_pr123',
      );
    });

    test('a blank or whitespace override falls through to build mode', () {
      expect(resolveAppDataDirName(override: '   ', isRelease: true),
          defaultAppDataDirName);
      expect(resolveAppDataDirName(override: '', isRelease: false),
          '${defaultAppDataDirName}_dev');
    });

    test('path separators and traversal are stripped out', () {
      // The value becomes a path segment under the app-data root, so it must
      // not be able to escape it.
      expect(
        resolveAppDataDirName(override: '../../Windows', isRelease: true),
        'Windows',
      );
      expect(
        resolveAppDataDirName(override: 'a/b\\c', isRelease: true),
        'abc',
      );
    });

    test('an override of only separators falls back rather than resolving to '
        'the app-data root itself', () {
      expect(
        resolveAppDataDirName(override: '../..', isRelease: true),
        defaultAppDataDirName,
      );
      expect(
        resolveAppDataDirName(override: '/', isRelease: true),
        defaultAppDataDirName,
      );
    });
  });

  // Whether a build is *pinned* is what decides if it warns the person
  // running it about the library it opened (see PinnedLibraryWarning): a
  // pinned build sees neither the startup picker nor the Settings dev card,
  // both of which are gated on canPickAppDataDir.
  group('resolveIsAppDataDirPinned', () {
    test('no override means not pinned', () {
      expect(resolveIsAppDataDirPinned(''), isFalse);
    });

    test('a real override pins the build', () {
      expect(resolveIsAppDataDirPinned('daw_project_manager_pr141'), isTrue);
    });

    test('a whitespace-only override does not pin', () {
      expect(resolveIsAppDataDirPinned('   '), isFalse);
    });

    test('an override that sanitizes away does not pin', () {
      // Non-empty, but nothing survives sanitizing — appDataDirName falls
      // back to build mode, so claiming the build is pinned would name a
      // directory it is not actually using.
      expect(resolveIsAppDataDirPinned('../..'), isFalse);
      expect(resolveIsAppDataDirPinned('/'), isFalse);
    });

    test('agrees with resolveAppDataDirName on whether the override won', () {
      for (final override in [
        '',
        '   ',
        '../..',
        '/',
        'daw_project_manager_pr141',
        '../../Windows',
      ]) {
        final resolved =
            resolveAppDataDirName(override: override, isRelease: true);
        expect(
          resolveIsAppDataDirPinned(override),
          resolved != defaultAppDataDirName,
          reason: 'override "$override" resolved to $resolved',
        );
      }
    });
  });

  // A PR build handed to a tester is pinned to its own app-data directory,
  // but the single-instance guard used to bind one fixed port regardless.
  // Starting such a build while the installed app was open therefore just
  // forwarded to the installed app and exited — the tester never saw the
  // build at all, which is the opposite of being able to run it alongside.
  group('resolveSingleInstancePort', () {
    test('a non-isolated build keeps the fixed release port', () {
      expect(
        resolveSingleInstancePort(defaultAppDataDirName, isolated: false),
        defaultSingleInstancePort,
      );
    });

    test('the directory name is ignored when not isolated', () {
      expect(
        resolveSingleInstancePort('anything_at_all', isolated: false),
        defaultSingleInstancePort,
      );
    });

    test('an isolated build gets a port of its own', () {
      final port = resolveSingleInstancePort(
        'daw_project_manager_pr141',
        isolated: true,
      );
      expect(port, isNot(defaultSingleInstancePort));
    });

    test('the same directory always resolves to the same port', () {
      // A port that moved between launches would make every launch look like
      // a first one, defeating the guard for that build entirely.
      expect(
        resolveSingleInstancePort('daw_project_manager_pr141', isolated: true),
        resolveSingleInstancePort('daw_project_manager_pr141', isolated: true),
      );
    });

    test('different PR builds do not share a port', () {
      expect(
        resolveSingleInstancePort('daw_project_manager_pr141', isolated: true),
        isNot(resolveSingleInstancePort('daw_project_manager_pr142',
            isolated: true)),
      );
    });

    test('every derived port sits in the dynamic range, below the release one',
        () {
      // Staying under defaultSingleInstancePort is what guarantees a derived
      // port can never collide with the real library's.
      for (var i = 0; i < 500; i++) {
        final port = resolveSingleInstancePort(
          'daw_project_manager_pr$i',
          isolated: true,
        );
        expect(port, greaterThanOrEqualTo(49152));
        expect(port, lessThan(defaultSingleInstancePort));
      }
    });

    test('an empty directory name still resolves to a usable port', () {
      final port = resolveSingleInstancePort('', isolated: true);
      expect(port, greaterThanOrEqualTo(49152));
      expect(port, lessThan(defaultSingleInstancePort));
    });
  });
}
