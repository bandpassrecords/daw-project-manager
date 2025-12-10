import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/music_project.dart';
import '../models/scan_root.dart';
import '../models/release.dart';
import '../utils/app_paths.dart';

class ProfileRepository {
  static const profilesBoxName = 'profiles';
  static const currentProfileKey = 'current_profile_id';

  final Box<Profile> profilesBox;
  final Box<String> settingsBox; // For storing current profile ID
  final _uuid = const Uuid();

  ProfileRepository({
    required this.profilesBox,
    required this.settingsBox,
  });

  static Future<ProfileRepository> init() async {
    // Initialize Hive with LocalAppData directory
    final appDataPath = await getLocalAppDataPath();
    Hive.init(appDataPath);
    
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ProfileAdapter());
    }

    final profiles = await Hive.openBox<Profile>(profilesBoxName);
    final settings = await Hive.openBox<String>('settings');
    
    final repo = ProfileRepository(
      profilesBox: profiles,
      settingsBox: settings,
    );
    
    // Migrate existing data: if no profiles exist, create a default profile
    await repo._migrateToDefaultProfile();
    
    return repo;
  }

  /// Migrates existing data to a default profile if no profiles exist
  Future<void> _migrateToDefaultProfile() async {
    if (profilesBox.isEmpty) {
      // Create default profile
      final defaultProfile = Profile(
        id: _uuid.v4(),
        name: 'Default',
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );
      await profilesBox.put(defaultProfile.id, defaultProfile);
      await setCurrentProfileId(defaultProfile.id);
      
      // Migrate existing data from old boxes to default profile boxes
      await _migrateExistingData(defaultProfile.id);
    } else {
      // If profiles exist but no current profile is set, set the first one
      final currentId = getCurrentProfileId();
      if (currentId == null && profilesBox.isNotEmpty) {
        final firstProfile = profilesBox.values.first;
        await setCurrentProfileId(firstProfile.id);
      }
    }
  }
  
  /// Migrates existing data from old non-profile boxes to profile-specific boxes
  Future<void> _migrateExistingData(String profileId) async {
    try {
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MusicProjectAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ScanRootAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ReleaseAdapter());
      }
      
      // Check if old boxes exist and have data
      try {
        final oldProjectsBox = await Hive.openBox<MusicProject>('projects');
        if (oldProjectsBox.isNotEmpty) {
          final newProjectsBox = await Hive.openBox<MusicProject>('${profileId}_projects');
          for (var key in oldProjectsBox.keys) {
            if (!newProjectsBox.containsKey(key)) {
              final value = oldProjectsBox.get(key);
              if (value != null) {
                await newProjectsBox.put(key, value);
              }
            }
          }
        }
      } catch (_) {
        // Old projects box doesn't exist or can't be opened
      }
      
      try {
        final oldRootsBox = await Hive.openBox<ScanRoot>('roots');
        if (oldRootsBox.isNotEmpty) {
          final newRootsBox = await Hive.openBox<ScanRoot>('${profileId}_roots');
          for (var key in oldRootsBox.keys) {
            if (!newRootsBox.containsKey(key)) {
              final value = oldRootsBox.get(key);
              if (value != null) {
                await newRootsBox.put(key, value);
              }
            }
          }
        }
      } catch (_) {
        // Old roots box doesn't exist or can't be opened
      }
      
      try {
        final oldReleasesBox = await Hive.openBox<Release>('releases');
        if (oldReleasesBox.isNotEmpty) {
          final newReleasesBox = await Hive.openBox<Release>('${profileId}_releases');
          for (var key in oldReleasesBox.keys) {
            if (!newReleasesBox.containsKey(key)) {
              final value = oldReleasesBox.get(key);
              if (value != null) {
                await newReleasesBox.put(key, value);
              }
            }
          }
        }
      } catch (_) {
        // Old releases box doesn't exist or can't be opened
      }
    } catch (e) {
      // If migration fails, it's okay - the old boxes might not exist
      // This is expected on first run
    }
  }

  // Profile management
  Future<Profile> createProfile(String name) async {
    final profile = Profile(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
    await profilesBox.put(profile.id, profile);
    return profile;
  }

  Future<void> updateProfile(Profile profile) async {
    await profilesBox.put(profile.id, profile);
  }

  Future<void> deleteProfile(String profileId) async {
    // Don't allow deleting if it's the only profile
    if (profilesBox.length <= 1) {
      throw Exception('Cannot delete the last remaining profile');
    }
    
    final currentId = getCurrentProfileId();
    await profilesBox.delete(profileId);
    
    // If we deleted the current profile, switch to the first available one
    if (currentId == profileId) {
      final remainingProfiles = profilesBox.values.toList();
      if (remainingProfiles.isNotEmpty) {
        await setCurrentProfileId(remainingProfiles.first.id);
      }
    }
  }

  List<Profile> getAllProfiles() => profilesBox.values.toList(growable: false);

  Profile? getProfileById(String id) {
    return profilesBox.get(id);
  }

  // Current profile management
  String? getCurrentProfileId() {
    return settingsBox.get(currentProfileKey);
  }

  Future<void> setCurrentProfileId(String profileId) async {
    await settingsBox.put(currentProfileKey, profileId);
    // Update lastUsedAt
    final profile = profilesBox.get(profileId);
    if (profile != null) {
      await updateProfile(profile.copyWith(lastUsedAt: DateTime.now()));
    }
  }

  Profile? getCurrentProfile() {
    final currentId = getCurrentProfileId();
    if (currentId == null) return null;
    return getProfileById(currentId);
  }

  Stream<List<Profile>> watchAllProfiles() async* {
    yield profilesBox.values.toList();
    yield* profilesBox.watch().map((_) => profilesBox.values.toList());
  }

  Stream<BoxEvent> watchProfiles() => profilesBox.watch();
}

