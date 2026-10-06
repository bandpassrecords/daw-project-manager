import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/ui/midi_clip_share.dart';
import 'package:daw_project_manager/ui/midi_piano_roll_dialog.dart';
import 'package:daw_project_manager/ui/midi_preview_player.dart';
import 'package:daw_project_manager/ui/widgets/midi_piano_roll.dart';
import 'package:daw_project_manager/utils/musical_scale.dart';
import 'package:daw_project_manager/ui/widgets/midi_volume_control.dart';

const _clip = MidiClip(
  name: 'Riff',
  ppq: 480,
  lengthTicks: 1920,
  notes: [MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100)],
);

String _laneName(MidiLane lane) => lane.toString();

String _scaleTypeName(ScaleType type) => type.name;

const _labels = MidiPianoRollWindowLabels(
  roll: MidiPianoRollLabels(
    zoomIn: 'In',
    zoomOut: 'Out',
    fit: 'Fit',
    follow: 'Follow',
    lane: 'Lane',
    laneNone: 'None',
    laneName: _laneName,
    scale: 'Scale',
    scaleNone: 'No scale',
    scaleRoot: 'Root',
    scaleType: 'Type',
    scaleTypeName: _scaleTypeName,
  ),
  close: 'Close',
  play: 'Play',
  pause: 'Pause',
  stop: 'Stop',
  openProject: 'Open project',
);

void main() {
  group('MidiPreviewPlayer seek', () {
    test('jumps the playing clip, paused or not', () async {
      final player = MidiPreviewPlayer()..playingKey = 'k';
      addTearDown(player.dispose);
      await player.seek('k', const Duration(seconds: 3));
      expect(player.positionOf('k')!.inMilliseconds, closeTo(3000, 50));

      await player.pause();
      await player.seek('k', const Duration(milliseconds: 500));
      expect(player.positionOf('k'), const Duration(milliseconds: 500));
      await player.seek('k', const Duration(seconds: -1));
      expect(player.positionOf('k'), Duration.zero);
    });

    test('ignores a clip that is not the one playing', () async {
      final player = MidiPreviewPlayer()..playingKey = 'k';
      addTearDown(player.dispose);
      await player.pause();
      final before = player.positionOf('k');
      await player.seek('other', const Duration(seconds: 3));
      expect(player.positionOf('k'), before);
    });

    test('startAt is remembered for that clip only', () {
      final player = MidiPreviewPlayer();
      addTearDown(player.dispose);
      player.startAt('k', const Duration(seconds: 2));
      expect(player.pendingStartFor('k'), const Duration(seconds: 2));
      expect(player.pendingStartFor('other'), isNull);
    });
  });

  group('MidiPreviewPlayer pause', () {
    // The audio player is only created by play(), so these drive the state
    // machine without any sound.
    test('freezes the position while paused and moves on after resume', () async {
      final player = MidiPreviewPlayer()..playingKey = 'k';
      addTearDown(player.dispose);

      await player.pause();
      expect(player.paused, isTrue);
      final frozen = player.positionOf('k');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(player.positionOf('k'), frozen, reason: 'paused: no extrapolation');

      await player.resume();
      expect(player.paused, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(player.positionOf('k')! > frozen!, isTrue);
    });

    test('stop clears the pause', () async {
      final player = MidiPreviewPlayer()..playingKey = 'k';
      addTearDown(player.dispose);
      await player.pause();
      await player.stop();
      expect(player.paused, isFalse);
      expect(player.positionOf('k'), isNull);
    });
  });

  group('MidiPianoRollWindow', () {
    late MidiPreviewPlayer player;
    late int plays, opens;

    setUp(() {
      player = MidiPreviewPlayer();
      plays = opens = 0;
    });

    tearDown(() => player.dispose());

    Widget app({bool withActions = true}) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    child: SizedBox(
                      width: 700,
                      height: 450,
                      child: MidiPianoRollWindow(
                        clip: _clip,
                        title: 'Riff',
                        subtitle: 'Song',
                        player: player,
                        playerKey: 'k',
                        bpm: 120,
                        labels: _labels,
                        onPlay: (_, __) => plays++,
                        onOpenProject: withActions ? () => opens++ : null,
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );

    Future<void> open(WidgetTester tester, {bool withActions = true}) async {
      await tester.pumpWidget(app(withActions: withActions));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('Space starts, pauses and resumes', (tester) async {
      await open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(plays, 1, reason: 'not playing yet: start through the caller');

      player.playingKey = 'k'; // the caller's play() took effect
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(player.paused, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(player.paused, isFalse);
      expect(plays, 1);
      await player.stop();
      await tester.pumpAndSettle();
    });

    // The clip is one 4/4 bar at 120 BPM: the ruler's middle is 1 second.
    Offset rulerMiddle(WidgetTester tester) =>
        tester.getCenter(find.byKey(const ValueKey('midi-piano-roll-ruler')));

    testWidgets('clicking the ruler while stopped moves the start, plays nothing',
        (tester) async {
      await open(tester);
      await tester.tapAt(rulerMiddle(tester));
      await tester.pump();
      expect(plays, 0, reason: 'a click on the ruler never starts playback');

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(plays, 1);
      expect(player.pendingStartFor('k')!.inMilliseconds, closeTo(1000, 5),
          reason: 'play starts where the ruler was clicked');
    });

    testWidgets('clicking the ruler while playing jumps there', (tester) async {
      await open(tester);
      player.playingKey = 'k';
      await player.pause();
      await tester.pump();
      await tester.tapAt(rulerMiddle(tester));
      await tester.pump();
      expect(plays, 0, reason: 'already playing: no restart');
      expect(player.positionOf('k')!.inMilliseconds, closeTo(1000, 5));
      await player.stop();
      await tester.pumpAndSettle();
    });

    testWidgets('stop shows only while this clip plays', (tester) async {
      await open(tester);
      expect(find.byTooltip('Stop'), findsNothing);
      player.playingKey = 'k';
      player.notifyListeners();
      await tester.pump();
      expect(find.byTooltip('Pause'), findsOneWidget);
      await tester.tap(find.byTooltip('Stop'));
      await tester.pumpAndSettle();
      expect(player.playingKey, isNull);
    });

    testWidgets('Esc stops a playing clip first, then closes the window',
        (tester) async {
      await open(tester);
      player.playingKey = 'k';
      await player.pause(); // paused still counts as this clip's playback
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(player.playingKey, isNull);
      expect(find.byType(MidiPianoRollWindow), findsOneWidget,
          reason: 'stopping is all the first Esc does');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MidiPianoRollWindow), findsNothing);
    });

    testWidgets('Esc leaves another clip\'s playback alone and just closes',
        (tester) async {
      await open(tester);
      player.playingKey = 'other';
      await player.pause();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MidiPianoRollWindow), findsNothing);
      expect(player.playingKey, 'other');
      await player.stop();
    });

    testWidgets('open project closes the window first', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Open project'));
      await tester.pumpAndSettle();
      expect(opens, 1);
      expect(find.byType(MidiPianoRollWindow), findsNothing);
    });

    testWidgets('open project is hidden when not offered', (tester) async {
      await open(tester, withActions: false);
      expect(find.byTooltip('Open project'), findsNothing);
    });
  });

  group('header layout', () {
    test('stacks below 600 pixels wide', () {
      expect(pianoRollHeaderStacked(360), isTrue);
      expect(pianoRollHeaderStacked(999), isTrue);
      expect(pianoRollHeaderStacked(1000), isFalse);
      expect(pianoRollHeaderStacked(1200), isFalse);
    });

    const longTitle = 'Lead Synth Arp – Chorus Variation With A Long Name';

    Future<void> pumpAt(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final player = MidiPreviewPlayer();
      addTearDown(player.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MidiPianoRollWindow(
            clip: _clip,
            title: longTitle,
            subtitle: 'Night Drive (Extended Mix) – Final Version',
            player: player,
            playerKey: 'k',
            bpm: 120,
            labels: _labels,
            onPlay: (_, __) {},
            onOpenProject: () {},
            volume: 0.8,
            onVolumeChanged: (_) {},
            volumeLabels: const MidiVolumeLabels(
                volume: 'Volume', mute: 'Mute', unmute: 'Unmute'),
            loop: false,
            onLoopChanged: (_) {},
            loopTooltip: 'Loop',
          ),
        ),
      ));
    }

    Text title(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const ValueKey('midi-piano-roll-title')));

    testWidgets('on a phone the title gets a line of its own, two lines deep',
        (tester) async {
      await pumpAt(tester, 360);
      expect(title(tester).maxLines, 2);
      final width =
          tester.getSize(find.byKey(const ValueKey('midi-piano-roll-title'))).width;
      expect(width, greaterThan(250),
          reason: 'not squeezed between the controls any more');
      expect(tester.takeException(), isNull);
    });

    testWidgets('even the narrowest phone does not overflow', (tester) async {
      await pumpAt(tester, 320);
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Loop'), findsOneWidget);
      expect(find.byTooltip('Open project'), findsOneWidget);
    });

    testWidgets('a wide window keeps the single row', (tester) async {
      await pumpAt(tester, 1200);
      expect(title(tester).maxLines, 1);
      final titleTop =
          tester.getTopLeft(find.byKey(const ValueKey('midi-piano-roll-title'))).dy;
      final closeTop = tester.getTopLeft(find.byTooltip('Close')).dy;
      final loopTop = tester.getTopLeft(find.byTooltip('Loop')).dy;
      expect((loopTop - closeTop).abs(), lessThan(1),
          reason: 'controls share the row with the close button');
      expect(titleTop, lessThan(closeTop + 40));
    });
  });

  group('open-ended playback', () {
    const draft = MidiClip(
      name: 'Idea',
      ppq: 480,
      lengthTicks: 1920,
      notes: [MidiNote(startTick: 5000, lengthTicks: 240, pitch: 60, velocity: 90)],
    );

    test('renders past the last note, and never back', () {
      expect(openEndedHorizon(draft, current: 0, step: 15360), 5240 + 15360);
      expect(openEndedHorizon(draft, current: 40000, step: 15360), 40000,
          reason: 'what was reached stays reached');
      const empty = MidiClip(name: 'x', ppq: 480, lengthTicks: 1920, notes: []);
      expect(openEndedHorizon(empty, current: 0, step: 15360), 15360);
    });

    test('renders further a few seconds before the end', () {
      const rendered = Duration(seconds: 16);
      expect(needsLongerHorizon(const Duration(seconds: 12), rendered), isFalse);
      expect(needsLongerHorizon(const Duration(seconds: 13), rendered), isTrue);
      expect(needsLongerHorizon(null, rendered), isFalse);
    });
  });

  test('zipMidiFiles packs the files under a filesystem-safe name', () async {
    final dir = await Directory.systemTemp.createTemp('midi_zip_');
    addTearDown(() => dir.delete(recursive: true));
    final a = File('${dir.path}/A.mid')..writeAsBytesSync([1, 2, 3]);
    final b = File('${dir.path}/B.mid')..writeAsBytesSync([4, 5]);

    final zip = await zipMidiFiles([a, b], dir, 'Bass: lines?');

    expect(zip.uri.pathSegments.last, 'Bass_ lines_.zip');
    final archive = ZipDecoder().decodeBytes(zip.readAsBytesSync());
    expect(archive.files.map((f) => f.name), ['A.mid', 'B.mid']);
    expect(archive.findFile('B.mid')!.content, [4, 5]);
  });
}
