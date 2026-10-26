import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/services/backup_service.dart';

import '../helpers/hive_test_helper.dart';

/// "Launch in DAW" runs whatever program its settings name, and a backup
/// carries those settings. A backup someone else made could choose what the
/// button runs, so a program this device doesn't already have is imported
/// only when the user says yes.
void main() {
  late Directory tempDir;
  late ProfileRepository profiles;
  late ProjectRepository repo;
  const profileId = 'test-profile';

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    profiles = await HiveTestHelper.createProfileRepository();
    repo = await HiveTestHelper.createRepository(profileId: profileId);
  });

  tearDown(() async => HiveTestHelper.tearDown(tempDir));

  String backupWith(Map<String, List<String>> commands) => jsonEncode({
        'version': '1.4',
        'projects': <Object>[],
        'dawLaunchCommands': commands,
      });

  Future<void> import(
    Map<String, List<String>> commands, {
    Future<bool> Function(Map<String, List<String>>)? confirm,
  }) =>
      BackupService.importBackupJson(
        backupWith(commands),
        projectRepo: repo,
        profileRepo: profiles,
        currentProfileId: profileId,
        importMode: ImportMode.merge,
        confirmLaunchCommands: confirm,
      );

  test('asks about new programs, and imports them on yes', () async {
    await BackupService.writeDawLaunchCommandsForTest({
      'Ableton Live': [r'C:\Live 12\Live.exe'],
    });
    Map<String, List<String>>? asked;

    await import(
      {
        'Ableton Live': [r'C:\Live 12\Live.exe', r'C:\Live 11\Live.exe'],
        'Cubase': [r'C:\Cubase\Cubase13.exe'],
      },
      confirm: (commands) async {
        asked = commands;
        return true;
      },
    );

    // Only what is new is asked about — a program already here is no news.
    expect(asked, {
      'Ableton Live': [r'C:\Live 11\Live.exe'],
      'Cubase': [r'C:\Cubase\Cubase13.exe'],
    });
    expect(await BackupService.readDawLaunchCommandsForTest(), {
      'Ableton Live': [r'C:\Live 12\Live.exe', r'C:\Live 11\Live.exe'],
      'Cubase': [r'C:\Cubase\Cubase13.exe'],
    });
  });

  test('on no, nothing changes — and the rest of the backup still imports', () async {
    await BackupService.writeDawLaunchCommandsForTest({
      'Ableton Live': [r'C:\Live 12\Live.exe'],
    });

    await import(
      {'Cubase': [r'\\attacker\share\evil.exe']},
      confirm: (_) async => false,
    );

    expect(await BackupService.readDawLaunchCommandsForTest(), {
      'Ableton Live': [r'C:\Live 12\Live.exe'],
    });
  });

  test('with no one to ask, new programs are left out', () async {
    await import({'Cubase': [r'\\attacker\share\evil.exe']});

    expect(await BackupService.readDawLaunchCommandsForTest(), isEmpty);
  });

  test('a backup naming only programs already here asks nothing', () async {
    await BackupService.writeDawLaunchCommandsForTest({
      'Ableton Live': [r'C:\Live 12\Live.exe'],
    });
    var asked = false;

    await import(
      {'Ableton Live': [r'C:\Live 12\Live.exe']},
      confirm: (_) async => asked = true,
    );

    expect(asked, isFalse);
  });

  group('newDawLaunchCommands', () {
    test('keeps only paths, and DAWs, not already there', () {
      expect(
        BackupService.newDawLaunchCommands(
          {
            'Live': ['/a', '/b'],
          },
          {
            'Live': ['/b', '/c'],
            'Bitwig': ['/d'],
            'Reaper': <String>[],
          },
        ),
        {
          'Live': ['/c'],
          'Bitwig': ['/d'],
        },
      );
    });

    test('nothing new is empty', () {
      expect(
        BackupService.newDawLaunchCommands({'Live': ['/a']}, {'Live': ['/a']}),
        isEmpty,
      );
    });
  });
}
