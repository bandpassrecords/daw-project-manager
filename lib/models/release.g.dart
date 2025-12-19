// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReleaseAdapter extends TypeAdapter<Release> {
  @override
  final int typeId = 3;

  @override
  Release read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Release(
      id: fields[0] as String,
      title: fields[1] as String,
      releaseDate: fields[2] as DateTime?,
      artworkImagePath: fields[3] as String?,
      description: fields[4] as String?,
      trackIds: (fields[5] as List).cast<String>(),
      files: (fields[6] as List).cast<ReleaseFile>(),
      todos: fields.containsKey(7) && fields[7] != null 
          ? (fields[7] as List).cast<TodoItem>()
          : const [],
    );
  }

  @override
  void write(BinaryWriter writer, Release obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.releaseDate)
      ..writeByte(3)
      ..write(obj.artworkImagePath)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.trackIds)
      ..writeByte(6)
      ..write(obj.files)
      ..writeByte(7)
      ..write(obj.todos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReleaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
