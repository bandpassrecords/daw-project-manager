import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/models/sample_reference.dart';
import 'package:daw_project_manager/services/project_inspector/launch_check.dart';
import 'package:daw_project_manager/services/project_inspector/media_check.dart';

import '../../helpers/test_factories.dart';

const _rpp = '''<REAPER_PROJECT 0.1 "7.0/win64" 1700000000
  <TRACK
    NAME Drums
    <ITEM
      POSITION 0
      LENGTH 1
      <SOURCE WAVE
        FILE "kick.wav"
      >
    >
    <ITEM
      POSITION 1
      LENGTH 1
      <SOURCE WAVE
        FILE "snare.wav"
      >
    >
  >
>
''';

void main() {
  group('shouldCheckBeforeLaunch', () {
    final song = TestFactories.makeProject(
      filePath: '/x/Song.cpr',
      fileName: 'Song.cpr',
      fileSizeBytes: 1024,
    );

    test('only when asked for, on a file read in a moment', () {
      expect(
        shouldCheckBeforeLaunch(enabled: true, project: song, cloudOnly: false),
        isTrue,
      );
      expect(
        shouldCheckBeforeLaunch(enabled: false, project: song, cloudOnly: false),
        isFalse,
      );
    });

    test('never a cloud placeholder: reading would download it', () {
      expect(
        shouldCheckBeforeLaunch(enabled: true, project: song, cloudOnly: true),
        isFalse,
      );
    });

    test('never a very big file, a stack, or a format not read', () {
      expect(
        shouldCheckBeforeLaunch(
          enabled: true,
          project: song.copyWith(fileSizeBytes: kLaunchCheckMaxBytes + 1),
          cloudOnly: false,
        ),
        isFalse,
      );
      expect(
        shouldCheckBeforeLaunch(
          enabled: true,
          project: song.copyWith(isVirtual: true),
          cloudOnly: false,
        ),
        isFalse,
      );
      expect(
        shouldCheckBeforeLaunch(
          enabled: true,
          project: song.copyWith(filePath: '/x/notes.txt'),
          cloudOnly: false,
        ),
        isFalse,
      );
    });
  });

  group('launchWarnings', () {
    const kick = SampleReference(fileName: 'kick.wav', candidates: ['/a/kick.wav']);

    test('missing audio and a sample rate that is not the studio\'s', () {
      final w = launchWarnings(
        media: const [
          MediaCheck(kick, MediaStatus.missing),
          MediaCheck(kick, MediaStatus.found, path: '/a/kick.wav'),
        ],
        projectRate: 44100,
        studioRate: 48000,
      );
      expect((w.missingAudio, w.totalAudio), (1, 2));
      expect((w.projectRate, w.studioRate), (44100, 48000));
      expect(w.any, isTrue);
    });

    test('nothing to say: everything found, the same rate, or no studio rate', () {
      expect(
        launchWarnings(
          media: const [MediaCheck(kick, MediaStatus.foundElsewhere)],
          projectRate: 48000,
          studioRate: 48000,
        ).any,
        isFalse,
      );
      expect(launchWarnings(projectRate: 44100).any, isFalse);
      expect(launchWarnings(studioRate: 48000).any, isFalse);
    });
  });

  group('checkBeforeLaunch', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('dpm_launch_'));
    tearDown(() => dir.delete(recursive: true));

    test('reads the project: a missing sample, its rate against the studio', () async {
      final path = p.join(dir.path, 'Song.rpp');
      await File(path).writeAsString(_rpp);
      await File(p.join(dir.path, 'kick.wav')).writeAsBytes([0]);
      // The REAPER reader doesn't read a rate yet (#213): the deep scan's
      // stands in, as it does for any reader that gives none.
      final project = TestFactories.makeProject(
        filePath: path,
        fileName: 'Song.rpp',
        dawType: 'REAPER',
        stats: const ProjectStats(sampleRate: 44100),
      );
      final w = await checkBeforeLaunch(project, studioRate: 48000);
      expect(w, isNotNull);
      expect((w!.missingAudio, w.totalAudio), (1, 2));
      expect((w.projectRate, w.studioRate), (44100, 48000));
      expect(w.media, hasLength(2));
    });

    test('a file that cannot be read says nothing, and the project opens', () async {
      final project = TestFactories.makeProject(
        filePath: p.join(dir.path, 'gone.rpp'),
        fileName: 'gone.rpp',
      );
      expect(await checkBeforeLaunch(project, studioRate: 48000), isNull);
    });

    test('a check past its time says nothing', () async {
      final path = p.join(dir.path, 'Song.rpp');
      await File(path).writeAsString(_rpp);
      final project = TestFactories.makeProject(filePath: path, fileName: 'Song.rpp');
      expect(
        await checkBeforeLaunch(project, studioRate: 48000, timeout: Duration.zero),
        isNull,
      );
    });
  });
}
