import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/now_playing_icon.dart';

void main() {
  const green = Color(0xFF4CAF50);
  final bars = find.byKey(const ValueKey('now-playing-bars'));

  Widget host({required bool isPlaying}) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: IconButton(
              icon: NowPlayingIcon(
                isPlaying: isPlaying,
                idleIcon: Icons.play_circle,
              ),
              iconSize: 24,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              color: green,
              onPressed: () {},
            ),
          ),
        ),
      );

  testWidgets('an idle row shows the play icon', (tester) async {
    await tester.pumpWidget(host(isPlaying: false));

    expect(find.byIcon(Icons.play_circle), findsOneWidget);
    expect(bars, findsNothing);
  });

  testWidgets('a playing row shows the bouncing bars instead',
      (tester) async {
    await tester.pumpWidget(host(isPlaying: true));

    expect(bars, findsOneWidget);
    expect(find.byIcon(Icons.play_circle), findsNothing);
    expect(find.byIcon(Icons.pause_circle), findsNothing);
  });

  testWidgets('the bars take the button colour and size', (tester) async {
    await tester.pumpWidget(host(isPlaying: true));

    final painter =
        tester.widget<CustomPaint>(bars).painter! as NowPlayingBarsPainter;
    expect(painter.color, green);
    expect(tester.getSize(bars), const Size(24, 24));
  });

  testWidgets('the button stays the same size while playing', (tester) async {
    await tester.pumpWidget(host(isPlaying: false));
    final idle = tester.getSize(find.byType(IconButton));

    await tester.pumpWidget(host(isPlaying: true));

    expect(tester.getSize(find.byType(IconButton)), idle);
  });

  testWidgets('hovering a playing row shows what a click does: pause',
      (tester) async {
    await tester.pumpWidget(host(isPlaying: true));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(bars));
    await tester.pump();

    expect(find.byIcon(Icons.pause_circle), findsOneWidget);
    expect(bars, findsNothing);

    await mouse.moveTo(Offset.zero);
    await tester.pump();

    expect(bars, findsOneWidget);
  });

  testWidgets('the bars move', (tester) async {
    await tester.pumpWidget(host(isPlaying: true));
    final painter =
        tester.widget<CustomPaint>(bars).painter! as NowPlayingBarsPainter;
    final before = painter.progress.value;

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(painter.progress.value, isNot(before));
  });

  testWidgets('stopping playback stops the animation', (tester) async {
    await tester.pumpWidget(host(isPlaying: true));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(host(isPlaying: false));
    await tester.pump();

    expect(bars, findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('barHeight', () {
    test('never lets a bar vanish or overflow', () {
      for (var bar = 0; bar < 3; bar++) {
        for (var step = 0; step <= 100; step++) {
          final h = NowPlayingBarsPainter.barHeight(bar, step / 100);
          expect(h, inInclusiveRange(0.3, 1.0));
        }
      }
    });

    test('loops seamlessly', () {
      for (var bar = 0; bar < 3; bar++) {
        expect(NowPlayingBarsPainter.barHeight(bar, 1.0),
            closeTo(NowPlayingBarsPainter.barHeight(bar, 0.0), 1e-9));
      }
    });

    test('the bars do not move in step', () {
      final heights = [
        for (var bar = 0; bar < 3; bar++)
          NowPlayingBarsPainter.barHeight(bar, 0.1),
      ];
      expect(heights.toSet(), hasLength(3));
    });
  });
}
