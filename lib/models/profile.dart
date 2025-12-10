import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class Profile {
  @HiveField(0)
  final String id; // UUID

  @HiveField(1)
  final String name; // Display name (e.g., "Artist Name 1")

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime? lastUsedAt;

  const Profile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastUsedAt,
  });

  Profile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 5;

  @override
  Profile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Profile(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      lastUsedAt: fields.containsKey(3) ? fields[3] as DateTime? : null,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.lastUsedAt);
  }
}

