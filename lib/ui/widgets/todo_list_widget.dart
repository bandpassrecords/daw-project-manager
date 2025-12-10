import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/todo_item.dart';

class TodoListWidget extends StatefulWidget {
  final List<TodoItem> todos;
  final Function(List<TodoItem>) onTodosChanged;

  const TodoListWidget({
    super.key,
    required this.todos,
    required this.onTodosChanged,
  });

  @override
  State<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<TodoListWidget> {
  final _textController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addTodo() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final newTodo = TodoItem(
      id: _uuid.v4(),
      text: text,
      completed: false,
      createdAt: DateTime.now(),
    );

    widget.onTodosChanged([...widget.todos, newTodo]);
    _textController.clear();
  }

  void _toggleTodo(String id) {
    final updatedTodos = widget.todos.map((todo) {
      if (todo.id == id) {
        return todo.copyWith(completed: !todo.completed);
      }
      return todo;
    }).toList();

    widget.onTodosChanged(updatedTodos);
  }

  void _deleteTodo(String id) {
    final updatedTodos = widget.todos.where((todo) => todo.id != id).toList();
    widget.onTodosChanged(updatedTodos);
  }

  void _editTodo(TodoItem todo) {
    final editController = TextEditingController(text: todo.text);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D31),
        title: const Text('Edit Todo'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Todo text',
            hintText: 'Enter todo text',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              final updatedTodos = widget.todos.map((t) {
                if (t.id == todo.id) {
                  return t.copyWith(text: value.trim());
                }
                return t;
              }).toList();
              widget.onTodosChanged(updatedTodos);
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = editController.text.trim();
              if (text.isNotEmpty) {
                final updatedTodos = widget.todos.map((t) {
                  if (t.id == todo.id) {
                    return t.copyWith(text: text);
                  }
                  return t;
                }).toList();
                widget.onTodosChanged(updatedTodos);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2B2D31),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'TODO List',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Add new todo
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Add new todo',
                      hintText: 'Enter todo item',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTodo,
                  tooltip: 'Add todo',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Todo list
            if (widget.todos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No todos yet. Add one above.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.todos.length,
                  itemBuilder: (context, index) {
                    final todo = widget.todos[index];
                    return ListTile(
                      dense: true,
                      leading: Checkbox(
                        value: todo.completed,
                        onChanged: (_) => _toggleTodo(todo.id),
                      ),
                      title: Text(
                        todo.text,
                        style: TextStyle(
                          decoration: todo.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: todo.completed
                              ? Colors.white54
                              : Colors.white70,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: Colors.white70,
                            onPressed: () => _editTodo(todo),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: Colors.red.shade300,
                            onPressed: () => _deleteTodo(todo.id),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

