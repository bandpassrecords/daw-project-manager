import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/dialogs/color_picker_dialog.dart';
import 'package:daw_project_manager/ui/widgets/color_wheel.dart';
import 'package:daw_project_manager/utils/phase_colors.dart';

/// The color picker offers three ways in — swatches, the HSV wheel, and hex.
/// These pin that they stay in sync, which is the whole point of having all
/// three (#148).
void main() {
  // The picker is a desktop dialog: swatches, a 168px wheel, a brightness
  // slider and a hex row. At the default 800x600 test surface the dialog
  // clips and the wheel ends up outside the viewport, so a gesture aimed at
  // its centre would land on nothing. Give the tests a window the whole
  // dialog fits in.
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 1600);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  Future<Color?> openPicker(
    WidgetTester tester, {
    Color current = const Color(0xFF1E1F22),
    List<Color>? palette,
  }) async {
    Color? result;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppColorPicker(
                  context,
                  title: 'Accent',
                  current: current,
                  palette: palette,
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(closed, isFalse, reason: 'dialog should still be open');
    return result;
  }

  /// The current value of the hex field.
  String hexFieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  /// The preset swatches, scoped to their own Wrap — the dialog has plenty of
  /// other GestureDetectors (the wheel, the slider) that must not be counted.
  Finder swatches() => find.descendant(
        of: find.byType(Wrap),
        matching: find.byType(GestureDetector),
      );

  /// Drags across the wheel in steps, rather than tester.drag's single
  /// synthesized move, so every onPanUpdate the widget relies on is delivered.
  Future<void> dragWheel(WidgetTester tester, Offset by) async {
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ColorWheel)));
    for (var step = 1; step <= 4; step++) {
      await gesture.moveBy(by / 4);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('ColorWheel.colorAt', () {
    const size = 200.0;
    const centre = Offset(100, 100);
    final base = HSVColor.fromColor(const Color(0xFF808080));

    test('the centre is fully desaturated', () {
      expect(ColorWheel.colorAt(centre, size, base).saturation, 0.0);
    });

    test('the rim is fully saturated', () {
      final atRim = ColorWheel.colorAt(const Offset(200, 100), size, base);
      expect(atRim.saturation, closeTo(1.0, 0.001));
    });

    test('dragging past the rim clamps instead of stalling', () {
      // Overshooting the disc while dragging must keep tracking the hue.
      final beyond = ColorWheel.colorAt(const Offset(400, 100), size, base);
      expect(beyond.saturation, 1.0);
      expect(beyond.hue, closeTo(0.0, 0.001));
    });

    test('angle maps to hue the same way the painted sweep does', () {
      // 0° (right) is red, 90° (down, y grows downwards) is chartreuse-ish,
      // 180° (left) is cyan — matching SweepGradient's clockwise start.
      expect(ColorWheel.colorAt(const Offset(200, 100), size, base).hue,
          closeTo(0, 0.001));
      expect(ColorWheel.colorAt(const Offset(100, 200), size, base).hue,
          closeTo(90, 0.001));
      expect(ColorWheel.colorAt(const Offset(0, 100), size, base).hue,
          closeTo(180, 0.001));
    });

    test('brightness is carried over, not reset by a hue change', () {
      final dim = base.withValue(0.3);
      expect(ColorWheel.colorAt(const Offset(200, 100), size, dim).value, 0.3);
    });

    test('a point off-axis lands on the expected hue', () {
      // 45° down-right.
      final diagonal = centre + Offset(math.cos(math.pi / 4), math.sin(math.pi / 4)) * 50;
      expect(ColorWheel.colorAt(diagonal, size, base).hue, closeTo(45, 0.5));
    });
  });

  group('the three inputs stay in sync', () {
    testWidgets('the hex field starts on the incoming color', (tester) async {
      await openPicker(tester, current: const Color(0xFF1E1F22));
      expect(hexFieldText(tester), '#1E1F22');
    });

    testWidgets('dragging the wheel rewrites the hex field', (tester) async {
      await openPicker(tester, current: const Color(0xFF808080));
      final before = hexFieldText(tester);

      await dragWheel(tester, const Offset(40, 0));

      expect(hexFieldText(tester), isNot(before));
      expect(hexFieldText(tester), matches(RegExp(r'^#[0-9A-F]{6}$')));
    });

    testWidgets('typing a hex moves the wheel', (tester) async {
      await openPicker(tester, current: const Color(0xFF808080));
      final before = tester.widget<ColorWheel>(find.byType(ColorWheel)).color;

      await tester.enterText(find.byType(TextField), '#FF0000');
      await tester.pumpAndSettle();

      final after = tester.widget<ColorWheel>(find.byType(ColorWheel)).color;
      expect(after, isNot(before));
      expect(after.hue, closeTo(0, 0.001));
      expect(after.saturation, closeTo(1, 0.001));
    });

    testWidgets('a half-typed hex does not blow up or reset the wheel',
        (tester) async {
      await openPicker(tester, current: const Color(0xFFFF0000));

      await tester.enterText(find.byType(TextField), '#FF00');
      await tester.pumpAndSettle();

      // Still showing the last valid color rather than snapping to black.
      final wheel = tester.widget<ColorWheel>(find.byType(ColorWheel));
      expect(wheel.color.hue, closeTo(0, 0.001));
    });

    testWidgets('the brightness slider keeps hue and saturation', (tester) async {
      await openPicker(tester, current: const Color(0xFFFF0000));

      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(-60, 0));
      await tester.pumpAndSettle();

      final wheel = tester.widget<ColorWheel>(find.byType(ColorWheel));
      expect(wheel.color.hue, closeTo(0, 0.001));
      expect(wheel.color.saturation, closeTo(1, 0.001));
      expect(wheel.color.value, lessThan(1.0));
    });
  });

  group('confirming and dismissing', () {
    testWidgets('Apply returns the color the hex field shows', (tester) async {
      Color? picked;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await showAppColorPicker(
                    context,
                    title: 'Accent',
                    current: const Color(0xFF1E1F22),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '#00D4FF');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(picked, const Color(0xFF00D4FF));
    });

    testWidgets('an invalid hex is refused with a message, not accepted',
        (tester) async {
      await openPicker(tester);

      await tester.enterText(find.byType(TextField), 'nope');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Use #RRGGBB'), findsOneWidget);
      // Still open.
      expect(find.byType(ColorWheel), findsOneWidget);
    });

    testWidgets('tapping a preset swatch picks it outright', (tester) async {
      Color? picked;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await showAppColorPicker(
                    context,
                    title: 'Accent',
                    current: const Color(0xFF1E1F22),
                    palette: const [Color(0xFF4FC3F7), Color(0xFF66BB6A)],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(swatches().at(1));
      await tester.pumpAndSettle();

      expect(picked, const Color(0xFF66BB6A));
    });

    testWidgets('Cancel returns nothing', (tester) async {
      Color? picked;
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await showAppColorPicker(
                    context,
                    title: 'Accent',
                    current: const Color(0xFF1E1F22),
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(picked, isNull);
    });
  });

  testWidgets('defaults to the phase palette when none is given',
      (tester) async {
    await openPicker(tester);
    expect(swatches(), findsNWidgets(kPhaseColorPalette.length));
  });
}
