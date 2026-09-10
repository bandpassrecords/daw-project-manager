import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/widgets/project_cover_avatar.dart';
import 'package:daw_project_manager/utils/project_visuals.dart';

import '../helpers/test_factories.dart';

Future<void> _pump(WidgetTester tester, MusicProject project,
    {double size = 40, VoidCallback? onTap}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ProjectCoverAvatar(project: project, size: size, onTap: onTap),
        ),
      ),
    ),
  );
}

/// Pumps the avatar for a project whose cover path does not resolve, letting
/// the real file read fail so `errorBuilder` runs before the expectations do.
Future<void> _pumpWithRealImageIo(
  WidgetTester tester,
  MusicProject project,
) async {
  await tester.runAsync(() async {
    await _pump(tester, project);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
}

/// #110 — the avatar is the only place a project's visual identity is drawn,
/// so its two rules live or die here: cover art wins when it is set, and a
/// project without one still never renders blank.
///
/// **Not automatable here:** the success path, where a cover that really
/// decodes renders as an `Image`. `Image.file` over a file that exists never
/// finishes decoding under this project's test binding — a bare
/// `pumpWidget(Image.file(realFile))` hangs until the test times out, with or
/// without `runAsync`. The decision that feeds it, [projectHasCoverArt], is
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

  testWidgets('a project with no cover falls back to its accent icon',
      (tester) async {
    final project = TestFactories.makeProject(id: 'no-cover');
    await _pump(tester, project);

    expect(find.byType(Image), findsNothing);
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, resolveProjectIcon(project));
    expect(icon.color, resolveProjectAccentColor(project));
  });

  testWidgets('an accent override repaints the badge', (tester) async {
    final project = TestFactories.makeProject(
      id: 'override',
      accentColor: 0xFF123456,
      iconKey: 'mic',
    );
    await _pump(tester, project);

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, const Color(0xFF123456));
    expect(icon.icon, kProjectIconChoices['mic']);
  });

  testWidgets('a cover path that no longer resolves falls back to the badge',
      (tester) async {
    // The Drive-restore case: metadata arrives before (or without) the image.
    final project = TestFactories.makeProject(
      id: 'stale-cover',
      thumbnailPath: p.join(tempDir.path, 'deleted.png'),
    );
    await _pumpWithRealImageIo(tester, project);

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, resolveProjectIcon(project));
  });

  testWidgets('onTap makes the tile tappable, and null leaves it inert',
      (tester) async {
    var taps = 0;
    final project = TestFactories.makeProject(id: 'tappable');

    await _pump(tester, project, onTap: () => taps++);
    await tester.tap(find.byType(ProjectCoverAvatar));
    expect(taps, 1);

    await _pump(tester, project);
    expect(find.byType(InkWell), findsNothing);
  });
}
