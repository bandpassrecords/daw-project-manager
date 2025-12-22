import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/todo_item.dart';
import '../../generated/l10n/app_localizations.dart';

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
  bool _doneSectionExpanded = false; // Track if "Done" section is expanded

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
        // When marking as completed, update createdAt to current time so it appears at top of done list
        // When uncompleting, keep the original createdAt
        if (!todo.completed) {
          // Marking as done - update createdAt to now so it sorts to top
          return todo.copyWith(
            completed: true,
            createdAt: DateTime.now(),
          );
        } else {
          // Unmarking - just toggle completed status
          return todo.copyWith(completed: false);
        }
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
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.editTodo),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.todoText,
            hintText: AppLocalizations.of(context)!.enterTodoText,
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
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.todoList,
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
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.addNewTodo,
                      hintText: AppLocalizations.of(context)!.enterTodoItem,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTodo,
                  tooltip: AppLocalizations.of(context)!.tooltipAddTodo,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Separate active and done todos
            Builder(
              builder: (context) {
                final activeTodos = widget.todos.where((t) => !t.completed).toList();
                // Sort done todos by createdAt descending (most recently completed first)
                final doneTodos = widget.todos
                    .where((t) => t.completed)
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                
                if (widget.todos.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.noTodosYet,
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ),
                  );
                }
                
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Active todos section
                      if (activeTodos.isNotEmpty)
                        ...activeTodos.map((todo) => _buildTodoItem(todo)),
                      
                      // Done todos section (collapsible)
                      if (doneTodos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ExpansionTile(
                          key: const PageStorageKey<String>('done_section'),
                          initiallyExpanded: _doneSectionExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _doneSectionExpanded = expanded;
                            });
                          },
                          title: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${AppLocalizations.of(context)!.done} (${doneTodos.length})',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            ...doneTodos.map((todo) => _buildTodoItem(todo)),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(TodoItem todo) {
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
              ? Theme.of(context).textTheme.bodySmall?.color
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: Theme.of(context).textTheme.bodyMedium?.color,
            onPressed: () => _editTodo(todo),
            tooltip: AppLocalizations.of(context)!.edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.shade300,
            onPressed: () => _deleteTodo(todo.id),
            tooltip: AppLocalizations.of(context)!.delete,
          ),
        ],
      ),
    );
  }
}

