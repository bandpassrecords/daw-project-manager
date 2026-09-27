import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/ctrl_wheel_volume.dart';

void main() {
  group('volumeAfterScroll', () {
    test('scrolling up (negative delta) raises the volume', () {
      expect(volumeAfterScroll(0.5, -100), closeTo(0.55, 1e-9));
    });

    test('scrolling down (positive delta) lowers the volume', () {
      expect(volumeAfterScroll(0.5, 100), closeTo(0.45, 1e-9));
    });

    test('a larger scroll moves proportionally further', () {
      expect(volumeAfterScroll(0.5, -300), closeTo(0.65, 1e-9));
    });

    test('a partial notch moves a partial step', () {
      expect(volumeAfterScroll(0.5, -50), closeTo(0.525, 1e-9));
    });

    test('clamps at 1.0 instead of drifting above it', () {
      expect(volumeAfterScroll(0.98, -100), 1.0);
      expect(volumeAfterScroll(1.0, -1000), 1.0);
    });

    test('clamps at 0.0 instead of going negative', () {
      expect(volumeAfterScroll(0.02, 100), 0.0);
      expect(volumeAfterScroll(0.0, 1000), 0.0);
    });

    test('a zero delta leaves the volume alone', () {
      expect(volumeAfterScroll(0.42, 0), 0.42);
    });

    test('a zero delta still clamps an out-of-range starting value', () {
      expect(volumeAfterScroll(1.7, 0), 1.0);
    });

    test('honours a custom step', () {
      expect(volumeAfterScroll(0.5, -100, step: 0.25), closeTo(0.75, 1e-9));
    });

    test('can come back up from a muted player', () {
      // The mute button parks the level at 0; the wheel has to be able to
      // lift it again rather than being stuck there.
      expect(volumeAfterScroll(0.0, -100), closeTo(0.05, 1e-9));
    });
  });

  group('CtrlWheelVolume', () {
    // Keyed so the finder can't pick up one of the boxes Scaffold and
    // MaterialApp put in the tree around it.
    const playerArea = Key('player-area');

    /// Sends one wheel notch over the widget. Returns nothing — assertions
    /// read the captured callback values.
    Future<void> scrollOver(WidgetTester tester, Offset at, double dy) async {
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(at);
      await tester.sendEventToBinding(
        pointer.scroll(Offset(0, dy)),
      );
      await tester.pump();
    }

    Future<void> pumpTarget(
      WidgetTester tester, {
      required double volume,
      required ValueChanged<double> onChanged,
      bool enabled = true,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CtrlWheelVolume(
                volume: volume,
                onVolumeChanged: onChanged,
                enabled: enabled,
                child: const SizedBox(
                  key: playerArea,
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ),
        ),
      );
    }

    /// Holds [key] down for the duration of [body], then releases it.
    ///
    /// Releasing unconditionally in a tearDown trips HardwareKeyboard's
    /// "key was not pressed" assertion for the tests that never press one, so
    /// the press and the release are paired here instead.
    Future<void> holdingKey(
      LogicalKeyboardKey key,
      Future<void> Function() body,
    ) async {
      await simulateKeyDownEvent(key);
      try {
        await body();
      } finally {
        await simulateKeyUpEvent(key);
      }
    }

    testWidgets('ctrl+wheel up raises the volume', (tester) async {
      double? received;
      await pumpTarget(
        tester,
        volume: 0.5,
        onChanged: (v) => received = v,
      );

      await holdingKey(
        LogicalKeyboardKey.controlLeft,
        () => scrollOver(
            tester, tester.getCenter(find.byKey(playerArea)), -100),
      );

      expect(received, closeTo(0.55, 1e-9));
    });

    testWidgets('ctrl+wheel down lowers the volume', (tester) async {
      double? received;
      await pumpTarget(tester, volume: 0.5, onChanged: (v) => received = v);

      await holdingKey(
        LogicalKeyboardKey.controlLeft,
        () =>
            scrollOver(tester, tester.getCenter(find.byKey(playerArea)), 100),
      );

      expect(received, closeTo(0.45, 1e-9));
    });

    testWidgets('cmd+wheel works too, for macOS', (tester) async {
      double? received;
      await pumpTarget(tester, volume: 0.5, onChanged: (v) => received = v);

      await holdingKey(
        LogicalKeyboardKey.metaLeft,
        () => scrollOver(
            tester, tester.getCenter(find.byKey(playerArea)), -100),
      );

      expect(received, closeTo(0.55, 1e-9));
    });

    testWidgets('a plain wheel scroll is ignored', (tester) async {
      // Without the modifier the wheel must still scroll whatever the player
      // sits inside, not silently change the volume.
      double? received;
      await pumpTarget(tester, volume: 0.5, onChanged: (v) => received = v);

      await scrollOver(tester, tester.getCenter(find.byKey(playerArea)), -100);

      expect(received, isNull);
    });

    testWidgets('fires nothing when the volume is already at the ceiling',
        (tester) async {
      double? received;
      await pumpTarget(tester, volume: 1.0, onChanged: (v) => received = v);

      await holdingKey(
        LogicalKeyboardKey.controlLeft,
        () => scrollOver(
            tester, tester.getCenter(find.byKey(playerArea)), -100),
      );

      expect(received, isNull);
    });

    testWidgets('does nothing when disabled (mobile)', (tester) async {
      double? received;
      await pumpTarget(
        tester,
        volume: 0.5,
        onChanged: (v) => received = v,
        enabled: false,
      );

      await holdingKey(
        LogicalKeyboardKey.controlLeft,
        () => scrollOver(
            tester, tester.getCenter(find.byKey(playerArea)), -100),
      );

      expect(received, isNull);
    });

    testWidgets('renders its child unchanged when disabled', (tester) async {
      await pumpTarget(
        tester,
        volume: 0.5,
        onChanged: (_) {},
        enabled: false,
      );
      expect(find.byKey(playerArea), findsOneWidget);
    });

    group('inside a scrolling page', () {
      // The project and release pages both scroll. A Listener alone sees the
      // wheel but does not stop the scroll view acting on it too, so
      // ctrl+wheel used to change the volume and scroll the player away.
      Future<ScrollController> pumpInScrollView(
        WidgetTester tester, {
        required double volume,
        required ValueChanged<double> onChanged,
      }) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                controller: controller,
                children: [
                  CtrlWheelVolume(
                    volume: volume,
                    onVolumeChanged: onChanged,
                    child: const SizedBox(
                      key: playerArea,
                      width: 200,
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 3000),
                ],
              ),
            ),
          ),
        );
        return controller;
      }

      testWidgets('ctrl+wheel changes the volume and does not scroll',
          (tester) async {
        double? received;
        final controller = await pumpInScrollView(
          tester,
          volume: 0.5,
          onChanged: (v) => received = v,
        );

        await holdingKey(
          LogicalKeyboardKey.controlLeft,
          () => scrollOver(
              tester, tester.getCenter(find.byKey(playerArea)), 100),
        );
        await tester.pumpAndSettle();

        expect(received, closeTo(0.45, 1e-9));
        expect(controller.offset, 0,
            reason: 'the page must stay put under the player');
      });

      testWidgets('a plain wheel still scrolls the page', (tester) async {
        double? received;
        final controller = await pumpInScrollView(
          tester,
          volume: 0.5,
          onChanged: (v) => received = v,
        );

        await scrollOver(tester, tester.getCenter(find.byKey(playerArea)), 100);
        await tester.pumpAndSettle();

        expect(received, isNull);
        expect(controller.offset, greaterThan(0));
      });
    });
  });
}
