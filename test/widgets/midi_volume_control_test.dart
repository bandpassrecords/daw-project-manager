import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/services/player_volume_store.dart';
import 'package:daw_project_manager/ui/midi_preview_player.dart';
import 'package:daw_project_manager/ui/widgets/midi_loop_toggle.dart';
import 'package:daw_project_manager/ui/widgets/midi_volume_control.dart';

const _labels = MidiVolumeLabels(volume: 'Volume', mute: 'Mute', unmute: 'Unmute');

void main() {
  group('MidiVolumeControl', () {
    late List<double> changes;
    setUp(() => changes = []);

    Widget wrap(double volume) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: MidiVolumeControl(
                volume: volume,
                onChanged: changes.add,
                labels: _labels,
              ),
            ),
          ),
        );

    testWidgets('the slider reports the level it is dragged to', (tester) async {
      await tester.pumpWidget(wrap(0.5));
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 0.5);
      slider.onChanged!(0.8);
      expect(changes, [0.8]);
    });

    testWidgets('mute goes to zero and unmute comes back to the old level',
        (tester) async {
      await tester.pumpWidget(wrap(0.6));
      await tester.tap(find.byTooltip('Mute'));
      expect(changes, [0]);

      await tester.pumpWidget(wrap(0));
      await tester.tap(find.byTooltip('Unmute'));
      expect(changes.last, 0.6);
    });

    testWidgets('unmuting with no earlier level comes back at full', (tester) async {
      await tester.pumpWidget(wrap(0));
      await tester.tap(find.byTooltip('Unmute'));
      expect(changes, [1]);
    });

    testWidgets('Ctrl+wheel rides the level, plain wheel does not', (tester) async {
      await tester.pumpWidget(wrap(0.5));
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(tester.getCenter(find.byType(Slider))));

      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
      expect(changes, isEmpty, reason: 'plain scroll is left to the page');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(changes.single, closeTo(0.55, 1e-9));
    });
  });

  group('midiPreviewLoopProvider', () {
    test('starts at the remembered setting and follows set', () {
      MidiPreviewLoopStore.cachedForTest = true;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(midiPreviewLoopProvider), isTrue);
      container.read(midiPreviewLoopProvider.notifier).set(false);
      expect(container.read(midiPreviewLoopProvider), isFalse);
      MidiPreviewLoopStore.cachedForTest = false;
    });
  });

  group('MidiLoopToggle', () {
    testWidgets('shows the setting and flips it', (tester) async {
      final changes = <bool>[];
      Widget wrap(bool loop) => MaterialApp(
            home: Scaffold(
              body: MidiLoopToggle(
                  loop: loop, onChanged: changes.add, tooltip: 'Loop'),
            ),
          );
      await tester.pumpWidget(wrap(false));
      expect(tester.widget<IconButton>(find.byType(IconButton)).isSelected,
          isFalse);
      await tester.tap(find.byTooltip('Loop'));
      await tester.pumpWidget(wrap(true));
      expect(tester.widget<IconButton>(find.byType(IconButton)).isSelected,
          isTrue);
      await tester.tap(find.byTooltip('Loop'));
      expect(changes, [true, false]);
    });
  });

  group('MidiPreviewPlayer loop', () {
    test('switching it with nothing playing just changes the setting', () async {
      final player = MidiPreviewPlayer();
      addTearDown(player.dispose);
      var notified = 0;
      player.addListener(() => notified++);
      await player.setLoop(true);
      expect(player.loop, isTrue);
      expect(player.playingKey, isNull);
      expect(player.preparingKey, isNull, reason: 'nothing was started');
      expect(notified, 1);
      await player.setLoop(true);
      expect(notified, 1, reason: 'no change, no notification');
    });

    test('a looping position wraps round each pass', () {
      const pass = Duration(seconds: 2);
      expect(wrapLoopPosition(const Duration(milliseconds: 2500), pass),
          const Duration(milliseconds: 500));
      expect(wrapLoopPosition(const Duration(seconds: 4), pass), Duration.zero);
      expect(wrapLoopPosition(const Duration(milliseconds: 2500), null),
          const Duration(milliseconds: 2500), reason: 'not looping');
      expect(wrapLoopPosition(const Duration(seconds: 1), Duration.zero),
          const Duration(seconds: 1));
    });
  });

  group('midiPreviewVolumeProvider', () {
    test('starts at the remembered level and clamps what it is given', () {
      MidiPreviewVolumeStore.cachedForTest = 0.4;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(midiPreviewVolumeProvider), 0.4);

      container.read(midiPreviewVolumeProvider.notifier).set(1.7);
      expect(container.read(midiPreviewVolumeProvider), 1.0);
      container.read(midiPreviewVolumeProvider.notifier).set(-1);
      expect(container.read(midiPreviewVolumeProvider), 0.0);
      MidiPreviewVolumeStore.cachedForTest = 1.0;
    });
  });

  test('MidiPreviewPlayer keeps the volume it is given, clamped', () async {
    // No audio player exists until something plays, so this needs no sound.
    final player = MidiPreviewPlayer();
    addTearDown(player.dispose);
    await player.setVolume(0.3);
    expect(player.volume, 0.3);
    await player.setVolume(4);
    expect(player.volume, 1.0);
  });
}
