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

  @HiveField(4)
  final String? photoPath; // Path to profile photo/thumbnail

  @HiveField(5)
  final String? bio; // Profile biography/description

  @HiveField(6)
  final String? artworkPath; // Path to profile artwork/image

  @HiveField(7)
  final String? pressKitPath; // Path to press kit file

  @HiveField(8)
  final Map<String, String>? additionalAssets; // Map of asset name to file path

  const Profile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastUsedAt,
    this.photoPath,
    this.bio,
    this.artworkPath,
    this.pressKitPath,
    this.additionalAssets,
  });

  Profile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    String? photoPath,
    bool clearPhotoPath = false,
    String? bio,
    bool clearBio = false,
    String? artworkPath,
    bool clearArtworkPath = false,
    String? pressKitPath,
    bool clearPressKitPath = false,
    Map<String, String>? additionalAssets,
    bool clearAdditionalAssets = false,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      bio: clearBio ? null : (bio ?? this.bio),
      artworkPath: clearArtworkPath ? null : (artworkPath ?? this.artworkPath),
      pressKitPath: clearPressKitPath ? null : (pressKitPath ?? this.pressKitPath),
      additionalAssets: clearAdditionalAssets ? null : (additionalAssets ?? this.additionalAssets),
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
      photoPath: fields.containsKey(4) ? fields[4] as String? : null,
      bio: fields.containsKey(5) ? fields[5] as String? : null,
      artworkPath: fields.containsKey(6) ? fields[6] as String? : null,
      pressKitPath: fields.containsKey(7) ? fields[7] as String? : null,
      additionalAssets: fields.containsKey(8) ? Map<String, String>.from(fields[8] as Map) : null,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.lastUsedAt)
      ..writeByte(4)
      ..write(obj.photoPath)
      ..writeByte(5)
      ..write(obj.bio)
      ..writeByte(6)
      ..write(obj.artworkPath)
      ..writeByte(7)
      ..write(obj.pressKitPath)
      ..writeByte(8)
      ..write(obj.additionalAssets);
  }
}
