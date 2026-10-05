import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/midi_piano_roll_dialog.dart';
import 'package:daw_project_manager/utils/midi_edit_hints.dart';

void main() {
  MidiEditHint? next({
    bool pencil = false,
    MidiHoverArea hover = MidiHoverArea.none,
    bool hasSelection = false,
    Set<MidiEditHint> learned = const {},
    bool keyboard = true,
  }) =>
      nextMidiEditHint(
        pencil: pencil,
        hover: hover,
        hasSelection: hasSelection,
        learned: learned,
        keyboard: keyboard,
      );

  group('nextMidiEditHint', () {
    test('with the select tool: the pencil first, then double-click, then '
        'the selection box, one after another', () {
      expect(next(), MidiEditHint.pencil);
      expect(next(learned: {MidiEditHint.pencil}), MidiEditHint.doubleClick);
      expect(next(learned: {MidiEditHint.pencil, MidiEditHint.doubleClick}),
          MidiEditHint.boxSelect);
      expect(
          next(learned: {
            MidiEditHint.pencil,
            MidiEditHint.doubleClick,
            MidiEditHint.boxSelect,
          }),
          isNull,
          reason: 'nothing left to teach here');
    });

    test('notes selected: moving them by key comes first', () {
      expect(next(hasSelection: true), MidiEditHint.transpose);
      expect(next(hasSelection: true, learned: {MidiEditHint.transpose}),
          MidiEditHint.altCopy);
    });

    test('over a note: Ctrl for off the grid', () {
      expect(next(hover: MidiHoverArea.note), MidiEditHint.ctrlFree);
    });

    test('a phone gets no hints about keys', () {
      expect(next(hasSelection: true, hover: MidiHoverArea.note, keyboard: false),
          MidiEditHint.pencil);
    });

    test('with the pencil: drawing, and erasing over a note', () {
      expect(next(pencil: true), MidiEditHint.pencilDraw);
      expect(next(pencil: true, hover: MidiHoverArea.note),
          MidiEditHint.pencilErase);
      expect(
          next(
              pencil: true,
              hover: MidiHoverArea.note,
              learned: {MidiEditHint.pencilErase}),
          MidiEditHint.pencilDraw);
      expect(next(pencil: true, learned: {MidiEditHint.pencilDraw}), isNull);
    });

    test('what is under the pointer wins: an edge, a lane', () {
      expect(next(hover: MidiHoverArea.noteEdge, pencil: true),
          MidiEditHint.resize);
      expect(next(hover: MidiHoverArea.velocityLane), MidiEditHint.velocity);
      expect(next(hover: MidiHoverArea.pitchBendLane), MidiEditHint.pitchBend);
      expect(next(hover: MidiHoverArea.controllerLane), MidiEditHint.lane);
      expect(
          next(hover: MidiHoverArea.velocityLane, learned: {MidiEditHint.velocity}),
          isNull,
          reason: 'over a lane, only the lane hint fits');
    });
  });

  group('MidiEditHints', () {
    test('learns once, tells and remembers', () {
      final told = <Set<MidiEditHint>>[];
      var notified = 0;
      final hints = MidiEditHints(
          learned: {MidiEditHint.lane}, onChanged: told.add)
        ..addListener(() => notified++);
      hints.learn(MidiEditHint.pencil);
      hints.learn(MidiEditHint.pencil);
      hints.learn(MidiEditHint.lane);
      expect(hints.learned, {MidiEditHint.lane, MidiEditHint.pencil});
      expect(told, [
        {MidiEditHint.lane, MidiEditHint.pencil}
      ]);
      expect(notified, 1);
    });
  });

  group('storing learned hints', () {
    test('round-trips', () {
      final hints = {MidiEditHint.velocity, MidiEditHint.pencil};
      expect(encodeMidiEditHints(hints), 'pencil,velocity');
      expect(decodeMidiEditHints(encodeMidiEditHints(hints)), hints);
    });

    test('nothing stored, or names this build no longer has', () {
      expect(decodeMidiEditHints(null), isEmpty);
      expect(decodeMidiEditHints(''), isEmpty);
      expect(decodeMidiEditHints('retired, resize'), {MidiEditHint.resize});
    });
  });

  test('every hint has something to say, keys named', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final hint in MidiEditHint.values) {
      final text = midiEditHintText(l10n, hint);
      expect(text, isNotEmpty, reason: hint.name);
      expect(text, isNot(contains('{key}')), reason: hint.name);
    }
    expect(midiEditHintText(l10n, MidiEditHint.ctrlFree), contains('Ctrl'));
  });
}
