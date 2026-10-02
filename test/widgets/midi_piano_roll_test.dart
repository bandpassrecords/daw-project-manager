import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/ui/midi_piano_roll_dialog.dart';
import 'package:daw_project_manager/ui/midi_preview_player.dart';
import 'package:daw_project_manager/ui/widgets/midi_piano_roll.dart';

const _labels = MidiPianoRollLabels(
  zoomIn: 'Zoom in',
  zoomOut: 'Zoom out',
  fit: 'Fit',
  follow: 'Follow',
);

MidiClip _clip({int bars = 4}) => MidiClip(
      name: 'Riff',
      trackName: 'Bass',
      ppq: 480,
      lengthTicks: bars * 1920,
      notes: [
        for (var i = 0; i < bars * 4; i++)
          MidiNote(startTick: i * 480, lengthTicks: 240, pitch: 36 + i % 7, velocity: 40 + i * 5),
      ],
    );

void main() {
  group('helpers', () {
    test('note names put middle C at C3', () {
      expect(midiNoteName(60), 'C3');
      expect(midiNoteName(61), 'C#3');
      expect(midiNoteName(0), 'C-2');
      expect(midiNoteName(127), 'G8');
    });

    test('black keys', () {
      expect([for (var p = 60; p < 72; p++) isBlackKey(p)],
          [false, true, false, true, false, false, true, false, true, false, true, false]);
    });

    test('range pads the notes and shows at least two octaves', () {
      final one = pianoRollRange(const [
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 60, velocity: 1),
      ]);
      expect(one.high - one.low + 1, 24);
      expect(one.low <= 57 && one.high >= 63, isTrue);

      final wide = pianoRollRange(const [
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 30, velocity: 1),
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 90, velocity: 1),
      ]);
      expect((wide.low, wide.high), (27, 93));
    });

    test('range never leaves the MIDI note range', () {
      final edge = pianoRollRange(const [
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 0, velocity: 1),
        MidiNote(startTick: 0, lengthTicks: 1, pitch: 127, velocity: 1),
      ]);
      expect((edge.low, edge.high), (0, 127));
      expect(pianoRollRange(const []).high - pianoRollRange(const []).low + 1, 24);
    });

    test('ticks from playback time at a tempo', () {
      // 1 s at 120 BPM is 2 beats.
      expect(ticksAt(const Duration(seconds: 1), 120, 480), 960);
      expect(ticksAt(const Duration(milliseconds: 500), 60, 960), 480);
    });

    group('followScroll keeps the playhead centred', () {
      double follow(double x) =>
          followScroll(playheadX: x, viewWidth: 1000, maxScroll: 5000);

      test('the line walks right until it reaches the middle', () {
        expect(follow(0), 0);
        expect(follow(300), 0);
        expect(follow(500), 0);
      });

      test('then the notes scroll smoothly with the line held centred', () {
        expect(follow(501), 1);
        expect(follow(2500), 2000);
        expect(follow(2500.5), 2000.5, reason: 'continuous, not paged');
      });

      test('at the end the scroll stops and the line walks to the edge', () {
        expect(follow(5500), 5000);
        expect(follow(5990), 5000);
      });

      test('a clip narrower than the view never scrolls', () {
        expect(followScroll(playheadX: 700, viewWidth: 1000, maxScroll: 0), 0);
      });
    });
  });

  group('extrapolatePosition', () {
    final at = DateTime(2026, 1, 1, 12);

    test('moves on by the time since the last report', () {
      expect(
        extrapolatePosition(const Duration(seconds: 2), at,
            at.add(const Duration(milliseconds: 150))),
        const Duration(milliseconds: 2150),
      );
    });

    test('a stalled player cannot send the playhead running off', () {
      expect(
        extrapolatePosition(Duration.zero, at, at.add(const Duration(seconds: 30))),
        const Duration(seconds: 1),
      );
    });

    test('a clock that went backwards does not move it back', () {
      expect(
        extrapolatePosition(const Duration(seconds: 1), at,
            at.subtract(const Duration(seconds: 1))),
        const Duration(seconds: 1),
      );
    });
  });

  group('MidiPianoRoll', () {
    Widget wrap(MidiClip clip, {Duration? Function()? positionOf, Listenable? playback}) =>
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: MidiPianoRoll(
                clip: clip,
                labels: _labels,
                bpm: 120,
                positionOf: positionOf,
                playback: playback,
              ),
            ),
          ),
        );

    testWidgets('draws a clip and handles zoom, fit and wheel input', (tester) async {
      await tester.pumpWidget(wrap(_clip()));
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      await tester.tap(find.byTooltip('Fit'));
      await tester.pump();

      final center = tester.getCenter(find.byType(MidiPianoRoll));
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(center));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty clip still lays out', (tester) async {
      await tester.pumpWidget(wrap(const MidiClip(name: 'x', ppq: 480, lengthTicks: 0, notes: [])));
      expect(tester.takeException(), isNull);
    });

    testWidgets('follow is on by default and can be switched off', (tester) async {
      await tester.pumpWidget(wrap(_clip()));
      IconButton followButton() => tester.widget<IconButton>(
          find.ancestor(of: find.byIcon(Icons.my_location), matching: find.byType(IconButton)));
      expect(followButton().isSelected, isTrue);
      await tester.tap(find.byTooltip('Follow'));
      await tester.pump();
      expect(tester.widgetList(find.byIcon(Icons.my_location)), isEmpty);
    });

    testWidgets('ticks only while playing', (tester) async {
      final playback = ValueNotifier(false);
      var polls = 0;
      await tester.pumpWidget(wrap(
        _clip(bars: 64),
        playback: playback,
        positionOf: () {
          polls++;
          return playback.value ? Duration(milliseconds: 100 * polls) : null;
        },
      ));
      // Silent: nothing scheduled, so the frame pump settles.
      await tester.pumpAndSettle();
      final idlePolls = polls;
      await tester.pump(const Duration(milliseconds: 100));
      expect(polls, idlePolls, reason: 'no per-frame polling while silent');

      playback.value = true;
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(polls, greaterThan(idlePolls + 2), reason: 'polled every frame while playing');

      playback.value = false;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('showMidiPianoRoll', () {
    testWidgets('shows the clip, plays through the caller, and closes', (tester) async {
      final player = MidiPreviewPlayer();
      addTearDown(player.dispose);
      var toggles = 0;
      // The window reads the shared preview volume, so it needs a scope.
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMidiPianoRoll(
                context,
                clip: _clip(),
                title: 'Bass – Riff',
                subtitle: 'Night Drive',
                player: player,
                playerKey: 'k',
                bpm: 128,
                onPlay: () => toggles++,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      )));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Bass – Riff'), findsOneWidget);
      expect(find.byType(Slider), findsWidgets, reason: 'the volume control');
      expect(find.text('Night Drive'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_circle_outline));
      expect(toggles, 1);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(MidiPianoRoll), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
