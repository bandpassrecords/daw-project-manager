import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import 'package:daw_project_manager/models/part_template.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/models/project_template.dart';
import 'package:daw_project_manager/models/template_root.dart';
import 'package:daw_project_manager/models/todo_template.dart';
import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

void main() {
  group('BackupService JSON round-trip', () {
    test('preserves the version stacking links (#94)', () {
      // Local backup is Flatpak's only backup path, so a field skipped here
      // is one those users can never back up at all.
      final stack = TestFactories.makeProject(
        id: 'stack-1',
        isVirtual: true,
        memberProjectIds: const ['v1', 'v2'],
        defaultLaunchMemberId: 'v1',
      );
      final restoredStack =
          BackupService.projectFromJson(BackupService.projectToJson(stack));
      expect(restoredStack.isVirtual, isTrue);
      expect(restoredStack.memberProjectIds, ['v1', 'v2']);
      expect(restoredStack.defaultLaunchMemberId, 'v1');

      final member = TestFactories.makeProject(id: 'v1', stackId: 'stack-1');
      final restoredMember =
          BackupService.projectFromJson(BackupService.projectToJson(member));
      expect(restoredMember.stackId, 'stack-1');
    });

    test('preserves all basic fields', () {
      final original = TestFactories.makeProject(
        id: 'rt-1',
        filePath: '/Users/artist/Live Sets/Banger.als',
        fileName: 'Banger.als',
        fileSizeBytes: 2048000,
        status: 'Mixing',
        dawType: 'Ableton Live',
        dawVersion: '11',
      );

      final json = BackupService.projectToJson(original);
      final restored = BackupService.projectFromJson(json);

      expect(restored.id, original.id);
      expect(restored.filePath, original.filePath);
      expect(restored.fileName, original.fileName);
      expect(restored.fileSizeBytes, original.fileSizeBytes);
      expect(restored.status, original.status);
      expect(restored.dawType, original.dawType);
      expect(restored.dawVersion, original.dawVersion);
      expect(restored.fileExtension, original.fileExtension);
    });

    test('preserves lastModifiedAt exactly', () {
      final modifiedAt = DateTime(2024, 11, 5, 14, 23, 45);
      final original = TestFactories.makeProject(lastModifiedAt: modifiedAt);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.lastModifiedAt, modifiedAt);
    });

    test('preserves fileCreatedAt when set', () {
      final createdAt = DateTime(2023, 3, 10, 9, 0, 0);
      final original =
          TestFactories.makeProject(fileCreatedAt: createdAt);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.fileCreatedAt, createdAt);
    });

    test('preserves null fileCreatedAt', () {
      final original = TestFactories.makeProject(fileCreatedAt: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.fileCreatedAt, isNull);
    });

    test('preserves createdAt and updatedAt', () {
      final createdAt = DateTime(2022, 1, 1);
      final updatedAt = DateTime(2025, 6, 15);
      final original = TestFactories.makeProject(
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.createdAt, createdAt);
      expect(restored.updatedAt, updatedAt);
    });

    test('preserves optional metadata (bpm, key, notes)', () {
      final original = TestFactories.makeProject(
        bpm: 128.5,
        musicalKey: 'F# minor',
        notes: 'Needs more reverb on the snare',
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.bpm, 128.5);
      expect(restored.musicalKey, 'F# minor');
      expect(restored.notes, 'Needs more reverb on the snare');
    });

    test('preserves null optional metadata', () {
      final original =
          TestFactories.makeProject(bpm: null, musicalKey: null, notes: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.bpm, isNull);
      expect(restored.musicalKey, isNull);
      expect(restored.notes, isNull);
    });

    test('preserves the card label the user typed (#111)', () {
      // Flatpak's only backup path — a field skipped here is one those users
      // can never back up at all.
      final original = TestFactories.makeProject(cardInitials: 'X7');

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.cardInitials, 'X7');
    });

    test('preserves an unset card label', () {
      final original = TestFactories.makeProject(cardInitials: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.cardInitials, isNull);
    });

    test('preserves deadline', () {
      final deadline = DateTime(2026, 9, 1);
      final original = TestFactories.makeProject(deadline: deadline);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.deadline, deadline);
    });

    test('preserves null deadline', () {
      final original = TestFactories.makeProject(deadline: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.deadline, isNull);
    });

    test('preserves todos list', () {
      final todos = [
        TestFactories.makeTodo(id: 't1', text: 'EQ the bass'),
        TestFactories.makeTodo(id: 't2', text: 'Add reverb', completed: true),
      ];
      final original = TestFactories.makeProject(todos: todos);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.todos.length, 2);
      expect(restored.todos[0].text, 'EQ the bass');
      expect(restored.todos[0].completed, false);
      expect(restored.todos[1].text, 'Add reverb');
      expect(restored.todos[1].completed, true);
    });

    test('preserves empty todos list', () {
      final original = TestFactories.makeProject(todos: []);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.todos, isEmpty);
    });

    test('preserves per-todo due dates (#113)', () {
      // Local backup is Flatpak's only backup path — a due date skipped here
      // is one those users can never back up at all.
      final original = TestFactories.makeProject(todos: [
        TestFactories.makeTodo(
            id: 't1', text: 'Vocals', dueAt: DateTime(2025, 2, 14)),
        TestFactories.makeTodo(id: 't2', text: 'Mix'),
      ]);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.todos[0].dueAt, DateTime(2025, 2, 14));
      expect(restored.todos[1].dueAt, isNull);
    });

    test('a backup written before due dates existed restores them as null', () {
      final json = BackupService.projectToJson(
        TestFactories.makeProject(
          todos: [TestFactories.makeTodo(dueAt: DateTime(2025, 2, 14))],
        ),
      );
      for (final todo in json['todos'] as List) {
        (todo as Map).remove('dueAt');
      }

      expect(BackupService.projectFromJson(json).todos.single.dueAt, isNull);
    });

    test('preserves hidden flag', () {
      final original = TestFactories.makeProject(hidden: true);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.hidden, true);
    });

    test('preserves customDisplayName', () {
      final original =
          TestFactories.makeProject(customDisplayName: 'My Banger');

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.customDisplayName, 'My Banger');
    });

    test('backward compat: missing optional fields default to null/false', () {
      // Simulate an old backup that lacks newer fields
      final minimalJson = {
        'id': 'old-id',
        'filePath': '/old/project.als',
        'fileName': 'project.als',
        'fileSizeBytes': 512,
        'lastModifiedAt': DateTime(2022, 1, 1).toIso8601String(),
        'fileExtension': '.als',
        'status': 'Idea',
        'createdAt': DateTime(2021, 6, 1).toIso8601String(),
        'updatedAt': DateTime(2022, 1, 1).toIso8601String(),
      };

      final restored = BackupService.projectFromJson(minimalJson);

      expect(restored.id, 'old-id');
      expect(restored.fileCreatedAt, isNull);
      expect(restored.deadline, isNull);
      expect(restored.bpm, isNull);
      expect(restored.notes, isNull);
      expect(restored.hidden, false);
      expect(restored.todos, isEmpty);
    });

    test('preserves previewSongAutoPath, parentProjectId, and ignoredNewerSongPath', () {
      final original = TestFactories.makeProject(
        previewSongAutoPath: '/Users/artist/Live Sets/Bounces/mixdown.wav',
        parentProjectId: 'parent-project-id',
        ignoredNewerSongPath: '/Users/artist/Live Sets/Bounces/rejected.wav',
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.previewSongAutoPath, '/Users/artist/Live Sets/Bounces/mixdown.wav');
      expect(restored.parentProjectId, 'parent-project-id');
      expect(restored.ignoredNewerSongPath, '/Users/artist/Live Sets/Bounces/rejected.wav');
    });

    test('preserves null previewSongAutoPath, parentProjectId, and ignoredNewerSongPath', () {
      final original = TestFactories.makeProject(
        previewSongAutoPath: null,
        parentProjectId: null,
        ignoredNewerSongPath: null,
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.previewSongAutoPath, isNull);
      expect(restored.parentProjectId, isNull);
      expect(restored.ignoredNewerSongPath, isNull);
    });

    test('preserves projectNotes', () {
      final original = TestFactories.makeProject(
        projectNotes: 'Notes 1\nby Audio Crawler\n\nSome project notes',
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.projectNotes, 'Notes 1\nby Audio Crawler\n\nSome project notes');
    });

    test('preserves sourceTemplateId', () {
      final original = TestFactories.makeProject(sourceTemplateId: 'template-42');

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.sourceTemplateId, 'template-42');
    });

    test('preserves null sourceTemplateId', () {
      final original = TestFactories.makeProject(sourceTemplateId: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.sourceTemplateId, isNull);
    });

    test('preserves null projectNotes', () {
      final original = TestFactories.makeProject(projectNotes: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.projectNotes, isNull);
    });

    test('lastModifiedAt is unchanged after round-trip (not bumped to now)',
        () {
      final past = DateTime(2020, 6, 15, 8, 0, 0);
      final original = TestFactories.makeProject(lastModifiedAt: past);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.lastModifiedAt, past);
      expect(
        restored.lastModifiedAt.isAfter(DateTime.now()),
        isFalse,
        reason: 'lastModifiedAt must not be bumped to now during round-trip',
      );
    });

    test('preserves the parts list, including status and performer', () {
      final original = TestFactories.makeProject(parts: [
        TestFactories.makePart(
          id: 'p1',
          name: 'Drums',
          performer: 'Alex',
          status: PartTakeStatus.finalTake,
          notes: 'keeper',
        ),
        TestFactories.makePart(id: 'p2', name: 'Bass', performer: null),
      ]);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.parts, original.parts);
    });

    test('a project with no parts round-trips to an empty list', () {
      final restored = BackupService.projectFromJson(
        BackupService.projectToJson(TestFactories.makeProject()),
      );

      expect(restored.parts, isEmpty);
    });

    test('a pre-1.2 backup with no parts key still imports', () {
      // Older backup files simply don't have the key; that must read as
      // "no parts", not blow up the whole import.
      final json = BackupService.projectToJson(TestFactories.makeProject())
        ..remove('parts');

      expect(BackupService.projectFromJson(json).parts, isEmpty);
    });
  });

  // Backup version 1.1 added these — previously, a local backup had no way to
  // carry todo templates, project templates, template roots, custom mixdown
  // folder names, or phase customization at all, which mattered most for
  // Linux, where Google Drive sync (the only other place these were backed
  // up) isn't available.
  group('BackupService JSON round-trip — templates', () {
    test('TodoTemplate preserves all fields', () {
      final original = TodoTemplate(
        id: 'tt-1',
        name: 'Mixdown checklist',
        items: ['Check levels', 'Bounce stems'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 2, 1),
      );

      final restored = BackupService.todoTemplateFromJson(BackupService.todoTemplateToJson(original));

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.items, original.items);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('TodoTemplate preserves an empty items list', () {
      final original = TodoTemplate(
        id: 'tt-2',
        name: 'Empty',
        items: const [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final restored = BackupService.todoTemplateFromJson(BackupService.todoTemplateToJson(original));

      expect(restored.items, isEmpty);
    });

    test('ProjectTemplate preserves all fields including optional metadata', () {
      final original = ProjectTemplate(
        id: 'pt-1',
        name: 'Techno starter',
        sourceFolderPath: '/Users/artist/Templates/Techno',
        mainFileRelativePath: 'Techno.als',
        createdAt: DateTime(2023, 5, 1),
        updatedAt: DateTime(2023, 6, 1),
        bpm: 128.0,
        musicalKey: 'A minor',
        dawVersion: '11.3',
        notes: 'Great starting point for peak-time sets',
        projectNotes: 'Author: DJ Example',
      );

      final restored =
          BackupService.projectTemplateFromJson(BackupService.projectTemplateToJson(original));

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.sourceFolderPath, original.sourceFolderPath);
      expect(restored.mainFileRelativePath, original.mainFileRelativePath);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.bpm, 128.0);
      expect(restored.musicalKey, 'A minor');
      expect(restored.dawVersion, '11.3');
      expect(restored.notes, 'Great starting point for peak-time sets');
      expect(restored.projectNotes, 'Author: DJ Example');
    });

    test('ProjectTemplate preserves null optional metadata', () {
      final original = ProjectTemplate(
        id: 'pt-2',
        name: 'Blank',
        sourceFolderPath: '/Templates/Blank',
        mainFileRelativePath: 'Blank.als',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 1),
      );

      final restored =
          BackupService.projectTemplateFromJson(BackupService.projectTemplateToJson(original));

      expect(restored.bpm, isNull);
      expect(restored.musicalKey, isNull);
      expect(restored.dawVersion, isNull);
      expect(restored.notes, isNull);
      expect(restored.projectNotes, isNull);
    });

    test('TemplateRoot preserves all fields', () {
      final original = TemplateRoot(
        id: 'root-1',
        path: '/Users/artist/Templates',
        addedAt: DateTime(2023, 1, 1),
        lastRefreshedAt: DateTime(2023, 2, 1),
      );

      final restored = BackupService.templateRootFromJson(BackupService.templateRootToJson(original));

      expect(restored.id, original.id);
      expect(restored.path, original.path);
      expect(restored.addedAt, original.addedAt);
      expect(restored.lastRefreshedAt, original.lastRefreshedAt);
    });

    test('TemplateRoot preserves null lastRefreshedAt', () {
      final original = TemplateRoot(
        id: 'root-2',
        path: '/Templates',
        addedAt: DateTime(2023, 1, 1),
      );

      final restored = BackupService.templateRootFromJson(BackupService.templateRootToJson(original));

      expect(restored.lastRefreshedAt, isNull);
    });

  });

  group('BackupService global data — Hive read/write', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('todo templates: write then read round-trips', () async {
      final template = TodoTemplate(
        id: 'tt-1',
        name: 'Checklist',
        items: ['a', 'b'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await BackupService.writeGlobalTemplatesForTest([template], ImportMode.merge);
      final read = await BackupService.readGlobalTemplatesForTest();

      expect(read, hasLength(1));
      expect(read.single.id, 'tt-1');
      expect(read.single.items, ['a', 'b']);
    });

    test('todo templates: merge mode keeps existing entries alongside new ones', () async {
      final first = TodoTemplate(
        id: 'tt-1',
        name: 'First',
        items: const [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final second = TodoTemplate(
        id: 'tt-2',
        name: 'Second',
        items: const [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await BackupService.writeGlobalTemplatesForTest([first], ImportMode.merge);
      await BackupService.writeGlobalTemplatesForTest([second], ImportMode.merge);
      final read = await BackupService.readGlobalTemplatesForTest();

      expect(read.map((t) => t.id).toSet(), {'tt-1', 'tt-2'});
    });

    test('todo templates: replace mode clears entries from a previous write first', () async {
      final first = TodoTemplate(
        id: 'tt-1',
        name: 'First',
        items: const [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final second = TodoTemplate(
        id: 'tt-2',
        name: 'Second',
        items: const [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await BackupService.writeGlobalTemplatesForTest([first], ImportMode.merge);
      await BackupService.writeGlobalTemplatesForTest([second], ImportMode.replace);
      final read = await BackupService.readGlobalTemplatesForTest();

      expect(read.map((t) => t.id).toSet(), {'tt-2'});
    });

    test('part templates: write then read round-trips including nested parts', () async {
      final template = PartTemplate(
        id: 'part-tpl-1',
        name: 'Band Lineup',
        items: const [
          ProjectPart(id: 'i1', name: 'Drums', performer: 'Alex'),
          ProjectPart(id: 'i2', name: 'Bass'),
        ],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await BackupService.writeGlobalPartTemplatesForTest([template], ImportMode.merge);
      final read = await BackupService.readGlobalPartTemplatesForTest();

      expect(read, hasLength(1));
      expect(read.single.name, 'Band Lineup');
      expect(read.single.items.map((i) => i.name), ['Drums', 'Bass']);
      expect(read.single.items.first.performer, 'Alex');
    });

    test('part templates: replace mode clears entries from a previous write first', () async {
      PartTemplate make(String id) => PartTemplate(
            id: id,
            name: id,
            items: const [],
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          );

      await BackupService.writeGlobalPartTemplatesForTest([make('a')], ImportMode.merge);
      await BackupService.writeGlobalPartTemplatesForTest([make('b')], ImportMode.replace);
      final read = await BackupService.readGlobalPartTemplatesForTest();

      expect(read.map((t) => t.id).toSet(), {'b'});
    });

    test('project templates: write then read round-trips', () async {
      final template = ProjectTemplate(
        id: 'pt-1',
        name: 'Techno starter',
        sourceFolderPath: '/Templates/Techno',
        mainFileRelativePath: 'Techno.als',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await BackupService.writeGlobalProjectTemplatesForTest([template], ImportMode.merge);
      final read = await BackupService.readGlobalProjectTemplatesForTest();

      expect(read, hasLength(1));
      expect(read.single.sourceFolderPath, '/Templates/Techno');
    });

    test('template roots: write then read round-trips', () async {
      final root = TemplateRoot(
        id: 'root-1',
        path: '/Templates',
        addedAt: DateTime(2024, 1, 1),
      );

      await BackupService.writeGlobalTemplateRootsForTest([root], ImportMode.merge);
      final read = await BackupService.readGlobalTemplateRootsForTest();

      expect(read, hasLength(1));
      expect(read.single.path, '/Templates');
    });

    test('custom mixdown folders: union-merges with what is already stored, does not overwrite', () async {
      await BackupService.writeCustomMixdownFoldersForTest(['Bounces']);
      await BackupService.writeCustomMixdownFoldersForTest(['Mixdown']);
      final read = await BackupService.readCustomMixdownFoldersForTest();

      expect(read.toSet(), {'Bounces', 'Mixdown'});
    });

    test('custom mixdown folders: writing an empty list is a no-op', () async {
      await BackupService.writeCustomMixdownFoldersForTest(['Bounces']);
      await BackupService.writeCustomMixdownFoldersForTest([]);
      final read = await BackupService.readCustomMixdownFoldersForTest();

      expect(read, ['Bounces']);
    });

    test('per-DAW custom mixdown folders: union-merges per DAW key, does not overwrite', () async {
      await BackupService.writeCustomMixdownFoldersByDawForTest({
        'Ableton Live': ['Bounces'],
      });
      await BackupService.writeCustomMixdownFoldersByDawForTest({
        'Ableton Live': ['Mixdown'],
        'FL Studio': ['Renders'],
      });
      final read = await BackupService.readCustomMixdownFoldersByDawForTest();

      expect(read['Ableton Live']!.toSet(), {'Bounces', 'Mixdown'});
      expect(read['FL Studio'], ['Renders']);
    });

    test('per-DAW custom mixdown folders: writing an empty map is a no-op', () async {
      await BackupService.writeCustomMixdownFoldersByDawForTest({
        'Ableton Live': ['Bounces'],
      });
      await BackupService.writeCustomMixdownFoldersByDawForTest({});
      final read = await BackupService.readCustomMixdownFoldersByDawForTest();

      expect(read, {'Ableton Live': ['Bounces']});
    });

    test('DAW launch commands: round-trips a written map of path lists', () async {
      await BackupService.writeDawLaunchCommandsForTest({
        'Zrythm': ['/opt/zrythm/zrythm'],
        'Ableton Live': ['/a/Live 11.app', '/a/Live 12.app'],
      });
      final read = await BackupService.readDawLaunchCommandsForTest();

      expect(read, {
        'Zrythm': ['/opt/zrythm/zrythm'],
        'Ableton Live': ['/a/Live 11.app', '/a/Live 12.app'],
      });
    });

    test(
      'DAW launch commands: merge keeps local paths and appends new backup ones',
      () async {
        await BackupService.writeDawLaunchCommandsForTest({
          'Ableton Live': ['/a/Live 12.app'],
        });
        // Importing a backup: the shared path is not duplicated, the local
        // one keeps its position, the new one is appended.
        await BackupService.writeDawLaunchCommandsForTest({
          'Ableton Live': ['/a/Live 12.app', '/a/Live 11.app'],
        });
        final read = await BackupService.readDawLaunchCommandsForTest();

        expect(read, {
          'Ableton Live': ['/a/Live 12.app', '/a/Live 11.app'],
        });
      },
    );

    test('DAW launch commands: fills in a DAW not already configured', () async {
      await BackupService.writeDawLaunchCommandsForTest({
        'Zrythm': ['/opt/zrythm/zrythm'],
      });
      await BackupService.writeDawLaunchCommandsForTest({
        'Ardour': ['/opt/Ardour/Ardour.AppImage'],
      });
      final read = await BackupService.readDawLaunchCommandsForTest();

      expect(read, {
        'Zrythm': ['/opt/zrythm/zrythm'],
        'Ardour': ['/opt/Ardour/Ardour.AppImage'],
      });
    });

    test('DAW launch commands: reads a legacy single-string backup value', () async {
      // Older backups wrote {daw: "path"}; the reader coerces to a list.
      await BackupService.writeDawLaunchCommandsForTest({
        'Zrythm': ['/opt/zrythm/zrythm'],
      });
      final read = await BackupService.readDawLaunchCommandsForTest();
      expect(read['Zrythm'], ['/opt/zrythm/zrythm']);
    });

    test('DAW launch commands: writing an empty map is a no-op', () async {
      await BackupService.writeDawLaunchCommandsForTest({
        'Zrythm': ['/opt/zrythm/zrythm'],
      });
      await BackupService.writeDawLaunchCommandsForTest({});
      final read = await BackupService.readDawLaunchCommandsForTest();

      expect(read, {
        'Zrythm': ['/opt/zrythm/zrythm'],
      });
    });

    test('phase settings: write then read round-trips phases, colors, and finished phases', () async {
      final settings = {
        'phases': ['Idea', 'Mixing', 'Mastered'],
        'phaseColors': {'Idea': '#FF0000'},
        'finishedPhases': ['Mastered'],
      };

      await BackupService.writePhaseSettingsForTest('profile-1', settings);
      final read = await BackupService.readPhaseSettingsForTest('profile-1');

      expect(read['phases'], ['Idea', 'Mixing', 'Mastered']);
      expect(read['phaseColors'], {'Idea': '#FF0000'});
      expect(read['finishedPhases'], ['Mastered']);
    });

    test('phase settings: settings for one profile do not leak into another', () async {
      await BackupService.writePhaseSettingsForTest('profile-1', {
        'phases': ['A'],
      });
      final readOther = await BackupService.readPhaseSettingsForTest('profile-2');

      expect(readOther, isEmpty);
    });

    test('reading global data from empty boxes returns empty results, not an error', () async {
      expect(await BackupService.readGlobalTemplatesForTest(), isEmpty);
      expect(await BackupService.readGlobalProjectTemplatesForTest(), isEmpty);
      expect(await BackupService.readGlobalTemplateRootsForTest(), isEmpty);
      expect(await BackupService.readCustomMixdownFoldersForTest(), isEmpty);
      expect(await BackupService.readCustomMixdownFoldersByDawForTest(), isEmpty);
      expect(await BackupService.readDawLaunchCommandsForTest(), isEmpty);
      expect(await BackupService.readPhaseSettingsForTest('no-such-profile'), isEmpty);
    });
  });
}
