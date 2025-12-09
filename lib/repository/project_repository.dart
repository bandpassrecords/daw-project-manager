import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/music_project.dart';
import '../models/scan_root.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../services/metadata_extractor.dart';

class ProjectRepository {
  static const projectsBoxName = 'projects';
  static const rootsBoxName = 'roots';
  static const releasesBoxName = 'releases';

  final Box<MusicProject> projectsBox;
  final Box<ScanRoot> rootsBox;
  final Box<Release> releasesBox;
  final _uuid = const Uuid();

  ProjectRepository({
    required this.projectsBox,
    required this.rootsBox,
    required this.releasesBox,
  });

  static Future<ProjectRepository> init() async {
    await Hive.initFlutter();
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

    final projects = await Hive.openBox<MusicProject>(projectsBoxName);
    final roots = await Hive.openBox<ScanRoot>(rootsBoxName);
    final releases = await Hive.openBox<Release>(releasesBoxName);
    return ProjectRepository(
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
    await rootsBox.delete(id);
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
  Future<void> upsertFromFileSystemEntity(FileSystemEntity entity) async {
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
      extractedMetadata = await MetadataExtractor.extractMetadata(filePath);
    } catch (_) {
      // If extraction fails, continue without metadata
    }
    
    // Always update BPM and key from file if available (these can change in the project)
    // Fall back to existing values only if extraction didn't find anything
    final bpm = extractedMetadata?.bpm ?? existing?.bpm;
    final key = extractedMetadata?.key ?? existing?.musicalKey;
    
    // Determine DAW type and version: use extracted (always update from file)
    final dawType = extractedMetadata?.dawType;
    final dawVersion = extractedMetadata?.dawVersion;
    
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
      status: existing?.status ?? 'Draft',             // <--- PRESERVA
      bpm: bpm,                                        // <--- USA EXISTENTE OU EXTRAÍDO
      musicalKey: key,                                 // <--- USA EXISTENTE OU EXTRAÍDO
      notes: existing?.notes,                         // <--- NOVO: PRESERVA NOTAS
      dawType: dawType,                                // <--- SEMPRE ATUALIZA DO ARQUIVO
      dawVersion: dawVersion,                          // <--- SEMPRE ATUALIZA DO ARQUIVO
    );

    await projectsBox.put(projectToSave.id, projectToSave);
  }

  List<MusicProject> getAllProjects() => projectsBox.values.toList(growable: false);

  Future<void> updateProject(MusicProject project) async {
    await projectsBox.put(project.id, project.copyWith(updatedAt: DateTime.now()));
  }

  // Reactive listeners
  ValueListenable<Box<MusicProject>> projectsListenable() => projectsBox.listenable();
  ValueListenable<Box<ScanRoot>> rootsListenable() => rootsBox.listenable();

  // Stream watch for Riverpod StreamProvider usage
  Stream<BoxEvent> watchProjects() => projectsBox.watch();
  
  // MÉTODO NOVO/CORRIGIDO: Retorna a lista completa a cada mudança do Hive
  Stream<List<MusicProject>> watchAllProjects() {
    return projectsBox.watch().map((_) => projectsBox.values.toList());
  }
  
  Stream<BoxEvent> watchRoots() => rootsBox.watch();

  Future<void> clearAllData() async {
    await projectsBox.clear();
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