import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_template.dart';
import 'package:daw_project_manager/ui/project_templates_page.dart';

void main() {
  group('compareTemplateModifiedCellValues', () {
    // Same regression this guards against as the main dashboard table's
    // compareLastModifiedCellValues: the cell must carry a raw DateTime (not
    // the formatted display string) so sort is chronological, not alphabetical.

    test('orders chronologically even when alphabetical month order disagrees', () {
      final july = DateTime(2026, 7, 1);
      final january = DateTime(2027, 1, 1); // later date, "smaller" month name

      expect(compareTemplateModifiedCellValues(july, january), lessThan(0));
      expect(compareTemplateModifiedCellValues(january, july), greaterThan(0));
    });

    test('treats equal DateTimes as equal', () {
      final date = DateTime(2026, 7, 21, 20, 0);

      expect(compareTemplateModifiedCellValues(date, DateTime(2026, 7, 21, 20, 0)), 0);
    });

    test('orders within the same day by time of day', () {
      final morning = DateTime(2026, 7, 21, 9, 0);
      final evening = DateTime(2026, 7, 21, 20, 0);

      expect(compareTemplateModifiedCellValues(morning, evening), lessThan(0));
    });

    test('treats two missing-file (null) values as equal', () {
      expect(compareTemplateModifiedCellValues(null, null), 0);
    });

    test('sorts a missing-file (null) value before a dated one', () {
      final date = DateTime(2026, 7, 21);

      expect(compareTemplateModifiedCellValues(null, date), lessThan(0));
      expect(compareTemplateModifiedCellValues(date, null), greaterThan(0));
    });
  });

  group('missingTemplateIds', () {
    // The templates table mirrors the dashboard's rule for projects: a
    // template whose files are still on disk can only be hidden, never
    // deleted (deleting it would just invite the next template-folder
    // refresh to re-import it). Deletion is offered for missing ones only,
    // and — like the dashboard's "Delete Missing" — must never reach past
    // them into healthy templates that happen to be selected too.

    ProjectTemplate template(String id, String mainFilePath) => ProjectTemplate(
      id: id,
      name: id,
      sourceFolderPath: File(mainFilePath).parent.path,
      mainFileRelativePath: mainFilePath.split(Platform.pathSeparator).last,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('returns only selected templates whose main file is gone', () async {
      final dir = await Directory.systemTemp.createTemp('missing_template_ids_');
      try {
        final existing = File('${dir.path}${Platform.pathSeparator}exists.als');
        await existing.create();
        final present = template('present', existing.path);
        final missing = template(
          'missing',
          '${dir.path}${Platform.pathSeparator}gone.als',
        );

        expect(
          missingTemplateIds([present, missing], ['present', 'missing']),
          ['missing'],
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('ignores a missing template that was not selected', () {
      final missing = template(
        'missing',
        '${Platform.pathSeparator}nonexistent${Platform.pathSeparator}gone.als',
      );

      expect(missingTemplateIds([missing], []), isEmpty);
    });

    test('is empty when every selected template still has its file', () async {
      final dir = await Directory.systemTemp.createTemp('missing_template_ids_');
      try {
        final existing = File('${dir.path}${Platform.pathSeparator}exists.als');
        await existing.create();

        expect(
          missingTemplateIds([template('present', existing.path)], ['present']),
          isEmpty,
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
