import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/missing_preview_songs_card.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';
import 'package:daw_project_manager/utils/missing_preview_songs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/semantics_orphans.dart';
import '../../helpers/test_factories.dart';

MissingPreviewSong _song(String id, MissingPreviewKind kind, {bool manual = true}) => MissingPreviewSong(
      project: TestFactories.makeProject(id: id, customDisplayName: 'Song $id'),
      path: '/gone/$id.wav',
      manual: manual,
      kind: kind,
    );

void main() {
  SemanticsOrphanBinding.ensureInitialized();

  final calls = <String>[];

  Widget app({
    List<MissingPreviewSong>? items,
    bool checking = false,
    bool busy = false,
    bool showSignInHint = false,
  }) =>
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MissingPreviewSongsCard(
              items: items,
              checking: checking,
              busy: busy,
              showSignInHint: showSignInHint,
              onCheck: () => calls.add('check'),
              onDownload: (s) => calls.add('download ${s.map((e) => e.project.id).join(',')}'),
              onFind: (s) => calls.add('find ${s.map((e) => e.project.id).join(',')}'),
              onChoose: (s) => calls.add('choose ${s.project.id}'),
              onRemove: (s, {required all}) =>
                  calls.add('remove${all ? ' all' : ''} ${s.map((e) => e.project.id).join(',')}'),
            ),
          ),
        ),
      );

  setUp(calls.clear);

  testWidgets('nothing is checked until asked', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Missing preview songs'), findsOneWidget);
    expect(find.text('Every preview song is where it should be.'), findsNothing);
    await tester.tap(find.text('Check'));
    expect(calls, ['check']);
  });

  testWidgets('while checking, the check waits', (tester) async {
    await tester.pumpWidget(app(checking: true));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Check'));
    expect(calls, isEmpty);
  });

  testWidgets('a clean check says so', (tester) async {
    await tester.pumpWidget(app(items: const []));

    expect(find.text('Every preview song is where it should be.'), findsOneWidget);
  });

  testWidgets('each reason is its own group, with its own actions', (tester) async {
    await tester.pumpWidget(app(items: [
      _song('d', MissingPreviewKind.onDrive),
      _song('o', MissingPreviewKind.otherComputer),
      _song('f', MissingPreviewKind.folderMissing),
      _song('g1', MissingPreviewKind.fileMissing),
      _song('g2', MissingPreviewKind.fileMissing, manual: false),
    ]));

    expect(find.text('On Google Drive (1)'), findsOneWidget);
    expect(find.text('From another computer (1)'), findsOneWidget);
    expect(find.text('Folder not there (1)'), findsOneWidget);
    expect(find.text('File gone (2)'), findsOneWidget);
    expect(find.text('Auto-detected · /gone/g2.wav'), findsOneWidget);

    // Another computer's songs may play fine there: never all at once.
    final other = find.byKey(const ValueKey('missing-preview-otherComputer'));
    expect(find.descendant(of: other, matching: find.text('Remove all')), findsNothing);
    expect(find.descendant(of: other, matching: find.text('Find all')), findsNothing);

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
    }

    await tap(find.text('Download all'));
    final gone = find.byKey(const ValueKey('missing-preview-fileMissing'));
    await tap(find.descendant(of: gone, matching: find.text('Find all')));
    await tap(find.descendant(of: gone, matching: find.text('Remove all')));
    expect(calls, ['download d', 'find g1,g2', 'remove all g1,g2']);
  });

  testWidgets('one button removes every song not found, whatever its group', (tester) async {
    await tester.pumpWidget(app(items: [
      _song('d', MissingPreviewKind.onDrive),
      _song('o', MissingPreviewKind.otherComputer),
      _song('f', MissingPreviewKind.folderMissing),
      _song('g', MissingPreviewKind.fileMissing),
    ]));

    final everything = find.byKey(const ValueKey('missing-preview-remove-everything'));
    await tester.ensureVisible(everything);
    await tester.pump();
    expect(find.text('Remove all not found (4)'), findsOneWidget);
    await tester.tap(everything);

    expect(calls, ['remove all d,o,f,g']);
  });

  testWidgets('a clean check offers nothing to remove', (tester) async {
    await tester.pumpWidget(app(items: const []));

    expect(find.byKey(const ValueKey('missing-preview-remove-everything')), findsNothing);
  });

  testWidgets('a row downloads, finds, picks or removes just its song', (tester) async {
    await tester.pumpWidget(app(items: [
      _song('d', MissingPreviewKind.onDrive),
      _song('g', MissingPreviewKind.fileMissing),
    ]));

    final drive = find.byKey(const ValueKey('missing-preview-song-d'));
    final gone = find.byKey(const ValueKey('missing-preview-song-g'));
    await tester.tap(find.descendant(of: drive, matching: find.text('Download')));
    await tester.tap(find.descendant(of: gone, matching: find.byTooltip('Auto-Find')));
    await tester.tap(find.descendant(of: gone, matching: find.byTooltip('Select New File')));
    await tester.tap(find.descendant(of: gone, matching: find.byTooltip('Remove preview song')));

    expect(calls, ['download d', 'find g', 'choose g', 'remove g']);
  });

  testWidgets('while an action runs, every button waits', (tester) async {
    await tester.pumpWidget(app(busy: true, items: [_song('g', MissingPreviewKind.fileMissing)]));

    await tester.tap(find.text('Check'));
    await tester.tap(find.text('Remove all'));
    await tester.tap(find.byTooltip('Remove preview song'));
    expect(calls, isEmpty);
  });

  testWidgets('says Drive could be searched too when signed out', (tester) async {
    await tester.pumpWidget(app(items: const [], showSignInHint: true));

    expect(find.text('Sign in to Google Drive to look for them there too.'), findsOneWidget);
  });

  testWidgets('no tooltip leaves Windows a node it would reject', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(items: [
      _song('d', MissingPreviewKind.onDrive),
      _song('g', MissingPreviewKind.fileMissing),
    ]));

    final hovered = await expectNoOrphanSemanticsWhileHovering(tester);
    expect(hovered, greaterThan(3));
    semantics.dispose();
  });
}
