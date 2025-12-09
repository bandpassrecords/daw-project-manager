import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/release.dart';
import '../models/release_file.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import 'project_detail_page.dart';

class ReleaseDetailPage extends ConsumerStatefulWidget {
  final String releaseId;
  const ReleaseDetailPage({super.key, required this.releaseId});

  @override
  ConsumerState<ReleaseDetailPage> createState() => _ReleaseDetailPageState();
}

class _ReleaseDetailPageState extends ConsumerState<ReleaseDetailPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _artworkImagePath;
  DateTime? _releaseDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final releases = ref.read(releasesProvider);
      final release = releases.asData?.value?.firstWhere(
        (r) => r.id == widget.releaseId,
        orElse: () => throw StateError('Release not found'),
      );
      if (release != null) {
        _titleController.text = release.title;
        _descriptionController.text = release.description ?? '';
        setState(() {
          _artworkImagePath = release.artworkImagePath;
          _releaseDate = release.releaseDate;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getFileType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    if (['.wav', '.mp3', '.flac', '.aac', '.ogg', '.m4a'].contains(ext)) {
      return 'audio';
    } else if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext)) {
      return 'video';
    } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(ext)) {
      return 'image';
    } else if (['.pdf', '.doc', '.docx', '.txt', '.rtf'].contains(ext)) {
      return 'document';
    }
    return 'other';
  }

  Future<void> _addFiles(BuildContext context, Release release) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final releasesDir = Directory(path.join(appDocDir.path, 'daw_project_manager', 'release_files', release.id));
      
      if (!await releasesDir.exists()) {
        await releasesDir.create(recursive: true);
      }

      final repo = await ref.read(repositoryProvider.future);
      final newFiles = <ReleaseFile>[];

      for (final pickedFile in result.files) {
        if (pickedFile.path == null) continue;
        
        final sourceFile = File(pickedFile.path!);
        if (!await sourceFile.exists()) continue;

        final fileExtension = path.extension(pickedFile.path!);
        final fileName = '${const Uuid().v4()}$fileExtension';
        final destPath = path.join(releasesDir.path, fileName);
        
        final destFile = await sourceFile.copy(destPath);
        final fileSize = await destFile.length();
        
        final releaseFile = ReleaseFile(
          id: const Uuid().v4(),
          fileName: pickedFile.name,
          filePath: destFile.path,
          fileType: _getFileType(pickedFile.name),
          fileSizeBytes: fileSize,
          addedAt: DateTime.now(),
        );
        
        newFiles.add(releaseFile);
      }

      if (newFiles.isNotEmpty) {
        final updatedFiles = [...release.files, ...newFiles];
        final updatedRelease = release.copyWith(files: updatedFiles);
        await repo.updateRelease(updatedRelease);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${newFiles.length} file(s) to release.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add files: $e')),
        );
      }
    }
  }

  Future<void> _downloadAsZip(BuildContext context, Release release) async {
    if (release.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files to download.')),
      );
      return;
    }

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final zipPath = path.join(appDocDir.path, 'daw_project_manager', '${release.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_files.zip');
      
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      final archive = Archive();
      
      for (final releaseFile in release.files) {
        final file = File(releaseFile.filePath);
        if (await file.exists()) {
          final fileData = await file.readAsBytes();
          archive.addFile(
            ArchiveFile(
              releaseFile.fileName,
              fileData.length,
              fileData,
            ),
          );
        }
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        await zipFile.writeAsBytes(zipData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ZIP file created: ${zipFile.path}'),
              action: SnackBarAction(
                label: 'Open Folder',
                onPressed: () async {
                  final folderPath = path.dirname(zipFile.path);
                  if (Platform.isWindows) {
                    await Process.run('explorer', [folderPath]);
                  } else if (Platform.isMacOS) {
                    await Process.run('open', [folderPath]);
                  } else if (Platform.isLinux) {
                    await Process.run('xdg-open', [folderPath]);
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ZIP: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final releases = ref.read(releasesProvider);
    final release = releases.asData?.value?.firstWhere(
      (r) => r.id == widget.releaseId,
      orElse: () => throw StateError('Release not found'),
    );
    
    if (release == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Release not found.')),
        );
      }
      return;
    }

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
        // Get app documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        final releasesDir = Directory(path.join(appDocDir.path, 'daw_project_manager', 'release_artwork'));
        
        // Create directory if it doesn't exist
        if (!await releasesDir.exists()) {
          await releasesDir.create(recursive: true);
        }

        // Generate unique filename
        final fileExtension = path.extension(sourcePath);
        final fileName = '${const Uuid().v4()}$fileExtension';
        final destPath = path.join(releasesDir.path, fileName);
        
        // Copy file to persistent location
        final destFile = await sourceFile.copy(destPath);
        
        // Delete old artwork if it exists and is in our app directory
        if (release.artworkImagePath != null && release.artworkImagePath!.contains('release_artwork')) {
          try {
            final oldFile = File(release.artworkImagePath!);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (_) {
            // Ignore errors deleting old file
          }
        }
        
        final newImagePath = destFile.path;
        
        // Automatically save the release with the new image path
        final repo = await ref.read(repositoryProvider.future);
        final updatedRelease = release.copyWith(
          artworkImagePath: newImagePath,
        );
        await repo.updateRelease(updatedRelease);
        
        setState(() {
          _artworkImagePath = newImagePath;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save image: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final releases = ref.watch(releasesProvider);
    final allProjects = ref.watch(projectsProvider);

    return releases.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Release Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error loading release: $error')),
      ),
      data: (releasesList) {
        try {
          final release = releasesList.firstWhere((r) => r.id == widget.releaseId);

          // Sync controllers and state with release data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_titleController.text != release.title) {
              _titleController.text = release.title;
            }
            if (_descriptionController.text != (release.description ?? '')) {
              _descriptionController.text = release.description ?? '';
            }
            if (_artworkImagePath != release.artworkImagePath) {
              setState(() {
                _artworkImagePath = release.artworkImagePath;
              });
            }
            if (_releaseDate != release.releaseDate) {
              setState(() {
                _releaseDate = release.releaseDate;
              });
            }
          });

          final releaseProjects = allProjects.where((p) => release.trackIds.contains(p.id)).toList();

          return Scaffold(
      appBar: AppBar(
        title: Text(release.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final repo = await ref.read(repositoryProvider.future);
              final updatedRelease = release.copyWith(
                title: _titleController.text,
                description: _descriptionController.text,
                artworkImagePath: _artworkImagePath,
                releaseDate: _releaseDate,
              );
              await repo.updateRelease(updatedRelease);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Release saved.')));
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Artwork and details
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Card(
                      child: Builder(
                        builder: (context) {
                          // Use release data directly to ensure we always show the latest image
                          final imagePath = release.artworkImagePath ?? _artworkImagePath;
                          if (imagePath != null && File(imagePath).existsSync()) {
                            return Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 50, color: Colors.white38),
                                      SizedBox(height: 8),
                                      Text(
                                        'Image not found',
                                        style: TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                          return const Center(child: Icon(Icons.add_a_photo, size: 50));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Release Title'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Release Date'),
                    subtitle: Text(
                      _releaseDate != null
                          ? DateFormat.yMMMd().format(_releaseDate!)
                          : 'No date set',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_releaseDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _releaseDate = null;
                              });
                            },
                            tooltip: 'Clear date',
                          ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _releaseDate ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _releaseDate = picked;
                              });
                            }
                          },
                          tooltip: 'Pick date',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right side: Tracklist and Files
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tracks Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tracks (${releaseProjects.length})', style: Theme.of(context).textTheme.headlineSmall),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Tracks'),
                        onPressed: () async {
                          final allProjects = ref.read(projectsProvider);
                          final availableProjects = allProjects.where((p) => !release.trackIds.contains(p.id)).toList();
                          
                          if (availableProjects.isEmpty) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All projects are already in this release.')),
                              );
                            }
                            return;
                          }

                          final selectedIds = await showDialog<List<String>>(
                            context: context,
                            builder: (context) => _TrackSelectionDialog(projects: availableProjects),
                          );

                          if (selectedIds != null && selectedIds.isNotEmpty) {
                            final repo = await ref.read(repositoryProvider.future);
                            final updatedTrackIds = {...release.trackIds, ...selectedIds}.toList();
                            final updatedRelease = release.copyWith(trackIds: updatedTrackIds);
                            await repo.updateRelease(updatedRelease);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added ${selectedIds.length} track(s) to release.')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      itemCount: releaseProjects.length,
                      itemBuilder: (context, index) {
                        final project = releaseProjects[index];
                        final folderPath = FileSystemEntity.isDirectorySync(project.filePath)
                            ? project.filePath
                            : path.dirname(project.filePath);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: const Color(0xFF2B2D31),
                          child: ListTile(
                            title: Text(project.displayName),
                            subtitle: Text(project.dawType ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Open Folder button
                                IconButton(
                                  icon: const Icon(Icons.folder_open),
                                  tooltip: 'Open Folder',
                                  onPressed: () async {
                                    final exists = Directory(folderPath).existsSync();
                                    if (!exists) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Folder missing.')),
                                        );
                                      }
                                      return;
                                    }
                                    
                                    try {
                                      if (Platform.isMacOS) {
                                        await Process.start('open', [folderPath]);
                                      } else if (Platform.isWindows) {
                                        await Process.start('explorer', [folderPath]);
                                      } else if (Platform.isLinux) {
                                        await Process.start('xdg-open', [folderPath]);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Opening folder for ${project.displayName}…')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to open folder: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                                // View button
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  tooltip: 'View Details',
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProjectDetailPage(projectId: project.id),
                                      ),
                                    );
                                  },
                                ),
                                // Launch button
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  tooltip: 'Launch in DAW',
                                  onPressed: () async {
                                    final exists = File(project.filePath).existsSync() || 
                                                  Directory(project.filePath).existsSync();
                                    if (!exists) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('File missing.')),
                                        );
                                      }
                                      return;
                                    }
                                    try {
                                      if (Platform.isMacOS) {
                                        await Process.start('open', [project.filePath]);
                                      } else if (Platform.isWindows) {
                                        await Process.start('cmd', ['/c', 'start', '', project.filePath]);
                                      } else {
                                        await Process.start(project.filePath, []);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Launching ${project.displayName}…')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to launch: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                                // Remove button
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Colors.red.shade300,
                                  tooltip: 'Remove from Release',
                                  onPressed: () async {
                                    final repo = await ref.read(repositoryProvider.future);
                                    final updatedTrackIds = release.trackIds.where((id) => id != project.id).toList();
                                    final updatedRelease = release.copyWith(trackIds: updatedTrackIds);
                                    await repo.updateRelease(updatedRelease);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Removed ${project.displayName} from release.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 2),
                  // Files Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Supporting Files (${release.files.length})', style: Theme.of(context).textTheme.headlineSmall),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.file_upload),
                            label: const Text('Add Files'),
                            onPressed: () => _addFiles(context, release),
                          ),
                          const SizedBox(width: 8),
                          if (release.files.isNotEmpty)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Download ZIP'),
                              onPressed: () => _downloadAsZip(context, release),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    flex: 1,
                    child: release.files.isEmpty
                        ? const Center(
                            child: Text(
                              'No files added yet.\nClick "Add Files" to upload supporting files.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : _FilesTable(
                            files: release.files,
                            release: release,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
        } catch (e) {
          return Scaffold(
            appBar: AppBar(title: const Text('Release Not Found')),
            body: const Center(child: Text('This release could not be found.')),
          );
        }
      },
    );
  }
}

class _FilesTable extends ConsumerWidget {
  final List<ReleaseFile> files;
  final Release release;

  const _FilesTable({
    required this.files,
    required this.release,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType) {
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.videocam;
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final fileExists = File(file.filePath).existsSync();
        
        // Special handling for audio files - show audio player
        if (file.fileType == 'audio' && fileExists) {
          return _AudioFileItem(
            file: file,
            release: release,
            onDelete: () => _deleteFile(context, ref, file),
          );
        }
        
        // Regular file item for non-audio files
        return ListTile(
          leading: Icon(
            _getFileTypeIcon(file.fileType),
            color: fileExists ? Colors.white70 : Colors.red.shade300,
          ),
          title: Text(
            file.fileName,
            style: TextStyle(
              color: fileExists ? Colors.white : Colors.red.shade300,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${file.fileType.toUpperCase()} • ${_formatFileSize(file.fileSizeBytes)}',
                style: const TextStyle(color: Colors.white54),
              ),
              if (file.description != null && file.description!.isNotEmpty)
                Text(
                  file.description!,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              Text(
                DateFormat.yMMMd().add_jm().format(file.addedAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!fileExists)
                const Tooltip(
                  message: 'File not found',
                  child: Icon(Icons.warning, color: Colors.red, size: 20),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade300,
                onPressed: () => _deleteFile(context, ref, file),
              ),
            ],
          ),
          onTap: fileExists
              ? () async {
                  // Open file
                  try {
                    if (Platform.isWindows) {
                      await Process.run('cmd', ['/c', 'start', '', file.filePath]);
                    } else if (Platform.isMacOS) {
                      await Process.run('open', [file.filePath]);
                    } else if (Platform.isLinux) {
                      await Process.run('xdg-open', [file.filePath]);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to open file: $e')),
                      );
                    }
                  }
                }
              : null,
        );
      },
    );
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref, ReleaseFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D31),
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.fileName}"?'),
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
        // Delete physical file
        final fileObj = File(file.filePath);
        if (await fileObj.exists()) {
          await fileObj.delete();
        }
        
        // Remove from release
        final repo = await ref.read(repositoryProvider.future);
        final updatedFiles = release.files.where((f) => f.id != file.id).toList();
        final updatedRelease = release.copyWith(files: updatedFiles);
        await repo.updateRelease(updatedRelease);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File "${file.fileName}" deleted.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete file: $e')),
          );
        }
      }
    }
  }
}

class _AudioFileItem extends ConsumerStatefulWidget {
  final ReleaseFile file;
  final Release release;
  final VoidCallback onDelete;

  const _AudioFileItem({
    required this.file,
    required this.release,
    required this.onDelete,
  });

  @override
  ConsumerState<_AudioFileItem> createState() => _AudioFileItemState();
}

class _AudioFileItemState extends ConsumerState<_AudioFileItem> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero || _position >= _duration) {
          await _audioPlayer.play(DeviceFileSource(widget.file.filePath));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
    }
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _position = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFF2B2D31),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File info header
            Row(
              children: [
                const Icon(Icons.audiotrack, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.file.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_formatFileSize(widget.file.fileSizeBytes)} • ${DateFormat.yMMMd().add_jm().format(widget.file.addedAt)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade300,
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Audio player controls
            Row(
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayPause,
                  iconSize: 32,
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: _isPlaying || _position > Duration.zero ? _stop : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Slider(
                        value: _duration.inMilliseconds > 0
                            ? _position.inMilliseconds.toDouble()
                            : 0.0,
                        max: _duration.inMilliseconds > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 100.0,
                        onChanged: (value) async {
                          final position = Duration(milliseconds: value.toInt());
                          await _audioPlayer.seek(position);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackSelectionDialog extends StatefulWidget {
  final List<MusicProject> projects;

  const _TrackSelectionDialog({required this.projects});

  @override
  State<_TrackSelectionDialog> createState() => _TrackSelectionDialogState();
}

class _TrackSelectionDialogState extends State<_TrackSelectionDialog> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2B2D31),
      title: const Text('Select Tracks to Add'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            Text(
              'Select tracks to add to this release (${_selectedIds.length} selected)',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.projects.length,
                itemBuilder: (context, index) {
                  final project = widget.projects[index];
                  final isSelected = _selectedIds.contains(project.id);
                  return CheckboxListTile(
                    title: Text(project.displayName),
                    subtitle: Text(
                      '${project.dawType ?? 'Unknown'} • ${project.bpm?.toStringAsFixed(0) ?? '?'} BPM',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(project.id);
                        } else {
                          _selectedIds.remove(project.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedIds.toList()),
          child: const Text('Add Tracks'),
        ),
      ],
    );
  }
}
