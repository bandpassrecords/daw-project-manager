import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/intl.dart';
import '../models/profile.dart';
import '../providers/providers.dart';
import '../repository/profile_repository.dart';
import '../repository/project_repository.dart';
import '../services/scanner_service.dart';
import '../utils/app_paths.dart';
import '../generated/l10n/app_localizations.dart';
import 'dashboard_page.dart';
import 'profile_view_page.dart';
import 'widgets/language_switcher.dart';
import '../services/backup_service.dart';

class ProfileManagerPage extends ConsumerStatefulWidget {
  const ProfileManagerPage({super.key});

  @override
  ConsumerState<ProfileManagerPage> createState() => _ProfileManagerPageState();
}

class _ProfileManagerPageState extends ConsumerState<ProfileManagerPage> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showCreateProfileDialog() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createNewProfile),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.profileName,
            hintText: AppLocalizations.of(context)!.profileName,
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, nameController.text.trim());
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _createProfile(result);
    }
  }

  Future<void> _createProfile(String name) async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      await profileRepo.createProfile(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileCreated(name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateProfile(e.toString()))),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.selectedFileDoesNotExist)),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.profilePhotoUpdated)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveProfilePhoto(e.toString()))),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.profilePhotoRemoved)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToRemoveProfilePhoto(e.toString()))),
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
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.editProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.profileName,
                hintText: AppLocalizations.of(context)!.profileName,
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
                  label: Text(AppLocalizations.of(context)!.changePhoto),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _pickProfilePhoto(profile);
                  },
                ),
                if (profile.photoPath != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete),
                    label: Text(AppLocalizations.of(context)!.remove),
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx, newName);
              }
            },
            child: Text(AppLocalizations.of(context)!.saveName),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.profileRenamed(result))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToRenameProfile(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _deleteProfile(Profile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.deleteProfile),
        content: Text(AppLocalizations.of(context)!.deleteProfileMessage(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.profileDeleted(profile.name))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToDeleteProfile(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _showProfileContextMenu(BuildContext context, Profile profile, Offset position, bool isCurrent, int totalProfiles) async {
    final l10n = AppLocalizations.of(context)!;
    
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.visibility, size: 20),
              const SizedBox(width: 8),
              Text('View Profile'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 8),
              Text(l10n.tooltipEditProfileName),
            ],
          ),
        ),
        if (!isCurrent)
          PopupMenuItem<String>(
            value: 'switch',
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, size: 20),
                const SizedBox(width: 8),
                Text(l10n.switchProfile),
              ],
            ),
          ),
        if (totalProfiles > 1)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
                const SizedBox(width: 8),
                Text(l10n.delete, style: TextStyle(color: Colors.red.shade300)),
              ],
            ),
          ),
      ],
      color: Theme.of(context).cardColor,
    );

    if (result != null && mounted) {
      switch (result) {
        case 'view':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileViewPage(profileId: profile.id),
            ),
          );
          break;
        case 'edit':
          await _editProfile(profile);
          break;
        case 'switch':
          await _switchProfile(profile.id);
          break;
        case 'delete':
          await _deleteProfile(profile);
          break;
      }
    }
  }

  Future<void> _exportBackup() async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfileId = profileRepo.getCurrentProfileId();
      if (currentProfileId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.noProfileSelected)),
          );
        }
        return;
      }

      final projectRepo = await ref.read(repositoryProvider.future);
      
      final file = await BackupService.exportBackup(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        profileId: currentProfileId,
        exportDialogTitle: AppLocalizations.of(context)!.exportBackupDialogTitle,
      );

      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.backupExportedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToExportBackup(e.toString()))),
        );
      }
    }
  }

  Future<void> _showImportDialog() async {
    ImportMode? selectedMode = ImportMode.merge; // Default to merge mode
    final profileNameController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocalizations.of(context)!.importBackup),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.importBackupMessage),
                const SizedBox(height: 16),
                RadioListTile<ImportMode>(
                  title: Text(AppLocalizations.of(context)!.mergeWithCurrentProfile),
                  value: ImportMode.merge,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value;
                    });
                  },
                ),
                RadioListTile<ImportMode>(
                  title: Text(AppLocalizations.of(context)!.replaceCurrentProfile),
                  value: ImportMode.replace,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value;
                    });
                  },
                ),
                RadioListTile<ImportMode>(
                  title: Text(AppLocalizations.of(context)!.createNewProfileForImport),
                  value: ImportMode.createNewProfile,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value;
                    });
                  },
                ),
                if (selectedMode == ImportMode.createNewProfile) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: profileNameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.profileName,
                      hintText: AppLocalizations.of(context)!.profileName,
                    ),
                    autofocus: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMode == ImportMode.createNewProfile) {
                  final name = profileNameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(ctx)!.pleaseEnterProfileName)),
                    );
                    return;
                  }
                  Navigator.pop(ctx, {
                    'mode': selectedMode,
                    'profileName': name,
                  });
                } else {
                  Navigator.pop(ctx, {
                    'mode': selectedMode,
                  });
                }
              },
              style: selectedMode == ImportMode.replace
                  ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
                  : null,
              child: Text(_getImportButtonText(selectedMode!)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final mode = result['mode'] as ImportMode;
      final profileName = result['profileName'] as String?;
      await _importBackup(importMode: mode, newProfileName: profileName);
    }
  }

  String _getImportButtonText(ImportMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ImportMode.merge:
        return l10n.mergeWithCurrentProfile;
      case ImportMode.replace:
        return l10n.replaceCurrentProfile;
      case ImportMode.createNewProfile:
        return l10n.create;
    }
  }

  Future<void> _importBackup({
    required ImportMode importMode,
    String? newProfileName,
  }) async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfileId = profileRepo.getCurrentProfileId();
      
      // For createNewProfile mode, we don't need currentProfileId or projectRepo yet
      ProjectRepository? projectRepo;
      if (importMode != ImportMode.createNewProfile) {
        if (currentProfileId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.noProfileSelected)),
            );
          }
          return;
        }
        projectRepo = await ref.read(repositoryProvider.future);
      }
      
      final importResult = await BackupService.importBackup(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        currentProfileId: currentProfileId,
        importMode: importMode,
        newProfileName: newProfileName,
        importDialogTitle: AppLocalizations.of(context)!.importBackupDialogTitle,
        invalidBackupFormatMessage: AppLocalizations.of(context)!.invalidBackupFileFormat,
        profileNameRequiredMessage: AppLocalizations.of(context)!.profileNameRequiredForNewProfile,
        currentProfileRequiredMessage: AppLocalizations.of(context)!.currentProfileRequired,
      );

      if (importResult.cancelled) {
        return;
      }

      if (mounted) {
        String message;
        if (importMode == ImportMode.createNewProfile && importResult.newProfileId != null) {
          message = AppLocalizations.of(context)!.backupImportedToNewProfile(
            newProfileName ?? '',
            importResult.projectsCount,
            importResult.rootsCount,
            importResult.releasesCount,
          );
        } else {
          message = AppLocalizations.of(context)!.backupImportedSuccessfully(
            importResult.projectsCount,
            importResult.rootsCount,
            importResult.releasesCount,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToImportBackup(e.toString()))),
        );
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
                color: Theme.of(context).cardColor,
                height: 40,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
                      onPressed: () => Navigator.pop(context),
                      tooltip: AppLocalizations.of(context)!.back,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        AppLocalizations.of(context)!.profileManager,
                        style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    const LanguageSwitcher(),
                    const SizedBox(width: 8),
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
            // Backup/Restore section
            Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.backupAndRestore,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: Text(AppLocalizations.of(context)!.exportBackup),
                          onPressed: () => _exportBackup(),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: Text(AppLocalizations.of(context)!.importBackup),
                          onPressed: () => _showImportDialog(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Profiles list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.profiles,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: AppLocalizations.of(context)!.createNewProfile,
                  onPressed: _showCreateProfileDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: profilesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(AppLocalizations.of(context)!.errorLoadingProfiles(error.toString())),
                ),
                data: (profiles) {
                  if (profiles.isEmpty) {
                    return Center(
                      child: Text(AppLocalizations.of(context)!.noProfilesFound),
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

                          return GestureDetector(
                            onDoubleTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProfileViewPage(profileId: profile.id),
                                ),
                              );
                            },
                            onSecondaryTapDown: (TapDownDetails details) {
                              _showProfileContextMenu(context, profile, details.globalPosition, isCurrent, profiles.length);
                            },
                            child: Card(
                              color: isCurrent 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                  : Theme.of(context).cardColor,
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
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.active,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility),
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProfileViewPage(profileId: profile.id),
                                          ),
                                        );
                                      },
                                      tooltip: 'View Profile',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      onPressed: () => _editProfile(profile),
                                      tooltip: AppLocalizations.of(context)!.tooltipEditProfileName,
                                    ),
                                    if (!isCurrent)
                                      TextButton(
                                        onPressed: () => _switchProfile(profile.id),
                                        child: Text(AppLocalizations.of(context)!.switchProfile),
                                      ),
                                    if (profiles.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.red.shade300,
                                        onPressed: () => _deleteProfile(profile),
                                        tooltip: AppLocalizations.of(context)!.delete,
                                      ),
                                  ],
                                ),
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

