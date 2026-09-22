import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/todo_item.dart';

/// Replays a recorded Hive field stream. Lets a test hand the adapter a
/// record written by an *older* build of the app, which is the only way to
/// prove the backwards-compatible default without shipping a fixture box.
class _FakeReader implements BinaryReader {
  _FakeReader(this._values);

  final List<dynamic> _values;
  int _cursor = 0;

  @override
  int readByte() => _values[_cursor++] as int;

  @override
  dynamic read([int? typeId]) => _values[_cursor++];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not needed in tests');
}

/// Records what an adapter writes, in the order it writes it.
class _FakeWriter implements BinaryWriter {
  final values = <dynamic>[];

  @override
  void writeByte(int byte) => values.add(byte);

  @override
  void write<T>(T value, {bool withTypeId = true}) => values.add(value);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not needed in tests');
}

void main() {
  final adapter = TodoItemAdapter();

  group('TodoItem.dueAt (#113)', () {
    test('a record written before due dates existed reads back with none', () {
      // Exactly what the pre-#113 adapter wrote: four fields, no field 4.
      final legacyRecord = <dynamic>[
        4,
        0, 'todo-1',
        1, 'Mix the kick drum',
        2, false,
        3, DateTime(2025, 1, 10),
      ];

      final todo = adapter.read(_FakeReader(legacyRecord));

      expect(todo.id, 'todo-1');
      expect(todo.text, 'Mix the kick drum');
      expect(todo.completed, isFalse);
      expect(todo.createdAt, DateTime(2025, 1, 10));
      expect(todo.dueAt, isNull);
    });

    test('round-trips a due date through the adapter', () {
      final original = TodoItem(
        id: 'todo-2',
        text: 'Vocals',
        createdAt: DateTime(2025, 1, 10),
        dueAt: DateTime(2025, 2, 14),
      );

      final writer = _FakeWriter();
      adapter.write(writer, original);
      // Field count byte, then the id/value pairs — skip the count when
      // replaying, the reader consumes it first anyway.
      final restored = adapter.read(_FakeReader(writer.values));

      expect(restored.dueAt, DateTime(2025, 2, 14));
      expect(restored.id, 'todo-2');
      expect(restored.text, 'Vocals');
      expect(restored.createdAt, DateTime(2025, 1, 10));
    });

    test('round-trips a todo that has no due date', () {
      final original = TodoItem(
        id: 'todo-3',
        text: 'Master',
        createdAt: DateTime(2025, 1, 10),
      );

      final writer = _FakeWriter();
      adapter.write(writer, original);

      expect(adapter.read(_FakeReader(writer.values)).dueAt, isNull);
    });
  });

  group('TodoItem.copyWith', () {
    final todo = TodoItem(
      id: 'todo-1',
      text: 'Mix',
      createdAt: DateTime(2025, 1, 10),
      dueAt: DateTime(2025, 2, 14),
    );

    test('carries the due date through an unrelated change', () {
      expect(todo.copyWith(completed: true).dueAt, DateTime(2025, 2, 14));
    });

    test('replaces the due date', () {
      expect(
        todo.copyWith(dueAt: DateTime(2025, 3, 1)).dueAt,
        DateTime(2025, 3, 1),
      );
    });

    test('clearDueAt removes it — a null dueAt alone cannot', () {
      // The usual copyWith null-means-unchanged trap: without the explicit
      // flag, "remove this due date" would silently keep the old one.
      expect(todo.copyWith(dueAt: null).dueAt, DateTime(2025, 2, 14));
      expect(todo.copyWith(clearDueAt: true).dueAt, isNull);
    });
  });
}
