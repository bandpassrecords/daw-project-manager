// Measures what playing a song costs the rest of the app, in the real app
// on a demo library — never a real one:
//
//   flutter test integration_test/perf/player_repaint_test.dart -d windows `
//     --dart-define=DPM_DATA_DIR=daw_project_manager_perf
//
// Plays a song in the desktop player bar and counts, over a few seconds,
// the frames drawn and the render objects painted — those in the projects
// table among them — first with the dashboard alone, then with the "Add todo
// at …" dialog open over it. Prints one `PERF {...}` line per measurement.
//
// While a song played the app fell to 12 frames a second, 73 ms of build
// each: every position update (once a frame) rebuilt the player bar and
// repainted the whole page, and the playing row's animated icon repainted
// the whole projects table on every frame — 27,000 render objects a second
// in it, behind an open dialog too. Now it draws ~100 frames a second at ~2
// ms, and the table doesn't repaint.
//
// Then it visits every tab in the rail and a project's page with the song
// still playing, and holds each to the same rule: nothing outside the player
// repaints. A one-off is a failure too — the automatic sync's status refresh
// rebuilt the whole dashboard (and laid the table out again) once, for the
// sake of one rail label, and showed up here as 753 objects a second.
//
// Not part of CI: a debug build on a real window, run when the player
// changes.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:trina_grid/trina_grid.dart';

import 'package:daw_project_manager/main.dart' as app;
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/services/demo_data_service.dart';
import 'package:daw_project_manager/ui/widgets/now_playing_icon.dart';
import 'package:daw_project_manager/utils/app_paths.dart';

const _measureFor = Duration(seconds: 4);

Future<void> _seed() async {
  if (!isAppDataDirPinned || !appDataDirName.endsWith('_perf')) {
    throw StateError(
      'Run with --dart-define=DPM_DATA_DIR=daw_project_manager_perf '
      '— this wipes the library it runs on.',
    );
  }
  final dataDir = Directory(await getLocalAppDataPath());
  if (await dataDir.exists()) await dataDir.delete(recursive: true);
  final profiles = await ProfileRepository.init();
  final starter = profiles.getCurrentProfileId()!;
  await ProjectRepository.init(profiles);
  final demo = await DemoDataService().generate(profiles);
  await profiles.setCurrentProfileId(demo.id);
  if (starter != demo.id) await profiles.deleteProfile(starter);
  final settings = await Hive.openBox<String>('settings');
  await settings.putAll({
    'onboardingComplete': 'true',
    'hidePinnedLibraryWarning': 'true',
    'warnBeforeQuit': 'false',
    'closeToTray': 'false',
    'dashboardViewMode': 'table',
  });
  final appSettings = await Hive.openBox<String>('app_settings');
  await appSettings.putAll({
    'syncOnStartup': 'false',
    'autoBackupInterval': 'off',
  });
}

/// A stereo 16-bit WAV of [seconds] of shifting tones, long enough to
/// measure every screen over (the demo library's previews last three
/// seconds).
Uint8List _songWav(int seconds) {
  const rate = 44100;
  final frames = rate * seconds;
  final data = ByteData(44 + frames * 4);
  void ascii(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + frames * 4, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 2, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 4, Endian.little);
  data.setUint16(32, 4, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, frames * 4, Endian.little);
  for (var i = 0; i < frames; i++) {
    final t = i / rate;
    final envelope = 0.3 + 0.25 * math.sin(2 * math.pi * 0.5 * t);
    final v = envelope * math.sin(2 * math.pi * (220 + 40 * (t % 4)) * t);
    final s = (v * 30000).round().clamp(-32768, 32767);
    data.setInt16(44 + i * 4, s, Endian.little);
    data.setInt16(46 + i * 4, s, Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Frames drawn and render objects painted over [_measureFor] of real time.
Future<Map<String, Object>> _measure(String label) async {
  final grid = find.byType(TrinaGrid).evaluate().firstOrNull?.renderObject;
  // The playing row's icon animates, inside the table, on purpose: its own
  // repaints are not the table's.
  final icons = {
    for (final e in find.byType(NowPlayingIcon).evaluate()) e.renderObject,
  };
  // What the player itself draws: the bar (its waveform and slider move
  // with the song) and the playing row's icon. Everything else is the cost
  // playing puts on the rest of the app.
  final player = {
    ...icons,
    for (final e
        in find
            .byKey(const Key('desktop_player_bar'), skipOffstage: false)
            .evaluate())
      e.renderObject,
  };
  bool outsidePlayer(RenderObject r) {
    for (RenderObject? o = r; o != null; o = o.parent) {
      if (player.contains(o)) return false;
    }
    return true;
  }

  bool inGrid(RenderObject r) {
    for (RenderObject? o = r; o != null; o = o.parent) {
      if (icons.contains(o)) return false;
      if (identical(o, grid)) return true;
    }
    return false;
  }

  var painted = 0, gridPainted = 0, outside = 0;
  final gridTypes = <String, int>{};
  final outsideTypes = <String, int>{};
  final timings = <FrameTiming>[];
  void onTimings(List<FrameTiming> t) => timings.addAll(t);
  debugOnProfilePaint = (r) {
    painted++;
    if (outsidePlayer(r)) {
      outside++;
      final creator = r.debugCreator;
      final chain = <String>[];
      if (creator is DebugCreator) {
        creator.element.visitAncestorElements((e) {
          final name = '${e.widget.runtimeType}';
          if (!name.startsWith('_')) chain.add(name);
          return chain.length < 8;
        });
      }
      final type = '${r.runtimeType} <- ${chain.join(' < ')}';
      outsideTypes[type] = (outsideTypes[type] ?? 0) + 1;
    }
    if (grid != null && inGrid(r)) {
      gridPainted++;
      final creator = r.debugCreator;
      final chain = <String>[];
      if (creator is DebugCreator) {
        creator.element.visitAncestorElements((e) {
          final name = '${e.widget.runtimeType}';
          if (!const [
            'Semantics',
            'Focus',
            'Actions',
            'IconTheme',
            'Padding',
            'Builder',
            'Default',
            'Mouse',
            'Listener',
            'Raw',
            'Gesture',
            'Ink',
            'Material',
            'Align',
            'Constrained',
            'Center',
            'Sized',
            '_',
          ].any(name.startsWith)) {
            chain.add(name);
          }
          return chain.length < 25;
        });
      }
      final type = '${r.runtimeType} <- ${chain.join(' < ')}';
      gridTypes[type] = (gridTypes[type] ?? 0) + 1;
    }
  };
  SchedulerBinding.instance.addTimingsCallback(onTimings);
  await Future<void>.delayed(_measureFor);
  SchedulerBinding.instance.removeTimingsCallback(onTimings);
  debugOnProfilePaint = null;

  double ms(Iterable<Duration> d) => d.isEmpty
      ? 0
      : d.map((x) => x.inMicroseconds).reduce((a, b) => a + b) /
            d.length /
            1000;
  final secs = _measureFor.inMilliseconds / 1000;
  final result = <String, Object>{
    'label': label,
    'framesPerSecond': (timings.length / secs).toStringAsFixed(1),
    'paintedPerSecond': (painted / secs).round(),
    'tablePaintedPerSecond': (gridPainted / secs).round(),
    'outsidePlayerPaintedPerSecond': (outside / secs).round(),
    'avgBuildMs': ms(timings.map((t) => t.buildDuration)).toStringAsFixed(2),
    'avgRasterMs': ms(timings.map((t) => t.rasterDuration)).toStringAsFixed(2),
    'outsideTop': (outsideTypes.entries.toList()
          ..sort((a, b) => b.value - a.value))
        .take(3)
        .map((e) => '${e.value} ${e.key}')
        .toList(),
    'tableTop': (gridTypes.entries.toList()..sort((a, b) => b.value - a.value))
        .take(1)
        .map(
          (e) =>
              '${e.value} ${e.key.length > 2500 ? e.key.substring(0, 2500) : e.key}',
        )
        .toList(),
  };
  debugPrint('PERF ${jsonEncode(result)}');
  return result;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('playing a song repaints nothing outside the player', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    await _seed();
    final errorWidgetBuilder = ErrorWidget.builder;

    app.main(const []);

    Future<void> until(Finder f) async {
      final end = DateTime.now().add(const Duration(seconds: 40));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
        if (f.evaluate().isNotEmpty) return;
      }
      throw TestFailure('Never showed $f');
    }

    await until(find.text('Distant Shore'));
    await until(find.byType(TrinaGrid));
    // Real frames, as the app draws them: only what asks to be drawn is.
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    await Future<void>.delayed(const Duration(seconds: 2));

    final idle = await _measure('idle, nothing playing');

    final song = File(p.join(Directory.systemTemp.path, 'dpm_perf_song.wav'));
    await song.writeAsBytes(_songWav(150));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrinaGrid)),
    );
    final project =
        (container.read(allProjectsStreamProvider).value ?? const [])
            .firstWhere((x) => x.displayName == 'Distant Shore');
    container.read(desktopPlayerProvider.notifier).play(project, song.path);

    final playing = find.byKey(const Key('desktop_player_bar'));
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (container.read(desktopPlayerPositionProvider) <
        const Duration(milliseconds: 500)) {
      if (DateTime.now().isAfter(end)) {
        throw TestFailure('The song never started');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(playing, findsOneWidget);
    // The waveform's peaks are read in the background; measure after.
    await Future<void>.delayed(const Duration(seconds: 2));

    final dashboard = await _measure('song playing, dashboard');

    await tester.tap(find.byTooltip(RegExp('^Add todo at')).first);
    // Opening it takes the keyboard from the table, whose focused button
    // fades its highlight out for a moment: measure after that.
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(find.byType(AlertDialog), findsOneWidget);

    final dialog = await _measure('song playing, add-todo dialog open');

    await tester.tap(find.text('Cancel'));
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // The song plays on under every other screen: each should cost what the
    // player draws and nothing else.
    final screens = <Map<String, Object>>[];
    Future<void> measureScreen(String name) async {
      final before = container.read(desktopPlayerPositionProvider);
      final result = await _measure('song playing, $name');
      expect(
        container.read(desktopPlayerPositionProvider),
        greaterThan(before),
        reason: 'the song had stopped by $name',
      );
      screens.add(result);
    }

    Future<void> tab(IconData icon, String name) async {
      final button = find.descendant(
        of: find.byType(NavigationRail),
        matching: find.byIcon(icon),
      );
      // Not every tab is in the rail by default.
      if (button.evaluate().isEmpty) return;
      await tester.tap(button.first);
      await Future<void>.delayed(const Duration(seconds: 3));
      await measureScreen(name);
    }

    await tab(Icons.album, 'releases');
    await tab(Icons.playlist_play, 'playlists');
    await tab(Icons.piano, 'MIDI');
    await tab(Icons.checklist, 'tasks');
    await tab(Icons.bar_chart_rounded, 'statistics');
    await tab(Icons.library_music, 'projects again');

    // A project's own page, pushed over the dashboard.
    final row = find.text('Fever Dream').first;
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.addPointer(location: tester.getCenter(row));
    await mouse.down(tester.getCenter(row));
    await mouse.up();
    await mouse.removePointer();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await tester.tap(find.text('View Details').first);
    await Future<void>.delayed(const Duration(seconds: 3));
    await measureScreen('project page');
    await tester.tap(find.byIcon(Icons.arrow_back).hitTestable().first);
    await Future<void>.delayed(const Duration(seconds: 1));

    container.read(desktopPlayerProvider.notifier).close();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    ErrorWidget.builder = errorWidgetBuilder;
    debugPrint(
      'PERF_SUMMARY ${jsonEncode([idle, dashboard, dialog, ...screens])}',
    );
    expect(
      dashboard['tablePaintedPerSecond'],
      0,
      reason: 'the table repainted while a song played',
    );
    expect(
      dialog['tablePaintedPerSecond'],
      0,
      reason: 'the table repainted behind the dialog',
    );
    for (final screen in [dashboard, dialog, ...screens]) {
      expect(
        screen['outsidePlayerPaintedPerSecond'],
        0,
        reason: '${screen['label']}: something besides the player repainted',
      );
    }
    expect(dashboard['framesPerSecond'], isNot('0.0'));
  });
}
