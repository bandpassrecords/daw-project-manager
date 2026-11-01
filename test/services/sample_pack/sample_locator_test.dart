import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/sample_reference.dart';
import 'package:daw_project_manager/services/sample_pack/sample_locator.dart';

void main() {
  late Directory root;
  late String project;
  late String library;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('locator_');
    project = p.join(root.path, 'Song Project');
    library = p.join(root.path, 'Library');
    await Directory(project).create();
    await Directory(library).create();
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<String> file(List<String> parts, {int size = 4}) async {
    final path = p.joinAll([root.path, ...parts]);
    await Directory(p.dirname(path)).create(recursive: true);
    await File(path).writeAsBytes(List.filled(size, 1));
    return path;
  }

  SampleReference ref(String name, List<String> candidates, {int? size}) =>
      SampleReference(fileName: name, candidates: candidates, sizeBytes: size);

  test('a stored path that exists is used as is', () async {
    final kick = await file(['Library', 'Kicks', 'kick.wav']);
    final found = await SampleLocator()
        .locate(ref('kick.wav', [kick]), projectDir: project);
    expect(found, p.normalize(kick));
  });

  test('a relative path is taken from the project folder, either separator',
      () async {
    final kick = await file(['Song Project', 'Audio', 'kick.wav']);
    final locator = SampleLocator();
    expect(
      await locator.locate(ref('kick.wav', ['Audio/kick.wav']),
          projectDir: project),
      p.normalize(kick),
    );
    expect(
      await locator.locate(ref('kick.wav', [r'Audio\kick.wav']),
          projectDir: project),
      p.normalize(kick),
    );
  });

  test('a stale path falls back to the project folder tree, by name',
      () async {
    final moved = await file(['Song Project', 'Samples', 'Imported', 'Hat.wav']);
    final found = await SampleLocator().locate(
      ref('Hat.wav', [p.join(root.path, 'Gone', 'Hat.wav')]),
      projectDir: project,
    );
    expect(found, moved);
  });

  test('names match whatever their case', () async {
    final moved = await file(['Song Project', 'Audio', 'CRASH 02.WAV']);
    final found = await SampleLocator().locate(
      ref('Crash 02.wav', ['Crash 02.wav']),
      projectDir: project,
    );
    expect(found, moved);
  });

  group('library folders', () {
    test('a recorded size picks the right one of same-named files', () async {
      await file(['Library', 'A', 'kick 15.wav'], size: 10);
      final right = await file(['Library', 'B', 'kick 15.wav'], size: 20);
      final found = await SampleLocator(libraryFolders: [library]).locate(
        ref('kick 15.wav', [p.join(root.path, 'Gone', 'kick 15.wav')],
            size: 20),
        projectDir: project,
      );
      expect(found, right);
    });

    test('a file of another size is not taken for it', () async {
      await file(['Library', 'A', 'kick 15.wav'], size: 10);
      final found = await SampleLocator(libraryFolders: [library]).locate(
        ref('kick 15.wav', ['kick 15.wav'], size: 99),
        projectDir: project,
      );
      expect(found, isNull);
    });

    test('without a size, the folder it was in has to match', () async {
      final right = await file(['Library', 'Kicks', 'kick 15.wav']);
      await file(['Library', 'Toolkit', 'Other', 'kick 15.wav']);
      final locator = SampleLocator(libraryFolders: [library]);
      // FL Studio 7: relative to an install that is gone.
      expect(
        await locator.locate(
          ref('kick 15.wav', [r'\Patches\Kicks\kick 15.wav']),
          projectDir: project,
        ),
        right,
      );
      expect(
        await locator.locate(
          ref('kick 15.wav', [r'\Patches\Snares\kick 15.wav']),
          projectDir: project,
        ),
        isNull,
        reason: 'any "kick 15.wav" is not this one',
      );
    });

    test('a bare name with nothing else to go by is taken', () async {
      final only = await file(['Library', 'Stabs', 'stab 4.wav']);
      final found = await SampleLocator(libraryFolders: [library]).locate(
        ref('stab 4.wav', ['stab 4.wav']),
        projectDir: project,
      );
      expect(found, only);
    });

    test("the project's own folder wins over a library", () async {
      await file(['Library', 'Kicks', 'kick.wav']);
      final own = await file(['Song Project', 'Audio', 'kick.wav']);
      final found = await SampleLocator(libraryFolders: [library]).locate(
        ref('kick.wav', [r'\Old\Kicks\kick.wav']),
        projectDir: project,
      );
      expect(found, own);
    });
  });

  test('expands %VARIABLES%, and skips a path naming one this machine lacks',
      () async {
    final pad = await file(['Library', 'Pads', 'air.wav']);
    final locator = SampleLocator(environment: {'SAMPLES': library});
    expect(
      await locator.locate(
        ref('air.wav', ['%SAMPLES%${p.separator}Pads${p.separator}air.wav']),
        projectDir: project,
      ),
      p.normalize(pad),
    );
    expect(
      await locator.locate(
        ref('air.wav', [r'%FLStudioFactoryData%\Pads\air.wav']),
        projectDir: project,
      ),
      isNull,
    );
  });

  test("searches only so deep below the project's folder", () async {
    await file(['Song Project', 'a', 'b', 'c', 'deep.wav']);
    final shallow = SampleLocator(projectTreeDepth: 1);
    expect(
      await shallow.locate(ref('deep.wav', ['deep.wav']), projectDir: project),
      isNull,
    );
    final deep = SampleLocator(projectTreeDepth: 3);
    expect(
      await deep.locate(ref('deep.wav', ['deep.wav']), projectDir: project),
      isNotNull,
    );
  });

  test('nothing found is null, not a throw', () async {
    final found = await SampleLocator(
      libraryFolders: [p.join(root.path, 'no such folder')],
    ).locate(ref('x.wav', ['x.wav']), projectDir: project);
    expect(found, isNull);
  });

  group('for a relink', () {
    test('candidatesFor: the project tree, then agreeing library files',
        () async {
      final own = await file(['Song Project', 'Audio', 'kick.wav']);
      final lib = await file(['Library', 'Song', 'kick.wav'], size: 9);
      await file(['Library', 'Elsewhere', 'kick.wav']); // 4 bytes: disagrees
      final hits = await SampleLocator(libraryFolders: [library]).candidatesFor(
        ref('kick.wav', [r'D:\Song\kick.wav'], size: 9),
        projectDir: project,
      );
      expect(hits, [lib, own], reason: 'the recorded size ranks first');
    });

    test('namedIn finds a name at any depth', () async {
      final deep = await file(['Library', 'a', 'b', 'c', 'd', 'e', 'f', 'k.wav']);
      expect(await SampleLocator().namedIn(library, ref('K.WAV', ['K.WAV'])),
          [deep]);
    });

    test('clearBest: one that agrees better, or none on a tie', () async {
      final a = await file(['Library', 'A', 'Comped', 'k.wav']);
      final b = await file(['Library', 'B', 'k.wav']);
      final locator = SampleLocator();
      expect(
          await locator.clearBest([a, b], ref('k.wav', [r'D:\x\Comped\k.wav'])),
          a);
      expect(await locator.clearBest([a, b], ref('k.wav', [r'D:\x\k.wav'])),
          isNull);
      expect(await locator.clearBest([b], ref('k.wav', ['k.wav'])), b);
    });
  });
}
