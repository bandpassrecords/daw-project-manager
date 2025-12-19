import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import '../models/profile.dart';
import '../providers/providers.dart';
import '../repository/profile_repository.dart';
import '../repository/project_repository.dart';
import '../services/scanner_service.dart';
import '../utils/app_paths.dart';
import 'dashboard_page.dart';

class ProfileManagerPage extends ConsumerStatefulWidget {
  const ProfileManagerPage({super.key});

  @override
  ConsumerState<ProfileManagerPage> createState() => _ProfileManagerPageState();
}

class _ProfileManagerPageState extends ConsumerState<ProfileManagerPage> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a profile name')),
      );
      return;
    }

    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      await profileRepo.createProfile(name);
      _nameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile "$name" created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create profile: $e')),
        );
      }
    }
  }

  Future<void> _switchProfile(String profileId) async {
    // Save provider references and container before any navigation that might unmount the widget
    final profileRepo = await ref.read(profileRepositoryProvider.future);
    final profileSwitchingNotifier = ref.read(profileSwitchingProvider.notifier);
    final container = ProviderScope.containerOf(context);
    
    try {
      await profileRepo.setCurrentProfileId(profileId);
      
      // Set profile switching state to show "Switching Profiles..." message
      profileSwitchingNotifier.setSwitching(true);
      
      // Navigate back to dashboard first so it can show the loading overlay
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Invalidate repository provider to reload with new profile (using saved container)
      container.invalidate(repositoryProvider);
      
      // Wait for repository to reload with new profile (using saved container)
      final repo = await container.read(repositoryProvider.future);
      
      // Trigger scan for the new profile's root folders (same as dashboard scan)
      await _scanProfileRoots(repo);
      
      // Mark profile switching as complete (using saved notifier)
      profileSwitchingNotifier.complete();
      
      // The dashboard will automatically show the updated projects
    } catch (e) {
      // Mark profile switching as complete even on error (using saved notifier)
      profileSwitchingNotifier.complete();
      // Error will be visible in the dashboard if needed
      if (kDebugMode) {
        print('Error switching profile: $e');
      }
    }
  }

  Future<void> _scanProfileRoots(ProjectRepository repo) async {
    final scanner = ScannerService();
    int foundCount = 0;
    
    // Clear missing files for the current profile
    await repo.clearMissingFiles();
    
    // Scan all root folders for the current profile (same logic as dashboard)
    // Use lightweight scan (fast, no full metadata extraction)
    final scanTime = DateTime.now();
    for (final root in repo.getRoots()) {
      await for (final entity in scanner.scanDirectory(root.path)) {
        await repo.upsertFromFileSystemEntity(entity, fullMetadata: false);
        foundCount++;
      }
      // Update lastScanAt timestamp for this root
      await repo.updateRootLastScanAt(root.id, scanTime);
    }
    
    // The dashboard will automatically show the updated projects
    // No need to show a message here as the scan state change will trigger UI updates
  }

  Future<String> _getProfilePhotosPath() async {
    final basePath = await getLocalAppDataPath();
    return path.join(basePath, 'profile_photos');
  }

  Future<void> _pickProfilePhoto(Profile profile) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final sourceFile = File(sourcePath);
      
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected file does not exist.')),
          );
        }
        return;
      }

      try {
        // Get profile photos directory
        final photosDirPath = await _getProfilePhotosPath();
        final photosDir = Directory(photosDirPath);
        
        // Create directory if it doesn't exist
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }

        // Copy file to profile photos directory with profile ID as name
        final fileExtension = path.extension(sourcePath);
        final destPath = path.join(photosDir.path, '${profile.id}$fileExtension');
        await sourceFile.copy(destPath);

        // Update profile with photo path
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        final updatedProfile = profile.copyWith(photoPath: destPath);
        await profileRepo.updateProfile(updatedProfile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile photo: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeProfilePhoto(Profile profile) async {
    if (profile.photoPath != null) {
      try {
        final photoFile = File(profile.photoPath!);
        if (await photoFile.exists()) {
          await photoFile.delete();
        }
        
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        final updatedProfile = profile.copyWith(clearPhotoPath: true);
        await profileRepo.updateProfile(updatedProfile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo removed.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove profile photo: $e')),
          );
        }
      }
    }
  }

  Future<void> _editProfile(Profile profile) async {
    final editController = TextEditingController(text: profile.name);
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D31),
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              decoration: const InputDecoration(
                labelText: 'Profile Name',
                hintText: 'Enter profile name',
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.pop(ctx, value.trim());
                }
              },
            ),
            const SizedBox(height: 16),
            // Profile photo preview and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (profile.photoPath != null && File(profile.photoPath!).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(profile.photoPath!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          width: 80,
                          height: 80,
                          child: Icon(Icons.broken_image),
                        );
                      },
                    ),
                  )
                else
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: Icon(Icons.person, size: 40),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Change Photo'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _pickProfilePhoto(profile);
                  },
                ),
                if (profile.photoPath != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _removeProfilePhoto(profile);
                    },
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx, newName);
              }
            },
            child: const Text('Save Name'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != profile.name) {
      try {
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        final updatedProfile = profile.copyWith(name: result);
        await profileRepo.updateProfile(updatedProfile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile renamed to "$result"')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to rename profile: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteProfile(Profile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D31),
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete "${profile.name}"? This will delete all projects, roots, and releases for this profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        await profileRepo.deleteProfile(profile.id);
        
        // Invalidate repository provider to reload with new profile
        ref.invalidate(repositoryProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile "${profile.name}" deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);
    final currentProfileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          // Window title bar
          if (!kDebugMode)
            GestureDetector(
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.restore();
                } else {
                  windowManager.maximize();
                }
              },
              child: Container(
                color: const Color(0xFF2B2D31),
                height: 40,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'Profile Manager',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    const WindowButtons(),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Create new profile section
            Card(
              color: const Color(0xFF2B2D31),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Profile Name',
                              hintText: 'e.g., Artist Name 1',
                            ),
                            onSubmitted: (_) => _createProfile(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _createProfile,
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Profiles list
            const Text(
              'Profiles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: profilesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading profiles: $error'),
                ),
                data: (profiles) {
                  if (profiles.isEmpty) {
                    return const Center(
                      child: Text('No profiles found. Create one above.'),
                    );
                  }

                  return currentProfileAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                    data: (currentProfile) {
                      return ListView.builder(
                        itemCount: profiles.length,
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          final isCurrent = currentProfile?.id == profile.id;

                          return Card(
                            color: isCurrent ? const Color(0xFF3C3F43) : const Color(0xFF2B2D31),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: profile.photoPath != null && File(profile.photoPath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.file(
                                        File(profile.photoPath!),
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: Icon(Icons.person),
                                          );
                                        },
                                      ),
                                    )
                                  : const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Icon(Icons.person),
                                    ),
                              title: Row(
                                children: [
                                  Text(
                                    profile.name,
                                    style: TextStyle(
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5A6B7A),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                'Created: ${profile.createdAt.toString().split('.')[0]}',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    color: Colors.white70,
                                    onPressed: () => _editProfile(profile),
                                    tooltip: 'Edit profile name',
                                  ),
                                  if (!isCurrent)
                                    TextButton(
                                      onPressed: () => _switchProfile(profile.id),
                                      child: const Text('Switch'),
                                    ),
                                  if (profiles.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red.shade300,
                                      onPressed: () => _deleteProfile(profile),
                                      tooltip: 'Delete profile',
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

