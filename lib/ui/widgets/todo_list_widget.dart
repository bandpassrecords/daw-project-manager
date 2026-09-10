import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/todo_item.dart';
import '../../models/todo_template.dart';
import '../../providers/providers.dart';
import '../../utils/todo_due_utils.dart';
import '../../generated/l10n/app_localizations.dart';
import '../todo_templates_page.dart';
import 'todo_due_chip.dart';

class TodoListWidget extends ConsumerStatefulWidget {
  final List<TodoItem> todos;
  final Function(List<TodoItem>) onTodosChanged;
  /// Optional callback fired when a todo is completed (false → true).
  final Future<void> Function(TodoItem)? onTodoCompleted;

  const TodoListWidget({
    super.key,
    required this.todos,
    required this.onTodosChanged,
    this.onTodoCompleted,
  });

  @override
  ConsumerState<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends ConsumerState<TodoListWidget> {
  final _textController = TextEditingController();
  final _uuid = const Uuid();
  bool _doneSectionExpanded = false; // Track if "Done" section is expanded
  late List<TodoItem> _currentTodos; // Track current todos to detect changes

  @override
  void initState() {
    super.initState();
    _currentTodos = widget.todos;
  }

  @override
  void didUpdateWidget(TodoListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when todos prop changes (e.g., after sync)
    // Always update if the lists are different (by reference or content)
    if (widget.todos != _currentTodos) {
      final hasChanges = widget.todos.length != _currentTodos.length ||
          !_todosEqual(widget.todos, _currentTodos);
      
      if (hasChanges) {
        setState(() {
          _currentTodos = List.from(widget.todos); // Create a new list to ensure reference change
        });
      }
    }
  }

  bool _todosEqual(List<TodoItem> a, List<TodoItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].text != b[i].text ||
          a[i].completed != b[i].completed ||
          a[i].dueAt != b[i].dueAt) {
        return false;
      }
    }
    return true;
  }

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

    widget.onTodosChanged([..._currentTodos, newTodo]);
    _textController.clear();
  }

  Future<void> _importFromTemplate() async {
    final templatesAsync = ref.read(todoTemplatesProvider);
    final templates = templatesAsync.value ?? [];

    if (templates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noTemplatesAvailable),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.create,
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TodoTemplatesPage(),
                  ),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    final selected = await showDialog<TodoTemplate>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.selectTemplate),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                leading: const Icon(Icons.note),
                title: Text(template.name),
                subtitle: Text(
                  AppLocalizations.of(context)!.templateItemCount(template.items.length),
                ),
                onTap: () => Navigator.pop(dialogContext, template),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    if (selected != null) {
      // Create todos from template
      final newTodos = selected.items.map((item) => TodoItem(
        id: _uuid.v4(),
        text: item,
        completed: false,
        createdAt: DateTime.now(),
      )).toList();

      // Add to existing todos
      widget.onTodosChanged([..._currentTodos, ...newTodos]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.templateImported(selected.name, newTodos.length),
            ),
          ),
        );
      }
    }
  }

  Future<void> _importTodosFromFile() async {
    try {
      // Pick a text file
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        dialogTitle: AppLocalizations.of(context)!.importTodos,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        
        // Split by lines and create todos
        final lines = contents.split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

        if (lines.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.noTodosInFile),
              ),
            );
          }
          return;
        }

        // Create new todos from lines
        final newTodos = lines.map((line) => TodoItem(
          id: _uuid.v4(),
          text: line,
          completed: false,
          createdAt: DateTime.now(),
        )).toList();

        // Add to existing todos
        widget.onTodosChanged([..._currentTodos, ...newTodos]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.todosImported(newTodos.length),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorImportingTodos(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleTodo(String id) {
    TodoItem? completedTodo;
    final updatedTodos = _currentTodos.map((todo) {
      if (todo.id == id) {
        if (!todo.completed) {
          // Marking as done — update createdAt to now so it sorts to top
          final updated = todo.copyWith(
            completed: true,
            createdAt: DateTime.now(),
          );
          completedTodo = updated;
          return updated;
        } else {
          return todo.copyWith(completed: false);
        }
      }
      return todo;
    }).toList();

    widget.onTodosChanged(updatedTodos);

    // Fire optional completion callback (fire-and-forget)
    if (completedTodo != null) {
      widget.onTodoCompleted?.call(completedTodo!);
    }
  }

  void _setDueDate(TodoItem todo, DateTime dueAt) {
    widget.onTodosChanged(
      _currentTodos
          .map((t) => t.id == todo.id ? t.copyWith(dueAt: dueAt) : t)
          .toList(),
    );
  }

  void _clearDueDate(TodoItem todo) {
    widget.onTodosChanged(
      _currentTodos
          .map((t) => t.id == todo.id ? t.copyWith(clearDueAt: true) : t)
          .toList(),
    );
  }

  void _deleteTodo(String id) {
    final updatedTodos = _currentTodos.where((todo) => todo.id != id).toList();
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
              final updatedTodos = _currentTodos.map((t) {
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
                final updatedTodos = _currentTodos.map((t) {
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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.file_download),
                  iconSize: 20,
                  tooltip: AppLocalizations.of(context)!.importFromTemplate,
                  onPressed: _importFromTemplate,
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  iconSize: 20,
                  tooltip: AppLocalizations.of(context)!.importTodos,
                  onPressed: _importTodosFromFile,
                ),
                IconButton(
                  icon: const Icon(Icons.note_add),
                  iconSize: 20,
                  tooltip: AppLocalizations.of(context)!.manageTemplates,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TodoTemplatesPage(),
                      ),
                    );
                  },
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
                // Use _currentTodos instead of widget.todos to ensure we show the latest data.
                // Active todos are ordered by what is due next; undated ones
                // sit behind the dated ones, oldest first.
                final activeTodos =
                    sortTodosByDue(_currentTodos.where((t) => !t.completed));
                // Sort done todos by createdAt descending (most recently completed first)
                final doneTodos = _currentTodos
                    .where((t) => t.completed)
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                
                if (_currentTodos.isEmpty) {
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
    final l10n = AppLocalizations.of(context)!;

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
      subtitle: todo.dueAt == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TodoDueChip(dueAt: todo.dueAt!, muted: todo.completed),
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TodoDueButton(
            todo: todo,
            onDueDateChanged: (dueAt) =>
                dueAt == null ? _clearDueDate(todo) : _setDueDate(todo, dueAt),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: Theme.of(context).textTheme.bodyMedium?.color,
            onPressed: () => _editTodo(todo),
            tooltip: l10n.edit,
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

