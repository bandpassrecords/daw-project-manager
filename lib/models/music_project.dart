import 'package:hive/hive.dart';
import 'todo_item.dart';

@HiveType(typeId: 1)
class MusicProject {
  @HiveField(0)
  final String id; // UUID primary key

  @HiveField(1)
  final String filePath; // absolute path

  @HiveField(2)
  final String fileName; // derived from path at scan time

  @HiveField(3)
  final int fileSizeBytes;

  @HiveField(4)
  final DateTime lastModifiedAt;

  @HiveField(5)
  final String? customDisplayName;

  @HiveField(6)
  final String? thumbnailPath;

  @HiveField(7)
  final String status; // Default: Idea (was 'Draft' in older versions)

  @HiveField(8)
  final String fileExtension; // e.g., .als, .cpr, .flp, .logicx

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  // Optional musical metadata
  @HiveField(11)
  final double? bpm; // Beats per minute, user editable

  @HiveField(12)
  final String? musicalKey; // e.g., C#m, F major, user editable

  // NOVO CAMPO
  @HiveField(13)
  final String? notes; // Notes about the project, user editable

  @HiveField(14)
  final String? dawType; // DAW type: Ableton, Cubase, FL Studio, Logic Pro, etc.

  @HiveField(15)
  final String? dawVersion; // DAW version (major version number)

  @HiveField(16)
  final List<TodoItem> todos; // TODO list for the track

  @HiveField(17)
  final bool hidden; // Whether the project is hidden from the list

  const MusicProject({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.lastModifiedAt,
    required this.fileExtension,
    required this.createdAt,
    required this.updatedAt,
    this.customDisplayName,
    this.thumbnailPath,
    this.status = 'Idea',
    this.bpm,
    this.musicalKey,
    this.notes, // NOVO CAMPO NO CONSTRUTOR
    this.dawType,
    this.dawVersion,
    this.todos = const [],
    this.hidden = false,
  });

  String get displayName => (customDisplayName != null && customDisplayName!.trim().isNotEmpty)
      ? customDisplayName!.trim()
      : fileName;

  MusicProject copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? fileSizeBytes,
    DateTime? lastModifiedAt,
    String? customDisplayName,
    String? thumbnailPath,
    String? status,
    String? fileExtension,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? bpm,
    String? musicalKey,
    String? notes, // NOVO CAMPO NO COPYWITH
    String? dawType,
    String? dawVersion,
    List<TodoItem>? todos,
    bool? hidden,
  }) {
    return MusicProject(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      customDisplayName: customDisplayName ?? this.customDisplayName,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      status: status ?? this.status,
      fileExtension: fileExtension ?? this.fileExtension,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bpm: bpm ?? this.bpm,
      musicalKey: musicalKey ?? this.musicalKey,
      notes: notes ?? this.notes, // NOVO CAMPO
      dawType: dawType ?? this.dawType,
      dawVersion: dawVersion ?? this.dawVersion,
      todos: todos ?? this.todos,
      hidden: hidden ?? this.hidden,
    );
  }
}

class MusicProjectAdapter extends TypeAdapter<MusicProject> {
  @override
  final int typeId = 1;

  @override
  MusicProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return MusicProject(
      id: fields[0] as String,
      filePath: fields[1] as String,
      fileName: fields[2] as String,
      fileSizeBytes: fields[3] as int,
      lastModifiedAt: fields[4] as DateTime,
      customDisplayName: fields[5] as String?,
      thumbnailPath: fields[6] as String?,
      // Migrate old "Draft" status to "Idea" for backward compatibility
      status: (fields[7] as String) == 'Draft' ? 'Idea' : (fields[7] as String),
      fileExtension: fields[8] as String,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      bpm: fields[11] as double?,
      musicalKey: fields[12] as String?,
      notes: fields.containsKey(13) ? fields[13] as String? : null, // NOVO CAMPO
      dawType: fields.containsKey(14) ? fields[14] as String? : null,
      dawVersion: fields.containsKey(15) ? fields[15] as String? : null,
      todos: fields.containsKey(16) && fields[16] != null 
          ? (fields[16] as List).cast<TodoItem>()
          : const [],
      hidden: fields.containsKey(17) ? (fields[17] as bool) : false,
    );
  }

  @override
  void write(BinaryWriter writer, MusicProject obj) {
    writer
      ..writeByte(18) // Agora são 18 campos (0-17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.fileSizeBytes)
      ..writeByte(4)
      ..write(obj.lastModifiedAt)
      ..writeByte(5)
      ..write(obj.customDisplayName)
      ..writeByte(6)
      ..write(obj.thumbnailPath)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.fileExtension)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.bpm)
      ..writeByte(12)
      ..write(obj.musicalKey)
      ..writeByte(13) // NOVO CAMPO
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.dawType)
      ..writeByte(15)
      ..write(obj.dawVersion)
      ..writeByte(16)
      ..write(obj.todos)
      ..writeByte(17)
      ..write(obj.hidden);
  }
}
