import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../providers/providers.dart';
import '../repository/profile_repository.dart';
import '../repository/project_repository.dart';
import '../services/scanner_service.dart';

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
    final scanTime = DateTime.now();
    for (final root in repo.getRoots()) {
      await for (final entity in scanner.scanDirectory(root.path)) {
        await repo.upsertFromFileSystemEntity(entity);
        foundCount++;
      }
      // Update lastScanAt timestamp for this root
      await repo.updateRootLastScanAt(root.id, scanTime);
    }
    
    // The dashboard will automatically show the updated projects
    // No need to show a message here as the scan state change will trigger UI updates
  }

  Future<void> _editProfile(Profile profile) async {
    final editController = TextEditingController(text: profile.name);
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D31),
        title: const Text('Edit Profile Name'),
        content: TextField(
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
            child: const Text('Save'),
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
      appBar: AppBar(
        title: const Text('Profile Manager'),
      ),
      body: Padding(
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
    );
  }
}

