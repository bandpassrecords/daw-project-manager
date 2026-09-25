import '../models/todo_item.dart';

/// [todos] with exactly the one whose id is [todoId] set to [completed].
///
/// Every other todo is returned untouched, including ones that share text or
/// due date — only the id decides. Returns the original list unchanged when no
/// todo matches, so a stale row that has already been deleted elsewhere cannot
/// cause a pointless write.
///
/// Callers must build this from a **freshly read** owner rather than one
/// captured when the widget was built. Completion rewrites the owner's whole
/// todo list, so two writes computed from the same stale snapshot will clobber
/// each other — the second silently undoing the first, or reviving a todo the
/// first had completed.
List<TodoItem> setTodoCompleted(
  List<TodoItem> todos,
  String todoId, {
  required bool completed,
}) {
  var changed = false;
  final next = [
    for (final todo in todos)
      if (todo.id == todoId)
        () {
          changed = todo.completed != completed;
          return todo.copyWith(completed: completed);
        }()
      else
        todo,
  ];
  return changed ? next : todos;
}

/// How many of [todos] are marked complete — used to assert that completing
/// one thing completed exactly one thing.
int completedTodoCount(Iterable<TodoItem> todos) =>
    todos.where((t) => t.completed).length;
