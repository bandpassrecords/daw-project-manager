import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/sample_reference.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_copy.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_plan.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_writer.dart';
import 'package:daw_project_manager/ui/dialogs/relink_dialog.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

import '../helpers/semantics_orphans.dart';

const _old = r'D:\Old\Song\Audio\';
const _new = r'E:\Backup\Song\Audio\';

RelinkItem _item(String name, {List<String> candidates = const [], String? choice}) =>
    RelinkItem(
      reference: SampleReference(fileName: name, candidates: ['$_old$name']),
      stored: '$_old$name',
      candidates: candidates,
      choice: choice,
    );

/// What the dialog asked for, and what the fakes answer.
class _World {
  final calls = <String>[];
  Map<String, String>? written;
  String? inspected;
  String? folder = r'E:\Elsewhere';
  String? file = '${_new}hat.wav';
  Object? writeError;
  RelinkCopy copy = const RelinkCopy(
    path: r'D:\Old\Song\Song (relinked).cpr',
    relinked: {'${_old}kick.wav', '${_old}hat.wav'},
    refused: {'${_old}snare.wav': RelinkRefusal.doesNotFit},
  );

  RelinkActions get actions => RelinkActions(
        plan: (folders) async {
          calls.add('plan $folders');
          return [
            _item('kick.wav', candidates: [r'C:\k\kick.wav'], choice: r'C:\k\kick.wav'),
            _item('snare.wav', candidates: [r'X:\a\snare.wav', r'X:\b\snare.wav']),
            _item('hat.wav',
                candidates: folders.isEmpty ? const [] : [r'E:\Elsewhere\hat.wav'],
                choice: folders.isEmpty ? null : r'E:\Elsewhere\hat.wav'),
          ];
        },
        pickFolder: () async => folder,
        pickFile: (name) async {
          calls.add('browse $name');
          return file;
        },
        exists: (path) async => path.startsWith(_new),
        write: (moves) async {
          written = moves;
          if (writeError != null) throw writeError!;
          return copy;
        },
        inspect: (path) => inspected = path,
      );
}

void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, _World world) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RelinkDialog(projectName: 'Song.cpr', actions: world.actions),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the plan: chosen, to choose from, not found',
      (tester) async {
    final world = _World();
    await pump(tester, world);
    expect(find.text('1 of 3 files will be relinked'), findsOneWidget);
    expect(find.textContaining(r'→ C:\k\kick.wav'), findsOneWidget);
    expect(find.textContaining('Found 2 times — choose one'), findsOneWidget);
    expect(find.textContaining('Not found'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Browse…'), findsOneWidget,
        reason: 'only the file with nothing to pick from');
  });

  testWidgets('searching a folder plans again with it', (tester) async {
    final world = _World();
    await pump(tester, world);
    await tester.tap(find.text('Search a folder…'));
    await tester.pumpAndSettle();
    expect(world.calls, ['plan []', r'plan [E:\Elsewhere]']);
    expect(find.text(r'Searched: E:\Elsewhere'), findsOneWidget);
    expect(find.text('2 of 3 files will be relinked'), findsOneWidget);
  });

  testWidgets('a file picked by hand offers the same move for the others',
      (tester) async {
    final world = _World();
    await pump(tester, world);
    await tester.tap(find.widgetWithText(TextButton, 'Browse…'));
    await tester.pumpAndSettle();
    expect(world.calls.last, 'browse hat.wav');
    expect(find.textContaining('→ ${_new}hat.wav'), findsOneWidget);
    // snare.wav, still unchosen, is under the same old folder.
    expect(
      find.text(r'The same move finds 1 more file: D:\Old → E:\Backup'),
      findsOneWidget,
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.textContaining('→ ${_new}snare.wav'), findsOneWidget);
    expect(find.text('3 of 3 files will be relinked'), findsOneWidget);
  });

  testWidgets('one of several picked from the menu', (tester) async {
    final world = _World();
    await pump(tester, world);
    await tester.tap(find.byTooltip('Choose where it points').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'X:\b\snare.wav').last);
    await tester.pumpAndSettle();
    expect(find.textContaining(r'→ X:\b\snare.wav'), findsOneWidget);
  });

  testWidgets('writes the chosen moves and says what came of them',
      (tester) async {
    final world = _World();
    await pump(tester, world);
    await tester.tap(find.text('Write relinked copy'));
    await tester.pumpAndSettle();
    expect(world.written, {'${_old}kick.wav': r'C:\k\kick.wav'});
    expect(find.text('Wrote Song (relinked).cpr'), findsOneWidget);
    expect(find.text('2 files relinked'), findsOneWidget);
    expect(find.textContaining('1 not relinked: its new path is longer'),
        findsOneWidget);
    expect(find.text('  ${_old}snare.wav'), findsOneWidget);
    await tester.tap(find.text('Inspect the copy'));
    expect(world.inspected, r'D:\Old\Song\Song (relinked).cpr');
  });

  testWidgets('a copy that fails its check is reported, not kept',
      (tester) async {
    final world = _World()
      ..writeError = const RelinkCheckFailed('the copy does not read as relinked');
    await pump(tester, world);
    await tester.tap(find.text('Write relinked copy'));
    await tester.pumpAndSettle();
    expect(
      find.text("The copy didn't check out and was not kept: "
          'the copy does not read as relinked'),
      findsOneWidget,
    );
    expect(find.text('Inspect the copy'), findsNothing);
  });

  testWidgets('every tooltip shows with no node Windows rejects',
      (tester) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await pump(tester, _World());
    expect(binding.orphans, isEmpty);
    expect(await expectNoOrphanSemanticsWhileHovering(tester), greaterThan(0));
    handle.dispose();
  });
}
