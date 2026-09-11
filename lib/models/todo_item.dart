import 'package:hive_ce/hive.dart';

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

  /// Optional per-todo due date, independent of the parent project's single
  /// `deadline` (the release/delivery date). A project is usually "vocals by
  /// Friday, mix by the 12th, master by the 20th" — one project-level date
  /// can't express that.
  @HiveField(4)
  final DateTime? dueAt;

  const TodoItem({
    required this.id,
    required this.text,
    this.completed = false,
    required this.createdAt,
    this.dueAt,
  });

  TodoItem copyWith({
    String? id,
    String? text,
    bool? completed,
    DateTime? createdAt,
    DateTime? dueAt,
    bool clearDueAt = false,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
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
      // Records written before per-todo due dates (#113) carry no field 4.
      dueAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TodoItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.completed)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.dueAt);
  }
}
