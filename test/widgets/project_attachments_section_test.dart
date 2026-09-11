import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_attachment.dart';
import 'package:daw_project_manager/ui/widgets/project_attachments_section.dart';

/// #112 — the attachments list takes plain values rather than a
/// `MusicProject` or a `Ref`, so every state here runs without opening Hive or
/// touching the file system.
void main() {
  final reference = ProjectAttachment(
    id: 'a1',
    kind: ProjectAttachmentKind.file,
    target: '/Users/artist/Refs/reference.wav',
    label: 'Reference track',
    addedAt: DateTime(2025, 2, 3),
  );
  final stems = ProjectAttachment(
    id: 'a2',
    kind: ProjectAttachmentKind.link,
    target: 'https://drive.google.com/drive/folders/abc123',
    addedAt: DateTime(2025, 2, 4),
    note: 'expires in 7 days',
  );

  late List<String> opened;
  late List<String> edited;
  late List<String> removed;
  late int addFileTaps;
  late int addLinkTaps;
  late int exportTaps;

  setUp(() {
    opened = [];
    edited = [];
    removed = [];
    addFileTaps = 0;
    addLinkTaps = 0;
    exportTaps = 0;
  });

  Widget wrap(
    List<ProjectAttachment> attachments, {
    Set<String> missing = const {},
  }) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectAttachmentsSection(
              attachments: attachments,
              missingTargets: missing,
              addFileLabel: 'Add File',
              addLinkLabel: 'Add Link',
              exportLabel: 'Export',
              exportTooltip: 'Save the attached files and links',
              emptyTitle: 'Nothing attached yet',
              emptyDescription: 'Keep the reference track with the song.',
              missingLabel: 'File not found',
              openTooltip: 'Open',
              editTooltip: 'Edit',
              removeTooltip: 'Remove',
              onAddFile: () => addFileTaps++,
              onAddLink: () => addLinkTaps++,
              onExport: () => exportTaps++,
              onOpen: (a) => opened.add(a.id),
              onEdit: (a) => edited.add(a.id),
              onRemove: (a) => removed.add(a.id),
            ),
          ),
        ),
      );

  testWidgets('offers both add actions even with nothing attached',
      (tester) async {
    await tester.pumpWidget(wrap(const []));

    expect(find.text('Nothing attached yet'), findsOneWidget);
    expect(find.text('Add File'), findsOneWidget);
    expect(find.text('Add Link'), findsOneWidget);

    await tester.tap(find.text('Add File'));
    await tester.tap(find.text('Add Link'));
    expect(addFileTaps, 1);
    expect(addLinkTaps, 1);
    expect(
      find.text('Export'),
      findsNothing,
      reason: 'there is nothing to export until something is attached',
    );
  });

  testWidgets('export appears once something is attached', (tester) async {
    await tester.pumpWidget(wrap([reference]));

    await tester.tap(find.text('Export'));
    expect(exportTaps, 1);
  });

  testWidgets('shows a labelled file and its path', (tester) async {
    await tester.pumpWidget(wrap([reference]));

    expect(find.text('Nothing attached yet'), findsNothing);
    expect(find.text('Reference track'), findsOneWidget);
    expect(find.text('/Users/artist/Refs/reference.wav'), findsOneWidget);
  });

  testWidgets('an unlabelled link falls back to host and path',
      (tester) async {
    await tester.pumpWidget(wrap([stems]));

    expect(
      find.text('drive.google.com/drive/folders/abc123'),
      findsOneWidget,
    );
    expect(find.text('expires in 7 days'), findsOneWidget);
    // Scoped to the row: the "Add Link" button carries the same icon.
    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.byIcon(Icons.link),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a missing file is flagged in the row, not on click',
      (tester) async {
    await tester.pumpWidget(wrap([reference], missing: {reference.id}));

    expect(
      find.textContaining('File not found'),
      findsOneWidget,
      reason: 'a moved file must be visible before the user clicks it',
    );
    expect(find.byIcon(Icons.report_gmailerrorred_outlined), findsOneWidget);

    // Still tappable: the click is what surfaces the full message.
    await tester.tap(find.text('Reference track'));
    expect(opened, ['a1']);
  });

  testWidgets('tapping a row opens it; the icons edit and remove it',
      (tester) async {
    await tester.pumpWidget(wrap([reference]));

    await tester.tap(find.text('Reference track'));
    expect(opened, ['a1']);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    expect(edited, ['a1']);

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(removed, ['a1']);
  });

  testWidgets('every attachment gets its own row', (tester) async {
    await tester.pumpWidget(wrap([reference, stems]));

    expect(find.byType(ListTile), findsNWidgets(2));
  });
}
