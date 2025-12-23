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
import 'package:url_launcher/url_launcher.dart';

import '../services/scanner_service.dart';
import 'project_detail_page.dart';
import 'releases_tab_page.dart';
import 'release_detail_page.dart';
import 'profile_manager_page.dart';
import 'widgets/language_switcher.dart';
import 'widgets/theme_switcher.dart';
import '../generated/l10n/app_localizations.dart';

import '../models/music_project.dart';
import '../models/release.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import 'package:uuid/uuid.dart';

const String kAppVersion = '1.5.0';

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
          icon: Icon(Icons.minimize, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => windowManager.minimize(),
        ),
        // Maximize/Restore
        IconButton(
          icon: Icon(Icons.crop_square_sharp, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: _toggleMaximize, 
        ),
        // Close
        IconButton(
          icon: Icon(Icons.close, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
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
  bool _extractingMetadata = false;
  late TabController _tabController;
  
  // 1. FocusNode para a barra de pesquisa
  final FocusNode _searchFocusNode = FocusNode();
  
  // FocusNode auxiliar para o RawKeyboardListener
  final FocusNode _globalRawKeyListenerFocusNode = FocusNode();
  
  // TextEditingController para a barra de pesquisa
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFocusNode.dispose(); 
    _globalRawKeyListenerFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }


  // MÉTODO FINAL: Inclui Ctrl+F e Ctrl+R
  void _handleRawKeyEvent(RawKeyEvent event) {
    try {
      // Escutar apenas o evento de tecla para baixo (RawKeyDownEvent)
      if (event is! RawKeyDownEvent) return;

      // Ignore modifier-only events (Alt, Ctrl, Shift alone) to avoid Flutter framework assertion errors
      final logicalKey = event.logicalKey;
      if (logicalKey == LogicalKeyboardKey.altLeft ||
          logicalKey == LogicalKeyboardKey.altRight ||
          logicalKey == LogicalKeyboardKey.controlLeft ||
          logicalKey == LogicalKeyboardKey.controlRight ||
          logicalKey == LogicalKeyboardKey.shiftLeft ||
          logicalKey == LogicalKeyboardKey.shiftRight ||
          logicalKey == LogicalKeyboardKey.metaLeft ||
          logicalKey == LogicalKeyboardKey.metaRight) {
        return;
      }

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
    } catch (e) {
      // Silently ignore keyboard handling errors to prevent crashes
      // This can happen due to Flutter framework issues with modifier keys on Windows
      if (kDebugMode) {
        print('Keyboard event handling error (ignored): $e');
      }
    }
  }


  Future<void> _scanAll({bool fullMetadata = false}) async {
    if (_scanning) return;
    final repo = await ref.read(repositoryProvider.future);
    setState(() => _scanning = true);
    try {
      final scanner = ScannerService();
      int foundCount = 0;
      await repo.clearMissingFiles();
      final scanTime = DateTime.now();
      for (final root in repo.getRoots()) {
        await for (final entity in scanner.scanDirectory(root.path)) {
          await repo.upsertFromFileSystemEntity(entity, fullMetadata: fullMetadata);
          foundCount++;
        }
        // Update lastScanAt timestamp for this root
        await repo.updateRootLastScanAt(root.id, scanTime);
      }
      if (mounted) {
        final scanType = fullMetadata ? AppLocalizations.of(context)!.deepScan : AppLocalizations.of(context)!.rescan;
        final msg = foundCount == 0
            ? AppLocalizations.of(context)!.noProjectsFoundInRoots
            : AppLocalizations.of(context)!.scanComplete(scanType, foundCount, foundCount == 1 ? '' : 's');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _fullScanAll() async {
    await _scanAll(fullMetadata: true);
  }

  Future<void> _createReleaseFromSelectedProjects(BuildContext context, WidgetRef ref, List<MusicProject> selectedProjects) async {
    if (selectedProjects.isEmpty) return;

    String releaseTitle;
    
    // If single project, use project name; otherwise create with empty title
    if (selectedProjects.length == 1) {
      releaseTitle = selectedProjects.first.displayName;
    } else {
      releaseTitle = ''; // Empty title, user will fill it in the release page
    }

    final selectedProjectIds = selectedProjects.map((p) => p.id).toList();
    await _createRelease(context, ref, selectedProjectIds, releaseTitle);
    
    // Clear selection after creating release
    ref.read(selectedProjectsProvider.notifier).clear();
  }

  Future<void> _hideProjects(BuildContext context, WidgetRef ref, List<String> selectedProjectIds) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final allProjectsAsync = ref.read(allProjectsStreamProvider);
      final allProjects = allProjectsAsync.value ?? [];
      
      for (final projectId in selectedProjectIds) {
        final project = allProjects.firstWhere((p) => p.id == projectId);
        final updated = project.copyWith(hidden: true);
        await repo.updateProject(updated);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.projectsHidden(selectedProjectIds.length, selectedProjectIds.length == 1 ? '' : 's'))),
        );
        // Invalidate to refresh the list
        ref.invalidate(allProjectsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToHideProjects(e.toString()))),
        );
      }
    }
  }

  Future<void> _unhideProjects(BuildContext context, WidgetRef ref, List<String> selectedProjectIds) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final allProjectsAsync = ref.read(allProjectsStreamProvider);
      final allProjects = allProjectsAsync.value ?? [];
      
      // Check if we're in "show only hidden" mode
      final hiddenMode = ref.read(showHiddenProjectsProvider);
      final isShowingOnlyHidden = hiddenMode == 2;
      
      for (final projectId in selectedProjectIds) {
        final project = allProjects.firstWhere((p) => p.id == projectId);
        final updated = project.copyWith(hidden: false);
        await repo.updateProject(updated);
      }
      
      // Invalidate to refresh the list
      ref.invalidate(allProjectsStreamProvider);
      
      // Wait a bit for the data to refresh, then check if there are any hidden projects left
      await Future.delayed(const Duration(milliseconds: 100));
      final updatedProjectsAsync = ref.read(allProjectsStreamProvider);
      final updatedProjects = updatedProjectsAsync.value ?? [];
      final remainingHiddenCount = updatedProjects.where((p) => p.hidden).length;
      
      // If we were showing only hidden and there are no hidden projects left, switch back to visible
      if (isShowingOnlyHidden && remainingHiddenCount == 0) {
        ref.read(showHiddenProjectsProvider.notifier).setShowOnlyHidden(false);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.projectsUnhidden(selectedProjectIds.length, selectedProjectIds.length == 1 ? '' : 's'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToUnhideProjects(e.toString()))),
        );
      }
    }
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
          SnackBar(content: Text(AppLocalizations.of(context)!.releaseCreated(releaseTitle))),
        );
        // Switch to releases tab and navigate to the new release
        _tabController.animateTo(1);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReleaseDetailPage(releaseId: newRelease.id),
            ),
          );
          // Refresh releases data when returning from detail page
          if (mounted) {
            ref.invalidate(releasesProvider);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateRelease(e.toString()))),
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
    final hiddenMode = ref.watch(showHiddenProjectsProvider);
    final hiddenNotifier = ref.read(showHiddenProjectsProvider.notifier);
    final phaseFilter = ref.watch(phaseFilterProvider);
    final initialScanning = ref.watch(initialScanStateProvider);
    final isProfileSwitching = ref.watch(profileSwitchingProvider);
    final isScanning = _scanning || initialScanning;
    final isAnyOperation = isScanning || isProfileSwitching || _extractingMetadata;
    
    // Sync search controller with provider state
    if (_searchController.text != currentParams.searchText) {
      _searchController.text = currentParams.searchText;
      _searchController.selection = TextSelection.fromPosition(TextPosition(offset: currentParams.searchText.length));
    }
    
    // Get all projects and filter out preserved projects (same logic as projectsProvider)
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);
    final allProjects = allProjectsAsync.value ?? [];
    final releasesAsync = ref.watch(releasesProvider);
    final scanRoots = ref.watch(scanRootsProvider);
    
    // Filter out preserved projects (in releases but not in any active scan root)
    final releases = releasesAsync.value ?? [];
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }
    
    // Get all active scan root paths (normalized for comparison)
    final activeRootPaths = scanRoots.map((root) {
      final normalized = path.normalize(root.path);
      // Ensure root path ends with separator for proper prefix matching
      return normalized.endsWith(path.separator) ? normalized : normalized + path.separator;
    }).toList();
    
    // Filter out preserved projects before counting
    final filteredProjects = allProjects.where((project) {
      // If project is not in any release, always include it
      if (!protectedProjectIds.contains(project.id)) {
        return true;
      }
      
      // If project is in a release, check if it's in any active scan root
      final projectPath = path.normalize(project.filePath);
      final isInActiveRoot = activeRootPaths.any((rootPath) {
        // Check if project path starts with the root path
        return projectPath.startsWith(rootPath);
      });
      
      // Only include if it's in an active root (preserved projects not in active roots are excluded)
      return isInActiveRoot;
    }).toList();
    
    // Count visible and hidden from filtered projects only
    final visibleCount = filteredProjects.where((p) => !p.hidden).length;
    final hiddenCount = filteredProjects.where((p) => p.hidden).length;

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
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  height: 40, // Altura padrão para a barra
                  child: Row(
                    children: [
                      // Título da Aplicação com versão (como antes)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'DAW Project Manager v$kAppVersion',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleMedium?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(), // Espaçador para empurrar os botões para a direita
                      const SizedBox(width: 4),
                      // Donate button
                      Tooltip(
                        message: 'Support the project',
                        child: TextButton.icon(
                          icon: const Icon(Icons.card_giftcard, size: 18, color: Colors.white70),
                          label: const Text(
                            'Support',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse('https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } 
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const ThemeSwitcher(),
                      const SizedBox(width: 8),
                      const LanguageSwitcher(),
                      const SizedBox(width: 8),
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
                    flex: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile button - always visible
                        Consumer(
                          builder: (context, ref, child) {
                            final currentProfileAsync = ref.watch(currentProfileProvider);
                            return currentProfileAsync.when(
                              loading: () => Tooltip(
                                message: AppLocalizations.of(context)!.profileManager,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.person, size: 24),
                                  label: Text(AppLocalizations.of(context)!.profileManager),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ProfileManagerPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              error: (_, __) => Tooltip(
                                message: AppLocalizations.of(context)!.profileManager,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.person, size: 24),
                                  label: Text(AppLocalizations.of(context)!.profileManager),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ProfileManagerPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              data: (currentProfile) {
                                Widget profileIcon;
                                if (currentProfile?.photoPath != null && 
                                    File(currentProfile!.photoPath!).existsSync()) {
                                  profileIcon = ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(currentProfile.photoPath!),
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.person, size: 24);
                                      },
                                    ),
                                  );
                                } else {
                                  profileIcon = const Icon(Icons.person, size: 24);
                                }

                                final profileName = currentProfile?.name ?? AppLocalizations.of(context)!.profileManager;

                                return Tooltip(
                                  message: profileName,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ProfileManagerPage(),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        profileIcon,
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 150),
                                            child: Text(
                                              profileName,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: isAnyOperation
                                ? null
                                : () async {
                                      final path = await FilePicker.platform.getDirectoryPath(dialogTitle: AppLocalizations.of(context)!.selectProjectsFolder);
                                      if (path != null) {
                                        try {
                                          final repo = await ref.read(repositoryProvider.future);
                                          await repo.addRoot(path);
                                          // Invalidate roots providers to refresh UI immediately
                                          ref.invalidate(rootsWatchProvider);
                                          ref.invalidate(scanRootsProvider);
                                          // _scanAll() manages its own _scanning state
                                          await _scanAll();
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(AppLocalizations.of(context)!.errorAddingFolder(e.toString()))),
                                            );
                                          }
                                        }
                                      }
                                    },
                            icon: isAnyOperation
                                ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                : const Icon(Icons.create_new_folder_outlined),
                            label: Text(AppLocalizations.of(context)!.addFolder),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: isAnyOperation
                                ? null
                                : () async {
                                      await _scanAll();
                                    },
                            icon: isAnyOperation
                                ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                : const Icon(Icons.refresh),
                            label: Text(isAnyOperation ? AppLocalizations.of(context)!.scanning : AppLocalizations.of(context)!.rescan),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Tooltip(
                            message: AppLocalizations.of(context)!.deepScanTooltip,
                            waitDuration: const Duration(milliseconds: 500),
                            child: ElevatedButton.icon(
                              onPressed: isAnyOperation
                                  ? null
                                  : () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: Theme.of(context).cardColor,
                                            title: Text(AppLocalizations.of(context)!.deepScan),
                                            content: Text(AppLocalizations.of(context)!.deepScanConfirm),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: Text(AppLocalizations.of(context)!.cancel),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                                ),
                                                child: Text(AppLocalizations.of(context)!.deepScan),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _fullScanAll();
                                        }
                                      },
                              icon: isAnyOperation
                                  ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                  : const Icon(Icons.search),
                              label: Text(isAnyOperation ? AppLocalizations.of(context)!.scanning : AppLocalizations.of(context)!.deepScan),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
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
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.searchProjects,
                                isDense: true,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: currentParams.searchText.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          _searchController.clear();
                                          ref.read(queryParamsNotifierProvider.notifier).setSearchText('');
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (text) {
                                ref.read(queryParamsNotifierProvider.notifier).setSearchText(text);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Exibe o contador de projetos
                        Flexible(
                          child: repoAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (repo) {
                              String projectText;
                              final l10n = AppLocalizations.of(context)!;
                              if (hiddenMode == 2) {
                                // Showing only hidden
                                projectText = '${l10n.rootsCount(repo.getRoots().length)}   ${l10n.projectsCount(hiddenCount)} ${l10n.hiddenOnly}';
                              } else {
                                // Showing visible or all
                                projectText = '${l10n.rootsCount(repo.getRoots().length)}   ${l10n.projectsCount(visibleCount)}';
                                if (hiddenCount > 0 && hiddenMode == 0) {
                                  projectText += ' ${l10n.hiddenCount(hiddenCount)}';
                                }
                              }
                              return Text(
                                projectText,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hiddenMode == 2 ? Colors.orange.shade300 : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show Hidden Projects checkbox
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: hiddenMode == 1, // Show all mode
                              onChanged: (value) {
                                if (value == true) {
                                  hiddenNotifier.setShowAll(true);
                                } else {
                                  // If unchecking, go back to show only visible (mode 0)
                                  hiddenNotifier.setShowAll(false);
                                }
                              },
                            ),
                            Text(
                              AppLocalizations.of(context)!.showHidden,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Show Only Hidden button
                        if (hiddenCount > 0)
                          TextButton.icon(
                            icon: Icon(
                              hiddenMode == 2 ? Icons.visibility : Icons.visibility_off_outlined,
                              size: 16,
                            ),
                            label: Text(
                              hiddenMode == 2 ? AppLocalizations.of(context)!.showAll : AppLocalizations.of(context)!.showOnlyHidden,
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                          backgroundColor: hiddenMode == 2 ? Colors.orange.shade700 : null,
                          foregroundColor: hiddenMode == 2 ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            onPressed: () {
                              if (hiddenMode == 2) {
                                // Currently showing only hidden, switch back to visible (mode 0)
                                hiddenNotifier.setShowOnlyHidden(false);
                              } else {
                                // Switch to show only hidden (mode 2)
                                // Also uncheck the "Show Hidden" checkbox
                                hiddenNotifier.setShowOnlyHidden(true);
                              }
                            },
                          ),
                        const SizedBox(width: 8),
                        // Phase Filter dropdown
                        DropdownButton<String>(
                          value: phaseFilter,
                          hint: Text(
                            AppLocalizations.of(context)!.filterByPhase,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          underline: const SizedBox.shrink(),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                          icon: Icon(Icons.filter_list, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(AppLocalizations.of(context)!.allPhases),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Idea',
                              child: Text(AppLocalizations.of(context)!.projectPhaseIdea),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Arranging',
                              child: Text(AppLocalizations.of(context)!.projectPhaseArranging),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Mixing',
                              child: Text(AppLocalizations.of(context)!.projectPhaseMixing),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Mastering',
                              child: Text(AppLocalizations.of(context)!.projectPhaseMastering),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Finished',
                              child: Text(AppLocalizations.of(context)!.projectPhaseFinished),
                            ),
                          ],
                          onChanged: (String? value) {
                            ref.read(phaseFilterProvider.notifier).setPhase(value);
                          },
                        ),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: AppLocalizations.of(context)!.clearLibraryTooltip,
                                  icon: const Icon(Icons.delete_forever),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: Theme.of(context).cardColor,
                                        title: Text(AppLocalizations.of(context)!.clearLibrary),
                                        content: Text(AppLocalizations.of(context)!.clearLibraryMessage),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
                                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.clear)),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final repo = await ref.read(repositoryProvider.future);
                                      await repo.clearAllData();
                                      // Invalidate repository and related providers to refresh UI
                                      ref.invalidate(repositoryProvider);
                                      ref.invalidate(rootsWatchProvider);
                                      ref.invalidate(scanRootsProvider);
                                      ref.invalidate(allProjectsStreamProvider);
                                      // Wait for repository to reload
                                      await ref.read(repositoryProvider.future);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.libraryCleared)));
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                // Versão também na barra de ações (à direita do ícone de lixeira)
                                Text(
                                  'v$kAppVersion',
                                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
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
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!.deleteRootPath),
                                content: Text(AppLocalizations.of(context)!.deleteRootPathMessage(r.path)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(AppLocalizations.of(context)!.cancel),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: Text(AppLocalizations.of(context)!.delete),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final repo = await ref.read(repositoryProvider.future);
                              await repo.removeRoot(r.id);
                              // Invalidate repository to ensure fresh data
                              ref.invalidate(repositoryProvider);
                              // Wait for repository to reload before scanning
                              await ref.read(repositoryProvider.future);
                              // Trigger a scan to update the UI and remove projects
                              await _scanAll();
                            }
                          },
                          backgroundColor: Theme.of(context).cardColor,
                          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                    ],
                  ),
                ),
              ),
            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.library_music), text: AppLocalizations.of(context)!.projectsTab),
                Tab(icon: Icon(Icons.album), text: AppLocalizations.of(context)!.releasesTab),
              ],
              labelColor: Theme.of(context).textTheme.titleMedium?.color,
              unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
              indicatorColor: Theme.of(context).colorScheme.primary,
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
                    onHideProjects: (selectedProjectIds) async {
                      await _hideProjects(context, ref, selectedProjectIds);
                    },
                    onUnhideProjects: (selectedProjectIds) async {
                      await _unhideProjects(context, ref, selectedProjectIds);
                    },
                    showHidden: hiddenMode == 1 || hiddenMode == 2,
                    onExtractingMetadataChanged: (extracting) {
                      setState(() => _extractingMetadata = extracting);
                    },
                    isAnyOperation: isAnyOperation,
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
        if (isAnyOperation)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        isProfileSwitching ? AppLocalizations.of(context)!.switchingProfiles : AppLocalizations.of(context)!.scanningProjects,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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
  final Function(List<String>) onHideProjects;
  final Function(List<String>) onUnhideProjects;
  final bool showHidden;
  final Function(bool) onExtractingMetadataChanged;
  final bool isAnyOperation;

  const _PlutoProjectsTableWithSelection({
    required this.projects,
    required this.dateFormat,
    required this.onCreateRelease,
    required this.onHideProjects,
    required this.onUnhideProjects,
    required this.showHidden,
    required this.onExtractingMetadataChanged,
    required this.isAnyOperation,
  });

  @override
  ConsumerState<_PlutoProjectsTableWithSelection> createState() => _PlutoProjectsTableWithSelectionState();
}

class _PlutoProjectsTableWithSelectionState extends ConsumerState<_PlutoProjectsTableWithSelection> {
  Set<String> get _selectedProjectIds => ref.watch(selectedProjectsProvider);

  void _clearSelection() {
    ref.read(selectedProjectsProvider.notifier).clear();
  }

  void _toggleProjectSelection(String projectId) {
    ref.read(selectedProjectsProvider.notifier).toggle(projectId);
  }

  void _selectAll() {
    ref.read(selectedProjectsProvider.notifier).selectAll(widget.projects.map((p) => p.id).toList());
  }

  bool get _areAllSelected {
    if (widget.projects.isEmpty) return false;
    return _selectedProjectIds.length == widget.projects.length &&
        widget.projects.every((p) => _selectedProjectIds.contains(p.id));
  }

  Future<void> _showChangeStatusDialog(BuildContext context) async {
    String? selectedStatus;
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.changeStatus),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.selectNewStatus),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseIdea),
                value: 'Idea',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseArranging),
                value: 'Arranging',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseMixing),
                value: 'Mixing',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseMastering),
                value: 'Mastering',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseFinished),
                value: 'Finished',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: selectedStatus == null
                  ? null
                  : () => Navigator.pop(ctx, selectedStatus),
              child: Text(AppLocalizations.of(context)!.changeStatus),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _changeProjectsStatus(context, result);
    }
  }

  Future<void> _changeProjectsStatus(BuildContext context, String newStatus) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final allProjectsAsync = ref.read(allProjectsStreamProvider);
      final allProjects = allProjectsAsync.value ?? [];
      
      int successCount = 0;
      int failCount = 0;
      
      for (final projectId in _selectedProjectIds) {
        try {
          final project = allProjects.firstWhere((p) => p.id == projectId);
          final updated = project.copyWith(status: newStatus);
          await repo.updateProject(updated);
          successCount++;
        } catch (e) {
          failCount++;
          if (kDebugMode) {
            print('Failed to update project $projectId: $e');
          }
        }
      }
      
      // Refresh the projects list
      ref.invalidate(allProjectsStreamProvider);
      
      if (mounted) {
        final statusText = _translateStatus(context, newStatus);
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.statusChangedForProjects(
                successCount,
                successCount == 1 ? '' : 's',
                statusText,
              )),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.statusChangedForProjectsWithErrors(
                successCount,
                successCount == 1 ? '' : 's',
                failCount,
                failCount == 1 ? '' : 's',
                statusText,
              )),
            ),
          );
        }
      }
      
      _clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToChangeStatus(e.toString()))),
        );
      }
    }
  }

  String _translateStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'Idea':
        return l10n.projectPhaseIdea;
      case 'Arranging':
        return l10n.projectPhaseArranging;
      case 'Mixing':
        return l10n.projectPhaseMixing;
      case 'Mastering':
        return l10n.projectPhaseMastering;
      case 'Finished':
        return l10n.projectPhaseFinished;
      default:
        return status;
    }
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
            onHideProjects: widget.onHideProjects,
            onUnhideProjects: widget.onUnhideProjects,
          ),
        ),
        // Selection action bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _areAllSelected,
                    onChanged: (value) {
                      if (value == true) {
                        _selectAll();
                      } else {
                        _clearSelection();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedProjectIds.isEmpty
                        ? AppLocalizations.of(context)!.selectAllProjects
                        : AppLocalizations.of(context)!.projectsSelected(_selectedProjectIds.length, _selectedProjectIds.length == 1 ? '' : 's'),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ],
              ),
              if (_selectedProjectIds.isNotEmpty)
                Row(
                  children: [
                    TextButton(
                      onPressed: _clearSelection,
                      child: Text(AppLocalizations.of(context)!.clearSelection),
                    ),
                    const SizedBox(width: 8),
                    // Show Hide button when not showing hidden projects, or Unhide when showing hidden
                    if (widget.showHidden)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: Text(AppLocalizations.of(context)!.unhide),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                        ),
                        onPressed: () {
                          widget.onUnhideProjects(_selectedProjectIds.toList());
                          _clearSelection();
                        },
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.visibility_off),
                        label: Text(AppLocalizations.of(context)!.hide),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                        ),
                        onPressed: () {
                          widget.onHideProjects(_selectedProjectIds.toList());
                          _clearSelection();
                        },
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(AppLocalizations.of(context)!.extractMetadata),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: widget.isAnyOperation
                          ? null
                          : () async {
                                widget.onExtractingMetadataChanged(true);
                                final repo = await ref.read(repositoryProvider.future);
                                int successCount = 0;
                                int failCount = 0;
                                
                                for (final projectId in _selectedProjectIds) {
                                  try {
                                    await repo.extractFullMetadataForProject(projectId);
                                    successCount++;
                                  } catch (_) {
                                    failCount++;
                                  }
                                }
                                
                                // Refresh the projects list
                                ref.invalidate(allProjectsStreamProvider);
                                
                                if (mounted) {
                                  final plural = successCount == 1 ? '' : 's';
                                  final failures = failCount > 0 ? AppLocalizations.of(context)!.extractionFailures(failCount, failCount == 1 ? '' : 's') : '';
                                  final message = AppLocalizations.of(context)!.metadataExtractedForProjects(successCount, plural, failures);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                                
                                widget.onExtractingMetadataChanged(false);
                                _clearSelection();
                              },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: Text(AppLocalizations.of(context)!.changeStatus),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _showChangeStatusDialog(context),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.album),
                      label: Text(AppLocalizations.of(context)!.createRelease),
                      onPressed: () {
                        final selectedProjects = widget.projects
                            .where((p) => _selectedProjectIds.contains(p.id))
                            .toList();
                        widget.onCreateRelease(selectedProjects);
                        _clearSelection();
                      },
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
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
  final Function(List<String>) onHideProjects;
  final Function(List<String>) onUnhideProjects;
  const _PlutoProjectsTable({
    required this.projects,
    required this.dateFormat,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onHideProjects,
    required this.onUnhideProjects,
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
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToWriteBpmFile(e.toString()))),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToWriteKeyFile(e.toString()))),
        );
      }
    }
  } 

  String _translateStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'Idea':
        return l10n.projectPhaseIdea;
      case 'Arranging':
        return l10n.projectPhaseArranging;
      case 'Mixing':
        return l10n.projectPhaseMixing;
      case 'Mastering':
        return l10n.projectPhaseMastering;
      case 'Finished':
        return l10n.projectPhaseFinished;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Idea':
        return Colors.blue.shade300;
      case 'Arranging':
        return Colors.orange.shade300;
      case 'Mixing':
        return Colors.purple.shade300;
      case 'Mastering':
        return Colors.pink.shade300;
      case 'Finished':
        return Colors.green.shade300;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }

  String? _getDawLogoPath(String? dawType) {
    if (dawType == null) return null;
    
    // Map DAW types to logo file names (case-insensitive matching)
    final dawLower = dawType.toLowerCase();
    final logoMap = {
      'ableton': 'ableton-live.png',
      'ableton live': 'ableton-live.png',
      'fl studio': 'fl-studio.png',
      'flstudio': 'fl-studio.png',
      'logic pro': 'logic-pro.png',
      'logic': 'logic-pro.png',
      'cubase': 'cubase.png',
      'studio one': 'studio-one.png',
      'studioone': 'studio-one.png',
      'reaper': 'reaper.png',
      'pro tools': 'pro-tools.png',
      'protools': 'pro-tools.png',
      'bitwig': 'bitwig-studio.png',
      'bitwig studio': 'bitwig-studio.png',
      'nuendo': 'nuendo.png',
      'maschine': 'maschine.png',
    };
    
    // Try exact match first
    if (logoMap.containsKey(dawLower)) {
      return 'resources/daw/logos/${logoMap[dawLower]}';
    }
    
    // Try partial match
    for (final entry in logoMap.entries) {
      if (dawLower.contains(entry.key) || entry.key.contains(dawLower)) {
        return 'resources/daw/logos/${entry.value}';
      }
    }
    
    return null;
  }

  Future<void> _launchProject(MusicProject project) async {
    final exists = File(project.filePath).existsSync() || Directory(project.filePath).existsSync();
    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)));
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.launchingProject(project.displayName))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunch(e.toString()))));
      }
    }
  }

  Future<void> _viewProjectDetails(MusicProject project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
    );
  }

  Future<void> _openProjectFolder(MusicProject project) async {
    final String projectPath = project.filePath;
    final String folderPath = FileSystemEntity.isDirectorySync(projectPath)
        ? projectPath // Se for um diretório, usa o próprio caminho
        : path.dirname(projectPath); // Se for um arquivo, usa o diretório pai
    
    final exists = Directory(folderPath).existsSync();
    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)));
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.osNotSupportedForOpeningFolder)));
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.openingFolder(project.displayName))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.failedToOpenFolder(e.toString()))));
      }
    }
  }

  Future<void> _showContextMenu(BuildContext context, MusicProject project, Offset position) async {
    final l10n = AppLocalizations.of(context)!;
    
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'launch',
          child: Row(
            children: [
              const Icon(Icons.open_in_new, size: 20),
              const SizedBox(width: 8),
              Text(l10n.tooltipLaunchInDaw),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.assignment, size: 20),
              const SizedBox(width: 8),
              Text(l10n.tooltipViewDetails),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'openFolder',
          child: Row(
            children: [
              const Icon(Icons.folder_open, size: 20),
              const SizedBox(width: 8),
              Text(l10n.openFolder),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: project.hidden ? 'unhide' : 'hide',
          child: Row(
            children: [
              Icon(
                project.hidden ? Icons.visibility : Icons.visibility_off,
                size: 20,
                color: project.hidden ? Colors.green.shade300 : Colors.red.shade300,
              ),
              const SizedBox(width: 8),
              Text(project.hidden ? l10n.unhide : l10n.hide),
            ],
          ),
        ),
      ],
      color: Theme.of(context).cardColor,
    );

    if (result != null && mounted) {
      switch (result) {
        case 'launch':
          await _launchProject(project);
          break;
        case 'view':
          await _viewProjectDetails(project);
          break;
        case 'openFolder':
          await _openProjectFolder(project);
          break;
        case 'hide':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(l10n.hide),
              content: Text(l10n.hideProjectMessage(project.displayName)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade300,
                  ),
                  child: Text(l10n.hide),
                ),
              ],
            ),
          );
          if (confirm == true) {
            widget.onHideProjects([project.id]);
          }
          break;
        case 'unhide':
          widget.onUnhideProjects([project.id]);
          break;
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
        // Force rebuild to update checkbox states and color coding
        stateManager!.notifyListeners();
      }
    }
    
    // Also check if any project's lastModifiedAt changed (for color updates during scanning)
    if (oldWidget.projects.length == widget.projects.length) {
      bool hasModifiedDates = false;
      for (int i = 0; i < widget.projects.length; i++) {
        if (i < oldWidget.projects.length) {
          if (widget.projects[i].lastModifiedAt != oldWidget.projects[i].lastModifiedAt) {
            hasModifiedDates = true;
            break;
          }
        }
      }
      
      if (hasModifiedDates && stateManager != null) {
        // Update the lastModified cell values to trigger renderer refresh
        for (int i = 0; i < stateManager!.rows.length && i < widget.projects.length; i++) {
          final project = widget.projects[i];
          final row = stateManager!.rows[i];
          if (row.cells['lastModified'] != null) {
            row.cells['lastModified']!.value = widget.dateFormat.format(project.lastModifiedAt);
          }
        }
        stateManager!.notifyListeners();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: AppLocalizations.of(context)!.name,
        field: 'name',
        type: PlutoColumnType.text(),
        enableColumnDrag: true,
        enableContextMenu: false,
        width: 600,
        minWidth: 200,
        frozen: PlutoColumnFrozen.start,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) {
            return Text(rendererContext.cell.value.toString());
          }
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: Text(rendererContext.cell.value.toString()),
          );
        },
      ),
      PlutoColumn(
        title: l10n.phase,
        field: 'status',
        type: PlutoColumnType.text(),
        width: 140,
        minWidth: 120,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          final status = rendererContext.cell.value as String? ?? '';
          final translatedStatus = _translateStatus(context, status);
          final textWidget = Text(
            translatedStatus,
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w500,
            ),
          );
          
          if (project == null) return textWidget;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: textWidget,
          );
        },
      ),
      PlutoColumn(
        title: AppLocalizations.of(context)!.daw,
        field: 'dawType',
        type: PlutoColumnType.text(),
        width: 140,
        minWidth: 100,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          final dawType = rendererContext.cell.value as String? ?? '';
          final logoPath = _getDawLogoPath(dawType);
          
          final content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logoPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Image.asset(
                    logoPath,
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              Flexible(
                child: Text(
                  dawType,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
          
          if (project == null) return content;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: content,
          );
        },
      ),
      PlutoColumn(
        title: AppLocalizations.of(context)!.bpm,
        field: 'bpm',
        type: PlutoColumnType.text(),
        width: 100,
        minWidth: 80,
        enableEditingMode: true,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          final textWidget = Text(rendererContext.cell.value.toString());
          
          if (project == null) return textWidget;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: textWidget,
          );
        },
      ),
      PlutoColumn(
        title: AppLocalizations.of(context)!.key.split(' ').first, // Get just "Key" from "Key (e.g., C#m, F major)"
        field: 'key',
        type: PlutoColumnType.text(),
        width: 120,
        minWidth: 100,
        enableEditingMode: true,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          final textWidget = Text(rendererContext.cell.value.toString());
          
          if (project == null) return textWidget;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: textWidget,
          );
        },
      ),
      PlutoColumn(
        title: AppLocalizations.of(context)!.lastModifiedColumn,
        field: 'lastModified',
        type: PlutoColumnType.text(),
        width: 200,
        minWidth: 160,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) {
            return Text(rendererContext.cell.value.toString());
          }
          
          final status = project.status;
          
          // If status is "Finished", show green
          Color textColor;
          if (status == 'Finished') {
            textColor = Colors.green;
          } else {
            final now = DateTime.now();
            final lastModified = project.lastModifiedAt;
            
            // Calculate color based on age of lastModifiedAt
            final daysSinceModified = now.difference(lastModified).inDays;
            
            if (daysSinceModified < 21) {
              // Recent (0-21 days): default white
              textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
            } else if (daysSinceModified < 60) {
              // Medium (21-60 days): yellow/orange gradient
              final ratio = (daysSinceModified - 21) / 39.0; // 0 to 1 from 21 to 60 days
              textColor = Color.lerp(
                Colors.yellow.shade300,
                Colors.orange.shade400,
                ratio,
              )!;
            } else {
              // Old (60+ days): orange to red gradient
              final ratio = ((daysSinceModified - 60) / 60.0).clamp(0.0, 1.0); // 0 to 1 from 60 to 120 days
              textColor = Color.lerp(
                Colors.orange.shade400,
                Colors.red.shade400,
                ratio,
              )!;
            }
          }
          
          final textWidget = Text(
            rendererContext.cell.value.toString(),
            style: TextStyle(color: textColor),
          );
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: textWidget,
          );
        },
      ),
      PlutoColumn(
        title: AppLocalizations.of(context)!.actions,
        field: 'launch',
        type: PlutoColumnType.text(),
        width: 250, // Increased width to accommodate hidden button
        minWidth: 220,
        renderer: (ctx) {
          final project = ctx.row.cells['data']!.value as MusicProject;
          
          // Lógica para determinar o diretório pai
          final String projectPath = project.filePath;
          final String folderPath = FileSystemEntity.isDirectorySync(projectPath)
              ? projectPath // Se for um diretório, usa o próprio caminho
              : path.dirname(projectPath); // Se for um arquivo, usa o diretório pai
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Launch button
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: AppLocalizations.of(context)!.tooltipLaunchInDaw,
                onPressed: () => _launchProject(project),
              ),
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 18),
                ),
              ),
              // View button
              IconButton(
                icon: const Icon(Icons.assignment),
                tooltip: AppLocalizations.of(context)!.tooltipViewDetails,
                onPressed: () => _viewProjectDetails(project),
              ),
              // Open Folder button
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: AppLocalizations.of(context)!.openFolder,
                onPressed: () => _openProjectFolder(project),
              ),
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 18),
                ),
              ),
              // Hidden button
              IconButton(
                icon: Icon(project.hidden ? Icons.visibility : Icons.visibility_off),
                color: project.hidden ? Colors.green.shade300 : Colors.red.shade300,
                tooltip: project.hidden 
                    ? AppLocalizations.of(context)!.unhide 
                    : AppLocalizations.of(context)!.hide,
                onPressed: () async {
                  if (project.hidden) {
                    // Unhide - no confirmation needed
                    widget.onUnhideProjects([project.id]);
                  } else {
                    // Hide - show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).cardColor,
                        title: Text(AppLocalizations.of(context)!.hide),
                        content: Text(AppLocalizations.of(context)!.hideProjectMessage(project.displayName)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade300,
                            ),
                            child: Text(AppLocalizations.of(context)!.hide),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      widget.onHideProjects([project.id]);
                    }
                  }
                },
              ),
            ],
          ),
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
          gridBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          gridBorderColor: Theme.of(context).dividerColor,
          gridBorderRadius: BorderRadius.zero,
          rowColor: Theme.of(context).cardColor,
          cellColorInEditState: Theme.of(context).cardColor,
          cellColorInReadOnlyState: Theme.of(context).cardColor,
          columnTextStyle: TextStyle(
            color: Theme.of(context).textTheme.titleMedium?.color,
            fontWeight: FontWeight.w600,
          ),
          cellTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          columnHeight: 44,
          rowHeight: 48,
          activatedBorderColor: Theme.of(context).colorScheme.primary,
          activatedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          iconColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          menuBackgroundColor: Theme.of(context).cardColor,
          evenRowColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor.withOpacity(0.5)
              : Theme.of(context).cardColor.withOpacity(0.7),
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
        
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
        );
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
      backgroundColor: Theme.of(context).cardColor,
      title: Text(AppLocalizations.of(context)!.enterReleaseTitle),
      content: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.releaseTitle,
          hintText: AppLocalizations.of(context)!.enterReleaseTitleHint,
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _titleController.text.trim()),
          child: Text(AppLocalizations.of(context)!.create),
        ),
      ],
    );
  }
}
