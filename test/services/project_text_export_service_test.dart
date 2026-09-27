import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/generated/l10n/app_localizations_en.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/services/project_text_export_service.dart';
import '../helpers/test_factories.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('ProjectTextExportService.formatProject', () {
    test('includes core metadata fields', () {
      final project = TestFactories.makeProject(
        customDisplayName: 'Banger',
        filePath: '/Users/artist/Live Sets/Banger.als',
        fileSizeBytes: 2048000,
        status: 'Mixing',
        dawType: 'Ableton Live',
        dawVersion: '11',
        bpm: 128,
        musicalKey: 'C#m',
      );

      final text = ProjectTextExportService.formatProject(project, l10n);

      expect(text, contains('Project: Banger'));
      expect(text, contains('DAW: Ableton Live 11'));
      expect(text, contains('Status: Mixing'));
      expect(text, contains('BPM: 128'));
      expect(text, contains('Key: C#m'));
      expect(text, contains('File path: /Users/artist/Live Sets/Banger.als'));
    });

    test('formats a non-integer BPM with decimals', () {
      final project = TestFactories.makeProject(bpm: 127.5);
      final text = ProjectTextExportService.formatProject(project, l10n);
      expect(text, contains('BPM: 127.50'));
    });

    test('includes notes, todos, and work sessions when present', () {
      final project = TestFactories.makeProject(
        notes: 'Needs a bigger drop',
        todos: [
          TestFactories.makeTodo(text: 'Mix the kick drum', completed: true),
          TestFactories.makeTodo(id: 'todo-2', text: 'Add reverb', completed: false),
        ],
        totalWorkSeconds: 5400,
        sessions: [
          SessionRecord(
            id: 's1',
            startedAt: DateTime(2025, 1, 10, 9, 0),
            endedAt: DateTime(2025, 1, 10, 10, 30),
            durationSeconds: 5400,
            phase: 'Mixing',
          ),
        ],
      );

      final text = ProjectTextExportService.formatProject(project, l10n);

      expect(text, contains('Notes:'));
      expect(text, contains('Needs a bigger drop'));
      expect(text, contains('[x] Mix the kick drum'));
      expect(text, contains('[ ] Add reverb'));
      expect(text, contains('Total time worked: 1h 30m'));
      expect(text, contains('Work sessions (1):'));
      expect(text, contains('[Mixing]'));
    });

    test('omits optional sections for a minimal project without throwing', () {
      final project = TestFactories.makeMinimalProject();

      final text = ProjectTextExportService.formatProject(project, l10n);

      expect(text, contains('Project:'));
      expect(text, isNot(contains('Notes:')));
      expect(text, isNot(contains('To-dos:')));
      expect(text, isNot(contains('Work sessions')));
      expect(text, isNot(contains('BPM:')));
      expect(text, isNot(contains('Key:')));
      expect(text, isNot(contains('Parts:')));
      expect(text, isNot(contains('Tags:')));
    });

    test('lists the tags on one line (#109)', () {
      final project = TestFactories.makeProject(tags: ['trap', '🔥🔥🔥']);

      final text = ProjectTextExportService.formatProject(project, l10n);

      expect(text, contains('Tags: trap, 🔥🔥🔥'));
    });

    test('lists each part with its performer, status and progress summary', () {
      final project = TestFactories.makeProject(
        parts: [
          TestFactories.makePart(
            id: 'p1',
            name: 'Drums',
            performer: 'Alex',
            status: PartTakeStatus.finalTake,
          ),
          TestFactories.makePart(
            id: 'p2',
            name: 'Bass',
            performer: null,
            status: PartTakeStatus.recording,
            notes: 'try the P-Bass',
          ),
        ],
      );

      final text = ProjectTextExportService.formatProject(project, l10n);

      expect(text, contains('Parts:'));
      expect(text, contains('Drums — Alex — Final take'));
      expect(text, contains('Bass — Unassigned — Recording'));
      expect(text, contains('try the P-Bass'));
      expect(text, contains('1 of 2 final takes'));
    });
  });

  group('ProjectTextExportService.formatProjects', () {
    test('includes every project and a total count header', () {
      final projects = [
        TestFactories.makeProject(id: 'p1', customDisplayName: 'First'),
        TestFactories.makeProject(id: 'p2', customDisplayName: 'Second'),
      ];

      final text = ProjectTextExportService.formatProjects(projects, l10n);

      expect(text, contains('Total projects: 2'));
      expect(text, contains('Project: First'));
      expect(text, contains('Project: Second'));
    });

    test('handles an empty project list', () {
      final text = ProjectTextExportService.formatProjects(const [], l10n);
      expect(text, contains('Total projects: 0'));
    });
  });

  group('file name suggestions', () {
    test('suggestedFileNameFor sanitizes unsafe characters from the display name', () {
      final project = TestFactories.makeProject(customDisplayName: 'My:Song/Name?');
      final name = ProjectTextExportService.suggestedFileNameFor(project);
      expect(name, 'My_Song_Name__info.txt');
    });

    test('suggestedBulkFileName has a .txt extension', () {
      final name = ProjectTextExportService.suggestedBulkFileName();
      expect(name, endsWith('.txt'));
      expect(name, startsWith('daw_project_manager_projects_'));
    });
  });
}
