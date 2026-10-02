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

const _clip = MidiClip(
  name: 'Riff',
  ppq: 480,
  lengthTicks: 1920,
  notes: [MidiNote(startTick: 0, lengthTicks: 240, pitch: 60, velocity: 100)],
);

String _laneName(MidiLane lane) => lane.toString();

const _labels = MidiPianoRollWindowLabels(
  roll: MidiPianoRollLabels(
    zoomIn: 'In',
    zoomOut: 'Out',
    fit: 'Fit',
    follow: 'Follow',
    lane: 'Lane',
    laneNone: 'None',
    laneName: _laneName,
  ),
  close: 'Close',
  play: 'Play',
  pause: 'Pause',
  stop: 'Stop',
  openProject: 'Open project',
);

void main() {
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
                        onPlay: () => plays++,
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
