import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:file_picker/file_picker.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/custom_theme.dart';
import '../models/music_project.dart';
import '../models/project_attachment.dart';
import '../models/project_marker.dart';
import '../models/scan_root.dart';
import '../models/ignored_path.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../models/profile.dart';
import '../models/todo_item.dart';
import '../models/todo_template.dart';
import '../models/part_template.dart';
import '../models/project_part.dart';
import '../models/project_template.dart';
import '../models/template_root.dart';
import '../repository/project_repository.dart';
import '../repository/profile_repository.dart';
import 'custom_theme_merge.dart';
import '../utils/app_paths.dart';

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
      final ignoredPaths = projectRepo.getIgnoredPaths();
      final releases = projectRepo.getAllReleases();
      final profile = profileRepo.getProfileById(profileId);

      // Globally-scoped user data (not per-profile). Drive sync has always
      // included these; a local backup that omitted them meant anyone without
      // Drive — notably Flatpak, where Drive sync is unavailable — had no way
      // to back up their templates or phase customization at all.
      final templates = await _readGlobalTemplates();
      final partTemplates = await _readGlobalPartTemplates();
      final projectTemplates = await _readGlobalProjectTemplates();
      final templateRoots = await _readGlobalTemplateRoots();
      final customMixdownFolders = await _readCustomMixdownFolders();
      final customMixdownFoldersByDaw = await _readCustomMixdownFoldersByDaw();
      final dawLaunchCommands = await _readDawLaunchCommands();
      final customThemes = await _readCustomThemes();
      // Unlike Drive (which stores a byProfile map for every profile), a local
      // backup covers a single profile, so only that profile's phase settings
      // are relevant here.
      final phaseSettings = await _readPhaseSettings(profileId);

      // Create backup data structure
      final backupData = {
        // 1.1 added templates/projectTemplates/templateRoots/
        // customMixdownFolders/phaseSettings. 1.2 added partTemplates (and, on
        // each project, its parts). 1.3 added customThemes. Importing an older
        // file still works — every new key is read with a null check on the
        // way back in.
        'version': '1.3',
        'exportDate': DateTime.now().toIso8601String(),
        'profileId': profileId,
        'profile': profile != null ? await _profileToJson(profile) : null,
        'projects': await Future.wait(projects.map(_projectToJsonWithCoverArt)),
        'roots': roots.map((r) => _rootToJson(r)).toList(),
        'ignoredPaths': ignoredPaths.map((ip) => _ignoredPathToJson(ip)).toList(),
        'releases': await Future.wait(releases.map((r) => _releaseToJson(r))),
        'templates': templates.map(_todoTemplateToJson).toList(),
        'partTemplates': partTemplates.map((t) => t.toJson()).toList(),
        'projectTemplates': projectTemplates.map(_projectTemplateToJson).toList(),
        'templateRoots': templateRoots.map(_templateRootToJson).toList(),
        'customMixdownFolders': customMixdownFolders,
        'customMixdownFoldersByDaw': customMixdownFoldersByDaw,
        'dawLaunchCommands': dawLaunchCommands,
        // User-authored themes. Global (not per-profile), and this is the only
        // backup path Flatpak has, so leaving them out would mean Flatpak
        // users could never back a theme up at all. The *selected* theme is
        // deliberately absent: that is a device-local preference.
        'customThemes': customThemes.map((t) => t.toJson()).toList(),
        'phaseSettings': phaseSettings,
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save to file
      final result = await FilePicker.saveFile(
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
      final result = await FilePicker.pickFiles(
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
      final importedIgnoredPaths = <IgnoredPath>[];
      final importedReleases = <Release>[];

      // Import projects
      if (backupData['projects'] != null) {
        final projectsList = backupData['projects'] as List;
        for (var projectJson in projectsList) {
          try {
            final project = await _projectFromJsonWithCoverArt(
              projectJson as Map<String, dynamic>,
            );
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

      // Import ignored paths (optional, backward compatible)
      if (backupData['ignoredPaths'] != null) {
        final ignoredList = backupData['ignoredPaths'] as List;
        for (var ignoredJson in ignoredList) {
          try {
            final ignoredPath = _ignoredPathFromJson(ignoredJson as Map<String, dynamic>);
            importedIgnoredPaths.add(ignoredPath);
          } catch (e) {
            continue;
          }
        }
      }

      // Import releases
      if (backupData['releases'] != null) {
        final releasesList = backupData['releases'] as List;
        for (var releaseJson in releasesList) {
          try {
            final release = await _releaseFromJson(releaseJson as Map<String, dynamic>);
            importedReleases.add(release);
          } catch (e) {
            // Skip invalid releases
            continue;
          }
        }
      }

      // Import global (non-per-profile) data — added in backup version 1.1.
      // Absent entirely on a 1.0 file, so every block below is a no-op there.
      final importedTemplates = <TodoTemplate>[];
      if (backupData['templates'] != null) {
        for (final templateJson in backupData['templates'] as List) {
          try {
            importedTemplates.add(_todoTemplateFromJson(templateJson as Map<String, dynamic>));
          } catch (e) {
            continue;
          }
        }
      }

      final importedPartTemplates = <PartTemplate>[];
      if (backupData['partTemplates'] != null) {
        for (final templateJson in backupData['partTemplates'] as List) {
          try {
            importedPartTemplates
                .add(PartTemplate.fromJson(templateJson as Map<String, dynamic>));
          } catch (e) {
            continue;
          }
        }
      }

      final importedProjectTemplates = <ProjectTemplate>[];
      if (backupData['projectTemplates'] != null) {
        for (final templateJson in backupData['projectTemplates'] as List) {
          try {
            importedProjectTemplates.add(_projectTemplateFromJson(templateJson as Map<String, dynamic>));
          } catch (e) {
            continue;
          }
        }
      }

      final importedTemplateRoots = <TemplateRoot>[];
      if (backupData['templateRoots'] != null) {
        for (final rootJson in backupData['templateRoots'] as List) {
          try {
            importedTemplateRoots.add(_templateRootFromJson(rootJson as Map<String, dynamic>));
          } catch (e) {
            continue;
          }
        }
      }

      final importedCustomMixdownFolders = (backupData['customMixdownFolders'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      final importedCustomMixdownFoldersByDaw =
          (backupData['customMixdownFoldersByDaw'] as Map?)?.map(
                (key, value) => MapEntry(
                  key as String,
                  (value as List).map((f) => f.toString()).toList(),
                ),
              ) ??
          const <String, List<String>>{};

      final importedDawLaunchCommands = _normalizeDawLaunchCommands(
        (backupData['dawLaunchCommands'] as Map?) ?? const {},
      );

      // Absent in a pre-1.3 backup, which is fine — the user simply had no
      // custom themes to restore.
      final importedCustomThemes = customThemesFromJson(
        backupData['customThemes'] as List?,
      );

      final importedPhaseSettings =
          (backupData['phaseSettings'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

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
      // Use restoreProject to preserve the original lastModifiedAt from the backup
      for (final project in importedProjects) {
        await targetRepo.restoreProject(project);
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

      for (final ignoredPath in importedIgnoredPaths) {
        // Only add if not already present in merge mode
        if (importMode == ImportMode.merge) {
          final existingIgnored = targetRepo.getIgnoredPaths();
          if (!existingIgnored.any((p) => p.path == ignoredPath.path)) {
            await targetRepo.addIgnoredPath(ignoredPath.path);
          }
        } else {
          await targetRepo.addIgnoredPath(ignoredPath.path);
        }
      }

      for (final release in importedReleases) {
        await targetRepo.updateRelease(release);
      }

      // Restore global (non-per-profile) data. These boxes are shared across
      // every profile, so — unlike the per-profile data above — writing them
      // is never gated on importMode being merge vs. createNewProfile; the
      // only mode-sensitive behavior is Replace clearing each box first, same
      // as targetRepo.clearAllData() does for the per-profile boxes above.
      await _writeGlobalTemplates(importedTemplates, importMode);
      await _writeGlobalPartTemplates(importedPartTemplates, importMode);
      await _writeGlobalProjectTemplates(importedProjectTemplates, importMode);
      await _writeGlobalTemplateRoots(importedTemplateRoots, importMode);
      await _writeCustomMixdownFolders(importedCustomMixdownFolders);
      await _writeCustomMixdownFoldersByDaw(importedCustomMixdownFoldersByDaw);
      await _writeDawLaunchCommands(importedDawLaunchCommands);
      await _writeCustomThemes(importedCustomThemes);
      await _writePhaseSettings(targetProfileId, importedPhaseSettings);

      // Restore profile photo if embedded in backup
      final profileJson = backupData['profile'] as Map<String, dynamic>?;
      if (profileJson != null) {
        final photoBase64 = profileJson['photoData'] as String?;
        if (photoBase64 != null && photoBase64.isNotEmpty) {
          try {
            final photoFileName = profileJson['photoFileName'] as String? ?? 'photo.jpg';
            final photosDir = p.join(await getLocalAppDataPath(), 'profile_photos');
            final dir = Directory(photosDir);
            if (!await dir.exists()) await dir.create(recursive: true);
            final ext = p.extension(photoFileName);
            final destPath = p.join(photosDir, '${targetProfileId}_photo$ext');
            await File(destPath).writeAsBytes(base64Decode(photoBase64));
            final currentProfile = profileRepo.getProfileById(targetProfileId);
            if (currentProfile != null) {
              await profileRepo.updateProfile(currentProfile.copyWith(photoPath: destPath));
            }
          } catch (_) {}
        }
      }

      return ImportResult(
        cancelled: false,
        projectsCount: importedProjects.length,
        rootsCount: importedRoots.length,
        ignoredPathsCount: importedIgnoredPaths.length,
        releasesCount: importedReleases.length,
        templatesCount: importedTemplates.length,
        projectTemplatesCount: importedProjectTemplates.length,
        newProfileId: createdProfileId,
      );
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Global (non-per-profile) user data.
  //
  // These live in their own top-level Hive boxes rather than behind
  // ProjectRepository, so they're read/written directly here. Every read is
  // failure-tolerant and returns an empty result: a box that can't be opened
  // should degrade to "nothing to back up for this section", never abort an
  // export the user asked for.
  // ---------------------------------------------------------------------------

  static const String _appSettingsBoxName = 'app_settings';
  static const String _todoTemplatesBoxName = 'todoTemplates';
  static const String _partTemplatesBoxName = 'partTemplates';
  static const String _projectTemplatesBoxName = 'projectTemplates';
  static const String _templateRootsBoxName = 'templateRoots';
  static const String _customMixdownFoldersKey = 'customMixdownFolders';
  static const String _customMixdownFoldersByDawKey = 'customMixdownFoldersByDaw';
  static const String _dawLaunchCommandsByDawKey = 'dawLaunchCommandsByDaw';
  static const String _customThemesKey = 'customThemes';

  static Future<List<TodoTemplate>> _readGlobalTemplates() async {
    try {
      final box = await Hive.openBox<TodoTemplate>(_todoTemplatesBoxName);
      return box.values.toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<PartTemplate>> _readGlobalPartTemplates() async {
    try {
      final box = await Hive.openBox<PartTemplate>(_partTemplatesBoxName);
      return box.values.toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<ProjectTemplate>> _readGlobalProjectTemplates() async {
    try {
      final box = await Hive.openBox<ProjectTemplate>(_projectTemplatesBoxName);
      return box.values.toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<TemplateRoot>> _readGlobalTemplateRoots() async {
    try {
      final box = await Hive.openBox<TemplateRoot>(_templateRootsBoxName);
      return box.values.toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<String>> _readCustomMixdownFolders() async {
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      final raw = box.get(_customMixdownFoldersKey);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<Map<String, List<String>>> _readCustomMixdownFoldersByDaw() async {
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      final raw = box.get(_customMixdownFoldersByDawKey);
      if (raw == null) return const {};
      return (jsonDecode(raw) as Map).map(
        (key, value) => MapEntry(
          key as String,
          (value as List).map((f) => f.toString()).toList(),
        ),
      );
    } catch (_) {
      return const {};
    }
  }

  /// User-authored themes. Global (not per-profile), stored as a JSON array
  /// in the same box as the other global preferences.
  static Future<List<CustomTheme>> _readCustomThemes() async {
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      return _customThemesFromRaw(box.get(_customThemesKey));
    } catch (_) {
      return const [];
    }
  }

  static List<CustomTheme> _customThemesFromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return customThemesFromJson(jsonDecode(raw) as List?);
    } catch (_) {
      return const [];
    }
  }

  /// Merges [themes] into the stored ones — union rather than overwrite,
  /// matching how the mixdown folder names above are restored, and resolved
  /// by the same [mergeCustomThemes] that Drive sync uses so a restore and a
  /// sync can't disagree about which copy of a theme wins.
  static Future<void> _writeCustomThemes(List<CustomTheme> themes) async {
    if (themes.isEmpty) return;
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      final merged = mergeCustomThemes(
        _customThemesFromRaw(box.get(_customThemesKey)),
        themes,
      );
      await box.put(
        _customThemesKey,
        jsonEncode(merged.map((t) => t.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// "Launch in DAW" executable overrides, keyed by DAW display name. Global
  /// (device-local), not per-profile — see
  /// ProjectRepository.getDawLaunchCommands. Included in local backup (also
  /// per-machine) but deliberately NOT in Google Drive sync
  /// (google_drive_sync_service.dart): these are raw filesystem paths to
  /// programs installed on this specific machine (and a macOS `.app` path
  /// wouldn't resolve on Windows/Linux and vice versa), so pushing them to
  /// other devices would only ever point at the wrong place.
  static Future<Map<String, List<String>>> _readDawLaunchCommands() async {
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      final raw = box.get(_dawLaunchCommandsByDawKey);
      if (raw == null) return const {};
      return _normalizeDawLaunchCommands(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  /// Coerces either JSON shape — `{daw: "path"}` (legacy) or
  /// `{daw: ["path", ...]}` (current) — into the list form, dropping blanks
  /// and empty DAWs. Mirrors ProjectRepository.getDawLaunchCommands.
  static Map<String, List<String>> _normalizeDawLaunchCommands(Map decoded) {
    final out = <String, List<String>>{};
    decoded.forEach((key, value) {
      final paths = <String>[
        if (value is String)
          value
        else if (value is List)
          for (final v in value) v.toString(),
      ].map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (paths.isNotEmpty) out[key as String] = paths;
    });
    return out;
  }

  /// Phase customization for [profileId]: custom phase names, their colors, and
  /// which phases count as "finished". Keys mirror the ones Drive sync uses so
  /// the two backup formats stay readable against each other.
  static Future<Map<String, dynamic>> _readPhaseSettings(String profileId) async {
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      final phasesRaw = box.get('${profileId}_phases');
      final colorsRaw = box.get('${profileId}_phase_colors');
      final finishedRaw = box.get('${profileId}_finished_phases');
      final legacyFinishedRaw = box.get('${profileId}_finished_phase');

      final settings = <String, dynamic>{};
      if (phasesRaw != null) settings['phases'] = jsonDecode(phasesRaw);
      if (colorsRaw != null) settings['phaseColors'] = jsonDecode(colorsRaw);
      if (finishedRaw != null) {
        settings['finishedPhases'] = jsonDecode(finishedRaw);
      } else if (legacyFinishedRaw != null) {
        // Pre-multi-phase backups stored a single phase name under a
        // singular key; normalize it to the list shape on the way out.
        settings['finishedPhases'] = [legacyFinishedRaw];
      }
      return settings;
    } catch (_) {
      return const {};
    }
  }

  static Future<void> _writeGlobalTemplates(
    List<TodoTemplate> templates,
    ImportMode importMode,
  ) async {
    if (templates.isEmpty) return;
    try {
      final box = await Hive.openBox<TodoTemplate>(_todoTemplatesBoxName);
      if (importMode == ImportMode.replace) await box.clear();
      for (final template in templates) {
        // Keyed by id so a re-import updates in place instead of duplicating.
        await box.put(template.id, template);
      }
    } catch (_) {
      // A failed template restore shouldn't fail the whole import — the
      // projects/releases the user actually came for are already in.
    }
  }

  static Future<void> _writeGlobalPartTemplates(
    List<PartTemplate> templates,
    ImportMode importMode,
  ) async {
    if (templates.isEmpty) return;
    try {
      final box = await Hive.openBox<PartTemplate>(_partTemplatesBoxName);
      if (importMode == ImportMode.replace) await box.clear();
      for (final template in templates) {
        await box.put(template.id, template);
      }
    } catch (_) {}
  }

  static Future<void> _writeGlobalProjectTemplates(
    List<ProjectTemplate> templates,
    ImportMode importMode,
  ) async {
    if (templates.isEmpty) return;
    try {
      final box = await Hive.openBox<ProjectTemplate>(_projectTemplatesBoxName);
      if (importMode == ImportMode.replace) await box.clear();
      for (final template in templates) {
        await box.put(template.id, template);
      }
    } catch (_) {}
  }

  static Future<void> _writeGlobalTemplateRoots(
    List<TemplateRoot> roots,
    ImportMode importMode,
  ) async {
    if (roots.isEmpty) return;
    try {
      final box = await Hive.openBox<TemplateRoot>(_templateRootsBoxName);
      if (importMode == ImportMode.replace) await box.clear();
      for (final root in roots) {
        await box.put(root.id, root);
      }
    } catch (_) {}
  }


  /// Merges [folders] into the stored custom mixdown folder names. Union rather
  /// than overwrite, matching how Drive sync merges the same preference — these
  /// are additive folder names, so losing a local one to an older backup would
  /// be surprising.
  static Future<void> _writeCustomMixdownFolders(List<String> folders) async {
    if (folders.isEmpty) return;
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      final existingRaw = box.get(_customMixdownFoldersKey);
      final merged = <String>{
        if (existingRaw != null)
          ...(jsonDecode(existingRaw) as List).map((e) => e.toString()),
        ...folders,
      };
      await box.put(_customMixdownFoldersKey, jsonEncode(merged.toList()));
    } catch (_) {}
  }

  /// Merges [foldersByDaw] into the stored per-DAW custom mixdown folder
  /// names, unioning each DAW's list rather than overwriting it — same
  /// rationale as [_writeCustomMixdownFolders].
  static Future<void> _writeCustomMixdownFoldersByDaw(
    Map<String, List<String>> foldersByDaw,
  ) async {
    if (foldersByDaw.isEmpty) return;
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      final existingRaw = box.get(_customMixdownFoldersByDawKey);
      final merged = <String, List<String>>{
        if (existingRaw != null)
          ...(jsonDecode(existingRaw) as Map).map(
            (key, value) => MapEntry(
              key as String,
              (value as List).map((f) => f.toString()).toList(),
            ),
          ),
      };
      for (final entry in foldersByDaw.entries) {
        final existing = merged.putIfAbsent(entry.key, () => []);
        for (final folder in entry.value) {
          if (!existing.contains(folder)) existing.add(folder);
        }
      }
      await box.put(_customMixdownFoldersByDawKey, jsonEncode(merged));
    } catch (_) {}
  }

  /// Merges [commands] into the local overrides: per DAW, the local paths
  /// are kept and any backup paths not already present are appended (a
  /// per-DAW list has a natural union, like mixdown folder names). A local
  /// path the user may have fixed since the backup is never dropped or
  /// reordered.
  static Future<void> _writeDawLaunchCommands(
    Map<String, List<String>> commands,
  ) async {
    if (commands.isEmpty) return;
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      final existingRaw = box.get(_dawLaunchCommandsByDawKey);
      final merged = <String, List<String>>{
        for (final entry in _normalizeDawLaunchCommands(
          existingRaw != null ? jsonDecode(existingRaw) as Map : const {},
        ).entries)
          entry.key: List<String>.from(entry.value),
      };
      commands.forEach((daw, paths) {
        final list = merged.putIfAbsent(daw, () => <String>[]);
        for (final path in paths) {
          final cleaned = path.trim();
          if (cleaned.isNotEmpty && !list.contains(cleaned)) list.add(cleaned);
        }
      });
      merged.removeWhere((_, paths) => paths.isEmpty);
      await box.put(_dawLaunchCommandsByDawKey, jsonEncode(merged));
    } catch (_) {}
  }

  static Future<void> _writePhaseSettings(
    String profileId,
    Map<String, dynamic> settings,
  ) async {
    if (settings.isEmpty) return;
    try {
      final box = await Hive.openBox<String>(_appSettingsBoxName);
      if (settings['phases'] != null) {
        await box.put('${profileId}_phases', jsonEncode(settings['phases']));
      }
      if (settings['phaseColors'] != null) {
        await box.put('${profileId}_phase_colors', jsonEncode(settings['phaseColors']));
      }
      if (settings['finishedPhases'] != null) {
        await box.put('${profileId}_finished_phases', jsonEncode(settings['finishedPhases']));
      }
    } catch (_) {}
  }

  // Global-data read/write — exposed for testing so a test can drive the
  // actual Hive box interaction (merge vs. replace semantics, box-not-openable
  // fallbacks) rather than only the pure JSON conversion below.
  @visibleForTesting
  static Future<List<TodoTemplate>> readGlobalTemplatesForTest() => _readGlobalTemplates();
  @visibleForTesting
  static Future<void> writeGlobalTemplatesForTest(List<TodoTemplate> templates, ImportMode mode) =>
      _writeGlobalTemplates(templates, mode);

  @visibleForTesting
  static Future<List<CustomTheme>> readCustomThemesForTest() =>
      _readCustomThemes();
  @visibleForTesting
  static Future<void> writeCustomThemesForTest(List<CustomTheme> themes) =>
      _writeCustomThemes(themes);
  @visibleForTesting
  static List<CustomTheme> customThemesFromJsonForTest(List? entries) =>
      customThemesFromJson(entries);

  @visibleForTesting
  static Future<List<PartTemplate>> readGlobalPartTemplatesForTest() =>
      _readGlobalPartTemplates();
  @visibleForTesting
  static Future<void> writeGlobalPartTemplatesForTest(
    List<PartTemplate> templates,
    ImportMode mode,
  ) =>
      _writeGlobalPartTemplates(templates, mode);

  @visibleForTesting
  static Future<List<ProjectTemplate>> readGlobalProjectTemplatesForTest() =>
      _readGlobalProjectTemplates();
  @visibleForTesting
  static Future<void> writeGlobalProjectTemplatesForTest(
    List<ProjectTemplate> templates,
    ImportMode mode,
  ) =>
      _writeGlobalProjectTemplates(templates, mode);

  @visibleForTesting
  static Future<List<TemplateRoot>> readGlobalTemplateRootsForTest() => _readGlobalTemplateRoots();
  @visibleForTesting
  static Future<void> writeGlobalTemplateRootsForTest(List<TemplateRoot> roots, ImportMode mode) =>
      _writeGlobalTemplateRoots(roots, mode);

  @visibleForTesting
  static Future<List<String>> readCustomMixdownFoldersForTest() => _readCustomMixdownFolders();
  @visibleForTesting
  static Future<void> writeCustomMixdownFoldersForTest(List<String> folders) =>
      _writeCustomMixdownFolders(folders);

  @visibleForTesting
  static Future<Map<String, List<String>>> readCustomMixdownFoldersByDawForTest() =>
      _readCustomMixdownFoldersByDaw();
  @visibleForTesting
  static Future<void> writeCustomMixdownFoldersByDawForTest(Map<String, List<String>> foldersByDaw) =>
      _writeCustomMixdownFoldersByDaw(foldersByDaw);

  @visibleForTesting
  static Future<Map<String, List<String>>> readDawLaunchCommandsForTest() =>
      _readDawLaunchCommands();
  @visibleForTesting
  static Future<void> writeDawLaunchCommandsForTest(
    Map<String, List<String>> commands,
  ) =>
      _writeDawLaunchCommands(commands);

  @visibleForTesting
  static Future<Map<String, dynamic>> readPhaseSettingsForTest(String profileId) =>
      _readPhaseSettings(profileId);
  @visibleForTesting
  static Future<void> writePhaseSettingsForTest(String profileId, Map<String, dynamic> settings) =>
      _writePhaseSettings(profileId, settings);

  // JSON serialization helpers — exposed for testing via the public wrappers below.
  @visibleForTesting
  static Map<String, dynamic> projectToJson(MusicProject project) =>
      _projectToJson(project);

  @visibleForTesting
  static Map<String, dynamic> todoTemplateToJson(TodoTemplate template) =>
      _todoTemplateToJson(template);
  @visibleForTesting
  static TodoTemplate todoTemplateFromJson(Map<String, dynamic> json) => _todoTemplateFromJson(json);

  @visibleForTesting
  static Map<String, dynamic> projectTemplateToJson(ProjectTemplate template) =>
      _projectTemplateToJson(template);
  @visibleForTesting
  static ProjectTemplate projectTemplateFromJson(Map<String, dynamic> json) =>
      _projectTemplateFromJson(json);

  @visibleForTesting
  static Map<String, dynamic> templateRootToJson(TemplateRoot root) => _templateRootToJson(root);
  @visibleForTesting
  static TemplateRoot templateRootFromJson(Map<String, dynamic> json) => _templateRootFromJson(json);

  @visibleForTesting
  static MusicProject projectFromJson(Map<String, dynamic> json) =>
      _projectFromJson(json);

  @visibleForTesting
  static Future<Map<String, dynamic>> projectToJsonWithCoverArt(
    MusicProject project,
  ) =>
      _projectToJsonWithCoverArt(project);

  @visibleForTesting
  static Future<MusicProject> projectFromJsonWithCoverArt(
    Map<String, dynamic> json,
  ) =>
      _projectFromJsonWithCoverArt(json);

  /// [_projectToJson] plus the cover art's bytes (#110).
  ///
  /// The image travels base64 inside the JSON, the way release artwork and
  /// profile photos already do: this is Flatpak's only backup path, so a
  /// cover left behind here is one those users could never back up at all —
  /// and a bare path is worthless on the machine the backup is restored to.
  /// Kept separate from [_projectToJson] so that stays synchronous for the
  /// metadata-only round-trip tests.
  static Future<Map<String, dynamic>> _projectToJsonWithCoverArt(
    MusicProject project,
  ) async {
    final json = _projectToJson(project);
    final coverPath = project.thumbnailPath;
    if (coverPath != null && coverPath.isNotEmpty) {
      try {
        final file = File(coverPath);
        if (await file.exists()) {
          json['coverArtData'] = base64Encode(await file.readAsBytes());
          json['coverArtFileName'] = p.basename(coverPath);
        }
      } catch (_) {
        // Unreadable cover: back the metadata up without it rather than
        // failing the export.
      }
    }
    return json;
  }

  /// [_projectFromJson] plus materializing the embedded cover art (#110).
  ///
  /// The image is written into the managed cover-art folder and the project
  /// re-pointed at it, because the exporting machine's path means nothing
  /// here. A backup with no embedded bytes keeps whatever path it carried —
  /// on the same machine that is still the right file.
  static Future<MusicProject> _projectFromJsonWithCoverArt(
    Map<String, dynamic> json,
  ) async {
    final project = _projectFromJson(json);
    final coverBase64 = json['coverArtData'] as String?;
    if (coverBase64 == null || coverBase64.isEmpty) return project;
    try {
      final coverFileName = json['coverArtFileName'] as String? ?? 'cover.jpg';
      final coverDirPath = await getProjectCoverArtPath();
      final dir = Directory(coverDirPath);
      if (!await dir.exists()) await dir.create(recursive: true);
      final destName = '${project.id}_cover${p.extension(coverFileName)}';
      final destPath = p.join(coverDirPath, destName);
      await File(destPath).writeAsBytes(base64Decode(coverBase64));
      return project.copyWith(thumbnailPath: destPath);
    } catch (_) {
      return project;
    }
  }

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
      'todos': project.todos.map((t) => _todoToJson(t)).toList(),
      'parts': project.parts.map((part) => part.toJson()).toList(),
      'hidden': project.hidden,
      'previewSongPath': project.previewSongPath,
      'fileCreatedAt': project.fileCreatedAt?.toIso8601String(),
      'statusChangedAt': project.statusChangedAt?.toIso8601String(),
      'previewSongFileName': project.previewSongFileName,
      'uploadedPreviewSongHash': project.uploadedPreviewSongHash,
      'deadline': project.deadline?.toIso8601String(),
      'totalWorkSeconds': project.totalWorkSeconds,
      'sessions': project.sessions.map((s) => s.toMap()).toList(),
      'metadataScanned': project.metadataScanned,
      'previewSongAutoPath': project.previewSongAutoPath,
      'parentProjectId': project.parentProjectId,
      'ignoredNewerSongPath': project.ignoredNewerSongPath,
      'projectNotes': project.projectNotes,
      'sourceTemplateId': project.sourceTemplateId,
      // See the same block in google_drive_sync_service.dart — this is
      // Flatpak's only backup path, so a field skipped here cannot be backed
      // up at all, not merely lost on a Drive restore.
      'isVirtual': project.isVirtual,
      'memberProjectIds': project.memberProjectIds,
      'defaultLaunchMemberId': project.defaultLaunchMemberId,
      'stackId': project.stackId,
      'markers': project.markers.map((m) => m.toMap()).toList(),
      'attachments': project.attachments.map((a) => a.toMap()).toList(),
      // Per-project appearance (#110). Overrides only — null means "derive
      // from the id", which needs nothing stored to survive a restore.
      'accentColor': project.accentColor,
      'iconKey': project.iconKey,
      // User data: someone typed these two letters onto the card.
      'cardInitials': project.cardInitials,
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
      todos: (json['todos'] as List?)?.map((t) => _todoFromJson(t as Map<String, dynamic>)).toList() ?? [],
      parts: (json['parts'] as List?)
              ?.map((part) => ProjectPart.fromJson(part as Map<dynamic, dynamic>))
              .toList() ??
          const [],
      hidden: json['hidden'] as bool? ?? false,
      previewSongPath: json['previewSongPath'] as String?,
      fileCreatedAt: json['fileCreatedAt'] != null ? DateTime.parse(json['fileCreatedAt'] as String) : null,
      statusChangedAt: json['statusChangedAt'] != null ? DateTime.parse(json['statusChangedAt'] as String) : null,
      previewSongFileName: json['previewSongFileName'] as String?,
      uploadedPreviewSongHash: json['uploadedPreviewSongHash'] as String?,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      totalWorkSeconds: json['totalWorkSeconds'] as int? ?? 0,
      sessions: (json['sessions'] as List?)
              ?.map((e) => SessionRecord.fromMap(e as Map))
              .toList() ??
          const [],
      metadataScanned: json['metadataScanned'] as bool? ?? false,
      previewSongAutoPath: json['previewSongAutoPath'] as String?,
      parentProjectId: json['parentProjectId'] as String?,
      ignoredNewerSongPath: json['ignoredNewerSongPath'] as String?,
      projectNotes: json['projectNotes'] as String?,
      sourceTemplateId: json['sourceTemplateId'] as String?,
      isVirtual: json['isVirtual'] as bool? ?? false,
      memberProjectIds:
          (json['memberProjectIds'] as List?)?.cast<String>() ??
          const <String>[],
      defaultLaunchMemberId: json['defaultLaunchMemberId'] as String?,
      stackId: json['stackId'] as String?,
      markers: (json['markers'] as List?)
              ?.map((e) => ProjectMarker.fromMap(e as Map))
              .toList() ??
          const [],
      attachments: (json['attachments'] as List?)
              ?.map((e) => ProjectAttachment.fromMap(e as Map))
              .toList() ??
          const [],
      accentColor: (json['accentColor'] as num?)?.toInt(),
      iconKey: json['iconKey'] as String?,
      cardInitials: json['cardInitials'] as String?,
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

  static Map<String, dynamic> _ignoredPathToJson(IgnoredPath p) {
    return {
      'id': p.id,
      'path': p.path,
      'addedAt': p.addedAt.toIso8601String(),
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

  static IgnoredPath _ignoredPathFromJson(Map<String, dynamic> json) {
    return IgnoredPath(
      id: json['id'] as String? ?? '',
      path: json['path'] as String,
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt'] as String) : DateTime.now(),
    );
  }

  static Map<String, dynamic> _todoTemplateToJson(TodoTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'items': template.items,
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': template.updatedAt.toIso8601String(),
    };
  }

  static TodoTemplate _todoTemplateFromJson(Map<String, dynamic> json) {
    return TodoTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static Map<String, dynamic> _projectTemplateToJson(ProjectTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'sourceFolderPath': template.sourceFolderPath,
      'mainFileRelativePath': template.mainFileRelativePath,
      'createdAt': template.createdAt.toIso8601String(),
      'updatedAt': template.updatedAt.toIso8601String(),
      'bpm': template.bpm,
      'musicalKey': template.musicalKey,
      'dawVersion': template.dawVersion,
      'notes': template.notes,
      'projectNotes': template.projectNotes,
    };
  }

  static ProjectTemplate _projectTemplateFromJson(Map<String, dynamic> json) {
    return ProjectTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceFolderPath: json['sourceFolderPath'] as String,
      mainFileRelativePath: json['mainFileRelativePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      bpm: (json['bpm'] as num?)?.toDouble(),
      musicalKey: json['musicalKey'] as String?,
      dawVersion: json['dawVersion'] as String?,
      notes: json['notes'] as String?,
      projectNotes: json['projectNotes'] as String?,
    );
  }

  static Map<String, dynamic> _templateRootToJson(TemplateRoot root) {
    return {
      'id': root.id,
      'path': root.path,
      'addedAt': root.addedAt.toIso8601String(),
      'lastRefreshedAt': root.lastRefreshedAt?.toIso8601String(),
    };
  }

  static TemplateRoot _templateRootFromJson(Map<String, dynamic> json) {
    return TemplateRoot(
      id: json['id'] as String,
      path: json['path'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastRefreshedAt:
          json['lastRefreshedAt'] != null ? DateTime.parse(json['lastRefreshedAt'] as String) : null,
    );
  }

  static Future<Map<String, dynamic>> _releaseToJson(Release release) async {
    String? artworkBase64;
    String? artworkFileName;
    if (release.artworkImagePath != null) {
      try {
        final file = File(release.artworkImagePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          artworkBase64 = base64Encode(bytes);
          artworkFileName = p.basename(release.artworkImagePath!);
        }
      } catch (_) {}
    }
    return {
      'id': release.id,
      'title': release.title,
      'releaseDate': release.releaseDate?.toIso8601String(),
      'artworkImagePath': release.artworkImagePath,
      'artworkData': artworkBase64,
      'artworkFileName': artworkFileName,
      'description': release.description,
      'trackIds': release.trackIds,
      'files': release.files.map((f) => _releaseFileToJson(f)).toList(),
      'todos': release.todos.map((t) => _todoToJson(t)).toList(),
    };
  }

  static Future<Release> _releaseFromJson(Map<String, dynamic> json) async {
    String? artworkImagePath = json['artworkImagePath'] as String?;
    final artworkBase64 = json['artworkData'] as String?;
    if (artworkBase64 != null && artworkBase64.isNotEmpty) {
      try {
        final artworkFileName = json['artworkFileName'] as String? ?? 'artwork.jpg';
        final artworkDir = await getReleaseArtworkPath();
        final dir = Directory(artworkDir);
        if (!await dir.exists()) await dir.create(recursive: true);
        final releaseId = json['id'] as String? ?? '';
        final ext = p.extension(artworkFileName);
        final destFileName = releaseId.isNotEmpty ? '${releaseId}_artwork$ext' : artworkFileName;
        final destPath = p.join(artworkDir, destFileName);
        await File(destPath).writeAsBytes(base64Decode(artworkBase64));
        artworkImagePath = destPath;
      } catch (_) {}
    }
    return Release(
      id: json['id'] as String,
      title: json['title'] as String,
      releaseDate: json['releaseDate'] != null ? DateTime.parse(json['releaseDate'] as String) : null,
      artworkImagePath: artworkImagePath,
      description: json['description'] as String?,
      trackIds: (json['trackIds'] as List?)?.map((e) => e as String).toList() ?? [],
      files: (json['files'] as List?)?.map((f) => _releaseFileFromJson(f as Map<String, dynamic>)).toList() ?? [],
      todos: (json['todos'] as List?)?.map((t) => _todoFromJson(t as Map<String, dynamic>)).toList() ?? [],
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

  static Future<Map<String, dynamic>> _profileToJson(Profile profile) async {
    String? photoBase64;
    String? photoFileName;
    if (profile.photoPath != null) {
      try {
        final file = File(profile.photoPath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          photoBase64 = base64Encode(bytes);
          photoFileName = p.basename(profile.photoPath!);
        }
      } catch (_) {}
    }
    return {
      'id': profile.id,
      'name': profile.name,
      'createdAt': profile.createdAt.toIso8601String(),
      'lastUsedAt': profile.lastUsedAt?.toIso8601String(),
      'photoPath': profile.photoPath,
      'photoData': photoBase64,
      'photoFileName': photoFileName,
    };
  }

  static Map<String, dynamic> _todoToJson(TodoItem todo) {
    return {
      'id': todo.id,
      'text': todo.text,
      'completed': todo.completed,
      'createdAt': todo.createdAt.toIso8601String(),
      'dueAt': todo.dueAt?.toIso8601String(),
    };
  }

  static TodoItem _todoFromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      text: json['text'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      // Backups written before #113 carry no 'dueAt'.
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'] as String)
          : null,
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
  final int ignoredPathsCount;
  final int releasesCount;
  final int templatesCount;
  final int projectTemplatesCount;
  final String? newProfileId;

  ImportResult({
    this.cancelled = false,
    this.projectsCount = 0,
    this.rootsCount = 0,
    this.ignoredPathsCount = 0,
    this.releasesCount = 0,
    this.templatesCount = 0,
    this.projectTemplatesCount = 0,
    this.newProfileId,
  });
}

