// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectTemplateAdapter extends TypeAdapter<ProjectTemplate> {
  @override
  final typeId = 12;

  @override
  ProjectTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      sourceFolderPath: fields[2] as String,
      mainFileRelativePath: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      bpm: (fields[6] as num?)?.toDouble(),
      musicalKey: fields[7] as String?,
      dawVersion: fields[8] as String?,
      notes: fields[9] as String?,
      projectNotes: fields[10] as String?,
      hidden: fields[11] == null ? false : fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectTemplate obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sourceFolderPath)
      ..writeByte(3)
      ..write(obj.mainFileRelativePath)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.bpm)
      ..writeByte(7)
      ..write(obj.musicalKey)
      ..writeByte(8)
      ..write(obj.dawVersion)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.projectNotes)
      ..writeByte(11)
      ..write(obj.hidden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
