import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/music_project.dart';
import '../models/scan_root.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../models/todo_item.dart';
import '../services/metadata_extractor.dart';
import '../utils/app_paths.dart';
import 'profile_repository.dart';

class ProjectRepository {
  final String profileId;
  final Box<MusicProject> projectsBox;
  final Box<ScanRoot> rootsBox;
  final Box<Release> releasesBox;
  final _uuid = const Uuid();

  ProjectRepository({
    required this.profileId,
    required this.projectsBox,
    required this.rootsBox,
    required this.releasesBox,
  });

  static Future<ProjectRepository> init(ProfileRepository profileRepo) async {
    // Initialize Hive with LocalAppData directory
    final appDataPath = await getLocalAppDataPath();
    Hive.init(appDataPath);
    
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MusicProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScanRootAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ReleaseAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ReleaseFileAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TodoItemAdapter());
    }

    // Get current profile
    final currentProfile = profileRepo.getCurrentProfile();
    if (currentProfile == null) {
      throw Exception('No active profile found');
    }
    
    final profileId = currentProfile.id;
    
    // Use profile-specific box names
    final projects = await Hive.openBox<MusicProject>('${profileId}_projects');
    final roots = await Hive.openBox<ScanRoot>('${profileId}_roots');
    final releases = await Hive.openBox<Release>('${profileId}_releases');
    
    return ProjectRepository(
      profileId: profileId,
      projectsBox: projects,
      rootsBox: roots,
      releasesBox: releases,
    );
  }
  
  /// Reinitialize with a different profile
  static Future<ProjectRepository> initWithProfile(ProfileRepository profileRepo, String profileId) async {
    final appDataPath = await getLocalAppDataPath();
    Hive.init(appDataPath);
    
    // Use profile-specific box names
    final projects = await Hive.openBox<MusicProject>('${profileId}_projects');
    final roots = await Hive.openBox<ScanRoot>('${profileId}_roots');
    final releases = await Hive.openBox<Release>('${profileId}_releases');
    
    return ProjectRepository(
      profileId: profileId,
      projectsBox: projects,
      rootsBox: roots,
      releasesBox: releases,
    );
  }

  // Roots
  Future<void> addRoot(String path) async {
    final id = _uuid.v4();
    await rootsBox.put(id, ScanRoot(id: id, path: path, addedAt: DateTime.now()));
  }

  Future<void> removeRoot(String id) async {
    final root = rootsBox.get(id);
    if (root == null) return;
    
    // Get the root path and normalize it for comparison
    final rootPath = p.normalize(root.path);
    // Ensure root path ends with separator for proper matching
    final rootPathNormalized = rootPath.endsWith(p.separator) 
        ? rootPath 
        : rootPath + p.separator;
    
    // Get all project IDs that are referenced in releases (to preserve them)
    final releases = getAllReleases();
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }
    
    // Remove all projects that belong to this root folder
    // Note: projectsBox is already profile-specific, so we only operate on current profile's projects
    final projectsToDelete = <String>[];
    
    for (final project in projectsBox.values) {
      try {
        // Normalize project file path for comparison
        final projectPath = p.normalize(project.filePath);
        
        // Check if project's file path is within the root folder
        // This is safe because projectsBox is profile-specific (${profileId}_projects)
        if (projectPath.startsWith(rootPathNormalized) || 
            projectPath.startsWith(rootPath + p.separator)) {
          // Preserve projects that are referenced in releases
          if (!protectedProjectIds.contains(project.id)) {
            projectsToDelete.add(project.id);
          }
        }
      } catch (_) {
        // If path normalization fails, skip this project
        // Better to be safe and not delete than to delete incorrectly
      }
    }
    
    // Delete all projects from this root (except those in releases)
    if (projectsToDelete.isNotEmpty) {
      await projectsBox.deleteAll(projectsToDelete);
    }
    
    // Remove the root after deleting projects
    await rootsBox.delete(id);
  }

  Future<void> updateRootLastScanAt(String rootId, DateTime scanTime) async {
    final root = rootsBox.get(rootId);
    if (root != null) {
      await rootsBox.put(rootId, root.copyWith(lastScanAt: scanTime));
    }
  }

  List<ScanRoot> getRoots() => rootsBox.values.toList(growable: false);

  // Projects
  MusicProject? getByPath(String path) {
    try {
      return projectsBox.values.firstWhere((p) => p.filePath == path);
    } catch (_) {
      return null;
    }
  }

  // LÓGICA CORRIGIDA para preservar campos customizados
  /// Upserts a project from a file system entity
  /// [fullMetadata] if true, extracts full metadata (BPM, key, DAW version) - slower
  /// if false, only extracts DAW type from extension - faster
  Future<void> upsertFromFileSystemEntity(FileSystemEntity entity, {bool fullMetadata = false}) async {
    final isLogicBundle = entity is Directory && entity.path.toLowerCase().endsWith('.logicx');
    final filePath = entity.path;
    final stat = await entity.stat();
    final fileName = p.basename(filePath);
    final ext = isLogicBundle ? '.logicx' : p.extension(filePath).toLowerCase();
    final size = stat.size;
    final lastModified = stat.modified;

    final existing = getByPath(filePath);
    
    // Extract metadata from project file
    ProjectMetadata? extractedMetadata;
    try {
      if (fullMetadata) {
        extractedMetadata = await MetadataExtractor.extractMetadata(filePath);
      } else {
        extractedMetadata = await MetadataExtractor.extractLightweightMetadata(filePath);
      }
    } catch (_) {
      // If extraction fails, continue without metadata
    }
    
    // Always update BPM and key from file if available (these can change in the project)
    // Fall back to existing values only if extraction didn't find anything
    final bpm = extractedMetadata?.bpm ?? existing?.bpm;
    final key = extractedMetadata?.key ?? existing?.musicalKey;
    
    // Determine DAW type: always update from file (based on extension)
    final dawType = extractedMetadata?.dawType;
    // Preserve existing DAW version if extraction didn't find anything (e.g., during lightweight scan)
    final dawVersion = extractedMetadata?.dawVersion ?? existing?.dawVersion;
    
    // Cria o objeto base, usando os dados existentes se houver, 
    // mas atualizando os campos que vêm do sistema de arquivos (size, lastModified, fileName, etc.)
    final projectToSave = MusicProject(
      id: existing?.id ?? _uuid.v4(),
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: size,
      lastModifiedAt: lastModified,
      fileExtension: ext,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      
      // PRESERVAÇÃO: Estes campos foram editados pelo usuário e devem ser mantidos
      customDisplayName: existing?.customDisplayName, // <--- PRESERVA
      status: existing?.status ?? 'Idea',             // <--- PRESERVA (default changed from 'Draft' to 'Idea')
      bpm: bpm,                                        // <--- USA EXISTENTE OU EXTRAÍDO
      musicalKey: key,                                 // <--- USA EXISTENTE OU EXTRAÍDO
      notes: existing?.notes,                         // <--- NOVO: PRESERVA NOTAS
      dawType: dawType,                                // <--- SEMPRE ATUALIZA DO ARQUIVO
      dawVersion: dawVersion,                          // <--- USA EXISTENTE OU EXTRAÍDO (preserva se já existe)
    );

    await projectsBox.put(projectToSave.id, projectToSave);
  }

  List<MusicProject> getAllProjects() => projectsBox.values.toList(growable: false);

  Future<void> updateProject(MusicProject project) async {
    await projectsBox.put(project.id, project.copyWith(updatedAt: DateTime.now()));
  }

  /// Extracts full metadata for a single project and updates it
  Future<void> extractFullMetadataForProject(String projectId) async {
    final project = projectsBox.get(projectId);
    if (project == null) return;

    try {
      final extractedMetadata = await MetadataExtractor.extractMetadata(project.filePath);
      
      // Update project with extracted metadata, preserving existing values if extraction didn't find anything
      final updated = project.copyWith(
        bpm: extractedMetadata.bpm ?? project.bpm,
        musicalKey: extractedMetadata.key ?? project.musicalKey,
        dawType: extractedMetadata.dawType ?? project.dawType,
        dawVersion: extractedMetadata.dawVersion ?? project.dawVersion,
        updatedAt: DateTime.now(),
      );
      
      await projectsBox.put(projectId, updated);
    } catch (_) {
      // If extraction fails, silently continue
    }
  }

  // Reactive listeners
  ValueListenable<Box<MusicProject>> projectsListenable() => projectsBox.listenable();
  ValueListenable<Box<ScanRoot>> rootsListenable() => rootsBox.listenable();

  // Stream watch for Riverpod StreamProvider usage
  Stream<BoxEvent> watchProjects() => projectsBox.watch();
  
  // MÉTODO NOVO/CORRIGIDO: Retorna a lista completa a cada mudança do Hive
  Stream<List<MusicProject>> watchAllProjects() async* {
    // Emit initial value immediately
    yield projectsBox.values.toList();
    // Then watch for changes
    yield* projectsBox.watch().map((_) => projectsBox.values.toList());
  }
  
  Stream<BoxEvent> watchRoots() => rootsBox.watch();

  Future<void> clearAllData() async {
    // Get all project IDs that are referenced in releases (to preserve them)
    final releases = getAllReleases();
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }
    
    // Delete all projects except those referenced in releases
    if (protectedProjectIds.isNotEmpty) {
      final allProjectIds = projectsBox.keys.cast<String>().toSet();
      final projectsToDelete = allProjectIds.difference(protectedProjectIds);
      if (projectsToDelete.isNotEmpty) {
        await projectsBox.deleteAll(projectsToDelete);
      }
    } else {
      // No protected projects, safe to clear all
      await projectsBox.clear();
    }
    
    // Always clear roots
    await rootsBox.clear();
  }

  Future<void> clearMissingFiles() async {
    final toDelete = <dynamic>[];
    for (final entry in projectsBox.values) {
      if (!File(entry.filePath).existsSync() && !Directory(entry.filePath).existsSync()) {
        toDelete.add(entry.id);
      }
    }
    await projectsBox.deleteAll(toDelete);
  }

  // Releases
  Future<void> addRelease(Release release) async {
    await releasesBox.put(release.id, release);
  }

  Future<void> updateRelease(Release release) async {
    await releasesBox.put(release.id, release);
  }

  Future<void> deleteRelease(String releaseId) async {
    await releasesBox.delete(releaseId);
  }

  List<Release> getAllReleases() => releasesBox.values.toList(growable: false);

  Release? getReleaseById(String id) {
    try {
      return releasesBox.get(id);
    } catch (_) {
      return null;
    }
  }

  Stream<List<Release>> watchAllReleases() async* {
    // Emit initial value immediately
    yield releasesBox.values.toList();
    // Then watch for changes
    yield* releasesBox.watch().map((_) => releasesBox.values.toList());
  }

  Stream<BoxEvent> watchReleases() => releasesBox.watch();
}
