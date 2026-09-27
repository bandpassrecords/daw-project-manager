import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:daw_project_manager/models/ignored_path.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/playlist.dart';
import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/models/part_template.dart';
import 'package:daw_project_manager/models/project_event.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/models/project_template.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/models/release_file.dart';
import 'package:daw_project_manager/models/scan_root.dart';
import 'package:daw_project_manager/models/template_root.dart';
import 'package:daw_project_manager/models/todo_item.dart';
import 'package:daw_project_manager/models/todo_template.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';

/// Manages Hive lifecycle for unit tests.
///
/// Usage:
/// ```dart
/// late Directory tempDir;
/// late ProjectRepository repo;
///
/// setUp(() async {
///   tempDir = await HiveTestHelper.setUp();
///   repo = await HiveTestHelper.createRepository();
/// });
///
/// tearDown(() async {
///   await HiveTestHelper.tearDown(tempDir);
/// });
/// ```
class HiveTestHelper {
  static Future<Directory> setUp() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    _registerAdapters();
    return tempDir;
  }

  static Future<void> tearDown(Directory tempDir) async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MusicProjectAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ScanRootAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ReleaseAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ReleaseFileAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ProfileAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(TodoItemAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(IgnoredPathAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(PlaylistAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(TodoTemplateAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(ProjectEventAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(ProjectTemplateAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(TemplateRootAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ProjectPartAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(PartTemplateAdapter());
  }

  /// Creates a [ProfileRepository] backed by the same temp Hive instance,
  /// for tests that need multi-profile behavior (e.g. demo data generation).
  static Future<ProfileRepository> createProfileRepository() async {
    final profilesBox = await Hive.openBox<Profile>(ProfileRepository.profilesBoxName);
    final settingsBox = await Hive.openBox<String>('settings');
    return ProfileRepository(profilesBox: profilesBox, settingsBox: settingsBox);
  }

  static Future<ProjectRepository> createRepository({
    String profileId = 'test-profile',
    DeadlineNotificationRescheduler? rescheduleDeadlineNotifications,
  }) async {
    final projectsBox = await Hive.openBox<MusicProject>('${profileId}_projects');
    final rootsBox = await Hive.openBox<ScanRoot>('${profileId}_roots');
    final ignoredPathsBox = await Hive.openBox<IgnoredPath>('${profileId}_ignored_paths');
    final releasesBox = await Hive.openBox<Release>('${profileId}_releases');
    final playlistsBox = await Hive.openBox<Playlist>('${profileId}_playlists');
    final eventsBox = await Hive.openBox<ProjectEvent>('${profileId}_events');
    final appSettingsBox = await Hive.openBox<String>('app_settings');

    return ProjectRepository(
      profileId: profileId,
      projectsBox: projectsBox,
      rootsBox: rootsBox,
      ignoredPathsBox: ignoredPathsBox,
      releasesBox: releasesBox,
      playlistsBox: playlistsBox,
      eventsBox: eventsBox,
      appSettingsBox: appSettingsBox,
      rescheduleDeadlineNotifications:
          rescheduleDeadlineNotifications ?? _noDeadlineNotifications,
    );
  }

  static Future<void> _noDeadlineNotifications({
    required List<MusicProject> projects,
    required List<Release> releases,
  }) async {}
}
