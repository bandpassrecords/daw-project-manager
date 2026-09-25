import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/widgets/project_cover_avatar.dart';
import 'package:daw_project_manager/utils/project_visuals.dart';

import '../helpers/test_factories.dart';

Future<void> _pump(
  WidgetTester tester,
  MusicProject project, {
  double size = 40,
  VoidCallback? onTap,
  bool showEmptyPlaceholder = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ProjectCoverAvatar(
            project: project,
            size: size,
            onTap: onTap,
            showEmptyPlaceholder: showEmptyPlaceholder,
          ),
        ),
      ),
    ),
  );
}

/// Pumps the avatar for a project whose cover path does not resolve, letting
/// the real file read fail so `errorBuilder` runs before the expectations do.
Future<void> _pumpWithRealImageIo(
  WidgetTester tester,
  MusicProject project, {
  bool showEmptyPlaceholder = false,
}) async {
  await tester.runAsync(() async {
    await _pump(
      tester,
      project,
      showEmptyPlaceholder: showEmptyPlaceholder,
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
}

/// #110 — the avatar draws a project's identity, and its central rule is that
/// there is no identity until someone picks one. A list row must come out
/// empty; only the editing surfaces get the "add one" affordance.
///
/// **Not automatable here:** the success path, where a cover that really
/// decodes renders as an `Image`. `Image.file` over a file that exists never
/// finishes decoding under this project's test binding — a bare
/// `pumpWidget(Image.file(realFile))` hangs until the test times out, with or
/// without `runAsync`. The decision feeding it, [projectHasCoverArt], is
/// unit-tested in `test/utils/project_visuals_test.dart` instead; that the
/// widget then builds an `Image` from it needs a manual check.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cover_avatar_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  testWidgets('an undecorated project renders nothing at all', (tester) async {
    await _pump(tester, TestFactories.makeProject(id: 'plain'));

    expect(find.byType(Icon), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(
      tester.getSize(find.byType(ProjectCoverAvatar)),
      Size.zero,
      reason: 'an undecorated row must not even reserve space',
    );
  });

  testWidgets('a chosen colour and icon paint the badge', (tester) async {
    final project = TestFactories.makeProject(
      id: 'decorated',
      accentColor: 0xFF123456,
      iconKey: 'mic',
    );
    await _pump(tester, project);

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, const Color(0xFF123456));
    expect(icon.icon, kProjectIconChoices['mic']);
  });

  testWidgets('a colour on its own is a plain swatch, no invented icon',
      (tester) async {
    await _pump(
      tester,
      TestFactories.makeProject(id: 'colour-only', accentColor: 0xFF123456),
    );

    expect(find.byType(Icon), findsNothing);
    expect(
      tester.getSize(find.byType(ProjectCoverAvatar)),
      const Size(40, 40),
      reason: 'the swatch itself still occupies the tile',
    );
  });

  testWidgets('an icon on its own draws without a stored colour',
      (tester) async {
    await _pump(
      tester,
      TestFactories.makeProject(id: 'icon-only', iconKey: 'piano'),
    );

    expect(
      tester.widget<Icon>(find.byType(Icon)).icon,
      kProjectIconChoices['piano'],
    );
  });

  testWidgets('showEmptyPlaceholder offers a way in, and only when asked',
      (tester) async {
    final project = TestFactories.makeProject(id: 'empty');

    await _pump(tester, project, showEmptyPlaceholder: true);
    expect(
      tester.widget<Icon>(find.byType(Icon)).icon,
      Icons.add_photo_alternate_outlined,
    );

    await _pump(tester, project);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('a cover path that no longer resolves falls back', (tester) async {
    // The Drive-restore case: metadata arrives before (or without) the image.
    // With nothing else chosen there is nothing to fall back *to*, so the tile
    // holds its space rather than showing a broken image.
    final project = TestFactories.makeProject(
      id: 'stale-cover',
      thumbnailPath: p.join(tempDir.path, 'deleted.png'),
    );
    await _pumpWithRealImageIo(tester, project);

    expect(find.byType(Icon), findsNothing);

    // ...and falls back to the badge when the user did choose one.
    final decorated = TestFactories.makeProject(
      id: 'stale-cover-2',
      thumbnailPath: p.join(tempDir.path, 'deleted.png'),
      iconKey: 'mic',
    );
    await _pumpWithRealImageIo(tester, decorated);

    expect(
      tester.widget<Icon>(find.byType(Icon)).icon,
      kProjectIconChoices['mic'],
    );
  });

  testWidgets('onTap makes the tile tappable, and null leaves it inert',
      (tester) async {
    var taps = 0;
    final project = TestFactories.makeProject(
      id: 'tappable',
      accentColor: 0xFF123456,
    );

    await _pump(tester, project, onTap: () => taps++);
    await tester.tap(find.byType(ProjectCoverAvatar));
    expect(taps, 1);

    await _pump(tester, project);
    expect(find.byType(InkWell), findsNothing);
  });

  group('ProjectCoverBleed', () {
    Future<void> pumpBleed(WidgetTester tester, MusicProject project) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProjectCoverBleed(
                  project: project,
                  height: 48,
                  width: 96,
                  side: CoverBleedSide.right,
                ),
              ),
            ),
          ),
        );

    testWidgets('draws nothing for a project nobody decorated',
        (tester) async {
      // Still #110's rule: no placeholder, no invented colour.
      await pumpBleed(tester, TestFactories.makeProject(id: 'plain'));

      expect(tester.getSize(find.byType(ProjectCoverBleed)), Size.zero);
    });

    testWidgets('bleeds a chosen accent colour like cover art',
        (tester) async {
      // Previously left out on purpose; asked for so a coloured row reads
      // like a covered one.
      await pumpBleed(
        tester,
        TestFactories.makeProject(id: 'coloured', accentColor: 0xFF3366CC),
      );

      expect(
        tester.getSize(find.byType(ProjectCoverBleed)),
        const Size(96, 48),
      );
      final box = tester.widget<ColoredBox>(find.descendant(
        of: find.byType(ProjectCoverBleed),
        matching: find.byType(ColoredBox),
      ));
      expect(box.color.toARGB32() & 0x00FFFFFF, 0x3366CC,
          reason: 'the colour the user chose, not a stand-in');
      expect(box.color.a, closeTo(kAccentBleedOpacity, 0.01));
    });

    testWidgets('carries the chosen icon in the solid square',
        (tester) async {
      await pumpBleed(
        tester,
        TestFactories.makeProject(
          id: 'decorated',
          accentColor: 0xFF3366CC,
          iconKey: 'mic',
        ),
      );

      expect(
        find.descendant(
          of: find.byType(ProjectCoverBleed),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
      );
    });

    test('defaults to the left edge, as it always has', () {
      final bleed = ProjectCoverBleed(
        project: TestFactories.makeProject(),
        height: 48,
        width: 96,
      );
      expect(bleed.side, CoverBleedSide.left);
    });
  });

  group('coverBleedGradient', () {
    test('left-anchored art is solid on the left and fades rightwards', () {
      final g = coverBleedGradient(
        side: CoverBleedSide.left,
        solidFraction: 0.5,
      );
      expect(g.begin, Alignment.centerLeft);
      expect(g.end, Alignment.centerRight);
    });

    test('right-anchored art is solid on the right and fades leftwards', () {
      final g = coverBleedGradient(
        side: CoverBleedSide.right,
        solidFraction: 0.5,
      );
      expect(g.begin, Alignment.centerRight);
      expect(g.end, Alignment.centerLeft);
    });

    test('holds full strength for the solid fraction, then fades out', () {
      for (final side in CoverBleedSide.values) {
        final g = coverBleedGradient(side: side, solidFraction: 0.5);
        expect(g.stops, [0.0, 0.5, 1.0]);
        expect(g.colors.first.a, 1.0, reason: '$side starts opaque');
        expect(g.colors[1].a, 1.0, reason: '$side stays opaque to the stop');
        expect(g.colors.last.a, 0.0, reason: '$side ends transparent');
      }
    });
  });
}
