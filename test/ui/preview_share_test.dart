import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/preview_share.dart';

import '../helpers/test_factories.dart';

/// Redirects `getTemporaryDirectory()` at a real temp folder so
/// [stageFileForMobileShare] can be exercised without a device.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.tempPath);
  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

/// Stands in for share_plus. By default it answers the way the Windows
/// plugin does after opening the share menu: `unavailable`, because Windows
/// never reports what the user picked.
///
/// One instance for the whole file: `SharePlus.instance` captures the
/// platform the first time it is used, so swapping in a second fake later
/// would be silently ignored. Tests change [error] instead.
class _FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  ShareResult result = ShareResult.unavailable;
  Object? error;
  final shared = <ShareParams>[];

  void reset() {
    result = ShareResult.unavailable;
    error = null;
    shared.clear();
  }

  @override
  Future<ShareResult> share(ShareParams params) async {
    shared.add(params);
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('effectivePreviewPathFor', () {
    test('prefers a manually chosen preview over an auto-detected one', () {
      final project = TestFactories.makeProject(
        previewSongPath: '/manual/pick.wav',
        previewSongAutoPath: '/auto/detected.wav',
      );
      expect(effectivePreviewPathFor(project), '/manual/pick.wav');
    });

    test('falls back to the auto-detected mixdown', () {
      final project = TestFactories.makeProject(
        previewSongPath: null,
        previewSongAutoPath: '/auto/detected.wav',
      );
      expect(effectivePreviewPathFor(project), '/auto/detected.wav');
    });

    test('treats an empty manual path as unset', () {
      final project = TestFactories.makeProject(
        previewSongPath: '',
        previewSongAutoPath: '/auto/detected.wav',
      );
      expect(effectivePreviewPathFor(project), '/auto/detected.wav');
    });

    test('returns null when the project has no preview at all', () {
      final project = TestFactories.makeProject(
        previewSongPath: null,
        previewSongAutoPath: null,
      );
      expect(effectivePreviewPathFor(project), isNull);
    });
  });

  group('shareMimeTypeForFileName', () {
    // Android hands the declared type straight to the receiving app, and some
    // apps route on it instead of sniffing the bytes — a mistyped attachment
    // reads as "unsupported" even when the audio is fine.
    test('types the two formats the converters actually emit', () {
      // Windows/Linux produce MP3; Android and macOS produce AAC in MP4.
      expect(shareMimeTypeForFileName('Track.mp3'), 'audio/mpeg');
      expect(shareMimeTypeForFileName('Track.m4a'), 'audio/mp4');
    });

    test('types the unconverted formats a share can still fall back to', () {
      expect(shareMimeTypeForFileName('Track.wav'), 'audio/wav');
      expect(shareMimeTypeForFileName('Track.flac'), 'audio/flac');
      expect(shareMimeTypeForFileName('Track.aiff'), 'audio/aiff');
      expect(shareMimeTypeForFileName('Track.ogg'), 'audio/ogg');
      expect(shareMimeTypeForFileName('Track.aac'), 'audio/aac');
    });

    test('is case-insensitive', () {
      expect(shareMimeTypeForFileName('TRACK.M4A'), 'audio/mp4');
    });

    test('falls back to a generic audio type, never octet-stream', () {
      expect(shareMimeTypeForFileName('Track.weird'), 'audio/*');
      expect(shareMimeTypeForFileName('Track'), 'audio/*');
    });
  });

  group('stageFileForMobileShare', () {
    late Directory cacheDir;
    late Directory sourceDir;

    setUp(() async {
      cacheDir = await Directory.systemTemp.createTemp('share_cache_');
      sourceDir = await Directory.systemTemp.createTemp('share_source_');
      PathProviderPlatform.instance = _FakePathProvider(cacheDir.path);
    });

    tearDown(() async {
      if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
      if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
    });

    test('copies a file from outside the cache into it', () async {
      final source = File(p.join(sourceDir.path, 'Bounce.mp3'));
      await source.writeAsString('audio bytes');

      final staged = await stageFileForMobileShare(source, 'Bounce.mp3');

      expect(staged, isNotNull);
      expect(p.dirname(staged!.path), cacheDir.path);
      expect(await staged.readAsString(), 'audio bytes');
    });

    test('shares under the requested name, not the source name', () async {
      final source = File(p.join(sourceDir.path, 'uuid_preview.mp3'));
      await source.writeAsString('audio bytes');

      final staged = await stageFileForMobileShare(source, 'My Track.mp3');

      expect(p.basename(staged!.path), 'My Track.mp3');
    });

    // The regression this whole helper exists for. The audio converter writes
    // into the cache directory, so once Android conversion started working,
    // fileToShare and the staging destination became the same path — and
    // File.copy onto itself truncates to zero bytes. The recipient then sees
    // the message text with no playable attachment.
    test('does not destroy the file when it is already in the cache', () async {
      final alreadyStaged = File(p.join(cacheDir.path, 'Converted.mp3'));
      await alreadyStaged.writeAsString('converted audio');

      final staged = await stageFileForMobileShare(
        alreadyStaged,
        'Converted.mp3',
      );

      expect(staged, isNotNull);
      expect(await staged!.length(), greaterThan(0));
      expect(await staged.readAsString(), 'converted audio');
    });

    test('returns null for a zero-byte file rather than sharing nothing',
        () async {
      final empty = File(p.join(sourceDir.path, 'Empty.mp3'));
      await empty.create();

      expect(await stageFileForMobileShare(empty, 'Empty.mp3'), isNull);
    });

    test('overwrites a stale copy left by an earlier share', () async {
      // Sharing the same track twice must send the current audio, not
      // whatever was cached the first time.
      await File(p.join(cacheDir.path, 'Bounce.mp3')).writeAsString('old take');
      final source = File(p.join(sourceDir.path, 'Bounce.mp3'));
      await source.writeAsString('new take');

      final staged = await stageFileForMobileShare(source, 'Bounce.mp3');

      expect(await staged!.readAsString(), 'new take');
    });
  });

  group('share filename', () {
    tearDown(() => MusicProject.stripDatesFromNames = false);

    test('drops the date stamp the DAW put in the file name', () {
      // What the recipient sees in WhatsApp — a date here reads as a stale
      // bounce even when the file is fresh.
      final project = TestFactories.makeProject(
        customDisplayName: null,
        fileName: '2026-08-02 - Teardrop.cpr',
        previewSongPath: '/mixdown/2026-08-02 - Teardrop.wav',
        previewSongFileName: '2026-08-02 - Teardrop.wav',
      );

      expect(project.previewShareFileName, 'Teardrop.wav');
    });
  });

  group('shareProjectPreview on desktop', () {
    late Directory dir;
    final fake = _FakeSharePlatform();

    setUpAll(() => SharePlatform.instance = fake);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('share_desktop_');
      fake.reset();
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    Future<BuildContext> pumpHost(WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (context) {
            ctx = context;
            return const SizedBox();
          }),
        ),
      ));
      return ctx;
    }

    Future<MusicProject> projectWithPreview() async {
      final song = File(p.join(dir.path, 'Bounce.mp3'));
      await song.writeAsString('audio bytes');
      return TestFactories.makeProject(previewSongPath: song.path);
    }

    // The regression: Windows opened its share menu, the share worked, and
    // the app still said the share menu was unavailable — because the
    // plugin always answers `unavailable` there.
    testWidgets('an `unavailable` result after sharing shows no warning',
        (tester) async {
      final context = await pumpHost(tester);
      final project = await tester.runAsync(projectWithPreview);

      await tester.runAsync(() => shareProjectPreview(context, project!));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(fake.shared, hasLength(1));
      expect(fake.shared.single.files!.single.path, endsWith('Bounce.mp3'));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a share that really fails is still reported', (tester) async {
      fake.error = Exception('no share target');
      final context = await pumpHost(tester);
      final project = await tester.runAsync(projectWithPreview);

      await tester.runAsync(() => shareProjectPreview(context, project!));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(fake.shared, hasLength(1));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('no share target'), findsOneWidget);
    });
  });
}
