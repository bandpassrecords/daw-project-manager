import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_marker.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/models/project_template.dart';
import 'package:daw_project_manager/models/todo_item.dart';

/// Factory helpers for creating consistent test fixtures.
class TestFactories {
  /// A recent, fully-populated [MusicProject] with all fields set.
  static MusicProject makeProject({
    String id = 'test-id-1',
    String filePath = '/Users/test/Projects/MyProject.als',
    String fileName = 'MyProject.als',
    int fileSizeBytes = 1024000,
    DateTime? lastModifiedAt,
    DateTime? fileCreatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String status = 'Mixing',
    String? customDisplayName,
    String? thumbnailPath,
    String? dawType = 'Ableton Live',
    String? dawVersion = '11',
    double? bpm,
    String? musicalKey,
    String? notes,
    List<TodoItem>? todos,
    List<ProjectPart>? parts,
    DateTime? deadline,
    bool hidden = false,
    String? previewSongPath,
    String? previewSongFileName,
    String? uploadedPreviewSongHash,
    DateTime? statusChangedAt,
    int totalWorkSeconds = 0,
    List<SessionRecord>? sessions,
    bool metadataScanned = false,
    String? previewSongAutoPath,
    String? parentProjectId,
    String? ignoredNewerSongPath,
    String? projectNotes,
    String? sourceTemplateId,
    bool isVirtual = false,
    List<String> memberProjectIds = const [],
    String? defaultLaunchMemberId,
    String? stackId,
    List<ProjectMarker>? markers,
    int? accentColor,
    String? iconKey,
  }) {
    return MusicProject(
      id: id,
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      lastModifiedAt: lastModifiedAt ?? DateTime(2025, 1, 15, 10, 30),
      fileExtension: '.als',
      createdAt: createdAt ?? DateTime(2024, 6, 1, 12, 0),
      updatedAt: updatedAt ?? DateTime(2025, 1, 14, 9, 0),
      status: status,
      customDisplayName: customDisplayName,
      thumbnailPath: thumbnailPath,
      dawType: dawType,
      dawVersion: dawVersion,
      fileCreatedAt: fileCreatedAt,
      bpm: bpm,
      musicalKey: musicalKey,
      notes: notes,
      todos: todos ?? const [],
      parts: parts ?? const [],
      deadline: deadline,
      hidden: hidden,
      previewSongPath: previewSongPath,
      previewSongFileName: previewSongFileName,
      uploadedPreviewSongHash: uploadedPreviewSongHash,
      statusChangedAt: statusChangedAt,
      totalWorkSeconds: totalWorkSeconds,
      sessions: sessions ?? const [],
      metadataScanned: metadataScanned,
      previewSongAutoPath: previewSongAutoPath,
      parentProjectId: parentProjectId,
      ignoredNewerSongPath: ignoredNewerSongPath,
      projectNotes: projectNotes,
      sourceTemplateId: sourceTemplateId,
      isVirtual: isVirtual,
      memberProjectIds: memberProjectIds,
      defaultLaunchMemberId: defaultLaunchMemberId,
      stackId: stackId,
      markers: markers ?? const [],
      accentColor: accentColor,
      iconKey: iconKey,
    );
  }

  static TodoItem makeTodo({
    String id = 'todo-1',
    String text = 'Mix the kick drum',
    bool completed = false,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id,
      text: text,
      completed: completed,
      createdAt: createdAt ?? DateTime(2025, 1, 10),
    );
  }

  static ProjectPart makePart({
    String id = 'part-1',
    String name = 'Drums',
    String? performer = 'Alex',
    PartTakeStatus status = PartTakeStatus.needed,
    String? notes,
  }) {
    return ProjectPart(
      id: id,
      name: name,
      performer: performer,
      status: status,
      notes: notes,
    );
  }

  /// Minimal project with only required fields.
  static MusicProject makeMinimalProject({String id = 'min-id'}) {
    return MusicProject(
      id: id,
      filePath: '/test/$id.als',
      fileName: '$id.als',
      fileSizeBytes: 512,
      lastModifiedAt: DateTime(2025, 3, 1),
      fileExtension: '.als',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
  }

  static ProjectTemplate makeProjectTemplate({
    String id = 'template-1',
    String name = 'Song Template',
    String sourceFolderPath = '/Users/artist/Templates/Song Template',
    String mainFileRelativePath = 'Song Template.als',
    DateTime? createdAt,
    DateTime? updatedAt,
    double? bpm,
    String? musicalKey,
    String? dawVersion,
    String? notes,
    String? projectNotes,
  }) {
    return ProjectTemplate(
      id: id,
      name: name,
      sourceFolderPath: sourceFolderPath,
      mainFileRelativePath: mainFileRelativePath,
      createdAt: createdAt ?? DateTime(2025, 1, 1),
      updatedAt: updatedAt ?? DateTime(2025, 1, 2),
      bpm: bpm,
      musicalKey: musicalKey,
      dawVersion: dawVersion,
      notes: notes,
      projectNotes: projectNotes,
    );
  }
}
