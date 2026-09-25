import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:daw_project_manager/services/dev_library_service.dart';
import 'package:daw_project_manager/utils/app_paths.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.supportPath);
  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dev_library_test_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Directory makeLibrary(String name, {Map<String, int> boxes = const {}}) {
    final dir = Directory(p.join(root.path, name))..createSync(recursive: true);
    boxes.forEach((fileName, size) {
      File(p.join(dir.path, fileName)).writeAsBytesSync(List.filled(size, 0));
    });
    return dir;
  }

  group('discover', () {
    test('always offers the release and dev libraries, release first', () {
      final found = DevLibraryService.discover(root);

      expect(found.map((l) => l.dirName).take(2),
          [defaultAppDataDirName, '${defaultAppDataDirName}_dev']);
      expect(found.first.isRelease, isTrue);
    });

    test('marks libraries that do not exist yet', () {
      final found = DevLibraryService.discover(root);

      expect(found.every((l) => !l.exists), isTrue);
    });

    test('picks up per-pull-request directories left by tester builds', () {
      makeLibrary('${defaultAppDataDirName}_pr90');
      makeLibrary('${defaultAppDataDirName}_pr123');

      final names = DevLibraryService.discover(root).map((l) => l.dirName);

      expect(names, contains('${defaultAppDataDirName}_pr90'));
      expect(names, contains('${defaultAppDataDirName}_pr123'));
    });

    test('ignores unrelated directories', () {
      makeLibrary('some_other_app');
      makeLibrary('daw_project_managerX'); // no underscore separator

      final names = DevLibraryService.discover(root).map((l) => l.dirName);

      expect(names, isNot(contains('some_other_app')));
      expect(names, isNot(contains('daw_project_managerX')));
    });

    test('counts project boxes and total size', () {
      makeLibrary(defaultAppDataDirName, boxes: {
        'profile-a_projects.hive': 100,
        'profile-b_projects.hive': 200,
        'profile-a_releases.hive': 50,
        'settings.hive': 25,
      });

      final release = DevLibraryService.discover(root)
          .firstWhere((l) => l.dirName == defaultAppDataDirName);

      expect(release.exists, isTrue);
      expect(release.projectBoxCount, 2,
          reason: 'only *_projects boxes count towards the project box count');
      expect(release.totalBytes, 375);
      expect(release.lastModified, isNotNull);
    });

    test('detects the release library when its boxes sit directly in root', () {
      // Regression: on macOS/Linux the release build keeps its Hive boxes in
      // the app-support directory itself (= the picker root), not in a
      // daw_project_manager/ subdirectory, so discover never listed it and it
      // always showed "Does not exist yet — will be created empty".
      File(p.join(root.path, 'profile-a_projects.hive'))
          .writeAsBytesSync(List.filled(120, 0));
      File(p.join(root.path, 'settings.hive')).writeAsBytesSync(List.filled(30, 0));

      final release =
          DevLibraryService.discover(root).firstWhere((l) => l.isRelease);

      expect(release.exists, isTrue);
      expect(release.projectBoxCount, 1);
      expect(release.totalBytes, 150);
    }, testOn: '!windows');

    test('release library still reads as absent when root holds no boxes', () {
      // root exists (it is the OS app-support dir) but nothing has written a
      // library into it yet — keep the "will be created empty" affordance.
      final release =
          DevLibraryService.discover(root).firstWhere((l) => l.isRelease);

      expect(release.exists, isFalse);
    }, testOn: '!windows');

    test('a library with no boxes reports zero rather than failing', () {
      makeLibrary('${defaultAppDataDirName}_dev');

      final dev = DevLibraryService.discover(root)
          .firstWhere((l) => l.dirName == '${defaultAppDataDirName}_dev');

      expect(dev.exists, isTrue);
      expect(dev.projectBoxCount, 0);
      expect(dev.totalBytes, 0);
    });

    test('an empty or missing root still yields the two defaults', () {
      final missing = Directory(p.join(root.path, 'nope'));

      expect(DevLibraryService.discover(missing).length, 2);
    });
  });

  group('selection file', () {
    test('returns null when nothing has been remembered', () {
      expect(DevLibraryService.readSelection(root), isNull);
    });

    test('round-trips a remembered choice', () {
      DevLibraryService.writeSelection(root, '${defaultAppDataDirName}_dev');

      expect(DevLibraryService.readSelection(root),
          '${defaultAppDataDirName}_dev');
    });

    test('is stored beside the libraries, not inside one', () {
      // Which library is in play is exactly what this records, so it cannot
      // live inside a library directory.
      DevLibraryService.writeSelection(root, defaultAppDataDirName);

      expect(
        File(p.join(root.path, DevLibraryService.selectionFileName)).existsSync(),
        isTrue,
      );
    });

    test('writing null clears the choice so the picker asks again', () {
      DevLibraryService.writeSelection(root, defaultAppDataDirName);
      DevLibraryService.writeSelection(root, null);

      expect(DevLibraryService.readSelection(root), isNull);
    });

    test('an empty file reads as no choice', () {
      File(p.join(root.path, DevLibraryService.selectionFileName))
          .writeAsStringSync('   ');

      expect(DevLibraryService.readSelection(root), isNull);
    });

    test('clearing a choice that was never made is harmless', () {
      expect(() => DevLibraryService.writeSelection(root, null), returnsNormally);
    });
  });

  group('resolveRoot', () {
    // Regression: the picker resolves the root *before* a library is chosen
    // and writes the remembered choice there; the settings card resolves it
    // again *after* the choice and reads it back. resolveRoot used to derive
    // the root from getLocalAppDataPath(), which points inside the selected
    // library — so once a non-isolated (release) library was picked it
    // resolved one directory higher, the card never saw the file, and
    // "Ask again next launch" stayed permanently disabled.
    late Directory support;

    setUp(() {
      support = Directory(p.join(root.path, 'appsupport'))..createSync();
      PathProviderPlatform.instance = _FakePathProvider(support.path);
      // Windows resolves the app-support root from %LOCALAPPDATA%, which a
      // swapped PathProviderPlatform never reaches — without this the two
      // tests below compared against the developer's real AppData and failed
      // on Windows while passing everywhere else. Ignored off Windows, so it
      // is set unconditionally.
      debugLocalAppDataOverride = support.path;
      resetSelectedAppDataDir();
    });
    tearDown(() {
      debugLocalAppDataOverride = null;
      resetSelectedAppDataDir();
    });

    test('is the app-support dir and does not move when a library is selected',
        () async {
      final beforeChoice = await DevLibraryService.resolveRoot();

      // The user picks the release library and it gets remembered.
      selectAppDataDir(defaultAppDataDirName);
      final afterChoice = await DevLibraryService.resolveRoot();

      expect(p.equals(beforeChoice.path, support.path), isTrue);
      expect(p.equals(afterChoice.path, beforeChoice.path), isTrue);
    });

    test('a choice written before selection is readable after it', () async {
      final writeRoot = await DevLibraryService.resolveRoot();
      DevLibraryService.writeSelection(writeRoot, defaultAppDataDirName);

      selectAppDataDir(defaultAppDataDirName);
      final readRoot = await DevLibraryService.resolveRoot();

      expect(DevLibraryService.readSelection(readRoot), defaultAppDataDirName);
    });
  });

  group('formatBytes', () {
    test('scales through B, KB and MB', () {
      expect(DevLibraryService.formatBytes(512), '512 B');
      expect(DevLibraryService.formatBytes(2048), '2 KB');
      expect(DevLibraryService.formatBytes(5 * 1024 * 1024), '5.0 MB');
    });
  });
}
