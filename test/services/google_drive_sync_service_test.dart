import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:daw_project_manager/models/part_template.dart';
import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/models/todo_template.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';
import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

// Minimal stub — extends BaseClient so get/post/etc. are provided; only
// instantiation matters and no methods are ever called in these tests.
class _FakeAuthClient extends http.BaseClient
    implements auth_io.AutoRefreshingAuthClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  auth_io.AccessCredentials get credentials => throw UnimplementedError();

  @override
  Stream<auth_io.AccessCredentials> get credentialUpdates =>
      throw UnimplementedError();
}

void main() {
  group('GoogleDriveSyncService.isSignedIn (desktop)', () {
    // Regression: before fix, isSignedIn only checked _currentUser (the mobile
    // GoogleSignIn field). On desktop, auth sets _desktopAuthClient/_driveApi
    // and never populates _currentUser, so the getter always returned false.

    test('returns false before authentication', () {
      final service = GoogleDriveSyncService();
      expect(service.isSignedIn, isFalse);
    });

    test('returns true after desktopAuthClient and driveApi are set', () {
      final service = GoogleDriveSyncService();
      service.desktopAuthClient = _FakeAuthClient();
      service.driveApi = drive.DriveApi(http.Client());
      expect(service.isSignedIn, isTrue);
    });

    test('returns false when only desktopAuthClient is set', () {
      final service = GoogleDriveSyncService();
      service.desktopAuthClient = _FakeAuthClient();
      expect(service.isSignedIn, isFalse);
    });

    test('returns false when only driveApi is set', () {
      final service = GoogleDriveSyncService();
      service.driveApi = drive.DriveApi(http.Client());
      expect(service.isSignedIn, isFalse);
    });
  });

  group('GoogleDriveSyncService.isSupported', () {
    // isSupported is now false only inside an actual Flatpak sandbox (see
    // isFlatpakSandboxFor below for that logic in isolation). No runner in
    // this project's CI — including unit_tests on ubuntu-latest — is ever
    // inside a Flatpak sandbox, so isSupported is true everywhere this test
    // suite runs, same as Windows/macOS.
    test('is true outside a Flatpak sandbox', () {
      expect(GoogleDriveSyncService.isSupported, isTrue);
    });
  });

  group('GoogleDriveSyncService.isFlatpakSandboxFor', () {
    // Drive sync's desktop OAuth flow requires a client secret, which
    // Flathub's build sandbox has no way to keep out of the public
    // submission repo (see flatpak/README.md and CLAUDE.md) — so it's not
    // offered inside Flatpak specifically, detected via the /.flatpak-info
    // marker file every Flatpak app has at runtime. Extracted as a pure
    // function (mirrors looksLikeFlatpakPortalPath in settings_page.dart)
    // so this actual decision logic is testable without needing to run
    // inside a real sandbox.
    test('true when on Linux and the Flatpak marker file exists', () {
      expect(
        GoogleDriveSyncService.isFlatpakSandboxFor(
          isLinux: true,
          flatpakInfoExists: true,
        ),
        isTrue,
      );
    });

    test('false on Linux without the Flatpak marker file (tarball/AppImage)', () {
      expect(
        GoogleDriveSyncService.isFlatpakSandboxFor(
          isLinux: true,
          flatpakInfoExists: false,
        ),
        isFalse,
      );
    });

    test('false off Linux regardless of the marker file', () {
      expect(
        GoogleDriveSyncService.isFlatpakSandboxFor(
          isLinux: false,
          flatpakInfoExists: true,
        ),
        isFalse,
      );
    });
  });

  group('GoogleDriveSyncService cross-instance auth sync', () {
    // Regression: the app creates a separate GoogleDriveSyncService instance
    // per consumer (e.g. one for the tray, one for the sign-in page). Auth
    // state lives on instance fields, so signing in on one instance left
    // every other instance's isSignedIn stuck at false (tray "Backup Now"
    // menu item stayed disabled) until app restart. authStateStream +
    // forgetLocalSession() let a passive instance reconcile.

    test('forgetLocalSession clears in-memory auth state without touching other instances', () {
      final signedInInstance = GoogleDriveSyncService();
      signedInInstance.desktopAuthClient = _FakeAuthClient();
      signedInInstance.driveApi = drive.DriveApi(http.Client());
      expect(signedInInstance.isSignedIn, isTrue);

      final passiveInstance = GoogleDriveSyncService();
      passiveInstance.desktopAuthClient = _FakeAuthClient();
      passiveInstance.driveApi = drive.DriveApi(http.Client());
      expect(passiveInstance.isSignedIn, isTrue);

      passiveInstance.forgetLocalSession();

      expect(passiveInstance.isSignedIn, isFalse);
      expect(signedInInstance.isSignedIn, isTrue,
          reason: 'clearing one instance must not affect another');
    });

    test('signOut broadcasts false on the shared authStateStream', () async {
      final service = GoogleDriveSyncService();
      service.desktopAuthClient = _FakeAuthClient();
      service.driveApi = drive.DriveApi(http.Client());

      final events = <bool>[];
      final sub = GoogleDriveSyncService.authStateStream.listen(events.add);

      await service.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(events, contains(false));
      expect(service.isSignedIn, isFalse);

      await sub.cancel();
    });
  });

  group('GoogleDriveSyncService.mergeData - custom mixdown folders and phase settings', () {
    late Directory tempDir;
    late ProjectRepository projectRepo;
    late ProfileRepository profileRepo;
    late Profile profile;
    late Box<String> appSettingsBox;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ProfileAdapter());
      projectRepo = await HiveTestHelper.createRepository();
      final profilesBox = await Hive.openBox<Profile>('profiles');
      final settingsBox = await Hive.openBox<String>('settings');
      profileRepo = ProfileRepository(profilesBox: profilesBox, settingsBox: settingsBox);
      profile = await profileRepo.createProfile('Test Profile');
      appSettingsBox = await Hive.openBox<String>('app_settings');
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('restores part templates from a backup with none stored locally', () async {
      final remote = PartTemplate(
        id: 'pt-1',
        name: 'Band Lineup',
        items: PartTemplate.parseItems('Drums — Alex\nBass — Sam'),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'partTemplates': [remote.toJson()],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final box = await Hive.openBox<PartTemplate>('partTemplates');
      expect(box.get('pt-1')?.items.map((i) => i.name), ['Drums', 'Bass']);
    });

    test('does not clobber a part template edited locally since the backup', () async {
      final box = await Hive.openBox<PartTemplate>('partTemplates');
      await box.put(
        'pt-1',
        PartTemplate(
          id: 'pt-1',
          name: 'Renamed locally',
          items: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 6, 1),
        ),
      );

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'partTemplates': [
            PartTemplate(
              id: 'pt-1',
              name: 'Stale remote name',
              items: const [],
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 3, 1),
            ).toJson(),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(box.get('pt-1')?.name, 'Renamed locally');
    });

    test('restores custom mixdown folders from a backup with no local folders', () async {
      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'customMixdownFolders': ['Mixdowns', 'Bounces'],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final raw = appSettingsBox.get('customMixdownFolders');
      expect(raw, isNotNull);
      expect(jsonDecode(raw!), ['Mixdowns', 'Bounces']);
    });

    test('unions local and remote custom mixdown folders without duplicates', () async {
      await appSettingsBox.put('customMixdownFolders', jsonEncode(['Mixdowns', 'exports']));

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'customMixdownFolders': ['Exports', 'Bounces'],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final raw = appSettingsBox.get('customMixdownFolders');
      final merged = (jsonDecode(raw!) as List).cast<String>();
      // 'Exports' from remote is a case-insensitive duplicate of local 'exports' and is dropped.
      expect(merged, ['Mixdowns', 'exports', 'Bounces']);
    });

    test('restores per-DAW custom mixdown folders from a backup with none stored locally', () async {
      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'customMixdownFoldersByDaw': {
            'Ableton Live': ['MyBounces'],
          },
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final raw = appSettingsBox.get('customMixdownFoldersByDaw');
      expect(raw, isNotNull);
      expect(jsonDecode(raw!), {
        'Ableton Live': ['MyBounces'],
      });
    });

    test('unions local and remote per-DAW custom mixdown folders without duplicates', () async {
      await appSettingsBox.put(
        'customMixdownFoldersByDaw',
        jsonEncode({
          'Ableton Live': ['MyBounces'],
        }),
      );

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'customMixdownFoldersByDaw': {
            'Ableton Live': ['MyBounces', 'MoreExports'],
            'FL Studio': ['Renders'],
          },
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final raw = appSettingsBox.get('customMixdownFoldersByDaw');
      final merged = (jsonDecode(raw!) as Map).map(
        (k, v) => MapEntry(k as String, (v as List).cast<String>()),
      );
      expect(merged['Ableton Live'], ['MyBounces', 'MoreExports']);
      expect(merged['FL Studio'], ['Renders']);
    });

    test('fills in phase settings for a profile that has none locally', () async {
      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'phaseSettingsByProfile': {
            profile.id: {
              'phases': ['Idea', 'Tracking', 'Mixing', 'Done'],
              'phaseColors': {'Done': '#00FF00'},
              'finishedPhases': ['Done'],
            },
          },
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(
        jsonDecode(appSettingsBox.get('${profile.id}_phases')!),
        ['Idea', 'Tracking', 'Mixing', 'Done'],
      );
      expect(
        jsonDecode(appSettingsBox.get('${profile.id}_phase_colors')!),
        {'Done': '#00FF00'},
      );
      expect(
        jsonDecode(appSettingsBox.get('${profile.id}_finished_phases')!),
        ['Done'],
      );
    });

    test('never overwrites a profile\'s existing phase customization with backup data', () async {
      await appSettingsBox.put('${profile.id}_phases', jsonEncode(['Local Idea', 'Local Done']));

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'phaseSettingsByProfile': {
            profile.id: {
              'phases': ['Remote Idea', 'Remote Mixing', 'Remote Done'],
            },
          },
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(
        jsonDecode(appSettingsBox.get('${profile.id}_phases')!),
        ['Local Idea', 'Local Done'],
      );
    });
  });

  group('GoogleDriveSyncService.mergeData - TODO templates', () {
    // Regression for #96: TODO templates were serialized into every backup
    // under 'templates', but mergeData had no block reading that key back —
    // _deserializeTemplate had no caller at all. Restoring onto a fresh
    // machine brought back everything except the user's TODO templates.
    late Directory tempDir;
    late ProjectRepository projectRepo;
    late ProfileRepository profileRepo;
    late Box<TodoTemplate> templatesBox;

    /// The wire shape produced by `_serializeTemplate` on the upload side.
    Map<String, dynamic> remoteTemplate({
      required String id,
      required String name,
      required List<String> items,
      required DateTime updatedAt,
    }) {
      return {
        'id': id,
        'name': name,
        'items': items,
        'createdAt': DateTime(2025, 1, 1).toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
    }

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ProfileAdapter());
      projectRepo = await HiveTestHelper.createRepository();
      final profilesBox = await Hive.openBox<Profile>('profiles');
      final settingsBox = await Hive.openBox<String>('settings');
      profileRepo = ProfileRepository(profilesBox: profilesBox, settingsBox: settingsBox);
      await profileRepo.createProfile('Test Profile');
      templatesBox = await Hive.openBox<TodoTemplate>('todoTemplates');
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('restores TODO templates onto a machine that has none', () async {
      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'templates': [
            remoteTemplate(
              id: 'tpl-1',
              name: 'Mixing checklist',
              items: ['Balance levels', 'Check mono'],
              updatedAt: DateTime(2025, 6, 1),
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final restored = templatesBox.get('tpl-1');
      expect(restored, isNotNull);
      expect(restored!.name, 'Mixing checklist');
      expect(restored.items, ['Balance levels', 'Check mono']);
      expect(restored.createdAt, DateTime(2025, 1, 1));
      expect(restored.updatedAt, DateTime(2025, 6, 1));
    });

    test('is keyed by template id so a re-merge updates in place', () async {
      final service = GoogleDriveSyncService();
      final payload = {
        'templates': [
          remoteTemplate(
            id: 'tpl-1',
            name: 'Mixing checklist',
            items: ['Balance levels'],
            updatedAt: DateTime(2025, 6, 1),
          ),
        ],
      };

      await service.mergeData(
          remoteData: payload, projectRepo: projectRepo, profileRepo: profileRepo);
      await service.mergeData(
          remoteData: payload, projectRepo: projectRepo, profileRepo: profileRepo);

      expect(templatesBox.length, 1);
    });

    test('a newer remote template overwrites the local copy', () async {
      await templatesBox.put(
        'tpl-1',
        TodoTemplate(
          id: 'tpl-1',
          name: 'Old name',
          items: ['Old item'],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 3, 1),
        ),
      );

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'templates': [
            remoteTemplate(
              id: 'tpl-1',
              name: 'New name',
              items: ['New item'],
              updatedAt: DateTime(2025, 6, 1),
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(templatesBox.get('tpl-1')!.name, 'New name');
    });

    test('an older remote template does not clobber a locally edited one', () async {
      await templatesBox.put(
        'tpl-1',
        TodoTemplate(
          id: 'tpl-1',
          name: 'Edited locally',
          items: ['Local item'],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 9, 1),
        ),
      );

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'templates': [
            remoteTemplate(
              id: 'tpl-1',
              name: 'Stale backup copy',
              items: ['Stale item'],
              updatedAt: DateTime(2025, 6, 1),
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final kept = templatesBox.get('tpl-1')!;
      expect(kept.name, 'Edited locally');
      expect(kept.items, ['Local item']);
    });

    test('keeps local-only templates that are absent from the backup', () async {
      await templatesBox.put(
        'local-only',
        TodoTemplate(
          id: 'local-only',
          name: 'Never backed up',
          items: ['x'],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'templates': [
            remoteTemplate(
              id: 'tpl-1',
              name: 'From backup',
              items: ['y'],
              updatedAt: DateTime(2025, 6, 1),
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(templatesBox.keys.toSet(), {'local-only', 'tpl-1'});
    });

    test('a backup with no templates key leaves local templates untouched', () async {
      await templatesBox.put(
        'tpl-1',
        TodoTemplate(
          id: 'tpl-1',
          name: 'Kept',
          items: ['x'],
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {},
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(templatesBox.get('tpl-1')!.name, 'Kept');
    });
  });

  group('GoogleDriveSyncService project serialization round-trip', () {
    test('preserves previewSongAutoPath, parentProjectId, and ignoredNewerSongPath', () {
      final service = GoogleDriveSyncService();
      final original = TestFactories.makeProject(
        previewSongAutoPath: '/Users/artist/Live Sets/Bounces/mixdown.wav',
        parentProjectId: 'parent-project-id',
        ignoredNewerSongPath: '/Users/artist/Live Sets/Bounces/rejected.wav',
      );

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.previewSongAutoPath, '/Users/artist/Live Sets/Bounces/mixdown.wav');
      expect(restored.parentProjectId, 'parent-project-id');
      expect(restored.ignoredNewerSongPath, '/Users/artist/Live Sets/Bounces/rejected.wav');
    });

    test('preserves the version stacking links (#94)', () {
      // A stack is a row like any other in the Drive payload. Dropping these
      // fields on restore would scatter a stacked song back into loose files
      // and orphan the row holding its shared metadata.
      final service = GoogleDriveSyncService();
      final stack = TestFactories.makeProject(
        id: 'stack-1',
        isVirtual: true,
        memberProjectIds: const ['v1', 'v2', 'v3'],
        defaultLaunchMemberId: 'v2',
      );
      final member = TestFactories.makeProject(id: 'v2', stackId: 'stack-1');

      final restoredStack = service.deserializeProjectForTest(
        service.serializeProjectForTest(stack),
      );
      final restoredMember = service.deserializeProjectForTest(
        service.serializeProjectForTest(member),
      );

      expect(restoredStack.isVirtual, isTrue);
      expect(restoredStack.memberProjectIds, ['v1', 'v2', 'v3']);
      expect(restoredStack.defaultLaunchMemberId, 'v2');
      expect(restoredStack.versionCount, 3);
      expect(restoredMember.stackId, 'stack-1');
      expect(restoredMember.isStackMember, isTrue);
    });

    test('preserves the archived state (#116)', () {
      // An archived project's files are deliberately gone from filePath. Drop
      // these on restore and it comes back looking merely missing, with no
      // pointer to the archive holding the work.
      final service = GoogleDriveSyncService();
      final original = TestFactories.makeProject(
        archivePath: '/Volumes/Archive/Midnight.zip',
        archivedAt: DateTime(2026, 3, 4, 15, 30),
        archiveEntryPath: 'Midnight/Midnight.als',
      );

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.archivePath, '/Volumes/Archive/Midnight.zip');
      expect(restored.archivedAt, DateTime(2026, 3, 4, 15, 30));
      expect(restored.archiveEntryPath, 'Midnight/Midnight.als');
      expect(restored.isArchived, isTrue);
      expect(restored.isMissingFileCandidate, isFalse);
    });

    test('a project that was never archived round-trips unarchived', () {
      final service = GoogleDriveSyncService();

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(TestFactories.makeProject()),
      );

      expect(restored.isArchived, isFalse);
      expect(restored.archivedAt, isNull);
      expect(restored.archiveEntryPath, isNull);
    });

    test('preserves projectNotes', () {
      final service = GoogleDriveSyncService();
      final original = TestFactories.makeProject(
        projectNotes: 'Notes 1\nby Audio Crawler\n\nSome project notes',
      );

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.projectNotes, 'Notes 1\nby Audio Crawler\n\nSome project notes');
    });

    test('preserves sourceTemplateId', () {
      final service = GoogleDriveSyncService();
      final original = TestFactories.makeProject(sourceTemplateId: 'template-42');

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.sourceTemplateId, 'template-42');
    });

    test('preserves null sourceTemplateId', () {
      final service = GoogleDriveSyncService();
      final original = TestFactories.makeProject(sourceTemplateId: null);

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.sourceTemplateId, isNull);
    });

    test('preserves the parts list', () {
      final service = GoogleDriveSyncService();
      final original = TestFactories.makeProject(parts: [
        TestFactories.makePart(
          id: 'p1',
          name: 'Lead Vocals',
          performer: 'Nina',
          status: PartTakeStatus.earlyTake,
          notes: 'double-track the chorus',
        ),
        TestFactories.makePart(id: 'p2', name: 'Bass', performer: null),
      ]);

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.parts, original.parts);
    });

    test('a backup written before parts existed deserializes to an empty list', () {
      final service = GoogleDriveSyncService();
      final data = service.serializeProjectForTest(TestFactories.makeProject())
        ..remove('parts');

      expect(service.deserializeProjectForTest(data).parts, isEmpty);
    });
  });

  group('GoogleDriveSyncService.mergeData - project conflict resolution', () {
    // Regression: mergeData used to always overwrite local project metadata
    // (notes, todos, bpm, status, etc.) with whatever was in the remote
    // backup whenever the two differed, regardless of which side was
    // actually edited more recently. That meant the auto-backup timer (which
    // downloads+merges via syncDatabase before re-uploading) could silently
    // discard a local edit made after the last backup in favor of a stale
    // remote copy. The fix compares updatedAt and only lets remote win when
    // it is genuinely the newer side.
    late Directory tempDir;
    late ProjectRepository projectRepo;
    late ProfileRepository profileRepo;
    late Profile profile;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ProfileAdapter());
      final profilesBox = await Hive.openBox<Profile>('profiles');
      final settingsBox = await Hive.openBox<String>('settings');
      profileRepo = ProfileRepository(profilesBox: profilesBox, settingsBox: settingsBox);
      profile = await profileRepo.createProfile('Test Profile');
      projectRepo = await HiveTestHelper.createRepository(profileId: profile.id);
      await Hive.openBox<String>('app_settings');
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    Map<String, dynamic> remoteProjectMap({
      required String id,
      required DateTime updatedAt,
      String? notes,
      String? previewSongAutoPath,
      String? parentProjectId,
      String? ignoredNewerSongPath,
      List<Map<String, dynamic>>? parts,
    }) {
      return {
        'id': id,
        'filePath': '/remote/$id.als',
        'fileName': '$id.als',
        'fileSizeBytes': 1000,
        'lastModifiedAt': DateTime(2025, 1, 1).toIso8601String(),
        'status': 'Mixing',
        'fileExtension': '.als',
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'notes': notes,
        'previewSongAutoPath': previewSongAutoPath,
        'parentProjectId': parentProjectId,
        'ignoredNewerSongPath': ignoredNewerSongPath,
        'parts': parts,
      };
    }

    test('keeps local edits when local was modified after the remote copy', () async {
      final local = TestFactories.makeProject(
        id: 'p1',
        notes: 'Local edit made after last backup',
        updatedAt: DateTime(2025, 6, 1, 12, 0),
      );
      await projectRepo.projectsBox.put(local.id, local);

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'projects': [
            remoteProjectMap(
              id: 'p1',
              // Older than local's updatedAt — this is a stale remote copy.
              updatedAt: DateTime(2025, 6, 1, 10, 0),
              notes: 'Stale remote note',
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      final merged = projectRepo.projectsBox.get('p1');
      expect(merged!.notes, 'Local edit made after last backup');
    });

    test('takes remote edits when remote was modified after the local copy', () async {
      final local = TestFactories.makeProject(
        id: 'p2',
        notes: 'Old local note',
        updatedAt: DateTime(2025, 6, 1, 8, 0),
      );
      await projectRepo.projectsBox.put(local.id, local);

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'projects': [
            remoteProjectMap(
              id: 'p2',
              // Newer than local's updatedAt — remote genuinely has the latest edit.
              updatedAt: DateTime(2025, 6, 1, 12, 0),
              notes: 'Fresh remote note',
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      final merged = projectRepo.projectsBox.get('p2');
      expect(merged!.notes, 'Fresh remote note');
    });

    test('takes a newer remote parts list over the local one', () async {
      final local = TestFactories.makeProject(
        id: 'p-parts',
        updatedAt: DateTime(2025, 6, 1, 8, 0),
        parts: [TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex')],
      );
      await projectRepo.projectsBox.put(local.id, local);

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'projects': [
            remoteProjectMap(
              id: 'p-parts',
              updatedAt: DateTime(2025, 6, 1, 12, 0),
              parts: [
                TestFactories.makePart(
                  id: 'p1',
                  name: 'Drums',
                  performer: 'Alex',
                  status: PartTakeStatus.finalTake,
                ).toJson(),
                TestFactories.makePart(id: 'p2', name: 'Bass', performer: 'Sam')
                    .toJson(),
              ],
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      final merged = projectRepo.projectsBox.get('p-parts')!;
      expect(merged.parts.map((p) => p.name), ['Drums', 'Bass']);
      expect(merged.parts.first.status, PartTakeStatus.finalTake);
    });

    test('keeps a locally edited parts list when local is newer', () async {
      final local = TestFactories.makeProject(
        id: 'p-parts-local',
        updatedAt: DateTime(2025, 6, 1, 12, 0),
        parts: [
          TestFactories.makePart(
            id: 'p1',
            name: 'Drums',
            performer: 'Alex',
            status: PartTakeStatus.finalTake,
          ),
        ],
      );
      await projectRepo.projectsBox.put(local.id, local);

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'projects': [
            remoteProjectMap(
              id: 'p-parts-local',
              updatedAt: DateTime(2025, 6, 1, 10, 0),
              parts: [
                TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex')
                    .toJson(),
              ],
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      final merged = projectRepo.projectsBox.get('p-parts-local')!;
      expect(merged.parts.single.status, PartTakeStatus.finalTake);
    });

    test('restores previewSongAutoPath, parentProjectId, and ignoredNewerSongPath for a brand-new project from remote', () async {
      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'projects': [
            remoteProjectMap(
              id: 'p3',
              updatedAt: DateTime(2025, 6, 1),
              previewSongAutoPath: '/remote/Bounces/mixdown.wav',
              parentProjectId: 'parent-id',
              ignoredNewerSongPath: '/remote/Bounces/rejected.wav',
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      final restored = projectRepo.projectsBox.get('p3');
      expect(restored, isNotNull);
      expect(restored!.previewSongAutoPath, '/remote/Bounces/mixdown.wav');
      expect(restored.parentProjectId, 'parent-id');
      expect(restored.ignoredNewerSongPath, '/remote/Bounces/rejected.wav');
    });

    test(
      'keeps local lastModifiedAt/fileCreatedAt on desktop even when remote is newer '
      '(flutter test runs as a desktop process, so MobileUtils.isMobile() is false here; '
      'the mobile branch — where these must come from remote — cannot be exercised by a '
      'unit test without mocking Platform.isAndroid/isIOS, so it is not automated)',
      () async {
        final localFileCreatedAt = DateTime(2024, 3, 1);
        final localLastModifiedAt = DateTime(2025, 5, 1);
        final local = TestFactories.makeProject(
          id: 'p4',
          fileCreatedAt: localFileCreatedAt,
          lastModifiedAt: localLastModifiedAt,
          updatedAt: DateTime(2025, 6, 1, 8, 0),
        );
        await projectRepo.projectsBox.put(local.id, local);

        final service = GoogleDriveSyncService();
        await service.mergeData(
          remoteData: {
            'projects': [
              remoteProjectMap(
                id: 'p4',
                updatedAt: DateTime(2025, 6, 1, 12, 0),
                notes: 'Remote note that makes metadata differ',
              ),
            ],
          },
          projectRepo: projectRepo,
          profileRepo: profileRepo,
          downloadPreviewSongs: false,
        );

        final merged = projectRepo.projectsBox.get('p4');
        expect(merged!.fileCreatedAt, localFileCreatedAt);
        expect(merged.lastModifiedAt, localLastModifiedAt);
      },
    );
  });

  group('GoogleDriveSyncService._autoPreviewAlreadyMatches', () {
    // Regression: the auto-backup timer switched from uploadDatabase() to
    // syncDatabase() (which downloads+merges before re-uploading) so a newer
    // Drive backup from another device wouldn't be silently clobbered. That
    // meant every routine desktop auto-backup now runs mergeData()'s preview
    // song reconciliation too. For a project whose preview was only ever
    // auto-detected (previewSongAutoPath set, previewSongPath null) and had
    // been auto-uploaded to Drive, mergeData saw previewSongPath == null and
    // concluded "we don't have this file yet", re-downloading a byte-identical
    // copy under a UUID-based filename and writing it into previewSongPath —
    // which outranks previewSongAutoPath everywhere in the UI, so the desktop
    // preview silently switched to the new UUID-named duplicate and the
    // "auto-detected" badge disappeared. _autoPreviewAlreadyMatches() is the
    // guard added to catch this: mergeData now consults it before deciding a
    // preview needs to be (re)downloaded.
    //
    // Exercising this from mergeData() end-to-end would require a real
    // driveApi/credentials round trip (downloadPreviewSongFile talks to
    // Drive), so the closest automatable test is the helper itself, which
    // contains the actual decision logic that was missing before the fix.
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('auto_preview_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('returns true when the auto-detected file on disk matches the expected hash', () async {
      final autoPath = path.join(tempDir.path, 'mixdown.wav');
      await File(autoPath).writeAsBytes([1, 2, 3, 4]);
      final expectedHash = md5.convert([1, 2, 3, 4]).toString();

      final project = TestFactories.makeProject(previewSongAutoPath: autoPath);

      final service = GoogleDriveSyncService();
      expect(
        await service.autoPreviewAlreadyMatchesForTest(project, expectedHash),
        isTrue,
      );
    });

    test('falls back to the project\'s stored uploadedPreviewSongHash when expectedHash is null', () async {
      final autoPath = path.join(tempDir.path, 'mixdown.wav');
      await File(autoPath).writeAsBytes([5, 6, 7, 8]);
      final storedHash = md5.convert([5, 6, 7, 8]).toString();

      final project = TestFactories.makeProject(previewSongAutoPath: autoPath)
          .copyWith(uploadedPreviewSongHash: storedHash);

      final service = GoogleDriveSyncService();
      expect(
        await service.autoPreviewAlreadyMatchesForTest(project, null),
        isTrue,
      );
    });

    test('returns false when the auto-detected file\'s hash differs from Drive\'s', () async {
      final autoPath = path.join(tempDir.path, 'mixdown.wav');
      await File(autoPath).writeAsBytes([1, 2, 3, 4]);
      final differentHash = md5.convert([9, 9, 9, 9]).toString();

      final project = TestFactories.makeProject(previewSongAutoPath: autoPath);

      final service = GoogleDriveSyncService();
      expect(
        await service.autoPreviewAlreadyMatchesForTest(project, differentHash),
        isFalse,
      );
    });

    test('returns false when previewSongAutoPath is not set', () async {
      final project = TestFactories.makeProject();

      final service = GoogleDriveSyncService();
      expect(
        await service.autoPreviewAlreadyMatchesForTest(project, 'anyhash'),
        isFalse,
      );
    });

    test('returns false when the auto-detected file no longer exists on disk', () async {
      final missingPath = path.join(tempDir.path, 'does-not-exist.wav');
      final project = TestFactories.makeProject(previewSongAutoPath: missingPath);

      final service = GoogleDriveSyncService();
      expect(
        await service.autoPreviewAlreadyMatchesForTest(project, 'anyhash'),
        isFalse,
      );
    });
  });

  group('GoogleDriveSyncService._realPreviewFileNameOrNull', () {
    // Regression: when restoring a backup that predates the previewSongFileNames
    // manifest map, mergeData() fell back to path.basename(remoteProject.previewSongPath)
    // for the display name with no check on what that basename actually was. If the
    // remote project's own previewSongPath was itself a previously-downloaded Drive
    // copy (named "<uuid>_preview.<ext>" by downloadPreviewSongFile), that UUID name
    // would be written into previewSongFileName and propagate through the whole sync
    // mesh on every future re-upload (uploadDatabase prefers project.previewSongFileName
    // over recomputing it). The dashboard's _displayFileName() already refuses to
    // *show* a UUID name, but that only masked the bad data rather than preventing it
    // from being stored. _realPreviewFileNameOrNull() closes the gap at the source, so
    // all four merge/restore call sites that derive a name from a remote path can never
    // write a UUID-shaped name into previewSongFileName in the first place.
    late GoogleDriveSyncService service;

    setUp(() {
      service = GoogleDriveSyncService();
    });

    test('returns the basename for a real, non-UUID filename', () {
      expect(
        service.realPreviewFileNameOrNullForTest('/Users/artist/Live Sets/Bounces/mixdown_final.wav'),
        'mixdown_final.wav',
      );
    });

    test('returns null for a Drive-download-shaped UUID filename', () {
      expect(
        service.realPreviewFileNameOrNullForTest(
          '/Users/artist/AppSupport/preview_songs/3fa85f64-5717-4562-b3fc-2c963f66afa6_preview.mp3',
        ),
        isNull,
      );
    });

    test('is case-insensitive when matching the UUID pattern', () {
      expect(
        service.realPreviewFileNameOrNullForTest(
          '/tmp/3FA85F64-5717-4562-B3FC-2C963F66AFA6_preview.wav',
        ),
        isNull,
      );
    });

    test('returns null when the path itself is null', () {
      expect(service.realPreviewFileNameOrNullForTest(null), isNull);
    });
  });
}
