import 'package:hive/hive.dart';

@HiveType(typeId: 6)
class TodoItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final bool completed;

  @HiveField(3)
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.text,
    this.completed = false,
    required this.createdAt,
  });

  TodoItem copyWith({
    String? id,
    String? text,
    bool? completed,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TodoItemAdapter extends TypeAdapter<TodoItem> {
  @override
  final int typeId = 6;

  @override
  TodoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return TodoItem(
      id: fields[0] as String,
      text: fields[1] as String,
      completed: fields.containsKey(2) ? fields[2] as bool : false,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TodoItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.completed)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}

