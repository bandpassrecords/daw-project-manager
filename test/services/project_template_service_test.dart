import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/project_template.dart';
import 'package:daw_project_manager/services/project_template_service.dart';

void main() {
  late Directory tempDir;
  late Directory sourceDir;
  late Directory destinationsDir;

  ProjectTemplate makeTemplate({
    String mainFileRelativePath = 'Song Template.als',
  }) {
    return ProjectTemplate(
      id: 'template-1',
      name: 'Song Template',
      sourceFolderPath: sourceDir.path,
      mainFileRelativePath: mainFileRelativePath,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'project_template_service_test_',
    );
    sourceDir = Directory(p.join(tempDir.path, 'source'));
    destinationsDir = Directory(p.join(tempDir.path, 'destinations'));
    await sourceDir.create(recursive: true);
    await destinationsDir.create(recursive: true);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ProjectTemplateService.instantiate', () {
    test(
      'renames the main file to the new project name, preserving its extension',
      () async {
        File(
          p.join(sourceDir.path, 'Song Template.als'),
        ).writeAsStringSync('als data');
        final destination = p.join(destinationsDir.path, 'My New Track');

        final newMainFilePath = await ProjectTemplateService.instantiate(
          template: makeTemplate(),
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
        );

        expect(newMainFilePath, p.join(destination, 'My New Track.als'));
        expect(File(newMainFilePath).existsSync(), isTrue);
        expect(File(newMainFilePath).readAsStringSync(), 'als data');
        expect(
          File(p.join(destination, 'Song Template.als')).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'stamps the new main file with the current time, not the template\'s old mtime',
      () async {
        // Regression: a plain file copy preserves the source's original
        // modified time (at least on Windows), so a project created from a
        // months-old template would otherwise inherit that stale timestamp and
        // sort to the bottom of the dashboard's Last Modified column as if it
        // hadn't been touched since.
        final templateFile = File(p.join(sourceDir.path, 'Song Template.als'))
          ..writeAsStringSync('als data');
        final longAgo = DateTime.now().subtract(const Duration(days: 400));
        await templateFile.setLastModified(longAgo);
        final destination = p.join(destinationsDir.path, 'My New Track');

        final before = DateTime.now();
        final newMainFilePath = await ProjectTemplateService.instantiate(
          template: makeTemplate(),
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
        );
        final after = DateTime.now();

        final newMtime = await File(newMainFilePath).lastModified();
        expect(
          newMtime.isBefore(before.subtract(const Duration(seconds: 2))),
          isFalse,
        );
        expect(
          newMtime.isAfter(after.add(const Duration(seconds: 2))),
          isFalse,
        );
      },
    );

    test('copies sibling files unchanged, without renaming them', () async {
      File(
        p.join(sourceDir.path, 'Song Template.als'),
      ).writeAsStringSync('als data');
      File(
        p.join(sourceDir.path, 'Song Template Kick.wav'),
      ).writeAsStringSync('kick data');
      File(p.join(sourceDir.path, 'readme.txt')).writeAsStringSync('notes');
      final destination = p.join(destinationsDir.path, 'My New Track');

      await ProjectTemplateService.instantiate(
        template: makeTemplate(),
        destinationFolderPath: destination,
        newProjectName: 'My New Track',
      );

      // Sibling files keep their original names verbatim — no token
      // substitution across unrelated files.
      expect(
        File(p.join(destination, 'Song Template Kick.wav')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(destination, 'Song Template Kick.wav')).readAsStringSync(),
        'kick data',
      );
      expect(File(p.join(destination, 'readme.txt')).existsSync(), isTrue);
    });

    test(
      'copies nested subfolders and renames a nested main file in place',
      () async {
        final projectFilesDir = Directory(
          p.join(sourceDir.path, 'Project Files'),
        );
        await projectFilesDir.create(recursive: true);
        File(
          p.join(projectFilesDir.path, 'Song Template.als'),
        ).writeAsStringSync('als data');
        File(
          p.join(sourceDir.path, 'notes.txt'),
        ).writeAsStringSync('top level file');
        final destination = p.join(destinationsDir.path, 'My New Track');

        final newMainFilePath = await ProjectTemplateService.instantiate(
          template: makeTemplate(
            mainFileRelativePath: p.join('Project Files', 'Song Template.als'),
          ),
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
        );

        expect(
          newMainFilePath,
          p.join(destination, 'Project Files', 'My New Track.als'),
        );
        expect(File(newMainFilePath).existsSync(), isTrue);
        expect(File(p.join(destination, 'notes.txt')).existsSync(), isTrue);
      },
    );

    test(
      'without siblingTemplates, an unregistered project file in the same folder is still copied',
      () async {
        // A stray/unregistered project file sitting next to the template is
        // not something the caller told us about, so it's treated like any
        // other resource — "other folders/files in that same folder should
        // be okay to copy even if they happen to have some other projects
        // inside" per the redesigned, template-aware exclusion.
        File(
          p.join(sourceDir.path, 'Song Template.als'),
        ).writeAsStringSync('als data');
        File(
          p.join(sourceDir.path, 'Other Version.als'),
        ).writeAsStringSync('other data');
        final destination = p.join(destinationsDir.path, 'My New Track');

        await ProjectTemplateService.instantiate(
          template: makeTemplate(),
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
        );

        expect(
          File(p.join(destination, 'Other Version.als')).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'excludes a registered sibling template that sits directly in the same folder',
      () async {
        // Two self-contained songs sharing one folder/sample pool — see
        // discoverTemplateCandidates. Instantiating one must not drag the
        // other registered template's project file along.
        File(
          p.join(sourceDir.path, 'Song Template.als'),
        ).writeAsStringSync('als data');
        File(
          p.join(sourceDir.path, 'Other Version.als'),
        ).writeAsStringSync('other data');
        File(p.join(sourceDir.path, 'Kick.wav')).writeAsStringSync('kick data');
        final destination = p.join(destinationsDir.path, 'My New Track');
        final sibling = makeTemplate(
          mainFileRelativePath: 'Other Version.als',
        ).copyWith(id: 'template-2', name: 'Other Version');

        await ProjectTemplateService.instantiate(
          template: makeTemplate(),
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
          siblingTemplates: [sibling],
        );

        expect(
          File(p.join(destination, 'My New Track.als')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(destination, 'Other Version.als')).existsSync(),
          isFalse,
        );
        // Non-project sibling files are still copied.
        expect(File(p.join(destination, 'Kick.wav')).existsSync(), isTrue);
      },
    );

    test(
      'excludes a registered sibling template that lives nested in its own subfolder',
      () async {
        // Each song lives in its own subfolder under the shared template
        // root — instantiating "Song A" must not drag the whole "Song B"
        // subfolder along, even though the exclusion only happened to catch
        // same-directory files before this template-aware redesign.
        final songADir = Directory(p.join(sourceDir.path, 'Song A'));
        final songBDir = Directory(p.join(sourceDir.path, 'Song B'));
        await songADir.create(recursive: true);
        await songBDir.create(recursive: true);
        File(
          p.join(songADir.path, 'Song A.als'),
        ).writeAsStringSync('song a data');
        File(
          p.join(songBDir.path, 'Song B.als'),
        ).writeAsStringSync('song b data');
        final destination = p.join(destinationsDir.path, 'My New Track');
        final template = makeTemplate(
          mainFileRelativePath: p.join('Song A', 'Song A.als'),
        );
        final sibling = template.copyWith(
          id: 'template-2',
          name: 'Song B',
          mainFileRelativePath: p.join('Song B', 'Song B.als'),
        );

        await ProjectTemplateService.instantiate(
          template: template,
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
          siblingTemplates: [sibling],
        );

        expect(
          File(p.join(destination, 'Song A', 'My New Track.als')).existsSync(),
          isTrue,
        );
        expect(Directory(p.join(destination, 'Song B')).existsSync(), isFalse);
      },
    );

    test(
      'does not exclude a project file that is not itself a registered sibling template',
      () async {
        File(
          p.join(sourceDir.path, 'Song Template.als'),
        ).writeAsStringSync('als data');
        final rendersDir = Directory(p.join(sourceDir.path, 'Renders'));
        await rendersDir.create(recursive: true);
        File(
          p.join(rendersDir.path, 'Export Session.als'),
        ).writeAsStringSync('export data');
        final destination = p.join(destinationsDir.path, 'My New Track');

        await ProjectTemplateService.instantiate(
          template: makeTemplate(),
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
        );

        expect(
          File(
            p.join(destination, 'Renders', 'Export Session.als'),
          ).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'does not exclude a sibling that shares the same top-level subfolder as the main file',
      () async {
        // Guard: if two registered siblings live nested under the exact same
        // subfolder, excluding that subfolder for the "other" sibling would
        // also delete the folder holding the main file being instantiated.
        // Fall back to copying both rather than corrupting the new project.
        final sharedDir = Directory(p.join(sourceDir.path, 'Shared'));
        await sharedDir.create(recursive: true);
        File(
          p.join(sharedDir.path, 'Song A.als'),
        ).writeAsStringSync('song a data');
        File(
          p.join(sharedDir.path, 'Song B.als'),
        ).writeAsStringSync('song b data');
        final destination = p.join(destinationsDir.path, 'My New Track');
        final template = makeTemplate(
          mainFileRelativePath: p.join('Shared', 'Song A.als'),
        );
        final sibling = template.copyWith(
          id: 'template-2',
          name: 'Song B',
          mainFileRelativePath: p.join('Shared', 'Song B.als'),
        );

        await ProjectTemplateService.instantiate(
          template: template,
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
          siblingTemplates: [sibling],
        );

        expect(
          File(p.join(destination, 'Shared', 'My New Track.als')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(destination, 'Shared', 'Song B.als')).existsSync(),
          isTrue,
        );
      },
    );

    test('throws when the template source folder no longer exists', () async {
      File(
        p.join(sourceDir.path, 'Song Template.als'),
      ).writeAsStringSync('als data');
      await sourceDir.delete(recursive: true);
      final destination = p.join(destinationsDir.path, 'My New Track');

      expect(
        () => ProjectTemplateService.instantiate(
          template: makeTemplate(),
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
        ),
        throwsStateError,
      );
    });

    test('throws when the template main file no longer exists', () async {
      // Source folder exists but the registered main file was deleted/moved.
      File(p.join(sourceDir.path, 'other.txt')).writeAsStringSync('data');
      final destination = p.join(destinationsDir.path, 'My New Track');

      expect(
        () => ProjectTemplateService.instantiate(
          template: makeTemplate(),
          destinationFolderPath: destination,
          newProjectName: 'My New Track',
        ),
        throwsStateError,
      );
    });

    test(
      'cleans up the partially-copied destination folder when the copy fails partway through',
      () async {
        File(
          p.join(sourceDir.path, 'Song Template.als'),
        ).writeAsStringSync('als data');
        final samplesDir = Directory(p.join(sourceDir.path, 'Samples'))
          ..createSync();
        File(
          p.join(samplesDir.path, 'kick.wav'),
        ).writeAsStringSync('wav data');

        final destination = p.join(destinationsDir.path, 'My New Track');
        // A copy that fails once files are already in the destination.
        debugAfterTemplateCopy = (_) => throw const FileSystemException('disk full');
        addTearDown(() => debugAfterTemplateCopy = null);

        await expectLater(
          ProjectTemplateService.instantiate(
            template: makeTemplate(),
            destinationFolderPath: destination,
            newProjectName: 'My New Track',
          ),
          throwsA(isA<FileSystemException>()),
        );

        // The whole destination folder — including what was already copied —
        // must be gone. Left behind, it would collide with a same-named retry
        // ("folder already exists") with no way for the user to tell it apart
        // from a real project.
        expect(await Directory(destination).exists(), isFalse);
      },
    );

    test('refuses a destination that already exists, and leaves it as it was',
        () async {
      // The failure cleanup deletes the destination recursively. It used to
      // trust the dialog to have checked the folder was new — when the name
      // was typed — so a folder appearing by the time the copy ran (a cloud
      // sync, a second click on Finish) was deleted with whatever was in it.
      File(p.join(sourceDir.path, 'Song Template.als')).writeAsStringSync('als data');
      final destination = Directory(p.join(destinationsDir.path, 'My New Track'));
      await destination.create(recursive: true);
      final mine = File(p.join(destination.path, 'vocals take 3.wav'))..writeAsStringSync('mine');

      await expectLater(
        ProjectTemplateService.instantiate(
          template: makeTemplate(),
          destinationFolderPath: destination.path,
          newProjectName: 'My New Track',
        ),
        throwsStateError,
      );

      expect(await mine.readAsString(), 'mine');
    });
  });

  group('ProjectTemplateService.discoverTemplateCandidates', () {
    test('registers a subfolder with exactly one recognized DAW file', () {
      final parent = Directory(p.join(tempDir.path, 'parent'));
      final songA = Directory(p.join(parent.path, 'Song A'));
      songA.createSync(recursive: true);
      File(p.join(songA.path, 'Song A.als')).writeAsStringSync('data');

      final candidates = ProjectTemplateService.discoverTemplateCandidates(
        parent.path,
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.name, 'Song A');
      expect(candidates.single.sourceFolderPath, songA.path);
      expect(candidates.single.mainFileRelativePath, 'Song A.als');
    });

    test(
      'finds the file even when nested in a subfolder of the template folder',
      () {
        final parent = Directory(p.join(tempDir.path, 'parent'));
        final songA = Directory(p.join(parent.path, 'Song A', 'Project Files'));
        songA.createSync(recursive: true);
        File(p.join(songA.path, 'Song A.als')).writeAsStringSync('data');

        final candidates = ProjectTemplateService.discoverTemplateCandidates(
          parent.path,
        );

        expect(candidates, hasLength(1));
        expect(
          candidates.single.mainFileRelativePath,
          p.join('Project Files', 'Song A.als'),
        );
      },
    );

    test('skips a subfolder with no recognized DAW file', () {
      final parent = Directory(p.join(tempDir.path, 'parent'));
      final noProject = Directory(p.join(parent.path, 'Not A Template'));
      noProject.createSync(recursive: true);
      File(p.join(noProject.path, 'readme.txt')).writeAsStringSync('data');

      final candidates = ProjectTemplateService.discoverTemplateCandidates(
        parent.path,
      );

      expect(candidates, isEmpty);
    });

    test(
      'registers one candidate per file when a subfolder has multiple DAW project files',
      () {
        // A "shared" folder — several self-contained songs sitting side by
        // side (e.g. sharing one sample pool) — must not be skipped as
        // ambiguous; each project file becomes its own template instead.
        final parent = Directory(p.join(tempDir.path, 'parent'));
        final shared = Directory(p.join(parent.path, 'Shared'));
        shared.createSync(recursive: true);
        File(p.join(shared.path, 'Version 1.als')).writeAsStringSync('data');
        File(p.join(shared.path, 'Version 2.als')).writeAsStringSync('data');

        final candidates = ProjectTemplateService.discoverTemplateCandidates(
          parent.path,
        );

        expect(candidates, hasLength(2));
        expect(
          candidates.every((c) => c.sourceFolderPath == shared.path),
          isTrue,
        );
        expect(candidates.map((c) => c.mainFileRelativePath).toSet(), {
          'Version 1.als',
          'Version 2.als',
        });
        expect(candidates.map((c) => c.name).toSet(), {
          'Shared — Version 1',
          'Shared — Version 2',
        });
      },
    );

    test(
      'ignores loose files directly in the parent folder, only descends into subfolders',
      () {
        final parent = Directory(p.join(tempDir.path, 'parent'));
        parent.createSync(recursive: true);
        File(p.join(parent.path, 'Loose.als')).writeAsStringSync('data');

        final candidates = ProjectTemplateService.discoverTemplateCandidates(
          parent.path,
        );

        expect(candidates, isEmpty);
      },
    );

    test('processes multiple subfolders independently', () {
      final parent = Directory(p.join(tempDir.path, 'parent'));
      final songA = Directory(p.join(parent.path, 'Song A'));
      final songB = Directory(p.join(parent.path, 'Song B'));
      songA.createSync(recursive: true);
      songB.createSync(recursive: true);
      File(p.join(songA.path, 'Song A.als')).writeAsStringSync('data');
      File(p.join(songB.path, 'Song B.rpp')).writeAsStringSync('data');

      final candidates = ProjectTemplateService.discoverTemplateCandidates(
        parent.path,
      );

      expect(candidates.map((c) => c.name).toSet(), {'Song A', 'Song B'});
    });

    test(
      'returns no candidates (instead of throwing) for a missing parent folder',
      () {
        // Regression test: when scanning multiple registered template roots in
        // a loop, one root that no longer exists (moved/deleted/unmounted
        // drive) used to throw and abort the whole loop, silently skipping
        // every root after it. This must degrade to "no candidates" instead.
        final missingParent = Directory(p.join(tempDir.path, 'does-not-exist'));

        final candidates = ProjectTemplateService.discoverTemplateCandidates(
          missingParent.path,
        );

        expect(candidates, isEmpty);
      },
    );

    test(
      'scanning a missing root does not prevent scanning a second, valid root',
      () {
        final missingParent = Directory(p.join(tempDir.path, 'does-not-exist'));
        final validParent = Directory(p.join(tempDir.path, 'valid-parent'));
        final songA = Directory(p.join(validParent.path, 'Song A'));
        songA.createSync(recursive: true);
        File(p.join(songA.path, 'Song A.als')).writeAsStringSync('data');

        final roots = [missingParent.path, validParent.path];
        final allCandidates = <TemplateFolderCandidate>[];
        for (final root in roots) {
          allCandidates.addAll(
            ProjectTemplateService.discoverTemplateCandidates(root),
          );
        }

        expect(allCandidates.map((c) => c.name), ['Song A']);
      },
    );
  });

  group('ProjectTemplateService.filterNewCandidates', () {
    const candidateA = TemplateFolderCandidate(
      name: 'Song A',
      sourceFolderPath: '/roots/parent/Song A',
      mainFileRelativePath: 'Song A.als',
    );
    const candidateB = TemplateFolderCandidate(
      name: 'Song B',
      sourceFolderPath: '/roots/parent/Song B',
      mainFileRelativePath: 'Song B.rpp',
    );
    String mainFilePath(TemplateFolderCandidate c) =>
        p.join(c.sourceFolderPath, c.mainFileRelativePath);

    test('keeps candidates whose main file path is not already registered', () {
      final result = ProjectTemplateService.filterNewCandidates([
        candidateA,
        candidateB,
      ], <String>{});

      expect(result, [candidateA, candidateB]);
    });

    test('drops candidates whose main file path is already registered', () {
      final result = ProjectTemplateService.filterNewCandidates(
        [candidateA, candidateB],
        {mainFilePath(candidateA)},
      );

      expect(result, [candidateB]);
    });

    test(
      'returns an empty list when every candidate is already registered',
      () {
        final result = ProjectTemplateService.filterNewCandidates(
          [candidateA, candidateB],
          {mainFilePath(candidateA), mainFilePath(candidateB)},
        );

        expect(result, isEmpty);
      },
    );

    test(
      'registering one candidate in a shared folder does not shadow its siblings',
      () {
        // Regression test: two candidates from the same "shared" folder (see
        // discoverTemplateCandidates) must be tracked independently by their
        // full file path — keying on sourceFolderPath alone would make
        // registering one filter out the other on every future refresh.
        const sharedA = TemplateFolderCandidate(
          name: 'Shared — Version 1',
          sourceFolderPath: '/roots/parent/Shared',
          mainFileRelativePath: 'Version 1.als',
        );
        const sharedB = TemplateFolderCandidate(
          name: 'Shared — Version 2',
          sourceFolderPath: '/roots/parent/Shared',
          mainFileRelativePath: 'Version 2.als',
        );

        final result = ProjectTemplateService.filterNewCandidates(
          [sharedA, sharedB],
          {mainFilePath(sharedA)},
        );

        expect(result, [sharedB]);
      },
    );
  });
}
