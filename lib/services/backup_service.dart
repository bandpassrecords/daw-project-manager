import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/music_project.dart';
import '../models/scan_root.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../models/profile.dart';
import '../models/todo_item.dart';
import '../repository/project_repository.dart';
import '../repository/profile_repository.dart';

class BackupService {
  /// Exports all data for the current profile to a JSON file
  static Future<File?> exportBackup({
    required ProjectRepository projectRepo,
    required ProfileRepository profileRepo,
    required String profileId,
    String? exportDialogTitle,
  }) async {
    try {
      // Get all data
      final projects = projectRepo.getAllProjects();
      final roots = projectRepo.getRoots();
      final releases = projectRepo.getAllReleases();
      final profile = profileRepo.getProfileById(profileId);

      // Create backup data structure
      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'profileId': profileId,
        'profile': profile != null ? _profileToJson(profile) : null,
        'projects': projects.map((p) => _projectToJson(p)).toList(),
        'roots': roots.map((r) => _rootToJson(r)).toList(),
        'releases': releases.map((r) => _releaseToJson(r, projects)).toList(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save to file
      final result = await FilePicker.platform.saveFile(
        dialogTitle: exportDialogTitle ?? 'Export Backup',
        fileName: 'daw_project_manager_backup_${DateTime.now().toIso8601String().split('T')[0]}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        return file;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  /// Imports data from a backup JSON file
  static Future<ImportResult> importBackup({
    required ProjectRepository? projectRepo, // Can be null if creating new profile
    required ProfileRepository profileRepo,
    required String? currentProfileId, // Can be null if creating new profile
    required ImportMode importMode, // Merge, Replace, or CreateNewProfile
    String? newProfileName, // Required if importMode is CreateNewProfile
    String? importDialogTitle,
    String? invalidBackupFormatMessage,
    String? profileNameRequiredMessage,
    String? currentProfileRequiredMessage,
  }) async {
    try {
      // Pick backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: importDialogTitle ?? 'Import Backup',
      );

      if (result == null || result.files.single.path == null) {
        return ImportResult(cancelled: true);
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup format
      if (backupData['version'] == null) {
        throw Exception(invalidBackupFormatMessage ?? 'Invalid backup file format: missing version');
      }

      final importedProjects = <MusicProject>[];
      final importedRoots = <ScanRoot>[];
      final importedReleases = <Release>[];

      // Import projects
      if (backupData['projects'] != null) {
        final projectsList = backupData['projects'] as List;
        for (var projectJson in projectsList) {
          try {
            final project = _projectFromJson(projectJson as Map<String, dynamic>);
            importedProjects.add(project);
          } catch (e) {
            // Skip invalid projects
            continue;
          }
        }
      }

      // Import roots
      if (backupData['roots'] != null) {
        final rootsList = backupData['roots'] as List;
        for (var rootJson in rootsList) {
          try {
            final root = _rootFromJson(rootJson as Map<String, dynamic>);
            importedRoots.add(root);
          } catch (e) {
            // Skip invalid roots
            continue;
          }
        }
      }

      // Import releases
      if (backupData['releases'] != null) {
        final releasesList = backupData['releases'] as List;
        for (var releaseJson in releasesList) {
          try {
            final release = _releaseFromJson(releaseJson as Map<String, dynamic>);
            importedReleases.add(release);
          } catch (e) {
            // Skip invalid releases
            continue;
          }
        }
      }

      // Apply import based on mode
      ProjectRepository targetRepo;
      String targetProfileId;
      String? createdProfileId;
      
      if (importMode == ImportMode.createNewProfile) {
        // Create new profile
        if (newProfileName == null || newProfileName.trim().isEmpty) {
          throw Exception(profileNameRequiredMessage ?? 'Profile name is required when creating a new profile');
        }
        await profileRepo.createProfile(newProfileName.trim());
        final newProfile = profileRepo.getAllProfiles().firstWhere(
          (p) => p.name == newProfileName.trim(),
        );
        targetProfileId = newProfile.id;
        createdProfileId = targetProfileId;
        // IMPORTANT: Switch to the new profile BEFORE initializing the repository
        // so that ProjectRepository.init() uses the correct profile's boxes
        await profileRepo.setCurrentProfileId(targetProfileId);
        targetRepo = await ProjectRepository.init(profileRepo);
      } else {
        // Merge or Replace mode - use existing profile
        if (currentProfileId == null || projectRepo == null) {
          throw Exception(currentProfileRequiredMessage ?? 'Current profile is required for merge or replace mode');
        }
        targetProfileId = currentProfileId;
        targetRepo = projectRepo;
        
        if (importMode == ImportMode.replace) {
          // Replace mode: clear existing data and import new
          await targetRepo.clearAllData();
        }
        // For merge mode, we just add/update without clearing
      }
      
      // Import data into target repository
      for (final project in importedProjects) {
        await targetRepo.updateProject(project);
      }
      for (final root in importedRoots) {
        // Check if root already exists (only in merge mode)
        if (importMode == ImportMode.merge) {
          final existingRoots = targetRepo.getRoots();
          if (!existingRoots.any((r) => r.path == root.path)) {
            await targetRepo.addRoot(root.path);
          }
        } else {
          await targetRepo.addRoot(root.path);
        }
      }
      for (final release in importedReleases) {
        await targetRepo.updateRelease(release);
      }

      return ImportResult(
        cancelled: false,
        projectsCount: importedProjects.length,
        rootsCount: importedRoots.length,
        releasesCount: importedReleases.length,
        newProfileId: createdProfileId,
      );
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  // JSON serialization helpers
  static Map<String, dynamic> _projectToJson(MusicProject project) {
    return {
      'id': project.id,
      'filePath': project.filePath,
      'fileName': project.fileName,
      'fileSizeBytes': project.fileSizeBytes,
      'lastModifiedAt': project.lastModifiedAt.toIso8601String(),
      'customDisplayName': project.customDisplayName,
      'thumbnailPath': project.thumbnailPath,
      'status': project.status,
      'fileExtension': project.fileExtension,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'bpm': project.bpm,
      'musicalKey': project.musicalKey,
      'notes': project.notes,
      'dawType': project.dawType,
      'dawVersion': project.dawVersion,
      'todos': project.todos.map((t) => _todoToJson(t as TodoItem)).toList(),
      'hidden': project.hidden,
    };
  }

  static MusicProject _projectFromJson(Map<String, dynamic> json) {
    return MusicProject(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      customDisplayName: json['customDisplayName'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      status: json['status'] as String? ?? 'Idea',
      fileExtension: json['fileExtension'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      bpm: json['bpm'] != null ? (json['bpm'] as num).toDouble() : null,
      musicalKey: json['musicalKey'] as String?,
      notes: json['notes'] as String?,
      dawType: json['dawType'] as String?,
      dawVersion: json['dawVersion'] as String?,
      todos: (json['todos'] as List?)?.map((t) => _todoFromJson(t as Map<String, dynamic>) as TodoItem).toList() ?? [],
      hidden: json['hidden'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _rootToJson(ScanRoot root) {
    return {
      'id': root.id,
      'path': root.path,
      'addedAt': root.addedAt.toIso8601String(),
      'lastScanAt': root.lastScanAt?.toIso8601String(),
    };
  }

  static ScanRoot _rootFromJson(Map<String, dynamic> json) {
    return ScanRoot(
      id: json['id'] as String,
      path: json['path'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastScanAt: json['lastScanAt'] != null ? DateTime.parse(json['lastScanAt'] as String) : null,
    );
  }

  static Map<String, dynamic> _releaseToJson(Release release, List<MusicProject> allProjects) {
    return {
      'id': release.id,
      'title': release.title,
      'releaseDate': release.releaseDate?.toIso8601String(),
      'artworkImagePath': release.artworkImagePath,
      'description': release.description,
      'trackIds': release.trackIds,
      'files': release.files.map((f) => _releaseFileToJson(f as ReleaseFile)).toList(),
      'todos': release.todos.map((t) => _todoToJson(t as TodoItem)).toList(),
    };
  }

  static Release _releaseFromJson(Map<String, dynamic> json) {
    return Release(
      id: json['id'] as String,
      title: json['title'] as String,
      releaseDate: json['releaseDate'] != null ? DateTime.parse(json['releaseDate'] as String) : null,
      artworkImagePath: json['artworkImagePath'] as String?,
      description: json['description'] as String?,
      trackIds: (json['trackIds'] as List?)?.map((e) => e as String).toList() ?? [],
      files: (json['files'] as List?)?.map((f) => _releaseFileFromJson(f as Map<String, dynamic>) as ReleaseFile).toList() ?? [],
      todos: (json['todos'] as List?)?.map((t) => _todoFromJson(t as Map<String, dynamic>) as TodoItem).toList() ?? [],
    );
  }

  static Map<String, dynamic> _releaseFileToJson(ReleaseFile file) {
    return {
      'id': file.id,
      'fileName': file.fileName,
      'filePath': file.filePath,
      'fileType': file.fileType,
      'fileSizeBytes': file.fileSizeBytes,
      'addedAt': file.addedAt.toIso8601String(),
      'description': file.description,
    };
  }

  static ReleaseFile _releaseFileFromJson(Map<String, dynamic> json) {
    return ReleaseFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileType: json['fileType'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      addedAt: DateTime.parse(json['addedAt'] as String),
      description: json['description'] as String?,
    );
  }

  static Map<String, dynamic> _profileToJson(Profile profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'createdAt': profile.createdAt.toIso8601String(),
      'lastUsedAt': profile.lastUsedAt?.toIso8601String(),
      'photoPath': profile.photoPath,
    };
  }

  static Map<String, dynamic> _todoToJson(TodoItem todo) {
    return {
      'id': todo.id,
      'text': todo.text,
      'completed': todo.completed,
      'createdAt': todo.createdAt.toIso8601String(),
    };
  }

  static TodoItem _todoFromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      text: json['text'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum ImportMode {
  merge,
  replace,
  createNewProfile,
}

class ImportResult {
  final bool cancelled;
  final int projectsCount;
  final int rootsCount;
  final int releasesCount;
  final String? newProfileId;

  ImportResult({
    this.cancelled = false,
    this.projectsCount = 0,
    this.rootsCount = 0,
    this.releasesCount = 0,
    this.newProfileId,
  });
}

