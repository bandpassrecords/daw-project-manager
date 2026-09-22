import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/project_attachment.dart';
import 'package:daw_project_manager/ui/dialogs/attachment_edit_dialog.dart';

/// #112 — the one dialog behind "Add Link" and behind editing any attachment.
/// It is the only place a user types a target by hand, so it is where a bad
/// link has to be caught before it reaches storage.
void main() {
  // Filled by the dialog's callback once it pops; a list rather than a
  // nullable field so "never returned" and "returned null" stay distinct.
  late List<ProjectAttachment?> results;

  setUp(() => results = []);

  Future<void> pump(
    WidgetTester tester, {
    ProjectAttachment? existing,
    ProjectAttachmentKind kind = ProjectAttachmentKind.link,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                results.add(await showAttachmentEditDialog(
                  context,
                  existing: existing,
                  kind: kind,
                ));
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder fieldWithLabel(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(TextField),
      );

  const urlError = 'Enter a valid link, e.g. https://example.com';

  testWidgets('a valid link comes back as a link attachment', (tester) async {
    await pump(tester);

    await tester.enterText(
      fieldWithLabel('URL'),
      'https://drive.google.com/drive/folders/abc',
    );
    await tester.enterText(fieldWithLabel('Label (optional)'), 'Stems');
    await tester.enterText(fieldWithLabel('Note (optional)'), 'expires soon');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    final added = results.single!;
    expect(added.kind, ProjectAttachmentKind.link);
    expect(added.target, 'https://drive.google.com/drive/folders/abc');
    expect(added.label, 'Stems');
    expect(added.note, 'expires soon');
    expect(added.id, isNotEmpty);
  });

  testWidgets('a scheme-less host is stored with the scheme added',
      (tester) async {
    await pump(tester);

    await tester.enterText(fieldWithLabel('URL'), 'www.example.com/song');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(results.single!.target, 'https://www.example.com/song');
  });

  testWidgets('an empty target is refused rather than stored', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget,
        reason: 'the dialog must stay open on an invalid target');
    expect(find.text(urlError), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('text that is not a URL is refused for a link', (tester) async {
    await pump(tester);

    await tester.enterText(fieldWithLabel('URL'), 'send me the stems');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(urlError), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('the error clears as soon as the user starts fixing it',
      (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text(urlError), findsOneWidget);

    await tester.enterText(fieldWithLabel('URL'), 'https://example.com');
    await tester.pumpAndSettle();
    expect(find.text(urlError), findsNothing);
  });

  testWidgets('editing pre-fills the existing values and keeps the id',
      (tester) async {
    final existing = ProjectAttachment(
      id: 'keep-me',
      kind: ProjectAttachmentKind.file,
      target: '/Users/artist/Refs/ref.wav',
      label: 'Reference',
      addedAt: DateTime(2025, 1, 1),
      note: 'v3',
    );

    await pump(tester, existing: existing);

    expect(find.text('Edit Attachment'), findsOneWidget);
    expect(find.text('/Users/artist/Refs/ref.wav'), findsOneWidget);
    expect(find.text('Reference'), findsOneWidget);
    expect(find.text('v3'), findsOneWidget);
    // A file attachment is edited as a path — never validated as a URL, or a
    // Windows path could never be corrected by hand.
    expect(find.text('File path'), findsOneWidget);

    await tester.enterText(fieldWithLabel('File path'), r'C:\Refs\ref.wav');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saved = results.single!;
    expect(saved.id, 'keep-me', reason: 'edit must not re-key the attachment');
    expect(saved.kind, ProjectAttachmentKind.file);
    expect(saved.target, r'C:\Refs\ref.wav');
    expect(saved.addedAt, DateTime(2025, 1, 1));
  });

  testWidgets('clearing the note removes it instead of storing empty text',
      (tester) async {
    final existing = ProjectAttachment(
      id: 'n1',
      kind: ProjectAttachmentKind.link,
      target: 'https://example.com',
      addedAt: DateTime(2025, 1, 1),
      note: 'expires soon',
    );

    await pump(tester, existing: existing);

    await tester.enterText(fieldWithLabel('Note (optional)'), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(results.single!.note, isNull);
  });
}
