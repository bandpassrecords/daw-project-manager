import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; // NOVO IMPORT
import 'package:path/path.dart' as p; // NOVO IMPORT

import '../models/music_project.dart';
import '../models/todo_item.dart';
import '../providers/providers.dart';
import 'dashboard_page.dart';
import 'widgets/todo_list_widget.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bpmCtrl;
  late TextEditingController _keyCtrl;
  late TextEditingController _notesCtrl; // NOVO CONTROLLER
  String? _selectedPhase;
  bool _hasInitializedPhase = false; // Track if we've initialized the phase
  
  static const List<String> _projectPhases = [
    'Idea',
    'Arranging',
    'Mixing',
    'Mastering',
    'Finished',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bpmCtrl = TextEditingController();
    _keyCtrl = TextEditingController();
    _notesCtrl = TextEditingController(); // INICIALIZA
    _selectedPhase = 'Idea'; // Initialize with default phase
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bpmCtrl.dispose();
    _keyCtrl.dispose();
    _notesCtrl.dispose(); // DISPOSE
    super.dispose();
  }

  // NOVO: Função para abrir o diretório pai
  Future<void> _openProjectFolder(String filePath) async {
    // Determina o caminho da pasta: Se for um arquivo, pega o diretório pai. Se for um diretório, pega ele mesmo.
    final folderPath = (FileSystemEntity.typeSync(filePath) == FileSystemEntityType.file) 
        ? p.dirname(filePath) 
        : filePath;

    final Uri uri = Uri.directory(folderPath);

    try {
        if (await launchUrl(uri)) {
          return;
        }
    } catch (_) {
      // Tenta métodos nativos como fallback se o launchUrl falhar
    }
    
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [folderPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [folderPath]); 
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open folder: $e')));
       }
    }
  }


  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(repositoryProvider);
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
      ),
      body: repoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (repo) {
          // Use projects from stream to get latest data, fallback to repo if stream not ready
          final allProjects = allProjectsAsync.value ?? repo.getAllProjects();
          final project = allProjects.firstWhere((p) => p.id == widget.projectId);

          // Sincroniza controllers com os dados do projeto
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentName = project.customDisplayName ?? project.fileName;
            if (_nameCtrl.text != currentName) {
               _nameCtrl.text = currentName;
            }
            if (_bpmCtrl.text != (project.bpm?.toString() ?? '')) {
              _bpmCtrl.text = project.bpm?.toString() ?? '';
            }
            if (_keyCtrl.text != (project.musicalKey ?? '')) {
              _keyCtrl.text = project.musicalKey ?? '';
            }
            // NOVO: Sincroniza Notas
            if (_notesCtrl.text != (project.notes ?? '')) {
              _notesCtrl.text = project.notes ?? '';
            }
            // Sincroniza fase do projeto (only on first load)
            if (!_hasInitializedPhase) {
              final projectStatus = project.status;
              // Use project status if it's valid, otherwise default to 'Idea'
              final validStatus = _projectPhases.contains(projectStatus) 
                  ? projectStatus 
                  : 'Idea';
              if (mounted) {
                setState(() {
                  _selectedPhase = validStatus;
                  _hasInitializedPhase = true;
                });
              }
            }
          });

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(project.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(project.filePath, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Text('Last modified: ${project.lastModifiedAt}'),
                  const SizedBox(height: 24),
                  
                  // Campo para editar o nome de exibição customizado
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Project Name'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bpmCtrl,
                          decoration: const InputDecoration(labelText: 'BPM'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _keyCtrl,
                          decoration: const InputDecoration(labelText: 'Key (e.g., C#m, F major)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await repo.extractFullMetadataForProject(project.id);
                            // Refresh the project data
                            ref.invalidate(allProjectsStreamProvider);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Metadata extracted successfully')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to extract metadata: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Extract'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A6B7A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Project Phase Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedPhase,
                    decoration: const InputDecoration(
                      labelText: 'Project Phase',
                    ),
                    items: _projectPhases.map((phase) {
                      return DropdownMenuItem<String>(
                        value: phase,
                        child: Text(phase),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPhase = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // NOVO: CAMPO DE NOTAS
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                  ),

                  const SizedBox(height: 24),
                  // TODO List
                  TodoListWidget(
                    todos: project.todos,
                    onTodosChanged: (updatedTodos) async {
                      final updated = project.copyWith(todos: updatedTodos);
                      await repo.updateProject(updated);
                      // Invalidate the projects stream to refresh the UI
                      if (mounted) {
                        ref.invalidate(allProjectsStreamProvider);
                      }
                    },
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // BOTÃO: SAVE (LÓGICA ATUALIZADA)
                      ElevatedButton.icon(
                        onPressed: () async {
                          // O campo name atualiza customDisplayName. Se o texto for vazio ou igual ao nome do arquivo original, ele deve ser null.
                          final nameText = _nameCtrl.text.trim();
                          final newCustomDisplayName = (nameText.isEmpty || nameText == project.fileName) 
                              ? null 
                              : nameText;
                          
                          final notesText = _notesCtrl.text.trim();
                          final newNotes = notesText.isEmpty ? null : notesText;

                          final updated = project.copyWith(
                            customDisplayName: newCustomDisplayName,
                            bpm: _bpmCtrl.text.trim().isEmpty ? null : double.tryParse(_bpmCtrl.text.trim()),
                            musicalKey: _keyCtrl.text.trim().isEmpty ? null : _keyCtrl.text.trim(),
                            notes: newNotes, // NOVO: Salva Notas
                            status: _selectedPhase ?? 'Idea', // Save project phase
                          );

                          await repo.updateProject(updated);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                      const SizedBox(width: 12),
                      
                      // NOVO: BOTÃO OPEN FOLDER
                      ElevatedButton.icon(
                        onPressed: () => _openProjectFolder(project.filePath),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Open Folder'),
                      ),
                      const SizedBox(width: 12),

                      // BOTÃO OPEN IN DAW (Existente)
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            if (Platform.isMacOS) {
                              await Process.start('open', [project.filePath]);
                            } else if (Platform.isWindows) {
                              await Process.start('cmd', ['/c', 'start', '', project.filePath]);
                            } else {
                              await Process.start(project.filePath, []);
                            }
                          } catch (_) {
                             if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to launch DAW')));
                             }
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in DAW'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}