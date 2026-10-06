import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_clip_naming.dart';
import 'package:daw_project_manager/models/midi_collection.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';
import 'package:daw_project_manager/ui/midi_collection_naming.dart';
import 'package:daw_project_manager/ui/widgets/midi_clip_list.dart';

Widget _app(void Function(BuildContext context) open) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) =>
          TextButton(onPressed: () => open(context), child: const Text('open')),
    ),
  ),
);

const _clip = MidiClip(
  name: 'Line',
  ppq: 480,
  lengthTicks: 1920 * 4,
  notes: [MidiNote(startTick: 0, lengthTicks: 240, pitch: 36, velocity: 100)],
);

void main() {
  group('MidiNamingDialog', () {
    final item = MidiCollectionItem(
      id: 'i',
      clip: _clip,
      addedAt: DateTime.utc(2026),
      bpm: 140,
      musicalKey: 'Am',
    );

    testWidgets('the example follows every change; save returns the template', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      MidiNamingTemplate? result;
      await tester.pumpWidget(
        _app((context) async {
          final labels = midiNamingLabelsOf(AppLocalizations.of(context)!);
          result = await showDialog<MidiNamingTemplate>(
            context: context,
            builder: (_) => MidiNamingDialog(
              initial: MidiNamingTemplate.standard,
              preview: (t) => midiTemplateFileName(
                t,
                midiNameParts(item, labels: labels, voice: SynthVoice.bass),
                number: 1,
              ),
            ),
          );
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      String example() => tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('midi-naming-preview')),
          )
          .data!;
      expect(example(), '01 Line - Bass - 140BPM - Am - 4 bars.mid');

      await tester.tap(find.byKey(const ValueKey('midi-naming-numbered')));
      await tester.pump();
      Finder box(String field) => find.descendant(
        of: find.byKey(ValueKey('midi-naming-field-$field')),
        matching: find.byType(Checkbox),
      );
      await tester.tap(box('key'));
      await tester.pump();
      await tester.tap(box('grid'));
      await tester.pump();
      expect(example(), 'Line - Bass - 140BPM - 4 bars - 1-4.mid');

      await tester.tap(find.byKey(const ValueKey('midi-naming-save')));
      await tester.pumpAndSettle();
      expect(result!.numbered, isFalse);
      expect(result!.fields, [
        MidiNameField.name,
        MidiNameField.role,
        MidiNameField.bpm,
        MidiNameField.bars,
        MidiNameField.timeSignature,
        MidiNameField.grid,
      ]);
    });
  });

  group('MidiSaveClipDialog', () {
    testWidgets('name, role and folder, with the file name it will get', (
      tester,
    ) async {
      MidiSaveClipChoice? result;
      await tester.pumpWidget(
        _app((context) async {
          result = await showDialog<MidiSaveClipChoice>(
            context: context,
            builder: (_) => MidiSaveClipDialog(
              initialName: 'Idea 3',
              suggestedRole: MidiClipRole.bass,
              folders: const [(id: 'f1', name: 'Bass', depth: 0)],
              initialFolderId: 'f1',
              fileNameOf: (c) =>
                  '${c.folderId ?? 'top'}/${c.name} - ${c.role?.name ?? 'auto'}.mid',
            ),
          );
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      String fileName() => tester
          .widget<Text>(find.byKey(const ValueKey('midi-save-clip-file-name')))
          .data!;
      expect(fileName(), 'f1/Idea 3 - auto.mid');
      expect(find.text('Automatic (Bass)'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('midi-save-clip-name')),
        'Acid line',
      );
      await tester.pump();
      expect(fileName(), 'f1/Acid line - auto.mid');

      await tester.tap(find.byKey(const ValueKey('midi-save-clip-role')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lead').last);
      await tester.pumpAndSettle();
      expect(fileName(), 'f1/Acid line - lead.mid');

      await tester.tap(find.byKey(const ValueKey('midi-save-clip-save')));
      await tester.pumpAndSettle();
      expect(result!.name, 'Acid line');
      expect(result!.role, MidiClipRole.lead);
      expect(result!.folderId, 'f1');
    });

    testWidgets('a blank name cannot be saved', (tester) async {
      await tester.pumpWidget(
        _app(
          (context) => showDialog<MidiSaveClipChoice>(
            context: context,
            builder: (_) => MidiSaveClipDialog(
              initialName: 'Idea',
              suggestedRole: MidiClipRole.melody,
              folders: const [],
              fileNameOf: (c) => c.name,
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('midi-save-clip-name')),
        '  ',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('midi-save-clip-save')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.byKey(const ValueKey('midi-save-clip-folder')),
        findsNothing,
        reason: 'no folders to choose from',
      );
    });
  });

  testWidgets(
    'pickMidiFolder offers the top level and every folder but excluded',
    (tester) async {
      final c = MidiCollection(
        id: 'c',
        name: 'Pack',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        folders: const [
          MidiCollectionFolder(id: 'a', name: 'Alpha'),
          MidiCollectionFolder(id: 'b', name: 'Beta', parentId: 'a'),
          MidiCollectionFolder(id: 'g', name: 'Gamma'),
        ],
      );
      ({String? id})? result;
      await tester.pumpWidget(
        _app((context) async {
          result = await pickMidiFolder(
            context,
            c,
            exclude: c.folderAndDescendants('a'),
          );
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Top level'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsNothing);
      await tester.tap(find.text('Gamma'));
      await tester.pumpAndSettle();
      expect(result!.id, 'g');
    },
  );

  testWidgets('pickMidiClipRole: automatic comes back as a null role', (
    tester,
  ) async {
    ({MidiClipRole? role})? result;
    await tester.pumpWidget(
      _app((context) async {
        result = await pickMidiClipRole(
          context,
          current: MidiClipRole.pad,
          suggested: MidiClipRole.chords,
        );
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic (Chords)'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.role, isNull);
  });

  group('MidiClipList row actions', () {
    MidiClipListLabels labels() => MidiClipListLabels(
      play: 'Play',
      stop: 'Stop',
      save: 'Save',
      share: 'Share',
      instrument: (n) => 'Instrument: $n',
      voiceName: (v) => v.name,
      dragTooltip: 'Drag',
      bars: (n) => '$n bars',
      notes: (n) => '$n notes',
      usedTimes: (n) => '$n×',
      alsoAs: (n) => n,
      noTrack: 'No track',
      expandTrack: 'Expand',
      collapseTrack: 'Collapse',
      more: 'More',
    );

    Future<List<String>> pump(
      WidgetTester tester, {
      required bool compact,
    }) async {
      final picked = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MidiClipList(
                clips: const [_clip],
                labels: labels(),
                compact: compact,
                grouped: false,
                onPlay: (_) {},
                onShare: (_, _) {},
                voiceOf: (_) => SynthVoice.bass,
                onVoiceChanged: (_, _) {},
                titleOf: (_) => 'My name',
                fileNameOf: (_) => '01 My name - Bass.mid',
                actionsOf: (_) => [
                  MidiClipRowAction(
                    id: 'rename',
                    label: 'Rename',
                    icon: Icons.edit,
                    onSelected: () => picked.add('rename'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return picked;
    }

    for (final compact in [false, true]) {
      testWidgets(
        '${compact ? 'phone' : 'desktop'}: its own name, its file name and '
        'its actions in the menu',
        (tester) async {
          final picked = await pump(tester, compact: compact);
          expect(find.text('My name'), findsOneWidget);
          expect(find.text('Line'), findsNothing);
          expect(find.text('01 My name - Bass.mid'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('midi-row-actions-0')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('midi-row-action-rename')),
          );
          await tester.pumpAndSettle();
          expect(picked, ['rename']);
        },
      );
    }
  });
}
