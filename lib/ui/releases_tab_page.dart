import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../models/release.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import 'release_detail_page.dart';
import 'dialogs/add_to_release_dialog.dart';

class ReleasesTabPage extends ConsumerStatefulWidget {
  const ReleasesTabPage({super.key});

  @override
  ConsumerState<ReleasesTabPage> createState() => _ReleasesTabPageState();
}

class _ReleasesTabPageState extends ConsumerState<ReleasesTabPage> {
  final DateFormat _dateFormat = DateFormat.yMMMd();

  Future<void> _createNewRelease() async {
    final projects = ref.read(projectsProvider);
    
    if (projects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No projects available. Please add projects first.')),
        );
      }
      return;
    }

    // Show dialog to select tracks
    final selectedProjectIds = await showDialog<List<String>>(
      context: context,
      builder: (context) => _TrackSelectionDialog(projects: projects),
    );

    if (selectedProjectIds == null || selectedProjectIds.isEmpty) {
      return;
    }

    // Get selected projects to determine release title
    final allProjectsAsync = ref.read(allProjectsStreamProvider);
    final allProjects = allProjectsAsync.value ?? [];
    final selectedProjects = allProjects.where((p) => selectedProjectIds.contains(p.id)).toList();

    String releaseTitle;
    bool shouldNavigateToRelease = false;

    // If single project, use project name; otherwise create with empty title
    if (selectedProjects.length == 1) {
      releaseTitle = selectedProjects.first.displayName;
    } else {
      releaseTitle = ''; // Empty title, user will fill it in the release page
      shouldNavigateToRelease = true;
    }

    final repo = await ref.read(repositoryProvider.future);
    final newRelease = Release(
      id: const Uuid().v4(),
      title: releaseTitle,
      trackIds: selectedProjectIds,
      releaseDate: DateTime.now(),
    );
    await repo.addRelease(newRelease);

    if (mounted) {
      if (shouldNavigateToRelease) {
        // Navigate to release page so user can fill in the title
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReleaseDetailPage(releaseId: newRelease.id),
          ),
        );
        // Refresh releases data when returning
        if (mounted) {
          ref.invalidate(releasesProvider);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Release "${releaseTitle}" created successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final releasesAsync = ref.watch(releasesProvider);
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);
    // Use allProjects to include preserved projects, not just filtered projectsProvider
    final projects = allProjectsAsync.value ?? [];

    return releasesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading releases: $error'),
          ],
        ),
      ),
      data: (releases) {
        if (releases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.album_outlined, size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                const Text(
                  'No releases yet',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first release by selecting tracks from your projects',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createNewRelease,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Release'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with create button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Releases (${releases.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ElevatedButton.icon(
                    onPressed: _createNewRelease,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Release'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Releases table
            Expanded(
              child: _ReleasesTable(
                releases: releases,
                projects: projects,
                dateFormat: _dateFormat,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReleasesTable extends ConsumerStatefulWidget {
  final List<Release> releases;
  final List<MusicProject> projects;
  final DateFormat dateFormat;

  const _ReleasesTable({
    required this.releases,
    required this.projects,
    required this.dateFormat,
  });

  @override
  ConsumerState<_ReleasesTable> createState() => _ReleasesTableState();
}

class _ReleasesTableState extends ConsumerState<_ReleasesTable> {
  PlutoGridStateManager? stateManager;

  @override
  void didUpdateWidget(_ReleasesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the grid rows when releases change
    if (widget.releases != oldWidget.releases && stateManager != null) {
      final newRows = _mapReleasesToRows(widget.releases);
      stateManager!.removeAllRows();
      stateManager!.appendRows(newRows);
    }
  }

  List<PlutoRow> _mapReleasesToRows(List<Release> releases) {
    return releases.map((release) {
      final releaseProjects = widget.projects
          .where((p) => release.trackIds.contains(p.id))
          .toList();
      
      return PlutoRow(cells: {
        'artwork': PlutoCell(value: release.artworkImagePath),
        'title': PlutoCell(value: release.title),
        'tracks': PlutoCell(value: releaseProjects.length),
        'releaseDate': PlutoCell(
          value: release.releaseDate != null
              ? widget.dateFormat.format(release.releaseDate!)
              : '',
        ),
        'description': PlutoCell(value: release.description ?? ''),
        'actions': PlutoCell(value: ''),
        'data': PlutoCell(value: release),
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final columns = [
      PlutoColumn(
        title: 'Artwork',
        field: 'artwork',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 100,
        minWidth: 80,
        frozen: PlutoColumnFrozen.start,
        renderer: (ctx) {
          final imagePath = ctx.cell.value as String?;
          if (imagePath != null && File(imagePath).existsSync()) {
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 40, color: Colors.white38);
                },
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.album, size: 40, color: Colors.white38),
          );
        },
      ),
      PlutoColumn(
        title: 'Title',
        field: 'title',
        type: PlutoColumnType.text(),
        enableColumnDrag: true,
        enableContextMenu: false,
        enableEditingMode: false,
        width: 300,
        minWidth: 200,
        frozen: PlutoColumnFrozen.start,
      ),
      PlutoColumn(
        title: 'Tracks',
        field: 'tracks',
        type: PlutoColumnType.number(),
        enableEditingMode: false,
        width: 100,
        minWidth: 80,
      ),
      PlutoColumn(
        title: 'Release Date',
        field: 'releaseDate',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 180,
        minWidth: 150,
      ),
      PlutoColumn(
        title: 'Description',
        field: 'description',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 300,
        minWidth: 200,
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 200,
        minWidth: 180,
        renderer: (ctx) {
          final release = ctx.row.cells['data']!.value as Release;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReleaseDetailPage(releaseId: release.id),
                    ),
                  );
                  // Refresh releases data when returning from detail page
                  if (mounted) {
                    ref.invalidate(releasesProvider);
                  }
                },
                child: const Text('View'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF2B2D31),
                      title: const Text('Delete Release'),
                      content: Text('Are you sure you want to delete "${release.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    final repo = await ref.read(repositoryProvider.future);
                    await repo.deleteRelease(release.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Release "${release.title}" deleted.')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: const Text('Delete'),
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
    ];

    final initialRows = _mapReleasesToRows(widget.releases);

    return PlutoGrid(
      columns: columns,
      rows: initialRows,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        stateManager = event.stateManager;
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
          rowHeight: 70, // Taller rows to accommodate thumbnails
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
      createFooter: (stateManager) => const SizedBox.shrink(),
    );
  }
}

class _TrackSelectionDialog extends StatefulWidget {
  final List<MusicProject> projects;

  const _TrackSelectionDialog({required this.projects});

  @override
  State<_TrackSelectionDialog> createState() => _TrackSelectionDialogState();
}

class _TrackSelectionDialogState extends State<_TrackSelectionDialog> {
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MusicProject> get _filteredProjects {
    if (_searchQuery.isEmpty) {
      return widget.projects;
    }
    return widget.projects.where((project) {
      final name = project.displayName.toLowerCase();
      final dawType = (project.dawType ?? '').toLowerCase();
      return name.contains(_searchQuery) || dawType.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _filteredProjects;
    
    return AlertDialog(
      backgroundColor: const Color(0xFF2B2D31),
      title: const Text('Select Tracks'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            Text(
              'Select tracks to include in the release (${_selectedIds.length} selected)',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search tracks',
                hintText: 'Search by name or DAW type',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredProjects.isEmpty
                  ? const Center(
                      child: Text(
                        'No tracks found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        final isSelected = _selectedIds.contains(project.id);
                        return CheckboxListTile(
                          title: Text(project.displayName),
                          subtitle: Text(
                            '${project.dawType ?? 'Unknown'} • ${project.bpm?.toStringAsFixed(0) ?? '?'} BPM',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(project.id);
                              } else {
                                _selectedIds.remove(project.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedIds.toList()),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _CreateReleaseDialog extends StatefulWidget {
  @override
  State<_CreateReleaseDialog> createState() => _CreateReleaseDialogState();
}

class _CreateReleaseDialogState extends State<_CreateReleaseDialog> {
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
      title: const Text('Create Release'),
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

