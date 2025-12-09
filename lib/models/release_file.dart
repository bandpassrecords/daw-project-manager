import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class ReleaseFile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fileName; // Original filename

  @HiveField(2)
  final String filePath; // Path to stored file

  @HiveField(3)
  final String fileType; // e.g., 'audio', 'video', 'image', 'document', etc.

  @HiveField(4)
  final int fileSizeBytes;

  @HiveField(5)
  final DateTime addedAt;

  @HiveField(6)
  final String? description; // Optional description/notes

  ReleaseFile({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSizeBytes,
    required this.addedAt,
    this.description,
  });

  ReleaseFile copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? fileType,
    int? fileSizeBytes,
    DateTime? addedAt,
    String? description,
  }) {
    return ReleaseFile(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      addedAt: addedAt ?? this.addedAt,
      description: description ?? this.description,
    );
  }
}

class ReleaseFileAdapter extends TypeAdapter<ReleaseFile> {
  @override
  final int typeId = 4;

  @override
  ReleaseFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReleaseFile(
      id: fields[0] as String,
      fileName: fields[1] as String,
      filePath: fields[2] as String,
      fileType: fields[3] as String,
      fileSizeBytes: fields[4] as int,
      addedAt: fields[5] as DateTime,
      description: fields.containsKey(6) ? fields[6] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, ReleaseFile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.fileType)
      ..writeByte(4)
      ..write(obj.fileSizeBytes)
      ..writeByte(5)
      ..write(obj.addedAt)
      ..writeByte(6)
      ..write(obj.description);
  }
}

