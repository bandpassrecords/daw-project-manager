import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:trina_grid/trina_grid.dart';
import 'package:uuid/uuid.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart' show camelotCodeForKey;
import '../models/project_template.dart';
import '../models/template_root.dart';
import '../providers/providers.dart';
import '../providers/theme_provider.dart';
import '../services/metadata_extractor.dart';
import '../services/project_template_service.dart';
import '../services/scanner_service.dart';
import '../utils/app_paths.dart';
import '../utils/daw_logo.dart';
import '../utils/file_launcher.dart';
import '../utils/mobile_utils.dart';
import '../utils/trina_grid_locale.dart';
import 'row_click_selection.dart';
import 'widgets/trina_grid_menu_delegate.dart';
import 'dialogs/create_project_dialog.dart';
import 'dialogs/duplicate_template_dialog.dart';
import 'template_detail_page.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/filter_dropdown.dart';

/// Same comparator shape as the main dashboard table's
/// `compareLastModifiedCellValues` — cell values are raw `DateTime?`s (not
/// the formatted display string) so sorting is chronological. A missing
/// source file (no on-disk timestamp) sorts before everything with a date.
/// Public (rather than private) so it can be unit tested the same way.
int compareTemplateModifiedCellValues(dynamic a, dynamic b) {
  final dateA = a as DateTime?;
  final dateB = b as DateTime?;
  if (dateA == null && dateB == null) return 0;
  if (dateA == null) return -1;
  if (dateB == null) return 1;
  return dateA.compareTo(dateB);
}

class ProjectTemplatesPage extends ConsumerStatefulWidget {
  const ProjectTemplatesPage({super.key});

  @override
  ConsumerState<ProjectTemplatesPage> createState() =>
      _ProjectTemplatesPageState();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _SearchAction extends Action<_SearchIntent> {
  final VoidCallback onSearch;
  _SearchAction(this.onSearch);

  @override
  Object? invoke(_SearchIntent intent) {
    onSearch();
    return null;
  }
}

class _ProjectTemplatesPageState extends ConsumerState<ProjectTemplatesPage> {
  final _uuid = const Uuid();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  /// Ctrl/cmd- and shift-click selection for this table, shared with the
  /// projects grid (see `row_click_selection.dart`) so both tables behave
  /// identically.
  late final _clickSelection = RowClickSelectionController(
    notifier: () => ref.read(selectedTemplatesProvider.notifier),
    selectedIds: () => ref.read(selectedTemplatesProvider),
    orderedIds: () => _visibleTemplateIds,
  );

  /// The ids of the rows currently on screen, in display order — what a
  /// shift-click range and the header "select all" both work from. Refreshed
  /// every build, since search filtering changes it.
  List<String> _visibleTemplateIds = const [];

  TrinaGridStateManager? _tableStateManager;

  @override
  void initState() {
    super.initState();
    // templateSearchProvider (rather than local widget state) is the source
    // of truth, so the search text survives navigating away from and back
    // to this page — prime the controller from it, then keep it in sync.
    _searchController.text = ref.read(templateSearchProvider);
    _searchController.addListener(() {
      ref
          .read(templateSearchProvider.notifier)
          .setSearchText(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tableStateManager?.removeListener(_onTableStateManagerChanged);
    super.dispose();
  }

  void _onTableStateManagerChanged() {
    if (mounted) setState(() {});
  }

  /// Focuses the search box and selects its current text, same as the main
  /// dashboard's Ctrl+F/Cmd+F handling — a couple of post-frame retries so a
  /// focus request that lands in the same frame TrinaGrid tries to grab
  /// focus for itself doesn't silently lose out.
  void _focusSearchAndSelectAll() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus != _searchFocusNode) {
      primaryFocus.unfocus();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchFocusNode.canRequestFocus) {
        _searchFocusNode.requestFocus();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_searchFocusNode.hasFocus) {
          final thief = FocusManager.instance.primaryFocus;
          if (thief != null && thief != _searchFocusNode) {
            thief.unfocus();
          }
          if (_searchFocusNode.canRequestFocus) {
            _searchFocusNode.requestFocus();
          }
        }
        if (_searchController.text.isNotEmpty) {
          _searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchController.text.length,
          );
        }
      });
    });
  }

  Set<String> get _selectedTemplateIds => ref.watch(selectedTemplatesProvider);

  void _clearTemplateSelection() => _clickSelection.clear();

  Future<void> _deleteSelectedTemplates(List<ProjectTemplate> selected) async {
    final l10n = AppLocalizations.of(context)!;
    final plural = selected.length == 1 ? '' : 's';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSelectedTemplates),
        content: Text(
          l10n.deleteSelectedTemplatesConfirm(selected.length, plural),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final notifier = ref.read(projectTemplatesNotifierProvider.notifier);
    for (final template in selected) {
      await notifier.deleteTemplate(template.id);
    }
    _clearTemplateSelection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.templatesDeleted(selected.length, plural))),
      );
    }
  }

  Future<void> _pickMainFile() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ScannerService.supportedExtensions
          .map((e) => e.substring(1))
          .toList(),
      dialogTitle: l10n.selectTemplateMainFile,
    );
    if (!mounted || result == null || result.files.single.path == null) return;

    final mainFilePath = result.files.single.path!;
    final nameController = TextEditingController(
      text: p.basenameWithoutExtension(mainFilePath),
    );

    ProjectMetadata? metadata;
    try {
      metadata = await MetadataExtractor.extractMetadata(mainFilePath);
    } catch (_) {
      // Best-effort — registration still proceeds without bpm/key/version.
    }
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.registerTemplate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.templateName),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              mainFilePath,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final template = ProjectTemplate(
                id: _uuid.v4(),
                name: name,
                sourceFolderPath: p.dirname(mainFilePath),
                mainFileRelativePath: p.basename(mainFilePath),
                bpm: metadata?.bpm,
                musicalKey: metadata?.key,
                dawVersion: metadata?.dawVersion,
                projectNotes: metadata?.projectNotes,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              ref
                  .read(projectTemplatesNotifierProvider.notifier)
                  .addTemplate(template);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.templateCreated)));
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  /// Registers a new template root folder, then immediately runs a refresh
  /// so any qualifying subfolders it already contains get imported right
  /// away instead of waiting for the next manual refresh.
  Future<void> _addTemplateRoot() async {
    final l10n = AppLocalizations.of(context)!;
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.selectTemplatesParentFolder,
    );
    if (!mounted || path == null) return;

    await ref
        .read(templateRootsNotifierProvider.notifier)
        .addRoot(
          TemplateRoot(id: _uuid.v4(), path: path, addedAt: DateTime.now()),
        );
    await _refreshTemplateRoots();
  }

  /// Re-scans every registered [TemplateRoot] for subfolders that
  /// unambiguously look like templates (see
  /// [ProjectTemplateService.discoverTemplateCandidates]) and registers any
  /// that aren't already a template (compared by source folder path), so
  /// re-running this only adds what's new rather than duplicating existing
  /// templates. Reports how many were added in a snackbar.
  Future<void> _refreshTemplateRoots() async {
    final l10n = AppLocalizations.of(context)!;

    // Read straight from the Hive boxes rather than through the
    // StreamProvider — `box.watch()` events are delivered asynchronously, so
    // a provider read immediately after `addRoot()`/`addTemplate()` can race
    // ahead of the box's own watch event and observe a stale list. The boxes
    // themselves are always current the instant a `put`/`delete` completes.
    await ensureHiveInitialized();
    final rootsBox = await Hive.openBox<TemplateRoot>('templateRoots');
    final roots = rootsBox.values.toList();
    if (roots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noTemplateFoldersRegistered)),
        );
      }
      return;
    }

    final templatesBox = await Hive.openBox<ProjectTemplate>(
      'projectTemplates',
    );
    // Keyed by full main-file path, not just the folder — a single folder
    // can now yield multiple templates (see discoverTemplateCandidates), so
    // registering one must not shadow its siblings on the next refresh.
    final existingPaths = templatesBox.values
        .map((t) => p.join(t.sourceFolderPath, t.mainFileRelativePath))
        .toSet();

    if (kDebugMode) {
      print(
        '[ProjectTemplatesPage] Refreshing ${roots.length} root(s): '
        '${roots.map((r) => r.path).join(' | ')}',
      );
    }

    final allCandidates = <TemplateFolderCandidate>[];
    for (final root in roots) {
      // Each root is scanned independently and failures are swallowed inside
      // discoverTemplateCandidates itself, so one missing/inaccessible root
      // never prevents the remaining roots from being scanned.
      allCandidates.addAll(
        ProjectTemplateService.discoverTemplateCandidates(root.path),
      );
    }
    final newCandidates = ProjectTemplateService.filterNewCandidates(
      allCandidates,
      existingPaths,
    );

    if (kDebugMode) {
      final alreadyRegistered = allCandidates.length - newCandidates.length;
      print(
        '[ProjectTemplatesPage] ${allCandidates.length} candidate(s) found across all roots, '
        '$alreadyRegistered already registered, ${newCandidates.length} new',
      );
    }

    for (final candidate in newCandidates) {
      final mainFilePath = p.join(
        candidate.sourceFolderPath,
        candidate.mainFileRelativePath,
      );
      ProjectMetadata? metadata;
      try {
        metadata = await MetadataExtractor.extractMetadata(mainFilePath);
      } catch (_) {
        // Extraction is best-effort here — an unreadable/corrupt file
        // shouldn't stop the template from being registered.
      }
      final newTemplate = ProjectTemplate(
        id: _uuid.v4(),
        name: candidate.name,
        sourceFolderPath: candidate.sourceFolderPath,
        mainFileRelativePath: candidate.mainFileRelativePath,
        bpm: metadata?.bpm,
        musicalKey: metadata?.key,
        dawVersion: metadata?.dawVersion,
        projectNotes: metadata?.projectNotes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await templatesBox.put(newTemplate.id, newTemplate);
    }

    for (final root in roots) {
      await rootsBox.put(
        root.id,
        root.copyWith(lastRefreshedAt: DateTime.now()),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.templatesRefreshedSummary(newCandidates.length)),
        ),
      );
    }
  }

  Future<void> _removeTemplateRoot(TemplateRoot root) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeTemplateFolder),
        content: Text(l10n.removeTemplateFolderConfirm(root.path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(templateRootsNotifierProvider.notifier)
          .removeRoot(root.id);
    }
  }

  Future<void> _manageTemplateFolders() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.manageTemplateFolders),
        content: SizedBox(
          width: 480,
          child: Consumer(
            builder: (context, ref, child) {
              final rootsAsync = ref.watch(templateRootsProvider);
              return rootsAsync.when(
                data: (roots) {
                  if (roots.isEmpty) {
                    return Text(l10n.noTemplateFoldersRegistered);
                  }
                  return SizedBox(
                    height: 240,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: roots.length,
                      itemBuilder: (context, index) {
                        final root = roots[index];
                        return ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Tooltip(
                            message: root.path,
                            child: Text(
                              root.path,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          subtitle: root.lastRefreshedAt != null
                              ? Text(
                                  l10n.lastRefreshed(
                                    DateFormat(
                                      'yyyy-MM-dd HH:mm',
                                    ).format(root.lastRefreshedAt!),
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.folder_open_outlined),
                                tooltip: l10n.openFolder,
                                onPressed: () =>
                                    FileLauncher.openFolder(root.path),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: l10n.remove,
                                onPressed: () => _removeTemplateRoot(root),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text(l10n.errorLoadingTemplates),
              );
            },
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: Text(l10n.addTemplateFolder),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _addTemplateRoot();
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _viewTemplateDetails(ProjectTemplate template) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateDetailPage(templateId: template.id),
      ),
    );
  }

  Future<void> _deleteTemplate(ProjectTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteTemplate),
        content: Text(l10n.deleteTemplateConfirm(template.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref
          .read(projectTemplatesNotifierProvider.notifier)
          .deleteTemplate(template.id);
      if (ref.read(selectedTemplatesProvider).contains(template.id)) {
        ref.read(selectedTemplatesProvider.notifier).toggle(template.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.templateDeleted)));
      }
    }
  }

  void _useTemplate(ProjectTemplate template) {
    showDialog(
      context: context,
      builder: (_) => CreateProjectDialog(initialTemplate: template),
    );
  }

  void _duplicateTemplate(ProjectTemplate template) {
    showDialog(
      context: context,
      builder: (_) => DuplicateTemplateDialog(template: template),
    );
  }

  // Ids of templates currently re-extracting metadata — tracked here (rather
  // than per-row widget state, which TrinaGrid rows don't have) so the
  // actions column can show a per-row spinner and disable just that row's
  // button while the extraction it triggered is in flight.
  final Set<String> _extractingTemplateIds = {};

  Future<void> _extractMetadata(ProjectTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _extractingTemplateIds.add(template.id));
    try {
      await ref
          .read(projectTemplatesNotifierProvider.notifier)
          .extractMetadataForTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.metadataExtractedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToExtractMetadata(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _extractingTemplateIds.remove(template.id));
    }
  }

  /// [orderedIds] is the current filtered/visible row order — needed by the
  /// header "select all" checkbox, the same way the main dashboard table's
  /// checkbox column works.
  List<TrinaColumn> _buildColumns(
    AppLocalizations l10n,
    List<String> orderedIds,
  ) {
    return [
      TrinaColumn(
        title: '',
        field: 'checkbox',
        type: TrinaColumnType.text(),
        width: 50,
        minWidth: 50,
        frozen: TrinaColumnFrozen.start,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableFilterMenuItem: false,
        enableSorting: false,
        enableEditingMode: false,
        titleRenderer: (rendererContext) {
          final selected = _selectedTemplateIds;
          final allSelected =
              orderedIds.isNotEmpty && orderedIds.every(selected.contains);
          final style = rendererContext.stateManager.configuration.style;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: rendererContext.column.backgroundColor,
              border: BorderDirectional(
                end: style.enableColumnBorderVertical
                    ? BorderSide(color: style.borderColor)
                    : BorderSide.none,
              ),
            ),
            child: Center(
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: allSelected,
                  tristate: selected.isNotEmpty && !allSelected,
                  onChanged: (_) => allSelected
                      ? _clickSelection.clear()
                      : _clickSelection.selectAll(),
                ),
              ),
            ),
          );
        },
        renderer: (ctx) {
          final template = ctx.row.cells['data']!.value as ProjectTemplate;
          final isSelected = _selectedTemplateIds.contains(template.id);
          return Transform.scale(
            scale: 0.78,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) {
                // A modifier-held click on this cell is already handled once,
                // at row level, by the grid's rowWrapper — this cell is part
                // of the row it wraps. Acting on it here as well would toggle
                // the same template twice and cancel itself out.
                if (selectionModifierHeld()) return;
                _clickSelection.toggle(template.id);
              },
            ),
          );
        },
      ),
      TrinaColumn(
        title: l10n.templateName,
        field: 'name',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        enableContextMenu: false,
        width: 260,
        minWidth: 160,
        frozen: TrinaColumnFrozen.start,
        renderer: (ctx) {
          final template = ctx.row.cells['data']!.value as ProjectTemplate;
          final fullPath = p.join(
            template.sourceFolderPath,
            template.mainFileRelativePath,
          );
          final sourceExists = File(fullPath).existsSync();
          return Row(
            children: [
              Expanded(
                child: Text(template.name, overflow: TextOverflow.ellipsis),
              ),
              if (!sourceExists)
                Tooltip(
                  message: AppLocalizations.of(context)!.templateSourceMissing,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Colors.orange.shade400,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      TrinaColumn(
        title: l10n.daw,
        field: 'dawType',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 140,
        minWidth: 100,
        renderer: (ctx) {
          final dawType = ctx.cell.value as String? ?? '';
          final logoPath = getDawLogoPath(dawType);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logoPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Image.asset(
                    logoPath,
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              Flexible(child: Text(dawType, overflow: TextOverflow.ellipsis)),
            ],
          );
        },
      ),
      TrinaColumn(
        title: l10n.bpm,
        field: 'bpm',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 90,
        minWidth: 80,
      ),
      TrinaColumn(
        title: l10n.key.split(' ').first,
        field: 'key',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 150,
        minWidth: 120,
        renderer: (ctx) {
          final template = ctx.row.cells['data']!.value as ProjectTemplate;
          final key = template.musicalKey;
          if (key == null || key.isEmpty) return const SizedBox.shrink();
          final camelot = camelotCodeForKey(key);
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  key,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (camelot != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: 1,
                    height: 14,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    camelot,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      TrinaColumn(
        title: l10n.dateModifiedColumn,
        field: 'modifiedAt',
        // Cell values are raw DateTimes (not the formatted display string),
        // same as the main dashboard table's lastModified column, so sorting
        // compares chronologically instead of alphabetically.
        type: TrinaColumnType.custom(
          compare: compareTemplateModifiedCellValues,
        ),
        enableEditingMode: false,
        width: 200,
        minWidth: 160,
        renderer: (ctx) {
          final date = ctx.cell.value as DateTime?;
          if (date == null) return const SizedBox.shrink();
          // Unlike the dashboard's lastModified column, this is intentionally
          // plain text — no staleness color gradient. Templates aren't
          // "worked on" the way projects are, so how long ago the file was
          // touched isn't a meaningful signal here.
          return Consumer(
            builder: (context, ref, _) {
              final dateFormat = ref.watch(dateFormatProvider);
              return Text(dateFormat.format(date));
            },
          );
        },
      ),
      TrinaColumn(
        title: l10n.actions,
        field: 'actions',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: false,
        enableColumnDrag: false,
        width: 270,
        minWidth: 270,
        renderer: (ctx) {
          final template = ctx.row.cells['data']!.value as ProjectTemplate;
          final fullPath = p.join(
            template.sourceFolderPath,
            template.mainFileRelativePath,
          );
          final sourceExists = File(fullPath).existsSync();
          final extractionSupported = MetadataExtractor.supportsFullExtraction(
            fullPath,
          );
          final isExtracting = _extractingTemplateIds.contains(template.id);
          final l10n = AppLocalizations.of(context)!;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.folder_open, size: 18),
                tooltip: l10n.openFolder,
                visualDensity: VisualDensity.compact,
                onPressed: sourceExists
                    ? () => FileLauncher.openFolder(template.sourceFolderPath)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                tooltip: l10n.useTemplate,
                visualDensity: VisualDensity.compact,
                onPressed: sourceExists ? () => _useTemplate(template) : null,
              ),
              IconButton(
                icon: const Icon(Icons.assignment, size: 18),
                tooltip: l10n.tooltipViewDetails,
                visualDensity: VisualDensity.compact,
                onPressed: () => _viewTemplateDetails(template),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                tooltip: l10n.duplicateTemplate,
                visualDensity: VisualDensity.compact,
                onPressed: sourceExists
                    ? () => _duplicateTemplate(template)
                    : null,
              ),
              IconButton(
                icon: isExtracting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 18),
                tooltip: l10n.extract,
                visualDensity: VisualDensity.compact,
                onPressed: sourceExists && extractionSupported && !isExtracting
                    ? () => _extractMetadata(template)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                tooltip: l10n.delete,
                visualDensity: VisualDensity.compact,
                onPressed: () => _deleteTemplate(template),
              ),
            ],
          );
        },
      ),
    ];
  }

  /// The main file's own last-modified timestamp on disk — not
  /// [ProjectTemplate.createdAt]/[updatedAt], which only track when the
  /// template record itself was registered/edited in the app. Null if the
  /// source file is missing.
  DateTime? _lastModifiedDate(ProjectTemplate template) {
    final file = File(
      p.join(template.sourceFolderPath, template.mainFileRelativePath),
    );
    if (!file.existsSync()) return null;
    return file.lastModifiedSync();
  }

  List<TrinaRow> _buildRows(List<ProjectTemplate> templates) {
    return templates
        .map(
          (template) => TrinaRow(
            cells: {
              'checkbox': TrinaCell(value: ''),
              'name': TrinaCell(value: template.name),
              'dawType': TrinaCell(
                value:
                    MetadataExtractor.getDawTypeFromExtension(
                      p.extension(template.mainFileRelativePath),
                    ) ??
                    '',
              ),
              'bpm': TrinaCell(
                value: template.bpm != null
                    ? template.bpm!.toStringAsFixed(
                        template.bpm! % 1 == 0 ? 0 : 2,
                      )
                    : '',
              ),
              'key': TrinaCell(value: template.musicalKey ?? ''),
              'modifiedAt': TrinaCell(value: _lastModifiedDate(template)),
              'actions': TrinaCell(value: ''),
              'data': TrinaCell(value: template),
            },
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(projectTemplatesProvider);
    final filtered = ref.watch(filteredProjectTemplatesProvider);
    final query = ref.watch(templateSearchProvider);
    final dawFilter = ref.watch(templateDawFilterProvider);
    final availableDaws = ref.watch(availableTemplateDawsProvider);
    final keyFilter = ref.watch(templateKeyFilterProvider);
    final availableKeys = ref.watch(availableTemplateKeysProvider);
    final hasAnyFilterOptions =
        availableDaws.isNotEmpty || availableKeys.isNotEmpty;
    final isMobile = MobileUtils.isMobile();
    final activeTheme = ref.watch(themeDataProvider);
    final isNeon = ref.watch(themeTypeProvider) == AppThemeType.neonDark;
    final isDark = activeTheme.brightness == Brightness.dark;
    // Classic Dark's primary is a muted gray-blue, so tinting with it reads
    // as barely-there against the dark card background — lean on white
    // instead for a highlight that actually contrasts. Neon Dark's bright
    // primary already pops, so keep that one colored.
    final rowSelectColor = isNeon
        ? activeTheme.colorScheme.primary.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.14);
    final oddColor = isNeon
        ? activeTheme.scaffoldBackgroundColor
        : activeTheme.cardColor;
    final evenColor = isNeon
        ? activeTheme.cardColor
        : isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            activeTheme.cardColor,
          )
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.04),
            activeTheme.cardColor,
          );

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyF,
        ): const _SearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SearchIntent: _SearchAction(_focusSearchAndSelectAll),
        },
        child: Focus(
          autofocus: true,
          canRequestFocus: true,
          child: Scaffold(
            appBar: isMobile
                ? AppBar(
                    title: Text(l10n.projectTemplates),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  )
                : null,
            body: Column(
              children: [
                DesktopTitleBar(title: l10n.projectTemplates, showBack: true),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.note_add_outlined, size: 18),
                        label: Text(l10n.registerTemplate),
                        onPressed: _pickMainFile,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.folder_special_outlined,
                          size: 18,
                        ),
                        label: Text(l10n.manageTemplateFolders),
                        onPressed: _manageTemplateFolders,
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: l10n.refreshTemplateFolders,
                        child: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshTemplateRoots,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 320,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText:
                                '${l10n.searchTemplates} (${Platform.isMacOS ? '⌘F' : 'Ctrl+F'})',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasAnyFilterOptions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        if (availableDaws.isNotEmpty) ...[
                          FilterDropdown<String>(
                            icon: Icons.piano,
                            value: dawFilter,
                            hintText: l10n.filterByDaw,
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(l10n.allDaws),
                              ),
                              ...availableDaws.map(
                                (daw) => DropdownMenuItem<String>(
                                  value: daw,
                                  child: Text(daw),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              ref
                                  .read(templateDawFilterProvider.notifier)
                                  .setDaw(value);
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (availableKeys.isNotEmpty)
                          FilterDropdown<String>(
                            icon: Icons.music_note,
                            value: keyFilter,
                            hintText: l10n.filterByKey,
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(l10n.allKeys),
                              ),
                              ...availableKeys.map(
                                (key) => DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(key),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              ref
                                  .read(templateKeyFilterProvider.notifier)
                                  .setKey(value);
                            },
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isNeon
                              ? activeTheme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                )
                              : activeTheme.dividerColor.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: templatesAsync.when(
                        data: (templates) {
                          if (templates.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_copy_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noTemplatesYet,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.createFirstProjectTemplate,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          }

                          if (filtered.isEmpty) {
                            return Center(
                              child: Text(l10n.noMatchingTemplates),
                            );
                          }

                          final orderedIds = filtered.map((t) => t.id).toList();
                          _visibleTemplateIds = orderedIds;
                          final selectedIds = _selectedTemplateIds;
                          final selectedTemplates = templates
                              .where((t) => selectedIds.contains(t.id))
                              .toList();

                          return Column(
                            children: [
                              Expanded(
                                child: TrinaGrid(
                                  key: ValueKey(
                                    'project_templates_grid_${l10n.localeName}_${ref.watch(themeTypeProvider).name}_'
                                    '${filtered.map((t) => '${t.id}_${t.updatedAt}').join(',')}_${selectedIds.join(',')}',
                                  ),
                                  columns: _buildColumns(l10n, orderedIds),
                                  rows: _buildRows(filtered),
                                  columnMenuDelegate:
                                      const FitAllColumnsMenuDelegate(),
                                  // Ctrl/cmd- and shift-click anywhere on a
                                  // row extend the checkbox selection, so
                                  // building a multi-selection doesn't mean
                                  // aiming at the 50px checkbox column.
                                  rowWrapper: (context, rowWidget, row, _) =>
                                      rowClickSelectionWrapper(
                                        row: row,
                                        rowWidget: rowWidget,
                                        rowId: (r) =>
                                            (r.cells['data']?.value
                                                    as ProjectTemplate?)
                                                ?.id,
                                        onRowClick:
                                            _clickSelection.handleRowClick,
                                      ),
                                  // Keeps the shift-click anchor on whichever
                                  // row is highlighted, however the highlight
                                  // got there — a plain click or an arrow-key
                                  // move. Skipped while a selection modifier
                                  // is held: a shift-click moves the highlight
                                  // to the row it just range-selected to,
                                  // which must not become the anchor for the
                                  // *next* shift-click, and a ctrl-click has
                                  // already recorded its own anchor by the
                                  // time this fires.
                                  onActiveCellChanged:
                                      (
                                        TrinaGridOnActiveCellChangedEvent event,
                                      ) {
                                        if (selectionModifierHeld()) return;
                                        final template =
                                            event.cell?.row.cells['data']?.value
                                                as ProjectTemplate?;
                                        if (template != null) {
                                          _clickSelection.handleRowHighlight(
                                            template.id,
                                          );
                                        }
                                      },
                                  rowColorCallback: (TrinaRowColorContext ctx) {
                                    final isActivated =
                                        _tableStateManager?.currentRow ==
                                        ctx.row;
                                    if (isActivated) return rowSelectColor;
                                    return ctx.rowIdx.isOdd
                                        ? oddColor
                                        : evenColor;
                                  },
                                  onLoaded: (TrinaGridOnLoadedEvent event) {
                                    _tableStateManager?.removeListener(
                                      _onTableStateManagerChanged,
                                    );
                                    _tableStateManager = event.stateManager;
                                    // Same as the projects grid: nothing here
                                    // acts on a cell/row range — bulk actions
                                    // go through the checkbox selection — so
                                    // turn TrinaGrid's own selection off
                                    // rather than have a ctrl/shift-click
                                    // paint a range behind the real one.
                                    _tableStateManager!.setSelectingMode(
                                      TrinaGridSelectingMode.none,
                                    );
                                    _tableStateManager!.addListener(
                                      _onTableStateManagerChanged,
                                    );
                                  },
                                  onRowDoubleTap:
                                      (
                                        TrinaGridOnRowDoubleTapEvent event,
                                      ) async {
                                        final template =
                                            event.row.cells['data']?.value
                                                as ProjectTemplate?;
                                        if (template == null) return;
                                        await _viewTemplateDetails(template);
                                      },
                                  configuration: TrinaGridConfiguration(
                                    localeText: trinaGridLocaleTextFor(context),
                                    style: TrinaGridStyleConfig(
                                      gridBackgroundColor:
                                          activeTheme.cardColor,
                                      gridBorderColor: isNeon
                                          ? activeTheme.colorScheme.primary
                                                .withValues(alpha: 0.25)
                                          : activeTheme.dividerColor.withValues(
                                              alpha: 0.4,
                                            ),
                                      borderColor: isNeon
                                          ? activeTheme.colorScheme.primary
                                                .withValues(alpha: 0.15)
                                          : activeTheme.dividerColor.withValues(
                                              alpha: 0.25,
                                            ),
                                      gridBorderRadius: BorderRadius.zero,
                                      rowColor: activeTheme.cardColor,
                                      cellColorInEditState: Colors.transparent,
                                      cellColorInReadOnlyState:
                                          Colors.transparent,
                                      columnTextStyle: TextStyle(
                                        color: isNeon
                                            ? activeTheme.colorScheme.primary
                                            : activeTheme
                                                  .textTheme
                                                  .titleMedium
                                                  ?.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      cellTextStyle: TextStyle(
                                        color: activeTheme
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                      ),
                                      columnHeight: 44,
                                      rowHeight: 48,
                                      // Transparent so rowColorCallback controls all row
                                      // backgrounds (odd/even and click-selection) with
                                      // no per-cell border/fill on click.
                                      activatedBorderColor: Colors.transparent,
                                      activatedColor: Colors.transparent,
                                      iconColor: isNeon
                                          ? activeTheme.colorScheme.primary
                                                .withValues(alpha: 0.7)
                                          : activeTheme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color ??
                                                Colors.grey,
                                      menuBackgroundColor:
                                          activeTheme.cardColor,
                                      oddRowColor: oddColor,
                                      evenRowColor: evenColor,
                                    ),
                                    // rowClickSelectionWrapper only adds a
                                    // Listener around each row, so every row
                                    // still measures exactly rowHeight.
                                    // Saying so keeps TrinaGrid's ListView
                                    // itemExtent fast path, which it otherwise
                                    // drops for variable-height wrappers.
                                    rowWrapperIsConstantHeight: true,
                                    columnSize: const TrinaGridColumnSizeConfig(
                                      autoSizeMode: TrinaAutoSizeMode.scale,
                                      resizeMode: TrinaResizeMode.pushAndPull,
                                    ),
                                  ),
                                ),
                              ),
                              if (selectedIds.isNotEmpty)
                                _buildSelectionBar(l10n, selectedTemplates),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            Center(child: Text(l10n.errorLoadingTemplates)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar(
    AppLocalizations l10n,
    List<ProjectTemplate> selected,
  ) {
    final plural = selected.length == 1 ? '' : 's';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.templatesSelected(selected.length, plural),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _clearTemplateSelection,
                child: Text(l10n.clearSelection),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: Text(l10n.deleteSelectedTemplates),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _deleteSelectedTemplates(selected),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
