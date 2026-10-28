import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/repository/sync_tombstones.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';

import '../helpers/fake_drive.dart';
import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// The sync service end to end, against an in-memory Drive ([FakeDrive])
/// spoken to through the real googleapis client.
void main() {
  late Directory tempDir;
  late ProjectRepository projectRepo;
  late ProfileRepository profileRepo;
  late Profile profile;
  late FakeDrive fakeDrive;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    final profilesBox = await Hive.openBox<Profile>('profiles');
    final settingsBox = await Hive.openBox<String>('settings');
    profileRepo =
        ProfileRepository(profilesBox: profilesBox, settingsBox: settingsBox);
    profile = await profileRepo.createProfile('Studio');
    projectRepo = await HiveTestHelper.createRepository(profileId: profile.id);
    await Hive.openBox<String>('app_settings');
    fakeDrive = FakeDrive();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  Future<GoogleDriveSyncService> signedIn() async {
    final service = GoogleDriveSyncService()..driveApi = fakeDrive.api;
    await service.ensureAppDataFolder();
    return service;
  }

  String folderId() =>
      fakeDrive.files.values.firstWhere((f) => f.isFolder && f.parents.contains('root')).id;

  /// What another device's upload would leave on Drive.
  void seedBackupFromAnotherDevice(
    GoogleDriveSyncService service, {
    List<Map<String, dynamic>> projects = const [],
    List<Map<String, dynamic>> releases = const [],
    List<Map<String, dynamic>> deletedRecords = const [],
    String device = 'Laptop',
  }) {
    fakeDrive.seed(
      name: 'database_backup.json',
      parent: folderId(),
      description: device,
      content: utf8.encode(jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'device': device,
        'projects': projects,
        'releases': releases,
        'deletedRecords': deletedRecords,
      })),
    );
  }

  Map<String, dynamic> backupOnDrive() =>
      jsonDecode(fakeDrive.named('database_backup.json')!.text)
          as Map<String, dynamic>;

  Set<String> projectIdsOnDrive() => {
        for (final p in backupOnDrive()['projects'] as List) p['id'] as String,
      };

  group('syncDatabase', () {
    test('keeps what another device pushed instead of overwriting it', () async {
      // The bug: the sync page's Upload and the tray's "Backup now" replaced
      // Drive's copy outright, so a phone's project vanished from the backup
      // the moment the laptop uploaded.
      final service = await signedIn();
      seedBackupFromAnotherDevice(service, projects: [
        service.serializeProjectForTest(
          TestFactories.makeProject(id: 'from-phone', notes: 'phone notes'),
        ),
      ]);
      await projectRepo.projectsBox
          .put('local', TestFactories.makeProject(id: 'local'));

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(projectIdsOnDrive(), {'local', 'from-phone'});
      expect(projectRepo.projectsBox.get('from-phone')!.notes, 'phone notes');
    });

    test('uploads straight away when Drive has no backup yet', () async {
      final service = await signedIn();
      await projectRepo.projectsBox
          .put('local', TestFactories.makeProject(id: 'local'));

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(projectIdsOnDrive(), {'local'});
    });

    test('downloads the backup once, not twice', () async {
      final service = await signedIn();
      seedBackupFromAnotherDevice(service);
      fakeDrive.log.clear();
      final backupId = fakeDrive.named('database_backup.json')!.id;

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      // The merge's read: the upload compares against that same copy (its
      // media hashes, and whether anything changed) instead of reading again.
      final reads =
          fakeDrive.log.where((l) => l == 'GET /drive/v3/files/$backupId');
      expect(reads.length, 1);
    });

    test('records a failure and clears it on the next success', () async {
      final service = await signedIn();
      fakeDrive.failWithStatus = 500;
      await expectLater(
        service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo),
        throwsA(anything),
      );
      expect(await service.getLastFailure(), isNotNull);

      fakeDrive.failWithStatus = null;
      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );
      expect(await service.getLastFailure(), isNull);
      expect(await service.getLastSyncedAt(), isNotNull);
    });
  });

  group('newer backup on Drive', () {
    test('not after this device uploaded', () async {
      final service = await signedIn();
      await service.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );
      final info = await service.getBackupInfo();
      expect(info['isNewer'], isFalse);
      expect(info['remoteDevice'], GoogleDriveSyncService.deviceName);
    });

    test('once another device writes, and names that device', () async {
      final service = await signedIn();
      await service.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );
      seedBackupFromAnotherDevice(service, device: 'Phone');

      final info = await service.getBackupInfo();
      expect(info['isNewer'], isTrue);
      expect(info['remoteDevice'], 'Phone');
    });

    test('reading the backup without merging it does not hide it', () async {
      // The bug: downloadDatabase marked the backup as seen, so the upload's
      // own read of it — or a restore cancelled at its confirmation — made
      // "newer backup available" go away with nothing merged.
      final service = await signedIn();
      seedBackupFromAnotherDevice(service);

      await service.downloadDatabase();
      expect((await service.getBackupInfo())['isNewer'], isTrue);

      final fetched = await service.fetchBackup();
      await service.markMerged(fetched);
      expect((await service.getBackupInfo())['isNewer'], isFalse);
    });

    test('isRemoteNewer compares Drive times, with slack for old values', () {
      final t = DateTime.utc(2026, 5, 1, 12);
      expect(
        GoogleDriveSyncService.isRemoteNewer(remoteModified: null, lastSeen: t),
        isFalse,
      );
      expect(
        GoogleDriveSyncService.isRemoteNewer(remoteModified: t, lastSeen: null),
        isTrue,
      );
      expect(
        GoogleDriveSyncService.isRemoteNewer(remoteModified: t, lastSeen: t),
        isFalse,
      );
      expect(
        GoogleDriveSyncService.isRemoteNewer(
          remoteModified: t.add(const Duration(seconds: 1)),
          lastSeen: t,
        ),
        isTrue,
        reason: 'a Drive time is exact: a write a second later is news',
      );
      expect(
        GoogleDriveSyncService.isRemoteNewer(
          remoteModified: t.add(const Duration(seconds: 3)),
          lastSeen: t,
          lastSeenIsDriveTime: false,
        ),
        isFalse,
        reason: "an old build's own clock gets a few seconds' slack",
      );
      expect(
        GoogleDriveSyncService.isRemoteNewer(
          remoteModified: t.add(const Duration(minutes: 1)),
          lastSeen: t,
        ),
        isTrue,
      );
    });
  });

  group('upload', () {
    test('names this device in the file and the data', () async {
      final service = await signedIn();
      await service.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );
      expect(
        fakeDrive.named('database_backup.json')!.description,
        GoogleDriveSyncService.deviceName,
      );
      expect(backupOnDrive()['device'], GoogleDriveSyncService.deviceName);
    });
  });

  group('nothing new, nothing written', () {
    test('a sync with nothing changed leaves Drive and its history alone', () async {
      // Every launch and timer tick used to write the whole backup again,
      // each write pushing one of the earlier backups out of `history`.
      final service = await signedIn();
      await projectRepo.projectsBox.put('a', TestFactories.makeProject(id: 'a', notes: 'n'));
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);
      final written = fakeDrive.named('database_backup.json')!.modifiedTime;
      fakeDrive.log.clear();

      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      expect(fakeDrive.log.where((l) => !l.startsWith('GET')), isEmpty,
          reason: 'nothing at all is written');
      expect(fakeDrive.log, hasLength(2), reason: 'finding the backup, and reading it once');
      expect(fakeDrive.named('database_backup.json')!.modifiedTime, written);
      expect(await service.listSnapshots(), isEmpty);
      expect(await service.getLastSyncedAt(), isNotNull);
      final status = await service.getBackupInfo();
      expect(status['isNewer'], isFalse, reason: 'Drive holds nothing unseen');
    });

    test('a change made here is still written', () async {
      final service = await signedIn();
      await projectRepo.projectsBox.put('a', TestFactories.makeProject(id: 'a', notes: 'n'));
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);
      final written = fakeDrive.named('database_backup.json')!.modifiedTime;

      await projectRepo.projectsBox.put('a', TestFactories.makeProject(id: 'a', notes: 'changed'));
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      expect(fakeDrive.named('database_backup.json')!.modifiedTime, isNot(written));
      expect((backupOnDrive()['projects'] as List).single['notes'], 'changed');
      expect(await service.listSnapshots(), hasLength(1), reason: 'the replaced one is kept');
    });

    test('asks Drive about its preview songs once, however many there are', () async {
      // Each song was looked up by name: a request per song per sync.
      final service = await signedIn();
      Future<void> song(String id) async {
        final file = File('${tempDir.path}/$id.wav')..writeAsBytesSync([id.codeUnitAt(0)]);
        await projectRepo.projectsBox.put(id, TestFactories.makeProject(id: id, previewSongPath: file.path));
      }

      Future<int> listingsOfASync() async {
        fakeDrive.log.clear();
        await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo, downloadPreviewSongs: false);
        return fakeDrive.log.where((l) => l == 'GET /drive/v3/files').length;
      }

      await song('a');
      await listingsOfASync();
      final withOne = await listingsOfASync();
      await song('b');
      await song('c');
      await listingsOfASync();
      final withThree = await listingsOfASync();

      expect(withThree, withOne);
    });
  });

  group('the sync when the app starts', () {
    test('doesn\'t merge a Drive copy this device already has', () async {
      final service = await signedIn();
      await projectRepo.projectsBox.put('a', TestFactories.makeProject(id: 'a', notes: 'mine'));
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);
      // Drive's copy says otherwise, but it is the one this device wrote:
      // its time on Drive is the one this device last saw.
      final backup = fakeDrive.named('database_backup.json')!;
      final data = backupOnDrive();
      (data['projects'] as List).single['notes'] = 'not merged';
      backup.content = utf8.encode(jsonEncode(data));

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        mergeOnlyIfNewer: true,
      );

      expect(projectRepo.projectsBox.get('a')!.notes, 'mine');
    });

    test('merges what another device wrote since', () async {
      final service = await signedIn();
      await projectRepo.projectsBox.put('a', TestFactories.makeProject(id: 'a', notes: 'mine'));
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);
      seedBackupFromAnotherDevice(service, projects: [
        service.serializeProjectForTest(TestFactories.makeProject(
          id: 'a',
          notes: 'from the phone',
          updatedAt: DateTime.now().add(const Duration(hours: 1)),
        )),
      ]);

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        mergeOnlyIfNewer: true,
      );

      expect(projectRepo.projectsBox.get('a')!.notes, 'from the phone');
    });

    test('still uploads what this device has that Drive lacks', () async {
      final service = await signedIn();
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);
      await projectRepo.projectsBox.put('late', TestFactories.makeProject(id: 'late'));

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        mergeOnlyIfNewer: true,
      );

      expect(projectIdsOnDrive(), contains('late'));
    });
  });

  group('earlier backups', () {
    test('every overwrite keeps the backup it replaces, newest first', () async {
      final service = await signedIn();
      final times = <DateTime>[];
      for (var i = 0; i < 3; i++) {
        // Something new each time: an unchanged backup isn't written at all.
        await projectRepo.projectsBox
            .put('p', TestFactories.makeProject(id: 'p', notes: 'take $i'));
        await service.uploadDatabase(
          projectRepo: projectRepo,
          profileRepo: profileRepo,
        );
        times.add(fakeDrive.named('database_backup.json')!.modifiedTime);
      }

      final snapshots = await service.listSnapshots();
      // The first upload replaced nothing; the next two each kept one.
      expect(snapshots.map((s) => s.takenAt), [times[1], times[0]]);
      expect(snapshots.first.device, GoogleDriveSyncService.deviceName);
    });

    test('keeps only the newest ${GoogleDriveSyncService.snapshotsKept}',
        () async {
      final service = await signedIn();
      for (var i = 0; i < GoogleDriveSyncService.snapshotsKept + 3; i++) {
        await projectRepo.projectsBox
            .put('p', TestFactories.makeProject(id: 'p', notes: 'take $i'));
        await service.uploadDatabase(
          projectRepo: projectRepo,
          profileRepo: profileRepo,
        );
      }
      expect(
        (await service.listSnapshots()).length,
        GoogleDriveSyncService.snapshotsKept,
      );
    });

    test('merging one back recovers what an overwrite lost', () async {
      final service = await signedIn();
      await projectRepo.projectsBox
          .put('precious', TestFactories.makeProject(id: 'precious'));
      await service.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );
      // The device loses it (say, a reinstall) and then overwrites Drive.
      await projectRepo.projectsBox.delete('precious');
      await service.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );
      expect(projectIdsOnDrive(), isNot(contains('precious')));

      final snapshots = await service.listSnapshots();
      await service.mergeData(
        remoteData: await service.downloadSnapshot(snapshots.single),
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      expect(projectRepo.projectsBox.get('precious'), isNotNull);
    });

    test('snapshot names round-trip to the time they keep', () {
      final t = DateTime.utc(2026, 10, 15, 18, 42, 9);
      final name = GoogleDriveSyncService.snapshotFileName(t);
      expect(name, 'backup_20261015T184209Z.json');
      expect(GoogleDriveSyncService.snapshotTakenAt(name), t);
      expect(GoogleDriveSyncService.snapshotTakenAt('notes.txt'), isNull);
    });
  });

  group('deleteAllDriveData', () {
    test('removes the backup folder and everything in it', () async {
      final service = await signedIn();
      await service.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );
      await service.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      ); // leaves a snapshot in history
      final oldFolder = folderId();

      await service.deleteAllDriveData();

      expect(fakeDrive.files.containsKey(oldFolder), isFalse);
      expect(fakeDrive.named('database_backup.json'), isNull);
      expect(await service.getRemoteBackupInfo(), isNull);
      expect(await service.getLastSyncedAt(), isNull);
      // This device keeps its data.
      expect(profileRepo.getAllProfiles(), isNotEmpty);
    });
  });

  group('one project id in two profiles', () {
    // Seen in a real library: "Follow My Voice" sat in two profiles under
    // one id — a stray hidden copy in one, the real project in the other.
    // The upload kept the first profile's copy while its id→profile map
    // named the last, so Drive held the hidden copy labelled as the real
    // project; and comparing by id paired the wrong rows, so it read as
    // "changed here" forever.
    late Profile atlas;
    late Box<MusicProject> atlasProjects;

    setUp(() async {
      atlas = await profileRepo.createProfile('ATLAS');
      atlasProjects = await Hive.openBox<MusicProject>('${atlas.id}_projects');
    });

    MusicProject real() => TestFactories.makeProject(
          id: 'fmv',
          hidden: false,
          updatedAt: DateTime(2026, 10, 15),
        );
    MusicProject stray() => TestFactories.makeProject(
          id: 'fmv',
          hidden: true,
          updatedAt: DateTime(2026, 7, 30),
        );

    test('each copy goes up under its own profile', () async {
      final service = await signedIn();
      await atlasProjects.put('fmv', stray());
      await projectRepo.projectsBox.put('fmv', real());

      await service.uploadDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      final entries = [
        for (final e in backupOnDrive()['projects'] as List)
          if (e['id'] == 'fmv') e as Map,
      ];
      expect(entries.length, 2);
      final byProfile = {for (final e in entries) e['profileId']: e['hidden']};
      expect(byProfile[profile.id], false);
      expect(byProfile[atlas.id], true);
    });

    test('a synced library then previews as in sync', () async {
      final service = await signedIn();
      await atlasProjects.put('fmv', stray());
      await projectRepo.projectsBox.put('fmv', real());
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      final preview =
          await service.previewMerge(await service.downloadDatabase(), profileRepo);

      expect(preview.inSync, isTrue,
          reason: 'was "1 project added or changed here: Follow My Voice"');
    });

    test('restoring puts each copy in its own profile, hidden only where it was',
        () async {
      final service = await signedIn();
      await atlasProjects.put('fmv', stray());
      await projectRepo.projectsBox.put('fmv', real());
      await service.uploadDatabase(projectRepo: projectRepo, profileRepo: profileRepo);
      final backup = await service.downloadDatabase();
      await atlasProjects.clear();
      await projectRepo.projectsBox.clear();

      await service.mergeData(
        remoteData: backup,
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      expect(projectRepo.projectsBox.get('fmv')!.hidden, isFalse);
      expect(atlasProjects.get('fmv')!.hidden, isTrue);
    });

    test("deleting the stray copy doesn't delete the real one", () async {
      final service = await signedIn();
      await atlasProjects.put('fmv', stray());
      await projectRepo.projectsBox.put('fmv', real());
      final atlasRepo = await HiveTestHelper.createRepository(profileId: atlas.id);
      await atlasRepo.deleteProjects(['fmv']);

      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      expect(projectRepo.projectsBox.get('fmv'), isNotNull);
      expect(atlasProjects.get('fmv'), isNull);
      expect(
        [
          for (final e in backupOnDrive()['projects'] as List)
            if (e['id'] == 'fmv') e['profileId'],
        ],
        [profile.id],
      );
    });

    test('an older backup with only the id→profile map still restores', () async {
      final service = await signedIn();
      final entry = service.serializeProjectForTest(real());
      await service.mergeData(
        remoteData: {
          'projects': [entry],
          'projectToProfile': {'fmv': atlas.id},
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );
      expect(atlasProjects.get('fmv'), isNotNull);
      expect(projectRepo.projectsBox.get('fmv'), isNull);
    });

    test('remoteEntryProfile: own field, then the map, then none', () {
      expect(
        GoogleDriveSyncService.remoteEntryProfile(
          {'id': 'x', 'profileId': 'A'},
          {'x': 'B'},
        ),
        'A',
      );
      expect(GoogleDriveSyncService.remoteEntryProfile({'id': 'x'}, {'x': 'B'}), 'B');
      expect(GoogleDriveSyncService.remoteEntryProfile({'id': 'x'}, null), isNull);
    });
  });

  group('deletions sync', () {
    // The bug: merging is a union, so a project deleted on one device came
    // straight back from any other device that still had it.
    test('a deletion here goes up with the backup', () async {
      final service = await signedIn();
      await projectRepo.projectsBox
          .put('gone', TestFactories.makeProject(id: 'gone'));
      await projectRepo.deleteProjects(['gone']);

      await service.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final deleted = tombstonesFromJson(backupOnDrive()['deletedRecords']);
      expect(deleted.map((t) => t.id), contains('gone'));
    });

    test('a restore from Recently deleted syncs back over the deletion',
        () async {
      final service = await signedIn();
      await projectRepo.projectsBox
          .put('back', TestFactories.makeProject(id: 'back', notes: 'kept'));
      await projectRepo.deleteProjects(['back']);
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);
      expect(projectIdsOnDrive(), isNot(contains('back')));

      await projectRepo.restoreFromTrash('back');
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      expect(projectIdsOnDrive(), contains('back'));
      // Another device, holding the tombstone, takes the restore.
      final backup = backupOnDrive();
      final entry = (backup['projects'] as List).firstWhere((e) => e['id'] == 'back');
      final tombstone =
          tombstonesFromJson(backup['deletedRecords']).firstWhere((t) => t.id == 'back');
      expect(tombstone.beats(DateTime.parse(entry['updatedAt'] as String)), isFalse);
    });

    // Instants went up as local times with no offset: read on a device in
    // another time zone, or twice in the hour the clocks go back, a restore
    // came out an hour before its own deletion and lost to it.
    test('times go up naming their zone, so any device reads the same moment',
        () async {
      final service = await signedIn();
      final changed = DateTime(2026, 10, 25, 2, 30);
      await projectRepo.projectsBox.put(
        'p',
        TestFactories.makeProject(id: 'p', createdAt: changed, updatedAt: changed, lastModifiedAt: changed),
      );

      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      final entry = (backupOnDrive()['projects'] as List).firstWhere((e) => e['id'] == 'p');
      for (final field in ['createdAt', 'updatedAt', 'lastModifiedAt']) {
        final text = entry[field] as String;
        expect(text, endsWith('Z'), reason: field);
        expect(DateTime.parse(text).isAtSameMomentAs(changed), isTrue, reason: field);
      }
    });

    test('a deletion elsewhere removes the row here', () async {
      final service = await signedIn();
      await projectRepo.projectsBox.put(
        'gone',
        TestFactories.makeProject(id: 'gone', updatedAt: DateTime(2026, 1, 1)),
      );
      seedBackupFromAnotherDevice(service, deletedRecords: [
        SyncTombstone(
          id: 'gone',
          kind: TombstoneKind.project,
          deletedAt: DateTime.utc(2026, 2, 1),
        ).toJson(),
      ]);

      final result = await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(projectRepo.projectsBox.get('gone'), isNull);
      expect(result.projectsDeleted, 1);
      expect(projectIdsOnDrive(), isNot(contains('gone')));
    });

    test('a project edited after it was deleted elsewhere is kept', () async {
      final service = await signedIn();
      await projectRepo.projectsBox.put(
        'revived',
        TestFactories.makeProject(id: 'revived', updatedAt: DateTime(2026, 3, 1)),
      );
      seedBackupFromAnotherDevice(service, deletedRecords: [
        SyncTombstone(
          id: 'revived',
          kind: TombstoneKind.project,
          deletedAt: DateTime.utc(2026, 2, 1),
        ).toJson(),
      ]);

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(projectRepo.projectsBox.get('revived'), isNotNull);
    });

    test("another device's stale copy of a deleted project is not added back",
        () async {
      final service = await signedIn();
      final stale = TestFactories.makeProject(
        id: 'gone',
        updatedAt: DateTime(2026, 1, 1),
      );
      await projectRepo.projectsBox.put('gone', stale);
      await projectRepo.deleteProjects(['gone']);
      seedBackupFromAnotherDevice(service, projects: [
        service.serializeProjectForTest(stale),
      ]);

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(projectRepo.projectsBox.get('gone'), isNull);
      expect(projectIdsOnDrive(), isNot(contains('gone')));
    });

    test('a release deleted here is not added back', () async {
      final service = await signedIn();
      final release = Release(
        id: 'rel',
        title: 'EP',
        releaseDate: DateTime(2026, 6, 1),
        trackIds: const [],
      );
      await projectRepo.releasesBox.put('rel', release);
      await projectRepo.deleteRelease('rel');
      seedBackupFromAnotherDevice(service, releases: [
        service.serializeReleaseForTest(release),
      ]);

      await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(projectRepo.releasesBox.get('rel'), isNull);
    });
  });

  group('after a restart', () {
    // Hive stores dates to the millisecond; the backup's JSON keeps
    // microseconds. A project saved in this session still holds its
    // microseconds in memory, so the upload writes them; after a restart the
    // same project reads back without them, and every Drive copy looked a
    // fraction of a millisecond newer — and "changed".
    Future<void> restart() async {
      await Hive.close();
      final profilesBox = await Hive.openBox<Profile>('profiles');
      final settingsBox = await Hive.openBox<String>('settings');
      profileRepo =
          ProfileRepository(profilesBox: profilesBox, settingsBox: settingsBox);
      projectRepo = await HiveTestHelper.createRepository(profileId: profile.id);
      await Hive.openBox<String>('app_settings');
    }

    MusicProject withMicroseconds(String id) => TestFactories.makeProject(
          id: id,
          notes: 'notes',
          updatedAt: DateTime(2026, 5, 1, 10, 0, 0, 123, 456),
          lastModifiedAt: DateTime(2026, 4, 1, 9, 0, 0, 7, 891),
          deadline: DateTime(2026, 7, 1, 0, 0, 0, 0, 1),
        );

    test('a synced library previews as unchanged', () async {
      final service = await signedIn();
      await projectRepo.projectsBox.put('p', withMicroseconds('p'));
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      await restart();
      final preview =
          await service.previewMerge(await service.downloadDatabase(), profileRepo);

      expect(preview.projectsUpdated, 0);
      expect(preview.projectsToUpload, 0);
      expect(preview.inSync, isTrue);
    });

    test('without a restart, a row touched this session is not "changed here"',
        () async {
      // The mirror of the restart case: Drive's dates are read at Hive's
      // precision, but a row saved this session (the startup scan saves
      // many) still holds microseconds in memory, and read as newer.
      final service = await signedIn();
      await projectRepo.projectsBox.put('p', withMicroseconds('p'));
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      final preview =
          await service.previewMerge(await service.downloadDatabase(), profileRepo);

      expect(preview.projectsToUpload, 0);
      expect(preview.inSync, isTrue);
    });

    test('syncing again reports nothing updated', () async {
      final service = await signedIn();
      await projectRepo.projectsBox.put('p', withMicroseconds('p'));
      await service.syncDatabase(projectRepo: projectRepo, profileRepo: profileRepo);

      await restart();
      final result = await service.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(result.projectsUpdated, 0);
    });
  });

  group('previewMerge', () {
    test('counts additions, updates and deletions without writing', () async {
      final service = await signedIn();
      await projectRepo.projectsBox.put(
        'edited',
        TestFactories.makeProject(
          id: 'edited',
          notes: 'old',
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      await projectRepo.projectsBox.put(
        'same',
        TestFactories.makeProject(id: 'same', updatedAt: DateTime(2026, 1, 1)),
      );
      await projectRepo.projectsBox.put(
        'doomed',
        TestFactories.makeProject(id: 'doomed', updatedAt: DateTime(2026, 1, 1)),
      );
      final remote = {
        'projects': [
          service.serializeProjectForTest(
            TestFactories.makeProject(id: 'new-1'),
          ),
          service.serializeProjectForTest(
            TestFactories.makeProject(
              id: 'edited',
              notes: 'new',
              updatedAt: DateTime(2026, 2, 1),
            ),
          ),
          service.serializeProjectForTest(
            projectRepo.projectsBox.get('same')!,
          ),
        ],
        'deletedRecords': [
          SyncTombstone(
            id: 'doomed',
            kind: TombstoneKind.project,
            deletedAt: DateTime.utc(2026, 2, 1),
          ).toJson(),
        ],
      };

      final preview = await service.previewMerge(remote, profileRepo);

      expect(preview.projectsAdded, 1);
      expect(preview.projectsUpdated, 1);
      expect(preview.projectsDeleted, 1);
      expect(preview.changesNothing, isFalse);
      expect(projectRepo.projectsBox.get('doomed'), isNotNull,
          reason: 'a preview writes nothing');
    });

    test('counts what this device would send, too', () async {
      // After signing in, the dialog only ever counted what Drive would bring
      // here, yet told you to sync to "add what's here" whatever the case.
      final service = await signedIn();
      await projectRepo.projectsBox.put(
        'only-here',
        TestFactories.makeProject(id: 'only-here'),
      );
      final shared = TestFactories.makeProject(
        id: 'edited-here',
        notes: 'old',
        updatedAt: DateTime(2026, 1, 1),
      );
      await projectRepo.projectsBox.put(
        'edited-here',
        shared.copyWith(notes: 'new', updatedAt: DateTime(2026, 2, 1)),
      );
      await projectRepo.releasesBox.put(
        'rel-here',
        Release(id: 'rel-here', title: 'EP', trackIds: const []),
      );

      final preview = await service.previewMerge({
        'projects': [service.serializeProjectForTest(shared)],
      }, profileRepo);

      expect(preview.changesNothing, isTrue, reason: 'nothing comes this way');
      expect(preview.projectsToUpload, 2);
      expect(preview.releasesToUpload, 1);
      expect(preview.inSync, isFalse);
    });

    test('an identical backup changes nothing', () async {
      final service = await signedIn();
      await projectRepo.projectsBox
          .put('same', TestFactories.makeProject(id: 'same'));
      final preview = await service.previewMerge({
        'projects': [
          service.serializeProjectForTest(projectRepo.projectsBox.get('same')!),
        ],
      }, profileRepo);
      expect(preview.changesNothing, isTrue);
      expect(preview.inSync, isTrue);
    });
  });

  group('estimateUpload', () {
    test('counts the media files that exist, by size', () async {
      final service = GoogleDriveSyncService();
      final song = File('${tempDir.path}/song.wav')
        ..writeAsBytesSync(List.filled(1000, 1));
      final auto = File('${tempDir.path}/auto.wav')
        ..writeAsBytesSync(List.filled(500, 1));
      await projectRepo.projectsBox.put(
        'a',
        TestFactories.makeProject(id: 'a', previewSongPath: song.path),
      );
      await projectRepo.projectsBox.put(
        'b',
        TestFactories.makeProject(id: 'b', previewSongAutoPath: auto.path),
      );
      await projectRepo.projectsBox.put(
        'c',
        TestFactories.makeProject(id: 'c', previewSongPath: '/no/such/file.wav'),
      );

      final manualOnly = await service.estimateUpload(profileRepo: profileRepo);
      expect(manualOnly.files, 1);
      expect(manualOnly.bytes, 1000);

      final withAuto = await service.estimateUpload(
        profileRepo: profileRepo,
        includeAutoDetected: true,
      );
      expect(withAuto.files, 2);
      expect(withAuto.bytes, 1500);
    });
  });

  group('exclusive', () {
    test('runs one operation at a time', () async {
      final service = GoogleDriveSyncService();
      final order = <String>[];
      final first = service.exclusive(() async {
        order.add('first start');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        order.add('first end');
      });
      final second = service.exclusive(() async {
        order.add('second');
      });
      expect(service.isBusy, isTrue);
      await Future.wait([first, second]);
      expect(order, ['first start', 'first end', 'second']);
      expect(service.isBusy, isFalse);
    });
  });
}
