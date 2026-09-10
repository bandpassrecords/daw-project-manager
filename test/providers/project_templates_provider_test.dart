import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/project_template.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/services/project_template_service.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  ProjectTemplate makeTemplate({
    String id = 'template-1',
    String name = 'Song Template',
  }) {
    return ProjectTemplate(
      id: id,
      name: name,
      sourceFolderPath: '/Users/artist/Templates/$name',
      mainFileRelativePath: '$name.als',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
  }

  group('ProjectTemplatesNotifier', () {
    test('addTemplate persists the template so it can be read back from the box', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(projectTemplatesNotifierProvider.notifier)
          .addTemplate(makeTemplate());

      final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
      expect(box.get('template-1')?.name, 'Song Template');
    });

    test('updateTemplate overwrites the existing entry for the same id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(makeTemplate());
      await notifier.updateTemplate(makeTemplate().copyWith(name: 'Renamed Template'));

      final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
      expect(box.get('template-1')?.name, 'Renamed Template');
      expect(box.length, 1);
    });

    // A ProjectTemplate points at a folder the user owns and maintains — the
    // app only ever copies it. Deleting the template must stay a Hive-only
    // operation, so a user removing a bookmark can never lose the real work.
    test('deleteTemplate leaves the template source folder on disk untouched', () async {
      final sourceFolder = Directory('${tempDir.path}/Song Template')
        ..createSync(recursive: true);
      final mainFile = File('${sourceFolder.path}/Song Template.als')
        ..writeAsStringSync('project data');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(
        ProjectTemplate(
          id: 'template-1',
          name: 'Song Template',
          sourceFolderPath: sourceFolder.path,
          mainFileRelativePath: 'Song Template.als',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );
      await notifier.deleteTemplate('template-1');

      final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
      expect(box.get('template-1'), isNull);
      expect(sourceFolder.existsSync(), isTrue);
      expect(mainFile.existsSync(), isTrue);
      expect(mainFile.readAsStringSync(), 'project data');
    });

    test('deleteTemplate removes only the targeted template', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(makeTemplate(id: 'template-1', name: 'A'));
      await notifier.addTemplate(makeTemplate(id: 'template-2', name: 'B'));
      await notifier.deleteTemplate('template-1');

      final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
      expect(box.get('template-1'), isNull);
      expect(box.get('template-2')?.name, 'B');
    });
  });

  group('ProjectTemplatesNotifier — hide/unhide', () {
    test('setTemplatesHidden(true) marks only the given templates hidden', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(makeTemplate(id: 'template-1', name: 'A'));
      await notifier.addTemplate(makeTemplate(id: 'template-2', name: 'B'));
      await notifier.setTemplatesHidden(['template-1'], true);

      final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
      expect(box.get('template-1')?.hidden, isTrue);
      expect(box.get('template-2')?.hidden, isFalse);
    });

    test('setTemplatesHidden(false) brings a hidden template back', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(makeTemplate());
      await notifier.setTemplatesHidden(['template-1'], true);
      await notifier.setTemplatesHidden(['template-1'], false);

      final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
      expect(box.get('template-1')?.hidden, isFalse);
    });

    // Hiding is a view preference, not an edit — bumping updatedAt would
    // reshuffle the table's default "most recently updated first" sort under
    // the user the moment they hid something.
    test('hiding leaves updatedAt untouched', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(makeTemplate());
      await notifier.setTemplatesHidden(['template-1'], true);

      final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
      expect(box.get('template-1')?.updatedAt, DateTime(2025, 1, 1));
    });

    test('ignores ids that are not in the box', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(makeTemplate());
      await notifier.setTemplatesHidden(['nope'], true);

      final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
      expect(box.get('template-1')?.hidden, isFalse);
      expect(box.length, 1);
    });

    // The reason hiding exists at all: a template whose folder still sits
    // under a registered template root would be re-imported as a brand new
    // template (new id, user's name/notes/metadata edits lost) on the next
    // refresh if the record were deleted. Hidden templates stay in the box,
    // so the refresh still recognizes the path as registered.
    test('a hidden template still counts as registered, so a refresh will not re-import it', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(projectTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(makeTemplate());
      await notifier.setTemplatesHidden(['template-1'], true);

      // Exactly how _refreshTemplateRoots builds its "already registered" set.
      final box = await Hive.openBox<ProjectTemplate>('projectTemplates');
      final existingPaths = box.values
          .map((t) => p.join(t.sourceFolderPath, t.mainFileRelativePath))
          .toSet();

      final rediscovered = TemplateFolderCandidate(
        name: 'Song Template',
        sourceFolderPath: '/Users/artist/Templates/Song Template',
        mainFileRelativePath: 'Song Template.als',
      );

      expect(
        ProjectTemplateService.filterNewCandidates([rediscovered], existingPaths),
        isEmpty,
      );
    });
  });

  // projectTemplatesProvider's own sort/emit logic isn't covered here: its
  // build() stays suspended inside `await for (box.watch())` even after the
  // first value is read via `.future`, and disposing a ProviderContainer
  // while that's still pending hangs at teardown in this Riverpod/Hive
  // combination. The identical existing pattern (todoTemplatesProvider) has
  // the same untestable shape and no coverage of its own for the same
  // reason — the sort itself is a one-line `list.sort(...)` exercised
  // manually above via direct box reads.
}
