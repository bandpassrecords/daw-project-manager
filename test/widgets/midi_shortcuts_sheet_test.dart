import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/services/midi/synth_voice.dart';
import 'package:daw_project_manager/ui/midi_piano_roll_dialog.dart';
import 'package:daw_project_manager/ui/midi_preview_player.dart';
import 'package:daw_project_manager/ui/widgets/midi_shortcuts_sheet.dart';

void main() {
  group('midiShortcutSections', () {
    late AppLocalizations l10n;
    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    List<MidiShortcut> all({required bool mac}) => [
          for (final s in midiShortcutSections(l10n, mac: mac)) ...s.shortcuts,
        ];

    test('every row says what to press and what it does', () {
      for (final section in midiShortcutSections(l10n, mac: false)) {
        expect(section.title, isNotEmpty);
        expect(section.shortcuts, isNotEmpty, reason: section.title);
        for (final s in section.shortcuts) {
          expect(s.action, isNotEmpty);
          expect(s.keys, isNotEmpty, reason: s.action);
          expect(s.keys.every((k) => k.isNotEmpty), isTrue, reason: s.action);
        }
      }
    });

    test("covers the tools' keys, transposing, undo and the sheet itself", () {
      final keys = [for (final s in all(mac: false)) s.keys.join('+')];
      expect(keys,
          containsAll(['1', '2', '5', '8', '↑ / ↓', 'Shift+↑ / ↓', 'Ctrl+Z', 'Ctrl+D', '?']));
      expect([for (final s in all(mac: true)) s.keys.join('+')], contains('⌘+D'),
          reason: 'Cmd on a Mac');
    });

    test('keys are named as a Mac prints them on a Mac', () {
      final mac = [for (final s in all(mac: true)) ...s.keys];
      expect(mac, containsAll(['⌘', '⌥', '⇧', '⌫']));
      expect(mac, isNot(contains('Ctrl')));
      expect([for (final s in all(mac: false)) ...s.keys],
          containsAll(['Ctrl', 'Alt', 'Shift', 'Delete']));
    });
  });

  testWidgets('the sheet lists its sections and keys, and closes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const MidiShortcutsSheet(
              title: 'Shortcuts',
              close: 'Close',
              sections: [
                MidiShortcutSection('Tools', [
                  MidiShortcut(['8'], 'Pencil'),
                ]),
                MidiShortcutSection('Editing', [
                  MidiShortcut(['Ctrl', 'Z'], 'Undo'),
                ]),
              ],
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    for (final text in ['Shortcuts', 'Tools', 'Editing', 'Pencil', 'Undo']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.byType(MidiKeycap), findsNWidgets(3));
    expect(find.text('+'), findsOneWidget, reason: 'Ctrl + Z');

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(MidiShortcutsSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('an edit taking over playback', () {
    const clip = MidiClip(
      name: 'Riff',
      ppq: 480,
      lengthTicks: 1920,
      notes: [MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100)],
    );

    test('keeps what plays playing while it renders: no flicker', () async {
      final player = MidiPreviewPlayer()..playingKey = 'k~edit';
      addTearDown(player.dispose);
      var notified = 0;
      player.addListener(() => notified++);
      final done = player.play('k~edit', clip,
          voice: SynthVoice.keys, takeOver: true);
      expect(player.preparingKey, isNull);
      expect(player.playingKey, 'k~edit');
      expect(notified, 0, reason: 'the transport is not told to change');
      await done.catchError((Object _) {});
    });

    test('a plain play still shows it is preparing', () async {
      final player = MidiPreviewPlayer()..playingKey = 'k~edit';
      addTearDown(player.dispose);
      final done = player.play('k~edit', clip, voice: SynthVoice.keys);
      expect(player.preparingKey, 'k~edit');
      await done.catchError((Object _) {});
    });

    test('nothing playing (or paused): takeover is an ordinary play',
        () async {
      final player = MidiPreviewPlayer();
      addTearDown(player.dispose);
      final done = player.play('k', clip,
          voice: SynthVoice.keys, takeOver: true);
      expect(player.preparingKey, 'k');
      await done.catchError((Object _) {});
    });
  });
}
