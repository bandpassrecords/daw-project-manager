import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/repository/project_repository.dart';

import '../helpers/hive_test_helper.dart';

/// Project stats follow the markers' null contract through a scan: a deep
/// scan writes what it read, a lightweight scan (which reads nothing) must
/// leave the last deep scan's stats alone.
void main() {
  late Directory tempDir;
  late Directory projectDir;
  late ProjectRepository repo;

  const rpp = '''
<REAPER_PROJECT 0.1 "7.0/win64" 0
  TEMPO 120 4 4
  <TRACK
    NAME "Vox"
    <ITEM
      LENGTH 1
      <SOURCE WAVE
        FILE "vox.wav"
      >
    >
  >
  <TRACK
    NAME "Keys"
    <FXCHAIN
      <VST "VSTi: Serum (Xfer Records)" Serum_x64.dll 0 "" 0 ""
      >
    >
  >
>
''';

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    repo = await HiveTestHelper.createRepository();
    projectDir = await Directory.systemTemp.createTemp('scan_stats_');
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
    if (await projectDir.exists()) await projectDir.delete(recursive: true);
  });

  test('a deep scan stores what the project file contains', () async {
    final file = File('${projectDir.path}/song.rpp')..writeAsStringSync(rpp);
    await repo.upsertFromFileSystemEntity(file, fullMetadata: true);

    final stats = repo.getByPath(file.path)!.stats!;
    expect(stats.audioTracks, 1);
    expect(stats.instrumentTracks, 1);
    expect(stats.plugins, ['Serum']);
    expect(stats.midiClipCount, 0);
  });

  test('a lightweight rescan keeps the last deep scan\'s stats', () async {
    final file = File('${projectDir.path}/song.rpp')..writeAsStringSync(rpp);
    await repo.upsertFromFileSystemEntity(file, fullMetadata: true);
    final before = repo.getByPath(file.path)!.stats;

    await repo.upsertFromFileSystemEntity(file);

    expect(repo.getByPath(file.path)!.stats, before);
  });

  test('a lightweight scan of a new project leaves stats unknown', () async {
    final file = File('${projectDir.path}/new.rpp')..writeAsStringSync(rpp);
    await repo.upsertFromFileSystemEntity(file);

    expect(repo.getByPath(file.path)!.stats, isNull);
  });

  test('extracting one project refreshes its stats', () async {
    final file = File('${projectDir.path}/song.rpp')..writeAsStringSync(rpp);
    await repo.upsertFromFileSystemEntity(file);
    final project = repo.getByPath(file.path)!;
    await repo.updateProject(
        project.copyWith(stats: const ProjectStats(audioTracks: 99)));

    await repo.extractFullMetadataForProject(project.id);

    expect(repo.getById(project.id)!.stats!.audioTracks, 1);
  });
}
