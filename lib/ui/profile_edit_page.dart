import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'widgets/desktop_title_bar.dart';
import 'package:archive/archive.dart';
import '../models/profile.dart';
import '../providers/providers.dart';
import '../utils/app_paths.dart';
import '../utils/mobile_utils.dart';
import '../utils/file_launcher.dart';
import '../generated/l10n/app_localizations.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  final String profileId;

  const ProfileEditPage({
    super.key,
    required this.profileId,
  });

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _bioController = TextEditingController();
  final _assetNameController = TextEditingController();
  final _nameController = TextEditingController();
  Timer? _nameSaveTimer;
  Timer? _bioSaveTimer;

  @override
  void dispose() {
    _nameSaveTimer?.cancel();
    _bioSaveTimer?.cancel();
    _bioController.dispose();
    _assetNameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<String> _getProfileAssetsPath() async {
    final basePath = await getLocalAppDataPath();
    return path.join(basePath, 'profile_assets', widget.profileId);
  }

  Future<String> _getProfilePhotosPath() async {
    final basePath = await getLocalAppDataPath();
    return path.join(basePath, 'profile_photos');
  }

  void _scheduleNameAutoSave(Profile profile) {
    _nameSaveTimer?.cancel();
    _nameSaveTimer = Timer(const Duration(milliseconds: 500), () => _saveName(profile));
  }

  // Silent auto-save, same rationale as _saveBio above.
  Future<void> _saveName(Profile profile) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == profile.name) return;

    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      await profileRepo.updateProfile(profile.copyWith(name: newName));
      ref.invalidate(currentProfileProvider);
      ref.invalidate(allProfilesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToRenameProfile(e.toString()))),
        );
      }
    }
  }

  Future<void> _pickProfilePhoto(Profile profile) async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;

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
      final photosDirPath = await _getProfilePhotosPath();
      final photosDir = Directory(photosDirPath);
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileExtension = path.extension(sourcePath);
      final destPath = path.join(photosDir.path, '${profile.id}$fileExtension');
      await sourceFile.copy(destPath);

      final profileRepo = await ref.read(profileRepositoryProvider.future);
      await profileRepo.updateProfile(profile.copyWith(photoPath: destPath));
      ref.invalidate(currentProfileProvider);
      ref.invalidate(allProfilesProvider);

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

  Future<void> _removeProfilePhoto(Profile profile) async {
    if (profile.photoPath == null) return;
    try {
      final photoFile = File(profile.photoPath!);
      if (await photoFile.exists()) {
        await photoFile.delete();
      }

      final profileRepo = await ref.read(profileRepositoryProvider.future);
      await profileRepo.updateProfile(profile.copyWith(clearPhotoPath: true));
      ref.invalidate(currentProfileProvider);
      ref.invalidate(allProfilesProvider);

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

  Future<void> _pickFile({
    required String assetType,
    required Function(String) onFileSelected,
  }) async {
    final result = await FilePicker.pickFiles(
      type: assetType == 'image' ? FileType.image : FileType.any,
    );

    if (result == null || result.files.single.path == null) return;

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
      final assetsDirPath = await _getProfileAssetsPath();
      final assetsDir = Directory(assetsDirPath);

      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }

      final fileExtension = path.extension(sourcePath);
      final fileName = '${assetType}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final destPath = path.join(assetsDir.path, fileName);
      await sourceFile.copy(destPath);

      onFileSelected(destPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveBiography(e.toString()))),
        );
      }
    }
  }

  void _scheduleBioAutoSave() {
    _bioSaveTimer?.cancel();
    _bioSaveTimer = Timer(const Duration(milliseconds: 500), _saveBio);
  }

  // Silent auto-save (no success snackbar) — triggered from typing, the same
  // way project_detail_page.dart debounces its own fields, rather than an
  // explicit Save button the user has to remember to press.
  Future<void> _saveBio() async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfile = profileRepo.getProfileById(widget.profileId);
      if (currentProfile == null) return;

      final updatedProfile = currentProfile.copyWith(
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      );

      await profileRepo.updateProfile(updatedProfile);
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveBiography(e.toString()))),
        );
      }
    }
  }

  Future<void> _downloadFile(String filePath, String suggestedFileName) async {
    final dialogTitle = AppLocalizations.of(context)!.saveFileDialogTitle;
    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.fileNotFound)),
          );
        }
        return;
      }

      final savePath = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: suggestedFileName,
        type: FileType.any,
      );

      if (savePath == null) return; // User cancelled

      final destFile = File(savePath);
      await sourceFile.copy(destFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileSavedTo(path.basename(savePath)))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToDownloadFile(e.toString()))),
        );
      }
    }
  }

  Future<void> _downloadAllFiles(Profile profile) async {
    final dialogTitle =
        AppLocalizations.of(context)!.saveAllFilesAsZipDialogTitle;
    final filesToDownload = <MapEntry<String, String>>[];

    // Add biography if present
    if (profile.bio != null && profile.bio!.trim().isNotEmpty) {
      filesToDownload.add(MapEntry('biography.txt', 'biography.txt')); // Special marker
    }

    // Add all artwork files
    final allArtworkPaths = profile.getAllArtworkPaths();
    for (int i = 0; i < allArtworkPaths.length; i++) {
      final artworkPath = allArtworkPaths[i];
      if (File(artworkPath).existsSync()) {
        final ext = path.extension(artworkPath);
        filesToDownload.add(MapEntry('artwork_${i + 1}$ext', artworkPath));
      }
    }

    // Add all press kit files
    final allPressKitPaths = profile.getAllPressKitPaths();
    for (final pressKitPath in allPressKitPaths) {
      if (File(pressKitPath).existsSync()) {
        filesToDownload.add(MapEntry(path.basename(pressKitPath), pressKitPath));
      }
    }

    if (profile.additionalAssets != null) {
      for (final entry in profile.additionalAssets!.entries) {
        if (File(entry.value).existsSync()) {
          filesToDownload.add(MapEntry(entry.key + path.extension(entry.value), entry.value));
        }
      }
    }

    if (filesToDownload.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noFilesToDownload)),
        );
      }
      return;
    }

    final safeName = profile.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final savePath = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: '${safeName}_profile_assets.zip',
      type: FileType.any,
    );

    if (savePath == null) return; // User cancelled

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.creatingZipFile,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final zipFile = File(savePath);
      if (!await zipFile.parent.exists()) {
        await zipFile.parent.create(recursive: true);
      }
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      final archive = Archive();

      for (final entry in filesToDownload) {
        final file = File(entry.value);
        if (await file.exists()) {
          final fileData = await file.readAsBytes();
          archive.addFile(
            ArchiveFile(
              entry.key,
              fileData.length,
              fileData,
            ),
          );
        }
      }

      // Handle biography as special case
      for (final entry in filesToDownload) {
        if (entry.value == 'biography.txt') {
          final bioText = profile.bio ?? '';
          final bioBytes = utf8.encode(bioText);
          archive.addFile(
            ArchiveFile(
              'biography.txt',
              bioBytes.length,
              bioBytes,
            ),
          );
        } else {
          final file = File(entry.value);
          if (await file.exists()) {
            final fileData = await file.readAsBytes();
            archive.addFile(
              ArchiveFile(
                entry.key,
                fileData.length,
                fileData,
              ),
            );
          }
        }
      }

      final zipData = ZipEncoder().encode(archive);
      await zipFile.writeAsBytes(zipData);
    
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.allFilesSavedTo(path.basename(savePath)))),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateZip(e.toString()))),
        );
      }
    }
  }

  Future<void> _addArtwork() async {
    await _pickFile(
      assetType: 'artwork',
      onFileSelected: (filePath) async {
        try {
          final profileRepo = await ref.read(profileRepositoryProvider.future);
          final currentProfile = profileRepo.getProfileById(widget.profileId);
          if (currentProfile != null) {
            final currentArtworkPaths = List<String>.from(currentProfile.getAllArtworkPaths());
            if (!currentArtworkPaths.contains(filePath)) {
              currentArtworkPaths.add(filePath);
            }
            // getAllArtworkPaths() folds the legacy singular artworkPath in
            // above, so it must be cleared here — otherwise it keeps
            // resurrecting itself (and duplicating into artworkPaths) on
            // every future read, regardless of what artworkPaths says.
            final updatedProfile = currentProfile.copyWith(
              artworkPaths: currentArtworkPaths,
              clearArtworkPath: true,
            );
            await profileRepo.updateProfile(updatedProfile);
            ref.invalidate(currentProfileProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.artworkAdded)),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddArtwork(e.toString()))),
            );
          }
        }
      },
    );
  }

  Future<void> _removeArtwork(String artworkPath) async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfile = profileRepo.getProfileById(widget.profileId);
      if (currentProfile != null) {
        final currentArtworkPaths = List<String>.from(currentProfile.getAllArtworkPaths());
        currentArtworkPaths.remove(artworkPath);
        // Same reason as _addArtwork: clear the legacy singular field so a
        // removed artwork doesn't reappear from it on the next read.
        final updatedProfile = currentProfile.copyWith(
          artworkPaths: currentArtworkPaths.isEmpty ? null : currentArtworkPaths,
          clearArtworkPath: true,
        );
        await profileRepo.updateProfile(updatedProfile);
        ref.invalidate(currentProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.artworkRemoved)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToRemoveArtwork(e.toString()))),
        );
      }
    }
  }

  Future<void> _addPressKitFile() async {
    await _pickFile(
      assetType: 'presskit',
      onFileSelected: (filePath) async {
        try {
          final profileRepo = await ref.read(profileRepositoryProvider.future);
          final currentProfile = profileRepo.getProfileById(widget.profileId);
          if (currentProfile != null) {
            final currentPressKitPaths = List<String>.from(currentProfile.getAllPressKitPaths());
            if (!currentPressKitPaths.contains(filePath)) {
              currentPressKitPaths.add(filePath);
            }
            // Same reason as artwork above: fold in and retire the legacy
            // singular pressKitPath so it can't resurrect a removed file.
            final updatedProfile = currentProfile.copyWith(
              pressKitPaths: currentPressKitPaths,
              clearPressKitPath: true,
            );
            await profileRepo.updateProfile(updatedProfile);
            ref.invalidate(currentProfileProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.pressKitFileAdded)),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddPressKitFile(e.toString()))),
            );
          }
        }
      },
    );
  }

  Future<void> _removePressKitFile(String pressKitPath) async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfile = profileRepo.getProfileById(widget.profileId);
      if (currentProfile != null) {
        final currentPressKitPaths = List<String>.from(currentProfile.getAllPressKitPaths());
        currentPressKitPaths.remove(pressKitPath);
        final updatedProfile = currentProfile.copyWith(
          pressKitPaths: currentPressKitPaths.isEmpty ? null : currentPressKitPaths,
          clearPressKitPath: true,
        );
        await profileRepo.updateProfile(updatedProfile);
        ref.invalidate(currentProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.pressKitFileRemoved)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToRemovePressKitFile(e.toString()))),
        );
      }
    }
  }

  Future<void> _showSelectFilesDialog(Profile profile) async {
    final selectedFiles = <String, String>{}; // Map of display name to file path

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final allArtworkPaths = profile.getAllArtworkPaths();
          final allPressKitPaths = profile.getAllPressKitPaths();
          final allAdditionalAssets = profile.additionalAssets ?? {};

          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.selectFilesToDownload),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Biography option
                    if (profile.bio != null && profile.bio!.trim().isNotEmpty)
                      CheckboxListTile(
                        title: Text(AppLocalizations.of(context)!.biography),
                        subtitle: Text(AppLocalizations.of(context)!.biographyWillBeSaved),
                        value: selectedFiles.containsKey('biography.txt'),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedFiles['biography.txt'] = 'biography.txt'; // Special marker
                            } else {
                              selectedFiles.remove('biography.txt');
                            }
                          });
                        },
                      ),
                    const Divider(),
                    // Artwork files
                    if (allArtworkPaths.isNotEmpty) ...[
                      Text(AppLocalizations.of(context)!.artworkFiles, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...allArtworkPaths.asMap().entries.map((entry) {
                        final index = entry.key;
                        final artworkPath = entry.value;
                        final fileName = 'artwork_${index + 1}${path.extension(artworkPath)}';
                        final fileExists = File(artworkPath).existsSync();
                        return CheckboxListTile(
                          title: Text(fileName),
                          subtitle: Text(fileExists ? path.basename(artworkPath) : AppLocalizations.of(context)!.fileNotFound),
                          value: selectedFiles.containsKey(fileName),
                          enabled: fileExists,
                          onChanged: fileExists ? (value) {
                            setState(() {
                              if (value == true) {
                                selectedFiles[fileName] = artworkPath;
                              } else {
                                selectedFiles.remove(fileName);
                              }
                            });
                          } : null,
                        );
                      }),
                      const Divider(),
                    ],
                    // Press Kit files
                    if (allPressKitPaths.isNotEmpty) ...[
                      Text(AppLocalizations.of(context)!.pressKitFiles, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...allPressKitPaths.asMap().entries.map((entry) {
                        final pressKitPath = entry.value;
                        final fileName = path.basename(pressKitPath);
                        final fileExists = File(pressKitPath).existsSync();
                        return CheckboxListTile(
                          title: Text(fileName),
                          subtitle: Text(fileExists ? AppLocalizations.of(context)!.pressKitFile : AppLocalizations.of(context)!.fileNotFound),
                          value: selectedFiles.containsKey(fileName),
                          enabled: fileExists,
                          onChanged: fileExists ? (value) {
                            setState(() {
                              if (value == true) {
                                selectedFiles[fileName] = pressKitPath;
                              } else {
                                selectedFiles.remove(fileName);
                              }
                            });
                          } : null,
                        );
                      }),
                      const Divider(),
                    ],
                    // Additional Assets
                    if (allAdditionalAssets.isNotEmpty) ...[
                      Text(AppLocalizations.of(context)!.additionalAssets, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...allAdditionalAssets.entries.map((entry) {
                        final assetName = entry.key;
                        final assetPath = entry.value;
                        final fileName = '$assetName${path.extension(assetPath)}';
                        final fileExists = File(assetPath).existsSync();
                        return CheckboxListTile(
                          title: Text(assetName),
                          subtitle: Text(fileExists ? path.basename(assetPath) : AppLocalizations.of(context)!.fileNotFound),
                          value: selectedFiles.containsKey(fileName),
                          enabled: fileExists,
                          onChanged: fileExists ? (value) {
                            setState(() {
                              if (value == true) {
                                selectedFiles[fileName] = assetPath;
                              } else {
                                selectedFiles.remove(fileName);
                              }
                            });
                          } : null,
                        );
                      }),
                    ],
                    if (selectedFiles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'No files selected',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: selectedFiles.isEmpty
                    ? null
                    : () => Navigator.pop(context, selectedFiles),
                child: Text(AppLocalizations.of(context)!.downloadNFiles(selectedFiles.length, selectedFiles.length == 1 ? '' : 's')),
              ),
            ],
          );
        },
      ),
    ).then((result) {
      if (result != null && result is Map<String, String>) {
        _downloadSelectedFiles(profile, result);
      }
    });
  }

  Future<void> _downloadSelectedFiles(Profile profile, Map<String, String> selectedFiles) async {
    if (selectedFiles.isEmpty) return;
    final dialogTitle =
        AppLocalizations.of(context)!.saveSelectedFilesAsZipDialogTitle;

    final safeName = profile.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final savePath = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: '${safeName}_selected_files.zip',
      type: FileType.any,
    );

    if (savePath == null) return; // User cancelled

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.creatingZipFile,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final zipFile = File(savePath);
      if (!await zipFile.parent.exists()) {
        await zipFile.parent.create(recursive: true);
      }
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      final archive = Archive();

      for (final entry in selectedFiles.entries) {
        final displayName = entry.key;
        final filePath = entry.value;

        // Handle biography as special case
        if (filePath == 'biography.txt') {
          final bioText = profile.bio ?? '';
          final bioBytes = utf8.encode(bioText);
          archive.addFile(
            ArchiveFile(
              'biography.txt',
              bioBytes.length,
              bioBytes,
            ),
          );
        } else {
          // Handle regular files
          final file = File(filePath);
          if (await file.exists()) {
            final fileData = await file.readAsBytes();
            archive.addFile(
              ArchiveFile(
                displayName,
                fileData.length,
                fileData,
              ),
            );
          }
        }
      }

      final zipData = ZipEncoder().encode(archive);
      await zipFile.writeAsBytes(zipData);
    
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nFilesSavedTo(selectedFiles.length, selectedFiles.length == 1 ? '' : 's', path.basename(savePath)))),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateZip(e.toString()))),
        );
      }
    }
  }

  Future<void> _addAdditionalAsset() async {
    final assetName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addAsset),
        content: TextField(
          controller: _assetNameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.assetNameLabel,
            hintText: AppLocalizations.of(context)!.assetNameHint,
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
              if (_assetNameController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, _assetNameController.text.trim());
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );

    if (assetName == null || assetName.isEmpty) return;

    _assetNameController.clear();

    await _pickFile(
      assetType: 'asset',
      onFileSelected: (filePath) async {
        try {
          final profileRepo = await ref.read(profileRepositoryProvider.future);
          final currentProfile = profileRepo.getProfileById(widget.profileId);
          if (currentProfile != null) {
            final currentAssets = Map<String, String>.from(currentProfile.additionalAssets ?? {});
            currentAssets[assetName] = filePath;
            final updatedProfile = currentProfile.copyWith(additionalAssets: currentAssets);
            await profileRepo.updateProfile(updatedProfile);
            ref.invalidate(currentProfileProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.assetAddedSuccessfully(assetName))),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddAsset(e.toString()))),
            );
          }
        }
      },
    );
  }

  Future<void> _removeAsset(String assetName) async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfile = profileRepo.getProfileById(widget.profileId);
      if (currentProfile != null) {
        final currentAssets = Map<String, String>.from(currentProfile.additionalAssets ?? {});
        currentAssets.remove(assetName);
        final updatedProfile = currentProfile.copyWith(additionalAssets: currentAssets);
        await profileRepo.updateProfile(updatedProfile);
        ref.invalidate(currentProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.assetRemoved(assetName))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToRemoveAsset(e.toString()))),
        );
      }
    }
  }

  Future<void> _openFile(String filePath) async {
    final success = await FileLauncher.openFile(filePath);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToOpenFile)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isMobile = MobileUtils.isMobile();

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.editProfile),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(
            title: AppLocalizations.of(context)!.editProfile,
            showBack: true,
          ),
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('${AppLocalizations.of(context)!.error}: $error'),
              ),
              data: (profile) {
                if (profile == null || profile.id != widget.profileId) {
                  // Try to get profile by ID directly
                  return FutureBuilder<Profile?>(
                    future: ref.read(profileRepositoryProvider.future).then((repo) => repo.getProfileById(widget.profileId)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return Center(child: Text(AppLocalizations.of(context)!.profileNotFound));
                      }
                      final profile = snapshot.data!;
                      if (_bioController.text != (profile.bio ?? '')) {
                        _bioController.text = profile.bio ?? '';
                      }
                      if (_nameController.text != profile.name) {
                        _nameController.text = profile.name;
                      }
                      return _buildProfileContent(profile);
                    },
                  );
                }

                // Initialize bio/name controllers if not already set
                if (_bioController.text != (profile.bio ?? '')) {
                  _bioController.text = profile.bio ?? '';
                }
                if (_nameController.text != profile.name) {
                  _nameController.text = profile.name;
                }
                return _buildProfileContent(profile);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(Profile profile, {required TextAlign textAlign}) {
    return TextField(
      controller: _nameController,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.name,
        isDense: true,
      ),
      onChanged: (_) => _scheduleNameAutoSave(profile),
    );
  }

  Widget _buildPhotoActions(Profile profile) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.photo, size: 16),
          label: Text(AppLocalizations.of(context)!.changePhoto, style: const TextStyle(fontSize: 12)),
          onPressed: () => _pickProfilePhoto(profile),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
        ),
        if (profile.photoPath != null)
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(AppLocalizations.of(context)!.remove, style: const TextStyle(fontSize: 12)),
            onPressed: () => _removeProfilePhoto(profile),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
          ),
      ],
    );
  }

  Widget _buildProfileContent(Profile profile) {
    final isMobile = MobileUtils.isMobile();
    return SingleChildScrollView(
                  padding: MobileUtils.getResponsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Profile Photo
                                    Center(
                                      child: profile.photoPath != null && File(profile.photoPath!).existsSync()
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(
                                                File(profile.photoPath!),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).cardColor,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Icon(Icons.person, size: 50),
                                                  );
                                                },
                                              ),
                                            )
                                          : Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).cardColor,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.person, size: 50),
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(child: _buildPhotoActions(profile)),
                                    const SizedBox(height: 8),
                                    // Profile Name and Info
                                    Center(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          _buildNameField(profile, textAlign: TextAlign.center),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Created: ${profile.createdAt.toString().split('.')[0]}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Profile Photo
                                    Column(
                                      children: [
                                        if (profile.photoPath != null && File(profile.photoPath!).existsSync())
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.file(
                                              File(profile.photoPath!),
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 120,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).cardColor,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(Icons.person, size: 60),
                                                );
                                              },
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.person, size: 60),
                                          ),
                                        const SizedBox(height: 8),
                                        _buildPhotoActions(profile),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    // Profile Name and Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildNameField(profile, textAlign: TextAlign.start),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Created: ${profile.createdAt.toString().split('.')[0]}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Download Files section — separated from the header
                      // since these act on the whole profile's files, not
                      // the name/photo above them.
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.folder_zip_outlined),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.downloadFilesSectionTitle,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.downloadFilesSectionDescription,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.select_all, size: 18),
                                    label: Text(AppLocalizations.of(context)!.selectFiles),
                                    onPressed: () => _showSelectFilesDialog(profile),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download, size: 18),
                                    label: Text(AppLocalizations.of(context)!.downloadAll),
                                    onPressed: () => _downloadAllFiles(profile),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bio Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biography',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _bioController,
                                maxLines: 8,
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.enterBiographyHint,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (_) => _scheduleBioAutoSave(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Artwork Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Artwork',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(AppLocalizations.of(context)!.addArtwork),
                                    onPressed: _addArtwork,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  final allArtworkPaths = profile.getAllArtworkPaths();
                                  final existingArtwork = allArtworkPaths.where((p) => File(p).existsSync()).toList();
                                  
                                  if (existingArtwork.isEmpty) {
                                    return Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_outlined,
                                              size: 48,
                                              color: Theme.of(context).textTheme.bodySmall?.color,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No artwork added',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final isMobile = MobileUtils.isMobile();
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isMobile ? 2 : 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.0,
                                    ),
                                    itemCount: existingArtwork.length,
                                    itemBuilder: (context, index) {
                                      final artworkPath = existingArtwork[index];
                                      return Card(
                                        clipBehavior: Clip.antiAlias,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.file(
                                              File(artworkPath),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Theme.of(context).cardColor,
                                                  child: const Center(
                                                    child: Icon(Icons.broken_image, size: 32),
                                                  ),
                                                );
                                              },
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.download, size: 18),
                                                    onPressed: () => _downloadFile(
                                                      artworkPath,
                                                      'artwork_${index + 1}${path.extension(artworkPath)}',
                                                    ),
                                                    tooltip: AppLocalizations.of(context)!.download,
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.black54,
                                                      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                                                      padding: const EdgeInsets.all(6),
                                                      minimumSize: const Size(32, 32),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, size: 18),
                                                    onPressed: () => _removeArtwork(artworkPath),
                                                    tooltip: AppLocalizations.of(context)!.remove,
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.black54,
                                                      foregroundColor: Colors.red.shade300,
                                                      padding: const EdgeInsets.all(6),
                                                      minimumSize: const Size(32, 32),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              left: 4,
                                              right: 4,
                                              child: TextButton.icon(
                                                icon: const Icon(Icons.folder_open, size: 14),
                                                label: Text(
                                                  'Version ${index + 1}',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                                onPressed: () => _openFile(artworkPath),
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.black54,
                                                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: const Size(0, 24),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Press Kit Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Press Kit',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(AppLocalizations.of(context)!.addFile),
                                    onPressed: _addPressKitFile,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  final allPressKitPaths = profile.getAllPressKitPaths();
                                  final existingPressKitFiles = allPressKitPaths.where((p) => File(p).existsSync()).toList();
                                  
                                  if (existingPressKitFiles.isEmpty) {
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No press kit files added',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: existingPressKitFiles.map((pressKitPath) {
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: const Icon(Icons.description),
                                          title: Text(path.basename(pressKitPath)),
                                          subtitle: Text(
                                            AppLocalizations.of(context)!.pressKitFile,
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.download),
                                                onPressed: () => _downloadFile(
                                                  pressKitPath,
                                                  path.basename(pressKitPath),
                                                ),
                                                tooltip: AppLocalizations.of(context)!.download,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.folder_open),
                                                onPressed: () => _openFile(pressKitPath),
                                                tooltip: AppLocalizations.of(context)!.openFile,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline),
                                                onPressed: () => _removePressKitFile(pressKitPath),
                                                tooltip: AppLocalizations.of(context)!.remove,
                                                color: Colors.red.shade300,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Additional Assets Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Additional Assets',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(AppLocalizations.of(context)!.addAsset),
                                    onPressed: _addAdditionalAsset,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (profile.additionalAssets != null && profile.additionalAssets!.isNotEmpty)
                                ...profile.additionalAssets!.entries.map((entry) {
                                  final fileExists = File(entry.value).existsSync();
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Icon(
                                        fileExists ? Icons.attach_file : Icons.broken_image,
                                      ),
                                      title: Text(entry.key),
                                      subtitle: Text(
                                        fileExists ? path.basename(entry.value) : AppLocalizations.of(context)!.fileNotFound,
                                        style: TextStyle(
                                          color: fileExists
                                              ? null
                                              : Colors.red,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (fileExists) ...[
                                            IconButton(
                                              icon: const Icon(Icons.download),
                                              onPressed: () => _downloadFile(
                                                entry.value,
                                                entry.key + path.extension(entry.value),
                                              ),
                                              tooltip: AppLocalizations.of(context)!.download,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.folder_open),
                                              onPressed: () => _openFile(entry.value),
                                              tooltip: AppLocalizations.of(context)!.openFile,
                                            ),
                                          ],
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            onPressed: () => _removeAsset(entry.key),
                                            tooltip: AppLocalizations.of(context)!.remove,
                                            color: Colors.red.shade300,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                })
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No additional assets added',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
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

