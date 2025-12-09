import 'dart:io';

import 'package:pluto_grid/pluto_grid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; 
import 'package:window_manager/window_manager.dart'; 
import 'package:path/path.dart' as path; // 🚨 NOVO IMPORT

import '../services/scanner_service.dart';
import 'project_detail_page.dart';
import 'releases_tab_page.dart';
import 'release_detail_page.dart';

import '../models/music_project.dart';
import '../models/release.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import 'package:uuid/uuid.dart';

const String kAppVersion = '1.0.3';

// WIDGET CORRIGIDO: Botões de controle da janela usando window_manager
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  // Função auxiliar assíncrona para alternar entre maximizar e restaurar
  void _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      windowManager.restore();
    } else {
      windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Minimize
        IconButton(
          icon: const Icon(Icons.minimize, size: 18, color: Colors.white70),
          onPressed: () => windowManager.minimize(),
        ),
        // Maximize/Restore
        IconButton(
          icon: const Icon(Icons.crop_square_sharp, size: 18, color: Colors.white70),
          onPressed: _toggleMaximize, 
        ),
        // Close
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: Colors.white70),
          onPressed: () => windowManager.close(), 
          splashColor: Colors.transparent, 
          highlightColor: const Color(0xFFC42B1C), 
        ),
      ],
    );
  }
}


class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with SingleTickerProviderStateMixin {
  bool _scanning = false;
  late TabController _tabController;
  
  // 1. FocusNode para a barra de pesquisa
  final FocusNode _searchFocusNode = FocusNode();
  
  // FocusNode auxiliar para o RawKeyboardListener
  final FocusNode _globalRawKeyListenerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFocusNode.dispose(); 
    _globalRawKeyListenerFocusNode.dispose();
    super.dispose();
  }


  // MÉTODO FINAL: Inclui Ctrl+F e Ctrl+R
  void _handleRawKeyEvent(RawKeyEvent event) {
    // Escutar apenas o evento de tecla para baixo (RawKeyDownEvent)
    if (event is! RawKeyDownEvent) return;

    // Verificar se Ctrl (ou Cmd/Meta no macOS) está pressionado
    final bool isControlOrMetaPressed = event.isControlPressed || event.isMetaPressed;
    
    // 1. Lógica para Ctrl + F
    final bool isKeyF = event.logicalKey == LogicalKeyboardKey.keyF;
    if (isKeyF && isControlOrMetaPressed) {
      _searchFocusNode.requestFocus();
      return; // Consome o evento
    }

    // 2. Lógica para Ctrl + R
    final bool isKeyR = event.logicalKey == LogicalKeyboardKey.keyR;
    if (isKeyR && isControlOrMetaPressed) {
      // Chama a função de Rescan
      _scanAll(); 
      return; // Consome o evento
    }
  }


  Future<void> _scanAll() async {
    if (_scanning) return;
    final repo = await ref.read(repositoryProvider.future);
    setState(() => _scanning = true);
    try {
      final scanner = ScannerService();
      int foundCount = 0;
      await repo.clearMissingFiles();
      for (final root in repo.getRoots()) {
        await for (final entity in scanner.scanDirectory(root.path)) {
          await repo.upsertFromFileSystemEntity(entity);
          foundCount++;
        }
      }
      if (mounted) {
        final msg = foundCount == 0
            ? 'No projects found in selected roots.'
            : 'Scan complete: $foundCount project${foundCount == 1 ? '' : 's'} added/updated.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Set<String> _selectedProjectIds = {};


  Future<void> _createReleaseFromSelectedProjects(BuildContext context, WidgetRef ref, List<MusicProject> selectedProjects) async {
    if (selectedProjects.isEmpty) return;

    String? releaseTitle;
    
    // If single project, pre-fill title; otherwise show dialog
    if (selectedProjects.length == 1) {
      releaseTitle = selectedProjects.first.displayName;
    } else {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => _ReleaseTitleDialog(),
      );
      if (result == null || result.trim().isEmpty) return;
      releaseTitle = result.trim();
    }

    final selectedProjectIds = selectedProjects.map((p) => p.id).toList();
    await _createRelease(context, ref, selectedProjectIds, releaseTitle!);
    
    // Clear selection after creating release
    setState(() {
      _selectedProjectIds.clear();
    });
  }

  Future<void> _createRelease(BuildContext context, WidgetRef ref, List<String> selectedProjectIds, String releaseTitle) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final newRelease = Release(
        id: const Uuid().v4(),
        title: releaseTitle,
        trackIds: selectedProjectIds,
        releaseDate: DateTime.now(),
      );
      await repo.addRelease(newRelease);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Release "$releaseTitle" created successfully.')),
        );
        // Switch to releases tab and navigate to the new release
        _tabController.animateTo(1);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReleaseDetailPage(releaseId: newRelease.id),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create release: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = ref.watch(dateFormatProvider);
    final repoAsync = ref.watch(repositoryProvider);
    final roots = ref.watch(scanRootsProvider);
    final currentParams = ref.watch(queryParamsNotifierProvider);
    final projects = ref.watch(projectsProvider);
    final initialScanning = ref.watch(initialScanStateProvider);
    final isScanning = _scanning || initialScanning;

    // RawKeyboardListener no topo.
    return Stack(
      children: [
        RawKeyboardListener(
          focusNode: _globalRawKeyListenerFocusNode,
          autofocus: true, 
          onKey: _handleRawKeyEvent, 
          child: Scaffold(
        appBar: null, 
        body: Column(
          children: [
            // ----------------------------------------------------
            // LÓGICA DE WINDOW BAR: APENHAS MOSTRA A BARRA PERSONALIZADA SE NÃO ESTIVER EM DEBUG
            if (!kDebugMode) 
              GestureDetector(
                onPanStart: (_) => windowManager.startDragging(),
                // LÓGICA para alternar maximizar/restaurar no double tap
                onDoubleTap: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.restore();
                  } else {
                    windowManager.maximize();
                  }
                }, 
                child: Container(
                  color: const Color(0xFF2B2D31), // Cor de fundo da AppBar
                  height: 40, // Altura padrão para a barra
                  child: Row(
                    children: [
                      // Título da Aplicação com versão (como antes)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'DAW Project Manager v$kAppVersion',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                      const Spacer(), // Espaçador para empurrar os botões para a direita
                      // Botões de minimizar, maximizar e fechar
                      const WindowButtons(),
                    ],
                  ),
                ),
              ),
            // ----------------------------------------------------
            
            // CONTEÚDO DA BARRA DE AÇÕES E PESQUISA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ações de Root e Scan
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: isScanning
                                ? null
                                : () async {
                                      final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select a projects folder');
                                      if (path != null) {
                                        setState(() => _scanning = true);
                                        try {
                                          final repo = await ref.read(repositoryProvider.future);
                                          await repo.addRoot(path);
                                          await _scanAll();
                                        } finally {
                                          if (mounted) setState(() => _scanning = false);
                                        }
                                      }
                                    },
                            icon: isScanning
                                ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                : const Icon(Icons.create_new_folder_outlined),
                            label: const Text('Add Projects Folder'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: isScanning
                                ? null
                                : () async {
                                      await _scanAll();
                                    },
                            icon: isScanning
                                ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                : const Icon(Icons.refresh),
                            label: Text(isScanning ? 'Scanning…' : 'Rescan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Área de Pesquisa e Filtro
                  Flexible(
                    flex: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SizedBox(
                            width: 250,
                            child: TextField(
                              // Associar o FocusNode ao TextField
                              focusNode: _searchFocusNode, 
                              controller: TextEditingController(text: currentParams.searchText)
                                ..selection = TextSelection.fromPosition(TextPosition(offset: currentParams.searchText.length)),
                              decoration: const InputDecoration(
                                hintText: 'Search by name...',
                                isDense: true,
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (text) {
                                ref.read(queryParamsNotifierProvider.notifier).setSearchText(text);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Toggle sort',
                          onPressed: () {
                            ref.read(queryParamsNotifierProvider.notifier).toggleSortDesc();
                          },
                          icon: Icon(currentParams.sortDesc ? Icons.sort_by_alpha : Icons.sort),
                        ),
                        const SizedBox(width: 8),
                        // Exibe o contador de projetos
                        Flexible(
                          child: repoAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (repo) => Text(
                              'Roots: ${repo.getRoots().length}   Projects: ${projects.length}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Clear Library (projects & roots)',
                                  icon: const Icon(Icons.delete_forever),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: const Color(0xFF2B2D31),
                                        title: const Text('Clear Library'),
                                        content: const Text('This will remove all saved projects and source folders. Continue?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final repo = await ref.read(repositoryProvider.future);
                                      await repo.clearAllData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Library cleared.')));
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                // Versão também na barra de ações (à direita do ícone de lixeira)
                                const Text(
                                  'v$kAppVersion',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            if (roots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in roots)
                        Chip(
                          label: Text(r.path),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () async {
                            final repo = await ref.read(repositoryProvider.future);
                            await repo.removeRoot(r.id);
                          },
                          backgroundColor: const Color(0xFF2B2D31),
                          labelStyle: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ),
            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.library_music), text: 'Projects'),
                Tab(icon: Icon(Icons.album), text: 'Releases'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: const Color(0xFF5A6B7A),
            ),
            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PlutoProjectsTableWithSelection(
                    projects: projects,
                    dateFormat: dateFormat,
                    onCreateRelease: (selectedProjects) {
                      _createReleaseFromSelectedProjects(context, ref, selectedProjects);
                    },
                  ),
                  const ReleasesTabPage(),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
        // Loading overlay
        if (isScanning)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                color: Color(0xFF2B2D31),
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Scanning projects...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 

class _PlutoProjectsTableWithSelection extends ConsumerStatefulWidget {
  final List<MusicProject> projects;
  final DateFormat dateFormat;
  final Function(List<MusicProject>) onCreateRelease;

  const _PlutoProjectsTableWithSelection({
    required this.projects,
    required this.dateFormat,
    required this.onCreateRelease,
  });

  @override
  ConsumerState<_PlutoProjectsTableWithSelection> createState() => _PlutoProjectsTableWithSelectionState();
}

class _PlutoProjectsTableWithSelectionState extends ConsumerState<_PlutoProjectsTableWithSelection> {
  final Set<String> _selectedProjectIds = {};

  void _clearSelection() {
    setState(() {
      _selectedProjectIds.clear();
    });
  }

  void _toggleProjectSelection(String projectId) {
    setState(() {
      if (_selectedProjectIds.contains(projectId)) {
        _selectedProjectIds.remove(projectId);
      } else {
        _selectedProjectIds.add(projectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _PlutoProjectsTable(
            projects: widget.projects,
            dateFormat: widget.dateFormat,
            selectedIds: _selectedProjectIds,
            onToggleSelection: _toggleProjectSelection,
          ),
        ),
        // Selection action bar
        if (_selectedProjectIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF2B2D31),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedProjectIds.length} project${_selectedProjectIds.length == 1 ? '' : 's'} selected',
                  style: const TextStyle(color: Colors.white70),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _clearSelection,
                      child: const Text('Clear Selection'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.album),
                      label: const Text('Create Release'),
                      onPressed: () {
                        final selectedProjects = widget.projects
                            .where((p) => _selectedProjectIds.contains(p.id))
                            .toList();
                        widget.onCreateRelease(selectedProjects);
                        _clearSelection();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlutoProjectsTable extends ConsumerStatefulWidget {
  final List<MusicProject> projects;
  final DateFormat dateFormat;
  final Set<String> selectedIds;
  final Function(String) onToggleSelection;
  const _PlutoProjectsTable({
    required this.projects,
    required this.dateFormat,
    required this.selectedIds,
    required this.onToggleSelection,
  });

  @override
  ConsumerState<_PlutoProjectsTable> createState() => _PlutoProjectsTableState();
}

class _PlutoProjectsTableState extends ConsumerState<_PlutoProjectsTable> {
  PlutoGridStateManager? stateManager;
  
  Future<void> _writeBpmToFile(MusicProject project, double? bpm) async {
    try {
      final projectDir = File(project.filePath).parent;
      final bpmFile = File(path.join(projectDir.path, 'bpm.txt'));
      
      if (bpm != null) {
        await bpmFile.writeAsString(bpm.toStringAsFixed(2));
      } else {
        // Delete file if BPM is cleared
        if (await bpmFile.exists()) {
          await bpmFile.delete();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to write BPM file: $e')),
        );
      }
    }
  }
  
  Future<void> _writeKeyToFile(MusicProject project, String? key) async {
    try {
      final projectDir = File(project.filePath).parent;
      final keyFile = File(path.join(projectDir.path, 'key.txt'));
      
      if (key != null && key.isNotEmpty) {
        await keyFile.writeAsString(key);
      } else {
        // Delete file if key is cleared
        if (await keyFile.exists()) {
          await keyFile.delete();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to write key file: $e')),
        );
      }
    }
  } 

  List<PlutoRow> _mapProjectsToRows(List<MusicProject> projects) {
    return projects.map((p) {
      // Combine DAW type and version into a single string
      final dawDisplay = p.dawType != null
          ? (p.dawVersion != null && p.dawVersion!.isNotEmpty
              ? '${p.dawType} ${p.dawVersion}'
              : p.dawType!)
          : '';
      
      return PlutoRow(
        cells: {
          'checkbox': PlutoCell(value: ''), // Placeholder for checkbox column
          'name': PlutoCell(value: p.displayName),
          'status': PlutoCell(value: p.status),
          'dawType': PlutoCell(value: dawDisplay),
          'bpm': PlutoCell(value: p.bpm?.toString() ?? ''),
          'key': PlutoCell(value: p.musicalKey ?? ''),
          'lastModified': PlutoCell(value: widget.dateFormat.format(p.lastModifiedAt)),
          'launch': PlutoCell(value: ''),
          'data': PlutoCell(value: p),
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(_PlutoProjectsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.projects != widget.projects || oldWidget.selectedIds != widget.selectedIds) {
      if (stateManager != null) {
        final newRows = _mapProjectsToRows(widget.projects);
        stateManager!.removeRows(stateManager!.rows, notify: false);
        stateManager!.insertRows(0, newRows);
        // Force rebuild to update checkbox states
        stateManager!.notifyListeners();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = [
      PlutoColumn(
        title: '',
        field: 'checkbox',
        type: PlutoColumnType.text(),
        width: 50,
        minWidth: 50,
        frozen: PlutoColumnFrozen.start,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableFilterMenuItem: false,
        enableSorting: false,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) return const SizedBox.shrink();
          
          final isSelected = widget.selectedIds.contains(project.id);
          return Checkbox(
            value: isSelected,
            onChanged: (value) {
              widget.onToggleSelection(project.id);
            },
          );
        },
      ),
      PlutoColumn(
        title: 'Name',
        field: 'name',
        type: PlutoColumnType.text(),
        enableColumnDrag: true,
        enableContextMenu: false,
        width: 600,
        minWidth: 200,
        frozen: PlutoColumnFrozen.start,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 140,
        minWidth: 120,
      ),
      PlutoColumn(
        title: 'DAW',
        field: 'dawType',
        type: PlutoColumnType.text(),
        width: 140,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'BPM',
        field: 'bpm',
        type: PlutoColumnType.text(),
        width: 100,
        minWidth: 80,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Key',
        field: 'key',
        type: PlutoColumnType.text(),
        width: 120,
        minWidth: 100,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Last Modified',
        field: 'lastModified',
        type: PlutoColumnType.text(),
        width: 200,
        minWidth: 160,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'launch',
        type: PlutoColumnType.text(),
        width: 360, // 🚨 LARGURA AUMENTADA para caber 3 botões
        minWidth: 260,
        renderer: (ctx) {
          final project = ctx.row.cells['data']!.value as MusicProject;
          
          // Lógica para determinar o diretório pai
          final String projectPath = project.filePath;
          final String folderPath = FileSystemEntity.isDirectorySync(projectPath)
              ? projectPath // Se for um diretório, usa o próprio caminho
              : path.dirname(projectPath); // Se for um arquivo, usa o diretório pai
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🚨 NOVO BOTÃO: OPEN FOLDER
              ElevatedButton(
                onPressed: () async {
                  final exists = Directory(folderPath).existsSync();
                  if (!exists) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder missing.')));
                    }
                    return;
                  }
                  
                  try {
                    // Lógica para abrir o diretório no explorador de arquivos nativo
                    if (Platform.isMacOS) {
                      await Process.start('open', [folderPath]);
                    } else if (Platform.isWindows) {
                      // Usar 'explorer' para Windows
                      await Process.start('explorer', [folderPath]);
                    } else if (Platform.isLinux) {
                      // Usar 'xdg-open' para a maioria dos ambientes Linux
                      await Process.start('xdg-open', [folderPath]);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OS not supported for opening folder.')));
                      }
                      return;
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening folder for ${project.displayName}…')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open folder: $e')));
                    }
                  }
                },
                child: const Text('Open Folder'),
              ),
              const SizedBox(width: 8),
              // BOTÃO: VIEW (Detalhes)
              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
                  );
                },
                child: const Text('View'),
              ),
              const SizedBox(width: 8), 
              // BOTÃO: LAUNCH (Abrir DAW)
              ElevatedButton(
                onPressed: () async {
                  final exists = File(project.filePath).existsSync() || Directory(project.filePath).existsSync();
                  if (!exists) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File missing.')));
                    }
                    return;
                  }
                  try {
                    // Lançamento específico para Windows e macOS
                    if (Platform.isMacOS) {
                      await Process.start('open', [project.filePath]);
                    } else if (Platform.isWindows) {
                      await Process.start('cmd', ['/c', 'start', '', project.filePath]);
                    } else {
                      // Fallback para outros sistemas operacionais (e.g. Linux)
                      await Process.start(project.filePath, []);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Launching ${project.displayName}…')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to launch: $e')));
                    }
                    return;
                  }
                },
                child: const Text('Launch'),
              ),
            ],
          );
        },
      ),
      // Hidden backing column for passing the model instance
      PlutoColumn(
        title: 'data',
        field: 'data',
        type: PlutoColumnType.text(),
        width: 0,
        hide: true,
      ),
    ]; // <-- Semicolon final do array de colunas

    final initialRows = _mapProjectsToRows(widget.projects);

    return PlutoGrid(
      columns: columns,
      rows: initialRows, 
      onLoaded: (PlutoGridOnLoadedEvent event) {
        stateManager = event.stateManager;
      },
      onChanged: (PlutoGridOnChangedEvent event) async {
        final project = event.row.cells['data']?.value as MusicProject?;
        if (project == null) return;
        
        final field = event.column.field;
        final newValue = event.value?.toString().trim() ?? '';
        
        if (field == 'bpm') {
          final bpm = newValue.isEmpty ? null : double.tryParse(newValue);
          
          // Write to bpm.txt file
          await _writeBpmToFile(project, bpm);
          
          // Update project in repository
          final repo = await ref.read(repositoryProvider.future);
          final updated = project.copyWith(bpm: bpm);
          await repo.updateProject(updated);
        } else if (field == 'key') {
          final key = newValue.isEmpty ? null : newValue;
          
          // Write to key.txt file
          await _writeKeyToFile(project, key);
          
          // Update project in repository
          final repo = await ref.read(repositoryProvider.future);
          final updated = project.copyWith(musicalKey: key);
          await repo.updateProject(updated);
        }
      },
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          gridBackgroundColor: const Color(0xFF1E1F22),
          gridBorderColor: const Color(0xFF3C3F43),
          gridBorderRadius: BorderRadius.zero,
          rowColor: const Color(0xFF2B2D31),
          cellColorInEditState: const Color(0xFF2F3136),
          cellColorInReadOnlyState: const Color(0xFF2B2D31),
          columnTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          cellTextStyle: const TextStyle(color: Colors.white),
          columnHeight: 44,
          rowHeight: 48,
          activatedBorderColor: const Color(0xFF5A6B7A),
          activatedColor: const Color(0xFF263238),
          iconColor: Colors.white70,
          menuBackgroundColor: const Color(0xFF2B2D31),
          evenRowColor: const Color(0xFF27292D),
        ),
        columnSize: const PlutoGridColumnSizeConfig(
          autoSizeMode: PlutoAutoSizeMode.scale,
          resizeMode: PlutoResizeMode.normal,
        ),
      ),
      onRowChecked: null,
      onSelected: null,
      onRowDoubleTap: (PlutoGridOnRowDoubleTapEvent event) async {
        final project = event.row.cells['data']?.value as MusicProject?;
        if (project == null) return;
        
        // Check if file exists
        final exists = File(project.filePath).existsSync() || Directory(project.filePath).existsSync();
        if (!exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File missing.')));
          }
          return;
        }
        
        try {
          // Launch project based on platform
          if (Platform.isMacOS) {
            await Process.start('open', [project.filePath]);
          } else if (Platform.isWindows) {
            await Process.start('cmd', ['/c', 'start', '', project.filePath]);
          } else {
            // Fallback for other operating systems (e.g., Linux)
            await Process.start(project.filePath, []);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Launching ${project.displayName}…')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to launch: $e')));
          }
        }
      },
      createFooter: (stateManager) => const SizedBox.shrink(),
    );
  }
}

class _ReleaseTitleDialog extends StatefulWidget {
  @override
  State<_ReleaseTitleDialog> createState() => _ReleaseTitleDialogState();
}

class _ReleaseTitleDialogState extends State<_ReleaseTitleDialog> {
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2B2D31),
      title: const Text('Enter Release Title'),
      content: TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Release Title',
          hintText: 'Enter release title',
        ),
        autofocus: true,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.pop(context, value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _titleController.text.trim()),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
