import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/player_readout.dart';

/// The player bar's clock and file details. Sized to their text, they grew
/// the moment a file's length or details loaded, shoving the track name beside
/// them sideways on every play.
void main() {
  const templates = ['00:00:00 / 00:00:00'];
  const placeholder = ValueKey('playerReadoutPlaceholder');

  Widget host(String? text, {List<String> templates = templates}) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayerReadout(
              key: const ValueKey('readout'),
              text: text,
              templates: templates,
              loadingLabel: 'Loading...',
            ),
          ),
        ),
      );

  Size readoutSize(WidgetTester tester) =>
      tester.getSize(find.byKey(const ValueKey('readout')));

  testWidgets('holds a placeholder, not 00:00, until the text is known',
      (tester) async {
    await tester.pumpWidget(host(null));

    expect(find.byKey(placeholder), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(find.bySemanticsLabel('Loading...'), findsOneWidget);
  });

  testWidgets('keeps one size from loading to loaded', (tester) async {
    await tester.pumpWidget(host(null));
    final loading = readoutSize(tester);

    await tester.pumpWidget(host('01:05 / 04:00'));
    final short = readoutSize(tester);

    await tester.pumpWidget(host('01:12:00 / 01:30:00'));
    final long = readoutSize(tester);

    expect(loading.width, greaterThan(0));
    expect(short, loading);
    expect(long, loading);
    expect(find.byKey(placeholder), findsNothing);
    expect(find.text('01:12:00 / 01:30:00'), findsOneWidget);
  });

  testWidgets('is as wide as the widest template', (tester) async {
    await tester.pumpWidget(host(null, templates: const ['WAV']));
    final narrow = readoutSize(tester).width;

    await tester.pumpWidget(
        host(null, templates: const ['WAV', '44.1kHz · 24-bit · Stereo']));
    expect(readoutSize(tester).width, greaterThan(narrow));
  });

  testWidgets('cuts text longer than every template instead of growing',
      (tester) async {
    await tester.pumpWidget(host(null, templates: const ['00:00']));
    final slot = readoutSize(tester);

    await tester.pumpWidget(
        host('far longer than the slot', templates: const ['00:00']));

    expect(readoutSize(tester), slot);
    expect(tester.takeException(), isNull);
  });
}
